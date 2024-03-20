trigger createOpptyTeamMembersBasedOnOppties on OpportunityTeamMemberEvent__e (After Insert) {

Set<string>  setOfOpptyIds = new Set<string>();    
for (OpportunityTeamMemberEvent__e event : Trigger.New) {     
      if (event.OpportunityId__c !=null ) {
      setOfOpptyIds.add(string.valueof(event.OpportunityId__c));
    }
 }
    List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(setOfOpptyIds,'Create Oppty Team','createOpptyTeamMembersBasedOnOppties','Platform_event Trigger','Success','The oppty from Oppty service id');
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
    if(!setOfOpptyIds.isEmpty()){
     List<Opportunity> listOfOppties=[SELECT Id, OwnerId,Drive_Date__c, AccountId  FROM Opportunity where Id IN:setOfOpptyIds ];
      OpportunityService.AddOpptyTeamMembers_Migration(listOfOppties);   
        
   }

}