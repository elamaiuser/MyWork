@isTest
private class skedDateRangeUtils_Test {

    @isTest
    static void GetNewDateRanges_NoSystemDateRange() {
        skedDateRange dr1 = new skedDateRange(null, System.today(), System.today().addDays(10), false, null);
        List<skedDateRange> dateRanges = skedDateRangeUtils.GetNewDateRanges(new List<skedDateRange>{dr1}, null);

        System.assertEquals(1, dateRanges.size());
        System.assertEquals(null, dateRanges[0].startDate);
        System.assertEquals(null, dateRanges[0].endDate);
        System.assertEquals(true, dateRanges[0].isSystemGenerated);
    }

    @isTest
    static void GetNewDateRanges_OneDateRange() {
        skedDateRange sysDr = new skedDateRange(null, null, null, true, null);
        skedDateRange dr1 = new skedDateRange(null, System.today(), System.today().addDays(10), false, null);

        List<skedDateRange> dateRanges = skedDateRangeUtils.GetNewDateRanges(new List<skedDateRange>{dr1}, sysDr);

        System.assertEquals(2, dateRanges.size());

        System.assertEquals(null, dateRanges[0].startDate);
        System.assertEquals(System.today().addDays(-1), dateRanges[0].endDate); 

        System.assertEquals(System.today().addDays(11), dateRanges[1].startDate);
        System.assertEquals(null, dateRanges[1].endDate);
    }

    @isTest
    static void GetNewDateRanges_ConsecutiveDateRanges() {
        skedDateRange sysDr = new skedDateRange(null, null, null, true, null);
        skedDateRange dr1 = new skedDateRange(null, System.today(), System.today().addDays(10), false, null);
        skedDateRange dr2 = new skedDateRange(null, System.today().addDays(11), System.today().addDays(20), false, null);

        List<skedDateRange> dateRanges = skedDateRangeUtils.GetNewDateRanges(new List<skedDateRange>{dr1, dr2}, sysDr);

        System.assertEquals(2, dateRanges.size());

        System.assertEquals(null, dateRanges[0].startDate);
        System.assertEquals(System.today().addDays(-1), dateRanges[0].endDate); 

        System.assertEquals(System.today().addDays(21), dateRanges[1].startDate);
        System.assertEquals(null, dateRanges[1].endDate);
    }

    @isTest
    static void IsDateRangeValid_NoDateRanges() {
        skedDateRange dr1 = new skedDateRange(null, System.today(), System.today().addDays(10), false, null);
        skedDateRangeUtils.skedDateRangeResult result = skedDateRangeUtils.IsDateRangeValid(null, dr1);
        System.assertEquals(true, result.isSuccess);
    }

    @isTest
    static void IsDateRangeValid_StartDateOverlap() {
        skedDateRange dr1 = new skedDateRange(null, System.today().addDays(10), System.today().addDays(20), false, null);
        skedDateRange dr2 = new skedDateRange(null, System.today().addDays(5), System.today().addDays(15), false, null);
        skedDateRangeUtils.skedDateRangeResult result = skedDateRangeUtils.IsDateRangeValid(new List<skedDateRange>{dr1}, dr2);
        System.assertEquals(false, result.isSuccess);
    }

    @isTest
    static void IsDateRangeValid_EndDateOverlap() {
        skedDateRange dr1 = new skedDateRange(null, System.today().addDays(10), System.today().addDays(20), false, null);
        skedDateRange dr2 = new skedDateRange(null, System.today().addDays(15), System.today().addDays(25), false, null);
        skedDateRangeUtils.skedDateRangeResult result = skedDateRangeUtils.IsDateRangeValid(new List<skedDateRange>{dr1}, dr2);
        System.assertEquals(false, result.isSuccess);
    }
}