public class BSF_General_Notification {
    public static List<BSF_Custom_Notification__c> getBellNotificationRecord(Id notificationTypeId, Set<String> recipientIds, String notificationTitle, 
                                                                        String notificationBody, Id targetId, Integer priority, String category, DateTime notificationExpiry){
        List<BSF_Custom_Notification__c> notificationList = new List<BSF_Custom_Notification__c>();
        if(notificationTypeId == null || recipientIds == null || recipientIds.isEmpty() || targetId == null || priority == null 
                || String.isBlank(category) || String.isBlank(notificationTitle) || String.isBlank(notificationBody)){
                    throw new BSF_General_Notification_Exception('Missing required fields.');
        }
        for(String recipientId : recipientIds){
            BSF_Custom_Notification__c notfRec = new BSF_Custom_Notification__c();
            notfRec.Notification_Type__c = 'SalesforcePush';
            notfRec.Status__c = 'Queued';
            notfRec.Category__c = category;
            notfRec.Custom_Notification_Type_Id__c = notificationTypeId;
            notfRec.Subject__c = notificationTitle;
            notfRec.Body__c = notificationBody;
            notfRec.Target_Record_Id__c = targetId;
            notfRec.Destination_Id__c = recipientId;
            notfRec.Priority__c = priority;
            notfRec.Scheduled_TimeStamp__c = System.now();
            notfRec.Expiry_TimeStamp__c = notificationExpiry;
            notificationList.add(notfRec);
        }
        return notificationList;
    }
    public static List<BSF_Custom_Notification__c> getEmailNotificationRecord(List<Messaging.SingleEmailMessage> emailList, String notificationKey, 
                                                                                Integer priority, DateTime emailExpiry) {
        List<BSF_Custom_Notification__c> notificationList = new List<BSF_Custom_Notification__c>();
        Map<Id,String> OrgWideEmailMap = new Map<Id,String>();
        if(emailList == null || emailList.isEmpty() || priority == null || String.isBlank(notificationKey)){
            throw new BSF_General_Notification_Exception('Missing required fields.');
        }
        for(OrgWideEmailAddress owea : [select Id, Address from OrgWideEmailAddress]){
            OrgWideEmailMap.put(owea.Id,owea.Address);
        }
        for(Messaging.SingleEmailMessage message : emailList){
            BSF_Custom_Notification__c emailRec = new BSF_Custom_Notification__c();
            emailRec.Notification_Type__c = 'Email';
            emailRec.Status__c = 'Queued';
            emailRec.Category__c = notificationKey;
            emailRec.Priority__c = priority;
            emailRec.Expiry_TimeStamp__c = emailExpiry;
            emailRec.Scheduled_TimeStamp__c = System.now();
            if(message.getTemplateId() != null){
                Messaging.SingleEmailMessage tempMessage = Messaging.renderStoredEmailTemplate(message.getTemplateId(),null,message.getTargetObjectId());
                emailRec.Email_Template__c = message.getTemplateId();
                emailRec.Subject__c = tempMessage.getSubject();
                emailRec.Body__c = tempMessage.getHtmlBody() == null ? tempMessage.getPlainTextBody() : tempMessage.getHtmlBody();
            }else{
                emailRec.Subject__c = message.getSubject();
                emailRec.Body__c = message.getHtmlBody() == null ? message.getPlainTextBody() : message.getHtmlBody();
            }
            if(message.treatTargetObjectAsRecipient == true){
                emailRec.Destination_Id__c = message.getTargetObjectId();
            }
            if(message.getOrgWideEmailAddressId() != null && OrgWideEmailMap.containsKey(message.getOrgWideEmailAddressId())){
                emailRec.Sender_Email__c = OrgWideEmailMap.get(message.getOrgWideEmailAddressId());
            }else{
                emailRec.Sender_Email__c = UserInfo.getUserEmail();
            }

            List<String> emailToAddresses = new List<String>();
            if(message.toAddresses != null){
                emailToAddresses.addAll(message.toAddresses);
            }
            if(message.ccAddresses != null){
                emailToAddresses.addAll(message.toAddresses);
            }
            if(message.bccAddresses != null){
                emailToAddresses.addAll(message.toAddresses);
            }
            
            if(emailToAddresses.isEmpty() || (emailToAddresses.size() == 1)){
                emailRec.Destination_Email__c = (!emailToAddresses.isEmpty()) ? emailToAddresses.get(0) : null;
                notificationList.add(emailRec);
            }else if(emailToAddresses.size() > 1){
                for(String destinationEmail : emailToAddresses){
                    BSF_Custom_Notification__c emailRecCloned = emailRec.clone();
                    emailRecCloned.Id = null;
                    emailRecCloned.Destination_Email__c = destinationEmail;
                    notificationList.add(emailRecCloned);
                }
            }
        }
        return notificationList;
    }
    public static void insertNotificationRecord(List<BSF_Custom_Notification__c> notfRecList){
        System.debug('Entering BSF_General_Notification.insertNotificationRecord==>'+notfRecList);
        if(notfRecList == null || notfRecList.isEmpty()){
            return;
        }
        if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
            String errMsg = '';
            Database.SaveResult[] srList;
            try{
                srList = Database.insert(notfRecList, false);
            }catch(Exception ex){
                errMsg = errMsg + ex.getMessage();
            }
            if(srList != null){
                for (Integer i=0; i < srList.size(); i++){
                    if(!srList.get(i).isSuccess()) {
                        for(Database.Error err : srList.get(i).getErrors()) {
                            errMsg = errMsg + err.getMessage();
                            System.debug('errMsg==> '+errMsg);
                        }
                    }
                }
            }
            if(String.isNotBlank(errMsg)){
                BSF_Error_Log__c err = BSF_Utilities.getErrorLog(null,'BSF_General_Notification','insertNotificationRecord()','Error','Error Creating notification Record',errMsg);
                try{
                    insert err;
                }catch(Exception excptn){
                    System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                }
            }
        }else{
            System.debug('Too many DML statements.');
        }
    }
    public class BSF_General_Notification_Exception extends Exception{}
}