@isTest
private class skedFsppHandler_Test {
    
    static testmethod void mainTest() {
        Account testAccount1 = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount1;
        
        sked_Fixed_Site_Procedure_Projection__c fspp = new sked_Fixed_Site_Procedure_Projection__c(
            sked_Account__c = testAccount1.Id,
            sked_Deferral__c = 5,
            sked_QNS__c = 5,
            sked_Productive_Procedure_Goal__c = 10,
            sked_Procedure_Type__c = '2RBC',
            sked_Effective_Start_Date__c = system.today().addDays(-14),
            sked_Effective_End_Date__c = system.today().addDays(14)
        );
        insert fspp;
        
        Test.startTest();
        
        fspp.sked_Productive_Procedure_Goal__c = fspp.sked_Productive_Procedure_Goal__c + 1;
        update fspp;
        
        Test.stopTest();
    }

}