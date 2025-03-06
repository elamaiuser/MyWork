/* The following test class covers DateUtility class (88%)
 
      Modification Log 
  	  Date					     Developer Name			            Comments
 	  **************************************************************************************
      2/7/2025                    Priti Jana			Added test methods to cover HRP-13039   
*/

@isTest 
private class DateUtilityTestClass {
    
    @testSetup
    private static void prepareTestData() {
        BSF_setting__c setting = new BSF_setting__c(
        	Donor_Eligibility_Day_for_2RBC__c = '113',
        	Donor_Eligibility_Day_for_WB__c = '57',
            Is_Donor_Eligibility_Msg_Needed__c = true,
            Donor_Eligibility_Msg__c = 'System will calculate drive dates based on donor eligibility for {donorEligibilityType} every {donorEligibilityDay} days'
        );
        insert setting;
    }
        
    @isTest static void test_validateGetWeeklyRecurrenceDate() {
		Test.startTest();
        DateUtility.ReturnValue result = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'weekly', '1', 'MON,TUE,WED,THU,FRI,SAT', '-1', '1', 'DAY', 'wholeBlood'); 
    	Test.stopTest();
    }

    @isTest static void test_validateGetMonthlyRecurrenceDate() {
		Test.startTest();
        DateUtility.ReturnValue result = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'monthly', '1', 'MON,TUE,WED,THU,FRI,SAT', '-1', '1', 'DAY', 'wholeBlood');
        DateUtility.ReturnValue result1 = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'monthly', '1', 'MON,TUE,WED,THU,FRI,SAT', '1', '1', 'SUNDAY', 'wholeBlood');
    	Test.stopTest();
    }
    
    //HRP-13039: Test Methods starts here
    
    @isTest static void test_getDonorEligibilityDay() {
        Test.startTest();
        DateUtility.ReturnValue result1 = DateUtility.getDonorEligibilityDay('Power Red');
        DateUtility.ReturnValue result2 = DateUtility.getDonorEligibilityDay('Whole Blood');
        Assert.isTrue(result1.donorEligibilityDay == '113');
        Assert.isTrue(result2.donorEligibilityDay == '57');
        Test.stopTest();
    }
    
    @isTest static void test_validateGetOtherRecurrenceTypeDate() {
        Test.startTest();
        DateUtility.ReturnValue result = DateUtility.getOtherRecurrenceDateBasedOnDonorEligibility('2021-07-08', '2022-03-05', 'Power Red');
        Assert.isTrue(result.returnValue.size() == 2);
        Test.stopTest();
    }
    
    //HRP-13039: Test Methods ends here
    
}