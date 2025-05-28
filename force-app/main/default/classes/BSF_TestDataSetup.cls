/***
* Name: BSF_TestDataFactory
* Description: Common Test Class for setting up the test data to be used across test classes
* Author: Anil K
* Date: 06/24/2022
* 
* */

@IsTest
public class BSF_TestDataSetup {
    
    public boolean doInsert = true;
    
    public BSF_TestDataSetup() {
        
    }
    
    public BSF_TestDataSetup(boolean insertSObject) {
        doInsert = insertSObject;
    }
    
    /*
        @isTest
        public static void testDataSetup(){
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup();
        testDataSetup.createAndInsertCommonObjects();
        }
	*/
    
    /****
        * This method acts as a test data factory and creates and inserts all common objects and returns map of objects
        * Caller of this method can retrieve object with its name(Names mentioned below) as key  from below
        * 
        * FIXED_SITE_ACCOUNT - returns fixed site account
        * MOBILE_ACCOUNT- returns mobile account
        * FIXED_SITE - returns fixed site
        * MOBILE_SITE - returns mobile site
        * FIXED_OPP - returns fixed opportunity
        * MOBILE_OPP - returns mobile opportunity
        * SKED_TERRITORY_DIVISON - returns sked territory division record type
        * SKED_TERRITORY_ARC_REGION - return skeds territory ArcRegion record type
        * SKED_TERRITORY_DISTRICT - return skeds territory District record type
        * SITE_COLLECTION_OPERATION  - return site collection opp
        * COLLECTION_OPERATION  - return collection opp
        * LEAD - return lead
        * CONTACT - return contact
        * SKED_REGION testRegion1
        * 
        * */
    
    public Map<string, sObject> createAndInsertCommonObjects(){
        
        Map<string, sObject> mapTestData = new  Map<string, sObject>();
        
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Map <String,Schema.RecordTypeInfo> recordTypesSite = sked__Location__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        /* DRD Profile User */
        User drdUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        if(doInsert){
			system.runAs(new User(Id = UserInfo.getUserId())) {
        		insert drdUser;
        	}
        }
        mapTestData.put('DRD_USER', drdUser);
        
         /* DRD Manager User */
        User drdManagerUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'DRDManagerLastName',
            Email = 'DRDManager@test.com',
            Username = 'DRDManager@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompanyDRD',
            Title = 'TestManagerTitle',
            Alias = 'DRDMng',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        if(doInsert){
			system.runAs(new User(Id = UserInfo.getUserId())) {
        		insert drdManagerUser;
        	}
        }
        mapTestData.put('DRD_MANAGER_USER', drdManagerUser);
        
        /* Mobile Account */
        Id MobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        Account mobileAcc = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            Internal_Name__c='Test Account 1',
            District_Manager__c = UserInfo.getUserId(),
        	BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
        System.debug('Before mobile account is inserted (doInsert) '+doInsert);
        if(doInsert) {
        	insert mobileAcc;
            System.debug('Ater mobile account is inserted '+mobileAcc.Id);
        }
        mapTestData.put('MOBILE_ACCOUNT', mobileAcc);
        
        /* Fixed Site Account - 1*/
        Id FixedAccountRecTypeId = recordTypesAccount.get('Fixed Site Account').getRecordTypeId();
        Account fixedAcc = new Account(
            name = 'Test Account 1',
        	RecordTypeId = FixedAccountRecTypeId,
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c='Test Fixed Site Account 1',
        	BillingStreet = '2204 Westcrt ln, Apt 213',
        	BillingCity = 'Walbridge',
        	BillingStateCode = 'OH',
        	BillingPostalCode = '43465'
        );
        if(doInsert) {
        	insert fixedAcc;
        }
        mapTestData.put('FIXED_SITE_ACCOUNT', fixedAcc);
        
         /* Fixed Site Account - 2*/
        Account fixedAcc2 = new Account(
            name = 'Test Account 2',
        	RecordTypeId = FixedAccountRecTypeId,
            District_Manager__c = drdManagerUser.Id,
            Internal_Name__c='Test Fixed Site Account 2',
        	BillingStreet = '730 N. Summit St.',
        	BillingCity = 'Toledo',
        	BillingStateCode = 'OH',
        	BillingPostalCode = '43604'
        );
        if(doInsert) {
        	insert fixedAcc2;
        }
        mapTestData.put('FIXED_SITE_ACCOUNT2', fixedAcc2);
        
        /* Contact */ //Changes to handle validation rule
        Contact contact = new Contact(
            firstname = 'Test Contact First 1',
            lastname = 'TestContactLast1',
            Email = 'testContact@gmail.com',
            Original_Service_Date__c = system.today().addDays(3),
        	MailingStreet = '2204 Westcrt ln, Apt 213',
        	MailingCity = 'Herndon',
        	MailingStateCode = 'MI',
        	MailingPostalCode = '48420',
            Primary_Phone__c = 'Mobile Phone',
            MobilePhone = '752-781-0090'
        );
        if(doInsert) {
            contact.AccountId = mobileAcc.Id;
        	insert contact;
        }
        mapTestData.put('CONTACT', contact);
       
        /* Collection Operation */
        Biomed_Collection_Op_Center__c collectionOperation = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            sked_Maximum_Shift_Length_Threshold__c = 480
        );
        if(doInsert) {
        	insert collectionOperation;
        }
        mapTestData.put('COLLECTION_OPP', collectionOperation);
        
