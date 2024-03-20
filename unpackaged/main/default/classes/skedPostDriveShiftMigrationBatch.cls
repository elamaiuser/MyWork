global class skedPostDriveShiftMigrationBatch implements Database.Batchable<sked_Drive_Shift__c>, Database.AllowsCallouts, Database.Stateful {
    
    List<sked_Collection_Operation_SDM__c> collectionOperationSDMs;
    Map<Id, sked_Staffing_Decision_Matrix__c> mapStaffingDecisionMatrix;
    
    global skedPostDriveShiftMigrationBatch() { }
    
    global List<sked_Drive_Shift__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Max_Donor_Capacity__c, sked_Start__c, sked_Finish__c,
                sked_Drive__r.sked_Type_of_Drive__c, sked_Drive__r.sked_Collection_Operation__c,
                sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Start_Time__c, sked_Drive__r.sked_End_Time__c,
                sked_Drive__r.sked_Timezone__c, sked_Drive__r.sked_Drive_Site__r.sked_Physical_Location_Type__c,
                sked_Drive__r.sked_Drive_Site__r.sked__Region__c, sked_Drive__r.sked_Account_Type__c,  sked_Drive__r.sked_Industry_Code__c,
                sked_Drive__r.sked_Projected_Registered_Donors__c, sked_Drive__r.sked_Maximum_Lunch_Break_Duration__c, 
                sked_Drive__r.sked_Total_Equipment_Requested__c,
                sked_Drive_Site__c, 
                sked_Vehicles_Allocated__c, sked_Equipment_Allocated__c,
                sked_Vehicles_Needed__c, sked_Equipment__c, sked_APT_Setup__c,
                sked_Total_Procedures_Projected__c,
                sked_Lunch_Break__c, sked_Lunch_Break_Before_Draw_Hours__c,
                (SELECT Id, sked_Resource_Role__c, sked_Asset_Type__c, sked_Volunteer_Role__c,
                 sked_Lead_Time__c, sked_Setup_Time__c, sked_Travel_Time__c, 
                 sked_Breakdown_Time__c, sked_Wrap_Up_Time__c, sked_Travel_Time2__c,
                 sked_APT_Quantity__c, sked_VPHH_Quantity__c, sked__Quantity__c, 
                 sked__Start__c, sked__Finish__c, sked__Duration__c, sked__Job_Allocation_Count__c
                 FROM sked_Jobs__r
                 ORDER BY sked__Start__c ASC)
                FROM sked_Drive_Shift__c
                WHERE sked_MigrationID__c != NULL
                AND sked_Post_Migration_Processed__c = FALSE
                ORDER BY Id ASC
                LIMIT 5000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive_Shift__c> records) {
        try {
            populateData(records);
            populateStaffCapacity(records);
        }
        catch (exception ex) {
            sked__Debug_Log__c debugLog = new sked__Debug_Log__c(
                sked__Message__c = ex.getStackTraceString(),
                sked__Summary__c = ex.getMessage(),
                sked__Type__c = 'Debug Log'
            );
            insert debugLog;
        }
        
        for (sked_Drive_Shift__c record : records) {
            record.sked_Post_Migration_Processed__c = TRUE;
        }
        update records;
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked_Drive_Shift__c> remainRecordQuery = [SELECT Id
                                                       FROM sked_Drive_Shift__c
                                                       WHERE sked_MigrationID__c != NULL
                                                       AND sked_Post_Migration_Processed__c = FALSE
                                                       ORDER BY Id ASC
                                                       LIMIT 1];
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedPostDriveShiftMigrationBatch(), 200);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void populateData(List<sked_Drive_Shift__c> skedDriveShifts) {
        Date earliestDriveDate;
        Date latestDriveDate;
        Set<Id> collectionOperationIds = new Set<Id>();

        for (sked_Drive_Shift__c skedDriveShift : skedDriveShifts) {
            if (skedDriveShift.sked_Drive__r.sked_Collection_Operation__c != NULL) {
            	collectionOperationIds.add(skedDriveShift.sked_Drive__r.sked_Collection_Operation__c);
            }
            
            if (earliestDriveDate == NULL || skedDriveShift.sked_Drive__r.sked_Drive_Date__c < earliestDriveDate) {
                earliestDriveDate = skedDriveShift.sked_Drive__r.sked_Drive_Date__c;
            }
            if (latestDriveDate == NULL || skedDriveShift.sked_Drive__r.sked_Drive_Date__c > latestDriveDate) {
                latestDriveDate = skedDriveShift.sked_Drive__r.sked_Drive_Date__c;
            }

            if (skedDriveShift.sked_Jobs__r != NULL && !skedDriveShift.sked_Jobs__r.isEmpty()) {
                DateTime minJobStart = skedDriveShift.sked_Jobs__r.get(0).sked__Start__c;
                DateTime maxJobEnd = skedDriveShift.sked_Jobs__r.get(0).sked__Finish__c;   
                
                decimal vehiclesNeeded = 0;
                decimal vehiclesAllocated = 0;
                decimal equipment = 0;
                decimal equipmentAllocated = 0;
                decimal aptSetup = 0;
                
                for (sked__Job__c skedJob : skedDriveShift.sked_Jobs__r) {
                    if (minJobStart > skedJob.sked__Start__c) {
                        minJobStart = skedJob.sked__Start__c;
                    }
                    if (maxJobEnd < skedJob.sked__Finish__c) {
                        maxJobEnd = skedJob.sked__Finish__c;
                    }
                    if (skedJob.sked_Asset_Type__c == 'Vehicle') { 
                        vehiclesNeeded += skedJob.sked__Quantity__c != NULL ? skedJob.sked__Quantity__c : 0;
                        vehiclesAllocated += skedJob.sked__Job_Allocation_Count__c != NULL ? skedJob.sked__Job_Allocation_Count__c : 0;
                    }
                    if (skedJob.sked_Asset_Type__c == 'Equipment') {
                        equipment += skedJob.sked__Quantity__c != NULL ? skedJob.sked__Quantity__c : 0;
                        equipmentAllocated += skedJob.sked__Job_Allocation_Count__c != NULL ? skedJob.sked__Job_Allocation_Count__c : 0;
                    }
                    if (skedJob.sked_APT_Quantity__c != NULL) {
                        aptSetup += skedJob.sked_APT_Quantity__c;
                    }
                }
                skedDriveShift.sked_Vehicles_Needed__c = vehiclesNeeded;
                skedDriveShift.sked_Vehicles_Allocated__c = vehiclesAllocated;
                skedDriveShift.sked_Equipment__c = equipment;
                skedDriveShift.sked_Equipment_Allocated__c = equipmentAllocated;
                skedDriveShift.sked_APT_Setup__c = aptSetup;
                skedDriveShift.sked_Drive_Date__c = skedDriveShift.sked_Drive__r.sked_Drive_Date__c;
                skedDriveShift.sked_Start__c = minJobStart;
                skedDriveShift.sked_Finish__c = maxJobEnd;
            }
        }

        this.collectionOperationSDMs = fetchCollectionOperationSDMs(collectionOperationIds, earliestDriveDate, latestDriveDate);
        this.mapStaffingDecisionMatrix = fetchStaffingDecisionMatrix(this.collectionOperationSDMs);
    }
    
    private void populateStaffCapacity(List<sked_Drive_Shift__c> skedDriveShifts) {
        for (sked_Drive_Shift__c skedDriveShift : skedDriveShifts) {
            if (skedDriveShift.sked_Drive__r.sked_Type_of_Drive__c == 'Mobile') {
                sked_Collection_Operation_SDM__c collectionOperationSDM;
                for (sked_Collection_Operation_SDM__c item : this.collectionOperationSDMs) {
                    if (item.sked_Collection_Operation__c == skedDriveShift.sked_Drive__r.sked_Collection_Operation__c) {
                        if (item.sked_Effective_Start_Date__c <= skedDriveShift.sked_Drive__r.sked_Drive_Date__c && skedDriveShift.sked_Drive__r.sked_Drive_Date__c <= item.sked_Effective_End_Date__c) {
                            collectionOperationSDM = item;
                            break;
                        }
                    }
                }
                if (collectionOperationSDM != NULL) {
                    sked_Staffing_Decision_Matrix__c matrix = this.mapStaffingDecisionMatrix.get(collectionOperationSDM.sked_Staffing_Decision_Matrix__c);
                    if (matrix != NULL) {
                        Map<string, decimal> donorCapacityMap = new Map<string, decimal>();
                        donorCapacityMap.put('Driver', matrix.sked_Driver_Capacity__c != NULL ? matrix.sked_Driver_Capacity__c : 0);
                        donorCapacityMap.put('Driver Support', matrix.sked_Driver_Support_Capacity__c != NULL ? matrix.sked_Driver_Support_Capacity__c : 0);
                        donorCapacityMap.put('2RBC', matrix.sked_2RBC_Staff_Capacity__c != NULL ? matrix.sked_2RBC_Staff_Capacity__c : 0);
                        donorCapacityMap.put('VP/HH', matrix.sked_VP_HH_Capacity__c != NULL ? matrix.sked_VP_HH_Capacity__c : 0);
                        donorCapacityMap.put('Charge', matrix.sked_Charge_Capacity__c != NULL ? matrix.sked_Charge_Capacity__c : 0);
                        
                        decimal staffCapacity = 0;
                        decimal maximumLunchBreakDuration = skedDriveShift.sked_Drive__r.sked_Maximum_Lunch_Break_Duration__c != NULL 
                            ? decimal.valueOf(skedDriveShift.sked_Drive__r.sked_Maximum_Lunch_Break_Duration__c) : 30;
                        for (sked__Job__c skedJob : skedDriveShift.sked_Jobs__r) {
                            if (!string.isBlank(skedJob.sked_Resource_Role__c) && donorCapacityMap.containsKey(skedJob.sked_Resource_Role__c)) {
                                decimal leadTime = skedJob.sked_Lead_Time__c != NULL ? skedJob.sked_Lead_Time__c : 0;
                                decimal setupTime = skedJob.sked_Setup_Time__c != NULL ? skedJob.sked_Setup_Time__c : 0;
                                decimal breakdownTime = skedJob.sked_Breakdown_Time__c != NULL ? skedJob.sked_Breakdown_Time__c : 0;
                                decimal wrapUpTime = skedJob.sked_Wrap_Up_Time__c != NULL ? skedJob.sked_Wrap_Up_Time__c : 0;
                                decimal travelTime = skedJob.sked_Travel_Time__c != NULL ? skedJob.sked_Travel_Time__c : 0;
                                decimal travelTime2 = skedJob.sked_Travel_Time2__c != NULL ? skedJob.sked_Travel_Time2__c : 0;
                                
                                decimal drawDuration = skedJob.sked__Duration__c - (leadTime + setupTime + breakdownTime + wrapUpTime + travelTime + travelTime2);
                                if (skedDriveShift.sked_Lunch_Break__c == TRUE && skedDriveShift.sked_Lunch_Break_Before_Draw_Hours__c == FALSE) {
                                    drawDuration = drawDuration - maximumLunchBreakDuration;
                                }
                                decimal drawHours = drawDuration / 60;
                                
                                decimal resourceDonorCapacity = donorCapacityMap.get(skedJob.sked_Resource_Role__c);
                                if (skedJob.sked_Resource_Role__c == '2RBC') {
                                    decimal noOf2RBCAssets = skedDriveShift.sked_Drive__r.sked_Total_Equipment_Requested__c != NULL ? skedDriveShift.sked_Drive__r.sked_Total_Equipment_Requested__c : 0;
                                    decimal noOfResources = skedJob.sked__Quantity__c != NULL ? skedJob.sked__Quantity__c : 0;
                                    decimal noOfResourcesHaveEnough2RBCAssets = Math.min(noOfResources, Math.floor(noOf2RBCAssets / 2));
                                    decimal noOfResourcesNotHaveEnough2RBCAssets = Math.max(noOfResources - noOfResourcesHaveEnough2RBCAssets, 0);
                                    decimal capacity1 = noOfResourcesHaveEnough2RBCAssets * 2 * drawHours;
                                    decimal capacity2 = noOfResourcesNotHaveEnough2RBCAssets * resourceDonorCapacity * drawHours;
                                    staffCapacity += capacity1 + capacity2;
                                }
                                else if (skedJob.sked_Resource_Role__c == 'VP/HH') {
                                    decimal vphhQuantity = skedJob.sked_VPHH_Quantity__c != NULL ? skedJob.sked_VPHH_Quantity__c : 0;
                                    staffCapacity += resourceDonorCapacity * vphhQuantity * drawHours;
                                }
                                else {
                                    decimal quantity = skedJob.sked__Quantity__c != NULL ? skedJob.sked__Quantity__c : 0;
                                    staffCapacity += resourceDonorCapacity * quantity * drawHours;
                                }
                            }
                        }
                        skedDriveShift.sked_Max_Donor_Capacity__c = staffCapacity;
                    }
                }
            }
        }
    }
    
    private List<sked_Collection_Operation_SDM__c> fetchCollectionOperationSDMs(Set<Id> collectionOperationIds, Date startDate, Date endDate) {
        return [SELECT Id, sked_Collection_Operation__c, sked_Staffing_Decision_Matrix__c,
                sked_Effective_End_Date__c, sked_Effective_Start_Date__c
                FROM sked_Collection_Operation_SDM__c
                WHERE sked_Collection_Operation__c IN :collectionOperationIds
                AND sked_Effective_Start_Date__c <= :endDate
                AND sked_Effective_End_Date__c >= :startDate];
    }
    
    private Map<Id, sked_Staffing_Decision_Matrix__c> fetchStaffingDecisionMatrix(List<sked_Collection_Operation_SDM__c> collectionOperationSDMs) {
        Set<Id> staffingDecisionMatrixIds = new Set<Id>();
        for (sked_Collection_Operation_SDM__c collectionOperationSdm : collectionOperationSDMs) {
            staffingDecisionMatrixIds.add(collectionOperationSdm.sked_Staffing_Decision_Matrix__c);
        }

        return new Map<Id, sked_Staffing_Decision_Matrix__c>([
            SELECT Id, sked_2RBC_Staff_Capacity__c, sked_Charge_Capacity__c, sked_Charge_Threshold__c,
            sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, 
            sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
            sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c, sked_2RBC_Hourly_Capacity__c,
            sked_WB_Hourly_Capacity__c, sked_Platelet_Hourly_Capacity__c, sked_Plasma_Hourly_Capacity__c,
            RecordType.Name
            FROM sked_Staffing_Decision_Matrix__c
            WHERE Id IN :staffingDecisionMatrixIds
        ]);
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    
}