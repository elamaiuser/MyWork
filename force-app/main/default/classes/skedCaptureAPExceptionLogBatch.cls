public class skedCaptureAPExceptionLogBatch implements Database.Batchable<sked__Activity_Resource__c>, Database.Stateful {

    protected Set<Id> activityResourceIds;
    
    public skedCaptureAPExceptionLogBatch(Set<Id> inputIds) {
    	this.activityResourceIds = inputIds;
    }
    
    public List<sked__Activity_Resource__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, sked__Activity__c, sked__Resource__c, sked_Start_Date__c, sked_Start1__c, sked_End_Date__c, sked_End__c
            FROM sked__Activity_Resource__c
            WHERE Id IN :activityResourceIds
        ];
    }
    
    public void execute(Database.BatchableContext BC, List<sked__Activity_Resource__c> records) {
        skedExceptionLogService service = new skedExceptionLogService();
        service.captureAPExceptionLogs(records);
    }
    
    public void finish(Database.BatchableContext BC) {}
    
}