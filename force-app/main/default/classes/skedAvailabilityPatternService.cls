global class skedAvailabilityPatternService extends skedDataService {
	
    protected override void initialize() {
        this.sObjectApiName = 'sked__Availability_Pattern__c';
        this.objectType = 'availabilityPattern';
        this.domainType = Type.forName('skedModels.availabilityPattern');
    }
    
    protected override void doAdditionalMap(sObject sObj, skedModels.modelBase modelBase) {
        skedModels.availabilityPattern model = (skedModels.availabilityPattern)modelBase;
        sObj.put('sked__Pattern__c', Json.serialize(model.patternData));
    }
    
    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        
        if (query.includes(skedSObjectType.AVAILABILITY_PATTERN_RESOURCE)) {
            skedQueryBuilder patternResourceBuilder = query.getQueryBuilder('sked__Availability_Pattern_Resource__c');
            patternResourceBuilder.orderClause = 'ORDER BY sked__Resource__r.Name ASC';
        }
    }
    
    /*********************************************************** Public ***********************************************************/
    public override List<skedModels.modelBase> getList(skedDataService.queryModelBase inputQuery) {
        List<skedModels.availabilityPattern> availabilityPatterns = (List<skedModels.availabilityPattern>)super.getList(inputQuery);
        for (skedModels.availabilityPattern availabilityPattern : availabilityPatterns) {
            availabilityPattern.patternData = (skedAvailabilityPatternData)Json.deserialize(availabilityPattern.pattern, skedAvailabilityPatternData.class);
        }
        return availabilityPatterns;
    }
    
    public Map<Id, List<skedModels.event>> getPatternEvents(Set<Id> inputResourceIds, Set<Date> inputDates) {
        Map<Id, List<skedModels.event>> map_Resource_Events = new Map<Id, List<skedModels.event>>();
        
        Date minDate, maxDate;
        for (Date inputDate : inputDates) {
            if (minDate == NULL || minDate > inputDate) {
                minDate = inputDate;
            }
            if (maxDate == NULL || maxDate < inputDate) {
                maxDate = inputDate;
            }
        }
        DateTime startTime = skedDateTimeUtils.getStartOfDate(minDate, this.timezoneSidId);
        DateTime endTime = skedDateTimeUtils.getEndOfDate(maxDate, this.timezoneSidId);
        
        List<sked__Availability_Pattern_Resource__c> patternResources = [SELECT sked__Resource__c, 
                                                                         sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c,
                                                                         sked__Availability_Pattern__c, sked__Availability_Pattern__r.sked__Pattern__c,
                                                                         sked__Start__c, sked__End__c
                                                                         FROM sked__Availability_Pattern_Resource__c
                                                                         WHERE sked__Resource__c IN :inputResourceIds
                                                                         AND sked__Start__c < :endTime
                                                                         AND (sked__End__c = NULL OR sked__End__c > :startTime)];
        if (patternResources != NULL && !patternResources.isEmpty()) {
            for (sked__Availability_Pattern_Resource__c patternResource : patternResources) {
                List<skedModels.event> resourceEvents;
                if (map_Resource_Events.containsKey(patternResource.sked__Resource__c)) {
                    resourceEvents = map_Resource_Events.get(patternResource.sked__Resource__c);
                }
                else {
                    resourceEvents = new List<skedModels.event>();
                    map_Resource_Events.put(patternResource.sked__Resource__c, resourceEvents);
                }
                skedAvailabilityPatternData patternData = (skedAvailabilityPatternData)Json.deserialize(patternResource.sked__Availability_Pattern__r.sked__Pattern__c, skedAvailabilityPatternData.class);
                if (patternData.type == 'weekly') {
                    List<skedModels.event> patternEvents = getWeeklyPatternEvents(patternResource, patternData, inputDates);
                    resourceEvents.addAll(patternEvents);
                }
                else if (patternData.type == 'custom') {
                    List<skedModels.event> patternEvents = getCustomPatternEvents(patternResource, patternData, inputDates);
                    resourceEvents.addAll(patternEvents);
                }
            }
        }
        return map_Resource_Events;
    }
    
    private List<skedModels.event> getWeeklyPatternEvents(sked__Availability_Pattern_Resource__c patternResource, skedAvailabilityPatternData patternData, Set<Date> inputDates) {
        List<skedModels.event> patternEvents = new List<skedModels.event>();
        Map<string, skedAvailabilityPatternData.dayModel> mapWeekdayPattern = new Map<string, skedAvailabilityPatternData.dayModel>();
        for (skedAvailabilityPatternData.dayModel day : patternData.days) {
            mapWeekdayPattern.put(day.weekday.toLowerCase(), day);
        }
        
        Date startDate = skedDateTimeUtils.getDate(patternResource.sked__Start__c, this.timezoneSidId);
        Date endDate;
        string firstDayOfWeek = 'Sunday';
        if (patternResource.sked__Resource__r.sked__Primary_Region__r != NULL 
            && patternResource.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r != NULL
            && patternResource.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c != NULL) {
            firstDayOfWeek = patternResource.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
        }
        firstDayOfWeek = firstDayOfWeek.substring(0, 3).toLowerCase();
        
        Map<string, integer> mapWeekdayIndex = skedUtils.getMapWeekdayIndex(firstDayOfWeek);
        DateTime startDateDt = patternResource.sked__Start__c;
        string startDateWeekday = startDateDt.format('EEE', this.timezoneSidId).toLowerCase();
        integer startDateWeekdayIndex = mapWeekdayIndex.get(startDateWeekday);
        
        if (patternResource.sked__End__c != NULL) {
            endDate = skedDateTimeUtils.getDate(patternResource.sked__End__c, this.timezoneSidId);
        }
        for (Date inputDate : inputDates) {
            if (startDate <= inputDate && (endDate == NULL || inputDate <= endDate)) {
                DateTime inputDateDt = skedDateTimeUtils.getStartOfDate(inputDate, this.timezoneSidId);
                string weekday = inputDateDt.format('EEE', this.timezoneSidId).toLowerCase();
                
                if (mapWeekdayPattern.containsKey((weekday))) {
                    integer weekdayIndex = mapWeekdayIndex.get(weekday);
                    integer daysDifference = startDate.daysBetween(inputDate);
                    integer weekNo = ((daysDifference - (weekdayIndex - startDateWeekdayIndex)) / 7) + 1;
                    if (patternData.repeatWeeks == 1 || Math.mod(weekNo, patternData.repeatWeeks) == 1) {
                        if (mapWeekdayPattern.containsKey(weekday)) {
                            skedAvailabilityPatternData.dayModel day = mapWeekdayPattern.get(weekday);
                            List<skedModels.event> dayEvents = generateDayEvents(day, inputDateDt);
                            patternEvents.addAll(dayEvents);
                        }
                    }
                }
            }
        }
        return patternEvents;
    }
    
    private List<skedModels.event> getCustomPatternEvents(sked__Availability_Pattern_Resource__c patternResource, skedAvailabilityPatternData patternData, Set<Date> inputDates) {
        List<skedModels.event> patternEvents = new List<skedModels.event>();
        
        Map<integer, skedAvailabilityPatternData.dayModel> mapDayPattern = new Map<integer, skedAvailabilityPatternData.dayModel>();
        for (skedAvailabilityPatternData.dayModel day : patternData.days) {
            mapDayPattern.put(day.day, day);
        }
        
        Date startDate = skedDateTimeUtils.getDate(patternResource.sked__Start__c, this.timezoneSidId);
        Date endDate;
        
        if (patternResource.sked__End__c != NULL) {
            endDate = skedDateTimeUtils.getDate(patternResource.sked__End__c, this.timezoneSidId);
        }
        for (Date inputDate : inputDates) {
            if (startDate <= inputDate && (endDate == NULL || inputDate <= endDate)) {
                DateTime inputDateDt = skedDateTimeUtils.getStartOfDate(inputDate, this.timezoneSidId);
                integer daysDifference = startDate.daysBetween(inputDate);
                integer dayTh = patternData.lengthDays == 1 ? 1 : Math.mod(daysDifference, patternData.lengthDays) + 1;
                if (mapDayPattern.containsKey(dayTh)) {
                    skedAvailabilityPatternData.dayModel day = mapDayPattern.get(dayTh);
                    List<skedModels.event> dayEvents = generateDayEvents(day, inputDateDt);
                    patternEvents.addAll(dayEvents);
                }
            }
        }
        
        return patternEvents;
    }
    
    private List<skedModels.event> generateDayEvents(skedAvailabilityPatternData.dayModel day, DateTime inputDateDt) {
        List<skedModels.event> dayEvents = new List<skedModels.event>();
        if (day.intervals != NULL && !day.intervals.isEmpty()) {
            for (skedAvailabilityPatternData.intervalModel interval : day.intervals) {
                integer startWorkingInMinutes = skedDateTimeUtils.convertTimeStrToMinutes(interval.startTime);
                integer endWorkingInMinutes = skedDateTimeUtils.convertTimeStrToMinutes(interval.endTime);
                
                DateTime startWorkingTime = skedDateTimeUtils.addMinutes(inputDateDt, startWorkingInMinutes, this.timezoneSidId);
                DateTime endWorkingTime = skedDateTimeUtils.addMinutes(inputDateDt, endWorkingInMinutes == 0 ? 1440 : endWorkingInMinutes, this.timezoneSidId);
                
                skedModels.event event = new skedModels.event();
                event.objectType = 'availability';
                event.eventType = 'template';
                event.start = startWorkingTime;
                event.finish = endWorkingTime;
                event.startTimeInMinutes = startWorkingInMinutes;
                event.endTimeInMinutes = endWorkingInMinutes;
                event.updateDateTimeFields(this.timezoneSidId);
                dayEvents.add(event);
            }
        }
        return dayEvents;
    }
    
    public List<string> getResourceIds(queryModel query) {
        List<sked__Availability_Pattern__c> skedPatterns = (List<sked__Availability_Pattern__c>) query(query);
        List<string> resourceIds = new List<string>();
        for (sked__Availability_Pattern__c skedPattern : skedPatterns) {
            if (skedPattern.sked__Availability_Pattern_Resources__r != NULL && !skedPattern.sked__Availability_Pattern_Resources__r.isEmpty()) {
                for (sked__Availability_Pattern_Resource__c skedPatternResource : skedPattern.sked__Availability_Pattern_Resources__r) {
                    resourceIds.add(skedPatternResource.sked__Resource__c);
                }
            }
        }
        return resourceIds;
    }
    
    private void validatePreSave(skedModels.availabilityPattern model, skedDataService.saveResult saveResullt) {
        string errorMessage = '';
        
        List<sked__Availability_Pattern__c> existingPatterns = [
            SELECT Id, Name, sked__Pattern__c
            FROM sked__Availability_Pattern__c
            WHERE Id != :model.id
        ];
        
        boolean patternNameRuleValid = true;
        boolean patternDataRuleValid = true;
        
        skedAvailabilityPatternData modelPatternData = (skedAvailabilityPatternData)JSON.deserialize(model.pattern, skedAvailabilityPatternData.class);
        string modelPatternStr = JSON.serialize(modelPatternData.days);
        
        for (sked__Availability_Pattern__c existingPattern : existingPatterns) {
            if (patternNameRuleValid) {
                patternNameRuleValid = existingPattern.Name != model.name;
            }
            if (patternDataRuleValid) {
                if (existingPattern.sked__Pattern__c != NULL) {
                    skedAvailabilityPatternData existingPatternData = (skedAvailabilityPatternData)JSON.deserialize(existingPattern.sked__Pattern__c, skedAvailabilityPatternData.class);
                    string existingPatternStr = JSON.serialize(existingPatternData.days);
                    
                    patternDataRuleValid = existingPatternStr != modelPatternStr || modelPatternData.repeatWeeks != existingPatternData.repeatWeeks;
                }
            }
            if (!patternNameRuleValid && !patternDataRuleValid) {
                break;
            }
        }
        
        List<string> errorMessages = new List<string>();
        if (!patternNameRuleValid) {
            errorMessages.add('Availability Pattern Name already in use.');
        }
        if (!patternDataRuleValid) {
            errorMessages.add('Availability Pattern days and hours already in use.');
        }
        
        saveResullt.success = patternNameRuleValid && patternDataRuleValid;
        if (!errorMessages.isEmpty()) {
        	saveResullt.errorMessage = string.join(errorMessages, ' ');
        }
    }

    public void validateOverlappingPatternResources(skedModels.availabilityPattern model) {
        if (model.availabilityPatternResources != NULL && !model.availabilityPatternResources.isEmpty()) {
            Date maxDateValue = skedDateTimeUtils.MAX_DATE;
            string maxDateValueStr = skedDateTimeUtils.MAX_DATE_STR;
            
            Set<Id> resourceIds = new Set<Id>();
            string minDateStr, maxDateStr;

            for (skedModels.availabilityPatternResource patternResource : model.availabilityPatternResources) {
                resourceIds.add(patternResource.resourceId);
                
                string prEndDate = patternResource.endDate == NULL ? maxDateValueStr : patternResource.endDate;

                minDateStr = minDateStr == NULL || patternResource.startDate < minDateStr ? patternResource.startDate : minDateStr;
                maxDateStr = maxDateStr == NULL || prEndDate > maxDateStr ? prEndDate : maxDateStr;
            }

            Date minDate = skedDateTimeUtils.getDateFromIsoString(minDateStr);
            Date maxDate = maxDateStr == NULL ? maxDateValue : skedDateTimeUtils.getDateFromIsoString(maxDateStr);

            List<sked__Availability_Pattern_Resource__c> patternResources = [
                SELECT Id, sked__Resource__c, sked_Start_Date__c, sked_End_Date__c,
                sked__Availability_Pattern__r.Name
                FROM sked__Availability_Pattern_Resource__c
                WHERE sked__Resource__c IN :resourceIds
                AND sked_Start_Date__c <= :maxDate
                AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :minDate)
            ];
            
            Map<Id, List<sked__Availability_Pattern_Resource__c>> map_resourceId_patternResource = new Map<Id, List<sked__Availability_Pattern_Resource__c>>();
            
            for (sked__Availability_Pattern_Resource__c patternResource : patternResources) {
                if (!map_resourceId_patternResource.containsKey(patternResource.sked__Resource__c)) {
                    map_resourceId_patternResource.put(patternResource.sked__Resource__c, new List<sked__Availability_Pattern_Resource__c>());
                }
                map_resourceId_patternResource.get(patternResource.sked__Resource__c).add(patternResource);
            }
            
            for (skedModels.availabilityPatternResource patternResource : model.availabilityPatternResources) {
                Date prStartDate = skedDateTimeUtils.getDateFromIsoString(patternResource.startDate);
                Date prEndDate = patternResource.endDate != NULL ? skedDateTimeUtils.getDateFromIsoString(patternResource.endDate) : maxDateValue;
                
                patternResource.isOverlapping = false;
                patternResource.overlappingPatternResources = new List<skedModels.overlappingPatternResource>();
                
                if (map_resourceId_patternResource.containsKey(patternResource.resourceId)) {
                    for (sked__Availability_Pattern_Resource__c existingPattern : map_resourceId_patternResource.get(patternResource.resourceId)) {
                        Date existingPatternEndDate = existingPattern.sked_End_Date__c != NULL ? existingPattern.sked_End_Date__c : maxDateValue;
                        if (prStartDate <= existingPatternEndDate && prEndDate >= existingPattern.sked_Start_Date__c) {
                            patternResource.isOverlapping = true;
                            
                            skedModels.overlappingPatternResource overlap = new skedModels.overlappingPatternResource();
                            overlap.startDate = JSON.serialize(existingPattern.sked_Start_Date__c).replace('"', '');
                            overlap.endDate = existingPattern.sked_End_Date__c != NULL ? JSON.serialize(existingPattern.sked_End_Date__c).replace('"', '') : '';
                            overlap.patternName = existingPattern.sked__Availability_Pattern__r.Name;
                            
                            patternResource.overlappingPatternResources.add(overlap);
                        }
                    }
                }
            }
        }
    }
    
    public skedDataService.saveResult saveAvailabilityPattern(skedModels.availabilityPattern model) {
        skedDataService.saveResult saveResullt = new skedDataService.saveResult();
        validatePreSave(model, saveResullt);
        
        if (saveResullt.success) {
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            skedSkeduloApiData.availabilityPatternPayload payload = generateAvailabilityPatternPayload(model);
            skedSkeduloApiData.upsertAvailabilityPatternResult calloutResult = apiManager.upsertAvailabilityPattern(payload);
            
            
            saveResullt.success = calloutResult.error == NULL && calloutResult.errors == NULL;
            if (!saveResullt.success) {
                saveResullt.errorMessage = calloutResult.error != NULL ? Json.serialize(calloutResult.error) : Json.serialize(calloutResult.errors);
            }
            else {
                string availabilityPatternId = string.isNotBlank(calloutResult.created) ? calloutResult.created : calloutResult.result;
                sked__Availability_Pattern__c newPattern = new sked__Availability_Pattern__c(
                    Id = availabilityPatternId,
                    sked_Validate_2CDO_Rule__c = model.validate2CDORule
                );
                upsert newPattern;
            }
        }
        return saveResullt;
    }
    
    public void savePatternResources(skedModels.availabilityPattern model) {
        Set<Id> resourceIds = new Set<Id>();
        for (skedModels.availabilityPatternResource patternResource : model.availabilityPatternResources) {
            resourceIds.add(patternResource.resourceId);
        }
        if (!string.isBlank(model.id)) {
            delete [SELECT Id 
                    FROM sked__Availability_Pattern_Resource__c 
                    WHERE sked__Availability_Pattern__c = :model.id
                    AND sked__Resource__c NOT IN :resourceIds];
        }
    }
    
    public void savePatternResource(skedModels.availabilityPatternResource availabilityPatternResource) {
        List<sked__Availability_Pattern_Resource__c> existingRecordQuery = [SELECT Id
                                                                            FROM sked__Availability_Pattern_Resource__c
                                                                            WHERE sked__Availability_Pattern__c = :availabilityPatternResource.availabilityPatternId
                                                                            AND sked__Resource__c = :availabilityPatternResource.resourceId];
        List<sked__Resource__c> skedResource = [SELECT Id, sked__Primary_Region__r.sked__Timezone__c
                                                FROM sked__Resource__c
                                                WHERE Id = :availabilityPatternResource.resourceId];
        string resourceTimezonesidId = skedResource.get(0).sked__Primary_Region__r.sked__Timezone__c;
        sked__Availability_Pattern_Resource__c skedPatternResource = new sked__Availability_Pattern_Resource__c(
        	sked__Availability_Pattern__c = availabilityPatternResource.availabilityPatternId,
            sked__Resource__c = availabilityPatternResource.resourceId,
            sked__Start__c = skedDateTimeUtils.newDateTimeInstance(availabilityPatternResource.startDate, 0, resourceTimezonesidId)
        );
        if (!string.isBlank(availabilityPatternResource.endDate)) {
            skedPatternResource.sked__End__c = skedDateTimeUtils.newDateTimeInstance(availabilityPatternResource.endDate, 0, resourceTimezonesidId);
        }
        if (!existingRecordQuery.isEmpty()) {
            skedPatternResource.Id = existingRecordQuery.get(0).Id;
        }
        upsert skedPatternResource;
    }
    
    /*********************************************************** Private ***********************************************************/
    private skedSkeduloApiData.availabilityPatternPayload generateAvailabilityPatternPayload(skedModels.availabilityPattern model) {
        skedSkeduloApiData.availabilityPatternPayload payload = new skedSkeduloApiData.availabilityPatternPayload();
        
        skedSkeduloApiData.pattern pattern = new skedSkeduloApiData.pattern();
        payload.pattern = pattern;
        
        pattern.UID = model.id;
        pattern.name = model.name;
        pattern.description = model.description;
        
        pattern.pattern = (skedSkeduloApiData.pattern2)Json.deserialize(model.pattern, skedSkeduloApiData.pattern2.class);
        
        if (model.availabilityPatternResources != NULL) {
            Set<Id> resourceIds = new Set<Id>();
            for (skedModels.availabilityPatternResource patternResource : model.availabilityPatternResources) {
                resourceIds.add(patternResource.resourceId);
            }
            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__c, sked__Primary_Region__r.sked__Timezone__c,
                                                                                     sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                                                                                     FROM sked__Resource__c
                                                                                     WHERE Id IN :resourceIds]);
            
            payload.resources = new List<skedSkeduloApiData.resource>();
            for (skedModels.availabilityPatternResource patternResource : model.availabilityPatternResources) {
                skedSkeduloApiData.resource resource = new skedSkeduloApiData.resource();
                resource.UID = patternResource.id;
                resource.resourceId = patternResource.resourceId;
                
                sked__Resource__c skedResource = mapResource.get(patternResource.resourceId);
                string timezoneSidId = skedResource.sked__Primary_Region__r.sked__Timezone__c;
                
                DateTime patternResourceStart = skedDateTimeUtils.getStartOfDate(patternResource.startDate, timezoneSidId);
                resource.start = patternResourceStart;
                
                if (!string.isBlank(patternResource.endDate)) {
                    DateTime patternResourceEnd = skedDateTimeUtils.getEndOfDate(patternResource.endDate, timezoneSidId);
                    resource.end_x = patternResourceEnd;
                }
                
                payload.resources.add(resource);
            }
        }
        
        return payload;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class queryModel extends skedEventService.queryModel {
        
    }

}