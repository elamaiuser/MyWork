@isTest
private class skedDateRangeBase_Test {
    @isTest
    static void compareTo_After_Test() {
        skedDateRangeBase dateRange = new skedDateRangeBase(null, System.today(), System.today().addDays(10));
        skedDateRangeBase otherDateRange = new skedDateRangeBase(null, System.today().addDays(11), System.today().addDays(20));
        
        System.assertEquals(-1, dateRange.compareTo(otherDateRange));
    }

    @isTest
    static void compareTo_Before_Test() {
        skedDateRangeBase dateRange = new skedDateRangeBase(null, System.today().addDays(11), System.today().addDays(20));
        skedDateRangeBase otherDateRange = new skedDateRangeBase(null, System.today(), System.today().addDays(10));
        
        System.assertEquals(1, dateRange.compareTo(otherDateRange));
    }

    @isTest
    static void compareTo_Overlap_Test() {
        skedDateRangeBase dateRange = new skedDateRangeBase(null, System.today(), System.today().addDays(10));
        skedDateRangeBase otherDateRange = new skedDateRangeBase(null, System.today().addDays(5), System.today().addDays(20));
        
        System.assert(dateRange.compareTo(otherDateRange) < 1);
    }

    @isTest
    static void compareTo_SameStartLaterEnd_Test() {
        skedDateRangeBase dateRange = new skedDateRangeBase(null, System.today(), System.today().addDays(10));
        skedDateRangeBase otherDateRange = new skedDateRangeBase(null, System.today(), System.today().addDays(100));

        System.assert(dateRange.compareTo(otherDateRange) < 0);
    }

    @isTest
    static void compareTo_SameStartEarlierEnd_Test() {
        skedDateRangeBase dateRange = new skedDateRangeBase(null, System.today(), System.today().addDays(10));
        skedDateRangeBase otherDateRange = new skedDateRangeBase(null, System.today(), System.today().addDays(5));

        System.assert(dateRange.compareTo(otherDateRange) > 0);
    }
}