@isTest
public class DeleteDuplicateAccountServiceTest {
    
    @isTest static void method1()
    {
       // Dataset for Account Object
       
       List<Account> acctest = new List<Account>(); 
        Account ac = new Account();
        ac.Name='170820211711Test';
        ac.Type='Business';
        ac.Internal_Name__c='170820211711Test';
        ac.Industry_Code__c = 'Agriculture';
        insert ac;
        
       // Dataset for Contact Object
      
      List<Contact> conntest = new List<Contact>();
        Contact con = new Contact();
        con.FirstName='abc';
        con.LastName='abc1';
        con.AccountId=ac.Id;
        con.Primary_Phone_Number__c ='7885465874';
        con.Email='test@test.com';
        con.Email = 'testContact@gmail.com';
        con.Original_Service_Date__c = system.today().addDays(3);
        con.Primary_Phone__c = 'Mobile Phone';
        con.MobilePhone = '752-781-0090';
        insert con;
        
      //Inserting Account_Service_Role__c values 2times for Duplicate entry.
    
        List<Account_Service_Role__c> accountServRoles = new List<Account_Service_Role__c>();
        Account_Service_Role__c accs = new Account_Service_Role__c();     
        accs.Account__c = ac.Id;
        accs.Contact__c = con.Id;
        accs.Start_Date__c = System.today();
        accs.End_Date__c = System.today() + 10;
        accs.Account_Service_End_Reason__c='Other';
        accs.Account_Service_Role__c = 'Blood Program Leader';
        accountServRoles.add(accs);
        
        Account_Service_Role__c acc = new Account_Service_Role__c();     
        acc.Account__c = ac.Id;
        acc.Contact__c = con.Id;
        acc.Start_Date__c = System.today();
        acc.End_Date__c = System.today() + 10;
        acc.Account_Service_End_Reason__c='Other';
        acc.Account_Service_Role__c = 'Blood Program Leader';
        accountServRoles.add(acc);
        insert accountServRoles; 
        
        system.debug('totalacc'+acc);
        
        Test.startTest();
        DeleteDuplicateAccountServiceRolesBatch ba= new DeleteDuplicateAccountServiceRolesBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
       
    } 
}