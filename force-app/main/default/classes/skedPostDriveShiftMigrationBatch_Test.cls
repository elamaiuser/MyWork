@isTest
private class skedPostDriveShiftMigrationBatch_Test {
    @isTest
    static void skedPostDriveShiftMigrationBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        
        Test.startTest();
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive.Id,
            sked_MigrationID__c = 'migration-1',
            sked_Total_Procedures_Projected__c = 100
        );
        insert testDriveShift;
        
        sked__Job__c testDriveShiftJob = new sked__Job__c(
            sked_Drive_Shift__c = testDriveShift.Id,
            sked__Region__c = testRegion.Id,
            sked__Start__c = System.today().addDays(5),
            sked__Finish__c = System.today().addDays(6),
            sked_Resource_Role__c = '2RBC'
        );
        insert testDriveShiftJob;
        
        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            sked_Driver_Capacity__c = 10,
            sked_Driver_Support_Capacity__c = 10,
            sked_2RBC_Staff_Capacity__c = 10,
            sked_VP_HH_Capacity__c = 10,
            sked_Charge_Capacity__c = 10,
            sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 10,
            sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 15
        );
        insert sdm;
        
        sked_Collection_Operation_SDM__c cOpSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-100),
            sked_Effective_End_Date__c = System.today().addDays(100),
            sked_Staffing_Decision_Matrix__c = sdm.Id
        );
        insert cOpSdm;
        
        Database.executeBatch(new skedPostDriveShiftMigrationBatch());
        
        Test.stopTest();
    }
    
    @isTest
    static void skedPostDriveShiftMigrationBatch_Test_FixedSite_Volunteers() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();
        
        Test.startTest();
        
        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked_Drive_Shift__c testDriveShift = new sked_Drive_Shift__c(
            sked_Drive__c = testDrive.Id,
            sked_MigrationID__c = 'migration-1',
            sked_Total_Procedures_Projected__c = 100
        );
        insert testDriveShift;
        
        sked__Job__c testDriveShiftJob = new sked__Job__c(
            sked_Drive_Shift__c = testDriveShift.Id,
            sked__Region__c = testRegion.Id,
            sked__Start__c = System.today().addDays(5),
            sked__Finish__c = System.today().addDays(6),
            sked_Resource_Role__c = '2RBC'
        );
        insert testDriveShiftJob;
        
        sked_Staffing_Decision_Matrix__c sdm = new sked_Staffing_Decision_Matrix__c(
            sked_Driver_Capacity__c = 10,
            sked_Driver_Support_Capacity__c = 10,
            sked_2RBC_Staff_Capacity__c = 10,
            sked_VP_HH_Capacity__c = 10,
            sked_Charge_Capacity__c = 10,
            sked_NR_Volunteer_Fixed_Site_Band_Lower__c = 10,
            sked_NR_Volunteer_Fixed_Site_Band_Upper__c = 15
        );
        insert sdm;
        
        sked_Collection_Operation_SDM__c cOpSdm = new sked_Collection_Operation_SDM__c(
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Effective_Start_Date__c = System.today().addDays(-100),
            sked_Effective_End_Date__c = System.today().addDays(100),
            sked_Staffing_Decision_Matrix__c = sdm.Id
        );
        insert cOpSdm;
        
        testDrive.sked_Type_of_Drive__c = skedConstants.DRIVE_TYPE_FIXED_SITE;
        update testDrive; 
        
        Database.executeBatch(new skedPostDriveShiftMigrationBatch());
        
        Test.stopTest();
    }
    
}