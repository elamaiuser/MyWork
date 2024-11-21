global class BSF_TemplateCDA_FutureOpportunity_Batch implements Database.Batchable<sObject>,Schedulable {
   	
    global Boolean changedToday;
    global BSF_TemplateCDA_FutureOpportunity_Batch(Boolean changedToday){
    	this.changedToday = changedToday;	   
    }
    
    global BSF_TemplateCDA_FutureOpportunity_Batch(String batchName,Boolean changedToday){
    	this.changedToday = changedToday;    
    }
    
    global void execute(SchedulableContext sc) {
      BSF_TemplateCDA_FutureOpportunity_Batch batch1 = new BSF_TemplateCDA_FutureOpportunity_Batch('Future Opportunity CDA Values Batch',this.changedToday); 
      Database.executeBatch(batch1,50); 
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,Parent_Template_Id__r.WB_Projected_Procedures__c,WholeBloodProceduresProjectedTemplate__c,Parent_Template_Id__r.X2RBC_Projected_Procedures__c,Double_Red_Procedures_Projected_Template__c,'+
            			'Parent_Template_Id__r.Anticipated_Registered_Donors__c,Anticipated_Registered_Donors_Template__c FROM Opportunity ';
        if(this.changedToday){
            query = query +' WHERE Parent_Template_Id__r.LastModifiedDate = TODAY';
        }
		
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope){
        List<Opportunity> opportunitiesToBeUpdated = new List<Opportunity>();
        for(Opportunity opptyRec : scope){
            if(opptyRec.Parent_Template_Id__r.WB_Projected_Procedures__c != opptyRec.WholeBloodProceduresProjectedTemplate__c ||
               		opptyRec.Parent_Template_Id__r.X2RBC_Projected_Procedures__c != opptyRec.Double_Red_Procedures_Projected_Template__c ||
               		opptyRec.Parent_Template_Id__r.Anticipated_Registered_Donors__c != opptyRec.Anticipated_Registered_Donors_Template__c){
                	   
            	opptyRec.WholeBloodProceduresProjectedTemplate__c = opptyRec.Parent_Template_Id__r.WB_Projected_Procedures__c;
                opptyRec.Double_Red_Procedures_Projected_Template__c = opptyRec.Parent_Template_Id__r.X2RBC_Projected_Procedures__c;
                opptyRec.Anticipated_Registered_Donors_Template__c = opptyRec.Parent_Template_Id__r.Anticipated_Registered_Donors__c;
                    
                opportunitiesToBeUpdated.add(opptyRec);
            }
        }
        
        List<Database.SaveResult> saveResults = Database.update(opportunitiesToBeUpdated,false);
    }

    
    global void finish(Database.BatchableContext BC){
        
    }
}