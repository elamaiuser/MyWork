global with sharing class BSF_Batch_CreatePlannedTask implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    private InputWrapper inputs;
    private Map<String, String> typeVsOwnerMap = new Map<String, String>();
    private Id generalTaskRecordTypeId;
    private Integer batchSize;
    private Boolean isScheduledRun = false;

    public BSF_Batch_CreatePlannedTask(InputWrapper inputs) {
        this.inputs = inputs;
        this.batchSize = inputs.batchSize != null ? inputs.batchSize : 20;

        for (Task_Definition__c td : [SELECT Name, Task_Type__c, Assigned_To__c FROM Task_Definition__c]) {
            if (!this.typeVsOwnerMap.containsKey(td.Task_Type__c)) {
                this.typeVsOwnerMap.put(td.Task_Type__c, td.Assigned_To__c);
            }
        }

        this.generalTaskRecordTypeId = Task.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('General_Task').getRecordTypeId();
    }

    global void execute(SchedulableContext cc) {
        this.isScheduledRun = true;
        Database.executeBatch(this, this.batchSize);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        Date driveDate = inputs.driveDate;
        Set<String> driveStatus = inputs.driveStatus;
        Set<Id> opportunityIds = inputs.opportunityIds;

        if(this.isScheduledRun) {
            System.debug('Scheduled run detected. Setting driveDate to yesterday.');
            driveDate = Date.today().addDays(-1);
        }

        String query =
            'SELECT Id, ' +
            'DriveStatus__c, ' +
            'Drive_Date__c, ' +
            'Type_of_Drive__c, ' +
            'Parent_Template_Id__c, ' +
            'AccountId, ' +
            'CreatedDate ' +
            'FROM Opportunity';

        List<String> conditions = new List<String>();

        conditions.add('Is_Template__c = false');
        conditions.add('Type_of_Drive__c = \'Mobile\'');

        if (driveDate != null) {
            conditions.add('Drive_Date__c >= :driveDate');
        }

        if (driveStatus != null && !driveStatus.isEmpty()) {
            conditions.add('DriveStatus__c IN :driveStatus');
        }

        if (opportunityIds != null && !opportunityIds.isEmpty()) {
            conditions.add('Id IN :opportunityIds');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY Drive_Date__c ASC';

        System.debug(
            LoggingLevel.DEBUG,
            'Batch Query: ' + query
        );

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> futureOPP = new List<Opportunity>();
        Map<Id, Opportunity> pastOPPMap = new Map<Id, Opportunity>();

        Set<Id> templateIds = new Set<Id>();

        for (Opportunity opp : scope) {

            if (opp.Drive_Date__c == null) {
                continue;
            }

            if (opp.Drive_Date__c >= Date.today()) {
                futureOPP.add(opp);
            } else {

                pastOPPMap.put(opp.Id, opp);

                if (opp.Parent_Template_Id__c != null) {
                    templateIds.add(opp.Parent_Template_Id__c);
                }
            }
        }

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('TaskTriggerHandler');
        if (!futureOPP.isEmpty()) {
            BSF_TaskPlanningService.cascadeTemplateToDrives(futureOPP);
        }

        if (pastOPPMap.isEmpty()) {
            return;
        }

        
  
        Map<Id, List<Task_Planning_Default__c>> templateConfigMap = getTemplateConfiguration(templateIds, inputs.taskSubjects);

        Map<Id, Set<String>> existingSubjectsByOpp =
            new Map<Id, Set<String>>();

        Set<Id> pastOpportunityIds = pastOPPMap.keySet();

        String query = 
            'SELECT Id, Subject, WhatId ' +
            'FROM Task ' +
            'WHERE WhatId IN :pastOpportunityIds';
            
        Set<String> taskSubjects = new Set<String>();
        if (inputs.taskSubjects != null && !inputs.taskSubjects.isEmpty()) {
            taskSubjects = inputs.taskSubjects;
            query += ' AND Subject IN :taskSubjects';
        }

        List<Task> existingTasks = Database.query(query);

        for (Task existingTask : existingTasks) {

            if (!existingSubjectsByOpp.containsKey(
                existingTask.WhatId
            )) {
                existingSubjectsByOpp.put(
                    existingTask.WhatId,
                    new Set<String>()
                );
            }

            existingSubjectsByOpp
                .get(existingTask.WhatId)
                .add(existingTask.Subject);
        }

        List<Task> tasksToInsert = new List<Task>();

        try {

            for (Opportunity opp : pastOPPMap.values()) {

                List<Task_Planning_Default__c> templateConfigs =
                    templateConfigMap.get(
                        opp.Parent_Template_Id__c
                    );

                if (
                    templateConfigs == null ||
                    templateConfigs.isEmpty()
                ) {
                    continue;
                }

                Set<String> existingSubjects =
                    existingSubjectsByOpp.get(opp.Id);

                if (existingSubjects == null) {
                    existingSubjects = new Set<String>();
                }

                for (
                    Task_Planning_Default__c templateConfig :
                    templateConfigs
                ) {

                    String subject =
                        templateConfig.Task_Definition__r.Name;

                    if (existingSubjects.contains(subject)) {
                        continue;
                    }

                    tasksToInsert.add(
                        createTask(
                            opp,
                            this.generalTaskRecordTypeId,
                            templateConfig
                        )
                    );
                }
            }

            DetermineTaskOwnerInvocable.TaskHierarchyContext taskHierCtxt =
                DetermineTaskOwnerInvocable.createOwnerkHierarchy(
                    pastOPPMap.keySet()
                );

            for (Task tsk : tasksToInsert) {

                tsk.OwnerId = BSF_TaskPlanningService.determineTaskOwner(typeVsOwnerMap.get(tsk.Type), taskHierCtxt.roleHierarchyMap.get(tsk.WhatId), taskHierCtxt.fallbackHierarchyMap);
            }

            if (!tasksToInsert.isEmpty()) {

                Database.SaveResult[] srList = Database.insert(tasksToInsert, false);

                for (Database.SaveResult sr : srList) {

                    if (sr.isSuccess()) {

                        System.debug('Successfully inserted Task. Task ID: '+ sr.getId());

                    } else {

                        for (Database.Error err : sr.getErrors()) {

                            System.debug(
                                'The following error has occurred.'
                            );

                            System.debug(
                                err.getStatusCode()
                                + ': '
                                + err.getMessage()
                            );

                            System.debug(
                                'Task fields that affected this error: '
                                + err.getFields()
                            );
                        }
                    }
                }

                List<BSF_Error_Log__c> errorList =
                    BSF_Utilities.createErrorLog(
                        srList,
                        'Missing Task Creation',
                        'BSF_Batch_CreatePlannedTask',
                        'execute',
                        'Error',
                        'Insert Failed'
                    );

                if (!errorList.isEmpty()) {
                    Database.insert(errorList, false);
                }
            }

            if(Test.isRunningTest() && BSF_Utilities.IS_SET_TO_GENERATE_EXCEPTION) {
                throw new CreatePlannedTaskException('Custom exception thrown for testing purposes.');
            }

        } catch (Exception ex) {

            System.debug(
                LoggingLevel.ERROR,
                'Exception in execute method: '
                + ex.getMessage()
            );

            BSF_Error_Log__c err =
                BSF_Utilities.getErrorLog(
                    null,
                    'BSF_Batch_CreatePlannedTask',
                    ex.getStackTraceString(),
                    'Error',
                    'Error creating tasks',
                    ex.getMessage()
                );

            if (err != null) {
                Database.insert(err, false);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    private static Task createTask(
        Opportunity opp,
        Id recordTypeId,
        Task_Planning_Default__c templateConfig
    ) {
        return new Task(
            Subject = templateConfig.Task_Definition__r.Name,
            ActivityDate = calculateActivityDate(opp.Drive_Date__c,Integer.valueOf(templateConfig.Task_Definition__r.Due_Date_Offset__c)),
            Priority = 'High',
            RecordTypeId = recordTypeId,
            WhatId = opp.Id,
            Drive_Date__c = opp.Drive_Date__c,
            Type = templateConfig.Task_Definition__r.Task_Type__c
        );
    }

    private static Map<Id, List<Task_Planning_Default__c>>
        getTemplateConfiguration(Set<Id> templateIds, Set<String> taskSubjects) {
        String queryStr;
        Map<Id, List<Task_Planning_Default__c>> templateConfigMap = new Map<Id, List<Task_Planning_Default__c>>();

        if (templateIds == null || templateIds.isEmpty()) {
            return templateConfigMap;
        }

        queryStr = 'SELECT Id, Template_Opportunity__c, Task_Definition__r.Name, Task_Definition__r.Task_Type__c, Task_Definition__r.Due_Date_Offset__c ' +
            'FROM Task_Planning_Default__c ' +
            'WHERE Template_Opportunity__c IN :templateIds';

        if (taskSubjects != null && !taskSubjects.isEmpty()) {
            queryStr += ' AND Task_Definition__r.Name IN :taskSubjects';
        }

        for (Task_Planning_Default__c config : Database.query(queryStr)) {

            if (
                !templateConfigMap.containsKey(
                    config.Template_Opportunity__c
                )
            ) {
                templateConfigMap.put(
                    config.Template_Opportunity__c,
                    new List<Task_Planning_Default__c>()
                );
            }

            templateConfigMap
                .get(config.Template_Opportunity__c)
                .add(config);
        }

        return templateConfigMap;
    }

    private static Date calculateActivityDate(Date referenceDate, Integer offsetDays) {
        if (referenceDate == null) { return Date.today(); }
        return referenceDate.addDays(-(offsetDays ?? 0));
    }

    public class InputWrapper {

        public Date driveDate;
        public Set<String> driveStatus;
        public Set<Id> opportunityIds;
        public Set<String> taskSubjects;
        public Integer batchSize;
    }

    public class CreatePlannedTaskException extends Exception {}
}