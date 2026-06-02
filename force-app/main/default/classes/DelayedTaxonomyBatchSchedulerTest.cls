@isTest
public class DelayedTaxonomyBatchSchedulerTest {

    @testSetup
    static void setupData() {
        // Create Taxonomy_Run__c records with various types
        List<Taxonomy_Run__c> runs = new List<Taxonomy_Run__c>();

        runs.add(new Taxonomy_Run__c(
            Taxo_Record_Type__c = BSF_Constants.BIO_COLLECTION_RECORD_TYPE,
            Future_Version_Number__c = 123,
            Sequence__c = 1,
            Run_Date__c = Date.today(),
            Status__c = 'Pending'
        ));

        runs.add(new Taxonomy_Run__c(
            Taxo_Record_Type__c = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,
            Future_Version_Number__c = 283,
            Sequence__c = 2,
            Run_Date__c = Date.today(),
            Status__c = 'Pending'
        ));

        runs.add(new Taxonomy_Run__c(
            Taxo_Record_Type__c = 'Other_Record_Type',
            Future_Version_Number__c = 456,
            Sequence__c = 3,
            Run_Date__c = Date.today(),
            Status__c = 'Pending'
        ));

        insert runs;
    }

    @isTest
    static void testSchedulerBioCollection() {
      // Change all records to non-pending
        List<Taxonomy_Run__c> allRuns = [SELECT Id FROM Taxonomy_Run__c];
        for (Taxonomy_Run__c run : allRuns) {
            run.Status__c = 'Completed';
        }
        update allRuns;

        // Create a fresh pending record for recruitment
        Taxonomy_Run__c newRun = new Taxonomy_Run__c(
            Taxo_Record_Type__c = BSF_Constants.BIO_COLLECTION_RECORD_TYPE,
            Future_Version_Number__c =216,
            Sequence__c = 1,
            Run_Date__c = Date.today(),
            Status__c = 'Pending'
        );
        insert newRun;

        Test.startTest();
        DelayedTaxonomyBatchScheduler scheduler = new DelayedTaxonomyBatchScheduler();
        scheduler.execute(null);
        Test.stopTest();

        Taxonomy_Run__c updated = [SELECT Status__c FROM Taxonomy_Run__c WHERE Id = :newRun.Id];
        //System.assertEquals('Processing', updated.Status__c);

   
    }

    @isTest
    static void testSchedulerBioRecruitment() {
        // Change all records to non-pending
        List<Taxonomy_Run__c> allRuns = [SELECT Id FROM Taxonomy_Run__c];
        for (Taxonomy_Run__c run : allRuns) {
            run.Status__c = 'Completed';
        }
        update allRuns;

        // Create a fresh pending record for recruitment
        Taxonomy_Run__c newRun = new Taxonomy_Run__c(
            Taxo_Record_Type__c = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,
            Future_Version_Number__c =216,
            Sequence__c = 1,
            Run_Date__c = Date.today(),
            Status__c = 'Pending'
        );
        insert newRun;

        Test.startTest();
        DelayedTaxonomyBatchScheduler scheduler = new DelayedTaxonomyBatchScheduler();
        scheduler.execute(null);
        Test.stopTest();

        Taxonomy_Run__c updated = [SELECT Status__c FROM Taxonomy_Run__c WHERE Id = :newRun.Id];
        //System.assertEquals('Processing', updated.Status__c);
    }

    @isTest
    static void testSchedulerOtherType() {
      // Change all records to non-pending
        List<Taxonomy_Run__c> allRuns = [SELECT Id FROM Taxonomy_Run__c];
        for (Taxonomy_Run__c run : allRuns) {
            run.Status__c = 'Completed';
        }
        update allRuns;

        // Create a fresh pending record for recruitment
        Taxonomy_Run__c newRun = new Taxonomy_Run__c(
            Taxo_Record_Type__c = 'Bio Sickle Cell Portfolio',
            Future_Version_Number__c =216,
            Sequence__c = 1,
            Run_Date__c = Date.today(),
            Status__c = 'Pending'
        );
        insert newRun;

        Test.startTest();
        DelayedTaxonomyBatchScheduler scheduler = new DelayedTaxonomyBatchScheduler();
        scheduler.execute(null);
        Test.stopTest();

        Taxonomy_Run__c updated = [SELECT Status__c FROM Taxonomy_Run__c WHERE Id = :newRun.Id];
        //System.assertEquals('Processing', updated.Status__c);
    }
}