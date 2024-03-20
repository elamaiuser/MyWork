trigger CBCreateDriveServicesRole on CBDriveServicesRoleAssignmentEvent__e (After Insert) {
    
    Set<Id> setOfOpportunityIds = new Set<Id>();
    
    For(CBDriveServicesRoleAssignmentEvent__e event : Trigger.New) {
        if(event.OpportunityId__c != null) {
            setOfOpportunityIds.add(event.OpportunityId__c);
        }
    }
    
    if(!setOfOpportunityIds.isEmpty()) {
        List<Opportunity> listOfCBOpportunities = [SELECT Id, Parent_Template_Id__c FROM Opportunity WHERE Id IN:setOfOpportunityIds];
        //Call helper method to process
        OpportunityService.AssignDriveSerivcesRoleForCBOpps(listOfCBOpportunities);
    }
}