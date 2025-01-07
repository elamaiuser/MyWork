public virtual class skedEventService extends skedDataService {

    protected skedModels.recurringSchedule recurringSchedule;

    public virtual saveResult saveRecurringSchedule(skedModels.recurringSchedule recurringSchedule) {
        return baseSaveRecurringSchedule(recurringSchedule);
    }

    protected saveResult baseSaveRecurringSchedule(skedModels.recurringSchedule recurringSchedule) {
        this.recurringSchedule = recurringSchedule;
        saveResult result = preSaveRecord(recurringSchedule.events);
        if (result.success == true) {
            //save recurring schedule/template/entries
            Map<string, Id> map_tempId_sObjectId = updateRecurringSchedule(recurringSchedule);
            Map<string, sObject> mapEvent = new Map<string, sObject>();
            List<sObject> insertEvents = new List<sObject>();
            List<sObject> updateEvents = new List<sObject>();
            for (skedModels.event model : recurringSchedule.events) {
                if (model.Id == NULL || model.scheduleId.startsWithIgnoreCase(skedConstants.TEMPORARY_ID_PREFIX)) {
                    model.scheduleId = map_tempId_sObjectId.get(model.scheduleId);
                }

                sObject record = mapTosObject(model);
                if (model.Id == NULL) {
                    mapEvent.put(model.temporaryId, record);
                    insertEvents.add(record);
                }
                else {
                    mapEvent.put(record.Id, record);
                    updateEvents.add(record);
                }
            }
            insert insertEvents;
            update updateEvents;

            for (string eventTempId : mapEvent.keySet()) {
                map_tempId_sObjectId.put(eventTempId, mapEvent.get(eventTempId).Id);
            }
            for (skedModels.event model : recurringSchedule.events) {
                if (model.Id == NULL) {
                    model.Id = (Id)map_tempId_sObjectId.get(model.temporaryId);
                }
            }
            system.debug('Before post save record');
            system.debug('recurringSchedule.events '+recurringSchedule.events);
            system.debug('mapEvent.values() '+mapEvent.values());
            postSaveRecord(recurringSchedule.events, mapEvent.values());
            system.debug('after post save record');
            result.savedObjects = mapEvent.values();
        }
        return result;
    }

    private virtual Map<string, Id> updateRecurringSchedule(skedModels.recurringSchedule recurringSchedule) {
        Map<string, Id> map_tempId_sObjectId = new Map<string, Id>();

        sObject skedRecurringSchedule = this.mapTosObject(recurringSchedule, 'sked__Recurring_Schedule__c');
        if (recurringSchedule.Id == NULL) {
            insert skedRecurringSchedule;
            string recurringScheduleTempId = recurringSchedule.temporaryId;
            map_tempId_sObjectId.put(recurringScheduleTempId, skedRecurringSchedule.Id);
        }
        else {
            update skedRecurringSchedule;
            map_tempId_sObjectId.put(skedRecurringSchedule.Id, skedRecurringSchedule.Id);
        }

        return map_tempId_sObjectId;
    }

    public virtual List<skedModels.event> applyRelationshipRecurringSchedule(skedModels.event sourceEvent, List<skedModels.event> recurringEvents) {
        Type sourceEventListType = Type.forName('List<skedModels.' + sourceEvent.objectType + '>');
        Type sourceEventType = Type.forName('skedModels.' + sourceEvent.objectType);

        skedDataService service = skedServiceFactory.instance.resolve(sourceEvent.objectType);
        Type queryModelType = Type.forName('sked' + sourceEvent.objectType + 'Service.queryModel');
        skedEventService.queryModel query = (skedEventService.queryModel)queryModelType.newInstance();
        query.recordIds = new List<string>();
        query.recordIds.add(sourceEvent.Id);
        skedModels.event originalEvent = (skedModels.event)service.getList(query).get(0);
        Map<string, object> map_SourceEvent_ChangedFields = identifyFieldsChanged(sourceEvent, originalEvent);

        for (skedModels.event event : recurringEvents) {
            if (sourceEvent.Id != event.Id) {
                string serializedEvent = JSON.serialize(event);
                Map<string, Object> eventFieldMap = (Map<string, Object>) JSON.deserializeUntyped(serializedEvent);
                for (string field : map_SourceEvent_ChangedFields.keySet()) {
                    eventFieldMap.put(field, map_SourceEvent_ChangedFields.get(field));
                }
                string updatedSerializedEvent = JSON.serialize(eventFieldMap);
                event = (skedModels.event)JSON.deserialize(updatedSerializedEvent, sourceEventType);
            }
        }

        return recurringEvents;
    }

    /******************************************* Event Conflict handling ***********************************************/
    public virtual override List<skedModels.modelBase> getList(skedDataService.queryModelBase query) {
        List<skedModels.event> events = (List<skedModels.event>)super.getList(query);
        for (skedModels.event event : events) {
            event.updateStartFinish(this.timezoneSidId);
        }
        return events;
    }

    public virtual List<skedModels.modelBase> getListAndFormatDateTimeByTimezone(skedDataService.queryModelBase query, string timezoneSidIdField) {
        List<sObject> records = (List<sObject>)super.query(query);
        skedAutoMapper autoMapper = skedAutoMapper.instance;
        
        Type modelListType = Type.forName('List<skedModels.' + this.objectType + '>');
        List<skedModels.event> results = (List<skedModels.event>)modelListType.newInstance();
        for (sObject record : records) {
            string timezonesidId = (string)record.get(timezoneSidIdField);
            skedSetting.instance.App.setTimezoneSidId(timezonesidId);
            skedAutoMapper.instance.setTimezoneSidId(timezonesidId);
            skedModels.event event = (skedModels.event)skedAutoMapper.instance.mapTo(record, this.domainType);
            event.updateStartFinish(timezoneSidId);
            results.add(event);
        }
        return results;
    }

    protected Map<string, object> identifyFieldsChanged(skedModels.event sourceEvent, skedModels.event originalEvent) {
        string serializedSourceEvent = JSON.serialize(sourceEvent);
        Map<string, Object> sourceEventFieldMap = (Map<string, Object>) JSON.deserializeUntyped(serializedSourceEvent);
        string serializedOriginalEvent = JSON.serialize(originalEvent);
        Map<string, Object> originalEventFieldMap = (Map<string, Object>) JSON.deserializeUntyped(serializedOriginalEvent);

        Map<string, string> relatedListFields = getRelatedListFields(sourceEvent);

        Map<string, object> map_SourceEvent_ChangedFields = new Map<string, object>();
        for (string field : originalEventFieldMap.keySet()) {
            if (originalEventFieldMap.get(field) != sourceEventFieldMap.get(field)) {
                map_SourceEvent_ChangedFields.put(field, sourceEventFieldMap.get(field));
            }
        }
        return map_SourceEvent_ChangedFields;
    }

    protected Map<string, string> getRelatedListFields(skedModels.event sourceEvent) {
        Map<string, string> relatedListFields = new Map<string, string>();
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sourceEvent.objectType);
        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            if (fieldConfig.mappingType == 'relatedList') {
                relatedListFields.put(fieldConfig.domainFieldName, fieldConfig.relatedListSObjectName);
            }
        }

        return relatedListFields;
    }

    protected virtual boolean hasChangeOnRelatedList(List<skedModels.modelBase> sourceRelatedList, List<skedModels.modelBase> originalRelatedList) {
        return FALSE;
    }

    private Type getObjectType(string sObjectType) {
        string className = sObjectType.removeEnd(skedAutoMapper.CUSTOM_FIELDS_EXTENSION);
        className = className.startsWith('sked_') ? className.remove('sked_') : className;
        className = className.remove('_');
        Type relatedObjectType = Type.forName('skedModels.' + className);

        return relatedObjectType;
    }

    private Type getListObjectType(string sObjectType) {
        string className = sObjectType.removeEnd(skedAutoMapper.CUSTOM_FIELDS_EXTENSION);
        className = className.startsWith('sked_') ? className.remove('sked_') : className;
        className = className.remove('_');
        Type relatedObjectType = Type.forName('List<skedModels.' + className + '>');

        return relatedObjectType;
    }

    /************************************************** Nested classes **************************************************/
    public virtual class queryModel extends skedDataService.queryModelBase {
        public string endDate;
        public DateTime endTime;
        public List<string> resourceIds;
        public List<string> recurringScheduleIds;
        public string startDate;
        public DateTime startTime;
    }

}