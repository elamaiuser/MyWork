@isTest
private class skedOppDriveSyncSchedulable_Test {
    @isTest
    static void skedOppDriveSyncSchedulable_Test() {
        Test.startTest();
        skedOppDriveSyncSchedulable schedulable = new skedOppDriveSyncSchedulable();
        String chron = '0 0 23 * * ?';        
        System.schedule('Test schedulable' + Math.random(), chron, schedulable);
        Test.stopTest();
    }
}