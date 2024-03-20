@isTest
public class BSFBatchPortfolio_Test {
    @isTest
    Public static void TestMethod1()
    {
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        
        Date stDate = system.today()-100;
        Date enDate = system.today()+365;
        
        BSF_Batch_BSFPortfolio batch = new BSF_Batch_BSFPortfolio(stDate,True);
        database.executeBatch(batch);
        
        BSF_Batch_BSFPortfolio batchV1 = new BSF_Batch_BSFPortfolio('Testbatch',1000,stDate,enDate,True);
        database.executeBatch(batchV1);
        
        BSF_Batch_BSFPortfolio batchV2 = new BSF_Batch_BSFPortfolio('Testbatch',1000,Null,Null,True);
        String chron = '0 0 23 * * ?';        
         String jobid = System.schedule('testScheduledApex', chron, batchV2);
        //database.executeBatch(batchV2);
    }
}