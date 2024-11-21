/**
* ***************************************************************************************************************************************************************************
* @Description: This class is the Test class for DriveAffiliationHandler apex class.
* ***************************************************************************************************************************************************************************
* @developer         Barnojit Sharma
* @version           1.0
* @created           06/19/2023
* ***************************************************************************************************************************************************************************
**/
@isTest
public class DriveAffiliationHandlerTest {
    @TestSetup
    static void makeData(){
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        insert testMobileAccount;
        System.assertNotEquals(null, testMobileAccount.Id,'Account Not Inserted');
        
        // insert mobile site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        testMobileSite.sked_Active__c = true;
        testMobileSite.sked_Start_Date__c = system.today().addDays(-30);
        testMobileSite.sked_End_Date__c = system.today().addDays(30);
        testMobileSite.National_Name_Status__c = 'Second Review Pending';
        insert testMobileSite;
        System.assertNotEquals(null, testMobileSite.Id,'Site Not Inserted');
        
        // insert Mobile Opportunity Template
        Opportunity optyObj = new Opportunity();
        optyObj.accountId = testMobileAccount.Id;
        optyObj.Drive_Site__c = testMobileSite.Id;
        optyObj.Drive_Date__c = system.today().addDays(-1);
        optyObj.CloseDate = system.today().addDays(-20);
        optyObj.Is_Template__c = true;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery'; 
        optyObj.Drive_Status__c = 'Draft';
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert optyObj;
        System.assertNotEquals(null, optyObj.Id,'Template Not Inserted');

        // insert Mobile Opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Drive_Date__c = system.today().addDays(-1);
        testMobileOpp.CloseDate = system.today().addDays(-20);
        testMobileOpp.Parent_Template_Id__c = optyObj.id;
        insert testMobileOpp;
        System.assertNotEquals(null, testMobileOpp.Id,'Opportunity Not Inserted');
            
        //create affiliations
        List<Marketing_Program__c> affList = new List<Marketing_Program__c>();
        Marketing_Program__c aff = new Marketing_Program__c();
        aff.Name = 'Pint Sized Hero';
        aff.External_Name__c = 'Pint Sized Hero';
        aff.Scope__c = 'Drive';
        affList.add(aff);
        insert affList;
        System.assertNotEquals(null, affList[0].Id,'Marketing Program Not Inserted');
        
        //create drive affiliations
        List<Drive_Marketing_Programs__c> dmList = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c dm = new Drive_Marketing_Programs__c();
        dm.Marketing_Program__c = affList[0].id;
        dm.Blood_Drive_Opportunity__c = optyObj.id;
        dmList.add(dm);
        insert dmList;
        System.assertNotEquals(null, dmList[0].Id,'Drive Affiliation Not Inserted');
    }
    @isTest 
    static void testDriveAffiliationHandler1() {
        
        List<Opportunity> oppList = [SELECT Id, Parent_Template_Id__c, Is_Template__c FROM Opportunity WHERE Is_Template__c = false AND Parent_Template_Id__c != null];

        test.startTest();
            DriveAffiliationHandler.getInstance(oppList,true).run();

            List<Drive_Marketing_Programs__c> drvAffList = [SELECT Id FROM Drive_Marketing_Programs__c];
            System.Assert(drvAffList.size() > 0,'Drive Affiliation Not Inserted');
        test.stopTest();
            
    } 
    @isTest 
    static void testDriveAffiliationHandler2() {
        
        List<Opportunity> oppList = [SELECT Id, Parent_Template_Id__c, Is_Template__c FROM Opportunity WHERE Is_Template__c = false AND Parent_Template_Id__c != null];

        test.startTest();
            DriveAffiliationHandler.getInstance(oppList,false).run();

            List<Drive_Marketing_Programs__c> drvAffList = [SELECT Id FROM Drive_Marketing_Programs__c];
            System.Assert(drvAffList.size() > 0,'Drive Affiliation Not Inserted');
        test.stopTest();
            
    } 
}