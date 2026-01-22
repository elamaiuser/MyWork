/**
 * @Description        : Service class to handle Task Generation, Date Syncing, 
 *                       and Configuration Inheritance across Accounts and Opportunities.
 **/
public with sharing class BSF_TaskPlanningService {
    
    // ============================================================================
    // 1. TASK GENERATION (EXECUTION)
    // ============================================================================
    public static void generateTasksFromQueue(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        List<Planned_Task__c> configuredPlannedTasks = [
            SELECT Id, Subject__c, Scheduling_Method__c, User_Defined_Offset__c, Target_Date__c,
                   Related_Opportunity__c, Related_Opportunity__r.Drive_Date__c, Related_Opportunity__r.OwnerId
            FROM Planned_Task__c
            WHERE Related_Opportunity__c IN :opportunityIds 
            AND Status__c = :BSF_Constants.PLANNED_TASK_STATUS_CONFIGURED
            WITH USER_MODE
        ];

        if (configuredPlannedTasks.isEmpty()) {
            return;
        }

        List<Task> standardTasksToCreate = new List<Task>();
        List<Planned_Task__c> processedPlannedTasks = new List<Planned_Task__c>();

        for (Planned_Task__c plannedTask : configuredPlannedTasks) {
            Task newTask = new Task(
                WhatId = plannedTask.Related_Opportunity__c,
                Subject = plannedTask.Subject__c,
                OwnerId = plannedTask.Related_Opportunity__r.OwnerId,
                Status = BSF_Constants.STATUS_NOT_STARTED
            );

            if (plannedTask.Scheduling_Method__c == BSF_Constants.PLANNED_TASK_SCHEDULING_METHOD_DAYS_OFFSET) {
                newTask.ActivityDate = calculateActivityDate(plannedTask.Related_Opportunity__r.Drive_Date__c, (Integer)plannedTask.User_Defined_Offset__c);
                newTask.Drive_Offset_Days__c = plannedTask.User_Defined_Offset__c;
                newTask.Is_Drive_Dependent__c = true;
            } else {
                newTask.ActivityDate = plannedTask.Target_Date__c;
            }

            standardTasksToCreate.add(newTask);
            plannedTask.Status__c = BSF_Constants.PLANNED_TASK_STATUS_PROCESSED;
            processedPlannedTasks.add(plannedTask);
        }

        if (!standardTasksToCreate.isEmpty()) {
            handleDatabaseResults(Database.insert(standardTasksToCreate, false, AccessLevel.USER_MODE), 'Standard Task Creation');
        }
        if (!processedPlannedTasks.isEmpty()) {
            handleDatabaseResults(Database.update(processedPlannedTasks, false, AccessLevel.USER_MODE), 'Marking Planned Tasks Processed');
        }
    }

    // ============================================================================
    // 2. REACTIVITY (SYNC DATES)
    // ============================================================================
    public static void syncTaskDates(Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap) {
        Set<Id> opportunityIdsWithDateChange = new Set<Id>();
        for (Opportunity opp : newOpportunityMap.values()) {
            Opportunity oldOpp = (oldOpportunityMap != null) ? oldOpportunityMap.get(opp.Id) : null;
            if (opp.Drive_Date__c != null && oldOpp != null && opp.Drive_Date__c != oldOpp.Drive_Date__c) {
                opportunityIdsWithDateChange.add(opp.Id);
            }
        }

        if (opportunityIdsWithDateChange.isEmpty()) {
            return;
        }

        List<Task> dependentTasksToUpdate = [
            SELECT Id, WhatId, Drive_Offset_Days__c FROM Task 
            WHERE WhatId IN :opportunityIdsWithDateChange AND Is_Drive_Dependent__c = TRUE AND IsClosed = FALSE
            WITH USER_MODE
        ];

        for (Task taskRecord : dependentTasksToUpdate) {
            Opportunity parentOpp = newOpportunityMap.get(taskRecord.WhatId);
            if (parentOpp != null && taskRecord.Drive_Offset_Days__c != null) {
                taskRecord.ActivityDate = calculateActivityDate(parentOpp.Drive_Date__c, (Integer)taskRecord.Drive_Offset_Days__c);
            }
        }

        if (!dependentTasksToUpdate.isEmpty()) {
            handleDatabaseResults(Database.update(dependentTasksToUpdate, false, AccessLevel.USER_MODE), 'Syncing Task Dates');
        }
    }

    // ============================================================================
    // 3. INHERITANCE (CLONE DOWN)
    // ============================================================================
    public static void inheritConfiguration(List<Opportunity> newOpportunities) {
        List<Task_Planning_Default__c> clonedDefaultConfigs = new List<Task_Planning_Default__c>();
        List<Planned_Task__c> newPlannedTasks = new List<Planned_Task__c>();
        List<Task_Selected_Package__c> clonedSelectedBundles = new List<Task_Selected_Package__c>();

        Set<Id> accountIds = new Set<Id>();
        Set<Id> templateIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            if (opp.AccountId != null) { accountIds.add(opp.AccountId); }
            if (opp.Parent_Template_Id__c != null) { templateIds.add(opp.Parent_Template_Id__c); }
        }

        Map<Id, List<Task_Planning_Default__c>> configsByAccountId = getParentConfigs(accountIds, 'Account__c');
        Map<Id, List<Task_Planning_Default__c>> configsByTemplateId = getParentConfigs(templateIds, 'Template_Opportunity__c');
        Map<Id, List<Task_Selected_Package__c>> bundlesByAccountId = getParentBundles(accountIds, 'Account__c');
        Map<Id, List<Task_Selected_Package__c>> bundlesByTemplateId = getParentBundles(templateIds, 'Opportunity__c');

        for (Opportunity opp : newOpportunities) {
            List<Task_Planning_Default__c> sourceConfigs = new List<Task_Planning_Default__c>();
            List<Task_Selected_Package__c> sourceBundles = new List<Task_Selected_Package__c>();

            if (opp.Parent_Template_Id__c != null && configsByTemplateId.containsKey(opp.Parent_Template_Id__c)) {
                sourceConfigs = configsByTemplateId.get(opp.Parent_Template_Id__c);
                sourceBundles = bundlesByTemplateId.get(opp.Parent_Template_Id__c) ?? new List<Task_Selected_Package__c>();
            } else if (opp.AccountId != null && configsByAccountId.containsKey(opp.AccountId)) {
                sourceConfigs = configsByAccountId.get(opp.AccountId);
                sourceBundles = bundlesByAccountId.get(opp.AccountId) ?? new List<Task_Selected_Package__c>();
            }

            if (opp.Is_Template__c) {
                for (Task_Planning_Default__c src : sourceConfigs) {
                    clonedDefaultConfigs.add(createConfigClone(src, opp.Id, 'Template_Opportunity__c'));
                }
            } else {
                for (Task_Planning_Default__c src : sourceConfigs) {
                    newPlannedTasks.add(createPlannedTaskFromConfig(src, opp.Id));
                }
            }
            for (Task_Selected_Package__c srcBundle : sourceBundles) {
                clonedSelectedBundles.add(createBundleClone(srcBundle, opp.Id, 'Opportunity__c'));
            }
        }

        if (!clonedDefaultConfigs.isEmpty()) {
            handleDatabaseResults(Database.insert(clonedDefaultConfigs, false, AccessLevel.USER_MODE), 'Cloning Default Configs');
        }
        if (!newPlannedTasks.isEmpty()) {
            handleDatabaseResults(Database.insert(newPlannedTasks, false, AccessLevel.USER_MODE), 'Creating Initial Planned Tasks');
        }
        if (!clonedSelectedBundles.isEmpty()) {
            handleDatabaseResults(Database.insert(clonedSelectedBundles, false, AccessLevel.USER_MODE), 'Cloning Selected Bundles');
        }
    }

    // ============================================================================
    // 4. CASCADE HELPERS (BATCH)
    // ============================================================================
    public static void cascadeAccountToTemplates(List<Opportunity> templatesToSync) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity t : templatesToSync) { accountIds.add(t.AccountId); }

        Map<Id, Account> accountsById = new Map<Id, Account>([SELECT Id, Planning_Path__c FROM Account WHERE Id IN :accountIds WITH USER_MODE]);
        Map<Id, List<Task_Planning_Default__c>> configsByAccountId = getParentConfigs(accountIds, 'Account__c');
        Map<Id, List<Task_Selected_Package__c>> bundlesByAccountId = getParentBundles(accountIds, 'Account__c');

        List<Task_Planning_Default__c> newConfigs = new List<Task_Planning_Default__c>();
        List<Task_Selected_Package__c> newBundles = new List<Task_Selected_Package__c>();
        
        List<Task_Planning_Default__c> existingConfigs = [SELECT Id FROM Task_Planning_Default__c WHERE Template_Opportunity__c IN :templatesToSync WITH USER_MODE];
        List<Task_Selected_Package__c> existingBundles = [SELECT Id FROM Task_Selected_Package__c WHERE Opportunity__c IN :templatesToSync WITH USER_MODE];

        if (!existingConfigs.isEmpty()) { handleDatabaseResults(Database.delete(existingConfigs, false, AccessLevel.USER_MODE), 'Wiping Template Configs'); }
        if (!existingBundles.isEmpty()) { handleDatabaseResults(Database.delete(existingBundles, false, AccessLevel.USER_MODE), 'Wiping Template Bundles'); }

        for (Opportunity template : templatesToSync) {
            Account parentAccount = accountsById.get(template.AccountId);
            if (parentAccount != null) { template.Planning_Path__c = parentAccount.Planning_Path__c; }

            if (configsByAccountId.containsKey(template.AccountId)) {
                for (Task_Planning_Default__c src : configsByAccountId.get(template.AccountId)) {
                    newConfigs.add(createConfigClone(src, template.Id, 'Template_Opportunity__c'));
                }
            }
            if (bundlesByAccountId.containsKey(template.AccountId)) {
                for (Task_Selected_Package__c src : bundlesByAccountId.get(template.AccountId)) {
                    newBundles.add(createBundleClone(src, template.Id, 'Opportunity__c'));
                }
            }
        }

        handleDatabaseResults(Database.update(templatesToSync, false, AccessLevel.USER_MODE), 'Updating Template Paths');
        if (!newConfigs.isEmpty()) { handleDatabaseResults(Database.insert(newConfigs, false, AccessLevel.USER_MODE), 'Cascading Configs to Template'); }
        if (!newBundles.isEmpty()) { handleDatabaseResults(Database.insert(newBundles, false, AccessLevel.USER_MODE), 'Cascading Bundles to Template'); }
    }

    public static Set<Id> cascadeTemplateToDrives(List<Opportunity> drivesToSync) {
        Set<Id> templateIds = new Set<Id>();
        Set<Id> confirmedDriveIdsToTrigger = new Set<Id>(); 
        for (Opportunity d : drivesToSync) { templateIds.add(d.Parent_Template_Id__c); }

        Map<Id, Opportunity> templatesById = new Map<Id, Opportunity>([SELECT Id, Planning_Path__c FROM Opportunity WHERE Id IN :templateIds WITH USER_MODE]);
        Map<Id, List<Task_Planning_Default__c>> configsByTemplateId = getParentConfigs(templateIds, 'Template_Opportunity__c');
        Map<Id, List<Task_Selected_Package__c>> bundlesByTemplateId = getParentBundles(templateIds, 'Opportunity__c');

        List<Planned_Task__c> newQueue = new List<Planned_Task__c>();
        List<Task_Selected_Package__c> newBundles = new List<Task_Selected_Package__c>();

        List<Planned_Task__c> existingTasks = [SELECT Id FROM Planned_Task__c WHERE Related_Opportunity__c IN :drivesToSync WITH USER_MODE];
        List<Task_Selected_Package__c> existingBundles = [SELECT Id FROM Task_Selected_Package__c WHERE Opportunity__c IN :drivesToSync WITH USER_MODE];

        if (!existingTasks.isEmpty()) { handleDatabaseResults(Database.delete(existingTasks, false, AccessLevel.USER_MODE), 'Wiping Drive Tasks'); }
        if (!existingBundles.isEmpty()) { handleDatabaseResults(Database.delete(existingBundles, false, AccessLevel.USER_MODE), 'Wiping Drive Bundles'); }

        for (Opportunity drive : drivesToSync) {
            Opportunity parentTemplate = templatesById.get(drive.Parent_Template_Id__c);
            if (parentTemplate != null) { drive.Planning_Path__c = parentTemplate.Planning_Path__c; }

            if (configsByTemplateId.containsKey(drive.Parent_Template_Id__c)) {
                for (Task_Planning_Default__c src : configsByTemplateId.get(drive.Parent_Template_Id__c)) {
                    newQueue.add(createPlannedTaskFromConfig(src, drive.Id));
                }
            }
            if (bundlesByTemplateId.containsKey(drive.Parent_Template_Id__c)) {
                for (Task_Selected_Package__c src : bundlesByTemplateId.get(drive.Parent_Template_Id__c)) {
                    newBundles.add(createBundleClone(src, drive.Id, 'Opportunity__c'));
                }
            }

            if (drive.Drive_Status__c == BSF_Constants.DOC_STATUS_CONFIRMED && drive.Planning_Path__c == BSF_Constants.PATH_FLEXIBLE) {
                confirmedDriveIdsToTrigger.add(drive.Id);
            }
        }

        handleDatabaseResults(Database.update(drivesToSync, false, AccessLevel.USER_MODE), 'Updating Drive Paths');
        if (!newQueue.isEmpty()) { handleDatabaseResults(Database.insert(newQueue, false, AccessLevel.USER_MODE), 'Cascading Configs to Drive'); }
        if (!newBundles.isEmpty()) { handleDatabaseResults(Database.insert(newBundles, false, AccessLevel.USER_MODE), 'Cascading Bundles to Drive'); }

        return confirmedDriveIdsToTrigger;
    }

    // ============================================================================
    // 5. CENTRAL HANDLER
    // ============================================================================
    public static void handleOpportunityUpdates(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Set<Id> confirmedIds = new Set<Id>();
        Set<Id> templateChangedIds = new Set<Id>();

        for(Opportunity opp : newOpps) {
            Opportunity old = oldMap.get(opp.Id);
            
            // 1. Detect Status Change to 'Confirmed' (Trigger Task Generation)
            if(opp.Drive_Status__c == 'Confirmed' && old.Drive_Status__c != 'Confirmed') {
                confirmedIds.add(opp.Id);
            }
            
            // 2. Detect Template Planning Path Change (Trigger Cascade Batch)
            if(opp.Is_Template__c && opp.Planning_Path__c != old.Planning_Path__c) {
                templateChangedIds.add(opp.Id);
            }
        }

        // Action: Generate Tasks for newly Confirmed drives
        if(!confirmedIds.isEmpty()) {
            generateTasksFromQueue(confirmedIds);
        }

        // Action: Cascade changes from Template to Child Drives
        if(!templateChangedIds.isEmpty()) {
            Database.executeBatch(new BSF_TemplateTaskPlanningCascadeBatch(templateChangedIds), 50);
        }
    }

    // ============================================================================
    // 6. CLEANUP
    // Context: Switching Path back to Standard
    // ============================================================================
    public static void handlePathCleanup(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Set<Id> revertIds = new Set<Id>();
        for(Opportunity opp : newOpps) {
            // Detect switch Flexible -> Standard
            if(opp.Planning_Path__c == BSF_Constants.PATH_STANDARD && oldMap.get(opp.Id).Planning_Path__c == BSF_Constants.PATH_FLEXIBLE) {
                revertIds.add(opp.Id);
            }
        }

        if(!revertIds.isEmpty()) {
            // Delete Queue Items
            delete [SELECT Id FROM Planned_Task__c WHERE Related_Opportunity__c IN :revertIds];
            // Delete Configs (if Template)
            delete [SELECT Id FROM Task_Planning_Default__c WHERE Template_Opportunity__c IN :revertIds];
            // Delete Junctions
            delete [SELECT Id FROM Task_Selected_Package__c WHERE Opportunity__c IN :revertIds];
            // Delete Generated Tasks (Flexible Only)
            //delete [SELECT Id FROM Task WHERE WhatId IN :revertIds AND Planning_Task_Category__c = 'Flexible' AND IsClosed = FALSE];
        }
    }

    // ============================================================================
    // PRIVATE HELPERS
    // ============================================================================
    private static Date calculateActivityDate(Date referenceDate, Integer offsetDays) {
        if (referenceDate == null) { return Date.today(); }
        return referenceDate.addDays(-(offsetDays ?? 0));
    }

    private static Task_Planning_Default__c createConfigClone(Task_Planning_Default__c source, Id parentRecordId, String lookupFieldApiName) {
        Task_Planning_Default__c configClone = source.clone(false, true);
        configClone.Account__c = null; 
        configClone.Template_Opportunity__c = null;
        configClone.put(lookupFieldApiName, parentRecordId);
        return configClone;
    }

    private static Planned_Task__c createPlannedTaskFromConfig(Task_Planning_Default__c source, Id opportunityId) {
        Planned_Task__c plannedTask = new Planned_Task__c(
            Related_Opportunity__c = opportunityId, 
            Task_Definition__c = source.Task_Definition__c, 
            Scheduling_Method__c = source.Scheduling_Method__c, 
            Status__c = BSF_Constants.PLANNED_TASK_STATUS_CONFIGURED
        );
        if (source.Scheduling_Method__c == BSF_Constants.PLANNED_TASK_SCHEDULING_METHOD_DAYS_OFFSET) { 
            plannedTask.User_Defined_Offset__c = source.Configured_Offset__c;
        } else { 
            plannedTask.Target_Date__c = source.Configured_Date__c; 
        }
        return plannedTask;
    }

    private static Task_Selected_Package__c createBundleClone(Task_Selected_Package__c source, Id parentRecordId, String lookupFieldApiName) {
        Task_Selected_Package__c bundleClone = source.clone(false, true);
        bundleClone.Account__c = null; 
        bundleClone.Opportunity__c = null;
        bundleClone.put(lookupFieldApiName, parentRecordId);
        return bundleClone;
    }

    private static Map<Id, List<Task_Planning_Default__c>> getParentConfigs(Set<Id> parentIds, String lookupFieldApiName) {
        if (parentIds.isEmpty() || !BSF_Constants.ALLOWED_PLANNING_DEFAULT_LOOKUPS.contains(lookupFieldApiName)) { return new Map<Id, List<Task_Planning_Default__c>>(); }
        String query = String.format('SELECT Task_Definition__c, Scheduling_Method__c, Configured_Offset__c, Configured_Date__c, {0} FROM Task_Planning_Default__c WHERE {0} IN :parentIds WITH USER_MODE', new List<String>{String.escapeSingleQuotes(lookupFieldApiName)});
        Map<Id, List<Task_Planning_Default__c>> resultsByParentId = new Map<Id, List<Task_Planning_Default__c>>();
        for (Task_Planning_Default__c config : Database.query(query)) {
            Id pId = (Id)config.get(lookupFieldApiName);
            if (!resultsByParentId.containsKey(pId)) { resultsByParentId.put(pId, new List<Task_Planning_Default__c>()); }
            resultsByParentId.get(pId).add(config);
        }
        return resultsByParentId;
    }

    private static Map<Id, List<Task_Selected_Package__c>> getParentBundles(Set<Id> parentIds, String lookupFieldApiName) {
        if (parentIds.isEmpty() || !BSF_Constants.ALLOWED_SELECTED_PACKAGE_LOOKUPS.contains(lookupFieldApiName)) { return new Map<Id, List<Task_Selected_Package__c>>(); }
        String query = String.format('SELECT Task_Package__c, {0} FROM Task_Selected_Package__c WHERE {0} IN :parentIds WITH USER_MODE', new List<String>{String.escapeSingleQuotes(lookupFieldApiName)});
        Map<Id, List<Task_Selected_Package__c>> resultsByParentId = new Map<Id, List<Task_Selected_Package__c>>();
        for (Task_Selected_Package__c bundle : Database.query(query)) {
            Id pId = (Id)bundle.get(lookupFieldApiName);
            if (!resultsByParentId.containsKey(pId)) { resultsByParentId.put(pId, new List<Task_Selected_Package__c>()); }
            resultsByParentId.get(pId).add(bundle);
        }
        return resultsByParentId;
    }

    private static void handleDatabaseResults(Object results, String context) {
        List<Database.Error> errors = new List<Database.Error>();
        if (results instanceof List<Database.SaveResult>) {
            for (Database.SaveResult sr : (List<Database.SaveResult>)results) { if (!sr.isSuccess()) { errors.addAll(sr.getErrors()); } }
        } else if (results instanceof List<Database.DeleteResult>) {
            for (Database.DeleteResult dr : (List<Database.DeleteResult>)results) { if (!dr.isSuccess()) { errors.addAll(dr.getErrors()); } }
        }
        
        for (Database.Error err : errors) { 
            System.debug(LoggingLevel.ERROR, 'Error in context [' + context + ']: ' + err.getMessage()); 
        }
    }
}