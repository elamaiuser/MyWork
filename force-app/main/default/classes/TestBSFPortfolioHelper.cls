/**
 * This Class contains testMethods for BSFPortfolioHelper
 * 
 * */
@isTest
private class TestBSFPortfolioHelper {
    
	@testSetup static void prepareTestData() {
        String recordTypeName = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeId = recordTypesadjustment.get(recordTypeName).getRecordTypeId();
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
    	Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',	DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = Date.newinstance(2021, 09, 30),	RecordTypeId=RecTypeId, Start_Date__c=Date.newinstance(2021, 01, 01),	Team_Code__c='MICH_Detroit S',	Team_Name__c='MICH_Detroit S',		Type__c='Bio Recruitment',	Version_Key__c=108.0, Zip_Code__c='48093');
		Taxonomy__c tax2 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',		DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = Date.newinstance(2021, 09, 30),	RecordTypeId=RecTypeId, Start_Date__c=Date.newinstance(2021, 01, 01), Team_Code__c='MICH_E Michigan',	Team_Name__c='MICH_E Michigan',		Type__c='Bio Recruitment',	Version_Key__c=108.0, Zip_Code__c='48420');
		Taxonomy__c tax3 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdSEMR_1820',DRD_Territory_Name__c='Detroit North 05',	DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = Date.newinstance(2021, 12, 31),	RecordTypeId=RecTypeId, Start_Date__c=Date.newinstance(2021, 07, 01), Team_Code__c='MICH_Detroit N',	Team_Name__c='MICH_Detroit N',		Type__c='Bio Recruitment',	Version_Key__c=109.0, Zip_Code__c='48093');
		Taxonomy__c tax4 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',DRD_Territory_Code__c='HProdGLR_710',  DRD_Territory_Name__c='MI North 03',		DS_Region_Code__c='13Z18Z',	DS_Region_Name__c='Michigan',	End_Date__c = Date.newinstance(2021, 12, 31),	RecordTypeId=RecTypeId, Start_Date__c=Date.newinstance(2021, 07, 01), Team_Code__c='MICH_E Michigan',	Team_Name__c='MICH_E Michigan',		Type__c='Bio Recruitment',	Version_Key__c=109.0, Zip_Code__c='48420');
		taxList.add(tax1);
        taxList.add(tax2);
        taxList.add(tax3);
        taxList.add(tax4);
        
        insert taxList;
    }
    
    @isTest static void testPortfolioInsert() {
        String recordTypeName = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
        Test.startTest();
        
        BSFPortfolioHelper.processTaxonomyData(108, recordTypeName);
        
        Test.stopTest();
        
        List<BSF_Portfolio__c> testPortfolios = [SELECT Id FROM BSF_Portfolio__c];
        Assert.isTrue(testPortfolios != null && !testPortfolios.isEmpty());
    }
}