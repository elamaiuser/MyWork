/* Description : This test class covers SponsorPlanningReportPDFController (91%) and SponsorPlanningReportController(94%) 
   
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 11/08/2024				  Priti Jana				Modified to cover SponsorPlanningReportPDFController
 *************************************************************************************************************************************************
*/

@isTest
public class SponsorPlanningReportController_Test {
	
    @testSetup static void setup() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Map<string, List<string>> mapResourceTypeCategories =
            skedPicklistFieldUtils.getMapDependentOptions(sked__Resource__c.sked__Resource_Type__c, sked__Resource__c.sked__Category__c);
        List<string> resourceCategories = mapResourceTypeCategories.get(skedConstants.RESOURCE_TYPE_PERSON);
        List<string> assetCategories = mapResourceTypeCategories.get(skedConstants.RESOURCE_TYPE_ASSET);
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');
        List <sked__Resource__c> ResourceList = new List<sked__Resource__c>();       
        List <sked__Account_Resource_Score__c> accountScoreList = new List <sked__Account_Resource_Score__c>();
        List <sked__Resource_Tag__c> resourceTags = new List <sked__Resource_Tag__c>();
        List<sked__Resource_Override__c> resourceOverRides = new List<sked__Resource_Override__c>();
        
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c  = 'Test Internal Name'
        );
        insert testAccount1;  
        
          Contact contact = new Contact(
            firstname = 'Test Contact',
            lastname = 'TestContact',
        	MailingStreet = '2204 Westcrt KR, Apt 219',
        	MailingCity = 'INDIA',
        	MailingStateCode = 'MI',
        	MailingPostalCode = '45720',
            Email = 'test123@gmail.com',
            Primary_Phone__c = 'Work Phone',
            Original_Service_Date__c = System.today(),
            AccountId = testAccount1.Id
        );
       	insert contact;
        
        sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type';            
            insert skedTag;
        
        sked__Account_Tag__c AccTag = new sked__Account_Tag__c(
            sked__Account__c = testAccount1.Id,
            sked__Tag__c = skedTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        insert AccTag;                
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;         
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        sked__Location__c testLocation1 = new sked__Location__c(
            Name = 'Test Location 1',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            // sked__Region__c = testRegion1.Id,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
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
        insert testLocation1; 
        
        sked_Location_Tag__c driveSiteTag1 = new sked_Location_Tag__c(
            sked_Location__c = testLocation1.Id,
            sked_Tag__c = skedTag.Id,
            sked_Minimum_Quantity__c = 1
        );
        insert driveSiteTag1;
        
        Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE,
            Drive_Site__c = testLocation1.Id,
            Additional_Description__c = 'test Desc',
            Drive_Date__c = system.today()+30,
            Drive_Status__c = 'Confirmed',
        	Start_Time__c = Time.newInstance(02, 0, 0, 0),
        	End_Time__c = Time.newInstance(11, 0, 0, 0)
        );
        insert parentOpp;
        
         Opportunity parentOpp2 = new Opportunity(
            Name = 'parent2',
            AccountId = testAccount1.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE,
            Drive_Site__c = testLocation1.Id,
            Additional_Description__c = 'test Desc2',
            Drive_Date__c = system.today()+30,
            Drive_Status__c = 'Confirmed',
        	Start_Time__c = Time.newInstance(02, 0, 0, 0),
        	End_Time__c = Time.newInstance(11, 0, 0, 0)
        );
        insert parentOpp2;
        
        sked_Drive__c testDrive1 = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp.Id,
            sked_Drive_Date__c = system.today()+5,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Primary_Contact__c = contact.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 1           
        );
        insert testDrive1;
        
        sked_Drive__c testDrive2 = new sked_Drive__c(
            Name = 'Test Drive',
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive_Site__c = testLocation1.Id,
            sked_Opportunity__c = parentOpp2.Id,
            sked_Drive_Date__c = null,
            sked_Type_of_Drive__c = 'Mobile',
            sked_Account__c = testAccount1.Id,
            sked_Primary_Contact__c = contact.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
            sked_Drive_Productivity_Planned__c = 0.8,
            sked_Projected_Registered_Donors__c = 1000,
            sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
            sked_2RBC_Projected_Procedures__c = 2,
            sked_Total_Products_Projected__c = 1           
        );
        skedHubBase.BypassUpdateTriggers = TRUE;
        skedHubBase.BypassInsertTriggers = true;
        insert testDrive2;
        
        sked_Drive_Shift__c shiftData = new sked_Drive_Shift__c(
            Name = 'test shift 1',
            sked_Max_Donor_Capacity__c = 250,
            sked_2RBC_Projected_Procedures__c = 6,
            sked_WB_Projected_Procedures__c = 6,
            sked_Staff_Setup__c = 15,
            sked_Equipment_Allocated__c = 4,
            sked_Lunch_Break_Start_Time__c = Time.newInstance(8, 0, 0, 0),
            sked_Lunch_Break_End_Time__c = Time.newInstance(9, 0, 0, 0),
            sked_Drive__c = testDrive1.Id,
            sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
            sked_End_Time__c = Time.newInstance(12, 0, 0, 0));  
            insert shiftData;
        
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = testRegion1.Id,
            sked__Start__c = system.today(),
            sked__Finish__c = system.today()+10,
            sked__Duration__c = 14400,
            sked_Drive__c = testDrive1.Id,
            sked_Asset_Type__c = 'Vehicle',
            sked_Setup_Time__c = 100,
            sked_Drive_Shift__c = shiftData.Id,
            sked_Redcross_Volunteer_Quantity__c = 1,
            sked_Sponsor_Volunteer_Quantity__c = 1,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION
        );
        insert job1;
        system.debug('job1 '+job1.sked__Duration__c);
        
        BSF_Portfolio__c bsfPortfolio = new BSF_Portfolio__c();
        bsfPortfolio.Name = 'Test BSF Name';
        bsfPortfolio.Portfolio_Name__c ='SAM Test Data 1';
        bsfPortfolio.Portfolio_Code__c ='SAM Test Data 1';
        bsfPortfolio.Account_Based_Portfolio__c = true;
        bsfPortfolio.Portfolio_Type__c = 'Sickle Cell Account Manager';
        triggerHandler.bypass('BsfPortfolioTriggerHandler');
        
        insert bsfPortfolio;
    
        Account_Portfolio_Assignment__c accPortfolio2 = new Account_Portfolio_Assignment__c();
        accPortfolio2.BSF_Portfolio__c = bsfPortfolio.Id;
        accPortfolio2.Account__c = testAccount1.Id;
        accPortfolio2.Start_Date__c = SYstem.today();
        accPortfolio2.End_Date__c = System.today() +5;
        triggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        insert accPortfolio2;
        
        OpportunityTeamMember opptyTeamMember = new OpportunityTeamMember(
        OpportunityId=parentOpp.Id,
        TeamMemberRole ='Account Manager',
        UserId=UserInfo.getUserId());
        insert opptyTeamMember;
        
    }            
    
    @IsTest
    private static void test () {
        Test.startTest();
        Account acc= [Select Id,Name,Internal_Name__c,District_Manager__c From Account Limit 1];
        Opportunity mobileOpportunity = [Select Id, AccountId, Drive_Site__c, StageName,CloseDate,Is_template__c,Additional_Description__c,Parent_Template_Id__r.Additional_Description__c,
        Drive_Date__c, Drive_Status__c,Start_Time__c,End_Time__c From Opportunity LIMIT 1];
        Biomed_Collection_Op_Center__c collOpp = [Select Id,Name From Biomed_Collection_Op_Center__c Limit 1];
        sked_Drive__c drive = [Select Id,sked_Collection_Operation__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Drive_Site__c,sked_Account__c From sked_Drive__c Limit 1];
        sked__Job__c job = [Select Id,sked__Region__c,sked_Drive__c From sked__Job__c Limit 1];
        sked_Drive_Shift__c driveShift = [Select Id,Name,sked_Drive__c,sked_Start_Time__c,sked_End_Time__c,sked_Drive__r.sked_Opportunity__c,sked_Max_Donor_Capacity__c From sked_Drive_Shift__c Limit 1];
        Contact contact = new Contact(
            firstname = 'Test Contact First 1',
            lastname = 'TestContactLast1', 
        	MailingStreet = '2204 Westcrt ln, Apt 213',
        	MailingCity = 'Herndon',
        	MailingStateCode = 'MI',
        	MailingPostalCode = '48420',
            Email = 'test@gmail.com',
            Primary_Phone__c = 'Work Phone',
            Original_Service_Date__c = System.today(),
            AccountId = mobileOpportunity.AccountId
        );
       	insert contact;
        OpportunityTeamMember opptyTeamMember = new OpportunityTeamMember(OpportunityId=mobileOpportunity.Id,TeamMemberRole ='Account Manager',UserId=UserInfo.getUserId());
        insert opptyTeamMember;
        
        OpportunityContactRole opptyContactRole = new OpportunityContactRole(Role = 'Whom to Meet',ContactId=contact.Id,OpportunityId=mobileOpportunity.Id);
        insert opptyContactRole;
        
        List<Note> notes = new List<Note>();
        notes.add(new Note(ParentId=mobileOpportunity.AccountId,Title='Account Notes'));
        notes.add(new Note(ParentId=mobileOpportunity.Id,Title='Opportunity Notes'));
        notes.add(new Note(ParentId=mobileOpportunity.Drive_Site__c,Title='Site Notes'));
        insert notes;
        
        Account_Service_Role__c asr = new Account_Service_Role__c(Contact__c=contact.Id,Account__c=mobileOpportunity.AccountId,Account_Service_Role__c='Blood Program Leader');
        insert asr;
        
        Id organizationPartnershipRTId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Organization Partnership').getRecordTypeId();
        Marketing_Program__c  affilaition = new Marketing_Program__c(Scope__c='Drive;Account;Template',Name='Test Marketing Program',RecordTypeId=organizationPartnershipRTId, Nationwide_Marketing_Program__c = 'Yes',External_Name__c='Test Marketing Program');
        insert affilaition;
        
        Account_Marketing_Program__c amp = new Account_Marketing_Program__c(Marketing_Program__c =affilaition.id,Account__c = mobileOpportunity.AccountId );
        insert amp;
        Drive_Marketing_Programs__c  dmp= new Drive_Marketing_Programs__c (Marketing_Program__c =affilaition.id,Blood_Drive_Opportunity__c = mobileOpportunity.Id);
        insert dmp;
        
        Order order1 = new Order(Comments__c='Test Order',
                                 Local_Recruitment_Request_Need_by_Date__c = System.today().addDays(10) ,
                                 BudgetCurrency__c = 1000,
                                 OpportunityId=mobileOpportunity.Id,
                                 AccountId=mobileOpportunity.AccountId,
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
        IsActive = true);
	    insert standardPrice;									
															
      /*  OrderItem ordItem = new OrderItem(
            OrderId= order1.id,
			PricebookEntryId = standardPrice.Id,
			Quantity = 1,
			//UnitPrice = 0.40,
            ListPrice = 0.40,
			Product2id  = prod.Id,
			Material_Recipient__c  = 'Account Manager'); 
			insert ordItem; */
        
        Task task1 = new Task(Subject='Test Task',ActivityDate=System.today().addDays(10), WhatId=mobileOpportunity.Id);
        insert task1;
        Test.setCurrentPageReference(new PageReference('Page.generatePdfWithData'));
        System.currentPageReference().getParameters().put('ids', mobileOpportunity.Id);
        sponsorPlanningReportController pdefObj = new sponsorPlanningReportController();
        
        // Test for SponsorPlanningReportPDFController
        System.currentPageReference().getParameters().put('opportunityids', mobileOpportunity.Id);
        SponsorPlanningReportPDFController pdef1Obj = new SponsorPlanningReportPDFController();
        Test.stopTest();
        
    }
   /* @IsTest
    private static void testgetDataforPdf(){
        test.startTest();
        
        sked__Location__c site = [Select Id From sked__Location__c LIMIT 1];
        Account testAccount1 = new Account(
            Name = 'Test Account1',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c  = 'Test Internal Name'
        );
        insert testAccount1; 
        Biomed_Collection_Op_Center__c collOpp = [Select Id,Name From Biomed_Collection_Op_Center__c Limit 1];
        sked_Drive__c drive = [Select Id,sked_Collection_Operation__c,sked_Drive_Date__c,sked_Opportunity__c,sked_Drive_Site__c,sked_Account__c From sked_Drive__c Limit 1];
        sked__Job__c job = [Select Id,sked__Region__c,sked_Drive__c From sked__Job__c Limit 1];
        sked_Drive_Shift__c driveShift = [Select Id,Name,sked_Drive__c,sked_Start_Time__c,sked_End_Time__c,sked_Drive__r.sked_Opportunity__c,sked_Max_Donor_Capacity__c From sked_Drive_Shift__c Limit 1];
         Opportunity parentOpp = new Opportunity(
            Name = 'parent',
            AccountId = testAccount1.Id,
            StageName = 'Discovery',
            CloseDate = system.today()+10,
            Is_template__c = TRUE,
            Drive_Site__c = site.Id,
            Additional_Description__c = 'test Desc',
            Drive_Date__c = system.today()+30,
            Drive_Status__c = 'Confirmed',
        	Start_Time__c = Time.newInstance(02, 0, 0, 0),
        	End_Time__c = Time.newInstance(11, 0, 0, 0)
        );
        insert parentOpp;  
        
        Contact contact = new Contact(
            firstname = 'Test Contact First 1',
            lastname = 'Test Contact Last 1',
        	MailingStreet = '2204 Westcrt ln, Apt 213',
        	MailingCity = 'Herndon',
        	MailingStateCode = 'MI',
        	MailingPostalCode = '48420',
            Email = 'test@gmail.com',
            Primary_Phone__c = 'Work Phone',
            Original_Service_Date__c = System.today(),
            AccountId = parentOpp.AccountId
        );
       	insert contact;
        
        Account_Service_Role__c asr = new Account_Service_Role__c(Contact__c=contact.Id,Account__c=parentOpp.AccountId,Account_Service_Role__c='Blood Program Leader');
        insert asr;
        
         Order ord = new Order(Comments__c='Test Order', Local_Recruitment_Request_Need_by_Date__c = System.today().addDays(10) , OpportunityId=parentOpp.Id,AccountId=testAccount1.Id,EffectiveDate=System.today(), Status='Draft');
        insert ord;
        
        Marketing_Program__c  affilaition = new Marketing_Program__c(Scope__c='Drive',Name='Test Marketing Program', Nationwide_Marketing_Program__c = 'Yes',External_Name__c='Test Marketing Program');
        insert affilaition;
        
       Drive_Marketing_Programs__c  dmp= new Drive_Marketing_Programs__c (Marketing_Program__c =affilaition.id ,Blood_Drive_Opportunity__c = parentOpp.Id, Account__c = testAccount1.Id);
        insert dmp;
        
         Task task1 = new Task(Subject='Test Task',ActivityDate=System.today().addDays(10), WhatId=parentOpp.Id);
        insert task1;
        
        sponsorPlanningReportController.DriveWrapper wrapper= new sponsorPlanningReportController.DriveWrapper ();
        
        Test.setCurrentPageReference(new PageReference('Page.generatePdfWithData'));
        System.currentPageReference().getParameters().put('ids', parentOpp.Id);
        sponsorPlanningReportController pdefObj = new sponsorPlanningReportController();
        test.stopTest();
    } */
   
     @IsTest
    private static void search () {
        Test.startTest();
        Opportunity mobileOpportunity = [Select Id,Name, AccountId, Drive_Site__c From Opportunity LIMIT 1];
          Account testAccount1 = new Account(
            Name = 'Test Account1',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c  = 'Test Internal Name'
        );
        insert testAccount1; 
        BSF_Portfolio__c bsf = [Select Name,Portfolio_Name__c,Portfolio_Code__c,Account_Based_Portfolio__c,Portfolio_Type__c From BSF_Portfolio__c Limit 1];
        Account_Portfolio_Assignment__c accPortfolio = [Select Name, Account__r.Name, Account__c, BSF_Portfolio__c, BSF_Portfolio__r.Name, Start_Date__c, End_Date__c From Account_Portfolio_Assignment__c Limit 1];
        OpportunityTeamMember oppTeamMember = [Select Id,Name,OpportunityId,TeamMemberRole,UserId From OpportunityTeamMember Limit 1];
        /*  BSF_Portfolio__c bsfPortfolio = new BSF_Portfolio__c();
        bsfPortfolio.Name = 'Test BSF Name';
        bsfPortfolio.Portfolio_Name__c ='SAM Test Data 1';
        bsfPortfolio.Portfolio_Code__c ='SAM Test Data 1';
        bsfPortfolio.Account_Based_Portfolio__c = true;
        bsfPortfolio.Portfolio_Type__c = 'Sickle Cell Account Manager';
        
        insert bsfPortfolio;
        
        Account_Portfolio_Assignment__c accPortfolio2 = new Account_Portfolio_Assignment__c();
        accPortfolio2.Name = 'Test Account Portfolio';
        accPortfolio2.BSF_Portfolio__c = bsfPortfolio.Id;
        accPortfolio2.Account__c = testAccount1.Id;
        accPortfolio2.Start_Date__c = SYstem.today();
        accPortfolio2.End_Date__c = System.today() +5;
        insert accPortfolio2; 
        
        OpportunityTeamMember opptyTeamMember = new OpportunityTeamMember(OpportunityId=mobileOpportunity.Id,TeamMemberRole ='Account Manager',UserId=UserInfo.getUserId());
        insert opptyTeamMember; */
        
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
        Test.stopTest();
    }
    
}