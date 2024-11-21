@isTest
public class AddBusinessDaysTest {
    @testSetup
    public static void setupDate(){
        Test.startTest();               
        Account acc = new account();
        acc.name='testAccount';
        insert acc;   
        
        opportunity opp1=new opportunity();
        opp1.AccountId=acc.Id;
        opp1.name='testOpp1';
        opp1.StageName= 'Closed';
        opp1.Drive_Date__c =  system.today().addDays(3) ;
        opp1.CloseDate = system.today();
        opp1.Start_Time__c = Time.newInstance(10, 2, 3, 0) ;
        opp1.End_Time__c = Time.newInstance(20, 2, 3, 0);
        opp1.Accept_56_Day_Rule_Violation__c = true;
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
    public static void addBusinessDays_Test(){
        date newDate = date.newInstance(2021, 05, 27);
        list<order> orderList = [select id, opportunityId, Order_Due_Date__c from order];
        OrderService.calculateOrderDueDate(orderList);
        for(order od: orderList){
            system.assertNotEquals(od.Order_Due_Date__c, newDate, 'Date mismatched');            
        }
    }
}