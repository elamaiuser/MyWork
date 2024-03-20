/**
*
* @group Triggers
*
* @description Trigger Handler Base to set context, provide methods decide if trigger should execute
*/
public virtual class TriggerFactoryHandler{
    /**
    * @description tracks if this is the first run on the trigger for an SObject
    */
    public boolean firstRun = true;
    //private boolean m_isExecuting = false;
    /**
    * @description used to determine if triggers execute during testing
    */
    public Boolean runWhenRunningTest = true;
    /**
    * @description allows for custom batch sizes
    */
    private integer BatchSize = 0;
    /**
    * @description the name of the sObject in the current context
    */
    public String sObjectName {get; set;}
    
    /**
    * @description If we want to create/update objects in Test classes, we can use this flag to insert the core records without logic running on them, 
    * then change the flag back
    */
    public boolean byPassTrigger = false;
    public boolean disableTrigger = false; //checks if Bypass Trigger custom setting disables user from running triggers

    public Set<Id> asyncInsert {get;}

    /**
    * @description determines if the trigger should actually run
    */  
    public Boolean executeTrigger(){
        return !getByPassTriggerContext() 
                && runWhenRunningTestContext() 
                && !getDisableTrigger();
    }
 
    /**
    * @description method used to grab the byPassTrigger current context 
    */           
    public Boolean getByPassTriggerContext() {
        return byPassTrigger;
    }

    public Boolean runWhenRunningTestContext(){
        Boolean testRunning = Test.isRunningTest();
        return !testRunning || (testRunning && runWhenRunningTest);
    }
    
    /**
    * @description method used to set the byPassTrigger to false which could be used when we don't want a trigger to fire                 
    */
    public void setByPassTriggerFalse(){
       byPassTrigger = false;
   }

    /**
    * @description method used to set the byPassTrigger context back to true which can be used when more than 1 DML operation is executed within a single test method context                  
   */
   public void setByPassTriggerTrue(){ 
       byPassTrigger = true;
   }
 
   /**
    * @description method used to set the byPassTrigger context back to true which can be used when more than 1 DML operation is executed within a single test method context                  
   */
   public void setByPassTrigger(boolean value){ 
       byPassTrigger = value;
   }

   /**
    * @description checks if the user/profile should bypass triggers for the given object
    * @param ObjectName - the name of the object in the current context               
   */
   public void setDisableTrigger(String ObjectName){
        //Bypass_Triggers__c disable = Bypass_Triggers__c.getInstance(UserInfo.getUserId());
        String[] objects = new List<String>();

        //if a standard object need to add __c
        String fieldName = ObjectName.containsIgnoreCase('__c') ? ObjectName : ObjectName + '__c';

        //Boolean objectDisabled = SObjectHelper.hasSObjectField(fieldName, disable) ? Boolean.valueOf(disable.get(ObjectName)) : false;

        //if(disable.Bypass_All_Objects__c || objectDisabled){
        //    disableTrigger = true;
        //}else {
        //    disableTrigger = false;
        //}
   }

   public Boolean getDisableTrigger(){
        return disableTrigger;
   }
    
    public TriggerFactoryHandler(){
        //firstRun = true;
        BatchSize = 0;
    }
    
    public void setParameters(boolean isExecuting, integer size){
       // this.m_isExecuting = isExecuting;
        this.BatchSize = size;
    }
    
    //public virtual Boolean GetIsExecuting() { return m_isExecuting; }
    //public virtual void SetIsExecuting(Boolean bExecuting) { m_isExecuting = bExecuting; }
    
    public virtual Integer GetBatchSize() { return BatchSize; }
    public virtual void SetBatchSize(Integer bSize) { BatchSize = bSize; }
              
    public virtual void OnBeforeInsert(List<SObject> newMappings){}
    
    public virtual void OnAfterInsert(List<SObject> newMappings){}
    
    @future 
    public static void OnAfterInsertAsync(Set<ID> newMappingIDs,String objectName)
    {
        if(String.isBlank(objectName)) return;
        //if(objectName.equalsIgnoreCase('Work'))
        //{
        //    WorkHelper.onAfterInsertAsync(newMappingIDs);
        //}
    }
    
    public virtual void OnBeforeUpdate(List<SObject> oldMappings, List<SObject> updatedMappings, Map<ID, SObject> mappingOldMap, Map<ID, SObject> mappingNewMap){}
    
    public virtual void OnAfterUpdate(List<SObject> oldMappings, List<SObject> updatedMappings, Map<ID, SObject> mappingOldMap, Map<ID, SObject> mappingMap){}
    
    @future 
    public static void OnAfterUpdateAsync(Set<ID> updatedMappingIDs, String objectName)
    {
        if(String.isBlank(objectName)) return;
        //if(objectName.equalsIgnoreCase('Work'))
        //{
        //    WorkHelper.onAfterUpdateAsync(updatedMappingIDs);
        //}
    }
    
    public virtual void OnBeforeDelete(List<SObject> MappingsToDelete, Map<ID, SObject> MappingMap){}
    
    public virtual void OnAfterDelete(List<SObject> deletedMappings, Map<ID, SObject> MappingMap){}
    
    @future 
    public static void OnAfterDeleteAsync(Set<ID> deletedMappingIDs, String objectName){}
    
    public virtual void OnUndelete(List<SObject> restoredMappings){}
    
    //runs at beginning of before trigger
    public virtual void BulkBefore(){}
    
    //runs at end of before but before general cleanup
    public virtual void BulkBeforeCleanup(){}     
    
    //runs at beginning of after trigger
    public virtual void BulkAfter(){}
    
    //runs at end of after but before general cleanup method
    public virtual void BulkAfterCleanUp(){}  
    
    //runs at end of before and at end of After
    public virtual void cleanUp(){}

    //reset variables and such
    public virtual void finish(){}
    
    // public boolean IsTriggerContext{
    //     get{ return m_isExecuting;}
    // }
    
    // public boolean IsVisualforcePageContext{
    //     get{ return !IsTriggerContext;}
    // }
    
    // public boolean IsWebServiceContext{
    //     get{ return !IsTriggerContext;}
    // }
    
    // public boolean IsExecuteAnonymousContext{
    //     get{ return !IsTriggerContext;}
    // }
}