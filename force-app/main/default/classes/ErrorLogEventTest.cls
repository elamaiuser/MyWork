@isTest
public class ErrorLogEventTest {

    @isTest
    static void testErrorLogEventTrigger() {
        // Create a list of platform event records
        List<Account_Portfolio_Error_Log_Event__e> eventList = new List<Account_Portfolio_Error_Log_Event__e>();

        Account_Portfolio_Error_Log_Event__e eventRecord = new Account_Portfolio_Error_Log_Event__e(
            Process_Name__c = 'Account Portfolio Assignment',
            ApexClass__c = 'AccountPortfolioBatch',
            Method__c = 'execute',
            Type__c = 'Error',
            Error_Description__c = 'Test error occurred'
        );

        eventList.add(eventRecord);

        // Enqueue the platform event(s)
        Test.startTest();
        Database.SaveResult[] results = EventBus.publish(eventList);
        Test.stopTest(); // This is important to fire the trigger

        // Validate the logs were inserted
        List<BSF_Error_Log__c> insertedLogs = [SELECT Id, Process_Name__c, ApexClass__c, Method__c, Type__c, Error_Description__c FROM BSF_Error_Log__c];

       
    }
}