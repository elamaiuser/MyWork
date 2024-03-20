/* 
* @description: This class is called from AccountTeamMember trigger handler.
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 09/20/2023				 Krapy Tuli					 Logic for HRP-10359(Update AM, DM, AM Portfolio and DM Portfolio)
* 01/03/2024				 Krapy Tuli					 Logic for HRP-11777
************************************************************************************************************************************************
*/
public  with sharing  class AccountTeamMemberHelper {
    public static Boolean firstRun = true;
    public static Boolean skipAccountTrigger = false;
    
    @InvocableMethod(label='Get Account Team Members' description='Get all the Account Team Members' category='AccountTeamMember')
    public static void getAccountTeamMembers(List<ID> ids) {
        System.debug('getAccountTeamMembers called....');
        List<AccountTeamMember> members = [SELECT Id, AccountId,TeamMemberRole,Coverage_Reason__c, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,Account.Account_Manager__c,Account.District_Manager__c, Account.District_Manager_Portfolio__c, Account.Account_Manager_Portfolio__c, BSF_Portfolio__c FROM AccountTeamMember WHERE Id IN: ids ]; //HRP-10359
        List<id>atmAccountId=new List<id>();
        for(AccountTeamMember atm: members)
        {
            atmAccountId.add(atm.accountId);
        }
        
        List<AccountTeamMember> atmToCompareList =[SELECT Id, AccountId,TeamMemberRole, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c, BSF_Portfolio__c FROM AccountTeamMember WHERE (accountId IN: atmAccountId and Start_Date__c <= today and End_Date__c >=today and Is_Covering_Recruiter__c=true) and (TeamMemberRole='Account Manager' OR TeamMemberRole='District Manager')]; //HRP-10359
        
        Map<String,id> mapOfCoveringTeamMember=new Map<String,id>();
        
        
        for(AccountTeamMember atm:atmToCompareList)
        {
            mapOfCoveringTeamMember.put(atm.AccountID+atm.TeamMemberRole,atm.userID);
        }
        List<AccountTeamMember> allTeamListnotCRecruiter =[SELECT Id, AccountId,TeamMemberRole, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c, BSF_Portfolio__c FROM AccountTeamMember WHERE (accountId IN: atmAccountId and Start_Date__c <= today and End_Date__c >=today and Is_Covering_Recruiter__c=false) and (TeamMemberRole='Account Manager' OR TeamMemberRole='District Manager')]; //HRP-10359
        Map<Id,AccountTeamMember> defaultAMmap = new Map<Id,AccountTeamMember>();
        Map<String,Id> atmPortfolio = new Map<String,Id>();
        for(AccountTeamMember atm:allTeamListnotCRecruiter){
            if(atm.TeamMemberRole=='Account Manager'){
                defaultAMmap.put(atm.AccountId,atm);
                atmPortfolio.put('Account Manager_'+atm.accountId,atm.BSF_Portfolio__c); //HRP-10359 start
            } else if(atm.TeamMemberRole=='District Manager'){
                atmPortfolio.put('District Manager_'+atm.accountId,atm.BSF_Portfolio__c);
            } //HRP-10359 end
        }
        
        
        Map<Id,Account> accMap = new Map<Id, Account>();
        for(AccountTeamMember atm : members) 
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
            } //HRP-11777 end
            
            //AM assignment logic
            if(atm.TeamMemberRole == BSF_Constants.ACCOUNT_MANAGER  ) 
            {
                if(atm.Start_Date__c <=System.today() && atm.End_Date__c>=System.today()){
                    system.debug('entered here');
                    if(atm.Is_Covering_Recruiter__c==true && acc.Account_Manager__c != atm.UserId && atm.Coverage_Reason__c =='Leave of Absence (LOA)')
                    {
                        
                        AmDmLookupUpdatedFlag=True;
                        acc.Account_Manager__c = atm.UserId; 
                        acc.Is_Account_Managed__c = false;
                        acc.Unmanaged__c='LOA Vacancy';
                        if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                            acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                        } //HRP-10359 end
                        system.debug('entered here1'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                    }else if(atm.Is_Covering_Recruiter__c==true && acc.Account_Manager__c != atm.UserId && atm.Coverage_Reason__c =='Vacant Territory'){
                        
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
                        if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)==Null && (acc.Account_Manager__c!=atm.UserId || acc.Account_Manager_Portfolio__c==null)) //HRP-10359
                        {
                            
                            AmDmLookupUpdatedFlag=True;
                            acc.Account_Manager__c=atm.UserId;
                            acc.Unmanaged__c=null;
                            if(atm.BSF_Portfolio__c != null){ //HRP-10359 start
                                acc.Account_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                            } //HRP-10359 end
                            system.debug('entered here4'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                        }else if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)!=Null && acc.Account_Manager__c!=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole))
                        {
                            AmDmLookupUpdatedFlag=True;
                            acc.Account_Manager__c=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole);
                            acc.Is_Account_Managed__c = true;
                            acc.Unmanaged__c=null;
                            if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                                acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            } //HRP-10359 end
                            system.debug('entered here5'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                        } 
                        
                    } 
                }else if((atm.Start_Date__c <System.today() && atm.End_Date__c<System.today()) ||(atm.Start_Date__c >System.today() && atm.End_Date__c>System.today()) && atm.Is_Covering_Recruiter__c==true){
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
                }              
            }
            //DM assignment logic
            else if(atm.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER && atm.Start_Date__c <=System.today() && atm.End_Date__c>=System.today() ) 
            {
                if(atm.Is_Covering_Recruiter__c==true && acc.District_Manager__c != atm.UserId)
                {
                    AmDmLookupUpdatedFlag=True;
                    acc.District_Manager__c = atm.UserId;
                    if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                        acc.District_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                    } //HRP-10359 end
                }
                else if(atm.Is_Covering_Recruiter__c==false) 
                {
                    if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)==Null && acc.District_Manager__c!=atm.UserId)
                    {
                        AmDmLookupUpdatedFlag=True;
                        acc.District_Manager__c = atm.UserId;
                        if(atm.BSF_Portfolio__c != null){ //HRP-10359 start
                            acc.District_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                        } //HRP-10359 end
                        
                    }else if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)!=Null && acc.District_Manager__c!=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole))
                    {
                        AmDmLookupUpdatedFlag=True;
                        acc.District_Manager__c = mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole); //HRP-10359
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
        /*else if(atm.TeamMemberRole == BSF_Constants.TEMPORARY_ACCOUNT_MANAGER && atm.Start_Date__c <=System.today()) 
{
accMap.get( atm.AccountId ).Temporary_Account_Manager__c = atm.UserId;
accMap.get( atm.AccountId ).Is_Account_Managed__c = true;
}*/
        
        try{
            system.debug( 'acc map :' + accMap );
        AccountTeamMemberHelper.skipAccountTrigger = true;
        System.debug('AccountTeamMemberHelper.skipAccountTrigger: '+AccountTeamMemberHelper.skipAccountTrigger);
        update accMap.values();
        } catch(exception exp){
            system.debug('error message '+exp.getMessage());
        }
        
        
    }
    
    //Below code which was running from Trigger, commented and pasted to AccountTeamMemberService class
    
    /*     public static void createAccountTeamMemberHistoryRecords(List<AccountTeamMember> newAccountTeamMembers){
List<Team_Member_History__c> teamMemberHistoryList = new  List<Team_Member_History__c>();

if(newAccountTeamMembers.size()>0){
for(AccountTeamMember teamMember:newAccountTeamMembers){
Team_Member_History__c historyRecord = new Team_Member_History__c();
historyRecord.Account__c = teamMember.AccountId;
historyRecord.Team_Member__c = teamMember.UserId;
if(teamMember.Start_Date__c!=null){
historyRecord.Start_Date__c = teamMember.Start_Date__c;
}
else{
historyRecord.Start_Date__c = System.today();
}
teamMemberHistoryList.add(historyRecord);
}
}

Database.insert(teamMemberHistoryList);

}

public static void populateEndDateOnAccountTeamMemberHistoryRecords(List<AccountTeamMember> deletedMappings, Map<ID, AccountTeamMember> MappingMap){

System.debug('Entered populateEndDateOnAccountTeamMemberHistoryRecords');
System.debug('MappingMap: '+MappingMap.keySet());
Set<Id> userIdList = new Set<Id>(); 
Set<Id> accIdList = new Set<Id>();
List<Team_Member_History__c> teamMemberHistoryListToUpdate = new List<Team_Member_History__c>();

for(AccountTeamMember teamMember:deletedMappings){
userIdList.add(teamMember.UserId); 
accIdList.add(teamMember.AccountId);
}

List<Team_Member_History__c> teamMemberHistoryList = [SELECT Id,Account__c,Team_Member__c,Start_Date__c,End_Date__c FROM Team_Member_History__c WHERE Team_Member__c IN:userIdList AND Account__c IN:accIdList];

System.debug('teamMemberHistoryList to Update after delete: '+teamMemberHistoryList);
if(teamMemberHistoryList.size()>0){
for(Team_Member_History__c memberHistory:teamMemberHistoryList){
memberHistory.End_Date__c =  system.today();
teamMemberHistoryListToUpdate.add(memberHistory);
}
}

Database.update(teamMemberHistoryListToUpdate);
} */
}