public class skedRoleTimeVarianceHandler extends skedTriggerHub {

    public override void onBeforeInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            validateVarianceType(this.context.newRecords);
        }
    }
    
    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	captureExceptionLog(this.context.newRecords);
            updateRelatedJobs(skedRoleTimeVarianceUtils.getAdjustmentsToAddBufferForRelatedJobs(this.context.newRecords));
        }
    }

    public override void onBeforeUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            validateVarianceType(this.context.newRecords);
        }
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	captureExceptionLog(this.context.newRecords);
            updateRelatedJobs(skedRoleTimeVarianceUtils.getAdjustmentsToModifyBufferForRelatedJobs(this.context.newRecords, (Map<Id, sked_Role_Time_Variance__c>)this.context.oldMap));
        }
    }
    
    public override void onAfterDelete() {
        if (!skedSetting.instance.Admin.migrationMode) {
        	captureExceptionLog(((Map<Id, sked_Role_Time_Variance__c>)this.context.oldMap).values());
            updateRelatedJobs(skedRoleTimeVarianceUtils.getAdjustmentsToRemoveBufferForRelatedJobs(((Map<Id, sked_Role_Time_Variance__c>)this.context.oldMap).values()));
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void captureExceptionLog(List<sked_Role_Time_Variance__c> newRecords) {
        Set<Id> locationIds = new Set<Id>();
        for (sked_Role_Time_Variance__c newRecord : newRecords) {
            locationIds.add(newRecord.sked_Location__c);   
        }
        
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        List<sked_Drive__c> impactedDrives = new List<sked_Drive__c>();
        //Pick only drives with drive dates that fall under rtv impact date ranges
        for(sked_Role_Time_Variance__c newRecord : newRecords){
            List<Integer> daysOfWeek =  getDaysInWeek(newRecord.sked_Days_Of_Week__c);
            List<sked_Drive__c> impactedDrivesListForThisVariance = [SELECT Id  FROM sked_Drive__c
                                                  WHERE sked_Drive_Site__c = :newRecord.sked_Location__c
                                                  AND sked_Drive_Date__c >= TODAY
                                                  AND sked_Drive_Date__c >= :newRecord.sked_Effective_Start_Date__c
                                                  AND sked_Drive_Date__c <= :newRecord.sked_Effective_End_Date__c
                                                  AND DAY_IN_WEEK(sked_Drive_Date__c) in :daysOfWeek];
            impactedDrives.addAll(impactedDrivesListForThisVariance);                                 

        }
        /*List<sked_Drive__c> impactedDrives = [SELECT Id
                                              FROM sked_Drive__c
                                              WHERE sked_Drive_Site__c IN :locationIds
                                              AND sked_Drive_Date__c >= TODAY
                                              ];*/
        for (sked_Drive__c impactedDrive : impactedDrives) {
            skedHC__Exception__c newException = new skedHC__Exception__c(
                sked_Drive__c = impactedDrive.Id,
                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_ROLE_TIME_VARIANCE_CHANGED
            );
            exceptionLog.add(newException);
        }
        if (!exceptionLog.isEmpty()) {
            insert exceptionLog;
        }
    }
    //This method takes Strings seperated by; which can have values of Sunday thru Saturday and returns corresponding number. eg: 1 for Sunday
    //Since this is mandatory field (sked_Days_Of_Week__c) on RTV object, atleast one value will be present
    private static List<Integer> getDaysInWeek(String daysOfweek){
         // Map to convert day names to corresponding integer values
         Map<String, Integer> dayMap = new Map<String, Integer>{
            'Sunday' => 1,
            'Monday' => 2,
            'Tuesday' => 3,
            'Wednesday' => 4,
            'Thursday' => 5,
            'Friday' => 6,
            'Saturday' => 7
        };

        // List to store resulting integers
        List<Integer> daysOfWeekNumbers = new List<Integer>();

        // Split the string by ';' and iterate through each value
        for (String day : daysOfweek.split(';')) {
            day = day.trim();  // Trim whitespace
            if (dayMap.containsKey(day)) {
                daysOfWeekNumbers.add(dayMap.get(day));
            }
        }

        return daysOfWeekNumbers;
    }
    
        
        

    private void validateVarianceType(List<sked_Role_Time_Variance__c> newRecords) {
        for (sked_Role_Time_Variance__c newRecord : newRecords) {
            if (newRecord.sked_Variation_Type__c == 'Imported from Hemasphere') {
                newRecord.addError('Imported from Hemasphere is only available for migration.');
            }
        }
    }

    private void updateRelatedJobs(List<skedRoleTimeVarianceAdjustment> rtvAdjustments) {
        if (!Test.isRunningTest() && !System.isBatch() && !rtvAdjustments.isEmpty()) {
            Database.executeBatch(new skedUpdateJobTimeVarianceBatch(rtvAdjustments), 100);
        }
    }
}