        /* Staffing Decision Matrix (SDM) */
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrix = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 36,
            sked_VP_HH_Capacity__c = 2.2,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile').getRecordTypeId()
        );
        if(doInsert) {
            insert staffingDecisionMatrix;
        }
		mapTestData.put('STAFFING_DECISION_MATRIX', staffingDecisionMatrix);
        
        sked_Staffing_Decision_Matrix__c staffingDecisionMatrixFixed = new sked_Staffing_Decision_Matrix__c (
            sked_2RBC_Staff_Capacity__c = 1.6,
            sked_Charge_Capacity__c = 1.1,
            sked_Charge_Threshold__c = 36,
            sked_Driver_Capacity__c = 2.2,
            sked_Driver_Support_Capacity__c = 2.2,
            sked_Team_Supervisor_Threshold__c = 36,
            sked_VP_HH_Capacity__c = 2.2,
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId()
        );
        if(doInsert) {
            insert staffingDecisionMatrixFixed;
        }
        mapTestData.put('STAFFING_DECISION_MATRIX_FIXED', staffingDecisionMatrixFixed);
        
          
        /* US Citizen Tag */
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        if(doInsert) {
            insert usCitizenTag;
        }
        mapTestData.put('US_CITIZEN_TAG', usCitizenTag);
        
        /* Spanish Tag */
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        if(doInsert) {
            insert spanishTag;
        }
        mapTestData.put('SPANISH_TAG', spanishTag);
        
        /* Lift Gate Tag */
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        if(doInsert) {
            insert liftGateTag;
        }
        mapTestData.put('LIFT_GATE_TAG', liftGateTag);
        
        /* Account Team Member - Mobile */
        AccountTeamMember mobileAccTeamMember = new AccountTeamMember(
            AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Account Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Coverage_Reason__c = ''
        );
        if(doInsert) {
            mobileAccTeamMember.UserId = drdUser.Id;
            mobileAccTeamMember.AccountId = mobileAcc.Id;
            insert mobileAccTeamMember;
        }
        mapTestData.put('ACCOUNT_TEAM_MEMBER_MOBILE', mobileAccTeamMember);
        
        /* Account Team Member - Fixed Site Account */
        AccountTeamMember fixedAccTeamMember = new AccountTeamMember(
        	AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            UserId = drdUser.Id,
            TeamMemberRole = 'Account Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(50),
            Is_Covering_Recruiter__c = true,
            Coverage_Reason__c = ''
        );
        if(doInsert) {
            fixedAccTeamMember.AccountId = fixedAcc.Id;
            insert fixedAccTeamMember;
        }
        mapTestData.put('ACCOUNT_TEAM_MEMBER_FIXED', fixedAccTeamMember);
        
        /* Account Team Member - Fixed Site Account 2*/
        AccountTeamMember fixedAccTeamMember2 = new AccountTeamMember(
        	AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',            
            TeamMemberRole = 'Account Manager',
            Start_Date__c = System.today(),
            End_Date__c = System.today().addDays(100),
            Is_Covering_Recruiter__c = true,
            Coverage_Reason__c = ''
        );
        if(doInsert) {
            fixedAccTeamMember2.UserId = drdManagerUser.Id;
            fixedAccTeamMember2.AccountId = fixedAcc2.Id;
            insert fixedAccTeamMember2;
        }
        mapTestData.put('ACCOUNT_TEAM_MEMBER_FIXED2', fixedAccTeamMember2);
        
        /* Sked Region */
        sked__Region__c region = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID()
        );
        if(doInsert) {
            region.sked_Biomed_Collection_Op_Center__c = collectionOperation.Id;
			insert region;	
        }
        mapTestData.put('SKED_REGION', region);
        
        /* Donor Services Region */
        Collections_Region__c donorServicesRegion = new Collections_Region__c(
        	name = 'Test Donor Services Region'
        );
        if(doInsert) {
            insert donorServicesRegion;
        }
		mapTestData.put('DONOR_SERVICES_REGION', donorServicesRegion);

        /* Collection Operation SDM */
        sked_Collection_Operation_SDM__c collectionOperationSdm = new sked_Collection_Operation_SDM__c(
            sked_Effective_End_Date__c = System.today().AddDays(6000),
            sked_Effective_Start_Date__c = System.today().AddDays(-5000)
        );
        if(doInsert) {
            collectionOperationSdm.sked_Collection_Operation__c = collectionOperation.Id;
            collectionOperationSdm.sked_Staffing_Decision_Matrix__c = staffingDecisionMatrix.Id;
            insert collectionOperationSdm;
        }
        mapTestData.put('COLLECTION_OPERATION_SDM', collectionOperationSdm);
        
        sked_Collection_Operation_SDM__c collectionOperationSdmFixed = new sked_Collection_Operation_SDM__c(
            sked_Effective_End_Date__c = System.today().AddDays(6000),
            sked_Effective_Start_Date__c = System.today().AddDays(-5000)
        );
        if(doInsert) {
            collectionOperationSdm.sked_Collection_Operation__c = collectionOperation.Id;
            collectionOperationSdm.sked_Staffing_Decision_Matrix__c = staffingDecisionMatrixFixed.Id;
            insert collectionOperationSdmFixed;
        }
        mapTestData.put('COLLECTION_OPERATION_SDM_FIXED', collectionOperationSdmFixed);
        
		/* Lunch Break Setting */
        sked_Lunch_Break_Setting__c lunchBreakSetting = new sked_Lunch_Break_Setting__c(
            sked_Maximum_Lunch_Break_Duration__c = '30'
        );
        if(doInsert) {
            insert lunchBreakSetting;
        }
        mapTestData.put('LUNCH_BREAK_SETTING', lunchBreakSetting);
        
        /* Sked Lunch Break Definition */
        sked_Lunch_Break_Definition__c lunchBreakDefinition = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 60,
            sked_Max_Number_of_Staff__c = 2,
            sked_Min_Number_of_Staff__c = 0,
            sked_Slot_Reduction__c = 100
        );
        if(doInsert) {
            lunchBreakDefinition.sked_Lunch_Break_Setting__c = lunchBreakSetting.Id;
            insert lunchBreakDefinition;
        }
		mapTestData.put('LUNCH_BREAK_DEFINITION', lunchBreakDefinition);
        
        /* Collection Territory for Region */
        Collections_Territory__c regionTerritory = new Collections_Territory__c(
            Name = 'Test Territory',
            Zip__c = '27560',
            BDM__c = UserInfo.getUserId()
        );
        if(doInsert) {
            regionTerritory.Region__c = donorServicesRegion.Id;
            insert regionTerritory;
        }
        mapTestData.put('COLLECTION_TERRITORY_REGION', regionTerritory);
        
        /*Chapter for Site*/
        Chapter__c testChapter = new Chapter__c(
            Chapter_Code__c='AB299',
            Division_Code__c='D21',
            City__c='Charlotte',
            State__c='NC',
            Regional_Chapter_Code__c='00F33',
            Type__c='Chapter',
            Region_Name__c='Test Region'
        );
        if(doInsert) {
            insert testChapter;
        }
        
        /* Mobile Account Tag - US Citizen */
        sked__Account_Tag__c mobileAccountTagUsCitizen = new sked__Account_Tag__c(
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        if(doInsert) {
            mobileAccountTagUsCitizen.sked__Account__c = mobileAcc.Id;
            mobileAccountTagUsCitizen.sked__Tag__c = usCitizenTag.Id;
            insert mobileAccountTagUsCitizen;
        }
        mapTestData.put('MOBILE_ACCOUNT_TAG_USCITIZEN', mobileAccountTagUsCitizen);
        
        /* Mobile Account Tag - Spanish */
        sked__Account_Tag__c mobileAccountTagSpanish = new sked__Account_Tag__c(
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        if(doInsert) {
            mobileAccountTagSpanish.sked__Account__c = mobileAcc.Id;
            mobileAccountTagSpanish.sked__Tag__c = spanishTag.Id;
            insert mobileAccountTagSpanish;
        }
        mapTestData.put('MOBILE_ACCOUNT_TAG_SPANISH', mobileAccountTagSpanish);
        
        /* Fixed Account Tag - US Citizen */
        sked__Account_Tag__c fixedSiteAccountTagUsCitizen = new sked__Account_Tag__c(
            sked__Required__c = TRUE,
            sked__Weighting__c = NULL
        );
        if(doInsert) {
            fixedSiteAccountTagUsCitizen.sked__Account__c = fixedAcc.id;
            fixedSiteAccountTagUsCitizen.sked__Tag__c = usCitizenTag.Id;
            insert fixedSiteAccountTagUsCitizen;
        }
        mapTestData.put('FIXED_ACCOUNT_TAG_USCITIZEN', fixedSiteAccountTagUsCitizen);
        
        /* Fixed Account Tag - Spanish */
        sked__Account_Tag__c fixedSiteAccountTagSpanish = new sked__Account_Tag__c(
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        if(doInsert) {
            fixedSiteAccountTagSpanish.sked__Account__c = fixedAcc.Id;
            fixedSiteAccountTagSpanish.sked__Tag__c = spanishTag.Id;
            insert fixedSiteAccountTagSpanish;
        }
		mapTestData.put('FIXED_ACCOUNT_TAG_SPANISH', fixedSiteAccountTagSpanish);
        
        //system.debug('mapTestData.get.Id '+mapTestData.get('CONTACT').Id);
        
        /* Mobile Site */
        sked__Location__c mobileSite = new sked__Location__c(
            Name = 'Test Mobile Location',
            RecordTypeId=  recordTypesSite.get('Mobile Site').getRecordTypeId(),  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Inside_stairs__c = 3,
            Chapter__c = testChapter.Id,
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
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form'
        );
        if(doInsert){
            mobileSite.sked__Region__c = region.Id;
            mobileSite.sked_Collection_Operation__c = collectionOperation.Id;
            mobileSite.sked_Site_Contact__c = mapTestData.get('CONTACT').Id;
            insert mobileSite;
        }
        mapTestData.put('MOBILE_SITE', mobileSite);
        
        /* Mobile Site #2 */
        sked__Location__c mobileSite2 = new sked__Location__c(
            Name = 'Test Mobile Location',
            RecordTypeId=  recordTypesSite.get('Mobile Site').getRecordTypeId(),  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Inside_stairs__c = 3,
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
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form',
            sked_Site_Contact__c = contact.Id
        );
        if(doInsert){
            mobileSite2.sked__Region__c = region.Id;
            mobileSite2.sked_Collection_Operation__c = collectionOperation.Id;
            mobileSite2.sked_Site_Contact__c = mapTestData.get('CONTACT').Id;
            insert mobileSite2;
        }
        mapTestData.put('MOBILE_SITE2', mobileSite2);
        
        /* Mobile Site #3 --> Without mandatory fields HRP-10882 */
        sked__Location__c mobileSite3 = new sked__Location__c(
            Name = 'Test Mobile Location 3',
            RecordTypeId=  recordTypesSite.get('Mobile Site').getRecordTypeId(),  
            sked_TimeZone__c = 'America/New_York',
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA, 27560',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            //sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Fixed_Site_Appointment_Pattern__c = 'Grouped',
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            //sked_Outside_stairs__c = 3,
            sked_Inside_stairs__c = 3,
            sked_Pay_for_Parking__c = 'Other',
            sked_Pay_for_Parking_Details__c = 'Pay for parking details',
            sked_Physical_Location_Type__c = 'Inside',
            sked_Room_Name__c = 'Room 1',
            sked_Room_Size__c = '2001-2400 Sq. Ft.',
            sked_Site_Building_Name__c = 'Building Name',
            sked_Site_Inspection_Completed_By__c = UserInfo.getUserId(),
            //sked_Site_Main_Phone__c = '098-765-4321',
            //sked_Staff_Personal_Parking_Directions__c = 'Staff Personal Parking Directions',
            sked_Travel_Time_to_Staging_Location__c = 15,
            sked_Wireless_Policy__c = 'Accepted',
            sked_Address_1__c = 'Test Address', 
            sked_City__c = 'city', 
            sked_County__c = 'United States', 
            sked_State__c = 'Texas', 
            sked_Zip_Code__c = '27560',
            Source__c ='Custom New Form'
            ///sked_Site_Contact__c = contact.Id
        );
        if(doInsert){
            mobileSite3.sked__Region__c = region.Id;
            mobileSite3.sked_Collection_Operation__c = collectionOperation.Id;
           // mobileSite3.sked_Site_Contact__c = mapTestData.get('CONTACT').Id;
            insert mobileSite3;
        }
        mapTestData.put('MOBILE_SITE3', mobileSite3);
        
        /* Fixed Site */
        sked__Location__c fixedSite = new sked__Location__c(
            Name = 'Test Fixed Location',
            RecordTypeId=  recordTypesSite.get('Fixed Site').getRecordTypeId(),  
            sked__Address__c = 'Inner Parkside, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7450046,
            sked__GeoLocation__Longitude__s = -122.4816244,
            sked_ARC_Vehicle_Parking_Directions__c = 'ARC Vehicle Parking Directions',
            sked_Automation_Suitability__c = 'Suitable',
            sked_Base_Description__c = 'Base Description',
            sked_Directions_From_CollectionOperation__c = 'Directions from Collection Operation',
            sked_Date_Site_Inspection_Completed__c = Date.today().addDays(-1),
            sked_Floor_Description__c = 'Floor Description',
            sked_National_Name__c = 'USA',
            sked_Outside_stairs__c = 3,
            sked_Inside_stairs__c = 3,
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
            Operation_Type__c = 'Integrated',
            sked_Address_1__c='Test Address', 
            sked_City__c='city', 
            sked_County__c='United States', 
            sked_State__c='Texas', 
            sked_Zip_Code__c='61641',
            Source__c='Custom New Form'
        );
        if(doInsert) {
            fixedSite.sked__Region__c = region.Id;
            fixedSite.sked_Collection_Operation__c = collectionOperation.Id;
        	insert fixedSite;   
        }
        mapTestData.put('FIXED_SITE', fixedSite);
        
        /* Template Opportunity - Mobile */
        Opportunity mobileTemplateOpp = new Opportunity(
            Name = 'Mobile Template Opp',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
            StageName = 'Discovery', 
            CloseDate = System.today(),
            Is_Template__c = TRUE,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
            Anticipated_Registered_Donors__c = 10,
            WB_Projected_Procedures__c = 11,
            X2RBC_Projected_Procedures__c = 12,
            Red_Cross_Volunteer_Required__c = true
        );
        if(doInsert) {
            mobileTemplateOpp.AccountId = mobileAcc.Id;
            mobileTemplateOpp.Drive_Site__c = mobileSite.Id;
            insert mobileTemplateOpp;
        }
        mapTestData.put('MOBILE_TEMPLATE_OPP', mobileTemplateOpp);
        
        /* Site Collection Operation - Mobile Site */
        sked_Site_Collection_Operation__c mobileSiteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_End_Date__c = system.today().AddDays(5000),
            sked_Start_Date__c = System.today().AddDays(-5000)
        );
        if(doInsert) {
            mobileSiteCollectionOperation.sked_Collection_Operation__c = collectionOperation.Id;
            mobileSiteCollectionOperation.sked_Site__c = mobileSite.Id;
            mobileSiteCollectionOperation.sked_Collections_Zip_Code__c = regionTerritory.Id;
            mobileSiteCollectionOperation.sked_Region__c = region.Id;
        }
        mapTestData.put('MOBILE_SITE_COLLECTION_OPERATION', mobileSiteCollectionOperation);
        
        /* Site Collection Operation - Fixed Site */
		sked_Site_Collection_Operation__c fixedSiteCollectionOperation = new sked_Site_Collection_Operation__c(
            sked_Collection_Operation__c = collectionOperation.Id,
            sked_End_Date__c = Date.today().addDays(365),
            sked_Start_Date__c = Date.today()
        );
        if(doInsert) {
       		fixedSiteCollectionOperation.sked_Collection_Operation__c = collectionOperation.Id;
            fixedSiteCollectionOperation.sked_Site__c = fixedSite.Id;
            insert fixedSiteCollectionOperation;
        }
        mapTestData.put('FIXED_SITE_COLLECTION_OPERATION', fixedSiteCollectionOperation); 
        
		/* Mobile Opportunity */
        Opportunity mobileOpp = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            Source__c = 'Adhoc',
            Slot_Generator__c = 130
		);
        if(doInsert) {
            mobileOpp.AccountId = mobileAcc.Id;
            mobileOpp.Drive_Site__c = mobileSite.id;
			insert mobileOpp;        
        }
        mapTestData.put('MOBILE_OPP', mobileOpp);   
        
		/* Template Opportunity - FIXED */
        Opportunity fixedTemplateOpp = new Opportunity(
            Name = 'Fixed Template Opp',
            RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId(),
            StageName = 'Discovery', 
            CloseDate = System.today(),
            Is_Template__c = TRUE,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
            Anticipated_Registered_Donors__c = 10,
            WB_Projected_Procedures__c = 11,
            X2RBC_Projected_Procedures__c = 12,
            Source__c = 'Adhoc',
            Slot_Generator__c = 140
        );
        if(doInsert) {
            fixedTemplateOpp.AccountId = fixedAcc.Id;
            fixedTemplateOpp.Drive_Site__c = fixedSite.Id;
            insert fixedTemplateOpp;
        }
        mapTestData.put('FIXED_TEMPLATE_OPP', fixedTemplateOpp);
        
        /* Fixed Opportunity */
        Opportunity fixedOpp = new Opportunity(
			Name = 'Test Fixed Opportunity',
        	StageName = 'Draft',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(10),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
        	End_Time__c=Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
            Source__c = 'Adhoc',
            Slot_Generator__c = 140
		);
        if(doInsert) {
            fixedOpp.accountId = fixedAcc.Id;
            fixedOpp.Drive_Site__c = fixedSite.Id;
			insert fixedOpp;   
        }
        mapTestData.put('FIXED_OPP', fixedOpp);      
        
        /* Division Territory */
        sked_Territory__c skedTerritoryDivision = new sked_Territory__c(
            Name='SE Caribbean',
            RecordTypeId =  sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Division').getRecordTypeId(),
            sked_High_Drive_Productivity_Threshold__c =0.800000,  
            sked_Mid_Drive_Productivity_Threshold__c=0.600000     
        );
        if(doInsert) {
        	insert  skedTerritoryDivision;
        }
        mapTestData.put('SKED_TERRITORY_DIVISON', skedTerritoryDivision);

        /* ARC Region Territory */
        sked_Territory__c arcRegionTerritory = new sked_Territory__c(
            Name= 'Alabama Mississippi',
            RecordTypeId =  sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('ARC Region').getRecordTypeId(),  
            sked_High_Drive_Productivity_Threshold__c= 0.800000,
            sked_Mid_Drive_Productivity_Threshold__c= 0.600000,
            sked_Parent__c = skedTerritoryDivision.id
        );
        if(doInsert) {
        	insert arcRegionTerritory;
        }
        mapTestData.put('SKED_TERRITORY_ARC_REGION', arcRegionTerritory);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1 = new sked_Fixed_Site_Procedure_Projection__c(
            
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = System.today().addDays(1200),
            sked_Effective_Start_Date__c = System.today().addDays(-90), 
            sked_Procedure_Type__c = 'WB',
            sked_Productive_Procedure_Goal__c = 50,
            sked_QNS__c = 25
        );
        if(doInsert) {
            fixedSiteProcedureProjection1.sked_Account__c = fixedAcc.Id;
            insert fixedSiteProcedureProjection1;
        }
		mapTestData.put('FIXED_SITE_PROJECTION1', fixedSiteProcedureProjection1);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2 = new sked_Fixed_Site_Procedure_Projection__c(
            //sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = System.today().addDays(1200),
            sked_Effective_Start_Date__c = System.today().addDays(-90), 
            sked_Procedure_Type__c = '2RBC',
            sked_Productive_Procedure_Goal__c = 50,
            sked_QNS__c = 25
        );
        if(doInsert) {
            fixedSiteProcedureProjection2.sked_Account__c = fixedAcc.Id;
            insert fixedSiteProcedureProjection2;
        }
		mapTestData.put('FIXED_SITE_PROJECTION2', fixedSiteProcedureProjection2);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection3 = new sked_Fixed_Site_Procedure_Projection__c(
            //sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = System.today().addDays(1200),
            sked_Effective_Start_Date__c = System.today().addDays(-90), 
            sked_Procedure_Type__c = 'Platelet',
            sked_Productive_Procedure_Goal__c = 50,
            sked_QNS__c = 25
        );
        if(doInsert) {
            fixedSiteProcedureProjection3.sked_Account__c = fixedAcc.Id;
            insert fixedSiteProcedureProjection3;
        }
		mapTestData.put('FIXED_SITE_PROJECTION3', fixedSiteProcedureProjection3);
        
        sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4 = new sked_Fixed_Site_Procedure_Projection__c(
            //sked_Account__c = fixedSiteAccount.Id,
            sked_Deferral__c = 25,
            sked_Effective_End_Date__c = System.today().addDays(1200),
            sked_Effective_Start_Date__c = System.today().addDays(-90),
            sked_Procedure_Type__c = 'Plasma',
            sked_Productive_Procedure_Goal__c = 50,
            sked_QNS__c = 25
        );
        if(doInsert) {
            fixedSiteProcedureProjection4.sked_Account__c = fixedAcc.Id;
            insert fixedSiteProcedureProjection4;
        }
		mapTestData.put('FIXED_SITE_PROJECTION4', fixedSiteProcedureProjection4);
        
        /* Distric Territory */
        sked_Territory__c districtTerritory = new sked_Territory__c(
            Name= 'Alabama North',
            RecordTypeId =  sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('District').getRecordTypeId(),  
            sked_High_Drive_Productivity_Threshold__c= 0.800000,
            sked_Mid_Drive_Productivity_Threshold__c= 0.600000,
            sked_Parent__c = skedTerritoryDivision.id
        );
        if(doInsert) {
        	insert districtTerritory;
        }
        mapTestData.put('SKED_TERRITORY_DISTRICT', districtTerritory);
        
        /* Lead */
        Lead testLead = new Lead(
            FirstName = 'LeadService', 
            LastName ='Tests2323',
            Company ='TestComany',
            City = 'Raleigh',
            StateCode = 'NC',
            PostalCode = '27560',
            CountryCode = 'US',
            Parent_Campaign__c = null,
            Campaign_member_status__c = null,
            Email = 'test@test.com'
        );
        if(doInsert) {
        	insert testLead;
        }
        mapTestData.put('LEAD', testLead);

        sked__Tag__c skedTag = new sked__Tag__c(
        	sked__Type__c = 'Physical Location Type',
        	Name = 'Inside',
            sked__Classification__c = 'Global'
        );
        if(doInsert) {
        	insert skedTag;
        }
        mapTestData.put('GLOBAL_TAG', skedTag);
        
		OpportunityContactRole ocr = new OpportunityContactRole();
        if(doInsert) {
            ocr.OpportunityId = mobileOpp.Id;
            ocr.ContactId = contact.id;
            ocr.Role = 'Primary Contact';
            insert ocr;
        }
        mapTestData.put('OPP_CONTACT_ROLE', ocr);
          
        /*
        Biomed_Collection_Op_Center__c testCollectionOperation2 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 2',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        if(doInsert) {
        	insert testCollectionOperation2;
        }
  
        sked__Region__c testRegion2 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation2.Id
        );
        if(doInsert) {
        	insert testRegion2;
        } */
        		
		/*Account_Service_Role__c serviceRole = new Account_Service_Role__c();
        serviceRole.Account_Service_Role__c='Blood Program Leader';
        serviceRole.Account__c = mobileAcc.id; 
        serviceRole.Contact__c = contact.id;
        insert serviceRole;*/        
        
        return mapTestData;
    }
}