trigger UpdateAcctTeamMembersBasedOnPortfoliotDatesUpdate on PortfolioAssignmentUpdateEvent__e (after insert) {
/*List<AccountTeamMember> listOfAcctTeamMembersToUpdate=new List<AccountTeamMember>();
    set<string> accTeamIDSet = new set<string>();
for (PortfolioAssignmentUpdateEvent__e event : Trigger.New) {     
        if (event.AccountTeamMemberId__c!=null ) {
            AccountTeamMember atmRecord=new AccountTeamMember();
            atmRecord.Id=event.AccountTeamMemberId__c;
            atmRecord.Start_Date__c=event.StartDate__c;
            atmRecord.End_Date__c=event.EndDate__c;
            listOfAcctTeamMembersToUpdate.add(atmRecord);
            accTeamIDSet.add(string.valueof(atmRecord.Id));
        }
    }
    
    List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(accTeamIDSet,'Populate Account Team','AccountTeamInsert','Platform_event Trigger','Success','The Platform Event Fired for the DM Team Ids');
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
    
    if(!listOfAcctTeamMembersToUpdate.isEmpty()){
      System.debug('EnteredInto UpdateAcctTeamMembersBasedOnPortfoliotDatesUpdate  ===');
      //PortfolioAssignmentService.updateacctTeammembers(listOfAcctTeamMembersToUpdate);
    
    }*/

}