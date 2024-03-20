public class skedNotificationService {
    
    public static void addNotificationQueueItems(string action, string sObjectName, List<sObject> newRecords, Map<Id, sObject> oldMap) {
        List<sked_Notification_Setting__mdt> skedNotificationSettings = [SELECT Id, sked_Notification_Type__c, sked_Active__c,
                                                                         sked_Target_Field__c, sked_Target_Field_Value__c
                                                                         FROM sked_Notification_Setting__mdt
                                                                         WHERE sked_Target_SObject__c = :sObjectName
                                                                         AND sked_Trigger__c = :action];
        
        if (!skedNotificationSettings.isEmpty()) {
            integer numberOfRecordsPerBatch = skedSetting.instance.Notification.numberOfRecordsPerQueueItem;
            List<sked_Notification_Queue_Item__c> newItems = new List<sked_Notification_Queue_Item__c>();
            
            for (sked_Notification_Setting__mdt skedNotificationSetting : skedNotificationSettings) {
                if (skedNotificationSetting.sked_Active__c || Test.isRunningTest()) {
                    List<sObject> filteredRecords = newRecords;
                    Map<Id, sObject> mapNewRecord = new Map<Id, sObject>(newRecords);
                    
                    if (!filteredRecords.isEmpty()) {
                        List<Id> recordIds = new List<Id>();
                        if (action == 'Insert') {
                            for (sObject record : filteredRecords) {
                                if (!string.isBlank(skedNotificationSetting.sked_Target_Field_Value__c)) {
                                    Object targetFieldValue = record.get(skedNotificationSetting.sked_Target_Field__c);
                                    string targetFieldStrValue = string.valueOf(targetFieldValue);
                                    if (targetFieldStrValue != NULL && targetFieldStrValue.equalsIgnoreCase(skedNotificationSetting.sked_Target_Field_Value__c)) {
                                        recordIds.add(record.Id);
                                    }
                                }
                                else {
                                    recordIds.add(record.Id);
                                }
                            }
                        }
                        else if (action == 'Update') {
                            for (sObject record : filteredRecords) {
                                sObject oldData = oldMap.get(record.Id);
                                Object targetFieldValue = record.get(skedNotificationSetting.sked_Target_Field__c);
                                Object targetFieldOldValue = oldData.get(skedNotificationSetting.sked_Target_Field__c);
                                string targetFieldStrValue = string.valueOf(targetFieldValue);
                                targetFieldStrValue = targetFieldStrValue == NULL ? '' : targetFieldStrValue;
                                if (targetFieldValue != targetFieldOldValue && targetFieldStrValue.equalsIgnoreCase(skedNotificationSetting.sked_Target_Field_Value__c)) {
                                    recordIds.add(record.Id);
                                }
                            }
                        }
                        if (!recordIds.isEmpty()) {
                            Set<Id> recordIdsPerBatch = new Set<Id>();
                            List<sObject> newRecordsPerBatch = new List<sObject>();
                            Map<Id, sObject> oldMapPerBatch = new Map<Id, sObject>();
                            
                            for (integer i = 1; i <= recordIds.size(); i++) {
                                Id recordId = recordIds.get(i - 1);
                                recordIdsPerBatch.add(recordId);
                                
                                sObject newRecord = mapNewRecord.get(recordId);
                                newRecordsPerBatch.add(newRecord);
                                
                                if (oldMap != NULL && oldMap.containsKey(recordId)) {
                                    sObject oldData = oldMap.get(recordId);
                                    oldMapPerBatch.put(recordId, oldData);
                                }
                                
                                if (Math.mod(i, numberOfRecordsPerBatch) == 0 || i == recordIds.size()) {
                                    sked_Notification_Queue_Item__c queueItem = new sked_Notification_Queue_Item__c(
                                        sked_Notification_Setting_Id__c = skedNotificationSetting.Id,
                                        sked_Notification_Type__c = skedNotificationSetting.sked_Notification_Type__c,
                                        sked_Number_Of_Records__c = recordIdsPerBatch.size(),
                                        sked_Batch_Params_1__c = JSON.serialize(recordIdsPerBatch),
                                        sked_Batch_Params_2__c = JSON.serialize(newRecordsPerBatch),
                                        sked_Batch_Params_3__c = JSON.serialize(oldMapPerBatch),
                                        sked_Priority__c = 10000
                                    );
                                    newItems.add(queueItem);
                                    
                                    recordIdsPerBatch = new Set<Id>();
                                    newRecordsPerBatch = new List<sObject>();
                                    oldMapPerBatch = new Map<Id, sObject>();
                                }
                            }
                        }
                    }
                }
            }
            if (!newItems.isEmpty()) {
                insert newItems;
            }
        }
    }
    
}