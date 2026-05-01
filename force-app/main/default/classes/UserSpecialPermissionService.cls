/**
 * Description: Service class to re-assign specific permission sets to users
 * defined in User_Special_Permission__mdt, ensuring they persist after
 * the automated wipe in userService.AssignResourcesToUser.
 */
public with sharing class UserSpecialPermissionService {

    public static void assignSpecialPermissions(Set<String> userIdsStrings) {
        if (userIdsStrings == null || userIdsStrings.isEmpty()) {
            return;
        }

        // Sanitize and split IDs in case they are concatenated with hyphens
        Set<Id> userIds = new Set<Id>();
        for (String idStr : userIdsStrings) {
            if (String.isBlank(idStr)) continue;

            if (idStr.contains('-')) {
                // Handle concatenated IDs like "ID1-ID2"
                for (String part : idStr.split('-')) {
                    try {
                        userIds.add((Id)part);
                    } catch (Exception e) {
                        System.debug('Malformed ID encountered: ' + part);
                    }
                }
            } else {
                try {
                    userIds.add((Id)idStr);
                } catch (Exception e) {
                    System.debug('Malformed ID encountered: ' + idStr);
                }
            }
        }

        if (userIds.isEmpty()) return;

        // 1. Get Usernames for the provided User IDs
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Username
            FROM User
            WHERE Id IN :userIds
        ]);

        Set<String> usernames = new Set<String>();
        for (User u : userMap.values()) {
            usernames.add(u.Username);
        }

        // 2. Fetch active mappings from Custom Metadata
        List<User_Special_Permission__mdt> specialPermissions = [
            SELECT User_Username__c, Permission_Set_Name__c
            FROM User_Special_Permission__mdt
            WHERE User_Username__c IN :usernames
            AND Active__c = true
        ];

        if (specialPermissions.isEmpty()) {
            return;
        }

        // 3. Resolve Permission Set names to IDs
        Set<String> psNames = new Set<String>();
        for (User_Special_Permission__mdt mdt : specialPermissions) {
            psNames.add(mdt.Permission_Set_Name__c);
        }

        Map<String, Id> psNameToIdMap = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :psNames]) {
            psNameToIdMap.put(ps.Name, ps.Id);
        }

        // 4. Determine which assignments are actually needed
        List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();

        // To avoid duplicates, fetch currently assigned permission sets for these users
        Set<String> existingAssignmentsKey = new Set<String>();
        for (PermissionSetAssignment psa : [
            SELECT AssigneeId, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds
        ]) {
            // Use a composite key to uniquely identify existing assignments
            existingAssignmentsKey.add(psa.AssigneeId + '-' + psa.PermissionSetId);
        }

        for (User_Special_Permission__mdt mdt : specialPermissions) {
            Id userId = null;
            // Find the ID associated with this username
            for (User u : userMap.values()) {
                if (u.Username == mdt.User_Username__c) {
                    userId = u.Id;
                    break;
                }
            }

            Id psId = psNameToIdMap.get(mdt.Permission_Set_Name__c);

            if (userId != null && psId != null) {
                String key = userId + '-' + psId;
                if (!existingAssignmentsKey.contains(key)) {
                    assignmentsToInsert.add(new PermissionSetAssignment(
                        AssigneeId = userId,
                        PermissionSetId = psId
                    ));
                }
            }
        }

        // 5. Insert missing assignments
        if (!assignmentsToInsert.isEmpty()) {
            Database.insert(assignmentsToInsert, false);
        }
    }
}