@isTest
public class FetchOpportunityListTest {
    @testSetup
    static void dataSetupMethod(){
        Test.startTest();
        
        list<opportunity> oppList = new list<opportunity>();
        
        Account acc = new account();
        acc.name='testAccount';
        insert acc;
        
        for(integer i=1; i<5; i++){
            opportunity opp=new opportunity();
            opp.AccountId=acc.Id;
            opp.name='testOpp'+i;
            opp.StageName= 'Closed';
            opp.CloseDate= System.today(); 
           // opp.Drive_Date__c = system.today() + i;
            oppList.add(opp);
        }        
        insert oppList;  
        Test.stopTest();
    } 
    @isTest static void fetchOppList(){
        List<Opportunity> getOppList =  FetchOpportunityList.listOppLwc();  
        for(opportunity opp: getOppList){
            opp.description = 'Test Description';
        }
        List<Opportunity> getUpdatedOppList = FetchOpportunityList.updateOppLwc(getOppList);
        string oppDescription;
        for(opportunity opp: getUpdatedOppList){
            oppDescription = opp.Description;
        }
        system.assertEquals(oppDescription, 'Test Description', 'Dscription Mismatched');
    }
}