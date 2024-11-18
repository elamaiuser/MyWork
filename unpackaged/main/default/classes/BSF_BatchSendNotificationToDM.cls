global class BSF_BatchSendNotificationToDM implements Schedulable, Database.Batchable<sObject>{
    String taskSubject = Task_Reassignment_Matrix__mdt.getInstance('Sponsor_Planning').Task_Subject__c;
	public String query = 'SELECT Id, WhatId, ActivityDate, subject, OwnerId, Owner.Name FROM Task WHERE ActivityDate = TODAY AND subject =:taskSubject AND Status != \'Completed\'';
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<Task> scope){
		set<id> oppIds = new set<id>();
        Map<id,Id> dmMap = new Map<id,Id>();
        List<String> sendId = new List<String>();
        for(Task t : scope){
            oppIds.add(t.WhatId);
        }
        if(!oppIds.isEmpty()){
            customNotificationType cn=[select id from CustomNotificationType where developername='Task_Custom_Notification'];
            for(OpportunityTeamMember oppTeamMembers : [SELECT Id, 
                                                                            OpportunityId, 
                                                                            TeamMemberRole, 
                                                                            UserId
                                                                        FROM OpportunityTeamMember
                                                                        WHERE TeamMemberRole =:BSF_Constants.DISTRICT_MANAGER
                                                                        AND OpportunityId IN :oppIds
                                                                        ]){
                dmMap.put(oppTeamMembers.OpportunityId,oppTeamMembers.UserId);
            }
            if(!dmMap.isEmpty()){
                for(Task t : scope){
                    if(dmMap.containsKey(t.WhatId)){
                        sendId.clear();
                        sendId.add(dmMap.get(t.WhatId));
                        new BSF_CustomNotification()
                            .typeId(cn.id)
                            .title('Sponsor Planning Meeting is expired')
                            .body('Please review the task with the Account Manager '+t.Owner.Name + ' and complete it.')
                            .sender(UserInfo.getUserId())
                            .target(t.WhatId)
                            .category('SponsorPlanningMeetingTask')
                            .send(sendId);
                    }
                }
            }
        }
	}
	global void execute(SchedulableContext scon){
		Database.executeBatch(new BSF_BatchSendNotificationToDM(),200);
	}
	global void finish(Database.BatchableContext BC){
	}
}