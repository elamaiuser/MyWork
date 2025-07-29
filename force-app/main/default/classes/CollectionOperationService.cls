/**
 * @description: This class contains all Collection Operation utility methods called from trigger handler.
**/
public inherited sharing class CollectionOperationService {
    //method to update Queue named when Collection Operation name changed.
    public static void updateUserQueues(List<Biomed_Collection_Op_Center__c> newList, Map<Id, Biomed_Collection_Op_Center__c> oldMap){
        List<Collection_Op_Queue_Event__e> eventList = new List<Collection_Op_Queue_Event__e>();
        for(Biomed_Collection_Op_Center__c collectionOp : newList){
            if(oldMap != null && oldMap.containsKey(collectionOp.Id) 
                    && !collectionOp.Name.equals(oldMap.get(collectionOp.Id).Name)){
                        Collection_Op_Queue_Event__e event = new Collection_Op_Queue_Event__e();
                        event.Collection_Op_Id__c = collectionOp.Id;
                        event.Collection_Op_New_Name__c = collectionOp.Name;
                        event.Collection_Op_Old_Name__c = oldMap.get(collectionOp.Id).Name;
                        event.Trigger_Operation_Type__c = getTriggerOperationType();
                        eventList.add(event);
            }
        }
        if(!eventList.isEmpty()){
            EventBus.publish(eventList);
        }
    }
    //method to execute BSF_UpdateCollectionOperationsBatch when Collection Operation name changed.
    public static void updateUserCollectionOpPicklist(Map<Id, Biomed_Collection_Op_Center__c> newMap, Map<Id, Biomed_Collection_Op_Center__c> oldMap){
        String opType = getTriggerOperationType();
        BSF_UpdateCollectionOperationsBatch batchObj;

        if(opType.equals('INSERT')){
            batchObj = new BSF_UpdateCollectionOperationsBatch(newMap,opType);
        }else if(opType.equals('DELETE')){
            batchObj = new BSF_UpdateCollectionOperationsBatch(oldMap,opType);
        }else if(opType.equals('UPDATE')){
            Map<Id, Biomed_Collection_Op_Center__c> collectionOpMap = new Map<Id, Biomed_Collection_Op_Center__c>();
            for(Id coid : newMap.keySet()){
                if(oldMap != null && oldMap.containsKey(coid) 
                        && !newMap.get(coid).Name.equals(oldMap.get(coid).Name)){
                            collectionOpMap.put(coid,oldMap.get(coid)); 
                }
            }
            if(!collectionOpMap.isEmpty()){
                batchObj = new BSF_UpdateCollectionOperationsBatch(collectionOpMap,opType);
            }
        }
        try{
            if(batchObj != null && !Test.isRunningTest()){
                Database.executeBatch(batchObj,200);
            }
        }catch(Exception ex){
            System.debug('Failed to execute BSF_UpdateCollectionOperationsBatch : '+ex.getMessage());
        }
    }
    //this method is called from Collection_Op_Queue_Event__e event trigger.
    public static void updateUserQueues(List<Collection_Op_Queue_Event__e> eventList){
        Map<String, String> collectionOpNames = new Map<String, String>();
        for(Collection_Op_Queue_Event__e event : eventList){
            if(String.isNotBlank(event.Trigger_Operation_Type__c) && event.Trigger_Operation_Type__c.equals('UPDATE')
                    && String.isNotBlank(event.Collection_Op_New_Name__c) && String.isNotBlank(event.Collection_Op_Old_Name__c)
                    && !event.Collection_Op_New_Name__c.equals(event.Collection_Op_Old_Name__c)){
                        collectionOpNames.put(event.Collection_Op_Old_Name__c,event.Collection_Op_New_Name__c);
            }
        }
        if(!collectionOpNames.isEmpty()){
            reNameQueues(collectionOpNames);
        }
    }

    //method to rename related queues when Collection Operation name changed.
    public static void reNameQueues(Map<String, String> collectionOpNames) {
        Set<String> collectionOpSet = new Set<String>();
        for(String collOpName : collectionOpNames.keySet()){
            collectionOpSet.add(collOpName+ '%');
        }
        List<Group> collectionOpQueues = [SELECT Id, Name, DeveloperName
                                            FROM Group
                                            WHERE Name LIKE :collectionOpSet]; 
        for(Group gp : collectionOpQueues){
            for(String collOpName : collectionOpNames.keySet()){
                if(gp.Name.contains(collOpName)){
                    gp.Name = gp.Name.replace(collOpName,collectionOpNames.get(collOpName));
                    String devName = gp.Name.trim().replaceAll('[^A-Za-z0-9]', '_');
                    for(;devName.contains('__');){
                        devName = devName.replace('__','_');
                    }
                    gp.DeveloperName = devName;
                    break;
                }
            }
        }
        try {
            if(!collectionOpQueues.isEmpty()){
                Database.update(collectionOpQueues,false);
            }
        } catch (DmlException dExc) {
            System.debug('Failed to update all Queues : '+dExc.getMessage());
        }
    }
    //get trigger oparation type in trigger context.
    public static String getTriggerOperationType(){
        switch on Trigger.OperationType  {
            when BEFORE_INSERT,AFTER_INSERT
            {
                return 'INSERT';
            }
            when BEFORE_UPDATE, AFTER_UPDATE
            {
                return 'UPDATE';
            }
            when BEFORE_DELETE, AFTER_DELETE
            {
                return 'DELETE';
            }
            when AFTER_UNDELETE
            {
                return 'UNDELETE';
            }
            when else
            {
                return 'INVALID';
            }
        } 
    }
}