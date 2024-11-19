global class skedDriveProductivityOneTimeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    Set<Id> driveIds;
    global skedDriveProductivityOneTimeBatch(Set<Id> driveIds) { 
    	this.driveIds = driveIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Type_of_Drive__c, sked_Account__c, sked_Travel_Time_Included__c,
            sked_Opportunity__r.OwnerId, sked_Drive_Owner__c, sked_Operation_Type__c,
            sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, 
            sked_Collection_Operation__c,
            sked_Collection_Operation__r.sked_Lunch_Break_Duration_Fixed_Site__c, 
            sked_Collection_Operation__r.sked_Lunch_Break_Duration_Mobile__c, 
            sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c, 
            sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c,
            sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c,
            sked_Maximum_Lunch_Break_Duration__c,
            sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Plasma_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c, 
            sked_Total_Procedures_Projected__c, sked_Total_Products_Projected__c,
            sked_Drive_Productivity_Planned__c, sked_Total_Equipment_Requested__c, sked_Staff_Capacity__c,
            (SELECT Id, sked_Resource_Role__c, sked__Quantity__c, sked__Duration__c,
                sked_Lead_Time__c, sked_Setup_Time__c, sked_Travel_Time__c, 
                sked_Breakdown_Time__c, sked_Wrap_Up_Time__c, sked_Travel_Time2__c,
                sked_VPHH_Quantity__c, sked_Manually_Created_From__c,
                sked_Drive_Shift__c,
                sked_Drive_Shift__r.sked_Lunch_Break__c,
                sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c
            FROM sked_Jobs__r
            WHERE sked__Job_Status__c != 'Cancelled')
            FROM sked_Drive__c
            WHERE Id IN :this.driveIds
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        Map<Id, sked_Drive__c> updatedDrivesMap = new Map<Id, sked_Drive__c>();
        try {
            updatedDrivesMap.putAll(populateDriveProductivity(records));
            updatedDrivesMap.putAll(populateStaffCapacity(records));
        }
        catch (exception ex) {
            insert new sked__Debug_Log__c(
                sked__Message__c = ex.getStackTraceString(),
                sked__Summary__c = ex.getMessage(),
                sked__Type__c = 'Debug Log'
            );
        }

        skedHubBase.setBypassAllTriggers(true);
        update updatedDrivesMap.values();
        skedHubBase.setBypassAllTriggers(false);
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    /*********************************************************** Privated Methods ***********************************************************/
    private Map<Id, sked_Drive__c> populateDriveProductivity(List<sked_Drive__c> skedDrives) {
        Map<Id, sked_Drive__c> updatedDrives = new Map<Id, sked_Drive__c>();
        for (sked_Drive__c skedDrive : skedDrives) {
            decimal sum = 0;
            if (skedDrive.sked_Jobs__r != NULL && !skedDrive.sked_Jobs__r.isEmpty()) {
                for (sked__Job__c skedJob : skedDrive.sked_Jobs__r) {
                    if (skedJob.sked_Resource_Role__c != null && skedJob.sked_Manually_Created_From__c != 'Staffing Modal') {
                        decimal lunchBreak = 0;
                        decimal maximumLunchBreakDuration = skedDrive.sked_Maximum_Lunch_Break_Duration__c != NULL 
                                ? decimal.valueOf(skedDrive.sked_Maximum_Lunch_Break_Duration__c) : 30;
    
                        if (skedJob.sked_Drive_Shift__r.sked_Lunch_Break__c && !skedJob.sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c) {
                            lunchBreak = maximumLunchBreakDuration;
                        }
    
                        Decimal quantity = skedJob.sked__Quantity__c != NULL ? skedJob.sked__Quantity__c : 0;
                        sum += quantity * (skedJob.sked__Duration__c - lunchBreak);
                    }
                }
            }
            Decimal newDriveProductivity = sum > 0 ? skedDrive.sked_Total_Products_Projected__c / (sum / 60) : 0;
            newDriveProductivity = newDriveProductivity.setScale(2, RoundingMode.HALF_UP);

            if (skedDrive.sked_Drive_Productivity_Planned__c != newDriveProductivity) {
                skedDrive.sked_Drive_Productivity_Planned__c = newDriveProductivity;
                updatedDrives.put(skedDrive.Id, skedDrive);
            }
        }

        return updatedDrives;
    }
    
    private Map<Id, sked_Drive__c> populateStaffCapacity(List<sked_Drive__c> skedDrives) {
        Map<Id, sked_Drive__c> updatedDrives = new Map<Id, sked_Drive__c>();
        Date earliestDriveDate;
        Date latestDriveDate;
        
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Collection_Operation__c != NULL) {
            	collectionOperationIds.add(skedDrive.sked_Collection_Operation__c);
            }
            
            if (earliestDriveDate == NULL || skedDrive.sked_Drive_Date__c < earliestDriveDate) {
                earliestDriveDate = skedDrive.sked_Drive_Date__c;
            }
            if (latestDriveDate == NULL || skedDrive.sked_Drive_Date__c > latestDriveDate) {
                latestDriveDate = skedDrive.sked_Drive_Date__c;
            }
        }
        
        List<sked_Collection_Operation_SDM__c> collectionOperationSDMs = fetchCollectionOperationSDMs(collectionOperationIds, earliestDriveDate, latestDriveDate);
        List<sked_Staffing_Decision_Matrix__c> staffingDecisionMatrices = fetchStaffingDecisionMatrices(collectionOperationSDMs);
        
        Map<Id, sked_Staffing_Decision_Matrix__c> mapStaffingDecisionMatrix = new Map<Id, sked_Staffing_Decision_Matrix__c>();
        for (sked_Staffing_Decision_Matrix__c staffingDecisionMatrix : staffingDecisionMatrices) {
            if (staffingDecisionMatrix.RecordType.Name == 'Mobile') {
                mapStaffingDecisionMatrix.put(staffingDecisionMatrix.Id, staffingDecisionMatrix);
            }
        }
        
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Type_of_Drive__c == 'Mobile') {
                sked_Collection_Operation_SDM__c collectionOperationSDM;
                for (sked_Collection_Operation_SDM__c item : collectionOperationSDMs) {
                    if (item.sked_Collection_Operation__c == skedDrive.sked_Collection_Operation__c && item.sked_Staffing_Decision_Matrix__r.RecordType.Name == 'Mobile') {
                        if (item.sked_Effective_Start_Date__c <= skedDrive.sked_Drive_Date__c && skedDrive.sked_Drive_Date__c <= item.sked_Effective_End_Date__c) {
                            collectionOperationSDM = item;
                            break;
                        }
                    }
                }
                
                if (collectionOperationSDM != NULL) {
                    sked_Staffing_Decision_Matrix__c matrix = mapStaffingDecisionMatrix.get(collectionOperationSDM.sked_Staffing_Decision_Matrix__c);
                    if (matrix != NULL) {
                        Map<string, decimal> donorCapacityMap = new Map<string, decimal>();
                        donorCapacityMap.put('Driver', matrix.sked_Driver_Capacity__c != NULL ? matrix.sked_Driver_Capacity__c : 0);
                        donorCapacityMap.put('Driver Support', matrix.sked_Driver_Support_Capacity__c != NULL ? matrix.sked_Driver_Support_Capacity__c : 0);
                        donorCapacityMap.put('2RBC', matrix.sked_2RBC_Staff_Capacity__c != NULL ? matrix.sked_2RBC_Staff_Capacity__c : 0);
                        donorCapacityMap.put('VP/HH', matrix.sked_VP_HH_Capacity__c != NULL ? matrix.sked_VP_HH_Capacity__c : 0);
                        donorCapacityMap.put('Charge', matrix.sked_Charge_Capacity__c != NULL ? matrix.sked_Charge_Capacity__c : 0);
                        
                        decimal newStaffCapacity = 0;
                        decimal maximumLunchBreakDuration = skedDrive.sked_Maximum_Lunch_Break_Duration__c != NULL 
                            ? decimal.valueOf(skedDrive.sked_Maximum_Lunch_Break_Duration__c) : 30;
                        
                        Map<Id, List<sked__Job__c>> map_driveShiftId_jobs = getMapDriveShiftIdJobs(skedDrive.sked_Jobs__r);
                        for (List<sked__Job__c> skedJobs : map_driveShiftId_jobs.values()) {
                            Decimal driveShiftStaffCapacity = 0;
                            for (sked__Job__c skedJob : skedJobs) {
                                if (!string.isBlank(skedJob.sked_Resource_Role__c) && donorCapacityMap.containsKey(skedJob.sked_Resource_Role__c) && skedJob.sked_Manually_Created_From__c != 'Staffing Modal') {
                                    decimal leadTime = skedJob.sked_Lead_Time__c != NULL ? skedJob.sked_Lead_Time__c : 0;
                                    decimal setupTime = skedJob.sked_Setup_Time__c != NULL ? skedJob.sked_Setup_Time__c : 0;
                                    decimal breakdownTime = skedJob.sked_Breakdown_Time__c != NULL ? skedJob.sked_Breakdown_Time__c : 0;
                                    decimal wrapUpTime = skedJob.sked_Wrap_Up_Time__c != NULL ? skedJob.sked_Wrap_Up_Time__c : 0;
                                    decimal travelTime = skedJob.sked_Travel_Time__c != NULL ? skedJob.sked_Travel_Time__c : 0;
                                    decimal travelTime2 = skedJob.sked_Travel_Time2__c != NULL ? skedJob.sked_Travel_Time2__c : 0;
                                    decimal drawDuration = skedJob.sked__Duration__c - (leadTime + setupTime + breakdownTime + wrapUpTime + travelTime + travelTime2);
                                    decimal drawDurationWithouLunchBreak = drawDuration;
                                    if (skedJob.sked_Drive_Shift__r.sked_Lunch_Break__c == TRUE && skedJob.sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c == FALSE) {
                                        drawDuration = drawDuration - maximumLunchBreakDuration;
                                    }
                                    decimal drawHours = drawDuration / 60;
                                    decimal drawHoursWithoutLunchBreak = drawDurationWithouLunchBreak / 60;
                                    
                                    decimal resourceDonorCapacity = donorCapacityMap.get(skedJob.sked_Resource_Role__c);
                                    if (skedJob.sked_Resource_Role__c == '2RBC') {
                                        decimal noOf2RBCAssets = skedDrive.sked_Total_Equipment_Requested__c != NULL ? skedDrive.sked_Total_Equipment_Requested__c : 0;
                                        decimal noOfResources = skedJob.sked__Quantity__c != NULL ? skedJob.sked__Quantity__c : 0;
                                        decimal noOfResourcesHaveEnough2RBCAssets = Math.min(noOfResources, Math.floor(noOf2RBCAssets / 2));
                                        decimal noOfResourcesNotHaveEnough2RBCAssets = Math.max(noOfResources - noOfResourcesHaveEnough2RBCAssets, 0);
                                        decimal capacity1 = noOfResourcesHaveEnough2RBCAssets * 2 * drawHoursWithoutLunchBreak;
                                        decimal capacity2 = noOfResourcesNotHaveEnough2RBCAssets * resourceDonorCapacity * drawHoursWithoutLunchBreak;
                                        driveShiftStaffCapacity += capacity1 + capacity2;
                                    }
                                    else if (skedJob.sked_Resource_Role__c == 'VP/HH') {
                                        decimal vphhQuantity = skedJob.sked_VPHH_Quantity__c != NULL ? skedJob.sked_VPHH_Quantity__c : 0;
                                        driveShiftStaffCapacity += resourceDonorCapacity * vphhQuantity * drawHours;
                                    }
                                    else {
                                        decimal quantity = skedJob.sked__Quantity__c != NULL ? skedJob.sked__Quantity__c : 0;
                                        driveShiftStaffCapacity += resourceDonorCapacity * quantity * drawHours;
                                    }
                                }
                            }
                            newStaffCapacity += Math.floor(driveShiftStaffCapacity);
                        }

                        if (skedDrive.sked_Staff_Capacity__c != newStaffCapacity) {
                            skedDrive.sked_Staff_Capacity__c = newStaffCapacity;
                            updatedDrives.put(skedDrive.Id, skedDrive);
                        }
                    }
                }
            }
        }

        return updatedDrives;
    }
    
    private List<sked_Collection_Operation_SDM__c> fetchCollectionOperationSDMs(Set<Id> collectionOperationIds, Date startDate, Date endDate) {
        return [SELECT Id, sked_Collection_Operation__c, sked_Staffing_Decision_Matrix__c,
                sked_Staffing_Decision_Matrix__r.RecordType.Name,
                sked_Effective_End_Date__c, sked_Effective_Start_Date__c
                FROM sked_Collection_Operation_SDM__c
                WHERE sked_Collection_Operation__c IN :collectionOperationIds
                AND sked_Effective_Start_Date__c <= :endDate
                AND sked_Effective_End_Date__c >= :startDate];
    }
    
    private List<sked_Staffing_Decision_Matrix__c> fetchStaffingDecisionMatrices(List<sked_Collection_Operation_SDM__c> collectionOperationSDMs) {
        Set<Id> staffingDecisionMatrixIds = new Set<Id>();
        for (sked_Collection_Operation_SDM__c collectionOperationSdm : collectionOperationSDMs) {
            staffingDecisionMatrixIds.add(collectionOperationSdm.sked_Staffing_Decision_Matrix__c);
        }
        return [SELECT Id, sked_2RBC_Staff_Capacity__c, sked_Charge_Capacity__c, sked_Charge_Threshold__c,
                sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, 
                sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
                sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c, sked_2RBC_Hourly_Capacity__c,
                sked_WB_Hourly_Capacity__c, sked_Platelet_Round_Capacity__c, sked_Plasma_Hourly_Capacity__c,
                RecordType.Name
                FROM sked_Staffing_Decision_Matrix__c
                WHERE Id IN :staffingDecisionMatrixIds];
    }

    private Map<Id, List<sked__Job__c>> getMapDriveShiftIdJobs(List<sked__Job__c> skedJobs) {
        Map<Id, List<sked__Job__c>> map_driveShiftId_jobs = new Map<Id, List<sked__Job__c>>();
        for (sked__Job__c skedJob : skedJobs) {
            if (map_driveShiftId_jobs.containsKey(skedJob.sked_Drive_Shift__c)) {
                map_driveShiftId_jobs.get(skedJob.sked_Drive_Shift__c).add(skedJob);
            }
            else {
                map_driveShiftId_jobs.put(skedJob.sked_Drive_Shift__c, new List<sked__Job__c>{skedJob});
            }
        }
        return map_driveShiftId_jobs;
    }
}