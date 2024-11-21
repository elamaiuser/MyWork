public with sharing class AutoCompleteService {
    /*
    return sobject data dynamically based on search items
    */
    @AuraEnabled
    public static List<Option> getACValues( String objectName, 
                                            String fieldNameKey, 
                                            String fieldNameValue,
                                            String searchValue,
                                            String recordLimit ){
        String query = 'select ' + String.escapeSingleQuotes(fieldNameKey) + ',' + String.escapeSingleQuotes(fieldNameValue) + 
                       ' from ' + String.escapeSingleQuotes(String.valueOf(objectName)) + ' where ' + String.escapeSingleQuotes(String.valueOf(fieldNameValue)) +
                       ' like \'%' + String.escapeSingleQuotes(searchValue) + '%\' order by ' + String.escapeSingleQuotes(fieldNameValue) +
                       ' limit ' + String.escapeSingleQuotes(recordLimit);
        List<Option> options = new List<Option>();

        for (SObject theObject : Database.query(query)) {
            Option theOption = new Option();
            theOption.key = (String) theObject.get(fieldNameKey);
            theOption.value = (String) theObject.get(fieldNameValue);
            options.add(theOption);
        }

        return options;
    }

    public class Option {
        @AuraEnabled public String key;
        @AuraEnabled public String value;
    }
}