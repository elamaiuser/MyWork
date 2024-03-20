/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/26/2023				 Kishore Das		        Logic for HRP-10887(Calendar Build Status not populating)

 *************************************************************************************************************************************************
*/
global class BSF_BatchCalendarBuildStatusUpdate implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Name, Drive_Date__c,Source__c,Calendar_Build_Status__c 
                                         from opportunity where Source__c= :BSF_Constants.DOC_SOURCE 
                                         AND Calendar_Build_Status__c=null AND drive_date__c > today
                                         AND StageName != :BSF_Constants.STAGE_CANCELLED]); 
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        set<Id> oppIds=new set<Id>();
        for(Opportunity op:scope){
            oppIds.add(op.id);
        }
        
        list<sked_Drive__c> docList=[select id,name,sked_Drive_Productivity_Planned__c,sked_Opportunity__c,
                                     sked_Total_Products_Projected__c
                                     from sked_Drive__c where sked_Opportunity__c in: oppIds];
        map<Id,sked_Drive__c> driveMap = new map<Id,sked_Drive__c>();
        for(sked_Drive__c dc:docList){
            driveMap.put(dc.sked_Opportunity__c,dc);
        }
        list<opportunity> oppListhasDoc=[SELECT Id, Name, Drive_Date__c,Source__c,Calendar_Build_Status__c 
                                         from opportunity where Source__c = :BSF_Constants.DOC_SOURCE 
                                         and Calendar_Build_Status__c=null and Id in:driveMap.keyset()];
        
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(opportunity opp:oppListhasDoc){
            List<string> unqualifiedReasons = new List<string>();
            if(driveMap.get(opp.Id).sked_Drive_Productivity_Planned__c < 0.5){
                unqualifiedReasons.add(Label.ReasonUqalifiedProductivity_Planned); 
            }
            if (driveMap.get(opp.Id).sked_Total_Products_Projected__c < 25) {
                unqualifiedReasons.add(Label.ReasonUqalifiedTotal_Products_Projected);
            }
            opp.Calendar_Build_Status__c = unqualifiedReasons.isEmpty() ? skedConstants.CALENDAR_BUILD_STATUS_QUALIFIED 
                														: skedConstants.CALENDAR_BUILD_STATUS_UNQUALIFIED;
            if (!unqualifiedReasons.isEmpty()) {
                opp.Calendar_Build_Reasons_For_Unqualified__c = string.join(unqualifiedReasons, ';');
            }    
            opportunitiesToUpdate.add(opp);
        }
        if (!opportunitiesToUpdate.isEmpty()) {
            Database.SaveResult[] UpdateResult = DataBase.Update(opportunitiesToUpdate,false);
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