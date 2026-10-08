/**
 * Drive-type-agnostic low-level slot-generation primitives, extracted out of
 * skedMobileSlotGenerator so a future Fixed Site engine can reuse them - confirmed via a
 * line-level comparison of mobileGenerator.js and fixedSiteGenerator.js that these two
 * methods are genuinely shared (reduceSlots is byte-identical between the two; generateSlots
 * differs only by the excludedTimeRanges parameter, which Fixed Site needs and Mobile always
 * passes empty).
 */
public with sharing class skedSlotGenerator {

    // Cycles through roundMinutesIntoStart to progressively densify slot coverage only as far
    // as needed to reach totalSlots. excludedTimeRanges lets a caller skip candidate slot starts
    // that fall inside a blocked window (e.g. Fixed Site's Platelet-round exclusions) without
    // counting them toward totalSlots - Mobile always passes an empty list, since its
    // regeneration path has nothing to exclude.
    public static List<sked__Slot__c> generateSlots(String slotType, DateTime startTime, DateTime lastSlotStart, Integer intervalMinutes,
            Integer slotDurationMinutes, List<Integer> roundMinutesIntoStart, Integer totalSlots, String timezoneSidId,
            List<skedTimeRange> excludedTimeRanges) {
        List<sked__Slot__c> slots = new List<sked__Slot__c>();
        if (totalSlots == null || totalSlots <= 0) {
            return slots;
        }

        Integer roundCount = 1;
        Integer slotCount = 0;
        Integer cycleLength = roundMinutesIntoStart.size();
        Integer consecutiveRoundsWithNoProgress = 0;
        while (slotCount < totalSlots) {
            Integer minutesIntoStart = roundMinutesIntoStart[cyclicIndex(roundCount, cycleLength)];
            DateTime firstSlotStart = skedDateTimeUtils.addMinutes(startTime, minutesIntoStart, timezoneSidId);
            if (firstSlotStart > lastSlotStart) {
                break;
            }

            Integer slotCountBeforeRound = slotCount;
            DateTime tempDt = firstSlotStart;
            while (tempDt <= lastSlotStart) {
                if (!isTimeExcluded(tempDt, excludedTimeRanges)) {
                    slots.add(newSlot(slotType, tempDt, skedDateTimeUtils.addMinutes(tempDt, slotDurationMinutes, timezoneSidId)));
                    slotCount++;
                    if (slotCount == totalSlots) {
                        break;
                    }
                }
                tempDt = skedDateTimeUtils.addMinutes(tempDt, intervalMinutes, timezoneSidId);
            }

            // Every offset in roundMinutesIntoStart is deterministic given fixed inputs - if a full
            // cycle through all of them adds nothing (every candidate excluded), no later round can
            // ever differ. Without this, an exclusion range covering every candidate in every offset
            // spins forever instead of returning fewer than totalSlots.
            if (slotCount == slotCountBeforeRound) {
                consecutiveRoundsWithNoProgress++;
                if (consecutiveRoundsWithNoProgress >= cycleLength) {
                    break;
                }
            } else {
                consecutiveRoundsWithNoProgress = 0;
            }
            roundCount++;
        }
        return slots;
    }

    // Removes slots falling within the given window, cycling the same round offsets as
    // generateSlots, until slotReductionPercent of the in-window slots are removed.
    public static void reduceSlots(List<sked__Slot__c> slots, DateTime startTime, DateTime endTime, Integer intervalMinutes,
            List<Integer> roundMinutesIntoStart, Decimal slotReductionPercent, String timezoneSidId) {
        Integer totalSlotsInWindow = 0;
        for (sked__Slot__c slot : slots) {
            if (slot.sked_Start__c >= startTime && slot.sked_End__c <= endTime) {
                totalSlotsInWindow++;
            }
        }
        Decimal reductionPercent = slotReductionPercent == null ? 0 : slotReductionPercent;
        Integer numberOfReducedSlots = Math.ceil(totalSlotsInWindow * (reductionPercent / 100)).intValue();

        Integer reduceSlotCount = 0;
        Integer roundCount = 1;
        Integer cycleLength = roundMinutesIntoStart.size();
        Integer consecutiveRoundsWithNoProgress = 0;
        while (reduceSlotCount < numberOfReducedSlots) {
            Integer minutesIntoStart = roundMinutesIntoStart[cyclicIndex(roundCount, cycleLength)];
            DateTime tempDt = skedDateTimeUtils.addMinutes(startTime, minutesIntoStart, timezoneSidId);

            Integer reduceCountBeforeRound = reduceSlotCount;
            while (tempDt < endTime) {
                Integer indexToRemove = -1;
                for (Integer i = 0; i < slots.size(); i++) {
                    if (slots[i].sked_Start__c == tempDt) {
                        indexToRemove = i;
                        break;
                    }
                }
                if (indexToRemove > -1) {
                    slots.remove(indexToRemove);
                    reduceSlotCount++;
                }
                if (reduceSlotCount == numberOfReducedSlots) {
                    break;
                }
                tempDt = skedDateTimeUtils.addMinutes(tempDt, intervalMinutes, timezoneSidId);
            }

            // Same no-progress guard as generateSlots: if a full cycle through every offset removes
            // nothing (no slot lands on any candidate grid point), no later round can differ either.
            if (reduceSlotCount == reduceCountBeforeRound) {
                consecutiveRoundsWithNoProgress++;
                if (consecutiveRoundsWithNoProgress >= cycleLength) {
                    break;
                }
            } else {
                consecutiveRoundsWithNoProgress = 0;
            }
            roundCount++;
        }
    }

    // Ported from baseGenerator.js:1257-1304's generateSlotsByNumberOfAssets - the general form of
    // the ceiling-distribution algorithm skedMobileSlotGenerator.generate2rbcSlots hardcodes for
    // Mobile's 2RBC case only. This is a NEW shared primitive, not a promotion of that Mobile
    // method - skedMobileSlotGenerator.cls is untouched by this addition.
    public static List<sked__Slot__c> generateSlotsByNumberOfAssets(String slotType, DateTime firstSlotStart, DateTime lastSlotStart,
            Integer roundIntervalMinutes, Integer numberOfGroups, Integer groupIntervalMinutes, Integer slotDurationMinutes,
            Decimal numberOfAssets, List<skedTimeRange> excludedTimeRanges, String timezoneSidId) {
        List<sked__Slot__c> slots = new List<sked__Slot__c>();
        Decimal assets = numberOfAssets == null ? 0 : numberOfAssets;
        if (assets <= 0) {
            return slots;
        }

        DateTime tempStart = firstSlotStart;
        while (tempStart <= lastSlotStart) {
            Decimal remainingAssets = assets;
            for (Integer i = 0; i < numberOfGroups; i++) {
                Decimal groupQuantity = Math.ceil(remainingAssets / (numberOfGroups - i));
                if (groupQuantity > remainingAssets) {
                    groupQuantity = remainingAssets;
                }

                DateTime slotStart = skedDateTimeUtils.addMinutes(tempStart, i * groupIntervalMinutes, timezoneSidId);
                DateTime slotEnd = skedDateTimeUtils.addMinutes(slotStart, slotDurationMinutes, timezoneSidId);
                if (slotStart <= lastSlotStart && !isTimeExcluded(slotStart, excludedTimeRanges)) {
                    for (Integer q = 0; q < groupQuantity.intValue(); q++) {
                        slots.add(newSlot(slotType, slotStart, slotEnd));
                    }
                }
                remainingAssets -= groupQuantity;
            }
            tempStart = skedDateTimeUtils.addMinutes(tempStart, roundIntervalMinutes, timezoneSidId);
        }
        return slots;
    }

    public static sked__Slot__c newSlot(String slotType, DateTime startTime, DateTime endTime) {
        return new sked__Slot__c(
            Name = slotType,
            sked_Type__c = slotType,
            sked_Start__c = startTime,
            sked_End__c = endTime,
            sked_Status__c = 'Open',
            sked_Locked__c = false
        );
    }

    // Half-open interval: candidate >= rangeStart && candidate < rangeEnd, mirroring the JS
    // isTimeExcluded predicate.
    private static Boolean isTimeExcluded(DateTime candidate, List<skedTimeRange> excludedTimeRanges) {
        for (skedTimeRange range : excludedTimeRanges) {
            if (candidate >= range.rangeStart && candidate < range.rangeEnd) {
                return true;
            }
        }
        return false;
    }

    // 0-based cyclic index: (roundCount - 1) % length.
    private static Integer cyclicIndex(Integer roundCount, Integer length) {
        return Math.mod(roundCount - 1, length);
    }
}
