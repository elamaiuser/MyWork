/**
 * Raises Drive Change Requests when an SDM's own capacity or threshold values are edited.
 *
 * Editing the matrix in place is the only way to change staffing for a Collection Operation that is
 * already mapped to it - no junction row is created or touched - so without this entry point such a
 * change would only ever reach drives created afterwards.
 */
public class skedStaffingDecisionMatrixHandler extends skedTriggerHub {

    /**
     * Named explicitly rather than derived from the schema. A field map would also pick up OwnerId
     * and RecordTypeId, so simply reassigning a record's owner would raise a DCR against every
     * in-window drive. sked_MigrationID__c and the two NR Volunteer Band fields are excluded because
     * none of them feed drive staffing.
     */
    private static final Set<String> STAFFING_FIELD_API_NAMES = new Set<String>{
        'sked_2RBC_Hourly_Capacity__c',
        'sked_2RBC_Staff_Capacity__c',
        'sked_Charge_Capacity__c',
        'sked_Charge_Threshold__c',
        'sked_Driver_Capacity__c',
        'sked_Driver_Support_Capacity__c',
        'sked_Plasma_Hourly_Capacity__c',
        'sked_Platelet_Hourly_Capacity__c',
        'sked_Platelet_Round_Capacity__c',
        'sked_Team_Supervisor_Threshold__c',
        'sked_VP_HH_Capacity__c',
        'sked_WB_Hourly_Capacity__c'
    };

    public override void onAfterUpdate() {
        if (skedSetting.instance.Admin.migrationMode) {
            return;
        }
        // Database.executeBatch is illegal from batch/future context, so a migration or integration
        // job editing matrices simply does not fan out.
        if (System.isBatch() || System.isFuture()) {
            return;
        }

        Set<Id> changedMatrixIds = getMatrixIdsWithChangedStaffing();
        if (changedMatrixIds.isEmpty()) {
            return;
        }

        // A mapping that closed in the past cannot affect any drive this batch would touch.
        List<sked_Collection_Operation_SDM__c> junctions = [
            SELECT Id, sked_Collection_Operation__c, sked_Effective_Start_Date__c,
                   sked_Effective_End_Date__c, sked_Staffing_Decision_Matrix__r.RecordType.Name
            FROM sked_Collection_Operation_SDM__c
            WHERE sked_Staffing_Decision_Matrix__c IN :changedMatrixIds
            AND (sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= TODAY)
        ];

        if (!junctions.isEmpty()) {
            Database.executeBatch(new skedCreateDCRForSDMChangeBatch(junctions), 200);
        }
    }

    private Set<Id> getMatrixIdsWithChangedStaffing() {
        Set<Id> changedMatrixIds = new Set<Id>();

        for (sked_Staffing_Decision_Matrix__c newMatrix : (List<sked_Staffing_Decision_Matrix__c>) this.context.newRecords) {
            sked_Staffing_Decision_Matrix__c oldMatrix =
                (sked_Staffing_Decision_Matrix__c) this.context.oldMap.get(newMatrix.Id);

            for (String fieldApiName : STAFFING_FIELD_API_NAMES) {
                if (newMatrix.get(fieldApiName) != oldMatrix.get(fieldApiName)) {
                    changedMatrixIds.add(newMatrix.Id);
                    break;
                }
            }
        }

        return changedMatrixIds;
    }
}