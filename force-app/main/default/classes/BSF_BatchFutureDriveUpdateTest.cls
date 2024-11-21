/* Description : This test class covers below classes :
 * BSF_BatchFutureDriveUpdate -> 100%
 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 11/05/2024				  Priti Jana				Updated for HRP-13521
 *************************************************************************************************************************************************
*/

@isTest
public class BSF_BatchFutureDriveUpdateTest {
    
    @isTest
    private static void opportunityUpdateTest() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        Test.startTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Id jobid = Database.executeBatch(new BSF_BatchFutureDriveUpdate(new List<String>{(String) mobileOpportunity.Id},null, null), 10);
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        Test.stopTest();
        
        Assert.isNotNull(jobid, 'jobid should not be null');
    }
}