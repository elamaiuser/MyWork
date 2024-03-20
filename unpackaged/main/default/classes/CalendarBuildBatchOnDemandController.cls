/**************************************************************************************************************************************
 * 
 * Description:     This is an aura component controller class for the "CalendarBuildExecuteBatchOnDemand".  It handles the two 
 * 					Calendar Build buttons that are availalbe when a user clicks on "Run Calendar Build"; one for creating draft
 * 					drives and another for system generate/resource allocation
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 04/28/21     Fitsum Worku        Initial Code Creation 
 * 07/26/23     Fitsum Worku		Updates per HRP-10179 make the batch sizes configurable via a custom metadata type
 * 
 **************************************************************************************************************************************/

public with sharing class CalendarBuildBatchOnDemandController {
    
    @AuraEnabled
    public static Id executeBatchJob() {
        try {
        	   
            Calendar_Build_Setting__mdt mdtGenerateDraftDrives = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        	Integer batchSize = mdtGenerateDraftDrives?.Draft_Drives_Batch_Size__c.intValue();
            Id batchJobId = Database.executeBatch(new CalendarBuildEvaluateDrivesBatch(), batchSize);
            return batchJobId;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    @AuraEnabled
    public static Id executeBatchUpdateJob() {
        try {
             
            Calendar_Build_Setting__mdt mdtSytemGenerateDraftDrives = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        	Integer batchSize = mdtSytemGenerateDraftDrives?.System_Gen_Drives_Batch_Size__c.intValue();
            Id batchJobId = Database.executeBatch(new CalendarBuildUpdateDrivesBatch(), batchSize);
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
    public static Integer getDraftDrivesBatchSize(){
		Calendar_Build_Setting__mdt mdtGenerateDraftDrives = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer batchSize = mdtGenerateDraftDrives?.Draft_Drives_Batch_Size__c.intValue();
        return batchSize;
    }
    
    @AuraEnabled
    public static Integer getSysGenDrivesBatchSize(){
		Calendar_Build_Setting__mdt mdtSytemGenerateDraftDrives = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer batchSize = mdtSytemGenerateDraftDrives?.System_Gen_Drives_Batch_Size__c.intValue();
        return batchSize;
    }
}