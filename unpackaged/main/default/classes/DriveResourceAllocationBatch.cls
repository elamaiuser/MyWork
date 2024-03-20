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
 *****************************************************************************
*/
global with sharing class DriveResourceAllocationBatch implements Database.Batchable<sObject>,Database.Stateful{	
    
    public sked_Drive__c drive;
    public String driveSite = '';
    public Date driveDate;
    public String driveCO = '';
    public String driveAccount = '';
    public Set<Id> driveIdSet;
    public Set<Id> processedDrive = new Set<Id>();	
    public Set<Id> processedResource = new Set<Id>();
    public static List<sked__Resource__c> vehicleTypeResource = new  List<sked__Resource__c>();
    public static List<sked__Resource__c> vehicleTypeResourceForCDL = new  List<sked__Resource__c>(); // HRP-10212
    public static List<sked__Resource__c> vehicleTypeResourceForDOT = new  List<sked__Resource__c>(); // HRP-10212
    public static List<sked__Resource__c> vehicleTypeResourceForRegVechicle = new  List<sked__Resource__c>(); // HRP-10212	
    public static List<sked__Resource__c> EquipmentTypeResource = new  List<sked__Resource__c>();	
    public static Map<Id,Decimal> resourceIdVsCapacity = new Map<Id,Decimal>();
    public static Map<Id,sked__Resource__c> resourceIdVsResourceDetails = new Map<Id,sked__Resource__c>();
    public static Map<Id,Decimal> resourceIdVsCapacityForCDLAndDOT = new Map<Id,Decimal>(); // HRP-10212
    public static Map<Id,Decimal> resourceIdVsCapacityForRegVechicle = new Map<Id,Decimal>(); // HRP-10212		
    public static Map<Id,List<sked__Resource_Tag__c>> resourceVsResourceTagMap = new Map<Id,List<sked__Resource_Tag__c>>();	
    public static List<sked__Job__c> vehicleTypeJob = new  List<sked__Job__c>();	
    public static List<sked__Job__c> equipmentTypeJob = new  List<sked__Job__c>();
    public static List<sked__Job__c> rbcJob = new  List<sked__Job__c>();
    public Integer noOfVehicles = 0; // HRP-10212
    public Integer count = 0;
    public Decimal remainingNoOfDOT = 0; // HRP-10212
    public Decimal remainingNoOfCDL = 0; // HRP-10212
    public static List<sked_Operation_Drive_Limit__c> operationalLimit = new List<sked_Operation_Drive_Limit__c> (); // HRP-10212
    public static Decimal remainingStaff = 0; // HRP-11001
    public static Decimal reCalTotalNoOfStaffRequired = 0; // HRP-11001
    
    public DriveResourceAllocationBatch(Set<Id> skedDrives){
        driveIdSet = new Set<Id>(skedDrives);
    }    
    

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(createDriveQuery());
    }	
    public void execute(Database.BatchableContext bc, List<sked_Drive__c> driveList)
    {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true; //HRP-11418 (Add check to prevent DOC update failure)

        drive = driveList[0];
        String dayOfWeek = drive.sked_Day_of_Week__c;
        String typeOfDrive = drive.sked_Type_of_Drive__c; // new
        driveSite = drive.sked_Drive_Site__c;
        driveDate = drive.sked_Drive_Date__c;
        driveCO = drive.sked_Collection_Operation__c;
        driveAccount = drive.sked_Account__c;
        List<sked__Resource__c> resList = Database.query(createResourceQuery()); 
        system.debug('drive.Id:: '+drive.Id);
        Decimal staffJobCount = 0;
        Decimal totalNoOfStaffRequired = 0; // HRP-10523
        Decimal RBCJobCount = 0; // HRP-10213
        Decimal totalNoOfCDL = 0; // HRP-10212
        Decimal totalNoOfDOT = 0; // HRP-10212
        Decimal totalNoOf2RBC = 0; // HRP-10213
        Decimal vechicleJobCount = 0; // HRP-10212
        
        for(sked__Job__c job : drive.sked_Jobs__r){	
            system.debug('job.sked_Asset_Type__c:: '+job.sked_Asset_Type__c);
            system.debug('job.sked__Type__c:: '+job.sked__Type__c);
            system.debug('job.sked__Quantity__c:: '+job.sked__Quantity__c);
            if(job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE){	
                vehicleTypeJob.add(job);
                vechicleJobCount += job.sked__Quantity__c; // HRP-10212
            }else if(job.sked_Asset_Type__c == Constants.JOB_TYPE_EQUIPMENT){	      
                equipmentTypeJob.add(job);	
            }else if(job.sked__Type__c == Constants.PROCEDURE_TYPE_2RBC){	      
                RBCJobCount += job.sked__Quantity__c; // HRP-10213
                staffJobCount += job.sked__Quantity__c; // HRP-11001
            }else{
                staffJobCount += job.sked__Quantity__c;
            }
        }
		System.debug('RBCJobCount:: '+RBCJobCount);
        totalNoOfStaffRequired = staffJobCount; //HRP-10523 HRP-11001
		System.debug('totalNoOfStaffRequired:: '+totalNoOfStaffRequired);
        // HRP-10212 and HRP-10213 start
        operationalLimit = [SELECT Id, Name, sked_Collection_Operation__c, sked_Days_of_Week__c, sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Quantity__c, sked_Type__c, sked_MigrationID__c FROM sked_Operation_Drive_Limit__c
                                                                   Where (sked_Type__c =: Constants.OPERATION_DRIVE_2RBC_LIMIT OR sked_Type__c =: Constants.OPERATION_DRIVE_DOT_LIMIT OR sked_Type__c =: Constants.OPERATION_DRIVE_CDL_LIMIT) AND sked_Collection_Operation__c =: drive.sked_Collection_Operation__c
                                                                   AND ( ( sked_Effective_Start_Date__c <=: drive.sked_Drive_Date__c AND (sked_Effective_End_Date__c = NULL
                                                                   OR sked_Effective_End_Date__c >=: drive.sked_Drive_Date__c ) ) OR ( ( sked_Effective_Start_Date__c = NULL
                                                                   OR sked_Effective_Start_Date__c <=: drive.sked_Drive_Date__c ) AND sked_Effective_End_Date__c >=: drive.sked_Drive_Date__c ) )];
        
        if(!operationalLimit.isEmpty()){
                    Set<Id> storeOperationDriveLimitID = new Set <Id>();
                    Map<Id,Decimal> operationDriveLimitOverrideIdVsQuantity = new Map<Id,Decimal>();
                    for(sked_Operation_Drive_Limit__c iterateOperationDriveLimit: operationalLimit){
                            storeOperationDriveLimitID.add(iterateOperationDriveLimit.Id);
                        }
                    List<sked_Operation_Drive_Limit_Override__c> operationDriveLimitOverride = [SELECT Id, sked_Operation_Drive_Limit__c, sked_Operation_Drive_Limit__r.sked_Type__c, sked_Date__c, sked_Quantity__c FROM sked_Operation_Drive_Limit_Override__c where sked_Operation_Drive_Limit__c IN: storeOperationDriveLimitID AND sked_Date__c =: drive.sked_Drive_Date__c ];
                    system.debug('operationDriveLimitOverride:::'+operationDriveLimitOverride);
                    if(!operationDriveLimitOverride.isEmpty()){
                    for(sked_Operation_Drive_Limit_Override__c iterateOperationDriveLimit : operationDriveLimitOverride){
                            operationDriveLimitOverrideIdVsQuantity.put(iterateOperationDriveLimit.sked_Operation_Drive_Limit__c,iterateOperationDriveLimit.sked_Quantity__c);
                        }
            }
            boolean cDLFlag = true,dOTFlag = true, rBCFlag = true;
            for(sked_Operation_Drive_Limit__c iterateOperationDriveLimit : operationalLimit){
                if(iterateOperationDriveLimit.sked_Type__c == Constants.OPERATION_DRIVE_DOT_LIMIT){
                      if((!operationDriveLimitOverride.isEmpty()) && operationDriveLimitOverrideIdVsQuantity.containsKey(iterateOperationDriveLimit.Id)){
                        dOTFlag = false;
                        totalNoOfDOT = operationDriveLimitOverrideIdVsQuantity.get(iterateOperationDriveLimit.Id) == null ? null : operationDriveLimitOverrideIdVsQuantity.get(iterateOperationDriveLimit.Id);
                        } else{
                            if(iterateOperationDriveLimit.sked_Days_of_Week__c != null && (iterateOperationDriveLimit.sked_Days_of_Week__c.contains(dayOfWeek))){
                                dOTFlag = false;
                                if(totalNoOfDOT == null){
                                    if(iterateOperationDriveLimit.sked_Quantity__c == null){
                                        totalNoOfDOT = null;
                                    } else{
                                        totalNoOfDOT = iterateOperationDriveLimit.sked_Quantity__c;
                                    }
                                } else{
                                    if(iterateOperationDriveLimit.sked_Quantity__c == null){
                                        totalNoOfDOT = totalNoOfDOT;
                                    } else{
                                        totalNoOfDOT = totalNoOfDOT + iterateOperationDriveLimit.sked_Quantity__c;
                                    }
                                }
                            } else if(totalNoOfDOT == 0 && dOTFlag){
                                totalNoOfDOT = null;
                            }
                        }
                } else if (iterateOperationDriveLimit.sked_Type__c == Constants.OPERATION_DRIVE_CDL_LIMIT){
                 if((!operationDriveLimitOverride.isEmpty()) && operationDriveLimitOverrideIdVsQuantity.containsKey(iterateOperationDriveLimit.Id)){
                    cDLFlag = false;
                    totalNoOfCDL = operationDriveLimitOverrideIdVsQuantity.get(iterateOperationDriveLimit.Id) == null ? null : operationDriveLimitOverrideIdVsQuantity.get(iterateOperationDriveLimit.Id);
                    } else{
                        if(iterateOperationDriveLimit.sked_Days_of_Week__c != null && (iterateOperationDriveLimit.sked_Days_of_Week__c.contains(dayOfWeek))){
                            cDLFlag = false;
                            if(totalNoOfCDL == null){
                                if(iterateOperationDriveLimit.sked_Quantity__c == null){
                                    totalNoOfCDL = null;
                                } else{
                                    totalNoOfCDL = iterateOperationDriveLimit.sked_Quantity__c;
                                }
                            } else{
                                if(iterateOperationDriveLimit.sked_Quantity__c == null){
                                    totalNoOfCDL = totalNoOfCDL;
                                } else{
                                    totalNoOfCDL = totalNoOfCDL + iterateOperationDriveLimit.sked_Quantity__c;
                                }
                            }
                        } else if(totalNoOfCDL == 0 && cDLFlag){
                            totalNoOfCDL = null;
                        }
                    }
                     
                } else if(iterateOperationDriveLimit.sked_Type__c == Constants.OPERATION_DRIVE_2RBC_LIMIT){
                    if((!operationDriveLimitOverride.isEmpty()) && operationDriveLimitOverrideIdVsQuantity.containsKey(iterateOperationDriveLimit.Id)){
                        rBCFlag = false;
                        totalNoOf2RBC = operationDriveLimitOverrideIdVsQuantity.get(iterateOperationDriveLimit.Id) == null ? null : operationDriveLimitOverrideIdVsQuantity.get(iterateOperationDriveLimit.Id);
                        } else{
                            if(iterateOperationDriveLimit.sked_Days_of_Week__c != null && (iterateOperationDriveLimit.sked_Days_of_Week__c.contains(dayOfWeek))){
                            rBCFlag = false;
                            if(totalNoOf2RBC == null){
                                if(iterateOperationDriveLimit.sked_Quantity__c == null){
                                    totalNoOf2RBC = null;
                                } else{
                                    totalNoOf2RBC = iterateOperationDriveLimit.sked_Quantity__c;
                                }
                            } else{
                                if(iterateOperationDriveLimit.sked_Quantity__c == null){
                                    totalNoOf2RBC = totalNoOf2RBC;
                                } else{
                                    totalNoOf2RBC = totalNoOf2RBC + iterateOperationDriveLimit.sked_Quantity__c;
                                }
                            }
                        } else if(totalNoOf2RBC == 0 && rBCFlag){
                            totalNoOf2RBC = null;
                        }
                    }
                } 
            }
            if(cDLFlag){
                totalNoOfCDL = null;
            }
            if(dOTFlag){
                totalNoOfDOT = null;
            }
            if(rBCFlag){
                totalNoOf2RBC = null;
            }
        } // HRP-10212 and HRP-10213 end
        System.debug('totalNoOfCDL:: '+totalNoOfCDL);
        System.debug('totalNoOfDOT:: '+totalNoOfDOT);
        List<sked_Staffing_Constraint__c> staffConstraintList = [Select Id, sked_Collection_Operation__c, sked_Date_of_Constraint__c, 
                                                                 sked_Total_Staff_Constraints__c,sked_Num_Available_Staff__c // HRP-10523
                                                                 From sked_Staffing_Constraint__c Where 
                                                                 sked_Drive_Type__c =: drive.sked_Type_of_Drive__c AND //HRP-10009
                                                                 sked_Collection_Operation__c =: drive.sked_Collection_Operation__c AND 
                                                                 sked_Date_of_Constraint__c =: drive.sked_Drive_Date__c LIMIT 1];
        if(staffConstraintList.size() > 0)
        {
            // quering for pre-existing drives
            List<sked_Drive__c> drvList = [Select Id,sked_Status__c,sked_Collection_Operation__c,sked_Type_of_Drive__c,
                                           (SELECT Id,sked__Type__c,sked_Drive_Shift__c,sked__Quantity__c,sked_Asset_Type__c FROM sked_Jobs__r) 
                                           From sked_Drive__c Where sked_Status__c !=: Constants.DRIVE_STATUS_DRAFT
                                           AND sked_Status__c !=: Constants.DRIVE_STATUS_CANCELLED 
                                           AND sked_Collection_Operation__c =: drive.sked_Collection_Operation__c 
                                           AND sked_Drive_Date__c =: drive.sked_Drive_Date__c
                                           AND sked_Type_of_Drive__c =:typeOfDrive]; // new

            Decimal noOfStaffsAllocated = 0; // HRP-10212
            Decimal noOfRBCAllocated = 0; // HRP-10213
            Decimal noOfCDLAllocated = 0; // HRP-10212
            Decimal noOfDOTAllocated = 0; // HRP-10212
            Set<Id> storeJobIdOfVehicle = new Set <Id>(); // HRP-10212 and HRP 10213
            system.debug('drivelist contains '+drvList.size()+' drives');
            if (drvList.size() > 0) {
                for(sked_Drive__c drives : drvList){
                    system.debug(' drive Id '+drives.id+' and type of drive '+drives.sked_Type_of_Drive__c);
                    if(drives.sked_Jobs__r != null || !drives.sked_Jobs__r.isEmpty()){
                        for(sked__Job__c job : drives.sked_Jobs__r){
                            if(job.sked_Asset_Type__c != Constants.JOB_TYPE_VEHICLE && job.sked_Asset_Type__c != Constants.JOB_TYPE_EQUIPMENT){
                                noOfStaffsAllocated += job.sked__Quantity__c;
                            }
                            if (job.sked__Type__c == Constants.PROCEDURE_TYPE_2RBC) {
                                noOfRBCAllocated += job.sked__Quantity__c;
                            }
                            if(job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE){ // HRP-10212 and HRP 10213
                                storeJobIdOfVehicle.add(job.Id); 
                            }

                        }

                    }  
                }
            }
            if(storeJobIdOfVehicle != Null){ // HRP-10212 start
                List <sked__Job_Allocation__c> vehicleJobAllotedJob = [SELECT Id, sked__Resource__r.sked_DOT__c, sked__Resource__r.sked_CDL__c, sked__Job__r.sked__Quantity__c FROM sked__Job_Allocation__c where sked__Job__c IN: storeJobIdOfVehicle];
                if(vehicleJobAllotedJob.size()>0){
                    for(sked__Job_Allocation__c jobAllocation : vehicleJobAllotedJob){
                        if(jobAllocation.sked__Resource__r.sked_DOT__c == true){
                            noOfDOTAllocated += jobAllocation.sked__Job__r.sked__Quantity__c;
                        }
                        if(jobAllocation.sked__Resource__r.sked_CDL__c == true){
                            noOfCDLAllocated += jobAllocation.sked__Job__r.sked__Quantity__c;
                        }
                    }
                }
            }
            if(!operationalLimit.isEmpty()){
                    remainingNoOfDOT = ( totalNoOfDOT == null ) ? null : totalNoOfDOT - noOfDOTAllocated;
                    remainingNoOfCDL = ( totalNoOfCDL == null ) ? null : totalNoOfCDL - noOfCDLAllocated;
            } // HRP-10212 end

            /* Logic for HRP-10523 -  Calculating remaining staff by subtracting noOfStaffAllocated from Available staffs (New Field Added) instead of total staff constraint field
            * This field will dynamically capture the no. of available staffs once they move to different col opp
            */
            system.debug('No of DOT allocated to previous drives:: '+noOfDOTAllocated);
            system.debug('No of CDL allocated to previous drives:: '+noOfCDLAllocated);
            system.debug('No of Remaning CDL :: '+remainingNoOfDOT);
            system.debug('No of total CDL :: '+totalNoOfCDL);
            system.debug('No of total DOT :: '+totalNoOfDOT);
            system.debug('No of Remaning DOT :: '+remainingNoOfDOT);
            system.debug('No of staffs allocated for pre-existing drives:: '+noOfStaffsAllocated);
            system.debug('Num of available staffs :: '+staffConstraintList[0].sked_Total_Staff_Constraints__c);

            remainingStaff = staffConstraintList[0].sked_Total_Staff_Constraints__c - noOfStaffsAllocated; // HRP-10523 // HRP-11224

            system.debug('No of remaining staffs :: '+remainingStaff);
            system.debug('No of staffs required :: '+totalNoOfStaffRequired);

            if (remainingStaff >= totalNoOfStaffRequired && ((operationalLimit.isEmpty()) || ( totalNoOf2RBC == NULL ) || ( totalNoOf2RBC == 0 ) || ( RBCJobCount == 0 ) || ( RBCJobCount <= (totalNoOf2RBC - noOfRBCAllocated)) ) ) { // HRP-10212 and HRP-10213
                checkAvailableResource(resList, driveList[0]);
            } //HRP-10009 Start 
            else if (drive.sked_Type_of_Drive__c == Constants.FIX_SITE_OPP) {
                drive.sked_Status__c = drive.sked_Opportunity__r.Source__c != Constants.SOURCE_CALENDAR_BUILD ? Constants.DRIVE_STATUS_TENTATIVE : Constants.DRIVE_STATUS_CONFIRMED;
                update drive;
                processedDrive.add(drive.Id);
            }//HRP-10009 End 
        } else if (drive.sked_Type_of_Drive__c == Constants.FIX_SITE_OPP) {
            drive.sked_Status__c = drive.sked_Opportunity__r.Source__c != Constants.SOURCE_CALENDAR_BUILD ? Constants.DRIVE_STATUS_TENTATIVE : Constants.DRIVE_STATUS_CONFIRMED;
            update drive;
            processedDrive.add(drive.Id);
        }
    }
    
    private static String createResourceQuery () {	
        String queryStr = 'SELECT Id,sked_DOT__c, sked_CDL__c,sked_Dedicated_to_Site__c,sked_Equipment_Subtype__c,sked_Asset_Type__c,sked_Pres_Donor_Capacity__c,sked__Is_Active__c,sked__Primary_Region__c,'+	
            'sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,(SELECT sked_Biomed_Collection_Op_Center__c,sked_Start_Date__c,sked_End_Date__c,sked_Resource__c'+	
            ' FROM sked_Resource_Biomed_Collection_Ops__r),(SELECT sked__Blacklisted__c,sked__Account__c FROM sked__Account_Resource_Scores__r Where sked__Blacklisted__c = false AND sked__Account__c =: driveAccount),'+	
            '(SELECT sked_Collection_Operation__c,sked__Resource__c,sked_Start_Date__c,sked_End_Date__c FROM sked__Resource_Overrides__r Where sked_Collection_Operation__c =: driveCO AND sked_Start_Date__c <=: driveDate AND sked_End_Date__c >=: driveDate),'+
            '(SELECT sked__Blacklisted__c,sked__Location__c FROM sked__Location_Resource_Scores__r Where sked__Blacklisted__c = false AND sked__Location__c =: driveSite),'+
            '(SELECT Id, Name,sked_Start_Date__c, sked__Status__c,sked_Finish_Date__c, sked__Resource__c  FROM sked__Availabilities1__r),'+	
            '(SELECT sked__Status__c ,sked__Resource__c,sked_Start_Date__c,sked_Set_End_Date__c FROM sked__Job_Allocations__r Where sked__Status__c  != \'Deleted\' AND sked_Start_Date__c <=: driveDate AND sked_Set_End_Date__c >=: driveDate),'+	
            '(SELECT sked__Resource__c,sked_Start_Date__c,sked_End_Date__c FROM sked__Activities__r),(SELECT Id, Name,sked__Activity__r.sked_Start_Date__c,'+	
            'sked__Activity__r.sked_End_Date__c,  sked__Resource__c FROM sked__Activity_Resources__r),(SELECT sked__Resource__c ,sked_Start_Date__c,sked_Expiry_Date__c,'+	
            'sked__Tag__c,sked_Tag_Type__c FROM sked__ResourceTags__r) FROM sked__Resource__c WHERE sked__Is_Active__c = true AND (sked_Asset_Type__c = \'Vehicle\''+	
            ' OR sked_Asset_Type__c = \'Equipment\' OR sked_Asset_Type__c = \'2RBC\') AND (sked_Dedicated_to_Site__c = null OR sked_Dedicated_to_Site__c =: driveSite) ORDER BY sked_Pres_Donor_Capacity__c DESC'; // HRP-11001
        return queryStr;		
    }
    
    private static String createDriveQuery () {
        String queryString = 'SELECT Id, Name,sked_Status__c, sked_Day_of_Week__c, sked_2RBC_Projected_Procedures__c,' +
            ' sked_Total_Products_Projected__c, sked_Maximum_Lunch_Break_Duration__c ,sked_Drive_Site__c,sked_Collection_Operation__c,'+
            ' sked_End_Time__c, sked_Account__c,sked_Collection_Operation__r.sked_Lunch_Break_Before_Draw_Hours__c,sked_Timezone__c,sked_Start_Time__c, sked_Projected_Registered_Donors__c,sked_Drive_Date__c,'+
            'sked_Opportunity__c, sked_Opportunity__r.Source__c, sked_Type_of_Drive__c ,sked_Drive_Site__r.sked_Physical_Location_Type__c, (SELECT Id,sked_Equipment_Subtype__c,'+
            'sked__Type__c,sked_Travel_Time2__c,sked_Travel_Time__c,sked_Lead_Time__c,sked_Wrap_up_Time__c,sked_Setup_Time__c,sked_Breakdown_Time__c,'+
            'sked_Drive_Shift__c,sked__Quantity__c,sked_Resource_Role__c,sked_Asset_Type__c,sked_APT_Quantity__c FROM sked_Jobs__r) FROM sked_Drive__c '+
            'WHERE  ( sked_Status__c =\'Draft\') AND Id IN: driveIdSet ORDER BY sked_Rank__c';
            return queryString;
    }
    
    public void finish(Database.BatchableContext bc){
    } 
    
    public void checkAvailableResource(List<sked__Resource__c> resList, sked_Drive__c drive){
        List<sked__Resource__c> resourceList = new List<sked__Resource__c>();
        Map<Id,Set<Id>> jobVsResourceIds = new Map<Id,Set<Id>>();
        if(!resList.isEmpty()){
            List<sked__Resource__c> resourceDedicatedToSite = filterResourceDedicatedToSite(resList, drive);
            List<sked__Resource__c> resourceavailableInJobCollectionOperation = filterResourceavailableInJobCollectionOperation(resourceDedicatedToSite, drive);
            List<sked__Resource__c> resourceNotMovedToOperation = filterResourceIsNotMovedToCollectionOperation(resourceavailableInJobCollectionOperation, drive);
            List<sked__Resource__c> resourceAccountBlacklist = filterAccountBlacklist(resourceNotMovedToOperation, drive);
            List<sked__Resource__c> resourceLocationBlacklist = filterLocationBlacklist(resourceAccountBlacklist, drive);
            List<sked__Resource__c> resourceAvailability = filterResourceAvailability(resourceLocationBlacklist, drive);
            filterTags(resourceAvailability, drive);
            
        }
    }
    
    //2.Check Resource is dedicated to a site
    private static List<sked__Resource__c> filterResourceDedicatedToSite(List<sked__Resource__c> resList, sked_Drive__c drive){
        List<sked__Resource__c> reourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c res : resList){
            if(res.sked_Dedicated_to_Site__c == null){
                reourceListToReturn.add(res);
                }else if(res.sked_Dedicated_to_Site__c == drive.sked_Drive_Site__c){
                reourceListToReturn.add(res);
            }
        }
        return reourceListToReturn;
    } 
    
    //3.Check Resource is available in Job Collection Operation(incomplete)
    private static List<sked__Resource__c> filterResourceavailableInJobCollectionOperation(List<sked__Resource__c> resList, sked_Drive__c drive){
        List<sked__Resource__c> reourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c res : resList){
            if(res.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c == drive.sked_Collection_Operation__c ){
                reourceListToReturn.add(res);
            }
            else if(!res.sked_Resource_Biomed_Collection_Ops__r.isEmpty()){
                for(sked_Resource_Biomed_Collection_Op__c secColOpr : res.sked_Resource_Biomed_Collection_Ops__r){
                    if(secColOpr.sked_Biomed_Collection_Op_Center__c == drive.sked_Collection_Operation__c && secColOpr.sked_Resource__c == res.Id && 
                       (secColOpr.sked_Start_Date__c == null || secColOpr.sked_Start_Date__c <= drive.sked_Drive_Date__c) && (secColOpr.sked_End_Date__c == null || secColOpr.sked_End_Date__c >= drive.sked_Drive_Date__c)){
                        reourceListToReturn.add(res);
                    } 
                }  
            }  
            else if(!res.sked__Resource_Overrides__r.isEmpty()){
                for(sked__Resource_Override__c resOveride : res.sked__Resource_Overrides__r){
                    if(resOveride.sked_Collection_Operation__c == drive.sked_Collection_Operation__c && (resOveride.sked_Start_Date__c <= drive.sked_Drive_Date__c && resOveride.sked_End_Date__c >= drive.sked_Drive_Date__c) && resOveride.sked__Resource__c == res.Id ){
                        reourceListToReturn.add(res);
                    } 
                }
            }
        }
        return reourceListToReturn; 
    }
    
    //4.Resource is not moved to another Collection Operation
    private static List<sked__Resource__c> filterResourceIsNotMovedToCollectionOperation(List<sked__Resource__c> resList, sked_Drive__c drive){
        List<sked__Resource__c> reourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c res : resList){
            if(!res.sked__Resource_Overrides__r.isEmpty()){
                for(sked__Resource_Override__c resOveride : res.sked__Resource_Overrides__r){
                    if(!(resOveride.sked_Collection_Operation__c != drive.sked_Collection_Operation__c && (resOveride.sked_Start_Date__c <= drive.sked_Drive_Date__c && resOveride.sked_End_Date__c >= drive.sked_Drive_Date__c) && resOveride.sked__Resource__c == res.Id )){
                        reourceListToReturn.add(res);
                    } 
                }
            } 
            else {
                reourceListToReturn.add(res);
            }
        }
        return reourceListToReturn;
    }
    
    //5. Check account & location blacklist     
    private static List<sked__Resource__c> filterAccountBlacklist(List<sked__Resource__c> resList, sked_Drive__c drive){
        List<sked__Resource__c> reourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c res : resList){
            if(res.sked__Account_Resource_Scores__r.isEmpty()){
                reourceListToReturn.add(res);
            }else{
                for(sked__Account_Resource_Score__c accRes : res.sked__Account_Resource_Scores__r){
                    if(accRes.sked__Blacklisted__c = false && (accRes.sked__Account__c == drive.sked_Account__c)){
                        reourceListToReturn.add(res);
                    }
                }
            }
        }
        return reourceListToReturn;
    }
    
    //5. Check account & location blacklist     
    private static List<sked__Resource__c> filterLocationBlacklist(List<sked__Resource__c> resList, sked_Drive__c drive){
        List<sked__Resource__c> reourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c res : resList){
            if(res.sked__Location_Resource_Scores__r.isEmpty()){
                reourceListToReturn.add(res);
            }else{
                for(sked__Location_Resource_Score__c locRes : res.sked__Location_Resource_Scores__r){
                    if(locRes.sked__Blacklisted__c = false && (locRes.sked__Location__c == drive.sked_Drive_Site__c)){
                        reourceListToReturn.add(res);
                    }
                }
            }
        }
        return reourceListToReturn;
    }
    
    //7.Check Resource availability
    @testVisible  private static List<sked__Resource__c> filterResourceAvailability(List<sked__Resource__c> resList,sked_Drive__c drive){
        List<sked__Resource__c> reourceListToReturn = new List<sked__Resource__c>();
        for(sked__Resource__c res : resList){
            Boolean flag = true;
            if(res.sked__Availabilities1__r.isEmpty() && res.sked__Job_Allocations__r.isEmpty() && res.sked__Activities__r.isEmpty() && res.sked__Activity_Resources__r.isEmpty()){
                flag = true;
            }else{
                if(!res.sked__Availabilities1__r.isEmpty()){
                    for(sked__Availability__c availablity : res.sked__Availabilities1__r){
                        if(availablity.sked__Status__c  == Constants.AVAILABILITY_STATUS_APPROVED && (availablity.sked_Start_Date__c <= drive.sked_Drive_Date__c && availablity.sked_Finish_Date__c >= drive.sked_Drive_Date__c) && availablity.sked__Resource__c == res.Id ){
                            flag = false;
                        } 
                    }
                }
                if(!res.sked__Job_Allocations__r.isEmpty()){
                    for(sked__Job_Allocation__c joballoc : res.sked__Job_Allocations__r){
                        if(joballoc.sked__Status__c  != Constants.ALLOCATION_STATUS_DELETED && (joballoc.sked_Start_Date__c <= drive.sked_Drive_Date__c && joballoc.sked_Set_End_Date__c >= drive.sked_Drive_Date__c) && joballoc.sked__Resource__c == res.Id ){
                            flag = false;
                        } 
                    }
                }
                if(!res.sked__Activities__r.isEmpty()){
                    for(sked__Activity__c activity : res.sked__Activities__r){
                        if((activity.sked_Start_Date__c <= drive.sked_Drive_Date__c && activity.sked_End_Date__c >= drive.sked_Drive_Date__c) && activity.sked__Resource__c == res.Id ){
                            flag = false;
                        } 
                    }
                }
                if(!res.sked__Activity_Resources__r.isEmpty()){
                    for(sked__Activity_Resource__c activityres : res.sked__Activity_Resources__r){
                        if((activityres.sked__Activity__r.sked_Start_Date__c  <= drive.sked_Drive_Date__c && activityres.sked__Activity__r.sked_End_Date__c  >= drive.sked_Drive_Date__c) && activityres.sked__Resource__c == res.Id ){
                            flag = false;
                        } 
                    }
                }
            }
            if(flag){
                reourceListToReturn.add(res);
            }
        }
        
        return reourceListToReturn;
    }
    
    //8.Check Tags
    @testVisible  private void filterTags(List<sked__Resource__c> resList, sked_Drive__c drive){
        List<sked__Resource__c> reourceListToReturn = new List<sked__Resource__c>();
        List<sked__Job_Tag__c> jobTagList = new  List<sked__Job_Tag__c>();
        Map<Id,List<sked__Job_Tag__c>> jobVsJobTagMap = new Map<Id,List<sked__Job_Tag__c>>();
        Set<Id> tagIds = new  Set<Id>();
        List<sked__Resource_Tag__c> resourecTagList = new  List<sked__Resource_Tag__c>();
        Map<Id,Set<Id>> jobVsResourceIds = new Map<Id,Set<Id>>();
        if(resList != null && !resList.isEmpty()){
            for(sked__Resource__c res : resList){              
                if(res.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE){ // HRP-10212 start
                    if((!operationalLimit.isEmpty()) && res.sked_DOT__c == True && ( remainingNoOfDOT == null || remainingNoOfDOT > 0 )){
                        vehicleTypeResourceForDOT.add(res);
                    } else if((!operationalLimit.isEmpty()) && res.sked_CDL__c == True && ( remainingNoOfCDL == null || remainingNoOfCDL > 0)){
                        vehicleTypeResourceForCDL.add(res);
                    } else {
                        vehicleTypeResourceForRegVechicle.add(res);
                    }
                    resourceIdVsCapacity.put(res.Id, res.sked_Pres_Donor_Capacity__c); // HRP-10212 end
                }else if(res.sked_Asset_Type__c == Constants.JOB_TYPE_EQUIPMENT){
                    equipmentTypeResource.add(res);
                }
                resourceVsResourceTagMap.put(res.Id,res.sked__ResourceTags__r);
            }
        }
        system.debug('vehicleTypeResourceForCDL :: '+vehicleTypeResourceForCDL);
        system.debug('vehicleTypeResourceForDOT :: '+vehicleTypeResourceForDOT);
        system.debug('vehicleTypeResourceForRegVechicle :: '+vehicleTypeResourceForRegVechicle);
        system.debug('resourceVsResourceTagMap :: '+resourceVsResourceTagMap);
        if(drive.sked_Jobs__r != null && !drive.sked_Jobs__r.isEmpty()){
            jobTagList = [SELECT sked__Tag__c,sked__Tag__r.sked__Type__c, sked__Job__c FROM sked__Job_Tag__c WHERE sked__Job__c IN: drive.sked_Jobs__r AND (sked__Job__r.sked_Asset_Type__c =: Constants.JOB_TYPE_VEHICLE OR sked__Job__r.sked_Asset_Type__c =: Constants.JOB_TYPE_EQUIPMENT)];
            for(sked__Job_Tag__c jt : jobTagList){
                if(jobVsJobTagMap.containsKey(jt.sked__Job__c)){
                    jobVsJobTagMap.get(jt.sked__Job__c).add(jt);
                }else{
                    jobVsJobTagMap.put(jt.sked__Job__c, new List<sked__Job_Tag__c>{jt});
                }
            }
        }
        if(vehicleTypeResourceForCDL != NULL){ // HRP-10212 start
            vehicleTypeResource.addAll(vehicleTypeResourceForCDL);
        }
        if(vehicleTypeResourceForDOT != NULL){
            vehicleTypeResource.addAll(vehicleTypeResourceForDOT);
        }
        vehicleTypeResource.addAll(vehicleTypeResourceForRegVechicle); // HRP-10212 end
        system.debug('vehicleTypeResource.size:: '+vehicleTypeResource.size());
        JobAllocations alloctn = new JobAllocations();
        alloctn.equipmentAllocations = selectionForEquipment(drive, equipmentTypeJob, equipmentTypeResource, resourceVsResourceTagMap, jobVsJobTagMap);
        alloctn.vehicleAllocations = selectionForVehicles(drive, vehicleTypeJob, vehicleTypeResource, resourceVsResourceTagMap, jobVsJobTagMap, resourceIdVsCapacity);
        allocateResourceToJob(alloctn, drive);
    }
    
    //Job Allocation
    private  void allocateResourceToJob(JobAllocations jobAllocations, sked_Drive__c drive){
        system.debug('jobAllocations:: '+jobAllocations);
        Integer va = jobAllocations.vehicleAllocations.keySet().size();
        system.debug('va:: '+va);
        Integer ea = 0;
        ea = jobAllocations.equipmentAllocations.keySet().size();
        List<sked__Job_Allocation__c> jobAlocList = new  List<sked__Job_Allocation__c>();
        Map<Id,sked__Job__c> IdVsJobMap = new Map<Id,sked__Job__c>(drive.sked_Jobs__r);
        if(jobAllocations != null && (ea > 0 || (ea == 0 && equipmentTypeJob.size() == 0))){
            for(Id jobId : jobAllocations.equipmentAllocations.keySet()){
                if(IdVsJobMap.get(jobId).sked__Quantity__c == jobAllocations.equipmentAllocations.get(jobId).size()){
                    for(Id resId : jobAllocations.equipmentAllocations.get(jobId)){
                        sked__Job_Allocation__c jobAloc = new sked__Job_Allocation__c();
                        jobAloc.sked__Job__c = jobId;
                        jobAloc.sked__Resource__c = resId; 
                        jobAlocList.add(jobAloc);
                        processedResource.add(resId);
                    }
                }            
            }
        }
        if(jobAllocations != null && va > 0){
            for(Id jobId : jobAllocations.vehicleAllocations.keySet()){
                for(Id resId : jobAllocations.vehicleAllocations.get(jobId)){
                    sked__Job_Allocation__c jobAloc = new sked__Job_Allocation__c();
                    jobAloc.sked__Job__c = jobId;
                    jobAloc.sked__Resource__c = resId;
                    jobAlocList.add(jobAloc);
                    processedResource.add(resId);
                }
          }
        }
        List<sked__Job__c> combinedJobList = new List<sked__Job__c>();
        List<sked_Drive_Shift__c> driveshifts = getDriveShifts(drive.Id);
        if(!jobAlocList.isEmpty() && (va > 0 || (va == 0 && vehicleTypeJob.size() == 0)) && (ea > 0 || (ea == 0 && equipmentTypeJob.size() == 0))){
            drive.sked_Status__c = drive.sked_Type_of_Drive__c == Constants.FIX_SITE_OPP ? (drive.sked_Opportunity__r.Source__c == Constants.SOURCE_CALENDAR_BUILD ? Constants.DRIVE_STATUS_CONFIRMED : Constants.DRIVE_STATUS_TENTATIVE) : Constants.DRIVE_STATUS_SYSTEM_GENERATED; //HRP-10009
            Boolean recalculationFlag = false;
            if (!jobAllocations.vehicleAllocations.isEmpty() && drive.sked_Type_of_Drive__c != Constants.FIX_SITE_OPP) {
                Decimal driveProductivity = 0;
                reCalTotalNoOfStaffRequired = 0;
                for(sked_Drive_Shift__c shift : driveshifts){
                    driveStaffingComplementModel staffingComplement = new driveStaffingComplementModel();
                    for(sked__Job__c job : shift.sked_Jobs__r){ // HRP-11001 start
                        if ( (job.sked_Asset_Type__c != null) && (job.sked_Asset_Type__c == Constants.JOB_TYPE_VEHICLE && job.sked__Quantity__c != va) ){
                            recalculationFlag = true;
                        }
                    }
                    if(recalculationFlag){
                        List<sked__Job__c> jobList = reCalculateStaffingComplement(noOfVehicles, drive, shift, shift.sked_Jobs__r, staffingComplement, driveshifts.size());
                        combinedJobList.addAll(jobList);
                        driveProductivity += calculateDriveProductivityPlanned(shift, drive, jobList);
                    } else{
                        system.debug('Drive recalculationFlag is false');
                    }
                }
                if(recalculationFlag){
                    system.debug('Productivity is update');
                    drive.sked_Drive_Productivity_Planned__c =   driveProductivity > 0 ? drive.sked_Total_Products_Projected__c / (driveProductivity / 60) : 0;
                }
                system.debug('No of remaining staffs :: '+remainingStaff);
                system.debug('No of staffs required :: '+reCalTotalNoOfStaffRequired);
                if (remainingStaff >= reCalTotalNoOfStaffRequired) { // HRP-11001 start
                    if(recalculationFlag){
                        update combinedJobList;
                        List<sked_Drive_Shift__c> driveshiftsAfter = getDriveShifts(drive.Id); //HRP-11207 start
                        List<sked_Drive_Shift__c> driveshiftsToBeUpdate = new List<sked_Drive_Shift__c>();
                        for(sked_Drive_Shift__c driveShiftSingle : driveshiftsAfter){
                            decimal staffSetupAfter = 0;
                            decimal staffSetupBefore = driveShiftSingle.sked_Staff_Setup__c;
                            system.debug('staffSetupBefore :: '+staffSetupBefore);
                            for (sked__Job__c job : driveShiftSingle.sked_Jobs__r){
                                if (!string.isBlank(job.sked_Resource_Role__c)){
                                    staffSetupAfter += job.sked__Quantity__c;
                                }
                            }
                            system.debug('staffSetupAfter :: '+staffSetupAfter);
                            if(staffSetupAfter != staffSetupBefore){
                                driveShiftSingle.sked_Staff_Setup__c = staffSetupAfter;
                                driveshiftsToBeUpdate.add(driveShiftSingle);
                            }
                        }
                        if(driveshiftsToBeUpdate != null){
                            update driveshiftsToBeUpdate;
                        } //HRP-11207 end
                    }
                }
            }
            system.debug('No of remaining staffs :: '+remainingStaff);
            system.debug('No of staffs required :: '+reCalTotalNoOfStaffRequired);
            if (remainingStaff >= reCalTotalNoOfStaffRequired) {
                insert jobAlocList;
           	    update drive;
                processedDrive.add(drive.Id);
            } else if (drive.sked_Type_of_Drive__c == Constants.FIX_SITE_OPP) {
                drive.sked_Status__c = drive.sked_Opportunity__r.Source__c != Constants.SOURCE_CALENDAR_BUILD ? Constants.DRIVE_STATUS_TENTATIVE : Constants.DRIVE_STATUS_CONFIRMED;
                update drive;
                processedDrive.add(drive.Id);
            } // HRP-11001 end
           	
        }//HRP-10009 Start 
        else if (drive.sked_Type_of_Drive__c == Constants.FIX_SITE_OPP) {
            drive.sked_Status__c = drive.sked_Opportunity__r.Source__c != Constants.SOURCE_CALENDAR_BUILD ? Constants.DRIVE_STATUS_TENTATIVE : Constants.DRIVE_STATUS_CONFIRMED;
            update drive;
            processedDrive.add(drive.Id);
        }//HRP-10009 End
    }
    
    //Job Allocation for Equipments
    private static Map<Id,Set<Id>> selectionForEquipment(sked_Drive__c drive,  List<sked__Job__c> equipmentTypeJob, List<sked__Resource__c> equipmentTypeResource, Map<Id,List<sked__Resource_Tag__c>> resourceVsResourceTagMap, Map<Id,List<sked__Job_Tag__c>> jobVsJobTagMap){
        Set<Id> assignedResourceId = new  Set<Id>();
        Map<Id,Set<Id>> jobVsResourceIds = new Map<Id,Set<Id>>();
        if(!equipmentTypeJob.isEmpty()){
            for(sked__Job__c vJob : equipmentTypeJob){
                for (Integer i=0 ; i<vJob.sked__Quantity__c; i++) {
                    for(sked__Resource__c vRes : equipmentTypeResource){
                        if (jobVsResourceIds.containsKey(vJob.Id) && jobVsResourceIds.get(vJob.Id).size() == vJob.sked__Quantity__c) {
                            break;
                        }else if(!resourceVsResourceTagMap.get(vRes.Id).isEmpty() && jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id) ){
                            Integer count = 0;
                            for(sked__Resource_Tag__c resTag : resourceVsResourceTagMap.get(vRes.Id)){
                                if(resTag.sked_Start_Date__c  <= drive.sked_Drive_Date__c && (resTag.sked_Expiry_Date__c == null || (resTag.sked_Expiry_Date__c != null && drive.sked_Drive_Date__c <= resTag.sked_Expiry_Date__c))){
                                    for(sked__Job_Tag__c jobTag : jobVsJobTagMap.get(vJob.Id)){
                                        if(jobTag.sked__Tag__c == resTag.sked__Tag__c){
                                            count++;
                                        }
                                    }
                                }
                            }
                            if(count >= jobVsJobTagMap.get(vJob.Id).size()){
                                if (!jobVsResourceIds.containsKey(vJob.Id)) {
                                    jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                                }
                                jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                                assignedResourceId.add(vRes.Id);
                            }
                        }else if( !jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id) ){
                            if (!jobVsResourceIds.containsKey(vJob.Id)) {
                                jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                            }
                            jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                            assignedResourceId.add(vRes.Id);
                        }
                    }
                }
                
            }
        }
        return jobVsResourceIds;
    }
    
    //Job Allocation for Vehicles
    private Map<Id,Set<Id>> selectionForVehicles(sked_Drive__c drive,  List<sked__Job__c> vehicleTypeJob, List<sked__Resource__c> vehicleTypeResource, Map<Id,List<sked__Resource_Tag__c>> resourceVsResourceTagMap, Map<Id,List<sked__Job_Tag__c>> jobVsJobTagMap, Map<Id,Decimal> resourceIdVsCapacity){
        Map<Id,Set<Id>> jobVsResourceIds = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> jobVsResourceAllocations = new Map<Id,Set<Id>>();
        Set<Id> assignedResourceId = new  Set<Id>();
        for(sked__Job__c vJob : vehicleTypeJob){ // HRP-10212 start
        if(!vehicleTypeResourceForCDL.isEmpty()){
            for(sked__Resource__c vRes : vehicleTypeResourceForCDL){
                if(!resourceVsResourceTagMap.get(vRes.Id).isEmpty() && jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id) ){
                    Integer count = 0;
                    for(sked__Resource_Tag__c resTag : resourceVsResourceTagMap.get(vRes.Id)){
                        if(resTag.sked_Start_Date__c  <= drive.sked_Drive_Date__c && (resTag.sked_Expiry_Date__c == null || (resTag.sked_Expiry_Date__c != null || drive.sked_Drive_Date__c <= resTag.sked_Expiry_Date__c))){
                            for(sked__Job_Tag__c jobTag : jobVsJobTagMap.get(vJob.Id)){
                                if(jobTag.sked__Tag__c == resTag.sked__Tag__c){
                                    count++;
                                }
                            }
                        }  
                    } 
                    if(count == jobVsJobTagMap.get(vJob.Id).size()){
                        if (!jobVsResourceIds.containsKey(vJob.Id)) {
                            jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                        }
                        jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                        assignedResourceId.add(vRes.Id);
                        resourceIdVsResourceDetails.put(vRes.Id, vRes);
                    }
                }else if(!resourceVsResourceTagMap.get(vRes.Id).isEmpty() && !jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id)){
                    if (!jobVsResourceIds.containsKey(vJob.Id)) {
                        jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                    }
                    jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                    assignedResourceId.add(vRes.Id);
                    resourceIdVsResourceDetails.put(vRes.Id, vRes);
                }
            }
        }
        if(!vehicleTypeResourceForDOT.isEmpty()){
            for(sked__Resource__c vRes : vehicleTypeResourceForDOT){
                if(!resourceVsResourceTagMap.get(vRes.Id).isEmpty() && jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id) ){
                    Integer count = 0;
                    for(sked__Resource_Tag__c resTag : resourceVsResourceTagMap.get(vRes.Id)){
                        if(resTag.sked_Start_Date__c  <= drive.sked_Drive_Date__c && (resTag.sked_Expiry_Date__c == null || (resTag.sked_Expiry_Date__c != null || drive.sked_Drive_Date__c <= resTag.sked_Expiry_Date__c))){
                            for(sked__Job_Tag__c jobTag : jobVsJobTagMap.get(vJob.Id)){
                                if(jobTag.sked__Tag__c == resTag.sked__Tag__c){
                                    count++;
                                }
                            }
                        }  
                    } 
                    if(count == jobVsJobTagMap.get(vJob.Id).size()){
                        if (!jobVsResourceIds.containsKey(vJob.Id)) {
                            jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                        }
                        jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                        assignedResourceId.add(vRes.Id);
                        resourceIdVsResourceDetails.put(vRes.Id, vRes);
                    }
                }else if(!resourceVsResourceTagMap.get(vRes.Id).isEmpty() && !jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id)){
                    if (!jobVsResourceIds.containsKey(vJob.Id)) {
                        jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                    }
                    jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                    assignedResourceId.add(vRes.Id);
                    resourceIdVsResourceDetails.put(vRes.Id, vRes);
                }
            }
        }
            system.debug('vehicleTypeResourceForRegVechicle::'+vehicleTypeResourceForRegVechicle);
            for(sked__Resource__c vRes : vehicleTypeResourceForRegVechicle){ // HRP-10212 end
                if(!resourceVsResourceTagMap.get(vRes.Id).isEmpty() && jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id) ){
                    Integer count = 0;
                    for(sked__Resource_Tag__c resTag : resourceVsResourceTagMap.get(vRes.Id)){
                        if(resTag.sked_Start_Date__c  <= drive.sked_Drive_Date__c && (resTag.sked_Expiry_Date__c == null || (resTag.sked_Expiry_Date__c != null || drive.sked_Drive_Date__c <= resTag.sked_Expiry_Date__c))){
                            for(sked__Job_Tag__c jobTag : jobVsJobTagMap.get(vJob.Id)){
                                if(jobTag.sked__Tag__c == resTag.sked__Tag__c){
                                    count++;
                                }
                            }
                        }  
                    }
                    if(count == jobVsJobTagMap.get(vJob.Id).size()){
                        if (!jobVsResourceIds.containsKey(vJob.Id)) {
                            
                            jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                        }
                        jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                        assignedResourceId.add(vRes.Id);
                        resourceIdVsResourceDetails.put(vRes.Id, vRes); // HRP-10212
                    }
                }else if(!resourceVsResourceTagMap.get(vRes.Id).isEmpty() && !jobVsJobTagMap.containskey(vJob.Id) && !assignedResourceId.contains(vRes.Id)){
                    if (!jobVsResourceIds.containsKey(vJob.Id)) {
                        
                        jobVsResourceIds.put(vJob.Id, new Set<Id>{vRes.Id});
                    }
                    jobVsResourceIds.get(vJob.Id).add(vRes.Id);
                    assignedResourceId.add(vRes.Id);
                    resourceIdVsResourceDetails.put(vRes.Id, vRes); // HRP-10212
                }
            }
        }
        system.debug('jobVsResourceIds::'+jobVsResourceIds);
        system.debug('jobVsResourceIds.size()::'+jobVsResourceIds.size());
        Integer maxNoOfVehicles = 0;
        for (Id jobId : jobVsResourceIds.keySet()) {
            Decimal pdC = 0;
            Set<Id> resourceIds = new Set<Id>();
            for (Id resId : jobVsResourceIds.get(jobId)) { // HRP-10212 and HRP-10213 start
                if(operationalLimit.isEmpty()){
                    pdC += resourceIdVsCapacity.get(resId);
                    resourceIds.add(resId);
                }else if(resourceIdVsResourceDetails.containsKey(resId) && resourceIdVsResourceDetails.get(resId).sked_DOT__c == True && (remainingNoOfDOT == null || remainingNoOfDOT > 0)){
                    remainingNoOfDOT = remainingNoOfDOT != null ? remainingNoOfDOT - 1 : null;
                    pdC += resourceIdVsCapacity.get(resId);
                    resourceIds.add(resId);
                } else if(resourceIdVsResourceDetails.containsKey(resId) && resourceIdVsResourceDetails.get(resId).sked_CDL__c == True && (remainingNoOfCDL == null || remainingNoOfCDL > 0)){
                    remainingNoOfCDL = remainingNoOfCDL != null ? remainingNoOfCDL - 1 : null;
                    pdC += resourceIdVsCapacity.get(resId);
                    resourceIds.add(resId);
                }else if((vehicleTypeResourceForCDL.isEmpty() || remainingNoOfCDL < = 0) && (vehicleTypeResourceForDOT.isEmpty() || remainingNoOfDOT <= 0) && resourceIdVsResourceDetails.containsKey(resId) && resourceIdVsResourceDetails.get(resId).sked_DOT__c != True && resourceIdVsResourceDetails.get(resId).sked_CDL__c != True){
                    pdC += resourceIdVsCapacity.get(resId);
                    resourceIds.add(resId);
                }
                // HRP-10212 and HRP-10213 end
                if (pdC >= drive.sked_Projected_Registered_Donors__c) {
                    break;
                }
            }
            if(pdC >= drive.sked_Projected_Registered_Donors__c){
                jobVsResourceAllocations.put(jobId, resourceIds);
                maxNoOfVehicles = resourceIds.size() > maxNoOfVehicles ? resourceIds.size() : maxNoOfVehicles;
            }
        }
        noOfVehicles = maxNoOfVehicles;
        return jobVsResourceAllocations;
    }
    
    //Recalculate Staffing Complement
    @testVisible  private static List<sked__Job__c> reCalculateStaffingComplement(Integer noOfVehicles, sked_Drive__c drive, sked_Drive_Shift__c driveShift, List<sked__Job__c> jobsToReCalculate, driveStaffingComplementModel staffingComplement, Integer noOfShifts){
        List<sked__Job__c> jobsToUpdate = new List<sked__Job__c>();
        sked__Job__c vpHHJob = new sked__Job__c();
        sked__Job__c chargeJob = new sked__Job__c();
        // HRP-11001 start
        Datetime drawStartTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_Start_Time__c);
        Datetime drawStart = skedDateTimeUtils.toTimezone(drawStartTime, drive.sked_Timezone__c);
        Datetime drawEndTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_End_Time__c);
        Datetime drawEnd = skedDateTimeUtils.toTimezone(drawEndTime, drive.sked_Timezone__c);
        Decimal drawDuration = skedDateTimeUtils.getDifferentMinutes(drawStart, drawEnd);
        Decimal drawHoursActual = drawDuration / 60;
        Decimal drawHours = drawHoursActual;
        List<sked_Lunch_Break_Setting__c> lunchBreakSettings = fetchLunchBreakSettings();
            sked_Lunch_Break_Setting__c lunchBreakSetting = new sked_Lunch_Break_Setting__c();
            decimal coMaxLunchBreakDuration = drive.sked_Maximum_Lunch_Break_Duration__c != NULL ? Decimal.valueOf(drive.sked_Maximum_Lunch_Break_Duration__c) : 30;
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
        Decimal numberOf2rbcEquipments = calculate2rbcEquipmentQuantityForDriveShift(driveShift,drawHours);
        // HRP-11001 end
        if (!jobsToReCalculate.isEmpty()) {
            staffingComplement.numberOfVehicles = noOfVehicles;
            staffingComplement = calculateDriverQuantity (drive.sked_Type_of_Drive__c, staffingComplement);
            staffingComplement = calculateDriverSupportQuantity (drive.sked_Type_of_Drive__c, staffingComplement);
            for (sked__Job__c job : jobsToReCalculate) {
                if (job.sked__Type__c == Constants.JOB_TYPE_DRIVER) {
                    if(noOfVehicles > 0){
                        job.sked__Quantity__c = staffingComplement.numberOfDrivers;
                        reCalTotalNoOfStaffRequired += job.sked__Quantity__c; // HRP-11001
                        jobsToUpdate.add(job);
                    }
                }else if (job.sked__Type__c == Constants.JOB_TYPE_DRIVER_SUPPORT) {
                    if(noOfVehicles > 0){
                        job.sked__Quantity__c = staffingComplement.numberOfDriverSupports;
                        reCalTotalNoOfStaffRequired += job.sked__Quantity__c; // HRP-11001
                        jobsToUpdate.add(job);
                    }
                }else if (job.sked__Type__c == Constants.JOB_TYPE_EQUIPMENT) { // HRP-11001 start
                    numberOf2rbcEquipments = job.sked__Quantity__c;
                }else if (job.sked__Type__c == 'Drive Lead' || job.sked__Type__c == 'Team Supervisor') {
                    staffingComplement.numberOfTeamSupervisors = job.sked__Quantity__c;
                    reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
                }else if(job.sked__Type__c == Constants.PROCEDURE_TYPE_2RBC){	
                    reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
                }else{
                    if(job.sked_Asset_Type__c != Constants.JOB_TYPE_VEHICLE && job.sked_Asset_Type__c != Constants.JOB_TYPE_EQUIPMENT && job.sked__Type__c != Constants.JOB_TYPE_VP_HH && job.sked__Type__c != Constants.JOB_TYPE_CHARGE){
                        reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
                    }
                }
            }
            staffingComplement.numberOf2rbcEquipments = numberOf2rbcEquipments;
            staffingComplement.numberOf2rbc = Math.ceil(staffingComplement.numberOf2rbcEquipments / 2);
            
            staffingComplement = calculateVpHhQuantity (driveShift, drive, staffingComplement, lunchBreakSetting, noOfShifts);
            staffingComplement = calculateChargeQuantity (driveShift, drive, staffingComplement, lunchBreakSetting, noOfShifts);

            for (sked__Job__c job : jobsToReCalculate) {
                if (job.sked__Type__c == Constants.JOB_TYPE_VP_HH) {
                    job.sked__Quantity__c = staffingComplement.numberOfVphh+job.sked_APT_Quantity__c;
                    job.sked_VPHH_Quantity__c = staffingComplement.numberOfVphh;
                    reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
                    jobsToUpdate.add(job);
                }else if (job.sked__Type__c == Constants.JOB_TYPE_CHARGE) {
                    job.sked__Quantity__c = staffingComplement.numberOfCharge;
                    reCalTotalNoOfStaffRequired += job.sked__Quantity__c;
                    jobsToUpdate.add(job);
                }
            } // HRP-11001 end
        }
        return jobsToUpdate;
    }

    private static driveStaffingComplementModel calculateDriverQuantity(String typeOfDrive, driveStaffingComplementModel staffingComplement) {
        staffingComplement.numberOfDrivers = typeOfDrive == Constants.FIX_SITE_OPP ? 0 : staffingComplement.numberOfVehicles;
        return staffingComplement;
    }

    private static driveStaffingComplementModel calculateDriverSupportQuantity(String typeOfDrive, driveStaffingComplementModel staffingComplement) {
        staffingComplement.numberOfDriverSupports = 0;
        staffingComplement.numberOfDriverSupports = typeOfDrive == Constants.FIX_SITE_OPP ? 0 : staffingComplement.numberOfVehicles;
        return staffingComplement;
    }

    static List<sked_Lunch_Break_Setting__c> fetchLunchBreakSettings() {
        return [SELECT Id, Name, sked_Maximum_Lunch_Break_Duration__c,
                (SELECT Id, Name, sked_Lunch_Break_Duration__c,
                 sked_Lunch_Break_Setting__c, sked_Max_Number_of_Staff__c,
                 sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
                 FROM sked_Lunch_Break_Definitions__r)
                FROM sked_Lunch_Break_Setting__c];
    }

    //calculateVpHhQuantity
    private static driveStaffingComplementModel calculateVpHhQuantity(sked_Drive_Shift__c driveShift, sked_Drive__c drive, driveStaffingComplementModel staffingComplement, sked_Lunch_Break_Setting__c lunchBreakSetting, Integer noOfShifts){
        staffingComplement.numberOfVphh = 0;
        Datetime drawStartTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_Start_Time__c);
        Datetime drawStart = skedDateTimeUtils.toTimezone(drawStartTime, drive.sked_Timezone__c);
        Datetime drawEndTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_End_Time__c);
        Datetime drawEnd = skedDateTimeUtils.toTimezone(drawEndTime, drive.sked_Timezone__c);
        Decimal drawDuration = skedDateTimeUtils.getDifferentMinutes(drawStart, drawEnd);
        Decimal drawHoursActual = drawDuration / 60;
        Decimal drawHours = drawHoursActual; // HRP-11001 start
        system.debug('drawHoursActual:: '+drawHoursActual);
        sked_Staffing_Decision_Matrix__c matrix =  staffingDecisionMatrix(drive.sked_Collection_Operation__c, drive);

        if(driveShift.sked_Lunch_Break__c && (!drive.sked_Collection_Operation__r.sked_Lunch_Break_Before_Draw_Hours__c)){
            Decimal driveshiftDrawhr = (drawHoursActual * 60) -  decimal.valueOf(lunchBreakSetting.sked_Maximum_Lunch_Break_Duration__c);
            Decimal drawHourswithLunchBreak = driveshiftDrawhr.divide(60, 2, System.RoundingMode.UP);
            drawHours = drawHourswithLunchBreak != null ? drawHourswithLunchBreak : drawHoursActual;
        }

        Decimal noOf2RBCAssets = staffingComplement.numberOf2rbcEquipments;
        Decimal noOfResourcesHaveEnough2RBCAssets = Math.min(staffingComplement.numberOf2rbc, Math.floor(noOf2RBCAssets / 2));
        Decimal noOfResourcesNotHaveEnough2RBCAssets = Math.max(staffingComplement.numberOf2rbc - noOfResourcesHaveEnough2RBCAssets, 0);
        Decimal capacity1 = noOfResourcesHaveEnough2RBCAssets * 2 * drawHours;
        Decimal capacity2 = noOfResourcesNotHaveEnough2RBCAssets * matrix.sked_2RBC_Staff_Capacity__c * drawHours; //HRP-11207
        decimal donorProcessingCapacityWithoutVpHhCharge = 0;
        donorProcessingCapacityWithoutVpHhCharge += staffingComplement.numberOfDrivers * drawHours * matrix.sked_Driver_Capacity__c; //HRP-11207
        donorProcessingCapacityWithoutVpHhCharge += staffingComplement.numberOfDriverSupports * drawHours * matrix.sked_Driver_Support_Capacity__c; //HRP-11207
        donorProcessingCapacityWithoutVpHhCharge += (capacity1 + capacity2);
        // HRP-11001 end
        Decimal divDec = drive.sked_Projected_Registered_Donors__c.divide(noOfShifts, 2, System.RoundingMode.UP);  
        if (divDec > donorProcessingCapacityWithoutVpHhCharge) {
            staffingComplement.numberOfVphh = Math.ceil((divDec - donorProcessingCapacityWithoutVpHhCharge) / (matrix.sked_VP_HH_Capacity__c * drawHours));
        }
        return staffingComplement;
    }
    // HRP-11001 start
    private static Decimal calculate2rbcEquipmentQuantityForDriveShift(sked_Drive_Shift__c driveShift, Decimal drawHours) {
        Decimal numberOf2rbcEquipments = 0;
            if (drawHours > 1)
            {
            	Decimal noOf2RBCAssests = Math.ceil( (Decimal)driveShift.sked_2RBC_Projected_Procedures__c / (drawHours));
                if(noOf2RBCAssests < 1)
                {
                    noOf2RBCAssests = 1;
                }
            	return numberOf2rbcEquipments = noOf2RBCAssests;
            }
            return numberOf2rbcEquipments;
    } // HRP-11001 end

    private static Decimal calculate2rbcEquipmentQuantity(sked_Drive__c drive, Decimal drawHours) {
        Decimal numberOf2rbcEquipments = 0;        
        if (drawHours > 1) {
            numberOf2rbcEquipments = Math.ceil( ((Decimal)drive.sked_2RBC_Projected_Procedures__c / (drawHours))/2);     
        }
        return numberOf2rbcEquipments;
    }
    
    //calculate productivity
    @testVisible private static Decimal calculateDriveProductivityPlanned( sked_Drive_Shift__c driveShift , sked_Drive__c drive, List<sked__Job__c> jobsToReCalculate) {
        decimal sum = 0;        
        
        for (sked__Job__c job : jobsToReCalculate) {
            Datetime drawStart1 = DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_Start_Time__c);
            Datetime drawStart2 = skedDateTimeUtils.toTimezone(drawStart1, drive.sked_Timezone__c);
            Datetime drawEnd1 = DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, driveShift.sked_End_Time__c);
            Datetime drawEnd2 = skedDateTimeUtils.toTimezone(drawEnd1, drive.sked_Timezone__c);
            Decimal drawDuration = skedDateTimeUtils.getDifferentMinutes(drawStart2, drawEnd2);
            if (!string.isBlank(job.sked_Resource_Role__c)) {
                decimal leadTime = job.sked_Lead_Time__c != NULL ? job.sked_Lead_Time__c : 0;
                decimal setupTime = job.sked_Setup_Time__c != NULL ? job.sked_Setup_Time__c : 0;
                decimal breakdownTime = job.sked_Breakdown_Time__c != NULL ? job.sked_Breakdown_Time__c : 0;
                decimal wrapUpTime = job.sked_Wrap_up_Time__c != NULL ? job.sked_Wrap_up_Time__c : 0;
                decimal travelTime = job.sked_Travel_Time__c != NULL ? job.sked_Travel_Time__c : 0;
                decimal travelTime2 = job.sked_Travel_Time2__c != NULL ? job.sked_Travel_Time2__c : 0;
                sum += job.sked__Quantity__c * (drawDuration + travelTime + leadTime + setupTime + breakdownTime + wrapUpTime + travelTime2);
            }   
        }
        
        return  sum ;
    }
    
    //calculateChargeQuantity
    @testVisible  private static driveStaffingComplementModel calculateChargeQuantity(sked_Drive_Shift__c driveShift, sked_Drive__c drive, driveStaffingComplementModel staffingComplement, sked_Lunch_Break_Setting__c lunchBreakSetting, Integer noOfShifts){
        staffingComplement.numberOfCharge = 0;
        Datetime drawStartTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_Start_Time__c);
        Datetime drawStart = skedDateTimeUtils.toTimezone(drawStartTime, drive.sked_Timezone__c);
        Datetime drawEndTime = DateTime.newInstanceGMT(drive.sked_Drive_Date__c, driveShift.sked_End_Time__c);
        Datetime drawEnd = skedDateTimeUtils.toTimezone(drawEndTime, drive.sked_Timezone__c);
        Decimal drawDuration = skedDateTimeUtils.getDifferentMinutes(drawStart, drawEnd);
        Decimal drawHoursActual = drawDuration / 60;
        Decimal drawHours = drawHoursActual; // HRP-11001 start

        sked_Staffing_Decision_Matrix__c matrix =  staffingDecisionMatrix(drive.sked_Collection_Operation__c, drive);

        decimal totalQtyWithoutCharge = staffingComplement.numberOfDrivers 
                + staffingComplement.numberOfDriverSupports
                + staffingComplement.numberOf2rbc
                + staffingComplement.numberOfVphh; 
        
        decimal noOfLeaders = Math.ceil(totalQtyWithoutCharge / 11);
        staffingComplement.numberOfTeamSupervisors = staffingComplement.numberOfTeamSupervisors == null ? 0 : staffingComplement.numberOfTeamSupervisors ;
        staffingComplement.numberOfCharge = noOfLeaders - staffingComplement.numberOfTeamSupervisors;
        if (staffingComplement.numberOfCharge > 0) { //HRP-11207 start
            if(driveShift.sked_Lunch_Break__c && (!drive.sked_Collection_Operation__r.sked_Lunch_Break_Before_Draw_Hours__c)){
                Decimal driveshiftDrawhr = (drawHoursActual * 60) - decimal.valueOf(lunchBreakSetting.sked_Maximum_Lunch_Break_Duration__c);
                Decimal drawHourswithLunchBreak = driveshiftDrawhr.divide(60, 2, System.RoundingMode.UP);
                drawHours = drawHourswithLunchBreak != null ? drawHourswithLunchBreak : drawHoursActual;
            } 
            decimal donorProcessingCapacityWithoutVpHh = 0;
            donorProcessingCapacityWithoutVpHh += staffingComplement.numberOfDrivers * drawHours * matrix.sked_Driver_Capacity__c;
            donorProcessingCapacityWithoutVpHh += staffingComplement.numberOfDriverSupports * drawHours * matrix.sked_Driver_Support_Capacity__c;
            donorProcessingCapacityWithoutVpHh += staffingComplement.numberOf2rbc * drawHours * matrix.sked_2RBC_Staff_Capacity__c;
            donorProcessingCapacityWithoutVpHh += staffingComplement.numberOfCharge * drawHours * matrix.sked_Charge_Capacity__c; //HRP-11207 end

            // HRP-11001 end
            Decimal divDec = drive.sked_Projected_Registered_Donors__c.divide(noOfShifts, 2, System.RoundingMode.UP);  
            if (divDec > donorProcessingCapacityWithoutVpHh) {
                staffingComplement.numberOfVphh = Math.ceil((divDec - donorProcessingCapacityWithoutVpHh) / (matrix.sked_VP_HH_Capacity__c * drawHours));
            } else{ //HRP-10358
                staffingComplement.numberOfVphh = 0;
            }
        }
        
        return staffingComplement;
    }
    
    //getDriveShifts for the Drive
    private static List<sked_Drive_Shift__c> getDriveShifts(Id driveId) {
        return [Select Id, sked_Lunch_Break__c, sked_2RBC_Projected_Procedures__c, sked_Start_Time__c,sked_Drive_Date__c, sked_End_Time__c,sked_Timezone__c, sked_Staff_Setup__c, (SELECT Id,sked_Equipment_Subtype__c,sked_APT_Quantity__c,sked__Type__c,sked_Travel_Time2__c,sked_Travel_Time__c,sked_Lead_Time__c,sked_Wrap_up_Time__c,sked_Setup_Time__c,sked_Breakdown_Time__c,sked__Quantity__c,sked_Resource_Role__c,sked_Asset_Type__c FROM sked_Jobs__r) From sked_Drive_Shift__c Where sked_Drive__c =: driveId];
    }
    
    //getstaffingDecisionMatrix for the Drive
    @testVisible private static sked_Staffing_Decision_Matrix__c staffingDecisionMatrix(Id collectionOperationId, sked_Drive__c drive) {
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
                sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, 
                sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
                sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c,
                RecordType.Name
                FROM sked_Staffing_Decision_Matrix__c
                WHERE Id IN :staffingDecisionMatrixIds AND RecordType.Name =: drive.sked_Type_of_Drive__c];
    }
    
    public class JobAllocations{
        Map<Id, Set<Id>> vehicleAllocations;
        Map<Id, Set<Id>> equipmentAllocations;
    }

    public class driveStaffingComplementModel {
        public boolean success;
        public string opportunityId;
        
        //Mobile
        public decimal numberOfVehicles;
        public decimal numberOf2rbcEquipments;
        public decimal numberOfDrivers;
        public decimal numberOfDriverSupports;
        public decimal numberOf2rbc;
        public decimal numberOfTeamSupervisors;
        public decimal numberOfVphh;
        public decimal numberOfApt;
        public decimal numberOfCharge;
        public decimal numberOfVolunteerDonorAmbassadors;
        
        //Fixed Site
        public decimal numberOf2rbcAssets;
        public decimal numberOfPlasmaAssets;
        public decimal numberOfPlateletAssets;
        public Map<string, procedureTypeStaffingModel> mapProcedureStaffing;
        public decimal numberOfWholeBloodResources;
        public decimal numberOf2rbcResources;
        public decimal numberOfApheresisCharge;
    }

    public class procedureTypeStaffingModel {
        public string resourceRole;
        public string procedureType;
        public decimal noOfStaff;
        public decimal donorsPerHoursCapacity;
    }
}