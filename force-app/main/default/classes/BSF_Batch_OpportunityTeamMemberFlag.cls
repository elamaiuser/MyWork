global class BSF_Batch_OpportunityTeamMemberFlag implements Database.Batchable<sObject>{
	global List<Opportunity> opportunityList;
    global List<Account> accountList;
    
    global BSF_Batch_OpportunityTeamMemberFlag(){
      this.opportunityList = new List<Opportunity>();
      this.accountList = new List<Account>();
    }
    
    global BSF_Batch_OpportunityTeamMemberFlag(List<Opportunity> opportunityList){
      this.opportunityList = opportunityList;
    }
    
    global BSF_Batch_OpportunityTeamMemberFlag(List<Account> accountList){
      this.accountList = accountList;
    }
    
  	global Database.QueryLocator start(Database.BatchableContext BC)
  	{
     String opportunityQuery = 'SELECT Id,AccountId,Drive_Date__c FROM Opportunity WHERE Drive_Date__c != null ';
     if(this.opportunityList != null && this.opportunityList.size() > 0){
      opportunityQuery = opportunityQuery + ' AND Id IN :opportunityList ';
     }else if(this.accountList != null && this.accountList.size() > 0){
      opportunityQuery = opportunityQuery + ' AND AccountId IN :accountList ';
     }
  	 
     return Database.getQueryLocator(opportunityQuery);
  }
 
  global void execute(Database.BatchableContext bc, List<Opportunity> opportunities)
  {
   	  Map<Id,Set<Id>> accountTeamMap = new Map<Id,Set<Id>>();
      List<OpportunityTeamMember> opptyTeamListToUpdate = new List<OpportunityTeamMember>();
      List<Id> accountIds = new List<Id>();
      
      for(Opportunity oppty : opportunities){
          accountIds.add(oppty.AccountId);
      }
      
      for(AccountTeamMember actTeamMember : [SELECT Id,UserId,AccountId FROM AccountTeamMember WHERE AccountId IN :accountIds]){
          if(!accountTeamMap.containsKey(actTeamMember.AccountId)){
              accountTeamMap.put(actTeamMember.AccountId,new Set<Id>());
          }
          accountTeamMap.get(actTeamMember.AccountId).add(actTeamMember.UserId);
      } 
      
      for(OpportunityTeamMember opptyTeamMember : [SELECT Id,UserId,OpportunityId,Opportunity.AccountId FROM OpportunityTeamMember WHERE OpportunityId IN :opportunities]){
          if(accountTeamMap.containsKey(opptyTeamMember.Opportunity.AccountId)){
              if(accountTeamMap.get(opptyTeamMember.Opportunity.AccountId).contains(opptyTeamMember.UserId)){
                  opptyTeamMember.is_AccountTeammember__c = true;
                  opptyTeamListToUpdate.add(opptyTeamMember);
              }
          }
      }
      
      Database.SaveResult[] updateResults = Database.update(opptyTeamListToUpdate,false);
      //Log errros in BSF_Error_Log__c
      
  }
    
  global void finish(Database.BatchableContext BC)
  {
       //Capture finish method entry in Error Log
  }
    
}