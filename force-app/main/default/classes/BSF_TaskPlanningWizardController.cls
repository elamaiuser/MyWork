/**
 * @Description        : Controller for Task Planning Wizard. Handles metadata-driven
 *                       task configuration for Accounts, Opportunities, and Templates.
 **/
public without sharing class BSF_TaskPlanningWizardController {

    // ============================================================================
    // WRAPPERS
    // ============================================================================

    public class InitData {
        @AuraEnabled public String currentPath;
        @AuraEnabled public String driveStatus;
        @AuraEnabled public Boolean isOverridden;
        @AuraEnabled public String objectApiName;        
        @AuraEnabled public List<PackageGroupWrapper> packages;
    }

    public class PackageGroupWrapper {
        @AuraEnabled public Id packageId;
        @AuraEnabled public String name;
        @AuraEnabled public Integer sortOrder;
        @AuraEnabled public Boolean isStandard;
        @AuraEnabled public List<TaskItemWrapper> tasks;
        @AuraEnabled public Boolean hideSelectAll;
    }

    public class TaskItemWrapper implements Comparable {
        @AuraEnabled public Id taskDefinitionId;
        @AuraEnabled public String subject;
        @AuraEnabled public String description;
        @AuraEnabled public String schedulingMethod; 
        @AuraEnabled public Integer defaultOffset;

        @AuraEnabled public Boolean isChecked = false;
        @AuraEnabled public Integer userOffset;
        @AuraEnabled public String userDate;

        @AuraEnabled public Boolean isDaysOffset;
        @AuraEnabled public Boolean isPostDrive;

        // Sort: Descending by Offset (Timeline view)
        public Integer compareTo(Object compareTo) {
            TaskItemWrapper other = (TaskItemWrapper) compareTo;
            Integer thisOffset = this.defaultOffset != null ? this.defaultOffset : 0;
            Integer otherOffset = other.defaultOffset != null ? other.defaultOffset : 0;
            
            if (thisOffset > otherOffset) {
                return -1;
            }
            if (thisOffset < otherOffset) {
                return 1;
            }
            return this.subject.compareTo(other.subject);
        }
    }

    public class SavePayload {
        @AuraEnabled public String definitionId; 
        @AuraEnabled public String schedulingMethod;
        @AuraEnabled public Integer userOffset;
        @AuraEnabled public String userDate;
        @AuraEnabled public String packageId; 
    }

    // ============================================================================
    // PUBLIC @AuraEnabled METHODS
    // ============================================================================

    @AuraEnabled(cacheable=true)
    public static InitData getTaskBundles(Id recordId) {
        String objectApiName = recordId.getSObjectType().getDescribe().getName();
        InitData response = new InitData();
        response.objectApiName = objectApiName;

        // 1. Fetch Context Details
        if (objectApiName == 'Account') {
            Account acc = [SELECT Planning_Path__c FROM Account WHERE Id = :recordId WITH SYSTEM_MODE];
            response.currentPath = acc.Planning_Path__c;
            response.isOverridden = false;
        } else {
            Opportunity opp = [SELECT Planning_Path__c, Drive_Status__c, Is_Path_Overridden__c FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE];
            response.currentPath = opp.Planning_Path__c;
            response.driveStatus = opp.Drive_Status__c;
            response.isOverridden = opp.Is_Path_Overridden__c;
        }
        
        if (response.currentPath == null && objectApiName == 'Account') {
            response.currentPath = 'Standard';
        }

        // 2. Fetch Metadata
        List<Task_Package__c> taskPackages = [SELECT Id, Name, Sort_Order__c, Hide_Select_All__c 
                                              FROM Task_Package__c WITH SYSTEM_MODE ORDER BY Sort_Order__c ASC];
        List<Task_Package_Item__c> packageItems = [SELECT Task_Package__c, Task_Definition__c, Task_Definition__r.Name,
                                            Task_Definition__r.Description__c, Task_Definition__r.Scheduling_Method__c,
                                            Task_Definition__r.Due_Date_Offset__c FROM Task_Package_Item__c WITH SYSTEM_MODE];
        
        Map<String, SavePayload> savedStateByKey = getSavedState(recordId, objectApiName);

        // 3. Construct Hierarchy
        Map<Id, PackageGroupWrapper> packageMap = new Map<Id, PackageGroupWrapper>();
        for (Task_Package__c pkg : taskPackages) {
            PackageGroupWrapper groupWrap = new PackageGroupWrapper();
            groupWrap.packageId = pkg.Id;
            groupWrap.name = pkg.Name;
            groupWrap.sortOrder = (Integer)pkg.Sort_Order__c;
            groupWrap.hideSelectAll = pkg.Hide_Select_All__c;
            groupWrap.tasks = new List<TaskItemWrapper>();
            groupWrap.isStandard = (pkg.Name.contains('Standard') || pkg.Sort_Order__c == 1);
            packageMap.put(pkg.Id, groupWrap);
        }

        for (Task_Package_Item__c item : packageItems) {
            if (!packageMap.containsKey(item.Task_Package__c)) {
                continue;
            }

            TaskItemWrapper task = new TaskItemWrapper();
            task.taskDefinitionId = item.Task_Definition__c;
            task.subject = item.Task_Definition__r.Name;
            task.description = item.Task_Definition__r.Description__c;
            task.schedulingMethod = item.Task_Definition__r.Scheduling_Method__c;
            task.defaultOffset = (Integer)item.Task_Definition__r.Due_Date_Offset__c;
            task.isDaysOffset = (task.schedulingMethod == 'Days Offset');

            // This ensures we only check the box if the Saved Record matches THIS Package
            String savedStateKey = item.Task_Definition__c + '-' + item.Task_Package__c;

            if (savedStateByKey.containsKey(savedStateKey)) {
                SavePayload saved = savedStateByKey.get(savedStateKey);
                task.isChecked = true;
                task.userOffset = Math.abs(saved.userOffset != null ? saved.userOffset : 0);
                task.userDate = saved.userDate;
                task.isPostDrive = (saved.userOffset != null && saved.userOffset < 0);
            } else {
                task.userOffset = Math.abs(task.defaultOffset != null ? task.defaultOffset : 0);
                task.isPostDrive = (task.defaultOffset != null && task.defaultOffset < 0);
            }

            packageMap.get(item.Task_Package__c).tasks.add(task);
        }

        for (PackageGroupWrapper pkg : packageMap.values()) {
            pkg.tasks.sort();
        }

        response.packages = packageMap.values();
        return response;
    }

    @AuraEnabled
    public static void saveTaskPlans(Id recordId, String jsonPayload, List<String> selectedPackageIds, String activePath) {
        try {        
            String objectApiName = recordId.getSObjectType().getDescribe().getName();
            Boolean isTemplateRecord = isTemplate(recordId);
            String currentPath;

            // Validation: Block Confirmed Drives
            if (objectApiName == 'Opportunity') {
                Opportunity opp = [SELECT Drive_Status__c, Planning_Path__c FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE];
                currentPath = opp.Planning_Path__c;
                if (opp.Drive_Status__c == 'Confirmed') {
                    throw new AuraHandledException('Planning is Read-Only for Confirmed Drives.');
                }
            } else {
                Account acc = [SELECT Planning_Path__c FROM Account WHERE Id = :recordId WITH SYSTEM_MODE];
                currentPath = acc.Planning_Path__c;
            }

            Boolean isPathChanged = (currentPath != activePath);

            // Scenario A: Revert to Standard
            if (activePath == 'Standard') {
                wipeConfiguration(recordId, objectApiName); 
                resetToStandardConfig(recordId, objectApiName); 
                updatePath(recordId, objectApiName, 'Standard');
                handleBatchTrigger(isPathChanged, isTemplateRecord, objectApiName, recordId);                           
                return;
            }

            // Scenario B: Flexible Save
            List<SavePayload> selections = (List<SavePayload>) JSON.deserialize(jsonPayload, List<SavePayload>.class);
            Set<Id> definitionIds = new Set<Id>();
            for (SavePayload p : selections) {
                definitionIds.add(p.definitionId);
            }

            Map<Id, Task_Definition__c> taskDefinitionsById = new Map<Id, Task_Definition__c>([
                SELECT Id, Creation_Date_Offset__c, Name FROM Task_Definition__c 
                WHERE Id IN :definitionIds WITH SYSTEM_MODE
            ]);

            if (objectApiName == 'Account' || isTemplateRecord) {
                saveToConfiguration(recordId, objectApiName, selections, taskDefinitionsById);
            } else {
                saveToQueue(recordId, selections, taskDefinitionsById);
            }

            saveSelectedPackages(recordId, selectedPackageIds);
            updatePath(recordId, objectApiName, 'Flexible');
            handleBatchTrigger(isPathChanged, isTemplateRecord, objectApiName, recordId);            
        } catch (Exception ex) {
            throw new AuraHandledException('Error Saving Task Plans: ' + ex.getMessage());
        }
    }

    // ============================================================================
    // PRIVATE HELPERS (Logic & Persistence)
    // ============================================================================

    private static Map<String, SavePayload> getSavedState(Id recordId, String objectApiName) {
        Map<String, SavePayload> payloadByKey = new Map<String, SavePayload>();
        
        if (objectApiName == 'Account' || isTemplate(recordId)) {
            String lookupField = getConfigurationLookupField(objectApiName);
            String query = String.format('SELECT Task_Definition__c, Task_Package__c, Scheduling_Method__c, Configured_Offset__c, Configured_Date__c FROM Task_Planning_Default__c WHERE {0} = :recordId WITH SYSTEM_MODE', 
                           new List<String>{ String.escapeSingleQuotes(lookupField) });

            for (Task_Planning_Default__c config : Database.query(query)) {
                SavePayload payload = new SavePayload();
                payload.definitionId = config.Task_Definition__c; 
                payload.schedulingMethod = config.Scheduling_Method__c;
                payload.userOffset = (Integer)config.Configured_Offset__c;
                payload.packageId = config.Task_Package__c;
                if (config.Configured_Date__c != null) {
                    payload.userDate = String.valueOf(config.Configured_Date__c);
                }
                String key = config.Task_Definition__c + '-' + config.Task_Package__c;
                payloadByKey.put(key, payload);
            }
        } else {
            for (Planned_Task__c pt : [SELECT Task_Definition__c, Task_Package__c, Scheduling_Method__c, User_Defined_Offset__c, Target_Date__c 
                                      FROM Planned_Task__c WHERE Related_Opportunity__c = :recordId WITH SYSTEM_MODE]) {
                SavePayload payload = new SavePayload();
                payload.definitionId = pt.Task_Definition__c;
                payload.packageId = pt.Task_Package__c;
                payload.schedulingMethod = pt.Scheduling_Method__c;
                payload.userOffset = (Integer)pt.User_Defined_Offset__c;
                if (pt.Target_Date__c != null) {
                    payload.userDate = String.valueOf(pt.Target_Date__c);
                }
                String key = pt.Task_Definition__c + '-' + pt.Task_Package__c;
                payloadByKey.put(key, payload);
            }
        }
        return payloadByKey;
    }

    private static void saveToQueue(Id opportunityId, List<SavePayload> payloads, Map<Id, Task_Definition__c> taskDefinitionsById) {
        List<Planned_Task__c> existingTasks = [SELECT Id FROM Planned_Task__c WHERE Related_Opportunity__c = :opportunityId AND Status__c = 'Configured' WITH SYSTEM_MODE];
        if (!existingTasks.isEmpty()) {
            Database.delete(existingTasks, false, AccessLevel.SYSTEM_MODE);
        }

        Opportunity opp = [SELECT Id, Drive_Status__c FROM Opportunity WHERE Id = :opportunityId WITH SYSTEM_MODE];

        List<Planned_Task__c> tasksToInsert = new List<Planned_Task__c>();
        for (SavePayload payload : payloads) {
            Planned_Task__c task = new Planned_Task__c(
                Related_Opportunity__c = opportunityId,
                Task_Definition__c = payload.definitionId,
                Task_Package__c = payload.packageId,
                Status__c = 'Configured'
            );
            if (payload.schedulingMethod == 'Days Offset') {
                task.Scheduling_Method__c = 'Days Offset';
                task.User_Defined_Offset__c = payload.userOffset;
            } else {
                task.Scheduling_Method__c = 'Target Date';
                task.Target_Date__c = (String.isNotBlank(payload.userDate) ? Date.valueOf(payload.userDate) : Date.today());
            }
            if (taskDefinitionsById.containsKey(payload.definitionId)) {
                Task_Definition__c taskDef = taskDefinitionsById.get(payload.definitionId);
                task.Creation_Offset__c = taskDef.Creation_Date_Offset__c;
                task.Subject__c = taskDef.Name;
            }
            task.Config_Key__c = BSF_TaskPlanningService.generateConfigKey(task);
            tasksToInsert.add(task);
        }        
        Database.upsert(tasksToInsert, Planned_Task__c.Fields.Config_Key__c, false, AccessLevel.SYSTEM_MODE);

        if(opp.Drive_Status__c == 'Confirmed') {
            System.debug('Drive is Confirmed - Skipping Task Generation');
            BSF_TaskPlanningService.generateTasksFromQueue(new Set<Id>{opportunityId});
        }
    }

    private static void saveToConfiguration(Id recordId, String objectApiName, List<SavePayload> payloads, Map<Id, Task_Definition__c> taskDefinitionsById) {
        String lookupField = getConfigurationLookupField(objectApiName);
        wipeConfiguration(recordId, objectApiName);

        List<Task_Planning_Default__c> configsToInsert = new List<Task_Planning_Default__c>();
        for (SavePayload payload : payloads) {
            Task_Planning_Default__c config = new Task_Planning_Default__c();
            config.put(lookupField, recordId);
            config.Task_Definition__c = payload.definitionId;
            config.Task_Package__c = payload.packageId;

            if (payload.schedulingMethod == 'Days Offset') {
                config.Scheduling_Method__c = 'Days Offset';
                config.Configured_Offset__c = payload.userOffset;
            } else {
                config.Scheduling_Method__c = 'Target Date';
                config.Configured_Date__c = (payload.userDate != null ? Date.valueOf(payload.userDate) : Date.today());
            }

            /*if (taskDefinitionsById.containsKey(payload.definitionId)) {
                config.Configured_Offset__c = taskDefinitionsById.get(payload.definitionId).Creation_Date_Offset__c;
            }*/
            configsToInsert.add(config);
        }
        insert as user configsToInsert;
    }

    private static void saveSelectedPackages(Id recordId, List<String> packageIds) {
        String lookupField = getBundleLookupField(recordId.getSObjectType().getDescribe().getName());
        List<Task_Selected_Package__c> bundlesToInsert = new List<Task_Selected_Package__c>();

        for (Id packageId : packageIds) {
            Task_Selected_Package__c bundle = new Task_Selected_Package__c(Task_Package__c = packageId);
            bundle.put(lookupField, recordId);
            bundlesToInsert.add(bundle);
        }

        if (!bundlesToInsert.isEmpty()) {
            insert as user bundlesToInsert;
        }
    }

    private static void resetToStandardConfig(Id recordId, String objectApiName) {
        List<Task_Definition__c> stdDefinitions = [SELECT Id, Name, Due_Date_Offset__c, Creation_Date_Offset__c, Scheduling_Method__c
                                                   FROM Task_Definition__c WHERE Category__c = 'Standard' WITH SYSTEM_MODE];
        
        List<Task_Package__c> stdPkgs = [SELECT Id FROM Task_Package__c WHERE Sort_Order__c = 1 WITH SYSTEM_MODE LIMIT 1];
        Id stdPkgId = stdPkgs.isEmpty() ? null : stdPkgs[0].Id;

        List<SavePayload> payloads = new List<SavePayload>();
        for (Task_Definition__c def : stdDefinitions) {
            SavePayload p = new SavePayload();
            p.definitionId = def.Id;
            p.schedulingMethod = (def.Scheduling_Method__c == 'Days Offset') ? 'Days Offset' : 'Target Date';
            p.userOffset = (Integer)def.Due_Date_Offset__c;
            p.packageId = stdPkgId;
            payloads.add(p);
        }

        if (objectApiName == 'Account' || isTemplate(recordId)) {
            saveToConfiguration(recordId, objectApiName, payloads, new Map<Id, Task_Definition__c>(stdDefinitions));
        } else {
            saveToQueue(recordId, payloads, new Map<Id, Task_Definition__c>(stdDefinitions));
        }
    }

    private static void wipeConfiguration(Id recordId, String objectApiName) {
        String bundleField = getBundleLookupField(objectApiName);
        
        // Wipe Bundles
        String bundleQuery = String.format('SELECT Id FROM Task_Selected_Package__c WHERE {0} = :recordId', new List<String>{ String.escapeSingleQuotes(bundleField) });
        List<Task_Selected_Package__c> existingBundles = Database.query(bundleQuery);
        if (!existingBundles.isEmpty()) {
            delete existingBundles;
        }

        // Wipe Specific Settings
        if (objectApiName == 'Account' || isTemplate(recordId)) {
            String configField = getConfigurationLookupField(objectApiName);
            String configQuery = String.format('SELECT Id FROM Task_Planning_Default__c WHERE {0} = :recordId', new List<String>{ String.escapeSingleQuotes(configField) });
            List<Task_Planning_Default__c> existingConfigs = Database.query(configQuery);
            if (!existingConfigs.isEmpty()) {
                delete existingConfigs;
            }
        } else {
            List<Planned_Task__c> tasksToWipe = [SELECT Id FROM Planned_Task__c WHERE Related_Opportunity__c = :recordId AND Status__c = 'Configured' WITH SYSTEM_MODE];
            if (!tasksToWipe.isEmpty()) {
                delete tasksToWipe;
            }
        }
    }

    private static void updatePath(Id recordId, String objectApiName, String pathValue) {
        if (objectApiName == 'Account') {
            update as user new Account(Id = recordId, Planning_Path__c = pathValue);
        } else {
            update as user new Opportunity(Id = recordId, Planning_Path__c = pathValue, Is_Path_Overridden__c = true);
        }
    }

    private static void handleBatchTrigger(Boolean isPathChanged, Boolean isTemplateRecord, String objectApiName, Id recordId) {
        if (!isPathChanged) {
            if (isTemplateRecord) {
                fireTemplateCascadeBatch(recordId);
            } else if (objectApiName == 'Account') {
                fireAccountCascadeBatch(recordId);
            }
        }
    }

    // ============================================================================
    // UTILITIES
    // ============================================================================

    private static String getConfigurationLookupField(String objectName) {
        return (objectName == 'Account') ? 'Account__c' : 'Template_Opportunity__c';
    }

    private static String getBundleLookupField(String objectName) {
        return (objectName == 'Account') ? 'Account__c' : 'Opportunity__c';
    }

    private static Boolean isTemplate(Id recordId) {
        if (recordId.getSObjectType() == Account.SObjectType) {
            return false;
        }
        return [SELECT Is_Template__c FROM Opportunity WHERE Id = :recordId WITH SYSTEM_MODE].Is_Template__c;
    }

    private static void fireTemplateCascadeBatch(Id templateId) {
        if (!System.isBatch() && !System.isFuture()) {
            System.debug('Firing Template Cascade Batch for Template Id: ' + templateId);
            Database.executeBatch(new BSF_TemplateTaskPlanningCascadeBatch(new Set<Id>{templateId}), 50);
        }
    }

    private static void fireAccountCascadeBatch(Id accountId) {
        if (!System.isBatch() && !System.isFuture()) {
            Database.executeBatch(new BSF_AccountTaskPlanningCascadeBatch(new Set<Id>{accountId}), 50);
        }
    }
}