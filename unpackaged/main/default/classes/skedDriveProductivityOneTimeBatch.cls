global class skedDriveProductivityOneTimeBatch implements Database.Batchable<sked_Drive__c>, Database.AllowsCallouts, Database.Stateful {
    Set<Id> driveIds;
    global skedDriveProductivityOneTimeBatch(Set<Id> driveIds) { 
    	this.driveIds = driveIds;
    }
    
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [
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
            sked_Drive_Productivity_Planned__c, sked_Total_Equipment_Requested__c,
            (SELECT Id, sked_Resource_Role__c, sked__Quantity__c, sked__Duration__c,
                sked_Lead_Time__c, sked_Setup_Time__c, sked_Travel_Time__c, 
                sked_Breakdown_Time__c, sked_Wrap_Up_Time__c, sked_Travel_Time2__c,
                sked_VPHH_Quantity__c,
                sked_Drive_Shift__r.sked_Lunch_Break__c,
                sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c
                FROM sked_Jobs__r)
            FROM sked_Drive__c
            WHERE Id IN :this.driveIds
        ];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        try {
            populateDriveProductivity(records);
            populateStaffCapacity(records);
            populateProcedureCapacity(records);
        }
        catch (exception ex) {
            insert new sked__Debug_Log__c(
                sked__Message__c = ex.getStackTraceString(),
                sked__Summary__c = ex.getMessage(),
                sked__Type__c = 'Debug Log'
            );
        }
        update records;
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void populateDriveProductivity(List<sked_Drive__c> skedDrives) {
        for (sked_Drive__c skedDrive : skedDrives) {
            decimal sum = 0;
            if (skedDrive.sked_Jobs__r != NULL && !skedDrive.sked_Jobs__r.isEmpty()) {
                for (sked__Job__c skedJob : skedDrive.sked_Jobs__r) {
                    if (skedJob.sked_Resource_Role__c != null) {
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
            skedDrive.sked_Drive_Productivity_Planned__c = sum > 0 ? skedDrive.sked_Total_Products_Projected__c / (sum / 60) : 0;
        }
    }
    
    private void populateStaffCapacity(List<sked_Drive__c> skedDrives) {
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
                        
                        decimal staffCapacity = 0;
                        decimal maximumLunchBreakDuration = skedDrive.sked_Maximum_Lunch_Break_Duration__c != NULL 
                            ? decimal.valueOf(skedDrive.sked_Maximum_Lunch_Break_Duration__c) : 30;
                        for (sked__Job__c skedJob : skedDrive.sked_Jobs__r) {
                            if (!string.isBlank(skedJob.sked_Resource_Role__c) && donorCapacityMap.containsKey(skedJob.sked_Resource_Role__c)) {
                                decimal leadTime = skedJob.sked_Lead_Time__c != NULL ? skedJob.sked_Lead_Time__c : 0;
                                decimal setupTime = skedJob.sked_Setup_Time__c != NULL ? skedJob.sked_Setup_Time__c : 0;
                                decimal breakdownTime = skedJob.sked_Breakdown_Time__c != NULL ? skedJob.sked_Breakdown_Time__c : 0;
                                decimal wrapUpTime = skedJob.sked_Wrap_Up_Time__c != NULL ? skedJob.sked_Wrap_Up_Time__c : 0;
                                decimal travelTime = skedJob.sked_Travel_Time__c != NULL ? skedJob.sked_Travel_Time__c : 0;
                                decimal travelTime2 = skedJob.sked_Travel_Time2__c != NULL ? skedJob.sked_Travel_Time2__c : 0;
                                decimal drawDuration = skedJob.sked__Duration__c - (leadTime + setupTime + breakdownTime + wrapUpTime + travelTime + travelTime2);
                                if (skedJob.sked_Drive_Shift__r.sked_Lunch_Break__c == TRUE && skedJob.sked_Drive_Shift__r.sked_Lunch_Break_Before_Draw_Hours__c == FALSE) {
                                    drawDuration = drawDuration - maximumLunchBreakDuration;
                                }
                                decimal drawHours = drawDuration / 60;
                                
                                decimal resourceDonorCapacity = donorCapacityMap.get(skedJob.sked_Resource_Role__c);
                                if (skedJob.sked_Resource_Role__c == '2RBC') {
                                    decimal noOf2RBCAssets = skedDrive.sked_Total_Equipment_Requested__c != NULL ? skedDrive.sked_Total_Equipment_Requested__c : 0;
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
                        skedDrive.sked_Staff_Capacity__c = staffCapacity;
                    }
                }
            }
        }
    }
    
    private void populateProcedureCapacity(List<sked_Drive__c> skedDrives) {
        Date earliestDriveDate;
        Date latestDriveDate;
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Account__c != NULL) {
                accountIds.add(skedDrive.sked_Account__c);
            }
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
            if (staffingDecisionMatrix.RecordType.Name == 'Fixed Site') {
                mapStaffingDecisionMatrix.put(staffingDecisionMatrix.Id, staffingDecisionMatrix);
            }
        }
        
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id,
                                                            (SELECT Id, sked_Effective_Start_Date__c, sked_Effective_End_Date__c,
                                                             sked_Deferral__c, sked_QNS__c, sked_Procedure_Type__c, sked_Productive_Procedure_Goal__c
                                                             FROM sked_Fixed_Site_Procedure_Projections__r)
                                                            FROM Account
                                                            WHERE Id IN :accountIds]);
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Type_of_Drive__c == 'Fixed Site' && skedDrive.sked_Operation_Type__c != 'Non Integrated WB') {
                sked_Collection_Operation_SDM__c collectionOperationSDM;
                for (sked_Collection_Operation_SDM__c item : collectionOperationSDMs) {
                    if (item.sked_Collection_Operation__c == skedDrive.sked_Collection_Operation__c && item.sked_Staffing_Decision_Matrix__r.RecordType.Name == 'Fixed Site') {
                        if (item.sked_Effective_Start_Date__c <= skedDrive.sked_Drive_Date__c && skedDrive.sked_Drive_Date__c <= item.sked_Effective_End_Date__c) {
                            collectionOperationSDM = item;
                            break;
                        }
                    }
                }
                sked_Staffing_Decision_Matrix__c matrix;
                if (collectionOperationSDM != NULL) {
                    matrix = mapStaffingDecisionMatrix.get(collectionOperationSDM.sked_Staffing_Decision_Matrix__c);
                }
                
                Account acc = mapAccount.get(skedDrive.sked_Account__c);
                boolean isValidDrive = matrix != NULL && acc != NULL && acc.sked_Fixed_Site_Procedure_Projections__r != NULL && !acc.sked_Fixed_Site_Procedure_Projections__r.isEmpty();
                
                if (isValidDrive) {
                    decimal totalDriveProcedureCapacity = 0;
                    for (sked_Fixed_Site_Procedure_Projection__c fspp : acc.sked_Fixed_Site_Procedure_Projections__r) {
                        decimal donorsPerHoursCapacity = this.getFixedSiteDonorsPerHourCapacity(matrix, skedDrive, fspp.sked_Procedure_Type__c);           
                        decimal projectedTypeHours = this.getDrawHoursAdjusted(skedDrive, fspp.sked_Procedure_Type__c);
                        decimal driveProcedureCapacity = 0;
                        decimal qns = fspp.sked_QNS__c != NULL ? fspp.sked_QNS__c : 0;
                        decimal deferral = fspp.sked_Deferral__c != NULL ? fspp.sked_Deferral__c : 0;
                        
                        if (fspp.sked_Procedure_Type__c == 'Platelet') {
                            decimal projectedProcedures = skedDrive.sked_Platelet_Projected_Procedures__c != NULL ? skedDrive.sked_Platelet_Projected_Procedures__c : 0;
                            decimal plateletProcedureCapcity = projectedProcedures / (1 - qns / 100) / (1 - deferral / 100) / projectedTypeHours / donorsPerHoursCapacity;
                            totalDriveProcedureCapacity += plateletProcedureCapcity;
                        }
                        if (fspp.sked_Procedure_Type__c == 'Plasma') {
                            decimal projectedProcedures = skedDrive.sked_Plasma_Projected_Procedures__c != NULL ? skedDrive.sked_Plasma_Projected_Procedures__c : 0;
                            decimal plasmaProcedureCapcity = projectedProcedures / (1 - qns / 100) / (1 - deferral / 100) / projectedTypeHours / donorsPerHoursCapacity;
                            totalDriveProcedureCapacity += plasmaProcedureCapcity;
                            
                        }
                        if (fspp.sked_Procedure_Type__c == 'WB') {
                            decimal projectedProcedures = skedDrive.sked_WB_Projected_Procedures__c != NULL ? skedDrive.sked_WB_Projected_Procedures__c : 0;
                            decimal wbProcedureCapcity = projectedProcedures / (1 - qns / 100) / (1 - deferral / 100) / projectedTypeHours / donorsPerHoursCapacity;
                            totalDriveProcedureCapacity += wbProcedureCapcity;
                        }
                        if (fspp.sked_Procedure_Type__c == '2RBC') {
                            decimal projectedProcedures = skedDrive.sked_2RBC_Projected_Procedures__c != NULL ? skedDrive.sked_2RBC_Projected_Procedures__c : 0;
                            decimal x2rbcProcedureCapcity = projectedProcedures / (1 - qns / 100) / (1 - deferral / 100) / projectedTypeHours / donorsPerHoursCapacity;
                            totalDriveProcedureCapacity += x2rbcProcedureCapcity;
                        }  
                    }
                    skedDrive.sked_Procedure_Capacity__c = Math.ceil(totalDriveProcedureCapacity);
                }
            }   
        }
    }
    
    private decimal getFixedSiteDonorsPerHourCapacity(sked_Staffing_Decision_Matrix__c matrix, sked_Drive__c skedDrive, string procedureType) {
        Decimal donorsPerHourCapacicy = 0;
        if (matrix != null) {
            if (procedureType == 'Platelet') {
                donorsPerHourCapacicy = matrix.sked_Platelet_Hourly_Capacity__c != NULL ? matrix.sked_Platelet_Hourly_Capacity__c : 0;
            }
            else if (procedureType == 'Plasma') {
                donorsPerHourCapacicy = matrix.sked_Plasma_Hourly_Capacity__c != NULL ? matrix.sked_Plasma_Hourly_Capacity__c : 0;
            }
            else if (procedureType == 'WB') {
                donorsPerHourCapacicy = matrix.sked_WB_Hourly_Capacity__c != NULL ? matrix.sked_WB_Hourly_Capacity__c : 0;
            }
            else if (procedureType == '2RBC') {
                donorsPerHourCapacicy = matrix.sked_2RBC_Hourly_Capacity__c != NULL ? matrix.sked_2RBC_Hourly_Capacity__c : 0;
            }
        }        
        return donorsPerHourCapacicy;
    }
    
    private decimal getDrawHoursAdjusted(sked_Drive__c skedDrive, String procedureType) {
        DateTime driveStart = DateTime.newInstance(skedDrive.sked_Drive_Date__c, skedDrive.sked_Start_Time__c);
        DateTime driveEnd = DateTime.newInstance(skedDrive.sked_Drive_Date__c, skedDrive.sked_End_Time__c);       
        
        if (procedureType == Constants.PROCEDURE_TYPE_PLATELET) {
            driveStart = driveStart;
            driveEnd = driveEnd;
        }
        if (procedureType == Constants.PROCEDURE_TYPE_PLASMA) {
            driveStart = driveStart.addMinutes(60);
            driveEnd = driveEnd.addMinutes(-50);
        }
        if (procedureType == Constants.PROCEDURE_TYPE_WB) {
            driveStart = driveStart.addMinutes(60);
            boolean isSkipLastAppointment = skedDrive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c != NULL
                && skedDrive.sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c.contains(skedDrive.sked_Type_of_Drive__c);
            if (isSkipLastAppointment) {
                driveEnd = driveEnd.addMinutes(-15);
            }
            else {
                driveEnd = driveEnd;
            }
        }
        if (procedureType == Constants.PROCEDURE_TYPE_2RBC) {
            driveStart = driveStart.addMinutes(60);
            driveEnd = driveEnd.addMinutes(-30);
        }
        
        Decimal driveDuration = skedDateTimeUtils.getDifferentMinutes(driveStart, driveEnd);
        driveDuration = driveDuration < 0 ? 0 : driveDuration / 60;
        return driveDuration;
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
                sked_WB_Hourly_Capacity__c, sked_Platelet_Hourly_Capacity__c, sked_Plasma_Hourly_Capacity__c,
                RecordType.Name
                FROM sked_Staffing_Decision_Matrix__c
                WHERE Id IN :staffingDecisionMatrixIds];
    }
    
}