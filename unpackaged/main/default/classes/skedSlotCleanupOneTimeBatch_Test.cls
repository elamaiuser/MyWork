@isTest
public class skedSlotCleanupOneTimeBatch_Test {
    @IsTest
    static void testCleanup(){
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        sked_Drive__c drive = (sked_Drive__c) mapTestData.get('testDrive1');

        createDriveShiftAndSlots(drive);

        Database.executeBatch(new skedSlotCleanupOneTimeBatch(''), 1);
        Test.stopTest();
        
        System.assertEquals(1, [Select Id FROM sked__Slot__c].size());
    }

    private static void createDriveShiftAndSlots(sked_Drive__c drive){
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
            sked_Drive__c = drive.Id,
            sked_Start_Time__c = drive.sked_Start_Time__c,
            sked_End_Time__c = drive.sked_End_Time__c,
            sked_Drive_Date__c = drive.sked_Drive_Date__c
        );

        insert driveShift;

        sked__Slot__c slot1 = new sked__Slot__c(
            sked_Start_Date__c = driveShift.sked_Drive_Date__c,
            sked_Start_Time__c = driveShift.sked_Start_Time__c,
            sked_End_Time__c = driveShift.sked_Start_Time__c.addHours(1),
            sked_Drive_Shift__c = driveShift.Id,
            sked_Type__c = 'Whole Blood'
        );

        sked__Slot__c slot2 = new sked__Slot__c(
            sked_Start_Date__c = driveShift.sked_Drive_Date__c,
            sked_Start_Time__c = driveShift.sked_End_Time__c,
            sked_End_Time__c = driveShift.sked_End_Time__c.addHours(1),
            sked_Drive_Shift__c = driveShift.Id,
            sked_Type__c = 'Whole Blood'
        );

        insert new List<sked__Slot__c>{slot1, slot2};
    }
}