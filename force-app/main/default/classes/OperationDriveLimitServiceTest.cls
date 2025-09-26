@isTest
public class OperationDriveLimitServiceTest {

    private static Date today = Date.today();

    @TestSetup
    static void setupTestData() {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, sObject> mapTestData = testDataSetup.createAndInsertCommonObjects();

        Biomed_Collection_Op_Center__c co1 = (Biomed_Collection_Op_Center__c)mapTestData.get('COLLECTION_OPP');
        co1.Name = 'Collection Operation 1';
        insert co1;

        Biomed_Collection_Op_Center__c co2 = co1.clone(false, true, false, false);
        co2.Name = 'Collection Operation 2';
        insert co2;

        Time_Block__c tb1 = new Time_Block__c(Name = 'TB1', Start_Time__c = Time.newInstance(8, 0, 0, 0), End_Time__c = Time.newInstance(12, 0, 0, 0));
        Time_Block__c tb2 = new Time_Block__c(Name = 'TB2', Start_Time__c = Time.newInstance(12, 0, 0, 0), End_Time__c = Time.newInstance(16, 0, 0, 0));
        Time_Block__c tb3 = new Time_Block__c(Name = 'TB3', Start_Time__c = Time.newInstance(16, 0, 0, 0), End_Time__c = Time.newInstance(17, 30, 0, 0));
        insert new List<Time_Block__c>{tb1, tb2, tb3};

        tb1 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB1' LIMIT 1];
        tb2 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB2' LIMIT 1];
        tb3 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB3' LIMIT 1];

        co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        co2 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 2' LIMIT 1];

        List<Collection_Operation_Time_Block__c> coTimeBlocks = new List<Collection_Operation_Time_Block__c>{
            new Collection_Operation_Time_Block__c(Collection_Operation__c = co1.Id, Time_Block__c = tb1.Id, Effective_Start_Date__c = today.addDays(-10), Effective_End_Date__c = today.addDays(10)),
            new Collection_Operation_Time_Block__c(Collection_Operation__c = co1.Id, Time_Block__c = tb2.Id, Effective_Start_Date__c = today.addDays(-5), Effective_End_Date__c = null),
            new Collection_Operation_Time_Block__c(Collection_Operation__c = co2.Id, Time_Block__c = tb3.Id, Effective_Start_Date__c = today.addDays(-15), Effective_End_Date__c = today.addDays(15))
        };
        insert coTimeBlocks;
    }

    private static sked_Operation_Drive_Limit__c createTestODL(Id coId, Id tbId, Date startDate, Date endDate) {
        return new sked_Operation_Drive_Limit__c(
            sked_Collection_Operation__c = coId,
            Time_Block__c = tbId,
            sked_Effective_Start_Date__c = startDate,
            sked_Effective_End_Date__c = endDate
        );
    }

    @isTest
    static void testValidOperationDriveLimit() {
        Biomed_Collection_Op_Center__c co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Time_Block__c tb1 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB1' LIMIT 1];

        Test.startTest();
        Database.SaveResult result = Database.insert(createTestODL(co1.Id, tb1.Id, today, today.addDays(5)), false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Record inserted successfully');
        Assert.areEqual(0, result.getErrors().size(), 'No errors');
    }

    @isTest
    static void testInvalidTimeBlock() {
        Biomed_Collection_Op_Center__c co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Time_Block__c tb3 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB3' LIMIT 1];

        Test.startTest();
        Database.SaveResult result = Database.insert(createTestODL(co1.Id, tb3.Id, today, today.addDays(5)), false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Insertion failed');
        Assert.areEqual(Label.ODL_TimeBlockNotAssociatedWithCO, result.getErrors()[0].getMessage(), 'Has error');
    }

    @isTest
    static void testInvalidDateRange_StartDateBefore() {
        Biomed_Collection_Op_Center__c co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Time_Block__c tb1 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB1' LIMIT 1];

        Test.startTest();
        Database.SaveResult result = Database.insert(createTestODL(co1.Id, tb1.Id, today.addDays(-20), today.addDays(5)), false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Insertion failed');
        Assert.areEqual(Label.ODL_DateRangeOutsideTimeBlock, result.getErrors()[0].getMessage(), 'Has error');
    }

    @isTest
    static void testInvalidDateRange_EndDateAfter() {
        Biomed_Collection_Op_Center__c co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Time_Block__c tb1 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB1' LIMIT 1];

        Test.startTest();
        Database.SaveResult result = Database.insert(createTestODL(co1.Id, tb1.Id, today, today.addDays(20)), false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Insertion failed');
        Assert.areEqual(Label.ODL_DateRangeOutsideTimeBlock, result.getErrors()[0].getMessage(), 'Has Error');
    }

    @isTest
    static void testValidOpenEndedDateRange() {
        Biomed_Collection_Op_Center__c co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Time_Block__c tb2 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB2' LIMIT 1];

        Test.startTest();
        Database.SaveResult result = Database.insert(createTestODL(co1.Id, tb2.Id, today, today.addDays(100)), false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Record inserted successfully');
    }
    
    @isTest
    static void testODLUpdate() {
        Biomed_Collection_Op_Center__c co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Time_Block__c tb1 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB1' LIMIT 1];

        Database.SaveResult result = Database.insert(createTestODL(co1.Id, tb1.Id, today, today.addDays(5)), false);
        Test.startTest();
        Database.SaveResult updateResult = Database.update(new sked_Operation_Drive_Limit__c( Id = result.getId(), sked_Effective_End_Date__c = today.addDays(7) ), false);
        Test.stopTest();

        Assert.isTrue(updateResult.isSuccess(), 'Record inserted successfully');
        Assert.areEqual(0, updateResult.getErrors().size(), 'No errors');
    }

    @isTest
    static void testBulkOperation() {
        Biomed_Collection_Op_Center__c co1 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 1' LIMIT 1];
        Biomed_Collection_Op_Center__c co2 = [SELECT Id FROM Biomed_Collection_Op_Center__c WHERE Name = 'Collection Operation 2' LIMIT 1];
        Time_Block__c tb1 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB1' LIMIT 1];
        Time_Block__c tb3 = [SELECT Id FROM Time_Block__c WHERE Name = 'TB3' LIMIT 1];

        List<sked_Operation_Drive_Limit__c> odls = new List<sked_Operation_Drive_Limit__c>{
            createTestODL(co1.Id, tb1.Id, today, today.addDays(5)),         // Valid
            createTestODL(co1.Id, tb3.Id, today, today.addDays(5)),         // Invalid TB
            createTestODL(co2.Id, tb3.Id, today.addDays(20), today.addDays(25)) // Invalid dates
        };

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(odls, false);
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess(), 'Record inserted successfully!');
        Assert.isFalse(results[1].isSuccess(), 'Insertion failed: invalid time block');
        Assert.isFalse(results[2].isSuccess(), 'Insertion failed: invalid date range');

        Assert.areEqual(Label.ODL_TimeBlockNotAssociatedWithCO, results[1].getErrors()[0].getMessage());
        Assert.areEqual(Label.ODL_DateRangeOutsideTimeBlock, results[2].getErrors()[0].getMessage());
    }
}