/* 
 * @description: This batch runs dails to update portfolios in Accounts and Opportunities.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 02/21/2024                Barnojit Sharma	      DOC does not pull up AM and DM portfolio according to drive date. (HRP-11849)
 ************************************************************************************************************************************************
*/
@isTest
private class UpdateAMAndDMPortfolioDailyBatchTest {
    @TestSetup
    static void prepareDataset() {
        String mobileAccRecType = 'Mobile Account';
        String mobileOppRecType = 'Mobile Opp';
        String mobileSiteRecType = 'Mobile Site';
        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        recordTypeMap = recordTypeMap( 'Opportunity' );
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        
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
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
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
       User DRDAMUser1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last one',
            Email = 'puser0001@amamama.com',
            Username = 'puser0001@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST1',
            Title = 'title1',
            Alias = 'alias1',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
       );
       User DRDAMUser2 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Manager'].Id,
            LastName = 'last two',
            Email = 'puser0002@amamama.com',
            Username = 'puser0002@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST2',
            Title = 'title2',
            Alias = 'alias2',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
       User DRDDMUser = new User(
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
            List<User> userList = new List<User>();
            userList.add(DRDAMUser);
            userList.add(DRDDMUser);
            userList.add(DRDAMUser1);
            userList.add(DRDAMUser2);

            skedHubBase.BypassInsertTriggers = true;
            insert userList;
            Assert.isNotNull(userList[0].Id);

            DRDAMUser = userList.get(0);
            DRDDMUser = userList.get(1);
            DRDAMUser1 = userList.get(2);
            DRDAMUser2 = userList.get(3);
       }
       
       // create Account
       List<Account> mobileAccList = new List<Account>();
       
       Account accobj;        
       accobj = new Account();
       accobj.RecordTypeId = recTypeId;
       accobj.Name = 'Nestle UK';
       accobj.BillingPostalCode = '30146';
       accobj.Internal_Name__c  =   accobj.Name+1;    
       mobileAccList.add(accobj);
       
       accobj = new Account();
       accobj.RecordTypeId = recTypeId;
       accobj.Name = 'Nestle USA';
       accobj.BillingPostalCode = '30146';  
       accobj.Internal_Name__c  =   accobj.Name+1;
       mobileAccList.add(accobj);

       skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
       insert mobileAccList;
       Assert.isNotNull(mobileAccList[0].Id);

        List<BSF_Portfolio__c> bParentportfolioList = new List<BSF_Portfolio__c>();
        List<BSF_Portfolio__c> bportfolioList = new List<BSF_Portfolio__c>();
        BSF_Portfolio__c bportfolio ;
        
        // create BSF Portfolio data
        
        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Code__c = 'Non-Collection Area-54E';
        bportfolio.Portfolio_Type__c = 'District Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Account Portfolio';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Account_Based_Portfolio__c = true;
        bParentportfolioList.add( bportfolio );
        
        skedHubBase.BypassInsertTriggers = true;
        insert bParentportfolioList;
        system.debug('bParentportfolioList value :: '+bParentportfolioList[0].id);
        Assert.isNotNull(bParentportfolioList[0].Id);

        bportfolio = new BSF_Portfolio__c();
        bportfolio.Portfolio_Name__c = 'Non-Collection Area';
        bportfolio.Portfolio_Code__c = 'HProdSED_NCA';
        bportfolio.Portfolio_Type__c = 'Account Manager';
        bportfolio.Taxonomy_Type__c = 'Bio Recruitment CD';
        bportfolio.Start_Date__c = System.today()-5;
        bportfolio.End_Date__c = System.today()+5;
        bportfolio.Parent_Portfolio__c = bParentportfolioList[0].Id ;
        bportfolio.Account_Based_Portfolio__c = true;
        bportfolioList.add( bportfolio );

		skedHubBase.BypassInsertTriggers = true;
        insert bportfolio;
        Assert.isNotNull(bportfolio.Id);
        system.debug('bParentportfolioList value :: '+bportfolio.id);

        List<Account_Portfolio_Assignment__c> apassignmentlist = new List<Account_Portfolio_Assignment__c>();
        Account_Portfolio_Assignment__c apassign ;
        
        apassign = new Account_Portfolio_Assignment__c();
        apassign.Account__c = mobileAccList[0].Id;
        apassign.BSF_Portfolio__c = bportfolio.Id;
        apassign.Start_Date__c = System.today()-5;
        apassign.End_Date__c = System.today()+5;
        
        apassignmentlist.add( apassign );

        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert apassignmentlist;
        Assert.isNotNull(apassignmentlist[0].Id);

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

        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('ContactTriggerHandler');
        insert conObj;
        Assert.isNotNull(conObj.Id);

        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile_Site').getRecordTypeId();
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
        siteObj.sked__GeoLocation__latitude__s = 36.7450046;
        siteObj.sked__GeoLocation__longitude__s = -120.4816244;

        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;
        Assert.isNotNull(siteObj.Id);

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
        
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('OpportunityTriggerHandler');
        insert oppsobjlist;
        Assert.isNotNull(oppsobjlist[0].Id);
    }

    @isTest
    private static void testMethodOne(){

        List<Account_Portfolio_Assignment__c> apassignmentlist1 = [SELECT Account__c, CreatedDate, BSF_Portfolio__r.Taxonomy_Type__c, BSF_Portfolio__r.Portfolio_Type__c FROM Account_Portfolio_Assignment__c where BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio') AND (CreatedDate = today or LastModifiedDate = today)];
        
        test.startTest();
            String cronExpr = '0 0 0 15 3 ? 2022';
            System.schedule('UpdateAMAndDMPortfolioDailyBatch_' + String.valueOf(Datetime.now()), 
            '0 0 0 * * ?', new UpdateAMAndDMPortfolioDailyBatch());
        test.stopTest();

    }
    @isTest
    private static void testMethodTwo(){

        Test.startTest();
            UpdateAMAndDMPortfolioDailyBatch batchObject = new UpdateAMAndDMPortfolioDailyBatch();
            Database.executeBatch(batchObject,2);
        Test.stopTest();
    }
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
}