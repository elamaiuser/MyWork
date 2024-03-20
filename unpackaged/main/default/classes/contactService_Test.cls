@isTest(SeeAllData = False)
public class contactService_Test 
{
 @testSetup
    public static void testDataSetup()
    {
        
        Account acc1 = new Account(name='Test Account 2');
        acc1.BillingStreet = '2205 Westcrt ln, Apt 215'; 
        acc1.BillingCity = 'Herndon';
        acc1.BillingStateCode = 'MI';
        acc1.BillingPostalCode = '48093';
        insert acc1;
        
        list<contact> cList = new list<Contact>();
        Contact contact1 = new Contact (firstname='Test Contact First 1',lastname='Test Contact Last 1');
        contact1.Active__c = TRUE;
        contact1.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact1.MailingCity = 'Herndon';
        contact1.MailingStateCode = 'MI';
        contact1.MailingPostalCode = '48093';
        contact1.AccountId = acc1.id;
        contact1.Primary_Phone__c='Mobile Phone';
        contact1.Email='avs1@dfh.com';
        contact1.Original_Service_Date__c=Date.newInstance(2022, 09, 01);
        cList.add( contact1);
        
        Contact contact2 = new Contact (firstname='Test Contact First 2',lastname='Test Contact Last 2');
        contact2.Active__c = TRUE;
        contact2.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact2.MailingCity = 'Herndon';
        contact2.MailingStateCode = 'MI';
        contact2.MailingPostalCode = '48093';
        contact2.AccountId = acc1.id;
        contact2.Primary_Phone__c='Mobile Phone';
        contact2.Email='avs1@dfh.com';
        contact2.Original_Service_Date__c=Date.newInstance(2022, 09, 01);
        cList.add( contact2);
		insert cList;
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert mobile site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Active__c = true;
        testMobileSite.sked_Start_Date__c = system.today().addDays(-30);
        testMobileSite.sked_End_Date__c = system.today().addDays(30);
        insert testMobileSite;
        
        // insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = acc1.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Drive_Date__c = system.today().addDays(-1);
        testMobileOpp.CloseDate = system.today().addDays(-20);
        insert testMobileOpp;
    }
    public static void testContactService()
    {
        Contact contact1 = new Contact (firstname='Test Contact First 3',lastname='Test Contact Last 3');
        contact1.Active__c = TRUE;
        contact1.MailingStreet = '2204 Westcrt ln, Apt 213'; 
        contact1.MailingCity = 'Herndon';
        contact1.MailingStateCode = 'MI';
        contact1.MailingPostalCode = '48093';
        contact1.AccountId = [select id from Account where Name ='Test Account 2'].id;
        contact1.Primary_Phone__c='Mobile Phone';
        contact1.Email='avs2@dfh.com';
        contact1.Original_Service_Date__c=Date.newInstance(2022, 09, 01);
        
        insert contact1;
        
        
        system.assertEquals(1, [select count() from contact where Email='avs2@dfh.com']);
        
       
    }
    
    @isTest
     public static void testContactServiceUpdate()
    {
        contact c = [select id,MailingPostalCode from contact limit 1];
        c.MailingPostalCode='48092';
            
            update c;
     }
    
    @isTest
     public static void testContactServiceUpdate2()
    {
        List<contact> cList = [select id,MailingPostalCode,Primary_Phone__c,Phone,OtherPhone,MobilePhone from contact];
        cList[0].MailingPostalCode='48092';
        cList[0].Primary_Phone__c='Work Phone';
        cList[0].Phone='242343242';
        cList[0].OtherPhone=null;
        
        
        //cList[0].MailingPostalCode='48092';
        cList[1].Primary_Phone__c='Mobile Phone';
        cList[1].Phone='242343242';
        
        try{
            update cList;
        }
        catch(exception e)
        {
            system.debug('exception'+e);
        }
        
        contact c =[select id,OtherPhone from contact where Primary_Phone__c='Work Phone'];
        system.assertequals('242343242',c.OtherPhone);
        
     }
    
    @isTest
    static void testUpdateNameChangeFlag()
    {
        List<contact> cList = [select id, firstname, lastname, Contact_Name_Change__c from Contact];
        
        cList[0].firstname = 'Test Contact Update 1';
        try
        {
            update cList[0];
        }catch(Exception ex)
        { }
        
        list<id> idList = new list<id>{cList[0].id,cList[1].id};
            
        test.startTest();
        ContactTriggerHandler.updateNameChangeFlag(idList);
        test.stopTest();
       
        system.assertEquals(cList[0].Contact_Name_Change__c, FALSE); 
        
    }
    
    @isTest
    static void testRestrictInactiveContact()
    {
        Account accObj = [Select Id from Account limit 1];
        Contact conObj = [select Id , Active__c from Contact limit 1];
        Opportunity oppObj = [Select Id, AccountId from Opportunity where AccountId =: accobj.Id];
        
        // insert Account Service Role
        Account_Service_Role__c accServiceRoleObj = new Account_Service_Role__c();
        accServiceRoleObj.Account__c = accObj.Id;
        accServiceRoleObj.Contact__c = conObj.Id;
        insert accServiceRoleObj;
        
        // insert Drive Service Role
        OpportunityContactRole driveServiceRoleObj = new OpportunityContactRole();
        driveServiceRoleObj.ContactId = conObj.Id;
        driveServiceRoleObj.OpportunityId = oppObj.Id;
        driveServiceRoleObj.Role = 'Primary Contact';
        insert driveServiceRoleObj;
        
        conObj.Active__c = false;
        
        try{
            update conObj;
        }Catch(Exception ex)
        {
            String errormsg = ex.getMessage();
            //system.debug('errormsg '+errormsg);
            System.assert(errormsg.contains('Contact is associated with Active Template, Future Opportunities or Account. Please remove the association before inactivating the contact'));
        }
        
    }
    
    @isTest
    public static void testOnlyAdminsCanDeleteContact()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert DRD User
         User testDRDUser = (User)mapTestData.get('DRD_USER');
         system.runAs(new User(Id = UserInfo.getUserId()))
         {
        	insert testDRDUser;
         }
        
         Contact conObj = [select Id , Active__c from Contact limit 1];
        
         system.runAs(testDRDUser)
         {
         	Test.startTest();
         	try
         	{
         		Delete conObj;        
         	}catch(Exception ex){
         		String errormsg = ex.getMessage();
         		System.assertEquals(0, conObj.getErrors().size());        
    		}
        	Test.stopTest();
        
    	}
    }
}