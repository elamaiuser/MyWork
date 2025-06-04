public class skedFixedSiteProcedureProjectionHandler extends skedTriggerHub {

    public override void onBeforeInsert() {
        populateData(this.context.newRecords, null);
    }
    public override void onBeforeUpdate() {
        populateData(this.context.newRecords, (Map<Id, sked_Fixed_Site_Procedure_Projection__c>)this.context.oldMap);
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    private void populateData(List<sked_Fixed_Site_Procedure_Projection__c> newRecords, Map<Id, sked_Fixed_Site_Procedure_Projection__c> oldMap) {
        Map<Id, List<Date>> AccountMap = new Map<Id, List<Date>>();
        List<sked_Fixed_Site_Procedure_Projection__c> recordsToUpdate = new List<sked_Fixed_Site_Procedure_Projection__c>();
        List<Id> fsppIds = new List<Id>();
        for (sked_Fixed_Site_Procedure_Projection__c newRecord : newRecords) {
            if(oldMap == null || oldMap.isEmpty() || !oldMap.containsKey(newRecord.Id) || oldMap.get(newRecord.Id) == null){
                AccountMap.put(newRecord.sked_Account__c, new List<Date>());
            }else if (!oldMap.get(newRecord.Id).sked_Impact_Drives__c 
                    && (newRecord.sked_Deferral__c != oldMap.get(newRecord.Id).sked_Deferral__c 
                    || newRecord.sked_QNS__c != oldMap.get(newRecord.Id).sked_QNS__c
                    || newRecord.sked_Productive_Procedure_Goal__c != oldMap.get(newRecord.Id).sked_Productive_Procedure_Goal__c
                    || newRecord.sked_Effective_Start_Date__c != oldMap.get(newRecord.Id).sked_Effective_Start_Date__c
                    || newRecord.sked_Effective_End_Date__c != oldMap.get(newRecord.Id).sked_Effective_End_Date__c)){
                        AccountMap.put(newRecord.sked_Account__c, new List<Date>());
            }
            if(newRecord.Id != null){
                fsppIds.add(newRecord.Id);
            }
        }
        if(!AccountMap.isEmpty()){
            List<Account> accList = [SELECT Id, 
                                            (SELECT Id, 
                                                    AccountId, 
                                                    Drive_Date__c 
                                            FROM Opportunities 
                                            WHERE StageName != 'Cancelled' 
                                            AND Drive_Date__c != null
                                            ORDER BY Drive_Date__c ASC), 
                                            (SELECT Id
                                            FROM sked_Fixed_Site_Procedure_Projections__r 
                                            WHERE sked_Impact_Drives__c = true) 
                                    FROM Account 
                                    WHERE Id IN :AccountMap.keySet()];
            if(!accList.isEmpty()){
                for(Account acc : accList){
                    if(acc.Opportunities != null){
                        for(Opportunity opp : acc.Opportunities){
                            AccountMap.get(opp.AccountId).add(opp.Drive_Date__c);
                        }
                    }
                    if(acc.sked_Fixed_Site_Procedure_Projections__r != null){
                        for(sked_Fixed_Site_Procedure_Projection__c fspp : acc.sked_Fixed_Site_Procedure_Projections__r){
                           if(!fsppIds.contains(fspp.id)){
                                fspp.sked_Impact_Drives__c = false;
                                recordsToUpdate.add(fspp);
                           }
                        }
                    }
                }
            }
        }
        for (sked_Fixed_Site_Procedure_Projection__c newRecord : newRecords) {
            if(oldMap == null || oldMap.isEmpty() || !oldMap.containsKey(newRecord.Id) || oldMap.get(newRecord.Id) == null){
                newRecord.sked_Impact_Drives__c = checkDrives(AccountMap.get(newRecord.sked_Account__c), newRecord.sked_Effective_Start_Date__c, newRecord.sked_Effective_End_Date__c);
            }else if (!oldMap.get(newRecord.Id).sked_Impact_Drives__c 
                    && (newRecord.sked_Deferral__c != oldMap.get(newRecord.Id).sked_Deferral__c 
                    || newRecord.sked_QNS__c != oldMap.get(newRecord.Id).sked_QNS__c
                    || newRecord.sked_Productive_Procedure_Goal__c != oldMap.get(newRecord.Id).sked_Productive_Procedure_Goal__c
                    || newRecord.sked_Effective_Start_Date__c != oldMap.get(newRecord.Id).sked_Effective_Start_Date__c
                    || newRecord.sked_Effective_End_Date__c != oldMap.get(newRecord.Id).sked_Effective_End_Date__c)) {
                        newRecord.sked_Impact_Drives__c = checkDrives(AccountMap.get(newRecord.sked_Account__c), newRecord.sked_Effective_Start_Date__c, newRecord.sked_Effective_End_Date__c);
            }
        }
        if(!recordsToUpdate.isEmpty()){
            Database.SaveResult[] srList = Database.update (recordsToUpdate,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Fixed Site Procedure Projection','skedFixedSiteProcedureProjectionHandler','populateData','Error','Error in updating Fixed Site Procedure Projection Records');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
    private Boolean checkDrives(List<Date> dateList, Date startDate, Date endDate){
        Boolean result = false;
        if(dateList != null && !dateList.isEmpty()){
            dateList.sort();
            for(Date dt : dateList){
                if(startDate == null && endDate == null){
                    result = true;
                    break;
                }else if(startDate == null && endDate != null && dt <= endDate){
                    result = true;
                    break;
                }else if(startDate != null && endDate == null && dt >= startDate){
                    result = true;
                    break;
                }else if(dt >= startDate && dt <= endDate){
                    result = true;
                    break;
                }
            }
        }
        return result;
    }
}