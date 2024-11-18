/* Description : This test class covers BSF_Batch_TaskRename 
 * Current Test Coverage : 100%
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 10/30/2024				  Priti Jana				Created for HRP-?
 *************************************************************************************************************************************************
*/

@isTest
public class BSF_Batch_TaskRename_Test {
    
    @testSetup static void prepareTestData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        //insert Task
        Task newAddressUpdateTask = new Task(
        	WhatId = testMobileAccount.Id,
        	Subject = 'Invalid Account Address',
        	Status = 'Not Started',
        	Priority= 'Normal',
        	OwnerId = UserInfo.getUserId(),
        	ActivityDate = system.today().addDays(20)
        );
        insert newAddressUpdateTask;
    }
    
    static testMethod void testBatchExecution() {
        Test.startTest();
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];
        BSF_Batch_TaskRename taskRenameBatchInstance = new BSF_Batch_TaskRename(
            new List<String>{'Completed'},
            new List<String>{(String) testAccount.Id},
            new Map<String, String>{'Invalid Account Address' => 'Invalid Account Address (Update Required)'}
        );
        Database.executeBatch(taskRenameBatchInstance, 100);
        Task updatedTask = [SELECT Id, Subject FROM Task WHERE WhatId = :testAccount.Id LIMIT 1];
        Assert.areEqual('Invalid Account Address (Update Required)', updatedTask.Subject);
        Test.stopTest();
    } 

}