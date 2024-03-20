/**
*
* @group Triggers
*
* @description Used to instantiate and execute Trigger Handlers associated with sObjects. 
*/
public with sharing class TriggerFactory {
 
    public static void createHandler(){  
        // Get a handler appropriate to the object being processed  
        String sObjectName = ObjectName(Trigger.old, Trigger.new);
        TriggerFactory.createHandler(sObjectName);
    }

    public static void createHandler(String sObjectName)
    {  
        if(String.isBlank(sObjectName))
        {
            // Get a handler appropriate to the object being processed  
            sObjectName = ObjectName(Trigger.old, Trigger.new);
        }        
        TriggerFactoryHandler handler = getHandler(Trigger.old, Trigger.new, sObjectName); 
        if(handler.executeTrigger()){
            execute(handler);  
        }
    }

    
    //private static method to control the execution of the handler  
    private static void execute(TriggerFactoryHandler handler){
        if(Trigger.isBefore){
            // Call the bulk before to handle any caching of data and enable bulkification 
            handler.BulkBefore();
            
            // Call the beforeDelete method of the handler
            if(Trigger.isDelete){
                handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);                
            }
            
            // Call the beforeInsert method of the handler
            if(Trigger.isInsert){               
                handler.OnBeforeInsert(Trigger.new);     
                          
            }
            
            //Call the beforeUpdate method of the handler
            if(Trigger.isUpdate){               
                handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
        }else if(Trigger.isAfter){
            // Call the bulk before to handle any caching of data and enable bulkification 
            handler.BulkAfter();
            
            // Call the afterDelete method of the handler
            if(Trigger.isDelete){
                handler.OnAfterDelete(Trigger.old, Trigger.oldMap);             
            }
            
            // Call the afterinsert method of the Handler
            if(Trigger.isInsert){               
                handler.OnAfterInsert(Trigger.new); 
                if(Helper.canExecuteAsync()){
                    TriggerFactoryHandler.OnAfterInsertAsync(Trigger.newMap.keySet(), handler.sObjectName);
                }
            }
            
            // call the afterUpdate method of the handler
            if(Trigger.isUpdate){
                handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
                if(Helper.canExecuteAsync()){
                    TriggerFactoryHandler.OnAfterUpdateAsync(Trigger.newMap.keySet(), handler.sObjectName);
                }       
            }
            
            handler.BulkAfterCleanup();
            
            
        }else if(Trigger.isUnDelete){
            handler.OnUnDelete(Trigger.new);            
        }
        
        //call the cleaup method
        handler.cleanUp();
        if(Trigger.isAfter){
            handler.firstrun = false;
            handler.finish();
        }

        
    }
    
    @testVisible
    // For this to work on any trigger you create your handler class must be the object name
    // underscores removed with _TriggerHandler appended on the end of the name
    // Example:
    // Object Name: Asset
    // Handler class name: Asset_TriggerHandler
    private static TriggerFactoryHandler getHandler(List<sObject> oldList, List<sObject> newList, String sObjectName){ 
        String apiName = sObjectName;
        sObjectName = sObjectName.replaceAll('EventbriteSync', '');
        sObjectName = sObjectName.replaceAll('npe03', '');
        sObjectName = sObjectName.replaceAll('__c', '');
        sObjectName = sObjectName.replaceAll('_', '');
        TriggerFactoryHandler handler = null;
        Type t = Type.forName(sObjectName + 'TriggerHandler');
        System.debug('t :: ' + t);
        if(t==null){
            //create instance of the default class
            t = Type.forName('TriggerFactoryHandler');
        }

        handler = (TriggerFactoryHandler) t.newInstance();
        handler.sObjectName = apiName;
        handler.setDisableTrigger(apiName);
        return handler;  
    } 
    @TestVisible
    private static String ObjectName(List <sObject >newObjectList, List <sObject >oldObjectList) {
        String objectName = '';
        if (newObjectList != null &&newObjectList [0]!= null) {
            objectName = newObjectList [0].getSObjectType().getDescribe().getName();
        }
        else if (oldObjectList != null &&oldObjectList [0]!= null){
            objectName = oldObjectList [0].getSObjectType().getDescribe().getName();
        }

        return objectName;
    }   
}