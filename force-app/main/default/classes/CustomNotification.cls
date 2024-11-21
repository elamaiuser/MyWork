public class CustomNotification {
    public static String category = 'Drive Generation'; 
    public static String emailSubject = 'Drive Generation Error';
    public static void notifyUsers(Set<String> recipientsIds, String targetId, String title, String message) {
      /*  CustomNotificationType notificationType = [SELECT Id, DeveloperName,CustomNotifTypeName FROM CustomNotificationType WHERE DeveloperName = 'Opportunity_Custom_Notification' limit 1];

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(title);
        notification.setBody(message);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId); */
        try {
          //  notification.send(recipientsIds);   
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
        finally{
             sendNotificationEmail(message,targetId);
        }
    }
    private static void sendNotificationEmail(String body,String targetId){
        System.debug('Notification will be send ');
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        List<Email_Recipient__mdt> driveEmailList = [Select Id,Email__c,Active__c from Email_Recipient__mdt where Active__c = True AND Category__c =: category];
        List<String> emailAddress = new List<String>{UserInfo.getUserEmail()};
            if(!driveEmailList.isEmpty() && driveEmailList != null){
                for(Email_Recipient__mdt drvEmail : driveEmailList){
                    emailAddress.add(drvEmail.Email__c);
                }
            }
        //Set recipients to two contact IDs.
        //Replace IDs with valid record IDs in your org.
        message.toAddresses = emailAddress;
        message.optOutPolicy = 'FILTER';
        message.subject = emailSubject;
        message.plainTextBody = 'Following data was not found while generating drive: \n'+body+'\n'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+targetId;
        Messaging.SingleEmailMessage[] messages = 
            new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: '
                + results[0].errors[0].message);
        }
        // if(false){
        // Map<Id, String> dml_error_map = new Map<Id, String>();
        // Map<Exception,String> common_exception_map = new Map<Exception,String>();
        // dml_error_map.put(targetId,body);
        // String oweFromAddress = System.label.BSF_OWEA_SENDER;
        // List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address=:oweFromAddress];
        // if(!owea.isEmpty()) {
        //         Helper.sendEmail(common_exception_map, dml_error_map, emailAddress, owea[0].Id, true);
        // }
        // }
    }
}