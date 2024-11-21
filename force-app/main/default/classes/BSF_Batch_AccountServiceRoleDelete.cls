global class BSF_Batch_AccountServiceRoleDelete implements Database.Batchable<SObject>,Schedulable{
    private String queryAccountServiceRole='Select id,End_Date__c,Contact__c,Account__c from Account_Service_Role__c Where End_Date__c < Today ';
	
    global void execute(System.SchedulableContext ctx) {
		BSF_Batch_AccountServiceRoleDelete conroleupdate = new BSF_Batch_AccountServiceRoleDelete();
		Database.executeBatch(conroleupdate);
	}
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryAccountServiceRole); 
    }

    public void execute(Database.BatchableContext BC, List<Account_Service_Role__c> scope){
        Database.delete(scope,false);
           
    }
	global void finish(Database.BatchableContext BC){
		
    }
}