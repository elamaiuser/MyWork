public class skedRecurringFactory {

    protected string timezoneSidId;

    public skedRecurringFactory() {
        this.timezoneSidId = skedSetting.instance.App.timezoneSidId;
    }

    public skedModels.recurringSchedule process(skedModels.event sourceEvent, recurringOption configuration) {
        skedModels.recurringSchedule schedule = createSchedule(configuration);
        Type sourceEventType = Type.forName('skedModels.' + sourceEvent.objectType);
        Type sourceEventListType = Type.forName('List<skedModels.' + sourceEvent.objectType + '>');
        schedule.events = (List<skedModels.event>)sourceEventListType.newInstance();
        sourceEvent.scheduleId = schedule.temporaryId;

        if (configuration.dateValues == NULL) {
            configuration.startDate = skedDateTimeUtils.getDateFromIsoString(configuration.availabilityTemplate.startDate);
            configuration.endDate = skedDateTimeUtils.getDateFromIsoString(configuration.availabilityTemplate.endDate);
            skedModels.availabilityTemplate template = configuration.availabilityTemplate;

            populateHolidays(configuration);
            generateEventsFromTemplate(sourceEvent, schedule, template, configuration);
        }
        else {
            generateEventsFromDates(sourceEvent, schedule, configuration);
        }

        return schedule;
    }

    public List<skedModels.event> editRecurring(skedModels.event sourceEvent, recurringOption configuration) {
        Type sourceEventListType = Type.forName('List<skedModels.' + sourceEvent.objectType + '>');
        Type sourceEventType = Type.forName('skedModels.' + sourceEvent.objectType);

        skedDataService service = skedServiceFactory.instance.resolve(sourceEvent.objectType);
        Type queryModelType = Type.forName('sked' + sourceEvent.objectType + 'Service.queryModel');
        skedEventService.queryModel query = (skedEventService.queryModel)queryModelType.newInstance();
        query.recordIds = new List<string>();
        query.recordIds.add(sourceEvent.Id);

        skedModels.event originalEvent = (skedModels.event)service.getList(query).get(0);
        string sourceEventWeekday = sourceEvent.start.format('EEE', this.timezoneSidId);
        Date eventStartDate = skedDateTimeUtils.getDate(sourceEvent.start, this.timezoneSidId);
        Date eventEndDate = skedDateTimeUtils.getDate(sourceEvent.finish, this.timezoneSidId);
        Date originalEventStartDate = skedDateTimeUtils.getDate(originalEvent.start, this.timezoneSidId);
        Date originalEventEndDate = skedDateTimeUtils.getDate(originalEvent.finish, this.timezoneSidId);
        integer startDateDiffDays = originalEventStartDate.daysBetween(eventStartDate);
        integer endDateDiffDays = originalEventEndDate.daysBetween(eventEndDate);

        query = (skedEventService.queryModel)queryModelType.newInstance();
        query.recurringScheduleIds = new List<string>();
        query.recurringScheduleIds.add(sourceEvent.scheduleId);

        query.startTime = system.now();
        if (configuration.editAction == 'following_events') {
            query.startTime = system.now() > sourceEvent.start ? system.now() : sourceEvent.start;
        }

        List<skedModels.event> recurringRecords = (List<skedModels.event>)sourceEventListType.newInstance();
        List<skedModels.event> queryResults = (List<skedModels.event>)service.getList(query);
        if (configuration.editAction == 'same_weekday') {
            for (skedModels.event event : queryResults) {
                string eventWeekday = event.start.format('EEE', this.timezoneSidId);
                if (eventWeekday == sourceEventWeekday) {
                    recurringRecords.add(event);
                }
            }
        }
        else {
            recurringRecords.addAll(queryResults);
        }

        Map<string, object> map_SourceEvent_ChangedFields = identifyFieldsChanged(sourceEvent, originalEvent);
        List<skedModels.event> result = (List<skedModels.event>)sourceEventListType.newInstance();
        
        integer sourceEventStartInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(sourceEvent.startTime);
        integer sourceEventEndInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(sourceEvent.endTime);
        
        for (skedModels.event event : recurringRecords) {
            DateTime recordStart_dateStart = skedDateTimeUtils.getStartOfDate(event.start, this.timezoneSidId);
            DateTime recordFinish_dateStart = skedDateTimeUtils.getStartOfDate(event.finish, this.timezoneSidId);

            string serializedEvent = JSON.serialize(event);
            Map<string, Object> eventFieldMap = (Map<string, Object>) JSON.deserializeUntyped(serializedEvent);
            for (string field : map_SourceEvent_ChangedFields.keySet()) {
                eventFieldMap.put(field, map_SourceEvent_ChangedFields.get(field));
            }
            string updatedSerializedEvent = JSON.serialize(eventFieldMap);
            event = (skedModels.event)JSON.deserialize(updatedSerializedEvent, sourceEventType);

            event.start = skedDateTimeUtils.addMinutes(recordStart_dateStart, sourceEventStartInMinutes, this.timezoneSidId);
            event.finish = skedDateTimeUtils.addMinutes(recordFinish_dateStart, sourceEventEndInMinutes, this.timezoneSidId);
            event.start = skedDateTimeUtils.addDays(event.start, startDateDiffDays, this.timezoneSidId);
            event.finish = skedDateTimeUtils.addDays(event.finish, endDateDiffDays, this.timezoneSidId);
            event.updateDateTimeFields(this.timezoneSidId);

            result.add(event);
        }

        return result;
    }

    public List<skedModels.event> getRecurringRecords(skedModels.event sourceEvent, recurringOption configuration, string sObjectType) {
        Type sourceEventListType = Type.forName('List<skedModels.' + sourceEvent.objectType + '>');

        skedDataService service = skedServiceFactory.instance.resolve(sObjectType);
        Type queryModelType = Type.forName('sked' + sourceEvent.objectType + 'Service.queryModel');
        skedEventService.queryModel query = (skedEventService.queryModel)queryModelType.newInstance();
        query.recurringScheduleIds = new List<string>();
        query.recurringScheduleIds.add(sourceEvent.scheduleId);

        if (configuration.editAction == 'all_events' || configuration.editAction == 'same_weekday') {
            query.startTime = system.now();
        }
        else if (configuration.editAction == 'following_events') {
            query.startTime = sourceEvent.start;
        }
        else if (configuration.editAction == 'only_me') {
            query.recordIds = new List<string>();
            query.recordIds.add(sourceEvent.Id);
        }

        List<skedModels.event> recurringRecords = (List<skedModels.event>)sourceEventListType.newInstance();
        List<skedModels.event> queryResults = (List<skedModels.event>)service.getList(query);
        if (configuration.editAction == 'same_weekday') {
            string sourceEventWeekday = sourceEvent.start.format('EEE', this.timezoneSidId);
            for (skedModels.event event : queryResults) {
                string eventWeekday = event.start.format('EEE', this.timezoneSidId);
                if (eventWeekday == sourceEventWeekday) {
                    recurringRecords.add(event);
                }
            }
        }
        else {
            recurringRecords.addAll(queryResults);
        }

        return recurringRecords;
    }

    /*********************************************************** Private methods ***********************************************************************/
    private void generateEventsFromTemplate(skedModels.event sourceEvent, skedModels.recurringSchedule schedule, skedModels.availabilityTemplate template, recurringOption configuration) {
        Type sourceEventType = Type.forName('skedModels.' + sourceEvent.objectType);
        Type sourceEventListType = Type.forName('List<skedModels.' + sourceEvent.objectType + '>');

        Map<string, integer> mapWeekdayIndex = skedUtils.getMapWeekdayIndex();
        DateTime startDateDt = skedDateTimeUtils.getStartOfDate(configuration.startDate, this.timezoneSidId);
        string startDateWeekday = startDateDt.format('EEE', this.timezoneSidId).toLowerCase();
        integer startDateWeekdayIndex = mapWeekdayIndex.get(startDateWeekday);
        integer startEndDaysDifference = configuration.startDate.daysBetween(configuration.endDate);
        integer noOfWeeks = identifyNoWeek(template);
        string serializedSourceEvent = JSON.serialize(sourceEvent);

        for (skedModels.availabilityTemplateEntry entry : template.availabilityTemplateEntries) {
            integer startTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(entry.startTime);
            integer endTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(entry.endTime);
            integer weekdayIndex = mapWeekdayIndex.get(entry.weekday);
            integer daysDifference = weekdayIndex - startDateWeekdayIndex + 7 * (entry.weekNo - 1);
            while (daysDifference <= startEndDaysDifference) {
                if (daysDifference >= 0) {
                    Date recurringDate = configuration.startDate.addDays(daysDifference);
                    if (!configuration.skippedDates.contains(recurringDate)) {
                        DateTime recurringDateStart = skedDateTimeUtils.addDays(startDateDt, daysDifference, this.timezoneSidId);
                        DateTime newEventStart = skedDateTimeUtils.addMinutes(recurringDateStart, startTimeInMinutes, this.timezoneSidId);
                        DateTime newEventEnd = skedDateTimeUtils.addMinutes(recurringDateStart, endTimeInMinutes, this.timezoneSidId);

                        skedModels.event newEvent = (skedModels.event)JSON.deserialize(serializedSourceEvent, sourceEventType);
                        newEvent.temporaryId = skedUtils.getKey();
                        newEvent.scheduleId = schedule.temporaryId;
                        newEvent.start = newEventStart;
                        newEvent.finish = newEventEnd;
                        if (entry.isAllDay != null) {
                            newEvent.isAllDay = entry.isAllDay;
                        }
                        newEvent.updateDateTimeFields(this.timezoneSidId);

                        schedule.events.add(newEvent);
                    }
                }
                daysDifference += 7 * noOfWeeks;
            }
        }
    }

    private void generateEventsFromDates(skedModels.event sourceEvent, skedModels.recurringSchedule schedule, recurringOption configuration) {
        Type sourceEventType = Type.forName('skedModels.' + sourceEvent.objectType);
        Type sourceEventListType = Type.forName('List<skedModels.' + sourceEvent.objectType + '>');

        string serializedSourceEvent = JSON.serialize(sourceEvent);
        for (Date recurringDate : configuration.dateValues) {
            skedModels.event newEvent = (skedModels.event)JSON.deserialize(serializedSourceEvent, sourceEventType);
            newEvent.temporaryId = skedUtils.getKey();
            newEvent.scheduleId = schedule.temporaryId;
            newEvent.start = skedDateTimeUtils.newDateTimeInstance(recurringDate, sourceEvent.startTime, this.timezoneSidId);
            newEvent.finish = skedDateTimeUtils.newDateTimeInstance(recurringDate, sourceEvent.endTime, this.timezoneSidId);
            newEvent.updateDateTimeFields(this.timezoneSidId);

            schedule.events.add(newEvent);
        }
    }

    private Set<Date> getHolidays(recurringOption configuration) {
        Map<string, Set<Date>> mapHolidays = skedSetting.instance.App.mapHoliday;
        Set<Date> allHolidays = new Set<Date>();
        if (mapHolidays.containsKey(skedConstants.HOLIDAY_GLOBAL)) {
            Set<Date> globalHolidays = mapHolidays.get(skedConstants.HOLIDAY_GLOBAL);
            allHolidays.addAll(globalHolidays);
        }

        List<string> regionIdsToCheck = new List<String>();
        if (!string.isBlank(configuration.regionId)) {
            regionIdsToCheck.add(configuration.regionId);
        }
        if(configuration.regionIds != NULL && !configuration.regionIds.isEmpty()) {
            regionIdsToCheck.addAll(configuration.regionIds);
        }

        for(String regionId : regionIdsToCheck) {
            if(mapHolidays.containsKey(regionId)) {
                Set<Date> globalHolidays = mapHolidays.get(regionId);
                allHolidays.addAll(globalHolidays);
            }
        }

        return allHolidays;
    }

    private void populateHolidays(recurringOption configuration) {
        configuration.skippedDates = new Set<Date>();
        if (configuration.skipHolidays == true) {
            Set<Date> holidays = getHolidays(configuration);
            configuration.skippedDates.addAll(holidays);

            system.debug(configuration.skippedDates);
        }
    }

    private skedModels.recurringSchedule createSchedule(recurringOption configuration) {
        skedModels.recurringSchedule schedule = new skedModels.recurringSchedule();
        schedule.temporaryId = skedUtils.getKey();
        schedule.description = configuration.description;
        schedule.skipHolidays = configuration.skipHolidays;

        return schedule;
    }

    private integer identifyNoWeek(skedModels.availabilityTemplate template) {
        integer noOfWeeks = 1;
        for (skedModels.availabilityTemplateEntry entry : template.availabilityTemplateEntries) {
            noOfWeeks = entry.WeekNo > noOfWeeks ? entry.WeekNo : noOfWeeks;
        }

        return noOfWeeks;
    }

    private Map<string, object> identifyFieldsChanged(skedModels.event sourceEvent, skedModels.event originalEvent) {
        string serializedSourceEvent = JSON.serialize(sourceEvent);
        Map<string, Object> sourceEventFieldMap = (Map<string, Object>) JSON.deserializeUntyped(serializedSourceEvent);
        string serializedOriginalEvent = JSON.serialize(originalEvent);
        Map<string, Object> originalEventFieldMap = (Map<string, Object>) JSON.deserializeUntyped(serializedOriginalEvent);

        List<string> relatedListFields = getRelatedListFields(sourceEvent);

        Map<string, object> map_SourceEvent_ChangedFields = new Map<string, object>();
        for (string field : originalEventFieldMap.keySet()) {
            if (relatedListFields.contains(field)) {
                map_SourceEvent_ChangedFields.put(field, sourceEventFieldMap.get(field));
            }
            else if (originalEventFieldMap.get(field) != sourceEventFieldMap.get(field)) {
                map_SourceEvent_ChangedFields.put(field, sourceEventFieldMap.get(field));
            }
        }
        return map_SourceEvent_ChangedFields;
    }

    public List<string> getRelatedListFields(skedModels.event sourceEvent) {
        List<string> relatedListFields = new List<string>();
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sourceEvent.objectType);
        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            if (fieldConfig.mappingType == 'relatedList') {
                relatedListFields.add(fieldConfig.domainFieldName);
            }
        }

        return relatedListFields;
    }

    /****************************************************************** MODELS *************************************************************************/
    public virtual class recurringOption {
        public string scheduleId;
        public Set<Date> skippedDates;
        public Date startDate;
        public Date endDate;
        public boolean skipHolidays;
        public string description;

        public skedModels.availabilityTemplate availabilityTemplate;
        public Set<Date> dateValues;

        public string editAction; //same_weekday | all_events | following_events
        public boolean isDeleting;

        public string regionId;
        public List<string> regionIds;
    }

}