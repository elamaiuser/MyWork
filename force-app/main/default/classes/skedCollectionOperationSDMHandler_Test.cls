@isTest
private class skedCollectionOperationSDMHandler_Test {

    /**
     * The factory's own Collection Operations already carry SDM mappings, which would collide with
     * the timeline being asserted here, so each test clones one into a mapping-free copy.
     */
    private static Biomed_Collection_Op_Center__c setupCollectionOperation(Map<String, sObject> testData) {
        Biomed_Collection_Op_Center__c collectionOperation =
            ((Biomed_Collection_Op_Center__c) testData.get('testCollectionOperation1')).clone(false, true, false, false);
        collectionOperation.Name = 'SDM Timeline CO';
        collectionOperation.External_Id__c = 'sdm-timeline-co';

        skedHubBase.setBypassAllTriggers(true);
        insert collectionOperation;
        skedHubBase.setBypassAllTriggers(false);
        return collectionOperation;
    }

    private static sked_Staffing_Decision_Matrix__c setupMatrix(String recordTypeDeveloperName) {
        sked_Staffing_Decision_Matrix__c matrix = new sked_Staffing_Decision_Matrix__c(
            RecordTypeId = Schema.SObjectType.sked_Staffing_Decision_Matrix__c
                .getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId()
        );
        insert matrix;
        return matrix;
    }

    private static sked_Staffing_Decision_Matrix__c setupMobileMatrix() {
        return setupMatrix('sked_Mobile');
    }

    private static sked_Staffing_Decision_Matrix__c setupFixedSiteMatrix() {
        return setupMatrix('sked_Fixed_Site');
    }

    private static sked_Drive__c setupMobileDrive(Map<String, sObject> testData, Id collectionOperationId, Date driveDate) {
        sked_Drive__c drive = ((sked_Drive__c) testData.get('testDrive1')).clone(false, true, false, false);
        drive.sked_Collection_Operation__c = collectionOperationId;
        drive.sked_Drive_Date__c = driveDate;

        skedHubBase.setBypassAllTriggers(true);
        insert drive;
        skedHubBase.setBypassAllTriggers(false);
        return drive;
    }

