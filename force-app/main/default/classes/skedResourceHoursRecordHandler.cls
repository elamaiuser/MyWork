public class skedResourceHoursRecordHandler extends skedTriggerHub {
    
    public override void onAfterUpdate() {
        onDurationChanged(this.context.newRecords, (Map<Id, sked_Resource_Hours_Record__c>)this.context.oldMap);
        captureWorkDaysException(this.context.newRecords, (Map<Id, sked_Resource_Hours_Record__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void onDurationChanged(List<sked_Resource_Hours_Record__c> newRecords, Map<Id, sked_Resource_Hours_Record__c> oldMap) {
        List<string> uniqueKeys = new List<string>();
        Map<Id, sked_Resource_Hours_Record__c> mapResourceHourByResourceId = new Map<Id, sked_Resource_Hours_Record__c>();
        for (sked_Resource_Hours_Record__c newRecord : newRecords) {
            sked_Resource_Hours_Record__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Total_Working_Time__c != oldData.sked_Total_Working_Time__c) {
                mapResourceHourByResourceId.put(newRecord.sked_Resource__c, newRecord);
            }
            
            string uniqueKey = newRecord.Id + ':' + skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_HOURS_VIOLATION;
            uniqueKeys.add(uniqueKey);
        }
        if (!mapResourceHourByResourceId.isEmpty()) {
            string exceptionTemplate = 'Maximum weekly hours violation. Week: {{weekStartDate}}';
            List<sked_Exception_Setting__c> exceptionSettingQuery = [SELECT Id, sked_Exception_Code__c, sked_Exception__c, sked_Priority__c
                                                                     FROM sked_Exception_Setting__c
                                                                     WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_HOURS_VIOLATION];
            if (!exceptionSettingQuery.isEmpty()) {
                exceptionTemplate = exceptionSettingQuery.get(0).sked_Exception__c;
            }
            
            List<skedHC__Exception__c> existingExceptionLog = [SELECT Id, sked_UniqueKey__c, skedHC__Status__c
                                                               FROM skedHC__Exception__c
                                                               WHERE sked_UniqueKey__c IN :uniqueKeys
                                                               AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN];
            Map<string, skedHC__Exception__c> mapExistingExceptionLog = new Map<string, skedHC__Exception__c>();
            for (skedHC__Exception__c existingException : existingExceptionLog) {
                mapExistingExceptionLog.put(existingException.sked_UniqueKey__c, existingException);
            }
            
            List<skedHC__Exception__c> newExceptionLog = new List<skedHC__Exception__c>();
            List<skedHC__Exception__c> exceptionLogToUpdate = new List<skedHC__Exception__c>();
            
            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked_Max_Hours_Per_Week__c
                                                                                     FROM sked__Resource__c
                                                                                     WHERE Id IN :mapResourceHourByResourceId.keySet()
                                                                                     AND sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON]);
            for (sked_Resource_Hours_Record__c resourceHoursRecord : mapResourceHourByResourceId.values()) {
                string uniqueKey = resourceHoursRecord.Id + ':' + skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_HOURS_VIOLATION;
                
                sked__Resource__c resource = mapResource.get(resourceHoursRecord.sked_Resource__c);
                if (resource != null) {
                    decimal resourceWorkingMinutesPerWeek = resource.sked_Max_Hours_Per_Week__c != NULL ? resource.sked_Max_Hours_Per_Week__c * 60 : 9999;
                    if (resourceHoursRecord.sked_Total_Working_Time__c > resourceWorkingMinutesPerWeek) {
                        if (!mapExistingExceptionLog.containsKey(uniqueKey)) {
                            Date weekStartDate = resourceHoursRecord.sked_Start_Date__c;
                            DateTime weekStartDateDt = DateTime.newInstance(weekStartDate, Time.newInstance(0, 0, 0, 0));
                            string weekStartDateStr = weekStartDateDt.format(skedDateTimeUtils.DATE_FORMAT);
                            string exceptionMsg = exceptionTemplate.replace('{{weekStartDate}}', weekStartDateStr);
                            
                            skedHC__Exception__c newException = new skedHC__Exception__c(
                                sked_Resource_Hours_Record__c = resourceHoursRecord.Id,
                                skedHC__Resource__c = resource.Id,
                                skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
                                skedHC__Exception__c = exceptionMsg,
                                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_HOURS_VIOLATION
                            );
                            newExceptionLog.add(newException);
                        }
                    }
                    else {
                        if (mapExistingExceptionLog.containsKey(uniqueKey)) {
                            skedHC__Exception__c existingException = mapExistingExceptionLog.get(uniqueKey);
                            existingException.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                            exceptionLogToUpdate.add(existingException);
                        }
                    }
                }
            }
            
            if (!newExceptionLog.isEmpty()) {
                insert newExceptionLog;
            }
            if (!exceptionLogToUpdate.isEmpty()) {
                update exceptionLogToUpdate;
            }
        }
    }
    
    private void captureWorkDaysException(List<sked_Resource_Hours_Record__c> newRecords, Map<Id, sked_Resource_Hours_Record__c> oldMap) {
        List<Id> resourceHoursRecordIdsToProcess = new List<Id>();
        for (sked_Resource_Hours_Record__c newRecord : newRecords) {
            sked_Resource_Hours_Record__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Total_Working_Days__c != oldData.sked_Total_Working_Days__c) {
                resourceHoursRecordIdsToProcess.add(newRecord.Id);
            }
        }

        if (resourceHoursRecordIdsToProcess.size() > 0) {
            skedResourceHoursRecordUtils.captureWorkDaysException(resourceHoursRecordIdsToProcess);
        }
    }
}