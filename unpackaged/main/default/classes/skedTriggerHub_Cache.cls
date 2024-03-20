public class skedTriggerHub_Cache {
    
    private static User mLoginUser;
    public static User loginUser {
        get {
            if (mLoginUser == NULL) {
                mLoginUser = [SELECT Id, Name, ProfileId, Profile.Name, alias
                              FROM User
                              WHERE Id = :UserInfo.getUserId()];
            }
            return mLoginUser;
        }
    }
    
    private static boolean mIsAdminUser;
    public static boolean isAdminUser {
        get {
            if (mIsAdminUser == NULL) {
                List<string> systemAdminProfiles = new List<string>();
                systemAdminProfiles.add('Global Admin');
                systemAdminProfiles.add('System Administrator');
                string userProfile = skedTriggerHub_Cache.loginUser.Profile.Name;
                
                mIsAdminUser = systemAdminProfiles.contains(userProfile);
            }
            return mIsAdminUser;
        }
    }
    
    @testVisible
    private static void setIsAdminUser(boolean value) {
        mIsAdminUser = value;
    }
    
    private static User autoProcessUser;
    public static User getAutoProcessUserFromCache() {
        if (autoProcessUser == null) {
            autoProcessUser = [SELECT Id FROM User WHERE alias = 'autoproc'];
        }

        return autoProcessUser;
    }

    private static sked__Resource__c currentUserResource;
    public static sked__Resource__c getCurrentUserResource() {
        if (currentUserResource == null) {
            currentUserResource = [
                SELECT Id, sked_Employee_Id__c, sked__Email__c
                FROM sked__Resource__c
                WHERE sked__User__c = :UserInfo.getUserId()
                AND sked__Is_Active__c = TRUE
                LIMIT 1
            ];
        }

        return currentUserResource;
    }

    private static Map<Id, List<PermissionSetAssignment>> permissionSetAssignmentsByUserId;
    public static List<PermissionSetAssignment> getPermissionSetsForUser(Id userId) {
        if (permissionSetAssignmentsByUserId == null) {
            permissionSetAssignmentsByUserId = new Map<Id, List<PermissionSetAssignment>>();
        }

        if (!permissionSetAssignmentsByUserId.containsKey(userId)) {
            List<PermissionSetAssignment> psasForUser = [
                SELECT Id, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND isActive = TRUE
            ];

            permissionSetAssignmentsByUserId.put(userId, psasForUser);
        }

        return permissionSetAssignmentsByUserId.get(userId);
    }

    private static Map<Id, Profile> profileById;
    public static Profile getProfileForId(String profileId) {
        if (profileById == null) {
            profileById = new Map<Id, Profile>([SELECT Id, Name FROM Profile]);
        }

        return profileById.get(profileId);
    }
}