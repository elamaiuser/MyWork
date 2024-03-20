/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
  **************************************************************************
 * 05/11/2023				  Krapy Tuli			 Logic for HRP-10009
 * 10/5/2023                  Priti Jana             Logic for HRP-11027
 *****************************************************************************
*/
global class CreateSkedDrivesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    List<Exception> errors = new List<Exception>();
    
    global List<Opportunity> opportunitiesToGenerateDrivesFor;
    global String optyIdForDriveGeneration; // HRP-11027
    
    global CreateSkedDrivesBatch(List<Opportunity> incomingOpportunities)
    {
        // HRP-11027 --> Starts Here 
        if(!incomingOpportunities.isEmpty() || incomingOpportunities.size() > 0)
        {
            opportunitiesToGenerateDrivesFor = incomingOpportunities;
        }
        // HRP-11027 --> Ends Here 
    }
    
    global List<Opportunity> start(Database.BatchableContext bc) {
        return opportunitiesToGenerateDrivesFor;
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        
        try {
            Drive_Generator_Selector__mdt mdtDriveGeneratorSelector = Drive_Generator_Selector__mdt.getInstance('Active_Setting');
            String source = mdtDriveGeneratorSelector.Drive_Generator_To_Use__c;
            if (source.toLowerCase() == 'exavalu')
            {
                optyIdForDriveGeneration = String.valueOf(scope[0].Id); // HRP-11027
                DriveGeneratorService.generateDrivesOnOppInsert(scope);
            }
        } catch (Exception e)
        {
            //errors.add(e);
            // HRP-11027 --> Starts Here 
            List<sked_Drive__c> drivesCreated = [select Id from sked_Drive__c where sked_Opportunity__c =:optyIdForDriveGeneration];
            if(drivesCreated.isEmpty())
            {
                DriveGenerationErrorHandler.notifyUsersUponFailureAndLogErrors(e, optyIdForDriveGeneration, NULL, Constants.TECHNICAL_ISSSUE, Constants.DRIVE_GEN_BATCH, Constants.BATCH_METHOD);
            } 
            // HRP-11027 --> Ends Here 
        }
    }
    
    global void finish(Database.BatchableContext bc)
    {
        
		/*List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
        //If there were errors, log them to BSF Error Log
        if(errors != null && errors.size() > 0) {
            for(Exception errorRec : errors) {
            	BSF_Error_Log__c errorLog = new BSF_Error_Log__c(Process_Name__c = '', ApexClass__c = 'CreateSkedDrivesBatch', Method__c ='Batch Execute', Type__c='', Error_Description__c = errorRec.getMessage().Length() > 2500 ? errorRec.getMessage().subString(0,2500) : errorRec.getMessage(),Error_Description_Long__c = errorRec.getStackTraceString().Length() > 2500 ? errorRec.getStackTraceString().subString(0,2500) : errorRec.getStackTraceString());
                errorLogList.add(errorLog);
            }
			insert errorLogList;
        }*/
        
        //Call batch class that performs Ranking
        //Create a set of Opportunity Ids
        Set<Id> setOppIds = new Set<Id>();
        Set<Id> setOppIdsForFixedSite = new Set<Id>(); //HRP-10009 Start
        for(Opportunity newOpp : opportunitiesToGenerateDrivesFor) {
            setOppIds.add(newOpp.Id);
            //HRP-10009 Start
            if(newOpp.type_of_Drive__c == Constants.FIX_SITE_OPP){
                setOppIdsForFixedSite.add(newOpp.Id);
            }
            //HRP-10009 End
        }        
        
        //Create a map of opportunity -> drives on calendar
        List<sked_Drive__c> driveRecList = [SELECT Id, sked_Status__c, sked_Opportunity__c FROM sked_Drive__c WHERE sked_Opportunity__c IN :setOppIds];
        Set<Id> skedDrives = new Set<ID>();
        if(driveRecList != null && driveRecList.size() > 0){
        	Database.executeBatch(new skedDriveRankingBatch(driveRecList), 1);
            for (sked_Drive__c sd : driveRecList) {
                if (setOppIdsForFixedSite.size() > 0 && sd.sked_Status__c == Constants.DRIVE_STATUS_DRAFT && setOppIdsForFixedSite.contains(sd.sked_Opportunity__c)) {
             		skedDrives.add(sd.Id);
                }
            }
        }
        
        //Create the Drive Affliation records for the Calendar Build Opps
        Map<Id,Opportunity> cbOppMap = new Map<Id,Opportunity>();
        for(Opportunity cbOpp : opportunitiesToGenerateDrivesFor) {
            cbOppMap.put(cbOpp.Id, cbOpp);
        }
        OpportunityService.createDriveAffiliations(opportunitiesToGenerateDrivesFor, cbOppMap);
        
        //Publish platform event to create the Drive Service Role record for each cloned opportunity based on the template
        List<CBDriveServicesRoleAssignmentEvent__e> dsrEvents = new List<CBDriveServicesRoleAssignmentEvent__e>();
        for(Opportunity newOpp : opportunitiesToGenerateDrivesFor) {
            CBDriveServicesRoleAssignmentEvent__e dsrEvent = new CBDriveServicesRoleAssignmentEvent__e();
            dsrEvent.OpportunityId__c = newOpp.Id;
            dsrEvents.add(dsrEvent);
        }
        if(dsrEvents.size() > 0) {
            EventBus.publish(dsrEvents);
        }
        
        //Start logic to see if we are ready to process drives and move them from 'draft' to 'system generated'
        //get # of days after end of month to run the system generated logic
        Calendar_Build_Setting__mdt mdtCBConfig = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfSystemGenBufferDays = mdtCBConfig?.Buffer_Days_For_System_Generated__c.intValue();
        //get automation flag; if on, system gen process runs automatically at the end of the month plus buffer days
        Boolean systemGenAutomation = mdtCBConfig?.Automation_Flag__c;
		//get batch size
		Integer batchSize = mdtCBConfig?.System_Gen_Drives_Batch_Size__c.intValue();
        
        //Get last day of last month
        Date LastDayOfLastMonth = date.Today().toStartOfMonth().addDays(-1);
        //Add the number of buffer days to last day of last month
        Date CBUpdateDate = LastDayOfLastMonth.addDays(numOfSystemGenBufferDays);

        //If today's date = last day of last month + buffer days and automation is turned on, update drives to 'system generated'
        //If this is met, the batch process is going grab *ALL* draft drives that aren't marked as 'do not roll' 
        if(CBUpdateDate == date.Today() && systemGenAutomation) {
            Database.executeBatch(new CalendarBuildUpdateDrivesBatch(), batchSize);
        } 

        //HRP-10009 Start
        if(skedDrives != null && skedDrives.size() > 0){
        	Database.executeBatch(new DriveResourceAllocationBatch(skedDrives), 1);
        }
        //HRP-10009 End
    }
}