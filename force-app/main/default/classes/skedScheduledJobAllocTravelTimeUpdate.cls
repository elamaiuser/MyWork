global class skedScheduledJobAllocTravelTimeUpdate implements Schedulable{
    global void execute(SchedulableContext SC) {
        List<sked__Job_Allocation__c> records = [
            SELECT Id
            FROM sked__Job_Allocation__c
            WHERE (sked_Travel_Time_To__c = NULL OR sked_Travel_Time_Back__c = NULL)
            AND sked__Status__c != 'Deleted'
            AND sked_Optimization_Run__c != NULL 
            AND sked__Job__r.sked_Resource_Role__c != NULL
            AND sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
            AND sked__Job__r.sked_Drive__r.sked_Status__c != 'Cancel'            
        ];

        Set<Id> recordIds = new Set<Id>();
        sked__Debug_Log__c debugLogs = new sked__Debug_Log__c();
        debugLogs.sked__Summary__c = '';
        for (sked__Job_Allocation__c record : records) {
            debugLogs.sked__Summary__c += record.Id + ', ';
            recordIds.add(record.Id);
        }
        System.debug('Record Count: '+ recordIds.size());        
        debugLogs.sked__Message__c = 'Number of Job Allocations that has null Travel Time: '+ recordIds.size() + ' records';
        debugLogs.sked__Type__c = 'Debug Log';
        insert debugLogs;
        if(!recordIds.isEmpty()){
            Database.executeBatch(new skedJobAllocationTravelTimeBatch(recordIds), 40);            
        }        
    }
}