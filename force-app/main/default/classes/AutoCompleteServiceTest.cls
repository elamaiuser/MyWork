/* This test class is covering the below apex class
 *  AutoCompleteService
 * */

@isTest(SeeAllData=false)
private class AutoCompleteServiceTest {
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        insert testMobileAccount;
    }
    
    @isTest static void getAcValuesTest() {
        Test.startTest();
        List<AutoCompleteService.Option> optionList =  AutoCompleteService.getACValues('Account', 'Name' , 'Internal_Name__c' , 'Test Account' , '1');
        Test.stopTest();
        Assert.isTrue(optionList.size() == 1); // one record will be appeared as the limit has been set as 1
    }
}