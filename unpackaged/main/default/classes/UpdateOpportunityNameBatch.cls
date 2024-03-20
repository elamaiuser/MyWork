//@Description: This batch updating opportunity name, called from Account Service, Site Service and opportunity service 
/*

* Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 09/08/2023			Kishore Das				Added Database method and Error log(For the Story HRP-10549)
*****************************************************************************************************************************************************************************
*/
global class UpdateOpportunityNameBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global List<Opportunity> oppNewList = new List<opportunity>();
    global Map<id, Opportunity> oppOldMap = new Map<id, Opportunity>();
    global Boolean updateNameInBulk = false;
    global String query; 
    
    global UpdateOpportunityNameBatch(Boolean runBulkUpdate, string incomingQuery) {
        //system.debug('coming here1# '+runBulkUpdate+' '+incomingQuery);
        updateNameInBulk = true;
        query = incomingQuery;
    }
    
    global UpdateOpportunityNameBatch(list<Opportunity> incomingOppNewList) {
        oppNewList = incomingOppNewList;
    }
    
    global UpdateOpportunityNameBatch(list<Opportunity> incomingOppNewList, map<Id, Opportunity> incomingOppOldMap) {
     
        oppNewList = incomingOppNewList;
        oppOldMap = incomingOppOldMap;
    }
    
    global List<Opportunity> start(Database.BatchableContext bc) {
       
        //If after insert, query the opportunity since it will be read-only
        //if(oppOldMap == null) {
        //    oppNewList = [SELECT Id, Name, Is_Template__c, Drive_Site__c, Account_Internal_Name__c, Site_Building_Name__c FROM Opportunity WHERE Id in: oppNewList];
        //}
        if(updateNameInBulk == true && query != '') {
            
            oppNewList = Database.query(query);
            //system.debug('oppNewList### '+oppNewList);
        }
        return oppNewList;
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunities) {
       // System.debug('### inside UpdateOpportunityNameBatch Execute ' + lstOpportunities.size() + ' ---' + lstOpportunities);
        if(updateNameInBulk) {
            //system.debug('updateNameInBulk##'+updateNameInBulk);
            List<Opportunity> finalOppList = new List<Opportunity>();
            for (opportunity opp : lstOpportunities) {
                if(opp.Is_Template__c == false && opp.Drive_Site__c == null) {
                    string tmpTbdOppName = opp.Account_Internal_Name__c + ', TBD';
                    if(opp.Name != tmpTbdOppName) {
                        opp.Name =  opp.Account_Internal_Name__c + ', TBD';   
                        finalOppList.add(opp);
                    }
                }                    
                else if (opp.Is_Template__c == false && opp.Drive_Site__c != null) {
                    string tmpOppName = opp.Account_Internal_Name__c + ', ' +  opp.Site_Building_Name__c;
                    if(tmpOppName.length() > 120) {
                        tmpOppName = tmpOppName.substring(0,120);
                    }
                    if(opp.Name != tmpOppName) {
                        opp.Name = tmpOppName;
                        finalOppList.add(opp);
                    }
                } 
            }
            // added Database method and Error log(HRP-10549):start
            //system.debug('finalOppList##'+finalOppList.size());
            Database.UpsertResult[] upsertfinalOppList = Database.upsert(finalOppList,false);
            
            if(upsertfinalOppList.size()>0){
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(upsertfinalOppList,'UpdateOpportunityName','UpdateOpportunityNameBatch','execute','Error','Error in Updating opportunity name');
            InsertBsfErrorLog.insertBsfErrors(logList);
            // added Database method and Error log(HRP-10549):End
        }
        }
        else{
            // added Database method and Error log(HRP-10549):start
            //system.debug('lstOpportunities##'+lstOpportunities.size()+' '+lstOpportunities);
            Database.UpsertResult[] upsertlstOpportunities = Database.upsert(lstOpportunities,false);
            
            if(upsertlstOpportunities.size()>0){
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(upsertlstOpportunities,'UpdateOpportunityName','UpdateOpportunityNameBatch','execute','Error','Error in Updating opportunity name');
            InsertBsfErrorLog.insertBsfErrors(logList);
            // added Database method and Error log(HRP-10549):End
        }
        }
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}