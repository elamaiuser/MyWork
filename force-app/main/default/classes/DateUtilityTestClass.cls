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
        	Donor_Eligibility_Day_for_WB__c = '57'
        );
        insert setting;
    }
        
    @isTest static void test_validateGetWeeklyRecurrenceDate() {
		Test.startTest();
        DateUtility.ReturnValue result = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'weekly', '1', 'MON,TUE,WED,THU,FRI,SAT', '-1', '1', 'DAY', new List<String>()); 
    	Test.stopTest();
    }

    @isTest static void test_validateGetMonthlyRecurrenceDate() {
		Test.startTest();
        DateUtility.ReturnValue result = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'monthly', '1', 'MON,TUE,WED,THU,FRI,SAT', '-1', '1', 'DAY', new List<String>());
        DateUtility.ReturnValue result1 = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'monthly', '1', 'MON,TUE,WED,THU,FRI,SAT', '1', '1', 'SUNDAY', new List<String>());
    	Test.stopTest();
    }
    
    //HRP-13039: Test Methods starts here
    
    @isTest static void test_getDonorEligibilityDay() {
        Test.startTest();
        DateUtility.ReturnValue result1 = DateUtility.getDonorEligibilityDay('powerRed');
        DateUtility.ReturnValue result2 = DateUtility.getDonorEligibilityDay('wholeBlood');
        Assert.isTrue(result1.donorEligibilityDay == '113');
        Assert.isTrue(result2.donorEligibilityDay == '57');
        Test.stopTest();
    }
    
    @isTest static void test_validateGetOtherRecurrenceTypeDate() {
        Test.startTest();
        DateUtility.ReturnValue result = DateUtility.getOtherRecurrenceDateBasedOnDonorEligibility('2021-07-08', '2022-03-05', new List<String>{'powerRed'});
        Assert.isTrue(result.returnValue.size() == 2);
        Test.stopTest();
    }
    
    //HRP-13039: Test Methods ends here
    
}