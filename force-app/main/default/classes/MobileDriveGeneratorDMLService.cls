/*
* Description: 1. This class is used to fetch required data to create Drives on Calender records for mobile opp or Operation Type = Non Integrated WB 
               2. It is called from DriveGeneratorService class
* */

/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 10/09/2023                 Krapy Tuli             Logic for HRP-9943, HRP-9944 & HRP-9945
 * 06/22/2023                 Priti Jana             Logic for HRP - 9901
 * 06/22/2023                 Krapy Tuli             Logic for HRP - 10169
 * 29/09/2023                 Krapy Tuli             Logic for HRP-10846
 * 10/5/2023                  Priti Jana             Logic for HRP-11027
 * 10/20/2023                 Krapy Tuli             Logic for HRP-11226
 * 11/20/2023                 Krapy Tuli             Logic for HRP-11419
 * 12/11/2023                 Priti Jana             Logic for HRP-11653
 * 12/20/2023                 Krapy Tuli             Logic for HRP-11513
 * 06/05/2024                 Priti Jana             Logic for HRP-11908
 * 06/06/2024                 Priti Jana             Logic for HRP-12011
 * 17/06/2024                 Barnojit Sharma        Logic for HRP-12738
 * 08/01/2024                 Priti Jana             Logic for HRP-10994
 * 01/15/2025				  Priti Jana			 Logic for HRP-12299
 * 01/15/2025				  Barnojit Sharma		 Logic for HRP-13864
 *****************************************************************************
