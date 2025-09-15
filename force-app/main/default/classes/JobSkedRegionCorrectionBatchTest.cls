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
       // TriggerHandler.bypass('AccountTriggerHandler');
      //  TriggerHandler.bypass('OpportunityTriggerHandler');
       // TriggerHandler.bypass('OpportunitySplitTriggerHandler');
     //   GenerateMobileDrive.generateDrives(config);
                
        AccountTeamMemberHelper.skipAccountTrigger = false;
       // Triggerhandler.clearAllBypasses();
        
        JobSkedRegionCorrectionBatch batchObject = new JobSkedRegionCorrectionBatch();
        Database.executeBatch(batchObject,100);
        
        JobSkedRegionCorrectionBatch batchObject1 = new JobSkedRegionCorrectionBatch(286);
        Database.executeBatch(batchObject1,100);
        Test.stopTest();
    }
    
    @istest
    public static void updateSkedRegionForJobsAtSpecificDateTest() {
       /* Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);*/
         skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
       sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
      
        Test.startTest();
        
       // AccountTeamMemberHelper.skipAccountTrigger = true;
        //TriggerHandler.bypass('AccountTriggerHandler');
        //TriggerHandler.bypass('OpportunityTriggerHandler');
       // TriggerHandler.bypass('OpportunitySplitTriggerHandler');
      //  GenerateMobileDrive.generateDrives(config);
                
      ////  List<sked_Drive__c> mobileDriveCreated = [Select Id, sked_Drive_Date__c, sked_Opportunity__c from sked_Drive__c /*where sked_Opportunity__c =:mobileOpportunity.Id*/ where Id=:'a2m8J000000DNIBQA4'];
        
        //AccountTeamMemberHelper.skipAccountTrigger = false;
     //   Triggerhandler.clearAllBypasses();
        Date toDate = testDrive1.sked_Drive_Date__c;
        Date fromDate = testDrive1.sked_Drive_Date__c;
       JobSkedRegionCorrectionBatch batchObject = new JobSkedRegionCorrectionBatch(toDate, fromDate);
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
    
    @istest
    public static void updateSkedRegionForSpecificDriveTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
       sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
      

//Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        /*Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');
        
        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);*/
        
        Test.startTest();
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
       // TriggerHandler.bypass('AccountTriggerHandler');
        //TriggerHandler.bypass('OpportunityTriggerHandler');
       // TriggerHandler.bypass('OpportunitySplitTriggerHandler');
       // GenerateMobileDrive.generateDrives(config);
                
        
      
        List<sked_Drive__c> mobileDriveCreated = [Select Id, sked_Drive_Date__c, sked_Opportunity__c, sked_Drive_Site__c, sked_Collection_Operation__c from sked_Drive__c where sked_Opportunity__c =:testDrive1.Id];
        
        Set<Id> docId = new Set<Id>();        
        for(sked_Drive__c doc : mobileDriveCreated) {
            docId.add(doc.Id);
        } 
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 2',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testDrive1.sked_Collection_Operation__c
        );
        insert testRegion1;
        
        sked__Job__c skedJob = new sked__Job__c();
        skedJob.sked__Job_Status__c  = 'Pending Allocation';
        skedJob.sked_Drive__c = testDrive1.Id;
        skedJob.sked__Region__c = testRegion1.Id;
        skedJob.sked__Duration__c = 415;
        skedJob.sked__Location__c = testDrive1.sked_Drive_Site__c;
sked__Job__c skedJob2 = skedJob.clone(false, false, false, false);
insert new List<sked__Job__c>{skedJob, skedJob2};
      /*  List<sked__Job__c> jobList = [SELECT Id, sked__Region__c FROM sked__Job__c WHERE sked_Drive__c IN: docId];
        for(sked__Job__c job : jobList) {
            job.sked__Region__c = testRegion1.Id;
        } 
        update jobList;*/
        AccountTeamMemberHelper.skipAccountTrigger = false;
        //Triggerhandler.clearAllBypasses();
        Id driveId = testRegion1.Id;
        JobSkedRegionCorrectionBatch batchObject = new JobSkedRegionCorrectionBatch(testDrive1.Id);
        Database.executeBatch(batchObject,100);
        Test.stopTest();
    }
    
   @isTest
    public static void testCatchBlock() {
        // Setting up necessary test data
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive1 = (sked_Drive__c) mapTestData.get('testDrive1');
        
        // Create an empty Set<Id> to simulate no valid drives (which will make the map get null)
        Set<Id> driveIds = new Set<Id>(); // Empty Set to simulate no valid drives
        
        // Simulate an empty or invalid data condition for `mapDriveVsJobs.get(job.sked_Drive__c)`
        List<sked__Job__c> jobRelatedToDrive = [SELECT Id, sked__Location__c, sked__Region__c, sked_Drive__c, sked__Job_Status__c 
                                                FROM sked__Job__c 
                                                WHERE sked__Job_Status__c NOT IN ('Complete', 'Cancelled') 
                                                AND sked_Drive__c IN :driveIds];
        
        Map<Id, List<sked__Job__c>> mapDriveVsJobs = new Map<Id, List<sked__Job__c>>();
        for (sked__Job__c job : jobRelatedToDrive) {
            List<sked__Job__c> listOfJob = new List<sked__Job__c>();
            // The map will return null because driveIds is empty
            if (mapDriveVsJobs.get(job.sked_Drive__c) != null) {
                listOfJob = mapDriveVsJobs.get(job.sked_Drive__c);
                listOfJob.add(job);
                mapDriveVsJobs.put(job.sked_Drive__c, listOfJob);
            } else {
                listOfJob.add(job);
                mapDriveVsJobs.put(job.sked_Drive__c, listOfJob);
            }
        }

        // Simulate the condition where no records are returned from the SOQL query or the map is empty
        Test.startTest();
        
        // Pass an invalid or empty driveIds (as done in the above code) to trigger the 'else' block.
        JobSkedRegionCorrectionBatch batchObject = new JobSkedRegionCorrectionBatch(testDrive1.Id);  // Invalid driveId setup
        Database.executeBatch(batchObject, 100);
        
        Test.stopTest();
        
       
    }

}