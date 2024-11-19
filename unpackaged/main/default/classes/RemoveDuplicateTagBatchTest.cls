@istest
public class RemoveDuplicateTagBatchTest {
	@istest
    public static void removeDuplicateTagFromDriveShiftTest(){ 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData1 =  testDataSetup.createAndInsertCommonObjects(); 
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
        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c FROM sked_Drive__c where sked_Opportunity__c =: mobileOpportunity.Id limit 1];
        List<sked__Tag__c> tagList = [SELECT Id, Name FROM sked__Tag__c where Name = 'US Citizen' Or Name = 'Lift Gate'];
        Id usCitizenTag =  null;
        Id liftGateTag =  null;
        for(sked__Tag__c tag : tagList){
            if(tag.Name == 'US Citizen'){
                usCitizenTag = tag.Id; 
            }else if(tag.Name == 'Lift Gate'){
                liftGateTag = tag.Id; 
            }
        }
        List<sObject> secondList = new List<sObject>();
        sked__Account_Tag__c mobileAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = usCitizenTag,
            sked__Required__c = TRUE
        );
        secondList.add(mobileAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag4 = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = liftGateTag,
            sked__Required__c = FALSE,
            sked__Weighting__c = 1,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag4);//HRP-xxxxx
        sked_Location_Tag__c driveSiteUSCitizenTag = new sked_Location_Tag__c(
            sked_Location__c = drive[0].sked_Drive_Site__c,
            sked_Tag__c = usCitizenTag,
            sked_Required__c = TRUE
        );
        secondList.add(driveSiteUSCitizenTag);
        insert secondList;
        Map<Id,sked__Account_Tag__c> accountMap = new Map<Id,sked__Account_Tag__c> ([SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Account__c, sked__Required__c, sked_Minimum_Quantity__c FROM sked__Account_Tag__c Where sked__Account__c =: drive[0].sked_Account__c]);
        Id tagIdToCreateDuplicateJobTag = null;
        Id tagIdToCreateDuplicateDriveShiftTag = null;
        for(sked__Account_Tag__c accTag : accountMap.values()){
            if(accTag.sked__Tag__r.Name == 'Lift Gate'){
                tagIdToCreateDuplicateDriveShiftTag = accTag.sked__Tag__c;
            }
        }
        Map<Id,sked_Location_Tag__c> locationMap = new Map<Id,sked_Location_Tag__c> ([SELECT Id, sked_Location__c, sked_Tag__c,sked_Tag__r.Name, sked_Minimum_Quantity__c, sked_Required__c FROM sked_Location_Tag__c Where sked_Location__c =: drive[0].sked_Drive_Site__c]);
        for(sked_Location_Tag__c locTag : locationMap.values()){
            if(locTag.sked_Tag__r.Name == 'US Citizen'){
                tagIdToCreateDuplicateJobTag = locTag.sked_Tag__c;
            }
        }
        List <sked_Drive_Shift__c> DriveShiftList = [SELECT Id, sked_Drive__c FROM sked_Drive_Shift__c where sked_Drive__c =: drive[0].Id];
        List<sked_Drive_Shift_Tag__c> driveShiftTags = [SELECT Id, Name, sked_Drive_Shift__c, sked_Tag__c, sked_Tag__r.Name, sked_Minimum_Quantity__c from sked_Drive_Shift_Tag__c where sked_Drive_Shift__c =: DriveShiftList[0].Id];
        sked_Drive_Shift_Tag__c driveShiftTagClone = new sked_Drive_Shift_Tag__c();
        for(sked_Drive_Shift_Tag__c driveShiftTag : driveShiftTags){
            if(driveShiftTag.sked_Tag__r.Name == 'Lift Gate'){
                driveShiftTagClone = driveShiftTag.clone();
            }
        }
        driveShiftTagClone.sked_Minimum_Quantity__c = 1;

        insert driveShiftTagClone;

        Set<Id> driveShiftIdSet = new Set<Id>();
        for(sked_Drive_Shift__c singleDriveShift : DriveShiftList){
            driveShiftIdSet.add(singleDriveShift.Id);
        }
        RemoveDuplicateTagFromDriveShift batch = new RemoveDuplicateTagFromDriveShift(null, null, driveShiftIdSet,0);
        database.executebatch(batch,200);
        Test.stopTest();
    }
    @istest
    public static void removeDuplicateTagFromJobTest(){ 
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData1 =  testDataSetup.createAndInsertCommonObjects(); 
        
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
        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c FROM sked_Drive__c where sked_Opportunity__c =: mobileOpportunity.Id limit 1];
        List<sked__Tag__c> tagList = [SELECT Id, Name FROM sked__Tag__c where Name = 'US Citizen' Or Name = 'Spanish'];
        Id usCitizenTag =  null;
        Id spanishTag =  null;
        for(sked__Tag__c tag : tagList){
            if(tag.Name == 'US Citizen'){
                usCitizenTag = tag.Id; 
            }else if(tag.Name == 'Spanish'){
                spanishTag = tag.Id; 
            }
        }
        List<sObject> secondList = new List<sObject>();
        sked__Account_Tag__c mobileAccountTag1 = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = usCitizenTag,
            sked__Required__c = TRUE
        );
        secondList.add(mobileAccountTag1);
        
        sked__Account_Tag__c mobileAccountTag4 = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = spanishTag,
            sked__Required__c = FALSE,
            sked__Weighting__c = 10,
            sked_Minimum_Quantity__c = 1
        );
        secondList.add(mobileAccountTag4);//HRP-xxxxx
        sked_Location_Tag__c driveSiteSpanishTag = new sked_Location_Tag__c(
            sked_Location__c = drive[0].sked_Drive_Site__c,
            sked_Tag__c = spanishTag,
            sked_Minimum_Quantity__c = 5,
            sked_Required__c = FALSE
        );
        secondList.add(driveSiteSpanishTag);
        sked_Location_Tag__c driveSiteUSCitizenTag = new sked_Location_Tag__c(
            sked_Location__c = drive[0].sked_Drive_Site__c,
            sked_Tag__c = usCitizenTag,
            sked_Required__c = TRUE
        );
        secondList.add(driveSiteUSCitizenTag);
        insert secondList;
        Map<Id,sked__Account_Tag__c> accountMap = new Map<Id,sked__Account_Tag__c> ([SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Account__c, sked__Required__c, sked_Minimum_Quantity__c FROM sked__Account_Tag__c Where sked__Account__c =: drive[0].sked_Account__c]);
        Id tagIdToCreateDuplicateJobTag = null;
        Id tagIdToCreateDuplicateDriveShiftTag = null;
        for(sked__Account_Tag__c accTag : accountMap.values()){
            if(accTag.sked__Tag__r.Name == 'Spanish'){
                tagIdToCreateDuplicateDriveShiftTag = accTag.sked__Tag__c;
            }
        }
        Map<Id,sked_Location_Tag__c> locationMap = new Map<Id,sked_Location_Tag__c> ([SELECT Id, sked_Location__c, sked_Tag__c,sked_Tag__r.Name, sked_Minimum_Quantity__c, sked_Required__c FROM sked_Location_Tag__c Where sked_Location__c =: drive[0].sked_Drive_Site__c]);
        for(sked_Location_Tag__c locTag : locationMap.values()){
            if(locTag.sked_Tag__r.Name == 'US Citizen'){
                tagIdToCreateDuplicateJobTag = locTag.sked_Tag__c;
            }
        }
        
        List <sked_Drive_Shift__c> DriveShiftList = [SELECT Id, sked_Drive__c FROM sked_Drive_Shift__c where sked_Drive__c =: drive[0].Id];
        
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c limit 1];
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Duration__c = 10,
            sked__Quantity__c = 2,
            sked_Drive__c = drive[0].Id,
            sked_Asset_Type__c = Constants.JOB_TYPE_VEHICLE,
            sked_Drive_Shift__c = DriveShiftList[0].Id,
            sked__Job_Status__c = 'Pending Allocation'
        );
        insert job1;

        sked__Job_Tag__c skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = job1.Id,
            sked__Tag__c = tagIdToCreateDuplicateJobTag
        );
        insert skedJobTag;
        skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = job1.Id,
            sked__Tag__c = tagIdToCreateDuplicateJobTag
        );
        insert skedJobTag;

        Set<Id> jobIdSet = new Set<Id>();
        jobIdSet.add(job1.Id);
        RemoveDuplicateTagFromJob batch = new RemoveDuplicateTagFromJob(null, null, jobIdSet,0);
        database.executebatch(batch,200);
        Test.stopTest();
    }
}