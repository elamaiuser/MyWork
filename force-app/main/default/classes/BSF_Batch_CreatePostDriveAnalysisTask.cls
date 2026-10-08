/*
 * @Description:
 * One-time batch for HRP-17659 - Post Drive Analysis Tasks not deploying.
 *
 * This batch creates missing Post Drive Analysis Tasks for Opportunities
 * completed on or after the specified cutoff date.
 *
 * It compares the existing Task Subjects on the Opportunity with the
 * configured Task Definitions and creates only the missing tasks.
 */
global class BSF_Batch_CreatePostDriveAnalysisTask implements Database.Batchable<SObject> {
	private Map<String, String> typeVsOwnerMap = new Map<String, String>();
    private String query;
    private Map<String, String> subjectVsTypeMap = new Map<String, String>();

    global BSF_Batch_CreatePostDriveAnalysisTask(Map<String, String> subjectVsTypeMap, List<String> subjectPatterns, Date cutOffDate) {
		List<Task_Definition__c> taskDefList = [SELECT Name, Task_Type__c, Assigned_To__c FROM Task_Definition__c WHERE Task_Type__c IN :subjectVsTypeMap.values() ];
        for(Task_Definition__c td : taskDefList){
            if(!this.typeVsOwnerMap.containsKey(td.Task_Type__c)){
                this.typeVsOwnerMap.put(td.Task_Type__c, td.Assigned_To__c);
            }
        }
        String taskWhereClause = buildTaskWhereClause(subjectPatterns);
        this.subjectVsTypeMap = subjectVsTypeMap;
        
        query =
            'SELECT Id, Drive_Date__c, ' +
            '(SELECT Id, Subject FROM Tasks';

        if (!String.isBlank(taskWhereClause)) {
            query += ' WHERE ' + taskWhereClause;
        }

        query +=
            ') FROM Opportunity ' +
            'WHERE Drive_Date__c >= ' + String.valueOf(cutOffDate) +
            ' AND Is_Template__c = false' +
            ' AND DriveStatus__c = \'Complete\'' +
            ' AND Type_of_Drive__c = \'Mobile\'';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Set<Id> oppIds = new Set<Id>();

        if (subjectVsTypeMap.isEmpty()) {
            return;
        }

        Id generalTaskRecordTypeId =
            Task.SObjectType.getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('General_Task')
                .getRecordTypeId();

        List<Task> tasksToInsert = new List<Task>();

        try {
            for (Opportunity opp : scope) {
                oppIds.add(opp.Id);

                Set<String> existingSubjects = new Set<String>();

                if (opp.Tasks != null) {
                    for (Task existingTask : opp.Tasks) {
                        existingSubjects.add(existingTask.Subject);
                    }
                }

                for (String subject : subjectVsTypeMap.keySet()) {

                    if (existingSubjects.contains(subject)) {
                        continue;
                    }

                    tasksToInsert.add(
                        createTask(
                            opp,
                            generalTaskRecordTypeId,
                            subject,
                            subjectVsTypeMap.get(subject)
                        )
                    );
                }
            }
            
            DetermineTaskOwnerInvocable.TaskHierarchyContext taskHierCtxt = DetermineTaskOwnerInvocable.createOwnerkHierarchy(oppIds);  
            for(Task tsk : tasksToInsert){
                tsk.OwnerId = BSF_TaskPlanningService.determineTaskOwner(typeVsOwnerMap.get(tsk.Type), taskHierCtxt.roleHierarchyMap.get(tsk.WhatId), taskHierCtxt.fallbackHierarchyMap);
            }
            if (!tasksToInsert.isEmpty()) {
                Database.SaveResult[] srList = Database.insert(tasksToInsert, false);
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully inserted Task. Task ID: ' + sr.getId());
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Task fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(srList,'Post Drive Analysis Task Creation','BSF_Batch_CreatePostDriveAnalysisTask','execute','Error','Insert Failed');
                if(!errorList.isEmpty()){
                    Database.insert(errorList, false);
                }
            }
        } catch (Exception ex) {
            System.debug('Exception in execute method: ' + ex.getMessage());
            
        }

        
    }

    private static Task createTask(
        Opportunity opp,
        Id recordTypeId,
        String subject,
        String taskType
    ) {
        return new Task(
            Subject = subject,
            ActivityDate = opp.Drive_Date__c.addDays(4),
            Priority = 'High',
            RecordTypeId = recordTypeId,
            WhatId = opp.Id,
            Drive_Date__c = opp.Drive_Date__c,
            Type = taskType
        );
    }
    
    private static String buildTaskWhereClause(List<String> subjectPatterns) {

        if (subjectPatterns == null || subjectPatterns.isEmpty()) {
            return '';
        }
    
        List<String> clauses = new List<String>();
    
        for (String pattern : subjectPatterns) {
            clauses.add('Subject LIKE \'%' + String.escapeSingleQuotes(pattern) + '%\'');
        }
    
        return String.join(clauses, ' OR ');
    }

    global void finish(Database.BatchableContext bc) {}
}