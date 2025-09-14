/* 
 * @Description: This class is used to serve different Account affiliation object related functionalities and is called from AccountAffiliationTriggerHandler.
 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * *********************************************************************************
 * 02/15/2025				   Priti Jana		      Logic for HRP-14275
 ***********************************************************************************
 */ 

public with sharing class AccountAffiliationService {
    
     public static void createHistoryOnAccAffiliation( list<Account_Marketing_Program__c> accAffiliatonCreatedList, String triggerContext){
        system.debug('Its Here createHistoryOnAccAffiliation');
        list<Account_Affiliation_History__c> affiliationHistoryListOnCreation = new list<Account_Affiliation_History__c>();
        map<Id, String> affiliationIdNameMap = new map<Id, String>();
        map<Id, String> affiliationIdRecordTypeMap = new map<Id, String>();
        map<Id, String> affiliationNotToDelete = new map<Id,String>();
        String PremierBonusCurrent =system.label.Premier_Bonus_Current;
        String PremierBonusPrior = system.label.Premier_Bonus_Prior;
        String PremierCurrent = system.label.PremierCurrent;
        String PremierPrior = system.label.PremierPrior;
        List<String> affList = new List<String>{PremierBonusCurrent,PremierBonusPrior,PremierCurrent,PremierPrior};
        Set<Id> recognistionAffIdSet = new Set<Id>();
        Set<Id> recognistionAffAccIdSet = new Set<Id>();
        List<Account_Marketing_Program__c> acmListToUpdateHistory = new List<Account_Marketing_Program__c>();
        
        set<Id> affiliationId = new set<Id>();
        for(Account_Marketing_Program__c amp: accAffiliatonCreatedList){
            affiliationId.add(amp.Marketing_Program__c);
        }
        for(Marketing_Program__c mp: [SELECT Id, Name, RecordType.Name FROM Marketing_Program__c WHERE ID IN : affiliationId ]){
            affiliationIdNameMap.put(mp.Id, mp.Name);
            affiliationIdRecordTypeMap.put(mp.Id, mp.RecordType.Name);
            if(affList.contains(mp.Name)){
                recognistionAffIdSet.add(mp.Id);
                affiliationNotToDelete.put(mp.Id, mp.RecordType.Name);
            }
            
        }
        for(Account_Marketing_Program__c amp: accAffiliatonCreatedList){
            Account_Affiliation_History__c accAffHis = new Account_Affiliation_History__c();
            accAffHis.Account__c = amp.Account__c;
            accAffHis.Account_Affiliation_Name__c = amp.Name;
            accAffHis.Affiliation_Name__c = affiliationIdNameMap.get(amp.Marketing_Program__c);
            accAffHis.Operation_Type__c = triggerContext;
            if(triggerContext == 'Delete' && recognistionAffIdSet.contains(amp.Marketing_Program__c)){
                acmListToUpdateHistory.add(amp);
                recognistionAffAccIdSet.add(amp.Account__c);
                continue;
            }
            if(triggerContext == 'Delete'){
                accAffHis.Deleted_Date__c =system.today();
            }
            accAffHis.Start_Date__c = amp.Start_Date__c;
            accAffHis.End_Date__c = amp.End_Date__c;
            accAffHis.Date_Assigned__c = amp.Date_Assigned__c ;
            accAffHis.Date_Removed__c = amp.Date_Removed__c;
            accAffHis.Assigned_By__c = amp.Assigned_By__c;
            accAffHis.Removed_By__c = amp.Removed_By__c;
            accAffHis.Affiliation_Record_Type__c = affiliationIdRecordTypeMap.get(amp.Marketing_Program__c);
            if(!affiliationNotToDelete.containsKey(amp.Marketing_Program__c ) || !triggerContext.equalsIgnoreCase('Update')){
                affiliationHistoryListOnCreation.add(accAffHis);
            }
        } 
        
        List<Account_Affiliation_History__c> historyToBeUpdated = new List<Account_Affiliation_History__c>();
        Map<String,Account_Affiliation_History__c> accRecHisyoryMap = new Map<String,Account_Affiliation_History__c>();
        for(Account_Affiliation_History__c accAffHistory :[Select Id,Account__c,Affiliation_Name__c FROM Account_Affiliation_History__c Where Account__c in :recognistionAffAccIdSet  AND Date_Removed__c = null]){
            accRecHisyoryMap.put(accAffHistory.Account__c+''+accAffHistory.Affiliation_Name__c,accAffHistory);
        }
        for(Account_Marketing_Program__c accRecAffilistion : acmListToUpdateHistory){
            String key = accRecAffilistion.Account__c+''+affiliationIdNameMap.get(accRecAffilistion.Marketing_Program__c);
            
            if(accRecHisyoryMap.containsKey(key)){
                Account_Affiliation_History__c accRecHistory = accRecHisyoryMap.get(key);
                accRecHistory.Date_Removed__c = System.today();
                historyToBeUpdated.add(accRecHistory);
            }
        }
        try {
			//Schema.DescribeSObjectResult ds = Account_Affiliation_History__c.sObjectType.getDescribe();
            //if( ds.isCreateable() ){}
				Database.insert(affiliationHistoryListOnCreation,false);
			    Database.update(historyToBeUpdated,false);
            
        }
        catch (Exception e) {
            System.debug('Not able to create history due to ' + e.getMessage());
        }
    }
    
    // HRP-11077
    // Method Name: deletePriorAccAffiliation
    // 
     public static void deletePriorAccAffiliation(list<Account_Marketing_Program__c> currentValues )//Current Affiliation Values
      {
          
          system.debug('currentValues##');
          String PremierBonusPrior = system.label.Premier_Bonus_Prior;
          String PremierPrior = system.label.PremierPrior;
          list<id> accountIds=new List<id>();
          list<String> priorList=new list<String>{PremierBonusPrior,PremierPrior};
          list<Account_Marketing_Program__c> affiliationList=[select id,name,Marketing_Program__r.Name,Account__c,
                                                                 Date_Assigned__c,Date_Removed__c from 
                                                                 Account_Marketing_Program__c where Id In:currentValues];
         // system.debug('currentValues1##'+AffiliationList);
          
          for(Account_Marketing_Program__c ac:AffiliationList){
              accountIds.add(ac.Account__c);
          }
          Map<String,Account_Marketing_Program__c> priorAcctAffMap = new Map<String,Account_Marketing_Program__c>();
          
          for(Account_Marketing_Program__c newAffiliationprior :[select id,name,Marketing_Program__c,Account__c from Account_Marketing_Program__c
                                                                  where Account__c in:accountIds 
                                                                 and Marketing_Program__r.Name In:priorList]){
               priorAcctAffMap.put(newAffiliationprior.Account__c+''+newAffiliationprior.Marketing_Program__c,newAffiliationprior);                                                      
          }
          
          Map<String,Id> priorAffMasterData = new Map<String,Id>();
          
          for (Marketing_Program__c priorAff : [Select Id,Name from Marketing_Program__c Where Name in :priorList])
            {
                
                priorAffMasterData.put(priorAff.Name,priorAff.Id);
            }
			
          List<Account_Marketing_Program__c> accmTobeDelete = new List<Account_Marketing_Program__c>();
          for(Account_Marketing_Program__c newAffiliation : affiliationList)
          {
              if(newAffiliation.Marketing_Program__r.Name == Label.Premier_Bonus_Current){
                  Account_Marketing_Program__c priorToDelete = priorAcctAffMap.get(newAffiliation.Account__c+''+priorAffMasterData.get(Label.Premier_Bonus_Prior));
                  if(priorToDelete != null){
                    accmTobeDelete.add(priorToDelete);
                  }
              }else if(newAffiliation.Marketing_Program__r.Name == Label.PremierCurrent){
                  Account_Marketing_Program__c priorToDelete = priorAcctAffMap.get(newAffiliation.Account__c+''+priorAffMasterData.get(Label.PremierPrior));
                  if(priorToDelete != null){
                  	accmTobeDelete.add(priorToDelete);
                  }
              }
              
          }
           if(!accmTobeDelete.isEmpty())
           {
               
               Database.delete(accmTobeDelete,false);
               
           }  
                    
       }
    public static void AccountFlagForPumpItUpCurrent(list<Account_Marketing_Program__c> accAffiliationList, List<String> priorList, List<String> recordTypeNames){
        map<id,list<id>> marketingProgramMap = new map<id,list<id>>();
        
        for(Account_Marketing_Program__c ac : accAffiliationList){
            if(marketingProgramMap.containskey(ac.Marketing_Program__c)) {
                list<id> accList=marketingProgramMap.get(ac.Marketing_Program__c);
                accList.add(ac.Account__c);
                marketingProgramMap.put(ac.Marketing_Program__c,accList);
            } else{
                marketingProgramMap.put(ac.Marketing_Program__c,new list<id>{ac.Account__c});
            }  
        }

        system.debug('keys '+marketingProgramMap.keyset()+ 'values '+ marketingProgramMap.values());
        //Id RccognitionId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Recognition Affiliation').getRecordTypeId();
        list<Marketing_Program__c> accMkting=[select id,name from Marketing_Program__c where id in :marketingProgramMap.keyset() and RecordType.Name = :recordTypeNames
                                                and Name =: priorList];//and Start_Date__c = THIS_YEAR
        system.debug('accMkting '+accMkting.size());        
        Map<Id,Account> accountMap= new Map<Id,Account>();
        
        for(Marketing_Program__c mpc:accMkting){
            if(mpc.name== label.Premier_Bonus_Current){
                List<Id> newAcccList=marketingProgramMap.get(mpc.id);
                if(newAcccList == null)
                    continue;
                for(Id acctId : newAcccList){
                    if(!accountMap.containsKey(acctId)){
                        accountMap.put(acctId,new Account(Id=acctId,IsPumpedItUpCurrent__c = true));
                    }else{
                        accountMap.get(acctId).IsPumpedItUpCurrent__c = true;
                    }
                }
            }else if(mpc.name == label.PremierCurrent){
                List<Id> newAcccList=marketingProgramMap.get(mpc.id);
                if(newAcccList == null)
                    continue;
                for(Id acctId : newAcccList){
                    if(!accountMap.containsKey(acctId)){
                        accountMap.put(acctId,new Account(Id=acctId,IsPremierCurrent__c = true));
                    }else{
                        accountMap.get(acctId).IsPremierCurrent__c = true;
                    }
                }
            }else if(mpc.name == BSF_Constants.HOSPITAL_CONTRACT_PARTNER){
                List<Id> newAcccList=marketingProgramMap.get(mpc.id);
                if(newAcccList == null)
                    continue;
                for(Id acctId : newAcccList){
                    if(!accountMap.containsKey(acctId)){
                        accountMap.put(acctId,new Account(Id=acctId,Is_Hospital_Contract_Partner__c = true));
                    }else{
                        accountMap.get(acctId).Is_Hospital_Contract_Partner__c = true;
                    }
                }
            }
        }
            
            AccountTeamMemberHelper.skipAccountTrigger=true;
            update accountMap.values();
            AccountTeamMemberHelper.skipAccountTrigger=false;        
    }

    public static void AccountFlagForAffiliationList(list<Account_Marketing_Program__c> accAffiliationList, String triggerContext){
        String pumpitupBonusCurrent = system.label.Premier_Bonus_Current;
        String PremierCurrent = system.label.PremierCurrent;
        String hospitalContractPartner = BSF_Constants.HOSPITAL_CONTRACT_PARTNER;
        list<String> affiliationProgramName=new list<String>{pumpitupBonusCurrent,PremierCurrent, hospitalContractPartner};
        list<String> affiliationProgramRecordType = new List<String>{BSF_Constants.AFFILIATION_RECORD_TYPE,BSF_Constants.AFFILIATION_RECORD_TYPE2};

        if(triggerContext == 'Insert'){
            AccountFlagForPumpItUpCurrent(accAffiliationList,affiliationProgramName, affiliationProgramRecordType);
        }else if(triggerContext == 'Update'){            
            RemovalOfAffiliationList(accAffiliationList, hospitalContractPartner);
        }
    }

    public static void RemovalOfAffiliationList(list<Account_Marketing_Program__c> accAffiliationList, String programName){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> otherAccountIds = new Set<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Marketing_Program__c> marketingPgms = [SELECT Id FROM Marketing_Program__c WHERE Name = :programName AND RecordType.Name = :BSF_Constants.AFFILIATION_RECORD_TYPE2 LIMIT 1];

        for(Account_Marketing_Program__c amp : accAffiliationList){
            if(amp.Date_Removed__c != null && 
               amp.Date_Removed__c <= System.today() && 
               amp.Marketing_Program__c == marketingPgms[0].Id){
                accountIds.add(amp.Account__c);
            }else if(amp.Marketing_Program__c == marketingPgms[0].Id && (amp.Date_Removed__c == null || amp.Date_Removed__c > System.today())){
                otherAccountIds.add(amp.Account__c);
            }
        }       

        if(!accountIds.isEmpty()){            
            for(Id accId : accountIds){
                accountsToUpdate.add(new Account(
                    Id = accId,
                    Is_Hospital_Contract_Partner__c = false
                ));
            }
        }
        
        if(!otherAccountIds.isEmpty()){            
            for(Id accId : otherAccountIds){
                accountsToUpdate.add(new Account(
                    Id = accId,
                    Is_Hospital_Contract_Partner__c = true
                ));
            }
        }

        AccountTeamMemberHelper.skipAccountTrigger=true;
        update accountsToUpdate;
        AccountTeamMemberHelper.skipAccountTrigger=false;
    }
    
    public static void SetUniqueAccountAffiliationKey(list<Account_Marketing_Program__c> accAffiliationList, String triggerContext){
       
            Set<Id> IdSetAcc = new Set<Id>();
        	Set<Id> IdSetMkt = new Set<Id>();
            for(Account_Marketing_Program__c ac:accAffiliationList){
                IdSetAcc.add(ac.Account__c);
                IdSetMkt.add(ac.Marketing_Program__c);
            }
		//String AccUFID=[select id,UFID__c from account where Id In:IdSetAcc].UFID__c;
        //String MktingUFID=[select id,UFID__c from Marketing_Program__c where Id In:IdSetMkt].UFID__c;
        
        Map<Id,Account> accMap=new Map<Id,Account>([select id,UFID__c from account where Id In:IdSetAcc]);
		Map<Id,Marketing_Program__c> MktMap=new Map<Id,Marketing_Program__c>([select id,UFID__c from Marketing_Program__c where Id In:IdSetMkt]);
        For(Account_Marketing_Program__c ac:accAffiliationList){
                if(String.isBlank(ac.Account_Affiliation_External_Key__c)){
                ac.Account_Affiliation_External_Key__c=accMap.get(ac.Account__c).UFID__c+'_'+MktMap.get(ac.Marketing_Program__c).UFID__c; 
                
                 }
                 if(ac.Date_Assigned__c == null){
                    ac.Date_Assigned__c = System.today();
                }
            }
             
        
    }
   public static void AccountAffiliationDateValidation(list<Account_Marketing_Program__c> accAffiliatonCreatedList)
    {
        set<String> affKeySet = new set<String>();
        for(Account_Marketing_Program__c amp : accAffiliatonCreatedList)
        {
            affKeySet.add(amp.Account_Affiliation_External_Key__c);
        }
        
        list<Account_Marketing_Program__c> existingAffiliationList = [select id,Name,Assigned_By__c,Removed_By__c,Start_Date__c,End_Date__c,Account__c,Marketing_Program__c,Marketing_Program__r.Name,Date_Assigned__c,Date_Removed__c,Account_Affiliation_External_Key__c from Account_Marketing_Program__c where Account_Affiliation_External_Key__c IN:affKeySet ];
        
        
        map<String,Account_Marketing_Program__c> affKeyAffiliationMap = new map<string,Account_Marketing_Program__c>();
        for(Account_Marketing_Program__c amp : existingAffiliationList)
        {
            affKeyAffiliationMap.put(amp.Account_Affiliation_External_Key__c,amp);
        }
        
        
        list<Account_Marketing_Program__c> updatedAffList = new list<Account_Marketing_Program__c>();
        for(Account_Marketing_Program__c amp : accAffiliatonCreatedList)
        {
            if(affKeyAffiliationMap!=null) {
                Account_Marketing_Program__c accMp = new Account_Marketing_Program__c();
                accMp = affKeyAffiliationMap.get(amp.Account_Affiliation_External_Key__c);
                Date oldDassign = accMp.Date_Assigned__c;
                Date newDassign = amp.Date_Assigned__c;
                Date oldDremove = accMp.Date_Removed__c;
                Date newDremove = amp.Date_Removed__c;
                boolean isupdate = false;
            
                amp.Date_Assigned__c = oldDassign;
                amp.Date_Removed__c  = oldDremove;

                if(oldDassign != newDassign) {

                    if(oldDassign > system.today() || oldDassign == NULL) { //HRP-14275
                        amp.Date_Assigned__c = newDassign;
                        isupdate = true;
                    }
                }
                
                if(oldDremove != newDremove)
                {
                    amp.Date_Removed__c = newDremove;
                    isupdate = true;
                }
                if(oldDremove < system.today())
                {
                    amp.Date_Assigned__c =  newDassign;
                    amp.Date_Removed__c  =  newDremove; 
                    isupdate = true;
                }
                if(isupdate)
                {
                    updatedAffList.add(amp);
                }
            }
        }
        
        if(!updatedAffList.isEmpty())
        {
            createHistoryOnAccAffiliation(updatedAffList, 'Update'); 
        }
    }    
}