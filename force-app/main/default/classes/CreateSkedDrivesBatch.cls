/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
  **************************************************************************
 * 05/11/2023				  Krapy Tuli			 Logic for HRP-10009
 * 10/5/2023                  Priti Jana             Logic for HRP-11027
 * 08/09/2024				  Raktim Ghosal			 Logic for HRP-12706
 * 01/31/2025                 Priti Jana             Logic for HRP-11368 
 *****************************************************************************
*/
global class CreateSkedDrivesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global String optyIdForDriveGeneration; // HRP-11027
    private DriveGenerationUtil.CalendarBuildLogWrapper cbLogWrapper;
    private String driveSource = '';
    private String runType;
    private Date driveDateToEval;
    
    /*HRP-12706 --> Starts Here
    /* @Reference : 
     		* CreatedBy : Raktim Ghosal
			* CreatedDate : 8/9/2024
			* CreatedFor : HRP-12706
    * @Description : 
     		* This constructor will be used for running drive generation Batch on demand/scheduled
            * It can be used for both the type of drives
            * This constructor is called from CB Batch
    *  @Parameters : 
            * runType: Scheduled/Manual
            * Source : Calendar Build / Adhoc / Business Planning / Adhoc Calendar Build / NULL
            * driveDateToEval : Drive Date For newly created CB Drives
            * incomingOpportunities : List of Opportunities for Scheduled and manual run with a specific drive date
    *   @Error Handling : 
            * Log the issue in BSF Error Log
            * Send error notification to BSF Support Team
            * Log the same issue in CB Error log with Parent CB Log record where CB Batch Status = Error
	*/
    global CreateSkedDrivesBatch(String runType, String source, Date driveDateToEval, List<Opportunity> incomingOpportunities) {
        try{
            this.driveDateToEval = driveDateToEval;
            this.driveSource = source;
            this.runType = runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_SCHEDULED) ? BSF_Constants.RUN_TYPE_SCHEDULED : BSF_Constants.RUN_TYPE_MANUAL;
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(NULL, BSF_Constants.BATCH_DRIVE_GENERATION, this.runType);
            cbLogWrapper.eligibleOpportunityForDriveGenList = (incomingOpportunities != NULL && incomingOpportunities.size() > 0) ?
                    											incomingOpportunities :
            													CalendarBuildBatchHandler.getEligibleDrivesToRunCb(this.driveSource, this.driveDateToEval, NULL);
            if(this.driveSource != NULL && !String.isBlank(this.driveSource)) {
                cbLogWrapper.opportunitySource = this.driveSource;
                if(this.driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD)) {
                    if(this.driveDateToEval == NULL) {
                        this.driveDateToEval = cbLogWrapper.eligibleOpportunityForDriveGenList[0].Drive_Date__c;
                    }
                    DateTime dt = Helper.getSameDayOfPrevYear(this.driveDateToEval);
                    cbLogWrapper.driveDateToEval = Date.newInstance(dT.year(), dT.month(), dT.day());
                } 
            } 
    	} catch(Exception ex) {
            if(source != NULL && !String.isBlank(source) && source.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD)) { //No need for Adhoc CB drives
                DateTime dt = Helper.getSameDayOfPrevYear(driveDateToEval);
                this.driveDateToEval = Date.newInstance(dT.year(), dT.month(), dT.day());
            }
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                this.driveDateToEval, 
                BSF_Constants.BATCH_DRIVE_GENERATION, 
                runType
            );
            cbLogWrapper.apexMethodName = 'Constructor Call for Scheduled Run';
            cbLogWrapper.opportunitySource = source;
            cbLogWrapper.eligibleOpportunityForDriveGenList = new List<Opportunity>();
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);    
        }
    }

	//Constructor that runs drive generation batch for a particular list of opportunities
    global CreateSkedDrivesBatch(List<Opportunity> incomingOpportunities) {
        try{
            if(!incomingOpportunities.isEmpty() || incomingOpportunities.size() > 0) {
                cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper();
                cbLogWrapper.eligibleOpportunityForDriveGenList = incomingOpportunities;
            }
    	} catch(Exception ex) {
            insert BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'CreateSkedDrivesBatch',
                'Constructor Call',
                BSF_Constants.BATCH_DRIVE_GENERATION,
                BSF_Constants.BATCH_DRIVE_GENERATION+' from Plan a Drive Flow',
                'sked_Drive__c',
                ''
            );
        }
    }
    
    global List<Opportunity> start(Database.BatchableContext bc) {
        return cbLogWrapper.eligibleOpportunityForDriveGenList;
    }
    //HRP-12706 --> Continues
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        try {
            Drive_Generator_Selector__mdt mdtDriveGeneratorSelector = Drive_Generator_Selector__mdt.getInstance('Active_Setting');
            String source = mdtDriveGeneratorSelector.Drive_Generator_To_Use__c;
            if (source.toLowerCase() == 'exavalu') {
                optyIdForDriveGeneration = String.valueOf(scope[0].Id); // HRP-11027
                DriveGeneratorService.generateDrivesOnOppInsert(scope);
            }
        } catch (Exception e) {
            // HRP-11027 --> Starts Here 
            List<sked_Drive__c> drivesCreated = [select Id from sked_Drive__c where sked_Opportunity__c =:optyIdForDriveGeneration];
            if(drivesCreated.isEmpty()) {
                DriveGenerationErrorHandler.notifyUsersUponFailureAndLogErrors(e, optyIdForDriveGeneration, NULL, Constants.TECHNICAL_ISSSUE, Constants.DRIVE_GEN_BATCH, Constants.BATCH_METHOD);
            } 
            // HRP-11027 --> Ends Here 
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        try {
            Set<Id> errorLogOppRecordIDSet = new Set<Id>();
            Set<Id> skedFixedDrives = new Set<Id>();
            Set<Id> skedMobileDrives = new Set<Id>();
            Set<Id> fsDriveGenerationFailure = new Set<Id>();
            Set<Id> mobileDriveGenerationFailure = new Set<Id>();
            Map<Id, sked_Drive__c> map_relatedDriveOppId_driveInfo = new  Map<Id, sked_Drive__c>();
            Map<Id, Opportunity> map_oppId_oppInfo = new Map<Id, Opportunity>(cbLogWrapper.eligibleOpportunityForDriveGenList);

            //HRP-12706 --> Continues
            Map<Id, BSF_Error_Log__c>  map_errorLogId_errorLogInfo = new Map<Id, BSF_Error_Log__c>([SELECT ID, Object_RecordId__c 
                                                                                                    FROM BSF_Error_Log__c
                                                                                                    WHERE Object_RecordId__c != NULL
                                                                                                    AND Object_RecordId__c IN : map_oppId_oppInfo.keySet()
                                                                                                    AND Process_Name__c = :Constants.CATEGORY
                                                                                                    AND CreatedDate = TODAY]);
            
            for(BSF_Error_Log__c getErrorLog: map_errorLogId_errorLogInfo.values()) {
                errorLogOppRecordIDSet.add(getErrorLog.Object_RecordId__c);
            }

            List<sked_Drive__c> docCreatedList = new List<sked_Drive__c>(
                [SELECT Id, sked_Status__c, sked_Type_of_Drive__c, sked_Opportunity__c 
                FROM sked_Drive__c 
                WHERE sked_Opportunity__c IN :map_oppId_oppInfo.keySet()]);
                
            if(docCreatedList != NULL && !docCreatedList.isEmpty()) {
                Database.executeBatch(new skedDriveRankingBatch(runType, driveSource, this.driveDateToEval, docCreatedList), 1);
                for(sked_Drive__c drive : docCreatedList) {
                    map_relatedDriveOppId_driveInfo.put(drive.sked_Opportunity__c, drive);
                }
            }

            for(Opportunity newOpp : cbLogWrapper.eligibleOpportunityForDriveGenList) {
                if (map_relatedDriveOppId_driveInfo != NULL && map_relatedDriveOppId_driveInfo.containsKey(newOpp.Id)) {
                    if(newOpp.Type_of_Drive__c.equalsIgnoreCase(Constants.FIX_SITE_OPP)) {
                        skedFixedDrives.add(newOpp.Id);
                    } else {
                        skedMobileDrives.add(newOpp.Id);
                    }
                } else {
                    if (errorLogOppRecordIDSet != NULL && !errorLogOppRecordIDSet.isEmpty() && errorLogOppRecordIDSet.contains(newOpp.Id)) {
                        if(newOpp.Type_of_Drive__c.equalsIgnoreCase(Constants.FIX_SITE_OPP)) {
                            fsDriveGenerationFailure.add(newOpp.Id);
                        } else {
                            mobileDriveGenerationFailure.add(newOpp.Id);
                        }
                    }
                }       
            }
		 
            //Create the Drive Affliation records for the Calendar Build Opps
            Map<Id,Opportunity> cbOppMap = new Map<Id,Opportunity>();
            for(Opportunity cbOpp : cbLogWrapper.eligibleOpportunityForDriveGenList) {
                cbOppMap.put(cbOpp.Id, cbOpp);
            }
            OpportunityService.createDriveAffiliations(cbLogWrapper.eligibleOpportunityForDriveGenList, cbOppMap);
            
            //Publish platform event to create the Drive Service Role record for each cloned opportunity based on the template
            List<CBDriveServicesRoleAssignmentEvent__e> dsrEvents = new List<CBDriveServicesRoleAssignmentEvent__e>();
            for(Opportunity newOpp : cbLogWrapper.eligibleOpportunityForDriveGenList) {
                CBDriveServicesRoleAssignmentEvent__e dsrEvent = new CBDriveServicesRoleAssignmentEvent__e();
                dsrEvent.OpportunityId__c = newOpp.Id;
                dsrEvents.add(dsrEvent);
            }
            if(dsrEvents.size() > 0) {
                EventBus.publish(dsrEvents);
            }
        
            //HRP-12706 --> Continues (Capturing the necessary info of the fields to log in the Calendar build Log Object)
            if(!String.isBlank(this.driveSource) 
                && (this.driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD) || this.driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_ADHOC_CALENDAR_BUILD))
             ) {
                cbLogWrapper.fsDriveGenerationCount = skedFixedDrives != NULL ? skedFixedDrives.size() : 0;
                cbLogWrapper.mobileDriveGenerationCount = skedMobileDrives!= NULL ? skedMobileDrives.size() : 0;
                cbLogWrapper.fsDriveGenerationFailureCount = fsDriveGenerationFailure!= NULL ? fsDriveGenerationFailure.size() : 0;
                cbLogWrapper.mobileDriveGenerationFailureCount = mobileDriveGenerationFailure!= NULL ? mobileDriveGenerationFailure.size(): 0;
                cbLogWrapper.errorLogIdsCreatedDuringBatchRun = map_errorLogId_errorLogInfo != NULL ? map_errorLogId_errorLogInfo.keySet() : new Set<Id>();
                DriveGenerationUtil.captureCbLogAndCbErrorLog(cbLogWrapper);
            }
        } catch(Exception ex) {
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                this.driveDateToEval,
                BSF_Constants.BATCH_DRIVE_GENERATION, 
                this.runType
            );
            cbLogWrapper.apexMethodName = 'Finish Method Call';
            cbLogWrapper.opportunitySource = driveSource;
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);  
        }
        //HRP-12706 --> Ends Here
    }
}