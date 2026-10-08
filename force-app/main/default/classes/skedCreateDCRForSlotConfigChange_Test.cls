@isTest
private class skedCreateDCRForSlotConfigChange_Test {

    private static final String WHOLE_BLOOD_JSON = '{"slotDuration":15}';

    @testSetup
    static void setupTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        testDataFactory.setupCommonTestData();
        testDataFactory.setupDriveData();
    }

    @isTest
    static void execute_flagsTheMobileDrivesAMobileConfigurationReaches() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(skedConstants.DRIVE_TYPE_MOBILE, NULL);
        insert slotConfig;

        Test.startTest();
        Database.executeBatch(new skedCreateDCRForSlotConfigChangeBatch(new List<sked_Collection_Operation_Slot_Config__c>{ slotConfig }));
        Test.stopTest();

        System.assertEquals(
            true,
            getDrive('Mobile').sked_Slot_Config_Change_DCR_Required__c,
            'A Mobile configuration row must raise a Drive Change Request for the Mobile drives in its Collection Operation'
        );
        System.assertEquals(
            false,
            getDrive('Fixed Site').sked_Slot_Config_Change_DCR_Required__c,
            'A Mobile configuration row must not reach Fixed Site drives'
        );
    }

    @isTest
    static void execute_flagsOnlyTheMatchingFixedSiteOperationType() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(skedConstants.DRIVE_TYPE_FIXED_SITE, skedConstants.OPERATION_TYPE_WB);
        insert slotConfig;

        Test.startTest();
        Database.executeBatch(new skedCreateDCRForSlotConfigChangeBatch(new List<sked_Collection_Operation_Slot_Config__c>{ slotConfig }));
        Test.stopTest();

        System.assertEquals(
            true,
            getDrive('Fixed Site').sked_Slot_Config_Change_DCR_Required__c,
            'The Non Integrated WB fixed site drive must be flagged by a Non Integrated WB configuration row'
        );
    }

    @isTest
    static void execute_ignoresAFixedSiteOperationTypeThatDoesNotMatch() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(skedConstants.DRIVE_TYPE_FIXED_SITE, skedConstants.OPERATION_TYPE_INTEGRATED);
        insert slotConfig;

        Test.startTest();
        Database.executeBatch(new skedCreateDCRForSlotConfigChangeBatch(new List<sked_Collection_Operation_Slot_Config__c>{ slotConfig }));
        Test.stopTest();

        System.assertEquals(
            false,
            getDrive('Fixed Site').sked_Slot_Config_Change_DCR_Required__c,
            'An Integrated configuration row must not reach a Non Integrated WB fixed site drive'
        );
    }

    @isTest
    static void execute_ignoresDrivesOutsideTheEffectivePeriod() {
        sked_Collection_Operation_Slot_Config__c slotConfig = buildSlotConfig(skedConstants.DRIVE_TYPE_MOBILE, NULL);
        slotConfig.sked_Effective_Start_Date__c = getDrive('Mobile').sked_Drive_Date__c.addDays(1);
        insert slotConfig;

        Test.startTest();
        Database.executeBatch(new skedCreateDCRForSlotConfigChangeBatch(new List<sked_Collection_Operation_Slot_Config__c>{ slotConfig }));
        Test.stopTest();

        System.assertEquals(
            false,
            getDrive('Mobile').sked_Slot_Config_Change_DCR_Required__c,
            'A drive dated before the configuration takes effect keeps its current slots'
        );
    }

    /*********************************************************** Test helpers ***********************************************************/
    private static sked_Collection_Operation_Slot_Config__c buildSlotConfig(String driveType, String fixedSiteOperationType) {
        return new sked_Collection_Operation_Slot_Config__c(
            sked_Collection_Operation__c = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1].Id,
            sked_Drive_Type__c = driveType,
            sked_Fixed_Site_Operation_Type__c = fixedSiteOperationType,
            sked_Procedure_Type__c = skedConstants.SLOT_CONFIG_PROCEDURE_TYPE_WHOLE_BLOOD,
            sked_Slot_Configuration__c = WHOLE_BLOOD_JSON,
            sked_Effective_Start_Date__c = Date.today()
        );
    }

    private static sked_Drive__c getDrive(String typeOfDrive) {
        return [
            SELECT Id, sked_Drive_Date__c, sked_Slot_Config_Change_DCR_Required__c
            FROM sked_Drive__c
            WHERE sked_Type_of_Drive__c = :typeOfDrive
            LIMIT 1
        ];
    }
}
