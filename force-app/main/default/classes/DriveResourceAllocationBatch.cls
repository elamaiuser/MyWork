/*
* Description: This class is used for allocating resources to Fixed Site and Mobile Drives
** NOTE: Please use skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true if you're doing any sort of modification on DOC (11418)
* */
/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 05/11/2023                  Krapy Tuli                HRP-10009
 * 06/22/2023                  Krapy Tuli                HRP-10212
 * 06/22/2023                  Krapy Tuli                HRP-10213
 * 08/17/2023                  Priti Jana                HRP-10523
 * 10/10/2023                  Krapy Tuli                HRP-11001
 * 11/28/2023                  Krapy Tuli                HRP-11207
 * 12/01/2023                  Krapy Tuli                HRP-11224
 * 1/15/2024                   priti Jana                HRP-11418
 * 01/23/2024                  Krapy Tuli                HRP-11793
 * 03/19/2024				   Priti Jana			     HRP-12338 (Removed extra check for pres donor capacity from resource query)
 * 05/02/2024                  Priti Jana                HRP-12440 (Restructuring class , correction of resource evaluation criteria)
 * 05/14/2024                  Priti Jana                HRP-12386
 * 06/07/2024                  Priti Jana                HRP-12760
 * 08/09/2024                  Priti Jana                HRP-11634
 * 08/09/2024				   Raktim Ghosal			 HRP-12706
 * 09/23/2024                  Krapy Tuli                HRP-13347
 * 01/15/2025				   Barnojit Sharma		     HRP-13864
 * 01/31/2025                  Priti Jana                HRP-11368 
 *****************************************************************************
*/

