trigger DeleteAcctTeamMembersBasedOnPortfoliotDelete  on PortfolioAssignmentDeleteEvent__e (After Insert) {
/*
Set<string> setOfAcctTeamMemberids=new Set<string>();
for (PortfolioAssignmentDeleteEvent__e event : Trigger.New) {     
        if (event.AccountTeamMemberId__c!=null ) {
            setOfAcctTeamMemberids.add(string.valueof(event.AccountTeamMemberId__c));
        }
    }
    
    List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(setOfAcctTeamMemberids,'Populate Account Team','DeleteAcctTeamMembersBasedOnPortfoliotDelete','Platform_event Trigger','Success','The accountTeamDeleteIds');
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
    
    if(!setOfAcctTeamMemberids.isEmpty()){
    
       List<AccountTeamMember> listOfAcctTeamMembersTodelete= [select id from AccountTeamMember where Id IN:setOfAcctTeamMemberids];
       if(!listOfAcctTeamMembersTodelete.isEmpty()){
          //PortfolioAssignmentService.deletePortfolioAssignedMembersfromAccountTeam(listOfAcctTeamMembersTodelete);
        //Database.DeleteResult[] deleteResults = Database.delete(listOfAcctTeamMembersTodelete,false);
       }
    }

*/
}