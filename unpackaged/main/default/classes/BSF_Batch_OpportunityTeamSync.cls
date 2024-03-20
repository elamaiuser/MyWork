//@Description: creates Opportunity Team from account Team Member
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 
*****************************************************************************
*/
global class BSF_Batch_OpportunityTeamSync implements Database.Batchable<sObject>{ 
	global Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers;
    global Integer countAccounts;
    //HRP-10889
    global String STAGE_CANCELLED = 'Cancelled';
    global DateTime teamMemberModifiedStart;
    global DateTime teamMemberModifiedEnd;
    //HRP-10889
    global BSF_Batch_OpportunityTeamSync(Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers,Integer countAccounts){
        this.mapOfAcctsWithTeamMembers = mapOfAcctsWithTeamMembers;
        this.countAccounts = countAccounts;
    }
    //HRP-10889
    global BSF_Batch_OpportunityTeamSync(DateTime teamMemberModifiedStart,DateTime teamMemberModifiedEnd){
        this.mapOfAcctsWithTeamMembers = new Map<Id,List<AccountTeamMember>>();
        this.countAccounts = 0;
        this.teamMemberModifiedStart = teamMemberModifiedStart;
        this.teamMemberModifiedEnd = teamMemberModifiedEnd;
        
    }
    //HRP-10889
    global Database.QueryLocator start(Database.BatchableContext BC)
  	{ 
        Set<Id> accountIds = mapOfAcctsWithTeamMembers.keySet();
        Date leastStartDate = null;
        Date maxEndDate = null;
        for(Id acctId : mapOfAcctsWithTeamMembers.keySet()){
            for(AccountTeamMember actTeamMember :mapOfAcctsWithTeamMembers.get(acctId)){
                if(leastStartDate == null || leastStartDate > actTeamMember.Start_Date__c){
                    leastStartDate = actTeamMember.Start_Date__c;
                }
                if(maxEndDate == null || maxEndDate < actTeamMember.End_Date__c){
                    maxEndDate = actTeamMember.End_Date__c;
                }
            }
        }
        
        String query = 'SELECT Id, ownerId, AccountId, Drive_Date__c, Account_Manager__c, Account_Manager_Portfolio__c ,Covering_Recruiter__c,District_Manager__c, District_Manager_Portfolio__c FROM Opportunity WHERE AccountId IN :accountIds AND Drive_Date__c != null AND Drive_Date__c >= TODAY AND StageName != :STAGE_CANCELLED AND Drive_Date__c >= :leastStartDate AND Drive_Date__c <= :maxEndDate';
        //HRP-10889  //HRP-10359
        if(mapOfAcctsWithTeamMembers.isEmpty()){
            query = 'SELECT Id, ownerId, AccountId, Drive_Date__c, Account_Manager__c,Covering_Recruiter__c,District_Manager__c, Account_Manager_Portfolio__c, District_Manager_Portfolio__c FROM Opportunity WHERE AccountId IN (SELECT AccountId FROM AccountTeamMember WHERE Lastmodifieddate >=:teamMemberModifiedStart AND Lastmodifieddate <= :teamMemberModifiedEnd) AND Drive_Date__c != null AND Drive_Date__c >= TODAY AND StageName != :STAGE_CANCELLED ';
        }
        //HRP-10889 //HRP-10359
        //System.debug( ' query is '+query);
        return Database.getQueryLocator(query); 
  	}
	
	global void execute(Database.BatchableContext bc, List<Opportunity> scope)
  	{
        List<OpportunityTeamMember> listOfOpptyTeamMembersTodelete = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> optyTeamMemberNotExistListToInsert = new List<OpportunityTeamMember>();
        //HRP-10889
        if(mapOfAcctsWithTeamMembers.isEmpty()){
            Set<Id> accountIdSet = new Set<Id>();
            for(Opportunity oppty:scope){
                accountIdSet.add(oppty.AccountId);
            }
            List<AccountTeamMember> listOfAcctteammembers=[SELECT Id,AccountId,Account.Account_Manager__c,account.District_Manager__c,UserId, TeamMemberRole, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, Start_Date__c, End_Date__c, Coverage_Reason__c, Is_Covering_Recruiter__c, 
                                                   BSF_Portfolio__c FROM AccountTeamMember where AccountId IN:accountIdSet order by createddate desc];
        	for(AccountTeamMember atmRecord:listOfAcctteammembers){   
                if(mapOfAcctsWithTeamMembers.containsKey(atmRecord.AccountId)){
                    List<AccountTeamMember> listOfExistAcctTeamMembers= mapOfAcctsWithTeamMembers.get(atmRecord.AccountId);
                    listOfExistAcctTeamMembers.add(atmRecord);
                    mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,listOfExistAcctTeamMembers);
                } else {       
                    mapOfAcctsWithTeamMembers.put(atmRecord.AccountId,new List<AccountTeamMember>{atmRecord});     
                }
            }
        }
        //HRP-10889
        AccountTeamMemberService.addAcctTeamMembers_To_BloodDriveOpptyMembers(mapOfAcctsWithTeamMembers,scope,listOfOpptyTeamMembersTodelete,optyTeamMemberNotExistListToInsert);
        
        OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true; 
		if(listOfOpptyTeamMembersTodelete.size() > 0){
            Database.DeleteResult[] drList = Database.delete(listOfOpptyTeamMembersTodelete,false);
            for(Database.DeleteResult dr : drList) {
                if (!dr.isSuccess()) {
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('Error Deleting teammember record is -> '+err.getStatusCode() + ': ' + err.getMessage());                    
                    }
                }
            }
			List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(drList, 'Populate Account Team','AccountTeamMemeberService','Batch - BSF_Batch_OpportunityTeamSync','Error','Error in deleting Opportunity Team');
        	InsertBsfErrorLog.insertBsfErrors(logList);
        }
        
        if(optyTeamMemberNotExistListToInsert.size() > 0){
            Database.SaveResult[] srList = Database.insert(optyTeamMemberNotExistListToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred in AccountTeamMemberService Insert.'+err.getStatusCode() + ': ' + err.getMessage());                    
                    }	
                }
            }
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Populate Account Team','AccountTeamMemeberService','Batch - BSF_Batch_OpportunityTeamSync','Error','Error in adding Opportunity Team');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
        
    }
    
    global void finish(Database.BatchableContext BC)
  	{
        insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='BSF_Batch_OpportunityTeamSync',Method__c='finish',Type__c='Success',Error_Description__c='countAccounts '+String.valueOf(countAccounts));
        List<Portfolio_Accounts_Processing__c> pt = [Select Id, Records_Processed__c From Portfolio_Accounts_Processing__c LIMIT 1 FOR UPDATE];	
        if (pt.size() > 0) {	
            pt[0].Records_Processed__c += countAccounts;	
            try{
                update pt;	
            }catch(Exception ex) {
                insert new BSF_Error_Log__c(Process_Name__c ='Run Logs',ApexClass__c='BSF_Batch_OpportunityTeamSync',Method__c='finish',Type__c='Error',Error_Description__c=ex.getMessage()+ '' +String.valueOf(countAccounts));
            }
        }  	
     }
    
}