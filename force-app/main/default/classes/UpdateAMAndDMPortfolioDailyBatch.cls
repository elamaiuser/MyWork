/* 
 * @description: This batch runs dails to update portfolios in Accounts and Opportunities.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 02/21/2024                Barnojit Sharma	      DOC does not pull up AM and DM portfolio according to drive date. (HRP-11849)
 * 12/06/2024				 Krapy Tuli				  Update batch and added error log for HRP-13362.
 ************************************************************************************************************************************************
*/
global class UpdateAMAndDMPortfolioDailyBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    String query;
    Set<Id> accountIdSet = new Set<Id>();
    
    public UpdateAMAndDMPortfolioDailyBatch(){//HRP-13362 start
        this.query = 'SELECT Id, Account__c, Account__r.Account_Manager_Portfolio__c , Account__r.District_Manager_Portfolio__c FROM Account_Portfolio_Assignment__c Where BSF_Portfolio__r.Portfolio_Type__c = \'Account Manager\' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN (\'Bio Recruitment CD\',\'Bio Account Portfolio\') AND (CreatedDate = yesterday OR CreatedDate = today OR LastModifiedDate = yesterday OR LastModifiedDate = today OR Start_Date__c = yesterday OR Start_Date__c = today)';
    }

    public UpdateAMAndDMPortfolioDailyBatch(String batchRunningContext){
        if(batchRunningContext == 'editAndUpdate'){
            this.query = 'SELECT Id, Account__c, Account__r.Account_Manager_Portfolio__c , Account__r.District_Manager_Portfolio__c FROM Account_Portfolio_Assignment__c Where BSF_Portfolio__r.Portfolio_Type__c = \'Account Manager\' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN (\'Bio Recruitment CD\',\'Bio Account Portfolio\') AND (CreatedDate = yesterday OR CreatedDate = today OR LastModifiedDate = yesterday OR LastModifiedDate = today OR Start_Date__c = yesterday OR Start_Date__c = today)';
        } else if(batchRunningContext == 'forCurrentDate'){
            this.query = 'SELECT Id, Account__c, Account__r.Account_Manager_Portfolio__c , Account__r.District_Manager_Portfolio__c FROM Account_Portfolio_Assignment__c Where BSF_Portfolio__r.Portfolio_Type__c = \'Account Manager\' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN (\'Bio Recruitment CD\',\'Bio Account Portfolio\') AND Start_Date__c <= TODAY and End_Date__c>= TODAY';
        }
        
    }//HRP-13362 end
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    global void execute(SchedulableContext cc) {
        Database.executeBatch(new UpdateAMAndDMPortfolioDailyBatch(),integer.valueof(System.Label.ChunkHandlerUpdateAMAndDMPortfolioDailyBatch));//HRP-13362
    }

    global void execute(Database.BatchableContext BC, List<Account_Portfolio_Assignment__c> accPortfolioAssignmentList){
        try {
        //initialize trigger bypass
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;

        Map<Id,List<Account_Portfolio_Assignment__c>> mapToStoreAccVsPortfolioAssignment = new  Map<Id,List<Account_Portfolio_Assignment__c>>();
        Map<Id, Account> impactedAccMap = new Map<Id, Account>();
        List<Account> accToBeUpdate = new List<Account>();
        List<Opportunity> oppToBeUpdate = new List<Opportunity>();
        String accountPortfolioAssignmentRecordsId = '';
        
        for(Account_Portfolio_Assignment__c accPort : accPortfolioAssignmentList){
            if(accPort.Account__c != null){
                impactedAccMap.put(accPort.Account__c,accPort.Account__r);
            }
            accountPortfolioAssignmentRecordsId = accountPortfolioAssignmentRecordsId == '' ? '\''+ accPort.Id + '\'' : accountPortfolioAssignmentRecordsId + ',\'' + accPort.Id + '\'';
        }
        
        BSF_Error_Log__c err = BSF_Utilities.getErrorLog('UpdateAMAndDMPortfolioDailyBatch','UpdateAMAndDMPortfolioDailyBatch','execute','Debug Log',String.valueOf(Date.today()),accountPortfolioAssignmentRecordsId);
        insert err;
        
        for (Account_Portfolio_Assignment__c pfa : [SELECT Id,
                                                            BSF_Portfolio__c,
                                                            BSF_Portfolio__r.Portfolio_Type__c,
                                                            BSF_Portfolio__r.Parent_Portfolio__c,
                                                            BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,
                                                            BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,
                                                            BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,
                                                            End_Date__c,
                                                            Start_Date__c,
                                                            Account__c
                                                    FROM Account_Portfolio_Assignment__c 
                                                    WHERE BSF_Portfolio__r.Portfolio_Type__c = 'Account Manager' 
                                                    AND Account__c IN: impactedAccMap.keySet()
                                                    AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio')]){
            if (!mapToStoreAccVsPortfolioAssignment.containsKey(pfa.Account__c)) {
                mapToStoreAccVsPortfolioAssignment.put(pfa.Account__c, new List<Account_Portfolio_Assignment__c>()); 
            }
            mapToStoreAccVsPortfolioAssignment.get(pfa.Account__c).add(pfa);
        }
        
        String accIds = String.join(new List<Id>(impactedAccMap.keySet()), '\',\''); //HRP-13362 start
        this.accountIdSet.addAll(impactedAccMap.keySet());//HRP-13362 end
        
        for(Id accId : impactedAccMap.keySet()){
            Id amPortfolioId = null;
            Id dmPortfolioId = null;
            if(!mapToStoreAccVsPortfolioAssignment.isEmpty() && mapToStoreAccVsPortfolioAssignment.containsKey(accId)){
                for(Account_Portfolio_Assignment__c accPort : mapToStoreAccVsPortfolioAssignment.get(accId)){
                    if(accPort.Start_Date__c <= System.today() && accPort.End_Date__c >= System.today()){
                        amPortfolioId = accPort.BSF_Portfolio__c;
                        if(accPort.BSF_Portfolio__r.Parent_Portfolio__c != null 
                                && accPort.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager'){
                                    dmPortfolioId = accPort.BSF_Portfolio__r.Parent_Portfolio__c;
                        }else if(accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c != null 
                                && accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager'){
                                    dmPortfolioId = accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c;
                        }
                    }
                }
            }
            
            if(impactedAccMap.get(accId).Account_Manager_Portfolio__c != amPortfolioId || impactedAccMap.get(accId).District_Manager_Portfolio__c != dmPortfolioId){
                accToBeUpdate.add(new Account(Id = accId, Account_Manager_Portfolio__c = amPortfolioId, District_Manager_Portfolio__c = dmPortfolioId));
            }
        }
    /*
        for(Id oppId : oppMapIdVsOpp.keySet()){
            Id amPortfolioId = null;
            Id dmPortfolioId = null;
            if(!mapToStoreAccVsPortfolioAssignment.isEmpty() && mapToStoreAccVsPortfolioAssignment.containsKey(oppMapIdVsOpp.get(oppId).AccountId)){
                for(Account_Portfolio_Assignment__c accPort : mapToStoreAccVsPortfolioAssignment.get(oppMapIdVsOpp.get(oppId).AccountId)){
                    if(accPort.Start_Date__c <= oppMapIdVsOpp.get(oppId).Drive_Date__c && accPort.End_Date__c >= oppMapIdVsOpp.get(oppId).Drive_Date__c){
                        amPortfolioId = accPort.BSF_Portfolio__c;
                        if(accPort.BSF_Portfolio__r.Parent_Portfolio__c != null 
                                && accPort.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager'){
                                    dmPortfolioId = accPort.BSF_Portfolio__r.Parent_Portfolio__c;
                        }else if(accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c != null 
                                && accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager'){
                                    dmPortfolioId = accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c;
                        }
                    }
                }
            }
            
            if(oppMapIdVsOpp.get(oppId).Account_Manager_Portfolio__c != amPortfolioId || oppMapIdVsOpp.get(oppId).District_Manager_Portfolio__c != dmPortfolioId){
                oppToBeUpdate.add(new Opportunity(Id = oppId, Account_Manager_Portfolio__c = amPortfolioId, District_Manager_Portfolio__c = dmPortfolioId));
            }
        }
    */
        //HRP-11849 starts
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        if(!accToBeUpdate.isEmpty()){
            Database.SaveResult[] srList = Database.update(accToBeUpdate, false);
            errorList.addAll(BSF_Utilities.createErrorLog(srList,'OpportunityPortfolioAssignment','UpdateAMAndDMPortfolioDailyBatch','execute','Error','Update Failed'));
        }
        /*
        if(!oppToBeUpdate.isEmpty()){
            Database.SaveResult[] srList = Database.update(oppToBeUpdate, false);
            OpportunityService.updateAMDMPortfolioOnDOC(oppToBeUpdate,null);
            errorList.addAll(BSF_Utilities.createErrorLog(srList,'OpportunityPortfolioAssignment','UpdateAMAndDMPortfolioDailyBatch','execute','Error','Update Failed'));
        }
        */
        if(!errorList.isEmpty()){
            Database.insert(errorList, false);
        }
        //clear trigger bypass
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
        TriggerHandler.clearbypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = false;
        } catch (Exception expt) {
            BSF_Error_Log__c err = BSF_Utilities.getErrorLog('UpdateAMAndDMPortfolioDailyBatch','UpdateAMAndDMPortfolioDailyBatch','execute','Error',expt.getStackTraceString(),expt.getMessage());
            insert err;
        }
    }

    global void finish(Database.BatchableContext bc){
        if(this.accountIdSet.size() != null && this.accountIdSet.size() >0){//HRP-13362 start
            UpdateAMandDMPortfOnOppAndDOCDailyBatch batchUpdate = new UpdateAMandDMPortfOnOppAndDOCDailyBatch(this.accountIdSet);
            database.executeBatch(batchUpdate,integer.valueof(System.Label.ChunkHandlerUpdateAMandDMPortfOnOppAndDOCDailyBatch));
        }//HRP-13362 end
    }
}