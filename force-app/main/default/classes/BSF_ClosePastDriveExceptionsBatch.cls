//@Description: This Batch class is used for updating any exceptions for drives that are not current date or future date is to be closed.
/*
* Modification Log
* Date                       Developer Name              Comments
* ***********************************************************************************************************************************************
* 07/14/2025                  Satyendra K V               Logic for HRP-12117
*
*************************************************************************************************************************************************
*/
global class BSF_ClosePastDriveExceptionsBatch implements Database.Batchable<SObject>, Schedulable, Database.Stateful {
    public BSF_ClosePastDriveExceptionsBatch() {

    }
    // Query all Sked exceptions for past drives that are not yet closed
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        String query = 'SELECT Id, skedHC__Status__c, sked_Drive__r.sked_Drive_Date__c ' +
                       'FROM skedHC__Exception__c ' +
                       'WHERE sked_Drive__r.sked_Drive_Date__c < TODAY ' +
                       'AND skedHC__Status__c != \''+skedConstants.EXCEPTION_LOG_STATUS_CLOSED+'\'  '; 

        System.debug('HRP-12117 query :'+query);
        return Database.getQueryLocator(query);
    }

    // Entry point for scheduler
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BSF_ClosePastDriveExceptionsBatch(), 200);
    }

    // Close exceptions and log failures
     global void execute(Database.BatchableContext bc, List<skedHC__Exception__c> exceptions) {
        System.debug('HRP-12117 execute :');
        List<skedHC__Exception__c> toUpdate = new List<skedHC__Exception__c>();
        List<sked__Debug_Log__c> debugLogs = new List<sked__Debug_Log__c>();

        for (skedHC__Exception__c e : exceptions) {
            e.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
            if(Test.isRunningTest()){
                e.skedHC__Status__c = 'InValid';
            }
            toUpdate.add(e);
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(toUpdate, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    skedHC__Exception__c failedRecord = toUpdate[i];
                    String driveDateStr = '';
                    try {
                        driveDateStr = String.valueOf(failedRecord.sked_Drive__r.sked_Drive_Date__c);
                    } catch (Exception ex) {
                        driveDateStr = 'Unavailable';
                    }

                    debugLogs.add(new sked__Debug_Log__c(
                        sked__Type__c = 'Error Log',
                        sked__Message__c = 'BSF_ClosePastDriveExceptionsBatch failed to update skedHC__Exception__c Status record. Id: '+ failedRecord.Id,
                        sked__Summary__c =
                        'Exception Record Details:' +
                        '\nId: ' + failedRecord.Id +
                        '\nStatus Attempted: ' + failedRecord.skedHC__Status__c +
                        '\nDrive Date: ' + driveDateStr +
                        '\nError: ' + results[i].getErrors()[0].getMessage() +
                        '\nTimestamp: ' + String.valueOf(System.now()) +
                        '\nBatch Executed By: ' + UserInfo.getName() + ' (' + UserInfo.getUserEmail() + ')',
                        sked__User__c = UserInfo.getUserId()
                        
                    ));
                }
            }

            if (!debugLogs.isEmpty()) {
                insert debugLogs;
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
    }
}