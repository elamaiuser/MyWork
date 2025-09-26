@isTest
public class TimeBlockComplianceReportControllerTest {
    private static Date today = Date.today();

    @TestSetup
    private static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, sObject> mapTestData = testDataSetup.createAndInsertCommonObjects();
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

        Biomed_Collection_Op_Center__c co1 = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');
        co1.Name = 'Collection Operation 1';
        insert co1;

        Biomed_Collection_Op_Center__c co2 = co1.clone(false, true, false, false);
        co2.Name = 'Collection Operation 2';
        insert co2;

        Time_Block__c tb1 = new Time_Block__c(Name = 'TB10', Start_Time__c = Time.newInstance(8, 0, 0, 0), End_Time__c = Time.newInstance(12, 0, 0, 0),Days_of_Week__c='Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday');
        Time_Block__c tb2 = new Time_Block__c(Name = 'TB20', Start_Time__c = Time.newInstance(12, 0, 0, 0), End_Time__c = Time.newInstance(16, 0, 0, 0),Days_of_Week__c='Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday');
        Time_Block__c tb3 = new Time_Block__c(Name = 'TB30', Start_Time__c = Time.newInstance(16, 0, 0, 0), End_Time__c = Time.newInstance(17, 30, 0, 0),Days_of_Week__c='Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday');
        insert new List<Time_Block__c>{tb1, tb2, tb3};

        co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        co2 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 2' LIMIT 1];

        List<Collection_Operation_Time_Block__c> coTimeBlocks = new List<Collection_Operation_Time_Block__c>{
            new Collection_Operation_Time_Block__c(Collection_Operation__c = co1.Id, Time_Block__c = tb1.Id, Effective_Start_Date__c = today.addDays(-10), Effective_End_Date__c = today.addDays(10)),
            new Collection_Operation_Time_Block__c(Collection_Operation__c = co1.Id, Time_Block__c = tb2.Id, Effective_Start_Date__c = today.addDays(-5), Effective_End_Date__c = null),
            new Collection_Operation_Time_Block__c(Collection_Operation__c = co2.Id, Time_Block__c = tb3.Id, Effective_Start_Date__c = today.addDays(-15), Effective_End_Date__c = today.addDays(15))
        };
        insert coTimeBlocks;

