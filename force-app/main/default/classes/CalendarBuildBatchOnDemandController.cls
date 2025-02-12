/**************************************************************************************************************************************
 * 
 * Description:     This is an aura component controller class for the "CalendarBuildExecuteBatchOnDemand".  It handles the two 
 * 					Calendar Build buttons that are availalbe when a user clicks on "Run Calendar Build"; one for creating draft
 * 					drives and another for system generated/resource allocation batch
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 04/28/21     Fitsum Worku        Initial Code Creation 
 * 07/26/23     Fitsum Worku		Updates per HRP-10179 make the batch sizes configurable via a custom metadata type
 * 08/29/24		Priti Jana			Updated batch size to 1 for both CB and Sys Gen batch run from UI button (HRP-12706)
 *                                  Called Resource allocation batch directly after button click
 **************************************************************************************************************************************/

public with sharing class CalendarBuildBatchOnDemandController {
    
    @AuraEnabled
    public static Id executeBatchJob() {
        try {   
            Id batchJobId = Database.executeBatch(new CalendarBuildEvaluateDrivesBatch(), 1); //HRP-12706
            return batchJobId;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    @AuraEnabled
    public static Id executeBatchUpdateJob() {
        try {
            Id batchJobId = Database.executeBatch(new DriveResourceAllocationBatch(BSF_Constants.RUN_TYPE_SCHEDULED, BSF_Constants.BATCH_CALENDAR_BUILD, BSF_Constants.MOBILE_DRIVE, NULL, new Set<Id>()), 1); //HRP-12706
            return batchJobId;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(Id jobID){
        AsyncApexJob jobInfo = [SELECT Status, NumberOfErrors,JobItemsProcessed,TotalJobItems FROM AsyncApexJob WHERE Id = :jobID ];
        return jobInfo;
    }
    
    @AuraEnabled
    public static Integer getDraftDrivesBatchSize() {
		Calendar_Build_Setting__mdt mdtGenerateDraftDrives = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer batchSize = mdtGenerateDraftDrives?.Draft_Drives_Batch_Size__c.intValue();
        return batchSize;
    }
    
    @AuraEnabled
    public static Integer getSysGenDrivesBatchSize() {
		Calendar_Build_Setting__mdt mdtSytemGenerateDraftDrives = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer batchSize = mdtSytemGenerateDraftDrives?.System_Gen_Drives_Batch_Size__c.intValue();
        return batchSize;

    @InvocableMethod(label='Run Adhoc Calendar Build')
    public static void triggerAdhocCBRunAndGetJobId(List<AdhocCalendarBuildInput> adhocCBInput) {
        Adhoc_Calendar_Build_Run__e adhocCbRunEvent = new Adhoc_Calendar_Build_Run__e();
        Map<Id, Opportunity> map_oppId_opportunity = new Map<Id, Opportunity>(adhocCBInput[0].selectedOpportunities);
        adhocCbRunEvent.Booking_Strategy__c = adhocCBInput[0].bookingStrategy;
        adhocCbRunEvent.Opportunity_Source__c = adhocCBInput[0].opportunitySource;
        adhocCbRunEvent.Opportunity_Ids__c = JSON.serialize(map_oppId_opportunity.keySet());
        
        if(adhocCbRunEvent != null) {
            EventBus.publish(adhocCbRunEvent);
        }
    }

    public class AdhocCalendarBuildInput {
        @InvocableVariable(label='Booking Strategy')
        public String bookingStrategy;

        @InvocableVariable(label='Opportunity Source')
        public String opportunitySource;

        @InvocableVariable(label='Selected opportunities')
        public List<Opportunity> selectedOpportunities;
    }
}