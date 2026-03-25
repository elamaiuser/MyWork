//@Description: Corrects Task owner for Opportunity Tasks
/*
* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 03/22/2024					 Balaji N				  		logic for HRP-12333
*************************************************************************************************************************************************************************************************************************************************************************
*/
global class  BSF_BatchTaskSync implements Database.Batchable<SObject>,Schedulable 
{
    private static final Integer BATCH_SIZE = 200;
    private final Boolean isFullRun;
    private final List<Id> specificWhatIds;
    private final List<Id> specificTaskIds;
    private final Map<String, String> typeToRoleMap = new Map<String, String>();
    private final Set<String> monitoredTaskTypes = new Set<String>();

    global BSF_BatchTaskSync() {
        this.isFullRun = true;
        this.specificWhatIds = null;
        this.specificTaskIds = null;
        loadTaskDefinitions();
    }
    
    global BSF_BatchTaskSync(List<Id> whatIdList, List<Id> taskIdList) {
        this.isFullRun = false;
        this.specificWhatIds = whatIdList;
        this.specificTaskIds = taskIdList;
        loadTaskDefinitions();
    }

    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new BSF_BatchTaskSync(), BATCH_SIZE);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String marketingSubject = BSF_Constants.MARKETING_EXCEPTION_TASK;

        String query =
            'SELECT Id, WhatId, Subject, Type, OwnerId ' +
            'FROM Task ' +
            'WHERE IsClosed = FALSE ' +
            '  AND Status != \'Completed\' ' +
            '  AND Status != \'Cancelled\' ' +
            '  AND WhatId != NULL ' +
            '  AND (Type IN :monitoredTaskTypes OR Subject = :marketingSubject)';

        if (isPopulated(specificWhatIds)) {
            query += ' AND WhatId IN :specificWhatIds';
        }
        if (isPopulated(specificTaskIds)) {
            query += ' AND Id IN :specificTaskIds';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Task> scope) {

        Set<Id> oppIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Boolean hasMarketing = false;
        Boolean hasOnlyMarketing  = true;

        for (Task t : scope) {
            if(isOrder(t.WhatId)){
                orderIds.add(t.WhatId);
            }else if(isOpportunity(t.WhatId)) {
                oppIds.add(t.WhatId);
            }
            if(isMarketingTask(t)){
                hasMarketing = true;
            }else{
                hasOnlyMarketing = false;
            }
        }

        Map<Id, Id> orderToOppMap = resolveOrderOpportunities(orderIds, oppIds);

        if (oppIds.isEmpty()) return;

        Map<Id, Opportunity> oppMap = hasMarketing ? fetchOpportunities(oppIds) : new Map<Id, Opportunity>();
        Map<Id, Id> siteToQueueMap = hasMarketing ? resolveMarketingQueues(oppMap.values()) : new Map<Id, Id>();
        Map<Id, Map<String, Id>> roleHierarchyMap = !hasOnlyMarketing ? BSF_TaskPlanningService.buildRoleHierarchyMap(oppIds) : new Map<Id, Map<String, Id>>();
        Map<String, List<String>> fallbackMap = !hasOnlyMarketing ? BSF_TaskPlanningService.getRoleFallbackHierarchyMap() : new Map<String, List<String>>();
        Id systemUserId = !hasOnlyMarketing ? TaskService.getDRDSystemUser() : null;


        List<Task> tasksToUpdate = new List<Task>();

        for (Task tsk : scope) {
            Id contextOppId = getContextOppId(tsk, orderToOppMap);
            if (contextOppId == null) continue;

            Id expectedOwner = resolveExpectedOwner(tsk, contextOppId, oppMap, siteToQueueMap, roleHierarchyMap, fallbackMap, systemUserId);
            if (expectedOwner != null && tsk.OwnerId != expectedOwner) {
                tsk.OwnerId = expectedOwner;
                tasksToUpdate.add(tsk);
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            BSF_TaskPlanningService.handleDatabaseResults(
                Database.update(tasksToUpdate, false),
                'BSF_BatchTaskSync Reassignment'
            );
        }
    }

    global void finish(Database.BatchableContext bc) {
        if (isFullRun && !Test.isRunningTest()) {
            Database.executeBatch(new BSF_Batch_CreateHandOffTasks());
        }
    }

    private void loadTaskDefinitions() {
        for(Task_Definition__c def : [SELECT Task_Type__c, 
                                                Assigned_To__c
                                        FROM Task_Definition__c
                                        WHERE Task_Type__c != NULL
                                         AND Assigned_To__c != NULL]) {
            typeToRoleMap.put(def.Task_Type__c, def.Assigned_To__c);
            monitoredTaskTypes.add(def.Task_Type__c);
        }
    }

    private Map<Id, Id> resolveOrderOpportunities(Set<Id> orderIds, Set<Id> oppIds) {
        Map<Id, Id> orderToOppMap = new Map<Id, Id>();
        if (orderIds.isEmpty()) return orderToOppMap;

        for (Order ord : [SELECT Id, 
                                OpportunityId 
                            FROM Order 
                            WHERE Id IN :orderIds WITH USER_MODE]) {
            if(ord.OpportunityId == null) continue;

            orderToOppMap.put(ord.Id, ord.OpportunityId);
            oppIds.add(ord.OpportunityId);
        }
        return orderToOppMap;
    }

    private Map<Id, Opportunity> fetchOpportunities(Set<Id> oppIds) {
        return new Map<Id, Opportunity>([
            SELECT Id, 
                    Drive_site__c, 
                    OwnerId
            FROM Opportunity
            WHERE Id IN :oppIds
            WITH USER_MODE
        ]);
    }

    private Id getContextOppId(Task tsk, Map<Id, Id> orderToOppMap) {
        return isOrder(tsk.WhatId) ? orderToOppMap.get(tsk.WhatId) : tsk.WhatId;
    }

    private Map<Id, Id> resolveMarketingQueues(List<Opportunity> opps) {
        Set<Id> siteIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.Drive_site__c != null){
                siteIds.add(opp.Drive_site__c);
            }
        }
        if (siteIds.isEmpty()) return new Map<Id, Id>();

        Map<Id, String> siteToCollName  = new Map<Id, String>();
        Set<String> queueNames = new Set<String>();

        for (Sked_Site_Collection_Operation__c sc : [SELECT sked_Site__c, 
                                                            sked_collection_operation__r.Name
                                                    FROM Sked_Site_Collection_Operation__c
                                                    WHERE sked_Site__c IN :siteIds
                                                    AND sked_Start_Date__c <= TODAY
                                                    AND (sked_End_Date__c >= TODAY 
                                                    OR sked_End_Date__c = NULL)]) {
            String collName = sc.sked_collection_operation__r.Name;
            siteToCollName.put(sc.sked_Site__c, collName);
            queueNames.add(collName + ': DMDCR');
        }

        if (queueNames.isEmpty()) return new Map<Id, Id>();

        Map<String, Id> queueNameToId = new Map<String, Id>();
        for (Group grp : [SELECT Id, 
                                Name 
                            FROM Group 
                            WHERE Type = 'Queue' 
                            AND Name IN :queueNames]) {
            queueNameToId.put(grp.Name.substringBefore(':').trim(), grp.Id);
        }

        Map<Id, Id> siteToQueueMap = new Map<Id, Id>();
        for (Id siteId : siteToCollName.keySet()) {
            String collName = siteToCollName.get(siteId);
            Id queueId  = queueNameToId.get(collName);
            if(queueId != null){
                siteToQueueMap.put(siteId, queueId);
            }
        }
        return siteToQueueMap;
    }

    private Id resolveExpectedOwner(Task tsk, Id contextOppId, Map<Id, Opportunity> oppMap, 
                                    Map<Id, Id> siteToQueueMap, Map<Id, Map<String, Id>> roleHierarchyMap, 
                                    Map<String, List<String>> fallbackMap, Id systemUserId) {
        if (isMarketingTask(tsk)) {
            Opportunity opp = oppMap.get(contextOppId);
            return (opp?.Drive_site__c != null) ? siteToQueueMap.get(opp.Drive_site__c) : null;
        }

        if (String.isBlank(tsk.Type)
            || !typeToRoleMap.containsKey(tsk.Type)
            || !roleHierarchyMap.containsKey(contextOppId)) return null;

        Id resolved = BSF_TaskPlanningService.determineTaskOwner(
            typeToRoleMap.get(tsk.Type),
            roleHierarchyMap.get(contextOppId),
            fallbackMap
        );
        return resolved != null ? resolved : systemUserId;
    }

    private static Boolean isPopulated(List<Id> ids) {
        return ids != null && !ids.isEmpty();
    }

    private static Boolean isOrder(Id recordId) {
        return recordId != null && recordId.getSObjectType() == Order.sObjectType;
    }

    private static Boolean isOpportunity(Id recordId) {
        return recordId != null && recordId.getSObjectType() == Opportunity.sObjectType;
    }

    private static Boolean isMarketingTask(Task tsk) {
        return tsk.Subject == BSF_Constants.MARKETING_EXCEPTION_TASK;
    }
}