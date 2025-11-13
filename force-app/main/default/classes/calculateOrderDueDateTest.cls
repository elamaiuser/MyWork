@isTest
private class calculateOrderDueDateTest {
    
    @testSetup
    static void prepareTestData() {            
       skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //insert Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        //insert order
        Order testOrder = new Order(
            AccountId = testMobileAccount.Id,
            OpportunityId = testMobileOpp.Id,
            EffectiveDate = system.today(),
            Status = 'Draft'
        );
        insert testOrder;
    }
    
    @isTest
    private static void dueDateMethod_Test() {
        Test.startTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        List<Order> orderList = [SELECT Id, OpportunityId, Order_Due_Date__c FROM Order];
        OrderService.calculateOrderDueDate(orderList);
        
        Opportunity opp = [SELECT Id, Drive_Date__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        opp.Drive_Date__c = Date.newInstance(2024, 4, 10);
        opp.Drive_Date_Change_Reason__c = 'TEST';
        update opp;
        OrderService.calculateOrderDueDate(orderList);
        
        Test.stopTest();
    }
    
    @isTest
    public static void dueDateForSunday_Test() {
        Test.startTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        Opportunity opp = [SELECT Id, Drive_Date__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
        opp.Drive_Date__c = Date.newInstance(2024, 4, 11);
        opp.Drive_Date_Change_Reason__c = 'TEST';
        update opp;
        
        List<order> orderList = [SELECT Id, opportunityId, Order_Due_Date__c FROM Order];
        
        OrderService.calculateOrderDueDate(orderList);
        Test.stopTest();
    }
}