global with sharing class DriveResourceAllocationBatch extends GenerateMobileDrive.mobileDriveGenerator implements Database.Batchable<sObject>, Database.Stateful {	
    
    public static Date driveDate;
    public static String driveSite = '';
    public static String driveCO = '';
    public static String driveAccount = '';
    public static List<sked__Resource__c> vehicleTypeResource = new  List<sked__Resource__c>();
    public static List<sked__Resource__c> vehicleTypeResourceForCDL = new  List<sked__Resource__c>(); 
    public static List<sked__Resource__c> vehicleTypeResourceForDOT = new  List<sked__Resource__c>(); 
    public static List<sked__Resource__c> vehicleTypeResourceForRegVechicle = new  List<sked__Resource__c>(); 	
    public static List<sked__Resource__c> EquipmentTypeResource = new  List<sked__Resource__c>();
    public static List<sked__Job__c> vehicleTypeJob = new  List<sked__Job__c>();	
    public static List<sked__Job__c> equipmentTypeJob = new  List<sked__Job__c>();
    public static List<sked__Resource__c> successfullyEvaluatedResourceList = new List<sked__Resource__c>();	
    public static Map<Id,Decimal> map_allVehicleResourceId_presDonorCapacity = new Map<Id,Decimal>();
    public static Map<Id,sked__Resource__c> resourceIdVsResourceDetails = new Map<Id,sked__Resource__c>();	
    public static Map<Id,List<sked__Resource_Tag__c>> resourceVsResourceTagMap = new Map<Id,List<sked__Resource_Tag__c>>();	
    public static Map<Id,sked_Operation_Drive_Limit__c> map_operationDriveLimitId_operationDriveLimit = new Map<Id,sked_Operation_Drive_Limit__c>();
    public static Decimal remainingStaff = 0; 
    public static Decimal reCalTotalNoOfStaffRequired = 0; 
    private Map<String, Set<Id>> map_driveType_failedDriveIds = new Map<String,  Set<Id>>();
    private Map<String, Set<ID>> typeOfDriveVsdriveIDSet = new Map<String, Set<ID>>();
    private Map<Id, String> map_driveId_noAllocationReason = new Map<Id, String>();
    private static Set<Id> driveJobIds = new Set<Id>();
    private static List<sked__Job_Allocation__c> jobAllocationList = new List<sked__Job_Allocation__c>();
    private static List<sked_Staffing_Constraint__c> staffConstraintList = new List<sked_Staffing_Constraint__c>();
    private static ResourceModel calculatedResourceModel;
    private Set<Id> errorLogIdsCreatedDuringBatchRun = new Set<Id>();
    public Set<Id> driveIdSet;
    public sked_Drive__c drive;
    public Integer noOfVehicles = 0; 
    private Date targetCreatedDate;
    private DateTime targetCreatedDateTo;
    private DateTime targetCreatedDateFrom;
    private Date manualRunDate;
    private String driveSource = '';
    private String typeOfDrive;
    private Date driveDateToEval;
    private String runType;
    public Decimal fsSysGenCount = 0;
    public Decimal mobileSysGenCount = 0;
    private DriveGenerationUtil.CalendarBuildLogWrapper cbLogWrapper;
   
    
   	/*HRP-12706 --> Starts Here
    * @Reference : 
     		* CreatedBy : Raktim Ghosal
			* CreatedDate : 8/20/2024
			* CreatedFor : HRP-12706
    * @Description : 
     		* This overloaded constructor will run for scheduled / manual run - System Generation batch
            * It can be used for both the type of drives
    *  @Parameters : 
    		* runType : Manual/Scheduled
     		* Source : Calendar Build / Adhoc / Business Planning / Adhoc Calendar Build / ''
            * typeOfDrive : Fixed Site / Mobile
            * driveDateToEval : optional
            * setOfDriveID : Set of drive Ids to process (Optional)
	*/
    public DriveResourceAllocationBatch(String runType, String source, String typeOfDrive, Date driveDateToEval, Set<ID> setOfDriveID) {
        try{
            this.driveIdSet = (setOfDriveID != NULL && !setOfDriveID.isEmpty()) ? setOfDriveID : new Set<Id>() ;
            this.driveDateToEval = (driveDateToEval != NULL) ? driveDateToEval : NULL ;
            this.typeOfDrive = (!String.isBlank(typeOfDrive)) ? typeOfDrive : NULL ;
            this.runType = (!String.isBlank(runType) && runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_MANUAL)) ? BSF_Constants.RUN_TYPE_MANUAL : BSF_Constants.RUN_TYPE_SCHEDULED;
            this.driveSource = source;
            Decimal daysAfterCbRollDate;
            if(BSF_Constants.MAP_DRIVETYPE_BATCHTYPE.containsKey(typeOfDrive)) {
                cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                    NULL,
                    BSF_Constants.MAP_DRIVETYPE_BATCHTYPE.get(typeOfDrive),
                    this.runType
                );
                cbLogWrapper.opportunitySource = this.driveSource;
            }
            Calendar_Build_Setting__mdt cbMetadata = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
            if(this.driveSource.equalsIgnoreCase(BSF_Constants.BATCH_CALENDAR_BUILD) && this.runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_SCHEDULED)) {
                if(typeOfDrive.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) {
                    daysAfterCbRollDate = cbMetadata?.No_of_Days_for_Sys_Gen_Batch_FS__c;
                } else {
                    daysAfterCbRollDate = cbMetadata?.No_of_Days_for_Sys_Gen_Batch_Mobile__c;
                }
            
                if(daysAfterCbRollDate != NULL) {
                    this.targetCreatedDate = DateTime.now().addDays(-daysAfterCbRollDate.intValue()).dateGMT(); 
                } else {
                    this.targetCreatedDate = typeOfDrive.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE) ? DateTime.now().addDays(-0).dateGMT() : NULL; 
                }
                if(targetCreatedDate != NULL) {
                    targetCreatedDateTo = datetime.newInstanceGMT(this.targetCreatedDate, Time.newInstance(23,59,59,59));
                    targetCreatedDateFrom = datetime.newInstanceGMT(this.targetCreatedDate, Time.newInstance(0,0,0,0));
                }
            }
            cbLogWrapper.draftDriveListToBeProcessed = Database.Query(createDriveQuery());
            if(this.typeOfDrive != NULL) {
                if(this.typeOfDrive.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) {
                    fsSysGenCount = cbLogWrapper.draftDriveListToBeProcessed != NULL ? (Decimal)cbLogWrapper.draftDriveListToBeProcessed.size() : 0;
                } else if(this.typeOfDrive.equalsIgnoreCase(BSF_Constants.MOBILE_DRIVE)) {
                    mobileSysGenCount = cbLogWrapper.draftDriveListToBeProcessed != NULL ? (Decimal)cbLogWrapper.draftDriveListToBeProcessed.size() : 0;
                }
            }
            if(this.driveSource != NULL && !String.isBlank(this.driveSource)) {
                cbLogWrapper.opportunitySource = this.driveSource;
                if(this.driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD) && cbLogWrapper.draftDriveListToBeProcessed != NULL && !cbLogWrapper.draftDriveListToBeProcessed.isEmpty()) {
                   /* HRP-14179: One drive date is processed every day via CB, 
                    but user can change the drive date within the 21 days gap before sys gen run.
                    To correctly capture sys gen info, system should use parent CB drive's drive date to find existing CB log */
                    
                    sked_Drive__c newCBDrive = cbLogWrapper.draftDriveListToBeProcessed[0];
                    this.driveDateToEval = newCBDrive.sked_Opportunity__r.Calendar_Build_Parent_Opportunity__r.Drive_Date__c;
                    cbLogWrapper.driveDateToEval = this.driveDateToEval;
                }
            } 
        } 
        catch(Exception ex) {
            if(source != NULL && !String.isBlank(source) && source.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD)) { //No need for Adhoc CB drives HRP-11368
                DateTime dt = Helper.getSameDayOfPrevYear(this.driveDateToEval);
                this.driveDateToEval = Date.newInstance(dT.year(), dT.month(), dT.day());
            }
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                this.driveDateToEval, 
                BSF_Constants.MAP_DRIVETYPE_BATCHTYPE.get(typeOfDrive), 
                runType
            );
            cbLogWrapper.apexMethodName = 'Constructor Call';
            cbLogWrapper.opportunitySource = source;
            cbLogWrapper.draftDriveListToBeProcessed = new List<sked_Drive__c>();
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);  
        }
    }
    
    public List<sked_Drive__c> start(Database.BatchableContext bc) {
        return cbLogWrapper.draftDriveListToBeProcessed;
    }

    /**
     * Drive day limits are found by querying non timeblock ODL records
     */
    public List<sked_Operation_Drive_Limit__c> getApplicableODLsForEntireDriveDay(sked_Drive__c drive){
        driveSite = drive.sked_Drive_Site__c;
        driveDate = drive.sked_Drive_Date__c;
        driveCO = drive.sked_Collection_Operation__c;
        String dayOfWeek = drive.sked_Day_of_Week__c;

         // Get only non time block records to get day limit
        List<sked_Operation_Drive_Limit__c> driveLevelODLRecordsList = new List<sked_Operation_Drive_Limit__c>(
            [SELECT Id, Name, sked_Collection_Operation__c, sked_Days_of_Week__c, sked_Effective_End_Date__c, 
                    sked_Effective_Start_Date__c, sked_Quantity__c, sked_Type__c, sked_MigrationID__c,
                    Time_Block__c
            FROM sked_Operation_Drive_Limit__c
            WHERE sked_Type__c IN (:Constants.OPERATION_DRIVE_2RBC_LIMIT, : Constants.OPERATION_DRIVE_DOT_LIMIT, : Constants.OPERATION_DRIVE_CDL_LIMIT) 
            AND sked_Collection_Operation__c = :driveCO
            AND sked_Days_of_Week__c INCLUDES (:dayOfWeek)
            AND Time_Block__c = null //pick records with timeblock as null
            AND ((sked_Effective_Start_Date__c <= :driveDate 
            AND (sked_Effective_End_Date__c = NULL
                OR sked_Effective_End_Date__c >= :driveDate)) 
                OR ((sked_Effective_Start_Date__c = NULL
                OR sked_Effective_Start_Date__c <= :driveDate)                
                AND sked_Effective_End_Date__c >= :driveDate))]);

        return  driveLevelODLRecordsList;           

    }

    public Map<Id, sked_Operation_Drive_Limit__c> getApplicableODLsForDriveShift(sked_Drive__c drive, sked_Drive_Shift__c driveShift){
        driveSite = drive.sked_Drive_Site__c;
        driveDate = drive.sked_Drive_Date__c;
        driveCO = drive.sked_Collection_Operation__c;
        String dayOfWeek = drive.sked_Day_of_Week__c;

        // Check ODL to get limits
        map_operationDriveLimitId_operationDriveLimit = new Map<Id,sked_Operation_Drive_Limit__c>(
            [SELECT Id, Name, sked_Collection_Operation__c, sked_Days_of_Week__c, sked_Effective_End_Date__c, 
                    sked_Effective_Start_Date__c, sked_Quantity__c, sked_Type__c, sked_MigrationID__c,
                    Time_Block__c, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c, Time_Block__r.Days_of_Week__c
            FROM sked_Operation_Drive_Limit__c
            WHERE sked_Type__c IN (:Constants.OPERATION_DRIVE_2RBC_LIMIT, : Constants.OPERATION_DRIVE_DOT_LIMIT, : Constants.OPERATION_DRIVE_CDL_LIMIT) 
            AND sked_Collection_Operation__c = :driveCO
            AND sked_Days_of_Week__c INCLUDES (:dayOfWeek)
            AND ((sked_Effective_Start_Date__c <= :driveDate 
            AND (sked_Effective_End_Date__c = NULL
                OR sked_Effective_End_Date__c >= :driveDate)) 
                OR ((sked_Effective_Start_Date__c = NULL
                OR sked_Effective_Start_Date__c <= :driveDate)                
                AND sked_Effective_End_Date__c >= :driveDate))]);

        // Filter ODL records based on time block applicability
        Map<Id, sked_Operation_Drive_Limit__c> filteredOperationDriveLimits = new Map<Id, sked_Operation_Drive_Limit__c>();

        if(map_operationDriveLimitId_operationDriveLimit != NULL && !map_operationDriveLimitId_operationDriveLimit.isEmpty()) {
                    // Group ODL records by type
                    Map<String, List<sked_Operation_Drive_Limit__c>> odlByType = new Map<String, List<sked_Operation_Drive_Limit__c>>();
                    for(sked_Operation_Drive_Limit__c odl : map_operationDriveLimitId_operationDriveLimit.values()) {
                        String odlType = odl.sked_Type__c;
                        if(!odlByType.containsKey(odlType)) {
                            odlByType.put(odlType, new List<sked_Operation_Drive_Limit__c>());
                        }
                        odlByType.get(odlType).add(odl);
                    }
                    
                    // Process each type separately
                    for(String odlType : odlByType.keySet()) {
                        List<sked_Operation_Drive_Limit__c> odlRecords = odlByType.get(odlType);
                        List<sked_Operation_Drive_Limit__c> applicableTimeBlockRecords = new List<sked_Operation_Drive_Limit__c>();
                        List<sked_Operation_Drive_Limit__c> noTimeBlockRecords = new List<sked_Operation_Drive_Limit__c>();
                        
                        // Separate records with time blocks 
                        for(sked_Operation_Drive_Limit__c odl : odlRecords) {
                            if(odl.Time_Block__c != null && driveShift.sked_Time_Block__c == odl.Time_Block__c &&
                                            driveShift.sked_Contention__c == null) { //If Matching time block exists
                                applicableTimeBlockRecords.add(odl);
                            } else {
                                noTimeBlockRecords.add(odl);
                            }
                        }
                        
                        //For each type
                        if(!applicableTimeBlockRecords.isEmpty()) {
                            // If there are applicable time block records, keep only the first one
                            filteredOperationDriveLimits.put(applicableTimeBlockRecords[0].Id, applicableTimeBlockRecords[0]);
                        } else {
                            // If no applicable time block records, keep all records without time blocks (existing behavior)
                            for(sked_Operation_Drive_Limit__c odl : noTimeBlockRecords) {
                                filteredOperationDriveLimits.put(odl.Id, odl);
                            }
                        }
                    }// end of for loop, for all 3 types  
        }
        
        return filteredOperationDriveLimits;
    }





    public static List<sked_Staffing_Constraint__c> getStaffingConstraints(sked_Drive__c drive,sked_Drive_Shift__c driveShift){
        List<sked_Staffing_Constraint__c> staffConstraintList = new List<sked_Staffing_Constraint__c>();              
        // First, try to find staff constraints with matching time block
        List<sked_Staffing_Constraint__c> timeBlockStaffConstraints = [SELECT Id, sked_Collection_Operation__c, sked_Date_of_Constraint__c, 
                                                                        sked_Total_Staff_Constraints__c, sked_Num_Available_Staff__c, sked_Time_Block__c 
                                                                        FROM sked_Staffing_Constraint__c 
                                                                        WHERE sked_Drive_Type__c =: drive.sked_Type_of_Drive__c 
                                                                        AND sked_Collection_Operation__c =: drive.sked_Collection_Operation__c 
                                                                        AND sked_Date_of_Constraint__c =: drive.sked_Drive_Date__c 
                                                                        AND sked_Time_Block__c =: driveShift.sked_Time_Block__c 
                                                                        LIMIT 1];
        
        // If no time block specific constraints found, use non-time block constraints
        if (timeBlockStaffConstraints.isEmpty()) {
            List<sked_Staffing_Constraint__c> nonTimeBlockStaffConstraints = [SELECT Id, sked_Collection_Operation__c, sked_Date_of_Constraint__c, 
                                                                                sked_Total_Staff_Constraints__c, sked_Num_Available_Staff__c, sked_Time_Block__c 
                                                                                FROM sked_Staffing_Constraint__c 
                                                                                WHERE sked_Drive_Type__c =: drive.sked_Type_of_Drive__c 
                                                                                AND sked_Collection_Operation__c =: drive.sked_Collection_Operation__c 
                                                                                AND sked_Date_of_Constraint__c =: drive.sked_Drive_Date__c 
                                                                                AND sked_Time_Block__c = NULL 
                                                                                LIMIT 1];
            staffConstraintList = nonTimeBlockStaffConstraints;
        } else {
            staffConstraintList = timeBlockStaffConstraints;
        }

        return staffConstraintList;
    }


    /**
     * This calculates limits from incoming list of ODL Records and populates ResourceModel
     */
    public static ResourceModel getResourceModelPopulatedFromODLRecords(List<sked_Operation_Drive_Limit__c> operationDriveLimitRecordsList){
        ResourceModel resourceModel = new ResourceModel();

        if(operationDriveLimitRecordsList != NULL && !operationDriveLimitRecordsList.isEmpty()) {
                Map<Id,Decimal> map_operationDriveLimit_odlOverrideQuantity = new Map<Id,Decimal>();
                // Extract IDs from the list for the SOQL query
                Set<Id> odlIds = new Set<Id>();
                for(sked_Operation_Drive_Limit__c odl : operationDriveLimitRecordsList) {
                    odlIds.add(odl.Id);
                }
                
                List<sked_Operation_Drive_Limit_Override__c> operationDriveLimitOverride = [SELECT Id, sked_Operation_Drive_Limit__c, 
                                                                                            sked_Operation_Drive_Limit__r.sked_Type__c, sked_Date__c, sked_Quantity__c 
                                                                                            FROM sked_Operation_Drive_Limit_Override__c 
                                                                                            WHERE sked_Operation_Drive_Limit__c IN :odlIds 
                                                                                            AND sked_Date__c = :driveDate];
                if(!operationDriveLimitOverride.isEmpty()) {
                    for(sked_Operation_Drive_Limit_Override__c odl : operationDriveLimitOverride) {
                        map_operationDriveLimit_odlOverrideQuantity.put(odl.sked_Operation_Drive_Limit__c, odl.sked_Quantity__c);
                    }
                }

                for(sked_Operation_Drive_Limit__c iterateOperationDriveLimit : operationDriveLimitRecordsList) {
                    // check for DOT Limit
                    if(iterateOperationDriveLimit.sked_Type__c == Constants.OPERATION_DRIVE_DOT_LIMIT) {
                        if((!operationDriveLimitOverride.isEmpty()) && map_operationDriveLimit_odlOverrideQuantity.containsKey(iterateOperationDriveLimit.Id)) {
                            resourceModel.totalDOTLimit = map_operationDriveLimit_odlOverrideQuantity.get(iterateOperationDriveLimit.Id) == NULL ? 
                                                            NULL : 
                                                            map_operationDriveLimit_odlOverrideQuantity.get(iterateOperationDriveLimit.Id);
                            
                        } else {
                            resourceModel.totalDOTLimit = iterateOperationDriveLimit.sked_Quantity__c == NULL ? 
                                                            NULL : 
                                                            (resourceModel.totalDOTLimit == NULL ? iterateOperationDriveLimit.sked_Quantity__c : 
                                                            resourceModel.totalDOTLimit + iterateOperationDriveLimit.sked_Quantity__c);
                        }
                        if(resourceModel.totalDOTLimit != NULL) {
                            resourceModel.isDOTLimitPresent = TRUE;
                        }
                   
                    }   

                    // Check for CDL Limit
                    else if (iterateOperationDriveLimit.sked_Type__c == Constants.OPERATION_DRIVE_CDL_LIMIT) {
                        if((!operationDriveLimitOverride.isEmpty()) && map_operationDriveLimit_odlOverrideQuantity.containsKey(iterateOperationDriveLimit.Id)) {
                            resourceModel.totalCDLLimit = map_operationDriveLimit_odlOverrideQuantity.get(iterateOperationDriveLimit.Id) == NULL ? NULL : map_operationDriveLimit_odlOverrideQuantity.get(iterateOperationDriveLimit.Id);
                        } else {
                            resourceModel.totalCDLLimit = iterateOperationDriveLimit.sked_Quantity__c == NULL ? 
                                                            NULL : 
                                                            (resourceModel.totalCDLLimit == NULL ?  iterateOperationDriveLimit.sked_Quantity__c : 
                                                            resourceModel.totalCDLLimit + iterateOperationDriveLimit.sked_Quantity__c);
                        }
                        if(resourceModel.totalCDLLimit != NULL) {
                            resourceModel.isCDLLimitPresent = TRUE; 
                        }
                       
                    } 

                    //Check for 2RBC Limit
                    else if(iterateOperationDriveLimit.sked_Type__c == Constants.OPERATION_DRIVE_2RBC_LIMIT) {
                        if((!operationDriveLimitOverride.isEmpty()) && map_operationDriveLimit_odlOverrideQuantity.containsKey(iterateOperationDriveLimit.Id)) {
                            resourceModel.total2RBCLimit = map_operationDriveLimit_odlOverrideQuantity.get(iterateOperationDriveLimit.Id) == NULL ? NULL : map_operationDriveLimit_odlOverrideQuantity.get(iterateOperationDriveLimit.Id);
                        } else {
                            resourceModel.total2RBCLimit = iterateOperationDriveLimit.sked_Quantity__c == NULL ? 
                                                            NULL : 
                                                            (resourceModel.total2RBCLimit == NULL ? iterateOperationDriveLimit.sked_Quantity__c :
                                                            resourceModel.total2RBCLimit + iterateOperationDriveLimit.sked_Quantity__c);     
                        }
                        if(resourceModel.total2RBCLimit != NULL) {
                            resourceModel.is2RBCLimitPresent = TRUE; 
                        }
                    
                    }
                }
            }

            return resourceModel;
    }


    public  Boolean processDriveAtShiftLevel(
        sked_Drive__c drive, 
        Decimal noOfStaffsAllocated,
        Decimal noOfRBCAllocated, 
        Decimal noOfCDLAllocated, 
        Decimal noOfDOTAllocated, 
        ResourceModel resourceModelDriveLevel
    ) {
                        
        Boolean allShiftsPassedChecks = true;        
    
        driveSite = drive.sked_Drive_Site__c;
        driveDate = drive.sked_Drive_Date__c;
        driveCO = drive.sked_Collection_Operation__c;
        driveAccount = drive.sked_Account__c;
        String dayOfWeek = drive.sked_Day_of_Week__c;
        String typeOfDrive = drive.sked_Type_of_Drive__c;
        
        // Get drive shifts for this drive
        List<sked_Drive_Shift__c> driveShifts = getDriveShifts(drive.Id);
        
        if(driveShifts.isEmpty()) {
            return true;
        }

        Integer driveShiftCount = 0;
        for(sked_Drive_Shift__c driveShift : driveShifts) {
            // Clear the sets for each shift
            driveJobIds.clear();
            jobAllocationList.clear();

            Decimal staffJobCount = 0;
            Decimal totalNoOfStaffRequired = 0;

            for(sked__Job__c job : driveShift.sked_Jobs__r) {	
                if(job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE && !drive.sked_Do_Not_Use_Vehicle__c) {	
                    vehicleTypeJob.add(job);
                    driveJobIds.add(job.Id);
                } else if(job.sked_Asset_Type__c == Constants.JOB_TYPE_EQUIPMENT) {	     
                    equipmentTypeJob.add(job);	
                    driveJobIds.add(job.Id);
                } else if(job.sked__Type__c == Constants.PROCEDURE_TYPE_2RBC) {	      
                    staffJobCount += job.sked__Quantity__c; 
                } else if(job.sked_Volunteer_Role__c != NULL) { 
                    continue;
                } else {
                    staffJobCount += job.sked__Quantity__c;
                }
            }

            if(isFixedSiteDrive(drive)) {
                allShiftsPassedChecks = true; //Shift level validation does not apply for Fixed site Drives
            } else {
                totalNoOfStaffRequired = staffJobCount;
                
                // Check for existing Job Allocation for Current Drive Shift
                if(!driveJobIds.isEmpty()) {
                    jobAllocationList = Database.Query(createJobAllocationsQuery(driveJobIds)); 
                }

                // Check Applicable Shift ODL records to get shift limits
                map_operationDriveLimitId_operationDriveLimit = getApplicableODLsForDriveShift(drive, driveShift);
                ResourceModel resourceModel = getResourceModelPopulatedFromODLRecords(map_operationDriveLimitId_operationDriveLimit.values());
                resourceModel = getCalculatedLimits(noOfRBCAllocated, noOfCDLAllocated, noOfDOTAllocated, resourceModel);
                if(driveShiftCount == 0) calculatedResourceModel = resourceModel; //Get the limits from 1st shift only

                staffConstraintList = getStaffingConstraints(drive, driveShift);
                Decimal remainingStaffShiftLevel = staffConstraintList != NULL && staffConstraintList.size() > 0 && staffConstraintList[0].sked_Total_Staff_Constraints__c != NULL ? (staffConstraintList[0].sked_Total_Staff_Constraints__c - noOfStaffsAllocated) : 0; // HRP-10523 // HRP-11224
                remainingStaff = remainingStaff + remainingStaffShiftLevel;//Keep the total remaining staff updated at instance level variable, this is used inside allocateResourceToJob
                
                Boolean passingRuleOne = isFixedSiteDrive(drive) && jobAllocationList.isEmpty();
                Boolean passingSubRuleTwo = remainingStaffShiftLevel >= totalNoOfStaffRequired && jobAllocationList.isEmpty();
                Boolean passingRuleTwo = passingSubRuleTwo && (map_operationDriveLimitId_operationDriveLimit.isEmpty() || resourceModel.total2RBCLimit == NULL || drive.sked_Total_Equipment_Requested__c == 0 || drive.sked_Total_Equipment_Requested__c <= resourceModel.remainingNoOf2RBC);    
                Boolean hasSufficientResourceBut2rbcLimitExceeded = !passingRuleOne && !passingRuleTwo;
                
                // Check if staffing constraint has sufficient resource 
                if(!passingRuleOne && !passingSubRuleTwo) {
                    map_driveId_noAllocationReason.put(drive.Id, 
                        'Insufficient Resource\n\nStaff Required: '+totalNoOfStaffRequired+'\nStaff Available: '+remainingStaffShiftLevel);
                    allShiftsPassedChecks =false;
                    break; //break out of the drive shift loop, no need to process any further drive shifts on this drive
                }

                // Check if staffing constraint has sufficient resource but 2RBC limit is reached for that day
                if(hasSufficientResourceBut2rbcLimitExceeded) {
                    map_driveId_noAllocationReason.put(drive.Id, 
                        '2RBC Limit Exceeded\n\nTotal Limit: '+resourceModel.total2RBCLimit+'\nRemaining Limit: '+resourceModel.remainingNoOf2RBC+'\nCurrent number of 2RBC: '+drive.sked_Total_Equipment_Requested__c);
                    allShiftsPassedChecks =false;
                    break; //break out of the drive shift loop, no need to process any further drive shifts on this drive
                }

                //check if any of the shift level limits exceeding per day drive level limit
                if(!passingRuleOne && resourceModelDriveLevel.totalDOTLimit != null && resourceModel.totalDOTLimit != null && resourceModelDriveLevel.totalDOTLimit < resourceModel.totalDOTLimit
                || (resourceModelDriveLevel.totalCDLLimit != null && resourceModel.totalCDLLimit!= null && resourceModelDriveLevel.totalCDLLimit<resourceModel.totalCDLLimit)
                || (resourceModelDriveLevel.total2RBCLimit != null && resourceModel.total2RBCLimit != null && resourceModelDriveLevel.total2RBCLimit<resourceModel.total2RBCLimit)) {
                        map_driveId_noAllocationReason.put(drive.Id, 
                        'Shift level Limits exceeding Per Day Limits');
                        allShiftsPassedChecks =false;
                        break; //break out of the drive shift loop, no need to process any further drive shifts on this drive
                } 
                driveShiftCount++;
            }
        } //end of drive shifts loop
        return allShiftsPassedChecks;
    }


    public void execute(Database.BatchableContext bc, List<sked_Drive__c> driveList) {
        Savepoint sp = Database.setSavepoint(); //HRP-13347
        try{
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; 
            
            for(sked_Drive__c drive : driveList) {
                driveSite = drive.sked_Drive_Site__c;
                driveDate = drive.sked_Drive_Date__c;
                driveCO = drive.sked_Collection_Operation__c;
                driveAccount = drive.sked_Account__c;
                String dayOfWeek = drive.sked_Day_of_Week__c;
                String typeOfDrive = drive.sked_Type_of_Drive__c;
                List<sked__Resource__c> resList = Database.Query(getResourcesToAllocate(drive)); 

                Boolean isMobileWithTimeBlockViolation = !isFixedSiteDrive(drive)  && drive.sked_Pending_Action_Reason_Code__c!=null 
                                                         && drive.sked_Pending_Action_Reason_Code__c.contains('Time Block') ;
                if(isMobileWithTimeBlockViolation == true) {
                    map_driveId_noAllocationReason.put(drive.Id, 'Time Block Violation:'+drive.sked_Pending_Action_Reason_Code__c);
                    continue; //skip processing drives with Time Block Violation
                }

                // quering for pre-existing drives
                List<sked_Drive__c> preExistingDriveList = [SELECT Id,sked_Status__c,sked_Collection_Operation__c,sked_Type_of_Drive__c,
                                                                (SELECT Id,sked__Type__c,sked_Drive_Shift__c,sked__Quantity__c,sked_Asset_Type__c, sked_Volunteer_Role__c, sked_Drive__c, sked_Drive__r.sked_Type_of_Drive__c FROM sked_Jobs__r) //HRP-11793
                                                                FROM sked_Drive__c Where sked_Status__c !=: Constants.DRIVE_STATUS_DRAFT
                                                                AND sked_Status__c !=: Constants.DRIVE_STATUS_CANCELLED 
                                                                AND sked_Collection_Operation__c =: drive.sked_Collection_Operation__c 
                                                                AND sked_Drive_Date__c =: drive.sked_Drive_Date__c
                                                                AND ID != :drive.Id
                                                            ];

                Decimal noOfStaffsAllocated = 0;
                Decimal noOfRBCAllocated = 0; 
                Decimal noOfCDLAllocated = 0; 
                Decimal noOfDOTAllocated = 0; 
                Set<Id> storeJobIdOfVehicle = new Set<Id>(); // HRP-10212 and HRP 10213
                system.debug('Pre-Existing Drive List Size:: '+preExistingDriveList.size());
                if (!preExistingDriveList.isEmpty()) {
                    for(sked_Drive__c preExistingDrive : preExistingDriveList) {
                        if(preExistingDrive.sked_Jobs__r != NULL || !preExistingDrive.sked_Jobs__r.isEmpty()) {
                            for(sked__Job__c job : preExistingDrive.sked_Jobs__r) {
                                if(job.sked_Asset_Type__c != Constants.JOB_TYPE_VEHICLE && job.sked_Asset_Type__c != Constants.JOB_TYPE_EQUIPMENT && job.sked_Volunteer_Role__c == NULL && job.sked_Drive__r.sked_Type_of_Drive__c == typeOfDrive) { //HRP-11793
                                    noOfStaffsAllocated += job.sked__Quantity__c;
                                }
                                if (job.sked_Asset_Type__c == Constants.JOB_TYPE_EQUIPMENT) {
                                    noOfRBCAllocated += job.sked__Quantity__c;
                                }
                                if(job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE) { // HRP-10212 and HRP 10213
                                    storeJobIdOfVehicle.add(job.Id); 
                                }
                            }
                        }  
                    }
                }
                if(!storeJobIdOfVehicle.isEmpty()) { // HRP-10212 start
                    List <sked__Job_Allocation__c> preExistingJobAllocationForVehicles = Database.Query(createJobAllocationsQuery(storeJobIdOfVehicle));
                    if(!preExistingJobAllocationForVehicles.isEmpty()) {
                        for(sked__Job_Allocation__c jobAllocation : preExistingJobAllocationForVehicles) {
                            if(jobAllocation.sked__Resource__r.sked_DOT__c == true) {
                                noOfDOTAllocated += 1;
                            }
                            if(jobAllocation.sked__Resource__r.sked_CDL__c == true) {
                                noOfCDLAllocated += 1;
                            }
                        }
                    }
                }
            
                ResourceModel resourceModelDriveLevel = getResourceModelPopulatedFromODLRecords(getApplicableODLsForEntireDriveDay(drive));
                resourceModelDriveLevel = getCalculatedLimits(noOfRBCAllocated, noOfCDLAllocated, noOfDOTAllocated, resourceModelDriveLevel);
				//Shift level validation does not apply for Fixed site Drives
                Boolean allShiftsPassedChecks = processDriveAtShiftLevel(drive, noOfStaffsAllocated,  noOfRBCAllocated, 
                                                noOfCDLAllocated, noOfDOTAllocated,resourceModelDriveLevel);
                System.debug('All shifts passed checks: ' + allShiftsPassedChecks);
                if(allShiftsPassedChecks == false) {
                    continue; //continue to next drive
                }

                resourceModelDriveLevel = calculatedResourceModel;
                evaluateResourceEligibilityAndAllocateResources(resList, drive, resourceModelDriveLevel);
            }
            sp = Database.setSavepoint(); //HRP-13347
    	} catch(Exception ex) {
            Database.rollback(sp); //HRP-13347
            List<BSF_Error_Log__c> bsfErrorLogToInsertList = new List<BSF_Error_Log__c>{BSF_Utilities.createBsfErrorLogForExceptions(ex, 'DriveResourceAllocationBatch', 'Execute Method', BSF_Constants.MAP_DRIVETYPE_BATCHTYPE.get(typeOfDrive), BSF_Constants.MAP_DRIVETYPE_BATCHTYPE.get(typeOfDrive), String.valueOf(drive.Id.getSobjectType()), String.valueOf(drive.Id))};
            if(!map_driveType_failedDriveIds.containsKey(drive.sked_Type_of_Drive__c)) {
                map_driveType_failedDriveIds.put(drive.sked_Type_of_Drive__c, new Set<Id>());
            }
            map_driveType_failedDriveIds.get(drive.sked_Type_of_Drive__c).add(drive.Id);
            Database.SaveResult[] logInsertResult = Database.insert(bsfErrorLogToInsertList, FALSE);
            errorLogIdsCreatedDuringBatchRun.addAll(BSF_Utilities.getSuccessfullySavedRecordIds(logInsertResult));
            sp = Database.setSavepoint(); //HRP-13347
        }
    }
    
    private static String getResourcesToAllocate (sked_Drive__c drive) {	
        String queryString = 'SELECT Id,sked_DOT__c, sked_CDL__c,sked_Dedicated_to_Site__c,sked_Equipment_Subtype__c,sked_Asset_Type__c,sked_Pres_Donor_Capacity__c,sked__Is_Active__c,sked__Primary_Region__c,	'+
            ' sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,(SELECT sked_Biomed_Collection_Op_Center__c,sked_Start_Date__c,sked_End_Date__c,sked_Resource__c '+
            ' FROM sked_Resource_Biomed_Collection_Ops__r),(SELECT sked__Blacklisted__c,sked__Account__c FROM sked__Account_Resource_Scores__r where sked__Blacklisted__c = true AND sked__Account__c = :driveAccount), '+
            ' (SELECT sked_Collection_Operation__r.Name,sked_Collection_Operation__c,sked__Resource__c,sked_Start_Date__c,sked_End_Date__c,sked_Start_Time__c, sked_End_Time__c, sked__Start__c, sked__End__c FROM sked__Resource_Overrides__r Where sked_Start_Date__c <=: driveDate AND sked_End_Date__c >=: driveDate), '+
            ' (SELECT sked__Blacklisted__c,sked__Location__c FROM sked__Location_Resource_Scores__r where sked__Blacklisted__c = true AND sked__Location__c = :driveSite), '+
            ' (SELECT Id, Name,sked_Start_Date__c, sked__Status__c,sked_Finish_Date__c, sked__Resource__c,sked__Type__c,sked_Start_Time__c, sked_Finish_Time__c, sked__Start__c, sked__Finish__c FROM sked__Availabilities1__r where sked__Status__c = \'Approved\' AND sked__Is_Available__c = false AND sked_Start_Date__c <=: driveDate AND sked_Finish_Date__c >=: driveDate), '+	
            ' (SELECT sked__Status__c ,sked__Resource__c,sked_Start_Date__c,sked_Set_End_Date__c,sked_Start_Time__c, sked_Set_End_Time__c, sked__Start__c, sked__Set_End__c FROM sked__Job_Allocations__r Where sked__Status__c  != \'Deleted\' AND sked_Start_Date__c <= :driveDate AND sked_Set_End_Date__c >= :driveDate), '+
            ' (SELECT sked__Resource__c,sked_Start_Date__c,sked_End_Date__c,sked_Start_Time__c, sked_End_Time__c, sked__Start__c, sked__End__c FROM sked__Activities__r where sked_Start_Date__c <=: driveDate AND sked_End_Date__c >=: driveDate), '+
            ' (SELECT Id, Name,sked__Activity__r.sked_Start_Date__c, sked__Activity__r.sked_End_Date__c,  sked__Resource__c,sked_Start_Time__c, sked_End_Time__c, sked_Start1__c, sked_End__c FROM sked__Activity_Resources__r Where sked__Activity__r.sked_Start_Date__c <= :driveDate AND sked__Activity__r.sked_End_Date__c>= :driveDate), '+
            ' (SELECT sked__Resource__c ,sked_Start_Date__c,sked_Expiry_Date__c, sked__Tag__c,sked_Tag_Type__c FROM sked__ResourceTags__r WHERE sked_Start_Date__c <= :driveDate AND (sked_Expiry_Date__c = NULL OR sked_Expiry_Date__c >= :driveDate)) '+
            ' FROM sked__Resource__c WHERE sked__Is_Active__c = true AND (sked_Dedicated_to_Site__c = null OR sked_Dedicated_to_Site__c = :driveSite)' ; // HRP-11001

        // HRP-11908 --> Starts Here
        if(isFixedSiteDrive(drive) || drive.sked_Do_Not_Use_Vehicle__c) {
            queryString += ' AND (sked_Asset_Type__c = \'Equipment\' OR sked_Asset_Type__c = \'2RBC\')';
        } else {
            queryString += ' AND (sked_Asset_Type__c = \'Vehicle\' OR sked_Asset_Type__c = \'Equipment\' OR sked_Asset_Type__c = \'2RBC\')' +
                            ' ORDER BY sked_Pres_Donor_Capacity__c DESC NULLS LAST';
        }
        // HRP-11908 --> Ends Here
        return queryString;
    }

    private String createDriveQuery () {
        String queryString = 'SELECT Id, sked_Do_Not_Use_Vehicle__c, sked_Staff_Capacity__c, Excess_Staff_Capacity__c, Average_Staff_Capacity__c, Name,sked_Status__c, sked_Drive_Shift_Count__c, sked_Day_of_Week__c, sked_2RBC_Projected_Procedures__c, sked_Operation_Type__c,' +
                            ' sked_Total_Products_Projected__c, sked_Maximum_Lunch_Break_Duration__c ,sked_Drive_Site__c,sked_Collection_Operation__c, sked_Total_Equipment_Requested__c, sked_Total_Vehicle_Requested__c,'+
                            ' sked_End_Time__c, sked_Account__c,sked_Collection_Operation__r.sked_Lunch_Break_Before_Draw_Hours__c,sked_Timezone__c,sked_Start_Time__c, sked_Projected_Registered_Donors__c,sked_Drive_Date__c,'+
                            ' sked_Opportunity__c, sked_Opportunity__r.Source__c, sked_Opportunity__r.Calendar_Build_Parent_Opportunity__r.Drive_Date__c, sked_Type_of_Drive__c ,sked_Drive_Site__r.sked_Physical_Location_Type__c,sked_Pending_Action_Reason_Code__c, (SELECT Id,sked_Equipment_Subtype__c,'+
                            ' sked__Type__c,sked_Travel_Time2__c,sked_Travel_Time__c,sked_Lead_Time__c,sked_Wrap_up_Time__c,sked_Setup_Time__c,sked_Breakdown_Time__c,'+
                            ' sked_Drive_Shift__c,sked__Quantity__c,sked_Resource_Role__c,sked_Asset_Type__c,sked_APT_Quantity__c, sked_Volunteer_Role__c, sked_Start_Time__c, sked_Finish_Time__c, sked__Start__c, sked__Finish__c FROM sked_Jobs__r) FROM sked_Drive__c'+
                            ' WHERE sked_Status__c != \'Cancel\'';

        //HRP-12706 --> Starts Here
        if(driveIdSet != NULL && !driveIdSet.isEmpty()) {
			queryString += ' AND Id IN: driveIdSet';            
        }
        if(driveSource != NULL && !String.isBlank(driveSource)) {
			queryString += ' AND sked_Opportunity__r.Source__c = :driveSource';            
        }
        if(typeOfDrive != NULL && !String.isBlank(typeOfDrive) && typeOfDrive.equalsIgnoreCase(BSF_Constants.MOBILE_DRIVE)) {
            queryString += ' AND sked_Status__c = \'Draft\'';
        }
        if(driveDateToEval != NULL) {
            queryString += ' AND sked_Drive_Date__c =: driveDateToEval';
        }
        if(targetCreatedDate != NULL) {
            queryString += ' AND CreatedDate >= :targetCreatedDateFrom AND CreatedDate <= :targetCreatedDateTo' ;
        }
        queryString += ' AND sked_Type_of_Drive__c =: typeOfDrive ORDER BY sked_Drive_Date__c DESC, sked_Rank__c';
        //HRP-12706 --> Ends Here
        return queryString; //HRP-11793
    }

    private static String createJobAllocationsQuery(Set<Id> jobIds) {
        String jobIdsString = '(';
        for (Id jobId : jobIds) {
            jobIdsString += '\'' + String.escapeSingleQuotes(jobId) + '\',';
        }
        jobIdsString = jobIdsString.substring(0, jobIdsString.length() - 1) + ')';
       
        return 'SELECT Id, sked__Resource__r.sked_DOT__c, sked__Resource__r.sked_CDL__c, sked__Job__r.sked__Quantity__c  '+
            'FROM sked__Job_Allocation__c WHERE sked__Status__c  != \'Deleted\' AND sked__Job__c IN '+jobIdsString;
    }

    private static Boolean isFixedSiteDrive(sked_Drive__c drive) {
        return drive.sked_Type_of_Drive__c == Constants.FIX_SITE_OPP;
    }
    
    public void finish(Database.BatchableContext bc) {
        //HRP-12706 --> Continues (Capturing the necessary info of the fields to log in the Calendar build Log Object)
        try {
            Set<Id> failedOrWithResourceAllocationDriveIds = new Set<Id>();
            List<Calendar_Build_Error_Log__c> entriesForDrivesWithNoAllocation = new List<Calendar_Build_Error_Log__c>();
            Integer noOfDriveErrorLog = 0;
            Integer noOfDriveWithAllocatedResource = 0;
            Integer fsDrivesWithNoResourceRequestedCount = 0;
            Integer mobileDrivesWithNoResourceRequestedCount = 0;
            Boolean isErrorHappened = map_driveType_failedDriveIds != NULL 
                                    && map_driveType_failedDriveIds.containsKey(this.typeOfDrive) 
                                    && map_driveType_failedDriveIds.get(this.typeOfDrive).size() > 0;

            Boolean isAllocationHappened = typeOfDriveVsdriveIDSet != NULL 
                                        && typeOfDriveVsdriveIDSet.containsKey(this.typeOfDrive) 
                                        && typeOfDriveVsdriveIDSet.get(this.typeOfDrive).size() > 0;

            if (this.typeOfDrive != NULL && !String.isBlank(this.typeOfDrive)) {
                if(isErrorHappened) {
                    failedOrWithResourceAllocationDriveIds.addAll(map_driveType_failedDriveIds.get(this.typeOfDrive));
                    noOfDriveErrorLog = failedOrWithResourceAllocationDriveIds.isEmpty() ? 0 : failedOrWithResourceAllocationDriveIds.size();  
                }

                if(isAllocationHappened) {
                    noOfDriveWithAllocatedResource = typeOfDriveVsdriveIDSet.get(this.typeOfDrive).size();
                    failedOrWithResourceAllocationDriveIds.addAll(typeOfDriveVsdriveIDSet.get(this.typeOfDrive));
                }

                if(this.typeOfDrive.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) {
                    cbLogWrapper.fsSysGenCount = fsSysGenCount != NULL && fsSysGenCount > 0 ? fsSysGenCount : 0;
                    cbLogWrapper.fsSysGenDrivesWithAllocResourceCount = (Decimal) noOfDriveWithAllocatedResource;
                    cbLogWrapper.fsSysGenFailureCount = (Decimal) noOfDriveErrorLog;
                } else {
                    cbLogWrapper.mobileSysGenCount = mobileSysGenCount != NULL && mobileSysGenCount > 0 ? mobileSysGenCount : 0;
                    cbLogWrapper.mobileSysGenDrivesWithAllocResourceCount = (Decimal) noOfDriveWithAllocatedResource;
                    cbLogWrapper.mobileSysGenFailureCount = (Decimal) noOfDriveErrorLog;
                }
            }
            cbLogWrapper.errorLogIdsCreatedDuringBatchRun = errorLogIdsCreatedDuringBatchRun != NULL ? errorLogIdsCreatedDuringBatchRun : new Set<Id>();
            cbLogWrapper.drivesWOResourceAllocThoughRequested = new List<Calendar_Build_Error_Log__c>();
            for(sked_Drive__c drive : cbLogWrapper.draftDriveListToBeProcessed) {
                if(failedOrWithResourceAllocationDriveIds.contains(drive.Id)) continue; 

                Boolean isFlaggingNeeded = false;

                if(drive.sked_Type_of_Drive__c.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) {
                    if(drive.sked_Total_Equipment_Requested__c > 0) isFlaggingNeeded = true;
                    else fsDrivesWithNoResourceRequestedCount++;
                } else {
                    if(drive.sked_Total_Vehicle_Requested__c > 0 || drive.sked_Total_Equipment_Requested__c > 0) {
                        isFlaggingNeeded = true;
                    }else if(drive.sked_Pending_Action_Reason_Code__c!=null && drive.sked_Pending_Action_Reason_Code__c.contains('Time Block')) { 
                        isFlaggingNeeded = true;
                    }else {
                        mobileDrivesWithNoResourceRequestedCount++;
                    }
                }

                if(isFlaggingNeeded) {
                    cbLogWrapper.drivesWOResourceAllocThoughRequested.add(
                        new Calendar_Build_Error_Log__c(
                            Category__c = BSF_Constants.MAP_DRIVETYPE_ERRORCATEGORY.get(drive.sked_Type_of_Drive__c),
                            Drive__c = drive.Id,
                            Opportunity__c = drive.sked_Opportunity__c,
                            Error_Information__c = map_driveId_noAllocationReason.containsKey(drive.Id) ? map_driveId_noAllocationReason.get(drive.Id) : 'No resource available'
                        )
                    ); 
                }
            }
            cbLogWrapper.fsSysGenDrivesWOResourceRequestedCount = (Decimal) fsDrivesWithNoResourceRequestedCount;
            cbLogWrapper.mobileSysGenDrivesWOResourceRequestedCount = (Decimal) mobileDrivesWithNoResourceRequestedCount;
            if(!String.isBlank(driveSource) 
                && (driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD) || driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_ADHOC_CALENDAR_BUILD)) //HRP-11368
            ) {
                DriveGenerationUtil.captureCbLogAndCbErrorLog(cbLogWrapper);

                // Call Resource Allocation Batch for Mobile Drives only for Calendar Build Process
                if(!String.isBlank(driveSource) && !String.isBlank(typeOfDrive) && !String.isBlank(runType) &&
                   driveSource.equalsIgnoreCase(BSF_Constants.OPP_SOURCE_CALENDAR_BUILD) &&
                   runType.equalsIgnoreCase(BSF_Constants.RUN_TYPE_SCHEDULED) &&
                   typeOfDrive.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)
                ) {
                    Database.executeBatch(new DriveResourceAllocationBatch(runType, driveSource, BSF_Constants.MOBILE_DRIVE, NULL, NULL), 1);
                }
            }

            //Custom exception to cover catch blocks 
            if(Test.isRunningTest() && BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION) {
                throw new CustomDriveResourceAllocationBatchException('This is custom exception during test class run');
            }
        } catch(Exception ex) {
            cbLogWrapper = new DriveGenerationUtil.CalendarBuildLogWrapper(
                this.driveDateToEval, 
                BSF_Constants.MAP_DRIVETYPE_BATCHTYPE.get(typeOfDrive), 
                this.runType
            );
            cbLogWrapper.apexMethodName = 'Finish Method Call';
            cbLogWrapper.opportunitySource = this.driveSource;
            cbLogWrapper.draftDriveListToBeProcessed = new List<sked_Drive__c>();
            
            DriveGenerationUtil.captureErrorLoggingForException(ex, cbLogWrapper);    
        }
        //HRP-12706 --> Continues
    } 
    
    /************************************************************** Resource Eligibility Evaluation ***********************************************************************/
    
    public void evaluateResourceEligibilityAndAllocateResources(List<sked__Resource__c> resourceList, sked_Drive__c drive, ResourceModel resourceModel) {
        Map<Id,sked__Resource__c> successfullyEvaluatedResourceMap = new Map<Id,sked__Resource__c>();
        if(!resourceList.isEmpty()) {
            List<sked__Resource__c> availableResourceListPassedCheckOne = filterResourceAvailability(resourceList, drive);
            List<sked__Resource__c> availableResourceListPassedCheckTwo = filterResourceNotBelongsToDriveCO(availableResourceListPassedCheckOne, drive);
            List<sked__Resource__c> availableResourceListPassedCheckThree = filterAccountBlacklist(availableResourceListPassedCheckTwo, drive);
            List<sked__Resource__c> availableResourceListPassedCheckFour = filterLocationBlacklist(availableResourceListPassedCheckThree, drive);
            List<sked__Resource__c> resourceListNeededForCOCheck = filterResourceDedicatedToSite(availableResourceListPassedCheckFour, successfullyEvaluatedResourceMap);
            filterResourceAvailabilityInJobCollectionOperation(resourceListNeededForCOCheck, drive, successfullyEvaluatedResourceMap);
            filterTagsAndAllocateResources(successfullyEvaluatedResourceMap, drive, resourceModel);     
        }
    }
    
    /*HRP-12760 --> Starts Here
        @Description : New method to compare timings of various events with drive timings to determine resource availability during job
    */
    public static Boolean isResourceAvailableDuringJob(List<sObject> eventList, sked_Drive__c drive, sked__Resource__c resource) {
        Boolean isResourceAvailable = TRUE;
        Boolean shouldBreakOuterLoop = FALSE;
        for(sked__Job__c job : drive.sked_jobs__r) {
            if(job.sked_Asset_Type__c == Constants.JOB_TYPE_EQUIPMENT || (drive.sked_Type_of_Drive__c == Constants.MOBILE_SITE_OPP && job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE)) {
                if(job.sked_Asset_Type__c != resource.sked_Asset_Type__c) {
                    continue;
                }
                for(sObject event : eventList) {
                    String eventType = String.valueOf(event.getSObjectType().getDescribe().getName());
                    Map<String, String> map_startEnd_fieldApiName = new Map<String, String>();
                    if(BSF_Constants.map_eventType_startEndFieldApiName.containsKey(eventType) && BSF_Constants.map_eventType_startEndFieldApiName.get(eventType) != NULL) {
                    	map_startEnd_fieldApiName = BSF_Constants.map_eventType_startEndFieldApiName.get(eventType);
                        DateTime eventStartTime = (DateTime) event.get(map_startEnd_fieldApiName.get('Start'));
                        DateTime eventEndTime = (DateTime) event.get(map_startEnd_fieldApiName.get('End'));
                        if(job.sked__Start__c < eventEndTime && job.sked__Finish__c > eventStartTime) {
                            isResourceAvailable = FALSE;
                            shouldBreakOuterLoop = TRUE;
                            break;
                        }
                    }
                }
            }
            if(shouldBreakOuterLoop) {
                break;
            }
        }
        return isResourceAvailable;
    }
    //HRP-12760 --> Ends Here

    //1. Check for Resource Availability
    @testVisible  private static List<sked__Resource__c> filterResourceAvailability(List<sked__Resource__c> resourceList, sked_Drive__c drive) {
        List<sked__Resource__c> resourceListToReturn = new List<sked__Resource__c>();
        List<String> unavailabilityTypes = new List<String>{'Maintenance','Activity','Break down'};
        for(sked__Resource__c res : resourceList) {
            Boolean isResourceAvailable = TRUE;

            //a. Check for Unavailability
            if(!res.sked__Availabilities1__r.isEmpty()) {
                for(sked__Availability__c unavailablity : res.sked__Availabilities1__r) {
                    if(unavailabilityTypes.contains(unavailablity.sked__Type__c)) {
                        isResourceAvailable = isResourceAvailableDuringJob(res.sked__Availabilities1__r, drive, res); //HRP-12760
                    }
                }
            }

            //b. Check for Overlapping Job Allocations
            if(!res.sked__Job_Allocations__r.isEmpty() && isResourceAvailable) {
                isResourceAvailable = isResourceAvailableDuringJob(res.sked__Job_Allocations__r, drive, res); //HRP-12760
            }

            //c. Check for Overlapping Activities
            if(!res.sked__Activities__r.isEmpty() && isResourceAvailable) {
                isResourceAvailable = isResourceAvailableDuringJob(res.sked__Activities__r, drive, res); //HRP-12760  
            }

            //d. Check for Overlapping Group Activities
            if(!res.sked__Activity_Resources__r.isEmpty() && isResourceAvailable) {
                isResourceAvailable = isResourceAvailableDuringJob(res.sked__Activity_Resources__r, drive, res); //HRP-12760  
            }

            if(isResourceAvailable) {
                resourceListToReturn.add(res);
            }            
        }
        return resourceListToReturn;
    }

    //2. Check for Resource Override - Not in Drive CO
    private static List<sked__Resource__c> filterResourceNotBelongsToDriveCO(List<sked__Resource__c> resourceList, sked_Drive__c drive){
        List<sked__Resource__c> resourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c resource : resourceList) {
            if(!resource.sked__Resource_Overrides__r.isEmpty()) {
                for(sked__Resource_Override__c resOverride : resource.sked__Resource_Overrides__r) {
                    if(resOverride.sked_Collection_Operation__c == driveCO) {
                        resourceListToReturn.add(resource);
                    }
                }
            } else {
                resourceListToReturn.add(resource);
            }  
        }  
        
        return resourceListToReturn;
    }

    //3. Check Account Blacklist     
    private static List<sked__Resource__c> filterAccountBlacklist(List<sked__Resource__c> resourceList, sked_Drive__c drive) {
        List<sked__Resource__c> resourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c resource : resourceList) {
            if(resource.sked__Account_Resource_Scores__r.isEmpty()) {
                resourceListToReturn.add(resource);
            }
        }
        return resourceListToReturn;
    }
    
    //4. Check Location Blacklist     
    private static List<sked__Resource__c> filterLocationBlacklist(List<sked__Resource__c> resourceList, sked_Drive__c drive) {
        List<sked__Resource__c> resourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c resource : resourceList) {
            if(resource.sked__Location_Resource_Scores__r.isEmpty()) {
                resourceListToReturn.add(resource);
            }
        }
        return resourceListToReturn;
    }
    
    //5. Check Resource Dedicated to Site
    private static List<sked__Resource__c> filterResourceDedicatedToSite(List<sked__Resource__c> resourceList, Map<Id,sked__Resource__c> successfullyEvaluatedResourceMap) {
        List<sked__Resource__c> resourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c resource : resourceList) {
            if(resource.sked_Dedicated_to_Site__c != NULL && resource.sked_Dedicated_to_Site__c == driveSite) {
                successfullyEvaluatedResourceMap.put(resource.Id, resource);
            } else {
                resourceListToReturn.add(resource);
            }
        }
        return resourceListToReturn;
    }
    
    //6. Check Resource Availability in Job Collection Operation
    private static void filterResourceAvailabilityInJobCollectionOperation(List<sked__Resource__c> resourceList, sked_Drive__c drive, Map<Id,sked__Resource__c> successfullyEvaluatedResourceMap) {
        List<sked__Resource_Override__c> resourceOverrideList = new List<sked__Resource_Override__c>();
        for(sked__Resource__c resource : resourceList) {
            // 1. Check for Primary CO
            if(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c == drive.sked_Collection_Operation__c) {
                if(!successfullyEvaluatedResourceMap.containsKey(resource.Id)) {
                    successfullyEvaluatedResourceMap.put(resource.Id, resource);
                }  
            }
            
            // 2. Check for Secondary CO
            if(!resource.sked_Resource_Biomed_Collection_Ops__r.isEmpty()) {
                for(sked_Resource_Biomed_Collection_Op__c secColOpr : resource.sked_Resource_Biomed_Collection_Ops__r) {
                    if(secColOpr.sked_Biomed_Collection_Op_Center__c == drive.sked_Collection_Operation__c 
                            && secColOpr.sked_Resource__c == resource.Id 
                            && (secColOpr.sked_Start_Date__c == NULL || secColOpr.sked_Start_Date__c <= drive.sked_Drive_Date__c) 
                            && (secColOpr.sked_End_Date__c == NULL || secColOpr.sked_End_Date__c >= drive.sked_Drive_Date__c)) {
                        if(!successfullyEvaluatedResourceMap.containsKey(resource.Id)) {            
                            successfullyEvaluatedResourceMap.put(resource.Id, resource);
                        }
                    }    
                }  
            }
    
            // 3. Check for Resource Override in Job CO
            if(!resource.sked__Resource_Overrides__r.isEmpty()) {
                for(sked__Resource_Override__c resOveride : resource.sked__Resource_Overrides__r) {
                    if(resOveride.sked_Collection_Operation__c == drive.sked_Collection_Operation__c) {
                        resourceOverrideList.add(resOveride);
                    }
                }
                Boolean isResourceAvailable = isResourceAvailableDuringJob(resourceOverrideList, drive, resource); //HRP-12760
                if(isResourceAvailable) {
                    if(!successfullyEvaluatedResourceMap.containsKey(resource.Id)) {
                        successfullyEvaluatedResourceMap.put(resource.Id, resource);
                    }
                }
            }
        }     
    }
    
    @testVisible  private void filterTagsAndAllocateResources(Map<Id,sked__Resource__c> resourceMap, sked_Drive__c drive, ResourceModel resourceModel) {
        List<sked__Job_Tag__c> jobTagList = new  List<sked__Job_Tag__c>();
        Map<Id,List<sked__Job_Tag__c>> jobVsJobTagMap = new Map<Id,List<sked__Job_Tag__c>>();

        // Get Job Tags
        if(drive.sked_Jobs__r != NULL && !drive.sked_Jobs__r.isEmpty()) {
            jobTagList = [SELECT sked__Tag__c,sked__Tag__r.sked__Type__c, sked__Job__c 
                            FROM sked__Job_Tag__c 
                            WHERE sked__Job__c IN: drive.sked_Jobs__r 
                            AND (sked__Job__r.sked_Asset_Type__c =: Constants.JOB_TYPE_VEHICLE 
                                OR sked__Job__r.sked_Asset_Type__c =: Constants.JOB_TYPE_EQUIPMENT)];
            for(sked__Job_Tag__c jobTag : jobTagList) {
                if(jobVsJobTagMap.containsKey(jobTag.sked__Job__c)){
                    jobVsJobTagMap.get(jobTag.sked__Job__c).add(jobTag);
                }else{
                    jobVsJobTagMap.put(jobTag.sked__Job__c, new List<sked__Job_Tag__c>{jobTag});
                }
            }
        }

        // Separate Out Vehicle and Equipment Type resources from successfully evaluated resource map
        if(resourceMap!= NULL && !resourceMap.isEmpty()) {
            for(sked__Resource__c res : resourceMap.values()) {  
                if(res.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE && res.sked_Pres_Donor_Capacity__c >= 0) { 
                    vehicleTypeResource.add(res);
                    map_allVehicleResourceId_presDonorCapacity.put(res.Id, res.sked_Pres_Donor_Capacity__c);
                } else if(res.sked_Asset_Type__c == Constants.JOB_TYPE_EQUIPMENT) {
                    equipmentTypeResource.add(res);
                }
                resourceVsResourceTagMap.put(res.Id,res.sked__ResourceTags__r);
            }
        }
        
        JobAllocations jobAllocation = new JobAllocations();
        jobAllocation.equipmentAllocations = selectionForEquipments(drive, equipmentTypeJob, equipmentTypeResource, resourceVsResourceTagMap, jobVsJobTagMap);
        jobAllocation.vehicleAllocations = selectionForVehicles(drive, vehicleTypeJob, vehicleTypeResource, resourceVsResourceTagMap, jobVsJobTagMap, map_allVehicleResourceId_presDonorCapacity, resourceModel);
        allocateResourceToJob(jobAllocation, drive);
    }
    
    //Job Allocation for Equipments
    private static Map<Id,Set<Id>> selectionForEquipments(sked_Drive__c drive,  List<sked__Job__c> equipmentTypeJob, List<sked__Resource__c> equipmentTypeResource, Map<Id,List<sked__Resource_Tag__c>> resourceVsResourceTagMap, Map<Id,List<sked__Job_Tag__c>> jobVsJobTagMap) {
        Set<Id> assignedResourceId = new  Set<Id>();
        Map<Id,Set<Id>> map_jobId_ResourceIds = new Map<Id,Set<Id>>();
        if(!equipmentTypeJob.isEmpty()) {
            for(sked__Job__c equipmentJob : equipmentTypeJob) {
                for (Integer i = 0 ; i < equipmentJob.sked__Quantity__c; i++) {
                    for(sked__Resource__c equipmentResource : equipmentTypeResource) {
                        if (map_jobId_ResourceIds.containsKey(equipmentJob.Id) && map_jobId_ResourceIds.get(equipmentJob.Id).size() == equipmentJob.sked__Quantity__c) {
                            break;
                        } else if(!resourceVsResourceTagMap.get(equipmentResource.Id).isEmpty() && jobVsJobTagMap.containskey(equipmentJob.Id) && !assignedResourceId.contains(equipmentResource.Id)) {
                            Integer count = 0;
                            for(sked__Resource_Tag__c resTag : resourceVsResourceTagMap.get(equipmentResource.Id)) {
                                if(resTag.sked_Start_Date__c  <= drive.sked_Drive_Date__c && (resTag.sked_Expiry_Date__c == null || (resTag.sked_Expiry_Date__c != null && drive.sked_Drive_Date__c <= resTag.sked_Expiry_Date__c))) {
                                    for(sked__Job_Tag__c jobTag : jobVsJobTagMap.get(equipmentJob.Id)) {
                                        if(jobTag.sked__Tag__c == resTag.sked__Tag__c) {
                                            count++;
                                        }
                                    }
                                }
                            }
                            if(count >= jobVsJobTagMap.get(equipmentJob.Id).size()) {
                                if (!map_jobId_ResourceIds.containsKey(equipmentJob.Id)) {
                                    map_jobId_ResourceIds.put(equipmentJob.Id, new Set<Id>{equipmentResource.Id});
                                }
                                map_jobId_ResourceIds.get(equipmentJob.Id).add(equipmentResource.Id);
                                assignedResourceId.add(equipmentResource.Id);
                            }
                        } else if(!jobVsJobTagMap.containskey(equipmentJob.Id) && !assignedResourceId.contains(equipmentResource.Id)) {
                            if (!map_jobId_ResourceIds.containsKey(equipmentJob.Id)) {
                                map_jobId_ResourceIds.put(equipmentJob.Id, new Set<Id>{equipmentResource.Id});
                            }
                            map_jobId_ResourceIds.get(equipmentJob.Id).add(equipmentResource.Id);
                            assignedResourceId.add(equipmentResource.Id);
                        }
                    }
                }   
            }
        }
        return map_jobId_ResourceIds;
    }
    
    //Job Allocation for Vehicles
    private Map<Id,Set<Id>> selectionForVehicles(sked_Drive__c drive,  List<sked__Job__c> vehicleTypeJob, List<sked__Resource__c> vehicleTypeResource, Map<Id,List<sked__Resource_Tag__c>> resourceVsResourceTagMap, Map<Id,List<sked__Job_Tag__c>> jobVsJobTagMap, Map<Id,Decimal> resourceIdVsCapacity, ResourceModel resourceModel){
        Map<Id,Set<Id>> map_jobId_ResourceIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> jobVsResourceAllocations = new Map<Id,Set<Id>>();
        Set<Id> assignedResourceId = new  Set<Id>();
        Set<Id> matchingTags;
        for(sked__Job__c vehicleJob : vehicleTypeJob) { // HRP-10212 start
            if(!vehicleTypeResource.isEmpty()) {
                for(sked__Resource__c vehicleResource : vehicleTypeResource) {
                    if(!resourceVsResourceTagMap.get(vehicleResource.Id).isEmpty() && jobVsJobTagMap.containskey(vehicleJob.Id) && !assignedResourceId.contains(vehicleResource.Id)) {
                        matchingTags = new Set<Id>();
                        for(sked__Resource_Tag__c resTag : resourceVsResourceTagMap.get(vehicleResource.Id)) {
                            if(resTag.sked_Start_Date__c  <= driveDate && (resTag.sked_Expiry_Date__c == NULL || (resTag.sked_Expiry_Date__c != NULL || driveDate <= resTag.sked_Expiry_Date__c))) {
                                for(sked__Job_Tag__c jobTag : jobVsJobTagMap.get(vehicleJob.Id)) {
                                    if(jobTag.sked__Tag__c == resTag.sked__Tag__c) {
                                        matchingTags.add(resTag.sked__Tag__c);
                                    }
                                }
                            }  
                        }
                        if(matchingTags.size() == jobVsJobTagMap.get(vehicleJob.Id).size()) {
                            if (!map_jobId_ResourceIds.containsKey(vehicleJob.Id)) {
                                map_jobId_ResourceIds.put(vehicleJob.Id, new Set<Id>{vehicleResource.Id});
                            }
                            map_jobId_ResourceIds.get(vehicleJob.Id).add(vehicleResource.Id);
                            assignedResourceId.add(vehicleResource.Id);
                            resourceIdVsResourceDetails.put(vehicleResource.Id, vehicleResource);
                        }
                    }else if(!resourceVsResourceTagMap.get(vehicleResource.Id).isEmpty() && !jobVsJobTagMap.containskey(vehicleJob.Id) && !assignedResourceId.contains(vehicleResource.Id)){
                        if (!map_jobId_ResourceIds.containsKey(vehicleJob.Id)) {
                            map_jobId_ResourceIds.put(vehicleJob.Id, new Set<Id>{vehicleResource.Id});
                        }
                        map_jobId_ResourceIds.get(vehicleJob.Id).add(vehicleResource.Id);
                        assignedResourceId.add(vehicleResource.Id);
                        resourceIdVsResourceDetails.put(vehicleResource.Id, vehicleResource);
                    }
                }
            }
        }

        Integer maxNoOfVehicles = 0;
        for (Id jobId : map_jobId_ResourceIds.keySet()) {
            Decimal pdC = 0;
            Set<Id> resourceIds = new Set<Id>();

            for(Integer i = 0; i < map_jobId_ResourceIds.get(jobId).size(); i++) {
                Id currentResourceId = new List<Id>(map_jobId_ResourceIds.get(jobId))[i];
                Decimal currentResourcePdc = resourceIdVsCapacity.get(currentResourceId);
                if(currentResourcePdc >= drive.sked_Projected_Registered_Donors__c) {
                    if(pdC == 0 || pdC >= currentResourcePdc) {
                        pdC = currentResourcePdc;
                        resourceIds = new Set<Id>{currentResourceId};
                    }
                } else {
                    if(pdC >= drive.sked_Projected_Registered_Donors__c) break;

                    if(pdC + currentResourcePdc < drive.sked_Projected_Registered_Donors__c) {
                        pdC += currentResourcePdc;
                        resourceIds.add(currentResourceId);
                        continue;
                    }

                    Decimal optimalPdc = currentResourcePdc;
                    Decimal optimalSum = pdC + currentResourcePdc;
                    Id bestResourceId = currentResourceId;

                    // check resources with smaller pdc value
                    for(Integer j = i + 1; j < map_jobId_ResourceIds.get(jobId).size(); j++) {
                        Id nextResourceId = new List<Id>(map_jobId_ResourceIds.get(jobId))[j];
                        Decimal nextResourcePdc = resourceIdVsCapacity.get(nextResourceId); 
                        Decimal cumulativeSum = pdc + nextResourcePdc;

                        if(cumulativeSum == optimalSum) continue;

                        if(cumulativeSum >= drive.sked_Projected_Registered_Donors__c && cumulativeSum < optimalSum) {
                            optimalSum = cumulativeSum;
                            optimalPdc = nextResourcePdc;
                            bestResourceId = nextResourceId;
                            
                            if(optimalSum == drive.sked_Projected_Registered_Donors__c) break;

                        } else break;
                    }

                    pdC += optimalPdc;
                    resourceIds.add(bestResourceId);
                    break;
                }
            }
                
            jobVsResourceAllocations.put(jobId, resourceIds);
            maxNoOfVehicles = resourceIds.size() > maxNoOfVehicles ? resourceIds.size() : maxNoOfVehicles;
        }
        
        for(Id jobId : jobVsResourceAllocations.keySet()) {
            for(Id resId : jobVsResourceAllocations.get(jobId)) {
                Boolean canResourceBeAllocated = false;
                sked__Resource__c resource = resourceIdVsResourceDetails.get(resId);
                if(resource.sked_DOT__c && 
                (resourceModel.isDOTLimitPresent == true && 
                (resourceModel.remainingNoOfDOT > 0 || resourceModel.remainingNoOfDOT == NULL)) || (resourceModel.isDOTLimitPresent == FALSE)) {
                    resourceModel.remainingNoOfDOT = resourceModel.remainingNoOfDOT != null ? resourceModel.remainingNoOfDOT - 1 : null;
                    canResourceBeAllocated = true;
                } else if(resource.sked_CDL__c && 
                (resourceModel.isCDLLimitPresent == true && 
                (resourceModel.remainingNoOfCDL > 0 || resourceModel.remainingNoOfCDL == null)) || (resourceModel.isCDLLimitPresent == FALSE)) {
                    resourceModel.remainingNoOfCDL = resourceModel.remainingNoOfCDL != null ? resourceModel.remainingNoOfCDL - 1 : null;
                    canResourceBeAllocated = true;
                } else if(!resource.sked_CDL__c && !resource.sked_DOT__c) {
                    canResourceBeAllocated = true;
                }

                if(!canResourceBeAllocated) {
                    jobVsResourceAllocations.get(jobId).remove(resId);
                }
            }
        }
            
        noOfVehicles = maxNoOfVehicles;
        return jobVsResourceAllocations;
    }

    //Job Allocation
    private  void allocateResourceToJob(JobAllocations jobAllocations, sked_Drive__c drive) {
        Integer noOfVehicleAllocations = jobAllocations.vehicleAllocations.keySet().size();
        Integer noOfEquipmentAllocations = jobAllocations.equipmentAllocations.keySet().size();
        List<sked__Job_Allocation__c> jobAlocList = new  List<sked__Job_Allocation__c>();
        Map<Id,sked__Job__c> IdVsJobMap = new Map<Id,sked__Job__c>(drive.sked_Jobs__r);
        if(jobAllocations != NULL && (noOfEquipmentAllocations > 0 || (noOfEquipmentAllocations == 0 && equipmentTypeJob.size() == 0))) {
            for(Id jobId : jobAllocations.equipmentAllocations.keySet()) {
                if(IdVsJobMap.get(jobId).sked__Quantity__c == jobAllocations.equipmentAllocations.get(jobId).size()) {
                    for(Id resId : jobAllocations.equipmentAllocations.get(jobId)){
                        sked__Job_Allocation__c jobAloc = new sked__Job_Allocation__c();
                        jobAloc.sked__Job__c = jobId;
                        jobAloc.sked__Resource__c = resId; 
                        jobAlocList.add(jobAloc);
                    }
                }            
            }
        }
        if(jobAllocations != null && noOfVehicleAllocations > 0){
            for(Id jobId : jobAllocations.vehicleAllocations.keySet()){
                for(Id resId : jobAllocations.vehicleAllocations.get(jobId)){
                    sked__Job_Allocation__c jobAloc = new sked__Job_Allocation__c();
                    jobAloc.sked__Job__c = jobId;
                    jobAloc.sked__Resource__c = resId;
                    jobAlocList.add(jobAloc);
                }
          }
        }
        List<sked__Job__c> combinedJobList = new List<sked__Job__c>();
        List<sked_Drive_Shift__c> driveshifts = getDriveShifts(drive.Id);
        if(!jobAlocList.isEmpty() && (noOfVehicleAllocations > 0 || (noOfVehicleAllocations == 0 && vehicleTypeJob.size() == 0)) && (noOfEquipmentAllocations > 0 || (noOfEquipmentAllocations == 0 && equipmentTypeJob.size() == 0))) {
            drive.sked_Status__c = drive.sked_Type_of_Drive__c == Constants.FIX_SITE_OPP ? (drive.sked_Opportunity__r.Source__c == Constants.SOURCE_CALENDAR_BUILD ? Constants.DRIVE_STATUS_CONFIRMED : Constants.DRIVE_STATUS_TENTATIVE) : Constants.DRIVE_STATUS_SYSTEM_GENERATED; //HRP-10009
            Boolean recalculationFlag = false;
            if (!jobAllocations.vehicleAllocations.isEmpty() && drive.sked_Type_of_Drive__c != Constants.FIX_SITE_OPP) {
                Decimal shiftTotalStaffCapacity = 0;
                Decimal shiftStaffCapacity = 0;
                Decimal shiftMaxRoleCapacity = 0; //HRP-13864
                Decimal driveMaxRoleCapacity = 0; //HRP-13864
                Decimal shiftMaxRoleCapacityWithDrawHours = 0; //HRP-13864
                Decimal driveMaxRoleCapacityWithDrawHours = 0; //HRP-13864
                Decimal staffPrimaryCount = 0;
                reCalTotalNoOfStaffRequired = 0;
                Map<String, Decimal> map_driveShiftId_driveShiftStaffCapacity = new Map<String, Decimal>();
                for(sked_Drive_Shift__c shift : driveshifts) {
                    GenerateMobileDrive.DriveStaffingComplementModel staffingComplement = new GenerateMobileDrive.DriveStaffingComplementModel(); //HRP-11634
                    for(sked__Job__c job : shift.sked_Jobs__r) { // HRP-11001 start
                        if ( (job.sked_Asset_Type__c != null) && (job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE && job.sked__Quantity__c != noOfVehicles)) {
                            recalculationFlag = true;
                        }
                    }
                    if(recalculationFlag) {
                        //HRP-11634 --> Starts Here
                        List<sked__Job__c> jobList = reCalculateStaffingComplement(
                            shift.sked_Jobs__r,
                            drive, 
                            shift,
                            noOfVehicles,
                            staffingComplement
                        );
                        combinedJobList.addAll(jobList);
                       
                        shiftStaffCapacity = Math.floor(reCalculateStaffCapacity(
                            drive,
                            shift,
                            staffingComplement
                        ));
                        map_driveShiftId_driveShiftStaffCapacity.put(shift.Id, shiftStaffCapacity);
                        shiftTotalStaffCapacity += shiftStaffCapacity;
                        staffPrimaryCount += getShiftPrimaryStaffCount(staffingComplement);
                        shiftMaxRoleCapacity = 0;
                        shiftMaxRoleCapacity = Math.floor(reCalculateMaxRoleCapacity(
                            drive,
                            shift,
                            staffingComplement
                        ));
                        if(shiftMaxRoleCapacity > driveMaxRoleCapacity){
                            driveMaxRoleCapacity = shiftMaxRoleCapacity;
                        }
                    } else{
                        system.debug('Drive recalculationFlag is false');
                    }
                }
                if(recalculationFlag) {
                    drive.sked_Staff_Capacity__c = shiftTotalStaffCapacity;
                    drive.Max_Role_Capacity__c = driveMaxRoleCapacity.setScale(2);
                    drive.Max_Role_Capacity_With_Draw_Hours__c = reCalculateMaxRoleCapacityWithDrawHours(
                        drive,
                        driveshifts,
                        driveMaxRoleCapacity
                    );
                    MobileDriveGeneratorDMLService.DMLDrive dmlDrive = reCalculateDriveAverageStaffCapacity(drive, staffPrimaryCount);
                    drive.Average_Staff_Capacity__c = dmlDrive?.averageStaffCapacity;
                    dmlDrive.maxRoleCapacityWithDrawHours = drive.Max_Role_Capacity_With_Draw_Hours__c;
                    drive.Excess_Staff_Capacity__c = reCalculateDriveExcessStaffCapacity(dmlDrive);
                }

                //HRP-11634 --> Ends Here
                if (remainingStaff >= reCalTotalNoOfStaffRequired) { // HRP-11001 start
                    if(recalculationFlag) {
                        update combinedJobList;
                        Decimal driveProductivity = 0;
                        List<sked_Drive_Shift__c> driveshiftsAfter = getDriveShifts(drive.Id); //HRP-11207 start
                        Map<Id, sked_Drive_Shift__c> map_driveShiftId_driveShift = new Map<Id, sked_Drive_Shift__c>();
                        for(sked_Drive_Shift__c driveShiftSingle : driveshiftsAfter) {
                            driveProductivity += reCalculateDriveProductivityPlanned(drive, driveShiftSingle); //HRP-11634
                            decimal staffSetupAfter = 0;
                            decimal staffSetupBefore = driveShiftSingle.sked_Staff_Setup__c;
                            for (sked__Job__c job : driveShiftSingle.sked_Jobs__r) {
                                if (!string.isBlank(job.sked_Resource_Role__c)) {
                                    staffSetupAfter += job.sked__Quantity__c;
                                }
                            }
                            if(staffSetupAfter != staffSetupBefore) {
                                driveShiftSingle.sked_Staff_Setup__c = staffSetupAfter;
                                map_driveShiftId_driveShift.put(driveShiftSingle.Id, driveShiftSingle);
                            }
                            if(driveShiftSingle.sked_Vehicles_Needed__c != noOfVehicles && driveShiftSingle.name == 'Shift 1') {
                                if(map_driveShiftId_driveShift.containsKey(driveShiftSingle.Id)) {
                                    driveShiftSingle = map_driveShiftId_driveShift.get(driveShiftSingle.Id);
                                } else {
                                    map_driveShiftId_driveShift.put(driveShiftSingle.Id, driveShiftSingle);
                                }
                                driveShiftSingle.sked_Vehicles_Needed__c = noOfVehicles;
                            }
                            driveShiftSingle.sked_Max_Donor_Capacity__c = map_driveShiftId_driveShiftStaffCapacity.get(driveShiftSingle.Id); //HRP-11634
                        }
                        drive.sked_Drive_Productivity_Planned__c = driveProductivity; //HRP-11634
                        if(map_driveShiftId_driveShift != null) {
                            update map_driveShiftId_driveShift.values();
                        } //HRP-11207 end
                    }
                }
            }
            if (remainingStaff >= reCalTotalNoOfStaffRequired) {
                insert jobAlocList;
           	    update drive;   
                //HRP-12706 -> Capturing drives with resource allocation as per tyoe of drive --> Starts here
                if(!typeOfDriveVsdriveIDSet.containsKey(drive.sked_Type_of_Drive__c)){
                	typeOfDriveVsdriveIDSet.put(drive.sked_Type_of_Drive__c, new Set<ID>());
            	}
            	typeOfDriveVsdriveIDSet.get(drive.sked_Type_of_Drive__c).add(drive.ID);
            } else if (isFixedSiteDrive(drive)) {
                insert jobAlocList;
                update drive;   
                if(!typeOfDriveVsdriveIDSet.containsKey(drive.sked_Type_of_Drive__c)){
                	typeOfDriveVsdriveIDSet.put(drive.sked_Type_of_Drive__c, new Set<ID>());
            	}
            	typeOfDriveVsdriveIDSet.get(drive.sked_Type_of_Drive__c).add(drive.ID);
                //HRP-12706 --> Ends Here
            } // HRP-11001 end
           	
        }//HRP-10009 Start 
        else if (isFixedSiteDrive(drive)) {
            drive.sked_Status__c = drive.sked_Opportunity__r.Source__c != Constants.SOURCE_CALENDAR_BUILD ? Constants.DRIVE_STATUS_TENTATIVE : Constants.DRIVE_STATUS_CONFIRMED;
            update drive;   
        }//HRP-10009 End
    }

    //HRP-11634 --> Starts Here

    @testVisible private static Decimal getShiftPrimaryStaffCount(GenerateMobileDrive.DriveStaffingComplementModel staffingComplement) {
        return staffingComplement.numberOfDrivers ?? 0 + staffingComplement.numberOfDriverSupports ?? 0 + staffingComplement.numberOfCharge ?? 0 + staffingComplement.numberOf2rbc ?? 0 + staffingComplement.numberOfVphh ?? 0;
    }

    @testVisible private static MobileDriveGeneratorDMLService.DMLDrive reCalculateDriveAverageStaffCapacity(
        sked_Drive__c driveSingle,
        Decimal totalStaffs
    ) {
        GenerateMobileDrive.mobileDriveGenerator driveGenInstance = new GenerateMobileDrive.mobileDriveGenerator();
        MobileDriveGeneratorDMLService.DMLDrive drive = new MobileDriveGeneratorDMLService.DMLDrive(MobileDriveGeneratorDMLService.fetchOpportunities(new Set<Id>{driveSingle.sked_Opportunity__c})[0]);  
        drive.staffCapacity = driveSingle.sked_Staff_Capacity__c;
        drive.totalStaffRequested = totalStaffs; 
        drive = driveGenInstance.calculateAverageStaffCapacity(drive);
        return drive;
    }

    @testVisible private static Decimal reCalculateDriveExcessStaffCapacity(
        MobileDriveGeneratorDMLService.DMLDrive drive
    ) {
        GenerateMobileDrive.mobileDriveGenerator driveGenInstance = new GenerateMobileDrive.mobileDriveGenerator(); 
        drive = driveGenInstance.calculateExcessStaffCapacity(drive);
        return drive?.excessStaffCapacity;
    }

    @testVisible private static Decimal reCalculateStaffCapacity(
        sked_Drive__c driveSingle,
        sked_Drive_Shift__c driveShiftSingle,
        GenerateMobileDrive.DriveStaffingComplementModel staffingComplement
    ) {
        Decimal staffCapacity = 0;
        GenerateMobileDrive.mobileDriveGenerator driveGenInstance = new GenerateMobileDrive.mobileDriveGenerator();
        sked_Staffing_Decision_Matrix__c matrix =  getStaffingDecisionMatrix(driveSingle.sked_Collection_Operation__c, driveSingle);
        MobileDriveGeneratorDMLService.DMLDrive drive = new MobileDriveGeneratorDMLService.DMLDrive(MobileDriveGeneratorDMLService.fetchOpportunities(new Set<Id>{driveSingle.sked_Opportunity__c})[0]);  
        drive.collectionOperation = new MobileDriveGeneratorDMLService.DMLCollectionOperation(MobileDriveGeneratorDMLService.fetchCollectionOperations(new Set<Id>{driveSingle.sked_Collection_Operation__c})[0]);
        MobileDriveGeneratorDMLService.DMLDriveShift driveShift = new MobileDriveGeneratorDMLService.DMLDriveShift(driveShiftSingle);
        driveShift.drawHourswithLunchBreak = getDrawHoursWithLunchBreak(driveSingle, driveShiftSingle);
        driveShift.numberOf2rbcEquipments = staffingComplement.numberOf2rbcEquipments ; 
        staffCapacity = driveGenInstance.calculateStaffCapacity(
            new List<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'},
            staffingComplement,
            drive,
            driveShift,
            new MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix(matrix),
            false
        );
        return staffCapacity;
    }

    //HRP-13864 starts here
    @testVisible private static Decimal reCalculateMaxRoleCapacityWithDrawHours(
        sked_Drive__c driveSingle,
        List<sked_Drive_Shift__c> driveshifts,
        Decimal driveMaxRoleCapacity
    ) {
        Decimal maxRoleCapacityWithDrawHours = 0;
        if(driveMaxRoleCapacity > 0){
            GenerateMobileDrive.mobileDriveGenerator driveGenInstance = new GenerateMobileDrive.mobileDriveGenerator();
            sked_Staffing_Decision_Matrix__c matrix =  getStaffingDecisionMatrix(driveSingle.sked_Collection_Operation__c, driveSingle);
            MobileDriveGeneratorDMLService.DMLDrive drive = new MobileDriveGeneratorDMLService.DMLDrive(MobileDriveGeneratorDMLService.fetchOpportunities(new Set<Id>{driveSingle.sked_Opportunity__c})[0]);  
            drive.collectionOperation = new MobileDriveGeneratorDMLService.DMLCollectionOperation(MobileDriveGeneratorDMLService.fetchCollectionOperations(new Set<Id>{driveSingle.sked_Collection_Operation__c})[0]);
            Decimal driveDrawHourswithLunchBreak = 0;
            for(sked_Drive_Shift__c driveShiftSingle : driveshifts){
                MobileDriveGeneratorDMLService.DMLDriveShift driveShift = new MobileDriveGeneratorDMLService.DMLDriveShift(driveShiftSingle);
                driveShift.drawHourswithLunchBreak = getDrawHoursWithLunchBreak(driveSingle, driveShiftSingle);
                driveDrawHourswithLunchBreak += driveShift.drawHourswithLunchBreak;
            }
            if(driveDrawHourswithLunchBreak > 0){
                maxRoleCapacityWithDrawHours = driveMaxRoleCapacity * driveDrawHourswithLunchBreak;
            }
        }
        return maxRoleCapacityWithDrawHours.setScale(2);
    }
    @testVisible private static Decimal reCalculateMaxRoleCapacity(
        sked_Drive__c driveSingle,
        sked_Drive_Shift__c driveShiftSingle,
        GenerateMobileDrive.DriveStaffingComplementModel staffingComplement
    ) {
        Decimal maxRoleCapacity = 0;
        GenerateMobileDrive.mobileDriveGenerator driveGenInstance = new GenerateMobileDrive.mobileDriveGenerator();
        sked_Staffing_Decision_Matrix__c matrix =  getStaffingDecisionMatrix(driveSingle.sked_Collection_Operation__c, driveSingle);
        MobileDriveGeneratorDMLService.DMLDrive drive = new MobileDriveGeneratorDMLService.DMLDrive(MobileDriveGeneratorDMLService.fetchOpportunities(new Set<Id>{driveSingle.sked_Opportunity__c})[0]);  
        drive.collectionOperation = new MobileDriveGeneratorDMLService.DMLCollectionOperation(MobileDriveGeneratorDMLService.fetchCollectionOperations(new Set<Id>{driveSingle.sked_Collection_Operation__c})[0]);
        MobileDriveGeneratorDMLService.DMLDriveShift driveShift = new MobileDriveGeneratorDMLService.DMLDriveShift(driveShiftSingle);
        driveShift.drawHourswithLunchBreak = getDrawHoursWithLunchBreak(driveSingle, driveShiftSingle);
        driveShift.numberOf2rbcEquipments = staffingComplement.numberOf2rbcEquipments ; 
        maxRoleCapacity = driveGenInstance.calculateMaxRoleCapacity(
            new List<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'},
            staffingComplement,
            drive,
            driveShift,
            new MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix(matrix),
            false
        );
        return maxRoleCapacity;
    }
    //HRP-13864 ends here
    
    @testVisible  private static List<sked__Job__c> reCalculateStaffingComplement(
        List<sked__Job__c> jobsToReCalculate,
        sked_Drive__c driveSingle,
        sked_Drive_Shift__c driveShiftSingle,
        Integer noOfVehicles, 
        GenerateMobileDrive.DriveStaffingComplementModel staffingComplement
    ) {
        List<sked__Job__c> jobsToUpdate = new List<sked__Job__c>();
        GenerateMobileDrive.mobileDriveGenerator driveGenInstance = new GenerateMobileDrive.mobileDriveGenerator();
        MobileDriveGeneratorDMLService.DMLDrive drive = new MobileDriveGeneratorDMLService.DMLDrive(MobileDriveGeneratorDMLService.fetchOpportunities(new Set<Id>{driveSingle.sked_Opportunity__c})[0]);
        drive.collectionOperation = new MobileDriveGeneratorDMLService.DMLCollectionOperation(MobileDriveGeneratorDMLService.fetchCollectionOperations(new Set<Id>{driveSingle.sked_Collection_Operation__c})[0]);
        MobileDriveGeneratorDMLService.DMLDriveShift driveShift = new MobileDriveGeneratorDMLService.DMLDriveShift(driveShiftSingle);
        driveShift.drawHourswithLunchBreak = getDrawHoursWithLunchBreak(driveSingle, driveShiftSingle);
        driveShift.projectedRegisteredDonors = driveSingle.sked_Projected_Registered_Donors__c.divide(driveSingle.sked_Drive_Shift_Count__c, 2, System.RoundingMode.UP);
        sked_Staffing_Decision_Matrix__c matrix =  getStaffingDecisionMatrix(driveSingle.sked_Collection_Operation__c, driveSingle);
        staffingComplement.numberOfVehicles = (Decimal)noOfVehicles;
        staffingComplement = driveGenInstance.calculateJobQuantity(staffingComplement, driveShift, drive.typeOfDrive, new MobileDriveGeneratorDMLService.DMLStaffingDecisionMatrix(matrix), drive);
        for (sked__Job__c job : jobsToReCalculate) {
            if (job.sked__Type__c == Constants.JOB_TYPE_DRIVER) {
                job.sked__Quantity__c = staffingComplement.numberOfDrivers;
                reCalTotalNoOfStaffRequired += job.sked__Quantity__c; // HRP-11001
                jobsToUpdate.add(job);
            } else if (job.sked__Type__c == Constants.JOB_TYPE_DRIVER_SUPPORT) {
                job.sked__Quantity__c = staffingComplement.numberOfDriverSupports;
                reCalTotalNoOfStaffRequired += job.sked__Quantity__c; // HRP-11001
                jobsToUpdate.add(job); 
            } else if (job.sked__Type__c == Constants.JOB_TYPE_VP_HH) {
                job.sked__Quantity__c = staffingComplement.numberOfVphh + job.sked_APT_Quantity__c;
                job.sked_VPHH_Quantity__c = staffingComplement.numberOfVphh;
                reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
                jobsToUpdate.add(job);
            } else if (job.sked__Type__c == Constants.JOB_TYPE_CHARGE) {
                job.sked__Quantity__c = staffingComplement.numberOfCharge;
                reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
                jobsToUpdate.add(job);
            } else if (job.sked__Type__c == Constants.JOB_TYPE_DRIVE_LEAD || job.sked__Type__c == Constants.JOB_TYPE_TEAM_SUPERVISOR) {
                reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
            } else if(job.sked__Type__c == Constants.PROCEDURE_TYPE_2RBC) {	
                reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
            } else if(job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE) {
                job.sked__Quantity__c = staffingComplement.numberOfVehicles;
                jobsToUpdate.add(job);
            } else if(job.sked_Asset_Type__c != Constants.JOB_TYPE_EQUIPMENT && job.sked_Volunteer_Role__c == null) { //HRP-11793
                reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
            }
        }

        return jobsToUpdate;
    }

    //calculate productivity
    @testVisible private static Decimal reCalculateDriveProductivityPlanned(
        sked_Drive__c driveSingle, 
        sked_Drive_Shift__c driveShiftSingle
    ) {
        GenerateMobileDrive.mobileDriveGenerator driveGenInstance = new GenerateMobileDrive.mobileDriveGenerator(); 
        List<MobileDriveGeneratorDMLService.DMLDriveShift> driveShifts = new List<MobileDriveGeneratorDMLService.DMLDriveShift>();
        List<MobileDriveGeneratorDMLService.DMLJob> driveShiftJobList = new List<MobileDriveGeneratorDMLService.DMLJob>();
        MobileDriveGeneratorDMLService.DMLDrive drive = new MobileDriveGeneratorDMLService.DMLDrive(MobileDriveGeneratorDMLService.fetchOpportunities(new Set<Id>{driveSingle.sked_Opportunity__c})[0]);  
        drive.collectionOperation = new MobileDriveGeneratorDMLService.DMLCollectionOperation(MobileDriveGeneratorDMLService.fetchCollectionOperations(new Set<Id>{driveSingle.sked_Collection_Operation__c})[0]);
        MobileDriveGeneratorDMLService.DMLDriveShift driveShift = new MobileDriveGeneratorDMLService.DMLDriveShift(driveShiftSingle);
        driveShift.drawHourswithLunchBreak = getDrawHoursWithLunchBreak(driveSingle, driveShiftSingle);
        drive.driveShifts = new List<MobileDriveGeneratorDMLService.DMLDriveShift>{driveShift};
        drive = driveGenInstance.calculateDriveProductivityPlanned(drive);
        return drive.driveProductivityPlanned;
    }
    
    @testVisible  private static Decimal getDrawHoursWithLunchBreak(sked_Drive__c drive, sked_Drive_Shift__c driveShift) {
        Decimal drawHours = 0;
        Datetime drawStartTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_Start_Time__c);
        Datetime drawStart = skedDateTimeUtils.toTimezone(drawStartTime, drive.sked_Timezone__c);
        Datetime drawEndTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_End_Time__c);
        Datetime drawEnd = skedDateTimeUtils.toTimezone(drawEndTime, drive.sked_Timezone__c);
        Decimal drawDuration = skedDateTimeUtils.getDifferentMinutes(drawStart, drawEnd);
        Decimal drawHoursActual = drawDuration / 60;
        drawHours = drawHoursActual;
        List<sked_Lunch_Break_Setting__c> lunchBreakSettings = fetchLunchBreakSettings();
        sked_Lunch_Break_Setting__c lunchBreakSetting = new sked_Lunch_Break_Setting__c();
        Decimal coMaxLunchBreakDuration = drive.sked_Maximum_Lunch_Break_Duration__c != NULL ? Decimal.valueOf(drive.sked_Maximum_Lunch_Break_Duration__c) : 30;
        for (sked_Lunch_Break_Setting__c setting : lunchBreakSettings) {
             Decimal maximumLunchBreakDuration = setting.sked_Maximum_Lunch_Break_Duration__c != NULL ? decimal.valueOf(setting.sked_Maximum_Lunch_Break_Duration__c) : 30;
             if (maximumLunchBreakDuration == coMaxLunchBreakDuration) {
                 lunchBreakSetting = setting;
                 break;
            }
        }
        if(driveShift.sked_Lunch_Break__c && (!drive.sked_Collection_Operation__r.sked_Lunch_Break_Before_Draw_Hours__c)){
            Decimal driveshiftDrawhr = (drawHoursActual * 60) -  decimal.valueOf(lunchBreakSetting.sked_Maximum_Lunch_Break_Duration__c);
            Decimal drawHourswithLunchBreak = driveshiftDrawhr.divide(60, 2, System.RoundingMode.UP);
            drawHours = drawHourswithLunchBreak != null ? drawHourswithLunchBreak : drawHoursActual;
        }
        return drawHours;
    }
    //HRP-11634 --> Ends Here
    
    //getDriveShifts for the Drive
    @testVisible private static List<sked_Drive_Shift__c> getDriveShifts(Id driveId) {
        return [Select Id, sked_Lunch_Break_Before_Draw_Hours__c, sked_Max_Donor_Capacity__c, Name, sked_Vehicles_Needed__c, sked_Lunch_Break__c, sked_2RBC_Projected_Procedures__c, sked_WB_Projected_Procedures__c, sked_Total_Products_Projected__c, sked_Total_Procedures_Projected__c, sked_Start_Time__c,sked_Drive_Date__c, sked_End_Time__c,sked_Timezone__c, sked_Staff_Setup__c, sked_Time_Block__c, sked_Contention__c, (SELECT Id,sked_VPHH_Quantity__c, sked_Site_Logistics_Back__c,sked_Site_Logistics_To__c,sked_Redcross_Volunteer_Quantity__c, sked_Sponsor_Volunteer_Quantity__c, sked__Location__c, sked_Drive__c,sked_Procedure_Type__c,sked_Drive_Shift__c,sked_Equipment_Subtype__c,sked_APT_Quantity__c,sked__Type__c,sked_Travel_Time2__c,sked_Travel_Time__c,sked_Lead_Time__c,sked_Wrap_up_Time__c,sked_Setup_Time__c,sked_Breakdown_Time__c,sked__Quantity__c, sked_Resource_Role__c, sked_Dual_Role__c, sked_Asset_Type__c, sked_Volunteer_Role__c, sked__Duration__c, sked__Finish__c, sked__Start__c FROM sked_Jobs__r) From sked_Drive_Shift__c Where sked_Drive__c =: driveId]; //HRP-11793
    }

    //getLunchBreakSettings for the Drive
    @testVisible private static List<sked_Lunch_Break_Setting__c> fetchLunchBreakSettings() {
        return [SELECT Id, Name, sked_Maximum_Lunch_Break_Duration__c,
                (SELECT Id, Name, sked_Lunch_Break_Duration__c,
                 sked_Lunch_Break_Setting__c, sked_Max_Number_of_Staff__c,
                 sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
                 FROM sked_Lunch_Break_Definitions__r)
                FROM sked_Lunch_Break_Setting__c];
    }
    
    //getstaffingDecisionMatrix for the Drive
    @testVisible private static sked_Staffing_Decision_Matrix__c getStaffingDecisionMatrix(Id collectionOperationId, sked_Drive__c drive) {
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrices = new List<sked_Staffing_Decision_Matrix__c>();
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMs = fetchCollectionOperationSDMs(collectionOperationId, drive); 
        staffingDecisionMatrices = fetchStaffingDecisionMatrices(collectionOperationSDMs, drive);
        return staffingDecisionMatrices[0];
    }
    
    private static List<sked_Collection_Operation_SDM__c> fetchCollectionOperationSDMs(Id collectionOperationIds, sked_Drive__c drive) {
        return [SELECT Id, sked_Collection_Operation__c, sked_Staffing_Decision_Matrix__c,
                sked_Effective_End_Date__c, sked_Effective_Start_Date__c
                FROM sked_Collection_Operation_SDM__c
                WHERE sked_Collection_Operation__c =:collectionOperationIds AND 
                sked_Effective_Start_Date__c <=: drive.sked_Drive_Date__c AND 
                (sked_Effective_End_Date__c >=: drive.sked_Drive_Date__c Or sked_Effective_End_Date__c = null)];
    }
    
    private static List<sked_Staffing_Decision_Matrix__c> fetchStaffingDecisionMatrices(List<sked_Collection_Operation_SDM__c> collectionOperationSDMs, sked_Drive__c drive) {
        
        Set<Id> staffingDecisionMatrixIds = new Set<Id>();
        for (sked_Collection_Operation_SDM__c collectionOperationSdm : collectionOperationSDMs) {
            staffingDecisionMatrixIds.add(collectionOperationSdm.sked_Staffing_Decision_Matrix__c);
        }
        return [SELECT Id, sked_2RBC_Staff_Capacity__c, sked_Charge_Capacity__c, sked_Charge_Threshold__c,
                sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, sked_WB_Hourly_Capacity__c,
                sked_Platelet_Hourly_Capacity__c, sked_Plasma_Hourly_Capacity__c, sked_2RBC_Hourly_Capacity__c,
                sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
                sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c,
                RecordType.Name
                FROM sked_Staffing_Decision_Matrix__c
                WHERE Id IN :staffingDecisionMatrixIds AND RecordType.Name =: drive.sked_Type_of_Drive__c];
    }

    @testVisible
    private static ResourceModel getCalculatedLimits(
        Decimal noOfRBCAllocated, 
        Decimal noOfCDLAllocated, 
        Decimal noOfDOTAllocated,
        ResourceModel resourceModelDriveLevel
    ) {
        if(resourceModelDriveLevel.isCDLLimitPresent) {
            resourceModelDriveLevel.remainingNoOfCDL = resourceModelDriveLevel.totalCDLLimit == NULL ? NULL : resourceModelDriveLevel.totalCDLLimit - noOfCDLAllocated;
        }
        if(resourceModelDriveLevel.isDOTLimitPresent) {
            resourceModelDriveLevel.remainingNoOfDOT = resourceModelDriveLevel.totalDOTLimit == NULL ? NULL : resourceModelDriveLevel.totalDOTLimit - noOfDOTAllocated;
        }
        if(resourceModelDriveLevel.is2RBCLimitPresent) {
            resourceModelDriveLevel.remainingNoOf2RBC = resourceModelDriveLevel.total2RBCLimit == NULL ? NULL : resourceModelDriveLevel.total2RBCLimit - noOfRBCAllocated;
        }
        return resourceModelDriveLevel;
    }

    public class JobAllocations{
        Map<Id, Set<Id>> vehicleAllocations;
        Map<Id, Set<Id>> equipmentAllocations;
    }

    public class ResourceModel {
        public Decimal totalCDLLimit;
        public Decimal totalDOTLimit;
        public Decimal total2RBCLimit;
        public Decimal remainingNoOfCDL;
        public Decimal remainingNoOfDOT;
        public Decimal remainingNoOf2RBC;
        public Boolean isCDLLimitPresent;
        public Boolean isDOTLimitPresent;
        public Boolean is2RBCLimitPresent;

        public ResourceModel() {
            this.totalCDLLimit = NULL; 
            this.totalDOTLimit = NULL; 
            this.total2RBCLimit = NULL;
            this.remainingNoOfCDL = NULL; 
            this.remainingNoOfDOT = NULL; 
            this.remainingNoOf2RBC = NULL;
            this.isCDLLimitPresent = FALSE; 
            this.isDOTLimitPresent = FALSE; 
            this.is2RBCLimitPresent = FALSE;
        }
    }

    private class CustomDriveResourceAllocationBatchException extends Exception {}
}