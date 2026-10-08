public class skedCreateNonUserChangeDCRBatch implements Schedulable, Database.Batchable<sked_Drive__c>, Database.Stateful {
    public Boolean stopProcessing = true;

    public static void schedule() {
        skedUtils.scheduleUniqueJobInSeconds('skedCreateNonUserChangeDCRBatch', new skedCreateNonUserChangeDCRBatch(), 15, true);
    }

    public void execute(SchedulableContext SC) {
        Integer existingBatchCount = [
            SELECT COUNT() 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = 'skedCreateNonUserChangeDCRBatch' 
            AND JobType = 'BatchApex' 
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
        if (existingBatchCount == 0) {
            Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        }
    }

    public List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked_RTD_Change_DCR_Required__c, sked_RTV_Change_DCR_Required__c, sked_Travel_Time_Change_DCR_Required__c,
            sked_Slot_Config_Change_DCR_Required__c, sked_Vehicle_Req_Change_DCR_Required__c,
            sked_SDM_Change_DCR_Required__c
            FROM sked_Drive__c
            WHERE sked_RTD_Change_DCR_Required__c = TRUE
            OR sked_RTV_Change_DCR_Required__c = TRUE
            OR sked_Travel_Time_Change_DCR_Required__c = TRUE
            OR sked_Slot_Config_Change_DCR_Required__c = TRUE
            OR sked_Vehicle_Req_Change_DCR_Required__c = TRUE
            OR sked_SDM_Change_DCR_Required__c = TRUE
            LIMIT 50000
        ];
    }

    public void execute(Database.BatchableContext BC, List<sked_Drive__c> drivesToGenerateDCR) {
        this.stopProcessing = drivesToGenerateDCR.isEmpty();

        if (this.stopProcessing == false) {
            slwcDriveService.skedCaptureNonUserChangeDCRs(getCaptureNonUserChangeDCRsRequestModel(
                drivesToGenerateDCR,
                'Role Time Detail Changed',
                'sked_Role_Time_Detail_Changed__c',
                'Boolean',
                skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE,
                'sked_RTD_Change_DCR_Required__c'
            ));
            slwcDriveService.skedCaptureNonUserChangeDCRs(getCaptureNonUserChangeDCRsRequestModel(
                drivesToGenerateDCR,
                'Role Time Variance Changed',
                'sked_Role_Time_Variance_Changed__c',
                'Boolean',
                skedConstants.DRIVE_CHANGE_REQUEST_TYPE_RTV_CHANGE,
                'sked_RTV_Change_DCR_Required__c'
            ));
            slwcDriveService.skedCaptureNonUserChangeDCRs(getCaptureNonUserChangeDCRsRequestModel(
                drivesToGenerateDCR,
                'Travel Time Changed',
                'sked_Travel_Time_Changed__c',
                'Boolean',
                skedConstants.DRIVE_CHANGE_REQUEST_TYPE_TRAVEL_TIME_CHANGE,
                'sked_Travel_Time_Change_DCR_Required__c'
            ));
            slwcDriveService.skedCaptureNonUserChangeDCRs(getCaptureNonUserChangeDCRsRequestModel(
                drivesToGenerateDCR,
                'Slot Configuration Changed',
                'sked_Slot_Configuration_Changed__c',
                'Boolean',
                skedConstants.DRIVE_CHANGE_REQUEST_TYPE_SLOT_CONFIG_CHANGE,
                'sked_Slot_Config_Change_DCR_Required__c'
            ));
            slwcDriveService.skedCaptureNonUserChangeDCRs(getCaptureNonUserChangeDCRsRequestModel(
                drivesToGenerateDCR,
                'Vehicle Requirement Changed',
                'sked_Vehicle_Requirement_Changed__c',
                'Boolean',
                skedConstants.DRIVE_CHANGE_REQUEST_TYPE_VEHICLE_REQUIREMENT_CHANGE,
                'sked_Vehicle_Req_Change_DCR_Required__c'
            ));
            slwcDriveService.skedCaptureNonUserChangeDCRs(getCaptureNonUserChangeDCRsRequestModel(
                drivesToGenerateDCR,
                'SDM Changed',
                'sked_SDM_Changed__c',
                'Boolean',
                skedConstants.DRIVE_CHANGE_REQUEST_TYPE_SDM_CHANGE,
                'sked_SDM_Change_DCR_Required__c'
            ));

            for (sked_Drive__c drive : drivesToGenerateDCR) {
                drive.sked_RTD_Change_DCR_Required__c = false;
                drive.sked_RTV_Change_DCR_Required__c = false;
                drive.sked_Travel_Time_Change_DCR_Required__c = false;
                drive.sked_Slot_Config_Change_DCR_Required__c = false;
                drive.sked_Vehicle_Req_Change_DCR_Required__c = false;
                drive.sked_SDM_Change_DCR_Required__c = false;
            }

            update drivesToGenerateDCR;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // No hand-off to skedDCRProcessingBatch: creating DCRs and applying them are separate steps
        // now, and applying is started deliberately rather than as a side effect of this sweep.
        if (this.stopProcessing == false) {
            Database.executeBatch(new skedCreateNonUserChangeDCRBatch(), 200);
        }
    }

    private List<sked_Drive__c> getAffectedDrives(List<sked_Drive__c> drivesToCheck, String driveChangedDetectField) {
        List<sked_Drive__c> affectedDrives = new List<sked_Drive__c>();

        for (sked_Drive__c drive : drivesToCheck) {
            if (drive.get(driveChangedDetectField) != null && (Boolean)drive.get(driveChangedDetectField) == true) {
                affectedDrives.add(drive);
            }
        }

        return affectedDrives;
    }

    private slwcDriveService.captureNonUserChangeDCRsModel getCaptureNonUserChangeDCRsRequestModel(
        List<sked_Drive__c> drives, 
        String fieldLabel,
        String fieldApiName,
        String fieldType,
        String driveChangeRequestType,
        String driveChangedDetectField
    ) {
        slwcDriveService.captureNonUserChangeDCRsModel request = new slwcDriveService.captureNonUserChangeDCRsModel();
        List<sked_Drive__c> drivesToGenerateDCR = getAffectedDrives(drives, driveChangedDetectField);
        request.fieldLabel = fieldLabel;
        request.fieldApiName = fieldApiName;
        request.fieldType = fieldType;
        request.driveChangeRequestType = driveChangeRequestType;
        request.impactedDrives = drivesToGenerateDCR;
        return request;
    }
}