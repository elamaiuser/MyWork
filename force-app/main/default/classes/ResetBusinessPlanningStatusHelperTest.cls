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
    
    static testMethod void testHelperMethod() {
        
        Test.startTest();
        List<ResetBusinessPlanningStatusHelper.getValues> getValuesList = new List<ResetBusinessPlanningStatusHelper.getValues>();
        ResetBusinessPlanningStatusHelper.getValues resetBusinessPlanClass = new ResetBusinessPlanningStatusHelper.getValues();
        
        List<account> accListToUpdate = [SELECT Id, Business_Planning_Completed__c, Business_Planning_Completed_By__c, Business_Planning_Completed_Date__c FROM Account LIMIT 2];
        resetBusinessPlanClass.accListToBeUpdated = accListToUpdate;
        resetBusinessPlanClass.profileName = 'System Administrator';        
        getValuesList.add(resetBusinessPlanClass);
        
        ResetBusinessPlanningStatusHelper.runBusinessPlanResetBatch(getValuesList);
        BSF_Batch_ResetBusinessPlanningStatus batch = new BSF_Batch_ResetBusinessPlanningStatus(getValuesList);
        Database.BatchableContext BC;
        batch.execute(BC, getValuesList);
        
        List<account> accListAfterUpdate = [SELECT Id, Business_Planning_Completed__c, Business_Planning_Completed_By__c, Business_Planning_Completed_Date__c FROM Account WHERE Id IN :accListToUpdate];
        for(Account acc : accListAfterUpdate) {
            Assert.isTrue(acc.Business_Planning_Completed__c == FALSE);
        }        
        Test.stopTest();
            
    }

}