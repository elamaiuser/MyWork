/*
* ******************************************************************************************************************************
* Modification Log                                                                                                             *
*  Date                          Developer Name                 Comments                                                       *
* ******************************************************************************************************************************
* 20/05/2024                     Balaji N                   This batch is created part of HRP-11784
*
*/
global class BSF_Batch_CreateHandOffTasks implements Database.Batchable<SObject>,Schedulable
{
    
    Set<String> regionNameSet = new Set<String>();
    Map<String,String> taskSubMdtNameMap = new Map<String,String>();
    Map<Date,List<String>> liveDateRegionListMap = new Map<Date,List<String>>();
    Map<String,Date> regLiveDateMap = new Map<String,Date>();
    List<Task_Reassignment_Matrix__mdt> taskReassignMdtList = new List<Task_Reassignment_Matrix__mdt>();
    
    List<Account_Handoff_Settings__mdt> accHandoffExpiredList = new List<Account_Handoff_Settings__mdt>();
    List<String> eligibleAccountStatusesForTaskCreation;
    User u = [select id from User where name=:BSF_constants.DRDSystemUser];
    
    global void execute(SchedulableContext scon) 
    {
        Database.executeBatch(new BSF_Batch_CreateHandOffTasks(), 200);
    }
    
    global BSF_Batch_CreateHandOffTasks() 
    {
        eligibleAccountStatusesForTaskCreation = new List<String>(System.Label.Eligible_Account_Statuses_for_HandOff_Tasks.split(','));
        
        for(Account_Handoff_Settings__mdt handOff : Account_Handoff_Settings__mdt.getAll().values()) 
        {
            if(handOff.Active__c && (System.today().daysBetween(handOff.Live_date__c) <= Task_Reassignment_Matrix__mdt.getInstance(BSF_constants.currentAMDataReview).Creation_Date_Offset__c || (test.isRunningTest() && handOff.DeveloperName=='TEST'))) 
            {
                liveDateRegionListMap.put(handOff.Live_date__c,new List<String>(handOff.Region_Name__c.split(',')));
                regionNameSet.addAll(handOff.Region_Name__c.split(','));
                for(String s :handOff.Region_Name__c.split(',')) 
                {
                    regLiveDateMap.put(s,handOff.Live_date__c);
                }
            }
            if(handOff.Live_date__c < system.today()) {
                accHandoffExpiredList.add(handOff);
            }
        }
        
        for(Task_Reassignment_Matrix__mdt mt : Task_Reassignment_Matrix__mdt.getAll().values()) 
        {
            if(mt.Category__c == BSF_constants.handOffTasks) 
            {
                taskReassignMdtList.add(mt);
                taskSubMdtNameMap.put(mt.Task_Subject__c,mt.DeveloperName);
            }
        } 
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        String query = 'SELECT Id, DS_Region_Name__c, Zip_Code__c, Start_date__c, End_Date__c FROM Taxonomy__c WHERE DS_Region_Name__c IN :regionNameSet AND RecordType.Name=\'Bio Collection BSF\' ORDER BY Zip_Code__c, DS_Region_Name__c';
        return Database.getqueryLocator(query);
    }
    
    global void execute (Database.batchableContext bc, List<Taxonomy__c> TaxoList) 
    {
        Map<String, Date> zipLiveDateMap = new Map<String, Date>();
        for(Taxonomy__c tx : TaxoList) 
        {
            Date liveDate = regLiveDateMap.get(tx.DS_Region_Name__c);//null check
            if(liveDate !=null && tx.Start_Date__c <= liveDate && tx.End_Date__c >= liveDate) 
            {
                zipLiveDateMap.put(tx.Zip_Code__c,liveDate);
            }
        }
        
        List<Account> accList = [SELECT Id, BillingPostalCode, ShippingPostalCode FROM Account WHERE Account_Status__c IN :eligibleAccountStatusesForTaskCreation AND (billingpostalCode IN:zipLiveDateMap.KeySet() OR ShippingPostalCode IN:zipLiveDateMap.KeySet())];
        Map<Id, Account> accIdMap = new Map<Id, Account>();
        for(Account acc : accList) 
        {
            accIdMap.put(acc.Id,acc);
        }
        
        Map<Id, List<accountTeamMember>> accIdFutureAccTeamMap = new Map<Id, List<accountTeamMember>>();
        Map<Id, List<accountTeamMember>> accIdExistAccTeamMap = new Map<Id, List<accountTeamMember>>();
        accountPortfolioassignmentservice.accTeamDateSyncOnAccPortUpdates(new List<Id>(accIdMap.keyset()),bsf_constants.BYPASS_TEAMDML,new set<id>(),accIdFutureAccTeamMap,accIdExistAccTeamMap);
        
        Set<String> focussedRoleSet = new Set<String>{BSF_constants.ACCOUNT_MANAGER,BSF_constants.AREA_BOOKING_MANAGER,BSF_constants.DISTRICT_MANAGER,BSF_constants.ACCOUNT_SPECIALIST};
        Map<Id, Map<String,AccountTeamMember>> accIdRoleFutureTeamMap = new Map<Id, Map<String,AccountTeamMember>>();
        Map<Id,Map<String,AccountTeamMember>> accIdRoleCurrentTeamMap = new Map<Id,Map<String,AccountTeamMember>>();
        for(id i:accIdExistAccTeamMap.keyset()) 
        {
            if(accIdFutureAccTeamMap != null && accIdFutureAccTeamMap.containsKey(i)) 
            {
                accIdExistAccTeamMap.get(i).addAll(accIdFutureAccTeamMap.get(i));
            }
            
            Map<String,accountTeamMember> accIdFutureAmMap = new Map<String,accountTeamMember>();
            Map<String,accountTeamMember> accIdCurrentTeamMap = new Map<String,accountTeamMember>();
            for(accountTeamMember atm : accIdExistAccTeamMap.get(i)) 
            {
                string zip = zipLiveDateMap.containsKey(accIdMap.get(i).BillingPostalCode)?accIdMap.get(i).BillingPostalCode:accIdMap.get(i).ShippingPostalCode;
                Date liveDate = zipLiveDateMap.get(zip);
                //Future Team 
                if(accIdRoleFutureTeamMap.containsKey(i))
                    accIdFutureAmMap  = accIdRoleFutureTeamMap.get(i);
                if( focussedRoleSet.contains(atm.TeamMemberRole) && atm.Start_Date__c <= liveDate && atm.End_Date__c >= liveDate &&
                   (!accIdFutureAmMap.containsKey(atm.TeamMemberRole) ||(accIdFutureAmMap.containsKey(atm.TeamMemberRole) && (atm.Is_Covering_Recruiter__c ))))
                {
                    accIdFutureAmMap.put(atm.TeamMemberRole,atm);
                }
                accIdRoleFutureTeamMap.put(i,accIdFutureAmMap);
                
                //Current Team
                if(accIdRoleCurrentTeamMap.containsKey(i))
                    accIdCurrentTeamMap = accIdRoleCurrentTeamMap.get(i);
                
                if(focussedRoleSet.contains(atm.TeamMemberRole) && atm.Start_Date__c <= System.Today() && atm.End_Date__c >= System.today() && 
                   (!accIdCurrentTeamMap.containskey(atm.TeamMemberRole) || (atm.is_covering_recruiter__c && accIdCurrentTeamMap.containskey(atm.TeamMemberRole))))
                {
                    accIdCurrentTeamMap.put(atm.TeamMemberRole,atm);
                }
                
                accIdRoleCurrentTeamMap.put(i,accIdCurrentTeamMap);
            }
        }
        
        
        Map<Id,Boolean> accAMChangeMap = new Map<Id,Boolean>();
        for(id i:accIdExistAccTeamMap.keyset())
        {
            AccountTeamMember cAtm=accIdRoleCurrentTeamMap.get(i).containsKey(BSF_constants.ACCOUNT_MANAGER)?accIdRoleCurrentTeamMap.get(i).get(BSF_constants.ACCOUNT_MANAGER):null;
            AccountTeamMember fAtm=accIdRoleFutureTeamMap.get(i).containsKey(BSF_constants.ACCOUNT_MANAGER)?accIdRoleFutureTeamMap.get(i).get(BSF_constants.ACCOUNT_MANAGER):null;
            accAMChangeMap.put(i, false);
            if(cAtm != fAtm)
            {
                accAMChangeMap.put(i,true);      
            }
        }
        
        List<Task> existingTaskList = [Select id, WhatId, WhoId, Subject,OwnerId from Task where WhatId IN:accIdMap.keyset() AND Subject IN:taskSubMdtNameMap.KeySet()];
        Map<String, Task> accIdExstTaskMap = new Map<String, Task>();
        for(Task t:existingTaskList)
        {
            String key = t.WhatId+'_'+taskSubMdtNameMap.get(t.subject);
            accIdExstTaskMap.put(key, t);
        }
        
        Map<Id, List<String>> accIdTaskListMap = new Map<Id, List<String>>();
        Map<String, Id> accIdOwnerMap = new Map<String,Id>();
        for(Account acc : accList)
        {
            if(zipLiveDateMap.containsKey(acc.BillingPostalCode))
            {
                for(String S : taskSubMdtNameMap.values())
                {
                    string zip = zipLiveDateMap.containsKey(accIdMap.get(acc.Id).BillingPostalCode)?accIdMap.get(acc.Id).BillingPostalCode:accIdMap.get(acc.Id).ShippingPostalCode;
                    Date liveDate = zipLiveDateMap.get(zip);
                    Integer diffDate = System.today().daysBetween(zipLiveDateMap.get(acc.BillingPostalCode));
                    
                    if(diffDate <= Task_Reassignment_Matrix__mdt.getInstance(s).Creation_Date_Offset__c || test.isRunningTest())
                    {
                        if(!accIdTaskListMap.containsKey(acc.Id))
                            accIdTaskListMap.put(acc.Id,new List<String>());
                        accIdTaskListMap.get(acc.Id).add(s);
                    }
                    accIdOwnerMap.put(acc.id+'_'+s,findOwnerId(acc.Id,Task_Reassignment_Matrix__mdt.getInstance(S),accIdRoleCurrentTeamMap.get(acc.Id),accIdRoleFutureTeamMap.get(acc.Id)).get(acc.id+'_'+s));
                }
            }
        }
        
        
        List<Task> taskToUpsert = new List<Task>();
        for(Id accId : accIdTaskListMap.KeySet())
        {
            for(String s : accIdTaskListMap.get(accId))
            {
                Account acc = accIdMap.get(accId);
                Task t = new Task(OwnerId = null);
                Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('General Task').getRecordTypeId();
                Task_Reassignment_Matrix__mdt taskMeta = Task_Reassignment_Matrix__mdt.getInstance(S);
                if(BSF_Constants.NoAMChangeTaskList.contains(taskMeta.Label) || (!BSF_Constants.NoAMChangeTaskList.contains(taskMeta.Label) && accAMChangeMap.get(accId)))
                {
                    if(!accIdExstTaskMap.containsKey(accId+'_'+s))
                    {
                        t.Subject = taskMeta.Task_Subject__c;
                        t.Description = taskMeta.Description__c;
                        t.ActivityDate = zipLiveDateMap.get(acc.BillingPostalCode)-Integer.Valueof(taskMeta.Due_Date_Offset__c);
                        t.WhatId =  acc.Id;
                        t.RecordTypeId = recTypeId;
                    }
                    else
                    {
                        t=accIdExstTaskMap.get(accId+'_'+s);
                    }
                    if(t.OwnerId == null ||(t.OwnerId != null && accIdOwnerMap.containsKey(acc.Id+'_'+s) && t.OwnerId != accIdOwnerMap.get(acc.Id+'_'+s)))
                    {
                        t.OwnerId = accIdOwnerMap.get(acc.Id+'_'+s);
                    }
                    
                    taskToUpsert.add(t);
                }
            }
        }
        
        if(!taskToUpsert.isEmpty()) 
        {
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.upsert(taskToUpsert,false), 'Account Handoff Task','BSF_Batch_CreateHandOffTasks','Execute','Error','Error during Task Creation');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
        
    }
    
    global void finish(Database.batchablecontext bc) {
        for(Account_Handoff_Settings__mdt handOff : accHandoffExpiredList) {
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = BSF_constants.HandOffApiName+handOff.DeveloperName;
            customMetadata.label = handOff.MasterLabel;
            
            Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue();
            customField1.field = 'Active__c';
            customField1.value = False;
            customMetadata.values.add(customField1);
            
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);
            
            if(!test.isRunningTest())
            Metadata.Operations.enqueueDeployment(mdContainer, null);
        }
    }
    
    public Map<String,Id> findOwnerId(Id accId, Task_Reassignment_Matrix__mdt taskMeta,Map<String,AccountTeamMember> currentTeamMap,Map<String,AccountTeamMember> newTeamMap)
    {
        Id ownerId;
        boolean abmNotPresent = true;
        if(taskMeta.Assigned_To__c == BSF_constants.ABM2SUPER)
        {
            if(taskMeta.DeveloperName.contains(BSF_constants.Current))
            {
                ownerId=currentTeamMap.containsKey(BSF_Constants.AREA_BOOKING_MANAGER)?currentTeamMap.get(BSF_Constants.AREA_BOOKING_MANAGER).UserId:u.Id;
            }
            else if(taskMeta.DeveloperName.contains(BSF_constants.Newtask))
            {
                ownerId=newTeamMap.containsKey(BSF_Constants.AREA_BOOKING_MANAGER)?newTeamMap.get(BSF_Constants.AREA_BOOKING_MANAGER).UserId:u.Id;
            }
        }
        else if(taskMeta.Assigned_To__c == BSF_constants.ABM)
        {
            abmNotPresent=currentTeamMap.containsKey(BSF_Constants.AREA_BOOKING_MANAGER)?False:True;
            if(!abmNotPresent)
                ownerId=currentTeamMap.get(BSF_Constants.AREA_BOOKING_MANAGER).UserId;               
        }
        
        if((taskMeta.Assigned_To__c == BSF_constants.ABM && abmNotPresent) || taskMeta.Assigned_To__c == BSF_constants.AM)
        {
            if(taskMeta.DeveloperName.contains(BSF_constants.Current) || (taskMeta.Assigned_To__c == BSF_constants.ABM && abmNotPresent))
            {
                ownerId= ownerFromHierachy(currentTeamMap);
            }
            else if(taskMeta.DeveloperName.contains(BSF_constants.Newtask))
            {
                ownerId= ownerFromHierachy(newTeamMap);
            }
        }
        
        return new map<String,Id>{accId+'_'+taskMeta.DeveloperName=>ownerId};
            }
    
    public Id ownerFromHierachy(Map<String,AccountTeamMember> teamMap)
    {
        Id OwnerId;
        
        if(teamMap.containsKey(BSF_Constants.ACCOUNT_MANAGER))
        {
            OwnerId = teamMap.get(BSF_Constants.ACCOUNT_MANAGER).UserId;
        }
        else if(teamMap.containsKey(BSF_Constants.ACCOUNT_SPECIALIST))
        {
            OwnerId = teamMap.get(BSF_Constants.ACCOUNT_SPECIALIST).UserId;
        }
        else if(teamMap.containsKey(BSF_Constants.DISTRICT_MANAGER))
        {
            OwnerId = teamMap.get(BSF_Constants.DISTRICT_MANAGER).UserId;
        }
        else
        {
            OwnerId = u.Id;
        }
        return OwnerId;
    }
}