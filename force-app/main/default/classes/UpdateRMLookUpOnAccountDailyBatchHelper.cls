public with sharing class UpdateRMLookUpOnAccountDailyBatchHelper {
    
    public static void updateRMLookUpOnAccount(List<Portfolio_Assignment__c> portfolioUserList){
        
        System.debug('portfolioUserList: '+portfolioUserList);
        
        Map<Id,Portfolio_Assignment__c> portfolioUserMap = new Map<Id,Portfolio_Assignment__c>();
        Map<Id,List<Id>> posrtfolioAccountMap = new Map<Id,List<Id>>();
        
        for(Portfolio_Assignment__c portfolioAssignment:portfolioUserList){
            portfolioUserMap.put(portfolioAssignment.BSF_Portfolio__c,portfolioAssignment);
        }
        
        List<Account_Portfolio_Assignment__c> accPortfolioList =[SELECT Id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE BSF_Portfolio__c IN :portfolioUserMap.keySet()];
        Set<Id> accIdSet = new Set<Id>();
        for(Account_Portfolio_Assignment__c accPortfolioAssignment:accPortfolioList){
            if(!posrtfolioAccountMap.containsKey(accPortfolioAssignment.BSF_Portfolio__c)){
                List<Id> accIdList = new List<Id>();
                accIdList.add(accPortfolioAssignment.Account__c);
                accIdSet.add(accPortfolioAssignment.Account__c);
                posrtfolioAccountMap.put(accPortfolioAssignment.BSF_Portfolio__c,accIdList);
            }
            else{
                List<Id> accIdList = posrtfolioAccountMap.get(accPortfolioAssignment.BSF_Portfolio__c);
                accIdList.add(accPortfolioAssignment.Account__c);
                accIdSet.add(accPortfolioAssignment.Account__c);
                posrtfolioAccountMap.put(accPortfolioAssignment.BSF_Portfolio__c,accIdList);
            }
        }
        
        Map<Id,Account> accMap = new Map<Id, Account>([SELECT Id,Name,Relationship_Manager__c FROM Account WHERE Id IN:accIdSet]);
        set<Account> accSetToUpdate = new Set<Account>();
        List<Account> accListToUpdate = new List <Account>();
        for(Id portfolioId:posrtfolioAccountMap.keySet()){
            List<Id> accIdList = posrtfolioAccountMap.get(portfolioId);
            for(Id accId:accIdList){
                Account accToUpdate = accMap.get(accId);
                accToUpdate.Relationship_Manager__c = portfolioUserMap.get(portfolioId).User__c;
                
                accSetToUpdate.add(accToUpdate);
            }
        }
        
        accListToUpdate.addall(accSetToUpdate);
        if(accListToUpdate.size()>0){
            try{
                System.debug('accListToUpdate: '+accListToUpdate);
                Database.update(accListToUpdate);
            }
            catch(Exception e){
                System.debug('An Error has occured: '+e.getMessage());
            }
        }        
    }    
    
}