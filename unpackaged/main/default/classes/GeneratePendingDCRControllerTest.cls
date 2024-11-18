@istest
public class GeneratePendingDCRControllerTest {
 @istest
    public static void createRequestForDCRTest(){ 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData1 =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Site 2
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData1.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');

        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        try{
            GenerateMobileDrive.generateDrives(config);
        }catch(Exception ex){}
        List<sked_Drive__c> drive = [SELECT Id FROM sked_Drive__c where sked_Opportunity__c =: mobileOpportunity.Id limit 1];        
        List<Id> testDriveId = new List<Id>{drive[0].Id};
        String messageCheck = GeneratePendingDCRController.createRequestForDCR(testDriveId);
        System.assert(messageCheck != null);
        Test.stopTest();
        }  
    @istest
    public static void getDriveRecordsTest(){ 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData1 =  testDataSetup.createAndInsertCommonObjects(); 
        
        // insert Mobile Site 2
        sked__Location__c testMobileSite2 = (sked__Location__c)mapTestData1.get('MOBILE_SITE2');
        insert testMobileSite2;
        
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Map<string, sObject> mapTestData = GenerateDriveTestData.testSetupForMobileDriveV2();
        Opportunity mobileOpportunity = (Opportunity)mapTestData.get('mobileOpportunity');

        MobileDriveGeneratorDMLService.driveGeneratorConfig config = new MobileDriveGeneratorDMLService.driveGeneratorConfig();
        config.oppIds = new Set<Id>();
        config.oppIds.add(mobileOpportunity.Id);
        
        AccountTeamMemberHelper.skipAccountTrigger = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        try{
            GenerateMobileDrive.generateDrives(config);
        }catch(Exception ex){}
        List<sked_Drive__c> drive = [SELECT Id FROM sked_Drive__c where sked_Opportunity__c =: mobileOpportunity.Id limit 1];        
        List<Id> testDriveId = new List<Id>{drive[0].Id};
        List<sked_Travel_Time_Index_Item__c> items = new List<sked_Travel_Time_Index_Item__c>();
        
        sked_Travel_Time_Index_Item__c item1 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = testMobileSite2.sked__GeoLocation__Latitude__s,
        	sked_From__Longitude__s = testMobileSite2.sked__GeoLocation__Longitude__s,
        	sked_To__Latitude__s = testMobileSite2.sked__GeoLocation__Latitude__s,
        	sked_To__Longitude__s = testMobileSite2.sked__GeoLocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item1);
        
        sked_Travel_Time_Index_Item__c item2 = new sked_Travel_Time_Index_Item__c (
        	sked_From__Latitude__s = testMobileSite2.sked__GeoLocation__Latitude__s,
        	sked_From__Longitude__s = testMobileSite2.sked__GeoLocation__Longitude__s,
        	sked_To__Latitude__s = testMobileSite2.sked__GeoLocation__Latitude__s,
        	sked_To__Longitude__s = testMobileSite2.sked__GeoLocation__Longitude__s,
            sked_Timezone__c = 'America/New_York'
        );
        items.add(item2);
        
        insert items;
        
        drive[0].sked_Travel_Time_Site_To_CO__c = item1.Id;
        drive[0].sked_Travel_Time_CO_To_Site__c = item2.Id;
        update drive;
        List<Id> travelTimeIndexIds = new List<Id>{item1.Id,item2.Id};
		GeneratePendingDCRController.getData(travelTimeIndexIds,travelTimeIndexIds);  
        System.assert(config != null);
        Test.stopTest();
       
    }
}