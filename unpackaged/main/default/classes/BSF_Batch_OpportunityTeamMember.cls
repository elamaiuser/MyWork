global class BSF_Batch_OpportunityTeamMember implements Database.Batchable<sObject>{
	
	global List<OpportunityTeamMember> listOfOpptyTeamMembersTodelete;
	global List<OpportunityTeamMember> optyTeamMemberNotExistListToInsert;
	global String operation;
    global Boolean decCounter;
    global Integer countAccounts;
 	global BSF_Batch_OpportunityTeamMember(List<OpportunityTeamMember> listOfOpptyTeamMembersTodelete,List<OpportunityTeamMember> optyTeamMemberNotExistListToInsert,
                                           								String operation, Boolean decCounter, Integer countAccounts){
        this.listOfOpptyTeamMembersTodelete = listOfOpptyTeamMembersTodelete;
        this.optyTeamMemberNotExistListToInsert = optyTeamMemberNotExistListToInsert;                                                                   
        this.operation = operation;
        this.decCounter = decCounter;
        this.countAccounts = countAccounts;
                                                                            
   	}

    global Iterable<sObject> start(Database.BatchableContext BC)
  	{ 
        if(operation == 'Delete'){
            return listOfOpptyTeamMembersTodelete;
        }else if(operation == 'Insert'){
            return optyTeamMemberNotExistListToInsert;
        }
        return null;
  	}
	
	global void execute(Database.BatchableContext bc, List<OpportunityTeamMember> scope)
  	{
        OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true; 
        set<string> optmOptyIdSet = new set<string>();
		if(operation == 'Delete'){
             for(OpportunityTeamMember otm:scope)
            {
                optmOptyIdSet.add(otm.userId+'_'+otm.opportunityId);
            }
            
            //successlog
            List<BSF_Error_Log__c> successList= BSF_Utilities.platformSuccessLog(optmOptyIdSet,'Populate Account Team','BSF_Batch_OpportunityTeamMember','Batch Triggerred','Success','The Batch Triggerred for delete of Oppty Team userIds_OpportunityId');
            if(!successList.isEmpty())
            {
                try{
                    insert successList;
                }
                catch (exception e)
                {
                    system.debug('The exception in successList: '+e);
                }
            }
            
            Database.DeleteResult[] drList = Database.delete(scope,false);
           	for(Database.DeleteResult dr : drList) {
            	if (!dr.isSuccess()) {
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('Error Deleting teammember record is -> '+err.getStatusCode() + ': ' + err.getMessage());                    
                    }
                }
          	}
            
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(drList, 'Populate Account Team','AccountTeamMemeberService','Batch - BSF_Batch_OpportunityTeamMember','Error','Error in deleting Opportunity Team');
           InsertBsfErrorLog.insertBsfErrors(logList);
		}else if(operation == 'Insert'){
           Database.SaveResult[] srList = Database.insert(scope, false);
           for (Database.SaveResult sr : srList) {
           		if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred in AccountTeamMemberService Insert.'+err.getStatusCode() + ': ' + err.getMessage());                    
                    }	
                }
           }
           List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','AccountTeamMemeberService','Batch - BSF_Batch_OpportunityTeamMember','Error','Error in adding Opportunity Team');
           InsertBsfErrorLog.insertBsfErrors(logList);
           
           
		}
        
  	}
 
  	global void finish(Database.BatchableContext BC)
  	{
        if(operation == 'Insert' && decCounter)
        {
        List<Portfolio_Accounts_Processing__c> pt = [Select Id,Portfolio_progress_for_Accounts__c, Records_Processed__c From Portfolio_Accounts_Processing__c LIMIT 1 FOR UPDATE];
            if (pt.size() > 0) {
                //pt[0].Portfolio_progress_for_Accounts__c = pt[0].Portfolio_progress_for_Accounts__c - countAccounts;
                pt[0].Records_Processed__c += countAccounts;
                update pt;
            }  
        }
        if(operation == 'Delete'){
            Database.executeBatch(new BSF_Batch_OpportunityTeamMember(null,this.optyTeamMemberNotExistListToInsert,'Insert',decCounter,countAccounts),100);
        }
  	}
}