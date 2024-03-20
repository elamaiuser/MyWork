public class skedOperationRecordService {
    
    public static List<sked_Operation_Record__c> generateOperationRecords(Set<Id> driveIds) {
        return generateOperationRecords(driveIds, false);
    }
    
    public static List<sked_Operation_Record__c> generateOperationRecords(Set<Id> driveIds, boolean deleteExisting) {
        List<sked_Drive__c> drives = [SELECT Id, sked_Account__c, sked_Collection_Operation__c, sked_Drive_Site__c, sked_Primary_Contact__c,
                                      sked_2RBC_Projected_Procedures__c, sked_Drive_Site__r.sked_Site_Contact__c,
                                      sked_Drive_Owner__r.FirstName, sked_Drive_Owner__r.LastName, sked_Drive_Owner__r.MobilePhone,
                                      sked_Equipment_Allocated__c,
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
       
        Map<Id, DriveBridgeAPI__x> map_DriveId_ExternalDrive = new Map<Id, DriveBridgeAPI__x>();
        
        try {
            //Need to handle external data source before DML as this is considered as callout
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

        List<sked_Operation_Record__c> existingOperationRecords = [SELECT Id, sked_Drive_Shift__c
                                                                   FROM sked_Operation_Record__c
                                                                   WHERE sked_Drive_Shift__c IN :driveShiftIds];
        Map<Id, sked_Operation_Record__c> map_driveShift_OperationRecord = new Map<Id, sked_Operation_Record__c>();
        if (!existingOperationRecords.isEmpty()) {
            if (deleteExisting) {
                delete existingOperationRecords;
            }
            else {
                for (sked_Operation_Record__c existingOperationRecord : existingOperationRecords) {
                    map_driveShift_OperationRecord.put(existingOperationRecord.sked_Drive_Shift__c, existingOperationRecord);
                }
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
                for (sked_Drive_Shift__c driveShift : drive.sked_Drive_Shifts__r) {
                    if (!map_driveShift_OperationRecord.containsKey(driveShift.Id)) {
                        sked_Operation_Record__c newOperation = new sked_Operation_Record__c(
                            sked_Account__c = drive.sked_Account__c,
                            sked_Collection_Operation__c = drive.sked_Collection_Operation__c,
                            sked_Donor_Ambassadors_Requested__c = 0,
                            sked_Drive__c = drive.Id,
                            sked_Drive_Shift__c = driveShift.Id,
                            sked_Drive_Site__c = drive.sked_Drive_Site__c,
                            sked_DRD_Rep__c = drive.sked_Drive_Owner__r.FirstName + ' ' + drive.sked_Drive_Owner__r.LastName,
                            sked_DRD_Rep_Contact__c = drive.sked_Drive_Owner__r.MobilePhone,
                            sked_Power_Red_Machines_Sent__c = drive.sked_Equipment_Allocated__c,
                            sked_Primary_Contact__c = drive.sked_Primary_Contact__c,
                            sked_Site_Contact__c = drive.sked_Drive_Site__r.sked_Site_Contact__c
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
        
        List<sked__Job_Allocation__c> allocations = [SELECT Id, sked__Job__c, sked__Job__r.sked_Drive_Shift__c, sked__Resource__c, 
                                                     sked_Resource_Role__c, sked_Premium_Pay__c
                                                     FROM sked__Job_Allocation__c
                                                     WHERE sked__Job__r.sked_Drive_Shift__c IN :driveShiftIds
                                                     AND sked__Job__r.sked_Resource_Role__c != NULL
                                                     AND sked__Status__c NOT IN :inActiveAllocationStatuses];
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
                    newOperationRecordStaffs.add(newOperationRecordStaff);
                }
            }
        }
        return newOperationRecordStaffs;
    }
    
}