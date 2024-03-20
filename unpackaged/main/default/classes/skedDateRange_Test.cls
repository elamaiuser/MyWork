@isTest
private class skedDateRange_Test {
    @isTest
    static void compareTo_After_Test() {
        skedDateRange dateRange = new skedDateRange(null, System.today(), System.today().addDays(10), false, null);
        skedDateRange otherDateRange = new skedDateRange(null, System.today().addDays(11), System.today().addDays(20), false, null);
        
        System.assertEquals(-1, dateRange.compareTo(otherDateRange));
    }

    @isTest
    static void compareTo_Before_Test() {
        skedDateRange dateRange = new skedDateRange(null, System.today().addDays(11), System.today().addDays(20), false, null);
        skedDateRange otherDateRange = new skedDateRange(null, System.today(), System.today().addDays(10), false, null);
        
        System.assertEquals(1, dateRange.compareTo(otherDateRange));
    }

    @isTest
    static void compareTo_Overlap_Test() {
        skedDateRange dateRange = new skedDateRange(null, System.today(), System.today().addDays(10), false, null);
        skedDateRange otherDateRange = new skedDateRange(null, System.today().addDays(5), System.today().addDays(20), false, null);
        otherDateRange.toString();
        
        System.assert(dateRange.compareTo(otherDateRange) < 1);
    }
}