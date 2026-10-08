@isTest
private class skedStaffingDecisionMatrixHandler_Test {

    /**
     * The factory maps its Mobile matrix to testCollectionOperation1 over a window that testDrive1
     * falls in, so editing that matrix is enough to exercise the whole fan-out.
     */
    private static sked_Staffing_Decision_Matrix__c getMobileMatrix() {
        List<sked_Staffing_Decision_Matrix__c> matrices = [
            SELECT Id, sked_WB_Hourly_Capacity__c, sked_NR_Volunteer_Fixed_Site_Band_Upper__c
            FROM sked_Staffing_Decision_Matrix__c
            WHERE RecordType.Name = :skedConstants.DRIVE_TYPE_MOBILE
        ];
        return matrices.get(0);
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
    static void testOnAfterUpdate_capacityChange_flagsMappedInWindowDrive() {
        Map<String, sObject> testData = setupFactoryData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Staffing_Decision_Matrix__c matrix = getMobileMatrix();

        Test.startTest();
        matrix.sked_WB_Hourly_Capacity__c = 9.9;
        update matrix;
        Test.stopTest();

        System.assertEquals(true, isFlagged(drive.Id),
            'Editing an SDM capacity must flag the in-window drives of every Collection Operation mapped to it');
    }

    /**
     * The NR Volunteer Band fields do not feed drive staffing, so editing one must stay silent -
     * this is what the explicit allowlist buys over diffing every field on the object.
     */
    @isTest
    static void testOnAfterUpdate_nonStaffingFieldChange_doesNotFlagDrive() {
        Map<String, sObject> testData = setupFactoryData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked_Staffing_Decision_Matrix__c matrix = getMobileMatrix();

        Test.startTest();
        matrix.sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 71;
        update matrix;
        Test.stopTest();

        System.assertEquals(false, isFlagged(drive.Id),
            'Editing a field outside the staffing allowlist must not raise a DCR');
    }

    @isTest
    static void testOnAfterUpdate_capacityChange_doesNotFlagDriveOfOtherType() {
        Map<String, sObject> testData = setupFactoryData();
        sked_Drive__c fixedSiteDrive = (sked_Drive__c) testData.get('testDrive2');
        sked_Staffing_Decision_Matrix__c matrix = getMobileMatrix();

        Test.startTest();
        matrix.sked_WB_Hourly_Capacity__c = 9.9;
        update matrix;
        Test.stopTest();

        System.assertEquals(false, isFlagged(fixedSiteDrive.Id),
            'Editing the Mobile matrix must leave Fixed Site drives alone');
    }
}