global class slwcUserService {
    
    @AuraEnabled
    public static slwcAuraResult getLoginUser() {
        slwcAuraResult result = new slwcAuraResult();
        
        User loginUser = [SELECT Id, Name, Profile.Name
                          FROM User
                          WHERE Id = :UserInfo.getUserId()];
        userModel model = new userModel();
        model.id = loginUser.Id;
        model.name = loginUser.Name;
        model.profileName = NULL;
        if (loginUser.Profile != NULL) {
            model.profileName = loginUser.Profile.Name;
        }
        model.slotPermission = new objectPermissionModel();
        model.slotPermission.isCreateable = Schema.sObjectType.sked__Slot__c.isCreateable();
        model.slotPermission.isUpdateable = Schema.sObjectType.sked__Slot__c.isUpdateable();
        model.slotPermission.isDeletable = Schema.sObjectType.sked__Slot__c.isDeletable();
        
        model.approvalPermission = new approvalPermissionModel();
        model.approvalPermission.driveChangeRequest = FALSE;
        model.approvalPermission.driveShiftTradeRequest = FALSE;
        model.approvalPermission.pendingActionDrive = FALSE;
        model.approvalPermission.roleTimeVariance = FALSE;
        
        List<sked_Profile_Approval_Queue_Access__mdt> approvalQueueAccessSettings 
            = [SELECT Id, sked_Drive_Change_Request__c, sked_Drive_Shift_Trade_Request__c,
               sked_Pending_Action__c, sked_Role_Time_Variance__c
               FROM sked_Profile_Approval_Queue_Access__mdt
               WHERE MasterLabel = :model.profileName];
        if (!approvalQueueAccessSettings.isEmpty()) {
            sked_Profile_Approval_Queue_Access__mdt approvalQueueAccessSetting = approvalQueueAccessSettings.get(0);
            model.approvalPermission.driveChangeRequest = approvalQueueAccessSetting.sked_Drive_Change_Request__c;
            model.approvalPermission.driveShiftTradeRequest = approvalQueueAccessSetting.sked_Drive_Shift_Trade_Request__c;
            model.approvalPermission.pendingActionDrive = approvalQueueAccessSetting.sked_Pending_Action__c;
            model.approvalPermission.roleTimeVariance = approvalQueueAccessSetting.sked_Role_Time_Variance__c;
        }
        
        if (model.profileName.toLowerCase().startsWith('drd')) {
            model.approvalPermission.driveChangeRequest = TRUE;
            model.approvalPermission.pendingActionDrive = TRUE;
        }
        
        result.returnedData = model;
        return result;
    }
    
    /* Nest classes */
    public class userModel {
        @AuraEnabled public string id {get; set;}
        @AuraEnabled public string name {get; set;}
        @AuraEnabled public string profileName {get; set;}
        @AuraEnabled public objectPermissionModel slotPermission {get; set;}
        @AuraEnabled public approvalPermissionModel approvalPermission {get; set;}
    }
    
    public class objectPermissionModel {
        @AuraEnabled public boolean isCreateable {get; set;}
        @AuraEnabled public boolean isUpdateable {get; set;}
        @AuraEnabled public boolean isDeletable {get; set;}
    }
    
    public class approvalPermissionModel {
        @AuraEnabled public boolean driveChangeRequest {get; set;}
        @AuraEnabled public boolean driveShiftTradeRequest {get; set;}
        @AuraEnabled public boolean pendingActionDrive {get; set;}
        @AuraEnabled public boolean roleTimeVariance {get; set;}
    }

}