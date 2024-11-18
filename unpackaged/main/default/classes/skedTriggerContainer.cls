public class skedTriggerContainer {
    
    public static Set<Id> revetingDcrRecordIds = new Set<Id>();
    public static Map<string, boolean> mapObjectActivation = new Map<string, boolean>();

    private static final List<String> MOBILE_APP_SOBJECT_BYPASSES = new List<String>{
        'Beforesked_Drive__c', 'Beforesked_Drive_Shift__c', 'Beforesked__Availability__c', 'Beforesked__Activity_Resource__c',
        'Beforesked__Job__c', 'Beforesked__Job_Allocation__c', 'Beforesked_Site_Feedback__c'
    };

    public skedTriggerContainer() {
        sObjectStack = new List<string>();
    }

    protected List<string> sObjectStack;
    
    public void execute(string sObjectName) {
        triggerContext context = getTriggerContext();
        context.sObjectName = sObjectName;
        string triggerActionOnObject = context.isBefore == TRUE ? 'Before' : 'After';
        triggerActionOnObject += sObjectName;
        
        //tracking sObjectStack
        if (sObjectStack.contains(triggerActionOnObject)) {
            return; 
        }
        sObjectStack.add(triggerActionOnObject);


        if (!MOBILE_APP_SOBJECT_BYPASSES.contains(sObjectStack[0])) {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        }

        if (!skedSetting.instance.Admin.migrationMode) {
            sendNotifications(context);
        }
    }
    
    /********************************************************* Private methods ***********************************************************/
    private void sendNotifications(triggerContext context) {
        if (context.isAfter && (context.isInsert || context.isUpdate)) {
            string action = context.isInsert ? 'Insert' : 'Update';
            new skedTriggerActionNotificationService(action, context.sObjectName).generateNotifications(context.newRecords, context.oldMap);
        }
    }
    
    private triggerContext getTriggerContext() {
        triggerContext context = new triggerContext();
        context.isBefore = Trigger.isBefore;
        context.isAfter = Trigger.isAfter;
        context.isInsert = Trigger.isInsert;
        context.isUpdate = Trigger.isUpdate;
        context.isDelete = Trigger.isDelete;
        context.isUndelete = Trigger.isUndelete;
        context.oldRecords = Trigger.old;
        context.newRecords = Trigger.new;
        context.oldMap = Trigger.oldMap;
        
        return context;
    }
    
    /********************************************************* Nested classes ***********************************************************/
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

        public string sObjectName;
    }

}