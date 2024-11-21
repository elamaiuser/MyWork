@istest
public class OpportunityServiceControllerTest {
    @istest
    public static void OpportunityServiceControllerTest(){ 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData1 =  testDataSetup.createAndInsertCommonObjects(); 
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData1.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');

        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        try{
            GenerateMobileDrive.generateDrives(config);
        }catch(Exception ex){}
        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c, sked_Status__c FROM sked_Drive__c where sked_Opportunity__c =: mobileOpportunity.Id limit 1];
        List<Opportunity> lstOpps = [SELECT Id, Is_Recursion_On__c, Drive_Date__c, Number_of_Platelet_Assets__c, Anticipated_Registered_Donors_Template__c, Number_of_Plasma_Assets__c, Start_Time__c, Drive_Site__c, Other_Projected_Units__c, Number_of_2RBC_Assets__c, End_Time__c, Drive_Status__c,Drive_Date_Change_Reason__c, Initiated_By__c, StageName,Platelet_Projected_Procedures__c,Plasma_Pheresis_Projected_Procedures__c, Anticipated_Registered_Donors__c, 
        WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Accepts_Automation__c, Automation_Suitability__c, Apheresis_Projected_Units__c, AnticipatedRegisterDonorChangeReason__c, WholeBloodProcedureProjectedChangeReason__c, DoubleRedProceduresProjectedChangeReason__c, Account_Manager__c, Parent_Template_Id__c, sked_Cancellation_Reason__c FROM Opportunity WHERE Id =: mobileOpportunity.Id];
        lstOpps[0].Number_of_Platelet_Assets__c = 2;
        lstOpps[0].Number_of_2RBC_Assets__c = 2;
        lstOpps[0].Number_of_Plasma_Assets__c = 2;
        lstOpps[0].Anticipated_Registered_Donors_Template__c = 50;
        lstOpps[0].AnticipatedRegisterDonorChangeReason__c = 'test';
        lstOpps[0].WholeBloodProcedureProjectedChangeReason__c = 'test';
        lstOpps[0].StageName = 'Discovery';
        lstOpps[0].DoubleRedProceduresProjectedChangeReason__c = 'test';
        lstOpps[0].Initiated_By__c = 'ARC_Initiated_Mobile';
        update lstOpps;
        drive[0].sked_Status__c = 'Tentative';
        update drive;
        OpportunityServiceController.syncOppsWithDrives(lstOpps);
        Test.stopTest();
    }
    @istest
    public static void StatusChangeCoverageTest(){ 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData1 =  testDataSetup.createAndInsertCommonObjects(); 
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData1.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');

        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        try{
            GenerateMobileDrive.generateDrives(config);
        }catch(Exception ex){}
        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c, sked_Status__c FROM sked_Drive__c where sked_Opportunity__c =: mobileOpportunity.Id limit 1];
        List<Opportunity> lstOpps = [SELECT Id, Is_Recursion_On__c, Drive_Date__c, Number_of_Platelet_Assets__c, Anticipated_Registered_Donors_Template__c, Number_of_Plasma_Assets__c, Start_Time__c, Drive_Site__c, Other_Projected_Units__c, Number_of_2RBC_Assets__c, End_Time__c, Drive_Status__c,Drive_Date_Change_Reason__c, Initiated_By__c, StageName,Platelet_Projected_Procedures__c,Plasma_Pheresis_Projected_Procedures__c, Anticipated_Registered_Donors__c, 
        WB_Projected_Procedures__c, X2RBC_Projected_Procedures__c, Accepts_Automation__c, Automation_Suitability__c, Apheresis_Projected_Units__c, AnticipatedRegisterDonorChangeReason__c, WholeBloodProcedureProjectedChangeReason__c, DoubleRedProceduresProjectedChangeReason__c, Account_Manager__c, Parent_Template_Id__c, sked_Cancellation_Reason__c FROM Opportunity WHERE Id =: mobileOpportunity.Id];
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
        update lstOpps;
        OpportunityServiceController.syncOppsWithDrives(lstOpps);
        Test.stopTest();
    }
}