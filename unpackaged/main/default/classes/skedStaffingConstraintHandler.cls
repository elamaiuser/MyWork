public class skedStaffingConstraintHandler extends skedTriggerHub {
	
    public override void onAfterUpdate() {
        onConstraintIncreased(this.context.newRecords, (Map<Id, sked_Staffing_Constraint__c>)this.context.oldMap);
        onConstraintDecreased(this.context.newRecords, (Map<Id, sked_Staffing_Constraint__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onConstraintIncreased(List<sked_Staffing_Constraint__c> newRecords, Map<Id, sked_Staffing_Constraint__c> oldMap) {
        List<sked_Staffing_Constraint__c> increasedRecords = new List<sked_Staffing_Constraint__c>();
        for (sked_Staffing_Constraint__c newRecord : newRecords) {
            sked_Staffing_Constraint__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Total_Staff_Constraints__c != oldData.sked_Total_Staff_Constraints__c) {
                decimal newConstraints = newRecord.sked_Total_Staff_Constraints__c != NULL ? newRecord.sked_Total_Staff_Constraints__c : 0;
                decimal oldConstraints = oldData.sked_Total_Staff_Constraints__c != NULL ? oldData.sked_Total_Staff_Constraints__c : 0;
                if (newConstraints > oldConstraints) {
                    increasedRecords.add(newRecord);
                }
            }
        }
        if (!increasedRecords.isEmpty()) {
            resolveException(increasedRecords);
        }
    }
    
    private void onConstraintDecreased(List<sked_Staffing_Constraint__c> newRecords, Map<Id, sked_Staffing_Constraint__c> oldMap) {
        List<sked_Staffing_Constraint__c> decreasedRecords = new List<sked_Staffing_Constraint__c>();
        for (sked_Staffing_Constraint__c newRecord : newRecords) {
            sked_Staffing_Constraint__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Total_Staff_Constraints__c != oldData.sked_Total_Staff_Constraints__c) {
                decimal newConstraints = newRecord.sked_Total_Staff_Constraints__c != NULL ? newRecord.sked_Total_Staff_Constraints__c : 0;
                decimal oldConstraints = oldData.sked_Total_Staff_Constraints__c != NULL ? oldData.sked_Total_Staff_Constraints__c : 0;
                if (newConstraints < oldConstraints) {
                    decreasedRecords.add(newRecord);
                }
            }
        }
        if (!decreasedRecords.isEmpty()) {
            updateDecreasedIndicator(decreasedRecords);
            captureException(decreasedRecords);
        }
    }
    
    private void updateDecreasedIndicator(List<sked_Staffing_Constraint__c> decreasedRecords) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Date> constraintDates = new Set<Date>();
        for (sked_Staffing_Constraint__c decreasedRecord : decreasedRecords) {
            collectionOperationIds.add(decreasedRecord.sked_Collection_Operation__c);
            constraintDates.add(decreasedRecord.sked_Date_of_Constraint__c);
        }
        Set<string> driveStatuses = new Set<string>();
        driveStatuses.add(skedConstants.DRIVE_STATUS_CONFIRMED);
        driveStatuses.add(skedConstants.DRIVE_STATUS_HOLD);
        
        Map<string, decimal> map_driveKey_staffRequested = new Map<string, decimal>();
        List<AggregateResult> driveSumResults = [SELECT sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c,
                                                 SUM(sked_Total_Staff_Requested__c) totalStaffRequested
                                                 FROM sked_Drive__c 
                                                 WHERE sked_Collection_Operation__c IN :collectionOperationIds
                                                 AND sked_Drive_Date__c IN :constraintDates
                                                 AND sked_Status__c IN :driveStatuses
                                                 GROUP BY sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c
                                                 ORDER BY sked_Drive_Date__c ASC];
        for (AggregateResult sumResult : driveSumResults) {
            string collectionOperationId = (string)sumResult.get('sked_Collection_Operation__c');
            string driveDate = Json.serialize((Date)sumResult.get('sked_Drive_Date__c')).replace('"', '');
            string driveType = (string)sumResult.get('sked_Type_of_Drive__c');
            decimal totalStaffRequested = (decimal)sumResult.get('totalStaffRequested');
            totalStaffRequested = totalStaffRequested == NULL ? 0 : totalStaffRequested;
            string key = collectionOperationId + ':' + driveDate + ':' + driveType;
            map_driveKey_staffRequested.put(key, totalStaffRequested);
        }
        
        Map<string, decimal> map_nceKey_staffRequested = new Map<string, decimal>();
        List<sked__Activity__c> nces = [SELECT Id, sked__Start__c, sked__Timezone__c, sked_Region__r.sked_Biomed_Collection_Op_Center__c, 
                                        sked_Fixed_Site_Staff_Quantity__c, sked_Mobile_Staff_Quantity__c 
                                        FROM sked__Activity__c
                                        WHERE sked_Is_Group_Activity__c = TRUE
                                        AND sked_Start_Date__c IN :constraintDates
                                        AND sked_Fixed_Site_Staff_Quantity__c != NULL
                                        AND sked_Mobile_Staff_Quantity__c != NULL
                                        AND sked_Region__r.sked_Biomed_Collection_Op_Center__c IN :collectionOperationIds];
        string userTimezoneSidId = UserInfo.getTimeZone().getID();
        for (sked__Activity__c nce : nces) {
            string timezoneSidId = nce.sked__Timezone__c != NULL ? nce.sked__Timezone__c : userTimezoneSidId;
            string collectionOperationId = nce.sked_Region__r.sked_Biomed_Collection_Op_Center__c;
            string nceDate = nce.sked__Start__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, userTimezoneSidId);
            string fixedSiteKey = collectionOperationId + ':' + nceDate + ':Fixed Site';
            string mobileKey = collectionOperationId + ':' + nceDate + ':Mobile';
            
            decimal totalFixedSiteStaffRequested = 0;
            if (map_nceKey_staffRequested.containsKey(fixedSiteKey)) {
                totalFixedSiteStaffRequested = map_nceKey_staffRequested.get(fixedSiteKey);
            }
            map_nceKey_staffRequested.put(fixedSiteKey, totalFixedSiteStaffRequested + nce.sked_Fixed_Site_Staff_Quantity__c);
            
            decimal totalMobileStaffRequested = 0;
            if (map_nceKey_staffRequested.containsKey(mobileKey)) {
                totalMobileStaffRequested = map_nceKey_staffRequested.get(mobileKey);
            }
            map_nceKey_staffRequested.put(mobileKey, totalMobileStaffRequested + nce.sked_Mobile_Staff_Quantity__c);
        }
        
        List<sked_Staffing_Constraint__c> recordsToUpdate = new List<sked_Staffing_Constraint__c>();
        for (sked_Staffing_Constraint__c decreasedRecord : decreasedRecords) {
            string key = decreasedRecord.sked_Collection_Operation__c + ':' 
                + Json.serialize(decreasedRecord.sked_Date_of_Constraint__c).replace('"', '') + ':'
                + decreasedRecord.sked_Drive_Type__c;
            decimal driveStaffRequested = 0;
            if (map_driveKey_staffRequested.containsKey(key)) {
                driveStaffRequested = map_driveKey_staffRequested.get(key);
            }
            
            decimal nceStaffRequested = 0;
            if (map_nceKey_staffRequested.containsKey(key)) {
                nceStaffRequested = map_nceKey_staffRequested.get(key);
            }
            
            decimal totalStaffRequested = driveStaffRequested + nceStaffRequested;
            
            if (decreasedRecord.sked_Total_Staff_Constraints__c < totalStaffRequested) {
                sked_Staffing_Constraint__c recordToUpdate = new sked_Staffing_Constraint__c(
                    Id = decreasedRecord.Id,
                    sked_Decrease_Indicator__c = TRUE
                );
                recordsToUpdate.add(recordToUpdate);
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
    
    private void captureException(List<sked_Staffing_Constraint__c> decreasedRecords) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Date> constraintDates = new Set<Date>();
        for (sked_Staffing_Constraint__c decreasedRecord : decreasedRecords) {
            collectionOperationIds.add(decreasedRecord.sked_Collection_Operation__c);
            constraintDates.add(decreasedRecord.sked_Date_of_Constraint__c);
        }
        
        Map<string, List<sked_Drive__c>> map_driveKey_drives = new Map<string, List<sked_Drive__c>>();
        List<sked_Drive__c> skedDrives = [SELECT sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_Total_Staff_Requested__c
                                          FROM sked_Drive__c 
                                          WHERE sked_Collection_Operation__c IN :collectionOperationIds
                                          AND sked_Drive_Date__c IN :constraintDates
                                          AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL];
        
        Set<Id> impactedDriveIds = new Set<Id>();
        for (sked_Drive__c skedDrive : skedDrives) {
            impactedDriveIds.add(skedDrive.Id);
            
            string collectionOperationId = skedDrive.sked_Collection_Operation__c;
            string driveDate = Json.serialize(skedDrive.sked_Drive_Date__c).replace('"', '');
            string driveType = skedDrive.sked_Type_of_Drive__c;
            string key = collectionOperationId + ':' + driveDate + ':' + driveType;
            List<sked_Drive__c> drivesByKey;
            if (map_driveKey_drives.containsKey(key)) {
                drivesByKey = map_driveKey_drives.get(key);
            }
            else {
                drivesByKey = new List<sked_Drive__c>();
                map_driveKey_drives.put(key, drivesByKey);
            }
            drivesByKey.add(skedDrive);
        }
        
        Map<string, List<sked__Activity__c>> map_activityKey_activities = new Map<string, List<sked__Activity__c>>();
        List<sked__Activity__c> skedActivities = [SELECT Id, sked__Quantity__c, sked_Fixed_Site_Staff_Quantity__c,
                                                  sked_Mobile_Staff_Quantity__c, sked_Start_Date__c, sked_Region__r.sked_Biomed_Collection_Op_Center__c
                                                  FROM sked__Activity__c
                                                  WHERE sked_Is_Group_Activity__c = TRUE
                                                  AND sked_Start_Date__c IN :constraintDates
                                                  AND sked_Region__r.sked_Biomed_Collection_Op_Center__c = :collectionOperationIds];
        for (sked__Activity__c skedActivity : skedActivities) {
            string collectionOperationId = skedActivity.sked_Region__r.sked_Biomed_Collection_Op_Center__c;
            string activityDate = Json.serialize(skedActivity.sked_Start_Date__c).replace('"', '');
            string key = collectionOperationId + ':' + activityDate;
            List<sked__Activity__c> activitiesByKey;
            if (map_activityKey_activities.containsKey(key)) {
                activitiesByKey = map_activityKey_activities.get(key);
            }
            else {
                activitiesByKey = new List<sked__Activity__c>();
                map_activityKey_activities.put(key, activitiesByKey);
            }
            activitiesByKey.add(skedActivity);
        }
        
        List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
        for (sked_Staffing_Constraint__c decreasedRecord : decreasedRecords) {
            string collectionOperationId = decreasedRecord.sked_Collection_Operation__c;
            string dateConstraint = Json.serialize(decreasedRecord.sked_Date_of_Constraint__c).replace('"', '');
            string driveType = decreasedRecord.sked_Drive_Type__c;
            string driveKey = collectionOperationId + ':' + dateConstraint + ':' + driveType;
            string activityKey = collectionOperationId + ':' + dateConstraint;
            
            if (map_driveKey_drives.containsKey(driveKey)) {
                List<sked_Drive__c> impactedDrives = map_driveKey_drives.get(driveKey);
                decimal totalStaffRequested = 0;
                
                for (sked_Drive__c impactedDrive : impactedDrives) {
                    decimal staffRequested = impactedDrive.sked_Total_Staff_Requested__c != NULL ? impactedDrive.sked_Total_Staff_Requested__c : 0;
                    totalStaffRequested += staffRequested;
                }
				
                if (map_activityKey_activities.containsKey(activityKey)) {
                    List<sked__Activity__c> impactedActivities = map_activityKey_activities.get(activityKey);
                    for (sked__Activity__c impactedActivity : impactedActivities) {
                        decimal staffRequested = decreasedRecord.sked_Drive_Type__c == 'Mobile' ? impactedActivity.sked_Mobile_Staff_Quantity__c : impactedActivity.sked_Fixed_Site_Staff_Quantity__c;
                        staffRequested = staffRequested != NULL ? staffRequested : 0;
                        totalStaffRequested += staffRequested;
                    }
                }
                if (decreasedRecord.sked_Total_Staff_Constraints__c < totalStaffRequested) {
                    List<skedHC__Exception__c> existingException = [SELECT Id,sked_Drive__c
                                                                    FROM skedHC__Exception__c
                                                                    WHERE sked_Drive__c IN :impactedDriveIds
                                                                    AND sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_STAFFING_CONSTRAINT_CHANGED
                                                                    AND skedHC__Status__c != :skedConstants.EXCEPTION_LOG_STATUS_CLOSED];
                    Set<Id> driveIdsHasException = new Set<Id>();
                    for (skedHC__Exception__c existingExceptionItem : existingException) {
                        driveIdsHasException.add(existingExceptionItem.sked_Drive__c);
                    }
                    for (sked_Drive__c impactedDrive : impactedDrives) {
                        if (!driveIdsHasException.contains(impactedDrive.Id)) {
                            skedHC__Exception__c newException = new skedHC__Exception__c(
                                sked_Drive__c = impactedDrive.Id,
                                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_STAFFING_CONSTRAINT_CHANGED
                            );
                            exceptionLog.add(newException);
                        }
                    }
                    if (!exceptionLog.isEmpty()) {
                        upsert exceptionLog;
                    }
                }
            }
        }
    }
    
    private void resolveException(List<sked_Staffing_Constraint__c> increasedRecords) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Date> constraintDates = new Set<Date>();
        for (sked_Staffing_Constraint__c increasedRecord : increasedRecords) {
            collectionOperationIds.add(increasedRecord.sked_Collection_Operation__c);
            constraintDates.add(increasedRecord.sked_Date_of_Constraint__c);
        }
        
        Map<string, List<sked_Drive__c>> map_driveKey_drives = new Map<string, List<sked_Drive__c>>();
        List<sked_Drive__c> skedDrives = [SELECT sked_Collection_Operation__c, sked_Drive_Date__c, sked_Type_of_Drive__c, sked_Total_Staff_Requested__c
                                          FROM sked_Drive__c 
                                          WHERE sked_Collection_Operation__c IN :collectionOperationIds
                                          AND sked_Drive_Date__c IN :constraintDates
                                          AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL];
        for (sked_Drive__c skedDrive : skedDrives) {
            string collectionOperationId = skedDrive.sked_Collection_Operation__c;
            string driveDate = Json.serialize(skedDrive.sked_Drive_Date__c).replace('"', '');
            string driveType = skedDrive.sked_Type_of_Drive__c;
            string key = collectionOperationId + ':' + driveDate + ':' + driveType;
            List<sked_Drive__c> drivesByKey;
            if (map_driveKey_drives.containsKey(key)) {
                drivesByKey = map_driveKey_drives.get(key);
            }
            else {
                drivesByKey = new List<sked_Drive__c>();
                map_driveKey_drives.put(key, drivesByKey);
            }
            drivesByKey.add(skedDrive);
        }
        
        Map<string, List<sked__Activity__c>> map_activityKey_activities = new Map<string, List<sked__Activity__c>>();
        List<sked__Activity__c> skedActivities = [SELECT Id, sked__Quantity__c, sked_Fixed_Site_Staff_Quantity__c,
                                                  sked_Mobile_Staff_Quantity__c, sked_Start_Date__c, sked_Region__r.sked_Biomed_Collection_Op_Center__c
                                                  FROM sked__Activity__c
                                                  WHERE sked_Is_Group_Activity__c = TRUE
                                                  AND sked_Start_Date__c IN :constraintDates
                                                  AND sked_Region__r.sked_Biomed_Collection_Op_Center__c = :collectionOperationIds];
        for (sked__Activity__c skedActivity : skedActivities) {
            string collectionOperationId = skedActivity.sked_Region__r.sked_Biomed_Collection_Op_Center__c;
            string activityDate = Json.serialize(skedActivity.sked_Start_Date__c).replace('"', '');
            string key = collectionOperationId + ':' + activityDate;
            List<sked__Activity__c> activitiesByKey;
            if (map_activityKey_activities.containsKey(key)) {
                activitiesByKey = map_activityKey_activities.get(key);
            }
            else {
                activitiesByKey = new List<sked__Activity__c>();
                map_activityKey_activities.put(key, activitiesByKey);
            }
            activitiesByKey.add(skedActivity);
        }
        
        Set<Id> driveIdsToResolve = new Set<Id>();
        for (sked_Staffing_Constraint__c increasedRecord : increasedRecords) {
            string collectionOperationId = increasedRecord.sked_Collection_Operation__c;
            string dateConstraint = Json.serialize(increasedRecord.sked_Date_of_Constraint__c).replace('"', '');
            string driveType = increasedRecord.sked_Drive_Type__c;
            string driveKey = collectionOperationId + ':' + dateConstraint + ':' + driveType;
            string activityKey = collectionOperationId + ':' + dateConstraint;
            
            if (map_driveKey_drives.containsKey(driveKey)) {
                List<sked_Drive__c> impactedDrives = map_driveKey_drives.get(driveKey);
                decimal totalStaffRequested = 0;
                
                for (sked_Drive__c impactedDrive : impactedDrives) {
                    decimal staffRequested = impactedDrive.sked_Total_Staff_Requested__c != NULL ? impactedDrive.sked_Total_Staff_Requested__c : 0;
                    totalStaffRequested += staffRequested;
                }
				
                if (map_activityKey_activities.containsKey(activityKey)) {
                    List<sked__Activity__c> impactedActivities = map_activityKey_activities.get(activityKey);
                    for (sked__Activity__c impactedActivity : impactedActivities) {
                        decimal staffRequested = increasedRecord.sked_Drive_Type__c == 'Mobile' ? impactedActivity.sked_Mobile_Staff_Quantity__c : impactedActivity.sked_Fixed_Site_Staff_Quantity__c;
                        staffRequested = staffRequested != NULL ? staffRequested : 0;
                        totalStaffRequested += staffRequested;
                    }
                }
                
                if (totalStaffRequested < increasedRecord.sked_Total_Staff_Constraints__c) {
                    for (sked_Drive__c impactedDrive : impactedDrives) {
                        driveIdsToResolve.add(impactedDrive.Id);
                    }
                }
            }
        }
        if (!driveIdsToResolve.isEmpty()) {
            List<skedHC__Exception__c> exceptionLog = [SELECT Id, skedHC__Status__c
                                                       FROM skedHC__Exception__c
                                                       WHERE sked_Drive__c IN :driveIdsToResolve
                                                       AND sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_STAFFING_CONSTRAINT_CHANGED
                                                       AND skedHC__Status__c != :skedConstants.EXCEPTION_LOG_STATUS_CLOSED];
            if (!exceptionLog.isEmpty()) {
                for (skedHC__Exception__c exceptionItem : exceptionLog) {
                    exceptionItem.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                }
                update exceptionLog;
            }
        }
    }
    
}