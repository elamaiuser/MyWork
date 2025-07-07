/*
* Description: New Class has been introduced as part of HRP-11908 to hold wrapper classes and utilize them in drive generation process
 
* Modification Log 
* Date					     Developer Name			     Comments
**************************************************************************
* 06/05/2024				  Priti Jana		    Created for HRP-11908
* 08/05/2024				  Priti Jana			Logic for HRP-12706
**************************************************************************/

public class DriveGenerationUtil {

    public class TimeConfigurationModel {
        public string resourceRoleGroup;
        public decimal travelTime;
        public decimal leadTime;
        public decimal setupTime;
        public decimal breakDownTime;
        public decimal wrapUpTime;
        public decimal travelTime2;
        public decimal siteLogisticsBack; // HRP-11226
        public decimal siteLogisticsTo; // HRP-11226
        public decimal travelTimeCoToSiteVariance;
        public decimal travelTimeSiteToCoVariance;

        public TimeConfigurationModel() {
            this.leadTime = 0;
            this.setupTime = 0;
            this.breakDownTime = 0;
            this.wrapUpTime = 0;
            this.travelTime = 0;
            this.travelTime2 = 0;
            this.siteLogisticsTo = 0;
            this.siteLogisticsBack = 0;
            this.travelTimeCoToSiteVariance = 0;
            this.travelTimeSiteToCoVariance = 0;
        }

        public Object get(String fieldName) {
            if(fieldName.equalsIgnoreCase('leadTime')) return this.leadTime;
            if(fieldName.equalsIgnoreCase('setupTime')) return this.setupTime;
            if(fieldName.equalsIgnoreCase('breakdownTime')) return this.breakdownTime;
            if(fieldName.equalsIgnoreCase('wrapUpTime')) return this.wrapUpTime;
            if(fieldName.equalsIgnoreCase('siteLogisticsTo')) return this.siteLogisticsTo;
            if(fieldName.equalsIgnoreCase('siteLogisticsBack')) return this.siteLogisticsBack;
            if(fieldName.equalsIgnoreCase('travelTime')) return this.travelTime;
            if(fieldName.equalsIgnoreCase('travelTime2')) return this.travelTime2;
            return null;
        }
    }

    public class TravelTimeSettingModel {
        public Boolean isNoTravelTimeChecked;
        public Decimal travelTimeCOToSite;
        public Decimal travelTimeSiteToCO;
        public List<String> resourceRoleGroupsNeededTravelTime;
        public String travelTimeIncludedForFixedSite;
        public String travelTimeIncludedForMobile;
        public Map<String, String> map_driveType_travelTimeIncludedFor;
    
        public TravelTimeSettingModel() {
            this.isNoTravelTimeChecked = FALSE;
            this.travelTimeCOToSite = 0;
            this.travelTimeSiteToCO = 0;
            this.resourceRoleGroupsNeededTravelTime = new List<String>();
            this.map_driveType_travelTimeIncludedFor = new Map<String, String>();
            this.travelTimeIncludedForFixedSite = 'Drivers Only';
            this.travelTimeIncludedForMobile = 'All Roles';
        }
    }
    
