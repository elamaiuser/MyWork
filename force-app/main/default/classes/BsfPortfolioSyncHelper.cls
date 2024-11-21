public class BsfPortfolioSyncHelper 
{
    public static void correctTeamBSFPorfolioOnAccPortfolioStartDate(Map<Id,Account_Portfolio_Assignment__c> accIdAccPortfolioMap)
    {
        
        list<Account_Portfolio_Assignment__c> existingAccPortAssg = [select id, Account__c,Portfolio_Type__c,start_Date__c,End_Date__c,Bsf_Portfolio__c,Bsf_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,Bsf_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,Bsf_Portfolio__r.Portfolio_Code__c,BSF_Portfolio__r.Taxonomy_Type__c from Account_Portfolio_Assignment__c where Account__c IN:accIdAccPortfolioMap.keyset()];
        system.debug('accIdAccPortfolioMap'+existingAccPortAssg);
        Map<string,Account_Portfolio_Assignment__c> bsfidAccPortfolioMap = new Map<string,Account_Portfolio_Assignment__c>();
        set<id> bsfidSet = new set<id>();
        set<string> portfolioCodeSet = new set<string>();
        map<id,id> accIdSupervisor = new map<id,id>();
        map<id,List<id>> accIdbsfIdListMap = new map<id,List<id>>();
        for(Account_Portfolio_Assignment__c ap: existingAccPortAssg)
        {
            if(ap.start_Date__c == system.today() || ap.start_Date__c == system.today()-1)
            {
                if(ap.BSF_Portfolio__r.Taxonomy_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE 
                   || ap.BSF_Portfolio__r.Taxonomy_Type__c == BSF_Constants.TAXO_ACCOUNT_RECORD_TYPE)
                {
                    system.debug('Its Acc/Terri');
                bsfidSet.add(ap.Bsf_Portfolio__c);
                portfolioCodeSet.add(ap.Bsf_Portfolio__r.Portfolio_Code__c);
                if(ap.bsf_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'Area Booking Manager')
                {
                    accIdbsfIdListMap.put(ap.Account__c,new List<id>{ap.bsf_Portfolio__c,ap.bsf_Portfolio__r.Parent_Portfolio__c,ap.bsf_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c});
                }
                else
                {
                    accIdbsfIdListMap.put(ap.Account__c,new List<id>{ap.bsf_Portfolio__c,ap.bsf_Portfolio__r.Parent_Portfolio__c});
                }
                }
                if(ap.BSF_Portfolio__r.Taxonomy_Type__c == BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE && ap.BSF_Portfolio__r.Portfolio_Type__c == BSF_Constants.ACCOUNT_MANAGER )
                {
                    system.debug('Its supv');
                    accIdSupervisor.put(ap.Account__c,ap.BSF_Portfolio__r.Parent_Portfolio__c);
                    bsfidSet.add(ap.Bsf_Portfolio__r.Parent_Portfolio__c);
                }
                bsfidAccPortfolioMap.put(ap.account__c+'_'+ap.bsf_Portfolio__c,ap);
            }
            }
        
        map<id,bsf_Portfolio__c> BSfPortfolioMap =new map<id,bsf_Portfolio__c>([SELECT Id,Portfolio_Type__c,
                                                                                Parent_Portfolio__c,
                                                                                Parent_Portfolio__r.Parent_Portfolio__c
                                                                                FROM BSF_Portfolio__c
                                                                                WHERE Id IN:bsfidSet]);
        
        system.debug('BSfPortfolioMap: '+BSfPortfolioMap);
        for(Account_Portfolio_Assignment__c ap: existingAccPortAssg)
        {
            if(bsfidSet.contains(ap.bsf_Portfolio__c) && ap.BSF_Portfolio__r.Taxonomy_Type__c != BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE)
            {
            bsf_Portfolio__c bsf = new bsf_Portfolio__c();
            bsf = BSfPortfolioMap.get(ap.bsf_Portfolio__c);
            system.debug('bsf: '+bsf);
            bsfidSet.add(ap.bsf_Portfolio__c);
            bsfidSet.add(bsf.Parent_Portfolio__c);
            bsfidSet.add(bsf.Parent_Portfolio__r.Parent_Portfolio__c);
            }
        }
        
        
        
        List<Portfolio_Assignment__c> portfolioAssigmtList = [select id,Bsf_Portfolio__c,User__c,start_Date__c,End_Date__c from Portfolio_Assignment__c where Bsf_Portfolio__c IN:bsfidSet and End_Date__c > = Today];
        system.debug('portfolioAssigmtList: '+portfolioAssigmtList);
        map<id,List<id>> bsfIdUserMap = new map<id,List<id>>();
        set<id> userIdSet = new set<id>();
        map<String,Portfolio_Assignment__c> userBSfIDPortAssgnMap = new map<String,Portfolio_Assignment__c>();
        for(Portfolio_Assignment__c pa : portfolioAssigmtList)
        {
            if(bsfIdUserMap.keyset().contains(pa.bsf_Portfolio__c))
            {
                bsfIdUserMap.get(pa.bsf_Portfolio__c).add(pa.User__c);
                system.debug('bsfIdUserMap: '+bsfIdUserMap);
            }
            else
            {
                bsfIdUserMap.put(pa.bsf_Portfolio__c,new list<id>{pa.User__c});
                system.debug('bsfIdUserMap: '+bsfIdUserMap);
            }
            userIdSet.add(pa.User__c);
            userBSfIDPortAssgnMap.put(pa.User__c+'_'+pa.Bsf_Portfolio__c,pa);
        }
        
        
        
        list<accountTeamMember> atmList = [select id,TeamMemberRole,bsf_Portfolio__c,accountid,userid from accountTeamMember where accountId IN:accIdAccPortfolioMap.keyset() and userid IN:userIdSet and is_covering_recruiter__c = false];
        system.debug('atmList: '+atmList);
        list<accountTeamMember> accTeamtoUpdate = new list<accountTeamMember>();
        for(accountTeamMember atm : atmList)
        {
            Id bsfId;
            
            if(atm.teamMemberRole == BSF_Constants.ACCOUNT_MANAGER)
            {
                bsfId = accIdbsfIdListMap.get(atm.accountid).get(0);
                system.debug('ACCOUNT_MANAGER');
            }
            else if(atm.teamMemberRole == BSF_Constants.AREA_BOOKING_MANAGER)
            {
                bsfId = accIdbsfIdListMap.get(atm.accountid).get(1);
                system.debug('AREA_BOOKING_MANAGER');
            }
            else if(atm.teamMemberRole == BSF_Constants.DISTRICT_MANAGER)
            {
                if(accIdbsfIdListMap.get(atm.accountid).size() == 3)
                {
                bsfId = accIdbsfIdListMap.get(atm.accountid).get(2);
                }
                else
                {
                    bsfId = accIdbsfIdListMap.get(atm.accountid).get(1);
                }
                system.debug('District_MANAGER');
            }
            else if(atm.teamMemberRole == BSF_Constants.SUPERVISOR)
            {
                bsfId = accIdSupervisor.get(atm.accountid);
                system.debug('Supervisor');
            }
            
            if(bsfIdUserMap.get(bsfId).contains(atm.userId) && atm.bsf_Portfolio__c != bsfId)
            {
             atm.bsf_Portfolio__c = bsfId;
             if(bsfidAccPortfolioMap.keyset().contains(atm.accountId+'_'+bsfId))
             {
                Account_Portfolio_Assignment__c ap = new Account_Portfolio_Assignment__c ();
                ap = bsfidAccPortfolioMap.get(atm.accountId+'_'+bsfId);

                Portfolio_Assignment__c pa = new Portfolio_Assignment__c();
                pa=userBSfIDPortAssgnMap.get(atm.userid+'_'+bsfId);
                atm.End_Date__c = ap.End_Date__c < pa.End_Date__c? ap.End_Date__c :pa.End_Date__c;
             }
             accTeamtoUpdate.add(atm);
            }
          }
        
        if(!accTeamtoUpdate.isEmpty())
        {
            Database.Update(accTeamtoUpdate,false);
        }
    }
 
    public static map<id,List<id>> accIdexistingUserIdMap(set<id> accidSet)
    {
        Map<id,List<id>> accAccTeamListMap = new map <id,List<id>>();
        List<AccountTeamMember> atmList = [Select Accountid,UserId from AccountTeamMember where AccountId IN:accidSet and is_covering_recruiter__c = false];
        
            for(AccountTeamMember atm : atmList)
            {
                if(accAccTeamListMap.keyset().contains(atm.accountId))
                {
                    accAccTeamListMap.get(atm.accountId).add(atm.userId);
                    system.debug('accAccTeamListMap: '+accAccTeamListMap);
                }
                else
                {
                    accAccTeamListMap.put(atm.accountId,new list<id>{atm.userId});
                    system.debug('accAccTeamListMap: '+accAccTeamListMap);
                }
            }

            if(accAccTeamListMap != null)
            {
                return accAccTeamListMap;
            }
            else
            {
                return null;
            }
    }

}