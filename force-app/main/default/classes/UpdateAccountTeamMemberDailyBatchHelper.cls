/* 
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 01/03/2024				 Krapy Tuli					 Logic for HRP-11777
* 08/07/2024				 Balaji N					 Logic for HRP-11815(reduced accteam query; unmanaged reason & is_account_managed__c population)
************************************************************************************************************************************************
*/
public with sharing class UpdateAccountTeamMemberDailyBatchHelper {
    
    public static void updateAccountTeamMemberLookUps(List<AccountTeamMember> accTeamMemberList){ 
        
        List<id>atmAccountId=new List<id>();
        List<AccountTeamMember> allTeamListnotCRecruiter = new List<AccountTeamMember>();
        List<AccountTeamMember> coveringTeamMemberList = new List<AccountTeamMember>();
        Map<String,AccountTeamMember> mapOfCoveringTeamMember=new Map<String,AccountTeamMember>();
        for(AccountTeamMember atm: accTeamMemberList)
        {
            //HRP-11815 
                if(atm.Is_Covering_Recruiter__c)
                {
                    coveringTeamMemberList.add(atm);
                    mapOfCoveringTeamMember.put(atm.AccountID+atm.TeamMemberRole,atm);
                }
                else
                {
                    allTeamListnotCRecruiter.add(atm);
                }
                //HRP-11815 
            atmAccountId.add(atm.AccountId); 
        }
        
        //List<AccountTeamMember> coveringTeamMemberList =[SELECT Id, AccountId,TeamMemberRole, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,BSF_Portfolio__c FROM AccountTeamMember WHERE (accountId IN: atmAccountId and Start_Date__c <= today and End_Date__c >=today and Is_Covering_Recruiter__c=true) and (TeamMemberRole='Account Manager' OR TeamMemberRole='District Manager')]; //HRP-10359
              /*HRP-11814
        Map<String,AccountTeamMember> mapOfCoveringTeamMember=new Map<String,AccountTeamMember>();
        for(AccountTeamMember atm:coveringTeamMemberList)
        {
            mapOfCoveringTeamMember.put(atm.AccountID+atm.TeamMemberRole,atm.userID);
        }
        */
        //List<AccountTeamMember> allTeamListnotCRecruiter =[SELECT Id, AccountId,TeamMemberRole, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,BSF_Portfolio__c FROM AccountTeamMember WHERE (accountId IN: atmAccountId and Start_Date__c <= today and End_Date__c >=today and Is_Covering_Recruiter__c=false) and (TeamMemberRole='Account Manager' OR TeamMemberRole='District Manager')]; //HRP-10359
        Map<Id,AccountTeamMember> defaultAMmap = new Map<Id,AccountTeamMember>();
        Map<String,Id> atmPortfolio = new Map<String,Id>();  //HRP-10359
        for(AccountTeamMember atm:allTeamListnotCRecruiter){
            if(atm.TeamMemberRole=='Account Manager'){
                defaultAMmap.put(atm.AccountId,atm); //HRP-10359 start
                atmPortfolio.put('Account Manager_'+atm.accountId,atm.BSF_Portfolio__c);
            } else if(atm.TeamMemberRole=='District Manager'){
                atmPortfolio.put('District Manager_'+atm.accountId,atm.BSF_Portfolio__c);
            } //HRP-10359 end
        }
        
        system.debug('mapOfCoveringTeamMember'+mapOfCoveringTeamMember);
        Map<Id, Account> accMap = new Map<Id, Account>();
        
        for(AccountTeamMember atm : accTeamMemberList) 
        {
            Boolean amDmLookupUpdatedFlag=False;
            //if map already has accountid in key assigning the same to account or else creating as new
            account acc=accMap.containskey(atm.accountid)?accMap.get(atm.accountid):new account(Id=atm.accountId);
            system.debug('am: '+acc.Account_Manager__c+' & DM: '+acc.District_Manager__c);
            
            //checking AM and DM presence and assigning accordingly
            if(acc.Account_Manager__c==null && acc.District_Manager__c==null)
            {
                
             acc.Account_Manager__c=atm.Account.Account_Manager__c;
             acc.District_Manager__c=atm.Account.District_Manager__c;
                
            }else if(acc.Account_Manager__c!=null && acc.District_Manager__c==null)
            {
                
             acc.District_Manager__c=atm.Account.District_Manager__c;
                
            }else if(acc.Account_Manager__c==null && acc.District_Manager__c!=null)
            {
               acc.Account_Manager__c=atm.Account.Account_Manager__c;
            }

            if(acc.Account_Manager_Portfolio__c==null && acc.District_Manager_Portfolio__c==null) //HRP-11777 start
            {
                
             acc.Account_Manager_Portfolio__c=atm.Account.Account_Manager_Portfolio__c;
             acc.District_Manager_Portfolio__c=atm.Account.District_Manager_Portfolio__c;
                
            }else if(acc.Account_Manager_Portfolio__c!=null && acc.District_Manager_Portfolio__c==null)
            {
                
             acc.District_Manager_Portfolio__c=atm.Account.District_Manager_Portfolio__c;
                
            }else if(acc.Account_Manager_Portfolio__c==null && acc.District_Manager_Portfolio__c!=null)
            {
               acc.Account_Manager_Portfolio__c=atm.Account.Account_Manager_Portfolio__c;
            } // HRP-11777 end
            
            //AM assignment logic
            if(atm.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER && atm.Start_Date__c <=System.today() && atm.End_Date__c>=System.today() ) 
            {
                if(atm.Start_Date__c <=System.today() && atm.End_Date__c>=System.today()){
                    system.debug('entered here');
                    if(atm.Is_Covering_Recruiter__c==true && (acc.Account_Manager__c != atm.UserId || test.isRunningTest() || (atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) !=null && ( acc.Account_Manager_Portfolio__c == null || (acc.Account_Manager_Portfolio__c != atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId))))) && atm.Coverage_Reason__c =='Leave of Absence (LOA)') //HRP-10359
                    {
                        
                        AmDmLookupUpdatedFlag=True;
                        acc.Account_Manager__c = atm.UserId;
                        acc.Is_Account_Managed__c = false;
                        acc.Unmanaged__c='LOA Vacancy';
                        if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                            acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } //HRP-10359 end
                        system.debug('entered here1'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                    }else if(atm.Is_Covering_Recruiter__c==true && (acc.Account_Manager__c != atm.UserId || test.isRunningTest() || (atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) !=null && ( acc.Account_Manager_Portfolio__c == null || (acc.Account_Manager_Portfolio__c != atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId))))) && atm.Coverage_Reason__c =='Vacant Territory'){ //HRP-10359
                        
                        AmDmLookupUpdatedFlag=True;
                        acc.Account_Manager__c = atm.UserId;
                        acc.Is_Account_Managed__c = false;
                        acc.Unmanaged__c='Territory Vacancy';
                        if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                            acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } //HRP-10359 end
                        system.debug('entered here2'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                        
                    }else if(atm.Is_Covering_Recruiter__c==false) 
                    {
                        system.debug('entered here3');
                        if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)==Null && (acc.Account_Manager__c!=atm.UserId || test.isRunningTest()))
                        {
                            
                            AmDmLookupUpdatedFlag=True;
                            acc.Account_Manager__c=atm.UserId;
                            acc.Unmanaged__c=null;
                            acc.Is_Account_Managed__c = True;//HRP-11815
                            if(atm.BSF_Portfolio__c != null){ //HRP-10359 start
                                acc.Account_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                            } //HRP-10359 end
                            system.debug('entered here4'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                        }else if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)!=Null && (acc.Account_Manager__c!=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId || test.isRunningTest())|| (atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) !=null && ( acc.Account_Manager_Portfolio__c == null || (acc.Account_Manager_Portfolio__c != atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId)))))  //HRP-10359
                        {
                            try{
                                system.debug('mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole) :: '+mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole));
                                system.debug('atmPortfolio.get(atm.TeamMemberRole+_+atm.accountId) :: '+atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId));
                                system.debug('acc.Account_Manager_Portfolio__c :: '+acc.Account_Manager_Portfolio__c);
                                AmDmLookupUpdatedFlag=True;
                                acc.Account_Manager__c=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId;
                                acc.Is_Account_Managed__c = False;
                                acc.Unmanaged__c=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).Coverage_Reason__c=='Leave of Absence (LOA)'?'LOA Vacancy':'Vacant Territory';//HRP-11815;
                                system.debug('entered here5'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                                if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                                    acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                                } //HRP-10359 end
                            }catch (Exception ex) {
                                BSF_Error_Log__c debugLog = new BSF_Error_Log__c();
                                debugLog.ApexClass__c = 'UpdateAccountTeamMemberDailyBatch';
                                debugLog.Method__c = 'UpdateAccountTeamMemberDailyBatch';
                                debugLog.Error_Description__c = String.valueOf(atm.Id); //
                                debugLog.Error_Description_Long__c = ex.getMessage()+ex.getStackTraceString()+ex.getLineNumber();
                                insert debugLog;
                            }
                            
                        } 
                        
                    } 
                }
                //Commented part of HRP-11815
                /*else if(atm.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER && atm.Start_Date__c <=System.today() && atm.End_Date__c>=System.today()){
                    if(defaultAMmap.get(atm.AccountId)!=null){
                       system.debug('defaultAMmap'+defaultAMmap);
                        AmDmLookupUpdatedFlag=True;
                        acc.Account_Manager__c = defaultAMmap.get(atm.AccountId).userId;
                        acc.Is_Account_Managed__c = true;
                        acc.Unmanaged__c=null;
                        if(defaultAMmap.get(atm.AccountId).BSF_Portfolio__c != null){ //HRP-10359 start
                            acc.Account_Manager_Portfolio__c = defaultAMmap.get(atm.AccountId).BSF_Portfolio__c;
                        } //HRP-10359 end 
                        system.debug('entered here222');
                    }else{
                        AmDmLookupUpdatedFlag=True;
                        acc.Is_Account_Managed__c = false;
                        acc.Unmanaged__c=null;  
                    }
                } */ //Commented part of HRP-11234  
                
            }
            //DM assignment logic
            else if(atm.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER && atm.Start_Date__c <=System.today() && atm.End_Date__c>=System.today() ) 
            {
                if(atm.Is_Covering_Recruiter__c==true && (acc.District_Manager__c != atm.UserId || test.isRunningTest() || (atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) !=null && ( acc.Account_Manager_Portfolio__c == null || (acc.Account_Manager_Portfolio__c != atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId)))))) //HRP-10359
                {
                    AmDmLookupUpdatedFlag=True;
                    acc.District_Manager__c = atm.UserId;
                    if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                        acc.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                    } //HRP-10359 end
                }
                else if(atm.Is_Covering_Recruiter__c==false) 
                {
                    if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)==Null && (acc.District_Manager__c!=atm.UserId || test.isRunningTest() || (atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) !=null && ( acc.Account_Manager_Portfolio__c == null || (acc.Account_Manager_Portfolio__c != atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId)))))) //HRP-10359
                    {
                        AmDmLookupUpdatedFlag=True;
                        acc.District_Manager__c = atm.UserId;
                        if(atm.BSF_Portfolio__c != null){ //HRP-10359 start
                            acc.District_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                        } //HRP-10359 end
                    }else if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)!=Null && (acc.District_Manager__c!=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId || test.isRunningTest() || (atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) !=null && ( acc.Account_Manager_Portfolio__c == null || (acc.Account_Manager_Portfolio__c != atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId)))))) //HRP-10359
                    {
                        AmDmLookupUpdatedFlag=True;
                        acc.District_Manager__c = mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId;
                        if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                            acc.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } //HRP-10359 end
                    } 
                }
                }
            // adding the account to the map for further execution
            if(AmDmLookupUpdatedFlag==True)
            {
               accMap.put(atm.AccountId, acc );
            }
          }
        
        /*if(atm.TeamMemberRole == 'Account Manager' && atm.Is_Covering_Recruiter__c==false) 
{	System.debug('Its here:');
accMap.get( atm.AccountId ).Account_Manager__c = atm.UserId;
accMap.get( atm.AccountId ).Is_Account_Managed__c = true;
}
else if(atm.TeamMemberRole == 'District Manager') 
{
accMap.get( atm.AccountId ).District_Manager__c = atm.UserId;
}*/
        if(!accMap.isEmpty()){
        try{
            System.debug('accMap.values(): '+accMap.values());
            Database.update(accMap.values());
        }
        catch(Exception e){
            System.debug('An Error has occured: '+e.getMessage());
        }
        }
    }  
    /*Set<Id> amUserIdSet = new Set<Id>();
Set<Id> portfolioIdSet = new Set<Id>();
Set<Id> DMPortfolioIdSet = new Set<Id>();

Map<Id,AccountTeamMember> accIdAMTeamMemberMap = new Map<Id,AccountTeamMember>();

for(AccountTeamMember teamMember:accTeamMemberList){
accIdAMTeamMemberMap.put(teamMember.AccountId, teamMember);
amUserIdSet.add(teamMember.UserId);
}

List<Portfolio_Assignment__c> UserPortfolioList = [SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE User__c IN:amUserIdSet];
Map<Id,Id> AMuserIdPortfolioMap = new Map<Id,Id>();
for(Portfolio_Assignment__c portfolioAssignment:UserPortfolioList){
if(portfolioAssignment.Start_Date__c == System.today()){
AMuserIdPortfolioMap.put(portfolioAssignment.Id,portfolioAssignment.User__c);
}            
}

List<BSF_Portfolio__c> portfolioList =[SELECT Id,Portfolio_Type__c,Parent_Portfolio__c FROM BSF_Portfolio__c WHERE ID IN:AMuserIdPortfolioMap.keySet()];
Map<Id,Id> dmToAmPortfolioMap = new Map<Id,Id>();
for(BSF_Portfolio__c portfolio:portfolioList){
dmToAmPortfolioMap.put( portfolio.Parent_Portfolio__c,portfolio.Id);
}

List<Portfolio_Assignment__c> DMUserPortfolioList = [SELECT Id,BSF_Portfolio__c,User__c,Start_Date__c,End_Date__c FROM Portfolio_Assignment__c WHERE BSF_Portfolio__c IN:dmToAmPortfolioMap.keySet()];
Map<Id,Id> amToDmUserMap = new Map<Id,Id>();
for(Portfolio_Assignment__c portfolioAssignment:DMUserPortfolioList){
Id amPortfolioId = dmToAmPortfolioMap.get(portfolioAssignment.Id);
Id AMuserId = AMuserIdPortfolioMap.get(amPortfolioId);

amToDmUserMap.put(AMuserId,portfolioAssignment.User__c);
}

Map<Id,Account> accMap = new Map<ID, Account>([SELECT Id,Account_Manager__c,District_Manager__c,Temporary_Account_Manager__c,Is_Account_Managed__c FROM Account WHERE Id IN:accIdAMTeamMemberMap.keySet()]);        
List<Account> accListToUpdate = new List<Account>();
for(Account acc:accMap.values())
{
if(accIdAMTeamMemberMap.get(acc.Id).TeamMemberRole == 'Account Manager'){
acc.Account_Manager__c = accIdAMTeamMemberMap.get(acc.Id).UserId;
acc.Is_Account_Managed__c = true;
}
if(accIdAMTeamMemberMap.get(acc.Id).TeamMemberRole == 'District Manager'){
acc.District_Manager__c = accIdAMTeamMemberMap.get(acc.Id).UserId;
}            
accListToUpdate.add(acc);
}

try{
Database.update(accListToUpdate);
}
catch(Exception e){
System.debug('An Error has occured: '+e.getMessage());
}
}
*/
}