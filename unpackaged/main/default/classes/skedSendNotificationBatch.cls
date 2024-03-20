global class skedSendNotificationBatch extends skedNotificationBatchBase implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    protected List<notificationSettingModel> notificationSettings;
    
    global skedSendNotificationBatch(Map<Id, Set<Id>> map_settingId_recordIds) {
        this.notificationSettings = getNotificationSettings(map_settingId_recordIds);
        initialize();
    }
    
    global skedSendNotificationBatch(Map<Id, Set<Id>> map_settingId_recordIds, List<SObject> newRecords, Map<Id, SObject> oldMap) {
        this.notificationSettings = getNotificationSettings(map_settingId_recordIds);
        initialize();

        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }
    
    global skedSendNotificationBatch(List<notificationSettingModel> settings) {
        this.notificationSettings = settings;
        initialize();
    }

    global skedSendNotificationBatch(List<notificationSettingModel> settings, List<SObject> newRecords, Map<Id, SObject> oldMap) {
        this.notificationSettings = settings;
        initialize();

        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }
    
    global List<sObject> start(Database.BatchableContext BC) {
        return this.retrieveTargetRecords();
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> records) {
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
        this.sendNotification(this.notificationSetting.notificationType, records);
    }
    
    global void finish(Database.BatchableContext BC) {
        this.notificationSettings.remove(0);
        if (!this.notificationSettings.isEmpty()) {
            skedSendNotificationBatch nextBatchJob = new skedSendNotificationBatch(this.notificationSettings, this.newRecords, this.oldMap);
            Database.executeBatch(nextBatchJob, 20);
        }
    }
    
    /************************************************* Private methods *******************************************************/
    private List<notificationSettingModel> getNotificationSettings(Map<Id, Set<Id>> map_settingId_recordIds) {
        List<notificationSettingModel> notificationSettings = new List<notificationSettingModel>();
        List<sked_Notification_Setting__mdt> skedNotificationSettings = [SELECT Id, DeveloperName, sked_Target_SObject__c, sked_Target_Field__c, 
                                                                         sked_Target_Field_Value__c, sked_Notification_Type__c, sked_Filter__c,
                                                                         sked_Destination_Field__c, sked_Notification_Target_Field__c, 
                                                                         sked_Email_From_Address_Field__c, sked_Template__c, 
                                                                         sked_Sending_From_Email_Address__c, sked_Custom_Target_Destination__c,
                                                                         sked_Content_Renderer__c, sked_Oneoff_Protocol_Field__c, sked_Subject__c,
                                                                         (SELECT Id, sked_Date_Time_Field__c, sked_Format_For_Token__c, 
                                                                          sked_Format_String__c, sked_Timezone_Field__c
                                                                          FROM sked_Notification_Formats__r)
                                                                         FROM sked_Notification_Setting__mdt
                                                                         WHERE Id IN :map_settingId_recordIds.keySet()];
        for (sked_Notification_Setting__mdt skedNotificationSetting : skedNotificationSettings) {
            Set<Id> recordIds = map_settingId_recordIds.get(skedNotificationSetting.Id);
            skedSendNotificationBatch.notificationSettingModel setting = new skedSendNotificationBatch.notificationSettingModel(skedNotificationSetting, recordIds);
            notificationSettings.add(setting);
        }
        return notificationSettings;
    }
    
    private void initialize() {
        this.notificationSetting = this.notificationSettings.get(0);
        this.recordIds = this.notificationSetting.recordIds;

		this.baseInitialize();
    }

}