@isTest
private class skedUpdateDcrCountQueueable_Test {

    @isTest
    static void execute_updatesCountToMatchPendingDCRs() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        // Create 3 Pending DCRs
        List<sked_Drive_Change_Request__c> dcrs = new List<sked_Drive_Change_Request__c>();
        for (Integer i = 0; i < 3; i++) {
            dcrs.add(new sked_Drive_Change_Request__c(
                sked_Drive__c = testDrive.Id,
                sked_New_Collection_Operation__c = opCenter.Id,
                sked_Status__c = 'Pending'
            ));
        }
        insert dcrs;

        // Force the count to a wrong value so we can verify the Queueable corrects it.
        skedHubBase.BypassUpdateTriggers = true;
        update new sked_Drive__c(Id = testDrive.Id, sked_Num_Of_Pending_DCRs__c = 999);
        skedHubBase.BypassUpdateTriggers = false;

        Test.startTest();
        System.enqueueJob(new skedUpdateDcrCountQueueable(new Set<Id>{ testDrive.Id }));
        Test.stopTest();

        sked_Drive__c reloaded = [
            SELECT sked_Num_Of_Pending_DCRs__c
            FROM sked_Drive__c
            WHERE Id = :testDrive.Id
        ];
        System.assertEquals(3, reloaded.sked_Num_Of_Pending_DCRs__c,
            'Queueable should refresh pending DCR count to the actual value');
    }

    @isTest
    static void execute_excludesNonPendingDCRsFromCount() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');

        // 2 Pending + 1 Cancelled => expected count = 2
        insert new List<sked_Drive_Change_Request__c>{
            new sked_Drive_Change_Request__c(
                sked_Drive__c = testDrive.Id,
                sked_New_Collection_Operation__c = opCenter.Id,
                sked_Status__c = 'Pending'
            ),
            new sked_Drive_Change_Request__c(
                sked_Drive__c = testDrive.Id,
                sked_New_Collection_Operation__c = opCenter.Id,
                sked_Status__c = 'Pending'
            ),
            new sked_Drive_Change_Request__c(
                sked_Drive__c = testDrive.Id,
                sked_New_Collection_Operation__c = opCenter.Id,
                sked_Status__c = 'Cancelled'
            )
        };

        Test.startTest();
        System.enqueueJob(new skedUpdateDcrCountQueueable(new Set<Id>{ testDrive.Id }));
        Test.stopTest();

        sked_Drive__c reloaded = [
            SELECT sked_Num_Of_Pending_DCRs__c
            FROM sked_Drive__c
            WHERE Id = :testDrive.Id
        ];
        System.assertEquals(2, reloaded.sked_Num_Of_Pending_DCRs__c,
            'Cancelled DCRs should not be counted as pending');
    }

    @isTest
    static void execute_handlesNullAndEmptyInputGracefully() {
        Test.startTest();
        System.enqueueJob(new skedUpdateDcrCountQueueable(new Set<Id>()));
        System.enqueueJob(new skedUpdateDcrCountQueueable(null));
        Test.stopTest();
        // No exception thrown = pass
    }
}