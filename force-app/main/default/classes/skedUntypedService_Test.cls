@isTest
private class skedUntypedService_Test {
    
    static testMethod void testUntypedServiceWithParameters() {
        Test.startTest();
        skedUntypedService testInstance = new skedUntypedService('sked_Drive__c');
        Test.stopTest();
    }
    
    static testMethod void testUntypedServiceWithNoParameters() {
        Test.startTest();
        skedUntypedService testInstance = new skedUntypedService();
        Test.stopTest();
    }
    
    static testMethod void testUntypedServiceWithCaseParameters() {
        Test.startTest();
        skedUntypedService testInstance = new skedUntypedService('Case');
        Test.stopTest();
    }
}