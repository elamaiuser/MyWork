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
-------------------------
Current Code Coverage :  
-------------------------
** CreateSkedDrive : 92%
** GenerateMobileDrive : 91%
** DriveGeneratorService : 92%
** JobTriggerHandler : 83%
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
    
    /*@istest
    public static void conditionForErrorMessageMobileTest(){        
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForErrorMsgMobileDrive();
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
        
        Assert.isTrue(config!=null); // NEW Assert Class
        
    }*/
    
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
        // Setup test data
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        Biomed_Collection_Op_Center__c collectionOperation = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        
        // Create time block
        Time_Block__c timeBlock = new Time_Block__c(
            Name = 'Test Time Block',
            Start_Time__c = Time.newInstance(6, 0, 0, 0),
            End_Time__c = Time.newInstance(18, 0, 0, 0),
            Days_of_Week__c = 'Monday;Tuesday;Wednesday;Thursday;Friday',
            sked__Region__c = collectionOperation.Id  // Add the required Region field
        );
        insert timeBlock;
        
        // Create collection operation time block
        Collection_Operation_Time_Block__c coTimeBlock = new Collection_Operation_Time_Block__c(
            Collection_Operation__c = collectionOperation.Id,
            Time_Block__c = timeBlock.Id,
            Effective_Start_Date__c = Date.today().addDays(-1),
            Effective_End_Date__c = Date.today().addDays(1)
        );
        insert coTimeBlock;
        
        Test.startTest();
        
        // Generate drive
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        
        GenerateMobileDrive.generateDrives(config);
        
        // Query created drive and drive shifts
        List<sked_Drive__c> drives = [
            SELECT Id, sked_Drive_Date__c, sked_Collection_Operation__c,
                   (SELECT Id, sked_Time_Block__c, sked_Start_Time__c, sked_End_Time__c 
                    FROM sked_Drive_Shifts__r)
            FROM sked_Drive__c 
            WHERE sked_Opportunity__c = :mobileOpportunity.Id
        ];
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, drives.size(), 'Should have created one drive');
        System.assertEquals(collectionOperation.Id, drives[0].sked_Collection_Operation__c, 'Drive should be associated with the test collection operation');
        System.assertNotEquals(0, drives[0].sked_Drive_Shifts__r.size(), 'Drive should have drive shifts');
        
        // Verify time block association
        for(sked_Drive_Shift__c shift : drives[0].sked_Drive_Shifts__r) {
            System.assertEquals(timeBlock.Id, shift.sked_Time_Block__c, 'Drive shift should be associated with the test time block');
            System.assert(shift.sked_Start_Time__c >= timeBlock.Start_Time__c, 'Drive shift start time should be within time block range');
            System.assert(shift.sked_End_Time__c <= timeBlock.End_Time__c, 'Drive shift end time should be within time block range');
        }
    }
    
}