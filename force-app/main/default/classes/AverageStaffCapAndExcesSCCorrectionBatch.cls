Global class AverageStaffCapAndExcesSCCorrectionBatch implements Database.Batchable<sObject>, Database.Stateful{
    /*

	AverageStaffCapAndExcesSCCorrectionBatch batchObject = new AverageStaffCapAndExcesSCCorrectionBatch();
    Database.executeBatch(batchObject,200);

    Set<Id> driveId = new Set<Id>{''};
    AverageStaffCapAndExcesSCCorrectionBatch batchObject = new AverageStaffCapAndExcesSCCorrectionBatch(driveId);
    Database.executeBatch(batchObject,200);

    
    Date toDate = Date.newInstance(2024,01,01);
    Date fromDate = Date.newInstance(2024,09,23);
    
    AverageStaffCapAndExcesSCCorrectionBatch batchObject = new AverageStaffCapAndExcesSCCorrectionBatch(toDate, fromDate);
    Database.executeBatch(batchObject,200);

   */
    String query;
    Set<Id> driveId;
    Date toDate; 
    Date fromDate;
    
    public AverageStaffCapAndExcesSCCorrectionBatch(){
        this.query = 'Select Id, sked_Drive_Date__c, Average_Staff_Capacity__c,  Excess_Staff_Capacity__c, sked_Staff_Capacity__c, sked_Projected_Registered_Donors__c from sked_Drive__c where sked_Drive_Date__c >= Today AND sked_Status__c Not IN (\'Cancel\',\'Complete\') AND (sked_Operation_Type__c = \'Non Integrated WB\' or sked_Type_of_Drive__c = \'Mobile\')';
    }

    public AverageStaffCapAndExcesSCCorrectionBatch(Set<Id> driveId){
        this.driveId = driveId;
        this.query = 'Select Id, sked_Drive_Date__c, Average_Staff_Capacity__c,  Excess_Staff_Capacity__c, sked_Staff_Capacity__c, sked_Projected_Registered_Donors__c from sked_Drive__c where sked_Drive_Date__c >= Today AND sked_Status__c Not IN (\'Cancel\',\'Complete\') AND (sked_Operation_Type__c = \'Non Integrated WB\' or sked_Type_of_Drive__c = \'Mobile\') AND Id IN: driveId';
    }

    public AverageStaffCapAndExcesSCCorrectionBatch(Date toDate, Date fromDate){
        this.toDate = toDate;
        this.fromDate = fromDate;
        
        this.query = 'Select Id, sked_Drive_Date__c, Average_Staff_Capacity__c,  Excess_Staff_Capacity__c, sked_Staff_Capacity__c, sked_Projected_Registered_Donors__c from sked_Drive__c where sked_Drive_Date__c >= :toDate AND sked_Drive_Date__c <= :fromDate AND sked_Drive_Date__c >= Today AND sked_Status__c Not IN (\'Cancel\',\'Complete\') AND (sked_Operation_Type__c = \'Non Integrated WB\' or sked_Type_of_Drive__c = \'Mobile\')';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {   
        return Database.getQueryLocator(this.query);        
    }
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> driveList){
        Set<Id> toGetDriveAgain = new Set<Id>();
        
        for(sked_Drive__c drive : driveList){
            toGetDriveAgain.add(drive.Id);
        }
        
        List<sked_Drive_Shift__c> driveShiftList = [Select Id, sked_Staff_Setup__c, sked_APT_Setup__c, sked_Drive__c, sked_Drive_Date__c, sked_Drive__r.Average_Staff_Capacity__c, sked_Drive__r.Excess_Staff_Capacity__c, sked_Drive__r.sked_Staff_Capacity__c, sked_Drive__r.sked_Projected_Registered_Donors__c from sked_Drive_Shift__c where sked_Drive__c IN: toGetDriveAgain];

        Map<Id,List<sked_Drive_Shift__c>> driveIdVsDriveShiftListMap = new Map<Id, List<sked_Drive_Shift__c>>();
        Set<Id> driveShiftIdSet = new Set<Id>();
        List<sked_Drive__c> driveToUpdate = new List<sked_Drive__c>();
        Boolean isUpdate = false;
        Set<String> staffQuantityNeededFor = new Set<String>{'Driver', 'Driver Support', '2RBC', 'VP/HH', 'Charge'};

        for(sked_Drive_Shift__c driveShift : driveShiftList){
            driveShiftIdSet.add(driveShift.Id);
            if(!driveIdVsDriveShiftListMap.containskey(driveShift.sked_Drive__c)){
                driveIdVsDriveShiftListMap.put(driveShift.sked_Drive__c, new List<sked_Drive_Shift__c>());
            }
            driveIdVsDriveShiftListMap.get(driveShift.sked_Drive__c).add(driveShift);
        }

        List<sked__Job__c> jobs = [SELECT Id, sked_Resource_Role__c, sked__Quantity__c, sked_VPHH_Quantity__c, sked_Drive_Shift__c FROM sked__Job__c where sked_Drive_Shift__c IN : driveShiftIdSet AND sked_Resource_Role__c IN: staffQuantityNeededFor];
        
        Map<Id,List<sked__Job__c>> driveShiftIdVsJobsListMap = new Map<Id, List<sked__Job__c>>();

        for(sked__Job__c job : jobs){
            if(!driveShiftIdVsJobsListMap.containskey(job.sked_Drive_Shift__c)){
                driveShiftIdVsJobsListMap.put(job.sked_Drive_Shift__c, new List<sked__Job__c>());
            }
            driveShiftIdVsJobsListMap.get(job.sked_Drive_Shift__c).add(job);
        }

        for(Id driveId : driveIdVsDriveShiftListMap.keySet()){
            isUpdate = false;
            Decimal curruntAverageStaffCapacity = 0;
            Decimal curruntExcessStaffCapacity = 0;
            Decimal updatedAverageStaffCapacity = 0;
            Decimal updatedExcessStaffCapacity = 0;
            Decimal driveStaffCapacity = 0;
            Decimal totalStaffRequested = 0;
            Decimal projectedRegisteredDonors = 0;
            if(driveIdVsDriveShiftListMap.get(driveId) != NULL){
                for(sked_Drive_Shift__c driveShift : driveIdVsDriveShiftListMap.get(driveId)){
                    driveStaffCapacity = driveShift.sked_Drive__r.sked_Staff_Capacity__c;
                    curruntAverageStaffCapacity = driveShift.sked_Drive__r.Average_Staff_Capacity__c;
                    curruntExcessStaffCapacity = driveShift.sked_Drive__r.Excess_Staff_Capacity__c;
                    projectedRegisteredDonors = driveShift.sked_Drive__r.sked_Projected_Registered_Donors__c;
                    Decimal driveShiftStaffCount = 0;
                    if(driveShiftIdVsJobsListMap.get(driveShift.Id) != NULL){
                        for(sked__Job__c job : driveShiftIdVsJobsListMap.get(driveShift.Id)){
                            if (!string.isBlank(job.sked_Resource_Role__c) && (staffQuantityNeededFor.contains(job.sked_Resource_Role__c))) {
                                if (job.sked_Resource_Role__c == 'VP/HH') {
                                    driveShiftStaffCount += job.sked_VPHH_Quantity__c;
                                } else {
                                    driveShiftStaffCount += job.sked__Quantity__c;
                                }
                            }
                        }
                    }
                    
                    totalStaffRequested = totalStaffRequested + driveShiftStaffCount;
                }
            }
            

            updatedAverageStaffCapacity = (totalStaffRequested == NULL || totalStaffRequested == 0) ? 0 : (driveStaffCapacity / totalStaffRequested).setScale(1, System.RoundingMode.HALF_UP);
            updatedExcessStaffCapacity = (updatedAverageStaffCapacity == NULL || updatedAverageStaffCapacity == 0) ? 0 : ((driveStaffCapacity - projectedRegisteredDonors) / updatedAverageStaffCapacity).setScale(1, System.RoundingMode.HALF_UP);
            sked_Drive__c drive = new sked_Drive__c();
            if(curruntAverageStaffCapacity != updatedAverageStaffCapacity){
                isUpdate = true;
                drive.Id = driveId;
                drive.Average_Staff_Capacity__c = updatedAverageStaffCapacity;
            }
            if(curruntExcessStaffCapacity != updatedExcessStaffCapacity){
                isUpdate = true;
                drive.Id = driveId;
                drive.Excess_Staff_Capacity__c = updatedExcessStaffCapacity;
            }
            if(isUpdate){
                driveToUpdate.add(drive);
                isUpdate = false;
            }
        }
        
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        if(driveToUpdate.size()>0){
            // datebase.update(driveToUpdate,false);
            Database.SaveResult[] driveToUpdateList = Database.update(driveToUpdate,false);
            errorList.addAll(BSF_Utilities.createErrorLog(driveToUpdateList,'AverageStaffCapAndExcesSCCorrectionBatch','AverageStaffCapAndExcesSCCorrectionBatch','execute','Error','Update Failed'));
        }
        
    }
    global void finish(Database.BatchableContext bc){
        
    }
}