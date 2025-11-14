public class BSF_Batch_RemoveDriveSpecialAffiliations implements Database.Batchable<sObject>, Schedulable {

    private final List<String> specialAffiliations = BSF_Utilities.getActivePicklistValues('Opportunity', 'Special_Affiliations__c');

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id
                FROM Drive_Marketing_Programs__c
                WHERE Marketing_Program__r.Name IN :specialAffiliations
                AND Date_Removed__c <= TODAY
                AND Blood_Drive_Opportunity__r.Is_Template__c = false
                AND Blood_Drive_Opportunity__r.Type_of_Drive__c = :BSF_Constants.MOBILE_DRIVE
                AND Blood_Drive_Opportunity__r.StageName != :BSF_Constants.STAGE_CANCELLED
                ORDER BY Blood_Drive_Opportunity__c
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<Drive_Marketing_Programs__c> scope) {
        Map<Id, Drive_Marketing_Programs__c> driveAffiliationsMap = new Map<Id, Drive_Marketing_Programs__c>(scope);

        DriveMarketingProgramTriggerService.syncSpecialAffiliationsOnDrive(driveAffiliationsMap, null, 'Update');
    }

    public void finish(Database.BatchableContext bc) {}

}