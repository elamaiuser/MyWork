@isTest
public class BSF_Batch_TemplateOrderExpiration_Test {
        
    @testSetup
    static void setup() {
        // Create a test user
        User drdUser = new User(
            FirstName = 'DRD',
            LastName = 'System',
            Username = 'drdsystem@test.com',
            Email = 'drdsystem@test.com',
            Alias = 'drdsys',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert drdUser;
        

        
        // Create an Account
        Account accObj;
        accObj = new Account();
        accObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Mobile_Account').getRecordTypeId();
        accObj.Name = 'Exavalu';
        accObj.BillingPostalCode = '30622';
        accObj.Internal_Name__c ='Exavalu'; 

        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
        insert accObj;
        Assert.isNotNull(accObj.Id);
        
        List<Contact> conlist = new List<Contact>();
         Contact conObj = new Contact();
        conObj.AccountId = accObj.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'test.barno@mailinator.com';
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.Original_Service_Date__c = Date.Today().addDays(-1000);
        conObj.HomePhone = '222-222-3333';
        conObj.MobilePhone = '222-222-3333';
        conObj.OtherPhone = '222-222-3333';
        conlist.add(conObj);
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('ContactTriggerHandler');
        insert conlist;
        
        
        
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
        sked__Location__c siteObj = new sked__Location__c();
        siteObj.Name = 'Test Site';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        siteObj.sked_Site_Inspection_Completed_By__c = drdUser.Id;
        siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
        siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Site_Contact__c = conlist[0].Id;
        siteObj.sked_Site_Main_Phone__c = '758-771-0091';
        siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.source__c='Custom New Form';
        siteObj.sked_Address_1__c='Test Site Address';
        siteObj.sked_City__c='Test site city';
        siteObj.sked_County__c='AMERICA';
        siteObj.sked_State__c='test state';
        siteObj.sked_Wireless_Policy__c='Accepted';
        siteObj.sked_Zip_Code__c='94608';
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;

        // Create an Opportunity with Is_Template__c = TRUE
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Draft',
            Drive_Name__c = 'Test Drive',
        	Drive_Date__c = Date.newinstance(2023,10,11),
            Drive_Site__c = siteObj.Id,
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
            Plasma_Pheresis_Projected_Procedures__c = 0,
            Platelet_Projected_Procedures__c = 0,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Slot_Generator__c = 130,
            Source__c = 'Adhoc',
            CloseDate = Date.today().addDays(30),
            Is_Template__c = TRUE,
            AccountId = accObj.Id
        );
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        insert testOpportunity;
        
        
        
        // Create an Order related to the Opportunity
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = accObj.Id,
            OpportunityId = testOpportunity.Id,
            EffectiveDate = system.today(),
            status = 'draft',
            EndDate = Date.today().addDays(2)
           // Order_Due_Date__c = Date.today().addDays(20)
        );
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('OrderTriggerHandler');
        insert testOrder;
        
        // Create Account Team Member
        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = accObj.Id,
            UserId = drdUser.Id,
            TeamMemberRole = 'Account Manager',
            is_covering_recruiter__c = false,
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(20)
        );
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert teamMember;
    }

    @isTest
    static void testBatchExecution() {
        
        // Start the test, this will run the batch
        Test.startTest();
        
        // Instantiate the batch class
        BSF_Batch_TemplateOrderExpiration batch = new BSF_Batch_TemplateOrderExpiration();
        
        // Execute the batch
        Database.executeBatch(batch);

        Test.stopTest();

        
    }
    
}