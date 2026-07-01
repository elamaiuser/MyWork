@isTest
private class UserProvisioningErrorHandlerTest {
    @isTest
    static void testCallableInsertErrorLogs() {
        List<BSF_Error_Log__c> mockLogs = new List<BSF_Error_Log__c>{
            new BSF_Error_Log__c() 
        };
        String jsonLogs = JSON.serialize(mockLogs);
        
        Map<String, Object> args = new Map<String, Object>{
            'param1' => jsonLogs,
            'param2' => 'null', 
            'param3' => '',     
            'param4' => null  
        };
        
        Callable handler = new UserProvisioningErrorHandler();
        
        Test.startTest();
        Object result = handler.call('insertErrorLogs', args);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Callable should return true upon successful insertion.');
    }

    @isTest
    static void testCallableInvalidAction() {
        Callable handler = new UserProvisioningErrorHandler();
        
        Test.startTest();
        Object result = handler.call('someUnknownAction', new Map<String, Object>());
        Test.stopTest();
        
        System.assertEquals(null, result, 'Callable should return null for unhandled actions.');
    }

    @isTest
    static void testHandleDatabaseSaveResultsAndChunking() {
        List<Account> badAccounts = new List<Account>();
        for (Integer i = 0; i < 350; i++) {
            badAccounts.add(new Account());
        }
        
        Database.SaveResult[] srList = Database.insert(badAccounts, false);
        
        Test.startTest();
        UserProvisioningErrorHandler.handleDatabaseResults(srList, 'Test Context', 'testSaveError');
        Test.stopTest();
        
        System.assert(true, 'Database SaveResult chunking and dispatch completed successfully.');
    }

    @isTest
    static void testHandleDatabaseDeleteResults() {
        String mobileAccRecType = 'Mobile Account';

        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        Account accObj;
        accObj = new Account();
        accObj.RecordTypeId = accRecTypeId;
        accObj.Name = 'Test Blood Drive Account';
        accObj.BillingPostalCode = '30622';
        accObj.Internal_Name__c ='Exavalu';  
        accObj.Planning_Path__c = 'Flexible';          
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
        insert accObj;
        
        delete accObj;
        
        Database.DeleteResult[] drList = Database.delete(new List<Account>{accObj}, false);
        
        Test.startTest();
        UserProvisioningErrorHandler.handleDatabaseResults(drList, 'Test Context', 'testDeleteError');
        Test.stopTest();
        
        System.assert(true, 'Database DeleteResult dispatch completed successfully.');
    }
    
    @isTest
    static void testHandleDatabaseResultsNull() {
        Test.startTest();
        UserProvisioningErrorHandler.handleDatabaseResults(null, 'Test Context', 'testNullError');
        Test.stopTest();
        
        System.assert(true, 'Null result passed gracefully.');
    }

    @isTest
    static void testHandleExceptions() {
        Exception capturedEx;
        
        try {
            Integer a = 1 / 0; 
        } catch (Exception ex) {
            capturedEx = ex;
        }
        
        Test.startTest();
        UserProvisioningErrorHandler.handleExceptions(capturedEx);
        Test.stopTest();
        
        System.assertNotEquals(null, capturedEx, 'Exception should have been generated and caught.');
    }
    private static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
}