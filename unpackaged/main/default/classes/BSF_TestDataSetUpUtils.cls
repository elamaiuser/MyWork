/***
 * Name: BSF_TestDataSetUpUtils
 * Description: Utility methods help get test data of objects to be used across test classes
 * Author: Anil K
 * Date: 06/24/2022
 * 
 * */
public class BSF_TestDataSetUpUtils {
    
    
    //Utility method to print JSON values of object-used to create test data 
    public static void printJson(){
        
        String query = retrieveAllFields('sked_Territory__c','a3K050000008y3AEAQ');
        sked_Territory__c site =(sked_Territory__c)Database.query(query);
        String jsonValue = JSON.serializePretty(site);
        System.debug('jsonValue->'+jsonValue);
    }
 
   public static String retrieveAllFields(String SobjectApiName,ID idValue){
        
        /*********************************************/
        List<SObjectType> childList = new List<SObjectType>();

     Schema.SObjectType convertType = Schema.getGlobalDescribe().get(SobjectApiName);
        Schema.DescribeSObjectResult obj = convertType.getDescribe();
        for (Schema.ChildRelationship cr: obj.getChildRelationships()) 
        {
            system.debug('Child Object Name:'+cr.getChildSObject());
            childList.add(cr.getChildSObject());
        }
        
        /*********************************************/
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
        Set<string> mapset = fieldMap.keyset();
        List<String>  listFields = new List<String>();
    	String allFields = '';
        FOR ( String str:mapset )
        {
            
            allFields += str +', '; 
            listFields.add(str);
        }
        allFields = allFields.removeEnd(', ');
        
        String query = 'SELECT ' + allFields + ' FROM ' + SobjectApiName + ' where id = \''+idValue+'\' ';
    	return query;
   }

}