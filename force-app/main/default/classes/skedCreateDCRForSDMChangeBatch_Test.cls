@isTest
private class skedCreateDCRForSDMChangeBatch_Test {

    // The factory already maps a Mobile and a Fixed Site SDM to testCollectionOperation1 over the
    // same window that testDrive1 (Mobile) and testDrive2 (Fixed Site) fall in, which is exactly
    // the in-window / wrong-drive-type pair these tests need.
    private static List<sked_Collection_Operation_SDM__c> getMobileJunction(Id collectionOperationId) {
        return [
            SELECT Id, sked_Collection_Operation__c, sked_Effective_Start_Date__c,
                   sked_Effective_End_Date__c, sked_Staffing_Decision_Matrix__r.RecordType.Name
            FROM sked_Collection_Operation_SDM__c
            WHERE sked_Collection_Operation__c = :collectionOperationId
            AND sked_Staffing_Decision_Matrix__r.RecordType.Name = :skedConstants.DRIVE_TYPE_MOBILE
        ];
    }

    private static Boolean isFlagged(Id driveId) {
        return [SELECT sked_SDM_Change_DCR_Required__c FROM sked_Drive__c WHERE Id = :driveId]
            .sked_SDM_Change_DCR_Required__c;
    }

    @isTest
    static void testExecute_inWindowDriveOfMatchingType_isFlagged() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c mobileDrive = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c collectionOperation =
            (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');

        Test.startTest();
        Database.executeBatch(new skedCreateDCRForSDMChangeBatch(getMobileJunction(collectionOperation.Id)), 200);
        Test.stopTest();

        System.assertEquals(true, isFlagged(mobileDrive.Id),
            'A Mobile drive inside the Mobile SDM window must be flagged for an SDM Change DCR');
    }

    @isTest
    static void testExecute_driveOfDifferentType_isNotFlagged() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c fixedSiteDrive = (sked_Drive__c) testData.get('testDrive2');
        Biomed_Collection_Op_Center__c collectionOperation =
            (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');

        Test.startTest();
        Database.executeBatch(new skedCreateDCRForSDMChangeBatch(getMobileJunction(collectionOperation.Id)), 200);
        Test.stopTest();

        System.assertEquals(false, isFlagged(fixedSiteDrive.Id),
            'A Fixed Site drive must not be flagged when only the Mobile SDM changed');
    }

    @isTest
    static void testExecute_driveOutsideWindow_isNotFlagged() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c mobileDrive = (sked_Drive__c) testData.get('testDrive1');
        Biomed_Collection_Op_Center__c collectionOperation =
            (Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1');
        List<sked_Collection_Operation_SDM__c> junctions = getMobileJunction(collectionOperation.Id);

        sked_Drive__c laterDrive = mobileDrive.clone(false, true, false, false);
        laterDrive.sked_Drive_Date__c = junctions.get(0).sked_Effective_End_Date__c.addDays(30);
        skedHubBase.setBypassAllTriggers(true);
        insert laterDrive;
        skedHubBase.setBypassAllTriggers(false);

        Test.startTest();
        Database.executeBatch(new skedCreateDCRForSDMChangeBatch(junctions), 200);
        Test.stopTest();

        System.assertEquals(false, isFlagged(laterDrive.Id),
            'A drive dated after the SDM mapping window must not be flagged');
    }
}