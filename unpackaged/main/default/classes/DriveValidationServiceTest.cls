/* @Description: This class is the test class of DriveValidationService class.
*/

@IsTest
public class DriveValidationServiceTest {
    @TestSetup
    static void makeData(){ 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        skedHubBase.BypassInsertTriggers = true;
        testMobileAccount.Type = 'Military';
        TriggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        Assert.isNotNull(testMobileAccount.Id,'Record not inserted.');
    
        sked__Tag__c tag = (sked__Tag__c)mapTestData.get('GLOBAL_TAG');
        insert tag;
        Assert.isNotNull(tag.Id,'Record not inserted.');
        
        sked__Location__c site = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        site.sked_Directions_From_CollectionOperation__c = null;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert site;
        Assert.isNotNull(site.Id,'Record not inserted.');

        Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testMobileAccount.id;
        templateOpp.Drive_Site__c = site.Id;
        templateOpp.Procedure_Projections_Template__c = 20;
        templateOpp.Projected_Registered_Donors_Template__c = 30;
        templateOpp.Staffing_Template__c = 40;
        templateOpp.Volunteers_Template__c = 10;
        templateOpp.WholeBloodProceduresProjectedTemplate__c = 50;
        templateOpp.Double_Red_Procedures_Projected_Template__c = 39;
        templateOpp.Anticipated_Registered_Donors_Template__c = 21;
        insert templateOpp;
        Assert.isNotNull(templateOpp.Id,'Record not inserted.');

        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.AccountId = testMobileAccount.id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Procedure_Projections_Template__c = 10;
        mobileOpportunityRecord.Drive_Date__c = System.Today().addDays(80);
        insert mobileOpportunityRecord;
        Assert.isNotNull(mobileOpportunityRecord.Id,'Record not inserted.');
        
    }
    @isTest
    private static void testmethod1(){
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE is_template__c = false];
        Test.startTest();
            DriveValidationService.validateOpportunityOnBanner(oppList.get(0).Id);
        Test.stopTest();
    }
    @isTest
    private static void testmethod4(){
        List<Opportunity> oppListTT = [SELECT Id, AccountId, Drive_Site__c FROM Opportunity WHERE is_template__c = true];
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE is_template__c = false];
        Opportunity optyObj1 ; // = new Opportunity();
            optyObj1 = new Opportunity();
            optyObj1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Mobile_Opp').getRecordTypeId();
            optyObj1.AccountId = oppListTT[0].AccountId;
            optyObj1.Drive_Site__c = oppListTT[0].Drive_Site__c;
            optyObj1.Name = 'Test Drive Test';
            optyObj1.StageName = 'Discovery'; 
            optyObj1.Drive_Status__c = 'Draft'; 
            optyObj1.CloseDate = System.Today().addDays(81);
            optyObj1.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
            optyObj1.End_Time__c =  Time.newInstance(18, 30, 2, 20);
            optyObj1.WB_Projected_Procedures__c = 1;
            optyObj1.X2RBC_Projected_Procedures__c = 1;
            optyObj1.Anticipated_Registered_Donors__c = 1;
            optyObj1.Drive_Date__c = System.Today().addDays(85);
            
            skedHubBase.BypassInsertTriggers = true;
            TriggerHandler.bypass('OpportunityTriggerHandler');
            
            insert optyObj1;
            Assert.isNotNull(optyObj1.Id,'Record not inserted.');

        Test.startTest();
            DriveValidationService.validateOpportunityOnBanner(oppList.get(0).Id);
        Test.stopTest();
    }
    @isTest
    private static void testmethod2(){
        List<Opportunity> oppList = [SELECT Id, AccountId, Drive_Site__c FROM Opportunity WHERE is_template__c = true];
        List<DriveValidationService.ValidatePlanADriveWrapper> wrapperList = new List<DriveValidationService.ValidatePlanADriveWrapper>();
        DriveValidationService.ValidatePlanADriveWrapper wrapper = new DriveValidationService.ValidatePlanADriveWrapper();
        wrapper.accountId = oppList.get(0).AccountId;
        wrapper.siteId = oppList.get(0).Drive_Site__c;
        wrapper.templateId = oppList.get(0).Id;
        wrapper.driveDate = Date.newInstance(2024,12,01);
        wrapper.siteTBD = false;
        wrapper.recurringDrive = null;
        wrapper.driveDateList = null;
        Test.startTest();
            DriveValidationService.validatePlanADrive(wrapperList);
        Test.stopTest();
    }

    @isTest
    private static void testmethod3(){
        List<Opportunity> oppList = [SELECT Id, AccountId, Drive_Site__c FROM Opportunity WHERE is_template__c = true];
        List<DriveValidationService.ValidatePlanADriveWrapper> wrapperList = new List<DriveValidationService.ValidatePlanADriveWrapper>();
        DriveValidationService.ValidatePlanADriveWrapper wrapper = new DriveValidationService.ValidatePlanADriveWrapper();
        wrapper.accountId = oppList.get(0).AccountId;
        wrapper.siteId = oppList.get(0).Drive_Site__c;
        wrapper.templateId = oppList.get(0).Id;
        wrapper.driveDate = Date.newInstance(2024,12,01);
        wrapper.siteTBD = false;
        wrapper.recurringDrive = true;
        wrapper.driveDateList = new List<Date>();
        date dtt = Date.newInstance(2024,12,01);
        for(Integer i=0 ; i < 10 ; i++ ){
            wrapper.driveDateList.add(dtt);
            dtt = dtt.addDays(80);
        }
        wrapperList.add(wrapper);
        Test.startTest();
            DriveValidationService.validatePlanADrive(wrapperList);
        Test.stopTest();
    }

    @isTest
    private static void testmethod5(){
        List<Opportunity> OppList = [SELECT Id, 
                                                AcceptblankMilitaryAuthNamePhone__c,
                                                Accept_56_Day_Rule_Violation__c,
                                                Drive_Date__c,
                                                AccountId,
                                                Account.Name,
                                                Account.Type,
                                                Account.Industry_Code__c,
                                                Account.Accepts_Automation2__c,
                                                Account.Internal_Name__c,
                                                Account.Military_Authority_Name__c,
                                                Account.Military_Authority_Phone__c,
                                                Account.RecordTypeId,
                                                Drive_Site__c,
                                                Drive_Site__r.Name,
                                                Drive_Site__r.RecordTypeId,
                                                Drive_Site__r.sked_Directions_From_CollectionOperation__c,
                                                Drive_Site__r.sked_Floor_Description__c,
                                                Drive_Site__r.sked_Outside_stairs__c,
                                                Drive_Site__r.sked_Physical_Location_Type__c,
                                                Drive_Site__r.sked_Site_Main_Phone__c,
                                                Drive_Site__r.sked_Automation_Suitability__c,
                                     			Drive_Site__r.sked_Staff_Personal_Parking_Directions__c,
                                                Drive_Site__r.sked_Room_Name__c,
                                                Drive_Site__r.sked_Site_Building_Name__c,
                                                Drive_Site__r.sked_Site_Contact__c,
                                                Drive_Site__r.Operation_Type__c,
                                                Drive_Site__r.sked_Inside_stairs__c
                                        FROM Opportunity
                                        WHERE is_template__c =false];
        DriveValidationService classObj = new DriveValidationService();
        classObj.oppId = OppList.get(0).Id;
        classObj.accRec = OppList.get(0).Account;
        classObj.siteRec = OppList.get(0).Drive_Site__r;
        classObj.driveDate = OppList.get(0).Drive_Date__c;
        classObj.acceptBlankMilitaryNamePhone = false;
        classObj.accept56DayRuleViolation = false;
        classObj.isFixedSite = true;

        Test.startTest();
            classObj.validateAccount();
            classObj.validateSite();
            classObj.oppId = null;
            classObj.checkAccept56DaysVoilation();
            classObj.getErrorMessageOnBanner();
            classObj.getErrorMessage();
        Test.stopTest();
    }
    @isTest
    private static void testmethod6(){
        Account accObj = new Account();
        accObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Account').getRecordTypeId();
        accObj.Name = 'Exavalu';
        accObj.BillingPostalCode = '30622';
        accObj.Internal_Name__c ='Exavalu'; 
        skedHubBase.BypassInsertTriggers = true;
        triggerHandler.bypass('AccountTriggerHandler');
        insert accObj;
        Assert.isNotNull(accObj.Id,'Record not inserted.');

        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Fixed_Site').getRecordTypeId();
        siteObj.Name = 'Test Site';
        siteObj.sked_Address_1__c = 'Test Site Address';
        siteObj.sked__Address__c = 'Test Site Address';
        siteObj.sked_City__c = 'Test Site City';
        siteObj.sked_State__c = 'Test Site State';
        siteObj.sked_Zip_Code__c = '4000';
        siteObj.sked_County__c = 'USA';
        siteObj.sked_Site_Building_Name__c = 'Test Site Building';
        //siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Room_Name__c = 'Room 15';
        //siteObj.sked_National_Name__c = 'AMERICA';
        siteObj.sked_Physical_Location_Type__c = 'Outside';
        //siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
        //siteObj.sked_Automation_Suitability__c = 'Suitable';
        siteObj.sked_Outside_stairs__c = 1;
        siteObj.sked_Inside_stairs__c = 2;
        siteObj.sked_Base_Description__c = 'test base description';
        siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
        siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
        siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
        //siteObj.sked_Site_Contact__c = conObj.Id;
        //siteObj.sked_Site_Main_Phone__c = '758-771-0091';
        //siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
        siteObj.sked_Pay_for_Parking__c = 'Other';
        siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.sked_Floor_Description__c='something';
        siteObj.Source__c = 'Custom New Form';
        siteObj.sked_Date_Site_Inspection_Completed__c = Date.today();
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert siteObj;
        Assert.isNotNull(siteObj.Id,'Record not inserted.');

        Opportunity optyObj1 ; // = new Opportunity();
        optyObj1 = new Opportunity();
        optyObj1.AccountId = accObj.Id;
        optyObj1.Drive_Site__c = siteObj.Id;
        optyObj1.Name = 'Test Drive Test';
        optyObj1.StageName = 'Discovery'; 
        optyObj1.Drive_Status__c = 'Draft'; 
        optyObj1.CloseDate = System.Today().addDays(81);
        optyObj1.Start_Time__c =  Time.newInstance(13, 30, 2, 20);
        optyObj1.End_Time__c =  Time.newInstance(18, 30, 2, 20);
        optyObj1.WB_Projected_Procedures__c = 1;
        optyObj1.X2RBC_Projected_Procedures__c = 1;
        optyObj1.Anticipated_Registered_Donors__c = 1;
        optyObj1.Drive_Date__c = System.Today().addDays(85);
        optyObj1.is_template__c = true;
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        insert optyObj1;
        Assert.isNotNull(optyObj1.Id,'Record not inserted.');

        List<DriveValidationService.ValidatePlanADriveWrapper> wrapperList = new List<DriveValidationService.ValidatePlanADriveWrapper>();
        DriveValidationService.ValidatePlanADriveWrapper wrapper = new DriveValidationService.ValidatePlanADriveWrapper();
        wrapper.accountId = accObj.Id;
        wrapper.siteId = siteObj.Id;
        wrapper.templateId = optyObj1.Id;
        wrapper.driveDate = Date.newInstance(2024,12,01);
        wrapper.siteTBD = false;
        wrapper.recurringDrive = true;
        wrapper.driveDateList = new List<Date>();
        date dtt = Date.newInstance(2024,12,01);
        for(Integer i=0 ; i < 10 ; i++ ){
            wrapper.driveDateList.add(dtt);
            dtt = dtt.addDays(80);
        }
        wrapperList.add(wrapper);
        Test.startTest();
            DriveValidationService.validatePlanADrive(wrapperList);
        Test.stopTest();
    }

    @isTest
    private static void testmethod7(){
        DriveValidationService classObj = new DriveValidationService();
        classObj.accRec = new Account();
        classObj.siteRec = new sked__Location__c();
        classObj.siteRec.RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile_Site').getRecordTypeId();
        classObj.driveDate = System.Today().addDays(1);
        Test.startTest();
            try{
                classObj.validateAccount();
                classObj.validateSite();
                classObj.checkAccept56DaysVoilation();
                classObj.getErrorMessageOnBanner();
                classObj.getErrorMessage();
            }catch(Exception ex){}
        Test.stopTest();
    }
    @isTest
    private static void testmethod8(){
        List<Opportunity> oppList = [SELECT Id, AccountId, Drive_Site__c FROM Opportunity WHERE is_template__c = true];
        List<DriveValidationService.ValidatePlanADriveWrapper> wrapperList = new List<DriveValidationService.ValidatePlanADriveWrapper>();
        DriveValidationService.ValidatePlanADriveWrapper wrapper = new DriveValidationService.ValidatePlanADriveWrapper();
        wrapper.accountId = oppList.get(0).AccountId;
        wrapper.driveDate = Date.newInstance(2024,12,01);
        wrapper.siteTBD = true;
        wrapper.recurringDrive = false;
        wrapperList.add(wrapper);
        Test.startTest();
            DriveValidationService.validatePlanADrive(wrapperList);
        Test.stopTest();
    }
    @isTest
    private static void testmethod9(){
        DriveValidationService classObj = new DriveValidationService();
        classObj.accRec = new Account();
        classObj.siteRec = new sked__Location__c();
        classObj.siteRec.RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile_Site').getRecordTypeId();
        classObj.driveDate = System.Today().addDays(1);
        Test.startTest();
            try{
                classObj.validateAccount();
                //classObj.validateSite();
                classObj.checkAccept56DaysVoilation();
                classObj.getErrorMessageOnBanner();
                classObj.getErrorMessage();
            }catch(Exception ex){}
        Test.stopTest();
    }
    @isTest
    private static void testmethod10(){
        DriveValidationService classObj = new DriveValidationService();
        classObj.accRec = new Account();
        classObj.siteRec = new sked__Location__c();
        classObj.siteRec.RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByDeveloperName().get('sked_Mobile_Site').getRecordTypeId();
        classObj.driveDate = System.Today().addDays(1);
        Test.startTest();
            try{
                //classObj.validateAccount();
                classObj.validateSite();
                classObj.checkAccept56DaysVoilation();
                classObj.getErrorMessageOnBanner();
                classObj.getErrorMessage();
            }catch(Exception ex){}
        Test.stopTest();
    }
}