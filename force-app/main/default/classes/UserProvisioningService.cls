public without sharing class UserProvisioningService {
    public class ProvisioningRequest {
        public String  userId;
        public String  newProfileName;
        public String  oldProfileName; 
        public Boolean skipRoleUpdate = false;
    }

    public static void syncUserProvisioningBulk(List<ProvisioningRequest> requests) {
        if (requests == null || requests.isEmpty()) return;

        List<String> allProfileNames = new List<String>();
        Set<Id>      allUserIds      = new Set<Id>();

        for (ProvisioningRequest req : requests) {
            if (String.isNotBlank(req.newProfileName)) allProfileNames.add(req.newProfileName);
            if (String.isNotBlank(req.oldProfileName)) allProfileNames.add(req.oldProfileName);
            if (String.isNotBlank(req.userId))         allUserIds.add((Id) req.userId);
        }

        Map<String, Map<String, List<Assign_SF_Resources_to_User__mdt>>> profileToMDT = loadMetadata(allProfileNames);

        List<SObject> allJunctionsToInsert = new List<SObject>();
        List<SObject> allJunctionsToDelete = new List<SObject>();
        Map<Id, User> userFieldUpdates     = new Map<Id, User>();

        syncJunctionRecordsBulk(requests, profileToMDT, allUserIds, BSF_Constants.PS_CONFIG, allJunctionsToInsert, allJunctionsToDelete);
        syncJunctionRecordsBulk(requests, profileToMDT, allUserIds, BSF_Constants.PG_CONFIG, allJunctionsToInsert, allJunctionsToDelete);
        syncJunctionRecordsBulk(requests, profileToMDT, allUserIds, BSF_Constants.QUEUE_CONFIG, allJunctionsToInsert, allJunctionsToDelete);
        
        if (!String.isEmpty(Label.AssignUserLicenses) && Label.AssignUserLicenses == 'Yes') {
            syncJunctionRecordsBulk(requests, profileToMDT, allUserIds, BSF_Constants.LIC_CONFIG, allJunctionsToInsert, allJunctionsToDelete);
        }

        syncUserFieldsBulk(requests, profileToMDT, userFieldUpdates);

        executeFinalDML(allJunctionsToDelete, allJunctionsToInsert, userFieldUpdates.values());
    }

    private static void syncJunctionRecordsBulk(
            List<ProvisioningRequest>                                        requests,
            Map<String, Map<String, List<Assign_SF_Resources_to_User__mdt>>> profileToMDT,
            Set<Id>                                                          allUserIds,
            UserAssignmentTypeConfig                                          config,
            List<SObject>                                                    toInsertAcc,
            List<SObject>                                                    toDeleteAcc) {

        Set<String> allIdentifiers = new Set<String>();
        for (ProvisioningRequest req : requests) {
            allIdentifiers.addAll(extractValues(profileToMDT.get(req.newProfileName), config.typeName));
            if (String.isNotBlank(req.oldProfileName)) {
                allIdentifiers.addAll(extractValues(profileToMDT.get(req.oldProfileName), config.typeName));
            }
        }
        if (allIdentifiers.isEmpty()) return;

        String targetQuery = String.format('SELECT Id, {0} FROM {1} WHERE {0} IN :allIdentifiers {2}', 
            new List<String>{ config.targetLookupField, config.targetObj, config.targetFilter });
        
        Map<String, Id> identifierToTargetId = new Map<String, Id>();
        for (SObject target : Database.query(targetQuery,AccessLevel.SYSTEM_MODE)) {
            identifierToTargetId.put((String)target.get(config.targetLookupField), target.Id);
        }

        String junctionQuery = String.format('SELECT Id, {0}, {1} FROM {2} WHERE {0} IN :allUserIds {3}', 
            new List<String>{ config.junctionUserField, config.junctionTargetField, config.junctionObj, config.junctionFilter });
        
        Map<Id, Map<Id, Id>> currentAssignments = new Map<Id, Map<Id, Id>>();
        for (Id uid : allUserIds) currentAssignments.put(uid, new Map<Id, Id>());

        for (SObject junction : Database.query(junctionQuery,AccessLevel.SYSTEM_MODE)) {
            Id uid = (Id) junction.get(config.junctionUserField);
            Id tid = (Id) junction.get(config.junctionTargetField);
            currentAssignments.get(uid).put(tid, junction.Id);
        }

        Type junctionType = Type.forName(config.junctionObj);

        for (ProvisioningRequest req : requests) {
            Id userId = (Id) req.userId;
            Set<String> newNames = extractValues(profileToMDT.get(req.newProfileName), config.typeName);
            Set<String> oldNames = String.isNotBlank(req.oldProfileName)
                ? extractValues(profileToMDT.get(req.oldProfileName), config.typeName)
                : new Set<String>();

            Map<Id, Id> currentForUser = currentAssignments.get(userId);

            for (String oldName : oldNames) {
                if (!newNames.contains(oldName)) {
                    Id targetId = identifierToTargetId.get(oldName);
                    if (targetId != null && currentForUser.containsKey(targetId)) {
                        Id recordIdToDelete = currentForUser.get(targetId);
                        SObject stub = recordIdToDelete.getSObjectType().newSObject(recordIdToDelete);
                        toDeleteAcc.add(stub);
                    }
                }
            }

            for (String newName : newNames) {
                Id targetId = identifierToTargetId.get(newName);
                if (targetId != null && !currentForUser.containsKey(targetId)) {
                    SObject newObj = (SObject) junctionType.newInstance();
                    newObj.put(config.junctionUserField, userId);
                    newObj.put(config.junctionTargetField, targetId);
                    toInsertAcc.add(newObj);
                }
            }
        }
    }

    private static void syncUserFieldsBulk(
            List<ProvisioningRequest>                                        requests,
            Map<String, Map<String, List<Assign_SF_Resources_to_User__mdt>>> profileToMDT,
            Map<Id, User>                                                    userFieldUpdates) {

        Set<Id> userIds = new Set<Id>();
        for (ProvisioningRequest req : requests) {
            userIds.add((Id)req.userId);
        }

        Map<Id, User> existingUsers = new Map<Id, User>([
            SELECT Id, UserRoleId, sked__skeduloUserType__c 
            FROM User 
            WHERE Id IN :userIds WITH SYSTEM_MODE
        ]);

        Set<String> roleDevNames = new Set<String>();
        for (ProvisioningRequest req : requests) {
            if (!req.skipRoleUpdate) {
                roleDevNames.addAll(extractValues(profileToMDT.get(req.newProfileName), BSF_Constants.TYPE_ROLE));
            }
        }

        Map<String, Id> roleDevNameToId = new Map<String, Id>();
        if (!roleDevNames.isEmpty()) {
            for (UserRole r : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :roleDevNames WITH SYSTEM_MODE]) {
                roleDevNameToId.put(r.DeveloperName, r.Id);
            }
        }

        for (ProvisioningRequest req : requests) {
            Id uid = (Id) req.userId;
            User existingUser = existingUsers.get(uid);
            if (existingUser == null) continue;

            User userUpdate = userFieldUpdates.containsKey(uid) ? userFieldUpdates.get(uid) : new User(Id = uid);
            Boolean isUpdated = false;

            if (!req.skipRoleUpdate) {
                Set<String> roles = extractValues(profileToMDT.get(req.newProfileName), BSF_Constants.TYPE_ROLE);
                if (!roles.isEmpty()) {
                    String roleName = new List<String>(roles)[0];
                    Id targetRoleId = roleDevNameToId.get(roleName);
                    
                    if (targetRoleId != null && existingUser.UserRoleId != targetRoleId) {
                        userUpdate.UserRoleId = targetRoleId;
                        isUpdated = true;
                    }
                }
            }

            Set<String> userTypes = extractValues(profileToMDT.get(req.newProfileName), BSF_Constants.TYPE_UT);
            if (!userTypes.isEmpty()) {
                Set<String> currentSet = new Set<String>();
                if (String.isNotBlank(existingUser.sked__skeduloUserType__c)) {
                    for (String val : existingUser.sked__skeduloUserType__c.split(';')) {
                        currentSet.add(val.trim());
                    }
                }
                
                if (!currentSet.equals(userTypes)) {
                    List<String> sortedUserTypes = new List<String>(userTypes);
                    sortedUserTypes.sort();
                    userUpdate.sked__skeduloUserType__c = String.join(sortedUserTypes, ';');
                    isUpdated = true;
                }
            }

            if (isUpdated) {
                userFieldUpdates.put(uid, userUpdate);
            }
        }
    }

    private static void executeFinalDML(List<SObject> toDelete, List<SObject> toInsert, List<User> toUpdate) {
        if (!toDelete.isEmpty()) {
            Database.DeleteResult[] drList = Database.delete(toDelete, false, AccessLevel.SYSTEM_MODE);
            UserProvisioningErrorHandler.handleDatabaseResults(drList, 'Delete Junction Records', 'syncUserProvisioningBulk');
        }
        
        if (!toInsert.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(toInsert, false, AccessLevel.SYSTEM_MODE);
            UserProvisioningErrorHandler.handleDatabaseResults(srList, 'Insert Junction Records', 'syncUserProvisioningBulk');
        }
        
        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update(toUpdate, false, AccessLevel.SYSTEM_MODE);
            UserProvisioningErrorHandler.handleDatabaseResults(srList, 'Update User Records', 'syncUserProvisioningBulk');
        }
    }

    private static Map<String, Map<String, List<Assign_SF_Resources_to_User__mdt>>> loadMetadata(List<String> profileNames) {
        Map<String, Map<String, List<Assign_SF_Resources_to_User__mdt>>> metadataMap = 
            new Map<String, Map<String, List<Assign_SF_Resources_to_User__mdt>>>();
        
        if (profileNames == null || profileNames.isEmpty()) return metadataMap;

        for (String pName : profileNames) {
            metadataMap.put(pName, new Map<String, List<Assign_SF_Resources_to_User__mdt>>());
        }

        for (Assign_SF_Resources_to_User__mdt mdt : [
            SELECT DeveloperName, Assignment_Type__c, Permission_Set_Name__c, Public_Group_Name__c,
                   Queue_Name__c, Role_Name__c, Package_License_Name__c, User_Type_Name__c, Profile_Name__c
            FROM   Assign_SF_Resources_to_User__mdt
            WHERE  Profile_Name__c IN :metadataMap.keySet()
            AND    Active__c = true  WITH SYSTEM_MODE
        ]) {
            if (!metadataMap.get(mdt.Profile_Name__c).containsKey(mdt.Assignment_Type__c)) {
                metadataMap.get(mdt.Profile_Name__c).put(mdt.Assignment_Type__c, new List<Assign_SF_Resources_to_User__mdt>());
            }
            metadataMap.get(mdt.Profile_Name__c).get(mdt.Assignment_Type__c).add(mdt);
        }
        
        return metadataMap;
    }

    private static Set<String> extractValues(Map<String, List<Assign_SF_Resources_to_User__mdt>> typeToMdtMap, String assignmentType) {
        Set<String> result = new Set<String>();
        if (typeToMdtMap == null || !typeToMdtMap.containsKey(assignmentType)) {
            return result;
        }
        
        String fieldApiName = BSF_Constants.TYPE_TO_MDT_FIELD.get(assignmentType);
        if (String.isBlank(fieldApiName)) return result;

        for (Assign_SF_Resources_to_User__mdt mdt : typeToMdtMap.get(assignmentType)) {
            String val = mdt.get(fieldApiName) != null ? String.valueOf(mdt.get(fieldApiName)) : null;
            if (String.isNotBlank(val)) {
                result.add(val);
            }
        }
        
        return result;
    }
    public static void handleEvents(List<AssignResourcesToUserEvent__e> events) {
        if (events == null || events.isEmpty()) return;

        List<ProvisioningRequest> requests = new List<ProvisioningRequest>();

        for (AssignResourcesToUserEvent__e evt : events) {
            if(String.isNotBlank(evt.UserId__c) && String.isNotBlank(evt.UserProfile__c) && String.isNotBlank(evt.Old_User_Profile__c)) {
                ProvisioningRequest req = new ProvisioningRequest();
                req.userId = evt.UserId__c;
                req.newProfileName = evt.UserProfile__c;
                req.oldProfileName = evt.Old_User_Profile__c;
                req.skipRoleUpdate = evt.skipUserRoleUpdate__c;
                requests.add(req);
            }
        }

        if (!requests.isEmpty()) {
            syncUserProvisioningBulk(requests);
        }
    }

    @AuraEnabled
    public static void syncUserMetadata(Id userId) {
        try {
            User u = [SELECT Id, Profile.Name FROM User WHERE Id = :userId WITH SYSTEM_MODE LIMIT 1];

            ProvisioningRequest req = new ProvisioningRequest();
            req.userId         = u.Id;
            req.newProfileName = u.Profile.Name;
            req.oldProfileName = u.Profile.Name;
            req.skipRoleUpdate = false;

            syncUserProvisioningBulk(
                new List<ProvisioningRequest>{ req }
            );
            
        } catch (Exception e) {
            throw new AuraHandledException('Provisioning Sync Failed: ' + e.getMessage());
        }
    }
}