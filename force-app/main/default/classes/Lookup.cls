public without sharing class Lookup {

    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTerm, string myObject, String filter) {
        String myQuery = null;
        if(filter != null && filter != ''){
            if (myObject == 'BSF_Portfolio__c') { 
                myQuery = 'Select Id,Name From BSF_Portfolio__c Where (Portfolio_Type__c = \'Account Manager\' OR Portfolio_Type__c = \'District Manager\') AND Name Like  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' AND '+String.escapeSingleQuotes(filter)+' LIMIT 100';
            }
            else{
                myQuery = 'Select Id, Name from '+String.escapeSingleQuotes(myObject)+' Where Name Like  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' AND '+String.escapeSingleQuotes(filter)+' LIMIT  100';
            }
        }
        else {
            if(searchTerm == null || searchTerm == ''){
                if (myObject == 'BSF_Portfolio__c') {
                    myQuery = 'Select Id,Name From BSF_Portfolio__c Where (Portfolio_Type__c = \'Account Manager\' OR Portfolio_Type__c = \'District Manager\') LIMIT 100';
                }
                else{
                    myQuery = 'Select Id, Name from '+String.escapeSingleQuotes(myObject)+' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  100';
                }
            }
            else {
                if (myObject == 'BSF_Portfolio__c') {
                    myQuery = 'Select Id,Name From BSF_Portfolio__c Where (Portfolio_Type__c = \'Account Manager\' OR Portfolio_Type__c = \'District Manager\') AND Name Like  \'%' + String.escapeSingleQuotes(searchTerm) + '%\'  LIMIT 100';
                }else{
                    myQuery = 'Select Id, Name from '+String.escapeSingleQuotes(myObject)+' Where Name Like  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' LIMIT  100';
                }
            }
        }
        List<sObject> lookUpList = database.query(myQuery);
        return lookUpList;
    }
}