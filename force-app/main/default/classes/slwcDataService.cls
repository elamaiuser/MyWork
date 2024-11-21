public without sharing class slwcDataService {
    
    @AuraEnabled(cacheable=false)
    public static Object executeQuery(String query) {
        return Database.query(query);
    }
    
    @AuraEnabled(cacheable=false)
    public static Object executeQueries(List<queryModel> request) {
        List<queryResultModel> results = new List<queryResultModel>();
        
        Set<Id> allIds = new Set<Id>();
        for(queryModel query : request){
            queryResultModel result = new queryResultModel();
            result.key = query.key;
            List<sObject> sObjects = Database.query(query.query);
            result.result = sObjects;
            for (sObject sObj : sObjects) {
                if (string.isBlank(query.fieldToExtractId)) {
                    allIds.add(sObj.Id);
                }
                else {
                    Id idValue = (Id)sObj.get(query.fieldToExtractId);
                    allIds.add(idValue);
                }
            }
            results.add(result);
        }
        
        return results;
    }
    
    @AuraEnabled
    public static slwcAuraResult dynamicDelete(string sObjectApiName, List<string> recordIds) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        slwcAuraResult result = new slwcAuraResult();
        SavePoint sp = Database.setSavepoint();
        try {
            
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectApiName);
            List<sObject> records = new List<sObject>();
            for (string recordId : recordIds) {
                sObject sObj = sObjectType.newSObject();
                sObj.Id = recordId;
                records.add(sObj);
            }
            delete records;
            
            result.success = true;
            
        }
        catch (Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult dynamicUpsert(List<sObjectWrapper> wrappers) {
        return dynamicUpsert(wrappers, NULL);
    }
    
    @AuraEnabled
    public static slwcAuraResult dynamicUpsert(List<sObjectWrapper> wrappers, List<deleteWrapper> deletedRecords) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        slwcAuraResult result = new slwcAuraResult();
        SavePoint sp = Database.setSavepoint();
        try {
            
            DateTime executionTime = system.now();
            
            deleteRecords(deletedRecords);
            
            List<sObject> allRecords = new List<sObject>();
            List<sObject> recordsToInsert = new List<sObject>();
            List<sObject> recordsToUpdate = new List<sObject>();
            for (sObjectWrapper wrapper : wrappers) {
                if (!string.isBlank(wrapper.sObj.Id)) {
                    if (wrapper.isChanged == TRUE) {
                        recordsToUpdate.add(wrapper.sObj);
                    }
                }
                else {
                    recordsToInsert.add(wrapper.sObj);
                }
                allRecords.add(wrapper.sObj);
            }
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }
            if (!recordsToUpdate.isEmpty()) {
                updateRecordsWithErrorBuilt(recordsToUpdate, recordsToUpdate[0].getSObjectType().getDescribe().getName());
            }
            insertRelatedList(wrappers, executionTime);

            result.success = true;
            result.returnedData = allRecords;
            
        }
        catch (Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult getCustomSettings(List<string> settingKeys) {
        slwcAuraResult result = new slwcAuraResult();
        
        Map<string, object> mapSetting = new Map<string, object>();
        if (settingKeys.contains('adminSetting')) {
            mapSetting.put('adminSetting', new slwcSetting.adminSetting());
        }
        if (settingKeys.contains('lac')) {
            mapSetting.put('lac', new slwcSetting.lacSetting());
        }
        if (settingKeys.contains('pac')) {
            mapSetting.put('pac', new slwcSetting.pacSetting());
        }
        if (settingKeys.contains('rac')) {
            mapSetting.put('rac', new slwcSetting.racSetting());
        }
        if (settingKeys.contains('mapRoleToPremiumOpPay')) {
            mapSetting.put('mapRoleToPremiumOpPay', skedUtils.getMapRoleToPremiumOpPay());
        }
        if (settingKeys.contains('resourceRoleGroups')) {
            List<sked_Resource_Role_Group__c> resourceRoleGroups = [SELECT Id, sked_Resource_Role_Group__c, sked_Resource_Roles__c
                                                                    FROM sked_Resource_Role_Group__c];
            Map<string, List<string>> mapResourceRoleGroup = new Map<string, List<string>>();
            for (sked_Resource_Role_Group__c resourceRoleGroup : resourceRoleGroups) {
                List<string> resourceRoles = resourceRoleGroup.sked_Resource_Roles__c.split(';');
                mapResourceRoleGroup.put(resourceRoleGroup.sked_Resource_Role_Group__c, resourceRoles);
            }
            mapSetting.put('resourceRoleGroups', mapResourceRoleGroup);
        }
        if (settingKeys.contains('lunchBreakSettings')) {
            List<sked_Lunch_Break_Setting__c> lunchBreakSettings = [SELECT Id, Name, sked_Maximum_Lunch_Break_Duration__c,
                                                                    (SELECT Id, Name, sked_Lunch_Break_Duration__c,
                                                                     sked_Lunch_Break_Setting__c, sked_Max_Number_of_Staff__c,
                                                                     sked_Min_Number_of_Staff__c, sked_Slot_Reduction__c
                                                                     FROM sked_Lunch_Break_Definitions__r)
                                                                    FROM sked_Lunch_Break_Setting__c];
            mapSetting.put('lunchBreakSettings', lunchBreakSettings);
        }
        if (settingKeys.contains('maxCDLDOTDuration')) {
            mapSetting.put('maxCDLDOTDuration', skedSetting.instance.Admin.maxCDLDOTDuration);
        }
        if (settingKeys.contains('exceptionSettings')) {
            List<sked_Exception_Setting__c> exceptionSettings = [SELECT Id, Name, sked_Exception__c, sked_Exception_Code__c, sked_Priority__c
                                                                 FROM sked_Exception_Setting__c];
            mapSetting.put('exceptionSettings', exceptionSettings);
        }
        if (settingKeys.contains('staffSetupExcludedRoles')) {
            List<sked_Staff_Setup_Excluded_Role__c> staffSetupExcludedRoles = [SELECT sked_Resource_Role__c, sked_Excluded_For_Staff_Allocated__c, sked_Excluded_for_Assigned_Staff_Count__c
                                              FROM sked_Staff_Setup_Excluded_Role__c];
            mapSetting.put('staffSetupExcludedRoles', staffSetupExcludedRoles);
        }
        if (settingKeys.contains('travelTimeManager')) {
            mapSetting.put('travelTimeManager', new slwcSetting.travelTimeManager());
        }
        if (settingKeys.contains('optimizerDefaultWeights')) {
            mapSetting.put('optimizerDefaultWeights', new slwcSetting.optimizerDefaultWeights());
        }
        if (settingKeys.contains('optimizerDefaultSettings')) {
            mapSetting.put('optimizerDefaultSettings', new slwcSetting.optimizerDefaultSettings());
        }
        if (settingKeys.contains('rtvAPSApprovalWindow')) {
            mapSetting.put('rtvAPSApprovalWindow', skedSetting.instance.Admin.rtvAPSApprovalWindow);
        }

        result.returnedData = mapSetting;
        
        return result;
    }
    
    @AuraEnabled
    public static string getSObjectName(string recordId) {
        Id idValue = Id.valueOf(recordId);
        return idValue.getSobjectType().getDescribe().getName();
    }
    
    @AuraEnabled
    public static slwcAuraResult getPicklistOptions(string objectApiName, string fieldApiName) {
        slwcAuraResult result = new slwcAuraResult();
        
        List<picklistOptionModel> options = new List<picklistOptionModel>();

        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
        DescribeSObjectResult objDescribe = targetType.getDescribe();
        map<String, SObjectField> mapFields = objDescribe.fields.getmap();
        SObjectField fieldType = mapFields.get(fieldApiName);
        DescribeFieldResult fieldResult = fieldType.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple) {
            picklistOptionModel option = new picklistOptionModel();
            option.label = f.getLabel();
            option.value = f.getValue();
            options.add(option);
        }
        result.returnedData = options;
        
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult getMapDependentOptions(string objectApiName, string controllingFieldApiName, string dependentFieldApiName) {
        slwcAuraResult result = new slwcAuraResult();
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
        DescribeSObjectResult objDescribe = targetType.getDescribe();
        map<String, SObjectField> mapFields = objDescribe.fields.getmap();
        
        Schema.SObjectField ctrlField = mapFields.get(controllingFieldApiName);
        Schema.SObjectField depField = mapFields.get(dependentFieldApiName);
        
        Map<String, List<String>> map_controlling_dependent = skedPicklistFieldUtils.getMapDependentOptions(ctrlField, depField);
        
        result.returnedData = map_controlling_dependent;
        return result;
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private static void insertRelatedList(List<sObjectWrapper> wrappers, DateTime executionTime) {
        Map<string, List<sObject>> mapRecordToInsert = new Map<string, List<sObject>>();
        Map<string, List<sObject>> mapRecordToUpdate = new Map<string, List<sObject>>();
        List<sObjectWrapper> allChildWrappers = new List<sObjectWrapper>();
        
        for (sObjectWrapper parentWrapper : wrappers) {
            if (parentWrapper.relatedListWrappers != NULL && !parentWrapper.relatedListWrappers.isEmpty()) {
                for (relatedListWrapper relatedList : parentWrapper.relatedListWrappers) {
                    List<sObject> recordsToInsert;
        			List<sObject> recordsToUpdate;
                        
                    if (mapRecordToInsert.containsKey(relatedList.sObjectType)) {
                        recordsToInsert = mapRecordToInsert.get(relatedList.sObjectType);
                    }
                    else {
                        recordsToInsert = new List<sObject>();
                        mapRecordToInsert.put(relatedList.sObjectType, recordsToInsert);
                    }
                    
                    if (mapRecordToUpdate.containsKey(relatedList.sObjectType)) {
                        recordsToUpdate = mapRecordToUpdate.get(relatedList.sObjectType);
                    }
                    else {
                        recordsToUpdate = new List<sObject>();
                        mapRecordToUpdate.put(relatedList.sObjectType, recordsToUpdate);
                    }
                    
                    for (sObjectWrapper childWrapper : relatedList.sObjectWrappers) {
                        if (!string.isBlank(childWrapper.sObj.Id)) {
                            if (childWrapper.isChanged == TRUE) {
                                recordsToUpdate.add(childWrapper.sObj);
                            }
                        }
                        else {
                            childWrapper.sObj.put(relatedList.parentField, parentWrapper.sObj.Id);
                            recordsToInsert.add(childWrapper.sObj);
                        }
                        allChildWrappers.add(childWrapper);
                    }
                }
            }
        }
        
        if (!mapRecordToInsert.isEmpty()) {
            for (string sObjectType : mapRecordToInsert.keySet()) {
                List<sObject> recordsToInsert = mapRecordToInsert.get(sObjectType);
                if (recordsToInsert != NULL && !recordsToInsert.isEmpty()) {
                    insert recordsToInsert;
                }
            }
        }
        if (!mapRecordToUpdate.isEmpty()) {
            for (string sObjectType : mapRecordToUpdate.keySet()) {
                List<sObject> recordsToUpdate = mapRecordToUpdate.get(sObjectType);
                if (recordsToUpdate != NULL && !recordsToUpdate.isEmpty()) {
                    updateRecordsWithErrorBuilt(recordsToUpdate, sObjectType);
                }
            }
        }
        
        if (!allChildWrappers.isEmpty()) {
            insertRelatedList(allChildWrappers, executionTime);
        }
    }
    
    private static void deleteRecords(List<deleteWrapper> deletedRecords) {
        if (deletedRecords != NULL && !deletedRecords.isEmpty()) {
            Map<integer, List<string>> map_level_ids = new Map<integer, List<string>>();
            buildHierarchyIdMap(map_level_ids, 1, deletedRecords);
            
            Set<integer> levelKeySet = map_level_ids.keySet();
            List<integer> levels = new List<integer>();
            levels.addAll(levelKeySet);
            levels.sort();
            
            Map<string, List<sObject>> mapRecordToDelete = new Map<string, List<sObject>>();
            for (integer i = levels.size() - 1; i >= 0; i--) {
                integer level = levels.get(i);
                List<string> ids = map_level_ids.get(level);
                ids.sort();
                
                for (string idStr : ids) {
                    Id recordId = Id.valueOf(idStr);
                    SObjectType sObjectType = recordId.getSObjectType();
                    string sObjectTypeName = sObjectType.getDescribe().getName();
                    sObject record = sObjectType.newSObject(recordId);
                    
                    List<sObject> recordsToDelete;
                    if (mapRecordToDelete.containsKey(sObjectTypeName)) {
                        recordsToDelete = mapRecordToDelete.get(sObjectTypeName);
                    }
                    else {
                        recordsToDelete = new List<sObject>();
                        mapRecordToDelete.put(sObjectTypeName, recordsToDelete);
                    }
                    recordsToDelete.add(record);
                }
            }
            for (string sObjectType : mapRecordToDelete.keySet()) {
                delete mapRecordToDelete.get(sObjectType);
            }
        }
    }
    
    private static void buildHierarchyIdMap(Map<integer, List<string>> map_level_ids, integer level, List<deleteWrapper> deletedRecords) {
        List<string> ids = map_level_ids.get(level);
        if (ids == NULL) {
            ids = new List<string>();
            map_level_ids.put(level, ids);
        }
        for (deleteWrapper deletedRecord : deletedRecords) {
            ids.add(deletedRecord.id);
            if (deletedRecord.children != NULL && !deletedRecord.children.isEmpty()) {
                buildHierarchyIdMap(map_level_ids, level + 1, deletedRecord.children);
            }
        }
    }

    private static void updateRecordsWithErrorBuilt(List<sObject> recordsToUpdate, String sObjectName) {
        List<Database.SaveResult> saveResults = Database.update(recordsToUpdate, false);
        String errorMessage = skedErrorUtils.getPartialUpdateErrorString(saveResults, recordsToUpdate, sObjectName);
        Database.SaveResult firstFailedSaveResult = findFirstFailedSaveResult(saveResults);
        if (String.isNotBlank(errorMessage)) {
            Map<String, Object> map_key_errorContent = new Map<String, Object>{
                'shortError' => firstFailedSaveResult.getErrors()[0].getMessage(),
                'fullError' => errorMessage
            };
            throw new skedException(JSON.serialize(map_key_errorContent));
        }
    }

    private static Database.SaveResult findFirstFailedSaveResult(List<Database.SaveResult> saveResults) {
        Database.SaveResult firstFailedSaveResult = NULL;
        for (Database.SaveResult saveResult : saveResults) {
            if (!saveResult.isSuccess()) {
                firstFailedSaveResult = saveResult;
                break;
            }
        }
        return firstFailedSaveResult;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class executeQueriesRequest {
        @AuraEnabled public List<queryModel> queries;
    }
    
    public class executeQueriesResponse {
        @AuraEnabled public List<queryResultModel> results;
    }
    
    public class queryModel {
        @AuraEnabled public String key {get; set;}
        @AuraEnabled public String query {get; set;}
        @AuraEnabled public String fieldToExtractId {get; set;}
    }
    
    public class queryResultModel {
        @AuraEnabled public String key {get; set; }
        @AuraEnabled public Object result {get; set;}
    }
    
    public class sObjectWrapper {
        @AuraEnabled public sObject sObj {get;set;}
        @AuraEnabled public List<relatedListWrapper> relatedListWrappers {get;set;}
        @AuraEnabled public boolean isChanged {get;set;}
    }
    
    public class relatedListWrapper {
        @AuraEnabled public string parentField {get;set;}
        @AuraEnabled public List<sObjectWrapper> sObjectWrappers {get;set;}
        @AuraEnabled public string sObjectType {get;set;}
    }
    
    public class deleteWrapper {
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public List<deleteWrapper> children {get;set;}
    }
    
    public class picklistOptionModel {
        @AuraEnabled public string label {get;set;}
        @AuraEnabled public string value {get;set;}
    }
    
}