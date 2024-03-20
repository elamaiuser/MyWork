public class skedAccountHandler extends skedTriggerHub {

    public override void onAfterUpdate() {
        onAccountClosed(this.context.newRecords, (Map<Id, Account>)this.context.oldMap);
        onAPTRequiredChanged(this.context.newRecords, (Map<Id, Account>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onAccountClosed(List<Account> newRecords, Map<Id, Account> oldMap) {
        Map<Id, Account> mapClosedAccount = new Map<Id, Account>();
        for (Account newRecord : newRecords) {
            Account oldData = oldMap.get(newRecord.Id);
            if (newRecord.Account_Status__c != oldData.Account_Status__c && newRecord.Account_Status__c == 'Closed') {
                mapClosedAccount.put(newRecord.Id, newRecord);
            }
        }
        if (!mapClosedAccount.isEmpty()) {
            List<sked_Drive__c> impactedDrives = [SELECT Id, sked_Account__c, sked_Status__c
                                                  FROM sked_Drive__c
                                                  WHERE sked_Account__c IN :mapClosedAccount.keySet()
                                                  AND sked_Drive_Date__c >= TODAY
                                                  AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL];
            if (!impactedDrives.isEmpty()) {
                for (sked_Drive__c impactedDrive : impactedDrives) {
                    impactedDrive.sked_Status__c = skedConstants.DRIVE_STATUS_CANCEL;
                }
                update impactedDrives;
            }
        }
    }
    
    private void onAPTRequiredChanged(List<Account> newRecords, Map<Id, Account> oldMap) {
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        for (Account newRecord : newRecords) {
            Account oldData = oldMap.get(newRecord.Id);
            if (newRecord.APT_Required__c != oldData.APT_Required__c) {
                mapAccount.put(newRecord.Id, newRecord);
            }
        }
        if (!mapAccount.isEmpty()) {
            List<sked_Drive__c> impactedDrives = [SELECT Id, sked_Account__c, sked_Opportunity__c, sked_APT_Required__c
                                                  FROM sked_Drive__c
                                                  WHERE sked_Account__c IN :mapAccount.keySet()
                                                  AND sked_Drive_Date__c >= TODAY
                                                  AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL];
            if (!impactedDrives.isEmpty()) {
                List<slwcDriveService.driveChangeRequestModel> requests = new List<slwcDriveService.driveChangeRequestModel>();
                for (sked_Drive__c impactedDrive : impactedDrives) {
                    Account skedAccount = mapAccount.get(impactedDrive.sked_Account__c);
                    if (impactedDrive.sked_APT_Required__c != skedAccount.APT_Required__c) {
                        slwcDriveService.driveChangeRequestModel request = new slwcDriveService.driveChangeRequestModel();
                        request.opportunityId = impactedDrive.sked_Opportunity__c;
                        request.driveChangeRequestItems = new List<slwcDriveService.driveChangeRequestItemModel>();
                        
                        string newValue = Json.serialize(skedAccount.APT_Required__c).replace('"', '');
                        string oldValue = Json.serialize(impactedDrive.sked_APT_Required__c).replace('"', '');
                        
                        slwcDriveService.driveChangeRequestItemModel item = new slwcDriveService.driveChangeRequestItemModel();
                        item.fieldApiName = 'sked_APT_Required__c';
                        item.newValue = newValue;
                        item.oldValue = oldValue;
                        item.objectApiName = 'sked_Drive__c';
                        request.driveChangeRequestItems.add(item);
                        
                        requests.add(request);
                    }
                }
                if (!requests.isEmpty()) {
                    slwcDriveService.captureDriveChangeRequests(requests);
                }
            }
        }
    }
    
}