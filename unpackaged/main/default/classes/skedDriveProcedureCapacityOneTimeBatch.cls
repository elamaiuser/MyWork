global class skedDriveProcedureCapacityOneTimeBatch implements Database.Batchable<sObject> {
    Set<Id> driveIds;
    global skedDriveProcedureCapacityOneTimeBatch(Set<Id> driveIds) { 
    	this.driveIds = driveIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked_Type_of_Drive__c, sked_Account__c,
            sked_Opportunity__r.OwnerId, sked_Drive_Owner__c, sked_Operation_Type__c,
            sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c,
            sked_Collection_Operation__c,
            sked_Collection_Operation__r.sked_Skip_Last_Appointment_For__c,
            sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, 
            sked_Plasma_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c,
            (
                SELECT Id, sked_Platelet_Rounds__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive__c
                FROM sked_Drive_Shifts__r
                ORDER BY sked_Start__c
            )
            FROM sked_Drive__c
            WHERE Id IN :this.driveIds
            AND sked_Type_of_Drive__c = :skedConstants.DRIVE_TYPE_FIXED_SITE
            AND sked_Operation_Type__c != :skedConstants.OPERATION_TYPE_WB
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        DriveProcedureCapacityCalcResult calculationResult = new DriveProcedureCapacityCalcResult();
        try {
            calculationResult = populateProcedureCapacity(records);
        }
        catch (exception ex) {
            insert new sked__Debug_Log__c(
                sked__Message__c = ex.getStackTraceString(),
                sked__Summary__c = ex.getMessage(),
                sked__Type__c = 'Debug Log'
            );
        }

        skedHubBase.setBypassAllTriggers(true);

        if (calculationResult.jobsToUpdate.size() > 0) {
            update calculationResult.jobsToUpdate;
        }

        if (calculationResult.drivesToUpdate.size() > 0) {
            update calculationResult.drivesToUpdate;
        }

        if (calculationResult.driveShiftsToUpdate.size() > 0) {
            update calculationResult.driveShiftsToUpdate;
        }

        skedHubBase.setBypassAllTriggers(false);
    }
    
    global void finish(Database.BatchableContext BC) {}
    
    /*********************************************************** Privated Methods ***********************************************************/
    
    private DriveProcedureCapacityCalcResult populateProcedureCapacity(List<sked_Drive__c> skedDrives) {
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
        Map<Id, sked_Staffing_Decision_Matrix__c> mapStaffingDecisionMatrix = fetchStaffingDecisionMatrices(collectionOperationSDMs);
        
        Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id,
                                                            (SELECT Id, sked_Effective_Start_Date__c, sked_Effective_End_Date__c,
                                                             sked_Deferral__c, sked_QNS__c, sked_Procedure_Type__c, sked_Productive_Procedure_Goal__c
                                                             FROM sked_Fixed_Site_Procedure_Projections__r
                                                             WHERE sked_Effective_Start_Date__c <= :latestDriveDate
                                                             AND sked_Effective_End_Date__c >= :earliestDriveDate
                                                             AND sked_Procedure_Type__c != 'Platelet')
                                                            FROM Account
                                                            WHERE Id IN :accountIds]);
        
        DriveProcedureCapacityCalcResult calculationResult = new DriveProcedureCapacityCalcResult();
        Map<Id, Decimal> map_driveId_apheresisStaffQuantity = new Map<Id, Decimal>();
        for (sked_Drive__c skedDrive : skedDrives) {
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
                if (collectionOperationSDM != NULL && mapStaffingDecisionMatrix != NULL && mapStaffingDecisionMatrix.containsKey(collectionOperationSDM.sked_Staffing_Decision_Matrix__c)) {
                    matrix =  mapStaffingDecisionMatrix.get(collectionOperationSDM.sked_Staffing_Decision_Matrix__c);
                }
                
                Account acc = mapAccount.get(skedDrive.sked_Account__c);
                boolean isValidDrive = matrix != NULL && acc != NULL && acc.sked_Fixed_Site_Procedure_Projections__r != NULL && !acc.sked_Fixed_Site_Procedure_Projections__r.isEmpty();
                
                if (isValidDrive) {
                    decimal totalDriveProcedureCapacity = 0;
                    Map<String, Decimal> map_procedureType_procedureCapacity = new Map<String, Decimal>();
                    Decimal totalApheresisStaffQuantity = 0;

                    // Calculate Platelet Staff Count Separately
                    Integer drivePlaleletRounds = this.getDrivePlateletRounds(skedDrive);
                    Decimal plateletRoundCapacity = this.getFixedSiteProcedureTypeCapacity(matrix, skedDrive, 'Platelet'); 
                    Decimal plateProcedureProjected = this.getProjectedProceduresByProcedureType(skedDrive, 'Platelet');
                    if(plateProcedureProjected > 0) {
                        totalApheresisStaffQuantity = plateProcedureProjected / drivePlaleletRounds / plateletRoundCapacity;
                        totalDriveProcedureCapacity = totalApheresisStaffQuantity * drivePlaleletRounds * plateletRoundCapacity;
                        map_procedureType_procedureCapacity.put('Platelet', totalDriveProcedureCapacity);
                    }

                    // Calculate Other Staff Counts
                    for (sked_Fixed_Site_Procedure_Projection__c fspp : acc.sked_Fixed_Site_Procedure_Projections__r) {
                        if(fspp.sked_Effective_Start_Date__c <= skedDrive.sked_Drive_Date__c && fspp.sked_Effective_End_Date__c >= skedDrive.sked_Drive_Date__c) {
                            decimal procedureTypeCapacity = this.getFixedSiteProcedureTypeCapacity(matrix, skedDrive, fspp.sked_Procedure_Type__c);           
                            decimal projectedTypeHours = this.getDrawHoursAdjusted(skedDrive, fspp.sked_Procedure_Type__c);
                            decimal projectProceduresByProcedureType = this.getProjectedProceduresByProcedureType(skedDrive, fspp.sked_Procedure_Type__c);
                            decimal driveProcedureCapacity = 0;
                            decimal qns = fspp.sked_QNS__c != NULL ? fspp.sked_QNS__c : 0;
                            decimal deferral = fspp.sked_Deferral__c != NULL ? fspp.sked_Deferral__c : 0;
                            decimal procedureCapacity = 0;
                            decimal noOfStaff = 0;

                            if (projectedTypeHours != 0 && procedureTypeCapacity != 0) {
                                noOfStaff = projectProceduresByProcedureType / (1 - qns / 100) / (1 - deferral / 100) / projectedTypeHours / procedureTypeCapacity;
                                procedureCapacity = noOfStaff * procedureTypeCapacity * projectedTypeHours * (1 - qns / 100) * (1 - deferral / 100);
                            }
                            totalApheresisStaffQuantity += noOfStaff;
                            totalDriveProcedureCapacity += procedureCapacity;
                            map_procedureType_procedureCapacity.put(fspp.sked_Procedure_Type__c, procedureCapacity);
                        }
                    }

                    skedDrive.sked_Procedure_Capacity__c = totalDriveProcedureCapacity.round(RoundingMode.HALF_UP);

                    calculationResult.drivesToUpdate.add(skedDrive);
                    calculationResult.driveShiftsToUpdate.addAll(calculateDriveShiftProcedureCapacity(
                        skedDrive,
                        drivePlaleletRounds,
                        map_procedureType_procedureCapacity
                    ));

                    totalApheresisStaffQuantity = totalApheresisStaffQuantity.round(RoundingMode.HALF_UP);
                    map_driveId_apheresisStaffQuantity.put(skedDrive.Id, totalApheresisStaffQuantity);
                }   

            if (map_driveId_apheresisStaffQuantity.size() > 0) {
                calculationResult.jobsToUpdate.addAll(updateDriveShiftApheresisJobQuantity(
                    calculationResult.driveShiftsToUpdate,
                    map_driveId_apheresisStaffQuantity
                ));
            }
        }
        return calculationResult;
    }
    
    private decimal getFixedSiteProcedureTypeCapacity(sked_Staffing_Decision_Matrix__c matrix, sked_Drive__c skedDrive, string procedureType) {
        Decimal procedureTypeCapacity = 0;
        if (matrix != null) {
            if (procedureType == Constants.PROCEDURE_TYPE_PLATELET) {
                procedureTypeCapacity = matrix.sked_Platelet_Round_Capacity__c != NULL ? matrix.sked_Platelet_Round_Capacity__c : 0;
            }
            else if (procedureType == Constants.PROCEDURE_TYPE_PLASMA) {
                procedureTypeCapacity = matrix.sked_Plasma_Hourly_Capacity__c != NULL ? matrix.sked_Plasma_Hourly_Capacity__c : 0;
            }
            else if (procedureType == Constants.PROCEDURE_TYPE_WB) {
                procedureTypeCapacity = matrix.sked_WB_Hourly_Capacity__c != NULL ? matrix.sked_WB_Hourly_Capacity__c : 0;
            }
            else if (procedureType == Constants.PROCEDURE_TYPE_2RBC) {
                procedureTypeCapacity = matrix.sked_2RBC_Hourly_Capacity__c != NULL ? matrix.sked_2RBC_Hourly_Capacity__c : 0;
            }
        }        
        return procedureTypeCapacity;
    }
    
    private decimal getDrawHoursAdjusted(sked_Drive__c skedDrive, String procedureType) {
        DateTime driveStart = DateTime.newInstance(skedDrive.sked_Drive_Date__c, skedDrive.sked_Start_Time__c);
        DateTime driveEnd = DateTime.newInstance(skedDrive.sked_Drive_Date__c, skedDrive.sked_End_Time__c);       
        
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
    
    private Map<Id, sked_Staffing_Decision_Matrix__c> fetchStaffingDecisionMatrices(List<sked_Collection_Operation_SDM__c> collectionOperationSDMs) {
        Set<Id> staffingDecisionMatrixIds = new Set<Id>();
        for (sked_Collection_Operation_SDM__c collectionOperationSdm : collectionOperationSDMs) {
            staffingDecisionMatrixIds.add(collectionOperationSdm.sked_Staffing_Decision_Matrix__c);
        }
        return new Map<Id, sked_Staffing_Decision_Matrix__c>([SELECT Id, sked_2RBC_Staff_Capacity__c, sked_Charge_Capacity__c, sked_Charge_Threshold__c,
                sked_Driver_Capacity__c, sked_Driver_Support_Capacity__c, 
                sked_NR_Volunteer_Fixed_Site_Band_Lower__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c,
                sked_Team_Supervisor_Threshold__c, sked_VP_HH_Capacity__c, sked_2RBC_Hourly_Capacity__c,
                sked_WB_Hourly_Capacity__c, sked_Platelet_Round_Capacity__c, sked_Plasma_Hourly_Capacity__c,
                RecordType.Name
                FROM sked_Staffing_Decision_Matrix__c
                WHERE Id IN :staffingDecisionMatrixIds
                AND RecordType.Name = 'Fixed Site']);
    }
    
    private Integer getDrivePlateletRounds(sked_Drive__c drive) {
        Integer plateletRounds = 0;
        if (drive.sked_Drive_Shifts__r != NULL && !drive.sked_Drive_Shifts__r.isEmpty()) {
            for (sked_Drive_Shift__c driveShift : drive.sked_Drive_Shifts__r) {
                plateletRounds += driveShift.sked_Platelet_Rounds__c != NULL ? Integer.valueOf(driveShift.sked_Platelet_Rounds__c) : 0;
            }
        }
        return plateletRounds;
    }

    private Decimal getProjectedProceduresByProcedureType(sked_Drive__c skedDrive, String procedureType) {
        Decimal projectedProcedures = 0;
        if (procedureType == Constants.PROCEDURE_TYPE_PLATELET) {
            projectedProcedures = skedDrive.sked_Platelet_Projected_Procedures__c != NULL ? skedDrive.sked_Platelet_Projected_Procedures__c : 0;
        }
        if (procedureType == Constants.PROCEDURE_TYPE_PLASMA) {
            projectedProcedures = skedDrive.sked_Plasma_Projected_Procedures__c != NULL ? skedDrive.sked_Plasma_Projected_Procedures__c : 0;
        }
        if (procedureType == Constants.PROCEDURE_TYPE_WB) {
            projectedProcedures = skedDrive.sked_WB_Projected_Procedures__c != NULL ? skedDrive.sked_WB_Projected_Procedures__c : 0;
        }
        if (procedureType == Constants.PROCEDURE_TYPE_2RBC) {
            projectedProcedures = skedDrive.sked_2RBC_Projected_Procedures__c != NULL ? skedDrive.sked_2RBC_Projected_Procedures__c : 0;
        }
        return projectedProcedures;
    }

    private List<sked_Drive_Shift__c> calculateDriveShiftProcedureCapacity(sked_Drive__c skedDrive, Integer drivePlateletRounds, Map<String, Decimal> map_procedureType_procedureCapacity) {
        Map<Id, sked_Drive_Shift__c> map_id_driveShiftToUpdate = new Map<Id, sked_Drive_Shift__c>();
        Decimal driveProcedureCapacity = skedDrive.sked_Procedure_Capacity__c;
        resetAllDriveShiftsProcedureCapacity(skedDrive.sked_Drive_Shifts__r);

        for (String procedureType : map_procedureType_procedureCapacity.keySet()) {
            if (skedDrive.sked_Drive_Shifts__r != NULL && !skedDrive.sked_Drive_Shifts__r.isEmpty()) {
                Boolean useRoundTimes = (new List<String>{Constants.PROCEDURE_TYPE_PLATELET, Constants.PROCEDURE_TYPE_PLASMA}).contains(procedureType);
                Boolean execludeOverlappedTime = (new List<String>{Constants.PROCEDURE_TYPE_PLATELET, Constants.PROCEDURE_TYPE_PLASMA, Constants.PROCEDURE_TYPE_2RBC}).contains(procedureType);
                DriveShiftsDurationResult driveShiftsDurationResult = useRoundTimes ? null : this.getDriveShiftsDurationInfo(skedDrive, execludeOverlappedTime);
                Decimal totalProcedureCapacityByProcedureType = map_procedureType_procedureCapacity.get(procedureType);
                Decimal remainingProcedureCapacityByProcedureType = totalProcedureCapacityByProcedureType;

                for (sked_Drive_Shift__c driveShift : skedDrive.sked_Drive_Shifts__r) {
                    Decimal percentage = 0;
                    if (useRoundTimes) {
                        if (drivePlateletRounds != 0) {
                            percentage = (driveShift.sked_Platelet_Rounds__c == null ? 0 : driveShift.sked_Platelet_Rounds__c) / drivePlateletRounds;
                        }
                    } else {
                        percentage = driveShiftsDurationResult.map_driveShiftId_duration.get(driveShift.Id) / driveShiftsDurationResult.totalDriveShiftsDuration;
                    }

                    Decimal driveShiftProcedureCapacityByProcedureType = totalProcedureCapacityByProcedureType * percentage;
                    if (driveShiftProcedureCapacityByProcedureType > remainingProcedureCapacityByProcedureType) {
                        driveShiftProcedureCapacityByProcedureType = remainingProcedureCapacityByProcedureType;
                    }

                    remainingProcedureCapacityByProcedureType -= driveShiftProcedureCapacityByProcedureType;
                    driveShift.sked_Procedure_Capacity__c += driveShiftProcedureCapacityByProcedureType;
                    map_id_driveShiftToUpdate.put(driveShift.Id, driveShift);
                }
            }
        }

        if (map_id_driveShiftToUpdate.size() > 0) {
            Decimal totalDriveProcedureCapacity = skedDrive.sked_Procedure_Capacity__c;
            Decimal remainingDriveProcedureCapacity = totalDriveProcedureCapacity;
            for (sked_Drive_Shift__c driveShiftToUpdate : map_id_driveShiftToUpdate.values()) {
                driveShiftToUpdate.sked_Procedure_Capacity__c = Math.ceil(driveShiftToUpdate.sked_Procedure_Capacity__c);
                if (driveShiftToUpdate.sked_Procedure_Capacity__c > remainingDriveProcedureCapacity) {
                    driveShiftToUpdate.sked_Procedure_Capacity__c = remainingDriveProcedureCapacity;
                }

                remainingDriveProcedureCapacity -= driveShiftToUpdate.sked_Procedure_Capacity__c;
            }
        }

        return map_id_driveShiftToUpdate.values();
    }

    private List<sked__Job__c> updateDriveShiftApheresisJobQuantity(List<sked_Drive_Shift__c> driveShifts, Map<Id, Decimal> map_driveId_apheresisStaffQuantity) {
        Set<String> staffAllocatedExcludedRoles = new Set<String>();
        for (sked_Staff_Setup_Excluded_Role__c staffSetupExcludedRole : [
            SELECT sked_Resource_Role__c, sked_Excluded_For_Staff_Allocated__c, sked_Excluded_for_Assigned_Staff_Count__c
            FROM sked_Staff_Setup_Excluded_Role__c
        ]) {
            if (staffSetupExcludedRole.sked_Excluded_For_Staff_Allocated__c == true) {
                staffAllocatedExcludedRoles.add(staffSetupExcludedRole.sked_Resource_Role__c);
            }
        }

        Map<Id, List<sked__Job__c>> map_driveShiftId_jobs = getMapDriveShiftIdJobs(driveShifts);

        List<sked__Job__c> jobsToUpdate = new List<sked__Job__c>();
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            Decimal staffSetup = 0;
            for (sked__Job__c job : map_driveShiftId_jobs.get(driveShift.Id)) {
                if (job.sked_Resource_Role__c != NULL && !staffAllocatedExcludedRoles.contains(job.sked_Resource_Role__c)) {
                    if (job.sked_Resource_Role__c == 'Apheresis' && map_driveId_apheresisStaffQuantity.containsKey(driveShift.sked_Drive__c)) {
                        job.sked__Quantity__c = map_driveId_apheresisStaffQuantity.get(driveShift.sked_Drive__c);
                        job.sked_System_Quantity__c = job.sked__Quantity__c;
                        jobsToUpdate.add(job);
                    }
                    staffSetup += job.sked__Quantity__c != NULL ? job.sked__Quantity__c : 0;
                }
            }
            driveShift.sked_Staff_Setup__c = staffSetup;
        }

        return jobsToUpdate;
    }

    private Map<Id, List<sked__Job__c>> getMapDriveShiftIdJobs(List<sked_Drive_Shift__c> driveShifts) {
        Map<Id, List<sked__Job__c>> map_driveShiftId_jobs = new Map<Id, List<sked__Job__c>>();
        List<Id> driveShiftIds = new List<Id>();
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            driveShiftIds.add(driveShift.Id);
            map_driveShiftId_jobs.put(driveShift.Id, new List<sked__Job__c>());
        }

        for (sked__Job__c job : [SELECT Id, sked_Drive_Shift__c, sked_Resource_Role__c, sked__Quantity__c, sked_System_Quantity__c
                                 FROM sked__Job__c
                                 WHERE sked_Resource_Role__c != NULL AND sked_Drive_Shift__c IN :driveShiftIds]) {
            map_driveShiftId_jobs.get(job.sked_Drive_Shift__c).add(job);
        }
        return map_driveShiftId_jobs;
    }

    private DriveShiftsDurationResult getDriveShiftsDurationInfo(sked_Drive__c drive, Boolean excludeOverlappedTime) {
        DriveShiftsDurationResult driveShiftsDurationResult = new DriveShiftsDurationResult();
        for (Integer i = 0; i < drive.sked_Drive_Shifts__r.size(); i++) {
            sked_Drive_Shift__c driveShift = drive.sked_Drive_Shifts__r[i];
            Datetime driveShiftStart = Datetime.newInstance(drive.sked_Drive_Date__c, driveShift.sked_Start_Time__c);
            Datetime driveShiftEnd = Datetime.newInstance(drive.sked_Drive_Date__c, driveShift.sked_End_Time__c);

            if (excludeOverlappedTime) {
                sked_Drive_Shift__c previousDriveShift = null;
                if (i > 0) {
                    previousDriveShift = drive.sked_Drive_Shifts__r[i - 1];
                }

                Datetime previousDriveShiftEnd = previousDriveShift == null ? null : Datetime.newInstance(drive.sked_Drive_Date__c, previousDriveShift.sked_End_Time__c);
                if (previousDriveShift != null && previousDriveShiftEnd > driveShiftStart) {
                    driveShiftStart = previousDriveShiftEnd < driveShiftEnd ? previousDriveShiftEnd : driveShiftEnd;
                }
            }
            Decimal driveShiftDuration = skedDateTimeUtils.getDifferentMinutes(driveShiftStart, driveShiftEnd);
            driveShiftsDurationResult.map_driveShiftId_duration.put(driveShift.Id, driveShiftDuration);
            driveShiftsDurationResult.totalDriveShiftsDuration += driveShiftDuration;
        }
        return driveShiftsDurationResult;
    }

    private void resetAllDriveShiftsProcedureCapacity(List<sked_Drive_Shift__c> driveShifts) {
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            driveShift.sked_Procedure_Capacity__c = 0;
        }
    }

    private class DriveProcedureCapacityCalcResult {
        List<sked_Drive__c> drivesToUpdate;
        List<sked_Drive_Shift__c> driveShiftsToUpdate;
        List<sked__Job__c> jobsToUpdate;

        public DriveProcedureCapacityCalcResult() {
            this.drivesToUpdate = new List<sked_Drive__c>();
            this.driveShiftsToUpdate = new List<sked_Drive_Shift__c>();
            this.jobsToUpdate = new List<sked__Job__c>();
        }
    }

    private class DriveShiftsDurationResult {
        Map<String, Decimal> map_driveShiftId_duration;
        Decimal totalDriveShiftsDuration;

        public DriveShiftsDurationResult() {
            this.map_driveShiftId_duration = new Map<String, Decimal>();
            this.totalDriveShiftsDuration = 0;
        }
    }
}