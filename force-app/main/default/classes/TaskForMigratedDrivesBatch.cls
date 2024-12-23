global class TaskForMigratedDrivesBatch implements Database.Batchable<sObject >{
    global static final String  SPONSOR_PLANNING_TASK = 'Sponsor Planning Meeting - System Generated';
    global static final String  RECRUITMENT_TASK = 'Recruitment Planning Meeting';//HRP-7123
    global static final String  SEVENTYTWO_HOUR_TASK = '72 Hour Check in - System Generated';
    global static final String  STAGE_CLOSED = 'Closed';
    global static final String  STAGE_COMMITTED = 'Committed';
    global static final String  query = 'SELECT Id, Name, StageName, Drive_Status__c, Account_Manager__c, Is_Template__c, Call_List_Recipient_Exist__c, RecordTypeId, OwnerId, Drive_Date__c, IsClosed, CloseDate FROM Opportunity WHERE Drive_Date__c > TODAY AND Migration_ID__c!=null AND Is_Template__c = false';

    global Database.QueryLocator start(Database.BatchableContext bc){ 
            return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
        List<String> subjectList = new List<String>{SPONSOR_PLANNING_TASK,RECRUITMENT_TASK,SEVENTYTWO_HOUR_TASK};
        List<Opportunity> oppIdSetgreatercommittedTentativeSpon = new List<Opportunity>();
        List<Opportunity> oppIdSetGreaterCloseConfirmedthree = new List<Opportunity>();
        List<Opportunity> oppIdSetLesserCloseConfirmed72 = new List<Opportunity>();
        if(opportunities.isEmpty()){
            return;
        }
        try{
            Map<Id, Opportunity> oppMap =new Map<Id, Opportunity>(opportunities);
            Map<Id, List<String>> oppVsTaskSubMap =new Map<Id, List<String>>();
            for(Task tk : [SELECT WhatId, Subject, Type FROM Task WHERE Subject IN: subjectList AND WhatId IN: oppMap.keySet()]){
                if(oppVsTaskSubMap.isEmpty() || !oppVsTaskSubMap.containsKey(tk.WhatId)){
                    oppVsTaskSubMap.put(tk.WhatId,new List<String>());
                }
                oppVsTaskSubMap.get(tk.WhatId).add(tk.Subject);
            }
            for(Id oppId : oppMap.keySet()){
                if(oppMap.get(oppId).Drive_Date__c > system.today()+98 && (oppMap.get(oppId).StageName.equalsIgnoreCase(STAGE_CLOSED) || oppMap.get(oppId).StageName.equalsIgnoreCase(STAGE_COMMITTED)) 
                    && (!oppVsTaskSubMap.containsKey(oppId) || !oppVsTaskSubMap.get(oppId).contains(SPONSOR_PLANNING_TASK))){
                        oppIdSetgreatercommittedTentativeSpon.add(oppMap.get(oppId));
                }
                if(oppMap.get(oppId).Drive_Date__c > system.today()+98 && oppMap.get(oppId).StageName.equalsIgnoreCase(STAGE_CLOSED) 
                    && (!oppVsTaskSubMap.containsKey(oppId) || !oppVsTaskSubMap.get(oppId).contains(RECRUITMENT_TASK))){
                        oppIdSetGreaterCloseConfirmedthree.add(oppMap.get(oppId));
                }
                if(oppMap.get(oppId).Drive_Date__c > system.today() && oppMap.get(oppId).StageName.equalsIgnoreCase(STAGE_CLOSED)
                    && (!oppVsTaskSubMap.containsKey(oppId) || !oppVsTaskSubMap.get(oppId).contains(SEVENTYTWO_HOUR_TASK))){
                        oppIdSetLesserCloseConfirmed72.add(oppMap.get(oppId));
                }
            }

            if(!oppIdSetgreatercommittedTentativeSpon.isEmpty()){
                try{
                    OpportunityService.createSponsorPlanningMeetingTask(oppIdSetgreatercommittedTentativeSpon, NULL); 
                }catch(Exception ex){
                  System.debug('Exception : '+ex.getMessage() +' '+ex.getLineNumber());  
                }
            }
            if(!oppIdSetGreaterCloseConfirmedthree.isEmpty()){
                try{
                    OpportunityService.createRecruitmentTask(oppIdSetGreaterCloseConfirmedthree, NULL);
                }catch(Exception ex){
                  System.debug('Exception : '+ex.getMessage() +' '+ex.getLineNumber());  
                }
            }
            if(!oppIdSetLesserCloseConfirmed72.isEmpty()){
                try{
                    OpportunityService.closedOpportunity72HourTaskCreation(oppIdSetLesserCloseConfirmed72, NULL);
                }catch(Exception ex){
                  System.debug('Exception : '+ex.getMessage() +' '+ex.getLineNumber());  
                }
            }
        }catch(Exception exp){
           System.debug('Exception : '+exp.getMessage() +' '+exp.getLineNumber()); 
        }
        
    }
    global void finish(Database.BatchableContext bc){}
}