public class CreateDriveAffiliationsBatch implements Database.Batchable<sObject>{


   Set<ID> templateIdSet = new Set<Id>();
   Map<Id,Opportunity> newOppMap = new Map<Id,Opportunity>();
   Set<ID> oppRecordIdList = new Set<ID>();
   Map<ID, List<ID>> templateOppMapping = new Map<ID, List<ID>>();
    
   String query = 'select id,Blood_Drive_Opportunity__c, Account__c, Assigned_By__c, Booking_End_Date__c, Date_Assigned__c, Date_Removed__c, End_Date__c,Name, IsActive__c, Marketing_Program__c, Removed_By__c, Start_Date__c,LastViewedDate,lastactivitydate from Drive_Marketing_Programs__c'+ 
       ' where Marketing_Program__r.is_active__c=true and blood_drive_opportunity__c in :templateIdSet';
   
     public CreateDriveAffiliationsBatch( Set<ID> templateIdList,Map<Id,Opportunity> newOpportunityMap){
        this.templateIdSet = templateIdList;
        this.newOppMap = newOpportunityMap;
        this.oppRecordIdList = newOpportunityMap.keyset();
        this.templateOppMapping = getTemplateToOppMapping(newOpportunityMap);
     }

     public Database.QueryLocator start(Database.BatchableContext BC){
			return Database.getQueryLocator (query);
     }
    
    public void execute(Database.BatchableContext BC, List<Drive_Marketing_Programs__c> scope){ //scope will have only 1 record
          
      
		  //for each drive affiliation record, clone it and save it for new opportunity created
		  List<Drive_Marketing_Programs__c> newDriveAffiliations = new List<Drive_Marketing_Programs__c>();
           for(Drive_Marketing_Programs__c driveAffiliation:scope){
               List<ID> oppIdList = templateOppMapping.get(driveAffiliation.Blood_Drive_Opportunity__c);
               for(Id oppId : oppIdList){
               	  Drive_Marketing_Programs__c newDriveAffiliation = driveAffiliation.clone(false,true,false,false);
               	  newDriveAffiliation.Migration_ID__c =null;//empty migration id
               	  newDriveAffiliation.Blood_Drive_Opportunity__c = oppId;
               	  newDriveAffiliations.add(newDriveAffiliation);
               }//for each opp
           }//for each affiliation
           insert newDriveAffiliations;
    }
    
    /**
     * In the incoming opportunities, there might be many opps associated with single template,
     * and there can be more than one template in case of calendar builds
     **/
    public static  Map<ID, List<ID>> getTemplateToOppMapping(Map<Id,Opportunity> newOpportunityMap){
        Map<ID, List<ID>> templateToOppMapping = new Map<ID, List<ID>>();
        
        for(Id oppId : newOpportunityMap.keyset()){
            Opportunity opp = newOpportunityMap.get(oppId);
            Id templateId = opp.Parent_Template_Id__c;
            if(templateToOppMapping.containsKey(templateId) == false){ //for first time  template entering map
                List<Id> oppList = new List<Id>();
                oppList.add(opp.id);
                templateToOppMapping.put(templateId,oppList);
            }else{ //by this point template will have an entry in map
                templateToOppMapping.get(templateId).add(opp.id);
            }
        }
		return templateToOppMapping;         
    }
    
   public void finish(Database.BatchableContext BC){
           
   }
}