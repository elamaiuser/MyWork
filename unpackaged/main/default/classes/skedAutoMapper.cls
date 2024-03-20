global class skedAutoMapper {
    /************************************************ Singleton stuff ***********************************************/
    private static skedAutoMapper mInstance;
    public static skedAutoMapper instance {
        get {
            if (mInstance == null) {
                mInstance = new skedAutoMapper();
            }
            return mInstance;
        }
    }

    private skedAutoMapper() {
        this.timezoneSidId = skedSetting.instance.App.timezoneSidId;
    }

    public void setTimezoneSidId(string inputTimezoneSidId) {
        this.timezoneSidId = inputTimezoneSidId;
    }
    
    /************************************************ Auto Mapper ***********************************************/
    public static final string CUSTOM_FIELDS_EXTENSION = '__c';

    protected Map<Id, Object> mapObject = new Map<Id, Object>();

    protected string timezoneSidId;

    public Map<string, Object> mapTo(sObject sObj) {
        string sObjectApiName = sObj.getSobjectType().getDescribe().getName();
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(sObjectApiName);
        Map<string, Object> untypedDomainMap;

        if (config == null) {
            untypedDomainMap = doMapping(sObj);
        }
        else {
            untypedDomainMap = doMapping(sObj, config);
        }
        return untypedDomainMap;
    }

    public Object mapTo(SObject sObj, Type domainType) {
        //if (sObj.Id != NULL && mapObject != NULL && mapObject.containsKey(sObj.Id)) {
        //    return mapObject.get(sObj.Id);
        //}
        Map<string, Object> untypedDomainMap = mapTo(sObj);
        Object domainObject;
        if (untypedDomainMap != NULL) {
            string untypedDomainMapJson = JSON.serialize(untypedDomainMap);
            domainObject = JSON.deserialize(untypedDomainMapJson, domainType);
        }
        //if (sObj.Id != NULL) {
        //    if (mapObject == NULL) {
        //        mapObject = new Map<Id, Object>();
        //    }
        //    mapObject.put(sObj.Id, domainObject);
        //}
        return domainObject;
    }

    public Map<string, object> convertToMap(skedModels.modelBase model) {
        string jsonStr = Json.serialize(model);
        return (Map<string, Object>) JSON.deserializeUntyped(jsonStr);
    }
    
    public string mapToSObjectFieldPath(string objectType, string domainFieldName) {
        string result;
        skedMappingConfigContainer.mappingConfigModel config = skedMappingConfigContainer.instance.getMappingConfig(objectType);
        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            if (fieldConfig.domainFieldName == domainFieldName) {
                result = fieldConfig.sObjectFieldPath;
            }
        }
        return result;
    }

    /************************************************ Private methods ***********************************************/
    private Map<string, Object> doMapping(SObject sObj) {
        string sObjJsonstring = JSON.serialize(sObj);

        Schema.SObjectType sObjectType = sObj.getSobjectType();
        Schema.DescribeSObjectResult sObejctDescription = sObjectType.getDescribe();

        Map<string, Object> untypedSObjectMap;

        if (sObejctDescription.isCustom()) {
            untypedSObjectMap = (Map<string, Object>) JSON.deserializeUntyped(sObjJsonstring);
            string newKey;
            for (string key : untypedSObjectMap.keySet()) {
                if (key.endsWith(CUSTOM_FIELDS_EXTENSION)) {
                    newKey = key.removeEnd(CUSTOM_FIELDS_EXTENSION);
                    Object value = untypedSObjectMap.remove(key);
                    untypedSObjectMap.put(newKey, value);
                }
            }
        }
        return untypedSObjectMap;
    }

    private Map<string, Object> doMapping(SObject sObj, skedMappingConfigContainer.mappingConfigModel config) {
        string serializedSObj = JSON.serialize(sObj);
        Map<string, Object> untypedSObjMap = (Map<string, Object>) JSON.deserializeUntyped(serializedSObj);
        Map<string, Object> untypedDomainMap = new Map<string, Object>();
        Map<string, skedModels.address> addressMap = new Map<string, skedModels.address>();

        for (skedMappingConfigContainer.fieldConfigModel fieldConfig : config.fieldConfigs) {
            List<domainFieldModel> domainFields;

            if (fieldConfig.mappingType == 'related') {
                Map<string, Object> untypedRelatedSObjMap = (Map<string, Object>)untypedSObjMap.get(fieldConfig.sObjectFieldPaths.get(0));
                string serializedDomain = JSON.serialize(untypedRelatedSObjMap);
                sObject relatedSObject = (sObject)JSON.deserialize(serializedDomain, sObject.class);
                if (relatedSObject != NULL) {
                    Object domainObject = mapTo(relatedSObject, fieldConfig.relatedObjectDomainType);
                    domainFields = new List<domainFieldModel>();
                    domainFields.add(new domainFieldModel(fieldConfig.domainFieldName, domainObject));
                }
            }
            else if (fieldConfig.mappingType == 'relatedList') {
                string relatedListFieldApi = fieldConfig.sObjectFieldPaths.get(0);
                if (untypedSObjMap.containsKey(relatedListFieldApi)) {
                    List<sObject> relatedRecords = (List<sObject>)sObj.getSObjects(relatedListFieldApi);
                    List<Map<string, Object>> relatedObjects = new List<Map<string, Object>>();
                    if (relatedRecords != NULL && !relatedRecords.isEmpty()) {
                        for (sObject relatedRecord : relatedRecords) {
                            Map<string, Object> relatedObject = mapTo(relatedRecord);
                            relatedObjects.add(relatedObject);
                        }

                        domainFields = new List<domainFieldModel>();
                        domainFields.add(new domainFieldModel(fieldConfig.domainFieldName, relatedObjects));
                    }
                }
            }
            else if (fieldConfig.mappingType == 'fullAddress' || fieldConfig.mappingType == 'addressLocation' || fieldConfig.mappingType == 'addressPostalCode') {
                if (!addressMap.containsKey(fieldConfig.domainFieldName)) {
                    skedModels.address address = new skedModels.address();
                    addressMap.put(fieldConfig.domainFieldName, address);
                }
                skedModels.address address = addressMap.get(fieldConfig.domainFieldName);
                if (fieldConfig.mappingType == 'fullAddress') {
                    List<domainFieldModel> fullAddressDomainFields = mapToDomainField(untypedSObjMap, fieldConfig);
                    if (!fullAddressDomainFields.isEmpty()) {
                        domainFieldModel fullAddressField = fullAddressDomainFields.get(0);
                        address.fullAddress = string.valueOf(fullAddressField.value);
                    }
                }
                else if (fieldConfig.mappingType == 'addressLocation') {
                    List<domainFieldModel> addressLocationDomainFields = mapToDomainField(untypedSObjMap, fieldConfig);
                    if (!addressLocationDomainFields.isEmpty()) {
                        domainFieldModel addressLocationField = addressLocationDomainFields.get(0);
                        Map<string, object> mapGeolocation = (Map<string, object>)addressLocationField.value;
                        if (mapGeolocation != null && !mapGeolocation.isEmpty()) {
                            address.geometry = new skedModels.geometry((decimal)mapGeolocation.get('latitude'), (decimal)mapGeolocation.get('longitude'));
                        }
                    }
                }
                else if (fieldConfig.mappingType == 'addressPostalCode') {
                    List<domainFieldModel> addressPostalCodeDomainFields = mapToDomainField(untypedSObjMap, fieldConfig);
                    if (!addressPostalCodeDomainFields.isEmpty()) {
                        domainFieldModel addressPostalCodeField = addressPostalCodeDomainFields.get(0);
                        address.postalCode = string.valueOf(addressPostalCodeField.value);
                    }
                }
            }
            else {
                domainFields = mapToDomainField(untypedSObjMap, fieldConfig);
            }
            if (domainFields != null) {
                for (domainFieldModel domainField : domainFields) {
                    untypedDomainMap.put(domainField.key, domainField.value);
                }
            }
        }
        if (!addressMap.isEmpty()) {
            for (string key : addressMap.keySet()) {
                skedModels.address address = addressMap.get(key);
                if (address != NULL) {
                    untypedDomainMap.put(key, address);
                }
            }
        }
        return untypedDomainMap;
    }

    private List<domainFieldModel> mapToDomainField(Map<string, Object> untypedSObjMap, skedMappingConfigContainer.fieldConfigModel fieldConfig) {
        return mapToDomainField(untypedSObjMap, fieldConfig, 0);
    }

    private List<domainFieldModel> mapToDomainField(Map<string, Object> untypedSObjMap, skedMappingConfigContainer.fieldConfigModel fieldConfig, integer pathIndex) {
        if (pathIndex == fieldConfig.sObjectFieldPaths.size() - 1) {
            List<domainFieldModel> results = new List<domainFieldModel>();
            string sObjectFieldName = fieldConfig.sObjectFieldPaths.get(pathIndex);
            if (untypedSObjMap.containsKey(sObjectFieldName)) {
                Object value = untypedSObjMap.get(sObjectFieldName);

                if (fieldConfig.mappingType == 'datetime' && value != null) {
                    DateTime valueDt = skedDateTimeUtils.getDateTimeFromIsoString(string.valueOf(value));
                    domainFieldModel dateField = new domainFieldModel(fieldConfig.domainFieldName + 'Date', valueDt.format(skedDateTimeUtils.DATE_ISO_FORMAT, this.timezoneSidId));
                    domainFieldModel timeField = new domainFieldModel(fieldConfig.domainFieldName + 'Time', integer.valueOf(valueDt.format('Hmm', this.timezoneSidId)));

                    string dateTimeDomainField = fieldConfig.domainFieldName;
                    dateTimeDomainField = dateTimeDomainField == 'end' ? 'finish' : dateTimeDomainField;
                    domainFieldModel dateTimeField = new domainFieldModel(dateTimeDomainField, valueDt);
                    results.add(dateTimeField);
                    results.add(dateField);
                    results.add(timeField);
                }
                else if (fieldConfig.mappingType == 'multiPicklist') {
                    string strValue =  string.valueOf(value);
                    domainFieldModel dataField = new domainFieldModel(fieldConfig.domainFieldName, strValue.split(';'));
                    results.add(dataField);
                }
                else {
                    domainFieldModel dataField = new domainFieldModel(fieldConfig.domainFieldName, value);
                    results.add(dataField);
                }
            }
            else {
                if (fieldConfig.mappingType == 'value') {
                    domainFieldModel dataField = new domainFieldModel(fieldConfig.domainFieldName, sObjectFieldName);
                    results.add(dataField);
                }
            }
            return results;
        }
        else {
            if (untypedSObjMap.containsKey(fieldConfig.sObjectFieldPaths.get(pathIndex))) {
                return mapToDomainField((Map<string, Object>)untypedSObjMap.get(fieldConfig.sObjectFieldPaths.get(pathIndex)), fieldConfig, pathIndex + 1);
            }
            return new List<domainFieldModel>();
        }
    }

    /************************************************ Nested classes ***********************************************/
    public class domainFieldModel {
        public string key;
        public object value;

        public domainFieldModel(string key, object value) {
            this.key = key;
            this.value = value;
        }
    }

}