public class CustomNotification {
    public static String category = 'Drive Generation'; 
    public static String emailSubject = 'Drive Generation Error'; 
    public static void notifyUsers(Set<String> recipientsIds, String targetId, String title, String message) {
        sendNotificationEmail(message,targetId);
    }
    private static void sendNotificationEmail(String body,String targetId){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        List<Email_Recipient__mdt> driveEmailList = [Select Id,Email__c,Active__c from Email_Recipient__mdt where Active__c = True AND Category__c =: category];
        List<String> emailAddress = new List<String>{UserInfo.getUserEmail()};
            if(!driveEmailList.isEmpty() && driveEmailList != null){
                for(Email_Recipient__mdt drvEmail : driveEmailList){
                    emailAddress.add(drvEmail.Email__c);
                }
            }
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
    } 
}