@isTest
public class CalendarBuildEvaluateDrivesBatch_Test {
    
    public static Biomed_Collection_Op_Center__c testCollectionOperation;
    public static sked_Staffing_Decision_Matrix__c testStaffingDecisionMatrix;
    public static sked_Lunch_Break_Setting__c testLunchBreakSetting;
    public static Account testMobileAccount;
    public static sked__Tag__c testUSCitizenTag;
    public static sked__Tag__c testSpanishTag;
    public static sked__Tag__c testLiftGateTag;
    public static User testDrdUser;
    public static AccountTeamMember testAccountTeamMemberMobile;
    public static sked__Region__c testRegion;
    public static sked_Collection_Operation_SDM__c testCollectionOperationSDM;
    public static sked_Lunch_Break_Definition__c testLunchBreakDefiniton;
    public static sked__Account_Tag__c testMobileAccountTagUsCitizen;
    public static sked__Account_Tag__c testMobileAccountTagSpanish;
    public static Collections_Region__c testDonorServicesRegion;
    public static Collections_Territory__c testRegionTerritory;
    public static sked__Location__c testMobileSite;
    public static Opportunity testMobileTemplateOpp;
    public static sked_Site_Collection_Operation__c testMobileSiteCollectionOperation;
    public static Opportunity testMobileOpp;
    //Fixed site account
    public static Account testFixedAccount;
    public static AccountTeamMember testAccountTeamMemberFixed;
    public static sked__Location__c testFixedSite;
    public static sked__Account_Tag__c testFixedAccountTagUsCitizen;
    public static sked__Account_Tag__c testFixedAccountTagSpanish;
    public static sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection1;
    public static sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection2;
    public static sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection3;
    public static sked_Fixed_Site_Procedure_Projection__c fixedSiteProcedureProjection4;
    public static sked_Site_Collection_Operation__c testFixedSiteCollectionOperation;
    public static Opportunity testFixedTemplateOpp;
    public static Opportunity testFixedOpp;
    
    @isTest
	static void testGenerateMobileDrive_GraySkies() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        createAccount();
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
		
        testMobileOpp.Drive_Designations__c = 'Gray Skies';
        createMobileOppRecord();
        
