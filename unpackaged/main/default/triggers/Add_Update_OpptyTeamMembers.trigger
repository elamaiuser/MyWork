trigger Add_Update_OpptyTeamMembers on UpdateOpptyTeamEvent__e (After Insert) {
    
    Set<Id>  setOfacctTeamMemberIdsInsert = new Set<Id>();
    Set<Id> setOfacctTeamMemberIdsUpdate = new Set<Id>();
    Set<string> accountIds = new Set<string>();
    Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers=new Map<Id,List<AccountTeamMember>>();    
    
    for (UpdateOpptyTeamEvent__e event : Trigger.New) {
        accountIds.add(string.valueof(event.AcctTeamMemberId__c));
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
        Database.executeBatch(new BSF_Batch_OpportunityTeamSync(mapOfAcctsWithTeamMembers,Trigger.New.size()),100);
    } 
        
    }
    
   
    
    
}