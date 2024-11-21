public with sharing class MassAssignAccountBasedPortfolioClass {
    
    public String concatenatedAccIds{get;set;}
    public List<Account> acclist{get;set;}
    public List<String> accIdarray{get;set;}
    public String unassignedviewId{get;set;}
    public String isError {get;set;}
    public ApexPages.StandardSetController setController{get;set;}    
    
    
    public MassAssignAccountBasedPortfolioClass(ApexPages.StandardSetController setCon){
        unassignedviewId = null;
        isError = 'false';
        if( AccountBasedPortfolioClass.isAllowedForNonGeographicData() ){
            /*List<ListView> lv = [SELECT Id FROM ListView where SobjectType = 'account' and DeveloperName = 'Unassigned_Accounts'];
            if( !lv.isEmpty() ){
                unassignedviewId = lv[0].Id;
            }*/
            setController = setCon;
            acclist = new List<Account>();
            acclist = (List<Account>)setController.getSelected();
            System.debug('acclist is ' + acclist );
            accIdarray = new List<String>();
            if( !acclist.isEmpty() ){
                for( Account acc : acclist ){
                    accIdarray.add( acc.Id );
                }
            }
            
            if( !accIdarray.isEmpty() ){
                concatenatedAccIds = '';
                for( String aid : accIdarray ){
                    concatenatedAccIds = concatenatedAccIds + aid + ';' ;
                }
            }
            
            if( concatenatedAccIds != null ){
                /*if(!AccountBasedPortfolioClass.isAllowedToCreateTeamMembers(concatenatedAccIds)){
                    isError = 'true';
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'You are not the District Manager of one of the Selected Account'));
                }*/
            }else{
                isError = 'true';
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'Please select account from List view'));
            }
            
            
        }else{
            isError = 'true';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'You are not authorized'));
        }
        
        
    }
}