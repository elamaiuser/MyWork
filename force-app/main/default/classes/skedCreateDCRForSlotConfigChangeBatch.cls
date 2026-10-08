/**
 * Flags every drive a slot configuration change affects, so skedCreateNonUserChangeDCRBatch raises a
 * Slot Configuration Change DCR for it (HRP-17440). Mirrors skedCreateDCRForRTDBatch.
 */
public class skedCreateDCRForSlotConfigChangeBatch implements Database.Batchable<sObject> {

    private Set<Id> collectionOperationIds;
    private Date minDate;
    private Date maxDate;
    private Map<Id, List<sked_Collection_Operation_Slot_Config__c>> map_coId_configs;

    public skedCreateDCRForSlotConfigChangeBatch(List<sked_Collection_Operation_Slot_Config__c> slotConfigs) {
        this.initialize(slotConfigs);
    }

    private void initialize(List<sked_Collection_Operation_Slot_Config__c> slotConfigs) {
        this.map_coId_configs = new Map<Id, List<sked_Collection_Operation_Slot_Config__c>>();

        for (sked_Collection_Operation_Slot_Config__c slotConfig : slotConfigs) {
            if (slotConfig.sked_Collection_Operation__c == NULL) {
                continue;
            }

            List<sked_Collection_Operation_Slot_Config__c> configs = this.map_coId_configs.get(slotConfig.sked_Collection_Operation__c);
            if (configs == NULL) {
                configs = new List<sked_Collection_Operation_Slot_Config__c>();
                this.map_coId_configs.put(slotConfig.sked_Collection_Operation__c, configs);
            }
            configs.add(slotConfig);

            Date effectiveEndDate = skedDateTimeUtils.getValueOrMaxDate(slotConfig.sked_Effective_End_Date__c);
            if (this.minDate == NULL || this.minDate > slotConfig.sked_Effective_Start_Date__c) {
                this.minDate = slotConfig.sked_Effective_Start_Date__c;
            }
            if (this.maxDate == NULL || this.maxDate < effectiveEndDate) {
                this.maxDate = effectiveEndDate;
            }
        }

        this.collectionOperationIds = this.map_coId_configs.keySet();
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_Operation_Type__c
            FROM sked_Drive__c
            WHERE sked_Collection_Operation__c IN :this.collectionOperationIds
            AND sked_Drive_Date__c >= TODAY
            AND sked_Drive_Date__c >= :this.minDate
            AND sked_Drive_Date__c <= :this.maxDate
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL
            AND sked_Status__c != :skedConstants.DRIVE_STATUS_COMPLETE
            AND sked_Surrogate_Drive_for__c = NULL
            ORDER BY sked_Collection_Operation__c, sked_Drive_Date__c ASC
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        List<sked_Drive__c> drivesToGenerateDCR = new List<sked_Drive__c>();

        for (sked_Drive__c drive : drives) {
            List<sked_Collection_Operation_Slot_Config__c> configs = this.map_coId_configs.get(drive.sked_Collection_Operation__c);
            if (configs == NULL) {
                continue;
            }

            for (sked_Collection_Operation_Slot_Config__c slotConfig : configs) {
                if (appliesToDrive(slotConfig, drive)) {
                    drive.sked_Slot_Config_Change_DCR_Required__c = true;
                    drivesToGenerateDCR.add(drive);
                    break;
                }
            }
        }

        if (!drivesToGenerateDCR.isEmpty()) {
            update drivesToGenerateDCR;
        }
    }

    public void finish(Database.BatchableContext BC) {
        skedCreateNonUserChangeDCRBatch.schedule();
    }

    /*********************************************************** Private methods ***********************************************************/
    /**
     * A configuration row reaches a drive when the drive date falls in its effective period and the drive's type
     * (and, for fixed sites, its operation type) matches. Mirrors skedCreateDCRForRTDBatch's drive matching.
     */
    private Boolean appliesToDrive(sked_Collection_Operation_Slot_Config__c slotConfig, sked_Drive__c drive) {
        Date effectiveEndDate = skedDateTimeUtils.getValueOrMaxDate(slotConfig.sked_Effective_End_Date__c);
        Boolean isWithinEffectivePeriod = slotConfig.sked_Effective_Start_Date__c <= drive.sked_Drive_Date__c
            && drive.sked_Drive_Date__c <= effectiveEndDate;
        if (!isWithinEffectivePeriod || slotConfig.sked_Drive_Type__c != drive.sked_Type_of_Drive__c) {
            return false;
        }

        if (skedConstants.DRIVE_TYPE_FIXED_SITE.equals(slotConfig.sked_Drive_Type__c)) {
            return slotConfig.sked_Fixed_Site_Operation_Type__c == drive.sked_Operation_Type__c;
        }
        return true;
    }
}
