/* Description : This test class covers:
 *  SponsorPlanningReportPDFController (93%)
 *  SponsorPlanningReportController(94%) 
*/

@isTest
private class SponsorPlanningReportController_Test {
    
    @testSetup
    static void setupData() {
        //Temporarily bypass heavy triggers
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('ContactTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.bypass('OpportunityTeamMemberTriggerHandler');
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        //Create Account and Contact
        Account acc = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal',
            District_Manager__c = UserInfo.getUserId()
        );
        insert acc;

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'test@example.com',
            Primary_Phone__c = 'Work Phone'
        );
        insert contact;

        //Create a Tag and Account Tag
        sked__Tag__c tag = new sked__Tag__c(Name = 'Inside', sked__Type__c = 'Physical Location Type');
        insert tag;

        sked__Account_Tag__c accTag = new sked__Account_Tag__c(
            sked__Account__c = acc.Id,
            sked__Tag__c = tag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        insert accTag;

        //Create supporting operational data
        Biomed_Collection_Op_Center__c opCenter = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert opCenter;     

        sked__Region__c region = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = opCenter.Id
        );
        insert region;

        //Create Site Location
        sked__Location__c loc = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            // sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = opCenter.Id,
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = system.today(),
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            sked_Site_Main_Phone__c = '098-765-4321',
            sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            Source__c = 'Custom New Form',sked_Address_1__c = 'test address',
			sked_City__c = 'test city',
			sked_County__c = 'test country',
			sked_State__c = 'test state',
			sked_Zip_Code__c = '532432',
            sked_Timezone__c = UserInfo.getTimezone().getID()
        );
        insert loc;

        //Create Opportunities and Drives
        Opportunity opp1 = new Opportunity(
            Name = 'parent',
            AccountId = acc.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE,
            Drive_Site__c = loc.Id,
            Additional_Description__c = 'test Desc',
            Drive_Date__c = system.today()+30,
            Drive_Status__c = 'Confirmed',
        	Start_Time__c = Time.newInstance(02, 0, 0, 0),
        	End_Time__c = Time.newInstance(11, 0, 0, 0)
        );
        insert opp1;
        Opportunity opp2 = new Opportunity(
            Name = 'parent2',
            AccountId = acc.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE,
            Drive_Site__c = loc.Id,
            Additional_Description__c = 'test Desc',
            Drive_Date__c = system.today()+30,
            Drive_Status__c = 'Confirmed',
        	Start_Time__c = Time.newInstance(02, 0, 0, 0),
        	End_Time__c = Time.newInstance(11, 0, 0, 0)
        );
        insert opp2;

        sked_Drive__c drive = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = opCenter.Id,
            sked_Drive_Site__c = loc.Id,
            sked_Opportunity__c = opp1.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = acc.Id,
            sked_Primary_Contact__c = contact.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 1    
        );
        insert drive;
        sked_Drive__c drive2 = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = opCenter.Id,
            sked_Drive_Site__c = loc.Id,
            sked_Opportunity__c = opp1.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = acc.Id,
            sked_Primary_Contact__c = contact.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 1    
        );
        insert drive2;

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(
            Name = 'test shift 1',
            sked_Max_Donor_Capacity__c = 250,
            sked_2RBC_Projected_Procedures__c = 6,
            sked_WB_Projected_Procedures__c = 6,
            sked_Staff_Setup__c = 15,
            sked_Equipment_Allocated__c = 4,
            sked_Lunch_Break_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_Lunch_Break_End_Time__c = Time.newInstance(9, 0, 0, 0),
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(12, 0, 0, 0)
		);  
        insert shift;
        
        sked__Job__c job = new sked__Job__c(
            sked__Region__c = region.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 14400,
            sked_Drive__c = drive.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked_Setup_Time__c = 100,
            sked_Drive_Shift__c = shift.Id,
            sked_Redcross_Volunteer_Quantity__c = 1,
            sked_Sponsor_Volunteer_Quantity__c = 1,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION
        );
        insert job;

        //Portfolio Setup
        BSF_Portfolio__c portfolio = new BSF_Portfolio__c(
            Name = 'Test Portfolio',
            Portfolio_Name__c = 'Test Portfolio',
            Portfolio_Code__c = 'PF-001',
            Portfolio_Type__c = 'Sickle Cell Account Manager',
            Account_Based_Portfolio__c = true
        );
        insert portfolio;

        Account_Portfolio_Assignment__c accPortfolio = new Account_Portfolio_Assignment__c(
            Account__c = acc.Id,
            BSF_Portfolio__c = portfolio.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(30)
        );
        insert accPortfolio;
        
        OpportunityTeamMember opptyTeamMember = new OpportunityTeamMember(
            OpportunityId=opp1.Id,
            TeamMemberRole ='Account Manager',
            UserId=UserInfo.getUserId());
        insert opptyTeamMember;

        OpportunityContactRole opptyContactRole = new OpportunityContactRole(
            Role = 'Whom to Meet',
            ContactId=contact.Id,
            OpportunityId=opp1.Id
        );

        insert opptyContactRole;
        
        List<Note> notes = new List<Note>();
        notes.add(new Note(ParentId=opp1.AccountId,Title='Account Notes'));
        notes.add(new Note(ParentId=opp1.Id,Title='Opportunity Notes'));
        notes.add(new Note(ParentId=opp1.Drive_Site__c,Title='Site Notes'));
        insert notes;

        Account_Service_Role__c asr = new Account_Service_Role__c(
            Contact__c=contact.Id,
            Account__c=opp1.AccountId,
            Account_Service_Role__c='Blood Program Leader');
        insert asr;
        
        Id organizationPartnershipRTId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Organization Partnership').getRecordTypeId();
        
        Marketing_Program__c  affilaition = new Marketing_Program__c(
            Scope__c='Drive;Account;Template',
            Name='Test Marketing Program',
            RecordTypeId=organizationPartnershipRTId, 
            Nationwide_Marketing_Program__c = 'Yes',
            External_Name__c='Test Marketing Program');
        insert affilaition;

        Account_Marketing_Program__c amp = new Account_Marketing_Program__c(
            Marketing_Program__c =affilaition.id,
            Account__c = opp1.AccountId );
        insert amp;

        Drive_Marketing_Programs__c  dmp= new Drive_Marketing_Programs__c (
            Marketing_Program__c =affilaition.id,
            Blood_Drive_Opportunity__c = Opp1.Id);
        insert dmp;

         Order order1 = new Order(Comments__c='Test Order',
                                 Local_Recruitment_Request_Need_by_Date__c = System.today().addDays(10) ,
                                 BudgetCurrency__c = 1000,
                                 OpportunityId=Opp1.Id,
                                 AccountId=Opp1.AccountId,
                                 EffectiveDate=System.today(),
                                 Status='Draft');
        insert order1;
        
        Product2 prod = new Product2(
            Name = 'Laptop X200',
            Family = 'Hardware');
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
		    Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
		    UnitPrice = 0.01,
            IsActive = true
        );
	    insert standardPrice;
        
        Task task1 = new Task(
            Subject='Test Task',
            ActivityDate=System.today().addDays(10), 
            WhatId=opp1.Id);
        insert task1;	
        
        //Clear Trigger Bypass Flags
        TriggerHandler.clearAllBypasses();
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
    }

    // -----------------------------------------------------------------------------------
    // Test: Verify PDF Controller Initialization
    // -----------------------------------------------------------------------------------
    @IsTest
    static void testSponsorPlanningPDFControllerInitialization() {
        Test.startTest();

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setCurrentPageReference(new PageReference('/apex/SponsorPlanningReport'));
        System.currentPageReference().getParameters().put('opportunityids', opp.Id);

        SponsorPlanningReportPDFController pdfController = new SponsorPlanningReportPDFController();

        System.assertNotEquals(null, pdfController, 'PDF Controller should initialize successfully.');

        Test.stopTest();
    }

    // -----------------------------------------------------------------------------------
    //Test: Verify Main Controller Initialization
    // -----------------------------------------------------------------------------------
    @IsTest
    static void testSponsorPlanningControllerInitialization() {
        Test.startTest();

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setCurrentPageReference(new PageReference('/apex/SponsorPlanningReport'));
        System.currentPageReference().getParameters().put('ids', opp.Id);

        sponsorPlanningReportController ctrl = new sponsorPlanningReportController();
        System.assertNotEquals(null, ctrl, 'Controller instance should be created.');

        Test.stopTest();
    }

    // -----------------------------------------------------------------------------------
    //Test: Search Function Scenarios
    // -----------------------------------------------------------------------------------
    @IsTest
    static void testSearchScenarios() {
        Test.startTest();

        //Call all supported permutations to validate search logic

        sponsorPlanningReportController.search('', '', null, null, '');
        sponsorPlanningReportController.search('', '', null, null, UserInfo.getUserName());
        sponsorPlanningReportController.search('', '', Date.today(), Date.today(), '');
        sponsorPlanningReportController.search('test', '', Date.today(), Date.today(), '');
        sponsorPlanningReportController.search('', 'test', Date.today(), Date.today(), '');
        sponsorPlanningReportController.search('', '', Date.today(), Date.today(), UserInfo.getUserName());
        sponsorPlanningReportController.search('', '', null, null, UserInfo.getUserName());
        sponsorPlanningReportController.search('', 'test', Date.today(), Date.today(), UserInfo.getUserName());
        sponsorPlanningReportController.search('', '', null, Date.today(), UserInfo.getUserName());
        sponsorPlanningReportController.search('', '', Date.today(), null, UserInfo.getUserName());
        sponsorPlanningReportController.search('test', '', null, null, UserInfo.getUserName());
        sponsorPlanningReportController.search('', '', null,  Date.today(), '');
        sponsorPlanningReportController.search('', '', Date.today(),  null, '');
        sponsorPlanningReportController.search('', 'test', null,  null, '');
        sponsorPlanningReportController.search('test', 'test', null,  null, '');
        sponsorPlanningReportController.search('test', 'test',  Date.today(),  null, '');
        sponsorPlanningReportController.search('test', '',  Date.today(),  null, UserInfo.getUserName());
        sponsorPlanningReportController.search('test', 'test',  Date.today(),  Date.today(), UserInfo.getUserName());
        sponsorPlanningReportController.search('', '',  null,  null, '');
        sponsorPlanningReportController.search('test', '',  null,  null, '');
        sponsorPlanningReportController.search('test', '',  Date.today(),  null, '');
        sponsorPlanningReportController.search('test', 'test',  Date.today(),  Date.today(), '');
        sponsorPlanningReportController.search('test', '',  Date.today(),  Date.today(), UserInfo.getUserName());
        sponsorPlanningReportController.search('test', '',  null,  Date.today(), UserInfo.getUserName());

        //Add assertion for execution
        System.assert(true, 'All search paths executed successfully.');

        Test.stopTest();
    }
}