/* 
* @description: This is a Platform Trigger called from AccountTeamMemberSerive; the logic updates opportunity team based on account team considering drive date
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 01/03/2024                 Balaji N					 Logic for HRP-10569 (Method call AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates to get the future team info)
* 08/28/2024				 Balaji N					 Logic for HRP-13340
* 20/06/2025                 Harika Bolisetti            Logic for HRP-15121
* 08/20/2025                 Satyendra Vishwakarma       Logic for HRP-15577 - Fix for BSF_Batch_OpportunityTeamSync getting triggerred multiple times
************************************************************************************************************************************************
*/
trigger Add_Update_OpptyTeamMembers on UpdateOpptyTeamEvent__e (After Insert) {
    
    Set<Id>  setOfacctTeamMemberIdsInsert = new Set<Id>();
    Set<Id> setOfacctTeamMemberIdsUpdate = new Set<Id>();
    Set<string> accountIds = new Set<string>();
    Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers=new Map<Id,List<AccountTeamMember>>();    
    Date startDate;
    Date endDate;
    for (UpdateOpptyTeamEvent__e event : Trigger.New) 
    {
        accountIds.add(string.valueof(event.AcctTeamMemberId__c));
        //HRP-13340 start
        if(startDate == null || (startDate != null && event.Start_Date__c < startDate))
            {
                startDate = event.Start_Date__c;
            }
            
            if(endDate == null || (endDate != null && event.End_Date__c > endDate))
            {
                endDate = event.End_Date__c;
            }
        //HRP-13340 end
    }
    
    if(!accountIds.isEmpty()){        
        List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(accountIds,'Populate Account Team','Add_Update_OpptyTeamMembers','Platform_event Trigger','Success','The Platform Event Fired for the Oppty Team Ids');
        if(!successList.isEmpty())
     {
          try{
         insert successList;
         }
         catch (exception e)
         {
             system.debug('The exception in successList: '+e);
         }
     }
    List<AccountTeamMember> listOfAcctteammembers=[SELECT Id,AccountId,Account.Account_Manager__c,account.District_Manager__c,UserId, TeamMemberRole, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, Start_Date__c, End_Date__c, Coverage_Reason__c, Is_Covering_Recruiter__c, 
                                                   BSF_Portfolio__c FROM AccountTeamMember where AccountId IN:accountIds order by createddate desc];
    
    for(AccountTeamMember atmRecord:listOfAcctteammembers){   
        if(mapOfAcctsWithTeamMembers.containsKey(atmRecord.AccountId)){
            List<AccountTeamMember> listOfExistAcctTeamMembers= mapOfAcctsWithTeamMembers.get(atmRecord.AccountId);
            listOfExistAcctTeamMembers.add(atmRecord);
            mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,listOfExistAcctTeamMembers);
        } else {       
            mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,new List<AccountTeamMember>{atmRecord});     
        }
    }
    
    if(!mapOfAcctsWithTeamMembers.isEmpty()){
        //AccountTeamMemberService.addAcctTeamMembers_To_BloodDriveOpptyMembers(mapOfAcctsWithTeamMembers,true,Trigger.New.size());
        //HRP-10569 start
        list<id> accIdList = new list<id>(mapOfAcctsWithTeamMembers.keyset());
        map<id,list<accountTeamMember>> accIdFutureAccTeamMap = new map<id,list<accountTeamMember>>();
        AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(accIdList,BSF_constants.BYPASS_TEAMDML,new set<id>(),accIdFutureAccTeamMap,new map<id,list<accountTeamMember>> ());
        
        for(id i:mapOfAcctsWithTeamMembers.keyset())
        {
            if(accIdFutureAccTeamMap != null && accIdFutureAccTeamMap.containsKey(i))
            {
                mapOfAcctsWithTeamMembers.get(i).addAll(accIdFutureAccTeamMap.get(i));
            }
        }
        //HRP-15121
        if(BSF_Utilities.metaDataupdate(null,null,null,'Opportunity_Team_Sync_Batch').By_Pass_Batch__c)
        {
            System.debug('HRP-Sync add_update 78:'+BSF_Utilities.metaDataupdate(null,null,null,'Opportunity_Team_Sync_Batch').By_Pass_Batch__c);
            //HRP-10569 End
            Database.executeBatch(new BSF_Batch_OpportunityTeamSync(mapOfAcctsWithTeamMembers,Trigger.New.size(),startDate,endDate),Integer.Valueof(System.Label.OpportunityTeamSyncTriggerSize));//HRP-13340
        }
    } 
    //HRP-15205 --> In case of accounts with no team members
    else {
        Integer runningJobCount = 0;
        if(String.isNotBlank(System.label.PortfolioAssignmentBatchNames)) {
            List<String> portfolioAssignmentBatches = System.label.PortfolioAssignmentBatchNames.split(',');
            List<String> batch_Status = Custom_Messages__mdt.getInstance('BSF_BatchProcessingStatuses').value__c.split(',');
            runningJobCount = [SELECT Count() 
                                FROM AsyncApexJob 
                                WHERE ApexClass.Name IN: portfolioAssignmentBatches
                                AND Status IN: batch_Status];
        }
        
        List<Portfolio_Accounts_Processing__c> portfolioAccProcessingRecord = [SELECT Id, Portfolio_progress_for_Accounts__c, 
                                                                               Records_Processed__c, Portfolio_Assignment_Updated__c 
                                                                               FROM Portfolio_Accounts_Processing__c];
        if((Test.isRunningTest() || runningJobCount == 0) && portfolioAccProcessingRecord != NULL && !portfolioAccProcessingRecord.isEmpty()) {
            update new Portfolio_Accounts_Processing__c(
                Id = portfolioAccProcessingRecord[0].Id,
                Records_Processed__c = portfolioAccProcessingRecord[0].Records_Processed__c ?? 0 + Trigger.New.size()
            );
        }
    }
        
    }  
}