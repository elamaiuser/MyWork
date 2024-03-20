@isTest
private class skedPostJobMigrationBatch_Test {
    @isTest
    static void skedPostJobMigrationBatch_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOp = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Location__c testLocation = (sked__Location__c) mapTestData.get('testLocation1');
        
        List<string> weekdays = new List<string>();
        weekdays.add('sunday');
        weekdays.add('monday');
        weekdays.add('tuesday');
        weekdays.add('wednesday');
        weekdays.add('thursday');
        weekdays.add('friday');
        weekdays.add('saturday');
        
        List<string> directions = new List<string>();
        directions.add('CO to Site');
        directions.add('Site to CO');
        
        List<skedAsyncJobHandler.travelTimeBreakdownModel> models = new List<skedAsyncJobHandler.travelTimeBreakdownModel>();
        for (string direction : directions) {
            for (string weekday : weekdays) {
                skedAsyncJobHandler.travelTimeBreakdownModel model = new skedAsyncJobHandler.travelTimeBreakdownModel();
                model.siteId = testLocation.Id;
                model.weekday = weekday;
                model.endOfWindow = Time.newInstance(23, 59, 0, 0);
                model.startOfWindow = Time.newInstance(0, 0, 0, 0);
                model.direction = direction;
                model.travelDistance = 5;
                model.travelTime = 30;
                models.add(model);
            }
        }

        Test.startTest();
        sked_Site_Collection_Operation__c testSco = new sked_Site_Collection_Operation__c(
            sked_Site__c = testLocation.Id,
            sked_Collection_Operation__c = testCollectionOp.Id,
            sked_Start_Date__c = testDataFactory.summary.startDate,
            sked_End_Date__c = testDataFactory.summary.endDate,
            sked_Travel_Time_Breakdown_JSON__c = JSON.serialize(models),
            sked_Travel_Time_Breakdown_JSON_2__c = JSON.serialize(models)
        );
        insert testSco;

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Job__c testDriveJob = new sked__Job__c(
            sked_Drive__c = testDrive.Id,
            sked__Region__c = testRegion.Id,
            sked__Start__c = System.today().addDays(5),
            sked__Finish__c = System.today().addDays(6),
            sked__Location__c = testLocation.Id,
            sked_Resource_Role__c = '2RBC',
            sked_MigrationID__c = 'migration-id',
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        sked__Job__c testDriveJob2 = new sked__Job__c(
            sked_Drive__c = testDrive.Id,
            sked__Region__c = testRegion.Id,
            sked__Start__c = System.today().addDays(5),
            sked__Finish__c = System.today().addDays(6),
            sked__Location__c = testLocation.Id,
            sked_Resource_Role__c = 'Apheresis',
            sked_MigrationID__c = 'migration-id-2',
            sked_Travel_Time__c = 45,
            sked_Travel_Time2__c = 45
        );
        insert new List<sked__Job__c>{testDriveJob, testDriveJob2};

        sked_Role_Time_Detail__c testRtd = new sked_Role_Time_Detail__c(
            sked_Effective_Start_Date__c = System.today().addDays(-100),
            sked_Effective_End_Date__c = System.today().addDays(100), 
            sked_Drive_Type__c = 'Mobile',
            sked_Mobile_Type__c = 'Outside',
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Collection_Operation__c = testCollectionOp.Id
        );

        sked_Role_Time_Detail__c testRtdGlobal = new sked_Role_Time_Detail__c(
            sked_Effective_Start_Date__c = System.today().addDays(-100),
            sked_Effective_End_Date__c = System.today().addDays(100), 
            sked_Drive_Type__c = 'Mobile',
            sked_Mobile_Type__c = 'Outside',
            sked_Resource_Role_Group__c = 'Staff roles',
            sked_Type__c = 'Global'
        );
        insert new List<sked_Role_Time_Detail__c>{testRtd, testRtdGlobal};

            Database.executeBatch(new skedPostJobMigrationBatch());
        Test.stopTest();
    }
}