@istest
private class RemoveDuplicateTagBatchTest {
    @testSetup
    static void prepareTestData() {
        TriggerHandler.bypass('DriveTriggerHandler');
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
    }
    
    @istest
    public static void removeDuplicateTagFromDriveShiftTest() { 
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        
        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c, sked_Drive_Date__c FROM sked_Drive__c limit 1];
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        sked__Tag__c liftGateTag = new sked__Tag__c(
            Name = 'Lift Gate',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Vehicle'
        );
        insert new List<sked__Tag__c>{usCitizenTag, liftGateTag};
        
        List<sObject> sObjectList = new List<sObject>();
                sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = drive[0].Id,
            sked_Drive_Date__c = drive[0].sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        sObjectList.add(testDriveShift);
        
        sked__Account_Tag__c mobileAccountTag_usCitizen = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE
        );
        sObjectList.add(mobileAccountTag_usCitizen);
        
        sked__Account_Tag__c mobileAccountTag_liftGate = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = liftGateTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 1,
            sked_Minimum_Quantity__c = 1
        );
        sObjectList.add(mobileAccountTag_liftGate);
        
        sked_Location_Tag__c driveSiteUSCitizenTag = new sked_Location_Tag__c(
            sked_Location__c = drive[0].sked_Drive_Site__c,
            sked_Tag__c = usCitizenTag.Id,
            sked_Required__c = TRUE
        );
        sObjectList.add(driveSiteUSCitizenTag);
        insert sObjectList;
        
        sked_Drive_Shift_Tag__c testDriveShiftTag_liftGate = new sked_Drive_Shift_Tag__c(
        	sked_Drive_Shift__c = testDriveShift.Id,
        	sked_Tag__c = liftGateTag.Id,
            sked_Minimum_Quantity__c = 2
        );
        insert testDriveShiftTag_liftGate;
        
        Map<Id,sked__Account_Tag__c> accountMap = new Map<Id,sked__Account_Tag__c> ([SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Account__c, sked__Required__c, sked_Minimum_Quantity__c FROM sked__Account_Tag__c Where sked__Account__c =: drive[0].sked_Account__c]);
        Id tagIdToCreateDuplicateJobTag = null;
        Id tagIdToCreateDuplicateDriveShiftTag = null;
        for(sked__Account_Tag__c accTag : accountMap.values()) {
            if(accTag.sked__Tag__r.Name == 'Lift Gate') {
                tagIdToCreateDuplicateDriveShiftTag = accTag.sked__Tag__c;
            }
        }
        Map<Id,sked_Location_Tag__c> locationMap = new Map<Id,sked_Location_Tag__c> ([SELECT Id, sked_Location__c, sked_Tag__c,sked_Tag__r.Name, sked_Minimum_Quantity__c, sked_Required__c FROM sked_Location_Tag__c Where sked_Location__c =: drive[0].sked_Drive_Site__c]);
        for(sked_Location_Tag__c locTag : locationMap.values()){
            if(locTag.sked_Tag__r.Name == 'US Citizen') {
                tagIdToCreateDuplicateJobTag = locTag.sked_Tag__c;
            }
        }
       
        sked_Drive_Shift_Tag__c driveShiftTagClone = new sked_Drive_Shift_Tag__c();
        driveShiftTagClone = testDriveShiftTag_liftGate.clone();
        driveShiftTagClone.sked_Minimum_Quantity__c = 1;
        insert driveShiftTagClone; //duplicate tag

        RemoveDuplicateTagFromDriveShift batch = new RemoveDuplicateTagFromDriveShift(null, null, new Set<Id>{testDriveShift.Id}, 0);
        database.executebatch(batch, 200);
        
        Test.stopTest();
        Assert.isTrue([SELECT count() FROM sked_Drive_Shift_Tag__c] == 1);
    }
    
    @istest
    public static void removeDuplicateTagFromJobTest() { 
        Test.startTest();
        skedHubBase.BypassInsertTriggers = true;
        
        List<sked_Drive__c> drive = [SELECT Id, sked_Account__c, sked_Drive_Site__c, sked_Drive_Date__c FROM sked_Drive__c LIMIT 1];
        
        sked__Tag__c usCitizenTag = new sked__Tag__c(
            Name = 'US Citizen',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        sked__Tag__c spanishTag = new sked__Tag__c(
            Name = 'Spanish',
            sked__Type__c = 'Certification',
            sked_Resource_Type__c = 'Person'
        );
        insert new List<sked__Tag__c>{usCitizenTag, spanishTag};
        
        List<sObject> sObjectList = new List<sObject>();
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = drive[0].Id,
            sked_Drive_Date__c = drive[0].sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 1,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        sObjectList.add(testDriveShift);
        
        sked__Account_Tag__c mobileAccountTag_usCitizen = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = usCitizenTag.Id,
            sked__Required__c = TRUE
        );
        sObjectList.add(mobileAccountTag_usCitizen);
        
        sked__Account_Tag__c mobileAccountTag_liftGate = new sked__Account_Tag__c(
            sked__Account__c = drive[0].sked_Account__c,
            sked__Tag__c = spanishTag.Id,
            sked__Required__c = FALSE,
            sked__Weighting__c = 1,
            sked_Minimum_Quantity__c = 1
        );
        sObjectList.add(mobileAccountTag_liftGate);
        
        sked_Location_Tag__c driveSiteUSCitizenTag = new sked_Location_Tag__c(
            sked_Location__c = drive[0].sked_Drive_Site__c,
            sked_Tag__c = usCitizenTag.Id,
            sked_Required__c = TRUE
        );
        sObjectList.add(driveSiteUSCitizenTag);
        insert sObjectList;
        
        Map<Id,sked__Account_Tag__c> accountMap = new Map<Id,sked__Account_Tag__c> ([SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Account__c, sked__Required__c, sked_Minimum_Quantity__c FROM sked__Account_Tag__c Where sked__Account__c =: drive[0].sked_Account__c]);
        Id tagIdToCreateDuplicateJobTag = null;
        Id tagIdToCreateDuplicateDriveShiftTag = null;
        for(sked__Account_Tag__c accTag : accountMap.values()){
            if(accTag.sked__Tag__r.Name == 'Spanish') {
                tagIdToCreateDuplicateDriveShiftTag = accTag.sked__Tag__c;
            }
        }
        
        Map<Id,sked_Location_Tag__c> locationMap = new Map<Id,sked_Location_Tag__c> ([SELECT Id, sked_Location__c, sked_Tag__c,sked_Tag__r.Name, sked_Minimum_Quantity__c, sked_Required__c FROM sked_Location_Tag__c Where sked_Location__c =: drive[0].sked_Drive_Site__c]);
        for(sked_Location_Tag__c locTag : locationMap.values()){
            if(locTag.sked_Tag__r.Name == 'US Citizen') {
                tagIdToCreateDuplicateJobTag = locTag.sked_Tag__c;
            }
        }
        
        sked__Region__c skdRegion = [SELECT Id, sked__Timezone__c FROM sked__Region__c LIMIT 1];
        sked__Job__c job1 = new sked__Job__c(
            sked__Region__c = skdRegion.Id,
            sked__Duration__c = 10,
            sked__Quantity__c = 2,
            sked_Drive__c = drive[0].Id,
            sked_Asset_Type__c = Constants.JOB_TYPE_VEHICLE,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked__Job_Status__c = 'Pending Allocation'
        );
        insert job1;
		
        List<sked__Job_Tag__c> testJobTags = new List<sked__Job_Tag__c>();
        sked__Job_Tag__c skedJobTag;
        skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = job1.Id,
            sked__Tag__c = tagIdToCreateDuplicateJobTag
        );
        testJobTags.add(skedJobTag);
        skedJobTag = new sked__Job_Tag__c(
            sked__Job__c = job1.Id,
            sked__Tag__c = tagIdToCreateDuplicateJobTag
        );
        testJobTags.add(skedJobTag);
        insert testJobTags;

        RemoveDuplicateTagFromJob batch = new RemoveDuplicateTagFromJob(null, null, new Set<Id>{job1.Id}, 0);
        database.executebatch(batch, 200);
        
        Test.stopTest();
        Assert.isTrue([SELECT count() FROM sked__Job_Tag__c] == 1);
    }
}