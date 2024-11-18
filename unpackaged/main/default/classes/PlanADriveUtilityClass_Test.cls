/* This test class covers BSF_Queueable_CreateRecurringOpp (100%) */

@isTest
public class PlanADriveUtilityClass_Test 
{
    @isTest
	public static void PlanADriveUtilityClassTest()
    {
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        // insert contact
        Contact testContact = (Contact)mapTestData.get('CONTACT');
        testContact.AccountId = testMobileAccount.id;
        insert testContact;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Site_Contact__c = testContact.Id;
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
       // insert mobile opportunity 1
       	Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
        	StageName = 'Discovery',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(20),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
           Call_List_Recipient_Exist__c=true
		);
        
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        List<Opportunity> oppList = new List<Opportunity>();
        List<List<Opportunity>> oppLists = new List<List<Opportunity>>();
        oppList.add(testMobileOpp1);
        oppLists.add(oppList);
        PlanADriveUtilityClass.queueOpportunityCreation(oppLists);
    }
}