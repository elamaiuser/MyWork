/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 *  12/27/2023				 Kishore Das		        Logic for HRP-11605(Newly created FS BDO's are reflecting as tentative when the DOC is reflecting as confirmed (out of sync))

 *************************************************************************************************************************************************************************************
*/
global class BSF_BatchOnDocForDriveStatusLookUp implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Name, sked_Opportunity__r.Related_Scheduled_Drive__c 
        									from sked_Drive__c where sked_Opportunity__r.Related_Scheduled_Drive__c=null 
                                            AND sked_Opportunity__r.Is_template__c=false]); 
        
    }
    
    global void execute(Database.BatchableContext BC, List<sked_Drive__c> scope){
        List<Opportunity> oppList = new List<Opportunity>();
        for(sked_Drive__c sc:scope){
            oppList.add(new Opportunity(Id=sc.sked_Opportunity__r.id,Related_Scheduled_Drive__c=sc.id));
        }
        if(!oppList.isEmpty()){
            Database.SaveResult[] UpdateResult = DataBase.Update(oppList,false);
            for (Database.SaveResult UpResult : UpdateResult) {
                if (UpResult.isSuccess()) {
                    System.debug('Record Succesffully created '+UpResult.getId());
                } else {
                    for (Database.Error error : UpResult.getErrors()) {
                        System.debug('Record Failed'+error);
                    }
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC) {}

}