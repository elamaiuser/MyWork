global class BSF_Batch_DriveStatusCorrection implements Schedulable, Database.Batchable<sObject>{
	private Integer batchSize;
    private DateTime targetDriveDate;
    private DateTime presetDate;
    private List<String> statusList = new List<String>{'Confirmed','Complete','Cancel'}; 
	global BSF_Batch_DriveStatusCorrection(){
		Calendar_Build_Setting__mdt cbMetadata = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numberOfDays = Integer.valueOf(cbMetadata?.No_of_Days_for_Status_Correction_Batch__c);
        this.batchSize = Integer.valueOf(cbMetadata?.Batch_Size_for_Status_Correction_Batch__c);
        if (numberOfDays != null) {
            this.targetDriveDate = system.now().addDays(-numberOfDays);
        } else {
            this.targetDriveDate = system.now().addDays(-18);
        }
        this.presetDate = DateTime.newInstance(2023, 1, 30);
	}
    global BSF_Batch_DriveStatusCorrection(Date manualRunDate, Date manualPresetDate){
		if (manualRunDate != null && manualPresetDate != null) {
            this.targetDriveDate = DateTime.newInstance(manualRunDate.year(),manualRunDate.month(),manualRunDate.day());
            this.presetDate = DateTime.newInstance(manualPresetDate.year(),manualPresetDate.month(),manualPresetDate.day());
        }
	}
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator('SELECT Id, sked_Status__c, sked_Drive_Date__c, sked_Type_of_Drive__c'+
                                        ' FROM sked_Drive__c WHERE'+
                                        ' sked_Drive_Date__c >= '+this.presetDate.format('yyyy-MM-dd')+
                                        ' AND sked_Drive_Date__c <= '+this.targetDriveDate.format('yyyy-MM-dd')+
                                        ' AND sked_Status__c NOT IN (\''+String.join(this.statusList, '\',\'')+'\')'+
                                        ' ORDER BY sked_Drive_Date__c ASC');
	}
	global void execute(Database.BatchableContext BC, List<sked_Drive__c> scope){
		List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        Map<Id, sked_Drive__c> driveMap = new Map<Id, sked_Drive__c>(scope);
        for(Id driveId : driveMap.keySet()){
            sked_Drive__c drive = new sked_Drive__c(Id = driveId);
            drive.sked_Status__c = 'Cancel';
            drive.sked_Cancellation_Reason__c = 'System Need';
            if(driveMap.get(driveId).sked_Type_of_Drive__c == 'Fixed Site'){
                drive.sked_Initiated_By__c = 'ARC Initiated-Fixed';
            }else{
                drive.sked_Initiated_By__c = 'ARC_Initiated_Mobile';
            }
            drivesToUpdate.add(drive);
        }
        if(!drivesToUpdate.isEmpty()){
            Database.saveResult[] drivesUpdateResultList = Database.update(drivesToUpdate,false);
            List<BSF_Error_Log__c> logListForDriveStatusUpdate = BSF_Utilities.createErrorLogWithObjectId(
                drivesUpdateResultList, 
                BSF_Constants.BATCH_DRIVE_STATUS_CORRECTION,
                'BSF_Batch_DriveStatusCorrection',
                'execute',
                'Error',
                'Error in Drive Status update to Cancel'
            );
            Database.SaveResult[] logResultList = Database.Insert(logListForDriveStatusUpdate, false);
        }
	}
	global void execute(SchedulableContext scon){
		Database.executeBatch(new BSF_Batch_DriveStatusCorrection(),batchSize);
	}
	global void finish(Database.BatchableContext BC){}
}