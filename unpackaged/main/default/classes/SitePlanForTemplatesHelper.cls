public with sharing class SitePlanForTemplatesHelper {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> SitePlanForTemplatesHelper(string recordId) {
        List<Opportunity> oppList = [select Id , Name , AccountId, Account.Name  from Opportunity where Drive_Site__c = :recordId and Is_Template__c = true];
        return oppList;

    }

}