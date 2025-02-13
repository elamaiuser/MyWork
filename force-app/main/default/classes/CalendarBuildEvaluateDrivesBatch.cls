/***************************************************************************************************************************************
 * Description:     
 		*  This is a batch job for "Calendar Build".  
 		* It runs every night and evaluates previously completed/cancelled/confirmed drives (maintaining an offset of 21 days from drive date)
 		   and rolls them over to next year.  
 		* It then performs various criteria evaluations and identifies each rolled over drive as either "qualifed" or "unqualifed" followed by
 		  Drive Generation process which generates DOC in Draft(Mobile) or Confirmed(Fixed Site) status.
 		* It then triggers Resource Allocation Batch(equipment for FS and equipment + Vehicle for mobile) 
  		  for FS drives immediately. 
        * Above batch will run daily (Chained from finish method for sys gen - FS) for mobile drives 
          maintaining an offset of 21 days from the CB Opportunity Roll date.
  
 * Modification Log:    
 * ---------------------------------------------------------------------------------------------------------------------------------
 *  Date                  Author                 Brief Mod Description
 * 04/28/21            Fitsum Worku            Initial Code Creation
 * 07/27/23		       Fitsum Worku		       HRP-10179 sending email notification if there is an error during draft drive generation
 * 02/05/24		        Priti Jana		       Added Type,DriveStatus__c fields in the initial query (HRP-11814)
 * 06/07/24             Priti Jana             Added Slot_Generator__c field in the initial query (HRP-12011)
 * 08/06/24             Priti Jana             Logic for HRP-12706 (Restructured)
 * 01/29/25             Priti Jana             Logic for HRP-11368
 ************************************************************************************************************************************/

 global class CalendarBuildEvaluateDrivesBatch implements Database.Batchable<Opportunity>, Database.Stateful, Schedulable {

    private Set<Id> lstCBOpps = new Set<Id>(); 
    private Set<Id> errorLogIdsCreatedDuringBatchRun = new Set<Id>();
    private Map<String, List<BSF_Error_Log__c>> map_driveType_failureLogDetails = new  Map<String, List<BSF_Error_Log__c>>();
    private DriveGenerationUtil.CalendarBuildLogWrapper cbLogWrapper;
    private String runType = '';
    private Date driveDateToEval;
    private String opportunitySource;
    private String bookingStrategy;
    private Boolean byPassDriveGeneration = false; 

    /* @Reference : 
     		* CreatedBy : Priti Jana
			* CreatedDate : 1/29/2025
			* CreatedFor : HRP-11368
    * @Description : 
     		* This constructor will be used for running Adhoc CB Batch by Sys Admin/ Global Admin/ Specific Users
            * It can be used for both the type of drives
    *  @Parameters : 
            * CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput : User inputs containing booking strategy, list of opps and Source as Adhoc Calendar Build
    *   @Error Handling : 
            * Log the issue in BSF Error Log
            * Send error notification to BSF Support Team
            * Log the same issue in CB Error log with Parent CB Log record where CB Batch Status = Error
	*/

    public CalendarBuildEvaluateDrivesBatch(CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput input) {
        try {
            this.runType = BSF_Constants.RUN_TYPE_MANUAL;
            this.bookingStrategy = input.bookingStrategy;
            this.opportunitySource = input.opportunitySource; //Adhoc Calendar Build
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(NULL, BSF_Constants.BATCH_CALENDAR_BUILD, this.runType);
            cbLogWrapper.opportunitySource = this.opportunitySource;
            Map<Id, Opportunity> map_eligibleOppsId_oppDetails = new Map<Id, Opportunity>(input.selectedOpportunities);
            List<Opportunity> lstOppsWithParentCB = new List<Opportunity>([SELECT Id, Calendar_Build_Parent_Opportunity__c 
                                                                            FROM Opportunity 
                                                                            WHERE Calendar_Build_Parent_Opportunity__c IN :map_eligibleOppsId_oppDetails.keySet()
                                                                            AND StageName NOT IN (:BSF_Constants.STAGE_CANCELLED)
                                                                        ]);
            Set<Id> parentCbIds = new Set<Id>();
            if(lstOppsWithParentCB != null && lstOppsWithParentCB.size() > 0) {
                for(Opportunity oppWithParentCB : lstOppsWithParentCB) {
                    parentCbIds.add(oppWithParentCB.Calendar_Build_Parent_Opportunity__c);
                }
            }

            cbLogWrapper.eligibleOpportunityForCbList = new List<Opportunity>();
            cbLogWrapper.map_driveType_eligibleOppList = new Map<String, List<Opportunity>>();
            for(Opportunity opp : map_eligibleOppsId_oppDetails.values()) {
                if(!parentCbIds.contains(opp.Id)) { 
                    cbLogWrapper.eligibleOpportunityForCbList.add(opp);
                    if(!cbLogWrapper.map_driveType_eligibleOppList.containsKey(opp.Type_of_Drive__c)) {
                        cbLogWrapper.map_driveType_eligibleOppList.put(opp.Type_of_Drive__c, new List<Opportunity>());
                    }
                    cbLogWrapper.map_driveType_eligibleOppList.get(opp.Type_of_Drive__c).add(opp);
                }
            }
        } catch(Exception ex) {
            sendErrorNotification(new Map<Exception, String>{ex => ''}, new Map<Id, String>());
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                NULL, 
                BSF_Constants.BATCH_CALENDAR_BUILD, 
                BSF_Constants.RUN_TYPE_MANUAL
            );
            cbLogWrapper.apexMethodName = 'Constructor Call for Manual Adhoc CB Run';
            cbLogWrapper.opportunitySource = input.opportunitySource;
            cbLogWrapper.eligibleOpportunityForCbList = new List<Opportunity>();
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);    
        }
    }

    /* @Reference : 
     		* CreatedBy : Priti Jana
			* CreatedDate : 8/6/2024
			* CreatedFor : HRP-12706
    * @Description : 
     		* This constructor will be used for running CB Batch on demand
            * It can be used for both the type of drives
    *  @Parameters : 
            * manualRunDate : Drive Date or complete/cancel/confirmed drives
    *   @Error Handling : 
            * Log the issue in BSF Error Log
            * Send error notification to BSF Support Team
            * Log the same issue in CB Error log with Parent CB Log record where CB Batch Status = Error
	*/

    global CalendarBuildEvaluateDrivesBatch(Date manualRunDate) {
        try {
            this.driveDateToEval = manualRunDate;
            this.runType = BSF_Constants.RUN_TYPE_MANUAL;
            this.opportunitySource = BSF_Constants.OPP_SOURCE_CALENDAR_BUILD;
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(manualRunDate, BSF_Constants.BATCH_CALENDAR_BUILD, this.runType);
            cbLogWrapper.opportunitySource = this.opportunitySource;
            cbLogWrapper = CalendarBuildBatchHandler.getEligibleOppsToRunCb(cbLogWrapper);
        } catch(Exception ex) {
            sendErrorNotification(new Map<Exception, String>{ex => ''}, new Map<Id, String>());
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                manualRunDate, 
                BSF_Constants.BATCH_CALENDAR_BUILD, 
                BSF_Constants.RUN_TYPE_MANUAL
            );
            cbLogWrapper.apexMethodName = 'Constructor Call for Manual Run';
            cbLogWrapper.opportunitySource = BSF_Constants.OPP_SOURCE_CALENDAR_BUILD;
            cbLogWrapper.eligibleOpportunityForCbList = new List<Opportunity>();
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);    
        }
    }

    /* @Reference : 
     		* ModifiedBy : Priti Jana
			* ModifiedDate : 8/6/2024
			* ModifiedFor : HRP-12706
    * @Description : 
     		* This constructor will be used during scheduled run of CB
            * It can be used for both the type of drives
    *  @Parameters : 
            * N/A
    *   @Error Handling : 
            * Log the issue in BSF Error Log
            * Send error notification to BSF Support Team
            * Log the same issue in CB Error log with Parent CB Log record where CB Batch Status = Error
	*/
    
    global CalendarBuildEvaluateDrivesBatch() {
        System.debug('Entered CalendarBuildEvaluateDrivesBatch');
        try {
            Calendar_Build_Setting__mdt cbMetadata = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
            Decimal daysAfterDriveCompletion = cbMetadata?.No_of_Days_for_Calendar_Build_Batch__c;
            this.byPassDriveGeneration = cbMetadata?.Bypass_Auto_Drive_Generation__c;
            this.runType = BSF_Constants.RUN_TYPE_SCHEDULED;
            this.opportunitySource = BSF_Constants.OPP_SOURCE_CALENDAR_BUILD;
            if(daysAfterDriveCompletion != null) {
                this.driveDateToEval = BSF_Constants.CURRENT_DATE.addDays(-daysAfterDriveCompletion.intValue()); 
            } else {
                this.driveDateToEval = BSF_Constants.CURRENT_DATE.addDays(-21); 
            }
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(this.driveDateToEval, BSF_Constants.BATCH_CALENDAR_BUILD, this.runType);
            cbLogWrapper.opportunitySource = this.opportunitySource;
            cbLogWrapper = CalendarBuildBatchHandler.getEligibleOppsToRunCb(cbLogWrapper);
        } catch(Exception ex) {
            sendErrorNotification(new Map<Exception, String>{ex => ''}, new Map<Id, String>());
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                BSF_Constants.CURRENT_DATE.addDays(-21), 
                BSF_Constants.BATCH_CALENDAR_BUILD, 
                BSF_Constants.RUN_TYPE_SCHEDULED
            );
            cbLogWrapper.apexMethodName = 'Constructor Call for Scheduled Run';
            cbLogWrapper.opportunitySource = BSF_Constants.OPP_SOURCE_CALENDAR_BUILD;
            cbLogWrapper.eligibleOpportunityForCbList = new List<Opportunity>();
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);           
        }
    }

    global Iterable<Opportunity> start(Database.BatchableContext bc) {
        return cbLogWrapper.eligibleOpportunityForCbList;
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> eligibleOppList) {
   
        Map<Exception, String> common_exception_map = new Map<Exception, String>();
    	Map<Id, String> dml_error_map = new Map<Id, String>(); 
        List<BSF_Error_Log__c> bsfErrorLogToInsertList = new List<BSF_Error_Log__c>();

        try {
            for(Opportunity opp : eligibleOppList) {
                opp.Booking_Strategy__c = this.bookingStrategy;
                opp.Source__c = this.opportunitySource;
            }
            List<Opportunity> lstOpps = CalendarBuildBatchHandler.cloneDrives(eligibleOppList);
            lstCBOpps.add(lstOpps[0].Calendar_Build_Parent_Opportunity__c);
            if(lstOpps != NULL && lstOpps.size() > 0 ) {
                Database.SaveResult[] clonedOppInsertResultList = Database.insert(lstOpps, false);
                for(Database.SaveResult sr : clonedOppInsertResultList) {
                    Integer i = 0;
                    if(!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
							BSF_Error_Log__c errorLog = new BSF_Error_Log__c(
                            	Process_Name__c = BSF_Constants.BATCH_CALENDAR_BUILD,
                                Functionality__c = BSF_Constants.BATCH_CALENDAR_BUILD+' - '+lstOpps.get(i).Type_of_Drive__c,
                				ApexClass__c = 'CalendarBuildEvaluateDrivesBatch',
                				Method__c = 'Execute Method Call',
                				Type__c = 'Error',
                                Object_Name__c = String.valueOf(lstOpps.get(i).Calendar_Build_Parent_Opportunity__c.getSobjectType()),
                                Object_RecordId__c = lstOpps.get(i).Calendar_Build_Parent_Opportunity__c,
                				Error_Description__c = err.getMessage().length() > 255 ? err.getMessage().subString(0, 255) : err.getMessage(),
                				Error_Description_Long__c = err.getStatusCode() + '\nFields ::: ' + err.getFields()
                            );
                            bsfErrorLogToInsertList.add(errorLog);
                            if(!map_driveType_failureLogDetails.containsKey(lstOpps.get(i).Type_of_Drive__c)) {
                                map_driveType_failureLogDetails.put(lstOpps.get(i).Type_of_Drive__c, new List<BSF_Error_Log__c>());
                            }
                            map_driveType_failureLogDetails.get(lstOpps.get(i).Type_of_Drive__c).add(errorLog);           
                    		dml_error_map.put(lstOpps.get(i).Calendar_Build_Parent_Opportunity__c ,'<tr><td>'+errorLog.ApexClass__c + ', ' + errorLog.Method__c + ' : ' + errorLog.Error_Description__c + ' : ' + err.getMessage()+' Field: '+err.getFields()+'</td><td>'+sr.getId()+'</td></tr>'); // HRP-10179
                        }
                    }
                    i++;
                }
            }
            Database.SaveResult[] logInsertResult = Database.insert(bsfErrorLogToInsertList, FALSE);
            errorLogIdsCreatedDuringBatchRun.addAll(BSF_Utilities.getSuccessfullySavedRecordIds(logInsertResult));
        } catch(Exception ex) {
            BSF_Error_Log__c errorLogToInsert = BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'CalendarBuildEvaluateDrivesBatch',
                'Execute Method Call',
                BSF_Constants.BATCH_CALENDAR_BUILD,
                BSF_Constants.BATCH_CALENDAR_BUILD+' - '+(eligibleOppList!= NULL ? eligibleOppList.get(0).Type_of_Drive__c : 'No Opps found'),
                'Opportunity',
                eligibleOppList != NULL ? eligibleOppList[0].Id : NULL
            );
            bsfErrorLogToInsertList.add(errorLogToInsert);
            if(eligibleOppList != NULL) {
                if(!map_driveType_failureLogDetails.containsKey(eligibleOppList[0].Type_of_Drive__c)) {
                    map_driveType_failureLogDetails.put(eligibleOppList[0].Type_of_Drive__c, new List<BSF_Error_Log__c>());
                }
                map_driveType_failureLogDetails.get(eligibleOppList[0].Type_of_Drive__c).add(errorLogToInsert);
            }
            Database.SaveResult[] logInsertResult = Database.insert(bsfErrorLogToInsertList, FALSE);
            errorLogIdsCreatedDuringBatchRun.addAll(BSF_Utilities.getSuccessfullySavedRecordIds(logInsertResult));
            common_exception_map.put(ex, '');  //HRP-10179
        }
        
     	//Start HRP-10179   
        if(!common_exception_map.isEmpty() || !dml_error_map.isEmpty()) {
            sendErrorNotification(common_exception_map, dml_error_map);
        }
        //End HRP-10179
    }

    global void finish(Database.BatchableContext bc) {
        //HRP-12706 --> Starts Here
        try {
            if(!cbLogWrapper.eligibleOpportunityForCbList.isEmpty()) {
                if(cbLogWrapper.batchException == NULL) {
                    cbLogWrapper.eligibleFsOppCount = cbLogWrapper.map_driveType_eligibleOppList.get(BSF_Constants.FIXED_SITE_DRIVE) != NULL ? (Decimal)cbLogWrapper.map_driveType_eligibleOppList.get(BSF_Constants.FIXED_SITE_DRIVE).size() : 0;
                    cbLogWrapper.eligibleMobileOppCount = cbLogWrapper.map_driveType_eligibleOppList.get(BSF_Constants.MOBILE_DRIVE) != NULL ? (Decimal)cbLogWrapper.map_driveType_eligibleOppList.get(BSF_Constants.MOBILE_DRIVE).size() : 0;
                    cbLogWrapper.fsOpportunitiesFailureCount = map_driveType_failureLogDetails.get(BSF_Constants.FIXED_SITE_DRIVE) != NULL ? (Decimal)map_driveType_failureLogDetails.get(BSF_Constants.FIXED_SITE_DRIVE).size() : 0;
                    cbLogWrapper.mobileOpportunitiesFailureCount = map_driveType_failureLogDetails.get(BSF_Constants.MOBILE_DRIVE) != NULL ? (Decimal)map_driveType_failureLogDetails.get(BSF_Constants.MOBILE_DRIVE).size() : 0;
                    cbLogWrapper.fsOpportunitiesCreated = cbLogWrapper.eligibleFsOppCount - cbLogWrapper.fsOpportunitiesFailureCount;
                    cbLogWrapper.mobileOpportunitiesCreated = cbLogWrapper.eligibleMobileOppCount - cbLogWrapper.mobileOpportunitiesFailureCount;
                    cbLogWrapper.errorLogIdsCreatedDuringBatchRun = errorLogIdsCreatedDuringBatchRun != NULL ? errorLogIdsCreatedDuringBatchRun : new Set<Id>();
                    DriveGenerationUtil.captureCbLogAndCbErrorLog(cbLogWrapper);
                }
                if(cbLogWrapper.opportunitySource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD)) {
                DateTime dt = Helper.getSameDayOfNextYear(cbLogWrapper.driveDateToEval);
                driveDateToEval = Date.newInstance(dT.year(), dT.month(), dT.day());
                }
                
                if(!this.byPassDriveGeneration) {
                    List<Opportunity> oppListToGenerateDrivesFor = CalendarBuildBatchHandler.getEligibleDrivesToRunCb(
                        opportunitySource, 
                        driveDateToEval, 
                        lstCBOpps
                    );
                    CreateSkedDrivesBatch driveGenBatchInstance = new CreateSkedDrivesBatch(
                        cbLogWrapper.runType, 
                        opportunitySource,
                        driveDateToEval, 
                        oppListToGenerateDrivesFor
                    );
                    Database.executeBatch(driveGenBatchInstance, 1);
                }
            }
        } catch(Exception ex) {
            sendErrorNotification(new Map<Exception, String>{ex => ''}, new Map<Id, String>()); 
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                this.driveDateToEval,
                BSF_Constants.BATCH_CALENDAR_BUILD, 
                this.runType
            );
            cbLogWrapper.apexMethodName = 'Finish Method Call';
            cbLogWrapper.opportunitySource = this.opportunitySource;
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);  
        }
        //HRP-12706 --> Ends Here
    }
    
    global void execute(SchedulableContext scon) {
      Database.executeBatch(new CalendarBuildEvaluateDrivesBatch(), 1);
   	}
    
    @testvisible private static void sendErrorNotification(Map<Exception, String> commonExMap, Map<Id, String> dmlErrMap ) {
        List<String> emailIds = System.label.BSF_SUPPORT_EMAIL_ID.split(',');
        String oweFromAddress = System.label.BSF_OWEA_SENDER;
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address= :oweFromAddress];
        if(!owea.isEmpty()) {
            Helper.sendEmail(commonExMap, dmlErrMap, emailIds, owea[0].Id, true, 'Error in CB Drive Creation');
        }
    }
}