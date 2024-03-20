public abstract class skedHubBase {

    public triggerContext context;

    public static boolean BypassInsertTriggers = false;
    public static boolean BypassUpdateTriggers = false;
    public static boolean BypassDeleteTriggers = false;

    public skedHubBase() {
        this.context = new triggerContext();
    }

    /************************************************************************* VIRTUAL METHODS *********************************************************************/
    public virtual void onBeforeInsertBase() { }
    public virtual void onBeforeUpdateBase() { }
    public virtual void onBeforeDeleteBase() { }

    public virtual void onAfterInsertBase() { }
    public virtual void onAfterUpdateBase() { }
    public virtual void onAfterDeleteBase() { }

    public virtual void onBeforeInsert() { }
    public virtual void onBeforeUpdate() { }
    public virtual void onBeforeDelete() { }

    public virtual void onAfterInsert() { }
    public virtual void onAfterUpdate() { }
    public virtual void onAfterDelete() { }
    public virtual void onAfterUndelete() { }

    /************************************************************************* BASE METHODS ************************************************************************/
    public void handleBeforeInsertBase() {
        onBeforeInsertBase();
    }

    public void handleAfterInsertBase() {
        onAfterInsertBase();
    }

    public void handleBeforeUpdateBase() {
        onBeforeUpdateBase();
    }

    public void handleAfterUpdateBase() {
        onAfterUpdateBase();
    }

    public void handleBeforeDeleteBase() {
        onBeforeDeleteBase();
    }

    public void handleAfterDeleteBase() {
        onAfterDeleteBase();
    }

    /************************************************************************* ACTION METHODS **********************************************************************/
    public void handleBeforeInsert() {
        if (!BypassInsertTriggers) {
            onBeforeInsert();
        }
    }

    public void handleAfterInsert() {
        if (!BypassInsertTriggers) {
            onAfterInsert();
        }
    }

    public void handleBeforeUpdate() {
        if (!BypassUpdateTriggers) {
            onBeforeUpdate();
        }
    }

    public void handleAfterUpdate() {
        if (!BypassUpdateTriggers) {
            onAfterUpdate();
        }
    }

    public void handleBeforeDelete() {
        if (!BypassDeleteTriggers) {
            onBeforeDelete();
        }
    }

    public void handleAfterDelete() {
        if (!BypassDeleteTriggers) {
            onAfterDelete();
        }
    }

    public static void setBypassAllTriggers(Boolean value) {
        BypassInsertTriggers = value;
        BypassUpdateTriggers = value;
        BypassDeleteTriggers = value;
    }

    /************************************************************************* PROTECTED METHODS ********************************************************************/
    protected virtual void preProcessTrigger() {
        sObject firstRecord = this.context.newRecords != null ? this.context.newRecords[0] : this.context.oldRecords[0];
        string sObjectName = firstRecord.getSobjectType().getDescribe().getName();
        skedTriggerContainer container = new skedTriggerContainer();
        container.execute(sObjectName);
    }

    protected virtual void postProcessTrigger() { }

    /************************************************************************* PUBLIC METHODS ***********************************************************************/
    public void processTriggerHandler(Type objectHandlerClass) {
        sObject firstRecord = this.context.newRecords != null ? this.context.newRecords[0] : this.context.oldRecords[0];
        string sObjectName = firstRecord.getSobjectType().getDescribe().getName();
        
        boolean objectActivation = TRUE;
        if (skedTriggerContainer.mapObjectActivation.containsKey(sObjectName)) {
            objectActivation = skedTriggerContainer.mapObjectActivation.get(sObjectName);
        }
        if (objectActivation == TRUE) {
            preProcessTrigger();
            
            if (objectHandlerClass == NULL) {
                return;
            }
            if (this.context.isBefore) {
                executeBefore(objectHandlerClass);
            }
            else {
                executeAfter(objectHandlerClass);
            }
            
            postProcessTrigger();
        }
    }

    public void processTriggerHandler() {
        processTriggerHandler(null);
    }

    /************************************************************************* PRIVATE METHODS **********************************************************************/
    private void executeBefore(Type objectHandlerClass) {
        Boolean isBatchProcessed = FALSE;
        if (this.context.isUpdate) {
            for (sObject sObj : this.context.newRecords) {
                if (isObjectProcessed(objectHandlerClass, sObj)) {
                    isBatchProcessed = TRUE;
                    break;
                }
            }
        }

        skedHubBase triggerHandler = (skedHubBase) objectHandlerClass.newInstance();
        triggerHandler.context = this.context;

        if (this.context.isInsert) {
            triggerHandler.handleBeforeInsertBase();
            triggerHandler.handleBeforeInsert();
        }
        else if (this.context.isUpdate) {
            triggerHandler.handleBeforeUpdateBase();
            if(!isBatchProcessed) {
                triggerHandler.handleBeforeUpdate();
            }
        }
        else if (this.context.isDelete) {
            triggerHandler.handleBeforeDeleteBase();
            triggerHandler.handleBeforeDelete();
        }
    }

    private void executeAfter(Type objectHandlerClass) {
        Boolean isBatchProcessed = FALSE;
        if (this.context.isUpdate) {
            for (sObject sObj : this.context.newRecords) {
                if (isObjectProcessed(objectHandlerClass, sObj)) {
                    isBatchProcessed = TRUE;
                    break;
                }
            }
        }

        skedHubBase triggerHandler = (skedHubBase) objectHandlerClass.newInstance();
        triggerHandler.context = this.context;

        if (this.context.isInsert) {
            triggerHandler.handleAfterInsertBase();
            triggerHandler.handleAfterInsert();
            setObjectsProcessed(objectHandlerClass, this.context.newRecords);
        }
        else if (this.context.isUpdate) {
            triggerHandler.handleAfterUpdateBase();
            if (!isBatchProcessed) {
                triggerHandler.handleAfterUpdate();
                setObjectsProcessed(objectHandlerClass, this.context.newRecords);
            }
        }
        else if (this.context.isDelete) {
            triggerHandler.handleAfterDeleteBase();
            triggerHandler.handleAfterDelete();
        }
    }

    private abstract Boolean isObjectProcessed(Type componentClass, SObject sObj);
    private abstract void setObjectsProcessed(Type componentClass, List<SObject> listSObjects);

    /************************************************************************* NESTED CLASSES **********************************************************************/
    public class triggerContext {
        public boolean isBefore;
        public boolean isAfter;
        public boolean isInsert;
        public boolean isUpdate;
        public boolean isDelete;
        public boolean isUndelete;

        public List<sObject> oldRecords;
        public List<sObject> newRecords;
        public Map<Id, sObject> oldMap;
        public Map<Id, sObject> newMap;

        public string sObjectName;

        public triggerContext() {
            this.isBefore = Trigger.isBefore;
            this.isAfter = Trigger.isAfter;
            this.isInsert = Trigger.isInsert;
            this.isUpdate = Trigger.isUpdate;
            this.isDelete = Trigger.isDelete;
            this.isUndelete = Trigger.isUndelete;
            this.oldRecords = Trigger.old;
            this.newRecords = Trigger.new;
            this.oldMap = Trigger.oldMap;
            this.newMap = Trigger.newMap;
        }
    }

}