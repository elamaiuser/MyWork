@isTest
private class skedExpireStaffTradeEvents_Test {
    @isTest
    private static void skedExpireStaffTradeEvents_Test() {
        sked_Drive_Shift_Trade__c dst1 = new sked_Drive_Shift_Trade__c(
            sked_Status__c = 'Submitted',
            sked_Requesting_Staff_Drive_Date__c = System.today().addDays(5)
        );
        
        sked_Drive_Shift_Trade__c dst2 = new sked_Drive_Shift_Trade__c(
            sked_Status__c = 'Submitted',
            sked_Requesting_Staff_Drive_Date__c = System.today().addDays(-5)
        );
        insert new List<SObject>{dst1, dst2};
            
        Test.startTest();
        
        skedExpireStaffTradeEventsSchedulable schedulable = new skedExpireStaffTradeEventsSchedulable();
        String chron = '0 0 23 * * ?'; 
        System.schedule('Test schedulable' + Math.random(), chron, schedulable);
        
        Test.stopTest();
    }
}