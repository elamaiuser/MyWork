/* 
 * @description: This batch runs dails to update portfolios in Accounts and Opportunities.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 02/21/2024                Barnojit Sharma	      DOC does not pull up AM and DM portfolio according to drive date. (HRP-11849)
 ************************************************************************************************************************************************
*/
global class UpdateAMAndDMPortfolioDailyBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    String query = 'SELECT Account__c, Account__r.Account_Manager_Portfolio__c , Account__r.District_Manager_Portfolio__c FROM Account_Portfolio_Assignment__c Where BSF_Portfolio__r.Portfolio_Type__c = \'Account Manager\' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN (\'Bio Recruitment CD\',\'Bio Account Portfolio\') AND (CreatedDate = yesterday OR CreatedDate = today OR LastModifiedDate = yesterday OR LastModifiedDate = today OR Start_Date__c = yesterday OR Start_Date__c = today)';
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    global void execute(SchedulableContext cc) {
        Database.executeBatch(new UpdateAMAndDMPortfolioDailyBatch(),200);
    }
    global void execute(Database.BatchableContext BC, List<Account_Portfolio_Assignment__c> accPortfolioAssignmentList){
        //initialize trigger bypass
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        triggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;

        Map<Id,List<Account_Portfolio_Assignment__c>> mapToStoreAccVsPortfolioAssignment = new  Map<Id,List<Account_Portfolio_Assignment__c>>();
        Map<Id, Account> impactedAccMap = new Map<Id, Account>();
        List<Account> accToBeUpdate = new List<Account>();
        List<Opportunity> oppToBeUpdate = new List<Opportunity>();

        for(Account_Portfolio_Assignment__c accPort : accPortfolioAssignmentList){
            if(accPort.Account__c != null){
                impactedAccMap.put(accPort.Account__c,accPort.Account__r);
            }
        }
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
        Map<Id,Opportunity> oppMapIdVsOpp = new Map<Id,Opportunity>([SELECT Id ,
                                                                            AccountId, 
                                                                            Account_Manager_Portfolio__c, 
                                                                            District_Manager_Portfolio__c,
                                                                            Drive_Date__c
                                                                    FROM Opportunity 
                                                                    WHERE Drive_Date__c != null 
                                                                    AND is_template__c = false 
                                                                    AND AccountID IN: impactedAccMap.keySet()]);
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
        //HRP-11849 starts
        List<BSF_Error_Log__c> errorList = new List<BSF_Error_Log__c>();
        if(!accToBeUpdate.isEmpty()){
            Database.SaveResult[] srList = Database.update(accToBeUpdate, false);
            errorList.addAll(BSF_Utilities.createErrorLog(srList,'OpportunityPortfolioAssignment','UpdateAMAndDMPortfolioDailyBatch','execute','Error','Update Failed'));
        }
        if(!oppToBeUpdate.isEmpty()){
            Database.SaveResult[] srList = Database.update(oppToBeUpdate, false);
            OpportunityService.updateAMDMPortfolioOnDOC(oppToBeUpdate,null);
            errorList.addAll(BSF_Utilities.createErrorLog(srList,'OpportunityPortfolioAssignment','UpdateAMAndDMPortfolioDailyBatch','execute','Error','Update Failed'));
        }
        if(!errorList.isEmpty()){
            Database.insert(errorList, false);
        }
        //clear trigger bypass
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
        TriggerHandler.clearbypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = false;
    }
    global void finish(Database.BatchableContext bc){}
}