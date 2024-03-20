@isTest
private class BSF_BatchUpdateAccountForZipCodeTest {
    @isTest
    Public static void Test_Schedule_Class()
    {
        Test.StartTest();
		BSF_BatchUpdateAccountSchedule testsche = new BSF_BatchUpdateAccountSchedule(200);
		String sch = '0 0 23 * * ?';
		system.schedule('Test schedule class', sch, testsche );
		Test.stopTest();
        
        CronTrigger contrg = [select Id,CronJobDetailId,CronJobDetail.Name from CronTrigger where CronJobDetail.Name = 'Test schedule class'];
        system.assert(contrg.CronJobDetail.Name == 'Test schedule class');
    }
    static testMethod void test(){
        Collections_Territory__c c=new Collections_Territory__c();
        c.Zip__c='40471';
        c.name='collections';
        c.sked_Start_Date__c=system.today();
        c.sked_End_Date__c=system.today();
        insert c;
        
        Account a=new Account();
        a.name='new account';
        a.BillingPostalCode='40471';
        a.Collections_Territory__c=c.Id;
        insert a;
        
        Test.startTest();
        BSF_BatchUpdateAccountForZipCode ba= new BSF_BatchUpdateAccountForZipCode();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
}