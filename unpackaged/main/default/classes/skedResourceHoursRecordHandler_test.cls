@isTest
public class skedResourceHoursRecordHandler_test{
	
	
	@isTest
	public static void testmethod1() {
		
		skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
		
		testResource1.sked_Max_Hours_Per_Week__c = 30;
		update testResource1;		
		
		sked_Resource_Hours_Record__c rhr = new sked_Resource_Hours_Record__c();
		rhr.sked_Resource__c = testResource1.id;
		rhr.sked_Start_Date__c = System.today();
		rhr.sked_End_Date__c = System.today().addDays(2);		
		insert rhr;
		
		sked_Resource_Hours_Record_Detail__c rhrd = new sked_Resource_Hours_Record_Detail__c();
		rhrd.sked_Resource_Hours_Record__c = rhr.id;
		rhrd.sked_Duration__c = 40;
		insert rhrd;
		
		rhrd.sked_Duration__c = 2000;
		update rhrd;	
		
		rhrd.sked_Duration__c = 40;
		update rhrd;
		
	}
}