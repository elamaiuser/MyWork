@isTest
public class BSF_Batch_AccountServiceRoleDeleteTest {
    
    
    @isTest
    public static void TestMethod1(){ 
        
        Account acc1=new Account();
        acc1.name='ShubhamTest';
        acc1.Internal_Name__c='Test';    
        
        insert acc1;
        
        Contact conObj = new Contact();
        conObj.AccountId = acc1.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.OtherCity = 'Ashburn';
        conObj.OtherCountryCode ='US';
        conObj.OtherPostalCode = '20148';
        conObj.OtherStateCode = 'VA';
        conObj.OtherStreet = '23070 Learning Cir';
        conObj.Primary_Phone__c='Work Phone';
        conObj.OtherPhone='13231314';
        insert conObj;
        
        
        Account_Service_Role__c accountServiceroleTest= new Account_Service_Role__c();
        accountServiceroleTest.Account__c=acc1.Id;
        accountServiceroleTest.Contact__c= conObj.Id;
        accountServiceroleTest.Start_Date__c=System.today()-2;
        accountServiceroleTest.End_Date__c=System.today()-1;
        accountServiceroleTest.Account_Service_Role__c='Executive Account Leader';
        accountServiceroleTest.Account_Service_End_Reason__c='Deceased';
        
        insert accountServiceroleTest;
        System.debug('Testing40'+accountServiceroleTest);
        Test.startTest();
        
        BSF_Batch_AccountServiceRoleDelete accservicerolebatch = new BSF_Batch_AccountServiceRoleDelete();
        DataBase.executeBatch(accservicerolebatch); 
        
        Test.stopTest();
        
    }
     @isTest static void executeTest(){
        
        SchedulableContext sc = null;
        BSF_Batch_AccountServiceRoleDelete accservicerolebatch = new BSF_Batch_AccountServiceRoleDelete();
        accservicerolebatch.execute(sc);
         
    }  
 
    
}