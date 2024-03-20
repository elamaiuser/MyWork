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
            map<String,Account_Portfolio_Assignment__c> supervisorUpdateMap = new map<String,Account_Portfolio_Assignment__c>();
            map<id,String> AccportIdPortfolioCodeMap = new  map<id,String>();
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
                supervisorUpdateMap.put(accPortfolio.BSF_Portfolio__r.Portfolio_code__c+'_'+accPortfolio.Account__c+'_'+accPortfolio.Start_Date__c,accPortfolio);
                
                AccportIdPortfolioCodeMap.put(accPortfolio.id,accPortfolio.BSF_Portfolio__r.Portfolio_code__c);
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
                    
                    
                    
                    
                    
                    // logic change comment HRP-10099 start 
                    //Updating end date of Previous Portfolio and asssociated AccTeams as per new start date
                    /* List<Account_Portfolio_Assignment__c> existPrevAccPortUpdate = new List<Account_Portfolio_Assignment__c>();
List<Account_Portfolio_Assignment__c> existNextAccPortUpdate = new List<Account_Portfolio_Assignment__c>();
if(!existPrevAccPortUpdate.isEmpty())
{
BSF_Constants.skipAccountPortfolioAssignmentTrigger = true;
try
{update existPrevAccPortUpdate;}
catch(exception e)
{System.debug('The exception when updating next close account Portofolio is : '+e);}

Map<id,Account_Portfolio_Assignment__c> existPrevAccPortUpdateMap = new Map<id,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accPortfolio : existPrevAccPortUpdate )
{
existPrevAccPortUpdateMap.put(accPortfolio.Account__c,accPortfolio);
}

if(isAccBasesPortfolioStarted ){
//expireAccountTeamByAccountPortfolio(existPrevAccPortUpdate,existPrevAccPortUpdateMap,'Update of Prev Default AccPortfolioAssign accTeam');
}
}

////Updating Start date of Next Portfolio and asssociated AccTeams as per new start date
if(!existNextAccPortUpdate.isEmpty())
{
BSF_Constants.skipAccountPortfolioAssignmentTrigger = true;
try
{update existNextAccPortUpdate;}
catch(exception e)
{System.debug('The exception when updating next close account Portofolio is : '+e);}

Map<id,Account_Portfolio_Assignment__c> existNextAccPortUpdateMap = new Map<id,Account_Portfolio_Assignment__c>();
for(Account_Portfolio_Assignment__c accPortfolio : existNextAccPortUpdate )
{
existNextAccPortUpdateMap.put(accPortfolio.Account__c,accPortfolio);
}

//expireAccountTeamByAccountPortfolio(existNextAccPortUpdate,existNextAccPortUpdateMap,'Update of Next Default AccPortfolioAssign accTeam');

}*/
                    // logic change comment HRP-10099 End 
                }
                HandleAccountSpecialist(accIdOldAccPortfolioMap.keyset());//HRP-6028
                accTeamDateSyncOnAccPortUpdates(new list<id>(accIdOldAccPortfolioMap.keyset()),null);//HRP-10099
            }
            
        }
    }
    
    
    /* 
* HRP-10099 changes starts here
* @Description: with account Id this method syncs dates in account team based on dates across Account portfolio assignments and Portfolio assignments
* @Date: 06/14/2023
*/
    public static map<string,AccountTeamMember> accTeamDateSyncOnAccPortUpdates (List<id> accountIdList,String calledFromBatch)
    {
        system.debug('Entered accTeamDateSyncOnAccPortUpdates');
        set<string> focusedPortFolioTypeSet = new set<string>{BSF_Constants.ACCOUNT_MANAGER,bsf_constants.SICKLE_CELL_ACCOUNT_MANAGER,Bsf_constants.NATIONAL_ACCOUNT_MANAGER,bsf_constants.Booking_Support,bsf_constants.ACCOUNT_SPECIALIST};//HRP-11290
            List <Account_Portfolio_assignment__c> accportfolioAssignOfAccList = [Select id,Start_date__c,End_Date__c,Account__c,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_code__c,BSF_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Taxonomy_Type__c,BSF_Portfolio__r.portfolio_type__c from Account_Portfolio_assignment__c where Account__c IN:accountIdList and BSF_Portfolio__r.Portfolio_type__c in:focusedPortFolioTypeSet order by Account__c, start_Date__c];//HRP-11290 added BSF_Portfolio__r.Portfolio_type__c in:focusedPortFolioTypeSet
        
        
        set<id> bsfIdsSet=new set<id>();
        for(Account_Portfolio_assignment__c ap:accportfolioAssignOfAccList)
        {
            bsfIdsSet.add(ap.BSF_Portfolio__c);
            system.debug('ap.BSF_Portfolio__c'+ap.BSF_Portfolio__c);
            if(ap.BSF_Portfolio__r.portfolio_type__c==BSF_Constants.ACCOUNT_MANAGER)//11290 check for AM node
            {
                bsfIdsSet.add(ap.BSF_Portfolio__r.Parent_Portfolio__c);
                bsfIdsSet.add(ap.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c);
            }
        }
        
        
        
        List<AccountTeamMember> teamMembersList = [SELECT Id,BSF_Portfolio__c,UserId,TeamMemberRole,AccountId,Start_Date__c,End_Date__c,BSF_Portfolio__r.Taxonomy_Type__c,user.name FROM AccountTEamMember WHERE AccountId IN:accountIdList and Is_Covering_Recruiter__c=false order by accountid];
        List <Account_Portfolio_assignment__c> accPortUpdateList = new List <Account_Portfolio_assignment__c>();
        Map <string,AccountTeamMember> accTeamMap = new Map <string,AccountTeamMember>();
        for(AccountTeamMember teamMember:teamMembersList)
        {
            accTeamMap.put(teamMember.accountId+'_'+teamMember.userId,teamMember);
        }
        
        
        List<Portfolio_Assignment__c> portfolioAssignList = [Select id,Start_date__c,End_Date__c,BSF_Portfolio__c,Assignment_Type__c,bsf_portfolio__r.Taxonomy_type__c,User__r.Name from Portfolio_Assignment__C where BSF_Portfolio__c IN:bsfIdsSet order by start_Date__c,BSF_Portfolio__c,user__c];
        map<string,accountTeamMember> accIdUserDate = new map<string,accountTeamMember>();//HRP-8897 map value changed from list of dates to AccountTeamMember
        Map <string,Portfolio_Assignment__c> portfolioUserMap = new Map <string,Portfolio_Assignment__c>();
        
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
                        system.debug('u name'+pa.User__r.name);
                        system.debug(startDate);
                        system.debug(endDate);
                        
                        string key =apa.account__c+'_'+pa.user__c;
                        if(accIdUserDate.keyset().contains(key))
                        {
                            atm=accIdUserDate.get(key);
                            if(startDate <= atm.End_Date__c+1 && atm.TeamMemberRole == pa.Assignment_Type__c)
                            {
                                system.debug('startDate <= atm.End_Date__c+1 '+pa.Assignment_Type__c+' '+ atm+startDate+'_'+atm.End_Date__c);
                                //startDate = accIdUserDate.get(key).get(0);
                                atm.End_Date__c = endDate;
                                
                                
                                
                            }
                            
                            else if(atm.End_Date__c<system.today() || (atm.End_Date__c>system.today() && startDate<atm.Start_Date__c && endDate<atm.Start_Date__c && endDate >system.today()))
                            {
                                system.debug('atm.End_Date__c<system.today() '+pa.Assignment_Type__c+' '+ atm+startDate+'_'+atm.End_Date__c);
                                atm.start_date__c = startDate;
                                atm.End_Date__c = endDate;
                                atm.TeamMemberRole = pa.Assignment_Type__c;
                                system.debug('EndDate<Today'+'accIdUserDate.get()'+pa.user__r.name+'__'+accIdUserDate.get(key));
                            }
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
                            system.debug('Dates___'+'accIdUserDate.get()'+pa.user__r.name+'__'+accIdUserDate.get(key));
                        }
                        portfolioUserMap.put(key,pa);
                    }
                }
                
            }
            
        }
        
        
        system.debug('accIdUserDate'+accIdUserDate);
        set <AccountTeamMember> accTeamUpdateSet = new set <AccountTeamMember>();
        for(String accUserKey:accIdUserDate.keyset())
        {
            string Key = accUserKey;
            AccountTeamMember existAcctm = new accountTeamMember();
            AccountTeamMember correctAcctm = new accountTeamMember();//HRP-8897
            //TEAM ALREADY THERE CHECKING FOR CORRECT DATES AND UPDATING
            if(accTeamMap.containskey(Key) )
            {
                //HRP-8897
                existAcctm=accTeamMap.get(accUserKey);
                correctAcctm = accIdUserDate.get(key);
                boolean Updated = false;
                if((existAcctm.Start_Date__c != correctAcctm.Start_Date__c) ||
                   (existAcctm.End_Date__c != correctAcctm.End_Date__c )	||
                   (existAcctm.BSF_Portfolio__c != correctAcctm.BSF_Portfolio__c ) ||
                   (existAcctm.TeamMemberRole != correctAcctm.TeamMemberRole ))
                {
                    Updated = true;
                }
                
                
                if(Updated)
                {
                    accTeamUpdateSet.add(correctAcctm);
                }
                //HRP-8897
            }
            // TEAM DOESN'T EXISTS CREATING NEW
            else
            {
                AccountTeamMember atm = new accountTeamMember();
                atm=accIdUserDate.get(key);
                accTeamUpdateSet.add(atm);
                system.debug('illai'+atm);
            }
        }
        
        list<string> accTeamRoleList = new list<string>{BSF_constants.ACCOUNT_MANAGER,BSF_constants.AREA_BOOKING_MANAGER,BSF_constants.DISTRICT_MANAGER,BSF_constants.SUPERVISOR};
            List <AccountTeamMember> atmToDeleteList = new List <AccountTeamMember>();
        for(String atmKey:accTeamMap.keyset())
        {
            AccountTeamMember atm = new accountTeamMember();
            atm=accTeamMap.get(atmKey);
            if(!accIdUserDate.containskey(atmKey) || (accIdUserDate.containskey(atmKey) && accIdUserDate.get(atmKey).end_Date__c<System.today()))//HRP-11290 removed role check from accTeamRoleList
            {
                atmToDeleteList.add(accTeamMap.get(atmKey));        
            }
        }
        
        
        
        if(!atmToDeleteList.isEmpty())
        {
            database.delete(atmToDeleteList,false);
        }
        if(calledFromBatch != BSF_constants.BYPASS_TEAMDML)
        {
            if(accTeamUpdateSet.size()>0)
            {
                List<AccountTeamMember> teamMemberListToInsert = new List<AccountTeamMember>();
                
                teamMemberListToInsert.addAll(accTeamUpdateSet);
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
                database.SaveResult [] srlist =Database.Insert(teamMemberListToInsert,false);
                bsf_constants.isdateCheckbeforeInsertUpdate = true;//HRP-8897 bypasses date validation from AccountTeamTriggerHandler method call dateCheckbeforeInsertUpdate
                List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srlist,'Create Portfolio','AccountPortfolioAssignmentService','accTeamDateSyncOnAccPortUpdates','Error','sync accteam dates');
                InsertBsfErrorLog.insertBsfErrors(logList);
                
            }
        }
        return accIdUserDate;
    }
    /*
* HRP-10099 changes Ends
*/
    
    
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
        
        map<id,list<BSF_Portfolio__c>> accIdBsfPortfolioListMap = new map<id,list<BSF_Portfolio__c>>();
        for(Account_Portfolio_Assignment__c ap:newItems)
        {
            if(!accIdBsfPortfolioListMap.keyset().contains(ap.account__c))
                accIdBsfPortfolioListMap.put(ap.account__c,new list<BSF_Portfolio__c>());
            
            if(bsfIdMap!= null && bsfIdMap.keyset().contains(ap.BSF_Portfolio__c))
                accIdBsfPortfolioListMap.get(ap.account__c).add(bsfIdMap.get(ap.BSF_Portfolio__c));
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
            list<BSF_Portfolio__c> bsfList = new list<BSF_Portfolio__c>();
            if(accIdBsfPortfolioListMap!= null && accIdBsfPortfolioListMap.keyset().contains(accId))
            {
                system.debug('bsfList populated');
                bsfList = accIdBsfPortfolioListMap.get(accId);
            }
            
            Date currentDate = system.today();
            Date EndDate;
            for(Account_Portfolio_Assignment__c ap: accIdAccPortfolioListMap.get(accId))
            {
                String key;
                if(ap.BSF_Portfolio__r.Taxonomy_Type__c!=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
                {
                    EndDate =ap.End_Date__c;
                    if(ap.BSF_Portfolio__r.Taxonomy_Type__c ==BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE)
                    {
                        system.debug(BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE);
                        if(ap.start_date__c <= currentDate && currentDate <= ap.End_date__c)
                        {
                            bsfTrackerSet.add(bsfList[bsfPOrtfolioIndex].id);
                            system.debug('current assignment');
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
                            
                        }
                        else if(ap.start_date__c > currentDate && bsfList[bsfPOrtfolioIndex].start_date__c <= ap.start_date__c && bsfList[bsfPOrtfolioIndex].end_date__c >= ap.start_date__c)
                        {
                            system.debug('future assignment');
                            key=ap.Account__c+'_'+ap.BSF_Portfolio__r.portfolio_code__c+'_'+ap.Start_Date__c; 
                            bsfTrackerSet.add(bsfList[bsfPOrtfolioIndex].id);
                            
                            ap.bsf_portfolio__c=bsfList[bsfPOrtfolioIndex].Id;
                            ap.end_date__c = ap.end_date__c <= bsfList[bsfPOrtfolioIndex].end_date__c?ap.end_Date__c:bsfList[bsfPOrtfolioIndex].end_date__c;
                            EndDate =ap.end_date__c;
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
                                        EndDate =ap.end_date__c;
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
                        }
                        
                    }
                    
                    
                    
                    
                }
                
                
            }
            
            system.debug('bsfTrackerSet '+bsfTrackerSet);
            
            
            
            
            
            
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
                        apa.start_date__c=EndDate+1;
                        apa.End_date__c=bsf.End_date__c;
                        EndDate =apa.end_date__c;
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
            }
        }
        
        
        
        
        system.debug('accPortAssignInsertListHandle'+accPortAssignInsertList);
        triggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        for(Account_Portfolio_Assignment__c apa:accPortAssignInsertList)
        {
            system.debug('accPortAssignInsertList'+apa);
        }
        
        if(!accPortAssignInsertList.isEmpty())
        {
            Database.Insert (accPortAssignInsertList,false);
        }
        
        if(!accPortAssignUpdateList.isEmpty())
        {
            Database.Update (accPortAssignUpdateList,false);
        }
        if(!supDelList.isEmpty())
        {
            system.debug('supDelList'+supDelList);
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
        list<Account_portfolio_assignment__c> allRelAccPort = [select id,start_Date__c,End_date__c,BSF_portfolio__c,Account__c,BSF_portfolio__r.Taxonomy_Type__c,BSF_portfolio__r.Name from Account_portfolio_assignment__c where account__c in :accountIdSet and BSF_portfolio__r.Portfolio_Type__c in :new list<string>{bsf_constants.ACCOUNT_SPECIALIST,bsf_constants.ACCOUNT_MANAGER} and bsf_portfolio__r.Taxonomy_Type__c<>:bsf_constants.TAXO_SUPERVISOR_RECORD_TYPE order by Account__c,Start_date__c];
        Map<id,list<Account_portfolio_assignment__c>> accIdexistngAccSpecListMap = new Map<id,list<Account_portfolio_assignment__c>>();
        list<Account_portfolio_assignment__c> focusedAccPort = new list<Account_portfolio_assignment__c>();
        
        for(Account_portfolio_assignment__c allApa:allRelAccPort)
        {
            if(allApa.BSF_portfolio__r.Taxonomy_Type__c != bsf_constants.ACCOUNT_SPECIALIST )//excludes specialist updates
            {
                bsfIdSet.add(allApa.BSF_Portfolio__c);
                focusedAccPort.add(allApa);
            }
            else if(allApa.BSF_portfolio__r.Taxonomy_Type__c == bsf_constants.ACCOUNT_SPECIALIST)
            {
                string key =allApa.Account__c+' '+allApa.BSF_Portfolio__c;
                if(!accIdexistngAccSpecListMap.containsKey(allApa.account__c))
                    accIdexistngAccSpecListMap.put(allApa.Account__c,new list<Account_portfolio_assignment__c>());
                
                accIdexistngAccSpecListMap.get(allApa.Account__c).add(allApa);                
            }
            
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
            
        }
        //HRP-6028
    }