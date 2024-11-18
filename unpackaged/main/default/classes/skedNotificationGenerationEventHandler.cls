public class skedNotificationGenerationEventHandler implements Callable {

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'generateNotifications' {
                    generateNotifications(
                        (List<sked_Notification_Setting__mdt>) JSON.deserialize((String) params.get('param1'), List<sked_Notification_Setting__mdt>.class),
                        (Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData>) JSON.deserialize((String) params.get('param2'), Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData>.class)
                    );
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedBiomedCollectionOpHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    public static void generateNotifications(List<sked_Notification_Setting__mdt> skedNotificationSettings, Map<Id, skedNotificationGenerationBatch.notificationSettingRecordData> map_notiSettingId_recordData) {
        skedNotificationGenerationBatch batch = new skedNotificationGenerationBatch(skedNotificationSettings, map_notiSettingId_recordData);
        System.debug('@@@skedNotificationSettings: ' + JSON.serialize(skedNotificationSettings));
        System.debug('@@@map_notiSettingId_recordData: ' + JSON.serialize(map_notiSettingId_recordData));
        batch.execute(null, skedNotificationSettings);
    }
}