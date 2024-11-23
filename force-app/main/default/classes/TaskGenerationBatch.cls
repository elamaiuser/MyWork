global class TaskGenerationBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, StageName, Account_Manager__c, OwnerId, Is_Template__c, Call_List_Recipient_Exist__c, RecordTypeId, Drive_Date__c, AccountId, Account.Account_Manager__c, IsClosed, CloseDate FROM Opportunity WHERE StageName = \'Committed\' OR StageName = \'Closed\''
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
        Set<Id> oppIdsWithSponsorTask = new Set<Id>();
        Set<Id> oppIdsWithRecruitmentTask = new Set<Id>();
        Set<Id> oppIdsWith72CheckInTask = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        
        for (Opportunity opp : opportunities) {
            oppIdSet.add(opp.Id);
        }
        List<Opportunity> oppsForSponsorTasks = new List<Opportunity>();
        List<Opportunity> oppsForRecruitmentTasks = new List<Opportunity>();
        List<Opportunity> oppsFor72CheckInTasks = new List<Opportunity>();
        List<task> tasks = [SELECT WhatId, Subject, Type FROM Task WHERE (Subject = 'Recruitment Planning Meeting' OR Type = 'Sponsor Planning Meeting' OR Subject = '72 Hour Check-In') AND WhatId IN: oppIdSet];//HRP-7123//HRP-12627
        if (!tasks.isEmpty()) {
            for (Task tsk : tasks) {
                if(tsk.Subject == 'Recruitment Planning Meeting'){//HRP-7123
                    oppIdsWithRecruitmentTask.add(tsk.WhatId);
                }else if(tsk.type == 'Sponsor Planning Meeting'){
                    oppIdsWithSponsorTask.add(tsk.WhatId);
                }else if(tsk.Subject == '72 Hour Check-In'){//HRP-12627
                    oppIdsWith72CheckInTask.add(tsk.WhatId);
                }
            }
            for (Opportunity opp : opportunities) {
                Boolean hasSponsorTask = oppIdsWithSponsorTask.contains(opp.Id);
                Boolean hasRecruitmentTask = oppIdsWithRecruitmentTask.contains(opp.Id);
                Boolean has72CheckInTask = oppIdsWith72CheckInTask.contains(opp.Id);
                if (opp.StageName == 'Closed') {
                    if (!hasSponsorTask) {
                        oppsForSponsorTasks.add(opp);
                    }
                    if (!hasRecruitmentTask) {
                        oppsForRecruitmentTasks.add(opp);
                    }
                    if (!has72CheckInTask) {
                        oppsFor72CheckInTasks.add(opp);
                    }
                }else if (opp.StageName == 'Committed' && !hasSponsorTask) {
                    oppsForSponsorTasks.add(opp);
                }else if(opp.StageName == 'Committed' && !has72CheckInTask) {//HRP-12627
                    oppsFor72CheckInTasks.add(opp);//HRP-12627
                }
            }
        }else{
            oppsForSponsorTasks.addAll(opportunities);
            oppsForRecruitmentTasks.addAll(opportunities);
            oppsFor72CheckInTasks.addAll(opportunities);
        }
        
        if(!oppsForSponsorTasks.isEmpty()){
            OpportunityService.createSponsorPlanningMeetingTask(oppsForSponsorTasks, NULL);
        }
        if(!oppsForRecruitmentTasks.isEmpty()){
            OpportunityService.createRecruitmentTask(oppsForRecruitmentTasks, NULL); //Recruitments are created only when Call_List_Recipient_Exist__c
        }
        if(!oppsFor72CheckInTasks.isEmpty()){
            OpportunityService.closedOpportunity72HourTaskCreation(oppsFor72CheckInTasks, NULL);
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
}