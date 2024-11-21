/* Description : This test class covers SiteSuitabilityController 
 * Current Test Coverage : 90%
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 10/30/2024				  Priti Jana				Created for HRP-8137
 *************************************************************************************************************************************************
*/

@isTest
public class SiteSuitabilityController_Test {
    
    @testSetup static void prepareTestData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        //insert Site Suitability Checklist
        Site_Suitability_Checklist__c siteSuitabilityChecklist = new Site_Suitability_Checklist__c(
        	UniqueName__c = 'A1_Site_Characteristics_Checked',
        	Value__c = TRUE,
        	Site__c = testMobileSite.Id
        );
        insert siteSuitabilityChecklist;
    }
	
    static testMethod void testCheckEditAccess() {
        Test.startTest();
        Boolean hasEditAccess = SiteSuitabilityController.checkEditAccess();
        Assert.areEqual(TRUE, hasEditAccess);
        Test.stopTest();
    }
    
    static testMethod void testGetSiteSuitabilityChecklist() {
        Test.startTest();
        Id testSiteId = [SELECT Id FROM sked__Location__c LIMIT 1].Id;
        Map<String, Map<String, String>> map_mdtLabel_mdtFieldsMap = SiteSuitabilityController.getSiteSuitabilitychecklist((String) testSiteId);
        system.debug('map_mdtLabel_mdtFieldsMap '+map_mdtLabel_mdtFieldsMap);
        Assert.isNotNull(map_mdtLabel_mdtFieldsMap);
        Assert.isNotNull(map_mdtLabel_mdtFieldsMap.get('A1_Site_Characteristics_Checked'));
        Test.stopTest();
    }
}