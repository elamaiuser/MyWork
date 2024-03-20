global class  BSF_BatchTaskSync implements Database.Batchable<SObject>,Schedulable {
   String query='SELECT WhatId,Account_Manager__c,Subject,OwnerId,RecordTypeId FROM Task Where Status!=\'Completed\' AND Status!=\'Cancelled\'';
    //Id test='00T8I000005sqRSUAY';
    //String query='select id,WhatId,Account_Manager__c,Subject,OwnerId,RecordTypeId from task where id=:test';
    
    global void execute(System.SchedulableContext ctx) {
		BSF_BatchTaskSync batchtsksyc = new BSF_BatchTaskSync();
		Database.executeBatch(batchtsksyc);
	}
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext BC, List<Task> scope){
        System.debug('scope'+scope);
        
        set<Id> oppIdset = new set<Id>();
        Map<String,String> taskoppmap = new Map<String,String>();
        List<Task> updatedtasklist = new List<Task>();
        for(Task tk:scope){
            oppIdset.add(tk.WhatId);
            taskoppmap.put(tk.Id,tk.WhatId); 
        }
        List<OpportunityTeamMember> oppteamlist = [Select Id,OpportunityId,TeamMemberRole,UserId from OpportunityTeamMember Where TeamMemberRole=:BSF_Constants.DISTRICT_MANAGER AND OpportunityId IN:oppIdset];
        Map<Id,OpportunityTeamMember> oppteammembermap = new Map<Id,OpportunityTeamMember>();
        for(OpportunityTeamMember oppteamem:oppteamlist){
            
            oppteammembermap.put(oppteamem.OpportunityId,oppteamem);
        }
        date date5=system.today()-5;
        List<Opportunity> Opplist=[SELECT Id,AccountId,Drive_Date__c,ownerId,Account_Manager__c FROM Opportunity Where Id IN:oppIdset];// AND Drive_Date__c>=:date5];
        //Map<Id,Account> oppaccmap = new Map<Id,Account>();
        Map<Id,Opportunity> oppIdMap = new Map<Id,Opportunity>();
        for(Opportunity opp:Opplist){
            
            oppIdMap.put(opp.Id,opp);
            
        }
        List<Task_Reassignment_Matrix__mdt> taskmppamdm = [Select Task_Subject__c,Assigned_To__c from Task_Reassignment_Matrix__mdt];
        System.debug('taskmppamdm'+taskmppamdm);
        Map<String,String> subjectassigntoMap = new Map<String,String>();
        for(Task_Reassignment_Matrix__mdt tm :taskmppamdm){
            subjectassigntoMap.put(tm.Task_Subject__c,tm.Assigned_To__c);
        }
        for(Task tsk: scope){
            system.debug('check2'+subjectassigntoMap.get(tsk.Subject)+' '+tsk.Subject);
            system.debug('AM '+subjectassigntoMap.get(tsk.Subject));
            if(subjectassigntoMap.get(tsk.Subject)=='AM'){
                system.debug('entered 1');
                /*if(oppIdMap.containsKey(tsk.whatId) && oppIdMap.get(tsk.WhatId).Account_Manager__c !=oppIdMap.get(tsk.WhatId).ownerId && oppIdMap.get(tsk.WhatId).Drive_Date__c <system.today()){
                    system.debug('entered 2');
                    tsk.OwnerId=oppIdMap.get(tsk.WhatId).ownerId; 
                    updatedtasklist.add(tsk);
                }else if(oppIdMap.containsKey(tsk.whatId) && oppIdMap.get(tsk.WhatId).Account_Manager__c != null){
                    system.debug('entered3');
                    tsk.OwnerId=oppIdMap.get(tsk.WhatId).Account_Manager__c;  
                    updatedtasklist.add(tsk);
                }*/
                if(oppIdMap.containsKey(tsk.whatId) && oppIdMap.get(tsk.WhatId).Account_Manager__c != null){
                    system.debug('entered 2');
                    tsk.OwnerId=oppIdMap.get(tsk.WhatId).Account_Manager__c; 
                    updatedtasklist.add(tsk);
                }else if(oppIdMap.containsKey(tsk.whatId)){
                    system.debug('entered3');
                    tsk.OwnerId=oppIdMap.get(tsk.WhatId).ownerId;  
                    updatedtasklist.add(tsk);
                }
            }
            else if(subjectassigntoMap.get(tsk.Subject)=='DM'){
                if(oppteammembermap.containsKey(tsk.WhatId) && oppteammembermap.get(tsk.WhatId).UserId!= null 
                   		&& oppteammembermap.get(tsk.WhatId).UserId!=tsk.ownerId){
                            tsk.ownerId=oppteammembermap.get(tsk.WhatId).UserId;
                            updatedtasklist.add(tsk);
                }
                
            }
        }
        Database.SaveResult[] saveupdatedtasklist = Database.update(updatedtasklist);
       
        if(updatedtasklist.size()>0){
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(saveupdatedtasklist,'Task Sync','BSF_BatchTaskSync','execute','Error','Error in Syncing Task');
            InsertBsfErrorLog.insertBsfErrors(logList);
            System.debug('logList'+logList);
        }
        
        
        
    }
    global void finish(Database.BatchableContext BC){
        
    }
}