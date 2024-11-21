@isTest
public class BSF_Batch_TaxonomyEndDate_Test 
{
	@TestSetup
    public static void setupData()
    {
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
    }
    
    @isTest
    public static void testMethod1()
    {
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c,Version_Key__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE]; 
        Test.startTest();
        BSF_Batch_TaxonomyEndDateHandler batch = new BSF_Batch_TaxonomyEndDateHandler(taxoList[0].version_Key__c,'Bio Recruitment CD',true,null,null);
           database.executeBatch(batch,25);
        Test.StopTest();
    }
}