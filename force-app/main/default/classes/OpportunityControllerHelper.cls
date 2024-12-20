public with sharing class OpportunityControllerHelper {

    @AuraEnabled(cacheable=true)
    public static Opportunity fetchOpportunityFromDriveChangeRequest(Id dcrId) {
        System.debug('fetchOpportunityFromDriveChangeRequest dcrId:'+dcrId);
        // Validate input
        if (dcrId == null) {
            throw new AuraHandledException('Invalid input: Drive Change Request ID is null.');
        }
        // Query sked_Drive_Change_Request__c with related fields
        sked_Drive_Change_Request__c dcrRecord = [
            SELECT sked_Opportunity__c, sked_Drive__c 
            FROM sked_Drive_Change_Request__c
            WHERE Id = :dcrId
            LIMIT 1
        ];
        System.debug('dcrRecord:'+dcrRecord);
        // Check if Opportunity exists on sked_Drive_Change_Request__c
        if (dcrRecord.sked_Opportunity__c != null) {
            // Return the Opportunity record directly
            return [
                SELECT Id, Name, Pending_ARD_Confirmation__c
                FROM Opportunity
                WHERE Id = :dcrRecord.sked_Opportunity__c
                LIMIT 1
            ];
        } 

        // If sked_Opportunity__c is null, check sked_Drive__c for Opportunity
        if (dcrRecord.sked_Drive__c != null) {
            sked_Drive__c driveRecord = [
                SELECT sked_Opportunity__c
                FROM sked_Drive__c
                WHERE Id = :dcrRecord.sked_Drive__c
                LIMIT 1
            ];
            System.debug('driveRecord:'+driveRecord);
            if (driveRecord.sked_Opportunity__c != null) {
                // Return Opportunity from sked_Drive__c
                return [
                    SELECT Id, Name, Pending_ARD_Confirmation__c
                    FROM Opportunity
                    WHERE Id = :driveRecord.sked_Opportunity__c
                    LIMIT 1
                ];
            }
        }
        // If no Opportunity found, return null
        return null;
    }
    
}