public with sharing class InactiveUserLookUpController {
    @AuraEnabled(cacheable=true)
    public static List<SObject> findRecords(String searchKey, String objectName, String searchField){
        String key = '%' + String.escapeSingleQuotes(searchKey) + '%';
        //String QUERY = 'Select Id, '+searchField+' From '+objectName +' Where '+searchField +' LIKE :key';
        String QUERY = 'Select Id, '+ String.escapeSingleQuotes(searchField) +' From User Where  isActive = FALSE AND '+ String.escapeSingleQuotes(searchField) +' LIKE :key ';
        //System.debug(System.LoggingLevel.DEBUG, QUERY);
        List<SObject> sObjectList = Database.query( QUERY );
        return sObjectList;
    }
}