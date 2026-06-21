public class UserProvisioningService {
    public static final String TYPE_PS      = 'Permission Set';
    public static final String TYPE_PG      = 'Public Group';
    public static final String TYPE_ROLE    = 'Role';
    public static final String TYPE_LICENSE = 'Package License';
    public static final String TYPE_UT      = 'User Type';

    private static final AssignmentConfig PS_CONFIG = new AssignmentConfig(
        TYPE_PS, 'PermissionSet', 'Name', 'PermissionSetAssignment', 'AssigneeId', 'PermissionSetId',
        'IsOwnedByProfile = false', 'PermissionSet.IsOwnedByProfile = false'
    );
    
    private static final AssignmentConfig PG_CONFIG = new AssignmentConfig(
        TYPE_PG, 'Group', 'DeveloperName', 'GroupMember', 'UserOrGroupId', 'GroupId',
        'Type = \'Regular\'', null
    );
    
    private static final AssignmentConfig LIC_CONFIG = new AssignmentConfig(
        TYPE_LICENSE, 'PackageLicense', 'NamespacePrefix', 'UserPackageLicense', 'UserId', 'PackageLicenseId',
        null, null
    );

    public class ProvisioningRequest {
        public String  userId;
        public String  newProfileName;
        public String  oldProfileName; 
        public Boolean skipRoleUpdate = false;
    }

    private class AssignmentConfig {
        public String typeName, targetObj, targetLookupField, junctionObj, junctionUserField, junctionTargetField, targetFilter, junctionFilter;

        public AssignmentConfig(String typeName, String targetObj, String targetLookupField, String junctionObj, 
                                String junctionUserField, String junctionTargetField, String targetFilter, String junctionFilter) {
            this.typeName            = typeName;
            this.targetObj           = targetObj;
            this.targetLookupField   = targetLookupField;
            this.junctionObj         = junctionObj;
            this.junctionUserField   = junctionUserField;
            this.junctionTargetField = junctionTargetField;
            this.targetFilter        = String.isNotBlank(targetFilter) ? ' AND ' + targetFilter : '';
            this.junctionFilter      = String.isNotBlank(junctionFilter) ? ' AND ' + junctionFilter : '';
        }
    }

    public static void syncUserProvisioningBulk(List<ProvisioningRequest> requests) {
        if (requests == null || requests.isEmpty()) return;

        Set<String> allProfileNames = new Set<String>();
        Set<Id>     allUserIds      = new Set<Id>();

        for (ProvisioningRequest req : requests) {
            if (String.isNotBlank(req.newProfileName)) allProfileNames.add(req.newProfileName);
            if (String.isNotBlank(req.oldProfileName)) allProfileNames.add(req.oldProfileName);
            if (String.isNotBlank(req.userId))         allUserIds.add((Id) req.userId);
        }

        Map<String, List<Assign_SF_Resources_to_User__mdt>> profileToMDT = loadMetadata(allProfileNames);

        syncJunctionRecordsBulk(requests, profileToMDT, allUserIds, PS_CONFIG);
        syncJunctionRecordsBulk(requests, profileToMDT, allUserIds, PG_CONFIG);
        syncJunctionRecordsBulk(requests, profileToMDT, allUserIds, LIC_CONFIG);

        Map<Id, User> userFieldUpdates = new Map<Id, User>();
        syncUserFieldsBulk(requests, profileToMDT, userFieldUpdates);

        if (!userFieldUpdates.isEmpty()) {
            update userFieldUpdates.values();
        }
    }

    private static void syncJunctionRecordsBulk(
            List<ProvisioningRequest>                           requests,
            Map<String, List<Assign_SF_Resources_to_User__mdt>> profileToMDT,
            Set<Id>                                             allUserIds,
            AssignmentConfig                                    config) {

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
        for (SObject target : Database.query(targetQuery)) {
            identifierToTargetId.put((String)target.get(config.targetLookupField), target.Id);
        }

        String junctionQuery = String.format('SELECT Id, {0}, {1} FROM {2} WHERE {0} IN :allUserIds {3}', 
            new List<String>{ config.junctionUserField, config.junctionTargetField, config.junctionObj, config.junctionFilter });
        
        Map<Id, Map<Id, Id>> currentAssignments = new Map<Id, Map<Id, Id>>();
        for (Id uid : allUserIds) currentAssignments.put(uid, new Map<Id, Id>());

        for (SObject junction : Database.query(junctionQuery)) {
            Id uid = (Id) junction.get(config.junctionUserField);
            Id tid = (Id) junction.get(config.junctionTargetField);
            currentAssignments.get(uid).put(tid, junction.Id);
        }

        List<SObject> toInsert     = new List<SObject>();
        List<Id>      idsToDelete  = new List<Id>();
        Type          junctionType = Type.forName(config.junctionObj);

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
                        idsToDelete.add(currentForUser.get(targetId));
                    }
                }
            }

            for (String newName : newNames) {
                Id targetId = identifierToTargetId.get(newName);
                if (targetId != null && !currentForUser.containsKey(targetId)) {
                    SObject newObj = (SObject) junctionType.newInstance();
                    newObj.put(config.junctionUserField, userId);
                    newObj.put(config.junctionTargetField, targetId);
                    toInsert.add(newObj);
                }
            }
        }

        if (!idsToDelete.isEmpty()) Database.delete(idsToDelete, false);
        if (!toInsert.isEmpty())    Database.insert(toInsert, false);
    }

    private static void syncUserFieldsBulk(
            List<ProvisioningRequest>                           requests,
            Map<String, List<Assign_SF_Resources_to_User__mdt>> profileToMDT,
            Map<Id, User>                                       userFieldUpdates) {

        Set<String> roleDevNames = new Set<String>();
        for (ProvisioningRequest req : requests) {
            if (!req.skipRoleUpdate) {
                roleDevNames.addAll(extractValues(profileToMDT.get(req.newProfileName), TYPE_ROLE));
            }
        }

        Map<String, Id> roleDevNameToId = new Map<String, Id>();
        if (!roleDevNames.isEmpty()) {
            for (UserRole r : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :roleDevNames]) {
                roleDevNameToId.put(r.DeveloperName, r.Id);
            }
        }

        for (ProvisioningRequest req : requests) {
            Id uid = (Id) req.userId;
            User userUpdate = userFieldUpdates.containsKey(uid) ? userFieldUpdates.get(uid) : new User(Id = uid);
            Boolean isUpdated = false;

            if (!req.skipRoleUpdate) {
                Set<String> roles = extractValues(profileToMDT.get(req.newProfileName), TYPE_ROLE);
                if (!roles.isEmpty()) {
                    String roleName = new List<String>(roles)[0];
                    if (roleDevNameToId.containsKey(roleName)) {
                        userUpdate.UserRoleId = roleDevNameToId.get(roleName);
                        isUpdated = true;
                    }
                }
            }

            Set<String> userTypes = extractValues(profileToMDT.get(req.newProfileName), TYPE_UT);
            if (!userTypes.isEmpty()) {
                userUpdate.sked__skeduloUserType__c = String.join(new List<String>(userTypes), ';');
                isUpdated = true;
            }

            if (isUpdated) {
                userFieldUpdates.put(uid, userUpdate);
            }
        }
    }

    private static Map<String, List<Assign_SF_Resources_to_User__mdt>> loadMetadata(Set<String> profileNames) {
        Map<String, List<Assign_SF_Resources_to_User__mdt>> result = new Map<String, List<Assign_SF_Resources_to_User__mdt>>();
        for (String pName : profileNames) {
            result.put(pName, new List<Assign_SF_Resources_to_User__mdt>());
        }

        for (Assign_SF_Resources_to_User__mdt mdt : [
            SELECT DeveloperName, Assignment_Type__c, Permission_Set_Name__c, Public_Group_Name__c,
                   Role_Name__c, Package_License_Name__c, User_Type_Name__c, Profile_Name__c
            FROM   Assign_SF_Resources_to_User__mdt
            WHERE  Profile_Name__c IN :profileNames
            AND    Active__c = true
        ]) {
            result.get(mdt.Profile_Name__c).add(mdt);
        }
        return result;
    }

    private static Set<String> extractValues(List<Assign_SF_Resources_to_User__mdt> mdtList, String assignmentType) {
        Set<String> result = new Set<String>();
        if (mdtList == null) return result;

        for (Assign_SF_Resources_to_User__mdt mdt : mdtList) {
            if (mdt.Assignment_Type__c != assignmentType) continue;

            String val;
            switch on assignmentType {
                when 'Permission Set'  { val = mdt.Permission_Set_Name__c; }
                when 'Public Group'    { val = mdt.Public_Group_Name__c; }
                when 'Role'            { val = mdt.Role_Name__c; }
                when 'Package License' { val = mdt.Package_License_Name__c; }
                when 'User Type'       { val = mdt.User_Type_Name__c; }
            }

            if (String.isNotBlank(val)) result.add(val);
        }
        return result;
    }
}