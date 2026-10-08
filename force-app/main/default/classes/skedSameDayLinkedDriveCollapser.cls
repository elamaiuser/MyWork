/**
 * Ported from helper.js's collapseSameDayLinkedDrives/collapseSameDayLinkedActivities (HRP-15611
 * Implementation Extensions) - collapses a same-day linked drive or activity pair into one entry
 * before the x2RBC/DOT/CDL_LIMIT and INSUFFICIENT_RESOURCES checks sum same-date quantities, so a
 * linked pair's shared resource pool isn't double-counted.
 *
 * For drives: only totalStaffRequested and driveShifts are actually maxed across the pair - the
 * source's own function spreads every other field from whichever drive was encountered first (a
 * documented quirk in its own comments notwithstanding); totalEquipmentRequested/
 * noOfAllocatedDOTVehicles/noOfAllocatedCDLVehicles are NOT maxed here either, faithfully
 * preserving that behavior rather than fixing it.
 */
public with sharing class skedSameDayLinkedDriveCollapser {

    public class CollapsedDriveShift {
        public Id timeBlockId;
        public Decimal staffSetup;
        public Time timeBlockStartTime;
    }

    public class CollapsedDrive {
        public Id driveId;
        public String status;
        public Boolean isFixedSite;
        public Id linkedDriveId;
        public String linkedDriveType;
        public Decimal totalStaffRequested;
        public Decimal totalEquipmentRequested;
        public Decimal noOfAllocatedDOTVehicles;
        public Decimal noOfAllocatedCDLVehicles;
        public List<CollapsedDriveShift> driveShifts = new List<CollapsedDriveShift>();
    }

    public static List<CollapsedDrive> collapseSameDayLinkedDrives(List<sked_Drive__c> sameDateDrives) {
        List<CollapsedDrive> source = new List<CollapsedDrive>();
        for (sked_Drive__c d : sameDateDrives) {
            source.add(toCollapsedDrive(d));
        }

        Set<Id> processedDriveIds = new Set<Id>();
        List<CollapsedDrive> result = new List<CollapsedDrive>();
        for (CollapsedDrive drive : source) {
            if (processedDriveIds.contains(drive.driveId)) {
                continue;
            }

            CollapsedDrive partner = (drive.linkedDriveId != null && drive.linkedDriveType == skedConstants.LINKED_DRIVE_TYPE_SINGLE)
                ? findSameDayLinkedPartner(drive, source) : null;

            if (partner == null) {
                result.add(drive);
                continue;
            }

            processedDriveIds.add(drive.driveId);
            processedDriveIds.add(partner.driveId);

            Map<Id, CollapsedDriveShift> mergedByTimeBlockId = new Map<Id, CollapsedDriveShift>();
            List<CollapsedDriveShift> combined = new List<CollapsedDriveShift>();
            combined.addAll(drive.driveShifts);
            combined.addAll(partner.driveShifts);
            for (CollapsedDriveShift shift : combined) {
                if (shift.timeBlockId == null) {
                    continue;
                }
                CollapsedDriveShift prev = mergedByTimeBlockId.get(shift.timeBlockId);
                CollapsedDriveShift merged = new CollapsedDriveShift();
                merged.timeBlockId = shift.timeBlockId;
                merged.timeBlockStartTime = prev != null ? prev.timeBlockStartTime : shift.timeBlockStartTime;
                merged.staffSetup = Math.max(prev != null && prev.staffSetup != null ? prev.staffSetup : 0,
                    shift.staffSetup != null ? shift.staffSetup : 0);
                mergedByTimeBlockId.put(shift.timeBlockId, merged);
            }
            List<CollapsedDriveShift> uniqueShifts = mergedByTimeBlockId.values();
            Decimal maxStaff = Math.max(drive.totalStaffRequested == null ? 0 : drive.totalStaffRequested,
                partner.totalStaffRequested == null ? 0 : partner.totalStaffRequested);

            List<CollapsedDriveShift> collapsedShifts = new List<CollapsedDriveShift>();
            if (!uniqueShifts.isEmpty()) {
                // >1 shift (spans time blocks): keep only the earliest, staffSetup = max(A, B).
                // ==1 shift (same time block): staffSetup = max(A, B). Same construction either way.
                CollapsedDriveShift earliest = uniqueShifts[0];
                for (CollapsedDriveShift shift : uniqueShifts) {
                    if (isEarlier(shift.timeBlockStartTime, earliest.timeBlockStartTime)) {
                        earliest = shift;
                    }
                }
                CollapsedDriveShift onlyShift = new CollapsedDriveShift();
                onlyShift.timeBlockId = earliest.timeBlockId;
                onlyShift.timeBlockStartTime = earliest.timeBlockStartTime;
                onlyShift.staffSetup = maxStaff;
                collapsedShifts.add(onlyShift);
            }

            CollapsedDrive merged = new CollapsedDrive();
            merged.driveId = drive.driveId;
            merged.status = drive.status;
            merged.isFixedSite = drive.isFixedSite;
            merged.linkedDriveId = drive.linkedDriveId;
            merged.linkedDriveType = drive.linkedDriveType;
            merged.totalEquipmentRequested = drive.totalEquipmentRequested;
            merged.noOfAllocatedDOTVehicles = drive.noOfAllocatedDOTVehicles;
            merged.noOfAllocatedCDLVehicles = drive.noOfAllocatedCDLVehicles;
            merged.totalStaffRequested = maxStaff;
            merged.driveShifts = collapsedShifts;
            result.add(merged);
        }
        return result;
    }

    private static CollapsedDrive findSameDayLinkedPartner(CollapsedDrive drive, List<CollapsedDrive> allDrives) {
        for (CollapsedDrive candidate : allDrives) {
            if (candidate.driveId != drive.driveId
                    && candidate.linkedDriveType == skedConstants.LINKED_DRIVE_TYPE_SINGLE
                    && candidate.linkedDriveId == drive.linkedDriveId) {
                return candidate;
            }
        }
        return null;
    }

    // A null Time sorts as "earliest" (matches the source's null-coalesce-to-empty-string compare).
    private static Boolean isEarlier(Time a, Time b) {
        if (a == null) {
            return b != null;
        }
        if (b == null) {
            return false;
        }
        return a < b;
    }

    private static CollapsedDrive toCollapsedDrive(sked_Drive__c d) {
        CollapsedDrive c = new CollapsedDrive();
        c.driveId = d.Id;
        c.status = d.sked_Status__c;
        c.isFixedSite = skedCollectionOperationTimeBlockMatcher.isFixedSiteDrive(d);
        c.linkedDriveId = d.sked_Linked_Drives__c;
        c.linkedDriveType = d.sked_Linked_Drives__c != null ? d.sked_Linked_Drives__r.sked_Linked_Drive_Type__c : null;
        c.totalStaffRequested = d.sked_Total_Staff_Requested__c;
        c.totalEquipmentRequested = d.sked_Total_Equipment_Requested__c;
        c.noOfAllocatedDOTVehicles = d.sked_No_of_Allocated_DOT__c;
        c.noOfAllocatedCDLVehicles = d.sked_No_of_Allocated_CDL__c;
        for (sked_Drive_Shift__c shift : d.sked_Drive_Shifts__r) {
            CollapsedDriveShift s = new CollapsedDriveShift();
            s.timeBlockId = shift.sked_Time_Block__c;
            s.staffSetup = shift.sked_Staff_Setup__c;
            s.timeBlockStartTime = shift.sked_Time_Block__c != null ? shift.sked_Time_Block__r.Start_Time__c : null;
            c.driveShifts.add(s);
        }
        return c;
    }

    public class CollapsedActivity {
        public Id timeBlockId;
        public Decimal fixedSiteStaffQuantity;
        public Decimal mobileStaffQuantity;
    }

    /**
     * Unlike collapseSameDayLinkedDrives, both staff-quantity fields ARE genuinely maxed across
     * the whole linked group here (not just one of them) - matches the source exactly. A group can
     * have more than 2 members (grouped by linkedDrivesId, not a strict pair).
     */
    public static List<CollapsedActivity> collapseSameDayLinkedActivities(List<sked__Activity__c> activities) {
        Set<Id> processedGroupIds = new Set<Id>();
        List<CollapsedActivity> result = new List<CollapsedActivity>();
        for (sked__Activity__c activity : activities) {
            Id linkedDrivesId = activity.sked_Linked_Drives__c;
            String linkedDriveType = linkedDrivesId != null ? activity.sked_Linked_Drives__r.sked_Linked_Drive_Type__c : null;

            if (linkedDrivesId == null || linkedDriveType != skedConstants.LINKED_DRIVE_TYPE_SINGLE) {
                CollapsedActivity passthrough = new CollapsedActivity();
                passthrough.timeBlockId = activity.sked_Time_Block__c;
                passthrough.fixedSiteStaffQuantity = activity.sked_Fixed_Site_Staff_Quantity__c;
                passthrough.mobileStaffQuantity = activity.sked_Mobile_Staff_Quantity__c;
                result.add(passthrough);
                continue;
            }
            if (processedGroupIds.contains(linkedDrivesId)) {
                continue; // later member of an already-collapsed group
            }
            processedGroupIds.add(linkedDrivesId);

            Decimal maxFixedSite = 0;
            Decimal maxMobile = 0;
            for (sked__Activity__c candidate : activities) {
                Id candidateLinkedDrivesId = candidate.sked_Linked_Drives__c;
                String candidateLinkedDriveType = candidateLinkedDrivesId != null ? candidate.sked_Linked_Drives__r.sked_Linked_Drive_Type__c : null;
                if (candidateLinkedDrivesId == linkedDrivesId && candidateLinkedDriveType == skedConstants.LINKED_DRIVE_TYPE_SINGLE) {
                    Decimal fixedSiteQty = candidate.sked_Fixed_Site_Staff_Quantity__c == null ? 0 : candidate.sked_Fixed_Site_Staff_Quantity__c;
                    Decimal mobileQty = candidate.sked_Mobile_Staff_Quantity__c == null ? 0 : candidate.sked_Mobile_Staff_Quantity__c;
                    maxFixedSite = Math.max(maxFixedSite, fixedSiteQty);
                    maxMobile = Math.max(maxMobile, mobileQty);
                }
            }

            CollapsedActivity collapsed = new CollapsedActivity();
            collapsed.timeBlockId = activity.sked_Time_Block__c;
            collapsed.fixedSiteStaffQuantity = maxFixedSite;
            collapsed.mobileStaffQuantity = maxMobile;
            result.add(collapsed);
        }
        return result;
    }
}
