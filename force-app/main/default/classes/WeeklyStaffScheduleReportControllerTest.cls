@isTest
private class WeeklyStaffScheduleReportControllerTest {
    @TestSetup
    static void makeData() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Map<String,Schema.RecordTypeInfo> recordTypeMapByName = Schema.SObjectType.sked_Territory__c.getRecordTypeInfosByName();
        
        sked_Territory__c division = new sked_Territory__c();
        division.RecordTypeId = recordTypeMapByName.get('Division').getRecordTypeId();
        division.Name = 'Division';
        division.Start_Date__c = Date.today().addDays(-500);
        division.End_Date__c = Date.today().addDays(500);
        division.sked_Parent__c = null;
        TriggerHandler.bypass('TerritoryTriggerHandler');
        insert division;

        sked_Territory__c region = new sked_Territory__c();
        region.RecordTypeId = recordTypeMapByName.get('ARC Region').getRecordTypeId();
        region.Name = 'ARC Region';
        region.Start_Date__c = Date.today().addDays(-500);
        region.End_Date__c = Date.today().addDays(500);
        region.sked_Parent__c = division.Id;
        TriggerHandler.bypass('TerritoryTriggerHandler');
        insert region;

        sked_Territory__c district = new sked_Territory__c();
        district.RecordTypeId = recordTypeMapByName.get('District').getRecordTypeId();
        district.Name = 'District';
        district.Start_Date__c = Date.today().addDays(-500);
        district.End_Date__c = Date.today().addDays(500);
        district.sked_Parent__c = region.Id;
        TriggerHandler.bypass('TerritoryTriggerHandler');
        insert district;

        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c();
        testCollectionOperation1.Name = 'Collection Operation 1';
        testCollectionOperation1.sked_Lunch_Break_Duration_Fixed_Site__c = '30';
        testCollectionOperation1.sked_Lunch_Break_Duration_Mobile__c = '30';
        testCollectionOperation1.sked_Hold_Threshold__c = 100;
        testCollectionOperation1.Staging_Location_Geolocation__Latitude__s = 37.7450046;
        testCollectionOperation1.Staging_Location_Geolocation__Longitude__s = -122.4816244;
        testCollectionOperation1.sked_Work_Week_First_Day__c = 'Sunday';
        testCollectionOperation1.External_Id__c = 'Bio_Collection_BSF_12345';
        testCollectionOperation1.Biomed_Collection_Op_Code_Center_ID__c = '12345';
        testCollectionOperation1.sked_Territory__c = district.Id;
        testCollectionOperation1.sked_IMPACT_Start_Date__c = Date.today().addDays(-500);
        testCollectionOperation1.sked_IMPACT_End_Date__c = Date.today().addDays(500);
        TriggerHandler.bypass('CollectionOperationTriggerHandler');
        insert testCollectionOperation1;

        sked_Territory_Collection_Operation__c territoryCollOp = new sked_Territory_Collection_Operation__c();
        territoryCollOp.sked_Start_Date__c = Date.today().addDays(-500);
        territoryCollOp.sked_End_Date__c =  Date.today().addDays(500);
        territoryCollOp.sked_Collection_Operation__c = testCollectionOperation1.Id;
        territoryCollOp.sked_Territory__c = district.Id;
        TriggerHandler.bypass('TerritoryCollOpTriggerHandler');
        insert territoryCollOp;

        Test.startTest();
        prepareDataset();
        Test.stopTest();

