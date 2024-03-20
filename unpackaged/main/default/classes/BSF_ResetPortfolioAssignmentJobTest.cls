/* 
 * @description: This class is the test class for BSF_ResetPortfolioAssignmentJob.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 12/26/2023				 Barnojit Sharma		     Reset Portfolio Assignment flag and record count(Logic for HRP-10460)
 ************************************************************************************************************************************************
*/
@IsTest
private class BSF_ResetPortfolioAssignmentJobTest {
    @TestSetup
    static void makeData(){
        Portfolio_Accounts_Processing__c accPro = new Portfolio_Accounts_Processing__c();
        accPro.Portfolio_Assignment_Updated__c = true;
        accPro.Portfolio_progress_for_Accounts__c = 20;
        accPro.Records_Processed__c = 10;
        insert accPro;
        Assert.isNotNull(accPro.Id,'Record Not Inserted.');
    }
    @IsTest
    static void testMethod1(){
        Test.startTest();
        BSF_ResetPortfolioAssignmentJob mysc = New BSF_ResetPortfolioAssignmentJob();
        System.schedule('Test schedule', '0 0 * * * ? *', mysc);
        Test.stopTest();
    }
}