//This batch is created as part of HRP-4619
global class CreateDefaultTerritoryPortfolioBatch implements Database.Batchable<sObject>,Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String AMRole = 'Account Manager'; 
        Date today = Date.today();
        Date yesterday = today.addDays(-1);
        List<String> reqTaxonomyList = new List<String>{BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE};
        String query = 'SELECT Id,Account__c,Start_Date__c,End_Date__c,Portfolio_Type__c,BSF_Portfolio__c,BSF_Portfolio__r.Account_Based_Portfolio__c,'+
                       'BSF_Portfolio__r.Territory_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,Bsf_Portfolio__r.Parent_Portfolio__c,'+
                       'Bsf_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,Bsf_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,'+
                       'Bsf_Portfolio__r.Portfolio_Code__c,BSF_Portfolio__r.Taxonomy_Type__c'+
                       ' FROM Account_Portfolio_Assignment__c WHERE (start_Date__c =:today OR start_Date__c =:yesterday OR End_date__c =:today)'+
                       ' AND BSF_Portfolio__r.Portfolio_Type__c =:AMRole AND (BSF_Portfolio__r.Account_Based_Portfolio__c = TRUE OR BSF_Portfolio__r.Territory_Portfolio__c = true)'+
                       ' AND BSF_Portfolio__r.Taxonomy_Type__c IN:reqTaxonomyList';
    	return Database.getQueryLocator(query);	
    }
    global void execute(Database.BatchableContext BC,List<Account_Portfolio_Assignment__c> accPortfolioList){
        DefaultTerritoryPortfolioBatchHelper.createDefaultTerritoryPortfolioRecords(accPortfolioList);
    }
    global void finish(Database.BatchableContext bc){
        
    }
}