public abstract class skedDataService {

    protected string timezoneSidId;
    protected string sObjectApiName;
    protected string objectType;
    protected Type domainType;

    public skedDataService() {
        system.debug('skedSetting.instance.App.timezoneSidId '+skedSetting.instance.App.timezoneSidId);
        this.timezoneSidId = skedSetting.instance.App.timezoneSidId;
        system.debug('this.timezoneSidId '+this.timezoneSidId);
        initialize();
    }

    protected virtual void initialize() {}

    protected virtual void doAdditionalMap(sObject sObj, skedModels.modelBase model) {}

    protected virtual void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase model) {}

    protected virtual saveResult preSaveRecord(List<skedModels.modelBase> models) {
        saveResult result = new saveResult();
        result.success = true;
        return result;
    }

    protected virtual void postSaveRecord(List<skedModels.modelBase> models, List<sObject> records) {}

    /*********************************************************** Public ***********************************************************/
    public void setTimezoneSidId(string inputTimezoneSidId) {
        this.timezoneSidId = inputTimezoneSidId;
    }
    
    public virtual List<sObject> query(queryModelBase query) {
        skedQueryBuilder queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        queryBuilder.setFromClause(this.sObjectApiName);
        
        //this set is used to track which sobject types is used to prevent loop query
        Set<string> sObjectList = new Set<String>();
        sObjectList.add(this.sObjectApiName);

        skedMappingConfigContainer.mappingConfigModel mainObjectConfig = skedMappingConfigContainer.instance.getMappingConfig(this.sObjectApiName);
        
        if (query != NULL) {
            getQueryConditions(queryBuilder, query);
        }

        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : mainObjectConfig.fieldConfigs) {
            if (fieldConfig.mappingType != 'value') {
                if (fieldConfig.mappingType == 'relatedList') {
                    if (query != NULL && query.mapSObjectQueryBuilder != NULL && query.mapSObjectQueryBuilder.containsKey(fieldConfig.relatedListSObjectName)) {
                        skedMappingConfigContainer.mappingConfigModel subObjectConfig = skedMappingConfigContainer.instance.getMappingConfig(fieldConfig.relatedListSObjectName);
                        skedQueryBuilder subObjectBuilder = query.mapSObjectQueryBuilder.get(fieldConfig.relatedListSObjectName);
                        subObjectBuilder.setFromClause(fieldConfig.sObjectFieldPath);

                        for (skedMappingConfigContainer.fieldConfigModel subObjectFieldConfig : subObjectConfig.fieldConfigs) {
                            if (subObjectFieldConfig.mappingType == 'related') {
                                if (!sObjectList.contains(subObjectFieldConfig.relatedSObjectName)) {
                                    addRelatedObjectFields(subObjectBuilder, subObjectFieldConfig.relatedSObjectName, subObjectFieldConfig.sObjectFieldPath);
                                }
                            }
                            else if (subObjectFieldConfig.mappingType != 'value' && subObjectFieldConfig.mappingType != 'relatedList') {
                                subObjectBuilder.addField(subObjectFieldConfig.sObjectFieldPath);
                            }
                        }
                        string subQueryStatement = '({0})';
                        subQueryStatement = subQueryStatement.replace('{0}', subObjectBuilder.toString());
                        queryBuilder.addField(subQueryStatement);
                    }
                }
                else if (fieldConfig.mappingType == 'related') {
                    if (!sObjectList.contains(fieldConfig.relatedSObjectName)) {
                        addRelatedObjectFields(queryBuilder, fieldConfig.relatedSObjectName, fieldConfig.sObjectFieldPath);
                    }
                }
                else {
                    queryBuilder.addField(fieldConfig.sObjectFieldPath);
                }
            }
        }

        if (query != NULL) {
            if (query.recordIds != NULL && !query.recordIds.isEmpty()) {
                queryBuilder.cleanConditions();
                queryBuilder.addCondition('Id IN {0}', query.recordIds);
            }
            else {
                if (query.predefinedRecordIds != NULL) {
                    if (query.predefinedRecordIds.isEmpty()) return new List<SObject>();
                    queryBuilder.addCondition('Id IN {0}', query.predefinedRecordIds);
                }
                if (query.excludedRecordIds != NULL && !query.excludedRecordIds.isEmpty()) {
                    queryBuilder.addCondition('Id NOT IN {0}', query.excludedRecordIds);
                }
                if (string.isNotBlank(query.queryText) && query.searchColumns != NULL && !query.searchColumns.isEmpty()) {
                    List<string> searchConditions = new List<string>();
                    string pattern = '{0} LIKE \'%{1}%\'';
                    for (string searchColumn : query.searchColumns) {
                        string searchCondition = pattern.replace('{0}', searchColumn).replace('{1}', query.queryText);
                        searchConditions.add(searchCondition);
                    }
                    string finalSearchCondition = string.join(searchConditions, ' OR ');
                    finalSearchCondition = searchConditions.size() > 1 ? '(' + finalSearchCondition + ')' : finalSearchCondition;
                    queryBuilder.conditions.add(finalSearchCondition);
                }
                if (query.mapSObjectQueryBuilder != NULL && query.mapSObjectQueryBuilder.containsKey(this.sObjectApiName)) {
                    skedQueryBuilder injectedQueryBuilder = query.mapSObjectQueryBuilder.get(this.sObjectApiName);
                    queryBuilder.addConditions(injectedQueryBuilder.conditions);
                }
            }
            if (!string.isBlank(query.orderBy)) {
                string orderByClause = 'ORDER BY ' + query.orderBy;
                if (!string.isBlank(query.orderAscending)) {
                    orderByClause += ' ' + query.orderAscending;
                }
                queryBuilder.orderClause = orderByClause;
            }
        }

        string statement = queryBuilder.toString();
        system.debug('#' + this.sObjectApiName + ' statement#' + statement);
        List<sObject> results = (List<sObject>)Database.query(statement);
        return results;
    }
    
    public paginationQueryModel doPaginationQuery(queryModelBase query) {
        paginationQueryModel result = new paginationQueryModel();
        
        skedQueryBuilder queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        queryBuilder.setFromClause(this.sObjectApiName);
        
        skedQueryBuilder countQueryBuilder = new skedQueryBuilder();
        countQueryBuilder.isCountQuery = true;
        countQueryBuilder.addField('Count()');
        countQueryBuilder.setFromClause(this.sObjectApiName);
        getQueryConditions(countQueryBuilder, query);
        
        if (query.recordIds != NULL && !query.recordIds.isEmpty()) {
            countQueryBuilder.cleanConditions();
            countQueryBuilder.addCondition('Id IN {0}', query.recordIds);
        }
        else {
            if (query.predefinedRecordIds != NULL && !query.predefinedRecordIds.isEmpty()) {
                countQueryBuilder.addCondition('Id IN {0}', query.predefinedRecordIds);
            }
            if (string.isNotBlank(query.queryText) && query.searchColumns != NULL && !query.searchColumns.isEmpty()) {
                List<string> searchConditions = new List<string>();
                string pattern = '{0} LIKE \'%{1}%\'';
                for (string searchColumn : query.searchColumns) {
                    string searchCondition = pattern.replace('{0}', searchColumn).replace('{1}', query.queryText);
                    searchConditions.add(searchCondition);
                }
                string finalSearchCondition = string.join(searchConditions, ' OR ');
                finalSearchCondition = searchConditions.size() > 1 ? '(' + finalSearchCondition + ')' : finalSearchCondition;
                countQueryBuilder.conditions.add(finalSearchCondition);
            }
        }
        
        result.totalRecords = Database.countQuery(countQueryBuilder.toString());
        
        queryBuilder.limitRecords = query.pageSize;
        queryBuilder.offsetRecords = (query.pageNo - 1) * query.pageSize;
        
        result.records = query(query);
        return result;
    }

    public virtual List<skedModels.modelBase> getList(queryModelBase query) {
        List<sObject> records = query(query);
        system.debug('#records#' + records);
        return mapToList(records, this.objectType);
    }
    
    public paginationListModel doPaginationList(queryModelBase query) {
        paginationListModel result = new paginationListModel();
        paginationQueryModel queryResult = doPaginationQuery(query);
        result.totalRecords = queryResult.totalRecords;
        result.models = mapToList(queryResult.records, this.objectType);
        return result;
    }

    public virtual sObject mapTosObject(skedModels.modelBase model) {
        return mapTosObject(model, this.sObjectApiName);
    }

    public virtual sObject mapTosObject(skedModels.modelBase model, string sObjectApiName) {
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sObjectApiName);
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectApiName);

        string serializedModel = JSON.serialize(model);
        Map<String, Object> untypedDomainMap = (Map<String, Object>) JSON.deserializeUntyped(serializedModel);
        boolean isEditing = untypedDomainMap.containsKey('id') && untypedDomainMap.get('id') != null;
        sObject sObj = sObjectType.newSObject();

        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            boolean isDirectField = fieldConfig.sObjectFieldPaths.size() == 1;
            if (!isDirectField) {
                continue;
            }
            string sObjectFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
            boolean isReadonlyField = config.readonlyFields != null && config.readonlyFields.contains(fieldConfig.sObjectFieldPaths.get(0));
            if (isReadonlyField) {
                continue;
            }
            boolean isMasterField = config.masterDetailFields != NULL && config.masterDetailFields.contains(sObjectFieldApiName);
            if (isMasterField && isEditing) {
                continue;
            }

            if (fieldConfig.mappingType == 'direct' || fieldConfig.mappingType == 'date') {
                if (untypedDomainMap.containsKey(fieldConfig.domainFieldName)) {
                    Object value = untypedDomainMap.get(fieldConfig.domainFieldName);
                    if (value != null) {
                        if (fieldConfig.mappingType == 'date') {
                            sObj.put(sObjectFieldApiName, skedDateTimeUtils.getDateFromIsoString((string)value));
                        }
                        else {
                            sObj.put(sObjectFieldApiName, value);
                        }
                    }
                    else {
                        //TODO: need to ask frontend to return all fields that were returned from server
                        //sObj.put(sObjectFieldApiName, null);
                    }
                }
            }
            else if (fieldConfig.mappingType == 'datetime') {
                string modelDateField = fieldConfig.domainFieldName + 'Date';
                string modelTimeField = fieldConfig.domainFieldName + 'Time';
                string dateStr = (string)untypedDomainMap.get(modelDateField);
                integer timeInt = (integer)untypedDomainMap.get(modelTimeField);

                if (!string.isBlank(dateStr) && timeInt != NULL) {
                    Date dateValue = skedDateTimeUtils.getDateFromIsoString(dateStr);
                    integer timeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(timeInt);
                    DateTime dateStart = skedDateTimeUtils.getStartOfDate(dateValue, this.timezoneSidId);
                    DateTime dateTimeValue = skedDateTimeUtils.addMinutes(dateStart, timeInMinutes, this.timezoneSidId);

                    string dateTimeFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
                    sObj.put(dateTimeFieldApiName, dateTimeValue);
                }
            }
            else if (fieldConfig.mappingType == 'fullAddress') {
                Map<string, object> addressMap = (Map<string, object>)untypedDomainMap.get(fieldConfig.domainFieldName);
                if (addressMap != NULL && addressMap.containsKey('fullAddress')) {
                    string fullAddressFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
                    sObj.put(fullAddressFieldApiName, addressMap.get('fullAddress'));
                }
            }
            else if (fieldConfig.mappingType == 'addressPostalCode') {
                Map<string, object> addressMap = (Map<string, object>)untypedDomainMap.get(fieldConfig.domainFieldName);
                if (addressMap != NULL && addressMap.containsKey('postalCode')) {
                    string postalCodeFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
                    sObj.put(postalCodeFieldApiName, addressMap.get('postalCode'));
                }
            }
            else if (fieldConfig.mappingType == 'addressLocation') {
                Map<string, object> addressMap = (Map<string, object>)untypedDomainMap.get(fieldConfig.domainFieldName);
                if (addressMap != NULL && addressMap.containsKey('geometry')) {
                    Map<string, object> geometryMap = (Map<string, object>)addressMap.get('geometry');
                    if (geometryMap != NULL && geometryMap.containsKey('lat') && geometryMap.containsKey('lng')) {
                        string geolocationFieldApiName = fieldConfig.sObjectFieldPaths.get(0);
                        string latFieldApiName = geolocationFieldApiName.replace('__c', '__latitude__s');
                        string lngFieldApiName = geolocationFieldApiName.replace('__c', '__longitude__s');
                        sObj.put(latFieldApiName, geometryMap.get('lat'));
                        sObj.put(lngFieldApiName, geometryMap.get('lng'));
                    }
                }
            }
            else if (fieldConfig.mappingType == 'multiPicklist') {
                Object value = untypedDomainMap.get(fieldConfig.domainFieldName);
                if (value != null) {
                    List<object> picklistValues = (List<object>)value;
                    List<string> picklistStrValues = new List<string>();
                    for (object picklistValue : picklistValues) {
                        picklistStrValues.add(string.valueOf(picklistValue));
                    }
                    sObj.put(sObjectFieldApiName, string.join(picklistStrValues, ';'));
                }
            }
        }
        if (this.sObjectApiName == sObjectApiName) {
            doAdditionalMap(sObj, model);
        }

        return sObj;
    }

    public saveResult saveRecord(skedModels.modelBase model) {
        Type modelListType = Type.forName('List<skedModels.' + objectType + '>');
        List<skedModels.modelBase> models = (List<skedModels.modelBase>)modelListType.newInstance();
        models.add(model);
        return saveRecords(models);
    }

    public saveResult saveRecords(List<skedModels.modelBase> models) {
        saveResult result = preSaveRecord(models);
        if (result.success == true) {
            List<sObject> records = new List<sObject>();
            List<sObject> recordsToInsert = new List<sObject>();
            List<sObject> recordsToUpdate = new List<sObject>();

            Map<string, sObject> map_tempId_sObject = new Map<string, sObject>();
            for (skedModels.modelBase model : models) {
                sObject record = mapTosObject(model);
                records.add(record);
                if (record.Id == NULL) {
                    model.temporaryId = skedUtils.getKey();
                    map_tempId_sObject.put(model.temporaryId, record);
                    recordsToInsert.add(record);
                }
                else {
                    recordsToUpdate.add(record);
                }
            }
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
                for (skedModels.modelBase model : models) {
                    if (!string.isBlank(model.temporaryId)) {
                        model.id = map_tempId_sObject.get(model.temporaryId).Id;
                    }
                }
            }
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
            postSaveRecord(models, records);
            result.savedObjects = records;
        }
        return result;
    }

    public saveResult deleteRecord(skedModels.modelBase model) {
        List<skedModels.modelBase> models = new List<skedModels.modelBase>();
        models.add(model);
        return deleteRecords(models);
    }

    public saveResult deleteRecords(List<skedModels.modelBase> models) {
        List<sObject> records = new List<sObject>();
        for (skedModels.modelBase model : models) {
            Id recordId = Id.valueOf(model.id);
            sObject record = recordId.getSObjectType().newSObject(recordId);
            records.add(record);
        }
        delete records;

        saveResult result = new saveResult();
        result.success = true;
        return result;
    }

    /*********************************************************** Private ***********************************************************/
    private void addRelatedObjectFields(skedQueryBuilder queryBuilder, string sObjectName, string relatedFieldAnchor) {
        skedMappingConfigContainer.mappingConfigModel relatedObjConfig = skedMappingConfigContainer.instance.getMappingConfig(sObjectName);
        for (skedMappingConfigContainer.fieldConfigModel relatedObjFieldConfig : relatedObjConfig.fieldConfigs) {
            if (relatedObjFieldConfig.mappingType != 'value' && relatedObjFieldConfig.mappingType != 'relatedList' && relatedObjFieldConfig.mappingType != 'related') {
                queryBuilder.addField(relatedFieldAnchor + '.' + relatedObjFieldConfig.sObjectFieldPath);
            }
        }
    }
    
    private List<skedModels.modelBase> mapToList(List<sObject> records, string outputObjectType) {
        Type modelListType = Type.forName('List<skedModels.' + outputObjectType + '>');
        List<skedModels.modelBase> results = (List<skedModels.modelBase>)modelListType.newInstance();
        for (sObject record : records) {
            skedModels.modelBase model = (skedModels.modelBase)skedAutoMapper.instance.mapTo(record, this.domainType);
            results.add(model);
        }
        return results;
    }

    /*********************************************************** Nested classes ***********************************************************/
    public virtual class queryModelBase {
        public List<string> recordIds;
        public List<string> predefinedRecordIds;
        public List<string> excludedRecordIds;
        public Map<string, skedQueryBuilder> mapSObjectQueryBuilder;
        public string timezoneSidId;
        public Integer subQueryIndicator;
        public string queryText;
        public string orderBy;
        public string orderAscending;
        public integer pageNo;
        public integer pageSize;
        public List<string> searchColumns;

        public boolean includes(Integer sObjectEnum) {
            return this.subQueryIndicator != NULL && (this.subQueryIndicator & sObjectEnum) > 0;
        }

        public skedQueryBuilder getQueryBuilder(string sObjectName) {
            if (mapSObjectQueryBuilder == NULL) {
                mapSObjectQueryBuilder = new Map<string, skedQueryBuilder>();
            }
            if (!this.mapSObjectQueryBuilder.containsKey(sObjectName)) {
                this.mapSObjectQueryBuilder.put(sObjectName, new skedQueryBuilder());
            }
            return this.mapSObjectQueryBuilder.get(sObjectName);
        }
    }

    public virtual class paginationQueryModel {
        public integer totalRecords;
        public List<sObject> records;
    }
    
    public virtual class paginationListModel {
        public integer totalRecords;
        public List<skedModels.modelBase> models;
    }
    
    public virtual class saveResult {
        public List<sObject> savedObjects;
        public boolean success;
        public object returnedData;
        public string errorMessage;
        public string message;
    }

}