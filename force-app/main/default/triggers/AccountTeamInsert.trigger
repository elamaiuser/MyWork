trigger AccountTeamInsert on AccTeamFromPortfolioAssignmentService__e (after insert) 
{
    List<AccTeamFromPortfolioAssignmentService__e> accTeamEveList = new List<AccTeamFromPortfolioAssignmentService__e>();
    accTeamEveList.addall(trigger.New);
    system.debug('AccountTeamInsert');
    set<string> accTeamIDSet = new set<string>();
    List<AccountTeamMember> teamMemberList = new List<AccountTeamMember>();
    for(AccTeamFromPortfolioAssignmentService__e accTeamEve :accTeamEveList)
    {
        AccountTeamMember teamMember = new AccountTeamMember();
        teamMember.AccountId = accTeamEve.AccountId__c;
        teamMember.UserId =  accTeamEve.UserId__c;
        teamMember.Start_Date__c = accTeamEve.Start_Date__c;
        teamMember.End_Date__c = accTeamEve.End_Date__c;
        teamMember.AccountAccessLevel = accTeamEve.AccountAccessLevel__c;
        teamMember.CaseAccessLevel = accTeamEve.CaseAccessLevel__c;
        teamMember.OpportunityAccessLevel = accTeamEve.OpportunityAccessLevel__c;
        teamMember.TeamMemberRole = accTeamEve.TeamMemberRole__c;
        teamMember.BSF_Portfolio__c = accTeamEve.BSF_Portfolio__c;
        teamMemberList.add(teamMember);
        accTeamIDSet.add('Accid:'+teamMember.AccountId+'_'+'atmId:'+teamMember.UserId);
        
        
    }
    List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(accTeamIDSet,'Populate Account Team','AccountTeamInsert','Platform_event Trigger','Success','The Platform Event Fired for the DM Team Ids accountid+UserID');
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
    
    if(teamMemberList.size()>0)
    {
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
         Database.UpsertResult[] atmResult=Database.upsert(teamMemberList,false);//dml for security
        for(Database.upsertResult result:atmResult) 
        {
            
         if(!result.isSuccess())
         {
             system.debug('Error');
             system.debug('ID: '+result.getId()+'  ERROR: '+result.getErrors()+'   CREATED: '+ result.isCreated());
             
         }
         
        }
        	List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(atmResult, 'Create Portfolio','PortfolioAssignmentService','createSingleLevelPortfolioRecords','Error','Error in upserting   DM accTeam ');
            InsertBsfErrorLog.insertBsfErrors(logList);
    }
}