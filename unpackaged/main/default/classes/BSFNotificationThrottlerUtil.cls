/**
 * @description: This class contains utility methods for Custom Notification proessing.
 * @createdby: Barnojit Sharma
 **/
public without sharing class BSFNotificationThrottlerUtil {

    public static NotificationThrottleBatchSettings__mdt batchSettings = NotificationThrottleBatchSettings__mdt.getInstance('NotificnThrottleBatchConfig');

    public static Boolean checkBatchProcessing(){
        Boolean result = false;
        list<AsyncApexJob> batchJobsProcessing = [SELECT id,
                                                            JobType,
                                                            ApexClassId,
                                                            ApexClass.Name,
                                                            CronTriggerId,
                                                            CronTrigger.NextFireTime
                                                    FROM AsyncApexJob 
                                                    WHERE ApexClass.Name = :BSF_NotificationThrottlerBatch.class.getName()
                                                    AND status IN ('Holding','Queued','Preparing','Processing')
                                                    AND JobType IN ('BatchApex','ScheduledApex')];
        for(AsyncApexJob job : batchJobsProcessing){
            if(job.JobType == 'BatchApex' || (job.JobType == 'ScheduledApex' && job.CronTrigger.NextFireTime != null
                    && job.CronTrigger.NextFireTime <= DateTime.now().addMinutes(Integer.valueOf(NotificationThrottleBatchSettings__mdt.getInstance('NotificnThrottleBatchConfig').BatchScheduleInterval__c)))){
                        result = true;
            }
        }
        return result;
    }
    public static void executeBatch(List<String> notificationTypeList){
        if(!checkBatchProcessing()){
            Id batchprocessid = Database.executeBatch(new BSF_NotificationThrottlerBatch(notificationTypeList),Integer.valueOf(batchSettings.BatchSize__c));
            System.debug('batchprocessid: '+batchprocessid);
            try {
                System.FlexQueue.moveJobToFront(batchprocessid);
            } catch (Exception e) {
                System.debug('The following error occured: '+e);
            }
                
        }
    }
    public static void scheduleBatch(List<String> notificationTypeList, Integer mindiff){
        if(!checkBatchProcessing()){
            Datetime nextFireDatetime = Datetime.now().addMinutes(mindiff);
            String cronExp = nextFireDatetime.second() + ' ' + 
                            nextFireDatetime.minute() + ' ' + 
                            nextFireDatetime.hour() + ' ' + 
                            nextFireDatetime.day() + ' '+ 
                            nextFireDatetime.format('MMM').toUppercase() + 
                            ' ? ' + 
                            nextFireDatetime.year();

            System.schedule(BSF_NotificationThrottlerBatch.class.getName()+
                            ' Scheduled on '+Datetime.now().format('MM-dd-yyyy \'at\' HH:mm:ss z'),
                            cronExp, new BSF_NotificationThrottlerBatch(notificationTypeList));
        }
    }
    public static Integer getEmailLimitRemaining(){
        Integer emailMaxLimit = OrgLimits.getMap().get('SingleEmail').getLimit();
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').DailyLimit__c != null){
            emailMaxLimit = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').DailyLimit__c);
        }
        Integer notificationSent = OrgLimits.getMap().get('SingleEmail').getValue();
        Integer limitRemaining = (emailMaxLimit > notificationSent) ? (emailMaxLimit - notificationSent) : 0;
        return limitRemaining;
    }
    public static Integer getPushNotificationLimitRemaining(){
        Integer houlyLimit = 10000;
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').HourlyLimit__c != null){
            houlyLimit = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').HourlyLimit__c);
        }
        Integer notificationSent = [SELECT Count() 
                                    FROM BSF_Custom_Notification__c 
                                    WHERE Notification_Type__c = 'SalesforcePush'
                                    AND Status__c = 'Completed'
                                    AND Notification_Sent_Timestamp__c >= :Datetime.now().addHours(-1)];
        Integer limitRemaining = (houlyLimit > notificationSent) ? (houlyLimit - notificationSent) : 0;
        return limitRemaining;
    }
    public static Integer getApiRequestsLimitRemaining(){
        Integer apilLimit = OrgLimits.getMap().get('DailyApiRequests').getLimit();
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').DailyLimit__c != null){
            apilLimit = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').DailyLimit__c);
        }
        Integer notificationSent = OrgLimits.getMap().get('DailyApiRequests').getValue();
        Integer limitRemaining = (apilLimit > notificationSent) ? (apilLimit - notificationSent) : 0;
        return limitRemaining;
    }
    public static BSF_Custom_Notification__c sendCustomSms(BSF_Custom_Notification__c record){
        if(String.isNotBlank(record.Phone_Number__c) && record.Body__c != null
                && String.isNotBlank(record.SMS_Country_Code_Abbreviation__c)){
                    skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
                    skedSkeduloApiData.smsResult smsResult = apiManager.notifySms(record.SMS_Country_Code_Abbreviation__c, record.Phone_Number__c, record.Body__c);
                    if (!smsResult.success) {
                        record.Status__c = 'Error';
                        record.Error_Message__c = smsResult.error.message;
                    }else{
                        record.Status__c = 'Completed';
                        record.Notification_Sent_Timestamp__c = DateTime.now();
                    }
        }else{
            throw new BSFNotificationThrottlerException('Invalid Parameters.');
        }
        return record;
    }
    public static BSF_Custom_Notification__c sendOneOffNotifications(BSF_Custom_Notification__c record){
        if(String.isNotBlank(record.Destination_Id__c) && record.Body__c != null
                && String.isNotBlank(record.Oneoff_Protocol__c)){
                    skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
                    skedSkeduloApiData.oneoffResult oneoffResult = apiManager.notifyOneOff(record.Destination_Id__c, record.Oneoff_Protocol__c, record.Body__c);
                    if (!oneoffResult.success) {
                        record.Status__c = 'Error';
                        record.Error_Message__c = oneoffResult.error.message;
                    }else{
                        record.Status__c = 'Completed';
                        record.Notification_Sent_Timestamp__c = DateTime.now();
                    }
        }else{
            throw new BSFNotificationThrottlerException('Invalid Parameters.');
        }
        return record;
    }
    public static String getNotificationQuery(List<String> notificationTypes){
        String currentDateTime = System.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String fieldNames = String.join(new List<String>(BSF_Custom_Notification__c.SObjectType.getDescribe().fields.getMap().keySet()), ', ');
        return 'SELECT '+fieldNames+' FROM BSF_Custom_Notification__c '+
                'WHERE Status__c = \'Queued\' '+
                'AND (Scheduled_TimeStamp__c <= ' +currentDateTime+' '+
                'OR Scheduled_TimeStamp__c = NULL) ' +
                'AND (Expiry_TimeStamp__c >= '+currentDateTime+' '+
                'OR Expiry_TimeStamp__c = NULL) ' +
                'AND Notification_Type__c IN (\'' +String.join(notificationTypes,'\',\'')+'\') '+
                'ORDER BY Priority__c ASC NULLS LAST, Expiry_TimeStamp__c ASC NULLS LAST, Scheduled_TimeStamp__c ASC NULLS FIRST, CreatedDate ASC';
    }
    public static Integer getRequestedAllNotificationCount(List<String> notificationTypes){
        DateTime currentDateTime = System.now();
        return [SELECT count() FROM BSF_Custom_Notification__c
                WHERE Status__c = 'Queued'
                AND (Scheduled_TimeStamp__c <= :currentDateTime
                OR Scheduled_TimeStamp__c = NULL)
                AND (Expiry_TimeStamp__c >= :currentDateTime
                OR Expiry_TimeStamp__c = NULL)
                AND Notification_Type__c IN :notificationTypes];
    }
    public static Integer getRequestedHighPriorityNotificationCount(List<String> notificationTypes){
        DateTime currentDateTime = System.now();
        return [SELECT count() FROM BSF_Custom_Notification__c
                WHERE Status__c = 'Queued'
                AND (Scheduled_TimeStamp__c <= :currentDateTime
                OR Scheduled_TimeStamp__c = NULL)
                AND (Expiry_TimeStamp__c >= :currentDateTime
                OR Expiry_TimeStamp__c = NULL)
                AND Notification_Type__c IN :notificationTypes
                AND Priority__c <=: batchSettings.HighPriorityLowerRange__c];
    }
    public static List<String> validNotificationTypes(){
        List<String> notificationTypes = new List<String>();
        for( Schema.PicklistEntry val : Schema.SObjectType.BSF_Custom_Notification__c.fields.BSF_Custom_Notification__c.getPicklistValues()){
            notificationTypes.add(val.getValue());
        }
        return notificationTypes;
    }
    public static Map<String,Decimal> getLimitsRemaining(List<String> notificationTypes){
        Map<String,Decimal> limitsRemaining = new Map<String,Decimal>();
        for(String notificationType : notificationTypes){
            if(notificationType == BSF_Constants.NOTIFICATION_TYPE_EMAIL){
                limitsRemaining.put(BSF_Constants.NOTIFICATION_TYPE_EMAIL,getEmailLimitRemaining());
            }
            if(notificationType == BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH){
                limitsRemaining.put(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH,getPushNotificationLimitRemaining());
            }
            if(notificationType == BSF_Constants.NOTIFICATION_TYPE_ONEOFF
                    || notificationType == BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS){
                        limitsRemaining.put(BSF_Constants.NOTIFICATION_TYPE_CALLOUT,getApiRequestsLimitRemaining());
            }
        }
        return limitsRemaining;
    }
    public static Map<String,Decimal> getMaxLimits(){
        Map<String,Decimal> mapLimits = new Map<String,Decimal>();
        Integer sfPushMaxLimit = 10000;
        Integer apiCallOutMaxLimit = OrgLimits.getMap().get('DailyApiRequests').getLimit();
        Integer emailMaxLimit = OrgLimits.getMap().get('SingleEmail').getLimit();
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').DailyLimit__c != null){
            emailMaxLimit = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').DailyLimit__c);
        }
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').HourlyLimit__c != null){
            sfPushMaxLimit = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').HourlyLimit__c);
        }
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').DailyLimit__c != null){
            apiCallOutMaxLimit = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').DailyLimit__c);
        }
        mapLimits.put(BSF_Constants.NOTIFICATION_TYPE_EMAIL,emailMaxLimit);
        mapLimits.put(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH,sfPushMaxLimit);
        mapLimits.put(BSF_Constants.NOTIFICATION_TYPE_CALLOUT,apiCallOutMaxLimit);
        return mapLimits;
    }
    public static Map<String,Decimal> getHighPriorityThresholds(){
        Map<String,Decimal> thresholdsMap = new Map<String,Decimal>();
        Integer sfPushthresholds = 100;
        Integer apiCallOutthresholds = 100;
        Integer emailthresholds = 100;
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').HighPriorityLimit__c != null){
            emailthresholds = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').HighPriorityLimit__c);
        }
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').HighPriorityLimit__c != null){
            sfPushthresholds = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').HighPriorityLimit__c);
        }
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').HighPriorityLimit__c != null){
            apiCallOutthresholds = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').HighPriorityLimit__c);
        }
        thresholdsMap.put(BSF_Constants.NOTIFICATION_TYPE_EMAIL,emailthresholds);
        thresholdsMap.put(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH,sfPushthresholds);
        thresholdsMap.put(BSF_Constants.NOTIFICATION_TYPE_CALLOUT,apiCallOutthresholds);
        return thresholdsMap;
    }
    public static Map<String,Decimal> getOtherPriorityThresholds(){
        Map<String,Decimal> thresholdsMap = new Map<String,Decimal>();
        Integer sfPushthresholds = 100;
        Integer apiCallOutthresholds = 100;
        Integer emailthresholds = 100;
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').OtherPriorityLimit__c != null){
            emailthresholds = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('EmailSettings').OtherPriorityLimit__c);
        }
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').OtherPriorityLimit__c != null){
            sfPushthresholds = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('SalesforcePushSettings').OtherPriorityLimit__c);
        }
        if(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').OtherPriorityLimit__c != null){
            apiCallOutthresholds = Integer.valueOf(BSF_Outbound_Notification_Settings__mdt.getInstance('CalloutSettings').OtherPriorityLimit__c);
        }
        thresholdsMap.put(BSF_Constants.NOTIFICATION_TYPE_EMAIL,emailthresholds);
        thresholdsMap.put(BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH,sfPushthresholds);
        thresholdsMap.put(BSF_Constants.NOTIFICATION_TYPE_CALLOUT,apiCallOutthresholds);
        return thresholdsMap;
    }
    public static BSFNotificationThrottlerValidation validNotification(BSF_Custom_Notification__c record){
        BSFNotificationThrottlerValidation response = new BSFNotificationThrottlerValidation();
        response.success = true;
        response.message = '';
        List<String> errMessage = new List<String>();
        if(record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_EMAIL){
            if(String.isBlank(record.Destination_Id__c) && String.isBlank(record.Destination_Email__c)){
                response.success = false;
                errMessage.add('Destination is Missing');
            }
            if(String.isBlank(record.Subject__c)){
                errMessage.add('Subject is Missing');
            }
        }else if(record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH){
            if(String.isBlank(record.Destination_Id__c)){
                response.success = false;
                errMessage.add('Destination Id is Missing');
            }
            if(String.isBlank(record.Subject__c)){
                errMessage.add('Subject is Missing');
            }
            if(String.isBlank(record.Target_Record_Id__c)){
                response.success = false;
                errMessage.add('Target Record Id is Missing');
            }
        }else if(record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS){
            if(String.isBlank(record.Phone_Number__c)){
                response.success = false;
                errMessage.add('Phone Number is Missing');
            }
            if(String.isBlank(record.SMS_Country_Code_Abbreviation__c)){
                response.success = false;
                errMessage.add('SMS Country Code is Missing');
            }
        }
        else if(record.Notification_Type__c == BSF_Constants.NOTIFICATION_TYPE_ONEOFF){
            if(String.isBlank(record.Destination_Id__c)){
                response.success = false;
                errMessage.add('Destination Id is Missing');
            }
            if(String.isBlank(record.Oneoff_Protocol__c)){
                response.success = false;
                errMessage.add('Oneoff Protocol is Missing');
            }
        }
        if(record.Body__c == null){
            response.success = false;
            errMessage.add('Notification Body is null');
        }
        if(!errMessage.isEmpty()){
            response.message = String.join(errMessage,', ');
            response.message = response.message.length() > 255 ? response.message.left(255) : response.message;
        }
        return response;
    }
    public static Id getOrgWideEmailAddressId(){
        Id orgWideEmailAddressId;
        if(String.isNotBlank(batchSettings.DefaultSenderEmail__c)){
            OrgWideEmailAddress[] owea = [SELECT Id 
                                            FROM OrgWideEmailAddress 
                                            WHERE Address =: batchSettings.DefaultSenderEmail__c ];
            if (owea.size()>0) {
                orgWideEmailAddressId = owea.get(0).Id;
            }
        }
        return orgWideEmailAddressId;
    }
    public static Map<String,Id> getOrgWideEmailAddressMap(){
        Map<String,Id> orgWideEmailAddressMap = new Map<String,Id>();
        if(String.isNotBlank(label.All_Org_Wide_Addresses)){
            List<String> orgWideAdd = System.label.All_Org_Wide_Addresses.split(',');
            OrgWideEmailAddress[] oweaList = [SELECT Id, Address
                                            FROM OrgWideEmailAddress 
                                            WHERE Address IN :orgWideAdd];
            for(OrgWideEmailAddress owea : oweaList){
                orgWideEmailAddressMap.put(owea.Address,owea.Id);
            }
        }
        return orgWideEmailAddressMap;
    }
    public static Messaging.SingleEmailMessage getEmailInstance(BSF_Custom_Notification__c record, Map<String,Id> orgWideEmailAddressMap){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        /*if(String.isNotBlank(record.Sender_Email__c)){
            mail.setReplyTo(record.Sender_Email__c);
            mail.setSenderDisplayName(record.Sender_Email__c);
        }*/ 
        if(String.isNotBlank(record.Sender_Email__c) && orgWideEmailAddressMap != null 
                && !orgWideEmailAddressMap.isEmpty() 
                && orgWideEmailAddressMap.containsKey(record.Sender_Email__c)){
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(record.Sender_Email__c));
        }else if(String.isNotBlank(batchSettings.DefaultSenderEmail__c) && orgWideEmailAddressMap != null 
                && !orgWideEmailAddressMap.isEmpty() 
                && orgWideEmailAddressMap.containsKey(batchSettings.DefaultSenderEmail__c)){
                    mail.setOrgWideEmailAddressId(orgWideEmailAddressMap.get(batchSettings.DefaultSenderEmail__c));
        }
        if (String.isNotBlank(record.Destination_Email__c)){
            mail.setToAddresses(record.Destination_Email__c.split(','));
        }
        if (String.isNotBlank(record.Destination_Id__c)) {
            mail.setTargetObjectId(record.Destination_Id__c);
            mail.setTreatTargetObjectAsRecipient(true);
        }
        mail.setSaveAsActivity(false);
        mail.optOutPolicy = ResourceNotificationEmailConstants.FILTER;

        if(String.isBlank(record.Subject__c)){
            mail.setSubject(batchSettings.GeneicSubject__c);
        }else{
            mail.setSubject(record.Subject__c);
        }
        mail.setHtmlBody(record.Body__c);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if (String.isNotBlank(record.Email_Template__c)) {
            mail.setTemplateId(record.Email_Template__c); 
            if(String.isNotBlank(record.Target_Record_Id__c)) {
                mail.setWhatId(record.Target_Record_Id__c);
            }
        }
        return mail;
    }
    public static Boolean isLimitRemains(Decimal priority, Decimal currentlimitRemaining, Decimal maxLimit, Decimal highPriorityThreshold, Decimal otherPriorityThreshold){
        Boolean result = false;
        System.debug('priority: '+ priority+' currentlimitRemaining: '+currentlimitRemaining+' maxLimit: '+maxLimit+' highPriorityThreshold: '+highPriorityThreshold+' otherPriorityThreshold: '+otherPriorityThreshold);

        Decimal limitExhaust = maxLimit - currentlimitRemaining;
        System.debug('limitExhaust: '+ limitExhaust);

        Decimal priorityPercentile = 0;
        if(priority != null && priority <= batchSettings.HighPriorityLowerRange__c){
            priorityPercentile = highPriorityThreshold;
        }else if(priority != null && priority > batchSettings.HighPriorityLowerRange__c && priority <= batchSettings.LowPriorityLowerRange__c){
            priorityPercentile = otherPriorityThreshold;
        }
        System.debug('priorityPercentile: '+ priorityPercentile);

        if(currentlimitRemaining >= 0 && maxLimit > 0 && limitExhaust >= 0 && (limitExhaust <= maxLimit) && priorityPercentile > 0){
            
            Decimal priorityWiseMaxLimit = (priorityPercentile * maxLimit)/ 100;
            priorityWiseMaxLimit = priorityWiseMaxLimit.round(System.RoundingMode.DOWN);
            System.debug('priorityWiseMaxLimit: '+ priorityWiseMaxLimit);

            if(limitExhaust <= priorityWiseMaxLimit){
                result = true;
            }
        }

        System.debug('result: '+ result);
        return result;
    }
    public class BSFNotificationThrottlerException extends Exception{}
    public class BSFNotificationThrottlerValidation{
        public Boolean success;
        public String message;
    }
}