        Test.startTest();
           	CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        	Database.executeBatch(cbDrive);
        Test.stopTest();
        //TODO:  perform assertions 
    } 
    
    @isTest
	static void testGenerateMobileDrive_AccountSunset() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        
        testMobileAccount.Account_Strategy__c = 'Sunset';
        createAccount();
        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createMobileOppRecord();
        
        Test.startTest();
           	CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        	Database.executeBatch(cbDrive);
        Test.stopTest();
        //TODO:  perform assertions 
    } 
  
    @isTest
	static void testGenerateMobileDrive_AccountLostDefunct() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        
        createAccount();
        testMobileAccount.Account_Status__c = 'Lost';
        testMobileAccount.Lost_Reason__c = 'Other';
        update testMobileAccount;
        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createMobileOppRecord();
                
        Test.startTest();
           	CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        	Database.executeBatch(cbDrive);
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
    @isTest
	static void testGenerateMobileDrive_Error() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        
        createAccount();
        testMobileAccount.Account_Status__c = 'Lost';
        testMobileAccount.Lost_Reason__c = 'Other';
        update testMobileAccount;
        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createMobileOppRecord();
                
        Test.startTest();
         	Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        	Integer numOfDays = mdtDriveCompletion?.Number_Of_Days__c.intValue();
          
        	List<Opportunity> opps = [SELECT id, name, stagename, Drive_Date__c, bypass_validation_rule__c, CloseDate FROM Opportunity];
        	opps[0].bypass_validation_rule__c = true;
        	opps[0].Drive_Date__c = System.today().addDays(-numOfDays);
        	update opps;
        
        	List<Opportunity> updatedOpps = [SELECT id, name, stagename, Drive_Date__c, bypass_validation_rule__c, CloseDate FROM Opportunity];
        	updatedOpps[0].CloseDate = System.today().addDays(-numOfDays + 1);
        	system.debug('###ALI Test2 ' + opps[0].Drive_Date__c + ' - ' + opps[0].CloseDate + ' -- ' + opps[0].bypass_validation_rule__c);
        	TriggerHandler.bypass('OpportunityTriggerHandler');
        	update updatedOpps;
        
        	List<Opportunity> updatedOpps2 = [SELECT id, name, stagename, Drive_Date__c, bypass_validation_rule__c, CloseDate FROM Opportunity];
        	updatedOpps2[0].bypass_validation_rule__c = false;
        	update updatedOpps2;
        
           	CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        	Database.executeBatch(cbDrive);
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
    @isTest
	static void testGenerateMobileDrive_TestSchedulableDraftDrives() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        
        createAccount();        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createMobileOppRecord();
                
        Test.startTest();
        	CalendarBuildUpdateDrivesBatch tsc = new CalendarBuildUpdateDrivesBatch();
        	tsc.batchSize = 1;
			String chron = '0 0 23 * * ?';        
         	system.schedule('Test Sched', chron, tsc);
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
    @isTest
	static void testGenerateMobileDrive_UpdateToSystemGen() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        createAccount();        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createDraftMobileOppRecord();
        
        Test.startTest();
			CalendarBuildUpdateDrivesBatch cbDriveUpdate = new CalendarBuildUpdateDrivesBatch();
        	Database.executeBatch(cbDriveUpdate, 1);
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
	@isTest
	static void testGenerateMobileDrive_TestSchedulableSystemGen() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        createAccount();        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createDraftMobileOppRecord();
        
        Test.startTest();
			CalendarBuildUpdateDrivesBatch tsc = new CalendarBuildUpdateDrivesBatch();
        	tsc.batchSize = 1;
			String chron = '0 0 23 * * ?';        
         	system.schedule('Test Sched', chron, tsc);
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
    @isTest
    static void test2() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        insert testFixedAccount;
        insert testFixedSite;
		testFixedOpp.AccountId = testFixedAccount.Id;
        system.debug(':::Site: ' + testFixedSite);
        testFixedOpp.Drive_Site__c = testFixedSite.Id;
		testFixedOpp.Drive_Status__c = 'Complete';
        testFixedOpp.CloseDate = system.today().addDays(-5);
        testFixedOpp.Drive_Date__c = System.today().addDays(-3);
        testFixedOpp.Drive_Site__c = testMobileSite.Id;
		testFixedOpp.End_Time__c = Time.newInstance(21, 0, 0, 0);
        testFixedOpp.StageName = 'Discovery';
        testFixedOpp.Start_Time__c = Time.newInstance(12, 0, 0, 0);
        test.startTest();
        	insert testFixedOpp;
        test.stopTest();
    }
    
   	/*@isTest
	static void testGenerateFixedDrive() {
        
        //Add comment about which records are getting created
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        initiateAllDriveData();
        createDrdUser();
        createFixedSiteAccount();
        createFirstSetOfRecordsForAll();
        createFirstSetOfRecordsFixed();
        createSecondSetOfRecordsFixed();
        createThirdSetOfRecordsFixed();
        createFixedOppRecord();
        
        Test.startTest();
           	CalendarBuildEvaluateDrivesBatch cbDrive = new CalendarBuildEvaluateDrivesBatch();
        	Database.executeBatch(cbDrive);
        Test.stopTest();
        //TODO:  perform assertions 
    }*/
    
    @isTest
	static void testGenerateFixedDrive_Error() {
        
        //Add comment about which records are getting created
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        initiateAllDriveData();
        createDrdUser();
        createFixedSiteAccount();
        createFirstSetOfRecordsForAll();
        createFirstSetOfRecordsFixed();
        createSecondSetOfRecordsFixed();
        createThirdSetOfRecordsFixed();
        createFixedOppRecord();
        
        Test.startTest();
        	          
        	List<Opportunity> opps = [SELECT id, name, stagename, Drive_Status__c, Drive_Date__c, AccountId, CloseDate FROM Opportunity];
  
          	Map<Id, String> dml_error_map = new Map<id, String>();
        	dml_error_map.put(opps[0].id, 'test class');
        	CalendarBuildEvaluateDrivesBatch.sendErrorNotification(null, dml_error_map);
    
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
	@isTest
	static void testGenerateMobileDrive_TestMobileDraftDrivesViaAura() {
      
       	TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        initiateAllDriveData();
        createDrdUser();
        
        createAccount();        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createMobileOppRecord();
                
        Test.startTest();
			Id jobId = CalendarBuildBatchOnDemandController.executeBatchJob();
        	AsyncApexJob apexJob = CalendarBuildBatchOnDemandController.getBatchJobStatus(jobId);
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
    @isTest
	static void testGenerateMobileDrive_TestMobileUpdateDrivesViaAura() {
      
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        
        initiateAllDriveData();
        createDrdUser();
        
        createAccount();        
        createFirstSetOfRecordsForAll();
        createSecondSetOfRecordsMobile();
        createThirdSetOfRecordsMobile();
        createFourthSetOfRecordsMobile();
        createMobileOppRecord();
                
        Test.startTest();
			Id jobId = CalendarBuildBatchOnDemandController.executeBatchUpdateJob();
        	AsyncApexJob apexJob = CalendarBuildBatchOnDemandController.getBatchJobStatus(jobId);
        	Integer draftBatchSize = CalendarBuildBatchOnDemandController.getDraftDrivesBatchSize();
        	Integer sysGenBatchSize = CalendarBuildBatchOnDemandController.getSysGenDrivesBatchSize();
        Test.stopTest();
        //TODO:  perform assertions 
    }
    
    private static void initiateAllDriveData() {
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
      
        testDrdUser = (User)mapTestData.get('DRD_USER');      
        testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT'); 
        testCollectionOperation = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');  
        testStaffingDecisionMatrix = (sked_Staffing_Decision_Matrix__c)mapTestData.get('STAFFING_DECISION_MATRIX');
        testLunchBreakSetting = (sked_Lunch_Break_Setting__c)mapTestData.get('LUNCH_BREAK_SETTING');
        testUSCitizenTag = (sked__Tag__c)mapTestData.get('US_CITIZEN_TAG');
        testSpanishTag = (sked__Tag__c)mapTestData.get('SPANISH_TAG');
        testLiftGateTag = (sked__Tag__c)mapTestData.get('LIFT_GATE_TAG');
     	testAccountTeamMemberMobile = (AccountTeamMember)mapTestData.get('ACCOUNT_TEAM_MEMBER_MOBILE');
        testRegion = (sked__Region__c)mapTestData.get('SKED_REGION');
		testCollectionOperationSDM = (sked_Collection_Operation_SDM__c)mapTestData.get('COLLECTION_OPERATION_SDM');
        testLunchBreakDefiniton = (sked_Lunch_Break_Definition__c)mapTestData.get('LUNCH_BREAK_DEFINITION');
		testMobileAccountTagUsCitizen = (sked__Account_Tag__c)mapTestData.get('MOBILE_ACCOUNT_TAG_USCITIZEN');
  		testMobileAccountTagSpanish = (sked__Account_Tag__c)mapTestData.get('MOBILE_ACCOUNT_TAG_SPANISH');
        testDonorServicesRegion = (Collections_Region__c)mapTestData.get('DONOR_SERVICES_REGION');
 		testRegionTerritory = (Collections_Territory__c)mapTestData.get('COLLECTION_TERRITORY_REGION');
		testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
       	testMobileTemplateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
		testMobileSiteCollectionOperation = (sked_Site_Collection_Operation__c)mapTestData.get('MOBILE_SITE_COLLECTION_OPERATION');
        testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        
        /* Fixed site drive */
        testFixedAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testAccountTeamMemberFixed = (AccountTeamMember)mapTestData.get('ACCOUNT_TEAM_MEMBER_FIXED');
        testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        testFixedAccountTagUsCitizen = (sked__Account_Tag__c)mapTestData.get('FIXED_ACCOUNT_TAG_USCITIZEN');
        testFixedAccountTagSpanish = (sked__Account_Tag__c)mapTestData.get('FIXED_ACCOUNT_TAG_SPANISH');
        fixedSiteProcedureProjection1 = (sked_Fixed_Site_Procedure_Projection__c)mapTestData.get('FIXED_SITE_PROJECTION1');
        fixedSiteProcedureProjection2 = (sked_Fixed_Site_Procedure_Projection__c)mapTestData.get('FIXED_SITE_PROJECTION2');
        fixedSiteProcedureProjection3 = (sked_Fixed_Site_Procedure_Projection__c)mapTestData.get('FIXED_SITE_PROJECTION3');
        fixedSiteProcedureProjection4 = (sked_Fixed_Site_Procedure_Projection__c)mapTestData.get('FIXED_SITE_PROJECTION4');
		testFixedSiteCollectionOperation = (sked_Site_Collection_Operation__c)mapTestData.get('FIXED_SITE_COLLECTION_OPERATION');
        testFixedTemplateOpp = (Opportunity)mapTestData.get('FIXED_TEMPLATE_OPP');
        testFixedOpp = (Opportunity)mapTestData.get('FIXED_OPP');
    }
    
    private static void createDrdUser() {
        system.runAs(new User(Id = UserInfo.getUserId())) {
            insert testDrdUser;
        }
    }
    
    private static void createAccount() {
        insert testMobileAccount;
    }
    
    /***** Create collection opp, sdm, lunch break, and tag records *****/
    private static void createFirstSetOfRecordsForAll() {
        List<sObject> firstList = new List<sObject>();
		firstList.add(testCollectionOperation);
        firstList.add(testStaffingDecisionMatrix);
		firstList.add(testLunchBreakSetting);
		firstList.add(testUSCitizenTag);        
		firstList.add(testSpanishTag);
        firstList.add(testLiftGateTag);
		insert firstList;	
    }
    
    /***** Create account team member, region, collection op SDM, lunch break definition, and account tag records *****/
    private static void createSecondSetOfRecordsMobile() {
        List<sObject> secondList = new List<sObject>();    
        testAccountTeamMemberMobile.AccountId = testMobileAccount.Id;
        testAccountTeamMemberMobile.UserId = testDrdUser.Id;
        secondList.add(testAccountTeamMemberMobile);
        
        testRegion.sked_Biomed_Collection_Op_Center__c = testCollectionOperation.Id;
        secondList.add(testRegion);
        
        testCollectionOperationSDM.sked_Collection_Operation__c = testCollectionOperation.Id;
        testCollectionOperationSDM.sked_Staffing_Decision_Matrix__c = testStaffingDecisionMatrix.Id;
        secondList.add(testCollectionOperationSDM);
        
        testLunchBreakDefiniton.sked_Lunch_Break_Setting__c = testLunchBreakSetting.Id;
        secondList.add(testLunchBreakDefiniton);
        
        testMobileAccountTagUsCitizen.sked__Account__c = testMobileAccount.Id;
        testMobileAccountTagUsCitizen.sked__Tag__c = testUsCitizenTag.Id; 
        //secondList.add(testMobileAccountTagUsCitizen);
        
        testMobileAccountTagSpanish.sked__Account__c = testMobileAccount.Id;
        testMobileAccountTagSpanish.sked__Tag__c = testSpanishTag.Id;  
        //secondList.add(testMobileAccountTagSpanish);
        secondList.add(testDonorServicesRegion);
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        insert secondList;
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
    }
    
    /***** Create territory region and site records *****/
    private static void createThirdSetOfRecordsMobile() {
		List<sObject> thirdList = new List<sObject>();
        testRegionTerritory.Region__c = testDonorServicesRegion.Id;
        thirdList.add(testRegionTerritory);
        
        testMobileSite.sked__Region__c = testRegion.Id;
		testMobileSite.sked_Collection_Operation__c = testCollectionOperation.Id;
        thirdList.add(testMobileSite);
        insert thirdList;
    }
    
    /***** Create template opp and site collection opp records *****/
    private static void createFourthSetOfRecordsMobile() {
       	List<sObject> fourthList = new List<sObject>();
        testMobileTemplateOpp.AccountId = testMobileAccount.Id;
        testMobileTemplateOpp.Drive_Site__c = testMobileSite.Id;
        fourthList.add(testMobileTemplateOpp);
        
        testMobileSiteCollectionOperation.sked_Collection_Operation__c = testCollectionOperation.Id;
        testMobileSiteCollectionOperation.sked_Site__c = testMobileSite.Id;
        testMobileSiteCollectionOperation.sked_Collections_Zip_Code__c = testRegionTerritory.Id;
        testMobileSiteCollectionOperation.sked_Region__c = testRegion.Id;
        fourthList.add(testMobileSiteCollectionOperation);
        insert fourthList;
    }
    
    private static void createMobileOppRecord() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.Number_Of_Days__c.intValue();
          
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Parent_Template_Id__c = testMobileTemplateOpp.Id;
		testMobileOpp.Drive_Status__c = 'Complete';
        testMobileOpp.CloseDate = system.today().addDays(-numOfDays-1);
        testMobileOpp.Drive_Date__c = System.today().addDays(-numOfDays);
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
		testMobileOpp.End_Time__c = Time.newInstance(21, 0, 0, 0);
        testMobileOpp.StageName = 'Solicitation';
        testMobileOpp.Start_Time__c = Time.newInstance(12, 0, 0, 0);
        testMobileOpp.Rollover_Consideration__c = '';
        insert testMobileOpp;
    }
    
    private static void createDraftMobileOppRecord() {

        //Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Days_After_Drive_Completion');
        //Integer numOfDays = mdtDriveCompletion?.Number_Of_Days__c.intValue();
        
        testMobileOpp.AccountId = testMobileAccount.Id;
        testMobileOpp.Parent_Template_Id__c = testMobileTemplateOpp.Id;
        testMobileOpp.Drive_Site__c = testMobileSite.Id;
        testMobileOpp.Drive_Status__c = 'draft';
        testMobileOpp.Rollover_Consideration__c = '';
        testMobileOpp.Source__c = 'Calendar Build';
        testMobileOpp.Drive_Date__c = system.today().toStartOfMonth().addDays(-1);
        testMobileOpp.CloseDate = system.today().addDays(-40);
        testMobileOpp.End_Time__c = Time.newInstance(21, 0, 0, 0);
        testMobileOpp.StageName = 'Solicitation';
        testMobileOpp.Rollover_Consideration__c = '';
        testMobileOpp.Start_Time__c = Time.newInstance(12, 0, 0, 0);
        testMobileOpp.Rollover_Consideration__c = '';
        insert testMobileOpp;
    }
   
    /*** Fixed  ***/
  	private static void createFixedSiteAccount() {
        insert testFixedAccount;
    }
    
    private static void createFirstSetOfRecordsFixed() {
        
       	List<sObject> firstFixedList = new List<sObject>();
        testRegion.sked_Biomed_Collection_Op_Center__c = testCollectionOperation.Id;
        firstFixedList.add(testRegion);
        
        testFixedAccountTagUsCitizen.sked__Account__c = testFixedAccount.Id;
        testFixedAccountTagUsCitizen.sked__Tag__c = testUsCitizenTag.Id; 
        //firstFixedList.add(testFixedAccountTagUsCitizen);
        
        testFixedAccountTagSpanish.sked__Account__c = testFixedAccount.Id;
        testFixedAccountTagSpanish.sked__Tag__c = testSpanishTag.Id;  
        //firstFixedList.add(testFixedAccountTagSpanish);
        
        fixedSiteProcedureProjection1.sked_Account__c = testFixedAccount.Id;
        firstFixedList.add(fixedSiteProcedureProjection1);
        
        fixedSiteProcedureProjection2.sked_Account__c = testFixedAccount.Id;
        firstFixedList.add(fixedSiteProcedureProjection2);
        
        fixedSiteProcedureProjection3.sked_Account__c = testFixedAccount.Id;
        firstFixedList.add(fixedSiteProcedureProjection3);
        
        fixedSiteProcedureProjection4.sked_Account__c = testFixedAccount.Id;
        firstFixedList.add(fixedSiteProcedureProjection4);
        insert firstFixedList;
    }
    
     private static void createSecondSetOfRecordsFixed() {
        
       	List<sObject> secondFixedList = new List<sObject>();
        testAccountTeamMemberFixed.AccountId = testFixedAccount.Id;
        testAccountTeamMemberFixed.UserId = testDrdUser.Id;
        secondFixedList.add(testAccountTeamMemberFixed);
         
        testFixedSite.sked__Region__c = testRegion.Id;
        testFixedSite.sked_Collection_Operation__c = testCollectionOperation.Id;
        secondFixedList.add(testFixedSite);
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        insert secondFixedList;   
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
    }
    
    private static void createThirdSetOfRecordsFixed() {
        
		List<sObject> thirdFixedList = new List<sObject>();
        testFixedTemplateOpp.AccountId = testFixedAccount.Id;
        testFixedTemplateOpp.Drive_Site__c = testFixedSite.Id;
        thirdFixedList.add(testFixedTemplateOpp);
        
        testFixedSiteCollectionOperation.sked_Collection_Operation__c = testCollectionOperation.Id;
        testFixedSiteCollectionOperation.sked_Site__c = testFixedSite.Id;
        testFixedSiteCollectionOperation.sked_Collections_Zip_Code__c = testRegionTerritory.Id;
        testFixedSiteCollectionOperation.sked_Region__c = testRegion.Id; 
		thirdFixedList.add(testFixedSiteCollectionOperation);
        insert thirdFixedList;
    }
    
	private static void createFixedOppRecord() {
		testFixedOpp.AccountId = testFixedAccount.Id;
        testFixedOpp.Parent_Template_Id__c = testFixedTemplateOpp.Id;
		testFixedOpp.Drive_Status__c = 'Complete';
        testFixedOpp.CloseDate = system.today().addDays(-5);
        testFixedOpp.Drive_Date__c = System.today().addDays(-3);
        testFixedOpp.Drive_Site__c = testMobileSite.Id;
		testFixedOpp.End_Time__c = Time.newInstance(21, 0, 0, 0);
        testFixedOpp.StageName = 'Solicitation';
        testFixedOpp.Start_Time__c = Time.newInstance(12, 0, 0, 0);
        insert testFixedOpp;
    }
    
	private static void setupFixedDriveData() {
             
        /*
        sked_Lunch_Break_Definition__c setting30definition2 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 90,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 3,
            sked_Min_Number_of_Staff__c = 3,
            sked_Slot_Reduction__c = 33.33
        );
        secondList.add(setting30definition2);
        
        sked_Lunch_Break_Definition__c setting30definition3 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 120,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 8,
            sked_Min_Number_of_Staff__c = 4,
            sked_Slot_Reduction__c = 25
        );
        secondList.add(setting30definition3);
        
        sked_Lunch_Break_Definition__c setting30definition4 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 150,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 16,
            sked_Min_Number_of_Staff__c = 9,
            sked_Slot_Reduction__c = 20
        );
        secondList.add(setting30definition4);
        
        sked_Lunch_Break_Definition__c setting30definition5 = new sked_Lunch_Break_Definition__c(
            sked_Lunch_Break_Duration__c = 180,
            sked_Lunch_Break_Setting__c = lunchBreakSetting30.Id,
            sked_Max_Number_of_Staff__c = 999,
            sked_Min_Number_of_Staff__c = 17,
            sked_Slot_Reduction__c = 16.67
        );
        secondList.add(setting30definition5); */
       
        
        /***** Third list ****/
        //List<sObject> thirdList = new List<sObject>();

        /*
        for (integer i = 1; i <= 5; i++) {
            sked__Resource__c testVehicle = new sked__Resource__c(
                Name = 'Test Vehicle ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Vehicle',
                sked_Pres_Donor_Capacity__c = 50,
                sked__Is_Active__c = TRUE
            );
            thirdList.add(testVehicle);
            mapTestData.put('testVehicle' + i, testVehicle);
        } */
        
        /*
        for (integer i = 1; i <= 10; i++) {
            sked__Resource__c test2rbcAsset = new sked__Resource__c(
                Name = 'Test 2RBC ' + i,
                sked__Primary_Region__c = testRegion1.Id,
                sked__Resource_Type__c = 'Asset',
                sked_Asset_Type__c = 'Equipment', 
                sked_Equipment_Subtype__c = '2RBC Asset',
                sked__Is_Active__c = TRUE
            );
            thirdList.add(test2rbcAsset);
            mapTestData.put('test2rbcAsset' + i, test2rbcAsset);
        }   */     
        //insert thirdList;
        
        /***** Fourth list ****/
        //List<sObject> fourthList = new List<sObject>();
        /*
        Opportunity fixedParentOpp = new Opportunity(
            Name = 'fixed parent',
            StageName = 'Discovery', 
            CloseDate = System.today(),
            Is_Template__c = TRUE,
            Anticipated_Registered_Donors__c = 10,
            WB_Projected_Procedures__c = 11,
            X2RBC_Projected_Procedures__c = 12,
            AccountId = fixedSiteAccount.Id,
            Drive_Site__c = testLocation1.Id
        );
        fourthList.add(fixedParentOpp);
        mapTestData.put('fixedParentOpp', fixedParentOpp); */
         
        //insert fourthList;
        
        /***** Fifth list ****/
        //List<sObject> fifthList = new List<sObject>();
        
        /*sked_Location_Tag__c driveSiteTag1 = new sked_Location_Tag__c(
            sked_Location__c = testLocation1.Id,
            sked_Tag__c = liftGateTag.Id,
            sked_Required__c = TRUE
        );
        fifthList.add(driveSiteTag1);*/
                
        /*
        sked_Role_Time_Variance__c driverVariance = new sked_Role_Time_Variance__c(
            sked_Buffer_Type__c = 'Add', 
            sked_Effective_End_Date__c = testDataFactory.summary.endDate, 
            sked_Effective_Start_Date__c = testDataFactory.summary.startDate, 
            sked_Location__c = testLocation1.Id,
            sked_Resource_Role_Group__c = 'Driving roles', 
            sked_Variance_Applies_to__c = 'Setup Time', 
            sked_Variation_Amount__c = 15, 
            sked_Variation_Type__c = 'Safety Video'
        );
        fifthList.add(driverVariance);*/
        

        /*
        Opportunity fixedSiteOpportunity = new Opportunity(
            Name = 'Test',
            AccountId = fixedSiteAccount.Id,
            Anticipated_Registered_Donors__c = 100,
            WB_Projected_Procedures__c = 50,
            X2RBC_Projected_Procedures__c = 25,
            CloseDate = System.today().addDays(-5),
            Drive_Date__c = System.today().addDays(-3),
            Drive_Site__c = testLocation1.Id,
            End_Time__c = Time.newInstance(15, 0, 0, 0),
            StageName = 'Solicitation',
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            Type_of_Drive__c = 'Fixed Site',
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Fixed_Site_Opp').getRecordTypeId(),
            Parent_Template_Id__c = fixedParentOpp.Id,
            Online_Scheduling_Enabled__c = 'No',
            Number_of_2RBC_Assets__c = 5,
            Number_of_Plasma_Assets__c = 5,
            Number_of_Platelet_Assets__c = 5
        );
        fifthList.add(fixedSiteOpportunity);
        mapTestData.put('fixedSiteOpportunity', fixedSiteOpportunity); */
        
        //insert fifthList;
    }
}