        sked_Territory_Collection_Operation__c territoryCollOp = new sked_Territory_Collection_Operation__c();
        territoryCollOp.sked_Start_Date__c = Date.today().addDays(-500);
        territoryCollOp.sked_End_Date__c =  Date.today().addDays(500);
        territoryCollOp.sked_Collection_Operation__c = co1.Id;
        territoryCollOp.sked_Territory__c = district.Id;
        TriggerHandler.bypass('TerritoryCollOpTriggerHandler');
        insert territoryCollOp;
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
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
            triggerHandler.bypass('DriveTriggerHandler');
            sked_Drive__c testDrive1 = new sked_Drive__c(Name = 'Test Drive',
                                                        sked_Collection_Operation__c = co1.Id,
                                                        sked_Drive_Date__c = System.today(),
                                                        sked_Drive_Site__c = siteObj.Id,
                                                        sked_Opportunity__c = oppsobjlist.get(0).Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
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
                                                        sked_Collection_Operation__c = co1.Id,
                                                        sked_Drive_Date__c = System.today().addDays(60),
                                                        sked_Drive_Site__c = siteObj.Id,
                                                        sked_Opportunity__c = oppsobjlist.get(1).Id,
                                                        sked_Type_of_Drive__c = 'Mobile',
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
                                                                    sked_Time_Block__c = tb1.Id,
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
                                                                     sked_Time_Block__c = tb2.Id,
                                                                    sked_Start_Time__c = Time.newInstance(7, 0, 0, 0),
                                                                    sked_End_Time__c = Time.newInstance(12, 0, 0, 0));
            insert shiftData2;
            sked__Region__c reg = new sked__Region__c(Name = 'ABCD',
                                                        sked__Timezone__c = UserInfo.getTimeZone().getID(),
                                                        sked_Biomed_Collection_Op_Center__c = co1.Id,
                                                     sked_Territory__c = district.Id );
            insert reg;
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            triggerHandler.bypass('ResourceTriggerHandler');
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            triggerHandler.bypass('OpportunityTriggerHandler');
            triggerHandler.bypass('JobAllocationTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;            
        }        
    }

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

    private static Map<String,Id> recordTypeMap(string obj) {
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }

    @isTest
    static void testSearchReportWithAllFilters() {
        // Fetch test data
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Time_Block__c tb = [SELECT Id FROM Time_Block__c WHERE Name = 'TB10' LIMIT 1];

        // Set parameters
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(1);
        List<String> coIds = new List<String>{ co.Id };
        List<String> driveStatusList = new List<String>{ 'Draft' };
        Boolean onlyViolations = false;
        List<String> timeBlockIds = new List<String>{ tb.Id };
        String accountManagerName = ''; 
        Test.startTest();
        TimeBlockComplianceReportController.DatableConfigWrapper wrapper =
            TimeBlockComplianceReportController.searchReport(
                startDate,
                endDate,
                coIds,
                driveStatusList,
                onlyViolations,
                timeBlockIds,
                accountManagerName
            );
        Test.stopTest();
        System.debug('Returned Rows: ' + wrapper.dataWrapper.size());
    }

    @isTest
    static void testGetTimeBlockPicklistByCO() {
        Biomed_Collection_Op_Center__c co = [
            SELECT Id FROM Biomed_Collection_Op_Center__c 
            WHERE Name = 'Collection Operation 1' LIMIT 1
        ];
        Collection_Operation_Time_Block__c cotb = [
            SELECT Time_Block__c 
            FROM Collection_Operation_Time_Block__c 
            WHERE Collection_Operation__c = :co.Id 
            LIMIT 1
        ];
        Test.startTest();
        List<Map<String, String>> options = TimeBlockComplianceReportController.getTimeBlockPicklistByCO(
            new List<String>{ co.Id }
        );
        Test.stopTest();
        System.debug('Returned Time Block options: ' + options);
    }

    @isTest
    static void testVFConstructorAndGetSummary() {
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1];
        Time_Block__c tb = [SELECT Id FROM Time_Block__c LIMIT 1];

        ApexPages.currentPage().getParameters().put('startdate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('enddate', String.valueOf(Date.today().addDays(1)));
        ApexPages.currentPage().getParameters().put('co', co.Id);
        ApexPages.currentPage().getParameters().put('driveStatusFilter', 'Draft');
        ApexPages.currentPage().getParameters().put('violationOnly', 'false');
        ApexPages.currentPage().getParameters().put('timeBlockFilter', tb.Id);
        ApexPages.currentPage().getParameters().put('accountManagerName', 'first1 last1');

        Test.startTest();
        TimeBlockComplianceReportController controller = new TimeBlockComplianceReportController();
        Test.stopTest();
    }
    @isTest
    static void testGetPaginatedData() {
        // Set parameters for controller constructor
        Biomed_Collection_Op_Center__c co = [SELECT Id FROM Biomed_Collection_Op_Center__c LIMIT 1];
        Time_Block__c tb = [SELECT Id FROM Time_Block__c LIMIT 1];

        ApexPages.currentPage().getParameters().put('startdate', String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('enddate', String.valueOf(Date.today().addDays(1)));
        ApexPages.currentPage().getParameters().put('co', co.Id);
        ApexPages.currentPage().getParameters().put('driveStatusFilter', 'Draft');
        ApexPages.currentPage().getParameters().put('violationOnly', 'false');
        ApexPages.currentPage().getParameters().put('timeBlockFilter', tb.Id);
        ApexPages.currentPage().getParameters().put('accountManagerName', '');

        Test.startTest();
        TimeBlockComplianceReportController controller = new TimeBlockComplianceReportController();
        List<List<Map<String, String>>> pages = controller.getPaginatedData();
        Test.stopTest();

        System.assertNotEquals(null, pages, 'Paginated data should not be null');
        System.debug('Number of pages returned: ' + pages.size());
        if (!pages.isEmpty()) {
            System.assert(!pages[0].isEmpty(), 'Each page should contain rows if data exists');
        }
    }
}