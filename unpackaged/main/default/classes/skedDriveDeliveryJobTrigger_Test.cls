@isTest
public class skedDriveDeliveryJobTrigger_Test {
    
    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        
        Test.startTest();
        
        sked_Drive_Delivery_Job__c driveDeliveryJob = new sked_Drive_Delivery_Job__c(
        	sked_Drive__c = testDrive1.Id,
            sked_Delivery_ID__c = 'DeliveryID',
            sked_Comments__c = 'Comments',
            sked_Vehicle__c = 'Vehicles',
            sked_Start__c = testDataFactory.summary.startTime.addHours(9),
            sked_Arrive__c = testDataFactory.summary.startTime.addHours(10),
            sked_Pick_Up__c = testDataFactory.summary.startTime.addHours(11),
            sked_End__c = testDataFactory.summary.startTime.addHours(12),
            sked_Type__c = 'Pick Up'
        );
        insert driveDeliveryJob;
        
        driveDeliveryJob.sked_Start__c = driveDeliveryJob.sked_Start__c.addHours(1);
        driveDeliveryJob.sked_Arrive__c = driveDeliveryJob.sked_Arrive__c.addHours(1);
        driveDeliveryJob.sked_Pick_Up__c = driveDeliveryJob.sked_Pick_Up__c.addHours(1);
        driveDeliveryJob.sked_End__c = driveDeliveryJob.sked_End__c.addHours(1);
        update driveDeliveryJob;
        
        Test.stopTest();
    }

}