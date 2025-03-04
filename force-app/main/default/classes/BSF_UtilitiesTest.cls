/* The following test class covers the below mentioned apex class
 * BSF_Utilities (81%)
 
 /* Modification Log 
 * Date					     Developer Name			             Comments
  ******************************************************************************************************************
 * 11/11/2024				   Priti Jana			 Added new testmethods, increased code coverage
 * *****************************************************************************************************************/

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
             LocaleSidKey = 'en_US'
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
     
     @isTest
     static void createErrorLogWithObjectIdTest() {
         List<Contact> contactListList = new List<Contact>();
         
         for(Integer i = 0; i < 2; i++) {
             Contact contactTest = new Contact(FirstName = 'Test', LastName = 'Contact '+i);
             contactListList.add(contactTest);
         }
         
         Test.startTest();
         Database.SaveResult[] saveResults1 = Database.insert(contactListList, false);
         List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLogWithObjectId(
             saveResults1, 
             'Error in inserting contact records', 
             'BSF_Utilities', 
             'createErrorLogWithObjectId', 
             'Error', 
             'Error in update'
         );
         
         Set<Id> successfullySavedRecords = BSF_Utilities.getSuccessfullySavedRecordIds(saveResults1);
         Exception ex = new System.MathException();
         ex.setMessage('Test message');
         insert BSF_Utilities.createBsfErrorLogForExceptions(
             ex,
             'CreateSkedDrivesBatch',
             'Constructor Call',
             BSF_Constants.BATCH_DRIVE_GENERATION,
             BSF_Constants.BATCH_DRIVE_GENERATION + ' from Plan a Drive Flow',
             'sked_Drive__c',
             ''
         );
         Test.stopTest();
     }
     
     @isTest
     static void capitalizeNameTest(){
        Test.startTest();
        String result = BSF_Utilities.capitalizeName('Aminata Labor-koroma 526350', true);
        String result1 = BSF_Utilities.capitalizeName('Aminata Labor-koroma 526350', false);
        Test.stopTest();
        System.assertEquals('Aminata Labor-kor oma 526350', result);
        System.assertEquals('Aminata Labor-koroma 526350', result1);
     }
     
     @isTest
     static void runtest() {
         Test.startTest();
         List<String> activeFccCodesList = BSF_Utilities.getActivePicklistValues('sked__Resource__c', 'sked_FCC_Code__c');
         Test.stopTest();
     }
     
     static testMethod void createDriveQueryForCalendarBuildTest() {
         Test.startTest();
         String query = BSF_Utilities.createDriveQueryForCalendarBuild();
         Test.stopTest();
         Assert.isTrue(query != NULL);
     }
     
     static testMethod void isWbFixedSiteOpportunityTest() {
         
         BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
         Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
         
         Test.startTest();
         
         // insert Mobile Account
         Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
         testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
         insert testMobileAccount;
         
         // insert contact
         Contact testContact = (Contact)mapTestData.get('CONTACT');
         testContact.AccountId =  testMobileAccount.Id;
         insert testContact;
         
         // insert Mobile Site
         sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
         //testMobileSite.sked_Site_Contact__c = testContact.Id;
         insert testMobileSite;
         
         // insert templates
         Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
         testTemplate.AccountId = testMobileAccount.Id;
         testTemplate.Drive_Site__c = testMobileSite.Id;
         insert testTemplate;
         
         // insert Mobile Opp
         Opportunity testMobileOpp2 = (Opportunity)mapTestData.get('MOBILE_OPP');
         testMobileOpp2.AccountId = testMobileAccount.Id;
         testMobileOpp2.Drive_Site__c = testMobileSite.Id;
         testMobileOpp2.Parent_Template_Id__c = testTemplate.Id;
         insert testMobileOpp2;
         
         Boolean isWbFsDrive = BSF_Utilities.isWbFixedSiteOpportunity(testMobileOpp2, testMobileSite);
         Boolean isMobileFsDrive = BSF_Utilities.isMobileOpportunity(testMobileOpp2);
         Test.stopTest();
         Assert.isTrue(isWbFsDrive == FALSE);
         Assert.isTrue(isMobileFsDrive == TRUE);
     }
     
     static testMethod void findSkedRegion_Test() {
         Date today = system.Today();
         Id recordTypeId = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get('Bio Collection BSF').getRecordTypeId();
         Taxonomy__c testTaxonomy = new Taxonomy__c(Division_Code__c='Div1', Division_Key__c=42068, Division_Name__c='Div_1', 
                                              DS_Region_Code__c='DSR1', DS_Region_Key__c=42069, DS_Region_Name__c='Reg_1', 
                                              District_Code__c='Dist1', District_Key__c=42070, District_Name__c='District_1',
                                              Collection_Operation_Name__c = 'Collection_Operation_Name__c', Collection_Operation_Code__c = 'C-OP3',
                                              Collection_Operation_Key__c = 1111,
                                              skedulo_region_cd__c = 'SkReg1', skedulo_region_name__c = 'SkReg_1',Time_Zone__c = 'GMT',
                                              RecordTypeId = recordTypeId,
                                              Version_Key__c = 0, Zip_Code__c = '85671',
                                              Start_Date__c = today-100, End_Date__c = today + 9);
         insert testTaxonomy;
         
         Biomed_Collection_Op_Center__c testCo = new Biomed_Collection_Op_Center__c();
         testCo.Biomed_Collection_Op_Code_Center_ID__c ='C-OP3';
         testCo.Name='Collection_Operation_Name__c';
         testCo.External_Id__c = 'Bio_Collection_BSF_' + 'Collection_Operation_Code__c';
        // testCo.sked_Territory__c = territory.id;
         testCo.sked_Lunch_Break_Duration_Fixed_Site__c='30';
         testCo.sked_Lunch_Break_Duration_Mobile__c='30';
         insert testCo;
         
         system.debug('testCo '+testCo.Biomed_Collection_Op_Code_Center_ID__c);
         
         BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
         Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
         
         // insert Mobile Site
         sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
         testMobileSite.sked_Zip_Code__c = testTaxonomy.Zip_Code__c;
         insert testMobileSite;
         
         // insert Collections Zip
         Collections_Territory__c testCollTerr = new Collections_Territory__c();
         testCollTerr.Collection_Operation__c = testCo.Id;
         testCollTerr.Zip__c = '85671';
         testCollTerr.sked_Start_Date__c = testTaxonomy.Start_Date__c;
         testCollTerr.sked_End_Date__c = testTaxonomy.End_Date__c;
         testCollTerr.External_Id_BackEnd__c='Bio_Collection_BSF_CollZip_'+testTaxonomy.Zip_Code__c+'_'+testTaxonomy.Collection_Operation_Code__c;
         testCollTerr.External_Id__c='Bio_Collection_BSF_CollZip_'+testTaxonomy.Zip_Code__c+'_'+testTaxonomy.Collection_Operation_Code__c+'_'+testTaxonomy.Start_Date__c;            
         insert testCollTerr;
         
         // insert Site CO
         sked_Site_Collection_Operation__c testSiteCO = new sked_Site_Collection_Operation__c(
             sked_Site__c = testMobileSite.Id,
             sked_Collection_operation__c = testCo.Id,
             sked_Start_Date__c = testTaxonomy.Start_Date__c,
             sked_End_Date__c = testTaxonomy.End_Date__c,
             sked_Collections_Zip_Code__c = testCollTerr.id
         );
         insert testSiteCO;
  
         Test.startTest();
         Map<String,Id> mapSkedRegion = BSF_Utilities.findSkedRegion(
            new Set<String>{'C-OP3'}, 
            new Set<String>{'85671'}, 
            NULL, 
            new List<sked_Site_Collection_Operation__c>{testSiteCO}, 
            new Map<Id, Collections_Territory__c>{testCollTerr.Id => testCollTerr}, 
            new Map<Id, sked__Location__c>{testMobileSite.Id => testMobileSite}
         );
         Test.stopTest();
         Assert.isTrue(mapSkedRegion != NULL);
    }

    static testMethod void getStringWithinLimit_Test() {
        Test.startTest();
        // A random text with 260 characters
        String randomText = 'The golden sun dipped below the horizon, casting a warm glow across the tranquil sea. Waves gently lapped at the shore, while seagulls soared above, their calls echoing in the crisp evening air, a perfect end to another peaceful day by the ocean.';
        String result = BSF_Utilities.getStringWithinLimit(randomText, 255);
        Assert.isTrue(result.length() == 255);
        Test.stopTest();
    }
}