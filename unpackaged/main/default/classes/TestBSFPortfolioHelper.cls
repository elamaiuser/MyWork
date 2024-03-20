/**
 * This Class contains testMethods for BSFPortfolioHelper
 * 
 * */
@isTest
public class TestBSFPortfolioHelper {
	@testSetup static void setUpData() {
         Account acc = new Account(name='Test Account 1');
         acc.BillingStreet = '2204 Westcrt ln, Apt 213'; 
         acc.BillingCity = 'Herndon';
         acc.BillingStateCode = 'MI';
         acc.BillingPostalCode = '48420';
         insert acc;
        
         Contact contact = new Contact (firstname='Test Contact First 1',lastname='Test Contact Last 1');
         contact.MailingStreet = '2204 Westcrt ln, Apt 213'; 
         contact.MailingCity = 'Herndon';
         contact.MailingStateCode = 'MI';
         contact.MailingPostalCode = '48420';
         contact.AccountId = acc.id;
         contact.Primary_Phone__c = 'Mobile Phone';
         contact.MobilePhone = '222-222-2222';
         contact.Email = 'testtest@test.com';
         contact.Original_Service_Date__c = Date.today();
         insert contact;
        
         Account acc1 = new Account(name='Test Account 2');
         acc1.BillingStreet = '2205 Westcrt ln, Apt 215'; 
         acc1.BillingCity = 'Herndon';
         acc1.BillingStateCode = 'MI';
         acc1.BillingPostalCode = '48093';
         insert acc1;
        
         Contact contact1 = new Contact (firstname='Test Contact First 2',lastname='Test Contact Last 2');
         contact1.MailingStreet = '2204 Westcrt ln, Apt 213'; 
         contact1.MailingCity = 'Herndon1';
         contact1.MailingStateCode = 'AL';
         contact1.MailingPostalCode = '48094';
         contact1.AccountId = acc1.id;
         contact1.Primary_Phone__c = 'Work Phone';
         contact1.MobilePhone = '222-452-2222';
         contact1.Email = 'testtester@test.com';
         contact1.Original_Service_Date__c = Date.today();
         insert contact1;
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
    
    @isTest static void testPortfolioInsert(){
        String recordTypeName = BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE;
        Test.startTest();
        BSFPortfolioHelper.processTaxonomyData(108,recordTypeName);
        
        Test.stopTest();
    }
}