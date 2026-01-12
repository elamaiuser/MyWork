//@Description: This class contains different AccountPortfolioAssignment Trigger methods which is called from AccountPortfolioAssignment Trigger Handler
/*
* Modification Log
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 06/14/2023                  Balaji N               Logic for HRP-10099 (Method:accTeamDateSyncOnAccPortUpdates,logic for syncing dates between account team based on Account portfolio assignment and portfolio assignment Dates)
* 08/08/2023			      Balaji N				 Logic for HRP-8897  (Method:accTeamDateSyncOnAccPortUpdates;changed the Value datatype of accIdUserDate map to AccountTeam from list of Dates & downstream changes)
* 09/18/2023			      Balaji N				 Logic for HRP-10878 (Method:handleTerritoryPortfolioInsert,logic for duplicate removal on account portfolio assignment)
* 11/06/2023				  Balaji N				 logic for HRP-11290 (Method:accTeamDateSyncOnAccPortUpdates, Logic for Handling all TeamMemberroles earlier AM node only )
* 12/08/2023				  Balaji N				 logic for HRP-6028 (Method:HandleAccountSpecialist,HandleSpecialistForAM,, Logic for Adding account Specialist based on AM node)
* 12/11/2023				  Balaji N				 logic for HRP-6028 (Method:UpdateAccPortfolioAndAccTeamDates,byPass for TriggerHandler)
* 01/02/2024				  Balaji N				 logic for HRP-10569(Method:UpdateAccPortfolioAndAccTeamDates;accTeamDateSyncOnAccPortUpdates; logic to opportunity Team part of future Account Team Members)
* 01/18/2024				  Balaji N               logic for HRP-11234(Method:systemUserAsOwner; new method-populates Opportunity owner as "system User" and AM and DM lookups blank when no accTeam covers the drive date)
* 02/01/2024				  Balaji N               logic for HRP-11424(Method:accTeamDateSyncOnAccPortUpdates, update CR dates on same user coming as Portfolio Assignment)
* 02/06/2024			      Venkat Dangeti	     logic for HRP-12053(New method handleSupervisorAPAs,supervisor code removed from UpdateAccPortfolioAndAccTeamDates)
* 02/13/2024				  Balaji N				 logic for HRP-11138(New Method :HandleAccExceptionDelete)
* 02/14/2024				  Balaji N				 logic for HRP-11138(New Method :zipTerrForException, wrapper class)
* 02/26/2024				  Balaji N				 logic for HRP-12122(Method :accTeamDateSyncOnAccPortUpdates, overlapping roles)
* 03/28/2024				  Balaji N				 logic for HRP-12390(Method:accTeamDateSyncOnAccPortUpdates, OpportunityLookupcorrection onetimeBatch)
* 07/12/2024				  Balaji N 				 logic for HRP-13028(Method:HandleAccExceptionDelete, null check; zipTerrForException,Error log event)
* 07/29/2024				  Balaji N 				 logic for HRP-13174(Method:accTeamDateSyncOnAccPortUpdates, Skip DML for account team with End dates in past)
* 08/12/2024				  Balaji N				 logic for HRP-12485(Method:handleTerritoryPortfolioInsert,logic for adding territory portfolio)
* 03/06/2025                  Krapy Tuli             logic for HRP-14322 to handle ATM bsf portfolio change if the same user present in future as well as past BSF portfolio
* *
*************************************************************************************************************************************************
*/
public with sharing class AccountPortfolioAssignmentService {
    public static Boolean isExecuted = false;
    Static boolean isMethodExecuted = false;
    Public static void  UpdateAccPortfolioAndAccTeamDates(List<Account_Portfolio_Assignment__c> newAccountPortfolioList, Map<Id, Account_Portfolio_Assignment__c> newAccountPortfoliosMap,Map<Id, Account_Portfolio_Assignment__c> oldAccountPortfoliosMap)
    {
        system.debug('Entered UpdateAccPortfolioAndAccTeamDates');
        Map<Id,Id> accountAndAccPortfolioIdsMap = new Map<Id,Id>();
        Map<Id,Id> accPortfolioAndAccountIdsMap = new Map<Id,Id>();
        Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioMap = new Map<Id,Account_Portfolio_Assignment__c>();
        Set<Id> finalEligibleAccountsIdSet = new Set<Id>();
        Set<Id> portfolioIdSet = new Set<Id>();
        for(Account_Portfolio_Assignment__c newAccPortfolio:newAccountPortfolioList)
        {
            portfolioIdSet.add(newAccPortfolio.BSF_Portfolio__c);
            accIdAccPortfolioMap.put(newAccPortfolio.Account__c, newAccPortfolio);
        }
        Map<Id,Account_Portfolio_Assignment__c> accIdOldAccPortfolioMap = new Map<Id,Account_Portfolio_Assignment__c>();
        for(Account_Portfolio_Assignment__c oldAccPortfolio:oldAccountPortfoliosMap.values())
        {
            accIdOldAccPortfolioMap.put(oldAccPortfolio.Account__c, oldAccPortfolio);
        }
        Map<Id,BSF_Portfolio__c> portfolioMap = new Map<Id,BSF_Portfolio__c>([SELECT Id,Portfolio_Name__c,Parent_Portfolio__c,Taxonomy_Type__c,Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:portfolioIdSet]);
        for(Account_Portfolio_Assignment__c newAccPortfolio:newAccountPortfolioList){
            if(portfolioMap.get(newAccPortfolio.BSF_Portfolio__c).Portfolio_Type__c.equalsIgnoreCase(BSF_Constants.ACCOUNT_MANAGER)){ ////HRP-10099 removed the "&& portfolioMap.get(newAccPortfolio.BSF_Portfolio__c).Account_Based_Portfolio__c == true" checks whether updated AccPortfolio is of AM Type and Account Based/Non-Geo Portfolio
                //checking whether changes in dates and then if there,proceeding further
                if(oldAccountPortfoliosMap != null && ((newAccountPortfoliosMap.get(newAccPortfolio.id).start_Date__c != oldAccountPortfoliosMap.get(newAccPortfolio.id).start_Date__c) ||
                                                       (newAccountPortfoliosMap.get(newAccPortfolio.id).End_Date__c != oldAccountPortfoliosMap.get(newAccPortfolio.id).End_Date__c)))
                {
                    accountAndAccPortfolioIdsMap.put(newAccPortfolio.Account__c,newAccPortfolio.Id );
                    accPortfolioAndAccountIdsMap.put(newAccPortfolio.Id,newAccPortfolio.Account__c );
                }
            }
        }
        if(accountAndAccPortfolioIdsMap.size()>0){
            //Account Team dates update as per Account based portfolio new date
            //expireAccountTeamByAccountPortfolio(newAccountPortfolioList,accIdAccPortfolioMap,'Called from AccountPortfolioAssignmentService');//HRP-10099 commented
            //Querying all the AM Portfolio of the Account
            List<Account_Portfolio_Assignment__c> accPortfolioList1 = [SELECT Id,Account__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_code__c,BSF_Portfolio__r.Taxonomy_Type__c, Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE Account__c IN:accountAndAccPortfolioIdsMap.keySet() AND BSF_Portfolio__r.Portfolio_Type__c =: BSF_Constants.ACCOUNT_MANAGER order by start_date__c]; //Get all the AM Portfolios of the Accounts
            Map<Id,List<Account_Portfolio_Assignment__c>> accAndaccPortfolioMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
            //map<String,Account_Portfolio_Assignment__c> supervisorUpdateMap = new map<String,Account_Portfolio_Assignment__c>();//HRP-12053
            //map<id,String> AccportIdPortfolioCodeMap = new  map<id,String>();//HRP-12053
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
                //HRP-10099
                //if(accPortfolio.BSF_Portfolio__r.Taxonomy_Type__c == bsf_constants.TAXO_SUPERVISOR_RECORD_TYPE){}
                //supervisorUpdateMap.put(accPortfolio.BSF_Portfolio__r.Portfolio_code__c+'_'+accPortfolio.Account__c+'_'+accPortfolio.Start_Date__c,accPortfolio);//HRP-12053
                //AccportIdPortfolioCodeMap.put(accPortfolio.id,accPortfolio.BSF_Portfolio__r.Portfolio_code__c);//HRP-12053
                //HRP-10099
            }
            List<Account_Portfolio_Assignment__c> accPortUpdateList = new List<Account_Portfolio_Assignment__c>();
            if(accAndaccPortfolioMap.size()>0){
                Boolean isAccBasedPortfolio = false;
                for(Id accId:accAndaccPortfolioMap.keySet())
                {
                    id accPortid = accountAndAccPortfolioIdsMap.get(accId);
                    for(Account_Portfolio_Assignment__c accPort:accAndaccPortfolioMap.get(accId)){
                        if( oldAccountPortfoliosMap != null && (oldAccountPortfoliosMap.get(accountAndAccPortfolioIdsMap.get(accId)).Portfolio_type__c==Bsf_constants.ACCOUNT_BASED ))
                        {
                            isAccBasedPortfolio = True;//HRP-10099
                        }
                        if(oldAccountPortfoliosMap != null)
                        {
                            //Start date update
                            if((oldAccountPortfoliosMap.get(accPortid).Start_Date__c != newAccountPortfoliosMap.get(accPortid).Start_Date__c) &&
                               (accPort.End_Date__c == oldAccountPortfoliosMap.get(accPortid).Start_Date__c-1)){
                                   accPort.End_date__c = newAccountPortfoliosMap.get(accPortid).Start_Date__c.addDays(-1);
                                   accPortUpdateList.add(accPort);
                               }
                            //End date update
                            if((oldAccountPortfoliosMap.get(accPortid).End_Date__c != newAccountPortfoliosMap.get(accPortid).End_Date__c) &&
                               (accPort.Start_Date__c == oldAccountPortfoliosMap.get(accPortid).End_Date__c+1)){
                                   accPort.Start_date__c = newAccountPortfoliosMap.get(accPortid).End_Date__c.addDays(+1);
                                   accPortUpdateList.add(accPort);
                               }
                        }
                    }
                    /*commented part of HRP-12053
//HRP-10099
if(supervisorUpdateMap !=null)//HRP-11290 removed isAccBasedPortfolio check
{
Account_Portfolio_Assignment__c supervisorAccPort =new  Account_Portfolio_Assignment__c();
supervisorAccPort = supervisorUpdateMap.get(AccportIdPortfolioCodeMap.get(accPortid)+'_'+oldAccountPortfoliosMap.get(accPortid).account__c +'_'+oldAccountPortfoliosMap.get(accPortid).Start_Date__c);
if(supervisorAccPort != null)
{
supervisorAccPort.Start_Date__c = newAccountPortfoliosMap.get(accPortid).Start_Date__c;
supervisorAccPort.End_Date__c	= newAccountPortfoliosMap.get(accPortid).End_Date__c;
accPortUpdateList.add(supervisorAccPort);
}
}
//HRP-10099
commented part of HRP-12053*/
                    if(!accPortUpdateList.isEmpty())
                    {
                        try
                        {
                            triggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');//HRP-6028
                            update accPortUpdateList;
                            triggerHandler.clearbyPass('AccountPortfolioAssignmentTriggerHandler');//HRP-6028
                        }
                        catch(exception e)
                        {System.debug('The exception when updating  account Portofolio is : '+e);}
                    }
                }
                HandleAccountSpecialist(accIdOldAccPortfolioMap.keyset());//HRP-6028
                bsf_constants.skipAccountPortfolioAssignmentUpdateTrigger=true;
                accTeamDateSyncOnAccPortUpdates(new list<id>(accIdOldAccPortfolioMap.keyset()),null,new Set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ());//HRP-10099
                //HRP-10569 new parameters
            }
        }
    }
    /*
* HRP-10099 changes starts here
* @Description: with account Id this method syncs dates in account team based on dates across Account portfolio assignments and Portfolio assignments
* @Date: 06/14/2023
*/
    public static map<string,AccountTeamMember> accTeamDateSyncOnAccPortUpdates (List<id> accountIdList,String calledFromBatch,Set<id> oppSet,map<id,list<accountTeamMember>> accIdFutureAccTeamMap,map <id,list<AccountTeamMember>> accIdAccTeamListMap)
    {
        set<string> focusedPortFolioTypeSet = new set<string>{BSF_Constants.ACCOUNT_MANAGER,bsf_constants.SICKLE_CELL_ACCOUNT_MANAGER,Bsf_constants.NATIONAL_ACCOUNT_MANAGER,bsf_constants.Booking_Support,bsf_constants.ACCOUNT_SPECIALIST};//HRP-11290
        list <Account_Portfolio_assignment__c> accportfolioAssignOfAccList = new list<Account_Portfolio_assignment__c>();//HRP-11290 added BSF_Portfolio__r.Portfolio_type__c in:focusedPortFolioTypeSet
        list<AccountTeamMember> overAllteamMembersList = new list<AccountTeamMember>();
        List <AccountTeamMember> atmToDeleteList = new List <AccountTeamMember>();
        List <AccountTeamMember> teamMemberListToInsert = new List <AccountTeamMember>();
        List <BSF_Error_Log__c> errorLogInsertList = new List <BSF_Error_Log__c>();
        set<id> bsfIdsSet=new set<id>();
        list<account> acclist = [select id,(Select id,Start_date__c,End_Date__c,Account__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_code__c,BSF_Portfolio__r.Parent_Portfolio__c,
                                            BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Taxonomy_Type__c,BSF_Portfolio__r.portfolio_type__c from
                                            AccountPortfolioAssignments__r where Account__c IN:accountIdList and BSF_Portfolio__r.Portfolio_type__c in:focusedPortFolioTypeSet order
                                            by Account__c, start_Date__c),(SELECT Id,BSF_Portfolio__c,UserId,TeamMemberRole,AccountId,Start_Date__c,End_Date__c,BSF_Portfolio__r.Taxonomy_Type__c,user.name,is_covering_recruiter__c FROM AccountTeamMembers WHERE AccountId IN:accountIdList order by accountid) from account where id in:accountIdList];
        for(account acc:acclist)
        {
            if(acc.AccountPortfolioAssignments__r !=null)
                accportfolioAssignOfAccList.addAll(acc.AccountPortfolioAssignments__r);
            if(acc.AccountTeamMembers!=null)
                overAllteamMembersList.addAll(acc.AccountTeamMembers);
        }
        for(Account_Portfolio_assignment__c ap:accportfolioAssignOfAccList)
        {
            bsfIdsSet.add(ap.BSF_Portfolio__c);
            if(ap.BSF_Portfolio__r.portfolio_type__c==BSF_Constants.ACCOUNT_MANAGER)//11290 check for AM node
            {
                bsfIdsSet.add(ap.BSF_Portfolio__r.Parent_Portfolio__c);
                bsfIdsSet.add(ap.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c);
            }
        }
        list <Account_Portfolio_assignment__c> accPortUpdateList = new list <Account_Portfolio_assignment__c>();
        map <string,AccountTeamMember> accTeamMap = new map <string,AccountTeamMember>();
        map <string,AccountTeamMember> covAccTeamMap = new map <string,AccountTeamMember>();//HRP-10569
        set<id> delAccIdset = new set<id>();
        for(AccountTeamMember teamMember:overAllteamMembersList)
        {
            if(!accIdAccTeamListMap.containsKey(teamMember.accountId))
                accIdAccTeamListMap.put(teamMember.accountId,new list<accountTeamMember>());
            accIdAccTeamListMap.get(teamMember.accountId).add(teamMember);
            if(!teamMember.is_covering_recruiter__c)
                accTeamMap.put(teamMember.accountId+'_'+teamMember.userId,teamMember);
            if(teamMember.is_covering_recruiter__c && teamMember.end_date__c >=system.today())//HRP-10569
                covAccTeamMap.put(teamMember.accountId+'_'+teamMember.userId,teamMember);//HRP-10569
        }
        List<Portfolio_Assignment__c> portfolioAssignList = [Select id,Start_date__c,End_Date__c,BSF_Portfolio__c,Assignment_Type__c,bsf_portfolio__r.Taxonomy_type__c,User__r.Name from Portfolio_Assignment__C where BSF_Portfolio__c IN:bsfIdsSet order by start_Date__c,BSF_Portfolio__c,user__c];
        map<string,accountTeamMember> accIdUserDate = new map<string,accountTeamMember>();//HRP-8897 map value changed from list of dates to AccountTeamMember
        map <string,Portfolio_Assignment__c> portfolioUserMap = new map <string,Portfolio_Assignment__c>();
        for(Account_Portfolio_Assignment__c apa : accportfolioAssignOfAccList)
        {
            for(Portfolio_Assignment__c pa:portfolioAssignList)
            {
                Date startDate;
                Date endDate;
                if(((pa.bsf_portfolio__c == apa.bsf_portfolio__c && focusedPortFolioTypeSet.contains(pa.Assignment_Type__c)&& pa.bsf_portfolio__r.Taxonomy_type__c!='Bio Recruitment Supervisor') || //HRP-11290 check focusedPortFolioTypeSet,Bio Recruitment Supervisor
                    (pa.bsf_portfolio__c == apa.bsf_portfolio__r.Parent_Portfolio__c && (pa.assignment_Type__c ==BSF_Constants.AREA_BOOKING_MANAGER || pa.Assignment_Type__c==BSF_Constants.DISTRICT_MANAGER || pa.Assignment_Type__c==BSF_Constants.SUPERVISOR))||
                    (pa.bsf_portfolio__c == apa.bsf_portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c && pa.Assignment_Type__c==BSF_Constants.DISTRICT_MANAGER && pa.bsf_portfolio__r.Taxonomy_type__c!='Bio Recruitment Supervisor')) &&
                   (pa.bsf_portfolio__r.Taxonomy_type__c == apa.bsf_portfolio__r.Taxonomy_type__c))
                {
                    accountTeamMember atm;
                    if((pa.Start_Date__c <= apa.Start_Date__c && pa.End_Date__c >= apa.Start_Date__c)|| (pa.Start_Date__c <= apa.End_Date__c && pa.End_Date__c >= apa.End_Date__c) ||
                       (apa.Start_Date__c <= pa.Start_Date__c && apa.End_Date__c >= pa.Start_Date__c)|| (apa.Start_Date__c <= pa.End_Date__c && apa.End_Date__c >= pa.End_Date__c))//HRP-11290
                    {
                        startDate = apa.Start_Date__c>= pa.Start_Date__c?apa.Start_Date__c:pa.Start_Date__c;
                        endDate = apa.End_Date__c<= pa.End_Date__c?apa.End_Date__c:pa.End_Date__c;
                        string key =apa.account__c+'_'+pa.user__c;
                        if(accIdUserDate.keyset().contains(key))
                        {
                            atm=accIdUserDate.get(key);
                            if(startDate <= atm.End_Date__c+1 && atm.TeamMemberRole == pa.Assignment_Type__c)
                            {
                                atm.End_Date__c = endDate;
                            }
                            else if(atm.End_Date__c<system.today() || (atm.End_Date__c>system.today() && startDate<atm.Start_Date__c && endDate<atm.Start_Date__c && endDate >system.today()))
                            {
                                atm.start_date__c = startDate;
                                atm.End_Date__c = endDate;
                                atm.TeamMemberRole = pa.Assignment_Type__c;
                                atm.BSF_Portfolio__c=pa.BSF_Portfolio__c;//HRP-14322
                            }
                            //HRP-10569 start
                            //The Acc Team inside this else if are future teams coming part of portfolio assignment
                            else if(atm.End_Date__c>=system.today() &&
                                    (startDate >atm.End_Date__c ||
                                     (((pa.Assignment_Type__c==bsf_constants.ACCOUNT_MANAGER && atm.TeamMemberRole==bsf_constants.SUPERVISOR) || (pa.Assignment_Type__c==bsf_constants.SUPERVISOR && atm.TeamMemberRole==bsf_constants.ACCOUNT_MANAGER)) && atm.TeamMemberRole != pa.Assignment_Type__c &&
                                      (!((startDate<atm.Start_Date__c && endDate<atm.Start_Date__c) ||(startDate>atm.End_Date__c && endDate>atm.End_Date__c)))))) //&& startDate>=atm.Start_Date__c && startDate <atm.End_Date__c)))
                            {
                                //HRP-12122 Start
                                accountTeamMember atmFuture;
                                AccountTeamMember atmFuture2;
                                if(startDate >atm.End_Date__c)
                                {
                                    atmFuture= new accountTeamMember(userid=pa.user__c,accountId=apa.account__c,Start_Date__c=startDate,end_date__c=endDate,TeamMemberRole=pa.Assignment_Type__c);
                                }
                                else
                                {
                                    AccountTeamMember am= new AccountTeamMember();
                                    AccountTeamMember superVisor= new AccountTeamMember();
                                    if(atm.TeamMemberRole==bsf_constants.SUPERVISOR)
                                    {
                                        superVisor = atm;
                                        am=new accountTeamMember(userid=pa.user__c,accountId=apa.account__c,TeamMemberRole=pa.Assignment_Type__c,start_date__c=StartDate,End_date__c=endDate,BSF_Portfolio__c=pa.BSF_Portfolio__c);
                                    }
                                    else if(atm.TeamMemberRole==bsf_constants.ACCOUNT_MANAGER)
                                    {
                                        am=atm;
                                        superVisor=new accountTeamMember(userid=pa.user__c,accountId=apa.account__c,TeamMemberRole=pa.Assignment_Type__c,start_date__c=StartDate,End_date__c=endDate,BSF_Portfolio__c=pa.BSF_Portfolio__c);
                                    }
                                    if(am.Start_Date__c<=superVisor.start_date__c)
                                    {
                                        atm = am;
                                        if(am.End_Date__c<superVisor.End_Date__c)
                                        {
                                            superVisor.start_date__c = am.End_Date__c+1;
                                            atmFuture= superVisor;
                                        }
                                    }
                                    else if(superVisor.Start_Date__c<=am.start_date__c)
                                    {
                                        atm = am;
                                        if(superVisor.End_Date__c>am.End_Date__c)
                                        {
                                            atmFuture2 = new accountTeamMember(userid=superVisor.userId,accountId=superVisor.accountId,TeamMemberRole=superVisor.TeamMemberRole,start_date__c=superVisor.Start_Date__c,End_date__c=superVisor.End_Date__c,BSF_Portfolio__c=superVisor.BSF_Portfolio__c);
                                            superVisor.End_Date__c=am.Start_Date__c-1;
                                            atmFuture= superVisor;
                                            atmFuture2.Start_Date__c=am.End_Date__c+1;
                                        }
                                    }
                                    //HRP-12122 End
                                }
                                /*if(startDate <= atm.End_Date__c && endDate>=atm.End_Date__c+1)
atmFuture.Start_Date__c= atm.End_Date__c+1;
atmFuture.End_Date__c=endDate;
atmFuture.BSF_Portfolio__c=pa.BSF_Portfolio__c;
}
else
{
atmFuture= new accountTeamMember(userid=atm.userId,accountId=atm.accountId,TeamMemberRole=atm.TeamMemberRole);
if(atm.Start_Date__c <= endDate && atm.End_Date__c>=endDate+1)
atmFuture.Start_Date__c= endDate+1;
atmFuture.End_Date__c=atm.End_Date__c;
atmFuture.BSF_Portfolio__c=atm.BSF_Portfolio__c;
atm = new accountTeamMember(userid=pa.user__c,accountId=apa.account__c,Start_Date__c=startDate,end_date__c=endDate,TeamMemberRole=pa.Assignment_Type__c);
}*/
                                if(!accIdFutureAccTeamMap.containsKey(apa.account__c))
                                    accIdFutureAccTeamMap.put(apa.account__c,new list<accountTeamMember>());
                                if(atmFuture!=null)
                                    accIdFutureAccTeamMap.get(apa.account__c).add(atmFuture);
                                if(atmFuture2!=null)
                                    accIdFutureAccTeamMap.get(apa.account__c).add(atmFuture2);
                            }
                            //HRP-10569 end
                            //HRP-8897
                            if(apa.Start_Date__c<=system.today() && apa.End_Date__c>=system.today())
                            {
                                atm.BSF_Portfolio__c=pa.BSF_Portfolio__c;
                            }
                            //HRP-8897
                            accIdUserDate.put(key,atm);
                        }
                        else
                        {
                            //HRP-8897
                            atm= new accountTeamMember(userid=pa.user__c,accountId=apa.account__c,Start_Date__c=startDate,end_date__c=endDate,TeamMemberRole=pa.Assignment_Type__c);
                            atm.BSF_Portfolio__c=pa.BSF_Portfolio__c;
                            accIdUserDate.put(key,atm);
                            //HRP-8897
                        }
                        portfolioUserMap.put(key,pa);
                    }
                }
            }
        }
        map<id,list <AccountTeamMember>> accIdAccTeamUpdateMap = new map<id,list <AccountTeamMember>>();
        for(String accUserKey:accIdUserDate.keyset())
        {
            string Key = accUserKey;
            AccountTeamMember existAcctm = new accountTeamMember();
            AccountTeamMember correctAcctm = new accountTeamMember();//HRP-8897
            correctAcctm = accIdUserDate.get(key);
            boolean Updated = false;
            //TEAM ALREADY THERE CHECKING FOR CORRECT DATES AND UPDATING
            if(accTeamMap.containskey(Key) && (!covAccTeamMap.containsKey(key) ||
                                               (covAccTeamMap.containsKey(key) && correctAcctm.Start_Date__c<= covAccTeamMap.get(key).start_date__c && correctAcctm.end_date__c>= covAccTeamMap.get(key).end_date__c)))//HRP-10569 checks with covAccTeamMap
            {
                //HRP-8897
                existAcctm=accTeamMap.get(accUserKey);
                if((existAcctm.Start_Date__c != correctAcctm.Start_Date__c) ||
                   (existAcctm.End_Date__c != correctAcctm.End_Date__c )	||
                   (existAcctm.BSF_Portfolio__c != correctAcctm.BSF_Portfolio__c ) ||
                   (existAcctm.TeamMemberRole != correctAcctm.TeamMemberRole ))
                {
                    Updated = true;
                }
                if(Updated && correctAcctm.end_date__c>=System.Today())//HRP-13174
                {
                    if(!accIdAccTeamUpdateMap.containsKey(correctAcctm.AccountId))
                        accIdAccTeamUpdateMap.put(correctAcctm.AccountId,new list<AccountTeamMember>());
                    accIdAccTeamUpdateMap.get(correctAcctm.AccountId).add(correctAcctm);
                }
                //HRP-8897
            }
            //HRP-10569 start
            //if the user is a active covering recruiter and coming in portfolio as well, then portfolio dates are added as future team in accIdFutureAccTeamMap
            ////CR having overlapping dates with portfolio dates are synced
            else if(covAccTeamMap.containsKey(key) && !(correctAcctm.Start_Date__c<= covAccTeamMap.get(key).start_date__c && correctAcctm.end_date__c>= covAccTeamMap.get(key).end_date__c))
            {
                accountTeamMember coverAtm = new accountTeamMember();
                accountTeamMember atmTotake = new accountTeamMember();
                coverAtm =covAccTeamMap.get(key);
                boolean delCR = false;
                //HRP-11424 start
                //end date overlap end date becomes portfolio start date -1
                if((correctAcctm.Start_Date__c <= coverAtm.end_Date__c && coverAtm.end_Date__c <= correctAcctm.End_Date__c ) || (coverAtm.Start_Date__c<=correctAcctm.Start_Date__c && correctAcctm.End_Date__c <=coverAtm.end_Date__c))
                {
                    if(correctAcctm.Start_Date__c-1>=System.today())
                    {
                        coverAtm.end_Date__c = correctAcctm.Start_Date__c-1;
                        atmTotake=coverAtm;
                    }
                    else if(correctAcctm.end_Date__c+1<=coverAtm.end_Date__c)
                    {
                        coverAtm.Start_Date__c = correctAcctm.end_Date__c+1;
                        atmTotake=coverAtm;
                    }
                    else
                    {
                        delCR=true;
                        atmTotake=correctAcctm;
                    }
                }
                //start dateoverlap same becomes  portfolio end date +1
                else if(correctAcctm.Start_Date__c <= coverAtm.Start_Date__c && coverAtm.Start_Date__c <= correctAcctm.End_Date__c)
                {
                    coverAtm.Start_Date__c = correctAcctm.end_Date__c+1;
                    atmTotake=coverAtm;
                }
                //HRP-11424 end
                if(!accIdAccTeamUpdateMap.containsKey(atmTotake.AccountId))
                    accIdAccTeamUpdateMap.put(atmTotake.AccountId,new list<AccountTeamMember>());
                //HRP-11424 start
                if(!delCR)
                {
                    if(atmTotake!=null)
                        accIdAccTeamUpdateMap.get(atmTotake.AccountId).add(atmTotake);
                    if(!accIdFutureAccTeamMap.containsKey(correctAcctm.accountId))
                        accIdFutureAccTeamMap.put(correctAcctm.accountId,new list<accountTeamMember>());
                    accIdFutureAccTeamMap.get(correctAcctm.accountId).add(correctAcctm);
                }
                else
                {
                    if(atmTotake.End_Date__c >= system.today())//HRP-13174
                        accIdAccTeamUpdateMap.get(atmTotake.AccountId).add(atmTotake);
                    atmToDeleteList.add(coverAtm);
                }
                //HRP-11424 end
            }
            //HRP-10569 End
            // TEAM DOESN'T EXISTS CREATING NEW
            else
            {
                AccountTeamMember atm = new accountTeamMember();
                atm=accIdUserDate.get(key);
                if(!accIdAccTeamUpdateMap.containsKey(correctAcctm.AccountId))
                    accIdAccTeamUpdateMap.put(correctAcctm.AccountId,new list<AccountTeamMember>());
                if(correctAcctm.End_Date__c >= system.today())//HRP-13174
                    accIdAccTeamUpdateMap.get(correctAcctm.AccountId).add(correctAcctm);
            }
        }
        if(calledFromBatch == null)//HRP-10569 prev this was only for Insert found below; now encloses delete as well
        {
            list<string> accTeamRoleList = new list<string>{BSF_constants.ACCOUNT_MANAGER,BSF_constants.AREA_BOOKING_MANAGER,BSF_constants.DISTRICT_MANAGER,BSF_constants.SUPERVISOR};
                for(String atmKey:accTeamMap.keyset())
            {
                AccountTeamMember atm = new accountTeamMember();
                atm=accTeamMap.get(atmKey);
                if(!accIdUserDate.containskey(atmKey) || (accIdUserDate.containskey(atmKey) && accIdUserDate.get(atmKey).end_Date__c<System.today()))//HRP-11290 removed role check from accTeamRoleList
                {
                    delAccIdset.add(accTeamMap.get(atmKey).accountId);
                    atmToDeleteList.add(accTeamMap.get(atmKey));
                }
            }
            if(!atmToDeleteList.isEmpty())
            {
                BSF_Constants.isTeamMemberCreatedFromBackend = true;
                Database.DeleteResult [] deleteResult = Database.delete(atmToDeleteList,false);
                errorLogInsertList.addAll(
                    BSF_Utilities.createErrorLog(deleteResult,'Acc Team Delete', 'AccountPortfolioAssignmentService', 'accTeamDateSyncOnAccPortUpdates', 'Error', 'sync accteam dates')
                );
                BSF_Constants.isTeamMemberCreatedFromBackend = false;
            }
            if(accIdAccTeamUpdateMap.values().size()>0)
            {
                for(id i: accIdAccTeamUpdateMap.keyset())
                {
                    teamMemberListToInsert.addAll(accIdAccTeamUpdateMap.get(i));
                }
                //HRP-8897
                for(AccountTeamMember team:teamMemberListToInsert)
                {
                    team.AccountAccessLevel= 'Edit';
                    team.CaseAccessLevel = 'Edit';
                    team.OpportunityAccessLevel = 'Edit';
                }
                //HRP-8897
                BSF_Constants.isTeamMemberCreatedFromBackend = true;
                bsf_constants.isdateCheckbeforeInsertUpdate = false;
                database.SaveResult [] srlist = Database.Insert(teamMemberListToInsert,false);
                bsf_constants.isdateCheckbeforeInsertUpdate = true;//HRP-8897 bypasses date validation from AccountTeamTriggerHandler method call dateCheckbeforeInsertUpdate
                errorLogInsertList.addAll(
                    BSF_Utilities.createErrorLog(srlist,'Acc Team Insert','AccountPortfolioAssignmentService','accTeamDateSyncOnAccPortUpdates','Error','sync accteam dates')
                );
            }
            InsertBsfErrorLog.insertBsfErrors(errorLogInsertList);
            
            //HRP-15205 -> In case of Acc Team Member Trigger doesn't get triggered due to failures
            List<Portfolio_Accounts_Processing__c> portfolioAccProcessingRecord = [SELECT Id, Portfolio_progress_for_Accounts__c, 
                                                                                   Records_Processed__c, Portfolio_Assignment_Updated__c 
                                                                                   FROM Portfolio_Accounts_Processing__c];
            if (portfolioAccProcessingRecord != NULL && !portfolioAccProcessingRecord.isEmpty() && portfolioAccProcessingRecord[0].Portfolio_Assignment_Updated__c) {
                update new Portfolio_Accounts_Processing__c(
                    Id = portfolioAccProcessingRecord[0].Id,
                    Portfolio_progress_for_Accounts__c = 0,
                    Records_Processed__c = 0,
                    Portfolio_Assignment_Updated__c = false
                );
            }
        }
        //HRP-10569 start
        if((accIdFutureAccTeamMap!= null || delAccIdset!= null) && calledFromBatch==null)
        {
            for(id i : accIdFutureAccTeamMap.keySet())
            {
                if(accIdAccTeamUpdateMap.containsKey(i) || delAccIdset.contains(i))
                {
                    accIdFutureAccTeamMap.remove(i);
                }
            }
        }
        list<opportunity> opptyList = new list<opportunity>();
        map<Id,Id> oppWithOwnerIdMap = new map<Id,Id>();
        map<Id,Id> oppWithAccMangrIdMap = new map<Id,Id>();
        opptyList = [select id, drive_date__c,Account_Manager__c,District_Manager_Portfolio__c,Account_Manager_Portfolio__c, OwnerId,accountId,District_Manager__c from opportunity where id in:oppSet];//HRP-12390 District_Manager__c
        boolean isnotOpptyService =false;//flag set to true if opportunityService
        if(oppSet.isEmpty())
        {
            isnotOpptyService= true;
            opptyList = [select id, drive_date__c,Account_Manager__c,OwnerId,accountId,District_Manager__c,District_Manager_Portfolio__c,Account_Manager_Portfolio__c from opportunity where AccountId in :accIdFutureAccTeamMap.keySet() and is_template__c=false and Drive_Date__c>=Today];
        }
        //this logic takes care future team only on portfolio/accountportfolio changes; not required for changes from opportunity
        if((isnotOpptyService && calledFromBatch==null) || calledFromBatch==bsf_constants.ONE_TIME_BATCH)//HRP-12390
        {
            Map<id,opportunity> oppToUpdate = new Map<id,opportunity>();
            Map<id,Set<string>> oppIdRoleSetMap = new Map<id,Set<string>>();
            Set<id> oppCovAmSet = new Set<id>();
            Map<id,list<String>> oppIdLookupPopulatedListMap = new Map<id,list<String>>();//HRP-11234
            Map<Id,Id> oppWithOldOwnerIdMap = new Map<Id,Id>();
            //iteration over existing account team on all opportunities; no updates, identify covering recruiter cover opportunities
            for(Opportunity opp: opptyList)
            {
                oppWithOldOwnerIdMap.put(opp.id,opp.OwnerId);
                if(accIdAccTeamListMap.containskey(opp.accountId) && accIdAccTeamListMap.get(opp.accountId) != NULL)
                {
                    for(AccountTeamMember atm : accIdAccTeamListMap.get(opp.accountId))
                    {
                        if(atm.start_date__c <= opp.Drive_date__c && atm.End_date__c>=opp.Drive_date__c)
                        {
                            if(!oppIdRoleSetMap.containsKey(opp.id))
                                oppIdRoleSetMap.put(opp.id,new set<string>());
                            oppIdRoleSetMap.get(opp.id).add(atm.userId+''+atm.TeamMemberRole+''+opp.Id);
                            if(atm.TeamMemberRole==BSf_constants.ACCOUNT_MANAGER)
                            {
                                if(!oppIdLookupPopulatedListMap.containsKey(opp.id))//HRP-11234
                                    oppIdLookupPopulatedListMap.put(opp.id,new list<string>());//HRP-11234
                                if(!atm.Is_Covering_Recruiter__c)
                                {
                                    oppIdLookupPopulatedListMap.get(opp.id).add('AM');//HRP-11234
                                    oppWithOwnerIdMap.put(opp.id,opp.OwnerId);
                                    if(!oppCovAmSet.contains(opp.id))
                                        oppWithAccMangrIdMap.put(opp.id,opp.Account_Manager__c);
                                }
                                else if(atm.Is_Covering_Recruiter__c)
                                {
                                    oppIdLookupPopulatedListMap.get(opp.id).add('CovAM');//HRP-11234
                                    if(opp.Account_Manager__c!=atm.UserId)
                                    {
                                        opp.Account_Manager__c=atm.UserId;
                                    }//HRP-12390
                                    oppToUpdate.put(opp.id,Opp);
                                    oppCovAmSet.add(opp.Id);
                                    oppWithAccMangrIdMap.put(opp.id,opp.Account_Manager__c);
                                }
                            }
                            else if(atm.TeamMemberRole==BSf_constants.DISTRICT_MANAGER)
                            {
                                //HRP-11234
                                if(!oppIdLookupPopulatedListMap.containsKey(opp.id))
                                    oppIdLookupPopulatedListMap.put(opp.id,new list<string>());
                                oppIdLookupPopulatedListMap.get(opp.id).add('DM');
                                //HRP-11234
                            }
                        }
                    }
                }
            }
            map<string,opportunityTeamMember> oppIdOppTeamMap = new map<string,opportunityTeamMember>();
            map<id,Opportunity> oppIdOppMap= new map<id,Opportunity>();
            map<string,OpportunityTeamMember> oppTeamToAdd = new map<string,OpportunityTeamMember>();
            map<Id,Opportunity> oppIdVsAMDMPortfoliodMap = new map<Id,Opportunity>();
            set<id> focusOppIdSet = new set<id>();
            //iteration on future team and opportunity team creation and AM,DM,Owner Lookup population
            for(Opportunity opp: opptyList)
            {
                focusOppIdSet.add(opp.id);
                boolean updated = false;
                integer i = 0;
                if(accIdFutureAccTeamMap!=null && accIdFutureAccTeamMap.containsKey(opp.accountId))
                {
                    for(AccountTeamMember atm : accIdFutureAccTeamMap.get(opp.accountId))
                    {
                        /*if(!oppIdRoleSetMap.containsKey(opp.id) || (oppIdRoleSetMap.containsKey(opp.id) && !oppIdRoleSetMap.get(opp.id).contains(atm.userId+''+atm.TeamMemberRole+''+opp.Id)))
{}*/
                        if(atm.start_date__c <= opp.Drive_date__c && atm.End_date__c>=opp.Drive_date__c)
                        {
                            OpportunityTeamMember otm = new OpportunityTeamMember();
                            otm.userId=atm.UserId;
                            otm.OpportunityId=opp.id;
                            otm.TeamMemberRole=atm.TeamMemberRole;
                            otm.is_AccountTeammember__c =true;
                            if(otm.TeamMemberRole==BSf_constants.DISTRICT_MANAGER)
                            {
                                if(!oppIdLookupPopulatedListMap.containsKey(opp.id))//HRP-11234
                                    oppIdLookupPopulatedListMap.put(opp.id,new list<string>());//HRP-11234
                                oppIdLookupPopulatedListMap.get(opp.id).add('DM');//HRP-11234
                                if(opp.District_Manager__c != atm.UserId )
                                {
                                    opp.District_Manager__c=atm.UserId;
                                    opp.District_Manager_Portfolio__c=atm.BSF_Portfolio__c;
                                    updated=true;
                                }
                                oppIdVsAMDMPortfoliodMap.put(opp.id,opp);
                            }
                            if(otm.TeamMemberRole==BSf_constants.ACCOUNT_MANAGER)
                            {
                                if(!oppIdLookupPopulatedListMap.containsKey(opp.id))//HRP-11234
                                    oppIdLookupPopulatedListMap.put(opp.id,new list<string>());//HRP-11234
                                if(!oppCovAmSet.contains(opp.id))
                                    oppIdLookupPopulatedListMap.get(opp.id).add('CovAM');//HRP-11234
                                oppIdLookupPopulatedListMap.get(opp.id).add('AM');//HRP-11234
                                if(opp.Account_Manager__c != atm.UserId || opp.OwnerId != atm.UserId)
                                {
                                    if(!oppCovAmSet.contains(opp.id))
                                    {
                                        opp.Account_Manager__c=atm.UserId;
                                        oppWithAccMangrIdMap.put(opp.id,opp.Account_Manager__c);
                                    }
                                    opp.OwnerId = atm.UserId;
                                    opp.Account_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                                    updated=true;
                                    oppWithOwnerIdMap.put(opp.id,opp.OwnerId);
                                }
                                otm.TeamMemberRole='Opportunity Owner';
                                oppIdVsAMDMPortfoliodMap.put(opp.id,opp);
                            }
                            oppTeamToAdd.put(otm.userId+''+otm.TeamMemberRole+''+otm.OpportunityId,otm);
                        }
                        //if(i==accIdFutureAccTeamMap.get(opp.accountId).size()-1 && updated)
                        //oppToUpdate.add(opp);
                        i++;
                    }
                }
            }
            list<opportunityTeamMember> optyTeamToDelList = new list<opportunityTeamMember>();
            for(opportunityTeamMember otm : [select id,userId,TeamMemberRole,opportunityId from opportunityTeamMember where opportunityId in:focusOppIdSet and is_AccountTeammember__c =true])
            {
                String key = otm.userId+''+otm.TeamMemberRole+''+otm.OpportunityId;
                if(!(oppTeamToAdd.containsKey(key) || (oppIdRoleSetMap.containsKey(otm.OpportunityId) && oppIdRoleSetMap.get(otm.OpportunityId).contains(key)) || oppIdRoleSetMap==null))
                {
                    optyTeamToDelList.add(otm);
                }
                else if(oppTeamToAdd.containsKey(key))
                {
                    oppTeamToAdd.remove(key);
                }
            }
            TriggerHandler.Bypass('OpportunityTriggerHandler');
            skedHubBase.BypassInsertTriggers = true;
            skedHubBase.BypassUpdateTriggers = true;
            //HRP-11234
            if(oppIdLookupPopulatedListMap!= null)
            {
                oppToUpdate.putAll(systemUserAsOwner(opptyList,oppIdLookupPopulatedListMap,oppTeamToAdd,false,oppWithOwnerIdMap,oppIdVsAMDMPortfoliodMap));
            }
            //HRP-11234
            //OpportunityService.UpdateDriveOwnerOnOppOwnerUpdate(oppWithOwnerIdMap,oppWithAccMangrIdMap,new Map<Id,Opportunity> ());
            if(!oppToUpdate.values().isEmpty())
            {
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.update(oppToUpdate.values(),false),'Create Portfolio','AccountPortfolioAssignmentService','accTeamDateSyncOnAccPortUpdates','Error','sync Future AccTeam opportunity AM');
                InsertBsfErrorLog.insertBsfErrors(logList);
                AccountTeamMemberService.oppLookupUpdates(oppWithOwnerIdMap,oppWithAccMangrIdMap,oppIdVsAMDMPortfoliodMap,oppToUpdate.values(),oppWithOldOwnerIdMap);//HRP-11234
            }
            if(!oppTeamToAdd.values().isEmpty())
            {
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.Insert(oppTeamToAdd.values(),false),'Create Portfolio','AccountPortfolioAssignmentService','accTeamDateSyncOnAccPortUpdates','Error','sync Future AccTeam opportunity Team creation');
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
            if(!optyTeamToDelList.isEmpty())
            {
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.delete(optyTeamToDelList,false),'Create Portfolio','AccountPortfolioAssignmentService','accTeamDateSyncOnAccPortUpdates','Error','sync Future AccTeam opportunity Team Delete');
                InsertBsfErrorLog.insertBsfErrors(logList);
            }
            TriggerHandler.ClearBypass('OpportunityTriggerHandler');
            skedHubBase.BypassInsertTriggers = false;
            skedHubBase.BypassUpdateTriggers = false;
        }
        //HRP-10569 End
        return accIdUserDate;
    }
    /*
* HRP-10099 changes Ends
*/
    /*
* HRP-11234 changes starts here
* @Description: populates Opportunity owner as "system User" and AM and DM lookups blank when no accTeam covers the drive date
returns opportunity with the updates on lookups
* @Date: 01/18/2024
*/
    public static list<opportunity> systemUserAsOwner(list<opportunity> opptyList,map<id,list<String>> oppIdLookupPopulatedListMap,map<string,OpportunityTeamMember> oppTeamToAdd,boolean oppService,Map<Id,Id> oppWithOwnerIdMap,map<Id,Opportunity> oppIdVsAMDMPortfoliodMap)
    {
        list<opportunity> oppList = new list<opportunity>();
        user u = [select id from user where name='DRD System User'];
        for(opportunity opp : opptyList)
        {
            opportunityTeamMember ownerTeam = new opportunityTeamMember();
            ownerTeam.opportunityId = opp.id;
            ownerTeam.is_AccountTeammember__c=true;
            boolean updated = false;
            if(!oppIdLookupPopulatedListMap.containsKey(opp.id))
            {
                if(!oppService)//excludes field update when context is opportunity afterupdate
                {
                    OpportunitySplitRecursive.isOppotysplitBackEndUpdated = true;
                    opp.OwnerId=u.id;
                    opp.Account_Manager__c=null;
                    opp.District_Manager__c=null;
                    oppWithOwnerIdMap.put(opp.id,opp.OwnerId);
                }
                updated=true;
                ownerTeam.UserId =u.id;
                ownerTeam.TeamMemberRole='Opportunity Owner';
            }
            else
            {
                if(!oppIdLookupPopulatedListMap.get(opp.id).contains('AM') )
                {
                    if(!oppService && opp.OwnerId!=u.id)
                    {
                        opp.OwnerId=u.id;
                        oppWithOwnerIdMap.put(opp.id,opp.OwnerId);
                    }
                    updated=true;
                    ownerTeam.UserId=u.id;
                    ownerTeam.TeamMemberRole='Opportunity Owner';
                }
                if(!oppIdLookupPopulatedListMap.get(opp.id).contains('CovAM') && !oppIdLookupPopulatedListMap.get(opp.id).contains('AM') && opp.Account_Manager__c!=null)
                {
                    if(!oppService)
                        opp.Account_Manager__c=null;
                    updated=true;
                }
                if(!oppIdLookupPopulatedListMap.get(opp.id).contains('DM') && opp.District_Manager__c!=u.id)
                {
                    if(!oppService)
                        opp.District_Manager__c=null;
                    updated=true;
                }
            }
            oppIdVsAMDMPortfoliodMap.put(opp.id,opp);
            if(!oppService && updated)//HRP-12390
            {
                oppList.add(opp);
            }
            if(ownerTeam.UserId != null && updated)
                oppTeamToAdd.put(ownerTeam.userId+''+ownerTeam.TeamMemberRole+''+ownerTeam.OpportunityId,ownerTeam);
        }
        return oppList;
    }
    //HRP-11234 End
    //HRP-10099 - Logic moved to the Method "accTeamDateSyncOnAccPortUpdates"
    /*public static List<AccountTeamMember> expireAccountTeamByAccountPortfolio(List<Account_Portfolio_Assignment__c> accPortfolioList,Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioIdMap,String calledFromBatch){
System.debug('accIdAccPortfolioIdMap: '+accIdAccPortfolioIdMap);
List<AccountTeamMember> teamMemberListToUpdate = new List<AccountTeamMember>();
Map<Id,Set<Id>> amAndItsHierarchyMap = new Map<Id,Set<Id>>(); //--> [AMId, (ABMId,DMId,DivisionId,RegionId)]
Set<AccountTeamMember> teamMembersSet = new Set<AccountTeamMember>();
Set<Id> portfolioIdSet = new Set<Id>();
Map<Id,Account_Portfolio_Assignment__c> amPortfolioAcctPortfolioMap = new Map<Id,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accPortfolio:accPortfolioList){
portfolioIdSet.add(accPortfolio.BSF_Portfolio__c);
amPortfolioAcctPortfolioMap.put(accPortfolio.BSF_Portfolio__c,accPortfolio);
}
System.debug('portfolioIdSet: '+portfolioIdSet);
List<AccountTeamMember> supervisorTeamMemberListToUpdate = checkAndUpdateSupervisorAMPortfolioEndDate(accPortfolioList,portfolioIdSet,accIdAccPortfolioIdMap,calledFromBatch);
System.debug('portfolioIdSet: '+portfolioIdSet);
List<BSF_Portfolio__c> portfolioList =[
SELECT Id,
Portfolio_Type__c,
Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,
Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c
FROM BSF_Portfolio__c
WHERE Id IN:portfolioIdSet
];
System.debug('portfolioList: '+portfolioList);
system.debug('accPortfolioList: '+accPortfolioList);
for(BSF_Portfolio__c portfolio:portfolioList){
Set<Id> superPortfolioIds = new Set<Id>();
superPortfolioIds.add(portfolio.Parent_Portfolio__c);
superPortfolioIds.add(portfolio.Parent_Portfolio__r.Parent_Portfolio__c);
superPortfolioIds.add(portfolio.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c);
superPortfolioIds.add(portfolio.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c);
superPortfolioIds.remove(null);
amAndItsHierarchyMap.put(portfolio.Id,superPortfolioIds);
}
System.debug('amAndItsHierarchyMap: '+amAndItsHierarchyMap);
List<id> accBsfPortfolio = new List<id>();
accBsfPortfolio.addall(amAndItsHierarchyMap.keyset());
for(Set<Id> ids :amAndItsHierarchyMap.values())
{
accBsfPortfolio.addall(ids);
}
System.debug('portfolioList: '+portfolioList);
List<AccountTeamMember> teamMembersList = [SELECT Id,BSF_Portfolio__c,UserId,TeamMemberRole,AccountId,Start_Date__c,End_Date__c,BSF_Portfolio__r.Taxonomy_Type__c FROM AccountTEamMember WHERE AccountId IN:accIdAccPortfolioIdMap.keySet()];
List<id> accTeamBsfIdList = new List<id>();
List<id> accTeamUserIdList = new List<id>();
//Commented For Ticket No : HRP-9699
//Start--->
//Map<Id,AccountTeamMember> portfolioIdTeamMemberMap = new Map<Id,AccountTeamMember>();
//<--End
for(AccountTeamMember teamMember:teamMembersList){
//Commented For Ticket No : HRP-9699
//Start--->
//portfolioIdTeamMemberMap.put(teamMember.BSF_Portfolio__c, teamMember);
//<---End
accTeamBsfIdList.add(teamMember.BSF_Portfolio__c);
accTeamUserIdList.add(teamMember.UserId);
system.debug('AccountTeamMember_'+teamMember.BSF_Portfolio__c+'_'+teamMember.UserId);
}
List<Portfolio_Assignment__c> portfolioAssgnList = [Select id,Start_date__c,End_Date__c,BSF_Portfolio__c,User__c from Portfolio_Assignment__C where BSF_Portfolio__c IN :accTeamBsfIdList and User__c IN:accTeamUserIdList];
Map<String,Portfolio_Assignment__c> userPortfolioMap = new Map<String,Portfolio_Assignment__c>();
for(Portfolio_Assignment__c ps :portfolioAssgnList)
{
string Key = ps.User__c;
Key = key + ps.BSF_Portfolio__c;
userPortfolioMap.put(Key,ps);
}
//Commented For Ticket No : HRP-9699 [Start]
for(Id id:portfolioIdTeamMemberMap.keySet()){
System.debug('Portfolio Id from TeamMemberMap: '+id);
System.debug('TeamMemberRole From TeamMemberMap'+portfolioIdTeamMemberMap.get(id).TeamMemberRole);
}
//Commented For Ticket No : HRP-9699 [End]
for(Id amPortfolioId:amAndItsHierarchyMap.keySet()){
System.debug('amPortfolioId: '+amPortfolioId);
Set<Id> superPortfolioIds = amAndItsHierarchyMap.get(amPortfolioId);
//Commented For Ticket No : HRP-9699 [Start]
if(portfolioIdTeamMemberMap.containsKey(amPortfolioId)){
System.debug('amPortfolioId: '+portfolioIdTeamMemberMap.get(amPortfolioId).BSF_Portfolio__r.Taxonomy_Type__c);
System.debug('amPortfolioId: '+portfolioIdTeamMemberMap.get(amPortfolioId).BSF_Portfolio__r.Taxonomy_Type__c !=BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE);
Set<Id> superPortfolioIds = amAndItsHierarchyMap.get(amPortfolioId);
if((portfolioIdTeamMemberMap.get(amPortfolioId).BSF_Portfolio__r.Taxonomy_Type__c != BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE ||
portfolioIdTeamMemberMap.get(amPortfolioId).BSF_Portfolio__r.Taxonomy_Type__c !=BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE ))
{
//Commented For Ticket No : HRP-9699 [End]
system.debug('superPortfolioIds');
superPortfolioIds.add(amPortfolioId);
system.debug('superPortfolioIds'+superPortfolioIds);
System.debug('amAndItsHierarchyMap: '+amAndItsHierarchyMap);
for(Id superPortfolioId:superPortfolioIds){
for(AccountTeamMember member:teamMembersList){
string Key = member.UserId;
Key = key + amPortfolioId;
if(!userPortfolioMap.containsKey(Key))
{
key= null;
key = member.UserId;
key = Key + superPortfolioId;
}
System.debug('userPortfolioMap : '+ userPortfolioMap);
System.debug('Key : '+ Key);
if(userPortfolioMap.containsKey(Key))
{
Portfolio_Assignment__c portfolioAssign = userPortfolioMap.get(Key);
Account_portfolio_Assignment__c accPortfolioAssign = accIdAccPortfolioIdMap.get(member.AccountId);
Date userStDate = portfolioAssign.start_date__c;
Date userEndDate = portfolioAssign.End_date__c;
Date teamMemStartDate = accPortfolioAssign.Start_date__c >= userStDate ? accPortfolioAssign.Start_date__c : userStDate;
Date teamMemEndDate = accPortfolioAssign.End_date__c <= userEndDate ? accPortfolioAssign.End_date__c : userEndDate;
system.debug('teamMemStartDate : '+teamMemStartDate);
system.debug('teamMemEndDate : '+teamMemEndDate);
if(member.BSF_Portfolio__c == superPortfolioId || member.BSF_Portfolio__c == amPortfolioId){
if(calledFromBatch.equalsIgnoreCase('Called from AccountPortfolioAssignmentService')){
System.debug('AccountPortfolioAssignmentService--Super TeamMembers Match found!');
//member.End_Date__c = amPortfolioAcctPortfolioMap.get(amPortfolioId).End_Date__c;
member.End_Date__c = teamMemEndDate;
member.Start_Date__c = teamMemStartDate;
teamMembersSet.add(member);
}
else if(calledFromBatch.equalsIgnoreCase('Called from DefaultTerritoryPortfolioBatchHelper')){
System.debug('DefaultTerritoryPortfolioBatchHelper--Super TeamMembers Match found!');
member.End_Date__c =teamMemEndDate;
teamMembersSet.add(member);
}
else if(calledFromBatch.equalsIgnoreCase('Update of Prev Default AccPortfolioAssign accTeam')){
System.debug('Update previous default Account Team end date on Acc based Portfolio Start date change');
member.End_Date__c = teamMemEndDate;
teamMembersSet.add(member);
}
else if(calledFromBatch.equalsIgnoreCase('Update of Next Default AccPortfolioAssign accTeam')){
System.debug('Update Next default Account Team Start date on Acc based Portfolio End date change');
member.Start_Date__c = teamMemStartDate;
teamMembersSet.add(member);
}
}
}
}
}
}
// for(AccountTeamMember teamMember:teamMembersSet){
//     System.debug('teamMember: '+teamMember.Id);
// }
//System.debug('teamMembersSet Size: '+teamMembersSet.size());
//System.debug('teamMembersSet: '+teamMembersSet);
if(teamMembersSet.size()>0){
teamMemberListToUpdate.addAll(teamMembersSet);
try{
//Schema.DescribeSObjectResult ds = AccountTeamMember.sObjectType.getDescribe();
//if( ds.isUpdateable() ){}
database.SaveResult [] srlist =Database.update(teamMemberListToUpdate,false);
List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srlist,'Create Portfolio','AccountPortfolioAssignmentService','ExpireAccteam','Error','expire accteam');
InsertBsfErrorLog.insertBsfErrors(logList);
for(database.SaveResult sr :srlist)
{
if(sr.isSuccess())
{
System.debug('Successfully inserted accountPort.  ID: ' + sr.getId());
}
else if (!sr.isSuccess()) {
for(Database.Error err : sr.getErrors()) {
System.debug('The following error has occurred in AccountTeamMemberService Insert.');
System.debug(err.getStatusCode() + ': ' + err.getMessage());
System.debug(' fields that affected this error: ' + err.getFields());
}
}
}
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
}
return supervisorTeamMemberListToUpdate;
}*/
    /*public static List<AccountTeamMember> checkAndUpdateSupervisorAMPortfolioEndDate(List<Account_Portfolio_Assignment__c> accPortfolioList,Set<Id> portfolioIdSet,Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioIdMap,String calledFromBatch){
List<BSF_Portfolio__c> portfolioList = [SELECT Id,Portfolio_Name__c,Portfolio_Code__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:portfolioIdSet];
Map<Id,BSF_Portfolio__c> portfolioIdMap = new Map<Id,BSF_Portfolio__c>();
for(BSF_Portfolio__c portfolio:portfolioList){
portfolioIdMap.put(portfolio.Id,portfolio);
}
List<Account_Portfolio_Assignment__c> supervisorAMPortfolioList = [SELECT Id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c,
BSF_Portfolio__r.Portfolio_Code__c,BSF_Portfolio__r.Taxonomy_Type__c,
BSF_Portfolio__r.Parent_Portfolio__c
FROM Account_Portfolio_Assignment__c
WHERE Account__c IN:accIdAccPortfolioIdMap.keySet()
AND BSF_Portfolio__r.Taxonomy_Type__c =: BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE ];
System.debug('supervisorAMPortfolioList: '+supervisorAMPortfolioList);
Map<Id,List<Account_Portfolio_Assignment__c>> accIdSupervisorAccPortfolioMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
if(supervisorAMPortfolioList.size()>0){
for(Account_Portfolio_Assignment__c accPortfolio:supervisorAMPortfolioList){
if(!accIdSupervisorAccPortfolioMap.containsKey(accPortfolio.Account__c)){
List<Account_Portfolio_Assignment__c> accPortfolioList1 = new List<Account_Portfolio_Assignment__c>();
accPortfolioList1.add(accPortfolio);
accIdSupervisorAccPortfolioMap.put(accPortfolio.Account__c,accPortfolioList1);
}
else{
List<Account_Portfolio_Assignment__c> accPortfolioList2 = accIdSupervisorAccPortfolioMap.get(accPortfolio.Account__c);
accPortfolioList2.add(accPortfolio);
accIdSupervisorAccPortfolioMap.put(accPortfolio.Account__c,accPortfolioList2);
}
}
}
System.debug('accIdSupervisorAccPortfolioMap: '+accIdSupervisorAccPortfolioMap);
Set<Id> supervisorPortfolioIdSet = new Set<Id>();
List<Account_Portfolio_Assignment__c> supervisorAccPortfolioListToUpdate = new List<Account_Portfolio_Assignment__c>();
for(Id accId:accIdAccPortfolioIdMap.keySet()){
Account_Portfolio_Assignment__c accPortfolio = accIdAccPortfolioIdMap.get(accId);
if(accIdSupervisorAccPortfolioMap.containsKey(accPortfolio.Account__c)){
for(Account_Portfolio_Assignment__c accPortfolioToMatch:accIdSupervisorAccPortfolioMap.get(accPortfolio.Account__c)){
if(accPortfolioToMatch.BSF_Portfolio__r.Portfolio_Code__c.equalsIgnoreCase(portfolioIdMap.get(accPortfolio.BSF_Portfolio__c).Portfolio_Code__c)){
System.debug('Supervisor Portfolio Code Match Found!');
if(calledFromBatch.equalsIgnoreCase('Called from AccountPortfolioAssignmentService'))
{
accPortfolioToMatch.Start_Date__c = accPortfolio.Start_Date__c;
accPortfolioToMatch.End_Date__c = accPortf]olio.End_Date__c;
}
else if(calledFromBatch.equalsIgnoreCase('Update of Prev Default AccPortfolioAssign accTeam'))
{
accPortfolioToMatch.End_Date__c = accPortfolio.End_Date__c;
}
else if(calledFromBatch.equalsIgnoreCase('Update of Next Default AccPortfolioAssign accTeam'))
{
accPortfolioToMatch.Start_Date__c = accPortfolio.Start_Date__c;
}
supervisorAccPortfolioListToUpdate.add(accPortfolioToMatch);
supervisorPortfolioIdSet.add(accPortfolioToMatch.BSF_Portfolio__r.Parent_Portfolio__c);
}
}
}
}
//System.debug('supervisorAccPortfolioListToUpdate: '+supervisorAccPortfolioListToUpdate);
List<AccountTeamMember> supervisorTeamMemberListToUpdate = new List<AccountTeamMember>();
if(supervisorAccPortfolioListToUpdate.size()>0){
//Set<Id> supervisorPortfolioIds = new Set<Id>();
//for(Account_Portfolio_Assignment__c supervisorAccPortfolio:supervisorAccPortfolioListToUpdate){
//supervisorPortfolioIds.add(supervisorAccPortfolio.BSF_Portfolio__c);}
List<AccountTeamMember> supervisorTeamMemberList = [SELECT Id,UserId,AccountId,Start_Date__c,End_Date__c,BSF_Portfolio__c FROM AccountTeamMember WHERE BSF_Portfolio__C IN:supervisorPortfolioIdSet];
List<id> accTeamSupvsrBsfIdList = new List<id>();
List<id> accTeamSupvsrUserIdList = new List<id>();
for(AccountTeamMember teamMember:supervisorTeamMemberList)
{
accTeamSupvsrBsfIdList.add(teamMember.BSF_Portfolio__c);
accTeamSupvsrUserIdList.add(teamMember.UserId);
}
List<Portfolio_Assignment__c> portfolioAssgnList = [Select id,Start_date__c,End_Date__c,BSF_Portfolio__c,User__c from Portfolio_Assignment__C where BSF_Portfolio__c IN :accTeamSupvsrBsfIdList and User__c IN:accTeamSupvsrUserIdList];
Map<String,Portfolio_Assignment__c> userPortfolioMap = new Map<String,Portfolio_Assignment__c>();
system.debug('portfolioAssgnList: '+portfolioAssgnList);
for(Portfolio_Assignment__c ps :portfolioAssgnList)
{
string Key = ps.User__c;
Key = key + ps.BSF_Portfolio__c;
userPortfolioMap.put(Key,ps);
}
System.debug('supervisorTeamMemberList: '+supervisorTeamMemberList);
System.debug('accIdAccPortfolioIdMap: '+accIdAccPortfolioIdMap);
for(AccountTeamMember supervisorTeamMember:supervisorTeamMemberList){
if(accIdAccPortfolioIdMap.containsKey(supervisorTeamMember.AccountId)){
string Key = supervisorTeamMember.UserId;
Key = key +supervisorTeamMember.BSF_Portfolio__c;
Portfolio_Assignment__c portfolioAssign = userPortfolioMap.get(Key);
system.debug('portfolioAssign: '+portfolioAssign);
Account_portfolio_Assignment__c accPortfolioAssign = accIdAccPortfolioIdMap.get(supervisorTeamMember.AccountId);
Date userStDate = portfolioAssign.start_date__c;
Date userEndDate = portfolioAssign.End_date__c;
Date teamMemStartDate = accPortfolioAssign.Start_date__c >= userStDate ? accPortfolioAssign.Start_date__c : userStDate;
Date teamMemEndDate = accPortfolioAssign.End_date__c <= userEndDate ? accPortfolioAssign.End_date__c : userEndDate;
system.debug('teamMemStartDate : '+teamMemStartDate);
system.debug('teamMemEndDate : '+teamMemEndDate);
if(calledFromBatch.equalsIgnoreCase('Called from AccountPortfolioAssignmentService')){
System.debug('AccountPortfolioAssignmentService--Super TeamMembers Match found!');
system.debug('supervisor update');
//member.End_Date__c = amPortfolioAcctPortfolioMap.get(amPortfolioId).End_Date__c;
supervisorTeamMember.End_Date__c = teamMemEndDate;
supervisorTeamMember.Start_Date__c = teamMemStartDate;
supervisorTeamMemberListToUpdate.add(supervisorTeamMember);
}
else if(calledFromBatch.equalsIgnoreCase('Update of Prev Default AccPortfolioAssign accTeam')){
System.debug('Update previous default Account Team supervisor end date on Acc based Portfolio Start date change');
system.debug('supervisor update');
supervisorTeamMember.End_Date__c = teamMemEndDate;
supervisorTeamMemberListToUpdate.add(supervisorTeamMember);
}
else if(calledFromBatch.equalsIgnoreCase('Update of Next Default AccPortfolioAssign accTeam')){
System.debug('Update Next default Account Team supervisor Start date on Acc based Portfolio End date change');
system.debug('supervisor update');
supervisorTeamMember.Start_Date__c = teamMemStartDate;
supervisorTeamMemberListToUpdate.add(supervisorTeamMember);
}
}
}
try{
Database.update(supervisorAccPortfolioListToUpdate);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
if(supervisorTeamMemberListToUpdate.size()>0){
try{
Database.update(supervisorTeamMemberListToUpdate);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
}
}
return supervisorTeamMemberListToUpdate;
}  */
    //HRP-10099 -  Logic moved to the Method "accTeamDateSyncOnAccPortUpdates"
    /*
* HRP-10878 changes starts here
* @Description: Handles  Account portfolio assignments for Territory portfolio on Zipcode change
* @Date: 09/18/2023
*/
    public static void handleTerritoryPortfolioInsert(list<Account_Portfolio_Assignment__c> newItems)
    {
        system.debug('Inside handleTerritoryPortfolioInsert');
        set<id>BSFIdset = new set<id>();
        set<id> accIdSet = new set<id>();
        system.debug('newItems'+newItems);
        for(Account_Portfolio_Assignment__c ap:newItems)
        {
            BSFIdset.add(ap.BSF_Portfolio__C);
            accIdSet.add(ap.account__C);
        }
        list<account> accToUpdate = new list<account>();
        for(Account acc:[select id,billingpostalcode,shippingpostalcode,Zipcode_change__c from account where id in:accIdSet])
        {
            acc.Zipcode_change__c =acc.billingpostalcode!=null?acc.billingpostalcode:acc.shippingpostalcode;
            accToUpdate.add(acc);
        }
        if(!accToUpdate.isEmpty())
        {
            triggerHandler.byPass('AccountTriggerHandler');
            update accToUpdate;
            triggerHandler.clearbyPass('AccountTriggerHandler');
        }
        Map<id,BSF_Portfolio__c> bsfIdMap = new Map<id,BSF_Portfolio__c>([select id,Start_date__c,End_Date__c,portfolio_code__c from BSF_Portfolio__C where Taxonomy_Type__c=:BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE and Id In:BSFIdset order by start_date__c]);
        system.debug('bsfIdMap'+bsfIdMap);
        Map<id,BSF_Portfolio__c> supBsfIdsMap = new Map<id,BSF_Portfolio__c>([select id,Start_date__c,End_Date__c,portfolio_code__c from BSF_Portfolio__C where Taxonomy_Type__c=:BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE and Id In:BSFIdset order by start_date__c]);
        Map<string,BSF_Portfolio__c> supBsfIdMap = new Map<string,BSF_Portfolio__c>();
        for(BSF_Portfolio__c bsf:supBsfIdsMap.values() )
        {
            supBsfIdMap.put(bsf.portfolio_code__c,bsf);
        }
        Map<Id,List<Account_Portfolio_Assignment__c>> accIdBsfPortfolioListMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
        for(Account_Portfolio_Assignment__c ap:newItems)
        {
            if(!accIdBsfPortfolioListMap.keyset().contains(ap.Account__c)){
                accIdBsfPortfolioListMap.put(ap.account__c,new List<Account_Portfolio_Assignment__c>());
            }
            accIdBsfPortfolioListMap.get(ap.Account__c).add(ap);
        }
        list<Account_Portfolio_Assignment__c> existingAccPortfolio = [select Start_Date__c,End_Date__c,Account__c,Portfolio_Type__c,BSF_Portfolio__r.Portfolio_Code__c,BSF_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Taxonomy_Type__c from Account_Portfolio_Assignment__c
                                                                      where (BSF_Portfolio__r.Taxonomy_Type__c =:BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE or BSF_Portfolio__r.Taxonomy_Type__c=:BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE or BSF_Portfolio__r.Taxonomy_Type__c=:BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
                                                                      and Account__c IN:accIdSet and BSF_Portfolio__r.Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER order by start_date__c];
        map<id,List<Account_Portfolio_Assignment__c>> accIdAccPortfolioListMap =new map<id,List<Account_Portfolio_Assignment__c>>();
        Map<string,Account_Portfolio_Assignment__c> exSupBsfIdMap = new Map<string,Account_Portfolio_Assignment__c> ();
        for(Account_Portfolio_Assignment__c ap: existingAccPortfolio)
        {
            if(!accIdAccPortfolioListMap.keyset().contains(ap.account__c))
                accIdAccPortfolioListMap.put(ap.account__c,new list<Account_Portfolio_Assignment__c>());
            accIdAccPortfolioListMap.get(ap.account__c).add(ap);
            if(ap.BSF_Portfolio__r.Taxonomy_Type__c==BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
                exSupBsfIdMap.put(ap.Account__c+'_'+ap.BSF_Portfolio__r.portfolio_code__c+'_'+ap.Start_Date__c,ap);
        }
        list<Account_Portfolio_Assignment__c> accPortAssignInsertList = new list<Account_Portfolio_Assignment__c>();
        list<Account_Portfolio_Assignment__c> accPortAssignUpdateList = new list<Account_Portfolio_Assignment__c>();
        list<Account_Portfolio_Assignment__c> supDelList = new list<Account_Portfolio_Assignment__c>();
        map<string,Account_Portfolio_Assignment__c> supAccPortMap = new map<string,Account_Portfolio_Assignment__c>();
        map<string,Account_Portfolio_Assignment__c> territoryUpdateInfoMap = new map<string,Account_Portfolio_Assignment__c>();
        for(id accId :accIdAccPortfolioListMap.keyset())
        {
            set<id> bsfTrackerSet = new set<id> ();
            integer bsfPOrtfolioIndex=0;
            List<Account_Portfolio_Assignment__c> newAPAList = new list<Account_Portfolio_Assignment__c>();
            if(accIdBsfPortfolioListMap!= null && accIdBsfPortfolioListMap.keyset().contains(accId))
            {
                newAPAList = accIdBsfPortfolioListMap.get(accId);
            }
            Date currentDate = system.today();
            Date lastEndDate;
            for(Account_Portfolio_Assignment__c ap: accIdAccPortfolioListMap.get(accId))
            {
                String key;
                if(ap.BSF_Portfolio__r.Taxonomy_Type__c!=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
                {
                    //HRP-12053 start
                    //Expired - No action needed
                    if(ap.End_Date__c < currentDate){
                        continue;
                    }
                    lastEndDate =ap.End_Date__c;
                    Boolean isPortfolioSame = false;
                    if(ap.BSF_Portfolio__r.Taxonomy_Type__c ==BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE)
                    {
                        if(bsfPOrtfolioIndex >= newAPAList.size()){
                            supDelList.add(ap);
                            continue;
                        }
                        if(ap.start_date__c == currentDate)
                        {
                            
                            if(ap.BSF_Portfolio__c != newAPAList[bsfPOrtfolioIndex].BSF_Portfolio__c){
                                ap.BSF_Portfolio__c = newAPAList[bsfPOrtfolioIndex].BSF_Portfolio__c;
                                accPortAssignUpdateList.add(ap);
                                }else{
                                isPortfolioSame = true;
                            }
                        } else if(ap.start_date__c < currentDate){
                            if(ap.BSF_Portfolio__c != newAPAList[bsfPOrtfolioIndex].BSF_Portfolio__c){
                                ap.End_date__c = currentDate.addDays(-1);
                                accPortAssignUpdateList.add(ap);
                                Account_Portfolio_Assignment__c newAPA = new Account_Portfolio_Assignment__c(
                                    account__c=ap.account__c,BSF_Portfolio__c=newAPAList[bsfPOrtfolioIndex].BSF_Portfolio__c);
                                newAPA.Start_date__c=currentDate;
                                newAPA.End_date__c=lastEndDate;
                                ap = newAPA;
                                accPortAssignInsertList.add(newAPA);
                                }else{
                                isPortfolioSame = true;
                            }
                        } else {
                            if(newAPAList[bsfPOrtfolioIndex].End_Date__c < ap.Start_Date__c){
                                bsfPOrtfolioIndex++;
                            }
                            if(bsfPOrtfolioIndex >= newAPAList.size()){
                                supDelList.add(ap);
                                continue;
                            }
                            if(ap.BSF_Portfolio__c != newAPAList[bsfPOrtfolioIndex].BSF_Portfolio__c){
                                ap.BSF_Portfolio__c = newAPAList[bsfPOrtfolioIndex].BSF_Portfolio__c;
                                accPortAssignUpdateList.add(ap);
                                }else{
                                isPortfolioSame = true;
                            }
                        }
                        if(newAPAList[bsfPOrtfolioIndex].End_Date__c <= lastEndDate){
                            Date orginalEndDate=ap.End_Date__c;
                            ap.End_Date__c = newAPAList[bsfPOrtfolioIndex].End_Date__c;
                            lastEndDate = ap.End_Date__c;
                            bsfPOrtfolioIndex++;
                            
                            //HRP-12485 start
                            if(newAPAList.size()-1>=bsfPOrtfolioIndex)
                            {
                            Account_Portfolio_Assignment__c newAPA = new Account_Portfolio_Assignment__c(
                                account__c=ap.account__c,BSF_Portfolio__c=newAPAList[bsfPOrtfolioIndex].BSF_Portfolio__c);
                            newAPA.Start_date__c=ap.End_Date__c+1;
                            newAPA.End_date__c=orginalEndDate;
                            accPortAssignInsertList.add(newAPA);
                            ap=newAPA;
                            lastEndDate = newAPA.End_date__c;
                        }
                            //HRP-12485 End
                            if(isPortfolioSame){
                                accPortAssignUpdateList.add(ap);
                                }
                        }
                        //HRP-12053 end
                        /* commented part of HRP-12053
if(ap.start_date__c <= currentDate && currentDate <= ap.End_date__c)
{
bsfTrackerSet.add(bsfList[bsfPOrtfolioIndex].id);
system.debug('current assignment');
system.debug('bsfList[bsfPOrtfolioIndex]'+bsfList[bsfPOrtfolioIndex]);
system.debug('ap'+ap);
if(ap.bsf_portfolio__c != bsfList[bsfPOrtfolioIndex].id)
{
system.debug('different bsfid');
Account_Portfolio_Assignment__c apa = new Account_Portfolio_Assignment__c();
Account_Portfolio_Assignment__c supApa;
apa.account__c = ap.account__c;
apa.BSF_Portfolio__c = bsfList[bsfPOrtfolioIndex].id;
apa.start_date__c=currentDate;
apa.End_date__c=ap.End_date__c;
accPortAssignInsertList.add(apa);
if(supBsfIdMap!=null && supBsfIdMap.get( bsfList[bsfPOrtfolioIndex].portfolio_code__c)!=null)
{
supApa = new Account_Portfolio_Assignment__c();
supApa.account__c = ap.account__c;
supApa.BSF_Portfolio__c = supBsfIdMap.get(bsfList[bsfPOrtfolioIndex].portfolio_code__c).id;
supApa.start_date__c=currentDate;
supApa.End_date__c=ap.End_date__c;
accPortAssignInsertList.add(supApa);
}
ap.End_date__c = currentDate.addDays(-1);
key = ap.Account__c+'_'+ap.BSF_Portfolio__r.portfolio_code__c+'_'+ap.Start_Date__c;
if(exSupBsfIdMap!=null && exSupBsfIdMap.get(key)!=null)
{
supApa = new Account_Portfolio_Assignment__c();
supApa=exSupBsfIdMap.get(key);
supApa.End_Date__c=ap.End_date__c;
}
if(ap.Start_Date__c <ap.End_Date__c)
{
accPortAssignUpdateList.add(ap);
if(supApa!=null)
accPortAssignUpdateList.add(supApa);
}
else
{
supDelList.add(ap);
if(supApa!=null)
supDelList.add(supApa);
}
territoryUpdateInfoMap.put(key,ap);
}
bsfPOrtfolioIndex++;
}
else if(ap.start_date__c > currentDate && bsfList[bsfPOrtfolioIndex].start_date__c <= ap.start_date__c && bsfList[bsfPOrtfolioIndex].end_date__c >= ap.start_date__c)
{
system.debug('future assignment');
system.debug('bsfList[bsfPOrtfolioIndex]'+bsfList[bsfPOrtfolioIndex]);
system.debug('ap'+ap);
key=ap.Account__c+'_'+ap.BSF_Portfolio__r.portfolio_code__c+'_'+ap.Start_Date__c;
bsfTrackerSet.add(bsfList[bsfPOrtfolioIndex].id);
ap.bsf_portfolio__c=bsfList[bsfPOrtfolioIndex].Id;
ap.end_date__c = ap.end_date__c <= bsfList[bsfPOrtfolioIndex].end_date__c?ap.end_Date__c:bsfList[bsfPOrtfolioIndex].end_date__c;
lastEndDate =ap.end_date__c;
territoryUpdateInfoMap.put(key,ap);
//update
accPortAssignUpdateList.add(ap);
if(supBsfIdMap!=null && supBsfIdMap.get(bsfList[bsfPOrtfolioIndex].portfolio_code__c)!=null)
{
Account_Portfolio_Assignment__c supApa = new Account_Portfolio_Assignment__c();
if(exSupBsfIdMap!=null && exSupBsfIdMap.get(key)!=null)
{
supApa=exSupBsfIdMap.get(key);
supApa.BSF_Portfolio__c = supBsfIdMap.get(bsfList[bsfPOrtfolioIndex].portfolio_code__c).id;
supApa.End_Date__c=ap.End_date__c;
accPortAssignUpdateList.add(supApa);
}
else
{
supApa.Start_Date__c=ap.Start_Date__c;
supApa.BSF_Portfolio__c = supBsfIdMap.get(bsfList[bsfPOrtfolioIndex].portfolio_code__c).id;
supApa.End_Date__c=ap.End_date__c;
accPortAssignInsertList.add(supApa);
}
}
else
{
if(exSupBsfIdMap!=null && exSupBsfIdMap.get(key)!=null)
{
supDelList.add(exSupBsfIdMap.get(key));
}
}
}
else if(ap.start_date__c > currentDate && bsfList[bsfPOrtfolioIndex].end_date__c <= ap.start_date__c)
{
system.debug('future assignment2');
system.debug('bsfList[bsfPOrtfolioIndex]'+bsfList[bsfPOrtfolioIndex]);
system.debug('ap'+ap);
for(integer i =bsfPOrtfolioIndex+1;i<bsfList.size();i++)
{
bsf_portfolio__c bsf = bsfList[i];
bsfPOrtfolioIndex=i;
bsfTrackerSet.add(bsf.id);
if(ap.start_date__c > currentDate && bsf.start_date__c <= ap.start_date__c && bsf.end_date__c >= ap.start_date__c )
{
system.debug('2nd entry');
if(ap.bsf_portfolio__c!=bsf.Id)
{
key=ap.Account__c+'_'+ap.BSF_Portfolio__r.portfolio_code__c+'_'+ap.Start_Date__c;
ap.bsf_portfolio__c=bsf.Id;
ap.end_date__c = ap.end_date__c <= bsf.end_date__c?ap.end_Date__c:bsf.end_date__c;
lastEndDate =ap.end_date__c;
territoryUpdateInfoMap.put(key,ap);
accPortAssignUpdateList.add(ap);
if(supBsfIdMap!=null && supBsfIdMap.get(bsfList[bsfPOrtfolioIndex].portfolio_code__c)!=null)
{
Account_Portfolio_Assignment__c supApa = new Account_Portfolio_Assignment__c();
if(exSupBsfIdMap!=null && exSupBsfIdMap.get(key)!=null)
{
supApa=exSupBsfIdMap.get(key);
supApa.BSF_Portfolio__c = supBsfIdMap.get(bsfList[bsfPOrtfolioIndex].portfolio_code__c).id;
supApa.End_Date__c=ap.End_date__c;
accPortAssignUpdateList.add(supApa);
}
else
{
supApa.Start_Date__c=ap.Start_Date__c;
supApa.BSF_Portfolio__c = supBsfIdMap.get(bsfList[bsfPOrtfolioIndex].portfolio_code__c).id;
supApa.End_Date__c=ap.End_date__c;
accPortAssignInsertList.add(supApa);
}
}
else
{
if(exSupBsfIdMap!=null && exSupBsfIdMap.get(key)!=null)
{
supDelList.add(exSupBsfIdMap.get(key));
}
}
break;
}
}
}
}commented part of HRP-12053*/ //Comment here
                    }
                }
            }
            system.debug('bsfTrackerSet '+bsfTrackerSet);
            /* commented part of HRP-12053
if(bsfTrackerSet.size() != bsfList.size() )
{
system.debug('bsfTrackerSet in');
for(bsf_portfolio__c bsf:bsfList)
{
if(!bsfTrackerSet.contains(bsf.id))
{
Account_Portfolio_Assignment__c apa = new Account_Portfolio_Assignment__c();
apa.account__c = accId;
apa.BSF_Portfolio__c = bsf.id;
apa.start_date__c=lastEndDate+1;
apa.End_date__c=bsf.End_date__c;
lastEndDate =apa.end_date__c;
accPortAssignInsertList.add(apa);
if(supBsfIdMap!=null && supBsfIdMap.get(bsf.portfolio_code__c)!=null)
{
Account_Portfolio_Assignment__c supApa = new Account_Portfolio_Assignment__c();
supApa.Start_Date__c=apa.Start_Date__c>=supBsfIdMap.get(bsf.portfolio_code__c).Start_date__c?apa.Start_Date__c:supBsfIdMap.get(bsf.portfolio_code__c).Start_date__c;//HRP-11290 date comparison
supApa.BSF_Portfolio__c = supBsfIdMap.get(bsf.portfolio_code__c).id;
supApa.End_Date__c=apa.End_Date__c<=supBsfIdMap.get(bsf.portfolio_code__c).End_Date__c?apa.End_Date__c:supBsfIdMap.get(bsf.portfolio_code__c).End_Date__c;//HRP-11290 date comparison
supApa.account__c=accId;
accPortAssignInsertList.add(supApa);
}
}
}
}commented part of HRP-12053*/
            //HRP-12053 Start
            if(bsfPOrtfolioIndex < newAPAList.size()){
                for(Integer index=bsfPOrtfolioIndex;index<newAPAList.size();index++){
                    Account_Portfolio_Assignment__c apa = new Account_Portfolio_Assignment__c(Account__c = accId,BSF_Portfolio__c = newAPAList[index].BSF_Portfolio__c);
                    apa.Start_date__c=lastEndDate+1;
                    apa.End_date__c=newAPAList[index].End_date__c;
                    lastEndDate =apa.End_date__c;
                    accPortAssignInsertList.add(apa);
                    system.debug('Insert 1)'+apa);
                }
            }
            //HRP-12053 end
        }
        triggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        for(Account_Portfolio_Assignment__c apa:accPortAssignInsertList)
        {
        }
        if(!accPortAssignInsertList.isEmpty())
        {
            system.debug('accPortAssignInsertList ' +accPortAssignInsertList);
            Database.Insert (accPortAssignInsertList,false);
        }
        if(!accPortAssignUpdateList.isEmpty())
        {
            Database.Update (accPortAssignUpdateList,false);
        }
        if(!supDelList.isEmpty())
        {
            database.delete(supDelList,false);
        }
        triggerHandler.clearBypass('AccountPortfolioAssignmentTriggerHandler');
        //HRP-10878
    }
    /*public static void accTeamMembersDeleteUpdate(list<Account_Portfolio_Assignment__c> accPortfolioAssign)
{
Map<Id,list<Account_Portfolio_Assignment__c>> accIdAccPortListMap = new Map<Id,list<Account_Portfolio_Assignment__c>>();
List<accountTeamMember> exAccTeamtoUpdateList = new List<accountTeamMember>();
set<id>BSFIdset = new set<id>();
set<string>portfolioCode = new set<String>();
for(Account_Portfolio_Assignment__c ap:accPortfolioAssign)
{
if(!accIdAccPortListMap.keyset().contains(ap.Account__c))
{
list<Account_Portfolio_Assignment__c>accportfolio= new list<Account_Portfolio_Assignment__c>();
accportfolio.add(ap);
accIdAccPortListMap.put(ap.Account__c,accportfolio);
}
else
{
accIdAccPortListMap.get(ap.Account__c).add(ap);
}
BSFIdset.add(ap.BSF_Portfolio__c);
BSFIdset.add(ap.BSF_Portfolio__r.Parent_Portfolio__c);
BSFIdset.add(ap.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c);
portfolioCode.add(ap.BSF_Portfolio__r.Portfolio_Code__c+'_'+ap.Start_Date__c+'_'+ap.account__c);
}
list<Account_Portfolio_Assignment__c> superviosorAccPort = [Select id,Account__c,BSF_Portfolio__c,Start_Date__c,End_Date__c,BSF_Portfolio__r.Parent_Portfolio__c from Account_Portfolio_Assignment__c
where account__C In:accIdAccPortListMap.Keyset() and BSF_Portfolio__r.Portfolio_Code__c IN:portfolioCode and BSF_Portfolio__r.Taxonomy_Type__c= :BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE and BSF_Portfolio__r.Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER];
for(Account_Portfolio_Assignment__c Sap:superviosorAccPort)
{
BSFIdset.add(sap.BSF_Portfolio__r.Parent_Portfolio__c);
//if(!(Sap.End_Date__c < system.today()))
//{
accPortfolioAssign.add(Sap);
//}
if(portfolioCode.contains(sap.BSF_Portfolio__r.Portfolio_Code__c+'_'+sap.Start_Date__c+'_'+sap.account__c))
{
accPortfolioAssign.add(Sap);
}
if(accIdAccPortListMap.keyset().contains(Sap.Account__c))
{accIdAccPortListMap.get(Sap.Account__c).add(Sap);}
}
Database.delete(accPortfolioAssign);
map<string,AccountTeamMember> accIdUserDate = new map<string,AccountTeamMember> ();
accIdUserDate = AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(new list<id>(accIdAccPortListMap.keyset()),'Called from DefaultTerritoryPortfolioBatchHelper');
List<AccountTeamMember> exAccTeamList = [Select id,AccountId,BSF_Portfolio__c,Start_Date__c,End_Date__c,BSF_Portfolio__r.Portfolio_Code__c,UserId from AccountTeamMember where AccountId IN:accIdAccPortListMap.keySet() and BSF_Portfolio__c IN:BSFIdset];
list<AccountTeamMember> exAccTeamListToDelete = new list<AccountTeamMember>();
for(AccountTeamMember atm : exAccTeamList)
{
String key = atm.AccountId+'_'+ atm.UserId;
if(!accIdUserDate.Keyset().contains(key))
{
exAccTeamListToDelete.add(atm);
}
}
set<Account_Portfolio_Assignment__c> accPortfolioAssignset = new set<Account_Portfolio_Assignment__c>();
//accPortfolioAssignset.addAll(accPortfolioAssign);
//accPortfolioAssign.clear();
//accPortfolioAssign.addAll(accPortfolioAssignset);
if(!exAccTeamListToDelete.isEmpty())
{
Database.delete(exAccTeamListToDelete);
}
}*/
    /*public static List<AccountTeammember> AccZipcodeChangeTeamHandle(list<Account_Portfolio_Assignment__c> newItems,List<AccountTeammember> atmList)
{
set<id>BSFIdset = new set<id>();
set<id> accidSet = new set<id>();
for(Account_Portfolio_Assignment__c ap: newItems)
{
BSFIdset.add(ap.BSF_Portfolio__c);
}
map<id,BSF_Portfolio__c> bsfPortfolioMap = new map<id,BSF_Portfolio__c>([select id,Parent_Portfolio__c,Portfolio_Type__c,Taxonomy_Type__c from BSF_Portfolio__c where id IN:BSFIdset]);//= :BSF_Constants.ACCOUNT_MANAGER
map<string,Account_Portfolio_Assignment__c> bsfIdaccPortMap = new map<string,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c ap: newItems)
{
bsfIdaccPortMap.put(ap.Account__c+'_'+ap.BSF_Portfolio__c,ap);
if(bsfPortfolioMap.get(ap.BSF_Portfolio__c).Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER && bsfPortfolioMap.get(ap.BSF_Portfolio__c).Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE)
{
bsfIdaccPortMap.put(ap.Account__c+'_'+bsfPortfolioMap.get(ap.BSF_Portfolio__c).Parent_Portfolio__c,ap);
}
}
Map<id,List<id>> accAccTeamListMap =BsfPortfolioSyncHelper.accIdexistingUserIdMap(accidSet);
for(AccountTeammember atm: atmList)
{
if(bsfIdaccPortMap.keyset().contains(atm.accountid+'_'+atm.BSF_Portfolio__c))
{
if((accAccTeamListMap == null || accAccTeamListMap.get(atm.AccountId) == Null) ||
(accAccTeamListMap != null && accAccTeamListMap.get(atm.AccountId) != null
&& !accAccTeamListMap.get(atm.AccountId).contains(atm.UserId)))
{
atm.Start_Date__c = bsfIdaccPortMap.get(atm.accountid+'_'+atm.BSF_Portfolio__c).Start_Date__c;
}
atm.End_Date__c = bsfIdaccPortMap.get(atm.accountid+'_'+atm.BSF_Portfolio__c).End_Date__c;
}
}
return atmList;
}*/
    //Added for HRP-4619:System Automatically Return to Territory Assignment
    /*public static void createDefaultTerritoryRecords(List<Account_Portfolio_Assignment__c> newAccountPortfolioList, Map<Id, Account_Portfolio_Assignment__c> newAccountPortfoliosMap,Map<Id, Account_Portfolio_Assignment__c> oldAccountPortfoliosMap){
if(!isMethodExecuted){
Map<Id,Id> accountAndAccPortfolioIdsMap = new Map<Id,Id>();
Map<Id,Id> accPortfolioAndAccountIdsMap = new Map<Id,Id>();
Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioMap = new Map<Id,Account_Portfolio_Assignment__c>();
Set<Id> finalEligibleAccountsIdSet = new Set<Id>();
Set<Id> portfolioIdSet = new Set<Id>();
for(Account_Portfolio_Assignment__c newAccPortfolio:newAccountPortfolioList){
portfolioIdSet.add(newAccPortfolio.BSF_Portfolio__c);
accIdAccPortfolioMap.put(newAccPortfolio.Account__c, newAccPortfolio);
}
<--List<Account_Portfolio_Assignment__c> accPortfolioListWithPortfolioDetails = [SELECT Id,Name,Account__c,Start_Date__c,End_Date__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Code__c,BSF_Portfolio__r.Taxonomy_Type__c FROM Account_Portfolio_Assignment__c WHERE Id IN:newAccountPortfoliosMap.keySet()];
for(Account_Portfolio_Assignment__c newAccPortfolio:accPortfolioListWithPortfolioDetails){
accIdAccPortfolioMap.put(newAccPortfolio.Account__c, newAccPortfolio);
}-->//already commmented
System.debug('==accIdAccPortfolioMap== '+accIdAccPortfolioMap);
Map<Id,BSF_Portfolio__c> portfolioMap = new Map<Id,BSF_Portfolio__c>([SELECT Id,Portfolio_Name__c,Parent_Portfolio__c,Taxonomy_Type__c,Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:portfolioIdSet]);
for(Account_Portfolio_Assignment__c newAccPortfolio:newAccountPortfolioList){
if(portfolioMap.get(newAccPortfolio.BSF_Portfolio__c).Portfolio_Type__c.equalsIgnoreCase(BSF_Constants.ACCOUNT_MANAGER) && portfolioMap.get(newAccPortfolio.BSF_Portfolio__c).Account_Based_Portfolio__c == true){ //First Check if the updated AccPortfolio is of AM Type and Account Based/Non-Geo Portfolio
System.debug('Its AM AND Account Based');
if(newAccPortfolio.End_Date__c <= System.today()){ //If yes, then check if the new End Date is less than or equal to Today
System.debug('Its here');
accountAndAccPortfolioIdsMap.put(newAccPortfolio.Account__c,newAccPortfolio.Id ); //If yes, then prepare a Map of AccPortfolio Id and its associated Account Id
accPortfolioAndAccountIdsMap.put(newAccPortfolio.Id,newAccPortfolio.Account__c );
}
}
}
if(accountAndAccPortfolioIdsMap.size()>0){
List<Account_Portfolio_Assignment__c> accPortfolioList1 = [SELECT Id,Account__c,BSF_Portfolio__c, Start_Date__c,End_Date__c FROM Account_Portfolio_Assignment__c WHERE Account__c IN:accountAndAccPortfolioIdsMap.keySet() AND BSF_Portfolio__r.Portfolio_Type__c =: BSF_Constants.ACCOUNT_MANAGER ]; //Get all the AM Portfolios of the Accounts
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
if(accPort.Start_Date__c > newAccountPortfoliosMap.get(accountAndAccPortfolioIdsMap.get(accId)).End_Date__c){
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
if(finalEligibleAccountsIdSet.size()>0){
System.debug('finalEligibleAccountsIdSet: '+finalEligibleAccountsIdSet);
//Before calling the method to create new Account-Portfolio and Team Member records, we need to first expire the Account-Based Team Member Records with the Account-Portfolio End Date
isMethodExecuted = true;
List<AccountTeamMember> teamToBeEndDated = expireAccountTeamByAccountPortfolio(newAccountPortfolioList,accIdAccPortfolioMap,'Called from AccountPortfolioAssignmentService');
isMethodExecuted = false;
List<Account> accList = [SELECT Id, Name,BillingPostalCode,Shippingpostalcode FROM Account WHERE Id IN:finalEligibleAccountsIdSet];
List<Account> accListToUpdate = new List<Account>();
for(Account acc:accList){
acc.Account_AM_Portfolio_Type__c = false;
System.debug('accListToUpdate--Account AM Portfolio Type Flag: '+acc.Account_AM_Portfolio_Type__c);
accListToUpdate.add(acc);
}
try{
System.debug('accListToUpdate: '+accListToUpdate);
//Schema.DescribeSObjectResult ds = Account.sObjectType.getDescribe();
//if( ds.isUpdateable() ){}
Database.update(accListToUpdate);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
Map<String,AccountTeamMember> teamMemberMap = new Map<String,AccountTeamMember>();
for(AccountTeamMember teamMember:teamToBeEndDated){
teamMemberMap.put(teamMember.AccountId+''+teamMember.UserId,teamMember);
}
AccountService.createAccountTeamMembers(accList,null,'Called from AccountPortfolioAssignmentService',accIdAccPortfolioMap,teamMemberMap);
System.debug('teamMemberMap '+teamMemberMap);
if(teamMemberMap.size() > 0){
Database.update(teamMemberMap.values(),false);
}
}
isMethodExecuted = true;
}
}*/
    /*
* HRP-6028 changes starts here
* @Description: trigger method called on After insert/Update/Delete, syncs specialist account portfolio assignments for accounts based on AM account portfolio assignments
* @Date: 12/07/2023
*/
    Public static void HandleSpecialistForAM(List<Account_portfolio_assignment__c> newItems,map<id,Account_portfolio_assignment__c> newMap,map<id,Account_portfolio_assignment__c> oldMap)
    {
        system.debug('Entered HandleAccountSpecialist');
        set<id> accountIdSet = new set<id>();
        set<id> bsfIdSet = new set<id>();
        for(Account_portfolio_assignment__c apa : newItems)
        {
            {
                bsfIdSet.add(apa.BSF_Portfolio__c);
            }
        }
        Map<Id,BSF_Portfolio__c> portfolioMap = new Map<Id,BSF_Portfolio__c>([SELECT Id,Portfolio_Name__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Code__c,Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Code__c,Parent_Portfolio__r.Portfolio_Type__c,Parent_Portfolio__r.Parent_Portfolio__c,Taxonomy_Type__c,Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:bsfIdSet]);
        for(Account_portfolio_assignment__c apa : newItems)
        {
            if(portfolioMap.get(apa.BSF_Portfolio__c).Portfolio_Type__c == BSF_constants.ACCOUNT_MANAGER &&
               portfolioMap.get(apa.BSF_Portfolio__c).Taxonomy_Type__c != BSF_constants.SUPERVISOR)
            {
                if(oldMap==null || (oldMap!=null &&(oldMap.get(apa.id).start_Date__c!=apa.Start_Date__c || oldMap.get(apa.id).End_Date__c!=apa.End_Date__c)))
                {
                    accountIdSet.add(apa.account__c);
                }
            }
        }
        HandleAccountSpecialist(accountIdSet);
    }
    Public static void HandleAccountSpecialist(set<id> accountIdSet)
    {
        Map<id,string> accIdPortfolioCodeMap = new Map<id,string>();
        set<id> bsfIdSet = new set<id>();
        list<Account_portfolio_assignment__c> allRelAccPort = [select id,start_Date__c,End_date__c,BSF_portfolio__c,Account__c,BSF_portfolio__r.Taxonomy_Type__c,BSF_portfolio__r.Name,BSF_portfolio__r.Portfolio_Code__c from Account_portfolio_assignment__c where account__c in :accountIdSet and BSF_portfolio__r.Portfolio_Type__c in :new list<string>{bsf_constants.ACCOUNT_SPECIALIST,bsf_constants.ACCOUNT_MANAGER} order by Account__c,Start_date__c];
        Map<id,list<Account_portfolio_assignment__c>> accIdexistngAccSpecListMap = new Map<id,list<Account_portfolio_assignment__c>>();
        Map<Id,List<Account_Portfolio_Assignment__c>> accIdExistngSupAPAMap = new Map<Id,list<Account_Portfolio_Assignment__c>>();
        list<Account_portfolio_assignment__c> focusedAccPort = new list<Account_portfolio_assignment__c>();
        for(Account_portfolio_assignment__c allApa:allRelAccPort)
        {
            if(allApa.BSF_portfolio__r.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE ||
               allApa.BSF_portfolio__r.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE)
            {
                bsfIdSet.add(allApa.BSF_Portfolio__c);
                focusedAccPort.add(allApa);
            }
            else if(allApa.BSF_portfolio__r.Taxonomy_Type__c == BSF_Constants.ACCOUNT_SPECIALIST)
            {
                string key =allApa.Account__c+' '+allApa.BSF_Portfolio__c;
                if(!accIdexistngAccSpecListMap.containsKey(allApa.account__c))
                    accIdexistngAccSpecListMap.put(allApa.Account__c,new list<Account_portfolio_assignment__c>());
                accIdexistngAccSpecListMap.get(allApa.Account__c).add(allApa);
                //HRP-12053 start
            }else if(allApa.BSF_portfolio__r.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE){
                if(!accIdExistngSupAPAMap.containsKey(allApa.account__c))
                    accIdExistngSupAPAMap.put(allApa.Account__c,new list<Account_Portfolio_Assignment__c>());
                accIdExistngSupAPAMap.get(allApa.Account__c).add(allApa);
            }
            //HRP-12053 end
        }
        system.debug('allRelAccPort'+allRelAccPort);
        system.debug('focusedAccPort'+focusedAccPort);
        Map<Id,BSF_Portfolio__c> portfolioMap = new Map<Id,BSF_Portfolio__c>([SELECT Id,Portfolio_Name__c,Parent_Portfolio__c,Parent_Portfolio__r.Portfolio_Code__c,Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Code__c,Parent_Portfolio__r.Portfolio_Type__c,Parent_Portfolio__r.Parent_Portfolio__c,Taxonomy_Type__c,Portfolio_Type__c,Account_Based_Portfolio__c,Territory_Portfolio__c FROM BSF_Portfolio__c WHERE Id IN:bsfIdSet]);
        for(Account_portfolio_assignment__c apa : focusedAccPort)
        {
            if(portfolioMap.get(apa.BSF_Portfolio__c).Portfolio_Type__c == BSF_constants.ACCOUNT_MANAGER &&
               portfolioMap.get(apa.BSF_Portfolio__c).Taxonomy_Type__c != BSF_constants.SUPERVISOR)
            {
                string dmPortfolioCode;
                if(portfolioMap.get(apa.BSF_Portfolio__c).Parent_Portfolio__r.Portfolio_Type__c== BSF_constants.DISTRICT_MANAGER)
                {
                    dmPortfolioCode=portfolioMap.get(apa.BSF_Portfolio__c).Parent_Portfolio__r.Portfolio_Code__c;
                }
                else
                {
                    dmPortfolioCode=portfolioMap.get(apa.BSF_Portfolio__c).Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Code__c;
                }
                accIdPortfolioCodeMap.put(apa.BSF_Portfolio__c,dmPortfolioCode);
            }
        }
        list<BSF_Portfolio__c> accSpecialistPortfolio = [select id,start_date__c,End_date__c,Portfolio_Type__c,Taxonomy_Type__c,Portfolio_Code__c,name from BSF_portfolio__c where Taxonomy_Type__c=:bsf_constants.ACCOUNT_SPECIALIST and Portfolio_Code__c in:accIdPortfolioCodeMap.values()];
        system.debug('accSpecialistPortfolio'+accSpecialistPortfolio);
        map<string,list<BSF_Portfolio__c>> portfCodeBSFPortMap = new map<string,list<BSF_Portfolio__c>>();
        for(BSF_Portfolio__c bsf : accSpecialistPortfolio)
        {
            if(!portfCodeBSFPortMap.containsKey(bsf.Portfolio_Code__c))
                portfCodeBSFPortMap.put(bsf.Portfolio_Code__c,new list<BSF_Portfolio__c>());
            portfCodeBSFPortMap.get(bsf.Portfolio_Code__c).add(bsf);
        }
        map<string,Account_portfolio_assignment__c> accBsfIdAccportAsMap = new map<string,Account_portfolio_assignment__c>();
        list<Account_portfolio_assignment__c> accSpecialistInsertList = new list<Account_portfolio_assignment__c>();
        list<Account_portfolio_assignment__c> accSpecialistInsertActualList = new list<Account_portfolio_assignment__c>();
        list<Account_portfolio_assignment__c> accSpecialistDelList = new list<Account_portfolio_assignment__c>();
        list<Account_portfolio_assignment__c> accSpecialistUpdateList = new list<Account_portfolio_assignment__c>();
        set<string> keyAccPortSet = new set<string>();
        if(!focusedAccPort.isEmpty())
        {
            for(Account_portfolio_assignment__c apa : focusedAccPort)
            {
                if(accIdPortfolioCodeMap.containsKey(apa.BSF_Portfolio__c))
                {
                    string dmPortfolioCode = accIdPortfolioCodeMap.get(apa.BSF_Portfolio__c);
                    if(portfCodeBSFPortMap.containskey(dmPortfolioCode))
                    {
                        for(BSF_Portfolio__c aspBsf :portfCodeBSFPortMap.get(dmPortfolioCode))
                        {
                            BSF_Portfolio__c amBsf = portfolioMap.get(apa.BSF_Portfolio__c);
                            if((aspBsf.Start_Date__c <= apa.Start_Date__c && aspBsf.end_date__c>= apa.Start_Date__c) ||
                               (aspBsf.Start_Date__c <= apa.end_date__c && aspBsf.end_date__c>= apa.end_date__c) )
                            {
                                System.debug('Valid AS '+aspBsf.name);
                                Account_portfolio_assignment__c asApa = new Account_portfolio_assignment__c();
                                asApa.Account__c=apa.Account__c;
                                asApa.BSF_Portfolio__c= aspBsf.id;
                                asApa.Start_Date__c = apa.Start_Date__c;
                                asApa.End_Date__c =  apa.end_date__c;
                                string key =asApa.Account__c+' '+asApa.BSF_Portfolio__c;
                                system.debug('asApa'+asApa);
                                /*if(!keyAccPortSet.contains(key) && accBsfIdAccportMap.containsKey(key))
accSpecialistDelList.add(accBsfIdAccportMap.get(key));*/
                                if(!accBsfIdAccportAsMap.containsKey(key))
                                {
                                    accBsfIdAccportAsMap.put(key,asApa);
                                    system.debug('not contains '+asApa.BSF_Portfolio__r.name+' '+asApa.Start_Date__c+' '+asApa.End_Date__c);
                                }
                                else if(accBsfIdAccportAsMap.containsKey(key) )
                                {
                                    system.debug('contains '+asApa.BSF_Portfolio__r.name+' '+asApa.Start_Date__c+' '+asApa.End_Date__c);
                                    Account_portfolio_assignment__c existingAsAccPort = accBsfIdAccportAsMap.get(key);
                                    system.debug('contains existingAsAccPort'+existingAsAccPort.BSF_Portfolio__r.name+' '+existingAsAccPort.Start_Date__c+' '+existingAsAccPort.End_Date__c);
                                    if(existingAsAccPort.End_Date__c+1 == asApa.start_date__c || (asApa.start_date__c>=existingAsAccPort.start_date__c && asApa.start_date__c<=existingAsAccPort.End_Date__c))
                                    {
                                        system.debug('asApa continues');
                                        existingAsAccPort.End_Date__c =asApa.End_Date__c;
                                        accBsfIdAccportAsMap.put(key,existingAsAccPort);
                                    }
                                    else if(asApa.End_Date__c+1 == existingAsAccPort.start_date__c || (existingAsAccPort.start_date__c>=asApa.start_date__c && existingAsAccPort.start_date__c<=asApa.End_Date__c)  )
                                    {
                                        system.debug('existingAsAccPort continues ');
                                        asApa.End_Date__c = accBsfIdAccportAsMap.get(key).End_Date__c;
                                        accBsfIdAccportAsMap.put(key,asApa);
                                    }
                                    else
                                    {
                                        system.debug('New  '+asApa.name+' '+asApa.Start_Date__c+' '+asApa.End_Date__c);
                                        accSpecialistInsertList.add(asApa);
                                    }
                                    /*if(asApa.Start_Date__c<accBsfIdAccportMap.get(key).start_date__c && asApa.End_Date__c>accBsfIdAccportMap.get(key).start_date__c)
{
accBsfIdAccportMap.get(key).start_date__c =asApa.start_date__c;
}
if(asApa.Start_Date__c<accBsfIdAccportMap.get(key).End_Date__c && asApa.End_Date__c>accBsfIdAccportMap.get(key).End_Date__c)
{
accBsfIdAccportMap.get(key).End_Date__c =asApa.End_Date__c;
}
if(asApa.Start_Date__c>accBsfIdAccportMap.get(key).End_Date__c)
{
}*/
                                }
                                keyAccPortSet.add(key);
                            }
                        }
                    }
                }
            }
            accSpecialistInsertList.addAll(accBsfIdAccportAsMap.values());
        }
        system.debug('accSpecialistInsertList1'+accSpecialistInsertList);
        map<id,list<Account_portfolio_assignment__c>> accIdAccPortList = new map<id,list<Account_portfolio_assignment__c>>();
        for(Account_portfolio_assignment__c apa : accSpecialistInsertList)
        {
            if(accIdexistngAccSpecListMap.containsKey(apa.account__c))
            {
                if(!accIdAccPortList.containsKey(apa.account__c))
                    accIdAccPortList.put(apa.account__c,new list<Account_portfolio_assignment__c>());
                accIdAccPortList.get(apa.account__c).add(apa);
            }
            else
            {
                accSpecialistInsertActualList.add(apa);
            }
        }
        accSpecialistInsertList.clear();
        list<Account_portfolio_assignment__c> newaccPortList = new list<Account_portfolio_assignment__c>();
        for(id accid  :accIdexistngAccSpecListMap.keySet())
        {
            newaccPortList.clear();
            integer i=0;
            boolean updated = true;
            for(Account_portfolio_assignment__c exAp : accIdexistngAccSpecListMap.get(accid))
            {
                if(accIdAccPortList.containsKey(exAp.account__c))
                {
                    newaccPortList=accIdAccPortList.get(exAp.account__c);
                    if(i<=newaccPortList.size()-1)
                    {
                        system.debug('List index '+exAp.BSF_portfolio__r.Name+' '+exAp.Start_Date__c+' '+exAp.End_Date__c);
                        Account_portfolio_assignment__c newAccSpec = newaccPortList[i];
                        if(exAp.Start_Date__c != newAccSpec.Start_Date__c || exAp.End_Date__c != newAccSpec.End_Date__c || exAp.BSF_Portfolio__c != newAccSpec.BSF_Portfolio__c)
                        {
                            system.debug('Updated '+exAp.BSF_portfolio__r.Name+' '+exAp.Start_Date__c+' '+exAp.End_Date__c);
                            system.debug('Updated to'+newAccSpec.BSF_portfolio__r.Name+' '+newAccSpec.Start_Date__c+' '+newAccSpec.End_Date__c);
                            exAp.Start_Date__c = newAccSpec.Start_Date__c;
                            exAp.End_Date__c = newAccSpec.End_Date__c;
                            exAp.BSF_Portfolio__c = newAccSpec.BSF_Portfolio__c;
                            accSpecialistUpdateList.add(exAp);
                            newaccPortList.remove(i);
                        }
                        else if(exAp.Start_Date__c == newAccSpec.Start_Date__c && exAp.End_Date__c == newAccSpec.End_Date__c && exAp.BSF_Portfolio__c == newAccSpec.BSF_Portfolio__c)
                        {
                            system.debug('existing '+exAp.BSF_portfolio__r.Name+' '+exAp.Start_Date__c+' '+exAp.End_Date__c);
                            newaccPortList.remove(i);
                        }
                    }
                    else
                    {
                        system.debug('Deleted '+exAp.BSF_portfolio__r.Name+' '+exAp.Start_Date__c+' '+exAp.End_Date__c);
                        accSpecialistDelList.add(exAp);
                    }
                    if((i+1==accIdexistngAccSpecListMap.get(accid).size() || i+1==newaccPortList.size()) && updated)
                    {
                        system.debug('index reached '+accIdexistngAccSpecListMap.get(accid).size()+' '+newaccPortList.size()+ i);
                        updated = false;
                        accSpecialistInsertActualList.addAll(newaccPortList);
                    }
                    i++;
                }
                else
                {
                    accSpecialistDelList.add(exAp);
                }
            }
        }
        handleSupervisorAPAs(accIdExistngSupAPAMap,focusedAccPort,accSpecialistInsertActualList,accSpecialistUpdateList,accSpecialistDelList);//HRP-12053
        triggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        system.debug('accSpecialistInsertList2'+accSpecialistInsertActualList);
        if(!accSpecialistInsertActualList.isEmpty())
        {
            List<BSF_Error_Log__c> logListInsert = BSF_Utilities.createErrorLog(DataBase.Insert(accSpecialistInsertActualList,false), 'AccountPortfolio Insert','AccountPortfolioAssignmentService','HandleAccountSpecialist','Error','Error in Creating Account Specialist');
            InsertBsfErrorLog.insertBsfErrors(logListInsert);
        }
        if(!accSpecialistUpdateList.isEmpty())
        {
            List<BSF_Error_Log__c> logListUpdate = BSF_Utilities.createErrorLog(DataBase.Update(accSpecialistUpdateList,false), 'AccountPortfolio Update','AccountPortfolioAssignmentService','HandleAccountSpecialist','Error','Error in Updating Account Specialist');
            InsertBsfErrorLog.insertBsfErrors(logListUpdate);
        }
        if(!accSpecialistDelList.isEmpty())
        {
            List<BSF_Error_Log__c> logListDelete = BSF_Utilities.createErrorLog(DataBase.Delete(accSpecialistDelList,false), 'AccountPortfolio Delete','AccountPortfolioAssignmentService','HandleAccountSpecialist','Error','Error in Deleting Account Specialist');
            InsertBsfErrorLog.insertBsfErrors(logListDelete);
        }
        triggerHandler.clearBypass('AccountPortfolioAssignmentTriggerHandler');
        //HRP-11138
        if(trigger.isExecuting && trigger.isDelete)
            accTeamDateSyncOnAccPortUpdates(new list<id>(accountIdSet),null,new Set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ());
        //HRP-11138
    }
    //HRP-6028
    /*
* HRP-12053 changes starts here
* @Description:  called on After insert/Update/Delete from the HandleAccountSpecialist method, creates supervisor account portfolio assignments
* @Date: 02/06/2023
*/
    public static void handleSupervisorAPAs(Map<Id,List<Account_Portfolio_Assignment__c>> accIdExistngSupAPAMap,List<Account_Portfolio_Assignment__c> amAPAs,
                                            List<Account_Portfolio_Assignment__c> apaInsertActualList,List<Account_Portfolio_Assignment__c> apaUpdateList,List<Account_Portfolio_Assignment__c> apaDeleteList)
    {
        Set<String> amPortfolioCodeSet = new Set<String>();
        Map<String,List<BSF_Portfolio__c>> supPortfolioMap = new Map<String,List<BSF_Portfolio__c>>();
        Map<Id,List<Account_Portfolio_Assignment__c>> accIdAPAMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
        Map<Id,List<Account_Portfolio_Assignment__c>> newSupervisorAPAMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
        System.debug('Inside handleSupervisorAPAs method');
        //1.Query Supervisor Taxonomy Data
        for(Account_Portfolio_Assignment__c amAPA:amAPAs){
            amPortfolioCodeSet.add(amAPA.BSF_portfolio__r.Portfolio_Code__c);
            if(!accIdAPAMap.containsKey(amAPA.Account__c)){
                accIdAPAMap.put(amAPA.Account__c,new List<Account_Portfolio_Assignment__c>());
            }
            accIdAPAMap.get(amAPA.Account__c).add(amAPA);
        }
        for(BSF_Portfolio__c supervisorPortfolio :[SELECT Id,Start_Date__c,End_Date__c,Portfolio_Type__c,Taxonomy_Type__c,Portfolio_Code__c,Portfolio_Name__c,Name
                                                   FROM BSF_Portfolio__c WHERE Taxonomy_Type__c=:BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE
                                                   AND Portfolio_Code__c IN :amPortfolioCodeSet Order By Portfolio_Code__c,Start_Date__c]){
                                                       if(!supPortfolioMap.containsKey(supervisorPortfolio.Portfolio_Code__c)){
                                                           supPortfolioMap.put(supervisorPortfolio.Portfolio_Code__c,new List<BSF_Portfolio__c>());
                                                       }
                                                       supPortfolioMap.get(supervisorPortfolio.Portfolio_Code__c).add(supervisorPortfolio);
                                                   }
        System.debug('supPortfolioMap '+supPortfolioMap);
        //2.Prepare Supervisor APAs as per amAPAs
        for(Id accId :accIdAPAMap.keySet()){
            newSupervisorAPAMap.put(accId,new List<Account_Portfolio_Assignment__c>());
            for(Account_Portfolio_Assignment__c amAPA:accIdAPAMap.get(accId)){
                String amPortCode = amAPA.BSF_portfolio__r.Portfolio_Code__c;
                if(!supPortfolioMap.containsKey(amPortCode)){
                    continue;
                }
                for(BSF_Portfolio__c supAMNode:supPortfolioMap.get(amPortCode)){
                    if(supAMNode.End_Date__c < amAPA.Start_Date__c || supAMNode.Start_Date__c > amAPA.End_Date__c){
                        continue;
                    }
                    Account_Portfolio_Assignment__c supAPA = new Account_Portfolio_Assignment__c(Account__c=amAPA.Account__c);
                    supAPA.BSF_Portfolio__c = supAMNode.Id;
                    supAPA.Start_Date__c = supAMNode.Start_Date__c>amAPA.Start_Date__c?supAMNode.Start_Date__c:amAPA.Start_Date__c;
                    supAPA.End_Date__c = supAMNode.End_Date__c < amAPA.End_Date__c?supAMNode.End_Date__c:amAPA.End_Date__c;
                    newSupervisorAPAMap.get(accId).add(supAPA);
                }
            }
        }
        System.debug('accIdExistngSupAPAMap '+accIdExistngSupAPAMap);
        System.debug('newSupervisorAPAMap '+newSupervisorAPAMap);
        //3.Iterate over existing supervior APAs. Add/update/delete as per records prepared in step2 above
        Set<Id> processedAccounts = new Set<Id>();
        for(Id accId :accIdExistngSupAPAMap.keySet()){
            List<Account_Portfolio_Assignment__c> existingSupAPAs = accIdExistngSupAPAMap.get(accId);
            List<Account_Portfolio_Assignment__c> newSupAPAs = newSupervisorAPAMap.get(accId);
            processedAccounts.add(accId);
            if(existingSupAPAs == null){
                existingSupAPAs = new List<Account_Portfolio_Assignment__c>();
            }
            if(newSupAPAs == null){
                newSupAPAs = new List<Account_Portfolio_Assignment__c>();
            }
            Integer index=0;
            for(;index<existingSupAPAs.size();index++){
                Account_Portfolio_Assignment__c existingSupAPA = existingSupAPAs[index];
                if(newSupAPAs.isEmpty() || index >= newSupAPAs.size()){
                    apaDeleteList.add(existingSupAPA);
                }else{
                    if(newSupAPAs[index].BSF_Portfolio__c != existingSupAPA.BSF_Portfolio__c ||
                       newSupAPAs[index].Start_Date__c != existingSupAPA.Start_Date__c ||
                       newSupAPAs[index].End_Date__c != existingSupAPA.End_Date__c){
                           existingSupAPA.BSF_Portfolio__c = newSupAPAs[index].BSF_Portfolio__c;
                           existingSupAPA.Start_Date__c = newSupAPAs[index].Start_Date__c;
                           existingSupAPA.End_Date__c = newSupAPAs[index].End_Date__c;
                           apaUpdateList.add(existingSupAPA);
                       }
                }
            }
            //Add any newAPAs that are not processed above to insert list.
            if(index < newSupAPAs.size()){
                for(;index<newSupAPAs.size();index++){
                    apaInsertActualList.add(newSupAPAs[index]);
                }
            }
        }//account for loop end
        for(Id accId :newSupervisorAPAMap.keySet()){
            if(processedAccounts.contains(accId)){
                continue;
            }
            List<Account_Portfolio_Assignment__c> newSupAPAs = newSupervisorAPAMap.get(accId);
            if(newSupAPAs != null && !newSupAPAs.isEmpty()){
                apaInsertActualList.addAll(newSupAPAs);
            }
        }
    }//HRP-12053 end.
    /*
* HRP-11138 changes starts here
* @Description: trigger method called on After Delete, reverts to default territory on exception delete
* @Date: 02/13/2024
*/
    public static void HandleAccExceptionDelete(List<Account_portfolio_assignment__c> newItems)
    {
        BSF_Constants.skipAccountPortfolioAssignmentDeleteTrigger=true;
        Map<id,Account_portfolio_Assignment__c> accIdAccPortExceptMap = new Map<id,Account_portfolio_Assignment__c>();
        List<String> blockedTaxTypeList = new List<String>{BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE,BSF_Constants.ACCOUNT_SPECIALIST};
            for(Account_portfolio_Assignment__c apa:newItems)
        {
            if(apa.Taxonomy_Type__c==BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE && apa.Account__c!=null)
            {
                accIdAccPortExceptMap.put(apa.account__c,apa);
            }
            else if(blockedTaxTypeList.contains(apa.Taxonomy_Type__c) && !BSF_Constants.isBackEndDelete)
            {
                apa.addError('Default Territory Assignments cannot be deleted. Please contact your admin');
            }
        }
        List<Account> newAccounts = [SELECT Id, Name,BillingPostalCode,Shippingpostalcode FROM Account WHERE Id IN:accIdAccPortExceptMap.keySet()];
        Map<Id,Account> newAccountsMap = new Map<Id,Account>();
        for(Account acc:newAccounts)
        {
            newAccountsMap.put(acc.id,acc);
        }
        List<Account_portfolio_assignment__c> territoryAssignList = AccountService.createAccountTeamMembers(newAccounts, newAccountsMap, 'AccportDelete', null, null);
        Map<Id,List<Account_Portfolio_Assignment__c>> accIdZipAccPortfolioListMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
        for(Account_Portfolio_Assignment__c ap:territoryAssignList)
        {
            if(!accIdZipAccPortfolioListMap.keyset().contains(ap.Account__c)){
                accIdZipAccPortfolioListMap.put(ap.account__c,new List<Account_Portfolio_Assignment__c>());
            }
            accIdZipAccPortfolioListMap.get(ap.Account__c).add(ap);
        }
        Map<Id,Set<id>> accIdBsfIdSetMap = new Map<Id,Set<id>>();
        List<Account_Portfolio_Assignment__c> accPortToInsert = new List<Account_Portfolio_Assignment__c>();
        List<Account_Portfolio_Assignment__c> accPortToUpdate = new List<Account_Portfolio_Assignment__c>();
        List<Account_Portfolio_Assignment__c> accPortToDel = new List<Account_Portfolio_Assignment__c>();
        List<String> taxonomyList = new List<String>{BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE,BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE};
            List<Account_Portfolio_Assignment__c> existingAccPort = [select id,Account__c,Bsf_portfolio__c,Start_Date__c,End_date__c,Bsf_portfolio__r.Taxonomy_type__c from Account_Portfolio_Assignment__c where BSF_Portfolio__r.Taxonomy_Type__c IN:taxonomyList
                                                                     and Account__c IN:accIdAccPortExceptMap.keySet() and BSF_Portfolio__r.Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER order by Account__c,start_date__c];
        Map<Id,List<Account_Portfolio_Assignment__c>> accIdExAccPortfolioListMap = new Map<Id,List<Account_Portfolio_Assignment__c>>();
        for(Account_Portfolio_Assignment__c ap: existingAccPort)
        {
            if(!accIdExAccPortfolioListMap.keyset().contains(ap.Account__c)){
                accIdExAccPortfolioListMap.put(ap.account__c,new List<Account_Portfolio_Assignment__c>());
            }
            accIdExAccPortfolioListMap.get(ap.Account__c).add(ap);
        }
        for(Id accid:accIdAccPortExceptMap.KeySet())
        {
            system.debug('inside loop accid '+accid);
            Integer exAccPortIndex=0;
            Integer terrAccPortIndex=0;
            Integer  zipAccPortIndex=0;
            Boolean updated=false;
            Boolean zipcodeChange = false;
            if(accIdExAccPortfolioListMap.containsKey(accId))
            {
                for(Account_Portfolio_Assignment__c ap:accIdExAccPortfolioListMap.get(accId))
                {
                    system.debug('inside loop ap '+ap);
                    //Deleted exception
                    Account_Portfolio_Assignment__c apaException = new Account_Portfolio_Assignment__c();
                    apaException = accIdAccPortExceptMap.get(accid);
                    system.debug('apaException### '+apaException);
                    //next APA in sequence
                    Account_Portfolio_Assignment__c nextExAccPort;
                    if(exAccPortIndex<accIdExAccPortfolioListMap.get(accId).size()-1)
                    {
                        nextExAccPort=accIdExAccPortfolioListMap.get(accId)[exAccPortIndex+1];
                        system.debug('nextExAccPort### '+nextExAccPort);
                    }
                    Account_Portfolio_Assignment__c prevExAccPort;
                    if(exAccPortIndex==accIdExAccPortfolioListMap.get(accId).size()-1 && exAccPortIndex!=0)
                    {
                        prevExAccPort=accIdExAccPortfolioListMap.get(accId)[exAccPortIndex-1];
                        system.debug('nextExAccPort### '+prevExAccPort);
                    }
                    List<Account_Portfolio_Assignment__c> zipBasedAccPortList= accIdZipAccPortfolioListMap.get(accId);
                    if(ap.End_Date__c==apaException.Start_Date__c-1)
                    {
                        system.debug('Inside apaException.Start_Date__c');
                        if(nextExAccPort!=null)
                        {
                            system.debug('nextExAccPort!=null');
                            if(nextExAccPort.Start_Date__c==apaException.End_Date__c+1)
                            {
                                system.debug('Inside nextExAccPort');
                                if(nextExAccPort.BSF_Portfolio__c==ap.BSF_Portfolio__c)
                                {
                                    system.debug('Inside same');
                                    ap.End_Date__c= nextExAccPort.End_Date__c;
                                    updated=true;
                                    accPortToDel.add(nextExAccPort);
                                }
                                else
                                {
                                    wrapper wrap = new wrapper();
                                    wrap.zipBasedAccPortList=zipBasedAccPortList;
                                    wrap.zipAccPortIndex=zipAccPortIndex;
                                    wrap.apaException=apaException;
                                    wrap.nextExAccPort=nextExAccPort;
                                    zipTerrForException(wrap,accPortToInsert,accPortToUpdate,accPortToDel);
                                }
                            }
                        }
                        else
                        {
                            system.debug('nextExAccPort==null');
                            if(ap.BSF_Portfolio__c == zipBasedAccPortList[zipAccPortIndex].BSF_Portfolio__c)
                            {
                                ap.End_Date__c=zipBasedAccPortList[zipAccPortIndex].End_Date__c;
                                updated=true;
                            }
                            else
                            {
                                zipBasedAccPortList[zipAccPortIndex].start_date__c=apaException.Start_Date__c;
                                accPortToInsert.addAll(zipBasedAccPortList);
                            }
                        }
                        if(updated)
                        {
                            accPortToUpdate.add(ap);
                        }
                        break;
                    }
                    else if(ap.Start_Date__c==apaException.End_Date__c+1)
                    {
                        system.debug('Inside ap.Start_Date__c==apaException.End_Date__c+1');
                        if(prevExAccPort!=null)
                        {
                            if(prevExAccPort.BSF_Portfolio__c==ap.BSF_Portfolio__c)
                            {
                                system.debug('Inside same');
                                ap.Start_Date__c= prevExAccPort.Start_Date__c;
                                updated=true;
                                accPortToDel.add(prevExAccPort);
                            }
                            else
                            {
                                wrapper wrap = new wrapper();
                                wrap.zipBasedAccPortList=zipBasedAccPortList;
                                wrap.zipAccPortIndex=zipAccPortIndex;
                                wrap.apaException=apaException;
                                wrap.nextExAccPort=ap;
                                zipTerrForException(wrap,accPortToInsert,accPortToUpdate,accPortToDel);
                            }
                        }
                        else
                        {
                            if(ap.BSF_Portfolio__c == zipBasedAccPortList[zipAccPortIndex].BSF_Portfolio__c)
                            {
                                ap.Start_Date__c=zipBasedAccPortList[zipAccPortIndex].Start_Date__c;
                                updated=true;
                            }
                            else
                            {
                                zipBasedAccPortList[zipBasedAccPortList.size()-1].End_date__c=apaException.End_date__c;
                                accPortToInsert.addAll(zipBasedAccPortList);
                            }
                        }
                        if(updated)
                        {
                            accPortToUpdate.add(ap);
                        }
                        break;
                    }
                    exAccPortIndex++;
                }
            }
            else
            {
                if(accIdZipAccPortfolioListMap.containsKey(accId))//HRP-13028
                    accPortToInsert.addAll(accIdZipAccPortfolioListMap.get(accId));
            }
        }
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        //HRP-13028 try catch and Error log Platform Event 
        try{
            if(!accPortToInsert.isEmpty())
            {
                Insert accPortToInsert;
            }
            if(!accPortToUpdate.isEmpty())
            {
                Update accPortToUpdate;
            }
            if(!accPortToDel.isEmpty())
            {
                Delete accPortToDel;
            }
        }
        catch (Exception  e)
        {
            List<Error_Log_Event__e> publishEvents = new List<Error_Log_Event__e>();
            Error_Log_Event__e eve = new Error_Log_Event__e();
            eve.RecordId__c =e.getDmlId(0) ;
            eve.Error_Message__c = e.getTypeName()+' '+e.getMessage();
            publishEvents.add(eve);
            if(publishEvents.size()>0)
            {
                EventBus.publish(publishEvents);
            }
            for(Account_portfolio_Assignment__c apa:newItems)
            {
                apa.addError('An error occurred during the Account exception delete, Please share this detail with the Support Team(Object Name: BSF_Error_Log__c, Field Name:Functionality__c).Reference value:'+'ED-'+system.now()+string.valueof(e.getDmlId(0)).substring(10,18));
            }
        }
        finally
        {
            TriggerHandler.clearbypass('AccountPortfolioAssignmentTriggerHandler');
        }
        //HRP-13028 try catch and Error log Platform Event 
    }
    //HRP-11138 End
    /*
* HRP-11138 changes starts here
* @Description: method called from HandleAccExceptionDelete method
* @Date: 02/14/2024
*/
    public static void zipTerrForException(Wrapper wrap,List<Account_Portfolio_Assignment__c>accPortToInsert,List<Account_Portfolio_Assignment__c> accPortToUpdate,List<Account_Portfolio_Assignment__c>accPortToDel)
    {
        system.debug('Inside zipException');
        List<Account_Portfolio_Assignment__c> zipBasedAccPortList=wrap.zipBasedAccPortList;
        Integer zipAccPortIndex=wrap.zipAccPortIndex;
        Account_Portfolio_Assignment__c apaException=wrap.apaException;
        Account_Portfolio_Assignment__c nextExAccPort=wrap.nextExAccPort;
        system.debug('Inside nextExAccPort '+nextExAccPort);
        while(zipBasedAccPortList[zipAccPortIndex].start_date__c>apaException.Start_Date__c)
        {
            if(zipBasedAccPortList.size()-1==zipAccPortIndex)
                break;
            zipAccPortIndex++;
        }
        zipBasedAccPortList[zipAccPortIndex].start_date__c=apaException.Start_Date__c;
        if(zipBasedAccPortList[zipAccPortIndex].End_Date__c>=nextExAccPort.Start_Date__c)
        {
            system.debug('Inside firtone only');
            if(zipBasedAccPortList[zipAccPortIndex].BSF_Portfolio__c==nextExAccPort.BSF_Portfolio__c)
            {
                nextExAccPort.start_Date__c=apaException.Start_Date__c;
                accPortToUpdate.add(nextExAccPort);
            }
            else
            {
                zipBasedAccPortList[zipAccPortIndex].End_Date__c = nextExAccPort.Start_Date__c-1;
                accPortToInsert.add(zipBasedAccPortList[zipAccPortIndex]);
            }
        }
        else
        {
            system.debug('Inside second one too');
            accPortToInsert.add(zipBasedAccPortList[zipAccPortIndex]);
            zipAccPortIndex++;
            if(zipAccPortIndex < zipBasedAccPortList.size()-1)
            {
                zipBasedAccPortList[zipAccPortIndex].End_Date__c = nextExAccPort.Start_Date__c-1;
                accPortToInsert.add(zipBasedAccPortList[zipAccPortIndex]);
            }
        }
    }
    /*
* HRP-11138 changes starts here
* @Description: wrapper for HandleAccExceptionDelete method
* @Date: 02/14/2024
*/
    public class wrapper
    {
        public List<Account_Portfolio_Assignment__c> zipBasedAccPortList;
        public Integer zipAccPortIndex;
        public Account_Portfolio_Assignment__c apaException;
        public Account_Portfolio_Assignment__c nextExAccPort;
    }

    /**
     * Ensure Territory coverage after inserting Account-Based AM APAs.
     * For each Account in pendingAPAs, if there is at least one Account-Based AM (Taxonomy = "Bio Account Portfolio",
     * Portfolio_Type = ACCOUNT_MANAGER) whose End_Date__c is before 4000-12-31
     */
    public static List<Account_Portfolio_Assignment__c> ensureTerritoryCoverage(List<Account_Portfolio_Assignment__c> pendingAMAPAs) {
        System.debug('HRP-15803 ensureTerritoryCoverage: pendingAMAPAs = ' + pendingAMAPAs);
        List<Account_Portfolio_Assignment__c> newTerrApaToBeCreated  = new List<Account_Portfolio_Assignment__c>();//toInsert

        if (pendingAMAPAs == null || pendingAMAPAs.isEmpty()) {
            return newTerrApaToBeCreated;
        }
        //Collect Accounts and BSF Ids from the pending set (we need taxonomy/role)
        Set<Id> accountIds  = new Set<Id>();
        Set<Id> bsfIds  = new Set<Id>();
        for (Account_Portfolio_Assignment__c apa : pendingAMAPAs) {
            if (apa == null) {
                continue;
            }
            if (apa.Account__c != null){
                accountIds.add(apa.Account__c);
            } 
            if (apa.BSF_Portfolio__c != null){
                bsfIds.add(apa.BSF_Portfolio__c);
            } 
        }
        System.debug('HRP-15803 accountIds :  = ' + accountIds );
        System.debug('HRP-15803 bsfIds:  = ' + bsfIds);
        if (accountIds.isEmpty()) {
            return newTerrApaToBeCreated;
        }
        // Collect BSF_Portfolio__c We need taxonomy/role of the referenced BSFs bsfIdVsBsfMap
        Map<Id, BSF_Portfolio__c> bsfIdVsBsfMap = new Map<Id, BSF_Portfolio__c>([
            SELECT Id, Portfolio_Type__c, Taxonomy_Type__c
            FROM BSF_Portfolio__c
            WHERE Id IN :bsfIds
        ]);
        System.debug('HRP-15803 bsfIdVsBsfMap:  = ' + bsfIdVsBsfMap);
        //For the Account, find the latest end among the pending *Account-Based AM* APAs We only care about AMs in the Account taxonomy (i.e., the exception window).
        Map<Id, Date> tailStartByAccount = new Map<Id, Date>(); // Account -> (max pending AB-AM End) + 1
        for (Account_Portfolio_Assignment__c apa : pendingAMAPAs) {
            if (apa == null || apa.Account__c == null || apa.BSF_Portfolio__c == null){ 
                continue;
            }
            BSF_Portfolio__c pendingApaPortfolio = bsfIdVsBsfMap.get(apa.BSF_Portfolio__c);
            if (pendingApaPortfolio == null) {
                continue;
            } 
            if (pendingApaPortfolio.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE && 
                pendingApaPortfolio.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER) {
                if (apa.End_Date__c == null){
                    continue;
                } 
                if (apa.End_Date__c < BSF_Constants.maxDate) {
                    Date newTerrApaStartDate = apa.End_Date__c.addDays(1);//newTerrApaStartDate
                    Date existing =null;
                    if(tailStartByAccount.get(apa.Account__c) !=null){
                        existing = tailStartByAccount.get(apa.Account__c);
                    }
                    if (existing == null || newTerrApaStartDate > existing) {
                        tailStartByAccount.put(apa.Account__c, newTerrApaStartDate);
                    }
                }  
            }
        }
        System.debug('HRP-15803 tailStartByAccount: '+tailStartByAccount);
        if (tailStartByAccount.isEmpty()) {
            return new List<Account_Portfolio_Assignment__c>(); // nothing to do; no AB-AM in this batch
        }
        //3) Get the Account zipCode //acctById
        Map<Id, Account> acctIdVsAccMap = new Map<Id, Account>([
            SELECT Id, BillingPostalCode, ShippingPostalCode
            FROM Account
            WHERE Id IN :accountIds
        ]);
        System.debug('HRP-15803 acctIdVsAccMap: '+acctIdVsAccMap);
        // Build zip set + track min/max tailStart to scope the next queries
        Set<String> zipSet = new Set<String>();
        Date minTail = null;
        Date maxTail = null;
        for (Id accId : tailStartByAccount.keySet()) {
            Account a = acctIdVsAccMap.get(accId);
            String zip = (a != null && !String.isBlank(a.BillingPostalCode)) ? a.BillingPostalCode : null;
            if (String.isBlank(zip)) {
                continue; //skip if no zip (NCA or edge cases)
            }
            zipSet.add(zip);
            if(tailStartByAccount!=null && tailStartByAccount.containsKey(accId)){
                Date t = tailStartByAccount.get(accId);
                if (minTail == null || t < minTail) {
                    minTail = t;
                }
                if (maxTail == null || t > maxTail) {
                    maxTail = t;
                } 
            }
        }
        System.debug('HRP15803 out minTail: '+minTail+'maxTail: '+maxTail);
        System.debug('HRP15803 zipSet: '+zipSet);
        if (zipSet.isEmpty()){
            return newTerrApaToBeCreated;
        } 
        // 4) Pull Taxonomy for those zipCode that overlap any tailStart
        List<Taxonomy__c> taxoRows = [
            SELECT Id, Zip_Code__c, Start_Date__c, End_Date__c, DRD_Territory_Name__c,DRD_Territory_Code__c 
            FROM Taxonomy__c
            WHERE Zip_Code__c IN :zipSet and DRD_Territory_Code__c !=null 
              AND Start_Date__c <= :maxTail
              AND End_Date__c   >= :minTail
        ];
        System.debug('HRP-15803 taxoRows:'+taxoRows);
        // Index taxonomy by zip
        Map<String, List<Taxonomy__c>> taxoByZip = new Map<String, List<Taxonomy__c>>();
        for (Taxonomy__c t : taxoRows) {
            if (String.isBlank(t.Zip_Code__c)){
                continue;
            } 
            if (!taxoByZip.containsKey(t.Zip_Code__c)){
                taxoByZip.put(t.Zip_Code__c, new List<Taxonomy__c>());
            } 
            taxoByZip.get(t.Zip_Code__c).add(t);
        }
        System.debug('HRP-15803 taxoByZip:'+taxoByZip);
        // 5) From the taxonomy windows, collect the territory names we need
        Set<String> territoryNames = new Set<String>();
        Set<String> territoryCodes = new Set<String>();
        for (Id accId : tailStartByAccount.keySet()) {
            Account acc = acctIdVsAccMap.get(accId);
            String zip = (acc != null && !String.isBlank(acc.BillingPostalCode)) ? acc.BillingPostalCode : null;
            if (String.isBlank(zip)) {
                continue;
            }
            Date t = tailStartByAccount.get(accId);
            List<Taxonomy__c> candidates = taxoByZip.get(zip);
            if (candidates == null) {
                continue;
            }
            for (Taxonomy__c row : candidates) {
                if (row.Start_Date__c <= t && row.End_Date__c >= t && !String.isBlank(row.DRD_Territory_Code__c)) {
                    territoryCodes.add(row.DRD_Territory_Code__c);
                    break; // one row is enough
                }
            }
        }
        System.debug('HRP-15803 territoryCodes:'+territoryCodes);
        if (territoryCodes.isEmpty()){
            return newTerrApaToBeCreated;
        } 
        //6) Load Territory AM BSF segments for those territory names that can cover any tailStart
        // We’re matching by Portfolio_Name__c to DRD_Territory_Code__c

        List<BSF_Portfolio__c> terrSegs = [
            SELECT Id, Portfolio_Name__c, Portfolio_Type__c,Portfolio_Code__c, Taxonomy_Type__c,
                   Start_Date__c, End_Date__c
            FROM BSF_Portfolio__c
            WHERE Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER
              AND Taxonomy_Type__c  = :BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE
              AND Portfolio_Code__c  IN :territoryCodes
              AND Start_Date__c     <= :maxTail
              AND End_Date__c       >= :minTail
        ];
        System.debug('HRP-15803 terrSegs:'+terrSegs);
        // Index Territory segments by Territory Name
        Map<String, List<BSF_Portfolio__c>> terrByCode = new Map<String, List<BSF_Portfolio__c>>();
        for (BSF_Portfolio__c seg : terrSegs) {
            if (String.isBlank(seg.Portfolio_Code__c)) {
                continue;
            }
            if (!terrByCode.containsKey(seg.Portfolio_Code__c)){
                terrByCode.put(seg.Portfolio_Code__c, new List<BSF_Portfolio__c>());
            } 
            terrByCode.get(seg.Portfolio_Code__c).add(seg);
        }
        System.debug('HRP-15803 terrByCode:'+terrByCode);
        //7) Existing Territory AM APAs covering any tail window (to avoid duplicates)
        System.debug('HRP-15803 duplicate check maxTail: '+maxTail+':minTail: '+minTail);
        List<Account_Portfolio_Assignment__c> existingTerr = [
            SELECT Id, Account__c, Start_Date__c, End_Date__c, BSF_Portfolio__c,
                    BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Portfolio_Code__c, BSF_Portfolio__r.Taxonomy_Type__c
                    FROM Account_Portfolio_Assignment__c
                    WHERE Account__c IN :accountIds
                    AND BSF_Portfolio__r.Portfolio_Type__c = :BSF_Constants.ACCOUNT_MANAGER
                    AND BSF_Portfolio__r.Taxonomy_Type__c  = :BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE
                    AND End_Date__c   = :BSF_Constants.maxDate];
        System.debug('HRP-15803 1 existingTerr:'+existingTerr);
        
        Map<Id, List<Account_Portfolio_Assignment__c>> existingTerrByAcc = new Map<Id, List<Account_Portfolio_Assignment__c>>();
        for (Account_Portfolio_Assignment__c e : existingTerr) {
            if (!existingTerrByAcc.containsKey(e.Account__c)){
                existingTerrByAcc.put(e.Account__c, new List<Account_Portfolio_Assignment__c>());
            } 
            existingTerrByAcc.get(e.Account__c).add(e);
        }
        System.debug('HRP-15803 existingTerrByAcc:'+existingTerrByAcc);

        //8) Build the new Territory tails
        for (Id accId : tailStartByAccount.keySet()) {
            Date newCoveringTerrApaStartDate = tailStartByAccount.get(accId);
            if (newCoveringTerrApaStartDate == null || newCoveringTerrApaStartDate > BSF_Constants.maxDate) {
                continue;
            }
            Account a = acctIdVsAccMap.get(accId);
            String zip = (a != null && !String.isBlank(a.BillingPostalCode)) ? a.BillingPostalCode : null;
            if (String.isBlank(zip)) {
                continue;
            }
            // Pick the taxonomy row covering tailStart
            Taxonomy__c match = null;
            List<Taxonomy__c> tRows = taxoByZip.get(zip);
            if (tRows != null) {
                for (Taxonomy__c row : tRows) {
                    if (row.Start_Date__c <= newCoveringTerrApaStartDate && row.End_Date__c >= newCoveringTerrApaStartDate) { 
                        match = row; 
                        break; 
                    }
                }
            }
            System.debug('HRP-15803 match:'+match);
            if (match == null || String.isBlank(match.DRD_Territory_Code__c)) {
                continue;
            }
            // Pick Territory BSF segment (AM, Bio Recruitment CD) for that territory name that covers tailStart
            BSF_Portfolio__c seg = null;
            List<BSF_Portfolio__c> segs = terrByCode.get(match.DRD_Territory_Code__c);
            if (segs != null) {
                for (BSF_Portfolio__c s : segs) {
                    if (s.Start_Date__c <= newCoveringTerrApaStartDate && s.End_Date__c >= newCoveringTerrApaStartDate) { 
                        seg = s; 
                        break; 
                    }
                }
            }
            System.debug('HRP-15803 seg:'+seg);
            if (seg == null){
                continue;
            } 
            // If a Territory AM already covers tailStart for this account, skip (no duplicates)
            Boolean covered = false;
            List<Account_Portfolio_Assignment__c> exList = existingTerrByAcc.get(accId);
            System.debug('HRP-15803 exList:'+exList);
            if (exList != null) {
                for (Account_Portfolio_Assignment__c existingTerryBasedAPA : exList) {
                    Boolean overlaps = false;
                    for(Account_Portfolio_Assignment__c newlyInsertedAPA  : pendingAMAPAs){
                        overlaps =  !(newlyInsertedAPA.start_Date__c > existingTerryBasedAPA.Start_Date__c || 
                                        newlyInsertedAPA.end_Date__c > existingTerryBasedAPA.Start_Date__c );
                        if (overlaps) { 
                            break; 
                        }
                    }
                    if (overlaps) { 
                        covered = true; 
                        break; 
                    }
                }
            }
            System.debug('HRP-15803 covered:'+covered);
            if (covered) {
                continue;
            }
            // Create the tail APA (Territory-Based AM)
            Account_Portfolio_Assignment__c tailAPA = new Account_Portfolio_Assignment__c();
            tailAPA.Account__c       = accId;
            tailAPA.BSF_Portfolio__c = seg.Id;
            tailAPA.Start_Date__c    = newCoveringTerrApaStartDate;
            tailAPA.End_Date__c      = BSF_Constants.maxDate;

            newTerrApaToBeCreated.add(tailAPA);
            System.debug('HRP-15803 tailAPA:'+tailAPA);
        }
        System.debug('HRP-15803 newTerrApaToBeCreated:'+newTerrApaToBeCreated);
        return newTerrApaToBeCreated;
    }
}