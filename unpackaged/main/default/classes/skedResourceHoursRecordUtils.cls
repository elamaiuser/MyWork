public class skedResourceHoursRecordUtils {
    public static void syncToResourceHoursRecord(List<sked__Job_Allocation__c> newRecords) {
        Map<string, jobAllocationModel> mapUniqueKey_Allocations = buildMapKey_AllocationModels(newRecords);
        
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = [SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
                                                                    FROM sked_Resource_Hours_Record__c
                                                                    WHERE sked_Unique_Key__c IN :mapUniqueKey_Allocations.keySet()
                                                                    ORDER BY sked_Unique_Key__c ASC];
        for (jobAllocationModel model : mapUniqueKey_Allocations.values()) {
            model.hasKey = FALSE;
            for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                    for (sked__Job_Allocation__c jobAllocation : model.jobAllocations) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = resourceHoursRecord.Id, 
                            sked_Job_Allocation__c = jobAllocation.Id,
                            sked_Job_Allocation_Status__c = jobAllocation.sked__Status__c,
                            sked_Duration__c = jobAllocation.sked_Duration_with_Travel_Time__c,
                            sked_Job__c = jobAllocation.sked__Job__c
                        );
                        model.resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                    }
                    model.hasKey = TRUE;
                    break;
                }
            }

            if (!model.hasKey) {
                sked_Resource_Hours_Record__c resourceHoursRecord = new sked_Resource_Hours_Record__c(
                    sked_End_Date__c = model.endDate, 
                    sked_Resource__c = model.resourceId, 
                    sked_Start_Date__c = model.startDate, 
                    sked_Unique_Key__c = model.key
                );
                model.resourceHoursRecord = resourceHoursRecord;
            }
        }

        List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
        for (jobAllocationModel model : mapUniqueKey_Allocations.values()) {
            if (!model.hasKey) {
                newResourceHoursRecords.add(model.resourceHoursRecord);
            }
        }
        insert newResourceHoursRecords;

        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        for (jobAllocationModel model : mapUniqueKey_Allocations.values()) {
            if (!model.hasKey) {
                for (sked__Job_Allocation__c jobAllocation : model.jobAllocations) {
                    sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                        sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                        sked_Job_Allocation__c = jobAllocation.Id,
                        sked_Job_Allocation_Status__c = jobAllocation.sked__Status__c,
                        sked_Duration__c = jobAllocation.sked_Duration_with_Travel_Time__c,
                        sked_Job__c = jobAllocation.sked__Job__c
                    );
                    resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                }
            }
            else {
                resourceHoursRecordDetails.addAll(model.resourceHoursRecordDetails);
            }
        }
        insert resourceHoursRecordDetails;
    }
    public static Map<string, jobAllocationModel> buildMapKey_AllocationModels(List<sked__Job_Allocation__c> newRecords) {
        List<string> excludedStatuses = new List<string>();
        excludedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);
        excludedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);
        Map<string, jobAllocationModel> mapUniqueKey_Allocations = new Map<string, jobAllocationModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Job_Allocation__c newRecord : newRecords) {
            if (!excludedStatuses.contains(newRecord.sked__Status__c)) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date jobDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked_Job_Timezone__c);
                Date startOfWeek = skedDateTimeUtils.findWeekStartDate(jobDate, workWeekday); 
                Date endOfWeek = startOfWeek.addDays(6);
                string key = buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                if (mapUniqueKey_Allocations.containsKey(key)) {
                    jobAllocationModel model = mapUniqueKey_Allocations.get(key);
                    model.jobAllocations.add(newRecord);
                }
                else {
                    jobAllocationModel model = new jobAllocationModel();
                    model.resourceId = newRecord.sked__Resource__c;
                    model.startDate = startOfWeek;
                    model.endDate = endOfWeek;
                    model.key = key;
                    model.jobAllocations = new List<sked__Job_Allocation__c>();
                    model.jobAllocations.add(newRecord);
                    mapUniqueKey_Allocations.put(model.key, model);
                }
            }
        }
        return mapUniqueKey_Allocations;
    }
    public static Map<Id, string> getMapRecord_WorkWeekday(List<sked__Job_Allocation__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Job_Allocation__c> jobAllocations = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                                        FROM sked__Job_Allocation__c
                                                        WHERE Id IN :newRecords];
        for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(jobAllocation.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = jobAllocation.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(jobAllocation.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }
    
    public static void syncToResourceHoursRecord(List<sked__Availability__c> newRecords) {
        Map<string, availabilityModel> mapUniqueKey_Availabilities = buildMapKey_AvailabilityModels(newRecords);
        
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = [SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
                                                                    FROM sked_Resource_Hours_Record__c
                                                                    WHERE sked_Unique_Key__c IN :mapUniqueKey_Availabilities.keySet()
                                                                    ORDER BY sked_Unique_Key__c ASC];
        for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
            model.hasKey = FALSE;
            for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                    for (sked__Availability__c availability : model.availabilities) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = resourceHoursRecord.Id, 
                            sked_Availability__c = availability.Id,
                            sked_Duration__c = availability.sked_Duration__c
                        );
                        model.resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                    }
                    model.hasKey = TRUE;
                    break;
                }
            }

            if (!model.hasKey) {
                sked_Resource_Hours_Record__c resourceHoursRecord = new sked_Resource_Hours_Record__c(
                    sked_End_Date__c = model.endDate, 
                    sked_Resource__c = model.resourceId, 
                    sked_Start_Date__c = model.startDate, 
                    sked_Unique_Key__c = model.key
                );
                model.resourceHoursRecord = resourceHoursRecord;
            }
        }

        List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
        for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
            if (!model.hasKey) {
                newResourceHoursRecords.add(model.resourceHoursRecord);
            }
        }
        insert newResourceHoursRecords;

        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
            if (!model.hasKey) {
                for (sked__Availability__c availability : model.availabilities) {
                    sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                        sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                        sked_Availability__c = availability.Id,
                        sked_Duration__c = availability.sked_Duration__c
                    );
                    resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                }
            }
            else {
                resourceHoursRecordDetails.addAll(model.resourceHoursRecordDetails);
            }
        }
        insert resourceHoursRecordDetails;
    }
    public static Map<string, availabilityModel> buildMapKey_AvailabilityModels(List<sked__Availability__c> newRecords) {
        Map<string, availabilityModel> mapUniqueKey_Availabilities = new Map<string, availabilityModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Availability__c newRecord : newRecords) {
            if (newRecord.sked__Is_Available__c == FALSE && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date eventDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked__Timezone__c);
                Date startOfWeek = skedDateTimeUtils.findWeekStartDate(eventDate, workWeekday);
                Date endOfWeek = startOfWeek.addDays(6);
                string key = buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                if (mapUniqueKey_Availabilities.containsKey(key)) {
                    availabilityModel model = mapUniqueKey_Availabilities.get(key);
                    model.availabilities.add(newRecord);
                }
                else {
                    availabilityModel model = new availabilityModel();
                    model.resourceId = newRecord.sked__Resource__c;
                    model.startDate = startOfWeek;
                    model.endDate = endOfWeek;
                    model.key = key;
                    model.availabilities = new List<sked__Availability__c>();
                    model.availabilities.add(newRecord);
                    mapUniqueKey_Availabilities.put(model.key, model);
                }
            }
        }
        return mapUniqueKey_Availabilities;
    }
    public static Map<Id, string> getMapRecord_WorkWeekday(List<sked__Availability__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Availability__c> availabilities = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                                      FROM sked__Availability__c
                                                      WHERE Id IN :newRecords];
        for (sked__Availability__c availability : availabilities) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(availability.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = availability.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(availability.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }
    
    public static void syncToResourceHoursRecord(List<sked__Activity__c> newRecords) {
        Map<string, activityModel> mapUniqueKey_Activities = buildMapKey_ActivityModels(newRecords);
        
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = [SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
                                                                    FROM sked_Resource_Hours_Record__c
                                                                    WHERE sked_Unique_Key__c IN :mapUniqueKey_Activities.keySet()
                                                                    ORDER BY sked_Unique_Key__c ASC];
        for (activityModel model : mapUniqueKey_Activities.values()) {
            model.hasKey = FALSE;
            for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                    for (sked__Activity__c activity : model.activities) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = resourceHoursRecord.Id, 
                            sked_Activity__c = activity.Id,
                            sked_Duration__c = activity.sked_Duration__c
                        );
                        model.resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                    }
                    model.hasKey = TRUE;
                    break;
                }
            }

            if (!model.hasKey) {
                sked_Resource_Hours_Record__c resourceHoursRecord = new sked_Resource_Hours_Record__c(
                    sked_End_Date__c = model.endDate, 
                    sked_Resource__c = model.resourceId, 
                    sked_Start_Date__c = model.startDate, 
                    sked_Unique_Key__c = model.key
                );
                model.resourceHoursRecord = resourceHoursRecord;
            }
        }

        List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
        for (activityModel model : mapUniqueKey_Activities.values()) {
            if (!model.hasKey) {
                newResourceHoursRecords.add(model.resourceHoursRecord);
            }
        }
        insert newResourceHoursRecords;

        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        for (activityModel model : mapUniqueKey_Activities.values()) {
            if (!model.hasKey) {
                for (sked__Activity__c activity : model.activities) {
                    sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                        sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                        sked_Activity__c = activity.Id,
                        sked_Duration__c = activity.sked_Duration__c
                    );
                    resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                }
            }
            else {
                resourceHoursRecordDetails.addAll(model.resourceHoursRecordDetails);
            }
        }
        insert resourceHoursRecordDetails;
    }
    public static Map<string, activityModel> buildMapKey_ActivityModels(List<sked__Activity__c> newRecords) {
        Map<string, activityModel> mapUniqueKey_Activities = new Map<string, activityModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Activity__c newRecord : newRecords) {
            if (newRecord.sked_Is_Group_Activity__c == FALSE && string.isNotBlank(newRecord.sked__Resource__c)) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date activityDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked__Timezone__c);
                Date startOfWeek = skedDateTimeUtils.findWeekStartDate(activityDate, workWeekday);
                Date endOfWeek = startOfWeek.addDays(6);
                string key = buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                if (mapUniqueKey_Activities.containsKey(key)) {
                    activityModel model = mapUniqueKey_Activities.get(key);
                    model.activities.add(newRecord);
                }
                else {
                    activityModel model = new activityModel();
                    model.resourceId = newRecord.sked__Resource__c;
                    model.startDate = startOfWeek;
                    model.endDate = endOfWeek;
                    model.key = key;
                    model.activities = new List<sked__Activity__c>();
                    model.activities.add(newRecord);
                    mapUniqueKey_Activities.put(model.key, model);
                }
            }
        }
        return mapUniqueKey_Activities;
    }
    public static Map<Id, string> getMapRecord_WorkWeekday(List<sked__Activity__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Activity__c> activities = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                              FROM sked__Activity__c
                                              WHERE Id IN :newRecords];
        for (sked__Activity__c activity : activities) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(activity.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = activity.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(activity.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }

    public static void syncToResourceHoursRecord(List<sked__Activity_Resource__c> newRecords) {
        Map<string, activityResourceModel> mapUniqueKey_ActivityResources = buildMapKey_ActivityResourceModels(newRecords);
        
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = [SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
                                                                    FROM sked_Resource_Hours_Record__c
                                                                    WHERE sked_Unique_Key__c IN :mapUniqueKey_ActivityResources.keySet()
                                                                    ORDER BY sked_Unique_Key__c ASC];
        for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
            model.hasKey = FALSE;
            for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                    for (sked__Activity_Resource__c activityResource : model.activityResources) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = resourceHoursRecord.Id, 
                            sked_Activity_Resource__c = activityResource.Id,
                            sked_Duration__c = activityResource.sked_Duration__c
                        );
                        model.resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                    }
                    model.hasKey = TRUE;
                    break;
                }
            }

            if (!model.hasKey) {
                sked_Resource_Hours_Record__c resourceHoursRecord = new sked_Resource_Hours_Record__c(
                    sked_End_Date__c = model.endDate, 
                    sked_Resource__c = model.resourceId, 
                    sked_Start_Date__c = model.startDate, 
                    sked_Unique_Key__c = model.key
                );
                model.resourceHoursRecord = resourceHoursRecord;
            }
        }

        List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
        for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
            if (!model.hasKey) {
                newResourceHoursRecords.add(model.resourceHoursRecord);
            }
        }
        insert newResourceHoursRecords;

        List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        for (activityResourceModel model : mapUniqueKey_ActivityResources.values()) {
            if (!model.hasKey) {
                for (sked__Activity_Resource__c activityResource : model.activityResources) {
                    sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                        sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                        sked_Activity_Resource__c = activityResource.Id,
                        sked_Duration__c = activityResource.sked_Duration__c
                    );
                    resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                }
            }
            else {
                resourceHoursRecordDetails.addAll(model.resourceHoursRecordDetails);
            }
        }
        insert resourceHoursRecordDetails;
    }
    public static Map<string, activityResourceModel> buildMapKey_ActivityResourceModels(List<sked__Activity_Resource__c> newRecords) {
        Map<string, activityResourceModel> mapUniqueKey_ActivityResources = new Map<string, activityResourceModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Activity_Resource__c newRecord : newRecords) {
            string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
            Date eventDate = skedDateTimeUtils.getDate(newRecord.sked_Start1__c, newRecord.sked_Timezone__c);
            Date startOfWeek = skedDateTimeUtils.findWeekStartDate(eventDate, workWeekday);
            Date endOfWeek = startOfWeek.addDays(6);
            string key = buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
            if (mapUniqueKey_ActivityResources.containsKey(key)) {
                activityResourceModel model = mapUniqueKey_ActivityResources.get(key);
                model.activityResources.add(newRecord);
            }
            else {
                activityResourceModel model = new activityResourceModel();
                model.resourceId = newRecord.sked__Resource__c;
                model.startDate = startOfWeek;
                model.endDate = endOfWeek;
                model.key = key;
                model.activityResources = new List<sked__Activity_Resource__c>();
                model.activityResources.add(newRecord);
                mapUniqueKey_ActivityResources.put(model.key, model);
            }
        }
        return mapUniqueKey_ActivityResources;
    }
    public static Map<Id, string> getMapRecord_WorkWeekday(List<sked__Activity_Resource__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Activity_Resource__c> activityResources = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                                              FROM sked__Activity_Resource__c
                                                              WHERE Id IN :newRecords];
        for (sked__Activity_Resource__c activityResource : activityResources) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(activityResource.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = activityResource.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(activityResource.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }

    public static void countTotalWorkingDays(List<Id> resourceHoursRecordIds) {
        Map<Id, List<sked__Activity__c>> map_resourceHoursRecordId_activities = new Map<Id, List<sked__Activity__c>>();
        Map<Id, List<sked__Activity_Resource__c>> map_resourceHoursRecordId_activityResources = new Map<Id, List<sked__Activity_Resource__c>>();
        Map<Id, List<sked__Availability__c>> map_resourceHoursRecordId_availabilities = new Map<Id, List<sked__Availability__c>>();
        Map<Id, List<sked__Job_Allocation__c>> map_resourceHoursRecordId_jobAllocations = new Map<Id, List<sked__Job_Allocation__c>>();
        prepareMappingFromResourceHoursRecordIdToEvents(
            resourceHoursRecordIds,
            map_resourceHoursRecordId_activities,
            map_resourceHoursRecordId_activityResources,
            map_resourceHoursRecordId_availabilities,
            map_resourceHoursRecordId_jobAllocations
        );

        List<sked_Resource_Hours_Record__c> resourceHoursRecordsToUpdate = new List<sked_Resource_Hours_Record__c>();
        for (Id resourceHoursRecordId : resourceHoursRecordIds) {
            resourceHoursRecordsToUpdate.add(new sked_Resource_Hours_Record__c(
                Id = resourceHoursRecordId,
                sked_Total_Working_Days__c = calculateTotalWorkingDays(
                    map_resourceHoursRecordId_activities.get(resourceHoursRecordId),
                    map_resourceHoursRecordId_activityResources.get(resourceHoursRecordId),
                    map_resourceHoursRecordId_availabilities.get(resourceHoursRecordId),
                    map_resourceHoursRecordId_jobAllocations.get(resourceHoursRecordId)
                )
            ));
        }

        update resourceHoursRecordsToUpdate;
    }

    public static void captureWorkDaysException(List<Id> resourceHoursRecordIds) {
        List<string> uniqueKeys = new List<string>();
        List<sked_Resource_Hours_Record__c> resourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
        prepareDataBeforeValidatingWorkDaysException(resourceHoursRecordIds, uniqueKeys, resourceHoursRecords);

        Map<String, sked_Exception_Setting__c> map_exceptionCode_exceptionSetting = getMinMaxWorkDaysExceptionSetting();
        Map<String, skedHC__Exception__c> map_uniqueKey_existingExceptionLog = getExistingOpenExceptionLog(uniqueKeys);

        List<skedHC__Exception__c> newExceptionLogs = new List<skedHC__Exception__c>();
        List<skedHC__Exception__c> exceptionLogsToUpdate = new List<skedHC__Exception__c>();
        for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {       
            validateWorkingDaysToCaptureNewOrResolveExistingExceptionLog(
                resourceHoursRecord,
                map_uniqueKey_existingExceptionLog,
                newExceptionLogs,
                exceptionLogsToUpdate,
                map_exceptionCode_exceptionSetting,
                skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION
            );
            validateWorkingDaysToCaptureNewOrResolveExistingExceptionLog(
                resourceHoursRecord,
                map_uniqueKey_existingExceptionLog,
                newExceptionLogs,
                exceptionLogsToUpdate,
                map_exceptionCode_exceptionSetting,
                skedConstants.EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION
            );
        }
            
        if (!newExceptionLogs.isEmpty()) {
            insert newExceptionLogs;
        }
        if (!exceptionLogsToUpdate.isEmpty()) {
            update exceptionLogsToUpdate;
        }
    }

    public static string buildResourceHoursRecordUniqueKey(String resourceId, Date startOfWeek, Date endOfWeek) {
        string key = resourceId;
        string startMonthText = (startOfWeek.month() < 10 ? '0' : '') + startOfWeek.month();
        string startDayText = (startOfWeek.day() < 10 ? '0' : '') + startOfWeek.day();
        string endMonthText = (endOfWeek.month() < 10 ? '0' : '') + endOfWeek.month();
        string endDayText = (endOfWeek.day() < 10 ? '0' : '') + endOfWeek.day();
        key += ':' + startOfWeek.year() + startMonthText + startDayText;
        key += ':' + endOfWeek.year() + endMonthText + endDayText;
        return key;
    }

    /*********************************************************** Privated Methods ***********************************************************/

    private static void prepareMappingFromResourceHoursRecordIdToEvents(
        List<Id> resourceHoursRecordIds,
        Map<Id, List<sked__Activity__c>> map_resourceHoursRecordId_activities,
        Map<Id, List<sked__Activity_Resource__c>> map_resourceHoursRecordId_activityResources,
        Map<Id, List<sked__Availability__c>> map_resourceHoursRecordId_availabilities,
        Map<Id, List<sked__Job_Allocation__c>> map_resourceHoursRecordId_jobAllocations
    ) {
        for (sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail : [
            SELECT
                sked_Resource_Hours_Record__c,
                sked_Activity__r.sked_Start_Date__c, sked_Activity__r.sked_End_Date__c,
                sked_Activity_Resource__r.sked_Start_Date__c, sked_Activity_Resource__r.sked_End_Date__c,
                sked_Availability__r.sked_Start_Date__c, sked_Availability__r.sked_Finish_Date__c,
                sked_Job_Allocation__r.sked_Start_Date__c, sked_Job_Allocation__r.sked_Set_End_Date__c
            FROM sked_Resource_Hours_Record_Detail__c
            WHERE sked_Resource_Hours_Record__c IN :resourceHoursRecordIds
            AND (
                (sked_Availability__c != NULL AND sked_Availability__r.sked__Type__c IN ('PTO', 'Floating Holiday')) OR
                (sked_Activity__c != NULL AND sked_Activity__r.sked__Type__c NOT IN ('On Call', 'After Hours Call Out Management')) OR
                (sked_Activity_Resource__c != NULL AND sked_Activity_Resource__r.sked__Activity__r.sked__Type__c NOT IN ('On Call', 'After Hours Call Out Management')) OR
                sked_Job_Allocation__c != NULL
            )
        ]) {
            if (resourceHoursRecordDetail.sked_Availability__r != NULL) {
                if (!map_resourceHoursRecordId_availabilities.containsKey(resourceHoursRecordDetail.sked_Resource_Hours_Record__c)) {
                    map_resourceHoursRecordId_availabilities.put(resourceHoursRecordDetail.sked_Resource_Hours_Record__c, new List<sked__Availability__c>());
                }
                map_resourceHoursRecordId_availabilities.get(resourceHoursRecordDetail.sked_Resource_Hours_Record__c).add(resourceHoursRecordDetail.sked_Availability__r);
            }
            else if (resourceHoursRecordDetail.sked_Activity__r != NULL) {
                if (!map_resourceHoursRecordId_activities.containsKey(resourceHoursRecordDetail.sked_Resource_Hours_Record__c)) {
                    map_resourceHoursRecordId_activities.put(resourceHoursRecordDetail.sked_Resource_Hours_Record__c, new List<sked__Activity__c>());
                }
                map_resourceHoursRecordId_activities.get(resourceHoursRecordDetail.sked_Resource_Hours_Record__c).add(resourceHoursRecordDetail.sked_Activity__r);
            }
            else if (resourceHoursRecordDetail.sked_Activity_Resource__r != NULL) {
                if (!map_resourceHoursRecordId_activityResources.containsKey(resourceHoursRecordDetail.sked_Resource_Hours_Record__c)) {
                    map_resourceHoursRecordId_activityResources.put(resourceHoursRecordDetail.sked_Resource_Hours_Record__c, new List<sked__Activity_Resource__c>());
                }
                map_resourceHoursRecordId_activityResources.get(resourceHoursRecordDetail.sked_Resource_Hours_Record__c).add(resourceHoursRecordDetail.sked_Activity_Resource__r);
            }
            else if (resourceHoursRecordDetail.sked_Job_Allocation__r != NULL) {
                if (!map_resourceHoursRecordId_jobAllocations.containsKey(resourceHoursRecordDetail.sked_Resource_Hours_Record__c)) {
                    map_resourceHoursRecordId_jobAllocations.put(resourceHoursRecordDetail.sked_Resource_Hours_Record__c, new List<sked__Job_Allocation__c>());
                }
                map_resourceHoursRecordId_jobAllocations.get(resourceHoursRecordDetail.sked_Resource_Hours_Record__c).add(resourceHoursRecordDetail.sked_Job_Allocation__r);
            }
        }
    }

    private static Integer calculateTotalWorkingDays(
        List<sked__Activity__c> activities,
        List<sked__Activity_Resource__c> activityResources,
        List<sked__Availability__c> availabilities,
        List<sked__Job_Allocation__c> jobAllocations
    ) {
        Set<Date> workingDays = new Set<Date>();
        workingDays.addAll(getWorkingDaysFromEvents(activities, 'sked_Start_Date__c', 'sked_End_Date__c'));
        workingDays.addAll(getWorkingDaysFromEvents(activityResources, 'sked_Start_Date__c', 'sked_End_Date__c'));
        workingDays.addAll(getWorkingDaysFromEvents(availabilities, 'sked_Start_Date__c', 'sked_Finish_Date__c'));
        workingDays.addAll(getWorkingDaysFromEvents(jobAllocations, 'sked_Start_Date__c', 'sked_Set_End_Date__c'));
        return workingDays.size();
    }

    private static Set<Date> getWorkingDaysFromEvents(List<SObject> events, String startDateFieldName, String endDateFieldName) {
        Set<Date> workingDays = new Set<Date>();

        if (events != null) {
            for (SObject event : events) {
                Date startDate = (Date)event.get(startDateFieldName);
                Date endDate = (Date)event.get(endDateFieldName);
                while (startDate <= endDate) {
                    workingDays.add(startDate);
                    startDate = startDate.addDays(1);
                }
            }
        }

        return workingDays;
    }

    private static void prepareDataBeforeValidatingWorkDaysException(
        List<Id> resourceHoursRecordIds,
        List<string> uniqueKeys,
        List<sked_Resource_Hours_Record__c> resourceHoursRecords
    ) {
        for (sked_Resource_Hours_Record__c resourceHoursRecord : [
            SELECT Id, sked_Total_Working_Days__c, sked_Start_Date__c,
                sked_Resource__r.sked_Max_Working_Days_Per_Week__c, sked_Resource__r.sked_Min_Working_Days_Per_Week__c
            FROM sked_Resource_Hours_Record__c
            WHERE Id IN :resourceHoursRecordIds
            AND sked_Resource__r.sked__Resource_Type__c = :skedConstants.RESOURCE_TYPE_PERSON
        ]) {
            uniqueKeys.add(String.format('{0}:{1}', new List<String>{resourceHoursRecord.Id, skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION}));
            uniqueKeys.add(String.format('{0}:{1}', new List<String>{resourceHoursRecord.Id, skedConstants.EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION}));
            resourceHoursRecords.add(resourceHoursRecord);
        }
    }

    private static Map<String, sked_Exception_Setting__c> getMinMaxWorkDaysExceptionSetting() {
        Map<String, sked_Exception_Setting__c> map_exceptionCode_exceptionSetting = new Map<String, sked_Exception_Setting__c>();
        List<String> minMaxWorkDaysExceptionCodes = new List<String>{
            skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION,
            skedConstants.EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION
        };
        for (sked_Exception_Setting__c exceptionSetting : [
            SELECT Id, sked_Exception_Code__c, sked_Exception__c
            FROM sked_Exception_Setting__c
            WHERE sked_Exception_Code__c IN :minMaxWorkDaysExceptionCodes
        ]) {
            map_exceptionCode_exceptionSetting.put(exceptionSetting.sked_Exception_Code__c, exceptionSetting);
        }
        return map_exceptionCode_exceptionSetting;
    }

    private static Map<String, skedHC__Exception__c> getExistingOpenExceptionLog(List<string> uniqueKeys) {
        Map<String, skedHC__Exception__c> map_uniqueKey_existingExceptionLog = new Map<String, skedHC__Exception__c>();
        for (skedHC__Exception__c exceptionLog : [
            SELECT Id, sked_UniqueKey__c, skedHC__Status__c
            FROM skedHC__Exception__c
            WHERE sked_UniqueKey__c IN :uniqueKeys
            AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN
        ]) {
            map_uniqueKey_existingExceptionLog.put(exceptionLog.sked_UniqueKey__c, exceptionLog);
        }
        return map_uniqueKey_existingExceptionLog;
    }

    private static void validateWorkingDaysToCaptureNewOrResolveExistingExceptionLog(
        sked_Resource_Hours_Record__c resourceHoursRecord,
        Map<String, skedHC__Exception__c> map_uniqueKey_existingExceptionLog,
        List<skedHC__Exception__c> newExceptionLogs,
        List<skedHC__Exception__c> exceptionLogsToUpdate,
        Map<String, sked_Exception_Setting__c> map_exceptionCode_exceptionSetting,
        String exceptionCode
    ) {
        String uniqueKey = resourceHoursRecord.Id + ':' + exceptionCode;
        String exceptionTemplate = map_exceptionCode_exceptionSetting.containsKey(exceptionCode) ? 
                map_exceptionCode_exceptionSetting.get(exceptionCode).sked_Exception__c : skedConstants.MAP_EXCEPTION_CODE_TO_DEFAULT_EXCEPTION_MESSAGE.get(exceptionCode);
        Integer resourceMaxWorkDaysPerWeek = resourceHoursRecord.sked_Resource__r.sked_Max_Working_Days_Per_Week__c == null ? null : Integer.valueOf(resourceHoursRecord.sked_Resource__r.sked_Max_Working_Days_Per_Week__c);
        Integer resourceMinWorkDaysPerWeek = resourceHoursRecord.sked_Resource__r.sked_Min_Working_Days_Per_Week__c == null ? null : Integer.valueOf(resourceHoursRecord.sked_Resource__r.sked_Min_Working_Days_Per_Week__c);
        Boolean isWorkDaysViolated = exceptionCode == skedConstants.EXCEPTION_CODE_MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION ?
                resourceMaxWorkDaysPerWeek != null && resourceHoursRecord.sked_Total_Working_Days__c > resourceMaxWorkDaysPerWeek :
                resourceMinWorkDaysPerWeek != null && resourceHoursRecord.sked_Total_Working_Days__c < resourceMinWorkDaysPerWeek;
        if (isWorkDaysViolated && !map_uniqueKey_existingExceptionLog.containsKey(uniqueKey)) {
            Date weekStartDate = resourceHoursRecord.sked_Start_Date__c;
            DateTime weekStartDateDt = DateTime.newInstance(weekStartDate, Time.newInstance(0, 0, 0, 0));
            string weekStartDateStr = weekStartDateDt.format(skedDateTimeUtils.DATE_FORMAT);
            string exceptionMsg = exceptionTemplate.replace('{{weekStartDate}}', weekStartDateStr);

            skedHC__Exception__c newException = new skedHC__Exception__c(
                sked_Resource_Hours_Record__c = resourceHoursRecord.Id,
                skedHC__Resource__c = resourceHoursRecord.sked_Resource__r.Id,
                skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
                skedHC__Exception__c = exceptionMsg,
                sked_Exception_Code__c = exceptionCode
            );
            newExceptionLogs.add(newException);
        } else if (!isWorkDaysViolated && map_uniqueKey_existingExceptionLog.containsKey(uniqueKey)) {
            skedHC__Exception__c existingException = map_uniqueKey_existingExceptionLog.get(uniqueKey);
            existingException.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
            exceptionLogsToUpdate.add(existingException);
        }
    }
    
	//========= Nested class ======//
    public class jobAllocationModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Job_Allocation__c> jobAllocations;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public jobAllocationModel() {
            jobAllocations = new List<sked__Job_Allocation__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }
    
    public class availabilityModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Availability__c> availabilities;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public availabilityModel() {
            availabilities = new List<sked__Availability__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }
    
    public class activityModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Activity__c> activities;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public activityModel() {
            activities = new List<sked__Activity__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }

    public class activityResourceModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Activity_Resource__c> activityResources;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public activityResourceModel() {
            activityResources = new List<sked__Activity_Resource__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }
}