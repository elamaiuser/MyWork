@isTest 
private class DateUtilityTestClass {
        
    @isTest static void validateGetWeeklyRecurrenceDate() {

        DateUtility.ReturnValue result = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'weekly', '1', 'MON,TUE,WED,THU,FRI,SAT', '-1', '1', 'DAY'); 
    }

    @isTest static void validateGetMonthlyRecurrenceDate() {

        DateUtility.ReturnValue result = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'monthly', '1', 'MON,TUE,WED,THU,FRI,SAT', '-1', '1', 'DAY');
        DateUtility.ReturnValue result1 = DateUtility.getRecurrenceDate('2021-07-08', '2022-03-05', 'monthly', '1', 'MON,TUE,WED,THU,FRI,SAT', '1', '1', 'SUNDAY');
    }
}