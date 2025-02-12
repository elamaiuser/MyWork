trigger AdhocCalendarBuildRunEvent on Adhoc_Calendar_Build_Run__e (after insert) {
    List<CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput> cbWrapperInputList = new List<CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput>();
    List<Id> oppIds = new List<Id>();
    for(Adhoc_Calendar_Build_Run__e event : Trigger.new) {
        CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput cbWrapperInput = new CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput();
        cbWrapperInput.opportunitySource = event.Opportunity_Source__c;
        cbWrapperInput.bookingStrategy = event.Booking_Strategy__c;
        oppIds.addAll((List<Id>) JSON.deserialize(event.Opportunity_Ids__c, List<Id>.class));
        cbWrapperInputList.add(cbWrapperInput);
    }
    
    String oppQuery = BSF_Utilities.createDriveQueryForCalendarBuild();
    oppQuery+= ' WHERE ID IN :oppIds';
    cbWrapperInputList[0].selectedOpportunities = Database.query(oppQuery);
    if(cbWrapperInputList[0].selectedOpportunities != NULL && !cbWrapperInputList[0].selectedOpportunities.isEmpty()) {
        Database.executeBatch(new CalendarBuildEvaluateDrivesBatch(cbWrapperInputList[0]), 1);
    }
    
}