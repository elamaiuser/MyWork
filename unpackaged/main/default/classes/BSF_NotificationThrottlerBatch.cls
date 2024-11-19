global without sharing class BSF_NotificationThrottlerBatch implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    //Stateful constants
	private final Map<String,Decimal> MAXLIMITS;
    private final Map<String,Decimal> HIGH_PRIORITY_THRESHOLDS;
    private final Map<String,Decimal> OTHER_PRIORITY_THRESHOLDS;
    private final List<String> NOTIFICATION_TYPES;
    private final Map<String,Id> ORGWIDEE_MAILADDRESSMAP;

    //static variables
    private static List<BSF_Custom_Notification__c> notificationsToUpdate = new List<BSF_Custom_Notification__c>();
    private static Map<Id,BSFNotificationThrottlerUtil.BSFNotificationThrottlerValidation> validationMap = new Map<Id,BSFNotificationThrottlerUtil.BSFNotificationThrottlerValidation>();
    public static NotificationThrottleBatchSettings__mdt batchSettings = NotificationThrottleBatchSettings__mdt.getInstance('NotificnThrottleBatchConfig');

    //Stateful variables
    private Map<String,Decimal> limitsRemaining = new Map<String,Decimal>();

    //Constructer
    global BSF_NotificationThrottlerBatch(List<String> mode){
        if(mode != null){
            List<String> notificationTypes = new List<String>();
            List<String> notificationTypeList = BSFNotificationThrottlerUtil.validNotificationTypes();
            for(String key : mode){
                if(notificationTypeList.contains(key)){
                    notificationTypes.add(key);
                }
            }
            this.NOTIFICATION_TYPES = notificationTypes;
            this.limitsRemaining = BSFNotificationThrottlerUtil.getLimitsRemaining(this.NOTIFICATION_TYPES);
            this.MAXLIMITS = BSFNotificationThrottlerUtil.getMaxLimits();
            this.HIGH_PRIORITY_THRESHOLDS = BSFNotificationThrottlerUtil.getHighPriorityThresholds();
            this.OTHER_PRIORITY_THRESHOLDS = BSFNotificationThrottlerUtil.getOtherPriorityThresholds();
            this.ORGWIDEE_MAILADDRESSMAP = BSFNotificationThrottlerUtil.getOrgWideEmailAddressMap();
        }
	}

    //start method
	global Database.QueryLocator start(Database.BatchableContext bc){
		return Database.getQueryLocator(BSFNotificationThrottlerUtil.getNotificationQuery(this.NOTIFICATION_TYPES));
	}

    //execute method Schedulable
    global void execute(SchedulableContext sc) {
        Id batchprocessid = Database.executeBatch(new BSF_NotificationThrottlerBatch(this.NOTIFICATION_TYPES),Integer.valueOf(batchSettings.BatchSize__c));
        try {
            System.FlexQueue.moveJobToFront(batchprocessid);
            System.abortJob(sc.getTriggerId());
        } catch (Exception e) {
            System.debug('The following error occured: '+e);
        }
    }
    //execute method Batchable
	global void execute(Database.BatchableContext bc, List<BSF_Custom_Notification__c> scope){
        List<BSF_Custom_Notification__c> customNotificationsToSend = new List<BSF_Custom_Notification__c>();
        List<BSF_Custom_Notification__c> emailsToSend = new List<BSF_Custom_Notification__c>();
        for(BSF_Custom_Notification__c notification : scope){
            BSFNotificationThrottlerUtil.BSFNotificationThrottlerValidation validationResp = BSFNotificationThrottlerUtil.validNotification(notification);
            validationMap.put(notification.Id,validationResp);
            if(validationResp.success && notification.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_EMAIL && isEmailLimitRemains(notification)){
                emailsToSend.add(notification);
            }else if(validationResp.success && notification.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH){
                customNotificationsToSend.add(notification);
            }else if(validationResp.success && (notification.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_ONEOFF
                    || notification.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS)) {
                        processCallouts(notification);
            }else if(!validationResp.success && String.isNotBlank(validationResp.message)){
                notification.Status__c = 'Error';
                notification.Error_Message__c = validationResp.message;
                notificationsToUpdate.add(notification);
            }
        }
		for(BSF_Custom_Notification__c notification : customNotificationsToSend){
            processSalesforcePush(notification);
        }
        if(!emailsToSend.isEmpty()){
            sendEmails(emailsToSend);
        }
        if(!notificationsToUpdate.isEmpty()){
            DataBase.saveResult[] srNotifnList = Database.update(notificationsToUpdate,false);
                
            List<BSF_Error_Log__c> errorLogJobs = BSF_Utilities.createErrorLog(srNotifnList,'Update processed record status', 'BSF_NotificationThrottleBatch', 'execute', 'Error', 'Error in BSF_Custom_Notification__c record update');
            insert errorLogJobs;
        }
	}

    //finish method
	global void finish(Database.BatchableContext bc){
        chainBatch();
	}

    //private methods
    private void processCallouts(BSF_Custom_Notification__c notification){
        if(BSFNotificationThrottlerUtil.isLimitRemains(notification.Priority__c,
                                                        this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_CALLOUT) - 1,
                                                        this.MAXLIMITS.get(BSF_Constants.NOTIFICATION_TYPE_CALLOUT),
                                                        this.HIGH_PRIORITY_THRESHOLDS.get(BSF_Constants.NOTIFICATION_TYPE_CALLOUT),
                                                        this.OTHER_PRIORITY_THRESHOLDS.get(BSF_Constants.NOTIFICATION_TYPE_CALLOUT))){
            try{
                if(notification.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_ONEOFF){
                    notification = BSFNotificationThrottlerUtil.sendOneOffNotifications(notification);
                }else if(notification.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS){
                    notification = BSFNotificationThrottlerUtil.sendCustomSms(notification);
                }
                Decimal limitCounter = this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_CALLOUT);
                this.limitsRemaining.put(BSF_Constants.NOTIFICATION_TYPE_CALLOUT,limitCounter - 1);
            }catch (Exception exe) {
                notification.Status__c = 'Error';
                notification.Error_Message__c = exe.getMessage();
            }
            notificationsToUpdate.add(notification);
        }
    }
    private void processSalesforcePush(BSF_Custom_Notification__c notification){
        if(BSFNotificationThrottlerUtil.isLimitRemains(notification.Priority__c,
                                                        this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH) - 1,
                                                        this.MAXLIMITS.get(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH),
                                                        this.HIGH_PRIORITY_THRESHOLDS.get(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH),
                                                        this.OTHER_PRIORITY_THRESHOLDS.get(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH))){
            try{
                Messaging.CustomNotification sfPushInstance = new Messaging.CustomNotification();
                if(String.isBlank(notification.Subject__c)){
                    sfPushInstance.setTitle(batchSettings.GeneicSubject__c);
                }else{
                    sfPushInstance.setTitle(notification.Subject__c);
                }
                sfPushInstance.setBody(notification.Body__c);
                sfPushInstance.setNotificationTypeId(notification.Custom_Notification_Type_Id__c);
                sfPushInstance.setTargetId(notification.Target_Record_Id__c);
                sfPushInstance.send(new Set<String> { notification.Destination_Id__c});
                if(String.isNotBlank(validationMap.get(notification.Id).message)){
                    notification.Status__c = 'Completed with Warning';
                    notification.Error_Message__c = validationMap.get(notification.Id).message;
                }else{
                    notification.Status__c = 'Completed';
                }
                notification.Notification_Sent_Timestamp__c = DateTime.now();
                Decimal limitCounter = this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH);
                this.limitsRemaining.put(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH,limitCounter - 1);
            }catch (Exception exe) {
                notification.Status__c = 'Error';
                notification.Error_Message__c = exe.getMessage();
            }
            notificationsToUpdate.add(notification);
        }
    }
    private Boolean isEmailLimitRemains(BSF_Custom_Notification__c notification){
        Boolean sendNotification = false;
        Boolean isInternalEmail = true;
        Integer emailAddressCount = 0;
        if(String.isNotBlank(notification.Destination_Email__c)){
            isInternalEmail = false;
            for(String emailId : notification.Destination_Email__c.split(',')){
                emailAddressCount = emailAddressCount + 1;
            }
        }
        if(isInternalEmail){
            sendNotification = true;
        }else if(!isInternalEmail && emailAddressCount > 0 && BSFNotificationThrottlerUtil.isLimitRemains(notification.Priority__c,
                                                            this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_EMAIL) - emailAddressCount,
                                                            this.MAXLIMITS.get(BSF_Constants.NOTIFICATION_TYPE_EMAIL),
                                                            this.HIGH_PRIORITY_THRESHOLDS.get(BSF_Constants.NOTIFICATION_TYPE_EMAIL),
                                                            this.OTHER_PRIORITY_THRESHOLDS.get(BSF_Constants.NOTIFICATION_TYPE_EMAIL))){
            sendNotification = true;
            Decimal limitCounter = this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_EMAIL);
            this.limitsRemaining.put(BSF_Constants.NOTIFICATION_TYPE_EMAIL,limitCounter - emailAddressCount);
            System.debug('limitCounter: '+this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_EMAIL));
        }
        return sendNotification;
    }
    private void sendEmails(List<BSF_Custom_Notification__c> notificationList){
        Map<Messaging.SingleEmailMessage,Id> emailsToSend = new Map<Messaging.SingleEmailMessage,Id>();
        Map<Id,Integer> emailAddressCountMap = new Map<Id,Integer>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for(BSF_Custom_Notification__c notification : notificationList){
            Integer emailAddressCount = 0;
            if(String.isNotBlank(notification.Destination_Email__c)){
                for(String emailId : notification.Destination_Email__c.split(',')){
                    emailAddressCount++;
                }
            }
            Messaging.SingleEmailMessage mail = BSFNotificationThrottlerUtil.getEmailInstance(notification,this.ORGWIDEE_MAILADDRESSMAP);
            emailList.add(mail);
            emailsToSend.put(mail,notification.Id);
            emailAddressCountMap.put(notification.Id,emailAddressCount);
        }
        
        if(!emailList.isEmpty()){
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList,false);
            for (Integer i=0; i < results.size(); i++) {
                BSF_Custom_Notification__c notification = new BSF_Custom_Notification__c();
                notification.Id = emailsToSend.get(emailList.get(i));
                if (results.get(i).isSuccess()) {
                    if(String.isNotBlank(validationMap.get(notification.Id).message)){
                        notification.Status__c = 'Completed with Warning';
                        notification.Error_Message__c = validationMap.get(notification.Id).message;
                    }else{
                        notification.Status__c = 'Completed';
                    }
                    notification.Notification_Sent_Timestamp__c = DateTime.now();
                }else{
                    Integer emailAddressCount = emailAddressCountMap.get(notification.Id);
                    Decimal limitRemaining = this.limitsRemaining.get(BSF_Constants.NOTIFICATION_TYPE_EMAIL);
                    this.limitsRemaining.put(BSF_Constants.NOTIFICATION_TYPE_EMAIL,(limitRemaining + emailAddressCount));
                    notification.Status__c = 'Error';
                    notification.Error_Message__c = '';
                    for(Messaging.SendEmailError err : results.get(i).getErrors()){
                        notification.Error_Message__c += err.getMessage()+' Field: '+err.getFields();
                    }
                }
                notificationsToUpdate.add(notification);
            }
        }
    }
    private void chainBatch(){

        Boolean executeBatchAgain = false;

        for (String notificationType : this.NOTIFICATION_TYPES) {
            Boolean islimitRemaining = false;
            Integer notificationCount = 0;

            //set key
            String key = notificationType;
            if(key == BSF_Constants.NOTIFICATION_TYPE_ONEOFF
                    || key == BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS){
                        key = BSF_Constants.NOTIFICATION_TYPE_CALLOUT;
            }

            //check low priority Limit Remaining
            islimitRemaining = BSFNotificationThrottlerUtil.isLimitRemains(batchSettings.LowPriorityLowerRange__c,this.limitsRemaining.get(key) - 1,
                                                                            this.MAXLIMITS.get(key),this.HIGH_PRIORITY_THRESHOLDS.get(key),
                                                                            this.OTHER_PRIORITY_THRESHOLDS.get(key));
            notificationCount = BSFNotificationThrottlerUtil.getRequestedAllNotificationCount(new List<String>{notificationType});

            if(islimitRemaining && notificationCount > 0){
                executeBatchAgain = true;
            }

            //check high priority Limit Remaining
            islimitRemaining = BSFNotificationThrottlerUtil.isLimitRemains(batchSettings.HighPriorityLowerRange__c,this.limitsRemaining.get(key) - 1,
                                                                            this.MAXLIMITS.get(key),this.HIGH_PRIORITY_THRESHOLDS.get(key),
                                                                            this.OTHER_PRIORITY_THRESHOLDS.get(key));
            notificationCount = BSFNotificationThrottlerUtil.getRequestedHighPriorityNotificationCount(new List<String>{notificationType});

            if(islimitRemaining && notificationCount > 0){
                executeBatchAgain = true;
            }
        }
        

        if(executeBatchAgain){
		    BSFNotificationThrottlerUtil.executeBatch(this.NOTIFICATION_TYPES);
        }else if(BSFNotificationThrottlerUtil.getRequestedAllNotificationCount(this.NOTIFICATION_TYPES) > 0 && Boolean.valueOf(batchSettings.IsSelfSchedulable__c)){
            BSFNotificationThrottlerUtil.scheduleBatch(this.NOTIFICATION_TYPES,Integer.valueOf(batchSettings.BatchScheduleInterval__c));
        }
    }
}