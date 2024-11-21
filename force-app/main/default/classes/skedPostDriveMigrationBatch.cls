global class skedPostDriveMigrationBatch implements Database.Batchable<sked_Drive__c>, Database.AllowsCallouts, Database.Stateful {
    
    private Set<String> keysToRank;
    protected string lastId = '';

    global skedPostDriveMigrationBatch(string lastId) { 
    	this.lastId = lastId;
    }
    
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        this.keysToRank = new Set<String>();
        return [SELECT Id, sked_Type_of_Drive__c, sked_Account__c, sked_Travel_Time_Included__c,
                sked_Opportunity__r.OwnerId, sked_Drive_Owner__c, sked_Drive_Date__c,
                sked_Collection_Operation__c, sked_Point__c, sked_Status__c, 
                sked_Collection_Operation__r.sked_Lunch_Break_Duration_Fixed_Site__c, 
                sked_Collection_Operation__r.sked_Lunch_Break_Duration_Mobile__c, 
                sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c, 
                sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c,
                sked_Maximum_Lunch_Break_Duration__c,  sked_Projected_Registered_Donors__c,
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
                WHERE Id > :this.lastId
                AND sked_MigrationID__c != NULL
                AND sked_Post_Migration_Processed__c = FALSE
                ORDER BY Id ASC
                LIMIT 5000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        try {
            populateDriveOwner(records);
            populateMaximumLunchBreakDuration(records);
            populateTravelTimeIncluded(records);
            populateProcedureProductProjected(records);
            populateDriveProductivity(records);
            populateStaffCapacity(records);
            populateDrivePoints(records);
        }
        catch (exception ex) {
            sked__Debug_Log__c debugLog = new sked__Debug_Log__c(
                sked__Message__c = ex.getStackTraceString(),
                sked__Summary__c = ex.getMessage(),
                sked__Type__c = 'Debug Log'
            );
            insert debugLog;
        }
        
        for (sked_Drive__c record : records) {
            record.sked_Post_Migration_Processed__c = TRUE;
        }
        update records;
        
        this.lastId = records.get(records.size() - 1).Id;
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked_Drive__c> remainRecordQuery = [SELECT Id
                                                 FROM sked_Drive__c
                                                 WHERE Id > :this.lastId
                                                 AND sked_MigrationID__c != NULL
                                                 AND sked_Post_Migration_Processed__c = FALSE
                                                 LIMIT 1];
        if (!remainRecordQuery.isEmpty()) {
            Database.executeBatch(new skedPostDriveMigrationBatch(this.lastId), 200);
        }

        if (!this.keysToRank.isEmpty()) {
            Database.executeBatch(new skedDriveRankingBatch(this.keysToRank), 1);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    
    
    private void populateDriveOwner(List<sked_Drive__c> skedDrives) {
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Drive_Owner__c == NULL && skedDrive.sked_Opportunity__r != NULL) {
            	skedDrive.sked_Drive_Owner__c = skedDrive.sked_Opportunity__r.OwnerId;
            }
        }
    }
    
    private void populateMaximumLunchBreakDuration(List<sked_Drive__c> skedDrives) {
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Maximum_Lunch_Break_Duration__c == NULL && skedDrive.sked_Collection_Operation__r != NULL) {
                if (skedDrive.sked_Type_of_Drive__c == 'Mobile') {
                    skedDrive.sked_Maximum_Lunch_Break_Duration__c = skedDrive.sked_Collection_Operation__r.sked_Lunch_Break_Duration_Mobile__c;
                }
                else if (skedDrive.sked_Type_of_Drive__c == 'Fixed Site') {
                    skedDrive.sked_Maximum_Lunch_Break_Duration__c = skedDrive.sked_Collection_Operation__r.sked_Lunch_Break_Duration_Fixed_Site__c;
                }
            }
        }
    }
    
    private void populateTravelTimeIncluded(List<sked_Drive__c> skedDrives) {
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Travel_Time_Included__c == NULL && skedDrive.sked_Collection_Operation__r != NULL) {
                if (skedDrive.sked_Type_of_Drive__c == 'Mobile') {
                    skedDrive.sked_Travel_Time_Included__c = skedDrive.sked_Collection_Operation__r.sked_Travel_Time_Included_Mobile__c;
                }
                else if (skedDrive.sked_Type_of_Drive__c == 'Fixed Site') {
                    skedDrive.sked_Travel_Time_Included__c = skedDrive.sked_Collection_Operation__r.sked_Travel_Time_Included_Fixed_Site__c;
                }
            }
        }
    }
    
    private void populateProcedureProductProjected(List<sked_Drive__c> skedDrives) {
        for (sked_Drive__c skedDrive : skedDrives) {
            decimal x2rbcProjectedProcedures = skedDrive.sked_2RBC_Projected_Procedures__c != NULL ? skedDrive.sked_2RBC_Projected_Procedures__c : 0;
            decimal wbProjectedProcedures = skedDrive.sked_WB_Projected_Procedures__c != NULL ? skedDrive.sked_WB_Projected_Procedures__c : 0;
            decimal plasmaProjectedProcedures = skedDrive.sked_Plasma_Projected_Procedures__c != NULL ? skedDrive.sked_Plasma_Projected_Procedures__c : 0;
            decimal plateletProjectedProcedures = skedDrive.sked_Platelet_Projected_Procedures__c != NULL ? skedDrive.sked_Platelet_Projected_Procedures__c : 0;
            
            if (skedDrive.sked_Total_Procedures_Projected__c == NULL) {
                skedDrive.sked_Total_Procedures_Projected__c = x2rbcProjectedProcedures + wbProjectedProcedures + plasmaProjectedProcedures + plateletProjectedProcedures;
            }
            if (skedDrive.sked_Total_Products_Projected__c == NULL) {
                skedDrive.sked_Total_Products_Projected__c = x2rbcProjectedProcedures * 2 + wbProjectedProcedures + plasmaProjectedProcedures + plateletProjectedProcedures;
            }
        }
    }
    
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
            mapStaffingDecisionMatrix.put(staffingDecisionMatrix.Id, staffingDecisionMatrix);
        }
        
        for (sked_Drive__c skedDrive : skedDrives) {
            if (skedDrive.sked_Type_of_Drive__c == 'Mobile') {
                sked_Collection_Operation_SDM__c collectionOperationSDM;
                for (sked_Collection_Operation_SDM__c item : collectionOperationSDMs) {
                    if (item.sked_Collection_Operation__c == skedDrive.sked_Collection_Operation__c) {
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

    private void populateDrivePoints(List<sked_Drive__c> drives) {
        List<sked_Drive_Rank_Setting__c> driveRankSettings = [
            SELECT Id, sked_Type__c, sked_Low_End__c, sked_High_End__c, sked_Point__c
            FROM sked_Drive_Rank_Setting__c
        ];

        if (!driveRankSettings.isEmpty()) {
            for (sked_Drive__c drive : drives) {
                decimal driveProductivityPoints = 0;
                if (drive.sked_Drive_Productivity_Planned__c != NULL) {
                    for (sked_Drive_Rank_Setting__c driveRankSetting : driveRankSettings) {
                        if (driveRankSetting.sked_Type__c == 'Planned Productivity') {
                            if (driveRankSetting.sked_Low_End__c <= drive.sked_Drive_Productivity_Planned__c && drive.sked_Drive_Productivity_Planned__c < driveRankSetting.sked_High_End__c) {
                                driveProductivityPoints = driveRankSetting.sked_Point__c;
                                break;
                            }
                        }
                    }
                }
                
                decimal sizePoints = 0;
                if (drive.sked_Projected_Registered_Donors__c != NULL) {
                    for (sked_Drive_Rank_Setting__c driveRankSetting : driveRankSettings) {
                        if (driveRankSetting.sked_Type__c == 'Size') {
                            if (driveRankSetting.sked_Low_End__c <= drive.sked_Projected_Registered_Donors__c && drive.sked_Projected_Registered_Donors__c < driveRankSetting.sked_High_End__c) {
                                sizePoints = driveRankSetting.sked_Point__c;
                                break;
                            }
                        }
                    }
                }
                
                decimal currentPoint = drive.sked_Point__c;
                drive.sked_Point__c = driveProductivityPoints + sizePoints;
                if (drive.sked_Status__c == 'Draft' && drive.sked_Type_of_Drive__c != 'Fixed Site' && drive.sked_Point__c != currentPoint) {
                    String key = drive.sked_Collection_Operation__c + ':' + String.valueOf(drive.sked_Drive_Date__c);
                    this.keysToRank.add(key);
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
    
    /*********************************************************** Nested classes ***********************************************************/
    
}