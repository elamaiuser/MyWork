@isTest
public class generateTemplateOppIdTest {
    
    @testSetup
    static void dataSetupMethod(){
        Test.startTest();               
        Account acc = new account();
        acc.name='testAccount';
        insert acc;     
        
        Contact con = new Contact();
        con.firstname = 'Test';
        con.lastName = 'Contact';
        con.AccountId = acc.Id;
        con.Email = 'testContact@gmail.com';
        con.Original_Service_Date__c = system.today().addDays(3);
        con.Primary_Phone__c = 'Mobile Phone';
        con.MobilePhone = '752-781-0090';
        con.MailingStreet = 'test';
        con.MailingStreet_1__c = 'test';
        con.MailingStreet_2__c = 'test';
        con.MailingCity = 't';
        con.MailingCountry = 'United States';
        con.MailingState = 'Texas';
        con.MailingPostalCode = '75240';
        insert con;
        
        list<opportunity> oppList = new list<opportunity>();
        for(Integer i = 1; i<5; i++){
            opportunity opp1=new opportunity();
            opp1.AccountId=acc.Id;
            opp1.name='testOpp' + i;
            opp1.StageName= 'Draft';
            opp1.CloseDate= System.today(); 
            opp1.Drive_Date__c = system.today() + i;
            Time startTime = Time.newInstance(10, 0, 0, 0);
        	opp1.Start_Time__c = startTime;
        	Time endTime = Time.newInstance(15, 30, 0, 0);
        	opp1.End_Time__c = endTime;
            opp1.Accept_56_Day_Rule_Violation__c = true;
            opp1.is_template__c = false;
            opp1.Additional_Description__c = 'test Desc';
            opp1.Template_Status__c = 'Inactive';
            oppList.add(opp1);
        }
        
        insert oppList;  
        Test.stopTest();
        
    }
    @isTest
    public static void generateTmpId_Test(){
        map<id,opportunity> oppMap = new map<id,opportunity>([select id, name,is_template__c,Account_Internal_Name__c, Additional_Description__c, Drive_Site_Name__c, Template_Status__c from opportunity]);
        list<opportunity> oppList = new list<opportunity>();
        for(id i: oppMap.keySet()){
            oppList.add(oppMap.get(i));
        }
        oppList[0].is_template__c = true;
        oppList[1].is_template__c = true;
        
        update oppList;
        //OpportunityService.generateTemplateOppId(oppList,oppMap);
        //list<opportunity> oppListUpdate = [select name,is_template__c from opportunity where is_template__c = true];
        //system.assertEquals(oppListUpdate[0].Template_Id__c, '1', 'Template Id mismatched');
        //system.assertEquals(oppListUpdate[1].Template_Id__c, '2', 'Template Id mismatched');       
    }
}