    private static sked_Collection_Operation_SDM__c buildJunction(Id collectionOperationId, Id matrixId,
            Date startDate, Date endDate) {
        return new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = collectionOperationId,
            sked_Staffing_Decision_Matrix__c = matrixId,
            sked_Effective_Start_Date__c = startDate,
            sked_Effective_End_Date__c = endDate
        );
    }

    private static Boolean isFlagged(Id driveId) {
        return [SELECT sked_SDM_Change_DCR_Required__c FROM sked_Drive__c WHERE Id = :driveId]
            .sked_SDM_Change_DCR_Required__c;
    }

    private static Map<String, sObject> setupFactoryData() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        return factory.setupDriveData();
    }

    @isTest
    static void testOnAfterInsert_newMapping_flagsInWindowDrive() {
        Map<String, sObject> testData = setupFactoryData();
        Biomed_Collection_Op_Center__c collectionOperation = setupCollectionOperation(testData);
        sked_Staffing_Decision_Matrix__c matrix = setupMobileMatrix();
        sked_Drive__c drive = setupMobileDrive(testData, collectionOperation.Id, Date.today().addDays(3));

        Test.startTest();
        insert buildJunction(collectionOperation.Id, matrix.Id, Date.today(), Date.today().addDays(30));
        Test.stopTest();

        System.assertEquals(true, isFlagged(drive.Id),
            'Adding an SDM mapping must flag the in-window drive for an SDM Change DCR');
    }

    /**
     * The mapping starts too short to cover the drive and is then extended over it. Were there an
     * after-update fan-out, that extension would flag the drive - so a still-false flag is real
     * evidence the update path stays silent, rather than the drive simply never being in range.
     */
    @isTest
    static void testOnAfterUpdate_extendingWindow_doesNotFlagDrive() {
        Map<String, sObject> testData = setupFactoryData();
        Biomed_Collection_Op_Center__c collectionOperation = setupCollectionOperation(testData);
        sked_Staffing_Decision_Matrix__c matrix = setupMobileMatrix();
        sked_Drive__c drive = setupMobileDrive(testData, collectionOperation.Id, Date.today().addDays(20));
        sked_Collection_Operation_SDM__c junction =
            buildJunction(collectionOperation.Id, matrix.Id, Date.today(), Date.today().addDays(5));
        insert junction;

        Test.startTest();
        junction.sked_Effective_End_Date__c = Date.today().addDays(30);
        update junction;
        Test.stopTest();

        System.assertEquals(false, isFlagged(drive.Id),
            'Editing a mapping window must never raise a DCR - only inserting a mapping fans out');
    }

    @isTest
    static void testOnBeforeInsert_contiguousMapping_isAllowed() {
        Map<String, sObject> testData = setupFactoryData();
        Biomed_Collection_Op_Center__c collectionOperation = setupCollectionOperation(testData);
        sked_Staffing_Decision_Matrix__c matrix = setupMobileMatrix();
        insert buildJunction(collectionOperation.Id, matrix.Id, Date.today().addDays(-10), Date.today().addDays(-1));

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildJunction(collectionOperation.Id, matrix.Id, Date.today(), Date.today().addDays(30)), false);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess(),
            'A mapping starting the day after the previous one ends must be allowed');
    }

    @isTest
    static void testOnBeforeInsert_overlappingMapping_isBlocked() {
        Map<String, sObject> testData = setupFactoryData();
        Biomed_Collection_Op_Center__c collectionOperation = setupCollectionOperation(testData);
        sked_Staffing_Decision_Matrix__c matrix = setupMobileMatrix();
        insert buildJunction(collectionOperation.Id, matrix.Id, Date.today().addDays(-10), Date.today().addDays(5));

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildJunction(collectionOperation.Id, matrix.Id, Date.today(), Date.today().addDays(30)), false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(),
            'A mapping starting before the previous one ends must be blocked as an overlap');
    }

    @isTest
    static void testOnBeforeInsert_mappingWithGap_isBlocked() {
        Map<String, sObject> testData = setupFactoryData();
        Biomed_Collection_Op_Center__c collectionOperation = setupCollectionOperation(testData);
        sked_Staffing_Decision_Matrix__c matrix = setupMobileMatrix();
        insert buildJunction(collectionOperation.Id, matrix.Id, Date.today().addDays(-10), Date.today().addDays(-1));

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildJunction(collectionOperation.Id, matrix.Id, Date.today().addDays(3), Date.today().addDays(30)), false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(),
            'A mapping that does not start the day after the previous one ends must be blocked as a gap');
    }

    /**
     * The previous mapping is still open-ended, so nothing can follow it until it is closed. This is
     * the branch the closed-window overlap test never reaches, and it is the mistake the OOTB related
     * list invites - adding the new row before editing the old one.
     */
    @isTest
    static void testOnBeforeInsert_openEndedPreviousMapping_isBlocked() {
        Map<String, sObject> testData = setupFactoryData();
        Biomed_Collection_Op_Center__c collectionOperation = setupCollectionOperation(testData);
        sked_Staffing_Decision_Matrix__c matrix = setupMobileMatrix();
        insert buildJunction(collectionOperation.Id, matrix.Id, Date.today().addDays(-10), null);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildJunction(collectionOperation.Id, matrix.Id, Date.today(), Date.today().addDays(30)), false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess(),
            'A mapping must not be added while the previous one is still open-ended');
    }

    /**
     * Mobile and Fixed Site timelines on one Collection Operation are independent, so two mappings
     * covering identical dates are legitimate when their SDMs differ in record type. Were the windows
     * grouped by Collection Operation alone, this pair would be rejected as an overlap.
     */
    @isTest
    static void testOnBeforeInsert_sameWindowOnOtherDriveType_isAllowed() {
        Map<String, sObject> testData = setupFactoryData();
        Biomed_Collection_Op_Center__c collectionOperation = setupCollectionOperation(testData);
        insert buildJunction(collectionOperation.Id, setupMobileMatrix().Id, Date.today().addDays(-10), null);

        Test.startTest();
        Database.SaveResult result = Database.insert(
            buildJunction(collectionOperation.Id, setupFixedSiteMatrix().Id, Date.today().addDays(-10), null), false);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess(),
            'Mobile and Fixed Site timelines for the same Collection Operation must not be cross-validated');
    }
}