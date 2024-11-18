global class BSF_TaskCreationBatch implements Schedulable, Database.Batchable<sObject>{
    Date nextNDays = Date.today().addDays(Integer.ValueOf(label.SponsorPlanningMeetingTaskThresholdDays));
    Id MOBILE_OPP_RECTYPEID = SObjectType.Opportunity.getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId();
	public String query;
	global BSF_TaskCreationBatch(){
		query = 'SELECT Id, Drive_Date__c, Is_Template__c, RecordTypeId, Account_Manager__c, OwnerId FROM Opportunity'+
    			' WHERE Drive_Date__c =: nextNDays AND StageName != \'Cancel\' AND Is_Template__c = false AND RecordTypeId =:MOBILE_OPP_RECTYPEID';
	}
	global BSF_TaskCreationBatch(Boolean allOpportunities){
		query = 'SELECT Id, Drive_Date__c, Is_Template__c, RecordTypeId, Account_Manager__c, OwnerId FROM Opportunity'+
    			' WHERE Drive_Date__c <=: nextNDays AND StageName != \'Cancel\' AND Is_Template__c = false AND RecordTypeId =:MOBILE_OPP_RECTYPEID';
	}
    global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        system.debug('scope '+scope);
		OpportunityService.createSponsorPlanningMeetingTask(scope,null);
	}
	global void execute(SchedulableContext scon){
		Database.executeBatch(new BSF_TaskCreationBatch(),200);
	}
	global void finish(Database.BatchableContext BC){}
}