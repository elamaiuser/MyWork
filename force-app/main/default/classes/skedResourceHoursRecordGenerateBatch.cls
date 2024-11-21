global class skedResourceHoursRecordGenerateBatch implements System.Schedulable, Database.Batchable<sObject> {

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedResourceHoursRecordGenerateBatch(), 200);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c, sked_Min_Working_Days_Per_Week__c
            FROM sked__Resource__c
            WHERE sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
            AND sked_Employment_Status__c != :skedConstants.RESOURCE_EMPLOYMENT_STATUS_INACTIVE
        ]);
    }

    global void execute(Database.BatchableContext BC, List<sked__Resource__c> resources) {
        Map<Id, sked__Resource__c> map_resourceId_resource = new Map<Id, sked__Resource__c>();
        for (sked__Resource__c resource : resources) {
            map_resourceId_resource.put(resource.Id, resource);
        }
        // get resource hours records for each resource overlap with TODAY
        Date today = System.today();
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = [
            SELECT Id, sked_Resource__c, sked_Start_Date__c, sked_End_Date__c, sked_Unique_Key__c
            FROM sked_Resource_Hours_Record__c
            WHERE sked_Resource__c IN :resources
            AND sked_End_Date__c >= :today
        ];
        Map<String, List<sked__Resource__c>> map_workFirstWeekDay_resources = getMap_workFirstWeekDay_resources(resources);
        Map<String, List<String>> map_resourceId_resourceHoursRecordUniqueKeys = getMap_resourceId_resourceHoursRecordUniqueKeys(resourceHoursRecords);
        List<sked_Resource_Hours_Record__c> resourceHoursRecordsToInsert = generateResourceHoursRecords(
            map_workFirstWeekDay_resources,
            map_resourceId_resourceHoursRecordUniqueKeys
        );
        if (resourceHoursRecordsToInsert.size() > 0) {
            insert resourceHoursRecordsToInsert;
        }

        List<skedHC__Exception__c> exceptionLogsToInsert = generateExceptionLogsForCreatedResourceHoursRecords(resourceHoursRecordsToInsert, map_resourceId_resource);
        if (exceptionLogsToInsert.size() > 0) {
            insert exceptionLogsToInsert;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    //------------------------------------------------Private methods----------------------------------------------------//
    private Map<String, List<sked__Resource__c>> getMap_workFirstWeekDay_resources(List<sked__Resource__c> resources) {
        Map<String, List<sked__Resource__c>> map_workFirstWeekDay_resources = new Map<String, List<sked__Resource__c>>();
        for (sked__Resource__c resource : resources) {
            String workFirstWeekDay = 'Sunday';
            if (resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c != null) {
                workFirstWeekDay = resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }

            if (!map_workFirstWeekDay_resources.containsKey(workFirstWeekDay)) {
                map_workFirstWeekDay_resources.put(workFirstWeekDay, new List<sked__Resource__c>());
            }

            map_workFirstWeekDay_resources.get(workFirstWeekDay).add(resource);
        }

        return map_workFirstWeekDay_resources;
    }

    private Map<String, List<String>> getMap_resourceId_resourceHoursRecordUniqueKeys(List<sked_Resource_Hours_Record__c> resourceHoursRecords) {
        Map<String, List<String>> map_resourceId_resourceHoursRecordUniqueKeys = new Map<String, List<String>>();
        for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
            if (!map_resourceId_resourceHoursRecordUniqueKeys.containsKey(resourceHoursRecord.sked_Resource__c)) {
                map_resourceId_resourceHoursRecordUniqueKeys.put(resourceHoursRecord.sked_Resource__c, new List<String>());
            }

            map_resourceId_resourceHoursRecordUniqueKeys.get(resourceHoursRecord.sked_Resource__c).add(resourceHoursRecord.sked_Unique_Key__c);
        }

        return map_resourceId_resourceHoursRecordUniqueKeys;
    }

    private List<sked_Resource_Hours_Record__c> generateResourceHoursRecords(
        Map<String, List<sked__Resource__c>> map_workFirstWeekDay_resources,
        Map<String, List<String>> map_resourceId_resourceHoursRecordUniqueKeys
    ) {
        Date workDaysValidationEndDate = Date.today().addDays(skedSetting.instance.Admin.daysToValidateWorkDaysException);
        List<sked_Resource_Hours_Record__c> resourceHoursRecordsToInsert = new List<sked_Resource_Hours_Record__c>();
        for (String firstWorkDayOfWeek : map_workFirstWeekDay_resources.keySet()) {
            Date workStartDateOfWeek = skedDateTimeUtils.findWeekStartDate(Date.today(), firstWorkDayOfWeek);
            Date workEndDateOfWeek = workStartDateOfWeek.addDays(6);
            for (sked__Resource__c resource : map_workFirstWeekDay_resources.get(firstWorkDayOfWeek)) {
                Date currentWorkEndDateOfWeek = workEndDateOfWeek;
                Date currentWorkStartDateOfWeek = workStartDateOfWeek;
                while (currentWorkEndDateOfWeek <= workDaysValidationEndDate) {
                    String uniqueKey = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(resource.Id, currentWorkStartDateOfWeek, currentWorkEndDateOfWeek);
                    if (!map_resourceId_resourceHoursRecordUniqueKeys.containsKey(resource.Id) 
                        || !map_resourceId_resourceHoursRecordUniqueKeys.get(resource.Id).contains(uniqueKey)) {
                        resourceHoursRecordsToInsert.add(new sked_Resource_Hours_Record__c(
                            sked_Resource__c = resource.Id,
                            sked_Start_Date__c = currentWorkStartDateOfWeek,
                            sked_End_Date__c = currentWorkEndDateOfWeek,
                            sked_Unique_Key__c = uniqueKey,
                            sked_Total_Working_Days__c = 0
                        ));
                    }

                    currentWorkStartDateOfWeek = currentWorkEndDateOfWeek.addDays(1);
                    currentWorkEndDateOfWeek = currentWorkStartDateOfWeek.addDays(6);
                }
            }
        }

        return resourceHoursRecordsToInsert;
    }

    private List<skedHC__Exception__c> generateExceptionLogsForCreatedResourceHoursRecords(
        List<sked_Resource_Hours_Record__c> createdResourceHoursRecords,
        Map<Id, sked__Resource__c> map_resourceId_resource
    ) {
        List<sked_Exception_Setting__c> results = [SELECT sked_Exception__c FROM sked_Exception_Setting__c WHERE sked_Exception_Code__c = :skedConstants.EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION];
        String minWorksDayExceptionTemplate = results.size() > 0 ?
            results[0].sked_Exception__c : skedConstants.MAP_EXCEPTION_CODE_TO_DEFAULT_EXCEPTION_MESSAGE.get(skedConstants.EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION);
        List<skedHC__Exception__c> exceptionLogsToInsert = new List<skedHC__Exception__c>();
        for (sked_Resource_Hours_Record__c resourceHoursRecord : createdResourceHoursRecords) {
            sked__Resource__c resource = map_resourceId_resource.get(resourceHoursRecord.sked_Resource__c);
            if (resource != null && resource.sked_Min_Working_Days_Per_Week__c != null && resourceHoursRecord.sked_Total_Working_Days__c < Integer.valueOf(resource.sked_Min_Working_Days_Per_Week__c)
            ) {
                Date weekStartDate = resourceHoursRecord.sked_Start_Date__c;
                DateTime weekStartDateDt = DateTime.newInstance(weekStartDate, Time.newInstance(0, 0, 0, 0));
                string weekStartDateStr = weekStartDateDt.format(skedDateTimeUtils.DATE_FORMAT);
                string exceptionMsg = minWorksDayExceptionTemplate.replace('{{weekStartDate}}', weekStartDateStr);
    
                exceptionLogsToInsert.add(new skedHC__Exception__c(
                    sked_Resource_Hours_Record__c = resourceHoursRecord.Id,
                    skedHC__Resource__c = resourceHoursRecord.sked_Resource__c,
                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
                    skedHC__Exception__c = exceptionMsg,
                    sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION
                ));
            }
        }

        return exceptionLogsToInsert;
    }
}