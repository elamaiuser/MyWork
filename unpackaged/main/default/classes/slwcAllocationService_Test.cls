@isTest
private class slwcAllocationService_Test { 
    @isTest
    static void getResourceData_Test_AssetsOnly() {
        List<String> dates = new List<String>();
        Date startDate = System.today();
        Date endDate = System.today().addDays(10);

        while (startDate < endDate) {
            dates.add('' + startDate.year() + '-' + startDate.month() + '-' + startDate.day());
            startDate = startDate.addDays(1);
        }
        dates.add('' + endDate.year() + '-' + endDate.month() + '-' + endDate.day());

        List<Id> accountIds = new List<Id>(); 
        List<Account> testAccounts = [SELECT Id FROM Account];
        for (Account account : testAccounts) { accountIds.add(account.Id); }

        List<Id> collectionOpIds = new List<Id>(); 
        List<Biomed_Collection_Op_Center__c> testCollectionOps = [SELECT Id FROM Biomed_Collection_Op_Center__c];
        for (Biomed_Collection_Op_Center__c collectionOp : testCollectionOps) { collectionOpIds.add(collectionOp.Id); }

        List<Id> jobIds = new List<Id>(); 
        List<sked__Job__c> testJobs = [SELECT Id FROM sked__Job__c];
        for (sked__Job__c job : testJobs) { jobIds.add(job.Id); }

        List<Id> locationIds = new List<Id>(); 
        List<sked__Location__c> testLocations = [SELECT Id FROM sked__Location__c];
        for (sked__Location__c location : testLocations) { locationIds.add(location.Id); }

        slwcAllocationService.getResourceDataRequestModel model = new slwcAllocationService.getResourceDataRequestModel();
        model.accountIds = accountIds;
        model.collectionOperationIds = collectionOpIds;
        model.excludedActivityIds = new List<string>();
        model.excludedDriveIds = new List<string>();
        model.locationIds = locationIds;
        model.inputDates = dates;
        model.jobIds = jobIds;
        model.pageSize = 50;
        model.pageNo = 1;
        model.timezoneSidId = UserInfo.getTimeZone().getID();
        model.getAssetsOnly = true;

        Test.startTest();
            slwcAuraResult result = slwcAllocationService.getResourceData(model);
        Test.stopTest();

        System.assertNotEquals(null, result.returnedData);
    }

    @isTest
    static void getResourceData_Test() {
        List<String> dates = new List<String>();
        Date startDate = System.today();
        Date endDate = System.today().addDays(10);

        while (startDate < endDate) {
            dates.add('' + startDate.year() + '-' + startDate.month() + '-' + startDate.day());
            startDate = startDate.addDays(1);
        }
        dates.add('' + endDate.year() + '-' + endDate.month() + '-' + endDate.day());

        List<Id> accountIds = new List<Id>(); 
        List<Account> testAccounts = [SELECT Id FROM Account];
        for (Account account : testAccounts) { accountIds.add(account.Id); }

        List<Id> collectionOpIds = new List<Id>(); 
        List<Biomed_Collection_Op_Center__c> testCollectionOps = [SELECT Id FROM Biomed_Collection_Op_Center__c];
        for (Biomed_Collection_Op_Center__c collectionOp : testCollectionOps) { collectionOpIds.add(collectionOp.Id); }

        List<Id> jobIds = new List<Id>(); 
        List<sked__Job__c> testJobs = [SELECT Id FROM sked__Job__c];
        for (sked__Job__c job : testJobs) { jobIds.add(job.Id); }

        List<Id> locationIds = new List<Id>(); 
        List<sked__Location__c> testLocations = [SELECT Id FROM sked__Location__c];
        for (sked__Location__c location : testLocations) { locationIds.add(location.Id); }

        slwcAllocationService.getResourceDataRequestModel model = new slwcAllocationService.getResourceDataRequestModel();
        model.accountIds = accountIds;
        model.collectionOperationIds = collectionOpIds;
        model.excludedActivityIds = new List<string>();
        model.excludedDriveIds = new List<string>();
        model.locationIds = locationIds;
        model.inputDates = dates;
        model.jobIds = jobIds;
        model.pageSize = 50;
        model.pageNo = 1;
        model.timezoneSidId = UserInfo.getTimeZone().getID();
        model.getAssetsOnly = false;

        Test.startTest();
            slwcAuraResult result = slwcAllocationService.getResourceData(model);
        Test.stopTest();

        System.assertNotEquals(null, result.returnedData);
    }

    @isTest
    static void getAssetDataCompact_Test() {
        List<String> dates = new List<String>();
        Date startDate = System.today();
        Date endDate = System.today().addDays(10);

        while (startDate < endDate) {
            dates.add('' + startDate.year() + '-' + startDate.month() + '-' + startDate.day());
            startDate = startDate.addDays(1);
        }
        dates.add('' + endDate.year() + '-' + endDate.month() + '-' + endDate.day());

        List<Id> accountIds = new List<Id>(); 
        List<Account> testAccounts = [SELECT Id FROM Account];
        for (Account account : testAccounts) { accountIds.add(account.Id); }

        List<Id> collectionOpIds = new List<Id>(); 
        List<Biomed_Collection_Op_Center__c> testCollectionOps = [SELECT Id FROM Biomed_Collection_Op_Center__c];
        for (Biomed_Collection_Op_Center__c collectionOp : testCollectionOps) { collectionOpIds.add(collectionOp.Id); }

        List<Id> jobIds = new List<Id>(); 
        List<sked__Job__c> testJobs = [SELECT Id FROM sked__Job__c];
        for (sked__Job__c job : testJobs) { jobIds.add(job.Id); }

        List<Id> locationIds = new List<Id>(); 
        List<sked__Location__c> testLocations = [SELECT Id FROM sked__Location__c];
        for (sked__Location__c location : testLocations) { locationIds.add(location.Id); }

        slwcAllocationService.getResourceDataRequestModel model = new slwcAllocationService.getResourceDataRequestModel();
        model.accountIds = accountIds;
        model.collectionOperationIds = collectionOpIds;
        model.locationIds = locationIds;
        model.inputDates = dates;
        model.jobIds = jobIds;
        model.pageSize = 50;
        model.pageNo = 1;
        model.timezoneSidId = UserInfo.getTimeZone().getID();
        model.getAssetsOnly = true;

        Test.startTest();
            slwcAuraResult result = slwcAllocationService.getAssetDataCompact(model);
        Test.stopTest();

        System.assertNotEquals(null, result.returnedData);

    }

    @isTest
    static void getLinkedDrivesResourceIds_Test() {

    }

    @testSetup
    static void makeData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
    }
}