*/
public with sharing class MobileDriveGeneratorDMLService {

    public static DMLData getDriveGenerationData(driveGeneratorConfig config) {
        List<Opportunity> oppportunities = fetchOpportunities(config.oppIds);
        
        Set<Date> driveDates = reduceDriveDatesFromOpportunities(oppportunities);
        DMLSchedulingBounds schedulingBounds = reduceSchedulingBoundsFromOpportunities(oppportunities);
        
        Set<Id> accountIds = reduceAccountIdsFromOpportunities(oppportunities);
        List<Account> accounts = fetchAccounts(accountIds);
        
        Set<Id> siteIds = reduceSiteIdsFromOpportunities(oppportunities);
        List<sked__Location__c> sites = fetchSites(siteIds, schedulingBounds);
        Set<Id> collectionOperationIds = reduceCollectionOperationIdsFromSites(sites);
        List<Biomed_Collection_Op_Center__c> collectionOperations = fetchCollectionOperations(collectionOperationIds);
        //HRP-10846
        List<sked_Collection_Op_Staging_Location__c> collectionOperationStagingLocations = fetchCollectionOperationStagingLocation(collectionOperationIds, schedulingBounds);

        //HRP-10846
        List<sked_Travel_Time_Index_Item__c> travelTimeIndexes = fetchTravelTimeIndexFromCOId(sites);
       
        List<sked_Lunch_Break_Setting__c> lunchBreakSettings = fetchLunchBreakSettings();
        
        List<sked_Resource_Role_Group__c> resourceRoleGroups = fetchResourceRoleGroups();
        
        List<sked_Role_Time_Detail__c> roleTimeDetails = fetchRoleTimeDetails(collectionOperationIds, schedulingBounds);
        
        List<sked_Role_Time_Variance__c> roleTimeVariances = fetchRoleTimeVariances(siteIds, schedulingBounds);
        
        List<sked__Resource__c> vehicles = fetchVehicles(collectionOperationIds);
	
        List<sked_Resource_Biomed_Collection_Op__c> secondaryCollOperation = fetchSecondaryCollectionOperations(collectionOperationIds);	
        
        List<sked__Resource_Override__c> resourceOverrides = fetchResourceOverrides(collectionOperationIds);

        List<sked_Collection_Operation_SDM__c> collectionOperationSDMs = fetchCollectionOperationSDMs(collectionOperationIds, schedulingBounds);
        
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrices = fetchStaffingDecisionMatrices(collectionOperationSDMs);
        
        return combineDriveGeneratorData(oppportunities, accounts, collectionOperations, sites, 	
                                         collectionOperationSDMs, staffingDecisionMatrices, lunchBreakSettings, 	
                                         resourceRoleGroups, roleTimeDetails, roleTimeVariances, vehicles, secondaryCollOperation, resourceOverrides, collectionOperationStagingLocations, travelTimeIndexes);
    }
    
    public static void saveDrives(List<DMLDrive> drives) {
        Set<Id> oppIds = new Set<Id>();
        for (DMLDrive drive : drives) {
            oppIds.add(drive.opportunityId);
        }
        
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>([SELECT Id, Start_Time__c, End_Time__c, Source__c,Name, Account_Manager__c
                                                                FROM Opportunity
                                                                WHERE Id IN :oppIds]);
        
        Map<string, sObject> map_tempId_sObject = new Map<string, sObject>();
        
        List<sked_Drive__c> skedDrives = new List<sked_Drive__c>();
        for (DMLDrive drive :drives) {
            Opportunity opp = mapOpp.get(drive.opportunityId);
            drive.tempId = skedUtils.getKey();
            sked_Drive__c skedDrive = (sked_Drive__c)drive.toSObject();
            skedDrive.sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT;
            if (skedDrive.sked_Type_of_Drive__c == 'Fixed Site') {
                skedDrive.sked_Status__c = opp.Source__c == 'Calendar Build' ? skedConstants.DRIVE_STATUS_CONFIRMED : skedConstants.DRIVE_STATUS_TENTATIVE;
            }
            skedDrive.sked_Drive_Owner__c = skedDrive.sked_Drive_Owner__c == null ? opp.Account_Manager__c : skedDrive.sked_Drive_Owner__c ;
            skedDrives.add(skedDrive);
            
            map_tempId_sObject.put(drive.tempId, skedDrive);
        }
        insert skedDrives;
        List<sked_Drive_Shift__c> skedDriveShifts = new List<sked_Drive_Shift__c>();
        for (DMLDrive drive :drives) {
            sked_Drive__c skedDrive = (sked_Drive__c)map_tempId_sObject.get(drive.tempId);
            drive.id = skedDrive.Id; 
            for (DMLDriveShift driveShift : drive.driveShifts) {
                driveShift.tempId = skedUtils.getKey();
                driveShift.driveId = drive.Id;
                sked_Drive_Shift__c skedDriveShift = (sked_Drive_Shift__c)driveShift.toSObject();
                skedDriveShifts.add(skedDriveShift);
                
                map_tempId_sObject.put(driveShift.tempId, skedDriveShift);
            }
        }
        insert skedDriveShifts;
        
        List<sked_Drive_Shift_Tag__c> skedDriveShiftTags = new List<sked_Drive_Shift_Tag__c>();
        for (DMLDrive drive :drives) {
            for (DMLDriveShift driveShift : drive.driveShifts) {
                sked_Drive_Shift__c skedDriveShift = (sked_Drive_Shift__c)map_tempId_sObject.get(driveShift.tempId);
                driveShift.id = skedDriveShift.Id;  
                if (driveShift.driveShiftTags != NULL && !driveShift.driveShiftTags.isEmpty()) {
                    for (DMLDriveShiftTag driveShiftTag : driveShift.driveShiftTags) {
                        driveShiftTag.tempId = skedUtils.getKey();
                        driveShiftTag.driveShiftId = driveShift.Id;
                        sked_Drive_Shift_Tag__c skedDriveShiftTag = (sked_Drive_Shift_Tag__c)driveShiftTag.toSObject();
                        skedDriveShiftTags.add(skedDriveShiftTag); 
                        map_tempId_sObject.put(driveShiftTag.tempId, skedDriveShiftTag);
                    }
                }
            }
        }
        if (skedDriveShiftTags != NULL && !skedDriveShiftTags.isEmpty()) {
            insert skedDriveShiftTags;
        }
        
        List<sked__Job__c> skedJobs = new List<sked__Job__c>();
        for (DMLDrive drive :drives) {
            for (DMLDriveShift driveShift : drive.driveShifts) {
                sked_Drive_Shift__c skedDriveShift = (sked_Drive_Shift__c)map_tempId_sObject.get(driveShift.tempId);
                driveShift.id = skedDriveShift.Id;
                for (DMLJob job : driveShift.jobs) {
                    job.tempId = skedUtils.getKey();
                    job.driveId = drive.Id;
                    job.driveShiftId = driveShift.Id;
                    sked__Job__c skedJob = (sked__Job__c)job.toSObject();
                    skedJobs.add(skedJob);
                    map_tempId_sObject.put(job.tempId, skedJob);
                }
            }
        }
        insert skedJobs;
        
        List<sked__Job_Tag__c> skedJobTags = new List<sked__Job_Tag__c>();
        for (DMLDrive drive :drives) {
            for (DMLDriveShift driveShift : drive.driveShifts) {
                for (DMLJob job : driveShift.jobs) {
                    sked__Job__c skedJob = (sked__Job__c)map_tempId_sObject.get(job.tempId);
                    job.id = skedJob.Id;  
                    if (job.jobTags != NULL && !job.jobTags.isEmpty()) {
                        for (DMLJobTag jobTag : job.jobTags) {
                            jobTag.tempId = skedUtils.getKey();
                            jobTag.jobId = skedJob.Id;
                            sked__Job_Tag__c skedJobTag = (sked__Job_Tag__c)jobTag.toSObject();
                            skedJobTags.add(skedJobTag);  
                            map_tempId_sObject.put(jobTag.tempId, skedJobTag);
                        }
                    }
                }
            }
        }
        if (skedJobTags != NULL && !skedJobTags.isEmpty()) {
            insert skedJobTags;
        }
        
        List<sked__Slot__c> skedSlots = new List<sked__Slot__c>();
        for (DMLDrive drive :drives) {
            for (DMLDriveShift driveShift : drive.driveShifts) {
                sked_Drive_Shift__c skedDriveShift = (sked_Drive_Shift__c)map_tempId_sObject.get(driveShift.tempId);
                driveShift.id = skedDriveShift.Id; 
                for (DMLSlot slot : driveShift.slots) {
                    slot.tempId = skedUtils.getKey();
                    slot.driveId = drive.Id;
                    slot.driveShiftId = driveShift.Id;
                    sked__Slot__c skedSlot = (sked__Slot__c)slot.toSObject();
                    skedSlots.add(skedSlot);
                    
                    map_tempId_sObject.put(slot.tempId, skedSlot);
                }
            }
        }
        insert skedSlots;
    }
    
    public static void updateDriveGenerationStatus(List<DMLDrive> drives) {
        if (drives != NULL && !drives.isEmpty()) {
            Set<Id> oppIds = new Set<Id>();
            for (DMLDrive drive : drives) {
                oppIds.add(drive.opportunityId);
            }
            
            Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>([SELECT Id, Calendar_Build_Status__c, Calendar_Build_Reasons_For_Unqualified__c,
                                                                    Source__c
                                                                    FROM Opportunity
                                                                    WHERE Id IN :oppIds]);
            
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            for (DMLDrive drive : drives) {
                if (mapOpp.containsKey(drive.opportunityId)) {
                    Opportunity opp = mapOpp.get(drive.opportunityId);
                    if (opp.Source__c == 'Calendar Build' && string.isBlank(opp.Calendar_Build_Status__c)) {
                        List<string> unqualifiedReasons = new List<string>();
                        if (drive.driveProductivityPlanned < 0.5) {
                            unqualifiedReasons.add('productivity < .5');
                        }
                        if (drive.totalProductsProjected < 25) {
                            unqualifiedReasons.add('products projected < 25');
                        }
                        opp.Calendar_Build_Status__c = unqualifiedReasons.isEmpty() ? skedConstants.CALENDAR_BUILD_STATUS_QUALIFIED 
                                                                                    : skedConstants.CALENDAR_BUILD_STATUS_UNQUALIFIED;
                        if (!unqualifiedReasons.isEmpty()) {
                            opp.Calendar_Build_Reasons_For_Unqualified__c = string.join(unqualifiedReasons, ';');
                            opp.Rollover_Consideration__c = BSF_Constants.ROLLOVER_CONSIDERATION_DO_NOT_ROLL; //HRP-12299
                        }
                        
                        opportunitiesToUpdate.add(opp);
                    }
                }
            }
            if (!opportunitiesToUpdate.isEmpty()) {
                update opportunitiesToUpdate;
            }
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    static DMLData combineDriveGeneratorData(
        List<Opportunity> oppportunities,
        List<Account> accounts,
        List<Biomed_Collection_Op_Center__c> collectionOperations,
        List<sked__Location__c> sites,
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMs,
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrices,
        List<sked_Lunch_Break_Setting__c> lunchBreakSettings,
        List<sked_Resource_Role_Group__c> resourceRoleGroups,
        List<sked_Role_Time_Detail__c> roleTimeDetails,
        List<sked_Role_Time_Variance__c> roleTimeVariances,
        List<sked__Resource__c> vehicles,
        List<sked_Resource_Biomed_Collection_Op__c> secondaryCollOperation,	
        List<sked__Resource_Override__c> resourceOverrides,
        List<sked_Collection_Op_Staging_Location__c> collectionOperationStagingLocations,
        List<sked_Travel_Time_Index_Item__c> travelTimeIndexes
    ) {
        DMLData data = new DMLData();
        
        data.drives = new List<DMLDrive>();
        for (Opportunity opp : oppportunities) {
            data.drives.add(new DMLDrive(opp));
        }
        
        data.mapAccount = new Map<Id, DMLAccount>();
        for (Account account : accounts) {
            data.mapAccount.put(account.Id, new DMLAccount(account));
        }
        
        data.mapCollectionOperation = new Map<Id, DMLCollectionOperation>();
        for (Biomed_Collection_Op_Center__c collectionOperation : collectionOperations) {
            data.mapCollectionOperation.put(collectionOperation.Id, new DMLCollectionOperation(collectionOperation));
        }
        
        data.mapLocation = new Map<Id, DMLLocation>();
        for (sked__Location__c site : sites) {
            data.mapLocation.put(site.Id, new DMLLocation(site));
        }
        
        data.lunchBreakSettings = new List<DMLLunchBreakSetting>();
        for (sked_Lunch_Break_Setting__c lunchBreakSetting : lunchBreakSettings) {
            data.lunchBreakSettings.add(new DMLLunchBreakSetting(lunchBreakSetting));
        }
        
        data.map_group_resourceRoles = new Map<string, DMLResourceRoleGroup>();
        data.resourceRoleGroups = new List<String>(); //HRP-11908
        data.map_resourceRole_resourceRoleGroup = new Map<String, String>(); //HRP-11908
        for (sked_Resource_Role_Group__c resourceRoleGroup : resourceRoleGroups) {
            data.map_group_resourceRoles.put(resourceRoleGroup.sked_Resource_Role_Group__c, new DMLResourceRoleGroup(resourceRoleGroup));

            //HRP-11908 --> Starts Here
            data.resourceRoleGroups.add(resourceRoleGroup.sked_Resource_Role_Group__c);
            List<String> resourceRoles = new List<String>(resourceRoleGroup.sked_Resource_Roles__c.split(';'));
            for(String resourceRole : resourceRoles) {
                data.map_resourceRole_resourceRoleGroup.put(resourceRole, resourceRoleGroup.sked_Resource_Role_Group__c);
            }
            //HRP-11908 --> Ends Here
        }
        
        data.roleTimeDetails = new List<DMLRoleTimeDetail>();
        for (sked_Role_Time_Detail__c roleTimeDetail : roleTimeDetails) {
            data.roleTimeDetails.add(new DMLRoleTimeDetail(roleTimeDetail));
        }
        
        data.roleTimeVariances = new List<DMLRoleTimeVariance>();
        for (sked_Role_Time_Variance__c roleTimeVariance : roleTimeVariances) {
            data.roleTimeVariances.add(new DMLRoleTimeVariance(roleTimeVariance));
        }
        
        data.map_coId_VehicleList = new Map<Id, DMLVehicleList>();	
        for (sked__Resource__c vehicle : vehicles) {	
            Id collectionOperationId = vehicle.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;	
            DMLVehicleList vehicleList;	
            if (data.map_coId_VehicleList.containsKey(collectionOperationId)) {	
                vehicleList = data.map_coId_VehicleList.get(collectionOperationId);	
            }	
            else {	
                vehicleList = new DMLVehicleList(collectionOperationId);	
                data.map_coId_VehicleList.put(collectionOperationId, vehicleList);	
            }	
            vehicleList.vehicles.add(new DMLVehicle(vehicle));	
        }	
        data.map_coIdSecondary_VehicleList = new Map<Id, List<sked_Resource_Biomed_Collection_Op__c>>();	
        for (sked_Resource_Biomed_Collection_Op__c secondaryCollOp : secondaryCollOperation) {	
            Id collectionOperationId = secondaryCollOp.sked_Biomed_Collection_Op_Center__c;	
            if (!data.map_coIdSecondary_VehicleList.containsKey(collectionOperationId)) {	
                data.map_coIdSecondary_VehicleList.put(collectionOperationId, new List<sked_Resource_Biomed_Collection_Op__c>());	
            }	
            data.map_coIdSecondary_VehicleList.get(collectionOperationId).add(secondaryCollOp);	
        }	
        data.map_resourceOverrides = new Map<Id, List<sked__Resource_Override__c>>();	
        for (sked__Resource_Override__c resourceOverride : resourceOverrides) {	
            Id collectionOperationId = resourceOverride.sked_Collection_Operation__c;	
            if (!data.map_resourceOverrides.containsKey(collectionOperationId)) {	
                data.map_resourceOverrides.put(collectionOperationId, new List<sked__Resource_Override__c>());	
            }	
            data.map_resourceOverrides.get(collectionOperationId).add(resourceOverride);	
        }

        Map<Id, DMLStaffingDecisionMatrix> mapStaffingDecisionMatrix = new Map<Id, DMLStaffingDecisionMatrix>();
        for (sked_Staffing_Decision_Matrix__c staffingDecisionMatrix : staffingDecisionMatrices) {
            mapStaffingDecisionMatrix.put(staffingDecisionMatrix.Id, new DMLStaffingDecisionMatrix(staffingDecisionMatrix));
        }
        
        data.collectionOperationSdms = new List<DMLCollectionOperationSdm>();
        for (sked_Collection_Operation_SDM__c skedCollectionOperationSdm : collectionOperationSDMs) {
            DMLCollectionOperationSdm collectionOperationSdm = new DMLCollectionOperationSdm(skedCollectionOperationSdm);
            collectionOperationSdm.staffingDecisionMatrix = mapStaffingDecisionMatrix.get(collectionOperationSdm.staffingDecisionMatrixId);
            data.collectionOperationSdms.add(collectionOperationSdm);
        }

        //HRP-10846 Start
        data.travelTimeIndexes = new List<TravelTimeIndex>();
        for (sked_Travel_Time_Index_Item__c travelTime : travelTimeIndexes)
        {
            if(travelTime.sked_Travel_Time_Breakdown_JSON__c != NULL)
            {

            
            data.travelTimeIndexes.add(new TravelTimeIndex(travelTime));
            }
        }
        data.mapCoIdVsStagingLocations = new Map<Id, List<sked_Collection_Op_Staging_Location__c>>();
        for (sked_Collection_Op_Staging_Location__c collectionOperationStagingLocation : collectionOperationStagingLocations) {
            if (!data.mapCoIdVsStagingLocations.containsKey(collectionOperationStagingLocation.sked_Collection_Operation__c)) {
                data.mapCoIdVsStagingLocations.put(collectionOperationStagingLocation.sked_Collection_Operation__c, new List<sked_Collection_Op_Staging_Location__c>());
            }
            data.mapCoIdVsStagingLocations.get(collectionOperationStagingLocation.sked_Collection_Operation__c).add(collectionOperationStagingLocation);
        }
        //HRP-10846 End
        
        return data;
    }
    
    // HRP - 10478 - added Call_List_Recipient_Exist__c field
    //HRP-12011 - added Slot_Generator__c field
    public static List<Opportunity> fetchOpportunities(Set<Id> oppIds) {
        return [SELECT Id, Name, AccountId, Account_Type__c, Anticipated_Registered_Donors__c,
                Drive_Date__c, Drive_Site__c,Flow_Start_Time_Field__c, Drive_Site__r.sked_Collection_Operation__c, Drive_Site__r.Operation_type__c,
                End_Time__c, Industry_Code__c, Recruited_By__c, Start_Time__c,
                Type_of_Drive__c, WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c,
                Number_of_2RBC_Assets__c, Number_of_Plasma_Assets__c, Number_of_Platelet_Assets__c, Day_of_Week__c,Call_List_Recipient_Exist__c, Slot_Generator__c, 
                APT_Required__c, APT_Quantity__c //HRP-13190 
                FROM Opportunity
                WHERE Id IN :oppIds];
    }

    // HRP - 9901 - Removed account operation type references
    public static List<Account> fetchAccounts(Set<Id> accountIds) {
        return [SELECT Id, Name, Accepts_Automation2__c, APT_Required__c,
                (SELECT Id, sked__Account__c, sked__Required__c, sked__Tag__c, sked_Minimum_Quantity__c,
                 sked__Tag__r.sked_Resource_Type__c, sked__Tag__r.Name, sked__Tag__r.sked__Type__c
                 FROM sked__Account_Tags__r),
                (SELECT Id, sked_Account__c, sked_Deferral__c, sked_Effective_End_Date__c, sked_Effective_Start_Date__c,
                 sked_Procedure_Type__c, sked_Productive_Procedure_Goal__c, sked_QNS__c
                 FROM sked_Fixed_Site_Procedure_Projections__r)
                FROM Account
                WHERE Id IN :accountIds];
    }
    
    public static List<Biomed_Collection_Op_Center__c> fetchCollectionOperations(Set<Id> collectionOperationIds) {
        return [SELECT Id, sked_Breakdown_Time_Threshold__c, sked_High_Drive_Productivity_Threshold__c,
                sked_Lunch_Break_Before_Draw_Hours__c, sked_Lunch_Break_Duration_Fixed_Site__c, sked_Lunch_Break_Duration_Mobile__c, 
                sked_Maximum_Drive_End_Time__c, sked_Maximum_Shift_Length_Threshold__c, sked_Mid_Drive_Productivity_Threshold__c, 
                sked_Minimum_Drive_Start_Time__c, sked_Setup_Time_Threshold__c, sked_Skip_Last_Appointment_For__c, sked_Unpaid_Lunch_Break_Duration__c, sked_Lunch_Break__c, 
                sked_Travel_Time_Included_Mobile__c, sked_Travel_Time_Included_Fixed_Site__c, sked_IMPACT__c, sked_IMPACT_End_Date__c, sked_IMPACT_Start_Date__c, sked_No_Travel_Time__c //HRP-11419
                FROM Biomed_Collection_Op_Center__c
                WHERE Id IN :collectionOperationIds];
    }

    //HRP-10846 Start
    static List<sked_Travel_Time_Index_Item__c> fetchTravelTimeIndexFromCOId(List<sked__Location__c> sites) {
        Set<Double> setOfLatitude = new Set<Double>();
        Set<Double> setOfLongitude = new Set<Double>();
        for (sked__Location__c site : sites)
        {
            setOfLatitude.add(site.sked__GeoLocation__latitude__s);
            setOfLongitude.add(site.sked__GeoLocation__longitude__s);
        }
        
        return [SELECT Id, sked_From__c, sked_Key__c, sked_Last_Refresh_Date__c, sked_Timezone__c,
                sked_To__c, sked_Travel_Distance__c, sked_Travel_Time_Breakdown_JSON__c
                FROM sked_Travel_Time_Index_Item__c Where (sked_From__latitude__s in:setOfLatitude AND sked_From__longitude__s in:setOfLongitude) OR (sked_To__latitude__s in:setOfLatitude AND sked_To__longitude__s in:setOfLongitude)];
    }
    
    static List<sked_Collection_Op_Staging_Location__c> fetchCollectionOperationStagingLocation(Set<Id> collectionOperationIds, DMLSchedulingBounds schedulingBounds) {
        return [SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Collection_Operation__c, sked_Staging_Location__c, sked_Staging_Location__r.sked_GeoLocation__c,
                sked_Staging_Location__r.sked_Address__c 
                FROM sked_Collection_Op_Staging_Location__c
                WHERE sked_Collection_Operation__c IN :collectionOperationIds AND sked_Start_Date__c <= :schedulingBounds.endDate
                AND sked_End_Date__c >= :schedulingBounds.startDate];
    }
    //HRP-10846 End
    
    // HRP - 9901 - Added Site Operation Type Reference
    static List<sked__Location__c> fetchSites(Set<Id> siteIds, DMLSchedulingBounds schedulingBounds) {
        return [SELECT Id, Name, sked_Collection_Operation__c, sked_Date_Site_Inspection_Completed__c, sked_Fixed_Site_Appointment_Pattern__c,
                sked_Physical_Location_Type__c, sked_Travel_Time_to_Staging_Location__c, sked_Timezone__c,
                sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c,Operation_Type__c, sked__GeoLocation__c,sked__GeoLocation__latitude__s,sked__GeoLocation__longitude__s, 
                (SELECT Id, sked_Location__c, sked_Required__c, sked_Tag__c, sked_Tag__r.Name, sked_Minimum_Quantity__c,
                 sked_Tag__r.sked_Resource_Type__c, sked_Tag__r.sked__Type__c
                 FROM sked_Location_Tags__r),
                (SELECT Id, sked_Collection_Operation__c, sked_End_Date__c, sked_Site__c, sked_Start_Date__c, sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c 
                 FROM sked_Site_Collection_Operations__r
                 WHERE sked_Start_Date__c <= :schedulingBounds.endDate
                 AND sked_End_Date__c >= :schedulingBounds.startDate)
                FROM sked__Location__c
                WHERE Id IN :siteIds];
    }
    
    static List<sked_Resource_Role_Group__c> fetchResourceRoleGroups() {
        return [SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                FROM sked_Resource_Role_Group__c];
    }
    
    static List<sked_Lunch_Break_Setting__c> fetchLunchBreakSettings() {
        return [SELECT Id, Name, sked_Maximum_Lunch_Break_Duration__c,
                (SELECT Id, Name, sked_Lunch_Break_Duration__c,
                 sked_Lunch_Break_Setting__c, sked_Max_Number_of_Staff__c,
                 sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
                 FROM sked_Lunch_Break_Definitions__r)
                FROM sked_Lunch_Break_Setting__c];
    }
    
    // HRP-11295
    static List<sked_Role_Time_Detail__c> fetchRoleTimeDetails(Set<Id> collectionOperationIds, DMLSchedulingBounds schedulingBounds) {
        return [SELECT Id, sked_Breakdown_Time__c, sked_Collection_Operation__c, sked_Drive_Type__c,
                sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Fixed_Site_Operation_Type__c,
                sked_Lead_Time__c, sked_Mobile_Type__c, sked_Resource_Role_Group__c, sked_Setup_Time__c, sked_Type__c, sked_Wrap_up_Time__c, sked_Days_of_Week__c
                FROM sked_Role_Time_Detail__c
                WHERE (sked_Collection_Operation__c = NULL OR sked_Collection_Operation__c IN :collectionOperationIds)
                AND ((sked_Drive_Type__c = :Constants.FIX_SITE_OPP AND
                     sked_Fixed_Site_Operation_Type__c =:Constants.NON_INTEGRATED_WB_OPERATION_TYPE)
                    OR (sked_Drive_Type__c = :Constants.MOBILE_SITE_OPP))
                AND (sked_Effective_Start_Date__c <= :schedulingBounds.endDate)
                AND (sked_Effective_End_Date__c >= :schedulingBounds.startDate OR sked_Effective_End_Date__c = NULL)]; //
    }
    
    static List<sked_Role_Time_Variance__c> fetchRoleTimeVariances(Set<Id> siteIds, DMLSchedulingBounds schedulingBounds) {
        return [SELECT Id, sked_Buffer_Type__c, sked_Effective_End_Date__c, sked_Effective_Start_Date__c, sked_Location__c,
                sked_Resource_Role_Group__c, sked_Variance_Applies_to__c, sked_Variation_Amount__c, sked_Variation_Type__c,
                sked_Days_Of_Week__c //added for HRP-12738
                FROM sked_Role_Time_Variance__c
                WHERE sked_Location__c IN :siteIds
                AND sked_Effective_Start_Date__c <= :schedulingBounds.endDate
                AND sked_Effective_End_Date__c >= :schedulingBounds.startDate];
    }
    
    static List<sked__Resource__c> fetchVehicles(Set<Id> collectionOperationIds) {
        return [SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, sked_Pres_Donor_Capacity__c
                FROM sked__Resource__c
                WHERE sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :collectionOperationIds
                AND sked_Asset_Type__c = 'Vehicle'
                AND sked__Is_Active__c = TRUE
                ORDER BY sked_Pres_Donor_Capacity__c DESC];
    }

    static List<sked__Resource_Override__c> fetchResourceOverrides(Set<Id> collectionOperationIds) {	
        return [SELECT Id, sked_Collection_Operation__c, sked__Resource__c, sked_Start_Date__c, sked_End_Date__c, sked__Resource__r.sked_Pres_Donor_Capacity__c 	
                FROM sked__Resource_Override__c	
                WHERE sked_Collection_Operation__c IN :collectionOperationIds	
                AND sked__Resource__r.sked_Asset_Type__c = 'Vehicle'	
                AND sked__Resource__r.sked__Is_Active__c = TRUE];	
    }	
    static List<sked_Resource_Biomed_Collection_Op__c> fetchSecondaryCollectionOperations(Set<Id> collectionOperationIds) {	
        return [SELECT Id, sked_Biomed_Collection_Op_Center__c, sked_Resource__c, sked_End_Date__c, sked_Start_Date__c, sked_Resource__r.sked_Pres_Donor_Capacity__c	
                FROM sked_Resource_Biomed_Collection_Op__c	
                WHERE sked_Biomed_Collection_Op_Center__c IN: collectionOperationIds AND sked_Resource__r.sked_Asset_Type__c = 'Vehicle'	
                AND sked_Resource__r.sked__Is_Active__c = TRUE];	
    }	

    // HRP-11027 (Added a check to fetch those records where staffing decision matrix is not null and dates are NULL means actiev for infinite time)
    static List<sked_Collection_Operation_SDM__c> fetchCollectionOperationSDMs(Set<Id> collectionOperationIds, DMLSchedulingBounds schedulingBounds) {
        return [SELECT Id, sked_Collection_Operation__c, sked_Staffing_Decision_Matrix__c,
                sked_Effective_End_Date__c, sked_Effective_Start_Date__c
                FROM sked_Collection_Operation_SDM__c
                WHERE sked_Collection_Operation__c IN :collectionOperationIds
                AND sked_Staffing_Decision_Matrix__c != NULL 
                AND (sked_Effective_Start_Date__c <= :schedulingBounds.endDate OR sked_Effective_Start_Date__c = NULL)
                AND (sked_Effective_End_Date__c >= :schedulingBounds.startDate OR sked_Effective_End_Date__c = NULL)];
    }

    static List<sked_Staffing_Decision_Matrix__c> fetchStaffingDecisionMatrices(List<sked_Collection_Operation_SDM__c> collectionOperationSDMs) {
        Set<Id> staffingDecisionMatrixIds = new Set<Id>();
        for (sked_Collection_Operation_SDM__c collectionOperationSdm : collectionOperationSDMs) {
            staffingDecisionMatrixIds.add(collectionOperationSdm.sked_Staffing_Decision_Matrix__c);
        }
        return [SELECT Id, sked_2RBC_Staff_Capacity__c, sked_Charge_Capacity__c, sked_Charge_Threshold__c,
                sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, 
                sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
                sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c, sked_2RBC_Hourly_Capacity__c,
                sked_WB_Hourly_Capacity__c, sked_Platelet_Hourly_Capacity__c, sked_Plasma_Hourly_Capacity__c,
                RecordType.Name
                FROM sked_Staffing_Decision_Matrix__c
                WHERE Id IN :staffingDecisionMatrixIds];
    }
    
    static Set<Id> reduceAccountIdsFromOpportunities(List<Opportunity> oppportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppportunities) {
            accountIds.add(opp.AccountId);
        }
        return accountIds;
    }
    
    static Set<Id> reduceCollectionOperationIdsFromSites(List<sked__Location__c> sites) {
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked__Location__c site : sites) {
            if (site.sked_Site_Collection_Operations__r != NULL && !site.sked_Site_Collection_Operations__r.isEmpty()) {
                for (sked_Site_Collection_Operation__c siteCollectionOperation : site.sked_Site_Collection_Operations__r) {
                    collectionOperationIds.add(siteCollectionOperation.sked_Collection_Operation__c);
                }
            }
        }
        return collectionOperationIds;        
    }
    
    static Set<Date> reduceDriveDatesFromOpportunities(List<Opportunity> oppportunities) {
        Set<Date> driveDates = new Set<Date>();
        for (Opportunity opp : oppportunities) {
            driveDates.add(opp.Drive_Date__c);
        }
        return driveDates;
    }
    
    static DMLSchedulingBounds reduceSchedulingBoundsFromOpportunities(List<Opportunity> oppportunities) {
        Date earliestDriveDate;
        Date latestDriveDate;
        
        for (Opportunity opp : oppportunities) {
            if (earliestDriveDate == NULL || opp.Drive_Date__c < earliestDriveDate) {
                earliestDriveDate = opp.Drive_Date__c;
            }
            
            if (latestDriveDate == NULL || opp.Drive_Date__c > latestDriveDate) {
                latestDriveDate = opp.Drive_Date__c;
            }
        }
        return new DMLSchedulingBounds(earliestDriveDate, latestDriveDate);
    }
    
    static Set<Id> reduceSiteIdsFromOpportunities(List<Opportunity> oppportunities) {
        Set<Id> siteIds = new Set<Id>();
        for (Opportunity opp : oppportunities) {
            siteIds.add(opp.Drive_Site__c);
        }
        return siteIds;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class DMLData {
        public List<DMLDrive> drives;
        public List<DMLLunchBreakSetting> lunchBreakSettings;
        public List<DMLRoleTimeDetail> roleTimeDetails;
        public List<DMLRoleTimeVariance> roleTimeVariances;
        public List<DMLCollectionOperationSdm> collectionOperationSdms;
        public Map<Id, DMLAccount> mapAccount;
        public Map<Id, DMLCollectionOperation> mapCollectionOperation;
        public Map<string, DMLResourceRoleGroup> map_group_resourceRoles;
        public Map<Id, DMLLocation> mapLocation;	
        public Map<Id, DMLVehicleList> map_coId_VehicleList;	
        public Map<Id, List<sked_Resource_Biomed_Collection_Op__c>> map_coIdSecondary_VehicleList;	
        public Map<Id, List<sked__Resource_Override__c>> map_resourceOverrides;
        public Map<Id, List<sked_Collection_Op_Staging_Location__c>> mapCoIdVsStagingLocations;
        public List<TravelTimeIndex> travelTimeIndexes;
        public List<String> resourceRoleGroups; //HRP-11908
        public Map<String, String> map_resourceRole_resourceRoleGroup; //HRP-11908
    }
    
    public virtual class DMLEntityBase {
        public string tempId;
        
        public virtual SObject toSObject() {
            return NULL;
        }
    }
    
    public class DMLAccount {
        public string id;
        public string name;
        public string acceptsAutomation2;
        public boolean aptRequired;
        //public string operationType; HRP - 9901
        public List<DMLAccountTag> accountTags;
        public List<DMLFixedSiteProcedureProjection> fixedSiteProcedureProjections;
        
        public DMLAccount(Account account) {
            this.id = account.Id;
            this.name = account.Name;
            this.acceptsAutomation2 = account.Accepts_Automation2__c;
            this.aptRequired = account.APT_Required__c;
            //this.operationType = account.Operation_Type__c != null ? account.Operation_Type__c : ''; HRP - 9901
            
            if (account.sked__Account_Tags__r != NULL && !account.sked__Account_Tags__r.isEmpty()) {
                this.accountTags = new List<DMLAccountTag>();
                for (sked__Account_Tag__c accountTag : account.sked__Account_Tags__r) {
                    this.accountTags.add(new DMLAccountTag(accountTag));
                }
            }
            
            if (account.sked_Fixed_Site_Procedure_Projections__r != NULL && !account.sked_Fixed_Site_Procedure_Projections__r.isEmpty()) {
                this.fixedSiteProcedureProjections = new List<DMLFixedSiteProcedureProjection>();
                for (sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection : account.sked_Fixed_Site_Procedure_Projections__r) {
                    this.fixedSiteProcedureProjections.add(new DMLFixedSiteProcedureProjection(fixedSiteProcedureProjection));
                }
            }
        }
    }
    
    public class DMLAccountTag {
        public string id;
        public string accountId;
        public decimal minimumQuantity;
        public boolean required;
        public string resourceType;
        public string tagId;
        public string tagType; // HRP-11513
        public string tagName; // HRP-11513
        
        public DMLAccountTag(sked__Account_Tag__c accountTag) {
            this.id = accountTag.Id;
            this.accountId = accountTag.sked__Account__c;
            this.minimumQuantity =accountTag.sked_Minimum_Quantity__c;
            this.required = accountTag.sked__Required__c;
            this.resourceType = accountTag.sked__Tag__r.sked_Resource_Type__c;
            this.tagId = accountTag.sked__Tag__c;
            this.tagType = accountTag.sked__Tag__r.sked__Type__c; // HRP-11513
            this.tagName = accountTag.sked__Tag__r.Name; // HRP-11513
        }
    }
    
    public class DMLCollectionOperation {
        public string id;
        public string name;
        public decimal breakdownTimeThreshold;
        public decimal highDriveProductivityThreshold;
        public boolean lunchBreakBeforeDrawHours;
        public decimal lunchBreakDurationFixedSite;
        public decimal lunchBreakDurationMobile;
        public Time maximumDriveEndTime;
        public decimal maximumShiftLengthThreshold;
        public decimal midDriveProductivityThreshold;
        public Time minimumDriveStartTime;
        public decimal setupTimeThreshold;
        public string skipLastAppointmentFor;
        public decimal unpaidLunchBreakDuration;
        public string travelTimeIncludedFixed;	
        public string travelTimeIncludedMobile;
        public Boolean lunchBreak; //HRP-9944
        //HRP-9945 Start
        public Boolean impact;
        public Date impactEndDate;
        public Date impactStartDate;
        //HRP-9945 End
        public Boolean noTravelTime; //HRP-11419
        
        public DMLCollectionOperation(Biomed_Collection_Op_Center__c collectionOperation) {
            this.id = collectionOperation.Id;
            this.name = collectionOperation.Id;
            this.breakdownTimeThreshold = collectionOperation.sked_Breakdown_Time_Threshold__c;
            this.highDriveProductivityThreshold = collectionOperation.sked_High_Drive_Productivity_Threshold__c;
            this.lunchBreakBeforeDrawHours = collectionOperation.sked_Lunch_Break_Before_Draw_Hours__c;
            this.lunchBreakDurationFixedSite = collectionOperation.sked_Lunch_Break_Duration_Fixed_Site__c != null
                ? decimal.valueOf(collectionOperation.sked_Lunch_Break_Duration_Fixed_Site__c) : 30;
            this.lunchBreakDurationMobile = collectionOperation.sked_Lunch_Break_Duration_Mobile__c != null
                ? decimal.valueOf(collectionOperation.sked_Lunch_Break_Duration_Mobile__c) : 30;
            this.maximumDriveEndTime = collectionOperation.sked_Maximum_Drive_End_Time__c;
            this.maximumShiftLengthThreshold = collectionOperation.sked_Maximum_Shift_Length_Threshold__c;
            this.midDriveProductivityThreshold = collectionOperation.sked_Mid_Drive_Productivity_Threshold__c;
            this.minimumDriveStartTime = collectionOperation.sked_Minimum_Drive_Start_Time__c;
            this.setupTimeThreshold = collectionOperation.sked_Setup_Time_Threshold__c;
            this.skipLastAppointmentFor = collectionOperation.sked_Skip_Last_Appointment_For__c;
            this.unpaidLunchBreakDuration = collectionOperation.sked_Unpaid_Lunch_Break_Duration__c;
            this.travelTimeIncludedFixed = collectionOperation.sked_Travel_Time_Included_Fixed_Site__c;	
            this.travelTimeIncludedMobile = collectionOperation.sked_Travel_Time_Included_Mobile__c;
            this.lunchBreak = collectionOperation.sked_Lunch_Break__c; //HRP-9944
            //HRP-9945 Start
            this.impact = collectionOperation.sked_IMPACT__c;
            this.impactEndDate = collectionOperation.sked_IMPACT_End_Date__c != null ? collectionOperation.sked_IMPACT_End_Date__c : null;
            this.impactStartDate = collectionOperation.sked_IMPACT_Start_Date__c != null ? collectionOperation.sked_IMPACT_Start_Date__c : null;
            //HRP-9945 End
            this.noTravelTime = collectionOperation.sked_No_Travel_Time__c != null ? collectionOperation.sked_No_Travel_Time__c : null; //HRP-11419
        }
    }

    public class DMLCollectionOperationSdm {
        public string id;
        public string collectionOperationId;
        public Date effectiveEndDate;
        public Date effectiveStartDate;
        public string staffingDecisionMatrixId;
        public DMLStaffingDecisionMatrix staffingDecisionMatrix;

        public DMLCollectionOperationSdm(sked_Collection_Operation_SDM__c collectionOperationSdm) {
            this.id = collectionOperationSdm.Id;
            this.collectionOperationId = collectionOperationSdm.sked_Collection_Operation__c;
            this.effectiveEndDate = collectionOperationSdm.sked_Effective_End_Date__c;
            this.effectiveStartDate = collectionOperationSdm.sked_Effective_Start_Date__c;
            this.staffingDecisionMatrixId = collectionOperationSdm.sked_Staffing_Decision_Matrix__c;
        }
    }
    
    public class DMLDrive extends DMLEntityBase {
        public string id;
        public string name;
        public string accountId;
        public string accountType;
        public string collectionOperationId;
        public string siteCollectionOperationId;
        public decimal drawDuration;
        public DateTime drawEnd;
        public decimal drawHours;
        public DateTime drawStart;
        public Date driveDate;
        public String driveDay;
        public decimal driveProductivityPlanned;
        public string driveSiteId;
        public Time endTime;
        public string industryCode;
        public string opportunityId;
        public decimal maximumLunchBreakDuration;
        public decimal numberOf2rbcAssets;
        public decimal numberOf2rbcEquipments;
        public decimal numberOfPlasmaAssets;
        public decimal numberOfPlateletAssets;
        public decimal plasmaProjectedProcedures;
        public decimal plateletProjectedProcedures;
        public decimal plateletRounds;
        public decimal projected2rbcDonors;
        public decimal projectedPlasmaDonors;
        public decimal projectedPlateletDonors;
        public decimal projectedRegisteredDonors;
        public decimal projectedWbDonors;
        public string recruitedBy;
        public decimal staffCapacity;
        public Time startTime;
        public String timezoneSidId;
        public decimal totalProceduresProjected;
        public decimal totalProductsProjected;
        public decimal totalSlots;
        public string typeOfDrive;
        public decimal wbProjectedProcedures;
        public decimal x2rbcProjectedProcedures;
        public Boolean isCallListRecipientExist;
        public Integer noOfDriveShifts;
        public String stagingLocation; // HRP-11653
        public sked_Collection_Op_Staging_Location__c coStagingLocation;
        public String travelTimeSitetoCO; //HRP-11650
        public String travelTimeCOtoSite; //HRP-11650
        public Decimal slotGenerator; //HRP-12011
        public Decimal excessStaffCapacity; //HRP-10994
        public Decimal averageStaffCapacity; //HRP-10994
        public Decimal maxRoleCapacity; //HRP-13864
        public Decimal maxRoleCapacityWithDrawHours; //HRP-13864
        public Decimal totalStaffRequested; //HRP-10994
        public Boolean aptRequired; //HRP-13190
        public Decimal aptQuantity; //HRP-13190
        
        public DMLAccount account;
        public DMLCollectionOperation collectionOperation;
        public DMLSiteCollectionOperation siteCollectionOperation;
        public DMLLocation driveSite;
        
        public List<DMLDriveShift> driveShifts;
        public Boolean hasError = false;
        public Boolean impactCO = false; //HRP-9945
        
        public DMLDrive(Opportunity opp) {
            DMLSchedulingBounds schedulingBounds = reduceSchedulingBoundsFromOpportunities(new List<Opportunity>{opp});
            this.name = opp.Name;
            this.accountId = opp.AccountId;
            this.accountType = opp.Account_Type__c;
            this.driveDate = opp.Drive_Date__c;
            this.driveDay = opp.Day_of_Week__c;
            this.driveSiteId = opp.Drive_Site__c;
            this.endTime = opp.End_Time__c;
            this.industryCode = opp.Industry_Code__c;
            this.opportunityId = opp.Id;
            this.numberOf2rbcAssets = opp.Number_of_2RBC_Assets__c != null ? opp.Number_of_2RBC_Assets__c : 0;            
            this.numberOfPlasmaAssets = opp.Number_of_Plasma_Assets__c != null ? opp.Number_of_Plasma_Assets__c : 0;
            this.numberOfPlateletAssets = opp.Number_of_Platelet_Assets__c != null ? opp.Number_of_Platelet_Assets__c : 0;
            this.projectedRegisteredDonors = opp.Anticipated_Registered_Donors__c != null ? opp.Anticipated_Registered_Donors__c : 0;
            this.recruitedBy = opp.Recruited_By__c;
            this.startTime = Time.newInstance(Integer.valueOf(opp.Flow_Start_Time_Field__c.left(2)), Integer.valueOf(opp.Flow_Start_Time_Field__c.right(2)), 0, 0);
            this.typeOfDrive = opp.Type_of_Drive__c;
            this.wbProjectedProcedures = opp.WB_Projected_Procedures__c != null ? opp.WB_Projected_Procedures__c : 0;
            this.x2rbcProjectedProcedures = opp.X2RBC_Projected_Procedures__c != null ? opp.X2RBC_Projected_Procedures__c : 0;
            this.isCallListRecipientExist = opp.Call_List_Recipient_Exist__c; // HRP - 10478
            this.slotGenerator = opp.Slot_Generator__c; //HRP-12011
            this.aptRequired = opp.APT_Required__c; //HRP-13190
            this.aptQuantity = opp.APT_Quantity__c; //HRP-13190
            this.totalProceduresProjected = this.wbProjectedProcedures + this.x2rbcProjectedProcedures;
            this.totalProductsProjected = this.wbProjectedProcedures + 2*this.x2rbcProjectedProcedures;
            this.driveSite = new DMLLocation(fetchSites(new Set<Id>{opp.Drive_Site__c}, schedulingBounds)[0]);
            this.account = new DMLAccount(fetchAccounts(new Set<Id>{opp.AccountId})[0]);
        }
        
        public override SObject toSObject() {
            String driveName = this.name.length() > 80 ? this.name.abbreviate(75) : this.name;
            sked_Drive__c skedDrive = new sked_Drive__c(
                Id = this.id,
                Name = driveName,
                sked_Account__c = this.accountId,
                sked_Collection_Operation__c = this.collectionOperationId,
                sked_Site_Collection_Operation__c = this.siteCollectionOperationId,
                sked_Drive_Date__c = this.driveDate,
                sked_Drive_Productivity_Planned__c = this.driveProductivityPlanned,
                sked_Drive_Site__c = this.driveSiteId,
                sked_End_Time__c = this.endTime,
                sked_Maximum_Lunch_Break_Duration__c = string.valueOf(this.maximumLunchBreakDuration),
                sked_Number_of_2RBC_Assets__c = this.numberOf2rbcEquipments,
                sked_Number_of_Plasma_Assets__c = this.numberOfPlasmaAssets,
                sked_Number_of_Platelet_Assets__c = this.numberOfPlateletAssets,
                sked_Opportunity__c = this.opportunityId,
                sked_Projected_Registered_Donors__c = this.projectedRegisteredDonors,
                sked_Recruited_By__c = this.recruitedBy,
                sked_Start_Time__c = this.startTime,
                sked_Staff_Capacity__c = this.staffCapacity,
                sked_Total_Procedures_Projected__c = this.totalProceduresProjected,
                sked_Total_Products_Projected__c = this.totalProductsProjected,
                sked_Total_Slots__c = this.totalSlots,
                sked_Type_of_Drive__c = this.typeOfDrive,
                sked_WB_Projected_Procedures__c = this.wbProjectedProcedures,
                sked_2RBC_Projected_Procedures__c = this.x2rbcProjectedProcedures,
                sked_Staging_Location__c = this.stagingLocation, // HRP-11653
                sked_Travel_Time_Site_To_CO__c = this.travelTimeSitetoCO,  //HRP-11650
                sked_Travel_Time_CO_To_Site__c = this.travelTimeCOtoSite,  //HRP-11650
                Excess_Staff_Capacity__c = this.excessStaffCapacity, //HRP-10994
                Average_Staff_Capacity__c = this.averageStaffCapacity, //HRP-10994
                Max_Role_Capacity__c = this.maxRoleCapacity, //HRP-13864
                Max_Role_Capacity_With_Draw_Hours__c = this.maxRoleCapacityWithDrawHours, //HRP-13864
                sked_APT_Required__c = this.aptRequired, //HRP-13190
                sked_APT_Quantity__c = this.aptQuantity //HRP-13190
            );
            return skedDrive;
        }
    }
    
    public class DMLDriveShift extends DMLEntityBase {
        public string id;
        public string name;
        public decimal default2rbcSlots;
        public decimal defaultPlasmaSlots;
        public decimal defaultPlateletSlots;
        public decimal defaultWbSlots;
        public decimal donorsScheduled;
        public Date driveDate;
        public string driveId;
        public decimal drawDuration;
        public decimal drawHours;
        public DateTime drawEnd;
        public DateTime drawStart;
        public Time endTime;
        public decimal equipment;
        public DateTime finish;
        public boolean lunchBreak;
        public boolean lunchBreakBeforeDrawHours;
        public decimal lunchBreakDuration;
        public decimal lunchBreakPerperson ;
        public Time lunchBreakEndTime;
        public Time lunchBreakStartTime;
        public decimal plateletRounds;
        public decimal rbcProcedureProjection;
        public decimal signUpReduction;
        public decimal staffSetup;
        public Time startTime;
        public DateTime start;
        public decimal vehiclesNeeded;
        public decimal volunteerSetup;
        public Decimal projectedRegisteredDonors;
        public decimal x2rbcProjectedProcedures;
        public Decimal wbProjectedProcedures;
        public Decimal totalProceduresProjected;
        public Decimal totalProductsProjected;
        public DMLDrive drive;
        public Decimal staffCapacity;
        public decimal aPTSetup;
        public decimal drawHourswithLunchBreak;
        public decimal numberOf2rbcEquipments;
        public Boolean noTravelTime; //HRP-11419
        public Decimal maxRoleCapacity; //HRP-13864
        public Decimal maxRoleCapacityWithDrawHours; //HRP-13864
        
        public List<DMLDriveShiftTag> driveShiftTags;
        public List<DMLJob> jobs;
        public List<DriveGenerationUtil.TimeConfigurationModel> timeConfigurations; //HRP-11908
        public List<DMLSlot> slots;
     
        public DMLDriveShift() {}
        
         public DMLDriveShift(sked_Drive_Shift__c driveShift) {
            List<DMLJob> jobList = new List<DMLJob>();
            this.startTime = driveShift.sked_Start_Time__c;
            this.endTime = driveShift.sked_End_Time__c;
            this.drawStart =  skedDateTimeUtils.toTimezone((DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, this.startTime)), driveShift.sked_Timezone__c);
            this.drawEnd = skedDateTimeUtils.toTimezone((DateTime.newInstanceGMT(driveShift.sked_Drive_Date__c, this.endTime)), driveShift.sked_Timezone__c);
            this.drawDuration = skedDateTimeUtils.getDifferentMinutes(this.drawStart, this.drawEnd);
            this.drawHours = this.drawDuration / 60;
            this.x2rbcProjectedProcedures = driveShift.sked_2RBC_Projected_Procedures__c;
            this.wbProjectedProcedures = driveShift.sked_WB_Projected_Procedures__c;
            this.totalProceduresProjected = driveShift.sked_Total_Procedures_Projected__c;
            this.totalProductsProjected = driveShift.sked_Total_Products_Projected__c;
            this.lunchBreak = driveShift.sked_Lunch_Break__c;
            this.lunchBreakBeforeDrawHours = driveShift.sked_Lunch_Break_Before_Draw_Hours__c;
            for(sked__Job__c job : driveShift.sked_jobs__r) {
                jobList.add(new DMLJob(job));
            }
            this.jobs = jobList;
        }
        
        public DMLDriveShift(DMLDriveShift source) {
            this.donorsScheduled = source.donorsScheduled;
            this.driveDate = source.driveDate;
            this.driveId = source.driveId;
            this.drawDuration = source.drawDuration;
            this.drawEnd = source.drawEnd;
            this.drawStart = source.drawStart;
            this.endTime = source.endTime;
            this.equipment = source.equipment;
            this.finish = source.finish;
            this.lunchBreak = source.lunchBreak;
            this.lunchBreakBeforeDrawHours = source.lunchBreakBeforeDrawHours;
            this.lunchBreakEndTime = source.lunchBreakEndTime;
            this.lunchBreakStartTime = source.lunchBreakStartTime;
            this.rbcProcedureProjection = source.rbcProcedureProjection;
            this.staffSetup = source.staffSetup;
            this.startTime = source.startTime;
            this.start = source.start;
            this.vehiclesNeeded = source.vehiclesNeeded;
            this.volunteerSetup = source.volunteerSetup;
            this.aPTSetup = source.aPTSetup;
            this.drive = source.drive;
            this.noTravelTime = source.noTravelTime; //HRP-11419
            
            if (source.jobs != NULL && !source.jobs.isEmpty()) {
                this.jobs = new List<DMLJob>();
                for (DMLJob sourceJob : source.jobs) {
                    DMLJob job = new DMLJob(sourceJob);
                    this.jobs.add(job);
                }
            }
        }
        
        public override SObject toSObject() {
            sked_Drive_Shift__c skedDriveShift = new sked_Drive_Shift__c(
                Id = this.id,
                sked_Donors_Scheduled__c = this.donorsScheduled,
                sked_Default_2RBC_Slots__c = this.default2rbcSlots,
                sked_Default_Plasma_Slots__c = this.defaultPlasmaSlots,
                sked_Default_Platelet_Slots__c = this.defaultPlateletSlots,
                sked_Default_WB_Slots__c = this.defaultWbSlots,
                sked_Drive_Date__c = this.driveDate,
                sked_Drive__c = this.driveId,
                sked_End_Time__c = this.endTime,
                sked_Equipment__c = this.equipment,
                sked_Finish__c = this.finish,
                sked_Lunch_Break__c = this.lunchBreak != NULL ? this.lunchBreak : FALSE,
                sked_Lunch_Break_Before_Draw_Hours__c = this.lunchBreakBeforeDrawHours != NULL ? this.lunchBreakBeforeDrawHours : FALSE,
                sked_Lunch_Break_Duration__c = this.lunchBreakDuration,
                sked_Lunch_Break_End_Time__c = this.lunchBreakEndTime,
                sked_Lunch_Break_Start_Time__c = this.lunchBreakStartTime,
                sked_Platelet_Rounds__c = this.plateletRounds,
                //sked_RBC_Procedure_Projection__c = this.rbcProcedureProjection,
                sked_Sign_Up_Reduction__c = this.signUpReduction,
                sked_Staff_Setup__c = this.staffSetup,
                sked_Start_Time__c = this.startTime,
                sked_Start__c = this.start,
                sked_Vehicles_Needed__c = this.vehiclesNeeded,
                sked_Volunteer_Setup__c = this.volunteerSetup,
                sked_APT_Setup__c = this.aPTSetup,
                sked_WB_Projected_Procedures__c = this.wbProjectedProcedures != null ? this.wbProjectedProcedures.setScale(2) : 0.00,	
                sked_2RBC_Projected_Procedures__c = this.x2rbcProjectedProcedures != null ? this.x2rbcProjectedProcedures.setScale(2) : 0.00,	
                sked_Total_Procedures_Projected__c = this.totalProceduresProjected != null ? this.totalProceduresProjected.setScale(2) : 0.00,	
                sked_Total_Products_Projected__c = this.totalProductsProjected != null ? this.totalProductsProjected.setScale(2) : 0.00,
                sked_Max_Donor_Capacity__c = this.staffCapacity
            );
            return skedDriveShift;
        }
    }
    
    public class DMLDriveShiftTag extends DMLEntityBase {
        public string id;
        public string driveShiftId;
        public decimal minimumQuantity;
        public string tagId;
        public string tagName; // HRP-11513
        
        public override SObject toSObject() {
            sked_Drive_Shift_Tag__c skedDriveShiftTag = new sked_Drive_Shift_Tag__c(
                sked_Drive_Shift__c = this.driveShiftId,
                sked_Minimum_Quantity__c = this.minimumQuantity,
                sked_Tag__c = this.tagId
            );
            return skedDriveShiftTag;
        }
    }
    
    public class DMLFixedSiteProcedureProjection {
        public string id;
        public string accountId;
        public decimal deferral;
        public Date effectiveEndDate;
        public Date effectiveStartDate;
        public string procedureType;
        public decimal productiveProcedureGoal;
        public decimal qns;
        public string resourceRole;
        
        public DMLFixedSiteProcedureProjection(sked_Fixed_Site_Procedure_Projection__c skedFixedSiteProcedureProjection) {
            this.id = skedFixedSiteProcedureProjection.Id;
            this.accountId = skedFixedSiteProcedureProjection.sked_Account__c;
            this.deferral = skedFixedSiteProcedureProjection.sked_Deferral__c;
            this.effectiveEndDate = skedFixedSiteProcedureProjection.sked_Effective_End_Date__c;
            this.effectiveStartDate = skedFixedSiteProcedureProjection.sked_Effective_Start_Date__c;
            this.procedureType = skedFixedSiteProcedureProjection.sked_Procedure_Type__c;
            this.productiveProcedureGoal = skedFixedSiteProcedureProjection.sked_Productive_Procedure_Goal__c;
            this.qns = skedFixedSiteProcedureProjection.sked_QNS__c;
            this.resourceRole = 'Apheresis';
        }
    }
    
    public class DMLJob extends DMLEntityBase {
        public string id;
        public string name;
        public decimal aptQuantity;
        public string assetType;
        public decimal breakdownTime;
        public string driveId;
        public string driveShiftId;
        public string driveSiteId;
        public decimal duration;
        public string equipmentSubtype;
        public DateTime finish;
        public decimal leadTime;
        public string procedureType;
        public decimal quantity;
        public decimal redcrossVolunteerQuantity;
        public string resourcerole;
        public decimal setupTime;
        public decimal sponsorVolunteerQuantity;
        public DateTime start;
        public decimal travelTime;
        public decimal travelTime2;
        public string type;
        public string volunteerRole;
        public decimal vphhQuantity;
        public decimal wrapUpTime;
        public decimal siteLogisticsBack; // HRP-11226
        public decimal siteLogisticsTo; // HRP-11226
        
        public List<DMLJobTag> jobTags;
        
        public DMLJob() {}

        public DMLJob(sked__Job__c job) {
            this.id = job.Id;
            this.resourceRole = job.sked_Resource_Role__c;
            this.aptQuantity = job.sked_APT_Quantity__c;
            this.assetType = job.sked_Asset_Type__c;
            this.breakdownTime = job.sked_Breakdown_Time__c;
            this.driveId = job.sked_Drive__c;
            this.driveShiftId = job.sked_Drive_Shift__c;
            this.driveSiteId = job.sked__Location__c;
            this.duration = job.sked__Duration__c;
            this.equipmentSubtype = job.sked_Equipment_Subtype__c;
            this.finish = job.sked__Finish__c;
            this.leadTime = job.sked_Lead_Time__c;
            this.procedureType = job.sked_Procedure_Type__c;
            this.quantity = job.sked__Quantity__c;
            this.redcrossVolunteerQuantity = job.sked_Redcross_Volunteer_Quantity__c;
            this.setupTime = job.sked_Setup_Time__c;
            this.sponsorVolunteerQuantity = job.sked_Sponsor_Volunteer_Quantity__c;
            this.start = job.sked__Start__c;
            this.travelTime = job.sked_Travel_Time__c;
            this.travelTime2 = job.sked_Travel_Time2__c;
            this.type = job.sked__Type__c;
            this.volunteerRole = job.sked_Volunteer_Role__c;
            this.vphhQuantity = job.sked_VPHH_Quantity__c;
            this.wrapUpTime = job.sked_Wrap_Up_Time__c;
            this.siteLogisticsBack = job.sked_Site_Logistics_Back__c;
            this.siteLogisticsTo = job.sked_Site_Logistics_To__c;
        }
        
        public DMLJob(DMLJob source) {
            this.aptQuantity = source.aptQuantity;
            this.assetType = source.assetType;
            this.breakdownTime = source.breakdownTime;
            this.driveId = source.driveId;
            this.driveShiftId = source.driveShiftId;
            this.driveSiteId = source.driveSiteId;
            this.duration = source.duration;
            this.equipmentSubtype = source.equipmentSubtype;
            this.finish = source.finish;
            this.leadTime = source.leadTime;
            this.procedureType = source.procedureType;
            this.quantity = source.quantity;
            this.redcrossVolunteerQuantity = source.redcrossVolunteerQuantity;
            this.resourcerole = source.resourcerole;
            this.setupTime = source.setupTime;
            this.sponsorVolunteerQuantity = source.sponsorVolunteerQuantity;
            this.start = source.start;
            this.travelTime = source.travelTime;
            this.travelTime2 = source.travelTime2;
            this.type = source.type;
            this.volunteerRole = source.volunteerRole;
            this.vphhQuantity = source.vphhQuantity;
            this.wrapUpTime = source.wrapUpTime;
            this.siteLogisticsBack = source.siteLogisticsBack; // HRP-11226
            this.siteLogisticsTo = source.siteLogisticsTo; // HRP-11226
        }
        
        public override SObject toSObject() {
            sked__Job__c skedJob = new sked__Job__c(
                Id = this.Id,
                sked_APT_Quantity__c = this.aptQuantity,
                sked_Asset_Type__c = this.assetType,
                sked_Breakdown_Time__c = this.breakdownTime,
                sked_Drive__c = this.driveId,
                sked_Drive_Shift__c = this.driveShiftId,
                sked__Duration__c = this.duration,
                sked_Equipment_Subtype__c = this.equipmentSubtype,
                sked__Finish__c = this.finish,
                sked__Job_Allocation_Time_Source__c = FALSE,
                sked_Lead_Time__c = this.leadTime,
                sked__Location__c = this.driveSiteId,
                sked_Procedure_Type__c = this.procedureType,
                sked__Quantity__c = this.quantity,
                sked_Redcross_Volunteer_Quantity__c = this.redcrossVolunteerQuantity,
                sked_Resource_Role__c = this.resourcerole,
                sked_Setup_Time__c = this.setupTime,
                sked_Sponsor_Volunteer_Quantity__c = this.sponsorVolunteerQuantity,
                sked__Start__c = this.start,
                sked_Travel_Time__c = this.travelTime,
                sked_Travel_Time2__c = this.travelTime2,
                sked__Type__c = this.type,
                sked_Volunteer_Role__c = this.volunteerRole,
                sked_VPHH_Quantity__c = this.vphhQuantity,
                sked_Wrap_Up_Time__c = this.wrapUpTime,
                sked_Site_Logistics_Back__c = this.siteLogisticsBack, // HRP-11226
                sked_Site_Logistics_To__c = this.siteLogisticsTo, // HRP-11226
                sked_Start_Date__c = system.today().addDays(7)
            );
            return skedJob;
        }
    }
    
    public class DMLJobTag extends DMLEntityBase {
        public string id;
        public string jobId;
        public string resourceType;
        public string tagId;
        public string tagType; // HRP-10169
        
        public override SObject toSObject() {
            sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
                sked__Job__c = this.jobId,
                sked__Tag__c = this.tagId
            );
            return skedJobTag;
        }
    }
    
    public class DMLLocation {
        public string id;
        public string name;
        public Location geoLocation;
        public string collectionOperationId;
        public Date dateSiteInspectionCompleted;
        public string fixedSiteAppointmentPattern;
        public string physicalLocationType;
        public Decimal travelTimeToStagingLocation;
        public String timezoneSidId;
        public string siteOperationType; // HRP - 9901
        public List<DMLLocationTag> locationTags;
        public List<DMLSiteCollectionOperation> siteCollectionOperations;
        //public List<DMLTravelTimeBreakdown> travelTimeBreakdownsCoToSite;
        //public List<DMLTravelTimeBreakdown> travelTimeBreakdownsSiteToCo;
        
        public DMLLocation(sked__Location__c site) {
            this.id = site.Id;
            this.name = site.Name;
            this.geoLocation = site.sked__GeoLocation__c;
            this.collectionOperationId = site.sked_Collection_Operation__c;
            this.dateSiteInspectionCompleted = site.sked_Date_Site_Inspection_Completed__c;
            this.fixedSiteAppointmentPattern = site.sked_Fixed_Site_Appointment_Pattern__c;
            this.physicalLocationType = site.sked_Physical_Location_Type__c;
            this.travelTimeToStagingLocation = site.sked_Travel_Time_to_Staging_Location__c;
            this.timezoneSidId = site.sked_Timezone__c;
            this.siteOperationType = site.Operation_Type__c != null ? site.Operation_Type__c : ''; // HRP - 9901
            
            if (site.sked_Location_Tags__r != NULL && !site.sked_Location_Tags__r.isEmpty()) {
                this.locationTags = new List<DMLLocationTag>();
                for (sked_Location_Tag__c locationTag : site.sked_Location_Tags__r) {
                    this.locationTags.add(new DMLLocationTag(locationTag));
                }
            }
            
            if (site.sked_Site_Collection_Operations__r != NULL && !site.sked_Site_Collection_Operations__r.isEmpty()) {
                this.siteCollectionOperations = new List<DMLSiteCollectionOperation>();
                for (sked_Site_Collection_Operation__c siteCollectionOperation : site.sked_Site_Collection_Operations__r) {
                    this.siteCollectionOperations.add(new DMLSiteCollectionOperation(siteCollectionOperation));
                }
            }
            
            /*if (!string.isBlank(site.sked_Travel_Time_Breakdown_JSON__c)) {
                this.travelTimeBreakdownsCoToSite = (List<DMLTravelTimeBreakdown>)JSON.deserialize(site.sked_Travel_Time_Breakdown_JSON__c, List<DMLTravelTimeBreakdown>.class);
            }
            if (!string.isBlank(site.sked_Travel_Time_Breakdown_JSON_2__c)) {
                this.travelTimeBreakdownsSiteToCo = (List<DMLTravelTimeBreakdown>)JSON.deserialize(site.sked_Travel_Time_Breakdown_JSON_2__c, List<DMLTravelTimeBreakdown>.class);
            }*/
        }
    }
    
    public class DMLLocationTag {
        public string id;
        public string locationId;
        public decimal minimumQuantity;
        public boolean required;
        public string resourceType;
        public string tagId;
        public string tagName; // HRP-11513
        public string tagType; // HRP-11513
        
        public DMLLocationTag(sked_Location_Tag__c locationTag) {
            this.id = locationTag.Id;
            this.locationId = locationTag.sked_Location__c;
            this.minimumQuantity = locationTag.sked_Minimum_Quantity__c;
            this.required = locationTag.sked_Required__c;
            this.resourceType = locationTag.sked_Tag__r.sked_Resource_Type__c;
            this.tagId = locationTag.sked_Tag__c;
            this.tagName = locationTag.sked_Tag__r.Name; // HRP-11513
            this.tagType = locationTag.sked_Tag__r.sked__Type__c;
        }
    }
    
    public class DMLLunchBreakSetting {
        public string id;
        public decimal maximumLunchBreakDuration;
        public List<DMLLunchBreakDefinition> lunchBreakDefinitions;
        
        public DMLLunchBreakSetting(sked_Lunch_Break_Setting__c lunchBreakSetting) {
            this.id = lunchBreakSetting.Id;
            this.maximumLunchBreakDuration = lunchBreakSetting.sked_Maximum_Lunch_Break_Duration__c != NULL
                ? decimal.valueOf(lunchBreakSetting.sked_Maximum_Lunch_Break_Duration__c) : 30;
            
            if (lunchBreakSetting.sked_Lunch_Break_Definitions__r != NULL && !lunchBreakSetting.sked_Lunch_Break_Definitions__r.isEmpty()) {
                this.lunchBreakDefinitions = new List<DMLLunchBreakDefinition>();
                for (sked_Lunch_Break_Definition__c lunchBreakDefinition : lunchBreakSetting.sked_Lunch_Break_Definitions__r) {
                    this.lunchBreakDefinitions.add(new DMLLunchBreakDefinition(lunchBreakDefinition));
                }
            }
        }
    }
    
    public class DMLLunchBreakDefinition {
        public string id;
        public decimal lunchBreakDuration;
        public decimal maxNumberOfStaff;
        public decimal minNumberOfStaff;
        public decimal slotReduction;
        
        public DMLLunchBreakDefinition(sked_Lunch_Break_Definition__c lunchBreakDefinition) {
            this.id = lunchBreakDefinition.Id;
            this.lunchBreakDuration = lunchBreakDefinition.sked_Lunch_Break_Duration__c;
            this.maxNumberOfStaff = lunchBreakDefinition.sked_Max_Number_of_Staff__c;
            this.minNumberOfStaff = lunchBreakDefinition.sked_Min_Number_of_Staff__c;
            this.slotReduction = lunchBreakDefinition.sked_Slot_Reduction__c;
        }
    }
    
    public class DMLResourceRoleGroup {
        public string id;
        public string resourceRoleGroup;
        public Set<string> resourceRoles;
        
        public DMLResourceRoleGroup(sked_Resource_Role_Group__c resourceRoleGroup) {
            this.id = resourceRoleGroup.Id;
            this.resourceRoleGroup = resourceRoleGroup.sked_Resource_Role_Group__c;
            this.resourceRoles = new Set<string>();
            if (resourceRoleGroup.sked_Resource_Roles__c != NULL) {
                this.resourceRoles.addAll(resourceRoleGroup.sked_Resource_Roles__c.split(';'));
            }
        }
    }
    
    public class DMLRoleTimeDetail {
        public string id;
        public decimal breakdownTime;
        public string collectionOperationId;
        public string driveType;
        public Date effectiveEndDate;
        public Date effectiveStartDate;
        public List<string> excludeTravelTimeForRoles;
        public string fixedSiteOperationType;
        public decimal leadTime;
        public string mobileType;
        public List<string> resourceRoleGroups;
        public decimal setupTime;
        public string type;
        public decimal wrapUpTime;
        public List<String> daysOfWeek; //HRP-9943
        public decimal siteLogisticsBack; // HRP-11226
        public decimal siteLogisticsTo; // HRP-11226
        
        public DMLRoleTimeDetail(sked_Role_Time_Detail__c roleTimeDetail) {
            this.id = roleTimeDetail.Id;
            this.breakdownTime = roleTimeDetail.sked_Breakdown_Time__c;
            this.collectionOperationId = roleTimeDetail.sked_Collection_Operation__c;
            this.driveType = roleTimeDetail.sked_Drive_Type__c;
            this.effectiveEndDate = roleTimeDetail.sked_Effective_End_Date__c;
            this.effectiveStartDate = roleTimeDetail.sked_Effective_Start_Date__c;
            this.excludeTravelTimeForRoles = new List<string>();
            /*if (!string.isBlank(roleTimeDetail.sked_Exclude_Travel_Time_for_Roles__c)) {
                this.excludeTravelTimeForRoles = roleTimeDetail.sked_Exclude_Travel_Time_for_Roles__c.split(';');
            }*/
            this.fixedSiteOperationType = roleTimeDetail.sked_Fixed_Site_Operation_Type__c;
            this.leadTime = roleTimeDetail.sked_Lead_Time__c;
            this.mobileType = roleTimeDetail.sked_Mobile_Type__c;
            this.resourceRoleGroups = new List<string>();
            if (roleTimeDetail.sked_Resource_Role_Group__c != NULL) {
                this.resourceRoleGroups = roleTimeDetail.sked_Resource_Role_Group__c.split(';');
            }
            this.setupTime = roleTimeDetail.sked_Setup_Time__c;
            this.type = roleTimeDetail.sked_Type__c;
            this.wrapUpTime = roleTimeDetail.sked_Wrap_up_Time__c;
             //HRP-9943 Start
            this.daysOfWeek = new List<String> ();
            if (roleTimeDetail.sked_Days_of_Week__c != NULL) {
                this.daysOfWeek = roleTimeDetail.sked_Days_of_Week__c.split(';');
            } //HRP-9943 End
        }
    }
    
    public class DMLRoleTimeVariance {
        public string id;
        public string bufferType;
        public Date effectiveEndDate;
        public Date effectiveStartDate;
        public List<string> resourceRoleGroups;
        public string siteId;
        public string varianceAppliesTo;
        public decimal varianceAmount;
        public string varianceType;
        public string driveType; // added by PB
        public string collectionOperationId; // added by PB
        public List<String> daysOfWeek; //added fo HRP-12738
        public DMLRoleTimeVariance(sked_Role_Time_Variance__c roleTimeVariance) {
            this.id = roleTimeVariance.Id;
            this.bufferType = roleTimeVariance.sked_Buffer_Type__c;
            this.effectiveEndDate = roleTimeVariance.sked_Effective_End_Date__c;
            this.effectiveStartDate = roleTimeVariance.sked_Effective_Start_Date__c;
            this.resourceRoleGroups = new List<string>();
            if (roleTimeVariance.sked_Resource_Role_Group__c != NULL) {
                this.resourceRoleGroups = roleTimeVariance.sked_Resource_Role_Group__c.split(';');
            }
            this.siteId = roleTimeVariance.sked_Location__c;
            this.varianceAppliesTo = roleTimeVariance.sked_Variance_Applies_to__c;
            this.varianceAmount = roleTimeVariance.sked_Variation_Amount__c;
            this.varianceType = roleTimeVariance.sked_Variation_Type__c;
            /*
            * HRP-12738 changes stats here
            */
            this.daysOfWeek = new List<String> ();
            if (String.isNotBlank(roleTimeVariance.sked_Days_Of_Week__c)) {
                this.daysOfWeek = roleTimeVariance.sked_Days_Of_Week__c.split(';');
            } 
            /*
            * HRP-12738 changes ends here
            */
        }
    }
    
    public class DMLSchedulingBounds {
        public Date startDate;
        public Date endDate;
        
        public DMLSchedulingBounds(Date s, Date e) {
            this.startDate = s;
            this.endDate = e;
        }
    }

    //HRP-10846 Start
    public class TravelTimeIndex {
        public string id;
        public string collectionOperationId;
        public Location fromGeo;
        public Location toGeo;
        public List<DMLTravelTimeBreakdown> travelTimeBreakdown;
        
        public TravelTimeIndex(sked_Travel_Time_Index_Item__c travelTimeIndex) {
            this.id = travelTimeIndex.Id;
            this.fromGeo = travelTimeIndex.sked_From__c;
            this.toGeo = travelTimeIndex.sked_To__c;
            if (!string.isBlank(travelTimeIndex.sked_Travel_Time_Breakdown_JSON__c)) {
                this.travelTimeBreakdown = (List<DMLTravelTimeBreakdown>)JSON.deserialize(travelTimeIndex.sked_Travel_Time_Breakdown_JSON__c, List<DMLTravelTimeBreakdown>.class);
            }
        }
    }
    //HRP-10846 End
    
    public class DMLSiteCollectionOperation {
        public string id;
        public string collectionOperationId;
        public Date endDate;
        public string siteId;
        public Date startDate;
        public List<DMLTravelTimeBreakdown> travelTimeBreakdownsCoToSite;
        public List<DMLTravelTimeBreakdown> travelTimeBreakdownsSiteToCo;
        
        public DMLSiteCollectionOperation(sked_Site_Collection_Operation__c siteCollectionOperation) {
            this.id = siteCollectionOperation.Id;
            this.collectionOperationId = siteCollectionOperation.sked_Collection_Operation__c;
            this.endDate = siteCollectionOperation.sked_End_Date__c;
            this.siteId = siteCollectionOperation.sked_Site__c;
            this.startDate = siteCollectionOperation.sked_Start_Date__c;
            if (!string.isBlank(siteCollectionOperation.sked_Travel_Time_Breakdown_JSON__c)) {
                this.travelTimeBreakdownsCoToSite = (List<DMLTravelTimeBreakdown>)JSON.deserialize(siteCollectionOperation.sked_Travel_Time_Breakdown_JSON__c, List<DMLTravelTimeBreakdown>.class);
            }
            if (!string.isBlank(siteCollectionOperation.sked_Travel_Time_Breakdown_JSON_2__c)) {
                this.travelTimeBreakdownsSiteToCo = (List<DMLTravelTimeBreakdown>)JSON.deserialize(siteCollectionOperation.sked_Travel_Time_Breakdown_JSON_2__c, List<DMLTravelTimeBreakdown>.class);
            }
        }
    }
    
    public class DMLSlot extends DMLEntityBase {
        public string id;
        public string name;
        public DateTime endTime;
        public string driveId;
        public string driveShiftId;
        public string label;
        public boolean locked;
        public string slotType;
        public DateTime startTime;
        public Date startDate;
        public Time startTimeOnly;
        public Date endDate;
        public Time endTimeOnly;
        public string status;
        
        public DMLSlot() {}
        
        public override SObject toSObject() {
            sked__Slot__c skedSlot = new sked__Slot__c(
                Id = this.Id,
                Name = this.name,                
                sked_Drive__c = this.driveId,
                sked_Drive_Shift__c = this.driveShiftId,
                sked_Label__c = this.label,
                sked_Locked__c = this.locked,
                sked_Type__c = this.slotType,
                sked_Start__c = this.startTime,
                sked_End__c = this.endTime,
                sked_Start_Date__c = this.startDate,
                sked_Start_Time__c = this.startTimeOnly,
                sked_End_Date__c = this.endDate,
                sked_End_Time__c = this.endTimeOnly,
                sked_Status__c = this.status
            );
            return skedSlot;
        }
    }
    
    public class DMLStaffingDecisionMatrix {
        public string id;
        public decimal chargeCapacity;
        public decimal chargeThreshold;
        public decimal driverCapacity;
        public decimal driverSupportCapacity;
        public string driveType;
        public decimal nrVolunteerFixedSiteBandLower;
        public decimal nrVolunteerFixedSiteBandUpper;
        public decimal teamSupervisorThreshold;
        public decimal vpHhCapacity;
        public decimal x2RbcStaffCapacity;
        public decimal wbHourlyCapacity;
        public decimal plateletHourlyCapacity;
        public decimal plasmaHourlyCapacity;
        public decimal x2rbcHourlyCapacity;
        
        public DMLStaffingDecisionMatrix(sked_Staffing_Decision_Matrix__c staffingDecisionMatrix) {
            this.id = staffingDecisionMatrix.Id;
            this.chargeCapacity = staffingDecisionMatrix.sked_Charge_Capacity__c;
            this.chargeThreshold = staffingDecisionMatrix.sked_Charge_Threshold__c;
            this.driverCapacity = staffingDecisionMatrix.sked_Driver_Capacity__c;
            this.driverSupportCapacity = staffingDecisionMatrix.sked_Driver_Support_Capacity__c;
            this.driveType = staffingDecisionMatrix.RecordType.Name;
            this.nrVolunteerFixedSiteBandLower = staffingDecisionMatrix.sked_NR_Volunteer_Fixed_Site_Band_Lower__c;
            this.nrVolunteerFixedSiteBandUpper = staffingDecisionMatrix.sked_NR_Volunteer_Fixed_Site_Band_Upper__c;
            this.teamSupervisorThreshold = staffingDecisionMatrix.sked_Team_Supervisor_Threshold__c;
            this.vpHhCapacity = staffingDecisionMatrix.sked_VP_HH_Capacity__c ;
            this.x2RbcStaffCapacity = staffingDecisionMatrix.sked_2RBC_Staff_Capacity__c;
            this.wbHourlyCapacity = staffingDecisionMatrix.sked_WB_Hourly_Capacity__c;
            this.plateletHourlyCapacity = staffingDecisionMatrix.sked_Platelet_Hourly_Capacity__c;
            this.plasmaHourlyCapacity = staffingDecisionMatrix.sked_Plasma_Hourly_Capacity__c;
            this.x2rbcHourlyCapacity = staffingDecisionMatrix.sked_2RBC_Hourly_Capacity__c;
        }
    }
    
    public class DMLTravelTimeBreakdown {
        public Time endOfWindow;
        public string locationId;
        public Time startOfWindow;
        public decimal travelDistance;
        public decimal travelTime;
        public string weekday;
    }
    
    public class DMLVehicle {
        public string id;
        public decimal presDonorCapacity;
        
        public DMLVehicle(sked__Resource__c vehicle) {
            this.id = vehicle.Id;
            this.presDonorCapacity = vehicle.sked_Pres_Donor_Capacity__c != null ? vehicle.sked_Pres_Donor_Capacity__c : 0;
        }
    }
    
    public class DMLVehicleList {
        public string collectionOperationId;
        public List<DMLVehicle> vehicles;
        
        public DMLVehicleList(Id collectionOperationId) {
            this.collectionOperationId = collectionOperationId;
            this.vehicles = new List<DMLVehicle>();
        }
    }
    
    public class driveGeneratorConfig {
        public Set<Id> oppIds; //Opportunities on same date
        public Date driveDate;
    }
    
    public class TimeConfiguration{
        public string resourceRoleGroup;
        public decimal travelTime;
        public decimal leadTime;
        public decimal setupTime;
        public decimal breakDownTime;
        public decimal wrapUpTime;
        public decimal travelTime2;
        public decimal siteLogisticsBack; // HRP-11226
        public decimal siteLogisticsTo; // HRP-11226
    }
}