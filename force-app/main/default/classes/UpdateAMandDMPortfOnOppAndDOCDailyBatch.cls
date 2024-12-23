/* 
 * @description: This batch executed to populate opportinity's and DOC's AM, DM and AM and DM portfolio lookup correctly.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 12/03/2024                Krapy Tuli	        This batch will update AM and DM fields on Opp and DOC and its run daily and also chain with UpdateAMandDMPortfolioDailyBatch
 ************************************************************************************************************************************************
*/
global class UpdateAMandDMPortfOnOppAndDOCDailyBatch implements Database.Batchable<sObject>,Database.Stateful{
    //HRP-11849 starts
    String query;
    Set<Id> accountIdSet = new set<Id>();
    Date driveStartDate; 
    Date driveEndDate; 

    public UpdateAMandDMPortfOnOppAndDOCDailyBatch(){
        this.query = 'SELECT Id, Account_Manager__c, AccountId, District_Manager__c, Drive_Date__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c FROM Opportunity WHERE (Account_Manager__c = NULL OR District_Manager__c = NULL OR District_Manager_Portfolio__c = NULL OR Account_Manager_Portfolio__c = NULL)';
    }

    public UpdateAMandDMPortfOnOppAndDOCDailyBatch(Date startDate, Date endDate){
        if(startDate != null && endDate != null){
            this.driveStartDate = startDate;
            this.driveEndDate = endDate;
            this.query = 'SELECT Id, Account_Manager__c, AccountId, District_Manager__c, Drive_Date__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c FROM Opportunity WHERE Drive_Date__c >= :driveStartDate AND  Drive_Date__c <= :driveEndDate';
        }
    }

    public UpdateAMandDMPortfOnOppAndDOCDailyBatch(Set<Id> accountIdSet){
        if(accountIdSet != null && !accountIdSet.isEmpty()){
            this.accountIdSet = accountIdSet;
            this.query = 'SELECT Id, Account_Manager__c, AccountId, District_Manager__c, Drive_Date__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c FROM Opportunity WHERE AccountId IN :accountIdSet AND Drive_Date__c >= TODAY AND Drive_Status__c NOT IN (\'Cancel\') AND is_template__c = FALSE';
        }
    }
    //HRP-11849 ends
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
        
    }
    public void execute(Database.BatchableContext BC, List<Opportunity> opportunities){
        try {
            String AMRole = 'Account Manager';
            String DMRole = 'District Manager';
            Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();
            Set<Id> accountIdSet = new Set<Id>();
            for (Opportunity opp : opportunities) {
                accountIdSet.add(opp.AccountId);
            }
            List<AccountTeamMember> atms = new List<AccountTeamMember>();
            Map<Id, List<AccountTeamMember>> accIdVsMembers = new Map<Id, List<AccountTeamMember>>();
            atms = [SELECT Id,AccountId,TeamMemberRole,Coverage_Reason__c,UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c, BSF_Portfolio__c  FROM AccountTeamMember WHERE TeamMemberRole IN (:AMRole,:DMRole) AND AccountId IN: accountIdSet];
            for (AccountTeamMember atm : atms) {
                if (!accIdVsMembers.containsKey(atm.AccountId)) {
                accIdVsMembers.put(atm.AccountId, new List<AccountTeamMember>()); 
                }accIdVsMembers.get(atm.AccountId).add(atm);
            }
            Map<Id, List<Account_Portfolio_Assignment__c>> accIdVsaccPortfolioAssignmentMap = new Map<Id, List<Account_Portfolio_Assignment__c>>();
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
                                                        AND Account__c IN: accountIdSet
                                                        AND BSF_Portfolio__r.Taxonomy_Type__c IN ('Bio Recruitment CD','Bio Account Portfolio')]){
                if (!accIdVsaccPortfolioAssignmentMap.containsKey(pfa.Account__c)) {
                    accIdVsaccPortfolioAssignmentMap.put(pfa.Account__c, new List<Account_Portfolio_Assignment__c>()); 
                }
                accIdVsaccPortfolioAssignmentMap.get(pfa.Account__c).add(pfa);
            }
            for (Opportunity opp : opportunities) {
                Boolean updated = false;
                List<AccountTeamMember> oatms;
                oatms = accIdVsMembers.containsKey(opp.AccountId) ? accIdVsMembers.get(opp.AccountId) : new List<AccountTeamMember>();
                if (!oatms.isEmpty()) {
                    Map<String,Id> atmAMandDMCoveringUser = new Map<String,Id>();
                    Map<String,Id> atmAMDMUser = new Map<String,Id>();
                    for (AccountTeamMember atm : oatms) {
                        if ((atm.Start_Date__c <= opp.Drive_Date__c  && atm.End_Date__c >= opp.Drive_Date__c) && atm.Is_Covering_Recruiter__c == false){
                            if(atm.TeamMemberRole=='Account Manager'){
                                atmAMDMUser.put('Account Manager_AM_'+atm.accountId,atm.UserId);
                            } else if(atm.TeamMemberRole=='District Manager'){
                                atmAMDMUser.put('District Manager_DM_'+atm.accountId,atm.UserId);
                            }
                        }
                        if ((atm.Start_Date__c <= opp.Drive_Date__c  && atm.End_Date__c >= opp.Drive_Date__c) && atm.Is_Covering_Recruiter__c == true){
                            if(atm.TeamMemberRole=='Account Manager'){
                                atmAMandDMCoveringUser.put('Account Manager_AM_'+atm.accountId,atm.UserId);
                            } else if(atm.TeamMemberRole=='District Manager'){
                                atmAMandDMCoveringUser.put('District Manager_DM_'+atm.accountId,atm.UserId);
                            }
                        }
                    }
                    Boolean oppNeedToUpdate = false;
                    if(atmAMandDMCoveringUser.get('Account Manager_AM_'+opp.accountId) != NULL && atmAMandDMCoveringUser.get('Account Manager_AM_'+opp.accountId) != opp.Account_Manager__c){
                        opp.Account_Manager__c = atmAMandDMCoveringUser.get('Account Manager_AM_'+opp.accountId);
                        oppNeedToUpdate = true;
                    } else if(atmAMDMUser.get('Account Manager_AM_'+opp.accountId) != NULL && atmAMDMUser.get('Account Manager_AM_'+opp.accountId) != opp.Account_Manager__c){
                        opp.Account_Manager__c = atmAMDMUser.get('Account Manager_AM_'+opp.accountId);
                        oppNeedToUpdate = true;
                    }
                    if(atmAMandDMCoveringUser.get('District Manager_DM_'+opp.accountId) != NULL && atmAMandDMCoveringUser.get('District Manager_DM_'+opp.accountId) != opp.District_Manager__c){
                        opp.District_Manager__c = atmAMDMUser.get('District Manager_DM_'+opp.accountId);
                        oppNeedToUpdate = true;
                    } else if(atmAMDMUser.get('District Manager_DM_'+opp.accountId) != NULL && atmAMDMUser.get('District Manager_DM_'+opp.accountId) != opp.District_Manager__c){
                        opp.District_Manager__c = atmAMDMUser.get('District Manager_DM_'+opp.accountId);
                        oppNeedToUpdate = true;
                    }
                    if (oppNeedToUpdate) {
                        oppsToUpdate.put(opp.Id,opp);
                    }
                }
                if (accIdVsaccPortfolioAssignmentMap.containsKey(opp.AccountId)) {
                    Id oldAMPortfolio = opp.Account_Manager_Portfolio__c;
                    Id oldDMPortfolio = opp.District_Manager_Portfolio__c;
                    for(Account_Portfolio_Assignment__c pfa : accIdVsaccPortfolioAssignmentMap.get(opp.AccountId)){
                        if(pfa.Start_Date__c <= opp.Drive_Date__c  && pfa.End_Date__c >= opp.Drive_Date__c){
                            opp.Account_Manager_Portfolio__c = pfa.BSF_Portfolio__c;
                            if(pfa.BSF_Portfolio__r.Parent_Portfolio__c != null 
                                    && String.isNotBlank(pfa.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c)
                                    && pfa.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase('District Manager')){
                                        opp.District_Manager_Portfolio__c = pfa.BSF_Portfolio__r.Parent_Portfolio__c;
                            }else if(pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c != null 
                                    && String.isNotBlank(pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c)
                                    && pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c.equalsIgnoreCase('District Manager')){
                                        opp.District_Manager_Portfolio__c = pfa.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c;
                            }else{
                                opp.District_Manager_Portfolio__c = null;
                            }
                            break;
                        }else{
                            opp.Account_Manager_Portfolio__c = null;
                            opp.District_Manager_Portfolio__c = null;
                        }
                    }
                    if(opp.Account_Manager_Portfolio__c != oldAMPortfolio || opp.District_Manager_Portfolio__c != oldDMPortfolio){
                        updated = true;
                    }
                }
                if (updated) {
                    oppsToUpdate.put(opp.Id,opp);
                }
            }
            if (!oppsToUpdate.isEmpty()) {
                TriggerHandler.bypass('OpportunityTriggerHandler');
                TriggerHandler.bypass('DriveTriggerHandler');
                skedHubBase.BypassUpdateTriggers = true;
                Database.SaveResult[] srList = Database.update(oppsToUpdate.values(), false);
                OpportunityService.updateAMDMPortfolioOnDOC(oppsToUpdate.values(),null);
                TriggerHandler.clearbypass('OpportunityTriggerHandler');
                TriggerHandler.clearbypass('DriveTriggerHandler');
                skedHubBase.BypassUpdateTriggers = false;
                List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(srList,'OpportunityPortfolioAssignment','UpdateAMandDMPortfOnOppAndDOCDailyBatch','execute','Error','Update Failed');
                if(!errorList.isEmpty()){
                    Database.insert(errorList, false);
                }
            }
        } catch (Exception expt) {
            BSF_Error_Log__c err = BSF_Utilities.getErrorLog('UpdateAMandDMPortfOnOppAndDOCDailyBatch','UpdateAMandDMPortfOnOppAndDOCDailyBatch','execute','Error',expt.getStackTraceString(),expt.getMessage());
            insert err;
        }
    }
    public void finish(Database.BatchableContext bc){
        System.debug('UpdateAMandDMPortfOnOppAndDOCDailyBatch has run succesfully');
    }
}