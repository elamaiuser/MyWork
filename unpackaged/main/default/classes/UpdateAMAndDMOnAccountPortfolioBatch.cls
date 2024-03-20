global class UpdateAMAndDMOnAccountPortfolioBatch implements Database.Batchable<sObject>,Database.Stateful{

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String AMRole = 'Account Manager';
        String DMRole = 'District Manager';
        Date today = Date.today();
        String query = 'SELECT Id,Account_Manager__c, District_Manager__c, District_Manager_Portfolio__c, Account_Manager_Portfolio__c, (SELECT Id,AccountId,TeamMemberRole,Coverage_Reason__c,UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,Account.Account_Manager__c,Account.District_Manager__c, BSF_Portfolio__c  FROM AccountTeamMembers WHERE TeamMemberRole IN (:AMRole,:DMRole)) FROM Account WHERE (Account_Manager__c = NULL OR District_Manager__c = NULL OR District_Manager_Portfolio__c = NULL OR Account_Manager_Portfolio__c = NULL)';
        return Database.getQueryLocator(query);
        
    }
    public void execute(Database.BatchableContext BC, List<Account> accounts){
        system.debug('accounts value :: '+accounts);
        //system.debug('accounts value :: '+accounts[0].Name);
        /*List<Account_Portfolio_Assignment__c> acctPortfolioAssignments = new List<Account_Portfolio_Assignment__c>();
        acctPortfolioAssignments = [Select Id, Start_Date__c , End_Date__c , Account__c , BSF_Portfolio__c  From Account_Portfolio_Assignment__c
                                   Where Account__c IN: accounts AND Start_Date__c <= today AND End_Date__c >= today AND (Portfolio_Type__c = 'Account Based'
                                   OR Portfolio_Type__c = 'Territory Based')];*/
		List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accounts) {
            Boolean updated = false;
            //if ((acc.Account_Manager__c != null && acc.Account_Manager_Portfolio__c == null ) || (acc.District_Manager__c != null && acc.District_Manager_Portfolio__c == null)) { 
                Map<String,Id> atmPortfolio = new Map<String,Id>();
                Map<String,Id> atmAMDMUser = new Map<String,Id>();
                for (AccountTeamMember atm : acc.AccountTeamMembers) {
                    system.debug('atm test:: '+atm);
                    if (atm.Start_Date__c <= Date.today() && atm.End_Date__c >= Date.today() && atm.Is_Covering_Recruiter__c == false){
                        system.debug('atm test:: '+atm);
                        if(atm.TeamMemberRole=='Account Manager'){
                            atmPortfolio.put('Account Manager_'+atm.accountId,atm.BSF_Portfolio__c);
                        } else if(atm.TeamMemberRole=='District Manager'){
                            atmPortfolio.put('District Manager_'+atm.accountId,atm.BSF_Portfolio__c);
                        }
                    }
                    if (atm.Start_Date__c <= Date.today() && atm.End_Date__c >= Date.today() && atm.Is_Covering_Recruiter__c == true){
                        system.debug('atm test:: '+atm);
                        if(atm.TeamMemberRole=='Account Manager'){
                            system.debug('atm test:: '+atm);
                            atmAMDMUser.put('Account Manager_AM_'+atm.accountId,atm.UserId);
                        } else if(atm.TeamMemberRole=='District Manager'){
                            system.debug('atm test:: '+atm);
                            atmAMDMUser.put('District Manager_DM_'+atm.accountId,atm.UserId);
                        }
                    }
                }
                system.debug('atmPortfolio test:: '+atmPortfolio);
            system.debug('atmAMDMUser test:: '+atmAMDMUser);
                for (AccountTeamMember atm : acc.AccountTeamMembers) {
                    if (atm.Start_Date__c <= Date.today() && atm.End_Date__c >= Date.today()) {
                        system.debug('atm test:: '+atm);
                        if(atm.TeamMemberRole == 'Account Manager' && atm.Is_Covering_Recruiter__c == true && acc.Account_Manager__c != atm.UserId){
                            updated = true;
                            acc.Account_Manager__c = atm.UserId;
                            acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } else if(atm.TeamMemberRole == 'Account Manager' && atm.Is_Covering_Recruiter__c == false && acc.Account_Manager__c != atm.UserId){
                            if(atmAMDMUser.get(atm.TeamMemberRole+'_AM_'+atm.accountId)==null){
                                updated = true;
                                acc.Account_Manager__c = atm.UserId;
                                acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            } else{
                                updated = true;
                                acc.Account_Manager__c = atm.UserId;
                                acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            }
                        }

                        if(atm.TeamMemberRole == 'District Manager' && atm.Is_Covering_Recruiter__c == true && acc.District_Manager__c != atm.UserId){
                            updated = true;
                            acc.District_Manager__c = atm.UserId;
                            acc.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } else if(atm.TeamMemberRole == 'District Manager' && atm.Is_Covering_Recruiter__c == false && acc.District_Manager__c != atm.UserId){
                            if(atmAMDMUser.get(atm.TeamMemberRole+'_DM_'+atm.accountId)==null){
                                updated = true;
                                acc.District_Manager__c = atm.UserId;
                                acc.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            } else{
                                updated = true;
                                acc.District_Manager__c = atm.UserId;
                                acc.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) == null ? null: atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            }
                        }
                            // System.debug('26');
                            // if (acc.Account_Manager__c == atm.UserId && atm.TeamMemberRole == 'Account Manager' && atm.BSF_Portfolio__c != null) {
                            //     System.debug('AMP');
                            //     acc.Account_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                            //     updated = true;
                            // }
                            // if (acc.District_Manager__c == atm.UserId && atm.TeamMemberRole == 'District Manager' && atm.BSF_Portfolio__c != null) {
                            //      System.debug('DMP');
                            //     acc.District_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                            //     updated = true;
                            // }
                            
                    }
                }
                if (updated) {
                    accountsToUpdate.add(acc);
                }
            //}
        }
        if (!accountsToUpdate.isEmpty()) {
            for (Account acc : accountsToUpdate) {
                System.debug('Id--> '+acc.Id);
                System.debug('AM--> '+acc.Account_Manager__c);
                System.debug('AMP--> '+acc.Account_Manager_Portfolio__c);
                System.debug('DM--> '+acc.District_Manager__c);
                System.debug('AMP--> '+acc.District_Manager_Portfolio__c);
            }
            update accountsToUpdate;
        }
        
    }
    public void finish(Database.BatchableContext bc){
        System.debug('UpdateAMAndDMPortfolioBatch has run succesfully');
    }
}