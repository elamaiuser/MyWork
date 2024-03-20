global class skedNotificationQueueBatch extends skedNotificationBatchBase implements Schedulable, Database.Batchable<sked_Notification_Queue_Item__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected Set<Id> processedQueueItemIds;
    protected Map<Id, string> map_errorQueueItemId_errorMessage;
    
    global skedNotificationQueueBatch() {
        this.processedQueueItemIds = new Set<Id>();
        this.map_errorQueueItemId_errorMessage = new Map<Id, string>();
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new skedNotificationQueueBatch(), 1);
    }
    
    global List<sked_Notification_Queue_Item__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Notification_Setting_Id__c, sked_Batch_Params_1__c,
                sked_Batch_Params_2__c, sked_Batch_Params_3__c, sked_Priority__c
                FROM sked_Notification_Queue_Item__c
                WHERE sked_Status__c = 'Queued'
                ORDER BY sked_Priority__c ASC, CreatedDate ASC
                LIMIT 100];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Notification_Queue_Item__c> queueItems) {
        //NOTE: This batch needs to be executed with chunk size = 1, each queue item will handle a number of records.
        for (sked_Notification_Queue_Item__c queueItem : queueItems) {
            try {
                this.initialize(queueItem);
                
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
                this.sendNotification(this.notificationSetting.notificationType, records);
            }
            catch (Exception ex) {
                string errorMessage = ex.getStackTraceString() + ' ' + ex.getMessage();
                this.map_errorQueueItemId_errorMessage.put(queueItem.Id, errorMessage);
            }
            this.processedQueueItemIds.add(queueItem.Id);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if (this.processedQueueItemIds != NULL && !this.processedQueueItemIds.isEmpty()) {
            List<sked_Notification_Queue_Item__c> processedQueueItems = new List<sked_Notification_Queue_Item__c>();
            for (Id processedQueueItemId : this.processedQueueItemIds) {
                sked_Notification_Queue_Item__c processedQueueItem = new sked_Notification_Queue_Item__c(
                    Id = processedQueueItemId,
                    sked_Status__c = 'Completed'
                );
                processedQueueItem.sked_Status__c = map_errorQueueItemId_errorMessage.containsKey(processedQueueItemId) 
                    ? 'Error' : processedQueueItem.sked_Status__c;
                processedQueueItem.sked_Error_Message__c = map_errorQueueItemId_errorMessage.get(processedQueueItemId);
                processedQueueItems.add(processedQueueItem);
            }
            update processedQueueItems;
        }
        
        if (!Test.isRunningTest()) {
            System.scheduleBatch(new skedNotificationQueueBatch(), 'skedNotificationQueueBatch_' + String.valueOf(Datetime.now()), 10, 1);
        }
    }
    
    /************************************************* Private methods *******************************************************/
    private void initialize(sked_Notification_Queue_Item__c queueItem) {
        this.notificationSetting = this.getNotificationSetting(queueItem.sked_Notification_Setting_Id__c);
        this.recordIds = (Set<Id>)JSON.deserialize(queueItem.sked_Batch_Params_1__c, Set<Id>.class);
        this.newRecords = (List<SObject>)JSON.deserialize(queueItem.sked_Batch_Params_2__c, List<SObject>.class);
        this.oldMap = (Map<Id, SObject>)JSON.deserialize(queueItem.sked_Batch_Params_3__c, Map<Id, SObject>.class);

		this.baseInitialize();
    }
    
}