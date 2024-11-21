/* The following test class is covering the below mentioned apex class
 * SiteMissingAddressBannerController
 * */

@isTest(SeeAllData = FALSE)
public class SiteMissingAddressBannerControllerTest 
{
    
    @testSetup
    public static void prepareDataSetup()
    {
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
    	Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
    
    	// insert mobile site
    	sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
    	testMobileSite.sked_Active__c = true;
    	testMobileSite.sked_Start_Date__c = system.today();
    	testMobileSite.sked_End_Date__c = system.today().addDays(50);
    	insert testMobileSite;

	}
    
    static testMethod void missingAddressBanner1_Test()
    {
        skedHubBase.BypassUpdateTriggers = true;
        sked__Location__c siteObj1 = [Select Id , sked_Address_1__c , sked_City__c , sked_State__c , sked_Zip_Code__c from sked__Location__c];
        
        siteObj1.sked_Address_1__c = '';
        siteObj1.sked_City__c = '';
        update siteObj1;
        
        Test.startTest();
        String bannerMessage1 = SiteMissingAddressBannerController.checkSiteMissingAddress(String.valueOf(siteObj1.Id));
        Test.stopTest();
        
        system.assertEquals('Site Missing Address. Please Populate Address, City.', bannerMessage1);
    }
    
    static testMethod void missingAddressBanner2_Test()
    {
        skedHubBase.BypassUpdateTriggers = true;
        sked__Location__c siteObj2 = [Select Id , sked_Address_1__c , sked_City__c , sked_State__c , sked_Zip_Code__c from sked__Location__c];
        
        siteObj2.sked_State__c = '';
        siteObj2.sked_Zip_Code__c = '';
        
        update siteObj2;
        
        
        Test.startTest();
        String bannerMessage2 = SiteMissingAddressBannerController.checkSiteMissingAddress(String.valueOf(siteObj2.Id));
        Test.stopTest();
        
        system.assertEquals('Site Missing Address. Please Populate State, Zip Code.', bannerMessage2);
    }
    
}