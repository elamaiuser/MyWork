global class BSF_Batch_OpportunitySplitDelete implements Database.Batchable<sObject>{
	
	global List<OpportunitySplit> optySplitListToDelete = new List<OpportunitySplit>();
    global List<OpportunityTeamMember> optyTeamMembersListToDelete = new List<OpportunityTeamMember>();
	global BSF_Batch_OpportunitySplitDelete(List<OpportunitySplit> optySplitListToDelete,List<OpportunityTeamMember> optyTeamMembersListToDelete){
        this.optySplitListToDelete = optySplitListToDelete;
        this.optyTeamMembersListToDelete = optyTeamMembersListToDelete;
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC)
  	{ 
        return optySplitListToDelete;
    }
	
	global void execute(Database.BatchableContext bc, List<OpportunitySplit> scope)
  	{
        OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
		Database.DeleteResult[] drList = Database.delete(optySplitListToDelete,false);
                    
        for(Database.DeleteResult dr : drList) {
            if (!dr.isSuccess()) {
                for(Database.Error err : dr.getErrors()) {
                    System.debug('Error Deleting split record is -> '+err.getStatusCode() + ': ' + err.getMessage());                    
                }
            }
        }
		
  	}
 
  	global void finish(Database.BatchableContext BC)
  	{
        BSF_Batch_OpportunityTeamMember teamMemberBatch = new BSF_Batch_OpportunityTeamMember(optyTeamMembersListToDelete,new List<OpportunityTeamMember>(),'Delete',false,0);
        Database.executeBatch(teamMemberBatch,100);
  	}
}