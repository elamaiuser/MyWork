public with sharing class BSF_TaskPlanningWizardController {

    // ============================================================================
    // WRAPPERS
    // ============================================================================

    public class InitData {
        @AuraEnabled public String currentPath;
        @AuraEnabled public String driveStatus;
        @AuraEnabled public List<PackageGroupWrapper> packages;
    }

    public class PackageGroupWrapper {
        @AuraEnabled public String id;            // Task_Package__c Id
        @AuraEnabled public String name;          // Package_Name__c
        @AuraEnabled public Integer sortOrder;    // Sort_Order__c
        @AuraEnabled public Boolean isStandard;   // Derived from Category logic
        @AuraEnabled public List<TaskItemWrapper> tasks;
    }

    public class TaskItemWrapper implements Comparable {
        @AuraEnabled public String id;            // Task_Definition__c Id
        @AuraEnabled public String subject;
        @AuraEnabled public String description;
        @AuraEnabled public String schedulingMethod; // 'Days Offset' or 'Target Date'
        @AuraEnabled public Integer defaultOffset;

        @AuraEnabled public Boolean isChecked = false;
        @AuraEnabled public Boolean isProcessed = false;
        @AuraEnabled public Integer userOffset;
        @AuraEnabled public String userDate;

        // UI Helpers
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
        public String definitionId; // Task_Definition__c Id
        public String schedulingMethod;
        public Integer userOffset;
        public String userDate;
        public String packageId;    // Task_Package__c Id
    }

    // ============================================================================
    // GET METHOD
    // ============================================================================

    @AuraEnabled(cacheable=true)
    public static InitData getTaskBundles(Id recordId) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        InitData response = new InitData();

        // 1. Context
        if(sObjName == 'Account') {
            response.currentPath = [SELECT Planning_Path__c FROM Account WHERE Id = :recordId].Planning_Path__c;
        } else {
            Opportunity opp = [SELECT Planning_Path__c, Drive_Status__c
                               FROM Opportunity
                               WHERE Id = :recordId
                               WITH USER_MODE];
            response.currentPath = opp.Planning_Path__c;
            response.driveStatus = opp.Drive_Status__c;
        }
        if(response.currentPath == null) {
            response.currentPath = 'Standard';
        }

        // 2. Fetch Metadata (Data Driven)
        // Fetch Packages in Order (Standard is #1, Additional is #2, etc.)
        List<Task_Package__c> packages = [SELECT Id, Package_Name__c, Sort_Order__c
                                          FROM Task_Package__c
                                          WITH USER_MODE
                                          ORDER BY Sort_Order__c ASC
                                          ];

        // Fetch Definitions linked to Packages
        List<Task_Package_Item__c> items = [SELECT Task_Package__c, Task_Definition__c, Task_Definition__r.Subject__c,
                                            Task_Definition__r.Description__c, Task_Definition__r.Scheduling_Method__c,
                                            Task_Definition__r.Due_Date_Offset__c, Task_Definition__r.Category__c
                                            FROM Task_Package_Item__c
                                            WITH USER_MODE];

        // 3. Fetch Saved State
        Map<Id, SavePayload> stateMap = getSavedState(recordId, sObjName);

        // 4. Construct Hierarchy
        Map<Id, PackageGroupWrapper> packageMap = new Map<Id, PackageGroupWrapper>();
        List<PackageGroupWrapper> resultPackages = new List<PackageGroupWrapper>();

        // Init Package Wrappers
        for(Task_Package__c pkg : packages) {
            PackageGroupWrapper grp = new PackageGroupWrapper();
            grp.id = pkg.Id;
            grp.name = pkg.Package_Name__c;
            grp.sortOrder = (Integer)pkg.Sort_Order__c;
            grp.tasks = new List<TaskItemWrapper>();
            // If the package name implies Standard (or based on Sort Order 1), mark it
            // Ideally, check the tasks inside, but for grouping we can rely on Name or Sort
            grp.isStandard = (pkg.Package_Name__c.contains('Standard') || pkg.Sort_Order__c == 1);
            packageMap.put(pkg.Id, grp);
            resultPackages.add(grp);
        }

        // 5. Populate Tasks into Packages
        for(Task_Package_Item__c item : items) {
            if(packageMap.containsKey(item.Task_Package__c)) {
                TaskItemWrapper task = new TaskItemWrapper();
                task.id = item.Task_Definition__c;
                task.subject = item.Task_Definition__r.Subject__c;
                task.description = item.Task_Definition__r.Description__c;
                task.schedulingMethod = item.Task_Definition__r.Scheduling_Method__c;
                task.defaultOffset = (Integer)item.Task_Definition__r.Due_Date_Offset__c;

                // UI Flags
                task.isDaysOffset = (task.schedulingMethod == 'Days Offset');
                // Check for Post-Drive (Negative Offset)
                task.isPostDrive = (task.defaultOffset != null && task.defaultOffset < 0);

                // Merge Saved State
                if(stateMap.containsKey(item.Task_Definition__c)) {
                    SavePayload saved = stateMap.get(item.Task_Definition__c);
                    task.isChecked = true;
                    // Send Positive Number to UI
                    task.userOffset = Math.abs(saved.userOffset != null ? saved.userOffset : 0);
                    task.userDate = saved.userDate;

                    // If saved value was negative, ensure UI knows it's Post Drive
                    if(saved.userOffset != null && saved.userOffset < 0) {
                        task.isPostDrive = true;
                    }
                } else {
                    task.userOffset = Math.abs(task.defaultOffset != null ? task.defaultOffset : 0);
                }

                packageMap.get(item.Task_Package__c).tasks.add(task);
            }
        }

        // 6. Sort Tasks inside Packages
        for(PackageGroupWrapper pkg : resultPackages) {
            pkg.tasks.sort();
        }

        response.packages = resultPackages;
        return response;
    }

    // ============================================================================
    // SAVE METHOD
    // ============================================================================

    @AuraEnabled
    public static void saveTaskPlans(Id recordId, String jsonPayload, List<String> selectedPackageIds, String activePath) {
        /*String sObjName = recordId.getSObjectType().getDescribe().getName();
        Boolean isTemplateRecord = isTemplate(recordId);

        // Security
        if(sObjName == 'Opportunity') {
            Opportunity opp = [SELECT Drive_Status__c FROM Opportunity WHERE Id = :recordId];
            if(opp.Drive_Status__c == 'Confirmed') throw new AuraHandledException('Planning is Read-Only for Confirmed Drives.');
        }

        // Scenario: Revert to Standard
        if(activePath == 'Standard') {
            wipeConfiguration(recordId, sObjName); 
            resetToStandardConfig(recordId, sObjName); 
            updatePath(recordId, sObjName, 'Standard');
            if (isTemplateRecord) fireTemplateCascadeBatch(recordId);
            return;
        }

        // Scenario: Save Flexible
        List<SavePayload> selections = (List<SavePayload>) JSON.deserialize(jsonPayload, List<SavePayload>.class);
        Map<String, SavePayload> uniqueMap = new Map<String, SavePayload>();
        // Dedupe: Last selection wins
        for(SavePayload p : selections) uniqueMap.put(p.definitionId, p);

        // Fetch Creation Offsets for Standard Tasks (Schedule Logic)
        Map<Id, Task_Definition__c> defMap = new Map<Id, Task_Definition__c>([
            SELECT Id, Creation_Date_Offset__c, Category__c 
            FROM Task_Definition__c 
            WHERE Id IN :uniqueMap.keySet()
        ]);

        if(sObjName == 'Account' || isTemplateRecord) {
            saveToConfiguration(recordId, sObjName, uniqueMap.values(), defMap);
        } else {
            saveToQueue(recordId, uniqueMap.values(), defMap);
        }

        saveSelectedPackages(recordId, selectedPackageIds);
        updatePath(recordId, sObjName, 'Flexible');

        if (isTemplateRecord) fireTemplateCascadeBatch(recordId);*/
    }

    // ============================================================================
    // PRIVATE HELPERS
    // ============================================================================

    private static Map<Id, SavePayload> getSavedState(Id recordId, String objectApiName) {
        Map<Id, SavePayload> payloadByDefinitionId = new Map<Id, SavePayload>();
        
        if (objectApiName == 'Account' || isTemplate(recordId)) {
            String queryTemplate = 'SELECT Task_Definition__c, Scheduling_Method__c, Configured_Offset__c, Configured_Date__c ' +
                                   'FROM Task_Planning_Default__c WHERE {0} = :recordId WITH USER_MODE';
            String filterField = (objectApiName == 'Account') ? 'Account__c' : 'Template_Opportunity__c';            
            String dynamicQuery = String.format(queryTemplate, new List<String>{ String.escapeSingleQuotes(filterField) });

            for(Task_Planning_Default__c config : Database.query(dynamicQuery)) {
                SavePayload payload = new SavePayload();
                payload.definitionId = config.Task_Definition__c; 
                payload.schedulingMethod = config.Scheduling_Method__c;
                payload.userOffset = (Integer)config.Configured_Offset__c;
                if(config.Configured_Date__c != null) {
                    payload.userDate = String.valueOf(config.Configured_Date__c);
                }
                payloadByDefinitionId.put(config.Task_Definition__c, payload);
            }
        } else {
            for(Planned_Task__c plannedTask : [SELECT Task_Definition__c, Scheduling_Method__c, User_Defined_Offset__c, Target_Date__c, Status__c 
                                               FROM Planned_Task__c WHERE Related_Opportunity__c = :recordId WITH USER_MODE]) {
                SavePayload payload = new SavePayload();
                payload.definitionId = plannedTask.Task_Definition__c;
                payload.schedulingMethod = plannedTask.Scheduling_Method__c;
                payload.userOffset = (Integer)plannedTask.User_Defined_Offset__c;
                if(plannedTask.Target_Date__c != null) {
                    payload.userDate = String.valueOf(plannedTask.Target_Date__c);
                }
                payloadByDefinitionId.put(plannedTask.Task_Definition__c, payload);
            }
        }
        return payloadByDefinitionId;
    }

    /*private static void saveToQueue(Id oppId, List<SavePayload> data, Map<Id, Task_Definition__c> defMap) {
        Opportunity opp = [SELECT Id, Drive_Status__c FROM Opportunity WHERE Id = :oppId];
        delete [SELECT Id FROM Task_Queue__c WHERE Related_Opportunity__c = :oppId AND Status__c = 'Configured'];

        List<Task_Queue__c> ins = new List<Task_Queue__c>();
        for(SavePayload p : data) {
            Task_Queue__c q = new Task_Queue__c();
            q.Related_Opportunity__c = oppId;
            q.Task_Definition__c = p.definitionId;
            q.Task_Package__c = p.packageId;
            q.Status__c = 'Configured';

            if(p.schedulingMethod == 'Days Offset') {
                q.Timing_Type__c = 'Drive Dependent'; // Mapping Picklist Value
                q.User_Defined_Offset__c = p.userOffset; // Negative allowed
            } else {
                q.Timing_Type__c = 'Manual Date';
                q.Manual_Date__c = (p.userDate != null ? Date.valueOf(p.userDate) : Date.today());
            }

            if(defMap.containsKey(p.definitionId)) {
                q.Creation_Offset__c = defMap.get(p.definitionId).Creation_Date_Offset__c;
                // Add Queue Category field if needed for reports based on Definition Category
            }
            ins.add(q);
        }
        insert ins;

        if(opp.Drive_Status__c == 'Confirmed') {
            FlexibleTaskService.evaluateAndGenerateTasks(new Set<Id>{oppId});
        }
    }

    private static void saveToConfiguration(Id parentId, String type, List<SavePayload> data, Map<Id, Task_Definition__c> defMap) {
        String field = (type == 'Account') ? 'Account__c' : 'Template_Opportunity__c';
        delete Database.query('SELECT Id FROM Planning_Configuration__c WHERE ' + field + ' = :parentId');

        List<Planning_Configuration__c> ins = new List<Planning_Configuration__c>();
        for(SavePayload p : data) {
            Planning_Configuration__c c = new Planning_Configuration__c();
            c.put(field, parentId);
            c.Task_Definition__c = p.definitionId;
            c.Task_Package__c = p.packageId;

            if(p.schedulingMethod == 'Days Offset') {
                c.Timing_Type__c = 'Drive Dependent';
                c.Configured_Offset__c = p.userOffset;
            } else {
                c.Timing_Type__c = 'Immediate';
                c.Configured_Date__c = (p.userDate != null ? Date.valueOf(p.userDate) : Date.today());
            }

            if(defMap.containsKey(p.definitionId)) {
                c.Configured_Creation_Offset__c = defMap.get(p.definitionId).Creation_Date_Offset__c;
            }
            ins.add(c);
        }
        if(!ins.isEmpty()) insert ins;
    }

    private static void saveSelectedPackages(Id recordId, List<String> packageIds) {
        String sObj = recordId.getSObjectType().getDescribe().getName();
        String field = sObj == 'Account' ? 'Account__c' : 'Opportunity__c';
        delete Database.query('SELECT Id FROM Selected_Bundle__c WHERE ' + field + ' = :recordId');

        List<Selected_Bundle__c> ins = new List<Selected_Bundle__c>();
        for(String pkgId : packageIds) {
            Selected_Bundle__c sb = new Selected_Bundle__c();
            sb.Task_Package__c = pkgId;
            sb.put(field, recordId);
            ins.add(sb);
        }
        if(!ins.isEmpty()) insert ins;
    }*/

    private static void resetToStandardConfig(Id recordId, String sObjName) {
        // Fetch Standard Tasks via Category
        List<Task_Definition__c> stdTasks = [
            SELECT Id, Due_Date_Offset__c, Creation_Date_Offset__c, Scheduling_Method__c, Category__c
            FROM Task_Definition__c
            WHERE Category__c = 'Standard'
        ];

        // Must map them to the Standard Package ID for consistency
        List<Task_Package__c> stdPkg = [SELECT Id FROM Task_Package__c WHERE Sort_Order__c = 1 LIMIT 1];
        String stdPkgId = stdPkg.isEmpty() ? null : stdPkg[0].Id;

        List<SavePayload> dummyPayloads = new List<SavePayload>();
        for(Task_Definition__c tm : stdTasks) {
            SavePayload p = new SavePayload();
            p.definitionId = tm.Id;
            p.schedulingMethod = (tm.Scheduling_Method__c == 'Days Offset') ? 'Days Offset' : 'Target Date';
            p.userOffset = (Integer)tm.Due_Date_Offset__c;
            p.packageId = stdPkgId;
            dummyPayloads.add(p);
        }

        Map<Id, Task_Definition__c> infoMap = new Map<Id, Task_Definition__c>(stdTasks);

        if(sObjName == 'Account' || isTemplate(recordId)) {
            //saveToConfiguration(recordId, sObjName, dummyPayloads, infoMap);
        } else {
            //saveToQueue(recordId, dummyPayloads, infoMap);
        }
    }

    /*private static void wipeConfiguration(Id recordId, String sObjName) {
        String configField = (sObjName == 'Account') ? 'Account__c' : 'Template_Opportunity__c';
        String bundleField = (sObjName == 'Account') ? 'Account__c' : 'Opportunity__c';
        if(sObjName == 'Account' || isTemplate(recordId)) {
            delete Database.query('SELECT Id FROM Planning_Configuration__c WHERE ' + configField + ' = :recordId');
        } else {
            delete [SELECT Id FROM Task_Queue__c WHERE Related_Opportunity__c = :recordId];
        }
        delete Database.query('SELECT Id FROM Selected_Bundle__c WHERE ' + bundleField + ' = :recordId');
    }*/

    private static void updatePath(Id recordId, String sObjName, String pathValue) {
        if(sObjName == 'Account') {
            update new Account(Id = recordId, Planning_Path__c = pathValue);
        } else {
            update new Opportunity(Id = recordId, Planning_Path__c = pathValue, Is_Path_Overridden__c = true);
        }
    }

    private static void fireTemplateCascadeBatch(Id templateId) {
        if (!System.isBatch() && !System.isFuture()) {
            Database.executeBatch(new FlexiblePathTemplateBatch(new Set<Id>{templateId}), 50);
        }
    }

    private static Boolean isTemplate(Id oppId) {
        if(oppId.getSObjectType() == Account.SObjectType) return false;
        return [SELECT Is_Template__c FROM Opportunity WHERE Id =: oppId WITH USER_MODE].Is_Template__c;
    }
}