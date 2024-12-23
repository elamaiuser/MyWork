public class DriveResourceAllocationRetrySchedulable implements Schedulable {
    
    private Date driveDateToEval;
    
    public DriveResourceAllocationRetrySchedulable(Date cbRetryDate) {
        this.driveDateToEval = cbRetryDate;
    }
    
    public DriveResourceAllocationRetrySchedulable() {
        Calendar_Build_Setting__mdt cbMetadata = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Decimal daysAfterDriveCompletion = cbMetadata?.No_of_Days_for_Calendar_Build_Batch__c;
        Date cbRecentRunDate = BSF_Constants.CURRENT_DATE.addDays(-daysAfterDriveCompletion.intValue()); 
        DateTime dt = Helper.getSameDayOfNextYear(cbRecentRunDate);
        this.driveDateToEval = Date.newInstance(dT.year(), dT.month(), dT.day());
    }
    
    public void execute(SchedulableContext context) {
        List<Calendar_Build_Log__c> currentCbLog = [SELECT Id, Drive_Date__c, External_Id__c 
                                                      FROM Calendar_Build_Log__c
                                                      WHERE External_Id__c = :driveDateToEval.format()
                                                      AND CB_Batch_Status__c = 'Completed'
                                                      AND Drive_Gen_Batch_Status__c = 'Completed'
                                                      AND FS_Sys_Gen_Batch_Run_Status__c = 'Pending'
                                                      ORDER BY LastModifiedDate DESC
                                                   ];
        if(currentCbLog != NULL && !currentCbLog.isEmpty()) {
        	Database.executeBatch(new DriveResourceAllocationBatch ('Scheduled', 'Calendar Build', 'Fixed Site', this.driveDateToEval, new set<Id>()), 1);
        }
    }
}