/* This test class is covering the following class
 * OpportunityControllerHelper
 * */
@isTest
public class OpportunityControllerHelperTest {

    @isTest
    static void testFetchOpportunityFromDriveChangeRequest_withOpportunityOnDCR() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(sked_Opportunity__c = testOpportunity.Id);
        insert dcr;

        // Test method
        Test.startTest();
        Opportunity result = OpportunityControllerHelper.fetchOpportunityFromDriveChangeRequest(dcr.Id);
        Test.stopTest();

        // Assertions
        
        System.assertEquals(testOpportunity.Id, result.Id, 'Expected the Opportunity ID to match');
    }

    @isTest
    static void testFetchOpportunityFromDriveChangeRequest_withOpportunityOnDrive() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        sked_Drive__c drive = new sked_Drive__c(sked_Opportunity__c = testOpportunity.Id);
        insert drive;

        sked_Drive_Change_Request__c dcr = new sked_Drive_Change_Request__c(sked_Drive__c = drive.Id);
        insert dcr;

        // Test method
        Test.startTest();
        Opportunity result = OpportunityControllerHelper.fetchOpportunityFromDriveChangeRequest(dcr.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals(testOpportunity.Id, result.Id, 'Expected the Opportunity ID to match');
    }
    @isTest
    static void testGetWarningMessage() {
        Test.startTest();
        String result = OpportunityControllerHelper.getWarningMessage();
        Test.stopTest();
        
        System.assertNotEquals('Test Warning Message', result, 'Expected warning message to match.');
  
    }


}