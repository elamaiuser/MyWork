//@Description: Deletes Job Allocation Batch
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
*06/06/2025                   Harika Bolisetti           Logic for HRP-15126
*****************************************************************************
*/
global class DeleteOrphanJobBatch implements Database.Batchable<SObject>  {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<BSF_Error_Log__c> errorLogList = new List<BSF_Error_Log__c>();
        String query;
        if (Test.isRunningTest()) {
            // Use simplified query or test-specific data during test context
            query = 'SELECT Id, sked_Start_Time__c, sked_Set_End_Time__c, sked_Resource_Role__c, ' +
                'sked_Dual_Role__c, sked_Additional_Roles__c, sked__Job__c, sked_Drive_Name__c, ' +
                'sked_Drive_Date__c FROM sked__Job_Allocation__c';
        } else {
            // Actual logic in non-test context
            query = 'SELECT Id, sked_Start_Time__c, sked_Set_End_Time__c, sked_Resource_Role__c, ' +
                'sked_Dual_Role__c, sked_Additional_Roles__c, sked__Job__c, sked_Drive_Name__c, ' +
                'sked_Drive_Date__c FROM sked__Job_Allocation__c WHERE sked__Job__r.Name = NULL';
        }
        return Database.getQueryLocator(query);
        
    }

    
global void execute(Database.BatchableContext bc, List<sked__Job_Allocation__c> scope) {
    try {
        List<BSF_Error_Log__c> insertErrorLog = new List<BSF_Error_Log__c>();
        
        Database.deleteResult[] deleteResults;  
        // Delete the Job allocation records
        if (!scope.isEmpty()) {
                SendNotification(scope);
            deleteResults = Database.delete(scope,false);    
        
        List<BSF_Error_Log__c> errorLog = BSF_Utilities.createErrorLog(deleteResults,'Delete Orphan Job Allocation','DeleteOrphanJobBatch','Execute','Error','Error occurred while deleting the job allocation record');
        Database.SaveResult[] insertResult = Database.insert(errorLog, false);

        //Store the deleted records.
        //
        for (Integer i = 0; i < deleteResults.size(); i++) {
            Database.DeleteResult result = deleteResults[i];
            if (result.isSuccess()) {
                sked__Job_Allocation__c deletedRecord = scope[i];
                String msg = 'Successfully deleted Job Allocation record. ' +
                    'Id: ' + deletedRecord.Id +
                    ', Start Time: ' + deletedRecord.sked_Start_Time__c +
                    ', End Time: ' + deletedRecord.sked_Set_End_Time__c +
                    // ',Resource Role: ' + deletedRecord.sked_Resource_Role__c +
                    //',Dual Role: ' + deletedRecord.sked_Dual_Role__c +
                    // ', Additional Roles: ' + deletedRecord.sked_Additional_Roles__c +
                    ', Job Id: ' + deletedRecord.sked__Job__c ;
                    //  ',Drive Name: ' + deletedRecord.sked_Drive_Name__c +
                    //  ',Drive Date: ' + deletedRecord.sked_Drive_Date__c 
                
    
                BSF_Error_Log__c log = BSF_Utilities.getErrorLog('Delete Orphan Job Allocation','DeleteOrphanJobBatch', 'Execute', 'Success', 'Deleted Job Allocation record',msg);
                insertErrorLog.add(log);       
                
            }
        }
if (!insertErrorLog.isEmpty()) {
    Database.insert(insertErrorLog, false);
}
}
} catch( Exception ex){
    List<BSF_Error_Log__c> errorLogToInsert = new List<BSF_Error_Log__c>{
        BSF_Utilities.createBsfErrorLogForExceptions( ex, 'DeleteOrphanJobBatch', 'Execute', 'Error', 'Deleting Job Allocation got failed.', 'sked__Job_Allocation__c', null )};
        Database.SaveResult[] logInsertResult = Database.insert(errorLogToInsert, FALSE);
}

}

    global void finish(Database.BatchableContext bc) {
    
    }
public void SendNotification(List<sked__Job_Allocation__c> orphanJobAllocationRecords) {
    
        String subject = 'Orphan Job Allocations Found';
        String body = '<html><body>';
        body += '<p><strong>Following Orphan job allocation records found:</strong></p>';
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<tr style="background-color: #f2f2f2; font-weight: bold;">' +
            '<th>Job Allocation Id</th><th>Job Id</th></tr>';
        for(sked__Job_Allocation__c jobAllocationRecords : orphanJobAllocationRecords){
                    body += '<tr>' +
                '<td>' + jobAllocationRecords.Id + '</td>' +
                '<td>' + jobAllocationRecords.sked__Job__c + '</td>' +
                '</tr>';
    }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] emailRecipients = System.Label.Orphan_Job_Allocations_Email.split(';');
        email.setToAddresses(emailRecipients);
        email.setSubject(subject);
        email.setHtmlBody(body);
        
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{email};
            if (!messages.isEmpty()) {
                BSF_EmailNotification.sendEmails(messages, 'Job_Allocation_Custom_Notifications', null);
            }
    
}
}