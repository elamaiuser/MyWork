public without sharing class BSFCustomNotificationTriggerHandler extends TriggerHandler{
    public static NotificationThrottleBatchSettings__mdt batchSettings = 	NotificationThrottleBatchSettings__mdt.getInstance('NotificnThrottleBatchConfig');
    public override void beforeInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('updatePriority') == -1) { 
            updatePriority((List<BSF_Custom_Notification__c>)trigger.new);
        }
        if(super.getTriggerMethodsToBypass().indexOf('updatePhoneNumber') == -1) { 
            updatePhoneNumber((List<BSF_Custom_Notification__c>)trigger.new);
        }
    }
    public override void afterInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('processNotifications') == -1) { 
            processNotifications((List<BSF_Custom_Notification__c>)trigger.new, null);
        }
    }
    public override void beforeUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('updatePriority') == -1) {
            updatePriority((List<BSF_Custom_Notification__c>)trigger.new);
        }
        if(super.getTriggerMethodsToBypass().indexOf('updatePhoneNumber') == -1) { 
            updatePhoneNumber((List<BSF_Custom_Notification__c>)trigger.new);
        }
    }
    public override void afterUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('processNotifications') == -1) {
            processNotifications((List<BSF_Custom_Notification__c>)trigger.new, (Map<Id,BSF_Custom_Notification__c>)trigger.oldMap);
        }
    }
    public static void processNotifications(List<BSF_Custom_Notification__c> newList, Map<Id,BSF_Custom_Notification__c> oldMap){
        List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_EMAIL, BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH, BSF_Constants.NOTIFICATION_TYPE_ONEOFF, BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS};
        Boolean runBatch = false;
        for(BSF_Custom_Notification__c notifn : newList){
            if(oldMap == null || oldMap.isEmpty()){
                if(String.isNotBlank(notifn.Status__c) && notifn.Status__c.equalsIgnoreCase('Queued')
                        && String.isNotBlank(notifn.Notification_Type__c) && notificationTypeList.contains(notifn.Notification_Type__c)){
                            runBatch = true;
                            break;
                }
            }else{
                if(String.isNotBlank(notifn.Status__c) && notifn.Status__c.equalsIgnoreCase('Queued')
                        && String.isNotBlank(notifn.Notification_Type__c) && notificationTypeList.contains(notifn.Notification_Type__c)
                        && oldMap.containsKey(notifn.Id) && oldMap.get(notifn.Id).Status__c != notifn.Status__c){
                            runBatch = true;
                            break;
                }
            }
        }
        /*if(runBatch && !System.isFuture() && !System.IsBatch()){
            BSFNotificationThrottlerUtil.executeBatch(notificationTypeList);
        }else if(runBatch && !System.isFuture() && System.IsBatch()){
            BSFNotificationThrottlerUtil.scheduleBatch(notificationTypeList,1);
        }*/
        if(runBatch && !System.isFuture()){
            BSFNotificationThrottlerUtil.scheduleBatch(notificationTypeList,1);
        }
    }
    public static void updatePriority(List<BSF_Custom_Notification__c> newList){
        for(BSF_Custom_Notification__c notifn : newList){
            if(notifn.Priority__c == null || notifn.Priority__c > batchSettings.MinPriority__c || notifn.Priority__c < batchSettings.MaxPriority__c){
                notifn.Priority__c = batchSettings.MinPriority__c;
            }
        }
    }
    public static void updateSubject(List<BSF_Custom_Notification__c> newList){
        for(BSF_Custom_Notification__c record : newList){
            if((record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_EMAIL
                    || record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH)
                    && String.isBlank(record.Subject__c)){
                        record.Subject__c = batchSettings.GeneicSubject__c;
            }
        }
    }
    public static void updatePhoneNumber(List<BSF_Custom_Notification__c> newList){
        Map<Id,String> resourcePhoneMap = new Map<Id,String>();
        for(BSF_Custom_Notification__c record : newList){
            if((record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS)
                    && String.isNotBlank(record.Destination_Id__c) && String.isBlank(record.Phone_Number__c)){
                        resourcePhoneMap.put(record.Destination_Id__c,'');
            }
        }
        if(!resourcePhoneMap.isEmpty()){
            List<sked__Resource__c> resourceList = [SELECT Id, 
                                                            sked__Primary_Phone__c
                                                    FROM sked__Resource__c 
                                                    WHERE Id IN :resourcePhoneMap.keySet()
                                                    AND sked__Primary_Phone__c != null];
            for(sked__Resource__c res : resourceList){
                resourcePhoneMap.put(res.Id,res.sked__Primary_Phone__c);
            }
            for(BSF_Custom_Notification__c record : newList){
                if((record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS)
                        && String.isNotBlank(record.Destination_Id__c) && String.isBlank(record.Phone_Number__c) 
                        && resourcePhoneMap.containsKey(record.Destination_Id__c)
                        && String.isNotBlank(resourcePhoneMap.get(record.Destination_Id__c))){
                            record.Phone_Number__c = resourcePhoneMap.get(record.Destination_Id__c);
                }
            }
        }
    }
}