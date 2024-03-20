/* Class Name : OpportunityService
* Method Name : updateAccountWithEarliestDriveDate
*/
@isTest
public class updateEarliestDriveDateHelperTest {
    @testSetup
    static void dataSetupMethod(){
        Test.startTest();               
        Account acc = new account();
        acc.name='testAccount';
        insert acc;     
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.lastName = 'Contact';
        con.AccountId = acc.Id;
        con.MailingStreet = 'test';
        con.MailingStreet_1__c = 'test';
        con.MailingStreet_2__c = 'test';
        con.MailingCity = 't';
        con.MailingCountry = 'United States';
        con.MailingState = 'Texas';
        con.MailingPostalCode = '75240';
        con.Email = 'testContact@gmail.com';
        con.Original_Service_Date__c = system.today().addDays(3);
        con.Primary_Phone__c = 'Mobile Phone';
        con.MobilePhone = '752-781-0090';
        insert con;
        
        Account_Service_Role__c accRole = new Account_Service_Role__c();
        accRole.Account__c = acc.Id;
        accRole.Contact__c = con.Id;
        accRole.Account_Service_Role__c = 'Blood Program Leader';
        insert accRole;
        
        list<opportunity> oppList = new list<opportunity>();
        
        opportunity opp1=new opportunity();
        opp1.AccountId=acc.Id;
        opp1.name='testOpp1';
        opp1.StageName= 'Closed';
        opp1.Drive_Date__c = date.newInstance(3000, 12, 31);
        opp1.CloseDate= opp1.Drive_Date__c-1;
        opp1.Start_Time__c = Time.newInstance(9, 2, 0, 0);
        opp1.End_Time__c = Time.newInstance(21, 2, 0, 0);
        opp1.Accept_56_Day_Rule_Violation__c = true;
        oppList.add(opp1);
        
        opportunity opp2=new opportunity();
        opp2.AccountId=acc.Id;
        opp2.name='testOpp2';
        opp2.StageName= 'Draft';
        opp2.Drive_Date__c = date.newInstance(3000, 11, 31);
        opp2.CloseDate= opp2.Drive_Date__c-1;
        opp2.Start_Time__c = Time.newInstance(10, 2, 0, 0);
        opp2.End_Time__c = Time.newInstance(23, 2, 0, 0);
        opp2.Accept_56_Day_Rule_Violation__c = true;
        opp2.Is_Template__c=false;
        oppList.add(opp2);
        
        insert oppList;  
        Test.stopTest();
        
    }
    
    @isTest
    static void updateAccountWithEarliestDriveDate_Test(){
        Test.startTest();
        Date earliestDriveDate = date.newInstance(3000, 11, 31);
        opportunity opp = [select ID,name,StageName,Accept_56_Day_Rule_Violation__c from Opportunity where stageName = 'Draft'];
        opp.StageName = 'Discovery' ;
        opp.Accept_56_Day_Rule_Violation__c = true;
        update opp;
        account acc = [select id,earliest_drive_date__c from account where name = 'testAccount'];
        list<opportunity> oppList = [select id,accountId, name,stageName,Drive_Date__c,Is_Template__c from opportunity 
                                     where accountId =: acc.id];
        for(opportunity opp1: oppList){
            opp1.StageName = 'Closed';
        }
        OpportunityService.updateAccountWithEarliestDriveDate(oppList,null);  
        account acc1 = [select id,earliest_drive_date__c from account where id=:acc.id];
        system.assertEquals(acc1.earliest_drive_date__c, earliestDriveDate, 'Earliest drivedate is mismatched');
        Test.stopTest();
    }
    
}