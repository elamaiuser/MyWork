/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_OpportunityTest
{
    @IsTest
    private static void testTrigger()
    {
Test.startTest();
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
         // insert Mobile Opp 1
        Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Draft',
            Type_of_Drive__c = 'Mobile',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            Drive_Name__c = 'Test Drive',
            Drive_Date__c = system.today().addDays(55),
            CloseDate = system.today(),
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
            End_Time__c = Time.newInstance(15, 30, 0, 0),
            Flow_Start_Time_Field__c = '1000',
            Flow_End_Time_Field__c = '1530',
            WB_Projected_Procedures__c = 4,
            X2RBC_Projected_Procedures__c = 2,
            Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
        );
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp1;

Test.stopTest();
    }
}