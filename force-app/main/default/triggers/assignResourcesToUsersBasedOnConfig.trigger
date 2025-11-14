trigger assignResourcesToUsersBasedOnConfig on AssignResourcesToUserEvent__e (After Insert) {
    if(!checkRecursive.firstcall) {
        checkRecursive.firstcall = true;
        Map<Id, Boolean> map_userId_skipRoleAssignment = new Map<Id, Boolean>();
        for(AssignResourcesToUserEvent__e evt : Trigger.New) {
            map_userId_skipRoleAssignment.put(evt.UserId__c, evt.skipUserRoleUpdate__c);
        }
        Map<String, Object> userObject = new Map<String, Object>{
            'userIds' => map_userId_skipRoleAssignment.keySet(),
            'skipUserRoleAssignment' => map_userId_skipRoleAssignment
        };
        userService.AssignResourcesToUser(userObject);
    }
}