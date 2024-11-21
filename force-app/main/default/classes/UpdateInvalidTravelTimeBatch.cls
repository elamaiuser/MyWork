global class UpdateInvalidTravelTimeBatch implements Database.Batchable<sked_Site_Collection_Operation__c>,Schedulable{
    global Integer batchSize = 200;

    global UpdateInvalidTravelTimeBatch(){}

    global UpdateInvalidTravelTimeBatch(Integer batchSize){
        this.batchSize = batchSize;
    }

    global Iterable<sked_Site_Collection_Operation__c> start(Database.BatchableContext bc){
        return [SELECT Id FROM sked_Site_Collection_Operation__c];
    }

    global void execute(Database.BatchableContext bc, List<sked_Site_Collection_Operation__c> scope){
        doExecute(scope);
    }

    global void execute(SchedulableContext cc) {
        UpdateInvalidTravelTimeBatch batchObject = new UpdateInvalidTravelTimeBatch();
        Database.executeBatch(batchObject,this.batchSize);
    }
    
    global void finish(Database.BatchableContext bc){}

    @TestVisible
    private void doExecute(List<sked_Site_Collection_Operation__c> scope){
        Set<Id> siteCollOpIds = new Set<Id>();
        List<sked_Site_Collection_Operation__c> siteCollOpList = new List<sked_Site_Collection_Operation__c>();
        if(scope == null || scope.isEmpty()){
            return;
        }
        for(sked_Site_Collection_Operation__c collop : scope){
            siteCollOpIds.add(collop.Id);
        }
        try{
            for(sked_Site_Collection_Operation__c collop : [SELECT Id,sked_Travel_Time_Breakdown_JSON_2__c,sked_Travel_Time_Breakdown_JSON__c  FROM sked_Site_Collection_Operation__c WHERE Id IN: siteCollOpIds]){
                siteCollOpList.add(SiteCollectionOperationService.getInstance().getInvalidTravelTimeFlag(collop));
            }
            if(!siteCollOpList.isEmpty()){
                Database.update(siteCollOpList,false);
            }
        }catch(Exception exp){
            System.debug(exp.getMessage()+exp.getLineNumber());
        }
    }
}