public class skedOpportunityHandler extends skedTriggerHub {
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            captureDriveChangeRequests(this.context.newRecords, (Map<Id, Opportunity>)this.context.oldMap);
        }
    }

    /*********************************************************** Privated Methods ***********************************************************/
    private void captureDriveChangeRequests(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap) {
        Set<string> fieldsToCheck = getLogisticFields();
        
        List<Opportunity> recordsToUpdate = new List<Opportunity>();
        List<slwcDriveService.driveChangeRequestModel> requests = new List<slwcDriveService.driveChangeRequestModel>();
        for (Opportunity newRecord : newRecords) {
            if (newRecord.Is_Recursion_On__c == FALSE) {
                Opportunity oldData = oldMap.get(newRecord.Id);
                
                slwcDriveService.driveChangeRequestModel request = new slwcDriveService.driveChangeRequestModel();
                request.opportunityId = newRecord.Id;
                request.driveChangeRequestItems = new List<slwcDriveService.driveChangeRequestItemModel>();
                
                for (string fieldToCheck : fieldsToCheck) {
                    string newValue = Json.serialize(newRecord.get(fieldToCheck)).replace('"', '');
                    string oldValue = Json.serialize(oldData.get(fieldToCheck)).replace('"', '');
                    if (newValue != oldValue) {
                        slwcDriveService.driveChangeRequestItemModel item = new slwcDriveService.driveChangeRequestItemModel();
                        item.fieldApiName = fieldToCheck;
                        item.newValue = newValue;
                        item.oldValue = oldValue;
                        item.objectApiName = 'Opportunity';
                        if (fieldToCheck == 'X2RBC_Projected_Procedures__c') {
                            item.changeReason = newRecord.DoubleRedProceduresProjectedChangeReason__c;
                        }
                        if (fieldToCheck == 'Anticipated_Registered_Donors__c') {
                            item.changeReason = newRecord.AnticipatedRegisterDonorChangeReason__c;
                        }
                        if (fieldToCheck == 'WB_Projected_Procedures__c') {
                            item.changeReason = newRecord.WholeBloodProcedureProjectedChangeReason__c;
                        }
                        if (fieldToCheck == 'Slot_Generator__c') {
                            item.changeReason = newRecord.Slot_Generator_Change_Reason__c;
                        }
                        request.driveChangeRequestItems.add(item);
                    }
                }
                
                if (!request.driveChangeRequestItems.isEmpty()) {
                    requests.add(request);
                }
            }
            else {
                Opportunity recordToUpdate = new Opportunity(
                    Id = newRecord.Id,
                    Is_Recursion_On__c = FALSE
                );
                recordsToUpdate.add(recordToUpdate);
            }
        }
        
        if (!recordsToUpdate.isEmpty()) {
            skedHubBase.BypassUpdateTriggers = true;
            update recordsToUpdate;
            skedHubBase.BypassUpdateTriggers = false;
        }
        
        if (!requests.isEmpty()) {
            slwcDriveService.captureUserChangeDriveChangeRequests(requests);
        }
    }
    
    private Set<string> getLogisticFields() {
        Set<string> fieldsToCheck = new Set<string>();
        fieldsToCheck.add('Parent_Template_Id__c');
        fieldsToCheck.add('Drive_Date__c');
        fieldsToCheck.add('Start_Time__c');
        fieldsToCheck.add('End_Time__c');
        fieldsToCheck.add('Drive_Site__c');
        fieldsToCheck.add('Anticipated_Registered_Donors__c');
        fieldsToCheck.add('WB_Projected_Procedures__c');
        fieldsToCheck.add('X2RBC_Projected_Procedures__c');
        fieldsToCheck.add('Platelet_Projected_Procedures__c');
        fieldsToCheck.add('Plasma_Pheresis_Projected_Procedures__c');
        fieldsToCheck.add('Number_of_2RBC_Assets__c');
        fieldsToCheck.add('Number_of_Plasma_Assets__c');
        fieldsToCheck.add('Number_of_Platelet_Assets__c');
        fieldsToCheck.add('Slot_Generator__c');
        fieldsToCheck.add('APT_Required__c'); //HRP-13190
        fieldsToCheck.add('APT_Quantity__c'); //HRP-13190
        return fieldsToCheck;
    }
    
}