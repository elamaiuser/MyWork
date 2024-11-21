public with sharing class MassAssignUserToRMPortfolioClass {
    
    public String concatenatedPortfolioIds{get;set;}
    public List<BSF_Portfolio__c> portfolioList{get;set;}
    public List<String> portfolioIdarray{get;set;}
    public String unassignedviewId{get;set;}
    public String isError {get;set;}
    public ApexPages.StandardSetController setController{get;set;}    
    
    
    public MassAssignUserToRMPortfolioClass(ApexPages.StandardSetController setCon){
        unassignedviewId = null;
        isError = 'false';
        if( AccountBasedPortfolioClass.isAllowedForNonGeographicData() ){
            List<ListView> lv = [SELECT Id FROM ListView where SobjectType = 'BSF_Portfolio__c' and DeveloperName = 'Assign_User_To_RM'];
            if( !lv.isEmpty() ){
                unassignedviewId = lv[0].Id;
            }
            setController = setCon;
            portfolioList = new List<BSF_Portfolio__c>();
            portfolioList = (List<BSF_Portfolio__c>)setController.getSelected();
            System.debug('portfolioList is ' + portfolioList );
            portfolioIdarray = new List<String>();
            if( !portfolioList.isEmpty() ){
                for( BSF_Portfolio__c portfolio : portfolioList ){
                    portfolioIdarray.add( portfolio.Id );
                }
            }
            
            if( !portfolioIdarray.isEmpty() ){
                concatenatedPortfolioIds = '';
                for( String aid : portfolioIdarray ){
                    concatenatedPortfolioIds = concatenatedPortfolioIds + aid + ';' ;
                }
            }            
        }else{
            isError = 'true';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'You are not authorized'));
        }
        
        
    }
}