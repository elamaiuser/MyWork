/**
 * Drive-type-agnostic port of helper.js's calculateDriveShiftTags - byte-identical in the LWC
 * between mobileGenerator.js and fixedSiteGenerator.js, so this class needs no drive-type
 * branching at all. Computes the non-required Account/Location tags a drive shift should carry
 * (sked_Drive_Shift_Tag__c candidates), deduped and merged by tag NAME (not Id) across both
 * lists combined.
 */
public class skedDriveShiftTagCalculator {

    public class TagResult {
        public Id tagId;
        public Decimal minimumQuantity;
    }

    // A name required by EITHER list excludes that name entirely from the result (even a
    // different, non-required candidate sharing the name), minimumQuantity merges by MAX across
    // every candidate sharing a name (null treated as 0 for the comparison only - a genuinely
    // null winner stays null, never coerced to 0), and when accountTags and locationTags share a
    // name, the LAST-processed candidate's tagId wins - locationTags are processed after
    // accountTags, mirroring the JS iteration order exactly.
    public static List<TagResult> calculateDriveShiftTags(List<skedDriveShiftTagCandidate> accountTags, List<skedDriveShiftTagCandidate> locationTags) {
        // The JS treats a missing/null driveTags.accountTags/locationTags as [] at every guard
        // (`driveTags.accountTags || []`) - mirrored here so a caller passing null doesn't NPE.
        accountTags = accountTags == null ? new List<skedDriveShiftTagCandidate>() : accountTags;
        locationTags = locationTags == null ? new List<skedDriveShiftTagCandidate>() : locationTags;

        Set<String> requiredTagNames = new Set<String>();
        for (skedDriveShiftTagCandidate candidate : accountTags) {
            if (candidate.required == true) {
                requiredTagNames.add(candidate.tagName);
            }
        }
        for (skedDriveShiftTagCandidate candidate : locationTags) {
            if (candidate.required == true) {
                requiredTagNames.add(candidate.tagName);
            }
        }

        Map<String, TagResult> resultsByName = new Map<String, TagResult>();
        mergeCandidates(accountTags, requiredTagNames, resultsByName);
        mergeCandidates(locationTags, requiredTagNames, resultsByName);
        return resultsByName.values();
    }

    private static void mergeCandidates(List<skedDriveShiftTagCandidate> candidates, Set<String> requiredTagNames, Map<String, TagResult> resultsByName) {
        for (skedDriveShiftTagCandidate candidate : candidates) {
            if (candidate.required == true || requiredTagNames.contains(candidate.tagName)) {
                continue;
            }
            TagResult existing = resultsByName.get(candidate.tagName);
            TagResult merged = new TagResult();
            merged.tagId = candidate.tagId;
            merged.minimumQuantity = existing == null ? candidate.minimumQuantity : mergeMinimumQuantity(existing.minimumQuantity, candidate.minimumQuantity);
            resultsByName.put(candidate.tagName, merged);
        }
    }

    private static Decimal mergeMinimumQuantity(Decimal existingValue, Decimal candidateValue) {
        Decimal existingForCompare = existingValue == null ? 0 : existingValue;
        Decimal candidateForCompare = candidateValue == null ? 0 : candidateValue;
        return existingForCompare > candidateForCompare ? existingValue : candidateValue;
    }
}
