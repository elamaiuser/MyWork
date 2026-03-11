public class skedOperationRecordService {
    public static void deleteExistingOperationRecords(Set<Id> driveIds) {
        List<sked_Drive__c> drives = [
            SELECT Id,
            (SELECT Id
            FROM sked_Drive_Shifts__r)
            FROM sked_Drive__c
            WHERE Id IN :driveIds
        ];

        Set<Id> driveShiftIds = new Set<Id>();
        for (sked_Drive__c drive : drives) {
            if (drive.sked_Drive_Shifts__r != NULL) {
                for (sked_Drive_Shift__c driveShift : drive.sked_Drive_Shifts__r) {
                    driveShiftIds.add(driveShift.Id);
                }
            }
        }

        List<sked_Operation_Record__c> existingOperationRecords = [
            SELECT Id, sked_Drive_Shift__c
            FROM sked_Operation_Record__c
            WHERE sked_Drive_Shift__c IN :driveShiftIds
        ];

        if (!existingOperationRecords.isEmpty()) {
            delete existingOperationRecords;
        }
    }

    public static List<sked_Operation_Record__c> regenerateOperationRecords(Set<Id> driveIds) {
        Map<Id, DriveBridgeAPI__x> map_DriveId_ExternalDrive = getMapDriveId_ExternalDrive(driveIds);
        deleteExistingOperationRecords(driveIds);
        return generateOperationRecords(driveIds, map_DriveId_ExternalDrive);
    }

    public static List<sked_Operation_Record__c> generateOperationRecords(Set<Id> driveIds) {
        Map<Id, DriveBridgeAPI__x> map_DriveId_ExternalDrive = getMapDriveId_ExternalDrive(driveIds);
        return generateOperationRecords(driveIds, map_DriveId_ExternalDrive);
    }
    
    public static List<sked_Operation_Record__c> populateExternalIds(Set<Id> operationRecordIds) {
        List<sked_Operation_Record__c> operationRecords = [SELECT Id, sked_Drive__c, sked_Account__c, sked_Drive_Site__c,
                                                           sked_Drive_External_ID__c, sked_Account_External_ID__c, sked_Site_External_ID__c
                                                           FROM sked_Operation_Record__c
                                                           WHERE Id IN :operationRecordIds];
        try {
            Set<Id> accountIds = new Set<Id>();
            Set<Id> driveSiteIds = new Set<Id>();
            Set<Id> driveIds = new Set<Id>();
            for (sked_Operation_Record__c operationRecord : operationRecords) {
                if (operationRecord.sked_Account__c != NULL) {
                    accountIds.add(operationRecord.sked_Account__c);
                }
                if (operationRecord.sked_Drive_Site__c != NULL) {
                    driveSiteIds.add(operationRecord.sked_Drive_Site__c);
                }
                if (operationRecord.sked_Drive__c != NULL) {
                    driveIds.add(operationRecord.sked_Drive__c);
                }
            }
            
            List<DriveBridgeAPI__x> externalDrives = [SELECT guid__c, external_id__c
                                                      FROM DriveBridgeAPI__x
                                                      WHERE guid__c IN :driveIds];
            
            Map<Id, DriveBridgeAPI__x> map_DriveId_ExternalDrive = new Map<Id, DriveBridgeAPI__x>();
            for (DriveBridgeAPI__x externalDrive : externalDrives) {
                map_DriveId_ExternalDrive.put(externalDrive.guid__c, externalDrive);
            }
            
            for (sked_Operation_Record__c operationRecord : operationRecords) {
                if (map_DriveId_ExternalDrive.containsKey(operationRecord.sked_Drive__c)) {
                    DriveBridgeAPI__x externalDrive = map_DriveId_ExternalDrive.get(operationRecord.sked_Drive__c);
                    operationRecord.sked_Drive_External_ID__c = externalDrive.external_id__c;
                    operationRecord.sked_Account_External_ID__c = externalDrive.Account_external_id__c;
                    operationRecord.sked_Site_External_ID__c = externalDrive.Location_external_id__c;
                }
            }
        }
        catch (Exception ex) {
            //error handler:
        }
        
        return operationRecords;
    }

    private static List<sked_Operation_Record__c> generateOperationRecords(Set<Id> driveIds, Map<Id, DriveBridgeAPI__x> map_DriveId_ExternalDrive) {
        List<sked_Drive__c> drives = [SELECT Id, sked_Account__c, sked_Collection_Operation__c, sked_Drive_Site__c, sked_Primary_Contact__c,
                                      sked_2RBC_Projected_Procedures__c, sked_Drive_Site__r.sked_Site_Contact__c,
                                      District_Manager__c, sked_Drive_Owner__c, sked_Type_of_Drive__c,
                                      sked_Drive_Owner__r.FirstName, sked_Drive_Owner__r.LastName, sked_Drive_Owner__r.MobilePhone,
                                      sked_Drive_Owner__r.WorkPhone__c, District_Manager__r.FirstName, District_Manager__r.LastName, 
                                      District_Manager__r.WorkPhone__c, sked_Equipment_Allocated__c,
                                      (SELECT Id
                                       FROM sked_Drive_Shifts__r),
                                      (SELECT Id, sked__Quantity__c, sked_Volunteer_Role__c
                                       FROM sked_Jobs__r
                                       WHERE sked_Volunteer_Role__c = 'Donor Ambassador')
                                      FROM sked_Drive__c
                                      WHERE Id IN :driveIds];
        Set<Id> accountIds = new Set<Id>();
        Set<Id> driveSiteIds = new Set<Id>();
        Set<Id> driveShiftIds = new Set<Id>();
        for (sked_Drive__c drive : drives) {
            if (drive.sked_Account__c != NULL) {
                accountIds.add(drive.sked_Account__c);
            }
            if (drive.sked_Drive_Site__c != NULL) {
                driveSiteIds.add(drive.sked_Drive_Site__c);
            }
            if (drive.sked_Drive_Shifts__r != NULL) {
                for (sked_Drive_Shift__c driveShift : drive.sked_Drive_Shifts__r) {
                    driveShiftIds.add(driveShift.Id);
                }
            }
        }

        List<sked_Operation_Record__c> existingOperationRecords = [SELECT Id, sked_Drive_Shift__c
                                                                   FROM sked_Operation_Record__c
                                                                   WHERE sked_Drive_Shift__c IN :driveShiftIds];
        Map<Id, sked_Operation_Record__c> map_driveShift_OperationRecord = new Map<Id, sked_Operation_Record__c>();
        if (!existingOperationRecords.isEmpty()) {
            for (sked_Operation_Record__c existingOperationRecord : existingOperationRecords) {
                map_driveShift_OperationRecord.put(existingOperationRecord.sked_Drive_Shift__c, existingOperationRecord);
            }
        }
        
        List<sked_Operation_Record__c> newOperations = new List<sked_Operation_Record__c>();
        for (sked_Drive__c drive : drives) {
            sked__Job__c donorAmbassadorJob;
            if (drive.sked_Jobs__r != NULL && !drive.sked_Jobs__r.isEmpty()) {
                for (sked__Job__c skedJob : drive.sked_Jobs__r) {
                    if (skedJob.sked_Volunteer_Role__c == 'Donor Ambassador') {
                        donorAmbassadorJob = skedJob;
                        break;
                    }
                }
            }
            if (drive.sked_Drive_Shifts__r != NULL && !drive.sked_Drive_Shifts__r.isEmpty()) {
                String drdRepInfo, drdRepContactNo;
                if (drive.sked_Type_of_Drive__c != skedConstants.DRIVE_TYPE_FIXED_SITE) {
                    if (drive.sked_Drive_Owner__c != NULL) {
                        drdRepInfo = drive.sked_Drive_Owner__r.FirstName + ' ' + drive.sked_Drive_Owner__r.LastName;
                        drdRepContactNo = drive.sked_Drive_Owner__r.WorkPhone__c;
                    } else if(drive.District_Manager__c != NULL) {
                        drdRepInfo = drive.District_Manager__r.FirstName + ' ' + drive.District_Manager__r.LastName;
                        drdRepContactNo = drive.District_Manager__r.WorkPhone__c;
                    }
                }
                for (sked_Drive_Shift__c driveShift : drive.sked_Drive_Shifts__r) {
                    if (!map_driveShift_OperationRecord.containsKey(driveShift.Id)) {
                        sked_Operation_Record__c newOperation = new sked_Operation_Record__c(
                            sked_Account__c = drive.sked_Account__c,
                            sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
                            sked_Donor_Ambassadors_Requested__c = 0,
                            sked_Drive__c = drive.Id,
                            sked_Drive_Shift__c = driveShift.Id,
                            sked_Drive_Site__c = drive.sked_Drive_Site__c,
                            sked_DRD_Rep__c = drdRepInfo, //HRP-9815
                            sked_DRD_Rep_Contact__c = drdRepContactNo, //HRP-9815
                            sked_Power_Red_Machines_Sent__c = drive.sked_Equipment_Allocated__c,
                            sked_Primary_Contact__c = drive.sked_Primary_Contact__c,
                            sked_Site_Contact__c = drive.sked_Drive_Site__r.sked_Site_Contact__c,
                            sked_Unique_Key__c = driveShift.Id
                        );
                        if (donorAmbassadorJob != NULL) {
                            newOperation.sked_Donor_Ambassadors_Requested__c = donorAmbassadorJob.sked__Quantity__c;
                        }
                        if (map_DriveId_ExternalDrive.containsKey(drive.Id)) {
                            DriveBridgeAPI__x externalDrive = map_DriveId_ExternalDrive.get(drive.Id);
                            newOperation.sked_Drive_External_ID__c = externalDrive.external_id__c;
                            newOperation.sked_Account_External_ID__c = externalDrive.Account_external_id__c;
                            newOperation.sked_Site_External_ID__c = externalDrive.Location_external_id__c;
                        }
                        newOperations.add(newOperation);
                    }
                }
            }
        }
        if (!newOperations.isEmpty()) {
            insert newOperations;
            
            List<sked_Operation_Record_Staff__c> newOperationRecordStaffs = generateOperationRecordStaffs(driveIds, newOperations);
            insert newOperationRecordStaffs;
        }
        
        return newOperations;
    } 
    
    private static List<sked_Operation_Record_Staff__c> generateOperationRecordStaffs(Set<Id> driveIds, List<sked_Operation_Record__c> operations) {
        List<string> inActiveAllocationStatuses = new List<string>();
        inActiveAllocationStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);
        inActiveAllocationStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);
        inActiveAllocationStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH);
        
        Map<string, string> mapRoleToPremiumOpPay = skedUtils.getMapRoleToPremiumOpPay();
        
        Set<Id> driveShiftIds = new Set<Id>();
        for (sked_Operation_Record__c operation : operations) {
            driveShiftIds.add(operation.sked_Drive_Shift__c);
        }
        
        List<sked__Job_Allocation__c> allocations = [
            SELECT Id, sked__Job__c, sked__Job__r.sked_Drive_Shift__c, sked__Resource__c, 
            sked_Resource_Role__c, sked_Premium_Pay__c, sked_Call_Out_Notes__c,
            sked_Call_Out_Reason_Code__c, sked_Call_Out_Reported__c, sked_Call_Out_Type__c,
            sked_DateTime_Call_Out_Received__c
            FROM sked__Job_Allocation__c
            WHERE sked__Job__r.sked_Drive_Shift__c IN :driveShiftIds
            AND sked__Job__r.sked_Resource_Role__c != NULL
            AND sked__Status__c NOT IN :inActiveAllocationStatuses
        ];
        Map<Id, List<sked__Job_Allocation__c>> mapDriveShiftAllocations = new Map<Id, List<sked__Job_Allocation__c>>();
        for (sked__Job_Allocation__c allocation : allocations) {
            List<sked__Job_Allocation__c> driveShiftAllocations;
            if (mapDriveShiftAllocations.containsKey(allocation.sked__Job__r.sked_Drive_Shift__c)) {
                driveShiftAllocations = mapDriveShiftAllocations.get(allocation.sked__Job__r.sked_Drive_Shift__c);
            }
            else {
                driveShiftAllocations = new List<sked__Job_Allocation__c>();
                mapDriveShiftAllocations.put(allocation.sked__Job__r.sked_Drive_Shift__c, driveShiftAllocations);
            }
            driveShiftAllocations.add(allocation);
        }
	
        List<sked_Operation_Record_Staff__c> newOperationRecordStaffs = new List<sked_Operation_Record_Staff__c>();
        for (sked_Operation_Record__c operation : operations) {
            if (mapDriveShiftAllocations.containsKey(operation.sked_Drive_Shift__c)) {
                List<sked__Job_Allocation__c> driveShiftAllocations = mapDriveShiftAllocations.get(operation.sked_Drive_Shift__c);
                for (sked__Job_Allocation__c driveShiftAllocation : driveShiftAllocations) {
                    sked_Operation_Record_Staff__c newOperationRecordStaff = new sked_Operation_Record_Staff__c(
                    	sked_Operation_Record__c = operation.Id,
                        sked_Job__c = driveShiftAllocation.sked__Job__c,
                        sked_Job_Allocation__c = driveShiftAllocation.Id,
                        sked_Resource__c = driveShiftAllocation.sked__Resource__c
                    );
                    List<string> premiumsOpPayList = new List<string>();
                    if (!string.isBlank(driveShiftAllocation.sked_Resource_Role__c) && mapRoleToPremiumOpPay.containsKey(driveShiftAllocation.sked_Resource_Role__c)) {
                        string premiumsOpPay = mapRoleToPremiumOpPay.get(driveShiftAllocation.sked_Resource_Role__c);
                        if (!premiumsOpPayList.contains(premiumsOpPay)) {
                            premiumsOpPayList.add(premiumsOpPay);
                        }
                    }
                    if (!premiumsOpPayList.isEmpty()) {
                        newOperationRecordStaff.sked_Premiums_Op_Pay__c = string.join(premiumsOpPayList, ';');
                    }

                    if (driveShiftAllocation.sked_Call_Out_Type__c == skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE) {
                        newOperationRecordStaff.sked_Early_Departure_Date_Received__c = driveShiftAllocation.sked_DateTime_Call_Out_Received__c.date();
                        newOperationRecordStaff.sked_Early_Departure_Time_Received__c = driveShiftAllocation.sked_DateTime_Call_Out_Received__c.time();
                        newOperationRecordStaff.sked_Early_Departure_DateTime_Received__c = driveShiftAllocation.sked_DateTime_Call_Out_Received__c;
                        newOperationRecordStaff.sked_Early_Departure_Reasons__c = driveShiftAllocation.sked_Call_Out_Reason_Code__c;
                    }

                    if (driveShiftAllocation.sked_Call_Out_Type__c == skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL) {
                        newOperationRecordStaff.sked_Late_Arrival_Date_Received__c = driveShiftAllocation.sked_DateTime_Call_Out_Received__c.date();
                        newOperationRecordStaff.sked_Late_Arrival_Time_Received__c = driveShiftAllocation.sked_DateTime_Call_Out_Received__c.time();
                        newOperationRecordStaff.sked_Late_Arrival_DateTime_Received__c = driveShiftAllocation.sked_DateTime_Call_Out_Received__c;
                        newOperationRecordStaff.sked_Late_Arrival_Reasons__c = driveShiftAllocation.sked_Call_Out_Reason_Code__c;
                    }
                    
                    newOperationRecordStaffs.add(newOperationRecordStaff);
                }
            }
        }
        return newOperationRecordStaffs;
    }
    
    private static Map<Id, DriveBridgeAPI__x> getMapDriveId_ExternalDrive(Set<Id> driveIds) {
        Map<Id, DriveBridgeAPI__x> map_DriveId_ExternalDrive = new Map<Id, DriveBridgeAPI__x>();
        
        try {
            List<DriveBridgeAPI__x> externalDrives = [SELECT guid__c, external_id__c, Account_external_id__c, Location_external_id__c 
                                                      FROM DriveBridgeAPI__x
                                                      WHERE guid__c IN :driveIds];
            for (DriveBridgeAPI__x externalDrive : externalDrives) {
                map_DriveId_ExternalDrive.put(externalDrive.guid__c, externalDrive);
            }
        }
        catch (Exception ex) {
            system.debug('#ex#' + ex.getMessage());
        }
        return map_DriveId_ExternalDrive;
    }
}