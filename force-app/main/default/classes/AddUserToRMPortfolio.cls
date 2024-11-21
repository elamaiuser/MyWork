public inherited sharing class AddUserToRMPortfolio {

    @AuraEnabled(cacheable=false)
    public static List<String> getPortfolioNames(List<String> selectedIdsList ){
        List<BSF_Portfolio__c> portfolios = [ Select Id, Portfolio_Name__c from BSF_Portfolio__c where ID IN: selectedIdsList ];

        List<String> portfolioNameList = new List<String>();

        for( BSF_Portfolio__c portfolio : portfolios ){
            portfolioNameList.add( portfolio.Portfolio_Name__c);
        }
        return portfolioNameList;
    }
    
    
    @AuraEnabled(cacheable=false)
    public static void createUserPortfolioMappingForRM(String inputString, List<String> selectedIdsList ){
        System.debug('selectedIdsList: '+selectedIdsList);
        
        AddUserToRMPortfolio.AddUserToRMPortfolioWrapper userPortfolioMappingWrapper = (AddUserToRMPortfolio.AddUserToRMPortfolioWrapper)JSON.deserialize(inputString,AddUserToRMPortfolio.AddUserToRMPortfolioWrapper.class);
        System.debug('====userPortfolioMappingWrapper===='+userPortfolioMappingWrapper);
        List<Portfolio_Assignment__c> userPortfolioMappingList = new List<Portfolio_Assignment__c>();
        Portfolio_Assignment__c userPortfolio;
        
        for(String portfolioId:selectedIdsList){
            System.debug('portfolioId: '+portfolioId);
            userPortfolio = new Portfolio_Assignment__c();
            userPortfolio.BSF_Portfolio__c = portfolioId;
            userPortfolio.User__c = userPortfolioMappingWrapper.userId;
            userPortfolio.Start_Date__c = Date.valueOf(userPortfolioMappingWrapper.startDate);
            userPortfolio.End_Date__c = Date.valueOf(userPortfolioMappingWrapper.endDate);
            userPortfolio.Assignment_Type__c = BSF_Constants.RELATIONSHIP_MANAGER;
            
            userPortfolioMappingList.add(userPortfolio);
        }
        
        if(userPortfolioMappingList.size()>0){
            try{
                //if (Schema.sObjectType.Portfolio_Assignment__c.isCreateable()){}
                 
                    Database.insert(userPortfolioMappingList);
                
            }
            catch(Exception e){
                System.debug('An error has occured: '+e.getMessage());
            }
        }
    }
    
    public without sharing class AddUserToRMPortfolioWrapper{
        @AuraEnabled public String userId;
        @AuraEnabled public String startDate;
 		@AuraEnabled public String endDate;
    }
    
}