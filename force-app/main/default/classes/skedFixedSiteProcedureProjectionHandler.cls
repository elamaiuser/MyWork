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
        }
        if(!AccountMap.isEmpty()){
            List<Opportunity> oppList= [SELECT Id, 
                                            AccountId, 
                                            Drive_Date__c
                                        FROM Opportunity
                                        WHERE AccountId IN :AccountMap.keySet()
                                        AND StageName != 'Cancelled'
                                        AND Drive_Date__c != null
                                        ORDER BY Drive_Date__c ASC];
            for(Opportunity opp : oppList){
                AccountMap.get(opp.AccountId).add(opp.Drive_Date__c);
            }
        }
        for (sked_Fixed_Site_Procedure_Projection__c newRecord : newRecords) {
            if(oldMap == null || oldMap.isEmpty() || !oldMap.containsKey(newRecord.Id) || oldMap.get(newRecord.Id) == null){
                newRecord.sked_Impact_Drives__c = checkDrives(AccountMap.get(newRecord.sked_Account__c), newRecord.sked_Effective_Start_Date__c, newRecord.sked_Effective_End_Date__c);
            }else if (!oldMap.get(newRecord.Id).sked_Impact_Drives__c 
                    && (newRecord.sked_Deferral__c != oldMap.get(newRecord.Id).sked_Deferral__c 
                    || newRecord.sked_QNS__c != oldMap.get(newRecord.Id).sked_QNS__c
                    || newRecord.sked_Productive_Procedure_Goal__c != oldMap.get(newRecord.Id).sked_Productive_Procedure_Goal__c)) {
                        newRecord.sked_Impact_Drives__c = checkDrives(AccountMap.get(newRecord.sked_Account__c), newRecord.sked_Effective_Start_Date__c, newRecord.sked_Effective_End_Date__c);
            }
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