    /* @Reference : 
     		* CreatedBy : Priti Jana
			* CreatedDate : 8/5/2024
			* CreatedFor : HRP-12706
     * @Description : 
     		* This utility method will return a list of CB Log/CB Log Manual Run as required
     		* Method is used in captureCbLogAndCbErrorLog(...)
     * @Method Parameters : 
     		* Wrapper class instance
	*/
    public static List<sObject> getCalendarBuildLogRecord(CalendarBuildLogWrapper cbLogWrapper) {
        string externalId = cbLogWrapper.externalId;
        
        String query = ' SELECT Id, Drive_Date__c, External_Id__c, ';
        if(cbLogWrapper.batchInfo.equalsIgnoreCase('Calendar Build')) {
            query += 'CB_Batch_Status__c, CB_Batch_Execution_Date__c, '+
                      'CB_FS_Eligible_Opportunity_Count__c, CB_FS_Opportunities_Created__c, CB_FS_Opportunities_Failure_Count__c, '+
                      'CB_Mobile_Eligible_Opportunity_Count__c, CB_Mobile_Opportunities_Created__c, CB_Mobile_Opportunities_Failure_Count__c ';
        } else if(cbLogWrapper.batchInfo.equalsIgnoreCase('Drive Generation')) {
            query += 'Drive_Gen_Batch_Status__c, Drive_Gen_Batch_Execution_Date__c, '+
                      'FS_Drive_Generation_Count__c, FS_Drive_Generation_Failure_Count__c, '+
                      'Mobile_Drive_Generation_Count__c, Mobile_Drive_Generation_Failure_Count__c ';
        } else if(cbLogWrapper.batchInfo.equalsIgnoreCase('Drive Status Correction')) {
            query += 'Status_Correction_Batch_Status__c, Status_Correction_Batch_Execution_Date__c, '+
                      'Status_Correction_Batch_Drive_Count__c, Final_State_Drive_Count__c, Open_Drive_Count__c, '+
                      'Corrected_Drive_Count__c, Op_Record_Count__c, Submitted_Op_Record_Count__c, Not_Submitted_Op_Record_Count__c ';
        } else if(cbLogWrapper.batchInfo.equalsIgnoreCase('Sys Gen Run - FS')) {
            query += 'FS_Sys_Gen_Batch_Run_Status__c, FS_Sys_Gen_Batch_Run_Date__c, '+
                      'FS_Drives_with_Resource_Allocation__c, FS_Drives_wo_Resource_Allocation__c, FS_Drives_Failed_Processing__c, FS_Drives_wo_Resource_Requested__c ';
        } else {
            query += 'Mobile_Sys_Gen_Batch_Run_Status__c, Mobile_Sys_Gen_Batch_Run_Date__c, '+
                      'Mobile_Drives_with_Resource_Allocation__c, Mobile_Drives_wo_Resource_Allocation__c, Mobile_Drives_Failed_Processing__c, Mobile_Drives_wo_Resource_Requested__c ';
        }
        query += cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL) ? ', Source__c FROM Calendar_Build_Log_Manual_Run__c ' : 'FROM Calendar_Build_Log__c ';
        query += 'WHERE External_Id__c = :externalId LIMIT 1';
        return Database.query(query);
    }
	
    /* @Reference : 
     		* CreatedBy : Priti Jana
			* CreatedDate : 8/5/2024
			* CreatedFor : HRP-12706
     * @Description : 
     		* This utility method will capture CB Logs, CB Manual Logs (manual run / adhoc CB run) and CB Error Logs
     		* Method can be called from finish method of every related CB batch
     * @Method Parameters : 
     		* Wrapper class instance
	  * @DMLs : 
	  		* Insert/Update CB Log
			* Insert/Update CB Log Manual Run (if runType == 'Manual')
			* Insert CB Error Log
	*/
    public static void captureCbLogAndCbErrorLog(CalendarBuildLogWrapper cbLogWrapper) {
        List<Calendar_Build_Error_Log__c> cbErrorLogListToInsert = new List<Calendar_Build_Error_Log__c>();
        try {
            if(cbLogWrapper.batchInfo.equalsIgnoreCase(BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION)
                || (cbLogWrapper.opportunitySource != NULL 
                    && !String.isBlank(cbLogWrapper.opportunitySource) 
                    && cbLogWrapper.opportunitySource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD)) //Ignore below assignments for Adhoc CB drives
            ) {
                String driveDateToEvalString = cbLogWrapper.driveDateToEval.format();
                DateTime sameDateTimeNextYear = Helper.getSameDayOfNextYear(cbLogWrapper.driveDateToEval);
                Date newDate = Date.newInstance(sameDateTimeNextYear.year(), sameDateTimeNextYear.month(), sameDateTimeNextYear.day());
                cbLogWrapper.formattedDate = newDate.format();
                cbLogWrapper.name = cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL) ? 'Calendar Build Log Manual Run - ' : 'Calendar Build Log - ';
                cbLogWrapper.name = cbLogWrapper.name + driveDateToEvalString;
                cbLogWrapper.externalId = cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL) ? BSF_Constants.CURRENT_DATE+'_'+cbLogWrapper.driveDateToEval+'_'+UserInfo.getUserName() : cbLogWrapper.formattedDate;
            } else {
                cbLogWrapper.name = 'Calendar Build Log Adhoc_Run Date- '+System.today().format();
                cbLogWrapper.externalId = 'Adhoc CB_Run Date- '+System.today().format();
            }
            
            sObject event;
            List<sObject> sObjectList = getCalendarBuildLogRecord(cbLogWrapper);
            if(sObjectList != NULL && sObjectList.size() > 0) {
                event = sObjectList[0];
            } else if(cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL)) {
                event = new Calendar_Build_Log_Manual_Run__c();
            } else if(cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_SCHEDULED)) {
                event = new Calendar_Build_Log__c();
            }
            event.put('Name', cbLogWrapper.name);
            event.put('External_Id__c', cbLogWrapper.externalId);

            if(BSF_Constants.MAP_BATCHINFO_FIELDSTOUPDATE.containsKey(cbLogWrapper.batchInfo)) {
                List<String> fieldsToUpdate = BSF_Constants.MAP_BATCHINFO_FIELDSTOUPDATE.get(cbLogWrapper.batchInfo);
                event.put(fieldsToUpdate[0], cbLogWrapper.batchException != NULL ? BSF_Constants.BATCH_STATUS_ERROR : BSF_Constants.BATCH_STATUS_COMPLETED);
                event.put(fieldsToUpdate[1], BSF_Constants.CURRENT_DATE_TIME);

                //HRP-11368: When Drive Gen Batch completes, set FS & Mobile sys gen status as Not Needed for Adhoc CB
                if(cbLogWrapper.batchInfo.equalsIgnoreCase(BSF_Constants.BATCH_DRIVE_GENERATION) && cbLogWrapper.opportunitySource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_ADHOC_CALENDAR_BUILD)) {
                    fieldsToUpdate.addAll(BSF_Constants.MAP_BATCHINFO_FIELDSTOUPDATE.get(BSF_Constants.BATCH_SYS_GEN_FS));
                    fieldsToUpdate.addAll(BSF_Constants.MAP_BATCHINFO_FIELDSTOUPDATE.get(BSF_Constants.BATCH_SYS_GEN_MOBILE));
                    event.put(fieldsToUpdate[2], BSF_Constants.BATCH_STATUS_NOT_NEEDED);
                    event.put(fieldsToUpdate[3], BSF_Constants.CURRENT_DATE_TIME);
                    event.put(fieldsToUpdate[4], BSF_Constants.BATCH_STATUS_NOT_NEEDED);
                    event.put(fieldsToUpdate[5], BSF_Constants.CURRENT_DATE_TIME);
                }
            }
            
            if(cbLogWrapper.batchException == NULL) {
                if(!String.isBlank(cbLogWrapper.batchInfo) && cbLogWrapper.batchInfo.equalsIgnoreCase(BSF_Constants.BATCH_CALENDAR_BUILD)) {  
                    event.put('CB_FS_Eligible_Opportunity_Count__c', cbLogWrapper.eligibleFsOppCount);
                    event.put('CB_Mobile_Eligible_Opportunity_Count__c', cbLogWrapper.eligibleMobileOppCount);
                    event.put('CB_FS_Opportunities_Created__c', cbLogWrapper.fsOpportunitiesCreated);
                    event.put('CB_Mobile_Opportunities_Created__c', cbLogWrapper.mobileOpportunitiesCreated);
                    event.put('CB_FS_Opportunities_Failure_Count__c', cbLogWrapper.fsOpportunitiesFailureCount);
                    event.put('CB_Mobile_Opportunities_Failure_Count__c', cbLogWrapper.mobileOpportunitiesFailureCount);
                } else if(!String.isBlank(cbLogWrapper.batchInfo) && cbLogWrapper.batchInfo.equalsIgnoreCase(BSF_Constants.BATCH_DRIVE_GENERATION)) {
                    event.put('FS_Drive_Generation_Count__c', cbLogWrapper.fsDriveGenerationCount);
                    event.put('FS_Drive_Generation_Failure_Count__c', cbLogWrapper.fsDriveGenerationFailureCount);
                    event.put('Mobile_Drive_Generation_Count__c', cbLogWrapper.mobileDriveGenerationCount);
                    event.put('Mobile_Drive_Generation_Failure_Count__c', cbLogWrapper.mobileDriveGenerationFailureCount);
                } else if(!String.isBlank(cbLogWrapper.batchInfo) && cbLogWrapper.batchInfo.equalsIgnoreCase(BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION)) {
                    event.put('Status_Correction_Batch_Drive_Count__c', cbLogWrapper.driveCount);
                    event.put('Final_State_Drive_Count__c', cbLogWrapper.finalStateDriveCount);
                    event.put('Open_Drive_Count__c', cbLogWrapper.OpenDriveCount);
                    event.put('Corrected_Drive_Count__c', cbLogWrapper.correctedDriveCount);
                    event.put('Op_Record_Count__c', cbLogWrapper.opRecordCount);
                    event.put('Submitted_Op_Record_Count__c', cbLogWrapper.submittedOpRecordCount);
                    event.put('Not_Submitted_Op_Record_Count__c', cbLogWrapper.notSubmittedOpRecordCount);
                } else if(!String.isBlank(cbLogWrapper.batchInfo) && cbLogWrapper.batchInfo.equalsIgnoreCase(BSF_Constants.BATCH_SYS_GEN_FS)) {
                    event.put('FS_Drives_with_Resource_Allocation__c', cbLogWrapper.fsSysGenDrivesWithAllocResourceCount);
                    event.put('FS_Drives_wo_Resource_Allocation__c', (Decimal) (!cbLogWrapper.drivesWOResourceAllocThoughRequested.isEmpty() ? cbLogWrapper.drivesWOResourceAllocThoughRequested.size() : 0));
                    event.put('FS_Drives_Failed_Processing__c', cbLogWrapper.fsSysGenFailureCount); 
                    event.put('FS_Drives_wo_Resource_Requested__c', cbLogWrapper.fsSysGenDrivesWOResourceRequestedCount);        
                } else if(!String.isBlank(cbLogWrapper.batchInfo) && cbLogWrapper.batchInfo.equalsIgnoreCase(BSF_Constants.BATCH_SYS_GEN_MOBILE)) {
                    event.put('Mobile_Drives_with_Resource_Allocation__c', cbLogWrapper.mobileSysGenDrivesWithAllocResourceCount);
                    event.put('Mobile_Drives_wo_Resource_Allocation__c', (Decimal) (!cbLogWrapper.drivesWOResourceAllocThoughRequested.isEmpty() ? cbLogWrapper.drivesWOResourceAllocThoughRequested.size() : 0));
                    event.put('Mobile_Drives_Failed_Processing__c', cbLogWrapper.mobileSysGenFailureCount);
                    event.put('Mobile_Drives_wo_Resource_Requested__c', cbLogWrapper.mobileSysGenDrivesWOResourceRequestedCount);  
                }
            }
            
            if(cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL)) {
                event.put('Parent_Calendar_Build_Log__c', [SELECT ID FROM Calendar_Build_Log__c WHERE External_Id__c = :cbLogWrapper.formattedDate LIMIT 1]?.Id);
                event.put('Source__c', cbLogWrapper.opportunitySource);
            }
            event.put('Drive_Date__c', cbLogWrapper.driveDateToEval);         
            upsert event;
            
            List<BSF_Error_Log__c> errorLogCreatedDuringBatchRun = [SELECT Id, Error_Description__c, 
                                                                    Object_RecordId__c, Functionality__c
                                                                    FROM BSF_Error_Log__c
                                                                    WHERE Id IN :cbLogWrapper.errorLogIdsCreatedDuringBatchRun];

            for(BSF_Error_Log__c errorLog : errorLogCreatedDuringBatchRun) {
                Calendar_Build_Error_Log__c cbErrorLog = new Calendar_Build_Error_Log__c();
                cbErrorLog.Name = cbLogWrapper.batchInfo+' Error Log_'+(cbLogWrapper.driveDateToEval != NULL ? cbLogWrapper.driveDateToEval.format() : System.today().format()); //for Adhoc CB errors, add the run date in the error log name HRP-11368
                cbErrorLog.BSF_Error_Log__c = errorLog.Id;
                if(cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL)) {
                    cbErrorLog.Calendar_Build_Log_Manual_Run__c = (Id) event.get('Id');
                } else {
                    cbErrorLog.Calendar_Build_Log__c = (Id) event.get('Id');
                }
                cbErrorLog.Category__c = cbLogWrapper.batchInfo;
                cbErrorLog.Error_Information__c = errorLog.Error_Description__c;
                if(BSF_Constants.MAP_BATCHINFO_CBERRORLOGFIELDS.containsKey(cbLogWrapper.batchInfo) && cbLogWrapper.batchException == NULL) {
                    List<String> fieldsToUpdate = BSF_Constants.MAP_BATCHINFO_CBERRORLOGFIELDS.get(cbLogWrapper.batchInfo);
                    if(!errorLog.Functionality__c.containsIgnoreCase('OpRecord')) {
                        cbErrorLog.put(fieldsToUpdate[0], errorLog.Object_RecordId__c);
                    } else {
                        cbErrorLog.put(fieldsToUpdate[1], errorLog.Object_RecordId__c);
                    }
                }
                cbErrorLogListToInsert.add(cbErrorLog);
            }

            if(cbLogWrapper.drivesWOResourceAllocThoughRequested != NULL && !cbLogWrapper.drivesWOResourceAllocThoughRequested.isEmpty()) {
                for(Calendar_Build_Error_Log__c error : cbLogWrapper.drivesWOResourceAllocThoughRequested) {
                    error.Name = cbLogWrapper.batchInfo + ' Error Log_'+(cbLogWrapper.driveDateToEval != NULL ? cbLogWrapper.driveDateToEval.format() : System.today().format());
                    if(cbLogWrapper.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL)) {
                        error.Calendar_Build_Log_Manual_Run__c = (Id) event.get('Id');
                    } else {
                        error.Calendar_Build_Log__c = (Id) event.get('Id');
                    }
                    cbErrorLogListToInsert.add(error);
                }
            }
            insert cbErrorLogListToInsert;

        } catch(Exception ex) {
            insert BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                'DriveGenerationUtil',
                'captureCbLogAndCbErrorLog',
                'Log Capture',
                'CB Log and CB Error Log Recording',
                '',
                ''
            );
        }
    }

    /* @Reference : 
     		* CreatedBy : Priti Jana
			* CreatedDate : 8/5/2024
			* CreatedFor : HRP-12706
     * @Description : 
     		* This wrapper class will be used to capture stats for each CB related batch during CB Process
	*/
    @testVisible
    public class CalendarBuildLogWrapper {
        public String name {get; set;}
        public String opportunitySource {get; set;} //HRP-11368
        public Date driveDateToEval {get; set;}
        public String formattedDate {get; set;}
        public String batchInfo {get; set;}
        public String runType {get; set;}
        public String externalId {get; set;}
        public String apexMethodName {get; set;}
        public List<sObject> sObjectList {get; set;}
        public Exception batchException {get; set;}
        public Set<Id> errorLogIdsCreatedDuringBatchRun {get; set;}
        public List<Calendar_Build_Error_Log__c> drivesWOResourceAllocThoughRequested {get; set;}

        /* Calendar Build Stats */
        public List<Opportunity> eligibleOpportunityForCbList {get; set;}
        public Map<String, List<Opportunity>> map_driveType_eligibleOppList {get; set;}
        public Decimal fsOpportunitiesCreated {get; set;}
        public Decimal fsOpportunitiesFailureCount {get; set;}
        public Decimal mobileOpportunitiesCreated {get; set;}
        public Decimal mobileOpportunitiesFailureCount {get; set;}
        public Decimal eligibleFsOppCount {get; set;}
        public Decimal eligibleMobileOppCount {get; set;}

        /* Drive Generation Stats */
        public List<Opportunity> eligibleOpportunityForDriveGenList {get; set;}
        public Decimal fsDriveGenerationCount {get; set;}
        public Decimal fsDriveGenerationFailureCount {get; set;}
        public Decimal mobileDriveGenerationCount {get; set;}
        public Decimal mobileDriveGenerationFailureCount {get; set;}

        /* System Gen - FS Stats */
		public Decimal fsSysGenCount {get; set;}
        public Decimal fsSysGenFailureCount {get; set;}
        public Decimal fsSysGenDrivesWithAllocResourceCount {get; set;}
        public Decimal fsSysGenDrivesWOResourceRequestedCount {get; set;}
        public Decimal fsSysGenDrivesWOAllocResourceCount {get; set;}

        /* System Gen - Mobile Stats */
        public List<sked_Drive__c> draftDriveListToBeProcessed {get; set;}
        public Decimal mobileSysGenCount {get; set;}
        public Decimal mobileSysGenFailureCount {get; set;}
		public Decimal mobileSysGenDrivesWithAllocResourceCount {get; set;}
        public Decimal mobileSysGenDrivesWOResourceRequestedCount {get; set;}
        public Decimal mobileSysGenDrivesWOAllocResourceCount {get; set;}  
        
        /* Drive Status Correction Stats */
        public Decimal driveCount {get; set;}
        public List<sked_Operation_Record__c> opRecordListToBeSubmitted {get; set;}
        public List<sked_Operation_Record__c> opRecordListToBeProcessed {get; set;}
        public Set<Id> drivesToBeCompleted {get; set;} 
        public Set<Id> driveIdsInCompleteCancelState {get; set;}
        public Decimal finalStateDriveCount {get; set;}
        public Decimal OpenDriveCount {get; set;}
        public Decimal opRecordCount {get; set;}
        public Decimal submittedOpRecordCount {get; set;}
        public Decimal notSubmittedOpRecordCount {get; set;}
        public Decimal correctedDriveCount {get; set;}

        /* Constructors */
        public CalendarBuildLogWrapper() {}
        
        public CalendarBuildLogWrapper(
            Date driveDateToEval, 
            String batchInfo,
            String runType
        ) {
            this.driveDateToEval = driveDateToEval;
            this.batchInfo = batchInfo;
            this.runType = runType;
        } 
    }

    public static void captureErrorLoggingForException(Exception ex, CalendarBuildLogWrapper cbLogWrapper) {
        List<BSF_Error_Log__c> errorLogToInsert = new List<BSF_Error_Log__c>{
            BSF_Utilities.createBsfErrorLogForExceptions(
                ex,
                BSF_Constants.MAP_BATCHINFO_CLASSNAME.get(cbLogWrapper.batchInfo),
                cbLogWrapper.apexMethodName,
                cbLogWrapper.batchInfo,
                cbLogWrapper.batchInfo,
                '',
                ''
            )
        };
        Database.SaveResult[] logInsertResult = Database.insert(errorLogToInsert, FALSE);
        cbLogWrapper.batchException = ex;
        cbLogWrapper.errorLogIdsCreatedDuringBatchRun = BSF_Utilities.getSuccessfullySavedRecordIds(logInsertResult);
        DriveGenerationUtil.captureCbLogAndCbErrorLog(cbLogWrapper);
    }
}