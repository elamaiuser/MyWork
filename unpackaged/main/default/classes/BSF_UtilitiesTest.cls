/* The following test class covers the below mentioned apex class
 * BSF_Utilities
 * */

@isTest
private class BSF_UtilitiesTest {
    private static Id test_variable;
    @IsTest
    static  void getRecordTypeIdTest1(){
        Test.startTest();
        Id result = BSF_Utilities.getRecordTypeId('Account','Fixed Site Account');
        Test.stopTest();
        System.assertNotEquals(null, result,'Record Type Not Found');
        test_variable = result; 
    }
    @IsTest
    static  void getRecordTypeNameTest1(){
        Test.startTest();
        String result = BSF_Utilities.getRecordTypeName(test_variable);
        Test.stopTest();
        System.assertEquals(null, result,'Record Type Found');
        
    }
    @IsTest
    static  void getTaxonomyNodesTest1(){
        Test.startTest();
        Set<String> result = BSF_Utilities.getTaxonomyNodes(BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(0, result.size(),'Taxonomy Nodes Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest1(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest2(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest3(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.TAXO_FIXED_SITE_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest4(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.TAXO_SICKLE_CELL_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest5(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.TAXO_RELATIONSHIP_MGR_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest6(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest7(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest8(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType(BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE);
        Test.stopTest();
        System.assertNotEquals(null, result,'PortFolio Type Not Found');
    }
    @IsTest
    static  void getPortFolioTypeTest9(){
        Test.startTest();
        String result = BSF_Utilities.getPortFolioType('abcd');
        Test.stopTest();
        System.assertEquals(null, result,'PortFolio Type Found');
    }
    @IsTest
    static  void isTerritoryPortfolioTest1(){
        Test.startTest();
        Boolean result = BSF_Utilities.isTerritoryPortfolio(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
        Test.stopTest();
        System.assertEquals(true, result,'Not Territory Portfolio');
    }
    @IsTest
    static  void isTerritoryPortfolioTest2(){
        Test.startTest();
        Boolean result = BSF_Utilities.isTerritoryPortfolio(BSF_Constants.TAXO_BOOKING_SUPPORT_RECORD_TYPE);
        Test.stopTest();
        System.assertEquals(false, result,'Territory Portfolio');
    }
    @IsTest
    static  void getErrorLogsTest1(){
        List<String> errors = new List<String>{'err1','err2','err3','err4','err5','err6','err7','err8','err9'};
        Test.startTest();
        List<BSF_Error_Log__c> result = BSF_Utilities.getErrorLogs('Test Process','BSF_UtilitiesTest','getErrorLogsTest1','ERROR','Test Error Log',errors);
        Test.stopTest();
        System.assertNotEquals(0, result.size(),'Error Logs not found');
    }
    
    //===== Added By Priti=====
    
    @isTest
    static void getTaskDueDateTest()
    {
        date inputDate1 = Date.newInstance(2023, 07, 01);
        date inputdate2 = Date.newInstance(2023, 07, 02);
        date inputdate3 = Date.newInstance(2023, 06, 30);
		String desiredFormat = 'EEE';
	
		Test.startTest();
        
        Date dueDate1 = BSF_Utilities.getTaskDueDate(inputDate1 , desiredFormat);
        Date dueDate2 = BSF_Utilities.getTaskDueDate(inputDate2 , desiredFormat);
        date dueDate3 = BSF_Utilities.getTaskDueDate(inputDate3 , desiredFormat);
		Test.stopTest(); 
        system.assert(dueDate1 != inputDate1);
        system.assert(dueDate2 != inputDate2);
        system.assert(dueDate3 == inputDate3);
    }
    
    @isTest
    static void createErrorLogTestForInsertAndUpsert()
    {
        List<Contact> contactInsertList = new List<Contact>();
        
        for(Integer i=0; i<3; i++)
        {
            Contact conObj = new Contact();
            conObj.LastName = 'Test';
            conObj.Email = 'testcontact@gmail.com';
            conObj.MailingPostalCode = '45643';
            conObj.OtherPostalCode = '45324';
            contactInsertList.add(conObj);
        }
        
        Test.startTest();
        
        Database.SaveResult[] saveResults1 = Database.insert(contactInsertList, false);   
        Database.UpsertResult[] saveResults2 = Database.upsert(contactInsertList, false);
        List<BSF_Error_Log__c> result1 = BSF_Utilities.createErrorLog(saveResults1,'Duplicate Contact Creation','BSF_UtilitiesTest','createErrorLogTestForInsertAndUpsert','ERROR','Test Error Log');
        List<BSF_Error_Log__c> result2 = BSF_Utilities.createErrorLog(saveResults2,'Duplicate Contact Creation','BSF_UtilitiesTest','createErrorLogTestForInsertAndUpsert','ERROR','Test Error Log');
        Test.stopTest();
        
        system.assertNotEquals(0, result1.size());
        system.assertNotEquals(0, result2.size());          
    }
    
    @isTest
    static void platformSuccessLogTest()
    {
        Set<string> idSet = new Set<String>();
        idSet.add('err1');
        idSet.add('err2');
        
        Test.startTest();
        
        List<BSF_Error_Log__c> result = BSF_Utilities.platformSuccessLog(idSet,'Test Process','BSF_UtilitiesTest','platformSuccessLogTest','Error','Test Error Log');
        Test.stopTest();
        
        system.assertNotEquals(0, result.size());
    }
    
    @isTest
    static void createErrorLogTest2ForDeletion()
    {
        
         User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        String rolename = 'West_BDM';
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = urole.Id
        );
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        List<Account> accInsertList = new List<Account>();
        for(Integer i=0;i<2;i++)
        {
            Account acc = new Account(name = 'Test Account '+i);
            accInsertList.add(acc);
        }
                
        system.runAs(DRDAMUser)
        {
            Test.startTest();
            
            insert accInsertList;
            DataBase.DeleteResult[] deleteResults = Database.delete(accInsertList,false);                    
        	List<BSF_Error_Log__c> result = BSF_Utilities.createErrorLog(deleteResults,'Account Deletion','BSF_UtilitiesTest','createErrorLogTest2ForDeletion','ERROR','Account Deletion by non admins');
        	Test.stopTest();
            
        	system.assertNotEquals(0, result.size());
        }
    }
}