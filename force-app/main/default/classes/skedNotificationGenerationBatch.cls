global class skedNotificationGenerationBatch extends skedNotificationBatchBase implements Schedulable, Database.Batchable<sked_Notification_Setting__mdt> {
    protected List<sked_Notification_Setting__mdt> notificationSettings;
    protected Map<Id, notificationSettingRecordData> map_notiSettingId_recordData;

    global skedNotificationGenerationBatch(List<sked_Notification_Setting__mdt> notificationSettings, Map<Id, notificationSettingRecordData> map_notiSettingId_recordData) {
        this.notificationSettings = notificationSettings;
        this.map_notiSettingId_recordData = map_notiSettingId_recordData;
    }

    global void execute() {
        if (System.isBatch() || System.isFuture()) {
            skedUtils.scheduleUniqueJobInSeconds('skedNotificationGenerationBatch', this, 10, false);
        } else {
            Database.executeBatch(this, 1);
        }
    }

    global void execute(SchedulableContext SC) {
        Database.executeBatch(this, 1);
    }

    global List<sked_Notification_Setting__mdt> start(Database.BatchableContext BC) {
        return this.notificationSettings;
    }

    global void execute(Database.BatchableContext BC, List<sked_Notification_Setting__mdt> notificationSettings) {
        //NOTE: This batch needs to be executed with  limit chunk size to avoid SOQL 101 error, each setting item will handle a number of records.
        this.generateNotifications(new Map<Id, sked_Notification_Setting__mdt>(notificationSettings).keySet());
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void generateNotifications(Set<Id> notificationSettingIds) {
        Map<Id, notificationSettingModel> map_id_settingModel = this.getNotificationSettingsMap(notificationSettingIds);
        List<BSF_Custom_Notification__c> bsfCustomNotifications = new List<BSF_Custom_Notification__c>();
        for (Id settingId : notificationSettingIds) {
            if (this.map_notiSettingId_recordData.containsKey(settingId)) {
                this.initialize(settingId, map_id_settingModel);
                
                List<sObject> records = this.retrieveTargetRecords();
                if (string.isNotBlank(this.notificationSetting.contentRenderer)) {
                    Set<Id> inputRecordIds = new Set<Id>();
                    for (sObject record : records) {
                        inputRecordIds.add(record.Id);
                    }
                    this.contentRenderer.process(inputRecordIds, newRecords, oldMap);
                }
                if(!string.isBlank(this.notificationSetting.customTargetDestination)) {
                    Set<Id> inputRecordIds = new Set<Id>();
                    for (sObject record : records) {
                        inputRecordIds.add(record.Id);
                    }
                    this.customTargetDestination.process(inputRecordIds, records);
                }
                bsfCustomNotifications.addAll(this.generateBsfCustomNotifications(records));
            }
        }

        if (!bsfCustomNotifications.isEmpty()) {
            insert bsfCustomNotifications;
        }
    }

    /************************************************* Private methods *******************************************************/
    private void initialize(Id notificationSettingId, Map<Id, notificationSettingModel> map_id_settingModel) {
        this.notificationSetting = map_id_settingModel.get(notificationSettingId);
        notificationSettingRecordData recordData = this.map_notiSettingId_recordData.get(notificationSettingId);
        this.recordIds = recordData.recordIds;
        this.newRecords = recordData.newRecords;
        this.oldMap = recordData.oldMap;

		this.baseInitialize();
    }

    /************************************************* Nested classes *******************************************************/
    global class notificationSettingRecordData {
        global Set<Id> recordIds;
        global List<sObject> newRecords;
        global Map<Id, sObject> oldMap;

        global notificationSettingRecordData(Set<Id> recordIds, List<sObject> newRecords, Map<Id, sObject> oldMap) {
            this.recordIds = recordIds;
            this.newRecords = newRecords;
            this.oldMap = oldMap;
        }
    }
}