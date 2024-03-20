public class skedDriveChangeRequestUtils {
    
    public static Map<Id, sked_Drive_Change_Request__c> GetPendingDCRByDriveId(Set<Id> driveIds, List<String> dcriFieldApiNames) {
        Map<Id, sked_Drive_Change_Request__c> dcrByDriveId = new Map<Id, sked_Drive_Change_Request__c>();

        Set<String> pendingDCRStatuses = new Set<String>{
            skedConstants.DRIVE_CHANGE_REQUEST_STATUS_PENDING,
            skedConstants.DRIVE_CHANGE_REQUEST_STATUS_SUBMITTED
        };

        List<sked_Drive_Change_Request__c> dcrs = [
            SELECT Id, sked_Drive__c, sked_Status__c, sked_Type__c,
                (SELECT Id FROM sked_Drive_Change_Request_Items__r
                WHERE sked_Field_API_Name__c IN :dcriFieldApiNames)
            FROM sked_Drive_Change_Request__c
            WHERE sked_Drive__c IN :driveIds
            AND sked_Status__c IN :pendingDCRStatuses
        ];

        if (dcrs != null && !dcrs.isEmpty()) {
            for (sked_Drive_Change_Request__c dcr : dcrs) {
                dcrByDriveId.put(dcr.sked_Drive__c, dcr);
            }
        }

        return dcrByDriveId;
    }
    
}