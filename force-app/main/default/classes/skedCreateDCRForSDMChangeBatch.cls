/**
 * Flags existing drives whose staffing complement is now stale because the Staffing Decision Matrix
 * mapped to their Collection Operation changed. Shared by both entry points - a new junction row
 * (skedCollectionOperationSDMHandler) and an edit to the SDM itself (skedStaffingDecisionMatrixHandler)
 * - so it is deliberately coupled to neither trigger's shape, only to the junctions themselves.
 *
 * Each junction passed in must carry sked_Collection_Operation__c, both effective dates, and
 * sked_Staffing_Decision_Matrix__r.RecordType.Name.
 */
public class skedCreateDCRForSDMChangeBatch implements Database.Batchable<sObject>, Database.Stateful {

    private List<sked_Collection_Operation_SDM__c> junctions;
    private Set<Id> collectionOperationIds;
    private Date minStartDate;
    // Null means at least one mapping is open-ended, so the drive query gets no upper bound.
    private Date maxEndDate;

    public skedCreateDCRForSDMChangeBatch(List<sked_Collection_Operation_SDM__c> junctions) {
        this.junctions = junctions;
        this.collectionOperationIds = new Set<Id>();
        Boolean hasOpenEndedWindow = false;
        Date latestEndDate = null;

        for (sked_Collection_Operation_SDM__c junction : junctions) {
            this.collectionOperationIds.add(junction.sked_Collection_Operation__c);

            Date startDate = junction.sked_Effective_Start_Date__c;
            if (startDate != null && (this.minStartDate == null || this.minStartDate > startDate)) {
                this.minStartDate = startDate;
            }

            Date endDate = junction.sked_Effective_End_Date__c;
            if (endDate == null) {
                hasOpenEndedWindow = true;
            } else if (latestEndDate == null || latestEndDate < endDate) {
                latestEndDate = endDate;
            }
        }

        this.maxEndDate = hasOpenEndedWindow ? null : latestEndDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Drives that already happened keep the complement they ran with - only future work is restaffed.
        Date lowerBound = this.minStartDate != null && this.minStartDate > Date.today()
            ? this.minStartDate
            : Date.today();

        if (this.maxEndDate == null) {
            return Database.getQueryLocator([
                SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c
                FROM sked_Drive__c
                WHERE sked_Collection_Operation__c IN :this.collectionOperationIds
                AND sked_Drive_Date__c >= :lowerBound
                AND sked_Surrogate_Drive_for__c = NULL
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
                AND sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE
            ]);
        }

        Date upperBound = this.maxEndDate;
        return Database.getQueryLocator([
            SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c
            FROM sked_Drive__c
            WHERE sked_Collection_Operation__c IN :this.collectionOperationIds
            AND sked_Drive_Date__c >= :lowerBound
            AND sked_Drive_Date__c <= :upperBound
            AND sked_Surrogate_Drive_for__c = NULL
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE
        ]);
    }

    public void execute(Database.BatchableContext bc, List<sked_Drive__c> drives) {
        List<sked_Drive__c> drivesToFlag = new List<sked_Drive__c>();
        for (sked_Drive__c drive : drives) {
            if (matchesAnyJunction(drive)) {
                drive.sked_SDM_Change_DCR_Required__c = true;
                drivesToFlag.add(drive);
            }
        }

        if (!drivesToFlag.isEmpty()) {
            update drivesToFlag;
        }
    }

    public void finish(Database.BatchableContext bc) {
        skedCreateNonUserChangeDCRBatch.schedule();
    }

    /**
     * The date range in start() is the union of every junction's window, so a drive inside that
     * range still has to be matched back to a specific junction - same Collection Operation, inside
     * that junction's own window, and drive type equal to the SDM's record type.
     */
    private Boolean matchesAnyJunction(sked_Drive__c drive) {
        for (sked_Collection_Operation_SDM__c junction : this.junctions) {
            Boolean sameCollectionOperation = junction.sked_Collection_Operation__c == drive.sked_Collection_Operation__c;
            Boolean onOrAfterStart = junction.sked_Effective_Start_Date__c == null
                || drive.sked_Drive_Date__c >= junction.sked_Effective_Start_Date__c;
            Boolean onOrBeforeEnd = junction.sked_Effective_End_Date__c == null
                || drive.sked_Drive_Date__c <= junction.sked_Effective_End_Date__c;
            Boolean sameDriveType = junction.sked_Staffing_Decision_Matrix__r.RecordType.Name == drive.sked_Type_of_Drive__c;

            if (sameCollectionOperation && onOrAfterStart && onOrBeforeEnd && sameDriveType) {
                return true;
            }
        }
        return false;
    }
}