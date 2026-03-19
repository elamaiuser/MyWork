//@Description: Corrects Task owner for Opportunity Tasks
/*
* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 03/22/2024					 Balaji N				  		logic for HRP-12333
*************************************************************************************************************************************************************************************************************************************************************************
*/
global class  BSF_BatchTaskSync implements Database.Batchable<SObject>,Schedulable 
{
    //HRP-12333 Start
    Public List<Id> whatIdList;
    Public List<Id> tasKIdList;
    Public Map<String,String> subjectassigntoMap = new Map<String,String>();
    Public Set<String> subjectSet = new Set<String>();
    Public Boolean isAll = True;
    global BSF_BatchTaskSync()
    {
        getMetaData();
    }
    global BSF_BatchTaskSync(List<Id> whatIdList,List<Id> tasKIdList)
    {
        this.isAll=false;
        this.whatIdList=whatIdList;
        this.tasKIdList=tasKIdList;
        getMetaData();
    }
    //HRP-12333 End
    global void execute(System.SchedulableContext ctx) 
    {
        BSF_BatchTaskSync batchtsksyc = new BSF_BatchTaskSync();
        Database.executeBatch(batchtsksyc);
    }
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        Set<String> subjectSet = new Set<String>(this.subjectSet);
        String query='SELECT WhatId,Account_Manager__c,Subject,OwnerId,RecordTypeId FROM Task Where Status!=\'Completed\' AND Status!=\'Cancelled\' AND Subject IN:subjectSet';
        
        //HRP-12333 start
        if(whatIdList!=null && tasKIdList!=null)
        {
            query+=' AND WhatId IN:whatIdList AND Id IN:tasKIdList';
        }
        else if(whatIdList!=null)
        {
            query+=' AND WhatId IN:whatIdList';
            
        }
        else if(tasKIdList!=null)
        {
            query+=' AND Id IN:tasKIdList';
        }
        //HRP-12333 end
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Task> scope)
    {
        Map<String,String> taskoppmap = new Map<String,String>();
        List<Task> updatedtasklist = new List<Task>();
        set<Id> oppIdset = new set<Id>();
        
        //HRP-12333 start
        Set<Id> orderIdSet = new Set<Id>();
        Map<Id,String> siteIdCollNameMap = new Map<Id,String>();
        set<string> collNameSet = new Set<String>();
        Map<String,Id> collNameQueIdMap = new Map<String,Id>();
        Map<Id,Id> orderIdOppIdMap = new Map<Id,Id>();
        Boolean marketTaskPresent=false;
        //HRP-12333 end
        Id drdSystemUserId;
        List<User> drdUsers = [SELECT Id, Name FROM User WHERE Name =:BSF_constants.DRDSystemUser AND IsActive = true LIMIT 1];
        if(!drdUsers.isEmpty())
        {
            drdSystemUserId = drdUsers[0].Id;
        }
        
        for(Task tk:scope)
        {
            oppIdset.add(tk.WhatId);
            taskoppmap.put(tk.Id,tk.WhatId);
            //HRP-12333 start
            if(tk.Subject==BSF_Constants.PUBLICITY_REVIEW_NEEDED_TASK)
            {
                OrderIdSet.add(tk.WhatId);
            }
            if(tk.Subject==BSF_Constants.MARKETING_EXCEPTION_TASK && !marketTaskPresent)
                marketTaskPresent = true;
            //HRP-12333 end
        }
        
        //HRP-12333 start
        if(!OrderIdSet.isEmpty())
        {
            List<Order> orderList =[select id,OpportunityId from Order where Id IN :OrderIdSet];
            for(Order o:orderList)
            {
                orderIdOppIdMap.put(o.Id,o.OpportunityId);
                oppIdset.add(o.OpportunityId);
            }
        }
        
        List<Opportunity> Opplist=[SELECT Id,AccountId,Drive_Date__c,Drive_site__c,ownerId,Account_Manager__c,(Select Id,OpportunityId,TeamMemberRole,UserId from OpportunityTeamMembers where opportunityId in:oppIdset) FROM Opportunity Where Id IN:oppIdset];// AND Drive_Date__c>=:date5];//HRP-12333 opportunity team child query
        Map<Id,List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id,List<OpportunityTeamMember>>();//HRP-12333
        Map<Id,Opportunity> oppIdMap = new Map<Id,Opportunity>();
        Map<Id,Id> oppIdDriveSiteIdMap = new Map<Id,Id>();
        for(Opportunity opp:Opplist)
        {
            
            oppIdMap.put(opp.Id,opp);
            //HRP-12333 start
            oppIdDriveSiteIdMap.put(opp.Id,opp.Drive_site__c);
            if(opp.OpportunityTeamMembers!=null)
                oppTeamMembersMap.put(opp.id,opp.OpportunityTeamMembers);
            //HRP-12333 end
        }
        
        
        //HRP-12333 start
        if(marketTaskPresent)
        {
            List<Sked_Site_Collection_Operation__c> siteCollOpList = [select id,sked_Site__c,sked_Start_Date__c,sked_End_Date__c,sked_collection_operation__r.Name from Sked_Site_Collection_Operation__c where sked_Site__c in :oppIdDriveSiteIdMap.values() and sked_Start_Date__c<=today and sked_end_Date__c>=Today];
            for(Sked_Site_Collection_Operation__c sColl:siteCollOpList)
            {
                siteIdCollNameMap.put(sColl.sked_Site__c,sColl.sked_collection_operation__r.Name);
                collNameSet.add(sColl.sked_collection_operation__r.Name+': DMDCR');
            }
            system.debug('collNameSet '+collNameSet);
            List<Group> queueList = [Select id,Name from Group where Name in:collNameSet];
            system.debug('queueList '+queueList);
            for(Group grp:queueList)
            {
                collNameQueIdMap.put(grp.name.subStringbefore(':'),grp.id);
            }
        }
        //HRP-12333 end
        
        for(Task tsk: scope)
        {
            //HRP-12333 start
            if(this.subjectassigntoMap.containsKey(tsk.Subject))
            {
                Id owner;
                if(this.subjectassigntoMap.get(tsk.Subject)==BSF_Constants.ACCOUNT_MANAGER && 
                   (oppIdMap.containsKey(tsk.whatId) || (tsk.Subject==BSF_Constants.PUBLICITY_REVIEW_NEEDED_TASK && orderIdOppIdMap!=null && orderIdOppIdMap.containsKey(tsk.whatId))))
                {
                    Opportunity opp;
                    if(tsk.Subject!=BSF_Constants.PUBLICITY_REVIEW_NEEDED_TASK)
                    {
                        opp=oppIdMap.get(tsk.whatId);
                    }
                    else 
                    {
                        Opp= oppIdMap.get(orderIdOppIdMap.get(tsk.whatId));
                    }
                    if(Opp!=null)
                        owner=opportunityService.getTaskOwner(Opp,oppTeamMembersMap,this.subjectassigntoMap.get(tsk.Subject));
                }
                else if(tsk.Subject==BSF_Constants.MARKETING_EXCEPTION_TASK)
                {
                    if(oppIdDriveSiteIdMap.containsKey(tsk.WhatId) && siteIdCollNameMap.containsKey(oppIdDriveSiteIdMap.get(tsk.WhatId)) && 
                       collNameQueIdMap.containsKey(siteIdCollNameMap.get(oppIdDriveSiteIdMap.get(tsk.WhatId))))
                    {
                        system.debug(tsk.whatId);
                        system.debug(collNameQueIdMap.get(siteIdCollNameMap.get(oppIdDriveSiteIdMap.get(tsk.WhatId))));
                        owner= collNameQueIdMap.get(siteIdCollNameMap.get(oppIdDriveSiteIdMap.get(tsk.WhatId)));
                    }
                    
                    
                }
                //HRP-16955 start
                if(owner == null && drdSystemUserId != null)
                {
                    owner = drdSystemUserId;
                }
                //HRP-16955 end
                
                if(owner != null && tsk.OwnerId!=owner)
                {
                    tsk.OwnerId = owner;
                    updatedtasklist.add(tsk);
                }
                
            }
            
        }
        
        
        if(updatedtasklist.size()>0)
        {
           // Database.SaveResult[] saveupdatedtasklist = Database.update(updatedtasklist); one bad record will not fail the whole batch chunk
           Database.SaveResult[] saveupdatedtasklist = Database.update(updatedtasklist, false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(saveupdatedtasklist,'Task Sync','BSF_BatchTaskSync','execute','Error','Error in Syncing Task');
            InsertBsfErrorLog.insertBsfErrors(logList);
            System.debug('logList'+logList);
        }
        
        
        
    }
    global void finish(Database.BatchableContext BC)
    {
        //HRP-12333 start
        if(!Test.isRunningTest() && this.isAll)
            DataBase.executebatch(new BSF_Batch_CreateHandOffTasks());
        //HRP-12333 End
    }
    
    //HRP-12333 start
    Private Void getMetaData()
    {
        for(Task_Reassignment_Matrix__mdt tm :Task_Reassignment_Matrix__mdt.getAll().values())
        {
            if(tm.Category__c==BSF_constants.opportunityTasks)
            {
                this.subjectassigntoMap.put(tm.Task_Subject__c,tm.Assigned_To__c);
                this.subjectSet.add(tm.Task_Subject__c);
            }
            
        }
        
    }
    //HRP-12333 End
}