@isTest
public class TaskPlatform_Test 
{
    @isTest
	static void taskPlatformTestMethod()
    {
        
        Account acc = new Account(name='Test Account 1');
        acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
        acc.BillingCity = 'Herndon';
        acc.BillingStateCode = 'MI';
        acc.BillingPostalCode = '48093';
        acc.Internal_Name__c ='TEst Test Account 1';
        insert acc;
        Id recTypeId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Recruitment Meeting').getRecordTypeId();
        list<Task_Platform_Event__e> taskPlatformEventList = new list<Task_Platform_Event__e>();
         			Task_Platform_Event__e tp = new Task_Platform_Event__e();
                    tp.RecordTypeId__c=recTypeId;
                    tp.ActivityDate__c=system.today();
                    tp.OwnerId__c=userinfo.getuserid();
                    tp.Subject__c='recruitment';
                    tp.WhatId__c=acc.id;
                    taskPlatformEventList.add(tp);
        
        test.StartTest();
        Eventbus.publish(taskPlatformEventList);
        test.StopTest();
        assert.isNotNull([select id,subject from task where subject='recruitment' and whatId=:acc.id]);
    }
}