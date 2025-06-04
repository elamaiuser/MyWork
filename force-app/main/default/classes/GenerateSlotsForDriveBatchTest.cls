@isTest
public class GenerateSlotsForDriveBatchTest {

    @isTest
    public static void fixMobileDriveSlotsTest() {
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
        
        List<sked__Slot__c> slotsList = [SELECT Id, sked_Drive__c FROM sked__Slot__c WHERE sked_Drive__r.sked_Opportunity__c IN: config.oppIds];
        //SELECT sked_Drive__c FROM sked__Slot__c where sked_Drive__c IN: driveIds
        delete slotsList;
        
        GenerateSlotsForDriveBatch batch1 = new GenerateSlotsForDriveBatch();
        Database.executeBatch(batch1, 100);
        
        skedSetting.instance.Admin.migrationMode = FALSE;

        skedHubBase.BypassInsertTriggers = FALSE;
        skedHubBase.BypassUpdateTriggers = FALSE;
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
                
        List<sked__Slot__c> slotsList = [SELECT Id, sked_Drive__c FROM sked__Slot__c WHERE sked_Drive__r.sked_Opportunity__c =: fixOpportunity.Id];
        //SELECT sked_Drive__c FROM sked__Slot__c where sked_Drive__c IN: driveIds
        delete slotsList;
        
        GenerateSlotsForDriveBatch batch1 = new GenerateSlotsForDriveBatch();
        Database.executeBatch(batch1, 100);

        Test.stopTest();   
    }
}