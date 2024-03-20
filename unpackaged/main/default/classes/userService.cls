/* Description:
 * The purpose of the "PublishEventForAssigningResourcesToUsers" and "AssignResourcesToUser" methods is to asynchornously assign resources such as permission sets, public
 * groups, and sked user type to a user record when a user is created or updated in the system.  The configuration of this resource assignment is maintained in the
 * custom metadata type "Assign SF Resources to User".
 * 
 * The "PublishEventForAssigningResourcesToUsers" method is used to publish a list of users to the platform event (AssignResourcesToUserEvent__e) and it is invoked from
 * the afterUpdate method of userTriggerHandler. Once the platform event is published, the subscriber (a trigger called assignResourcesToUsersBasedOnConfig) will process
 * the message and calls the "AssignResourcesToUser" method which has the logic to perform the resource assignment.  
 * 
 * 
 * Modification Log 
 * 
 * Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 5/5/2023				Fitsum Worku			Logic for HRP-9982. Added logic to exclude the system admin profile from user type assignment/removal.  Also added support for
 * 												license assignment.
 * 
 * 
 *****************************************************************************************************************************************************************************
*/

public class userService {
    public static boolean runUser=true;
    public static void formatMobilePhone(List<User> UserList){
        system.debug('UserList'+UserList);
        if(UserList!=null && runUser==true){
            for(user u:UserList){
                if(u.MobilePhone!=null){
                    u.MobilePhone=u.MobilePhone.replaceAll('[()\\s-]+', '');
                }  
            }
        }
        //database.update(UserList);
    }
    
    //Publish the Platform event to assign resources to each user based on the 
    //custom metadata configuration
    public static void PublishEventForAssigningResourcesToUsers(List<User> usersLst) {
        
        List<AssignResourcesToUserEvent__e> asrEvents = new List<AssignResourcesToUserEvent__e>();
        system.debug('#### inside PublishEventForAssigningResourcesToUsers ' + usersLst.size());
        For(User u : usersLst) {
            AssignResourcesToUserEvent__e asrEvent = new AssignResourcesToUserEvent__e();
            asrEvent.UserId__c = u.Id;
            asrEvents.add(asrEvent);
        }
        if(asrEvents != null && asrEvents.size() > 0) {
            EventBus.publish(asrEvents);
            system.debug('### event for assigning user resource published');
        }
    }
    
