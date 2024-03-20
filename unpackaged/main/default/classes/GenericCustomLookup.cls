public inherited sharing class GenericCustomLookup {
    @AuraEnabled(cacheable=true)
    public static List<SObject> findRecords(String searchKey, String objectName, String searchField){
        String key = '%' + searchKey + '%';
        String QUERY = 'Select Id, '+ String.escapeSingleQuotes(String.valueOf(searchField))+' From '+ String.escapeSingleQuotes(String.valueOf(objectName)) +' Where '+ String.escapeSingleQuotes(String.valueOf(searchField)) +' LIKE :key';
        //System.debug(System.LoggingLevel.DEBUG, QUERY);
        List<SObject> sObjectList = Database.query(QUERY);
        return sObjectList;
    }
}