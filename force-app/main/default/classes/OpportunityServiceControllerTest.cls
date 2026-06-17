@istest
private class OpportunityServiceControllerTest {
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('DriveTriggerHandler');
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
    }
    
    @istest
    static void OpportunityServiceControllerTest() { 
        Test.startTest();
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
          TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        skedHubBase.BypassUpdateTriggers = true;
          Opportunity testOpp = [SELECT Id, WholeBloodProceduresProjectedTemplate__c, Anticipated_Registered_Donors_Template__c, 
                               Double_Red_Procedures_Projected_Template__c, Drive_Site__c, Direct_Donors_To__c,
                               Anticipated_Registered_Donors__c, WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c,
                               WholeBloodProcedureProjectedChangeReason__c, DoubleRedProceduresProjectedChangeReason__c,
                               AnticipatedRegisterDonorChangeReason__c, AccountId
                               FROM Opportunity
                               LIMIT 1];
        
     BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testOpp.AccountId;
        testTemplate.Drive_Site__c = testOpp.Drive_Site__c;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert testTemplate;

        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c, sked_Status__c, sked_Opportunity__c FROM sked_Drive__c limit 1];
        System.debug('drive'+drive);
        List<Opportunity> lstOpps = [SELECT Id, Is_Recursion_On__c,Related_Scheduled_Drive__c, Drive_Date__c, Number_of_Platelet_Assets__c, Anticipated_Registered_Donors_Template__c, Number_of_Plasma_Assets__c, Start_Time__c, Drive_Site__c, Other_Projected_Units__c, Number_of_2RBC_Assets__c, End_Time__c, Drive_Status__c,Drive_Date_Change_Reason__c, Initiated_By__c, StageName,Platelet_Projected_Procedures__c,Plasma_Pheresis_Projected_Procedures__c, Anticipated_Registered_Donors__c, 
        WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Accepts_Automation__c, Automation_Suitability__c, Apheresis_Projected_Units__c, AnticipatedRegisterDonorChangeReason__c, WholeBloodProcedureProjectedChangeReason__c, DoubleRedProceduresProjectedChangeReason__c, Account_Manager__c, Parent_Template_Id__c, sked_Cancellation_Reason__c FROM Opportunity WHERE Id =: drive[0].sked_Opportunity__c];
       System.debug('lstOpps.Related_Scheduled_Drive__c'+lstOpps[0].Related_Scheduled_Drive__c);
        lstOpps[0].Number_of_Platelet_Assets__c = 2;
        lstOpps[0].Number_of_2RBC_Assets__c = 2;
        lstOpps[0].Number_of_Plasma_Assets__c = 2;
        lstOpps[0].Anticipated_Registered_Donors_Template__c = 50;
        lstOpps[0].AnticipatedRegisterDonorChangeReason__c = 'test';
        lstOpps[0].WholeBloodProcedureProjectedChangeReason__c = 'test';
        lstOpps[0].Related_Scheduled_Drive__c = drive[0].Id;
        lstOpps[0].StageName = 'Discovery';
        lstOpps[0].DoubleRedProceduresProjectedChangeReason__c = 'test';
        lstOpps[0].Drive_Status__c = 'Tentative';
        lstOpps[0].Start_Time__c =  Time.newInstance(10, 0, 0, 0);
            lstOpps[0].End_Time__c = Time.newInstance(15, 30, 0, 0);
            lstOpps[0].Anticipated_Registered_Donors__c = 10;
        lstOpps[0].Account_Manager__c = userInfo.getUserId();
         lstOpps[0].Parent_Template_Id__c = testTemplate.Id;
            
            lstOpps[0].sked_Cancellation_Reason__c = 'Testing';
        lstOpps[0].Initiated_By__c = 'ARC_Initiated_Mobile';
        update lstOpps;
        System.debug('lstOpps2'+lstOpps[0].Related_Scheduled_Drive__c);
        drive[0].sked_Status__c = 'Tentative';
      
        update drive;
        
        
    OpportunityServiceController.syncOppsWithDrives(lstOpps);


       // OpportunityServiceController.syncOppsWithDrives(lstOpps);
        System.debug('lstOpps3'+lstOpps);
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
    }
    
    @istest
    static void StatusChangeCoverageTest() { 
        Test.startTest();
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;
        
        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c, sked_Status__c, sked_Opportunity__c FROM sked_Drive__c limit 1];
        List<Opportunity> lstOpps = [SELECT Id, Is_Recursion_On__c, Drive_Date__c, Number_of_Platelet_Assets__c, Anticipated_Registered_Donors_Template__c, Number_of_Plasma_Assets__c, Start_Time__c, Drive_Site__c, Other_Projected_Units__c, Number_of_2RBC_Assets__c, End_Time__c, Drive_Status__c,Drive_Date_Change_Reason__c, Initiated_By__c, StageName,Platelet_Projected_Procedures__c,Plasma_Pheresis_Projected_Procedures__c, Anticipated_Registered_Donors__c, 
        WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Accepts_Automation__c, Automation_Suitability__c, Apheresis_Projected_Units__c, AnticipatedRegisterDonorChangeReason__c, WholeBloodProcedureProjectedChangeReason__c, DoubleRedProceduresProjectedChangeReason__c, Account_Manager__c, Parent_Template_Id__c, sked_Cancellation_Reason__c FROM Opportunity WHERE Id =: drive[0].sked_Opportunity__c];
        List<Contact> conlist = new List<Contact>();
        Contact conObj = new Contact();
        conObj.AccountId = drive[0].sked_Account__c ;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
		conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'testContact@gmail.com';
		conObj.Original_Service_Date__c = system.today().addDays(3);
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        insert conObj;
        //
        List<Account> accList = [SELECT Id, Contact_BPL__c FROM Account where id =: drive[0].sked_Account__c];
        accList[0].Contact_BPL__c = conObj.Id;
        update accList;
        List<sked__Location__c> site = [SELECT Id, sked_Site_Contact__c FROM sked__Location__c where id =: drive[0].sked_Drive_Site__c];
        site[0].sked_Site_Contact__c = conObj.Id;
        update site;
        drive[0].sked_Status__c = 'Confirmed';
        update drive;
        lstOpps[0].Initiated_By__c = 'ARC_Initiated_Mobile';
        lstOpps[0].Drive_Status__c = 'Confirmed';
        update lstOpps;
        OpportunityServiceController.syncOppsWithDrives(lstOpps);
        Test.stopTest();
    }
    
    @isTest
    static void populateLatestValuesUponTemplateChangeTest() {
        Test.startTest();
        Opportunity testOpp = [SELECT Id, WholeBloodProceduresProjectedTemplate__c, Anticipated_Registered_Donors_Template__c, 
                               Double_Red_Procedures_Projected_Template__c, Drive_Site__c, Direct_Donors_To__c,
                               Anticipated_Registered_Donors__c, WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c,
                               WholeBloodProcedureProjectedChangeReason__c, DoubleRedProceduresProjectedChangeReason__c,
                               AnticipatedRegisterDonorChangeReason__c, AccountId
                               FROM Opportunity
                               LIMIT 1];
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testOpp.AccountId;
        testTemplate.Drive_Site__c = testOpp.Drive_Site__c;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert testTemplate;
        
        OpportunityServiceController.populateLatestValuesUponTemplateChange(testOpp, testTemplate, 'Test Template Change');
        
        TriggerHandler.clearAllBypasses();
        Test.stopTest();
        
        Assert.isTrue(testOpp.Anticipated_Registered_Donors__c == testTemplate.Anticipated_Registered_Donors__c);
        Assert.isTrue(testOpp.AnticipatedRegisterDonorChangeReason__c.equalsIgnoreCase('Test Template Change')); 
    }
    
    

    
    
}