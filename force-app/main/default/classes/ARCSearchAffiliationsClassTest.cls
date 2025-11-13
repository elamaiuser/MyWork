/*
* This Test class covering the following Classes
* ARCSearchAffiliationsClass
*/

@isTest
private class ARCSearchAffiliationsClassTest {
    
    @testSetup 
    static void prepareDataset() {
       skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        List<BSF_Portfolio__c> bsfPortf = new List<BSF_Portfolio__c>();
        
        //insert Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        testMobileAccount.BillingPostalCode = '30146';
        insert testMobileAccount;
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        //insert mobile opportunity
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Parent_Template_Id__c = testTemplate.Id;
        insert testMobileOpp;
        
        BSF_Portfolio__c Portland_OR_AM_01 = new BSF_Portfolio__c();			
        Portland_OR_AM_01.Name='Wisconsin Region';
        Portland_OR_AM_01.Account_Based_Portfolio__c= true;			
        Portland_OR_AM_01.External_Key__c='Account_BD36_21E_NW_Portland OR_Portland OR ABM 01 03 07 08_Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Code__c='Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Name__c='Portland OR AM 01';
        Portland_OR_AM_01.Portfolio_Type__c='RDSE';
        Portland_OR_AM_01.Taxonomy_Type__c='Bio Account Portfolio';
        Portland_OR_AM_01.Territory_Portfolio__c=false;			
        bsfPortf.add(Portland_OR_AM_01);
            
        BSF_Portfolio__c Sickle_Cell_AM_04 = new BSF_Portfolio__c();
        Sickle_Cell_AM_04.Name='Test DRD Territory';
        Sickle_Cell_AM_04.Account_Based_Portfolio__c=true;
        Sickle_Cell_AM_04.External_Key__c='Sickle Cell_53E_SAM04';
        Sickle_Cell_AM_04.Portfolio_Code__c='SAM04';
        Sickle_Cell_AM_04.Portfolio_Name__c='Sickle Cell AM 04';
        Sickle_Cell_AM_04.Portfolio_Type__c='Account Manager';
        Sickle_Cell_AM_04.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
        Sickle_Cell_AM_04.Territory_Portfolio__c=false;
        bsfPortf.add(Sickle_Cell_AM_04);
        
        BSF_Portfolio__c Sickle_Cell_AM_05 = new BSF_Portfolio__c();
        Sickle_Cell_AM_05.Name='Test District 1';
        Sickle_Cell_AM_05.Account_Based_Portfolio__c=true;
        Sickle_Cell_AM_05.External_Key__c='Sickle Cell_53E_SAM05';
        Sickle_Cell_AM_05.Portfolio_Code__c='SAM05';
        Sickle_Cell_AM_05.Portfolio_Name__c='Sickle Cell AM 05';
        Sickle_Cell_AM_05.Portfolio_Type__c='District Manager';
        Sickle_Cell_AM_05.Taxonomy_Type__c='Bio Sickle Cell Portfolio';
        Sickle_Cell_AM_05.Territory_Portfolio__c=false;
        bsfPortf.add(Sickle_Cell_AM_05); 
        insert bsfPortf;
        
        // Create Collection Region
        Collections_Region__c clRegion;
        clRegion = new Collections_Region__c();
        clRegion.Name = 'Wisconsin Region';
        clRegion.Region_Code__c = '32E';
        insert clRegion;
        
        // create DRD Teritorry
        DRD_Territory__c dTeritory = new DRD_Territory__c();
        dTeritory.Name = 'Test DRD Territory';
        insert dTeritory;
        
        // create District
        District__c dst = new District__c() ;
        dst.Name = 'Test District 1';
        insert dst;
        
        // create Collection Teritorry
        Collections_Territory__c clTeritory;
        clTeritory = new Collections_Territory__c();
        clTeritory.Name = 'Dale, WI 54931';
        clTeritory.Zip__c = testMobileAccount.BillingPostalCode ;
        clTeritory.Region__c = clRegion.Id ;
        clTeritory.DRD_Territory2__c = dTeritory.Id ;
        clTeritory.District__c = dst.Id ;
        insert clTeritory;
        
        // Create Affiliation
        List<Marketing_Program__c> affiliationList = new List<Marketing_Program__c>();
        Marketing_Program__c affiliationobj;     
        
        // Nation wide Marketing Program == Yes and Scope  == Account
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_1';
        affiliationobj.External_Name__c = 'RSMO_1';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = 'N/A';
        affiliationobj.RecordTypeId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId();
        affiliationList.add(affiliationobj);
        
        // Nation wide Marketing Program == Yes and Scope  == Drive
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_2';
        affiliationobj.External_Name__c = 'RSMO_2';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = 'Mobile';
        affiliationobj.RecordTypeId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId();
        affiliationList.add(affiliationobj);
        
        // Nation wide Marketing Program == Yes and Scope  == Both
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_3';
        affiliationobj.External_Name__c = 'RSMO_3';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = '';
        affiliationobj.RecordTypeId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId();
        affiliationList.add(affiliationobj);
        
        // Nation wide Marketing Program == Yes and Scope  == Template
        affiliationobj  = new  Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_4';
        affiliationobj.External_Name__c = 'RSMO_4';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'Yes';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = '';
        affiliationobj.RecordTypeId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId();
        affiliationList.add(affiliationobj);
        
        
        // Nation wide Marketing Program == No and Scope  == Account
        affiliationobj  = new Marketing_Program__c();                                                       
        affiliationobj.Name = 'RSMO_5';
        affiliationobj.External_Name__c = 'RSMO_5';
        affiliationobj.Scope__c  = 'Drive';
        affiliationobj.Start_Date__c = System.today().addDays(-2);
        affiliationobj.End_Date__c = System.today().addDays(12) ;
        affiliationobj.Nationwide_Marketing_Program__c = 'No';
        affiliationobj.Allowed_Profiles__c = 'System Administrator';
        affiliationobj.Drive_Type__c = 'N/A';
        affiliationobj.RecordTypeId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId();
        affiliationList.add(affiliationobj);
        insert affiliationList;       
    }
    
