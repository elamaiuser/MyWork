public with sharing class AddTeamMemberToOpportunityExtension {

    public String concatenatedOppIds{get;set;}
 	public List<Opportunity> opplist{get;set;}
    public List<String> oppIdarray{get;set;}
    public String unassignedviewId{get;set;}
    
    public ApexPages.StandardSetController setController{get;set;} 
    
    public AddTeamMemberToOpportunityExtension(ApexPages.StandardSetController setCon){
        unassignedviewId = null;
        List<ListView> lv = [SELECT Id FROM ListView where SobjectType = 'Opportunity' and DeveloperName = 'Unmanaged_Drive' ];
        if( !lv.isEmpty() ){
            unassignedviewId = lv[0].Id;
        }
        setController = setCon;
        opplist = new List<Opportunity>();
        opplist = (List<Opportunity>)setController.getSelected();
        System.debug('opplist is ' + opplist );
        oppIdarray = new List<String>();
        if( !opplist.isEmpty() ){
            for( Opportunity acc : opplist ){
                oppIdarray.add( acc.Id );
            }
        }
        
        if( !oppIdarray.isEmpty() ){
            concatenatedOppIds = '';
            for( String aid : oppIdarray ){
                concatenatedOppIds = concatenatedOppIds + aid + ';' ;
            }
        }
    }
}