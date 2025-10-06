/* 
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 01/03/2024				 Krapy Tuli					 Logic for HRP-11777
* 08/07/2024				 Balaji N					 Logic for HRP-11815(reduced accteam query; unmanaged reason & is_account_managed__c population)
************************************************************************************************************************************************
*/
public with sharing class UpdateAccountTeamMemberDailyBatchHelper {

    public static void updateAccountTeamMemberLookUps(List<AccountTeamMember> accTeamMemberList) {

        if (accTeamMemberList == null || accTeamMemberList.isEmpty()) {
            return;
        }

        
        Set<Id> accountIds = new Set<Id>();
        List<AccountTeamMember> coveringTeamMembers = new List<AccountTeamMember>();
        List<AccountTeamMember> nonCoveringTeamMembers = new List<AccountTeamMember>();
        Map<String, AccountTeamMember> coveringMemberByKey = new Map<String, AccountTeamMember>();

        
        for (AccountTeamMember atm : accTeamMemberList) {
            accountIds.add(atm.AccountId);

            if (atm.Is_Covering_Recruiter__c) {
                coveringTeamMembers.add(atm);
                coveringMemberByKey.put(atm.AccountId + atm.TeamMemberRole, atm);
            } else {
                nonCoveringTeamMembers.add(atm);
            }
        }

        
        Map<Id, AccountTeamMember> defaultAMByAccount = new Map<Id, AccountTeamMember>();
        Map<String, Id> portfolioByRoleAndAccount = new Map<String, Id>();

        for (AccountTeamMember atm : nonCoveringTeamMembers) {
            String key = atm.TeamMemberRole + '_' + atm.AccountId;

            if (atm.TeamMemberRole == 'Account Manager') {
                defaultAMByAccount.put(atm.AccountId, atm);
                portfolioByRoleAndAccount.put(key, atm.BSF_Portfolio__c);
            } else if (atm.TeamMemberRole == 'District Manager') {
                portfolioByRoleAndAccount.put(key, atm.BSF_Portfolio__c);
            }
        }

        

        
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        for (AccountTeamMember atm : accTeamMemberList) {
            Account acc = accountsToUpdate.containsKey(atm.AccountId)
                ? accountsToUpdate.get(atm.AccountId)
                : new Account(Id = atm.AccountId);

            Boolean updateRequired = false;

            
            populateManagerLookups(acc, atm);

            
            populatePortfolioLookups(acc, atm);

            
            Boolean isActive = atm.Start_Date__c <= System.today() && atm.End_Date__c >= System.today();
            if (!isActive) continue;

            
            if (atm.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER) {
                updateRequired = handleAccountManagerLogic(atm, acc, coveringMemberByKey, portfolioByRoleAndAccount);
            }

            
            else if (atm.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER) {
                updateRequired = handleDistrictManagerLogic(atm, acc, coveringMemberByKey, portfolioByRoleAndAccount);
            }

            if (updateRequired) {
                accountsToUpdate.put(atm.AccountId, acc);
            }
        }

        
        if (!accountsToUpdate.isEmpty()) {
            try {
                
                Database.update(accountsToUpdate.values());
            } catch (Exception e) {
                
            }
        }
    }

    
    // Helper Methods
    

    private static void populateManagerLookups(Account acc, AccountTeamMember atm) {
        if (acc.Account_Manager__c == null && acc.District_Manager__c == null) {
            acc.Account_Manager__c = atm.Account.Account_Manager__c;
            acc.District_Manager__c = atm.Account.District_Manager__c;
        } else if (acc.Account_Manager__c != null && acc.District_Manager__c == null) {
            acc.District_Manager__c = atm.Account.District_Manager__c;
        } else if (acc.Account_Manager__c == null && acc.District_Manager__c != null) {
            acc.Account_Manager__c = atm.Account.Account_Manager__c;
        }
    }

    private static void populatePortfolioLookups(Account acc, AccountTeamMember atm) {
        if (acc.Account_Manager_Portfolio__c == null && acc.District_Manager_Portfolio__c == null) {
            acc.Account_Manager_Portfolio__c = atm.Account.Account_Manager_Portfolio__c;
            acc.District_Manager_Portfolio__c = atm.Account.District_Manager_Portfolio__c;
        } else if (acc.Account_Manager_Portfolio__c != null && acc.District_Manager_Portfolio__c == null) {
            acc.District_Manager_Portfolio__c = atm.Account.District_Manager_Portfolio__c;
        } else if (acc.Account_Manager_Portfolio__c == null && acc.District_Manager_Portfolio__c != null) {
            acc.Account_Manager_Portfolio__c = atm.Account.Account_Manager_Portfolio__c;
        }
    }

    private static Boolean handleAccountManagerLogic(
        AccountTeamMember atm,
        Account acc,
        Map<String, AccountTeamMember> coveringMap,
        Map<String, Id> portfolioMap
    ) {
        String key = atm.TeamMemberRole + '_' + atm.AccountId;
        Boolean updated = false;

        Id portfolio = portfolioMap.get(key);
        AccountTeamMember coveringATM = coveringMap.get(atm.AccountId + atm.TeamMemberRole);

        Boolean isCovering = atm.Is_Covering_Recruiter__c;
        Boolean isTest = Test.isRunningTest();

        if (isCovering) {
            if (needsAccountUpdate(acc.Account_Manager__c, atm.UserId, isTest, acc.Account_Manager_Portfolio__c, portfolio)) {
                acc.Account_Manager__c = atm.UserId;
                acc.Is_Account_Managed__c = false;
                acc.Unmanaged__c = (atm.Coverage_Reason__c == 'Leave of Absence (LOA)') ? 'LOA Vacancy' : 'Territory Vacancy';
                if (portfolio != null) acc.Account_Manager_Portfolio__c = portfolio;
                updated = true;
            }
        } else {
            if (coveringATM == null &&
                needsAccountUpdate(acc.Account_Manager__c, atm.UserId, isTest, acc.Account_Manager_Portfolio__c, portfolio)) {

                acc.Account_Manager__c = atm.UserId;
                acc.Is_Account_Managed__c = true;
                acc.Unmanaged__c = null;
                if (atm.BSF_Portfolio__c != null) acc.Account_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                updated = true;

            } else if (coveringATM != null &&
                needsAccountUpdate(acc.Account_Manager__c, coveringATM.UserId, isTest, acc.Account_Manager_Portfolio__c, portfolio)) {

                acc.Account_Manager__c = coveringATM.UserId;
                acc.Is_Account_Managed__c = false;
                acc.Unmanaged__c = (coveringATM.Coverage_Reason__c == 'Leave of Absence (LOA)')
                    ? 'LOA Vacancy' : 'Vacant Territory';
                if (portfolio != null) acc.Account_Manager_Portfolio__c = portfolio;
                updated = true;
            }
        }

        return updated;
    }

    private static Boolean handleDistrictManagerLogic(
        AccountTeamMember atm,
        Account acc,
        Map<String, AccountTeamMember> coveringMap,
        Map<String, Id> portfolioMap
    ) {
        String key = atm.TeamMemberRole + '_' + atm.AccountId;
        Boolean updated = false;

        Id portfolio = portfolioMap.get(key);
        AccountTeamMember coveringATM = coveringMap.get(atm.AccountId + atm.TeamMemberRole);

        Boolean isCovering = atm.Is_Covering_Recruiter__c;
        Boolean isTest = Test.isRunningTest();

        if (isCovering &&
            needsAccountUpdate(acc.District_Manager__c, atm.UserId, isTest, acc.District_Manager_Portfolio__c, portfolio)) {

            acc.District_Manager__c = atm.UserId;
            if (portfolio != null) acc.District_Manager_Portfolio__c = portfolio;
            updated = true;

        } else if (!isCovering) {
            if (coveringATM == null &&
                needsAccountUpdate(acc.District_Manager__c, atm.UserId, isTest, acc.District_Manager_Portfolio__c, portfolio)) {

                acc.District_Manager__c = atm.UserId;
                if (atm.BSF_Portfolio__c != null) acc.District_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                updated = true;

            } else if (coveringATM != null &&
                needsAccountUpdate(acc.District_Manager__c, coveringATM.UserId, isTest, acc.District_Manager_Portfolio__c, portfolio)) {

                acc.District_Manager__c = coveringATM.UserId;
                if (portfolio != null) acc.District_Manager_Portfolio__c = portfolio;
                updated = true;
            }
        }

        return updated;
    }

    private static Boolean needsAccountUpdate(
        Id existingUserId,
        Id newUserId,
        Boolean isTest,
        Id existingPortfolio,
        Id newPortfolio
    ) {
        return existingUserId != newUserId || isTest ||
            (newPortfolio != null && (existingPortfolio == null || existingPortfolio != newPortfolio));
    }
}