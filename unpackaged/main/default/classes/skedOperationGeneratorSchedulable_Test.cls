@isTest
private class skedOperationGeneratorSchedulable_Test {
    @isTest
    static void skedOperationGeneratorSchedulable_Test() {
        String chron = '0 0 23 * * ?'; 
        System.schedule('Test schedulable' + Math.random(), chron, new skedOperationGeneratorSchedulable());
    }
}