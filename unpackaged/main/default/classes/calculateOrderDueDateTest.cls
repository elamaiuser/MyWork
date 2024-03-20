@isTest
public class calculateOrderDueDateTest {
    @testSetup
    public static void setupData(){
        Test.startTest();               
        Account acc = new account();
        acc.name='testAccount';
        insert acc;   
        
        opportunity opp1=new opportunity();
        opp1.AccountId=acc.Id;
        opp1.name='testOpp1';
        opp1.StageName= 'Discovery';
        opp1.CloseDate= date.newInstance(2022, 11, 05); 
        opp1.Drive_Date__c = date.newInstance(2022, 11, 08);
        opp1.Accept_56_Day_Rule_Violation__c = true;
        opp1.End_Time__c = Time.newInstance(4, 4, 4, 4);
        insert opp1;  
        
        Order od = new Order();
        od.AccountId = acc.Id;
        od.OpportunityId = opp1.Id;
        od.EffectiveDate = system.today();
        od.Status = 'Draft';
        insert od;
        
        Test.stopTest();
    }
    @isTest
    public static void dueDateMethod_Test(){
        Test.startTest();
        list<order> orderList = [select id, opportunityId, Order_Due_Date__c from order];
        OrderService.calculateOrderDueDate(orderList);
        
        list<opportunity> oppList = [Select id, Drive_Date__c from opportunity];
        for(opportunity opp: oppList){
            opp.Drive_Date__c = Date.newInstance(2021, 4, 10);
        }
        update oppList;
        OrderService.calculateOrderDueDate(orderList);
        
        Test.stopTest();
    }
    @isTest
    public static void dueDateForSunday_Test(){
        Test.startTest();
        list<opportunity> oppList1 = [Select id, Drive_Date__c from opportunity];
        for(opportunity opp: oppList1){
            opp.Drive_Date__c = Date.newInstance(2021, 4, 11);
        }
        update oppList1;
        list<order> orderList = [select id, opportunityId, Order_Due_Date__c from order];
        
        OrderService.calculateOrderDueDate(orderList);
        Test.stopTest();
    }
}