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
        Map<String, Object> bindParams = new Map<String, Object>{
            'opportunityIds' => opportunityIds
        };
        String queryString = buildTaskGenerationBatchQuery(BSF_Constants.PLANNED_TASK_TRIGGER_FILTER);
        List<Planned_Task__c> tasksToProcess = Database.queryWithBinds(queryString, 
                                                                        bindParams, 
                                                                        AccessLevel.USER_MODE
                                                                      );
        if (!tasksToProcess.isEmpty()) {
            processAndGenerateTasks(tasksToProcess, 
                                        Boolean.valueOf(
                                        Label.BSF_Generate_Tasks_From_Events)
                                    );
        }
    }

    public static void triggerTaskGenerationOnConfirm(List<sked_Drive__c> newDrives, Map<Id, sked_Drive__c> oldMap) {
        Set<Id> oppIdsToProcess = new Set<Id>();

        for (sked_Drive__c drive : newDrives) {
            sked_Drive__c oldDrive = (oldMap != null) ? oldMap.get(drive.Id) : null;
            
            Boolean isNewlyConfirmed = drive.sked_Status__c == 'Confirmed' && 
                                    (oldDrive == null || drive.sked_Status__c != oldDrive.sked_Status__c);

            if (isNewlyConfirmed && drive.sked_Opportunity__c != null) {
                oppIdsToProcess.add(drive.sked_Opportunity__c);
            }
        }

        if (!oppIdsToProcess.isEmpty()) {
            generateTasksFromQueue(oppIdsToProcess);
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
            SELECT Id, WhatId FROM Task 
            WHERE WhatId IN :opportunityIdsWithDateChange AND IsClosed = FALSE
            WITH USER_MODE
        ];

        for (Task taskRecord : dependentTasksToUpdate) {
            Opportunity parentOpp = newOpportunityMap.get(taskRecord.WhatId);
            if (parentOpp != null ) {
                taskRecord.ActivityDate = calculateActivityDate(parentOpp.Drive_Date__c, 0);
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
            if(opp.Type_of_Drive__c.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) continue;

            if (opp.AccountId != null) { accountIds.add(opp.AccountId); }
            if (opp.Parent_Template_Id__c != null) { templateIds.add(opp.Parent_Template_Id__c); }
        }

        Map<Id, List<Task_Planning_Default__c>> configsByAccountId = getParentConfigs(accountIds, 'Account__c');
        Map<Id, List<Task_Planning_Default__c>> configsByTemplateId = getParentConfigs(templateIds, 'Template_Opportunity__c');
        Map<Id, List<Task_Selected_Package__c>> bundlesByAccountId = getParentBundles(accountIds, 'Account__c');
        Map<Id, List<Task_Selected_Package__c>> bundlesByTemplateId = getParentBundles(templateIds, 'Opportunity__c');

        for (Opportunity opp : newOpportunities) {
            if(opp.Type_of_Drive__c.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) continue;
            
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
        for (Opportunity template : templatesToSync) { 
            accountIds.add(template.AccountId); 
        }

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
            if(opp.Type_of_Drive__c.equalsIgnoreCase(BSF_Constants.FIXED_SITE_DRIVE)) continue;

            Opportunity old = oldMap.get(opp.Id);
            
            // 1. Detect Status Change to 'Confirmed' (Trigger Task Generation)
            /*if(opp.Drive_Status__c == 'Confirmed' && old.Drive_Status__c != 'Confirmed') {
                confirmedIds.add(opp.Id);
            }*/
            
            // 2. Detect Template Planning Path Change (Trigger Cascade Batch)
            if(opp.Is_Template__c && opp.Planning_Path__c != old.Planning_Path__c) {
                templateChangedIds.add(opp.Id);
            }
        }

        // Action: Generate Tasks for newly Confirmed drives
        /*if(!confirmedIds.isEmpty()) {
            generateTasksFromQueue(confirmedIds);
        }*/

        // Action: Cascade changes from Template to Child Drives
        if(!templateChangedIds.isEmpty() && !System.isBatch() && !System.isFuture()) {
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
    // 7. ACCOUNT INITIALIZATION
    // ============================================================================

    public static void initializeAccountTaskConfigs(List<Account> newAccounts) {
        if (newAccounts == null || newAccounts.isEmpty())  return;

        Set<Id> mobileAccountIds = new Set<Id>();
        Id mobileRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE).getRecordTypeId();
        for (Account acc : newAccounts) {
            if (acc.Id != null && acc.RecordTypeId == mobileRtId) {
                mobileAccountIds.add(acc.Id);
            }
        }

        if (mobileAccountIds.isEmpty()) return;

        List<Task_Planning_Default__c> configsToInsert = new List<Task_Planning_Default__c>();
        Set<Id> processedDefIds = new Set<Id>();
        for (Task_Package_Item__c item : [
            SELECT Task_Package__c,
                Task_Definition__c,
                Task_Definition__r.Scheduling_Method__c,
                Task_Definition__r.Due_Date_Offset__c
            FROM Task_Package_Item__c
            WHERE Task_Package__r.Name LIKE '%Standard%'
            OR Task_Package__r.Sort_Order__c = 1
        ]) {

            if (processedDefIds.contains(item.Task_Definition__c)) {
                continue;
            }
            processedDefIds.add(item.Task_Definition__c);
            configsToInsert.addAll(buildTaskConfigsForAccount(mobileAccountIds, item));
        }

        if (!configsToInsert.isEmpty()) {
            handleDatabaseResults(
                Database.insert(configsToInsert, false),
                'Account Task Config Initialization'
            );
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
        Task_Planning_Default__c config = new Task_Planning_Default__c();
        config.Task_Definition__c = source.Task_Definition__c;
        config.Scheduling_Method__c = source.Scheduling_Method__c;
        config.Configured_Offset__c = source.Configured_Offset__c;
        config.Configured_Date__c = source.Configured_Date__c;
        config.Task_Package__c = source.Task_Package__c;        
        config.put(lookupFieldApiName, parentRecordId);
        return config;
    }

    private static Planned_Task__c createPlannedTaskFromConfig(Task_Planning_Default__c source, Id opportunityId) {
        Planned_Task__c plannedTask = new Planned_Task__c(
            Related_Opportunity__c = opportunityId,
            Task_Definition__c = source.Task_Definition__c,
            Scheduling_Method__c = source.Scheduling_Method__c,
            Task_Package__c = source.Task_Package__c,
            Subject__c = source.Task_Definition__r != null ? source.Task_Definition__r.Name : 'Undefined Subject',
            creation_Offset__c = source.Task_Definition__r.Creation_Date_Offset__c,
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
        String query = String.format('SELECT Task_Definition__c, Scheduling_Method__c, Configured_Offset__c, Configured_Date__c, Task_Package__c, Task_Definition__r.Name, Task_Definition__r.Creation_Date_Offset__c, {0} FROM Task_Planning_Default__c WHERE {0} IN :parentIds WITH USER_MODE', new List<String>{String.escapeSingleQuotes(lookupFieldApiName)});
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

    private static List<Task_Planning_Default__c> buildTaskConfigsForAccount(Set<Id> accountIds, Task_Package_Item__c item) {
        List<Task_Planning_Default__c> configs = new List<Task_Planning_Default__c>();
        for (Id accId : accountIds) {
            configs.add(createConfig(accId, item));
        }
        return configs;
    }

    private static Task_Planning_Default__c createConfig(Id accountId, Task_Package_Item__c item) {
        return new Task_Planning_Default__c(
            Account__c = accountId,
            Task_Definition__c = item.Task_Definition__c,
            Task_Package__c = item.Task_Package__c,
            Scheduling_Method__c = item.Task_Definition__r.Scheduling_Method__c,
            Configured_Offset__c = item.Task_Definition__r.Due_Date_Offset__c
        );
    }

    public static void handleDatabaseResults(Object results, String context) {
        if (results == null){
            return;
        }
        List<Database.Error> errors = new List<Database.Error>();
        List<BSF_Error_Log__c> errorLogs = new List<BSF_Error_Log__c>();
        String className = 'BSF_TaskPlanningService';

        if (results instanceof List<Database.SaveResult>) {
            List<Database.SaveResult> srList = (List<Database.SaveResult>)results;
            for (Database.SaveResult sr : srList) { 
                if (!sr.isSuccess()) {
                    errors.addAll(sr.getErrors()); 
                }
            }
            errorLogs = BSF_Utilities.createErrorLog(srList, context, className, 'handleDatabaseResults', 'Error', 'DML Save Error');
        } 
        else if (results instanceof List<Database.DeleteResult>) {
            List<Database.DeleteResult> drList = (List<Database.DeleteResult>)results;
            for (Database.DeleteResult dr : drList) { 
                if (!dr.isSuccess()){ 
                    errors.addAll(dr.getErrors()); 
                }
            }
            errorLogs = BSF_Utilities.createErrorLog(drList, context, className, 'handleDatabaseResults', 'Error', 'DML Delete Error');
        }
        
        for (Database.Error err : errors) { 
            System.debug(LoggingLevel.ERROR, 'Error in context [' + context + ']: ' + err.getMessage()); 
        }

        if (!errorLogs.isEmpty()) {
            Database.SaveResult[] logResults = Database.insert(errorLogs, false, AccessLevel.USER_MODE);
            for (Database.SaveResult sr : logResults) {
                if (!sr.isSuccess()){
                    System.debug(LoggingLevel.ERROR, 'Failed to insert Error Log: ' + sr.getErrors()[0].getMessage());
                }
            }
        }
    }

    // ============================================================================
    // STANDARDTASKGENERATIONBATCH PRIVATE HELPER METHODS
    // ============================================================================

    private static Map<String, Task> getExistingTasks(Set<Id> oppIds, Set<String> taskTypes) {
        Map<String, Task> taskMap = new Map<String, Task>();
        if(oppIds.isEmpty() || taskTypes.isEmpty()) return taskMap;

        List<Task> existingTasks = [
            SELECT Id, Type, WhatId 
            FROM Task 
            WHERE WhatId IN :oppIds 
            AND Type IN :taskTypes
            AND Status != :BSF_Constants.STATUS_CANCELLED
        ];
        
        for (Task t : existingTasks) {
            taskMap.put(t.WhatId + '-' + t.Type, t);
        }
        return taskMap;
    }

    private static Boolean isDuplicateTask(Planned_Task__c pt, Map<String, Task> existingTaskMap) {
        String taskKey = pt.Related_Opportunity__c + '-' + pt.Task_Definition__r.Task_Type__c;
        return existingTaskMap.containsKey(taskKey);
    }
    
    private static Map<Id, Map<String, Id>> buildRoleHierarchyMap(Set<Id> oppIds) {
        Map<Id, Map<String, Id>> oppRolesMap = new Map<Id, Map<String, Id>>();
        if (oppIds.isEmpty()) return oppRolesMap;

        Id systemUserId = TaskService.getDRDSystemUser();
        List<Opportunity> oppList = [SELECT Id, 
                                            AccountId, 
                                            Account_Manager__c, 
                                            OwnerId,
                                            (SELECT UserId, 
                                                TeamMemberRole 
                                            FROM OpportunityTeamMembers)
                                        FROM Opportunity 
                                        WHERE Id IN :oppIds];

        Map<Id, Id> accSpecialistMap = getAccountSpecialistMap(oppList);

        for (Opportunity opp : oppList) {
            oppRolesMap.put(opp.Id, mapRolesForSingleOpp(opp, systemUserId, accSpecialistMap));
        }
        
        return oppRolesMap;
    }

    private static Map<Id, Id> getAccountSpecialistMap(List<Opportunity> oppList) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppList) {
            if (opp.AccountId != null) accountIds.add(opp.AccountId);
        }

        Map<Id, Id> specialistMap = new Map<Id, Id>();
        if (accountIds.isEmpty()) return specialistMap;

        for (AccountTeamMember atm : [SELECT AccountId, 
                                                UserId, 
                                                Is_Covering_Recruiter__c 
                                        FROM AccountTeamMember 
                                        WHERE AccountId IN :accountIds 
                                        AND TeamMemberRole = :BSF_Constants.ACCOUNT_SPECIALIST 
                                        ORDER BY CreatedDate DESC]) {
            if (!specialistMap.containsKey(atm.AccountId) || atm.Is_Covering_Recruiter__c) {
                specialistMap.put(atm.AccountId, atm.UserId);
            }
        }
        return specialistMap;
    }

    private static Map<String, Id> mapRolesForSingleOpp(Opportunity opp, Id systemUserId, Map<Id, Id> accSpecMap) {
        Map<String, Id> roles = new Map<String, Id>{
            BSF_Constants.ACCOUNT_MANAGER => opp.Account_Manager__c,
            BSF_Constants.OPPORTUNITY_OWNER => opp.OwnerId,
            BSF_Constants.DRD_SYSTEM_USER   => systemUserId
        };

        for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
            String role = otm.TeamMemberRole;
            if (String.isNotBlank(role) && 
                    (role.equalsIgnoreCase(BSF_Constants.AREA_BOOKING_MANAGER) || 
                    role.equalsIgnoreCase(BSF_Constants.DISTRICT_MANAGER) || 
                    role.equalsIgnoreCase(BSF_Constants.ACCOUNT_SPECIALIST))) {
                            roles.put(otm.TeamMemberRole, otm.UserId);
            }
        }

        if (roles.get(BSF_Constants.ACCOUNT_SPECIALIST) == null && accSpecMap.containsKey(opp.AccountId)) {
            roles.put(BSF_Constants.ACCOUNT_SPECIALIST, accSpecMap.get(opp.AccountId));
        }

        return roles;
    }
    
    private static Task buildTask(Planned_Task__c pt, Map<String, String> fieldMapping, Id ownerId) {
        Task newTask = new Task();
        newTask.Status = BSF_Constants.STATUS_NOT_STARTED;
        newTask.Priority = BSF_Constants.NORMAL_PRIORITY_TASK;
        
        if (fieldMapping != null && !fieldMapping.isEmpty()) {
            for (String sourceFieldPath : fieldMapping.keySet()) {
                String targetFieldAPI = fieldMapping.get(sourceFieldPath);
                Object fieldValue = getFieldValue(pt, sourceFieldPath);
                if (fieldValue != null) {
                    newTask.put(targetFieldAPI, fieldValue);
                }
            }
        }
        
        newTask.OwnerId = ownerId;
        return newTask;
    }

    private static Map<String, String> getDynamicFieldMapping() {
        Map<String, String> mappingMap = new Map<String, String>();
        Map<String, Object> rawMap = parseJson(BSF_Constants.TASK_FIELD_MAPPING_JSON, 'TASK_FIELD_MAPPING_JSON');
        for(String key : rawMap.keySet()) { 
            mappingMap.put(key, String.valueOf(rawMap.get(key))); 
        }
        return mappingMap;
    }

    private static GenerationContext setupContext(List<Planned_Task__c> plannedTasks, Boolean usePlatformEvent) {
        Set<Id> oppIds = new Set<Id>();
        Set<String> taskTypes = new Set<String>();

        for (Planned_Task__c pt : plannedTasks) {
            if (pt.Related_Opportunity__c != null && pt.Status__c == BSF_Constants.PLANNED_TASK_STATUS_CONFIGURED) {
                oppIds.add(pt.Related_Opportunity__c);
                taskTypes.add(pt.Task_Definition__r.Task_Type__c);
            }
        }

        GenerationContext ctx = new GenerationContext();
        ctx.existingTaskMap = getExistingTasks(oppIds, taskTypes);
        ctx.roleHierarchyMap = buildRoleHierarchyMap(oppIds);
        ctx.fieldMapping = getDynamicFieldMapping();
        ctx.fallbackHierarchyMap = getRoleFallbackHierarchyMap();
        if(usePlatformEvent){
            ctx.peMapping = getDynamicPlatformEventFieldMapping();
        }
        return ctx;
    }

    private static void processSinglePlannedTask(Planned_Task__c pt, GenerationContext ctx, ProcessingData data, Boolean usePlatformEvent) {
        Id ownerId = determineTaskOwner(pt.Task_Definition__r.Assigned_To__c, 
                                        ctx.roleHierarchyMap.get(pt.Related_Opportunity__c),
                                        ctx.fallbackHierarchyMap);
        Task newTask = buildTask(pt, ctx.fieldMapping, ownerId);
        System.debug(LoggingLevel.DEBUG, 'Built Task for Planned Task Id ' + pt.Id + ': ' + newTask);
        if (usePlatformEvent) {
            data.eventsToPublish.add(buildPlatformEvent(newTask, pt.Id, ctx.peMapping));
        } else {
            data.tasksToInsert.add(newTask);
            data.indexMap.put(data.tasksToInsert.size() - 1, pt);
        }
    }

    private static void executeDmlAndPublish(ProcessingData data, Boolean usePlatformEvent) {
        System.debug(LoggingLevel.INFO, 'Executing DML and Publishing. Use Platform Event: ' + usePlatformEvent);
        if (!data.tasksToInsert.isEmpty() && !usePlatformEvent) {
            Database.SaveResult[] srList = Database.insert(data.tasksToInsert, false);
            handleTaskInsertResults(srList, data.indexMap, data.pTasksToUpdate);
        }

        if (!data.eventsToPublish.isEmpty() && usePlatformEvent) {
            handleDatabaseResults(EventBus.publish(data.eventsToPublish), 'Platform Event Publish');
        }

        if (!data.pTasksToUpdate.isEmpty()) {
            handleDatabaseResults(Database.update(data.pTasksToUpdate, false), 'Planned Task Update');
        }
    }

    private static void handleTaskInsertResults(Database.SaveResult[] srList, Map<Integer, Planned_Task__c> indexMap, List<Planned_Task__c> pTasksToUpdate) {
        for (Integer i = 0; i < srList.size(); i++) {
            if (srList[i].isSuccess()) {
                pTasksToUpdate.add(markProcessed(indexMap.get(i)));
            }
        }
        handleDatabaseResults(srList, 'Direct Task Insertion');
    }

    private static Planned_Task__c markProcessed(Planned_Task__c pt) {
        pt.Status__c = BSF_Constants.PLANNED_TASK_STATUS_PROCESSED;
        return pt;
    }

    private static Map<String, Object> parseJson(String jsonString, String labelName) {
        if (String.isBlank(jsonString)){
            return new Map<String, Object>();
        }
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to parse ' + labelName + ': ' + e.getMessage());
            return new Map<String, Object>();
        }
    }

    private static SObject transferMappedFields(SObject source, SObject target, Map<String, String> mapping, Boolean isTaskToPE) {
        if (mapping == null || mapping.isEmpty()){
            return target;
        }
        
        for (String taskField : mapping.keySet()) {
            String peField = mapping.get(taskField);
            String sourceField = isTaskToPE ? taskField : peField;
            String targetField = isTaskToPE ? peField : taskField;
            try {
                Object val = source.get(sourceField);
                if (val != null) {
                    target.put(targetField, val);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Mapping failed (' + sourceField + ' -> ' + targetField + '): ' + e.getMessage());
            }
        }
        
        return target;
    }

    // ============================================================================
    // STANDARDTASKGENERATIONBATCH REUSABLE LOGIC FOR BOTH BATCH AND DIRECT EXECUTION
    // ============================================================================

    public static Id determineTaskOwner(String assignedTo, Map<String, Id> oppRoles, Map<String, List<String>> fallbackHierarchyMap){
        if (oppRoles == null || oppRoles.isEmpty()) {
            return null;
        }
        Id ownerId = null;
        if (String.isBlank(assignedTo)) {
            assignedTo = BSF_Constants.ACCOUNT_MANAGER; 
        } else if (assignedTo.equalsIgnoreCase(BSF_Constants.ASSIGNED_TO_SBPM)) {
            assignedTo = BSF_Constants.AREA_BOOKING_MANAGER; 
        }

        List<String> fallbackChain;
        if (fallbackHierarchyMap == null || fallbackHierarchyMap.isEmpty() 
                || !fallbackHierarchyMap.containsKey(assignedTo)) {
                    fallbackChain = new List<String>{ assignedTo };
        }else{
            fallbackChain = fallbackHierarchyMap.get(assignedTo);
            if (fallbackChain == null || fallbackChain.isEmpty()) {
                fallbackChain = new List<String>{ assignedTo };
            }
        }

        for (String roleToCheck : fallbackChain) {
            if (oppRoles.containsKey(roleToCheck) && oppRoles.get(roleToCheck) != null) {
                ownerId = oppRoles.get(roleToCheck);
                break;
            }
        }
        return ownerId;
    }

    public static Object getFieldValue(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)){ 
            return null;
        }

        if (!fieldPath.contains('.')) {
            return record.get(fieldPath);
        }
        
        List<String> relations = fieldPath.split('\\.');
        SObject currentObj = record;
        
        for (Integer i = 0; i < relations.size() - 1; i++) {
            if (currentObj == null){ 
                return null; 
            }
            currentObj = currentObj.getSObject(relations[i]);
        }
        
        return currentObj != null ? currentObj.get(relations[relations.size() - 1]) : null;
    }

    public static String buildTaskGenerationBatchQuery(String batchWhereClause) {
        Set<String> queryFields = new Set<String>{'Id'};
        for(Schema.FieldSetMember fsm : SObjectType.Planned_Task__c.FieldSets.Task_Generation_Fields.getFields()) {
            queryFields.add(fsm.getFieldPath());
        }
        return 'SELECT ' + String.join(new List<String>(queryFields), ', ') +
                ' FROM Planned_Task__c ' +
                ' WHERE ' + batchWhereClause;
    }

    public static Map<String, List<String>> getRoleFallbackHierarchyMap() {
        Map<String, List<String>> hierarchyMap = new Map<String, List<String>>();
        Map<String, Object> rawMap = parseJson(BSF_Constants.TASK_OWNER_HIERARCHY_JSON, 'TASK_OWNER_HIERARCHY_JSON');
        for (String key : rawMap.keySet()) {
            List<String> fallbacks = new List<String>();
            for (Object obj : (List<Object>)rawMap.get(key)) { 
                fallbacks.add(String.valueOf(obj).trim()); 
            }
            hierarchyMap.put(key.trim(), fallbacks);
        }
        return hierarchyMap;
    }

    public static Map<String, String> getDynamicPlatformEventFieldMapping() {
        Map<String, String> mappingMap = new Map<String, String>();
        Map<String, Object> rawMap = parseJson(BSF_Constants.PE_FIELD_MAPPING_JSON, 'PE_FIELD_MAPPING_JSON');
        for (String key : rawMap.keySet()) { 
            mappingMap.put(key, String.valueOf(rawMap.get(key))); 
        }
        return mappingMap;
    }

    public static Task_Platform_Event__e buildPlatformEvent(Task t, Id plannedTaskId, Map<String, String> peMapping) {
        return (Task_Platform_Event__e) transferMappedFields(
            t, 
            new Task_Platform_Event__e(Planned_Task_Id__c = plannedTaskId), 
            peMapping, 
            true
        );
    }

    public static Task buildTaskFromEvent(Task_Platform_Event__e pe, Map<String, String> peMapping) {
        return (Task) transferMappedFields(
            pe, 
            new Task(Status = BSF_Constants.STATUS_NOT_STARTED, Priority = BSF_Constants.NORMAL_PRIORITY_TASK), 
            peMapping, 
            false
        );
    }

    // ============================================================================
    // STANDARDTASKGENERATIONBATCH MAIN EXECUTE METHOD
    // ============================================================================

    public static void processAndGenerateTasks(List<Planned_Task__c> plannedTasks, Boolean usePlatformEvent) {
        if (plannedTasks == null || plannedTasks.isEmpty()){
            return;
        }
        if(usePlatformEvent == null) { 
            usePlatformEvent = false; 
        }
        try {
            GenerationContext ctx = setupContext(plannedTasks, usePlatformEvent);
            System.debug(LoggingLevel.INFO, 'Context setup complete. Existing Tasks: ' + ctx.existingTaskMap.size() + ', Opportunities with Roles: ' + ctx.roleHierarchyMap.size() + ', Field Mappings: ' + ctx.fieldMapping.size());
            ProcessingData data = new ProcessingData();
            List<String> duplicateErrors = new List<String>();

            for (Planned_Task__c pt : plannedTasks) {
                if (pt.Status__c != BSF_Constants.PLANNED_TASK_STATUS_CONFIGURED) continue;
                
                if (isDuplicateTask(pt, ctx.existingTaskMap)) {
                    data.pTasksToUpdate.add(markProcessed(pt));
                    continue;
                }
                processSinglePlannedTask(pt, ctx, data, usePlatformEvent);
            }
            System.debug(LoggingLevel.INFO, 'Task processing complete. Tasks to Insert: ' + data.tasksToInsert.size() + ', Events to Publish: ' + data.eventsToPublish.size() + ', Planned Tasks to Update: ' + data.pTasksToUpdate.size());
            executeDmlAndPublish(data, usePlatformEvent);
        }catch(Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Exception in processAndGenerateTasks(): ' + ex.getMessage());
            
            BSF_Error_Log__c exLog = BSF_Utilities.getErrorLog(
                'Task Generation', 
                'BSF_TaskPlanningService', 
                'processAndGenerateTasks', 
                'Critical Error', 
                'Exception occurred during execution', 
                ex.getMessage() + ' | Stack Trace: ' + ex.getStackTraceString()
            );

            Database.insert(new List<BSF_Error_Log__c>{exLog}, false, AccessLevel.USER_MODE);
        }
    }

    // ============================================================================
    // STANDARDTASKGENERATIONBATCH INNER CLASSES
    // ============================================================================

    private class GenerationContext {
        Map<String, Task> existingTaskMap;
        Map<Id, Map<String, Id>> roleHierarchyMap;
        Map<String, String> fieldMapping;
        Map<String, List<String>> fallbackHierarchyMap;
        Map<String, String> peMapping;
    }

    private class ProcessingData {
        List<Task> tasksToInsert = new List<Task>();
        Map<Integer, Planned_Task__c> indexMap = new Map<Integer, Planned_Task__c>();
        List<Task_Platform_Event__e> eventsToPublish = new List<Task_Platform_Event__e>();
        List<Planned_Task__c> pTasksToUpdate = new List<Planned_Task__c>();
    }
}