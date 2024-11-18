/**
 * @description: This apex class is executed from Send Bell Notification To Task processbuilder to send Email notification.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 10/28/2023			    Kishore Das 			Logic for HRP-10929 (Marketing Exception Enhancement)
 * 12/13/2023			    Barnojit Sharma			Logic for HRP-11608 (General Email Sending Method)
 * *****************************************************************************************************************************************************************************************
 **/

global class BSF_EmailNotification {
    
   
    public class Request {
        @InvocableVariable(label='Task ID' required=true)
        public Id taskId;
    }
    
    @InvocableMethod
    public static void sendEmail(List<Request> requests) {
        system.debug('requests##'+requests);
        List<Id> taskIds = new List<Id>();
        for(Request req : requests) {
            taskIds.add(req.taskId);
        }
        system.debug('taskIds##' + taskIds);

        List<Task> tasks = [SELECT Id, CreatedById, Subject FROM Task WHERE Id IN :taskIds];

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for(Task t : tasks) {
            system.debug('taskIds##' +t);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            System.debug('t.CreatedById## '+t.CreatedById);
            
            email.setTargetObjectId(t.CreatedById);
            
            email.setSubject('Approval Status Changed: ' + t.Subject);
            
            email.setTreatTargetObjectAsRecipient(true);
            
            email.setHtmlBody('Hello,<br/>The approval status for the task ' + t.Subject + ' has changed. Please review it.');
            
            email.setSaveAsActivity(false);
            
            emailList.add(email);
        }
        system.debug('emailList##' + emailList);
        sendEmails(emailList,'MarketingExceptionApproveReject',null);//Changes for  HRP-11608
    }
    /*
    * HRP-11608 changes starts here
    */
    public static void sendEmails(List<Messaging.SingleEmailMessage> emailList, String notificationKey, DateTime emailExpiry){
        final string logTag = '[BSF_EmailNotification:sendEmails]';
        System.debug(logTag + ' Entering method==> ' + emailList);
        Custom_Notification_Setting__mdt customEmailSetting;
        if(emailList == null || emailList.isEmpty()){
            return;
        }
        if(String.isNotBlank(notificationKey)){
            customEmailSetting = Custom_Notification_Setting__mdt.getInstance(notificationKey.trim());
        }
        if(customEmailSetting == null){
            throw new BSF_EmailNotification_Exception('Invalid Email Category');
        }
        if(customEmailSetting.Allow_Notification__c && customEmailSetting.Send_Notification_Separately__c){
            String errMsg = '';
            try{
                Messaging.SendEmailResult[] mrs = Messaging.sendEmail(emailList);
                for (Messaging.SendEmailResult mr : mrs){
                    if(!mr.isSuccess()){                     
                        for(Messaging.SendEmailError err : mr.getErrors()) {
                            errMsg = errMsg + err.getStatusCode() + ': ' + err.getMessage()+' : fields that affected this error: ' + err.getFields();
                        }
                    }
                }
            }catch(Exception except){
                errMsg = errMsg + except.getMessage();
            }
            if(String.isNotBlank(errMsg)){
                throw new BSF_EmailNotification_Exception(errMsg);
            }
        }else if(customEmailSetting.Allow_Notification__c && !customEmailSetting.Send_Notification_Separately__c){
            List<BSF_Custom_Notification__c> notificationList = BSF_General_Notification.getEmailNotificationRecord(emailList, notificationKey, 
                                                                                                                    Integer.valueOf(customEmailSetting.Priority__c), 
                                                                                                                    emailExpiry);
            System.debug('Calling BSF_General_Notification.insertNotificationRecord==>');
            BSF_General_Notification.insertNotificationRecord(notificationList);
        }
    }   
    public class BSF_EmailNotification_Exception extends Exception{} 
    /*
    * HRP-11608 changes ends here
    */
}