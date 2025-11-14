@isTest
public class AverageStaffCapAndExcesSCCorrectionTest {
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
        AverageStaffCapAndExcesSCCorrectionBatch batchObject = new AverageStaffCapAndExcesSCCorrectionBatch();
    	Database.executeBatch(batchObject,200);
        Test.stopTest();
        //Assert.areEqual(1, mobileDriveCreated.size()); // NEW Assert Class  
        
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
        AverageStaffCapAndExcesSCCorrectionBatch batchObject = new AverageStaffCapAndExcesSCCorrectionBatch();
    	Database.executeBatch(batchObject,200);
        Test.stopTest();
        Assert.areEqual(1, mobileDriveCreated.size()); // NEW Assert Class
        
    }
    
    @istest
    public static void testClassForConstructor() {
        //Test.startTest();
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
        Set<Id> driveId = new Set<Id>{mobileDriveCreated[0].id};
        AverageStaffCapAndExcesSCCorrectionBatch batchObject = new AverageStaffCapAndExcesSCCorrectionBatch(driveId);
        Database.executeBatch(batchObject,200);
        
        
        Date toDate = Date.newInstance(2019,01,01);
        Date fromDate = Date.newInstance(2024,09,23);
        
        AverageStaffCapAndExcesSCCorrectionBatch batchObject2 = new AverageStaffCapAndExcesSCCorrectionBatch(toDate, fromDate);
        Database.executeBatch(batchObject2,200);
        Test.stopTest();
    }
}