    public static void AssignResourcesToUser(Set<Id> userIds) {
        
        system.debug('### Inside assign resources to user...start assigning' + userIds.size());
        
        List<String> userPermissionSetAssignmentList = new List<String>(); 
        List<String> userPublicGroupAssignmentList = new List<String>(); 
        List<String> userPackageLicenseAssignmentList = new List<String>();
        List<String> userTypeList = new List<String>();
        
        string userTypeAssignment = '';
        Map<Id, List<String>> userPermissionSetAssignmentMap = new Map<Id, List<String>>();
        Map<Id, List<String>> userPublicGroupAssignmentMap = new Map<Id, List<String>>();
        Map<Id, List<String>> userPackageLicenseAssignmentMap = new Map<Id, List<String>>();
        Map<Id, List<String>> userTypeAssignmentMap = new Map<Id, List<String>>();
        
        Map<String, Id> permissionSetNameToIdMap = new Map<String, Id>();
        Map<String, Id> publicGroupNameToIdMap = new Map<String, Id>();
        Map<String, Id> packageLicenseNameToIdMap = new Map<String, Id>();
        
   
            
        List<User> newUserList = [SELECT Id, Name, sked__skeduloUserType__c, IsActive, Profile.Name FROM User WHERE Id in:userIds];
        system.debug('### list of users ' + newUserList.size());
        
        //Get all user assignments from the Custom Metadata config
        List<Assign_SF_Resources_to_User__mdt> allUsersAssignmentsFromMdt = getAllUserAssignmentsFromMdt();
        
        //Get AssignUserLicenses flag from a custom label
        String customLabelInfo = Label.AssignUserLicenses;
        //system.debug('### customLabelInfo ' + customLabelInfo);
        
        if(!allUsersAssignmentsFromMdt.isEmpty()) {
            
            //Get all permission sets and create a map of permission set name => permission set Id
            List<PermissionSet> permissionSetsList = getAllPermissionSets();
            if(!permissionSetsList.isEmpty()) {
                for(PermissionSet ps : permissionSetsList) {
                    permissionSetNameToIdMap.put(ps.name, ps.Id);
                }
            }
            
            //Get all public groups and create a map of public group developer name => public group Id
            List<Group> publicGroupsList = getAllPublicGroups();
            if(!publicGroupsList.isEmpty()) {
                for(Group gp : publicGroupsList) {
                    publicGroupNameToIdMap.put(gp.DeveloperName, gp.Id);
                }
            }
            
            //Get all active package licenses and create a map of package license namespace prefix => package Id
            if(!String.isEmpty(customLabelInfo) && customLabelInfo == 'Yes') {
                List<PackageLicense> packageLicenseList = getAllPackageLicenses();
                if(!packageLicenseList.isEmpty()) {
                    for(PackageLicense pl : packageLicenseList){
                        packageLicenseNameToIdMap.put(pl.NamespacePrefix, pl.Id);
                    }
                }
            }
            
            For(User userRec : newUserList) {
                if(userRec.IsActive == true) {
                    For(Assign_SF_Resources_to_User__mdt ura : allUsersAssignmentsFromMdt) {
                        if(ura.Active__c && userRec.Profile.Name == ura.Profile_Name__c) {
                            //For each user, build a list of permission set ids, public group ids, usertypes, and package license ids 
                            //based on the custom metadata type assignment of user profile to a resource i.e. get the name of the resource from the 
                            //mdt and save its Id only if a matching resource is found in the org. 
                            if(ura.Assignment_Type__c == 'Permission Set') {
                                if(permissionSetNameToIdMap.containsKey(ura.Permission_Set_Name__c) && 
                                   !userPermissionSetAssignmentList.contains(permissionSetNameToIdMap.get(ura.Permission_Set_Name__c))) {
                                       userPermissionSetAssignmentList.add(permissionSetNameToIdMap.get(ura.Permission_Set_Name__c));    
                                   }
                            }
                            if(ura.Assignment_Type__c == 'Public Group') {
                                if(publicGroupNameToIdMap.containsKey(ura.Public_Group_Name__c) && 
                                   !userPublicGroupAssignmentList.contains(publicGroupNameToIdMap.get(ura.Public_Group_Name__c))) {
                                       userPublicGroupAssignmentList.add(publicGroupNameToIdMap.get(ura.Public_Group_Name__c));
                                   }
                            }
                            if(ura.Assignment_Type__c == 'User Type') {
                                if(!userTypeList.contains(ura.User_Type_Name__c)) {
                                    userTypeList.add(ura.User_Type_Name__c);
                                }
                            }
                            if(!String.isEmpty(customLabelInfo) && customLabelInfo == 'Yes' && ura.Assignment_Type__c == 'Package License' &&
                               !userPackageLicenseAssignmentList.contains(packageLicenseNameToIdMap.get(ura.Package_License_Name__c))) {
                                   userPackageLicenseAssignmentList.add(packageLicenseNameToIdMap.get(ura.Package_License_Name__c));
                               }
                        }
                    }
                    
                    //for each user, create a map of userid => list of (permission set ids, public group ids, user types, and package license ids)
                    if(!userPermissionSetAssignmentList.isEmpty()) {
                        userPermissionSetAssignmentMap.put(userRec.Id, userPermissionSetAssignmentList);
                    }
                    if(!userPublicGroupAssignmentList.isEmpty()) {
                        userPublicGroupAssignmentMap.put(userRec.Id, userPublicGroupAssignmentList);
                    }
                    if(!userPackageLicenseAssignmentList.isEmpty()) {
                        userPackageLicenseAssignmentMap.put(userRec.Id, userPackageLicenseAssignmentList);
                    }
                    if(!userTypeList.isEmpty()) {
                        userTypeAssignmentMap.put(userRec.Id, userTypeList);
                    }
                }
            }
            
            //#1 Hanlde Permission Sets first
            List<PermissionSetAssignment> userPermissionSetAssignmentsToInsert = new List<PermissionSetAssignment>(); 
            //Delete existing permission set assignments 
            deleteUserPermissionSetAssignment(userPermissionSetAssignmentMap.KeySet());       
            for(Id usrId : userPermissionSetAssignmentMap.KeySet()) {
                if(userPermissionSetAssignmentMap.containsKey(usrId)) {
                    for(string psId : userPermissionSetAssignmentMap.get(usrId)) {
                        PermissionSetAssignment psAssign = new PermissionSetAssignment();
                        psAssign.AssigneeId = usrId;
                        psAssign.PermissionSetId = psId;
                        userPermissionSetAssignmentsToInsert.add(psAssign);
                    }
                }
            }
            
            if(!userPermissionSetAssignmentsToInsert.isEmpty()) {
                insert userPermissionSetAssignmentsToInsert;
                //Database.SaveResult[] psInsertResult = Database.insert(userPermissionSetAssignmentsToInsert, false);
                //insertErrors(psInsertResult, 'Permission Set Assignment Insert','Permisson Set Assignment Insert');    
            }            
            
            //#2 Handle Public Groups second
            List<GroupMember> userPublicGroupMembersToInsert = new List<GroupMember>();
            //Delete existing public group assignments
            deleteUserPublicGroupMembership(userPublicGroupAssignmentMap.KeySet());
            for(Id usrId :userPublicGroupAssignmentMap.KeySet()) {
                if(userPublicGroupAssignmentMap.containsKey(usrId)) {
                    for(string pgId : userPublicGroupAssignmentMap.get(usrId)) {
                        GroupMember gmAssign = new GroupMember(
                            GroupId = pgId,
                            UserOrGroupId = usrId
                        );
                        userPublicGroupMembersToInsert.add(gmAssign);
                    }
                }
            }
            if(!userPublicGroupMembersToInsert.isEmpty()) {
                system.debug('### userPublicGroupMembersToInsert ' + userPublicGroupMembersToInsert.size());
                Database.Insert(userPublicGroupMembersToInsert, false);
            }
            
            //#3 Handle user type
            if(!userTypeAssignmentMap.isEmpty()) {
                for(User userRec : newUserList) {
                    if(userTypeAssignmentMap.containsKey(userRec.Id)) {
                        for(string uType : userTypeAssignmentMap.get(userRec.Id)) {
                            userTypeAssignment += uType + ';';
                        }
                    }
                    userRec.sked__skeduloUserType__c = userTypeAssignment;
                    userTypeAssignment = '';
                }
                Database.update(newUserList, false);
            }           
            else
            {
                for(User userRec : newUserList) {
                    if(userRec.Profile.Name != System.Label.AssignResourceProfileToExclude) { //HRP-9982
                        userRec.sked__skeduloUserType__c = '';
                    }
                }
                Database.update(newUserList, false);
            }
            
            //#4 Handle Pakcage Licenses
            if(!String.isEmpty(customLabelInfo) && customLabelInfo == 'Yes') {
                List<UserPackageLicense> userPackageLicenseToInsert = new List<UserPackageLicense>();
                //Delete existing package license assignments
                deleteUserPackageLicenses(userPackageLicenseAssignmentMap.KeySet());
                for(Id usrId :userPackageLicenseAssignmentMap.KeySet()) {
                    if(userPackageLicenseAssignmentMap.containsKey(usrId)) {
                        for(string plId : userPackageLicenseAssignmentMap.get(usrId)) {
                            UserPackageLicense plAssign = new UserPackageLicense (
                                PackageLicenseId = plId,
                                UserId = usrId
                            );
                            userPackageLicenseToInsert.add(plAssign);
                        }
                    }
                }
                if(!userPackageLicenseToInsert.isEmpty()) {
                    system.debug('### userPackageLicenseToInsert ' + userPackageLicenseToInsert.size());
                    Database.insert(userPackageLicenseToInsert, false);
                }
            }
        }
    }
    
