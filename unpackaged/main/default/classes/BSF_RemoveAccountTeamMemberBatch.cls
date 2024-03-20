/*@Description:  This Batch will delete Account Team Members from Account when Effective Date is reached.
 * Date					Developer Name			Description
 * ***************************************************************************************************************************************************************************
 * 06/13/2023			Barnojit Sharma			Delete Account Team Members from Account when Effective Date is reached (Logic for HRP-4773)
 * 11/22/2023		    Balaji N			    Logic for HRP-11281(Syncing expired team Members)
 *****************************************************************************************************************************************************************************
*/
global class BSF_RemoveAccountTeamMemberBatch implements Schedulable, Database.Batchable<Sobject>{

	global Database.QueryLocator start(Database.BatchableContext BC){
        //Pulling Account Team Members who's Effective Date is reached (HRP-4773)
		String query = 'SELECT Id, End_Date__c, Is_Covering_Recruiter__c,accountId,start_Date__c FROM AccountTeamMember WHERE End_Date__c < TODAY order by accountId';
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<AccountTeamMember> scope){
        list<id> accountIdList = new list<id>();
        set<id>accTeamIdSet = new set<id>();
        for(AccountTeamMember atm:scope)
        {
            if(!accountIdList.contains(atm.accountId))
            accountIdList.add(atm.accountId);
            accTeamIdSet.add(atm.id);
        }
        
        map<string,AccountTeamMember> accTeamMap = AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(accountIdList,null);
        list<AccountTeamMember> teamTodeleteList = [select id from accountTeamMember where id in :accTeamIdSet and Is_Covering_Recruiter__c=true];
        if(!teamTodeleteList.isEmpty())
        doExecute(teamTodeleteList);
	}
	global void execute(SchedulableContext scon){
		Database.executeBatch(new BSF_RemoveAccountTeamMemberBatch(),200);
	}
	global void finish(Database.BatchableContext BC){}

    @TestVisible
    private void doExecute(List<AccountTeamMember> scope){
        Database.deleteResult[] srList = Database.delete(scope, false);
            for(Database.deleteResult sr : srList){
                if (!sr.isSuccess() || Test.isRunningTest()){
                    for(Database.Error err : sr.getErrors()){
                        System.debug('Error: '+err.getStatusCode() + ': ' + err.getMessage()+ ' ' + err.getFields());
				    }
                }
            }
    }
}