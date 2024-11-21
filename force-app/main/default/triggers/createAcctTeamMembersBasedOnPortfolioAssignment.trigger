/* 
* @description: This class is called from PortfolioAssignmentService for After Insert/Update/Delete context
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 11/07/2023                 Balaji N					 Logic for HRP-11290(Object_Name__c new field in Event; commented method call "PortfolioAssignmentService.createAccountTeamMembers"
added method call "AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates")
* 01/04/2024                 Balaji N			         Logic for HRP-10569(parameter changes on accTeamDateSyncOnAccPortUpdates method call)

************************************************************************************************************************************************
*/
trigger createAcctTeamMembersBasedOnPortfolioAssignment on PortfolioAssignmentEvent__e (After Insert) {
    
    Set<Id>  setOfPortfoliAssMemberIds = new Set<Id>();
    list<Id>  accountIdList = new list<Id>(); //HRP-11290   
    
    
    for (PortfolioAssignmentEvent__e event : Trigger.New) {     
        if (event.id__c !=null && event.Object_Name__c == 'Account')//HRP-11290
        {
            //HRP-11290
            if(!accountIdList.contains(event.id__c))
                accountIdList.add((event.id__c));
            //HRP-11290
            
            if (event.id__c !=null && event.Operation__c=='Insert') {
                setOfPortfoliAssMemberIds.add(event.id__c);
            }
        }
    }
    //HRP-11290 start
    if(!accountIdList.isEmpty())
    {
        insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='PortfolioAssignmentEvent__e',Method__c='createAcctTeamMembersBasedOnPortfolioAssignment',Type__c='Success',Error_Description__c='PE Size '+String.valueOf(trigger.new.size()));
        
        AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(accountIdList,null,new set<id>(),new map<id,list<AccountTeamMember>>(),new map<id,list<accountTeamMember>> ());//HRP-10569 added 3rd parameter
        
        //PortfolioAssignmentService.createAccountTeamMembers(listOfPortAssignmnets);   //HRP-11290 commented
     }
    //HRP-11290 end
    if(!setOfPortfoliAssMemberIds.isEmpty())
    {
        List<Portfolio_Assignment__c> listOfPortAssignmnets=[SELECT Id, OwnerId, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, BSF_Portfolio__c, End_Date__c, Start_Date__c, User__c, Assignment_Type__c 
                                                             FROM Portfolio_Assignment__c where Id IN:setOfPortfoliAssMemberIds ];
        PortfolioAssignmentService.assignPermissionSetWhenUserIsAM(listOfPortAssignmnets);
    }
}