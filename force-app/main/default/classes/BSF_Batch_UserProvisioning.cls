public without sharing class BSF_Batch_UserProvisioning implements Database.Batchable<sObject>, Schedulable {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BSF_Batch_UserProvisioning(), 200); 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> profileNames = getProfileNames();
        Integer queryLimit = Test.isRunningTest() ? 200 : 50000000;
        return Database.getQueryLocator([
            SELECT Id, 
            ProfileId,
            Profile.Name 
            FROM User 
            WHERE IsActive = true
            AND Bypass_Auto_Provisioning__c = false
            AND Profile.Name IN :profileNames
            LIMIT :queryLimit
        ]);
    }

    public void execute(Database.BatchableContext bc, List<User> scope) {
        List<UserProvisioningService.ProvisioningRequest> requests = new List<UserProvisioningService.ProvisioningRequest>();
        
        for (User u : scope) {
            UserProvisioningService.ProvisioningRequest req = new UserProvisioningService.ProvisioningRequest();
            req.userId = u.Id;
            req.newProfileName = u.Profile.Name;
            req.oldProfileName = '';
            req.skipRoleUpdate = true; 
            requests.add(req);
        }
        
        if (!requests.isEmpty()) {
            UserProvisioningService.syncUserProvisioningBulk(requests);
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public static Set<String> getProfileNames() {
        Set<String> profileNames = new Set<String>();
        for (Assign_SF_Resources_to_User__mdt mdt : [SELECT Profile_Name__c 
                                                    FROM Assign_SF_Resources_to_User__mdt 
                                                    WHERE Profile_Name__c != NULL
                                                    AND Active__c = true WITH SYSTEM_MODE]) {
            profileNames.add(mdt.Profile_Name__c.trim());
        }
        return profileNames;
    }
}