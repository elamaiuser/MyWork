public class NewFixedSiteDriveQueueable implements Queueable {
    
    public List<NewFixedSiteDrive.fixedOpps> oppIdList;
    public NewFixedSiteDriveQueueable(List<NewFixedSiteDrive.fixedOpps> oppIds) {
        this.oppIdList = new List<NewFixedSiteDrive.fixedOpps>();
        this.oppIdList=oppIds;
    }
    public void execute(QueueableContext context){
        List<NewFixedSiteDrive.fixedOpps> oppIds = this.oppIdList;
        List<Opportunity> oppList = new List<Opportunity>();
        system.debug('oppIds[0].oppsToCreate:::'+oppIds[0].oppsToCreate);
        if(oppIds[0].oppsToCreate != null && !oppIds[0].oppsToCreate.isEmpty()){
            oppList = oppIds[0].oppsToCreate; 
        }
        system.debug('oppList1234##'+oppList);
        Database.SaveResult[] srList = Database.insert(oppList, false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug('Successfully created Opp ID: ' + sr.getId());
                
            }
            else {              
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Opportunity fields that affected this error: ' + err.getFields());
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.toAddresses = new List<String>{'krapy.tuli@redcross.org'};
                        message.optOutPolicy = 'FILTER';
                    message.subject = 'Error on creation of Drives';
                    message.plainTextBody = 'Following fields that affected this error:- '+err.getFields()+'\n err.getStatusCode():- '+err.getMessage();
                    Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    if (results[0].success) {
                        System.debug('The email was sent successfully.');
                    } else {
                        System.debug('The email failed to send: '
                                     + results[0].errors[0].message);
                    }
                }
            }
        }
    }
}