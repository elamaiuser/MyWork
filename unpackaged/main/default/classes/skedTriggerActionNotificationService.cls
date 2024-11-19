public class skedTriggerActionNotificationService extends skedNotificationService {
    private String action;
    private String sObjectName;

    public skedTriggerActionNotificationService(String action, String sObjectName) {
        this.action = action;
        this.sObjectName = sObjectName;
    }
    
    protected override List<String> getAdditionalFieldsToFetchNotificationSettings() {
        return new List<String> {
            'sked_Target_Field__c', 'sked_Target_Field_Value__c', 'sked_Target_Field_Values__c'
        };
    }

    protected override void buildQueryConditionsToFetchNotificationSettings(skedQueryBuilder queryBuilder) {
        queryBuilder.addCondition('sked_Target_SObject__c = {0}', this.sObjectName);
        queryBuilder.addCondition('sked_Trigger__c = {0}', this.action);
    }

    protected override Set<Id> getRecordIdsNeedToBeNotified(
        List<sObject> newRecords,
        Map<Id, sObject> oldMap,
        sked_Notification_Setting__mdt skedNotificationSetting
    ) {
        Set<Id> recordIdsNeedToBeNotified = new Set<Id>();
        if (action == 'Insert') {
            for (sObject record : newRecords) {
                if (!string.isBlank(skedNotificationSetting.sked_Target_Field_Value__c)) {
                    Object targetFieldValue = record.get(skedNotificationSetting.sked_Target_Field__c);
                    string targetFieldStrValue = string.valueOf(targetFieldValue);
                    if (targetFieldStrValue != null && targetFieldStrValue.equalsIgnoreCase(skedNotificationSetting.sked_Target_Field_Value__c)) {
                        recordIdsNeedToBeNotified.add(record.Id);
                    }
                } else if (!string.isBlank(skedNotificationSetting.sked_Target_Field_Values__c)) {
                    Object targetFieldValue = record.get(skedNotificationSetting.sked_Target_Field__c);
                    string targetFieldStrValue = string.valueOf(targetFieldValue);  
                    List<String> values = skedNotificationSetting.sked_Target_Field_Values__c.split(';');
                    if (targetFieldStrValue != null && values != null && values.contains(targetFieldStrValue)) {
                        recordIdsNeedToBeNotified.add(record.Id);
                    }
                } else {
                    recordIdsNeedToBeNotified.add(record.Id);
                }
            }
        }
        else if (action == 'Update') {
            for (sObject record : newRecords) {
                sObject oldData = oldMap.get(record.Id);
                if (!string.isBlank(skedNotificationSetting.sked_Target_Field_Value__c)) {
                    Object targetFieldValue = record.get(skedNotificationSetting.sked_Target_Field__c);
                    Object targetFieldOldValue = oldData.get(skedNotificationSetting.sked_Target_Field__c);
                    if (targetFieldValue != targetFieldOldValue) {
                        string targetFieldStrValue = string.valueOf(targetFieldValue);
                        targetFieldStrValue = targetFieldStrValue == NULL ? '' : targetFieldStrValue;
                        if (targetFieldStrValue.equalsIgnoreCase(skedNotificationSetting.sked_Target_Field_Value__c)) {
                            recordIdsNeedToBeNotified.add(record.Id);
                        }
                    }
                } else if (!string.isBlank(skedNotificationSetting.sked_Target_Field_Values__c)) {
                    Object targetFieldValue = record.get(skedNotificationSetting.sked_Target_Field__c);
                    Object targetFieldOldValue = oldData.get(skedNotificationSetting.sked_Target_Field__c);
                    if (targetFieldValue != targetFieldOldValue) {
                        string targetFieldStrValue = string.valueOf(targetFieldValue);
                        targetFieldStrValue = targetFieldStrValue == NULL ? '' : targetFieldStrValue;
                        List<String> values = skedNotificationSetting.sked_Target_Field_Values__c.split(';');
                        if (values != null && values.contains(targetFieldStrValue)) {
                            recordIdsNeedToBeNotified.add(record.Id);
                        }
                    }
                } else {
                    recordIdsNeedToBeNotified.add(record.Id);
                }
            }
        }

        return recordIdsNeedToBeNotified;
    }
}