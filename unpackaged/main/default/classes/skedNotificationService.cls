public abstract class skedNotificationService {
    public void generateNotifications(List<sObject> newRecords, Map<Id, sObject> oldMap) {
        if (skedSetting.instance.Notification.notificationGenerationEnabled) {
            List<sked_Notification_Setting__mdt> skedNotificationSettings = fetchNotifcationSettings();
            Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData> map_notiSettingId_recordData = getNotificationSettingRecordDataMap(skedNotificationSettings, newRecords, oldMap);

            if (!map_notiSettingId_recordData.isEmpty()) {
                this.generateThroughPlatformEvents(skedNotificationSettings, map_notiSettingId_recordData);
            }
        }
    }

    public void generateNotifications(List<sObject> newRecords) {
        this.generateNotifications(newRecords, new Map<Id, sObject>());
    }

    protected List<sked_Notification_Setting__mdt> fetchNotifcationSettings() {
        skedQueryBuilder queryBuilder = new skedQueryBuilder();
        queryBuilder.setFromClause('sked_Notification_Setting__mdt');
        queryBuilder.addFields(new List<String> {
            'Id', 'sked_Priority__c', 'sked_Active__c', 'sked_Notification_Type__c', 'sked_Content_Renderer__c'
        });
        queryBuilder.addFields(getAdditionalFieldsToFetchNotificationSettings());
        buildQueryConditionsToFetchNotificationSettings(queryBuilder);

        List<sked_Notification_Setting__mdt> activeNotificationSettings = new List<sked_Notification_Setting__mdt>();
        for (sked_Notification_Setting__mdt setting : Database.query(queryBuilder.toString())) {
            if (setting.sked_Active__c || Test.isRunningTest()) {
                activeNotificationSettings.add(setting);
            }
        }
        
        return activeNotificationSettings;
    }

    protected virtual List<String> getAdditionalFieldsToFetchNotificationSettings() {
        return new List<String>();
    }

    protected virtual void buildQueryConditionsToFetchNotificationSettings(skedQueryBuilder queryBuilder) {
    }

    /////////////////////////////////////////////////////////////////////////// Private methods ///////////////////////////////////////////////////////////////////////////
    private void generateThroughPlatformEvents(List<sked_Notification_Setting__mdt> skedNotificationSettings, Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData> map_notiSettingId_recordData) {
        for (sked_Notification_Setting__mdt skedNotificationSetting : skedNotificationSettings) {
            skedNotificationGenerationBatch.notificationSettingRecordData recordData = map_notiSettingId_recordData.get(skedNotificationSetting.Id);
            if (recordData != NULL) {
                recordData.newRecords = this.transformToNewRecordsForRenderer(skedNotificationSetting, recordData.newRecords);
                recordData.oldMap = this.transformToOldMapForRenderer(skedNotificationSetting, recordData.oldMap);
            }
        }

        skedFutureCallEventHandler.publishFutureCallEvent(
            skedNotificationGenerationEventHandler.class.getName(), 
            'generateNotifications', 
            skedNotificationSettings, 
            map_notiSettingId_recordData
        );
    }

    private Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData> getNotificationSettingRecordDataMap(
        List<sked_Notification_Setting__mdt> skedNotificationSettings,
        List<sObject> newRecords,
        Map<Id, sObject> oldMap
    ) {
        Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData> map_notiSettingId_recordData = new Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData>();
        for (sked_Notification_Setting__mdt skedNotificationSetting : skedNotificationSettings) {
            Map<Id, sObject> mapNewRecord = new Map<Id, sObject>(newRecords);

            if (!newRecords.isEmpty()) {
                Set<Id> recordIdsNeedToBeNotified = getRecordIdsNeedToBeNotified(newRecords, oldMap, skedNotificationSetting);
                if (!recordIdsNeedToBeNotified.isEmpty()) {
                    List<sObject> newRecordsPerSetting = new List<sObject>();
                    Map<Id, sObject> oldMapPerSetting = new Map<Id, sObject>();
                    
                    for (Id recordId : recordIdsNeedToBeNotified) {                        
                        sObject newRecord = mapNewRecord.get(recordId);
                        newRecordsPerSetting.add(newRecord);
                        
                        if (oldMap != NULL && oldMap.containsKey(recordId)) {
                            sObject oldData = oldMap.get(recordId);
                            oldMapPerSetting.put(recordId, oldData);
                        }
                    }

                    map_notiSettingId_recordData.put(
                        skedNotificationSetting.Id,
                        new skedNotificationGenerationBatch.notificationSettingRecordData(recordIdsNeedToBeNotified, newRecordsPerSetting, oldMapPerSetting)
                    );
                }
            }
        }

        return map_notiSettingId_recordData;
    }

    private List<sObject> transformToNewRecordsForRenderer(sked_Notification_Setting__mdt skedNotificationSetting, List<sObject> newRecords) {
        List<sObject> transformedNewRecords = new List<sObject>();
        if (String.isNotBlank(skedNotificationSetting.sked_Content_Renderer__c) && !newRecords.isEmpty()) {
            List<String> fieldNames = getFieldNamesBySObjectType(newRecords[0].getSObjectType());
            skedNotificationBatchBase.contentRendererBase contentRenderer = skedNotificationBatchBase.getContentRendererInstance(skedNotificationSetting.sked_Content_Renderer__c);
            if (!contentRenderer.fieldsForRenderer.isEmpty()) {
                for (sObject record : newRecords) {
                    Map<String, Object> map_fieldName_fieldValue = buildMapFieldNameFieldValueForRenderer(record, contentRenderer.fieldsForRenderer);
                    transformedNewRecords.add((sObject)JSON.deserialize(JSON.serialize(map_fieldName_fieldValue), SObject.class));
                }    
            }
        }
        return transformedNewRecords;
    }

    private Map<String, Object> buildMapFieldNameFieldValueForRenderer(sObject record, List<String> fieldForRenderers) {
        string sObjectApiName = record.Id.getSobjectType().getDescribe().getName();

        Map<String, Object> map_fieldName_fieldValue = new Map<String, Object>();
        map_fieldName_fieldValue.put('attributes', new Map<String, String> { 'type' => sObjectApiName});
        
        for (String fieldForRenderer : fieldForRenderers) {
            map_fieldName_fieldValue.put(fieldForRenderer, record.get(fieldForRenderer));
        }
        return map_fieldName_fieldValue;
    }

    private Map<Id, sObject> transformToOldMapForRenderer(sked_Notification_Setting__mdt skedNotificationSetting, Map<Id, sObject> oldMap) {
        Map<Id, sObject> transformedOldMap = new Map<Id, sObject>();
        if (String.isNotBlank(skedNotificationSetting.sked_Content_Renderer__c) && !oldMap.isEmpty()) {
            List<String> fieldNames = getFieldNamesBySObjectType(oldMap.values().get(0).getSObjectType());
            skedNotificationBatchBase.contentRendererBase contentRenderer = skedNotificationBatchBase.getContentRendererInstance(skedNotificationSetting.sked_Content_Renderer__c);
            for (Id recordId : oldMap.keySet()) {
                sObject oldRecord = oldMap.get(recordId);
                Map<String, Object> map_fieldName_fieldValue = buildMapFieldNameFieldValueForRenderer(oldRecord, contentRenderer.fieldsForRenderer);
                transformedOldMap.put(recordId, (sObject)JSON.deserialize(JSON.serialize(map_fieldName_fieldValue), SObject.class));
            }
        }
        return transformedOldMap;
    }

    private List<String> getFieldNamesBySObjectType(Schema.SObjectType sObjectType) {
        List<String> fieldNames = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = sked_Drive__c.sObjectType.getDescribe().fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            fieldNames.add(fieldName);
        }
        return fieldNames;
    }

    protected virtual Set<Id> getRecordIdsNeedToBeNotified(
        List<sObject> newRecords,
        Map<Id, sObject> oldMap,
        sked_Notification_Setting__mdt skedNotificationSetting
    ) {
        return getAllRecordIds(newRecords);
    }

    private Set<Id> getAllRecordIds(List<sObject> newRecords) {
        Set<Id> recordIds = new Set<Id>();
        for (sObject record : newRecords) {
            recordIds.add(record.Id);
        }

        return recordIds;
    }
}