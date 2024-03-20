//@Description: This is a Helper class for CreateDefaultTerritoryPortfolioBatch; updates "Account_AM_Portfolio_Type__c" on Account
/* 
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 06/14/2023                  Balaji N               Logic for HRP-10099 (commented method call:AccountPortfolioAssignmentService.expireAccountTeamByAccountPortfolio)
* 08/08/2023			 	  Balaji N			 	 Logic for HRP-8897 (commented method call:AccountService.createAccountTeamMembers)											  
* *
*************************************************************************************************************************************************
*/
public with sharing class DefaultTerritoryPortfolioBatchHelper {
    public static void createDefaultTerritoryPortfolioRecords(List<Account_Portfolio_Assignment__c> AccPortfolioList){
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> finalEligibleAccountsIdSet = new Set<Id>();
        Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioMap = new Map<Id,Account_Portfolio_Assignment__c>();
        Map<Id,Account_Portfolio_Assignment__c> accountIdAccPortfolioMap = new Map<Id,Account_Portfolio_Assignment__c>();
        Map<Id,Id> accountAndAccPortfolioIdsMap = new Map<Id,Id>();
        
        List<Account_Portfolio_Assignment__c> nonGeoAccPortfolioList = new List<Account_Portfolio_Assignment__c>();
        for(Account_Portfolio_Assignment__c ap : AccPortfolioList)
        {
            if(ap.BSF_Portfolio__r.Account_Based_Portfolio__c && ap.BSF_Portfolio__r.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE)
            {
                system.debug('nonGeoAccPortfolioList populate');
                nonGeoAccPortfolioList.add(ap);
            }
        }

        List<Account_Portfolio_Assignment__c> geoAccPortfolioList = new List<Account_Portfolio_Assignment__c>();
        for(Account_Portfolio_Assignment__c ap : AccPortfolioList)
        {
            if(ap.BSF_Portfolio__r.Territory_Portfolio__c && (ap.start_Date__c == system.Today() || ap.Start_date__c == system.Today().addDays(-1)))
            {
                system.debug('GeoAccPortfolioList populate');
                geoAccPortfolioList.add(ap);
            }
        }

        for(Account_Portfolio_Assignment__c accPortfolio:nonGeoAccPortfolioList){
            accIdSet.add(accPortfolio.Account__c);
            accountIdAccPortfolioMap.put(accPortfolio.Account__c,accPortfolio);
            accIdAccPortfolioMap.put(accPortfolio.id, accPortfolio);
            accountAndAccPortfolioIdsMap.put(accPortfolio.Account__c,accPortfolio.Id );
        }       
        
        if(accountAndAccPortfolioIdsMap.size()>0){
            List<Account_Portfolio_Assignment__c> accPortfolioList1 = [SELECT Id,Account__c,BSF_Portfolio__c,BSF_Portfolio__r.Name, Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE Account__c IN:accountAndAccPortfolioIdsMap.keySet() AND BSF_Portfolio__r.Portfolio_Type__c =: BSF_Constants.ACCOUNT_MANAGER ]; //Get all the AM Portfolios of the Accounts 
            Map<Id,List<Account_Portfolio_Assignment__c>> accAndaccPortfolioMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
            for(Account_Portfolio_Assignment__c accPortfolio:accPortfolioList1){
                if(!accAndaccPortfolioMap.containsKey(accPortfolio.Account__c)){
                    List<Account_Portfolio_Assignment__c> accPortListForMap = new List<Account_Portfolio_Assignment__c>();
                    accPortListForMap.add(accPortfolio);
                    accAndaccPortfolioMap.put(accPortfolio.Account__c,accPortListForMap);   
                }
                else{
                    List<Account_Portfolio_Assignment__c> accPortListForMap = accAndaccPortfolioMap.get(accPortfolio.Account__c);
                    accPortListForMap.add(accPortfolio);
                    accAndaccPortfolioMap.put(accPortfolio.Account__c,accPortListForMap); 
                }
            }
            
            if(accAndaccPortfolioMap.size()>0){
                for(Id accId:accAndaccPortfolioMap.keySet()){
                    boolean isSkippingThisAcc = false;
                    for(Account_Portfolio_Assignment__c accPort:accAndaccPortfolioMap.get(accId)){
                        System.debug(accid+'-----Enddate'+accIdAccPortfolioMap.get(accountAndAccPortfolioIdsMap.get(accId)).End_Date__c);
                         System.debug(accid+'-----'+accPort);
                        if(accPort.Start_Date__c > accIdAccPortfolioMap.get(accountAndAccPortfolioIdsMap.get(accId)).End_Date__c){
                            System.debug('Its Coming here');
                            isSkippingThisAcc = true; 
                        }
                    }                    
                    if(!isSkippingThisAcc){
                        finalEligibleAccountsIdSet.add(accId);
                    }
                }
            }
        }
        
        List<Account> accList= [SELECT Id, Name, BillingPostalCode,Shippingpostalcode FROM Account WHERE Id IN:finalEligibleAccountsIdSet];
        //Update the Accounts to set the Account AM Portfolio Flag to False
        List<Account_Portfolio_Assignment__c> accPortfolioStartTodayList = new List<Account_Portfolio_Assignment__c>();
        Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioStartTodayMap = new Map<Id,Account_Portfolio_Assignment__c>();
        List<Account> accListToUpdate = new List<Account>();
        for(Account acc:accList){
            if(accountIdAccPortfolioMap.get(acc.id).Start_date__c == system.Today()
              || accountIdAccPortfolioMap.get(acc.id).Start_date__c == system.Today().addDays(-1))
            {
            acc.Account_AM_Portfolio_Type__c = true;
            accListToUpdate.add(acc);
            accPortfolioStartTodayList.add(accountIdAccPortfolioMap.get(acc.id));
            accIdAccPortfolioStartTodayMap.put(acc.id,accountIdAccPortfolioMap.get(acc.id));
            }
            else if (accountIdAccPortfolioMap.get(acc.id).End_date__c ==system.Today())
            {
            acc.Account_AM_Portfolio_Type__c = false;
            accListToUpdate.add(acc);
            }
        }
        try{
            //Schema.DescribeSObjectResult ds = Account.sObjectType.getDescribe();
            //if( ds.isUpdateable() ){}
            Database.update(accListToUpdate);
        }
        catch(Exception e){
            System.debug('An Error has occured: '+e.getMessage());
        }
        
        //Add the code to Expire the Account Team Members associated to the Account-Portfolio in context
        /*List<AccountTeamMember> teamToBeEndDated = AccountPortfolioAssignmentService.expireAccountTeamByAccountPortfolio(nonGeoAccPortfolioList,accIdAccPortfolioMap,'Called from DefaultTerritoryPortfolioBatchHelper');
        Map<String,AccountTeamMember> teamMemberMap = new Map<String,AccountTeamMember>();
        for(AccountTeamMember teamMember:teamToBeEndDated){
            teamMemberMap.put(teamMember.AccountId+''+teamMember.UserId,teamMember);
        }*/
        //Call The method from AccountService to create new Account-Portfolio record and update Team Members End Date
        for(Account_Portfolio_Assignment__c ap:geoAccPortfolioList)
        {
            accIdAccPortfolioStartTodayMap.put(ap.account__c,ap);
        }
        
        //Commented part of HRP-8897,logic moved to "BSF_Batch_CreateDefaultPortfolioAssign" Batch
        //AccountService.createAccountTeamMembers(accList,null,BSF_constants.DEFAULT_TERRITORY_BATCH,accountIdAccPortfolioMap,Null);
        
        // logic change comment HRP-10099
        /*
         BsfPortfolioSyncHelper.correctTeamBSFPorfolioOnAccPortfolioStartDate(accIdAccPortfolioStartTodayMap);
        AccountPortfolioAssignmentService.expireAccountTeamByAccountPortfolio(accPortfolioStartTodayList,accIdAccPortfolioStartTodayMap,'Update AccTeam BSF Portfolio');
        if(teamMemberMap.size() > 0){
            Database.update(teamMemberMap.values(),false);
        }
		*/
    }
}