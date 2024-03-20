global with sharing class slwcAccountService {

    @AuraEnabled
    public static List<AggregateResult> searchMarket(String queryText) {
        String queryTextPadded = '%' + queryText + '%';
        return [SELECT Market__c, Count(Id)
            FROM Account
            WHERE Market__c LIKE :queryTextPadded
            GROUP BY Market__c
            ORDER BY Market__c
            LIMIT 10];
    }
}