        sked__Resource__c testResource1 = [SELECT Id FROM sked__Resource__c WHERE RecordType.Name = 'Staff' AND sked__Resource_Type__c = 'Person' LIMIT 1];
        List<String> availabilityType = Custom_Report_Config__mdt.getInstance('AvailabilityType').Value__c.split(',');
        sked__Availability__c availability1 = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Approved',
            sked__Start__c = Date.today(),
            sked__Finish__c = Date.today().addDays(5),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c =  Date.today(),
            sked_Finish_Date__c =  Date.today().addDays(5),
            sked__Type__c = availabilityType[0],
            sked_Start_Time__c = Datetime.now().time(),
            sked_Finish_Time__c = Datetime.now().addMinutes(66).time()
        );
        skedHubBase.BypassInsertTriggers = true;
        insert availability1;
        
        sked__Resource__c testResource2 = [SELECT Id FROM sked__Resource__c 
                                           WHERE RecordType.Name = 'Asset' 
                                           AND sked__Resource_Type__c = 'Asset' 
                                           AND sked_Asset_Type__c = 'Vehicle' LIMIT 1];
        List<String> availabilityType2 = Custom_Report_Config__mdt.getInstance('Vehicle_Availability_Type').Value__c.split(',');
        sked__Availability__c availability2 = new sked__Availability__c(
            sked__Resource__c = testResource2.Id,
            sked__Is_Available__c = True,
            sked__Status__c = 'Approved',
            sked__Start__c = Date.today().addDays(1),
            sked__Finish__c = Date.today().addDays(5),
            sked_Bypass_Auto_Approval_Process__c = True,
            sked_Custom_Status__c = 'Pending',
            sked_Start_Date__c =  Date.today().addDays(1),
            sked_Finish_Date__c =  Date.today().addDays(5),
            sked__Type__c = availabilityType2[0],
            sked_Start_Time__c = Datetime.now().time(),
            sked_Finish_Time__c = Datetime.now().addMinutes(66).time()
        );
        skedHubBase.BypassInsertTriggers = true;
        insert availability2;
    }

    @isTest
    private static void testmethod1(){
        String collOpIds = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1].Id;
        Test.startTest();
        WeeklyStaffScheduleReportController.DatableConfigWrapper wrapper = WeeklyStaffScheduleReportController.searchReport(Date.Today(),Date.Today().addDays(70),'Both',collOpIds,'mobile,fixed');
        BSFVehiclePlanningController.vehicleResourceDataWrapper vpcWrapper = BSFVehiclePlanningController.getAllResourceDataWithDate(Date.Today(),Date.Today().addDays(6),collOpIds);        
        Test.stopTest();
    }
	
    @isTest
    private static void testmethod2(){
        String collOpIds = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1].Id;
        Test.startTest();
        PageReference pr = Page.BSFWeeklyStaffScheduleReportPDF;
        pr.getParameters().put('startdate','2024-06-13');
        pr.getParameters().put('enddate','2024-12-13');
        pr.getParameters().put('collopids',collOpIds);
        pr.getParameters().put('drivetypes','mobile,fixed');
        pr.getParameters().put('dispatch','Both');
        Test.setCurrentPage(pr);
        WeeklyStaffScheduleReportController ext = new WeeklyStaffScheduleReportController(); 
        ext.wrapper = new WeeklyStaffScheduleReportController.DatablePDFWrapper();       
        Test.stopTest();
    }
	
     @isTest
    private static void testmethod3(){
        String collOpIds = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1].Id;
            
        Test.startTest();
        PageReference pr = Page.bsfVehiclePlanningReportPDF;
        pr.getParameters().put('startdate','2024-06-13');
        pr.getParameters().put('enddate','2024-06-19');
        pr.getParameters().put('collopids',collOpIds);
        pr.getParameters().put('renderas','html');
        Test.setCurrentPage(pr);        
        BSFVehiclePlanningController vpc = new BSFVehiclePlanningController();
        vpc.wrapper = new BSFVehiclePlanningController.vehicleResourceDataWrapper();
        Test.stopTest();
    }
    
    @isTest
    private static void testmethod4(){
        String collOpIds = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1].Id;
        Test.startTest();
        PageReference pr = Page.BSFWeeklyStaffScheduleReportPDF;
        pr.getParameters().put('startdate','2024-06-13');
        pr.getParameters().put('enddate','2024-12-13');
        pr.getParameters().put('collopids',collOpIds);
        pr.getParameters().put('drivetypes','mobile,fixed');
        pr.getParameters().put('dispatch','Both');
        pr.getParameters().put('force_download','true');
        Test.setCurrentPage(pr);
        WeeklyStaffScheduleReportController ext = new WeeklyStaffScheduleReportController(); 
        ext.wrapper = new WeeklyStaffScheduleReportController.DatablePDFWrapper();
        Test.stopTest();
    }
     @isTest
    private static void testmethod5(){
        String collOpIds = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1].Id;
            
        Test.startTest();
        PageReference pr = Page.bsfVehiclePlanningReportPDF;
        pr.getParameters().put('startdate','2024-06-13');
        pr.getParameters().put('enddate','2024-06-19');
        pr.getParameters().put('collopids',collOpIds);
        pr.getParameters().put('renderas','pdf');
        pr.getParameters().put('force_download','true');
        Test.setCurrentPage(pr);       
        BSFVehiclePlanningController vpc = new BSFVehiclePlanningController();
        vpc.wrapper = new BSFVehiclePlanningController.vehicleResourceDataWrapper();
        Test.stopTest();
    }
    
	
    //Method to get the map of recordType Name as key and recordTypeId as value 
    private static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
    //Method to get the one picklist value of the Sobject field
    private static String picklistValues(String objectName, String fieldName) {
        String result;

        List<Schema.DescribeSobjectResult> sobjectlist = Schema.describeSObjects(new List<String>{objectName});
        
        for(Schema.DescribeSobjectResult sobj : sobjectlist) {
            for (Schema.PicklistEntry entry : sobj.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    result = entry.getValue();
                    break;
                }
            }
        }

        return result;
    }

    private static void prepareDataset(){
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        String rolename = 'West_BDM';
        String mobileOppRecType = 'Mobile Opp';
        String mobileAccRecType = 'Mobile Account';
        String mobileSiteRecType = 'Mobile Site';    
        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Opportunity' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        
        recordTypeMap = recordTypeMap( 'Account' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id accRecTypeId = recordTypeMap.get(mobileAccRecType);
        
        recordTypeMap = recordTypeMap( 'sked__Location__c' );
        System.debug( '#debug#1 is ' + recordTypeMap );
        Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);
        
        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'adminuser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        //insert AdminUser ;
        
        //UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last',
            Email = 'DRDProfile000@amamama.com',
            Username = 'drduser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        User DRDAMUser1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'last1',
            FirstName = 'first1',
            Phone = '8188188188',
            Email = 'DRDProfile0001@amamama.com',
            Username = 'drduser0001@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias1',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        
        System.runAs( AdminUser ){
            insert new List<User>{DRDAMUser,DRDAMUser1};
        }
        System.runAs( AdminUser ){
            List<Account> mobileAccList = new List<Account>();
            
            Account accObj;
            
            accObj = new Account();
            accObj.RecordTypeId = accRecTypeId;
            accObj.Name = 'Exavalu';
            accObj.BillingPostalCode = '30622';
            accObj.Internal_Name__c ='Exavalu';            
            mobileAccList.add(accobj); 
            
            triggerHandler.bypass('AccountTriggerHandler');
            insert mobileAccList;
            
            List<AccountTeammember> atmList = new List<AccountTeammember>();
            AccountTeammember atm;
            atm = new AccountTeammember();
            atm.AccountAccessLevel = 'Edit';
            atm.CaseAccessLevel = 'Edit';
            atm.OpportunityAccessLevel = 'Edit';
            atm.userId = DRDAMUser.Id ;
            atm.AccountId = mobileAccList[0].Id ;
            atm.TeamMemberRole = 'Account Specialist';
            atm.Coverage_Reason__c = picklistValues('AccountTeammember','Coverage_Reason__c');
            atm.End_Date__c = Date.Today().addDays(10);
            atm.Start_Date__c = Date.Today().addDays(-10);
            atmList.add(atm);
            
            triggerHandler.bypass('AccountTeamMemberTriggerHandler');
            insert atmList;
            
            
            
            
            Contact conObj = new Contact();
            conObj.AccountId = mobileAccList[0].Id;
            conObj.FirstName = 'Test';
            conObj.LastName = 'Contact';
            conObj.MailingCity = 'Ashburn';
            conObj.MailingCountryCode ='US';
            conObj.MailingPostalCode = '20148';
            conObj.MailingStateCode = 'VA';
            conObj.MailingStreet = '23070 Learning Cir';
            conObj.Email = 'test.barno@mailinator.com';
            conObj.Primary_Phone__c = picklistValues('Contact','Primary_Phone__c');
            conObj.Original_Service_Date__c = Date.Today().addDays(-1000);
            conObj.HomePhone = '222-222-3333';
            conObj.MobilePhone = '222-222-3333';
            conObj.OtherPhone = '222-222-3333';
            triggerHandler.bypass('ContactTriggerHandler');
            insert conObj;
            
            sked__Tag__c skedTag = new sked__Tag__c();
            skedTag.Name = 'Outside';
            skedTag.sked__Type__c = 'Physical Location Type'; 
            
            insert skedTag; 
            
            
            sked__Location__c siteObj = new sked__Location__c();
            siteObj.RecordTypeId = siteRecTypeId;
            siteObj.Name = 'Test Site';
            siteObj.sked_Address_1__c = 'Test Site Address';
            siteObj.sked__Address__c = 'Test Site Address';
            siteObj.sked_City__c = 'Test Site City';
            siteObj.sked_State__c = 'Test Site State';
            siteObj.sked_Zip_Code__c = '4000';
            siteObj.sked_County__c = 'USA';
            siteObj.sked_Site_Building_Name__c = 'Test Site Building';
            siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
            siteObj.sked_Room_Name__c = 'Room 15';
            siteObj.sked_National_Name__c = 'AMERICA';
            siteObj.sked_Physical_Location_Type__c = 'Outside';
            siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
            siteObj.sked_Automation_Suitability__c = 'Suitable';
            siteObj.sked_Outside_stairs__c = 1;
            siteObj.sked_Inside_stairs__c = 2;
            siteObj.sked_Base_Description__c = 'test base description';
            siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
            siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
            siteObj.sked_Site_Contact__c = conObj.Id;
            siteObj.sked_Site_Main_Phone__c = '758-771-0091';
            siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
            siteObj.sked_Pay_for_Parking__c = 'Other';
            siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
            siteObj.sked_Wireless_Policy__c = 'Accepted';
            siteObj.Source__c = 'Custom New Form';
            siteObj.sked_Date_Site_Inspection_Completed__c = Date.today();
            skedHubBase.BypassInsertTriggers = true;
            TriggerHandler.bypass('SiteTriggerHandler');
            insert siteObj;
            
            List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
            
            BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();			
            Portland_OR_AM_01.Name='Portland OR AM 01';
            Portland_OR_AM_01.Account_Based_Portfolio__c= true;			
            Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
            Portland_OR_AM_01.Portfolio_Type__c='Account Manager';
            Portland_OR_AM_01.Taxonomy_Type__c='Bio Account Portfolio';
            Portland_OR_AM_01.Territory_Portfolio__c=false;			
            bsfPortf.add(Portland_OR_AM_01);
            
            
            
            BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
            Sickle_Cell_AM_04.Name='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
            Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
            Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
            Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
            Sickle_Cell_AM_04.Portfolio_Type__c='District Manager';
            Sickle_Cell_AM_04.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
            Sickle_Cell_AM_04.Territory_Portfolio__c=false;
            bsfPortf.add(Sickle_Cell_AM_04);
            triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
            insert bsfPortf;
            
            List<Portfolio_Assignment__c> portfAssignList = new List<Portfolio_Assignment__c>();
            
            Portfolio_Assignment__c assign1 = new Portfolio_Assignment__c();
            assign1.Assignment_Type__c = 'District Manager';
            assign1.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign1.End_Date__c = Date.Today().addDays(10);
            assign1.Start_Date__c = Date.Today().addDays(-10);
            assign1.User__c = DRDAMUser.Id;
            portfAssignList.add(assign1);
            
            Portfolio_Assignment__c assign2 = new Portfolio_Assignment__c();
            assign2.Assignment_Type__c = 'District Manager';
            assign2.BSF_Portfolio__c = Sickle_Cell_AM_04.id;
            assign2.End_Date__c = Date.Today().addDays(10);
            assign2.Start_Date__c = Date.Today().addDays(-10);
            assign2.User__c = DRDAMUser.Id;
            portfAssignList.add(assign2);
            triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
            insert portfAssignList;
            triggerHandler.clearBypass('PortfolioAssignmentTriggerHandler');
            List<Opportunity> oppsobjlist = new List<Opportunity>();
            Opportunity optyObj ; // = new Opportunity();
            optyObj = new Opportunity();
            optyObj.RecordTypeId = optyRecTypeId;
            optyObj.AccountId = mobileAccList[0].Id;
            optyObj.Drive_Site__c = siteObj.Id;
            optyObj.Name = 'Test Drive';
            optyObj.StageName = 'Discovery'; 
            optyObj.Drive_Status__c = 'Draft'; 
            optyObj.Drive_Date__c = System.today();
            optyObj.CloseDate = System.today();
            optyObj.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
            optyObj.End_Time__c =  Time.newInstance(18, 30, 2, 20);
            optyObj.WB_Projected_Procedures__c = 1;
            optyObj.X2RBC_Projected_Procedures__c = 1;
            optyObj.Anticipated_Registered_Donors__c = 1;
            optyObj.Account_Manager__c = DRDAMUser1.Id;
            
            oppsobjlist.add( optyObj );

            Opportunity optyObj1 ; // = new Opportunity();
            optyObj1 = new Opportunity();
            optyObj1.RecordTypeId = optyRecTypeId;
            optyObj1.AccountId = mobileAccList[0].Id;
            optyObj1.Drive_Site__c = siteObj.Id;
            optyObj1.Name = 'Test Drive Test';
            optyObj1.StageName = 'Discovery'; 
            optyObj1.Drive_Status__c = 'Draft'; 
            optyObj1.Drive_Date__c = System.today();
            optyObj1.CloseDate = System.today();
            optyObj1.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
            optyObj1.End_Time__c =  Time.newInstance(18, 30, 2, 20);
            optyObj1.WB_Projected_Procedures__c = 1;
            optyObj1.X2RBC_Projected_Procedures__c = 1;
            optyObj1.Anticipated_Registered_Donors__c = 1;
            
            oppsobjlist.add( optyObj1 );
            
                
            triggerHandler.bypass('OpportunityTriggerHandler');
            insert oppsobjlist;

            Biomed_Collection_Op_Center__c testCollectionOperation1 = [SELECT Id, Name FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
            

            
            triggerHandler.bypass('DriveTriggerHandler');
            sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = testCollectionOperation1.Id,
                                                        sked_Drive_Date__c = System.today().addDays(1),
                                                        sked_Drive_Site__c = siteObj.Id,
                                                        sked_Opportunity__c = oppsobjlist.get(0).Id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = mobileAccList.get(0).Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
                                                        sked_Drive_Dispatched__c = false,
                                                            sked_2RBC_Projected_Procedures__c = 2);
            insert testDrive1;
            sked_Drive__c testDrive2 = new sked_Drive__c(Name = 'Testtwo Drive',
                                                        sked_Collection_Operation__c = testCollectionOperation1.Id,
                                                        sked_Drive_Date__c = System.today().addDays(60),
                                                        sked_Drive_Site__c = siteObj.Id,
                                                        sked_Opportunity__c = oppsobjlist.get(1).Id,
                                                        sked_Type_of_Drive__c = 'Fixed Site',
                                                        sked_Account__c = mobileAccList.get(0).Id,
                                                        sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                        sked_End_Time__c = Time.newInstance(17, 0, 0, 0),
                                                        sked_Drive_Productivity_Planned__c = 0.8,
                                                        sked_Projected_Registered_Donors__c = 100,
                                                        sked_Status__c = skedConstants.DRIVE_STATUS_DRAFT,
                                                        sked_Drive_Dispatched__c = true,
                                                        sked_2RBC_Projected_Procedures__c = 2);
            insert testDrive2;
            sked_Drive_Shift__c shiftData = new sked_Drive_Shift__c(Name = 'test shift 1',
                                                                    sked_Max_Donor_Capacity__c = 25,
                                                                    sked_2RBC_Projected_Procedures__c = 6,
                                                                    sked_WB_Projected_Procedures__c = 6,
                                                                    sked_Staff_Setup__c = 15,
                                                                    sked_Equipment_Allocated__c = 4,
                                                                    sked_Lunch_Break_Start_Time__c = Time.newInstance(8, 0, 0, 0),
                                                                    sked_Lunch_Break_End_Time__c = Time.newInstance(9, 0, 0, 0),
                                                                    sked_Drive__c = testDrive1.Id,
                                                                    sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                                    sked_End_Time__c = Time.newInstance(12, 0, 0, 0),
                                                                    sked_Lunch_Break_Duration__c = 40,
                                                                    sked_Lunch_Break_Before_Draw_Hours__c = true);
            insert shiftData;
            sked_Drive_Shift__c shiftData2 = new sked_Drive_Shift__c(Name = 'test shift 2',
                                                                    sked_Max_Donor_Capacity__c = 25,
                                                                    sked_2RBC_Projected_Procedures__c = 6,
                                                                    sked_WB_Projected_Procedures__c = 6,
                                                                    sked_Staff_Setup__c = 15,
                                                                    sked_Equipment_Allocated__c = 4,
                                                                    sked_Lunch_Break_Start_Time__c = Time.newInstance(8, 0, 0, 0),
                                                                    sked_Lunch_Break_End_Time__c = Time.newInstance(9, 0, 0, 0),
                                                                    sked_Drive__c = testDrive2.Id,
                                                                    sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                                    sked_End_Time__c = Time.newInstance(12, 0, 0, 0));
            insert shiftData2;
            System.debug('dfghjk ### 2'+shiftData2.Id);
            sked_Drive_Delivery_Job__c drivejob = new sked_Drive_Delivery_Job__c(sked_Drive__c = testDrive1.Id);
            insert drivejob;
            sked__Region__c reg = new sked__Region__c(Name = 'ABCD',
                                                        sked__Timezone__c = UserInfo.getTimeZone().getID(),
                                                        sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id);
            insert reg;
            String rll = picklistValues('sked__Job__c','sked_Resource_Role__c');
            sked__Job__c skedjob = new sked__Job__c(sked_Drive_Shift__c = shiftData.Id,
                                                    sked_Drive__c = testDrive1.Id,
                                                    sked__Region__c = reg.Id,
                                                    sked__Duration__c = 50,
                                                    sked_Resource_Role__c = rll,
                                                    sked_Lead_Time__c = 5,
                                                    sked_Travel_Time__c = 5,
                                                    sked_Setup_Time__c = 5,
                                                    sked_Breakdown_Time__c = 5,
                                                    sked_Travel_Time2__c = 5,
                                                    sked_Wrap_up_Time__c = 5,
                                                    sked_Sponsor_Volunteer_Quantity__c = 1,
                                                    sked_Redcross_Volunteer_Quantity__c = 1,
                                                    sked_Start_Time__c = Datetime.now().time(),
                                                    sked_Finish_Time__c = Datetime.now().addMinutes(406).time(),
                                                    sked_Dual_Role__c = 'Driver');
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert skedjob;
            sked__Job__c skedjob1 = new sked__Job__c(sked_Drive_Shift__c = shiftData2.Id,
                                                    sked_Drive__c = testDrive2.Id,
                                                    sked__Region__c = reg.Id,
                                                    sked__Duration__c = 50,
                                                    sked_Resource_Role__c = rll,
                                                    sked_Lead_Time__c = 5,
                                                    sked_Travel_Time__c = 5,
                                                    sked_Setup_Time__c = 5,
                                                    sked_Breakdown_Time__c = 5,
                                                    sked_Travel_Time2__c = 5,
                                                    sked_Wrap_up_Time__c = 5,
                                                    sked_Sponsor_Volunteer_Quantity__c = 1,
                                                    sked_Redcross_Volunteer_Quantity__c = 1,
                                                    sked_Start_Time__c = Datetime.now().time(),
                                                    sked_Finish_Time__c = Datetime.now().addMinutes(406).time());
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert skedjob1;
            sked__Job__c skedjob2 = new sked__Job__c(sked_Drive_Shift__c = shiftData.Id,
                                                    sked_Drive__c = testDrive1.Id,
                                                    sked__Region__c = reg.Id,
                                                    sked__Duration__c = 50,
                                                    sked_Asset_Type__c = 'Vehicle',
                                                    sked__Type__c = 'Vehicle',
                                                    sked_Lead_Time__c = 5,
                                                    sked_Travel_Time__c = 5,
                                                    sked_Setup_Time__c = 5,
                                                    sked_Breakdown_Time__c = 5,
                                                    sked_Travel_Time2__c = 5,
                                                    sked_Wrap_up_Time__c = 5,
                                                    sked_Start_Time__c = Datetime.now().time(),
                                                    sked_Finish_Time__c = Datetime.now().addMinutes(406).time());
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert skedjob2;
            sked__Job__c skedjob3 = new sked__Job__c(sked_Drive_Shift__c = shiftData2.Id,
                                                    sked_Drive__c = testDrive2.Id,
                                                    sked__Region__c = reg.Id,
                                                    sked__Duration__c = 50,
                                                    sked_Asset_Type__c = 'Vehicle',
                                                    sked__Type__c = 'Vehicle',
                                                    sked_Lead_Time__c = 5,
                                                    sked_Travel_Time__c = 5,
                                                    sked_Setup_Time__c = 5,
                                                    sked_Breakdown_Time__c = 5,
                                                    sked_Travel_Time2__c = 5,
                                                    sked_Wrap_up_Time__c = 5,
                                                    sked_Start_Time__c = Datetime.now().time(),
                                                    sked_Finish_Time__c = Datetime.now().addMinutes(406).time());
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert skedjob3;
            sked__Job__c skedjob4 = new sked__Job__c(sked_Drive_Shift__c = shiftData2.Id,
                                                    sked_Drive__c = testDrive2.Id,
                                                    sked__Region__c = reg.Id,
                                                    sked__Duration__c = 50,
                                                    sked_Asset_Type__c = 'Equipment',
                                                    sked__Type__c = 'Equipment',
                                                    sked_Lead_Time__c = 5,
                                                    sked_Travel_Time__c = 5,
                                                    sked_Setup_Time__c = 5,
                                                    sked_Breakdown_Time__c = 5,
                                                    sked_Travel_Time2__c = 5,
                                                    sked_Wrap_up_Time__c = 5,
                                                    sked_Start_Time__c = Datetime.now().time(),
                                                    sked_Finish_Time__c = Datetime.now().addMinutes(406).time());
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert skedjob4;
            /*
            * HRP-10127 Changes starts here 
            * @Description: New test data added for HRP-10127 changes coverage
            */
            sked__Tag__c tagObj = new sked__Tag__c(Name = 'Inside',
                                                sked__Classification__c = 'Global',
                                                sked__Type__c = 'Physical Location Type'
                                                );

            insert tagObj;
            Assert.areEqual('Inside', tagObj.Name,' Name should match');

            Id staffRecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Staff').getRecordTypeId();
            sked__Resource__c resourcestaff = new sked__Resource__c(
                                                recordTypeId = staffRecordTypeId,
                                                sked__Email__c = 'fghjkl123@yupmail.com',
                                                sked_Employee_ID__c = '23456765',
                                                sked__Is_Active__c = true,
                                                sked_Title__c = 'Test',
                                                sked_First_Name__c = 'Barnojit',
                                                sked_Preferred_First_Name__c = 'barnojit',
                                                sked_Last_Name__c = 'testone',
                                                sked_ULID__c = 'ULID123',
                                                sked__Category__c = 'Employee',
                                                sked_Employment_Status__c = 'Active',
                                                sked_Timezone__c = 'America/Los_Angeles',
                                                sked__Resource_Type__c = 'Person',
                                                sked_Primary_Phone_Type__c = 'Home Phone',
                                                sked_Home_Phone__c = '123-123-4321',
                                                sked__Primary_Phone__c = '123-123-4321',
                                                sked_Address_Referenced_for_Scheduling__c = 'Work',
                                                sked_Mobile_Type__c = 'Inside',
                                                sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
                                                sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
                                                sked_Work_Country__c = 'USA',
                                                sked_Work_City__c = 'Sylmar',
                                                sked_Work_State__c = 'CA',
                                                sked_Work_Address_1__c = '11970 Gager St',
                                                sked_Work_Zip_Code__c = '91342',
                                                sked__Primary_Region__c = reg.Id
                                                );

            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            triggerHandler.bypass('ResourceTriggerHandler');
            insert resourcestaff;
            Assert.areEqual('Barnojit', resourcestaff.sked_First_Name__c,'Frist Name should match');

            Id vkRecordTypeId = Schema.SObjectType.sked__Resource__c.getRecordTypeInfosByName().get('Asset').getRecordTypeId();
            sked__Resource__c resourceVehicle = new sked__Resource__c(
                                                recordTypeId = vkRecordTypeId,
                                                sked_Asset_Type__c = 'Vehicle',
                                                sked__Resource_Type__c = 'Asset',
                                                sked_Element_Unit__c = '23456765',
                                                sked__Is_Active__c = true,
                                                sked_Long_Desc__c = 'toyota 4x',
                                                sked_Short_Desc__c = 'XUV4',
                                                sked__Category__c = 'ProMaster',
                                                sked_ULID__c = 'ULID124',
                                                sked_Timezone__c = 'America/Los_Angeles',
                                                sked_Primary_Phone_Type__c = 'Home Phone',
                                                sked_Home_Phone__c = '123-123-4322',
                                                sked__Primary_Phone__c = '123-123-4322',
                                                sked_Address_Referenced_for_Scheduling__c = 'Work',
                                                sked_Mobile_Type__c = 'Inside',
                                                sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
                                                sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
                                                sked_Work_Country__c = 'USA',
                                                sked_Work_City__c = 'Sylmar',
                                                sked_Work_State__c = 'CA',
                                                sked_Work_Address_1__c = '11970 Gager St',
                                                sked_Work_Zip_Code__c = '91342',
                								sked__Primary_Region__c = reg.Id
                                                );

            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            triggerHandler.bypass('ResourceTriggerHandler');
            insert resourceVehicle;
                        
            sked__Resource__c resourceEquipment = new sked__Resource__c(
                                                recordTypeId = vkRecordTypeId,
                                                sked_Asset_Type__c = 'Equipment',
                                                sked__Resource_Type__c = 'Asset',
                                                sked_Element_Unit__c = '23456766',
                                                sked__Is_Active__c = true,
                                                sked_Long_Desc__c = 'toyota 4x',
                                                sked_Short_Desc__c = 'XUV4',
                                                sked__Category__c = 'ProMaster',
                                                sked_ULID__c = 'ULID125',
                                                sked_Timezone__c = 'America/Los_Angeles',
                                                sked_Primary_Phone_Type__c = 'Home Phone',
                                                sked_Home_Phone__c = '123-123-4322',
                                                sked__Primary_Phone__c = '123-123-4322',
                                                sked_Address_Referenced_for_Scheduling__c = 'Work',
                                                sked_Mobile_Type__c = 'Inside',
                                                sked_Work_Address_GeoLocation__Latitude__s = 34.280308,
                                                sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
                                                sked_Work_Country__c = 'USA',
                                                sked_Work_City__c = 'Sylmar',
                                                sked_Work_State__c = 'CA',
                                                sked_Work_Address_1__c = '11970 Gager St',
                                                sked_Work_Zip_Code__c = '91342'
                                                );

            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            triggerHandler.bypass('ResourceTriggerHandler');
            insert resourceEquipment;
            String fgtyfyt = Custom_Report_Config__mdt.getInstance('DriveDispatchedNo').Value__c;
            sked__Job_Allocation__c joballc1 = new sked__Job_Allocation__c(
                sked__Job__c = skedjob.id,
                sked__Resource__c = resourcestaff.id,
                sked__Status__c = fgtyfyt.split(',')[0],
                sked_Start_Time__c = Time.newInstance(5, 0, 0, 0),
                sked_Set_End_Time__c = Time.newInstance(12, 0, 0, 0),
                sked_Additional_Roles__c = '2RBC Sign-off'
            );
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert joballc1;
            String effwffwf = Custom_Report_Config__mdt.getInstance('DriveDispatchedYes').Value__c;
            sked__Job_Allocation__c joballc3 = new sked__Job_Allocation__c(
                sked__Job__c = skedjob1.id,
                sked__Resource__c = resourcestaff.id,
                sked__Status__c = effwffwf.split(',')[0],
                sked_Start_Time__c = Time.newInstance(5, 0, 0, 0),
                sked_Set_End_Time__c = Time.newInstance(12, 0, 0, 0)
            );
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert joballc3;

            sked__Job_Allocation__c joballc2 = new sked__Job_Allocation__c(
                sked__Job__c = skedjob2.id,
                sked__Resource__c = resourceVehicle.id,
                sked__Status__c = 'Complete',
                sked_Start_Time__c = Time.newInstance(5, 0, 0, 0),
                sked_Set_End_Time__c = Time.newInstance(12, 0, 0, 0)
            );
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert joballc2;
            sked__Job_Allocation__c joballc4 = new sked__Job_Allocation__c(
                sked__Job__c = skedjob3.id,
                sked__Resource__c = resourceVehicle.id,
                sked__Status__c = 'Complete',
                sked_Start_Time__c = Time.newInstance(5, 0, 0, 0),
                sked_Set_End_Time__c = Time.newInstance(12, 0, 0, 0)
            );
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert joballc4;
            sked__Job_Allocation__c joballc5 = new sked__Job_Allocation__c(
                sked__Job__c = skedjob4.id,
                sked__Resource__c = resourceEquipment.id,
                sked__Status__c = 'Complete',
                sked_Start_Time__c = Time.newInstance(5, 0, 0, 0),
                sked_Set_End_Time__c = Time.newInstance(12, 0, 0, 0)
            );
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            insert joballc5;
            
            
            sked__Activity__c activity = new sked__Activity__c(
            sked__Resource__c = resourcestaff.Id,
            sked__Type__c = 'On Call',
            sked_Activity_Title__c = 'On Call 1',
            sked__Start__c = Datetime.now(),
            sked_Start_Date__c =  Date.today(),
            sked_End_Date__c =  Date.today().addDays(1),
            sked__End__c = Datetime.now().addDays(1),
            sked_Start_Time__c = Datetime.now().time(),
            sked_End_Time__c = Datetime.now().addMinutes(66).time(),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive__c = testDrive1.Id,
            sked_Region__c = reg.Id,
            sked__Address__c = 'Test Address',
            sked__Notes__c = 'Test notes',
            sked_Is_Group_Activity__c = true
            );
            skedHubBase.BypassInsertTriggers = true;
            insert activity;
            
            sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
                sked__Activity__c = activity.Id,
                sked__Resource__c = resourcestaff.Id
            );
            skedHubBase.BypassInsertTriggers = true;
            insert skedActivityResource;
            
            sked__Activity_Resource__c skedActivityResourceVehicle1 = new sked__Activity_Resource__c(
                sked__Activity__c = activity.Id,
                sked__Resource__c = resourceVehicle.Id,
                sked_Start_Date__c = System.today().addDays(1)
            );
            skedHubBase.BypassInsertTriggers = true;
            insert skedActivityResourceVehicle1;
            
            sked__Activity__c activity1 = new sked__Activity__c(
            sked__Resource__c = resourcestaff.Id,
            sked__Type__c = 'On Call',
            sked_Activity_Title__c = 'On Call 1',
            sked__Start__c = Datetime.now().addDays(1),
            sked_Start_Date__c =  Date.today().addDays(1),
            sked_End_Date__c =  Date.today().addDays(2),
            sked__End__c = Datetime.now().addDays(2),
            sked_Start_Time__c = Datetime.now().time(),
            sked_End_Time__c = Datetime.now().addMinutes(66).time(),
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Drive__c = testDrive2.Id,
            sked_Region__c = reg.Id,
            sked__Address__c = 'Test Address',
            sked__Notes__c = 'Test notes',
            sked_Is_Group_Activity__c = true
            );
            skedHubBase.BypassInsertTriggers = true;
            insert activity1;
            sked__Activity_Resource__c skedActivityResource1 = new sked__Activity_Resource__c(
                sked__Activity__c = activity1.Id,
                sked__Resource__c = resourcestaff.Id
            );
            skedHubBase.BypassInsertTriggers = true;
            insert skedActivityResource1;
            
            sked__Activity_Resource__c skedActivityResourceVehicle2 = new sked__Activity_Resource__c(
                sked__Activity__c = activity1.Id,
                sked__Resource__c = resourceVehicle.Id,
                sked_Start_Date__c = System.today().addDays(1)
            );
            skedHubBase.BypassInsertTriggers = true;
            insert skedActivityResourceVehicle2;
        }        
        
    }

}