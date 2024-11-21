/* 
 * @description: This batch executed to populate opportinity's AM DM portfolio lookup correctly.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 02/21/2024                Barnojit Sharma	      DOC does not pull up AM and DM portfolio according to drive date. (HRP-11849)
 ************************************************************************************************************************************************
*/
global class UpdateAMAndDMOnOpportunityPortfolioBatch implements Database.Batchable<sObject>,Database.Stateful{
    //HRP-11849 starts
    String query;
    Set<Id> opportunityIds;
    Date driveStartDate; 
    Date driveEndDate; 

    public UpdateAMAndDMOnOpportunityPortfolioBatch(){
        this.query = 'SELECT Id, Account_Manager__c, AccountId, District_Manager__c, Drive_Date__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c FROM Opportunity WHERE (Account_Manager__c = NULL OR District_Manager__c = NULL OR District_Manager_Portfolio__c = NULL OR Account_Manager_Portfolio__c = NULL)';
    }

    public UpdateAMAndDMOnOpportunityPortfolioBatch(Date startDate, Date endDate){
        if(startDate != null && endDate != null){
            this.driveStartDate = startDate;
            this.driveEndDate = endDate;
            this.query = 'SELECT Id, Account_Manager__c, AccountId, District_Manager__c, Drive_Date__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c FROM Opportunity WHERE Drive_Date__c >= :driveStartDate AND  Drive_Date__c <= :driveEndDate';
        }
    }

    public UpdateAMAndDMOnOpportunityPortfolioBatch(Set<Id> oppIds){
        if(oppIds != null && !oppIds.isEmpty()){
            this.opportunityIds = oppIds;
            this.query = 'SELECT Id, Account_Manager__c, AccountId, District_Manager__c, Drive_Date__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c FROM Opportunity WHERE ID IN :opportunityIds';
        }
    }
    //HRP-11849 ends
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //String AMRole = 'Account Manager';
        //String DMRole = 'District Manager';
        //Date today = Date.today();
        //String accountId = '0066u0000093gaRAAQ';
        //String query = 'SELECT Id, Account_Manager__c, AccountId, District_Manager__c, Drive_Date__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c FROM Opportunity WHERE (Account_Manager__c = NULL OR District_Manager__c = NULL OR District_Manager_Portfolio__c = NULL OR Account_Manager_Portfolio__c = NULL)';
        return Database.getQueryLocator(this.query);
        
    }
    public void execute(Database.BatchableContext BC, List<Opportunity> opportunities){
        system.debug('Opportunity:: '+opportunities.size());
        String AMRole = 'Account Manager';
        String DMRole = 'District Manager';
        /*List<Account_Portfolio_Assignment__c> acctPortfolioAssignments = new List<Account_Portfolio_Assignment__c>();
        acctPortfolioAssignments = [Select Id, Start_Date__c , End_Date__c , Account__c , BSF_Portfolio__c  From Account_Portfolio_Assignment__c
                                   Where Account__c IN: accounts AND Start_Date__c <= today AND End_Date__c >= today AND (Portfolio_Type__c = 'Account Based'
                                   OR Portfolio_Type__c = 'Territory Based')];*/
		List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Set<Id> accountIdSet = new Set<Id>();
        for (Opportunity opp : opportunities) {
            accountIdSet.add(opp.AccountId);
        }
        system.debug('accountIdSet:: '+accountIdSet);
        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        Map<Id, List<AccountTeamMember>> accIdVsMembers = new Map<Id, List<AccountTeamMember>>();
        atms = [SELECT Id,AccountId,TeamMemberRole,Coverage_Reason__c,UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c, BSF_Portfolio__c  FROM AccountTeamMember WHERE TeamMemberRole IN (:AMRole,:DMRole) AND AccountId IN: accountIdSet];
        for (AccountTeamMember atm : atms) {
            if (!accIdVsMembers.containsKey(atm.AccountId)) {
               accIdVsMembers.put(atm.AccountId, new List<AccountTeamMember>()); 
            }accIdVsMembers.get(atm.AccountId).add(atm);
        }
        //HRP-11849 starts
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
        //HRP-11849 ends
        for (Opportunity opp : opportunities) {
            system.debug('opp '+opp.Id);
            Boolean updated = false;
            /*List<AccountTeamMember> oatms;
            oatms = accIdVsMembers.containsKey(opp.AccountId) ? accIdVsMembers.get(opp.AccountId) : new List<AccountTeamMember>();
            if (!oatms.isEmpty()) {
                Map<String,Id> atmPortfolio = new Map<String,Id>();
                Map<String,Id> atmAMDMUser = new Map<String,Id>();
                for (AccountTeamMember atm : oatms) {
                    system.debug('atm v3 '+atm);
                    system.debug('opp value '+opp);
                    system.debug('opp value date '+opp.Drive_Date__c);
                    if ((atm.Start_Date__c <= opp.Drive_Date__c  && atm.End_Date__c >= opp.Drive_Date__c) && atm.Is_Covering_Recruiter__c == false){
                        if(atm.TeamMemberRole=='Account Manager'){
                            atmPortfolio.put('Account Manager_'+atm.accountId,atm.BSF_Portfolio__c);
                        } else if(atm.TeamMemberRole=='District Manager'){
                            atmPortfolio.put('District Manager_'+atm.accountId,atm.BSF_Portfolio__c);
                        }
                    }
                    if ((atm.Start_Date__c <= opp.Drive_Date__c  && atm.End_Date__c >= opp.Drive_Date__c) && atm.Is_Covering_Recruiter__c == true){
                        if(atm.TeamMemberRole=='Account Manager'){
                            atmAMDMUser.put('Account Manager_AM_'+atm.accountId,atm.UserId);
                        } else if(atm.TeamMemberRole=='District Manager'){
                            atmAMDMUser.put('District Manager_DM_'+atm.accountId,atm.UserId);
                        }
                    }
                }
                for (AccountTeamMember atm : oatms) {
                    if (atm.Start_Date__c <= opp.Drive_Date__c  && atm.End_Date__c >= opp.Drive_Date__c) {
                        if(atm.TeamMemberRole == 'Account Manager' && atm.Is_Covering_Recruiter__c == true && opp.Account_Manager__c != atm.UserId){
                            updated = true;
                            opp.Account_Manager__c = atm.UserId;
                            //opp.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } else if(atm.TeamMemberRole == 'Account Manager' && atm.Is_Covering_Recruiter__c == false && opp.Account_Manager__c != atm.UserId){
                            if(atmAMDMUser.get(atm.TeamMemberRole+'_AM_'+atm.accountId)==null){
                                updated = true;
                                opp.Account_Manager__c = atm.UserId;
                                //opp.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            } else{
                                updated = true;
                                opp.Account_Manager__c = atm.UserId;
                                //opp.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            }
                        //HRP-11849 starts
                        }else if(opp.Account_Manager__c != null){
                            updated = true;
                            opp.Account_Manager__c = null;
                        }
                        //HRP-11849 ends
                        if(atm.TeamMemberRole == 'District Manager' && atm.Is_Covering_Recruiter__c == true && opp.District_Manager__c != atm.UserId){
                            updated = true;
                            opp.District_Manager__c = atm.UserId;
                            //opp.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } else if(atm.TeamMemberRole == 'District Manager' && atm.Is_Covering_Recruiter__c == false && opp.District_Manager__c != atm.UserId){
                            if(atmAMDMUser.get(atm.TeamMemberRole+'_DM_'+atm.accountId)==null){
                                updated = true;
                                opp.District_Manager__c = atm.UserId;
                                //opp.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            } else{
                                updated = true;
                                opp.District_Manager__c = atm.UserId;
                                //opp.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            }
                        //HRP-11849 starts
                        }else if(opp.District_Manager__c != null){
                            updated = true;
                            opp.District_Manager__c = null;
                        }
                        //HRP-11849 ends
                    }
                    // if ((atm.Start_Date__c <= opp.Drive_Date__c  && atm.End_Date__c >= opp.Drive_Date__c)) {
                    //     if (atm.TeamMemberRole == 'Account Manager') {
                    //         updated = true;
                    //         opp.Account_Manager__c = atm.UserId;
                    //         opp.Account_Manager_Portfolio__c = atm.BSF_Portfolio__c != null ? atm.BSF_Portfolio__c : opp.Account_Manager_Portfolio__c;
                    //     }
                    //     if (atm.TeamMemberRole == 'District Manager') {
                    //         updated = true;
                    //         opp.District_Manager__c = atm.UserId;
                    //         opp.District_Manager_Portfolio__c = atm.BSF_Portfolio__c != null ? atm.BSF_Portfolio__c : opp.District_Manager_Portfolio__c;
                    //     }
                    // }
                }
            }*/
            //HRP-11849 starts
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
            //HRP-11849 ends
            if (updated) {
                oppsToUpdate.add(opp);
            }
        }
        if (!oppsToUpdate.isEmpty()) {
            /*for (Opportunity opp : oppsToUpdate) {
                System.debug('Id--> '+opp.Id);
                System.debug('AM--> '+opp.Account_Manager__c);
                System.debug('AMP--> '+opp.Account_Manager_Portfolio__c);
                System.debug('DM--> '+opp.District_Manager__c);
                System.debug('AMP--> '+opp.District_Manager_Portfolio__c);
            }*/
            //HRP-11849 starts
            TriggerHandler.bypass('OpportunityTriggerHandler');
            TriggerHandler.bypass('DriveTriggerHandler');
            skedHubBase.BypassUpdateTriggers = true;
            Database.SaveResult[] srList = Database.update(oppsToUpdate, false);
            OpportunityService.updateAMDMPortfolioOnDOC(oppsToUpdate,null);
            TriggerHandler.clearbypass('OpportunityTriggerHandler');
            TriggerHandler.clearbypass('DriveTriggerHandler');
            skedHubBase.BypassUpdateTriggers = false;
            List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(srList,'OpportunityPortfolioAssignment','UpdateAMAndDMOnOpportunityPortfolioBatch','execute','Error','Update Failed');
            if(!errorList.isEmpty()){
                Database.insert(errorList, false);
            }
            //HRP-11849 ends
        }
        
    }
    public void finish(Database.BatchableContext bc){
        System.debug('UpdateAMAndDMPortfolioBatch has run succesfully');
    }
}