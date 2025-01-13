global class BSF_BatchFutureDriveUpdate2 implements Database.Batchable<sObject>, Database.Stateful{
    public List<String> OppFields = new List<String>();
    public List<String> selectedFields = new List<String>();
    public set<string> webschedulingfields = new set<string>{'end_time__c','web_schedule_start_time__c','web_schedule_enddate__c', 
                                                            'web_schedule_startdate__c','timezone__c','web_schedule_start_date__c',
                                                            'web_schedule_end_date__c','web_schedule_end_time__c',
                                                            'web_sched_offset_from_co_global_settings__c'};
            
    public String query;
    public Opportunity templateRec;
    boolean isDriveAffiliationFound = false;
    boolean isDriveServiceRolesFound = false;
    boolean isWebschedulingSettingsFound = false;
    boolean isTemplateOrderFound = false;
	global BSF_BatchFutureDriveUpdate2(List<String> driveIds, Opportunity template, List<String> selectedFields){
        Set<String> OpportunityFieldList = Schema.sObjectType.Opportunity.fields.getMap().keySet();
        if(driveIds != null && !driveIds.isEmpty() && template != null && selectedFields != null && !selectedFields.isEmpty()){
            for(String field : selectedFields){
                if(OpportunityFieldList.contains(field.toLowerCase())){
                    this.OppFields.add(field.toLowerCase());
                }
                if(field.equalsIgnoreCase('Web Scheduling Settings')){
                    this.OppFields.addAll(webSchedulingFields);
                    isWebschedulingSettingsFound = true;
                }
                if(field.equalsIgnoreCase('Template Order')){
                    isTemplateOrderFound = true;
                }
                if(field.equalsIgnoreCase('Drive Affiliations')){
                    isDriveAffiliationFound = true;
                }
                if(field.equalsIgnoreCase('Drive Service Roles')){
                    isDriveServiceRolesFound = true;
                }
                this.selectedFields.add(field.toLowerCase());
            }
        }
		this.query = 'SELECT id FROM Opportunity WHERE Id IN (\''+String.join(driveIds,'\',\'')+'\')';
	}
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(this.query);
	}
	global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        List<Opportunity> oppList = (List<Opportunity>) scope;
        Map<Id, Opportunity> oppMap = new  Map<Id, Opportunity>(oppList);
        GlobalWebSchedulingSettings__mdt globalWebSchedulingSettings = GlobalWebSchedulingSettings__mdt.getInstance('MobileDriveSettings');
        
        for(Id oppId : oppMap.keySet()){
            if(isDriveAffiliationFound == true || isDriveServiceRolesFound == true){
                FutureDrivesController.rollAffiliationsOrServiceRoles(isDriveAffiliationFound,isDriveServiceRolesFound,templateRec.Id,new List<Opportunity>{oppMap.get(oppId)},new List<String>{oppId});
            }
            if(isTemplateOrderFound == true){
                FutureDrivesController.syncTemplateOrderToOpportunity(templateRec.Id,new List<String>{oppId});
            }
        }
        if(!oppListToUpdate.isEmpty()){
            DataBase.saveResult[] srOppList = Database.update(oppListToUpdate,true);
            List<BSF_Error_Log__c> errorLogJobs = BSF_Utilities.createErrorLog(srOppList,'Update processed record status', 'BSF_BatchFutureDriveUpdate', 'execute', 'Error', 'Error in Future Drives Update');
            insert errorLogJobs;
        }
	}
	global void finish(Database.BatchableContext BC){}
}