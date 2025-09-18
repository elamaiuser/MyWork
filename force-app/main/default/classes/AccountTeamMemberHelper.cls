/* 
* @description: This class is called from AccountTeamMember trigger handler.
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 09/20/2023				 Krapy Tuli					 Logic for HRP-10359(Update AM, DM, AM Portfolio and DM Portfolio)
* 01/03/2024				 Krapy Tuli					 Logic for HRP-11777
* 02/20/2024                 Balaji N					 Logic for HRP-11234(blank AM,DM lookups on Account)
* 08/07/2024				 Balaji N					 Logic for HRP-11815(reduced accteam query; unmanaged reason & is_account_managed__c population)
************************************************************************************************************************************************
*/
public  with sharing  class AccountTeamMemberHelper {
    public static Boolean firstRun = true;
    public static Boolean skipAccountTrigger = false;

    /*public static void handleMilitaryMoATaskReassignment(List<AccountTeamMember> accntTeamMembers) {
        Set<Id> accountIds = new Set<Id>();
        for(AccountTeamMember atm : accntTeamMembers) {
            accountIds.add(atm.AccountId);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Account_Manager__c, OwnerId 
            FROM Account 
            WHERE Id IN :accountIds
        ]);

        List<Task> tasksToUpdate = [
            SELECT Id, WhatId, OwnerId 
            FROM Task 
            WHERE WhatId IN :accountIds 
            AND Subject = :Task_Reassignment_Matrix__mdt.getInstance('Renew_Military_MoA').Task_Subject__c            
        ];

        if(!tasksToUpdate.isEmpty()) {
            for(Task t : tasksToUpdate) {
                Account acc = accountMap.get(t.WhatId);
                Id taskOwnerId = acc.Account_Manager__c != null ? acc.Account_Manager__c : acc.OwnerId;
                Id newOwnerId = determineTaskOwner(t.WhatId, taskOwnerId);
                if(newOwnerId != t.OwnerId && newOwnerId != null) {
                    t.OwnerId = newOwnerId;
                }
            }
            update tasksToUpdate;
        }
    }

    public static Id determineTaskOwner(Id accountId, Id ownerId) {
        Date today = Date.today();
        List<AccountTeamMember> accountTeamMembers = [SELECT UserId, TeamMemberRole, Start_Date__c, End_Date__c, Is_Covering_Recruiter__c
                                                      FROM AccountTeamMember 
                                                      WHERE AccountId = :accountId
                                                      AND Start_Date__c <= :today AND End_Date__c >= :today
                                                      ORDER BY TeamMemberRole ASC, Is_Covering_Recruiter__c DESC
                                                      ];
        Map<String, List<AccountTeamMember>> roleToMembersMap = new Map<String, List<AccountTeamMember>>();

        if(accountTeamMembers != null && !accountTeamMembers.isEmpty()) {
            for(AccountTeamMember member : accountTeamMembers) {
                if(!roleToMembersMap.containsKey(member.TeamMemberRole)) {
                    roleToMembersMap.put(member.TeamMemberRole, new List<AccountTeamMember>());
                }
                roleToMembersMap.get(member.TeamMemberRole).add(member);
            }
        }

        List<String> roleHierarchy = new List<String>{BSF_Constants.ACCOUNT_MANAGER, BSF_Constants.ACCOUNT_SPECIALIST, BSF_Constants.DISTRICT_MANAGER};

        for(String role : roleHierarchy) {
            List<AccountTeamMember> membersInRole = roleToMembersMap.get(role);
            if(membersInRole != null && !membersInRole.isEmpty()) { 
                for(AccountTeamMember member : membersInRole) {
                    if(member.Is_Covering_Recruiter__c) {
                        return member.UserId;
                    }
                }
                return membersInRole[0].UserId;
            }
        }
        return ownerId;        
    }*/

   public static void handleMilitaryMoATaskReassignment(List<AccountTeamMember> accntTeamMembers) {
        Set<Id> accountIds = new Set<Id>();
        for (AccountTeamMember atm : accntTeamMembers) {
            if (atm.AccountId != null) accountIds.add(atm.AccountId);
        }
        if (accountIds.isEmpty()) return;

        Date today = Date.today();
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Account_Manager__c, OwnerId,
                   (SELECT UserId, TeamMemberRole, Start_Date__c, End_Date__c, Is_Covering_Recruiter__c
                    FROM AccountTeamMembers
                    WHERE Start_Date__c <= :today AND End_Date__c >= :today
                    ORDER BY TeamMemberRole ASC, Is_Covering_Recruiter__c DESC)
            FROM Account
            WHERE Id IN :accountIds
        ]);

        String subjectKey = Task_Reassignment_Matrix__mdt.getInstance('Renew_Military_MoA').Task_Subject__c;
        List<Task> tasks = [
            SELECT Id, WhatId, OwnerId
            FROM Task
            WHERE WhatId IN :accountIds AND Subject = :subjectKey
        ];
        if (tasks.isEmpty()) return;

        List<Task> toUpdate = new List<Task>();
        for (Task t : tasks) {
            Account acc = accountMap.get(t.WhatId);
            if (acc == null) continue;
            Id taskOwnerId = acc.Account_Manager__c != null ? acc.Account_Manager__c : acc.OwnerId;
            Id newOwner = determineTaskOwner(acc, taskOwnerId);
            if (newOwner != null && newOwner != t.OwnerId) {
                t.OwnerId = newOwner;
                toUpdate.add(t);
            }
        }
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    public static Id determineTaskOwner(Account acc, Id ownerId) {
        if (acc.AccountTeamMembers == null || acc.AccountTeamMembers.isEmpty()) return ownerId;
        
        Map<String, List<AccountTeamMember>> roleMap = new Map<String, List<AccountTeamMember>>();
        for (AccountTeamMember m : acc.AccountTeamMembers) {
            if (!roleMap.containsKey(m.TeamMemberRole)) {
                roleMap.put(m.TeamMemberRole, new List<AccountTeamMember>());
            }
            roleMap.get(m.TeamMemberRole).add(m);
        }
        
        List<String> hierarchy = new List<String>{BSF_Constants.ACCOUNT_MANAGER, BSF_Constants.ACCOUNT_SPECIALIST, BSF_Constants.DISTRICT_MANAGER};
                    
                    for(String role : hierarchy) {
                        List<AccountTeamMember> membersInRole = roleMap.get(role);
                        if(membersInRole != null && !membersInRole.isEmpty()) { 
                            for(AccountTeamMember member : membersInRole) {
                                if(member.Is_Covering_Recruiter__c) {
                                    return member.UserId;
                                }
                            }
                            return membersInRole[0].UserId;
                        }
                    }
        return ownerId;
    }


    /*private static Id determineTaskOwnerBulk(Id accountId, Id fallbackOwnerId, Map<Id, List<AccountTeamMember>> teamMap) {
        List<AccountTeamMember> teamMembers = teamMap.get(accountId);
        if (teamMembers == null || teamMembers.isEmpty()) {
            return fallbackOwnerId;
        }

        Map<String, List<AccountTeamMember>> roleToMembers = new Map<String, List<AccountTeamMember>>();
        for (AccountTeamMember member : teamMembers) {
            if (!roleToMembers.containsKey(member.TeamMemberRole)) {
                roleToMembers.put(member.TeamMemberRole, new List<AccountTeamMember>());
            }
            roleToMembers.get(member.TeamMemberRole).add(member);
        }

        List<String> roleHierarchy = new List<String>{
            BSF_Constants.ACCOUNT_MANAGER,
            BSF_Constants.ACCOUNT_SPECIALIST,
            BSF_Constants.DISTRICT_MANAGER
        };

        for (String role : roleHierarchy) {
            List<AccountTeamMember> members = roleToMembers.get(role);
            if (members != null && !members.isEmpty()) {
                for (AccountTeamMember m : members) {
                    if (m.Is_Covering_Recruiter__c) {
                        return m.UserId;
                    }
                }
                return members[0].UserId;
            }
        }

        return fallbackOwnerId;
    }*/


    
    @InvocableMethod(label='Get Account Team Members' description='Get all the Account Team Members' category='AccountTeamMember')
    public static void getAccountTeamMembers(List<ID> ids) {
        System.debug('getAccountTeamMembers called....');
        Set<id>atmAccountId=new Set<id>();//HRP-11234 collection type changed list to set
        atmAccountId.addAll(ids);
        /*//HRP-11234
         * List<AccountTeamMember> members = [SELECT Id, AccountId,TeamMemberRole,Coverage_Reason__c, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c,Account.Account_Manager__c,Account.District_Manager__c, Account.District_Manager_Portfolio__c, Account.Account_Manager_Portfolio__c, BSF_Portfolio__c FROM AccountTeamMember WHERE Id IN: ids ]; //HRP-10359
        
        for(AccountTeamMember atm: members)
        {
            atmAccountId.add(atm.accountId);
        }*///HRP-11234
        
        List<AccountTeamMember> members =[SELECT Id, AccountId,TeamMemberRole,Coverage_Reason__c, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c, BSF_Portfolio__c,Account.Account_Manager__c,Account.District_Manager__c,Account.District_Manager_Portfolio__c, Account.Account_Manager_Portfolio__c FROM AccountTeamMember WHERE (accountId IN: atmAccountId) and (TeamMemberRole='Account Manager' OR TeamMemberRole='District Manager') AND Start_Date__c <= today AND End_Date__c >=today]; //HRP-10359 //HRP-11815
        
        Map<String,AccountTeamMember> mapOfCoveringTeamMember=new Map<String,AccountTeamMember>();//HRP-11815
        
        List<AccountTeamMember> allTeamListnotCRecruiter = new List<AccountTeamMember>();//HRP-11815 
        for(AccountTeamMember atm:members)
        {
            if(atm.Start_Date__c<= system.today() && system.today() <=atm.End_Date__c)
            {
                //HRP-11815 
                if(atm.Is_Covering_Recruiter__c)
                {
                    mapOfCoveringTeamMember.put(atm.AccountID+atm.TeamMemberRole,atm);
                }
                else
                {
                    allTeamListnotCRecruiter.add(atm);
                }
                //HRP-11815 
            }
         }
        //List<AccountTeamMember> allTeamListnotCRecruiter =[SELECT Id, AccountId,TeamMemberRole, UserId,Start_Date__c,End_Date__c,Is_Covering_Recruiter__c, BSF_Portfolio__c,User.NAme FROM AccountTeamMember WHERE (accountId IN: atmAccountId and Start_Date__c <= today and End_Date__c >=today and Is_Covering_Recruiter__c=false) and (TeamMemberRole='Account Manager' OR TeamMemberRole='District Manager')]; //HRP-10359//HRP-11815 removed query
        Map<Id,AccountTeamMember> defaultAMmap = new Map<Id,AccountTeamMember>();
        Map<String,Id> atmPortfolio = new Map<String,Id>();
        Set<id> amAccIdSet = new Set<Id>();//HRP-11234
        Set<id> dmAccIdSet = new Set<Id>();//HRP-11234
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
                    amAccIdSet.add(atm.accountId);//HRP-11234
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
                            acc.Is_Account_Managed__c = True;//HRP-11815
                            if(atm.BSF_Portfolio__c != null){ //HRP-10359 start
                                acc.Account_Manager_Portfolio__c = atm.BSF_Portfolio__c;
                            } //HRP-10359 end
                            system.debug('entered here4'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                        }else if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)!=Null && acc.Account_Manager__c!=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId)
                        {
                            AmDmLookupUpdatedFlag=True;
                            acc.Account_Manager__c=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId;
                            acc.Is_Account_Managed__c = false;//HRP-11815 
                            acc.Unmanaged__c=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).Coverage_Reason__c=='Leave of Absence (LOA)'?'LOA Vacancy':'Vacant Territory';//HRP-11815 
                            if(atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId) != null){ //HRP-10359 start
                                acc.Account_Manager_Portfolio__c = atmPortfolio.get(atm.TeamMemberRole+'_'+atm.accountId);
                            } //HRP-10359 end
                            system.debug('entered here5'+acc.Is_Account_Managed__c+' '+acc.Unmanaged__c);
                        } 
                        
                    } 
                }
                //Commented part of HRP-11234
                /*else if((atm.Start_Date__c <System.today() && atm.End_Date__c<System.today()) ||(atm.Start_Date__c >System.today() && atm.End_Date__c>System.today()) && atm.Is_Covering_Recruiter__c==true){
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
                }*/ //Commented part of HRP-11234             
            }
            //DM assignment logic
            else if(atm.TeamMemberRole == BSF_Constants.DISTRICT_MANAGER && atm.Start_Date__c <=System.today() && atm.End_Date__c>=System.today() ) 
            {
                dmAccIdSet.add(atm.accountId);//HRP-11234
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
                        
                    }else if(mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole)!=Null && acc.District_Manager__c!=mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId)
                    {
                        AmDmLookupUpdatedFlag=True;
                        acc.District_Manager__c = mapOfCoveringTeamMember.get(atm.AccountiD+atm.TeamMemberRole).UserId; //HRP-10359
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
        //HRP-11234 start
        for(Id accId:atmAccountId)
        {
            system.debug(accId);
            account acc;
            boolean updated=false;
            if(!amAccIdSet.contains(accId))
            {
                acc=(accMap!=null && accMap.containsKey(accId))?accMap.get(accId):new Account(id=accId);
                acc.Account_Manager__c=null;
                accMap.put(acc.id,acc);
            }
            
            if(!dmAccIdSet.contains(accId))
            {
                acc=(accMap!=null && accMap.containsKey(accId))?accMap.get(accId):new Account(id=accId);
                acc.District_Manager__c=null;
                accMap.put(acc.id,acc);
            }
            
            
                
        }
        //HRP-11234 end
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