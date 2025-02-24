@isTest
public class JobSkedRegionCorrectionBatchTest {

    @istest
    public static void updateSkedRegionForAllJobsTest() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
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
                
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Triggerhandler.clearAllBypasses();
        
        JobSkedRegionCorrectionBatch batchObject = new JobSkedRegionCorrectionBatch();
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
    
    @istest
    public static void updateSkedRegionForJobsAtSpecificDateTest() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
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
                
        List<sked_Drive__c> mobileDriveCreated = [Select Id, sked_Drive_Date__c, sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:mobileOpportunity.Id];
        
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Triggerhandler.clearAllBypasses();
        Date toDate = mobileDriveCreated[0].sked_Drive_Date__c;
        Date fromDate = mobileDriveCreated[0].sked_Drive_Date__c;
        JobSkedRegionCorrectionBatch batchObject = new JobSkedRegionCorrectionBatch(toDate, fromDate);
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
    
    @istest
    public static void updateSkedRegionForSpecificDriveTest() {
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
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
                
        List<sked_Drive__c> mobileDriveCreated = [Select Id, sked_Drive_Date__c, sked_Opportunity__c, sked_Drive_Site__c, sked_Collection_Operation__c from sked_Drive__c where sked_Opportunity__c =:mobileOpportunity.Id];
        
        Set<Id> docId = new Set<Id>();        
        for(sked_Drive__c doc : mobileDriveCreated) {
            docId.add(doc.Id);
        } 
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = mobileDriveCreated[0].sked_Collection_Operation__c
        );
        insert testRegion1;
        List<sked__Job__c> jobList = [SELECT Id, sked__Region__c FROM sked__Job__c WHERE sked_Drive__c IN: docId];
        for(sked__Job__c job : jobList) {
            job.sked__Region__c = testRegion1.Id;
        } 
        update jobList;
        AccountTeamMemberHelper.skipAccountTrigger = false;
        Triggerhandler.clearAllBypasses();
        Id driveId = mobileDriveCreated[0].Id;
        JobSkedRegionCorrectionBatch batchObject = new JobSkedRegionCorrectionBatch(driveId);
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
}