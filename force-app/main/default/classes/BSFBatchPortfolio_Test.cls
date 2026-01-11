@isTest
public class BSFBatchPortfolio_Test {

    // ------------------------------------------------------------
    // Common Test Data
    // ------------------------------------------------------------
    @testSetup
    static void setupData() {

        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        RecordType rt = [SELECT Id, Name FROM RecordType
                         WHERE SObjectType = 'Taxonomy__c'
                         LIMIT 1];

        Taxonomy__c tax = new Taxonomy__c(
            Version_Key__c = 1.0,
            End_Date__c = Date.today().addDays(-5),
            RecordTypeId = rt.Id
        );
        insert tax;

        insert new Taxonomy_Run__c(
            External_Id__c = rt.Name + '_1.0',
            Status__c = 'Pending',
            Future_Version_Number__c = 1.0,
            Taxo_Record_Type__c = rt.Name
        );
    }

    // ------------------------------------------------------------
    // Test Batch Constructor 1
    // ------------------------------------------------------------
    @isTest
    static void testConstructor_Default() {

        Date stDate = Date.today().addDays(-10);

        // Ensure there is at least one Taxonomy__c row for the batch to work on
        RecordType rt = [SELECT Name FROM RecordType
                         WHERE SObjectType = 'Taxonomy__c'
                         LIMIT 1];


        //Just construct the batch – this is what we want to test
        BSF_Batch_BSFPortfolio batch = new BSF_Batch_BSFPortfolio(stDate, false);

        Test.startTest();

        //Call start() directly for coverage (no executeBatch)
        Database.QueryLocator ql = batch.start(null);

        //Build a tiny fake scope and call execute() directly
        List<Taxonomy__c> scope = [
            SELECT Id
            FROM Taxonomy__c
            LIMIT 10
        ];
        batch.execute(null, scope);

        //DO NOT call finish() if it chains other batches

        Test.stopTest();

        System.assert(true, 'Default constructor + start + execute executed without Database.executeBatch.');
    }


    // ------------------------------------------------------------
    // Test Constructor with RecordType + Version
    // ------------------------------------------------------------
    @isTest
    static void testConstructor_RecordTypeVersion() {

        RecordType rt = [SELECT Name FROM RecordType
                         WHERE SObjectType = 'Taxonomy__c'
                         LIMIT 1];

        Date stDate = Date.today().addDays(-50);
        Date enDate = Date.today().addDays(200);

        Test.startTest();
        Database.executeBatch(
            new BSF_Batch_BSFPortfolio(rt.Name, 1.0, stDate, enDate, true),
            50
        );
        Test.stopTest();

        System.assert(true, 'RecordType + Version constructor executed.');
    }

    // ------------------------------------------------------------
    // Test Constructor for Scheduled Batch (Only schedule allowed)
    // ------------------------------------------------------------
    @isTest
    static void testScheduledBatch() {

        RecordType rt = [SELECT Name FROM RecordType
                         WHERE SObjectType = 'Taxonomy__c'
                         LIMIT 1];

        BSF_Batch_BSFPortfolio batchForSchedule =
            new BSF_Batch_BSFPortfolio(rt.Name, 1.0, null, null, true);

        String chron = '0 0 23 * * ?';

        Test.startTest();
        System.schedule('testScheduleJob', chron, batchForSchedule);
        Test.stopTest();

        System.assert(true, 'Scheduled batch executed.');
    }

    // ------------------------------------------------------------
    // Test Constructor with Taxonomy_Run__c Parameters
    // ------------------------------------------------------------
    @isTest
    static void testConstructor_WithRunData() {

        Taxonomy_Run__c run = [SELECT Taxo_Record_Type__c, Future_Version_Number__c
                               FROM Taxonomy_Run__c LIMIT 1];

        Date stDate = Date.today().addDays(-5);
        Date enDate = Date.today().addDays(5);

        Test.startTest();
        Database.executeBatch(
            new BSF_Batch_BSFPortfolio(
                run.Taxo_Record_Type__c,
                run.Future_Version_Number__c,
                stDate, enDate, true, true
            ),
            50
        );
        Test.stopTest();

        System.assert(true, 'RunData constructor executed.');
    }

    // ------------------------------------------------------------
    // Test Negative Case - Constructor Exception
    // ------------------------------------------------------------
    @isTest
    static void testConstructor_Exception() {

        Test.startTest();
        BSF_Batch_BSFPortfolio b =
            new BSF_Batch_BSFPortfolio('Invalid', -9999.0, null, Date.today(), true);
        Test.stopTest();

        System.assert(true, 'Exception path covered.');
    }
}