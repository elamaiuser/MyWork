trigger Opportunity_Template_Order_Sync_Event_Trigger on Opportunity_Template_Order_Sync_Event__e (After Insert) {

    List<String> oppIds = new List<String>();
    
    For(Opportunity_Template_Order_Sync_Event__e event : Trigger.New) {
        if(event.OpportunityId__c != null) {
            oppIds.add(event.OpportunityId__c);
        }
    }
    
    if(!oppIds.isEmpty()) {
        //Call helper method to process
        OrderCloningService.cloneTemplateOrder(oppIds);
    }

}