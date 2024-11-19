@isTest
private class skedUtils_Test {
    @isTest
    static void getFieldValue_Test() {
        Date testDate = (Date) skedUtils.getFieldValue('2022-09-01', 'date');
        DateTime testDateTime = (DateTime) skedUtils.getFieldValue('2022-09-01T00:00:00+00:00', 'datetime');
        Time testTime = (Time) skedUtils.getFieldValue('T00:00:00+00:00', 'time');
        Boolean testBoolean = (Boolean) skedUtils.getFieldValue('true', 'boolean');
        Double testDouble = (Double) skedUtils.getFieldValue('15.00', 'double');
        String testString = (String) skedUtils.getFieldValue('test', 'string');
        Double testDouble2 = (Double) skedUtils.getFieldValue('120%', 'percent');
    }

    @isTest
    static void formatFieldValue_Test() {
        String testDate = skedUtils.formatFieldValue('2022-09-01', 'date');
        String testDateTime = skedUtils.formatFieldValue('2022-09-01T00:00:00+00:00', 'datetime');
        String testTime = skedUtils.formatFieldValue('13:00:00+00:00', 'time');
        String testBoolean = skedUtils.formatFieldValue('true', 'boolean');
        String testDouble = skedUtils.formatFieldValue('15.00', 'double');
    }

    @isTest
    static void combineAddress_Test() {
        skedUtils.combineAddress('100 Test Lane', 'Test Street', 'Testing', 'Test-on-Sea', 'Testex', 'T3S T1NG', 'UK');
    }

    @isTest
    static void convertSetToList_Test() {
        Set<Id> userIds = new Set<Id>{UserInfo.getUserId()};
        List<Id> userIdsList = skedUtils.convertSetToList(userIds);
    }

    @isTest static void getFieldNameFromTemplate_Test() {
        sked_Notification_Setting__mdt skedNotificationSetting = [
            SELECT Id, DeveloperName, Label, sked_Target_SObject__c, sked_Target_Field__c, 
                sked_Target_Field_Value__c, sked_Notification_Type__c, sked_Filter__c,
                sked_Destination_Field__c, sked_Notification_Target_Field__c, 
                sked_Email_From_Address_Field__c, sked_Template__c, sked_Priority__c,
                sked_Sending_From_Email_Address__c, sked_Custom_Target_Destination__c,
                sked_Content_Renderer__c, sked_Oneoff_Protocol_Field__c, sked_Subject__c,
                sked_Expiry_DateTime_Field__c,
                (SELECT Id, sked_Date_Time_Field__c, sked_Format_For_Token__c, 
                sked_Format_String__c, sked_Timezone_Field__c
            FROM sked_Notification_Formats__r)
            FROM sked_Notification_Setting__mdt
            LIMIT 1][0];

        skedNotificationBatchBase.notificationSettingModel setting = new skedNotificationBatchBase.notificationSettingModel(skedNotificationSetting, new Set<Id>());
        skedUtils.getFieldNameFromTemplate(setting.template);
    }

    @isTest
    static void getSourceFieldValue_Test() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Internal_Name__c = 'Test Internal Name',
            District_Manager__c = UserInfo.getUserId()
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Testleton',
            Email = 'test@testleton.com',
            Original_Service_Date__c = System.today(),
            Primary_Phone__c = 'Work Phone',
            OtherPhone = '123-123-1233',
            AccountId = testAccount.Id
        );
        insert testContact;

        testContact = [SELECT Id, Account.Name FROM Contact WHERE Id = :testContact.Id];
        skedUtils.getSourceFieldValue(testContact, 'Account.Name');
    }

    @isTest
    static void getJobStatusSettings_Test() {
        skedUtils.getJobStatusSettings();
    }

    @isTest
    static void getMapWeekdayIndex_Test() {
        skedUtils.getMapWeekdayIndex();
    }

    @isTest
    static void getMapRoleToPremiumOpPay_Test() {
        skedUtils.getMapRoleToPremiumOpPay();
    }

    @isTest
    static void getPickListOptions_Test() {
        skedUtils.getPickListOptions('sked__Activity__c', 'sked__Type__c');
    }

    @isTest
    static void getPickListValues_Test() {
        skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
    }

    @isTest
    static void getIdsFromList_Test() {
        User myUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Set<Id> userIds = skedUtils.getIdsFromList(new List<User>{myUser});
    }

    @isTest
    static void getIdsFromList_Models_Test() {
        User myUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        skedModels.user userModel = new skedModels.user();
        userModel.id = myUser.Id;
        
        Set<Id> userIds = skedUtils.getIdsFromList(new List<skedModels.user>{userModel});
    }

    @isTest
    static void getTravelTime_Test() {
        skedSetting.instance.Admin.distanceMeasurementUnit = 'mi';
        Location testLocation1 = Location.newInstance(38.955349, -77.393841);
        Location testLocation2 = Location.newInstance(40.955349, -79.393841);
        skedUtils.getTravelTime(testLocation1, testLocation2);
    }

    static testmethod void getMinFromDates_Test() {
        Date date1 = Date.newInstance(2020, 1, 1);
        Date date2 = Date.newInstance(2020, 1, 2);
        Date minDate = skedUtils.getMinFromDates(new List<Date>{date1, date2});
        System.assertEquals(date1, minDate);
        minDate = skedUtils.getMinFromDates(new List<Date>{date2, null});
        System.assertEquals(date2, minDate);
        minDate = skedUtils.getMinFromDates(new List<Date>{null, null});
        System.assertEquals(null, minDate);
    }

    static testmethod void scheduleUniqueJobInSeconds_Test() {
        skedUtils.scheduleUniqueJobInSeconds('skedCreateNonUserChangeDCRBatch', new skedCreateNonUserChangeDCRBatch(), 15, true);
    }
}