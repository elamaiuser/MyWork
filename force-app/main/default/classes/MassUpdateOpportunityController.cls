public with sharing class MassUpdateOpportunityController {
	public List<Opportunity> opplist{get;set;}
    public String opps{get;set;}
    public String accountId{get;set;} 
    public ApexPages.StandardSetController setController{get;set;}    
    
    
    public MassUpdateOpportunityController (ApexPages.StandardSetController controller){
        setController = controller;
        //List<Opportunity> oppIdlist = new List<Opportunity>();
        opplist = (List<Opportunity>)setController.getSelected();
        
        accountId = apexpages.currentpage().getparameters().get('id');
        system.debug('accountId = ' + accountId);
        
		List<Opportunity> oppDatalist = [SELECT id, 
                                     Account.Id,
                                     Account.RecordType.DeveloperName,
                                     Name, 
                                     Start_Time__c,
                                     Flow_Start_Time_Field__c, 
                                     End_Time__c, 
                                     Flow_End_Time_Field__c, 
                                     WB_Projected_Procedures__c, 
                                     WholeBloodProcedureProjectedChangeReason__c, 
                                     X2RBC_Projected_Procedures__c, 
                                     DoubleRedProceduresProjectedChangeReason__c , 
                                     Plasma_Pheresis_Projected_Procedures__c, 
                                     Platelet_Projected_Procedures__c,
                                     StageName, Open_to_Public__c, 
                                     Online_Donor_Message__c, 
                                     Calendar_Description__c, 
                                     Amount
                                     FROM Opportunity WHERE ID IN :opplist];
        if(oppDatalist != null && oppDatalist.size() > 0){
            accountId = oppDatalist[0].AccountId;
        }
        
        opps = JSON.serialize(opplist);
        
    }
}