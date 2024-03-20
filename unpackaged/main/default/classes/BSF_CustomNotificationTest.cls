@isTest
private class BSF_CustomNotificationTest {
    @testSetup
    static void makeData(){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().values()){
            recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
        }
        Id recTypeId = recTypeNameWithIdMap.get('Mobile Account');

        User drdUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            LastName = 'DRDLastName',
            Email = 'DRDUser@test.com',
            Username = 'DRDUser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TestCompany',
            Title = 'TestTitle',
            Alias = 'Tal',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'WEST_BDM'].Id
        );

        system.runAs(new User(Id = UserInfo.getUserId())) {
           insert drdUser;
           System.assertNotEquals(null,drdUser.Id,'User not Inserted.');
        } 
        system.runAs(drdUser) {
            Account acc1=new Account();
            acc1.name='testAcct01';
            acc1.Internal_Name__c = 'testAcc';
            acc1.RecordTypeId = recTypeId;
            acc1.BillingPostalCode = '30623';
            acc1.Days_of_Week_Declined__c ='Monday;Tuesday';

            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            TriggerHandler.bypass('AccountTriggerHandler');

            insert acc1;
            System.assertNotEquals(null,acc1.Id,'Account not Inserted.');
        }

    }
    @isTest
    static void testCustomNotification1() {
        CustomNotificationType ctype = [SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User ur = [SELECT Id FROM User WHERE Profile.Name = 'DRD Profile' LIMIT 1];
        Test.startTest();
            new BSF_CustomNotification()
            .type(ctype.DeveloperName)
            .title('Title of the notification')
            .body('Some useful information')
            .sender(UserInfo.getUserId())
            .target(acc.Id)
            .send(new List<String>{ur.Id});
        Test.stopTest();
    }
    @isTest
    static void testCustomNotification2() {
        CustomNotificationType ctype = [SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User ur = [SELECT Id FROM User WHERE Profile.Name = 'DRD Profile' LIMIT 1];
        Test.startTest();
            new BSF_CustomNotification()
            .type(ctype.DeveloperName)
            .title('Title of the notification')
            .body('Some useful information')
            .sender(UserInfo.getUserId())
            .target(acc.Id)
            .sendToOwner();
        Test.stopTest();
    }
    @isTest
    static void testCustomNotification3() {
        CustomNotificationType ctype = [SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User ur = [SELECT Id FROM User WHERE Profile.Name = 'DRD Profile' LIMIT 1];
        Test.startTest();
            new BSF_CustomNotification()
            .typeId(ctype.Id)
            .title('Title of the notification')
            .body('Some useful information')
            .target(acc.Id)
            .sendToCurrentUser();
        Test.stopTest();
    }
    @isTest
    static void testCustomNotification4() {
        CustomNotificationType ctype = [SELECT Id, DeveloperName FROM CustomNotificationType LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User ur = [SELECT Id FROM User WHERE Profile.Name = 'DRD Profile' LIMIT 1];
        Test.startTest();
            List<BSF_CustomNotification.CustomNotificationRequest> gggList = new List<BSF_CustomNotification.CustomNotificationRequest>();
            BSF_CustomNotification.CustomNotificationRequest ggg = new BSF_CustomNotification.CustomNotificationRequest();
            ggg.notificationTypeName = ctype.DeveloperName;
            ggg.recipientId = ur.Id;
            ggg.notificationTitle = 'Title of the notification';
            ggg.notificationBody = 'Some useful information';
            ggg.targetId = acc.Id;
            ggg.targetPageRef = 'gggggg';
            ggg.sendToCurrentUser = true;
            ggg.sendToOwner = true;
            gggList.add(ggg);
            BSF_CustomNotification.sendNotification(gggList);
        Test.stopTest();
    }
}