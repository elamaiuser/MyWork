public class DeleteStaffingBudgetDuplicateBatch implements Database.Batchable<sObject>{
    String typeOfDrive;
    String query;
    Set<Id> collectionOppIdsSet = new Set<Id>();

    public DeleteStaffingBudgetDuplicateBatch(String typeOfDrive){
        this.typeOfDrive = typeOfDrive;
        this.query = 'Select Count(Id), sked_Biomed_Collection_Operation__c  from sked_Staffing_Budget_Collection_Op__c group by sked_Biomed_Collection_Operation__c';
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext BC, List<sked_Staffing_Budget_Collection_Op__c> staffingBudgetCOList){
        Set<Id> collectionOpIdsSet = new Set<Id>();
        for(sked_Staffing_Budget_Collection_Op__c sbco : staffingBudgetCOList){
            collectionOpIdsSet.add(sbco.sked_Biomed_Collection_Operation__c);
        }
        List<sked_Staffing_Budget_Collection_Op__c> existingSBCOList = [SELECT Id, sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c, sked_Staffing_Budget__r.sked_Roles__c, sked_Staffing_Budget__r.sked_Drive_Types__c, sked_Biomed_Collection_Operation__c, sked_Staffing_Budget__c From sked_Staffing_Budget_Collection_Op__c where sked_Biomed_Collection_Operation__c IN: collectionOpIdsSet];

        Map<String, List<sked_Staffing_Budget_Collection_Op__c>> existingCombinationMap = new Map<String, List<sked_Staffing_Budget_Collection_Op__c>>();
        Map<String, List<sked_Staffing_Budget_Collection_Op__c>> duplicateCombinationMap = new Map<String, List<sked_Staffing_Budget_Collection_Op__c>>();
        Map<Id, List<sked_Staffing_Budget_Availability__c>> staffingBudgetWithAvailabilityMap = new Map<Id, List<sked_Staffing_Budget_Availability__c>>();
        Set<Id> staffingBudgetIdsSet = new Set<Id>();
        if(!existingSBCOList.isEmpty()){
            for(sked_Staffing_Budget_Collection_Op__c sbco : existingSBCOList){
                String existingKey = sbco.sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c.format() + 
                                     sbco.sked_Staffing_Budget__r.sked_Roles__c + 
                                     sbco.sked_Staffing_Budget__r.sked_Drive_Types__c + 
                                     sbco.sked_Biomed_Collection_Operation__c;
                System.debug('existingKey :: '+existingKey);
                //existingCombinationMap.put(existingKey, existingSBco);
                
                if(existingCombinationMap.containsKey(existingKey)){
                    List<sked_Staffing_Budget_Collection_Op__c> sBCOList = existingCombinationMap.get(existingKey);
                    sBCOList.add(sbco);
                    existingCombinationMap.put(existingKey, sBCOList);
                } else {
                    List<sked_Staffing_Budget_Collection_Op__c> sBCOList = new List<sked_Staffing_Budget_Collection_Op__c>();
                    sBCOList.add(sbco);
                    existingCombinationMap.put(existingKey,sBCOList);
                }
            }
            if(!existingCombinationMap.isEmpty()){
                for(String key : existingCombinationMap.keySet()){
                    if(existingCombinationMap.get(key).size() > 1){
                        duplicateCombinationMap.put(key,existingCombinationMap.get(key));
                        for(sked_Staffing_Budget_Collection_Op__c sbco : existingCombinationMap.get(key)){
                            staffingBudgetIdsSet.add(sbco.sked_Staffing_Budget__c);   
                        }
                    }
                }
            }
            List<sked_Staffing_Budget_Availability__c> staffingBudgetAvailabilityList = [Select Id, sked_Availability__c, sked_Availability_Status__c, sked_Staffing_Budget__c, sked_Status__c from sked_Staffing_Budget_Availability__c where sked_Staffing_Budget__c In: staffingBudgetIdsSet];
            for(sked_Staffing_Budget_Availability__c sBA : staffingBudgetAvailabilityList){
                if(staffingBudgetWithAvailabilityMap.containsKey(sBA.sked_Staffing_Budget__c)){
                    List<sked_Staffing_Budget_Availability__c> sBAList = staffingBudgetWithAvailabilityMap.get(sBA.sked_Staffing_Budget__c);
                    sBAList.add(sBA);
                    staffingBudgetWithAvailabilityMap.put(sBA.sked_Staffing_Budget__c, sBAList);
                } else {
                    List<sked_Staffing_Budget_Availability__c> sBAList = new List<sked_Staffing_Budget_Availability__c>();
                    sBAList.add(sBA);
                    staffingBudgetWithAvailabilityMap.put(sBA.sked_Staffing_Budget__c,sBAList);
                }
            }
        }
    }

    public static void calculation(Map<String, List<sked_Staffing_Budget_Collection_Op__c>> duplicateCombinationMap, Map<Id, List<sked_Staffing_Budget_Availability__c>> staffingBudgetWithAvailabilityMap){
        List<sked_Staffing_Budget_Collection_Op__c> sBCONeedToDelete = new List<sked_Staffing_Budget_Collection_Op__c>();
        for(String staffingBudgetUniqueKey : duplicateCombinationMap.keySet()){
            Decimal maxNumberOfTotalSlots = 0;
            for(sked_Staffing_Budget_Collection_Op__c sBCO : duplicateCombinationMap.get(staffingBudgetUniqueKey)){
                Id storeTempStaffingBudgetID = sBCO.sked_Staffing_Budget__c;
                //if(){

                //}
            }
        }
    }
    
    public void finish(Database.BatchableContext bc){
        system.debug('batch is done :: ');
    }
}