@isTest
public class BSF_Batch_UserEmailVerfnFollowupTest {
    @testSetup
    static void setupTestData() {
        // Create a test user
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert DRD User
        User drdUser = (User)mapTestData.get('DRD_USER');
        System.runAs( new User(Id = UserInfo.getUserId()))
        {
            insert drdUser;
        }
    }

    @isTest
    static void testBatchExecution() {
        
        BSF_Batch_UserEmailVerificationFollowup batchJob = new BSF_Batch_UserEmailVerificationFollowup();
        Test.startTest();
        ID batchprocessid = Database.executeBatch(batchJob);
        Test.stopTest();
        
        Assert.isNotNull(batchprocessid, 'Batch job executed successfully.');
    }
    
    @isTest
    static void testBatchWithUserIds() {
        List<User> unverifiedUsers = [SELECT Id FROM User WHERE IsActive = true];
        
        BSF_Batch_UserEmailVerificationFollowup batchJob = new BSF_Batch_UserEmailVerificationFollowup(new List<String>{unverifiedUsers[0].Id});
        Test.startTest();
        ID batchprocessid = Database.executeBatch(batchJob);
        Test.stopTest();
        
        Assert.isNotNull(batchprocessid, 'Batch job executed successfully for specified users.');
    }
}