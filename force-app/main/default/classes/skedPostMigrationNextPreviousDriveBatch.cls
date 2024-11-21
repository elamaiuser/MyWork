global class skedPostMigrationNextPreviousDriveBatch implements Database.Batchable<sked_Drive__c>, Database.AllowsCallouts, Database.Stateful {
    
    protected string lastId = '';

    global skedPostMigrationNextPreviousDriveBatch(string lastId) { 
    	this.lastId = lastId;
    }
    
    global List<sked_Drive__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Account__c, sked_Drive_Date__c, sked_Next_Drive__c, sked_Previous_Drive__c, 
                sked_Post_Migration_Completed_Steps__c 
                FROM sked_Drive__c
                WHERE Id > :this.lastId
                AND sked_MigrationID__c != NULL
                AND sked_Post_Migration_Processed__c = FALSE
                AND sked_Post_Migration_Completed_Steps__c EXCLUDES('Populate Next/Previous Drive')
                ORDER BY Id ASC
                LIMIT 40000];
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> records) {
        //NOTE: the below function uses 2 SOQL 1 DML per record. So the max chunk size is 50
        try {
            slwcDriveService.populateNextPreviousDrive(records);
        }
        catch (exception ex) {
            sked__Debug_Log__c debugLog = new sked__Debug_Log__c(
                sked__Message__c = ex.getStackTraceString(),
                sked__Summary__c = ex.getMessage(),
                sked__Type__c = 'Debug Log'
            );
            insert debugLog;
        }
        
        List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
        for (sked_Drive__c record : records) {
            List<string> postMigrationCompletedSteps = new List<string>();
            if (!string.isBlank(record.sked_Post_Migration_Completed_Steps__c)) {
                postMigrationCompletedSteps = record.sked_Post_Migration_Completed_Steps__c.split(';');
            }
            postMigrationCompletedSteps.add('Populate Next/Previous Drive');
            
            sked_Drive__c skedDrive = new sked_Drive__c(
                Id = record.Id,
            	sked_Post_Migration_Completed_Steps__c = string.join(postMigrationCompletedSteps, ';')
            );
            drivesToUpdate.add(skedDrive);
        }
        update drivesToUpdate;
        
        this.lastId = records.get(records.size() - 1).Id;
    }
    
    global void finish(Database.BatchableContext BC) {
        List<sked_Drive__c> remainRecordQuery = [
            SELECT Id
            FROM sked_Drive__c
            WHERE Id > :this.lastId
            AND sked_MigrationID__c != NULL
            AND sked_Post_Migration_Processed__c = FALSE
            AND sked_Post_Migration_Completed_Steps__c EXCLUDES('Populate Next/Previous Drive')
            ORDER BY Id ASC
            LIMIT 1
        ];

        if (!Test.isRunningTest()) {
            if (!remainRecordQuery.isEmpty()) {
                   Database.executeBatch(new skedPostMigrationNextPreviousDriveBatch(this.lastId), 50);
            }
            else {
                Database.executeBatch(new skedPostDriveMigrationBatch(''), 200);
            }
        }
    }
    
}