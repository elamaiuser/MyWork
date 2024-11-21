global class AccountBatchOnRecognition implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String PremierBonusCurrent =system.label.Premier_Bonus_Current;
        String PremierBonusPrior = system.label.Premier_Bonus_Prior;
        String PremierCurrent = system.label.PremierCurrent;
        String PremierPrior = system.label.PremierPrior;
        List<String> affList = new List<String>{PremierBonusCurrent,PremierBonusPrior,PremierCurrent,PremierPrior};
        String query = 'SELECT Id , Name,Marketing_Program__r.Name,Account__c FROM Account_Marketing_Program__c where Marketing_Program__r.Name In :affList AND Date_Assigned__c = LAST_YEAR ';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account_Marketing_Program__c> scope){
        
        Date dt=system.today();
        Marketing_Program__c pumpitupPrior = [Select Id,Name from Marketing_Program__c Where Name =:label.Premier_Bonus_Prior  AND RecordType.Name = :BSF_Constants.AFFILIATION_RECORD_TYPE Limit 1]; //HRP-11077
        Marketing_Program__c PremierPrior = [Select Id,Name from Marketing_Program__c Where Name =:label.PremierPrior AND RecordType.Name = :BSF_Constants.AFFILIATION_RECORD_TYPE Limit 1]; //HRP-11077
        
   /*     List<Account_Marketing_Program__c> accAffiliationList=[select Id,name,Account__c,Marketing_Program__r.Name, Date_Assigned__c,Date_Removed__c  from Account_Marketing_Program__c where Account__c in:scope
                                                               AND Marketing_Program__r.RecordType.Name = :BSF_Constants.AFFILIATION_RECORD_TYPE AND Marketing_Program__r.Name =: label.PumpItUpCurrent AND Marketing_Program__r.Name =: label.PremierCurrent
                                                               /*in ('Pump It Up Current','Premier Current')*/
                                                              /* AND Date_Assigned__c   <= TODAY];*/ //HRP-11077 */
        
        
        List<Account_Marketing_Program__c> updateList = new List<Account_Marketing_Program__c>();
        List<Account_Marketing_Program__c> insertList = new List<Account_Marketing_Program__c>();
        List<Account_Marketing_Program__c> deleteList = new List<Account_Marketing_Program__c>();
        Set<Id> accountIdSet = new Set<Id>();
        List<Account> accUpdateList = new List<Account>();
       for(Account_Marketing_Program__c accAffiliation : scope)    
       {
           
           deleteList.add(accAffiliation);
           if(accAffiliation.Marketing_Program__r.Name == label.Premier_Bonus_Current){
               accountIdSet.add(accAffiliation.Account__c);
               Account_Marketing_Program__c accPriorAffiliation = new Account_Marketing_Program__c(Account__c=accAffiliation.Account__c,Marketing_Program__c=pumpitupPrior.Id,Date_Assigned__c = System.today());
                    insertList.add(accPriorAffiliation);
               
            }
           else if(accAffiliation.Marketing_Program__r.Name == label.PremierCurrent){
                    accountIdSet.add(accAffiliation.Account__c);
                    Account_Marketing_Program__c accPriorAffiliation = new Account_Marketing_Program__c(Account__c=accAffiliation.Account__c,Marketing_Program__c=PremierPrior.Id,Date_Assigned__c = System.today());
                        insertList.add(accPriorAffiliation);
                  
            }
           
           
        }

            System.debug('insertList '+ insertList);
            
            for(Id accId : accountIdSet){
                Account acc = new account(Id = accId);
                acc.IsPumpedItUpCurrent__c = false;
                acc.IsPremierCurrent__c = false;
                accUpdateList.add(acc);
            } 
        
            
           Database.SaveResult[] accUpdateListNew = Database.update(accUpdateList,false);
            //Log Errors if any
            for(Database.SaveResult result:accUpdateListNew){
                if(!result.isSuccess()){
                    System.debug(' Account Update Error '+result.getErrors()[0].getMessage());
                }
            }
            
            Database.SaveResult[] accAffInsertResults = Database.insert(insertList,false);
            for(Database.SaveResult resultInsert:accAffInsertResults){
                if(!resultInsert.isSuccess()){
                    System.debug(' Account Affililiation Insert Error '+resultInsert.getErrors()[0].getMessage());
                }
            }
            Database.deleteResult[] accAffDeleteResults = Database.delete(deleteList,false);    
            for(Database.deleteResult resultDelete:accAffDeleteResults){
                if(!resultDelete.isSuccess()){
                    System.debug(' Account Affililiation Delete Error '+resultDelete.getErrors()[0].getMessage());
                }
                
            }
            
        }
        
        global void finish(Database.BatchableContext BC){
            
        }
    }