global class UpdateRMLookUpOnAccountDailyBatch implements Database.Batchable<sObject>,Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();
        String rmPortfolioType = BSF_Constants.RELATIONSHIP_MANAGER;
        String query = 'SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE Start_Date__c =:today AND BSF_Portfolio__r.Portfolio_Type__c =: rmPortfolioType';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC,List<Portfolio_Assignment__c> portfolioUserList){
        UpdateRMLookUpOnAccountDailyBatchHelper.updateRMLookUpOnAccount(portfolioUserList);
    }
    global void finish(Database.BatchableContext bc){
        
    }
}