@isTest
private class skedNightlyTradeProcessSchedulable_Test {
    @isTest
    static void skedNightlyTradeProcessSchedulable_Test() {
        skedNightlyTradeProcessSchedulable schedulable = new skedNightlyTradeProcessSchedulable();
        String chron = '0 0 23 * * ?'; 
        System.schedule('Test schedulable' + Math.random(), chron, schedulable);
    }
}