@isTest
public class createBsfErrorLogs_TEST 
{
    @isTest
	public static void testCreateBSFErrorLog()
    {
         	BSF_Error_Log__c errorLog = new BSF_Error_Log__c(
            ApexClass__c = 'className',
            Method__c = 'methodName',
            Type__c = 'Error',
            Error_Description__c = 'Error Type - ',
            Error_Description_Long__c = 'StackTracing :',
            Process_Name__c = 'processName',
            Functionality__c = 'functionality'
        );
        
        insert errorLog;
        
        List<Error_Log_Event__e> publishEvents = new List<Error_Log_Event__e>();
            Error_Log_Event__e eve = new Error_Log_Event__e();
            eve.RecordId__c =errorLog.Id ;
            eve.Error_Message__c = 'TEST message';
            publishEvents.add(eve);
            if(publishEvents.size()>0)
            {
                test.startTest();
                EventBus.publish(publishEvents);
                test.stopTest();
            }
    }
}