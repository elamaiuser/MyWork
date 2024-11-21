/*
* This Test class covering the following Classes
* BSF_NotificationThrottlerBatch, 
* */
@isTest
public with sharing class BSF_NotificationThrottlerBatchTest {
    @testSetup 
    public static void prepareDataset(){
        List<BSF_Custom_Notification__c> recordToInsert = new List<BSF_Custom_Notification__c>();
        for (Integer i=0; i < 1; i++) {
            BSF_Custom_Notification__c newRecord = new BSF_Custom_Notification__c();
            newRecord.Notification_Type__c = 'Email';
            newRecord.Sender_Email__c = 'bsfsystem@redcross.org';
            newRecord.Destination_Email__c = 'apurba@redcross.org.invalid';
            newRecord.Destination_Id__c = null; //0058K000003WWAcQAO
            newRecord.Email_Template__c = null;
            newRecord.Subject__c = 'Unit Testing BSF_NotificationThrottlerBatch';
            newRecord.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';
            newRecord.Category__c = null;
            newRecord.Status__c = 'Queued';
            newRecord.Scheduled_TimeStamp__c = System.now();
            newRecord.Expiry_TimeStamp__c = System.now().addDays(7);
            newRecord.Priority__c = 10000;
            recordToInsert.add(newRecord);           
        }        
        Database.SaveResult[] saveResults = Database.insert(recordToInsert, false);
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Address__c = '101 Test Lane, Test Avenue, 10101',
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday',
            External_Id__c = 'external-id-1',
            sked_Collections_Manager__c = UserInfo.getUserId()
        );
        insert testCollectionOperation1;
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = 'America/New_York',
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
       	insert testRegion1;
        sked__Tag__c physicalLocationTypeTagInside = new sked__Tag__c(
            Name = 'Inside',
            sked__Type__c = 'Physical Location Type'
        );
        insert physicalLocationTypeTagInside;
        sked__Resource__c testResource2 = new sked__Resource__c(
            Name = 'Test Resource 2',
            sked__Primary_Region__c = testRegion1.Id,
            sked__Resource_Type__c = 'Person',
            sked__Employment_Type__c = 'Full-time',
            sked__Category__c = 'Employee',
            sked__Home_Address__c = 'Inner Sunset, San Francisco, CA, USA',
            sked__GeoLocation__Latitude__s = 37.7575256,
            sked__GeoLocation__Longitude__s = -122.4730585,
            sked__Email__c = 'test@com.test1',
            sked__Primary_Phone__c = '1234567890',
            sked__Is_Active__c = TRUE,
            sked_Premium_Pay_Roles__c = '2RBC',
            sked_Employee_ID__c = '002',
            sked_Title__c = 'Sir',
            sked_First_Name__c = 'Barry',
            sked_Last_Name__c = 'White',
            sked_ULID__c = 'fe37f73y2',
            sked_Timezone__c = 'America/New_York',
            sked_Address_Referenced_for_Scheduling__c = 'Home',
            sked_Home_Address_GeoLocation__Latitude__s = 37.7575256,
            sked_Home_Address_GeoLocation__Longitude__s = -122.4730585,
            sked_Min_Working_Days_Per_Week__c = '2',
            Use_CO_Address_for_Scheduling__c = false
        );
        insert testResource2;
        
        List<Task> taskList1 = new List<Task>();
        Task t4 = new Task();
		t4.OwnerId = UserInfo.getUserId();
        //t4.whatId =  opp.Id;
		t4.Subject='Send Letter';
		t4.Status='Not Started';
		t4.Priority='Normal';
        taskList1.add(t4);
        insert taskList1;
        
    }
    
    @isTest
    public static void BSF_NotificationThrottlerBatch_InsertExternalEmail() {
        BSF_Custom_Notification__c newRecord = new BSF_Custom_Notification__c();
        newRecord.Notification_Type__c = 'Email';
        newRecord.Sender_Email__c = 'bsfsystem@redcross.org';
        newRecord.Destination_Email__c = 'apurba.bhattacharjee@redcross.org.invalid';
        newRecord.Destination_Id__c = null; //0058K000003WWAcQAO
        newRecord.Email_Template__c = null;
        newRecord.Subject__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Category__c = null;
        newRecord.Status__c = 'Queued';
        newRecord.Scheduled_TimeStamp__c = System.now();
        newRecord.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord.Priority__c = 1000;
        Database.SaveResult saveResults = Database.insert(newRecord, false);
   		List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_EMAIL};
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults.getId() LIMIT 1];
        Assert.areEqual(notifn.Status__c, 'Queued');
    }
    @isTest
    public static void BSF_NotificationThrottlerBatch_InsertInternalEmail() {
        BSF_Custom_Notification__c newRecord = new BSF_Custom_Notification__c();
        newRecord.Notification_Type__c = 'Email';
        newRecord.Sender_Email__c = 'bsfsystem@redcross.org';
        newRecord.Destination_Id__c = '0058K000003WWAcQAO';
        newRecord.Email_Template__c = null;
        newRecord.Subject__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Category__c = null;
        newRecord.Status__c = 'Queued';
        newRecord.Scheduled_TimeStamp__c = System.now();
        newRecord.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord.Priority__c = 1000;
        Database.SaveResult saveResults = Database.insert(newRecord, false);
        List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_EMAIL};
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults.getId() LIMIT 1];
        Assert.areEqual(notifn.Status__c, 'Queued');
    }
    @isTest
    public static void BSF_NotificationThrottlerBatch_UpdateEmail() {
        BSF_Custom_Notification__c updateRecordList = [SELECT Id, SUBJECT__C FROM BSF_Custom_Notification__c LIMIT 1];
        updateRecordList.SUBJECT__C='Test Class for BSF_NotificationThrottlerBatch';
        update updateRecordList;
    }
	@isTest
    public static void BSF_NotificationThrottlerBatch_InsertSalesforcePush() {
        BSF_Custom_Notification__c newRecord = new BSF_Custom_Notification__c();
        newRecord.Notification_Type__c = BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH;
        newRecord.Custom_Notification_Type_Id__c = [SELECT Id, DeveloperName, CustomNotifTypeName FROM CustomNotificationType WHERE DeveloperName ='Task_Custom_Notification' LIMIT 1].Id;
        newRecord.Target_Record_Id__c = [SELECT Id FROM Task LIMIT 1].Id;
        newRecord.Destination_Id__c = UserInfo.getUserId();
        newRecord.Subject__c = 'Notification Throattling Batch Testing';
        newRecord.Body__c = 'Please visit the task here lightning/r/Task/00T8K0000073n7NUAQ/view';
        newRecord.Category__c = 'AccountInvalidAddress';
        newRecord.Status__c = 'Queued';
        newRecord.Scheduled_TimeStamp__c = System.now();
        newRecord.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord.Priority__c = 1000;
        Database.SaveResult saveResults = Database.insert(newRecord, false);
        List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_SALESFORCEPUSH};
		Database.executeBatch(new BSF_NotificationThrottlerBatch(notificationTypeList),100);
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults.getId() LIMIT 1];
        Assert.areEqual(notifn.Status__c, 'Queued');
    }
    @isTest
    public static void BSF_NotificationThrottlerBatch_InsertOneOff() {
        BSF_Custom_Notification__c newRecord = new BSF_Custom_Notification__c();
        newRecord.Notification_Type__c = 'Oneoff';
        newRecord.Custom_Notification_Type_Id__c = null;
        newRecord.Target_Record_Id__c = 'a1B8K000000VEeuUAG';
        newRecord.Destination_Id__c = 'a1c5c00000FBmX4AAL';
        newRecord.Subject__c = null;
        newRecord.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Category__c = null;
        newRecord.Status__c = 'Queued';
        newRecord.Scheduled_TimeStamp__c = null;
        newRecord.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord.Priority__c = 1000;
        newRecord.Oneoff_Protocol__c = 'push';
        Database.SaveResult saveResults = Database.insert(newRecord, false);
        List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_ONEOFF};
		Database.executeBatch(new BSF_NotificationThrottlerBatch(notificationTypeList),100);
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults.getId() LIMIT 1];
        Assert.areEqual(notifn.Status__c, 'Queued');
    }
    @isTest
    public static void BSF_NotificationThrottlerBatch_validatePriority_Insert() {
        BSF_Custom_Notification__c newRecord = new BSF_Custom_Notification__c();
        newRecord.Notification_Type__c = 'Email';
        newRecord.Sender_Email__c = 'bsfsystem@redcross.org';
        newRecord.Destination_Email__c = 'apurba.bhattacharjee@redcross.org.invalid';
        newRecord.Subject__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Status__c = 'Queued';
        newRecord.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord.Priority__c = 0;    
        Database.SaveResult saveResults = Database.insert(newRecord, false);
        List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_EMAIL};
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults.getId() LIMIT 1];
        Assert.areEqual(notifn.Status__c, 'Queued');
    }

    @isTest
    public static void BSF_NotificationThrottlerBatch_validatePriority_Update() {
        BSF_Custom_Notification__c updateRecordList = [SELECT Id, SUBJECT__C FROM BSF_Custom_Notification__c LIMIT 1];
        updateRecordList.SUBJECT__C='Test validatePriority method';
        updateRecordList.PRIORITY__C=0;
        updateRecordList.STATUS__C='Queued';
        Database.SaveResult saveResults = Database.update(updateRecordList, false);
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults.getId() LIMIT 1];
        Assert.areEqual(notifn.Status__c, 'Queued');
    }
    @isTest
    public static void BSFNotificationThrottlerUtil_validNotificationTest() {
        List<BSF_Custom_Notification__c> recordToInsert = new List<BSF_Custom_Notification__c>();
        
        //Email with destination email and Id missing//
        BSF_Custom_Notification__c newRecord = new BSF_Custom_Notification__c();
        newRecord.Notification_Type__c = 'Email';
        /*newRecord.Sender_Email__c = 'bsfsystem@redcross.org';
        newRecord.Destination_Email__c = 'apurba.bhattacharjee@redcross.org.invalid';
        newRecord.Subject__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';*/
        newRecord.Status__c = 'Queued';
        newRecord.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord.Priority__c = 1000;    
        recordToInsert.add(newRecord); 
        
        //Email with destination email and Id missing//
        BSF_Custom_Notification__c newRecord1 = new BSF_Custom_Notification__c();
        newRecord1.Notification_Type__c = 'Email';
        newRecord1.Sender_Email__c = 'bsfsystem@redcross.org';
        newRecord1.Destination_Email__c = 'apurba.bhattacharjee@redcross.org.invalid';
        //newRecord1.Subject__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord1.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newRecord1.Status__c = 'Queued';
        newRecord1.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord1.Priority__c = 1000;    
        recordToInsert.add(newRecord1); 
        
        BSF_Custom_Notification__c newRecord2 = new BSF_Custom_Notification__c();
        newRecord2.Notification_Type__c = 'SalesforcePush';
        newRecord2.Custom_Notification_Type_Id__c = '0ML5c000000GnBWGA0';
        //newRecord2.Target_Record_Id__c = '00T8K0000073n7NUAQ';
        //newRecord2.Destination_Id__c = '0058K000003WWAcQAO';
        //newRecord2.Subject__c = 'Notification Throattling Batch Testing';
        newRecord2.Body__c = 'Please visit the task here lightning/r/Task/00T8K0000073n7NUAQ/view';
        newRecord2.Category__c = 'AccountInvalidAddress';
        newRecord2.Status__c = 'Queued';
        newRecord2.Scheduled_TimeStamp__c = System.now();
        newRecord2.Expiry_TimeStamp__c = System.now().addDays(7);
        newRecord2.Priority__c = 1000;
        recordToInsert.add(newRecord2);
        
        Database.SaveResult[] saveResults = Database.insert(recordToInsert, false);
        List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_EMAIL};
		Database.executeBatch(new BSF_NotificationThrottlerBatch(notificationTypeList),100);
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults[0].getId() LIMIT 1];
        Assert.areEqual(notifn.Status__c, 'Queued');
    }
    
    @isTest
    public static void BSFCustomNotificationTriggerHandler_updatePhoneNumberTest() {
        BSF_Custom_Notification__c newCustomSMSRecord = new BSF_Custom_Notification__c();
        newCustomSMSRecord.Notification_Type__c = BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS;
        newCustomSMSRecord.Destination_Id__c = [SELECT Id, sked__Primary_Phone__c FROM sked__Resource__c WHERE sked__Primary_Phone__c != null LIMIT 1].Id;
        newCustomSMSRecord.Body__c = 'Unit Testing BSF_NotificationThrottlerBatch';
        newCustomSMSRecord.Status__c = 'Queued';
        newCustomSMSRecord.Priority__c = 1000;
        newCustomSMSRecord.SMS_Country_Code_Abbreviation__c = 'US';
        Database.SaveResult saveResults = Database.insert(newCustomSMSRecord, false);
        List<String> notificationTypeList = new List<String>{BSF_Constants.NOTIFICATION_TYPE_CUSTOMSMS};
		Database.executeBatch(new BSF_NotificationThrottlerBatch(notificationTypeList),100);
        BSF_Custom_Notification__c notifn = [SELECT Id, Status__c, Phone_Number__c FROM BSF_Custom_Notification__c WHERE Id =:saveResults.getId() LIMIT 1];
        Assert.areEqual(notifn.Phone_Number__c, '1234567890');
        
    }
}