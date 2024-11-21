public class skedLexResourceController {
    
    @AuraEnabled
    public static List<sked__Availability_Template__c> getResourceTemplates(Id resourceId) {
        List<sked__Availability_Template_Resource__c> atrList = [SELECT Id, sked__Availability_Template__c
                                                                 FROM sked__Availability_Template_Resource__c
                                                                 WHERE sked__Resource__c = :resourceId
                                                                 AND (sked__Availability_Template__r.sked__Finish__c = NULL 
                                                                      OR sked__Availability_Template__r.sked__Finish__c >= :system.today())];
        Set<Id> templateIds = new Set<Id>();
        for (sked__Availability_Template_Resource__c atr : atrList) {
            templateIds.add(atr.sked__Availability_Template__c);
        }
        List<sked__Availability_Template__c> templates = [SELECT Id, Name, sked__Start__c, sked__Finish__c,
                                                          (SELECT Id, sked__Finish_Time__c, sked__Is_Available__c, sked__Start_Time__c, sked__Weekday__c
                                                           FROM sked__Availability_Template_Entries__r)
                                                          FROM sked__Availability_Template__c
                                                          WHERE Id IN :templateIds
                                                          ORDER BY sked__Start__c ASC];
        List<sked__Availability_Template__c> results = new List<sked__Availability_Template__c>();
        for (sked__Availability_Template__c template : templates) {
            if (template.sked__Availability_Template_Entries__r != NULL && !template.sked__Availability_Template_Entries__r.isEmpty()) {
                results.add(template);
            }
        }
        return results;
    }
    
    @AuraEnabled
    public static List<sked__Availability_Pattern_Resource__c> getPatternResources(Id resourceId) {
        return [SELECT Id, sked__Start__c, sked__End__c, sked__Availability_Pattern__c,
                sked__Availability_Pattern__r.Name, 
                sked__Availability_Pattern__r.sked__Description__c, 
                sked__Availability_Pattern__r.sked__Pattern__c
                FROM sked__Availability_Pattern_Resource__c
                WHERE sked__Resource__c = :resourceId
                AND (sked__End__c = NULL OR sked__End__c >= :system.now())];
    }
    
}