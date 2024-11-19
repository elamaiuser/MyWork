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
** CreateSkedDrive : 90%
** GenerateMobileDrive : 91%
** DriveGeneratorService : 92%
** FetchRelatedDriveData : 86%
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
    public static void conditionForMobileDriveTest(){        
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
        
        Test.startTest();
        Triggerhandler.bypass('OpportunityTriggerHandler');
        DriveGeneratorService.generateDrivesOnOppInsert(new List<Opportunity>{mobileOpportunity});
        
        List<sked_Drive__c> mobileDriveCreated = [Select Id , sked_Opportunity__c from sked_Drive__c where sked_Opportunity__c =:mobileOpportunity.Id];
      
        Triggerhandler.clearAllBypasses();
        Test.stopTest();
        Assert.areEqual(1, mobileDriveCreated.size()); // NEW Assert Class
        
    }
    
}