/* The following test class covers below mentioned apex classes
 * ResetBusinessPlanningStatusHelper
 * BSF_Batch_ResetBusinessPlanningStatus
 
@Created : 2/20/2024 Priti Jana
**********************************************************************************************************************************************************/

@isTest(seeAllData = false)
public class ResetBusinessPlanningStatusHelperTest {
    
    @testSetup
    private static void prepareData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        List<Account> accList = new List<Account>();
        
        // Account Preparation
        Account testFixedSiteAcc = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testFixedSiteAcc.Business_Planning_Completed__c = TRUE;
        accList.add(testFixedSiteAcc);        
        Account testMobileAcc = (Account)mapTestData.get('MOBILE_ACCOUNT');  
        testMobileAcc.Business_Planning_Completed__c = TRUE;
        accList.add(testMobileAcc);
        
        insert accList;
    }
    
    @IsTest
static void testHelperMethods() {
    ResetBusinessPlanningStatusHelper.Request countReq = new ResetBusinessPlanningStatusHelper.Request();
    countReq.action = 'count';
    countReq.onlyCompleted = true;
    
    List<ResetBusinessPlanningStatusHelper.Response> countResults =
        ResetBusinessPlanningStatusHelper.run(new List<ResetBusinessPlanningStatusHelper.Request>{ countReq });
    
    System.assertEquals(2, countResults[0].total, 'Expected 2 accounts to be completed');
    System.assertEquals(null, countResults[0].jobId, 'JobId should be null for count action');
    

    ResetBusinessPlanningStatusHelper.Request startReq = new ResetBusinessPlanningStatusHelper.Request();
    startReq.action = 'start';
    startReq.profileName = 'System Administrator'; 
    startReq.onlyCompleted = true;
    
    Test.startTest();
    List<ResetBusinessPlanningStatusHelper.Response> startResults =
        ResetBusinessPlanningStatusHelper.run(new List<ResetBusinessPlanningStatusHelper.Request>{ startReq });
    Test.stopTest(); 
    
    System.assertNotEquals(null, startResults[0].jobId, 'JobId should be returned for start action');
    
    List<Account> accListAfter = [
        SELECT Id, Business_Planning_Completed__c
        FROM Account
    ];
    
    for (Account acc : accListAfter) {
        System.assertEquals(false, acc.Business_Planning_Completed__c,
            'Business_Planning_Completed__c should be reset to false after batch');
    }
}

}