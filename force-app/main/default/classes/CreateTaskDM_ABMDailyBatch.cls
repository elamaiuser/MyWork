global class CreateTaskDM_ABMDailyBatch implements Database.Batchable<sObject>, Database.Stateful{
    list<Date> getAllDates;
    set<Id> allUserDmAbmId = new set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {   
        getAllDates = CreateTaskDM_ABMDailyBatchHelper.calculateDate();                
        String driveSource = 'Calendar Build';
        String calenderBuildStatus = 'UnQualified';
        String abm='';
        String bm='';
        
        String query = 'SELECT Id, AccountId, Account.District_Manager__c, Source__c FROM Opportunity WHERE Source__c =:'+
            'driveSource AND Calendar_Build_Status__c !=: calenderBuildStatus AND CreatedDate >= LAST_N_DAYS:30 ORDER BY AccountId';
        return Database.getQueryLocator(query);        
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> calenderBuildOppAccList){
        if(getAllDates[0] != null || getAllDates[0] == system.today()){
            if(calenderBuildOppAccList.size() > 0){
                map<Id, Id> getAccAbmMap = CreateTaskDM_ABMDailyBatchHelper.findABM(calenderBuildOppAccList);
                for(Opportunity opp: calenderBuildOppAccList){
                    if(getAccAbmMap.size() == 0 || (getAccAbmMap.size() > 0 && !getAccAbmMap.containskey(opp.accountId))
                       && (opp.Account.District_Manager__c != null)){                   
                           allUserDmAbmId.add( opp.Account.District_Manager__c);
                       }
                    else if(getAccAbmMap.size() > 0){
                        allUserDmAbmId.add(getAccAbmMap.get(opp.accountId));
                    }
                }
            }       
        }
    }
    global void finish(Database.BatchableContext bc){
        CreateTaskDM_ABMDailyBatchHelper.createTask(getAllDates,allUserDmAbmId);
    }
}