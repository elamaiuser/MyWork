public class skedUserHandler extends skedTriggerHub implements Callable {
    
    public override void onAfterInsert() {
        if (!Test.isRunningTest()) {
            assignUsersToQueues(this.context.newRecords);
        }
    }

    public override void onAfterUpdate() {
        if (!Test.isRunningTest()) {
            maintainUserQueues((Map<Id, User>) this.context.newMap, (Map<Id, User>) this.context.oldMap);
        }
    }

    public static void assignUsersToQueues(List<User> newUsers) {
        Map<Id, List<String>> collectionOpsByUser = new Map<Id, List<String>>();
        for (User user : newUsers) {
            if (user.sked_Collection_Operations__c != NULL) {
                List<String> collectionOps = user.sked_Collection_Operations__c.split(';');
                collectionOpsByUser.put(user.Id, collectionOps);
            }
        }
        if (!collectionOpsByUser.isEmpty()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedUserHandler.class.getName(),
                'addUsersToQueues',
                collectionOpsByUser);
        }
    }

    public static void maintainUserQueues(Map<Id, User> newMap, Map<Id, User> oldMap) {
        Map<Id, List<String>> collectionOpsToAddByUser = new Map<Id, List<String>>();
        Map<Id, List<String>> collectionOpsToRemoveByUser = new Map<Id, List<String>>();

        for (Id userId : newMap.keySet()) {
            User oldRecord = oldMap.get(userId);
            User newRecord = newMap.get(userId);

            List<String> newCollectionOps = new List<String>();
            if (newRecord.sked_Collection_Operations__c != null) {
                List<String> newCollectionOpsList = newRecord.sked_Collection_Operations__c.split(';');
                for (String newCollectionOp : newCollectionOpsList) {
                    newCollectionOps.add(newCollectionOp + ':');
                }
            }

            List<String> oldCollectionOps = new List<String>();
            if (oldRecord.sked_Collection_Operations__c != null) {
                List<String> oldCollectionOpsList = oldRecord.sked_Collection_Operations__c.split(';');
                for (String oldCollectionOp : oldCollectionOpsList) {
                    oldCollectionOps.add(oldCollectionOp + ':');
                }
            }

            // If the profile changes, remove them from all queues, then add them to the new queues
            if (oldRecord.ProfileId != newRecord.ProfileId) {
                collectionOpsToRemoveByUser.put(userId, oldCollectionOps);
                collectionOpsToAddByUser.put(userId, newCollectionOps);
                continue;
            }

            List<String> collectionOpsToRemove = new List<String>();
            for (String collectionOp : oldCollectionOps) {
                if (newCollectionOps.isEmpty() || !newCollectionOps.contains(collectionOp)) {
                    collectionOpsToRemove.add(collectionOp);
                }
            }

            if (!collectionOpsToRemove.isEmpty()) {
                collectionOpsToRemoveByUser.put(userId, collectionOpsToRemove);
            }

            List<String> collectionOpsToAdd = new List<String>();
            for (String collectionOp : newCollectionOps) {
                if (oldCollectionOps.isEmpty() || !oldCollectionOps.contains(collectionOp)) {
                    collectionOpsToAdd.add(collectionOp);
                }
            }

            if (!collectionOpsToAdd.isEmpty()) {
                collectionOpsToAddByUser.put(userId, collectionOpsToAdd);
            }
        }

        if (!collectionOpsToRemoveByUser.keySet().isEmpty()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedUserHandler.class.getName(),
                'removeUsersFromQueues',
                collectionOpsToRemoveByUser);
        }

        if (!collectionOpsToAddByUser.keySet().isEmpty()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedUserHandler.class.getName(),
                'addUsersToQueues',
                collectionOpsToAddByUser);
        }
    }

    public static void addUsersToQueues(String collectionOpsToAddByUserIdJSON) {
        Map<Id, List<String>> collectionOpsToAddByUserId = 
            (Map<Id, List<String>>) JSON.deserialize(collectionOpsToAddByUserIdJSON, Map<Id, List<String>>.class);

        List<User> users = [
            SELECT Id, Name, Profile.Name
            FROM User
            WHERE Id IN :collectionOpsToAddByUserId.keySet()
            AND IsActive = TRUE
        ];

        Set<String> allUsedCollectionOperationNames = new Set<String>();
        for (Id userId : collectionOpsToAddByUserId.keySet()) {
            List<String> collectionOperations = collectionOpsToAddByUserId.get(userId);

            for (String collectionOperation : collectionOperations) {
                allUsedCollectionOperationNames.add(collectionOperation + '%');
            }
        }

        List<Group> collectionOpQueues = [
            SELECT Id, Name,
                (SELECT Id, sobjectType FROM QueueSobjects)
            FROM Group
            WHERE Name LIKE :allUsedCollectionOperationNames
        ];

        Map<String, sked_Profile_Approval_Queue_Access__mdt> profileQueueAccessByLabel = getProfileQueueAccessByLabel();

        List<GroupMember> groupMembersToAdd = new List<GroupMember>();
        for (User user : users) {
            sked_Profile_Approval_Queue_Access__mdt profileQueueAccess = profileQueueAccessByLabel.get(user.Profile.Name);
            List<String> collectionOpsForUser = collectionOpsToAddByUserId.get(user.Id);

            if (null != profileQueueAccess) {
                for (Group collectionOpQueue : collectionOpQueues) {
                    if (doesUserBelongToCollectionOp(collectionOpsForUser, collectionOpQueue.Name)) {
                        if (doesUserBelongToGroup(collectionOpQueue.Name, profileQueueAccess)) {
                            groupMembersToAdd.add(new GroupMember(
                                UserOrGroupId = user.Id,
                                GroupId = collectionOpQueue.Id
                            ));
                        }
                    }
                }
            }
        }

        if (!groupMembersToAdd.isEmpty()) {
            insert groupMembersToAdd;
        }
    }

    public static void removeUsersFromQueues(String collectionOpsToRemoveByUserIdJSON) {
        Map<Id, List<String>> collectionOpsToRemoveByUserId =
            (Map<Id, List<String>>) JSON.deserialize(collectionOpsToRemoveByUserIdJSON, Map<Id, List<String>>.class);

        Set<String> allCollectionOps = new Set<String>();

        for (Id userId : collectionOpsToRemoveByUserId.keySet()) {
            List<String> userCollectionOps = collectionOpsToRemoveByUserId.get(userId);
            for (String userCollectionOp : userCollectionOps) {
                allCollectionOps.add(userCollectionOp + '%');
            }
        }

        List<GroupMember> usersGroupMembers = [
            SELECT Id, Group.Name, UserOrGroupId
            FROM GroupMember
            WHERE UserOrGroupId IN :collectionOpsToRemoveByUserId.keySet()
            AND Group.Name LIKE :allCollectionOps
        ];

        Map<Id, List<GroupMember>> groupsByUser = new Map<Id, List<GroupMember>>();
        for (GroupMember gm : usersGroupMembers) {
            List<GroupMember> usersGroupMemberships = groupsByUser.get(gm.UserOrGroupId);

            if (usersGroupMemberships == null) {
                usersGroupMemberships = new List<GroupMember>();
            }

            usersGroupMemberships.add(gm);
            groupsByUser.put(gm.UserOrGroupId, usersGroupMemberships);
        }

        List<GroupMember> groupMembersToDelete = new List<GroupMember>();
        for (Id userId : collectionOpsToRemoveByUserId.keySet()) { 
            List<String> userCollectionOps = collectionOpsToRemoveByUserId.get(userId);
            List<GroupMember> usersGroupMemberships = groupsByUser.get(userId);
            if (usersGroupMemberships != null && !usersGroupMemberships.isEmpty()) {
                for (GroupMember groupMember : usersGroupMemberships) {
                    // We want before the :, but we also want the :, so we just add it on afterwards.
                    String groupPrefix = groupMember.Group.Name.split(':')[0] + ':';
                    Integer groupIndex = userCollectionOps.indexOf(groupPrefix);
        
                    if (groupIndex != -1) {
                        groupMembersToDelete.add(groupMember);
                    }
                }
            }
        }

        if (!groupMembersToDelete.isEmpty()) {
            delete groupMembersToDelete;
        }
    }

    private static Boolean doesUserBelongToCollectionOp(List<String> collectionOps, String queueName) {
        for (String collectionOp : collectionOps) {
            if (queueName.contains(collectionOp)) return true;
        }

        return false;
    }

    private static Boolean doesUserBelongToGroup(String groupName, sked_Profile_Approval_Queue_Access__mdt profileSetting) {
        Boolean belongsToGroup = false;

        if ((groupName.contains(skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS) && profileSetting.sked_Drive_Change_Request__c) 
            || (groupName.contains(skedConstants.PROFILE_QUEUE_PENDING_ACTIONS) && profileSetting.sked_Pending_Action__c)
            || (groupName.contains(skedConstants.PROFILE_QUEUE_ROLE_TIME_VARIANCES) && profileSetting.sked_Role_Time_Variance__c)
            || (groupName.contains(skedConstants.PROFILE_QUEUE_DRIVE_SHIFT_TRADES) && profileSetting.sked_Drive_Shift_Trade_Request__c)
            || (groupName.contains(skedConstants.PROFILE_QUEUE_DM_DRIVE_CHANGE_REQUESTS) && profileSetting.sked_DM_Drive_Change_Request__c)
            || (groupName.contains(skedConstants.PROFILE_QUEUE_DM_PENDING_ACTIONS) && profileSetting.sked_DM_Pending_Action__c)) {
                belongsToGroup = true;
        }

        return belongsToGroup;
    }

    private static Map<String, sked_Profile_Approval_Queue_Access__mdt> getProfileQueueAccessByLabel() {
        List<sked_Profile_Approval_Queue_Access__mdt> profileQueueAccessList = [
            SELECT Id, Label, sked_Drive_Change_Request__c, sked_Drive_Shift_Trade_Request__c, 
                sked_Pending_Action__c, sked_Role_Time_Variance__c, sked_DM_Drive_Change_Request__c,
                sked_DM_Pending_Action__c
            FROM sked_Profile_Approval_Queue_Access__mdt
        ];

        Map<String, sked_Profile_Approval_Queue_Access__mdt> profileQueueAccessByLabel 
            = new Map<String, sked_Profile_Approval_Queue_Access__mdt>();
        
        for (sked_Profile_Approval_Queue_Access__mdt pqa : profileQueueAccessList) {
            profileQueueAccessByLabel.put(pqa.Label, pqa);
        }

        return profileQueueAccessByLabel;
    }
    
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'addUsersToQueues' {
                    addUsersToQueues((String) params.get('param1'));
                }
                when 'removeUsersFromQueues' {
                    removeUsersFromQueues((String) params.get('param1'));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedUserHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
}