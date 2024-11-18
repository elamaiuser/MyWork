/***
 * 
 * Common utility class for LSL and regular Leads
 * 
 * 
 * */
public class LeadUtils {
    
    //HRP-12024, returns taxonomies currently in non service area
    public static List<taxonomy__c> getCurrentlyValidTaxonomies(String zipCode){
        Date thisDate = Date.today();
        String taxonomyBioSFRecordType = Schema.SObjectType.Taxonomy__c.getRecordTypeInfosByName().get(BSF_Constants.BIO_COLLECTION_RECORD_TYPE).getRecordTypeId();
		String nonServiceArea=Label.NonCollectionArea_Label;
        
        List<Taxonomy__c > taxonomyResults = [select Id,RecordTypeId, Name, City__c, State__c,Collection_Operation_Name__c  from Taxonomy__c where Start_Date__c <= :thisDate and End_Date__c >= :thisDate and Zip_Code__c  = :zipCode 
                                              and RecordTypeId=:taxonomyBioSFRecordType and Collection_Operation_Name__c != :nonServiceArea and District_Name__c != :nonServiceArea 
                                              and Division_Name__c != :nonServiceArea and DS_Region_Name__c != :nonServiceArea and City__c!=null and State__c != null];
    	return taxonomyResults;
    }

}