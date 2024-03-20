/**
 * @description: This apex class is executed from Send Bell Notification To Task processbuilder to send Email notification.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 10/28/2023			    Kishore Das 			Logic for HRP-10929(Marketing Exception Enhancement)
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
        Messaging.SendEmailResult[] mrs = Messaging.sendEmail(emailList);
        for (Messaging.SendEmailResult mr : mrs){
            if(mr.isSuccess()){
                System.debug('Email send successfully.');  
            }else{
                // Operation failed, so get all errors                        
                for(Messaging.SendEmailError err : mr.getErrors()) {
                    System.debug('The following error has occurred.');  
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('fields that affected this error: ' + err.getFields());
                }
            }
        }
    }
    
}