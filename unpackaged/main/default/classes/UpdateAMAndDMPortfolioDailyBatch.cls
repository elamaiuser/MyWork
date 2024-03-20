global class UpdateAMAndDMPortfolioDailyBatch implements Database.Batchable<sObject>,Database.Stateful{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Account__c, Account__r.Account_Manager_Portfolio__c , Account__r.District_Manager_Portfolio__c ,BSF_Portfolio__c,BSF_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Parent_Portfolio__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c,BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c,End_Date__c,Start_Date__c FROM Account_Portfolio_Assignment__c Where BSF_Portfolio__r.Portfolio_Type__c = \'Account Manager\' AND Account__c != null AND BSF_Portfolio__r.Taxonomy_Type__c IN (\'Bio Recruitment CD\',\'Bio Account Portfolio\') AND (CreatedDate = yesterday or LastModifiedDate = yesterday)';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account_Portfolio_Assignment__c> accPortfolioAssignmentList){
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('AccountTriggerHandler');
        Map<Id,List<Account_Portfolio_Assignment__c>> mapToStoreAccVsPortfolioAssignment = new  Map<Id,List<Account_Portfolio_Assignment__c>>();
        Date todaysDate = System.today();
        Map<Id,Account> accToBeUpdateMap = new Map<Id,Account>();
        
        Set<Id> accId = new Set<Id>();
        for(Account_Portfolio_Assignment__c accPort : accPortfolioAssignmentList){
            if(accPort.Account__c != null){
                accId.add(accPort.Account__c);
            }
        }

        Map<Id,Account> accMapIdVsAcc = new Map<Id,Account>([Select Id, Account_Manager_Portfolio__c, District_Manager_Portfolio__c from Account where Id IN: (accId)]);

        //Start_Date__c < TODAY AND End_Date__c > TODAY
        for(Account_Portfolio_Assignment__c accPort : accPortfolioAssignmentList){
            system.debug('mapToStoreAccVsPortfolioAssignment.containsKey(accPort.Account__c)::'+mapToStoreAccVsPortfolioAssignment.containsKey(accPort.Account__c));

                if(mapToStoreAccVsPortfolioAssignment.containsKey(accPort.Account__c)){
                    if(mapToStoreAccVsPortfolioAssignment.get(accPort.Account__c) == null){
                        mapToStoreAccVsPortfolioAssignment.put(accPort.Account__c,new List<Account_Portfolio_Assignment__c>());
                        mapToStoreAccVsPortfolioAssignment.get(accPort.Account__c).add(accPort);
                    } else{
                        List<Account_Portfolio_Assignment__c> accPortfolioList = mapToStoreAccVsPortfolioAssignment.get(accPort.Account__c);
                        accPortfolioList.add(accPort);
                        mapToStoreAccVsPortfolioAssignment.put(accPort.Account__c,accPortfolioList);
                    }
                } else{
                    mapToStoreAccVsPortfolioAssignment.put(accPort.Account__c,new List<Account_Portfolio_Assignment__c>());
                    mapToStoreAccVsPortfolioAssignment.get(accPort.Account__c).add(accPort);
                }
            if(accPort.Start_Date__c <= todaysDate && accPort.End_Date__c >= todaysDate){
                system.debug('accPort.Account__c::'+accPort.Account__c);
                if(accMapIdVsAcc.get(accPort.Account__c) != null){
                    if(accPort.BSF_Portfolio__r.Portfolio_Type__c == 'Account Manager'){
                        if((accMapIdVsAcc.get(accPort.Account__c).Account_Manager_Portfolio__c == null) || (accMapIdVsAcc.get(accPort.Account__c).Account_Manager_Portfolio__c != accPort.BSF_Portfolio__c)){
                            accMapIdVsAcc.get(accPort.Account__c).Account_Manager_Portfolio__c = accPort.BSF_Portfolio__c;
                            if(!accToBeUpdateMap.containsKey(accPort.Account__c)){
                                accToBeUpdateMap.put(accPort.Account__c,accMapIdVsAcc.get(accPort.Account__c));
                            }else{
                                accToBeUpdateMap.put(accPort.Account__c,accMapIdVsAcc.get(accPort.Account__c));
                            }
                            system.debug('Account Manager update');
                        }
                        
                            if((accPort.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager') && ((accMapIdVsAcc.get(accPort.Account__c).District_Manager_Portfolio__c == null) || (accMapIdVsAcc.get(accPort.Account__c).District_Manager_Portfolio__c != accPort.BSF_Portfolio__r.Parent_Portfolio__c))){
                                accMapIdVsAcc.get(accPort.Account__c).District_Manager_Portfolio__c = accPort.BSF_Portfolio__r.Parent_Portfolio__c;
                                if(!accToBeUpdateMap.containsKey(accPort.Account__c)){
                                    accToBeUpdateMap.put(accPort.Account__c,accMapIdVsAcc.get(accPort.Account__c));
                                }else{
                                    accToBeUpdateMap.put(accPort.Account__c,accMapIdVsAcc.get(accPort.Account__c));
                                }
                                system.debug('District Manager update');
                                continue;
                            } else if((accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager') && ((accMapIdVsAcc.get(accPort.Account__c).District_Manager_Portfolio__c == null) || (accMapIdVsAcc.get(accPort.Account__c).District_Manager_Portfolio__c != accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c))){
                                accMapIdVsAcc.get(accPort.Account__c).District_Manager_Portfolio__c = accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c;
                                system.debug('District Manager update');
                                if(!accToBeUpdateMap.containsKey(accPort.Account__c)){
                                    accToBeUpdateMap.put(accPort.Account__c,accMapIdVsAcc.get(accPort.Account__c));
                                }else{
                                    accToBeUpdateMap.put(accPort.Account__c,accMapIdVsAcc.get(accPort.Account__c));
                                }
                                continue;
                            }
                        
                    }
                }
            }
        }

        Map<Id,Opportunity> oppMapIdVsOpp = new Map<Id,Opportunity>([Select Id ,AccountId, Account_Manager_Portfolio__c, District_Manager_Portfolio__c,Drive_Date__c from Opportunity where Drive_Date__c != null AND is_template__c = false AND AccountID IN: (accId)]);

        system.debug('mapToStoreAccVsPortfolioAssignment:: '+mapToStoreAccVsPortfolioAssignment);
        Map<Id,Opportunity> oppToBeUpdateMap = new Map<Id,Opportunity>();

        for(Opportunity opp : oppMapIdVsOpp.Values()){
            system.debug('opp id :: '+opp.Id);
            if(mapToStoreAccVsPortfolioAssignment.get(opp.AccountID) != null){
               for(Account_Portfolio_Assignment__c accPort : mapToStoreAccVsPortfolioAssignment.get(opp.AccountID)){
                system.debug('accPort:: '+accPort);
                if(accPort != Null){
                    if(accPort.Start_Date__c <= opp.Drive_Date__c && accPort.End_Date__c >= opp.Drive_Date__c){
                        system.debug('found a Account portfolio in between given date');
                        if(accPort.BSF_Portfolio__r.Portfolio_Type__c == 'Account Manager'){
                            if((oppMapIdVsOpp.get(opp.ID).Account_Manager_Portfolio__c == null) || (oppMapIdVsOpp.get(opp.ID).Account_Manager_Portfolio__c != accPort.BSF_Portfolio__c)){
                                oppMapIdVsOpp.get(opp.ID).Account_Manager_Portfolio__c = accPort.BSF_Portfolio__c;
                                if(!oppToBeUpdateMap.containsKey(opp.Id)){
                                    oppToBeUpdateMap.put(opp.Id,oppMapIdVsOpp.get(opp.ID));
                                }else{
                                    oppToBeUpdateMap.put(opp.Id,oppMapIdVsOpp.get(opp.ID));
                                }
                                system.debug('Account Manager portfolio update');
                            }
                                if((accPort.BSF_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager') && ((oppMapIdVsOpp.get(opp.ID).District_Manager_Portfolio__c == null) || (oppMapIdVsOpp.get(opp.ID).District_Manager_Portfolio__c != accPort.BSF_Portfolio__r.Parent_Portfolio__c))){
                                    oppMapIdVsOpp.get(opp.ID).District_Manager_Portfolio__c = accPort.BSF_Portfolio__r.Parent_Portfolio__c;
                                    system.debug('District Manager portfolio update');
                                    if(!oppToBeUpdateMap.containsKey(opp.Id)){
                                        oppToBeUpdateMap.put(opp.Id,oppMapIdVsOpp.get(opp.ID));
                                    }else{
                                        oppToBeUpdateMap.put(opp.Id,oppMapIdVsOpp.get(opp.ID));
                                    }
                                    continue;
                                } else if((accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__r.Portfolio_Type__c == 'District Manager') && ((oppMapIdVsOpp.get(opp.ID).District_Manager_Portfolio__c == null) || (oppMapIdVsOpp.get(opp.ID).District_Manager_Portfolio__c != accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c))){
                                    oppMapIdVsOpp.get(opp.ID).District_Manager_Portfolio__c = accPort.BSF_Portfolio__r.Parent_Portfolio__r.Parent_Portfolio__c;
                                    system.debug('District Manager portfolio update');
                                    if(!oppToBeUpdateMap.containsKey(opp.Id)){
                                        oppToBeUpdateMap.put(opp.Id,oppMapIdVsOpp.get(opp.ID));
                                    }else{
                                        oppToBeUpdateMap.put(opp.Id,oppMapIdVsOpp.get(opp.ID));
                                    }
                                    continue;
                                }
                        }
                    }
                }
              } 
            }
            
        }
        if(oppToBeUpdateMap != null){
            Database.update(oppToBeUpdateMap.Values(), false);
        }
        if(accToBeUpdateMap != null){
            Database.update(accToBeUpdateMap.Values(), false);
        }
        
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
    }
    global void finish(Database.BatchableContext bc){
        System.debug('opp update successfull');
    }
}