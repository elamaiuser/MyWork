public class skedResourceRoleGroupHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        validate(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        validate(this.context.newRecords, (Map<Id, sked_Resource_Role_Group__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void validate(List<sked_Resource_Role_Group__c> newRecords, Map<Id, sked_Resource_Role_Group__c> oldMap) {
        List<sked_Resource_Role_Group__c> recordsToValidate = new List<sked_Resource_Role_Group__c>();
        for (sked_Resource_Role_Group__c newRecord : newRecords) {
            sked_Resource_Role_Group__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Resource_Roles__c != oldData.sked_Resource_Roles__c) {
                recordsToValidate.add(newRecord);
            }
        }
        if (!recordsToValidate.isEmpty()) {
            validate(recordsToValidate);
        }
    }
    
    private void validate(List<sked_Resource_Role_Group__c> newRecords) {
        Set<Id> newRecordIds = new Set<Id>();
        for (sked_Resource_Role_Group__c newRecord : newRecords) {
            newRecordIds.add(newRecord.Id);
        }
        List<sked_Resource_Role_Group__c> existingRecords = [SELECT Id, sked_Resource_Roles__c 
                                                             FROM sked_Resource_Role_Group__c
                                                             WHERE Id != :newRecordIds];
            
        if (!existingRecords.isEmpty()) {
            for (integer i = 0; i < newRecords.size(); i++) {
                sked_Resource_Role_Group__c newRecord = newRecords.get(i);
                Set<string> usedRoles = new Set<string>();
                
                for (integer j = 0; j < newRecords.size(); j++) {
                    if (i != j) {
                    	sked_Resource_Role_Group__c recordToCheck = newRecords.get(j);
                        if (recordToCheck.sked_Resource_Roles__c != NULL) {
                            List<string> roles = recordToCheck.sked_Resource_Roles__c.split(';');
                            usedRoles.addAll(roles);
                        }
                    }
                }
                
                for (sked_Resource_Role_Group__c recordToCheck : existingRecords) {
                    if (newRecord.Id != recordToCheck.Id) {
                        if (recordToCheck.sked_Resource_Roles__c != NULL) {
                            List<string> roles = recordToCheck.sked_Resource_Roles__c.split(';');
                            usedRoles.addAll(roles);
                        }
                    }
                }
                if (newRecord.sked_Resource_Roles__c != NULL) {
                    List<string> roles = newRecord.sked_Resource_Roles__c.split(';');
                    boolean isAnyRoleUsed = FALSE;
                    for (string role : roles) {
                        if (usedRoles.contains(role)) {
                            isAnyRoleUsed = TRUE;
                            break;
                        }
                    }
                    if (isAnyRoleUsed) {
                        newRecord.addError('A Role can only be associated to 1 Resource Role Group record.');
                    }
                }
            }
        }
    }

}