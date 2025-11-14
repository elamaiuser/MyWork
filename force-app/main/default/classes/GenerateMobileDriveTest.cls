/* This test class is coving the following two classes for drive generation
 * CreateSkedDrive
 * GenerateMobileDrive
 * DriveGeneratorService
 * ***************************************************************************

 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 07/23/2024				  Priti Jana			 Corrected the test class, 
 													 increased code coverage
 * 09/26/2024				  Priti Jana			 Increased code coverage for JobTriggerHandler (HRP-13522)
 * 07/10/2025				  Priti Jana			 Added new test method to cover 
  													 Non Integrated WB FS Drive generation logic 
 * 08/06/2025				  Krapy Tuli			 Added test class for populateAdditionalRole in JobTriggerHandler (HRP-15160)

-------------------------
Current Code Coverage :  
-------------------------
** CreateSkedDrive : 92%
** GenerateMobileDrive : 91%
** DriveGeneratorService : 92%
** JobTriggerHandler : 91%
*******************************************************************************
*/

@isTest
public class GenerateMobileDriveTest {
    
    @istest
    public static void conditionForFixedSiteDriveTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
     
        Test.startTest();
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
                
        List<sked_Drive__c> fixedSiteDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:fixOpportunity.Id];
        Assert.areEqual(1, fixedSiteDriveCreated.size()); // NEW Assert Class
        
        Set<Id> docId = new Set<Id>();        
        for(sked_Drive__c doc : fixedSiteDriveCreated) {
            docId.add(doc.Id);
        } 
        List<sked_Drive_Shift__c> driveshiftList = [select Id , sked_Platelet_Rounds__c from sked_Drive_Shift__c where sked_Drive__c IN : docId];
        Assert.areEqual(2, driveshiftList.size()); // NEW Assert Class
        
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Triggerhandler.clearAllBypasses();
        Test.stopTest();       
    }  
    
   /* @istest
    public static void conditionForLunchBreakAsTrueTest()
    {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForElseCondition();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        Test.startTest();
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        GenerateMobileDrive.generateDrives(config);
        
        Triggerhandler.clearAllBypasses();
        AccountTeamMemberHelper.skipAccountTrigger = false;
        
        Test.stopTest();
        
        List<sked_Drive__c> mobileDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:mobileOpportunity.Id];
        
        Assert.areEqual(1, mobileDriveCreated.size()); // NEW Assert Class
    }*/

   @istest
    public static void conditionForErrorMessageFixedSiteDriveTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForErrorMessage();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
        
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
        
        Triggerhandler.clearAllBypasses();
        AccountTeamMemberHelper.skipAccountTrigger = false;
        
        Test.stopTest();
        
        Integer noOffixedSiteDriveCreated = [Select count() from sked_Drive__c where sked_Opportunity__c =:fixOpportunity.Id];
        Assert.areEqual(0, noOffixedSiteDriveCreated); // NEW Assert Class
    }
    
    @istest
    public static void conditionForMobileDriveTest() {   

        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        
        List<sked_Drive__c> mobileDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c IN :config.oppIds];
        
        // Coverage for JobTriggerhandler AfterDelete() --> HRP-13522
        List<sked__Job__c> jobsCreated = [SELECT Id FROM sked__Job__c where sked_Drive__c = :mobileDriveCreated[0].Id];
        delete jobsCreated;
        //HRP-13522 --> Ends Here
        
        Triggerhandler.clearAllBypasses();
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Test.stopTest();
       	Assert.areEqual(1, mobileDriveCreated.size()); // NEW Assert Class  
        
    }
    
    @istest
    public static void conditionForNonIntWbFsDriveTest() {        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForNonIntWbFsDrives();
        Opportunity nonIntWbFsOpportunity = (Opportunity)mapTestData.get('nonItegratedWBFixedSiteOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(nonIntWbFsOpportunity.Id);
        
        Test.startTest();
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        GenerateMobileDrive.generateDrives(config);
        
        Triggerhandler.clearAllBypasses();
        AccountTeamMemberHelper.skipAccountTrigger = false;
        
        Test.stopTest();
    }
    
    @istest
    public static void conditionForDriveGeneratorServiceTestForFixed() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        skedHubBase.BypassDeleteTriggers = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
        Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
        
        Test.startTest();
        
        DriveGeneratorService.generateDrivesOnOppInsert(new List<Opportunity>{fixOpportunity});
                
        List<sked_Drive__c> fixedSiteDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:fixOpportunity.Id];
        Set<Id> docId = new Set<Id>();
        
        for(sked_Drive__c doc : fixedSiteDriveCreated) {
            docId.add(doc.Id);
        }
        
        Assert.areEqual(1, fixedSiteDriveCreated.size()); // NEW Assert Class
        Test.stopTest();   
    }
    
    @istest
    public static void conditionForDriveGeneratorServiceTestForMobile() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        Test.startTest();
        
        DriveGeneratorService.generateDrivesOnOppInsert(new List<Opportunity>{mobileOpportunity});
        
        List<sked_Drive__c> mobileDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:mobileOpportunity.Id];
      
        Triggerhandler.clearAllBypasses();
        Test.stopTest();
        Assert.areEqual(1, mobileDriveCreated.size()); // NEW Assert Class
        
    }
    
    @isTest
    static void testAssociateTimeBlocksToDriveShifts() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');//Opp start time is 5AM and end time is 6PM
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        
        List<Time_Block__c> timeBlocks = new List<Time_Block__c>();
        
        // Full match time block (5 AM - 6 PM)
        timeBlocks.add(new Time_Block__c(
            Name = 'Exact Match Time Block',
            Start_Time__c = Time.newInstance(5, 0, 0, 0),
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        ));
        
        //  Day-only match time block (4 AM - 5 AM)
        timeBlocks.add(new Time_Block__c(
            Name = 'Day Only Match Time Block',
            Start_Time__c = Time.newInstance(4, 0, 0, 0),
            End_Time__c = Time.newInstance(5, 0, 0, 0),
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        ));
        
         //  Day-only match time block (1 AM - 2 AM)
        timeBlocks.add(new Time_Block__c(
            Name = 'Day Only Match Time Block2',
            Start_Time__c = Time.newInstance(1, 0, 0, 0),
            End_Time__c = Time.newInstance(2, 0, 0, 0),
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday'
        ));
        
        
        insert timeBlocks;
        
        // Create collection operation time blocks
        List<Collection_Operation_Time_Block__c> coTimeBlocks = new List<Collection_Operation_Time_Block__c>();
        for(Time_Block__c tb : timeBlocks) {
            coTimeBlocks.add(new Collection_Operation_Time_Block__c(
                Collection_Operation__c = collectionOperation.Id,
                Time_Block__c = tb.Id,
                Effective_Start_Date__c = Date.today().addDays(-1000),
                Effective_End_Date__c = Date.today().addDays(1000)
            ));
        }
        insert coTimeBlocks;
        
        Test.startTest();
        
        // Generate drive
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
     	skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        GenerateMobileDrive.generateDrives(config);
        
        
        // Query created drive and drive shifts once
        List<sked_Drive__c> drives = [
            SELECT Id, sked_Drive_Date__c, sked_Collection_Operation__c, sked_Pending_Action_Reason_Code__c,
                   (SELECT Id, sked_Time_Block__c, sked_Start_Time__c, sked_End_Time__c, 
                           sked_Contention__c 
                    FROM sked_Drive_Shifts__r)
            FROM sked_Drive__c 
            WHERE sked_Opportunity__c = :mobileOpportunity.Id
        ];
        
        Map<Id, Time_Block__c> timeBlockMap = new Map<Id, Time_Block__c>(timeBlocks);
        System.debug('Drive shifts size'+ drives[0].sked_Drive_Shifts__r.size());
        
        // Verify results
        System.assertEquals(1, drives.size(), 'Should have created one drive');
        System.assertEquals(collectionOperation.Id, drives[0].sked_Collection_Operation__c, 'Drive should be associated with the test collection operation');
        System.assertNotEquals(0, drives[0].sked_Drive_Shifts__r.size(), 'Drive should have drive shifts');
        
        // Verify time block associations and violations for each scenario
        for(sked_Drive_Shift__c shift : drives[0].sked_Drive_Shifts__r) {
            Time_Block__c associatedBlock = shift.sked_Time_Block__c != null ? timeBlockMap.get(shift.sked_Time_Block__c) : null;
            
            // Scenario 1: Full match
            if(shift.sked_Start_Time__c >= Time.newInstance(5, 0, 0, 0) && 
               shift.sked_End_Time__c <= Time.newInstance(18, 0, 0, 0)) {
                System.assert (shift.sked_Contention__c == null , 
                    'Drive shift within exact match time block should not have violation');
                System.assert( shift.sked_Time_Block__c !=null, 
                    'Drive shift should be associated with exact match time block');
            }
            
            // Scenario 2: Day-only match or no match
            else {
                System.assert(shift.sked_Contention__c != null, 
                    'Drive shift with day-only match or no match should have violation');
                if(shift.sked_Start_Time__c >= Time.newInstance(4, 0, 0, 0) && 
                   shift.sked_End_Time__c <= Time.newInstance(22, 0, 0, 0)) {
                    System.assertEquals(skedConstants.CONTENTION_CODE_OUT_OF_TIME_BLOCK, 
                        shift.sked_Contention__c, 
                        'Drive shift should have out of time block violation message');
                } else {
                    System.assertEquals(skedConstants.CONTENTION_CODE_MISSING_TIME_BLOCK, 
                        shift.sked_Contention__c, 
                        'Drive shift should have missing time block violation message');
                }
            }
        }             
        Triggerhandler.clearAllBypasses();
        Test.stopTest();    
    }   
    
    //HRP-15160
      @istest
    public static void JobTriggerHandlerTest() {

       Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);

        AccountTeamMemberHelper.skipAccountTrigger = true;
        skedHubBase.BypassUpdateTriggers = TRUE;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('DriveTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('BSFTaskChecklistTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        Test.startTest();
        GenerateMobileDrive.generateDrives(config);
        
        List<sked_Drive__c> mobileDriveCreated = [Select Id , sked_Opportunity__c , sked_Collection_Operation__c from sked_Drive__c where sked_Opportunity__c IN :config.oppIds];
        List<sked__Job__c> jobsCreated = [SELECT Id FROM sked__Job__c where sked_Drive__c = :mobileDriveCreated[0].Id];

        List<sked__Resource__c> resource = [SELECT Id, Name from sked__Resource__c where sked_Collection_Operation_Id__c = :mobileDriveCreated[0].sked_Collection_Operation__c];
        sked__Job_Allocation__c alloc = new sked__Job_Allocation__c(
            sked__Job__c = jobsCreated[0].Id ,
            sked__Resource__c = resource[0].Id
        );
        insert alloc;
        
        jobsCreated[0].sked_Dual_Role__c = 'Driver';
        update jobsCreated[0];

       List<sked__Job_Allocation__c> allocs = [
        SELECT Id, sked_Dual_Role__c, sked_Additional_Roles__c
        FROM sked__Job_Allocation__c
        WHERE sked__Job__c = :jobsCreated[0].Id
    ];
    Map<String, Object> params = new Map<String, Object>{
    'param1' => JSON.serialize(allocs)
    };

        JobTriggerHandler.call('updateAdditionalRole', params);
        Triggerhandler.clearAllBypasses();
        Test.stopTest();

        sked__Job_Allocation__c updatedAlloc = [
            SELECT Id, sked_Additional_Roles__c
            FROM sked__Job_Allocation__c
            WHERE Id = :alloc.Id
        ];

        System.assertEquals('Driver', updatedAlloc.sked_Additional_Roles__c, 'Additional role should match Dual Role');
        
    }
}