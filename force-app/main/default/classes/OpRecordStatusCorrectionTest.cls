/*
* This Test class covering the following Classes
* BSF_Batch_Drive_OpRecordStatusCorrection (85%)
* */
/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 08/13/2024                 Ankit Kundu                HRP-13126
 * 09/17/2024                 Priti Jana                 HRP-13126 (Restructured)
 *****************************************************************************
*/

@isTest(SeeAllData = FALSE)
public class OpRecordStatusCorrectionTest {
  
    @testSetup
    private static void prepareDataSetup() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData(); 
        mapTestData = testDataFactory.setupDriveData();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Location__c testDriveSite = (sked__Location__c) mapTestData.get('testLocation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        Account testAccount = (Account) mapTestData.get('testAccount1');
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive.Id,
            sked_Drive_Date__c = testDrive.sked_Drive_Date__c,
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
        insert testDriveShift;
        
        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Drive_Shift__c = testDriveShift.Id,
            sked_Resource_Role__c = '2RBC',
            sked_Volunteer_Role__c = 'Donor Ambassador'
        );
        insert testJob;
        
        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = testJob.Id,
            sked__Resource__c = testResource.Id,
            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_IN_PROGRESS
        );
        insert testJobAllocation;
        
        skedOperationRecordService.generateOperationRecords(new Set<Id>{testDrive.Id});
    }
    
    static testmethod void testScheduledRun() {
        Calendar_Build_Setting__mdt mdtDriveCompletion = Calendar_Build_Setting__mdt.getInstance('Calendar_Build_Drives_Config');
        Integer numOfDays = mdtDriveCompletion?.No_of_Days_for_Status_Correction_Batch__c.intValue();
        
        Test.startTest();
        sked_Drive__c testDrive = [select id, sked_Drive_date__c FROM sked_Drive__c LIMIT 1];
        testDrive.sked_Drive_Date__c = System.today().addDays(-numOfDays);
        update testDrive;

        BSF_Batch_Drive_OpRecordStatusCorrection statusCorrectionBatchInstance = new BSF_Batch_Drive_OpRecordStatusCorrection();
        Database.executeBatch(statusCorrectionBatchInstance);
        Test.stopTest();
    }
    
    static testmethod void testManualRun() {
        Date manualRunDate = system.today().addDays(-10);
        
        Test.startTest();
        sked_Drive__c testDrive = [select id, sked_Drive_date__c FROM sked_Drive__c LIMIT 1];
        testDrive.sked_Drive_Date__c = manualRunDate;
        update testDrive;

        BSF_Batch_Drive_OpRecordStatusCorrection statusCorrectionBatchInstance = new BSF_Batch_Drive_OpRecordStatusCorrection(manualRunDate);
        Database.executeBatch(statusCorrectionBatchInstance);
        Test.stopTest();
    }
    
    static testMethod void testScheduleExecuteMethod() {  
        Test.startTest();
        BSF_Batch_Drive_OpRecordStatusCorrection cb = new BSF_Batch_Drive_OpRecordStatusCorrection();
        SchedulableContext scon;
        cb.execute(scon);       
        Test.stopTest();
    }
    
    static testMethod void testScheduledRunException() {
        Test.startTest();
        BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION = TRUE;
        BSF_Batch_Drive_OpRecordStatusCorrection cb = new BSF_Batch_Drive_OpRecordStatusCorrection();
        Test.stopTest();
    }
    
    static testMethod void testManualRunException() {
        Test.startTest();
        BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION = TRUE;
        BSF_Batch_Drive_OpRecordStatusCorrection cb = new BSF_Batch_Drive_OpRecordStatusCorrection(null);
        Test.stopTest();
    }
}