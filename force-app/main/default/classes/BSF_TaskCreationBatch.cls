global class BSF_TaskCreationBatch implements Schedulable, Database.Batchable<sObject>{
	Integer sponsorPlanningMeetingTaskThreshold = Integer.ValueOf(label.SponsorPlanningMeetingTaskThresholdDays);
	Integer seventyuTwoHourTaskThreshold = Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Creation_Date_Offset__c != null 
											? Integer.valueOf(Task_Reassignment_Matrix__mdt.getInstance('X72_Hour').Creation_Date_Offset__c)
											: 0;
    Date nextNDays = sponsorPlanningMeetingTaskThreshold > seventyuTwoHourTaskThreshold 
					? Date.today().addDays(sponsorPlanningMeetingTaskThreshold) 
					: Date.today().addDays(seventyuTwoHourTaskThreshold);
    Id MOBILE_OPP_RECTYPEID = SObjectType.Opportunity.getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId();
	public String query = 'SELECT Id, Drive_Date__c, Is_Template__c, RecordTypeId, RecordType.Name, Account_Manager__c, OwnerId, StageName FROM Opportunity'+
    ' WHERE Drive_Date__c <=: nextNDays AND Drive_Date__c >= TODAY AND StageName != \'Cancel\' AND Is_Template__c = false AND RecordTypeId =:MOBILE_OPP_RECTYPEID';
    global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<Opportunity> scope){
		OpportunityService.createSponsorPlanningMeetingTask(scope,null);
		OpportunityService.closedOpportunity72HourTaskCreation(scope,null);
	}
	global void execute(SchedulableContext scon){
		Database.executeBatch(new BSF_TaskCreationBatch(),200);
	}
	global void finish(Database.BatchableContext BC){}
}