    @isTest static void getAffiliationTypes_test() {
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            
            Account testAccount = [SELECT Id,BillingPostalCode FROM Account LIMIT 1];
            Opportunity testMobileOpp = [SELECT Id, Parent_Template_Id__c FROM Opportunity WHERE Is_Template__c = false LIMIT 1];
            
            ARCSearchAffiliationsClass.getAffiliationTypes(testAccount.Id, false); // Account 
            ARCSearchAffiliationsClass.getAffiliationTypes(testMobileOpp.Parent_Template_Id__c, true);  // Template
            ARCSearchAffiliationsClass.getAffiliationTypes(testMobileOpp.Id, false); //Opportunity
            
            // Get List Of Affiliation for Account
            List<ARCSearchAffiliationsClass.Affiliationwrapper> aflwraper = ARCSearchAffiliationsClass.getAffiliations(Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId(), testAccount.BillingPostalCode, testAccount.Id, false);
            List<ARCSearchAffiliationsClass.Affiliationwrapper> aflwraperDrive = ARCSearchAffiliationsClass.getAffiliations(Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId(), testAccount.BillingPostalCode, testMobileOpp.Id, false);
            
            List<Id> mpList = new List<Id>();
            List<sObject> sObjList = new List<sObject>();
            for(Marketing_Program__c mp:[Select Id, Nationwide_Marketing_Program__c from Marketing_Program__c]) {
                mpList.add(mp.Id);
                sObjList.add(mp);
            }
            
            ARCSearchAffiliationsClass.getDonorServiceDivision(mpList, new List<Id>{[Select Id from BSF_Portfolio__c WHERE Name = 'Wisconsin Region'].Id});
            ARCSearchAffiliationsClass.getDRDTeritorry(mpList, new List<Id>{[Select Id from BSF_Portfolio__c WHERE Name = 'Test DRD Territory'].Id});
            ARCSearchAffiliationsClass.getDistrict(mpList, new List<Id>{[Select Id from BSF_Portfolio__c WHERE Name = 'Test District 1'].Id});
            ARCSearchAffiliationsClass.getFilteredAffiliationList(sObjList, 'TRUE');
            ARCSearchAffiliationsClass.getNationalAffiliationList(Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Marketing Program').getRecordTypeId());
        } 
    } 
}