/**
* ***************************************************************************************************************************************************************************
* @Description: As part of HRP-4878 this Batch has been created
* @developer:   Apurba Bhattacharjee
* Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 10/28/2024				  Barnojit Sharma			 Template Order products not cascading to Opportunity Order. (Logic for HRP-13521)
* ***************************************************************************************************************************************************************************
**/
global class BSF_BatchFutureDriveUpdate implements Database.Batchable<String>, Database.Stateful{

   global List<String> OppIdList;
   global String templateId;
   global List<String> selectedFields;
   global Map<String,String> errorMap = new Map<String,String>();

   global BSF_BatchFutureDriveUpdate(List<String> driveidset, String recordid, List<String> fields){
		this.OppIdList = driveidset;  
     	this.templateId = recordid;
      this.selectedFields = fields;
   }

   global Iterable<String> start(Database.BatchableContext bc){
      return OppIdList;
   }

   global void execute(Database.BatchableContext bc, List<String> scope){
      for(String oppId : scope){
         Savepoint sp = Database.setSavepoint();
         try {
            FutureDrivesController.applyChangestoFutureDrives(new List<String>{oppId},this.templateId,this.selectedFields);
         } catch (Exception e) {
            Database.rollback(sp);//HRP-13521
            BSF_Error_Log__c errLog = BSF_Utilities.createBsfErrorLogForExceptions(e,'BSF_BatchFutureDriveUpdate','execute','Future Drive Update', 'Apply Changes to Future Drives','Opportunity',oppId);
            insert errLog;
            String expText = 'Exception type caught: ' + e.getTypeName()+    
                              +'\nMessage: ' + e.getMessage()+    
                              +'\nCause: ' + e.getCause()+    
                              +'\nLine number: ' + e.getLineNumber()+    
                              +'\nStack trace: ' + e.getStackTraceString();  
            Attachment requestAttachment = new Attachment();
            requestAttachment.contentType = 'text/plain';
            requestAttachment.name = 'ErrorLog.txt';
            requestAttachment.parentId = errLog.Id;
            requestAttachment.body = Blob.valueOf(expText);
            insert requestAttachment;
            errorMap.put(oppId,'Message : '+e.getMessage()+' Stacktress : '+e.getStackTraceString()+' Line : '+e.getLineNumber());
            System.debug('Exception --'+e.getMessage());
         }
      }
   }

   global void finish(Database.BatchableContext bc){
      if(!this.errorMap.isEmpty() && String.isNotBlank(UserInfo.getUserEmail())){
         String emailBody = '<html><table border="1" cellpadding="4" cellspacing="0"><thead><tr><th>Record Id</th><th>Error Message</th></tr></thead><tbody>';
         for(String oppId : errorMap.keySet()){
            emailBody = emailBody + '<tr><td>'+oppId+'</td><td>'+errorMap.get(oppId)+'</td></tr>';
         }
         emailBody = emailBody + '</tbody></table></html>';
         System.debug('emailBody : '+emailBody);
         Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
         if(String.isNotBlank(label.RESOURCE_NOTIFICATION_SENDER_EMAIL)){
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: label.RESOURCE_NOTIFICATION_SENDER_EMAIL ];
            if (owea.size()>0) {
               message.setOrgWideEmailAddressId(owea.get(0).Id);
            }
         }
         message.toAddresses = new List<String>{UserInfo.getUserEmail()};
         message.optOutPolicy = 'FILTER';
         message.subject = 'Error on updating of Future Drives';
         message.setHtmlBody(emailBody);
         Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
         BSF_EmailNotification.sendEmails(messages,'FutureDriveUpdateBatchFailure',null);
      }
   }
}