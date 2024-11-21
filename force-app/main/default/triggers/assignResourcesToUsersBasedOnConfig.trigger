trigger assignResourcesToUsersBasedOnConfig on AssignResourcesToUserEvent__e (After Insert) {
    if(!checkRecursive.firstcall) {
        checkRecursive.firstcall = true;
        Set<Id> userIds = new Set<Id>();    
        for(AssignResourcesToUserEvent__e evt : Trigger.New) {
            userIds.add(evt.UserId__c);
        }
        System.debug('###FWO inside AssignResourcesToUserEvent__e trigger, published userIds ' + userIds);
        userService.assignResourcesToUser(userIds);
    }
}