    //Get all assignment configurations from the assignment custom metadata type
    public static List<Assign_SF_Resources_to_User__mdt> getAllUserAssignmentsFromMdt() {
        
        List<Assign_SF_Resources_to_User__mdt> profileUserAssignmentsList = [
            SELECT Active__c, Assignment_Type__c, Permission_Set_Name__c, Profile_Name__c, 
            Public_Group_Name__c, Queue_Name__c, User_Type_Name__c, Package_License_Name__c
            FROM Assign_SF_Resources_to_User__mdt
        ];
        
        return profileUserAssignmentsList;
    }
    
    //Delete permission sets assigned to users
    public static void deleteUserPermissionSetAssignment(Set<Id> uIds) {
        
        List<PermissionSetAssignment> curPermissionSetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId in: uIds 
            AND PermissionSetId In(SELECT Id FROM PermissionSet WHERE IsOwnedByProfile = false)
        ];
        
        if(!curPermissionSetAssignments.isEmpty()) {
            delete curPermissionSetAssignments;
        }
    }
    
    //Delete users' public group membership
    public static void deleteUserPublicGroupMembership(Set<Id> uIds) {
        
        List<GroupMember> curPublicGroupAssignments = [
            SELECT Id
            FROM GroupMember
            WHERE UserOrGroupId in: uIds And GroupId in (SELECT Id FROM Group WHERE Type = 'Regular')
        ];
        
        if(!curPublicGroupAssignments.isEmpty()) {
            delete curPublicGroupAssignments;
        }
    }
    
    //Delete package licenses assgined to users
    public static void deleteUserPackageLicenses(Set<Id> uIds) {
        
        List<UserPackageLicense> curPackageLicenseAssignments = [
            SELECT Id
            FROM UserPackageLicense
            WHERE UserId in: uIds
        ];
        
        if(!curPackageLicenseAssignments.isEmpty()) {
            delete curPackageLicenseAssignments;
        }
    }
    
    //Get all permission sets
    public static List<PermissionSet> getAllPermissionSets() {
        
        List<PermissionSet> allPermissionSetsList = [
            SELECT Id, Name 
            FROM PermissionSet
            WHERE IsOwnedByProfile = false AND Type <> 'Standard'
        ];
        
        return allPermissionSetsList;
    }
    
    //Get all public groups
    public static List<Group> getAllPublicGroups() {
        
        List<Group> allPublicGroupsList = [
            SELECT Id, Name, DeveloperName
            FROM Group
            WHERE Type = 'Regular'
        ];
        
        return allPublicGroupsList;
    }
    
    //Get all package licenses
    public static List<PackageLicense> getAllPackageLicenses() {
        
        List<PackageLicense> allPackageLicensesList = [
            SELECT Id, Status, NamespacePrefix 
            FROM PackageLicense
            WHERE Status ='Active'
        ];
        
        return allPackageLicensesList;
    }
    
    public static void insertErrors(Database.SaveResult[] saveErrors, String errorDesc, String processName){
        //List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        
        for(Database.SaveResult result : saveErrors){
            if(result != null && result.getErrors() != null && result.getErrors().size() > 0){
                system.debug('### Error during insert of resource... ' + result.getErrors()[0].getMessage());
                //errorList.add(BSF_Utilities.getErrorLog(processName,'BSFPortfolioHelper','createOrUpdatePortfolio','Error',errorDesc,result.getErrors()[0].getMessage()));
            }
        }
        //if(errorList.size() > 0){
        //    Database.insert(errorList,false);
        //}
    }    
}