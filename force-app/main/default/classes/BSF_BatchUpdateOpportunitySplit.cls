/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/21/2023				 Kishore Das		        Logic for HRP-11168(Coverage Recruiter Updated as Drive Owner on Opportunity Split)

 *************************************************************************************************************************************************
*/
global class BSF_BatchUpdateOpportunitySplit implements Database.Batchable<SObject>{

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [SELECT Id,name from account]
        );
    }
    
    
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        list<Id> accIdList = new list<Id>(); 
        for(account a:scope){
            accIdList.add(a.id);
        }
        
        List<AccountTeamMember> atmList = [SELECT Id, AccountId,UserId, AccountAccessLevel, OpportunityAccessLevel,
             CaseAccessLevel, Coverage_Reason__c, Start_Date__c, End_Date__c, 
             Is_Covering_Recruiter__c FROM AccountTeamMember 
             WHERE End_Date__c > TODAY AND Is_Covering_Recruiter__c = true and AccountId IN:accIdList];
        
        map<Id,AccountTeamMember> teammembertoAccountMap = new map<Id,AccountTeamMember>();
        
        for(AccountTeamMember atm : atmList){
            teammembertoAccountMap.put(atm.AccountId,atm);
        }
        list<Opportunity> oppList = [select id,name,drive_date__c,accountId from opportunity where drive_date__c>today AND accountId In:teammembertoAccountMap.keyset()];
        Map<Id,Opportunity> oppMap= new Map<Id,Opportunity>();
        for(Opportunity opp:oppList){
            AccountTeamMember atm = teammembertoAccountMap.get(opp.accountId);
            if((opp.drive_date__c<=atm.End_Date__c) && (opp.drive_date__c>=atm.Start_Date__c)){
                oppMap.put(opp.id,opp);
            }
        }
        OpportunitySplitType overlaySplitType = [SELECT DeveloperName,Id FROM OpportunitySplitType WHERE DeveloperName = 'Overlay'];
        list<OpportunitySplit> opSplit = [select Id,OpportunityId,SplitTypeId,SplitPercentage,Split_Reason__c,SplitOwnerId from OpportunitySplit where OpportunityId in:oppMap.keyset()
                                         AND SplitTypeId =: overlaySplitType.Id];
        Set<Id> oppSplitExists = new Set<Id>();
        for(OpportunitySplit os:opSplit){
            oppSplitExists.add(os.OpportunityId);
        }
        List<OpportunitySplit> osplitList = new List<OpportunitySplit>();
        for(Id oppId: oppMap.keySet()){
            if(oppSplitExists.isEmpty() || !oppSplitExists.contains(oppId)){
                		String coverageRsn = teammembertoAccountMap.get(oppMap.get(oppId).accountId).Coverage_Reason__c;
                        OpportunitySplit split = new OpportunitySplit();
                        split.SplitTypeId = overlaySplitType.Id;
                        split.OpportunityId = oppId;
                        split.SplitOwnerId = teammembertoAccountMap.get(oppMap.get(oppId).accountId).UserId;
                        split.SplitPercentage = 100;
                		split.Split_Reason__c = (coverageRsn == BSF_Constants.accTeamLoa) ? BSF_Constants.opSplitLoa : 
                        (coverageRsn == BSF_Constants.accTeamVacant) ? BSF_Constants.opSplitVacant : 
                        null;
                        split.Is_Covering_Incentive__c = true; 
                        osplitList.add(split);
            }
        }
        if(!osplitList.isEmpty()){
                        OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                        Database.SaveResult[] results = Database.insert(osplitList, false);
                        for (Database.SaveResult sr : results) {
                            system.debug('split member inserted successfully');
                            if (!sr.isSuccess()) {
                                for(Database.Error err : sr.getErrors()) {
                                    System.debug('The following error has occurred.');
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    System.debug('Fields that affected this error: ' + err.getFields()); 
                                }
                            }
                        }
        }
    }
    global void finish(Database.BatchableContext bc) {
        
    }
}