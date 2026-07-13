public without sharing class BSFTaskChecklistTriggerHandler extends TriggerHandler {
    public static String oppPrefix = Opportunity.sObjectType.getDescribe().getKeyPrefix();
    public static Map<String, Map<String, Task_Checklist_Setting__mdt>> metadataMap = getMetaDataMap();
    public static Map<String, Map<String,String>> taskVsFieldVsObjectMap = getFieldVsObjectMap(metadataMap);
    public static List<String> subjectList = getSubjectList();

    public override void afterUpdate() {
        processChecklistUpdates((List<BSF_Task_Checklist__c>)Trigger.new, (Map<Id, BSF_Task_Checklist__c>)Trigger.oldMap);
    }
    public override void beforeInsert() {
        prepopulateValues((List<BSF_Task_Checklist__c>)Trigger.new);
    }
    public static void prepopulateValues(List<BSF_Task_Checklist__c> newList) {
        if(subjectList.isEmpty()){
                return;
        }
        Set<String> taskIds = new Set<String>();
        Map<String,Id> taskVsOppMap = new Map<String,Id>();
        Map<String,Opportunity> taskVsOpportunityMap = new Map<String,Opportunity>();
        Map<String,Account> taskVsAccountMap = new Map<String,Account>();
        Map<Id,String> taskVsSubjectMap = new Map<Id,String>();
        Map<String,String> fieldVsObjectMap = new Map<String,String>();
        if(taskVsFieldVsObjectMap != null){
            for(String subject : subjectList){
                if(taskVsFieldVsObjectMap.containsKey(subject)){
                    fieldVsObjectMap.putAll(taskVsFieldVsObjectMap.get(subject));
                }
            }
        }
        if(newList != null && !newList.isEmpty() && !fieldVsObjectMap.isEmpty()){
            for(BSF_Task_Checklist__c taskChecklist: newList){
                if(String.isNotBlank(taskChecklist.TaskLookup__c) && String.isNotBlank(taskChecklist.Unique_Name__c) 
                        && fieldVsObjectMap.containsKey(taskChecklist.Unique_Name__c)){
                            taskIds.add(taskChecklist.TaskLookup__c);
                }
            }
        }
        if(!taskIds.isEmpty()){
            List<Task> taskList = [SELECT Id, 
                                            Subject, 
                                            WhatId, 
                                            Status 
                                    FROM Task 
                                    WHERE Id IN: taskIds
                                    AND Subject IN :subjectList
                                    AND WhatId != null
                                    WITH SYSTEM_MODE];
            for(Task task : taskList){
                if(((String)task.WhatId).startsWith(oppPrefix)){
                    taskVsOppMap.put(task.Id,task.WhatId);
                    taskVsSubjectMap.put(task.Id,task.Subject);
                }
            }
        }
        if(!taskVsOppMap.isEmpty()){
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            Map<Id,Account> accMap = new Map<Id,Account>();
            List<Id> accIds = new List<Id>();
            List<String> oppFields = new List<String>();
            List<String> accFields = new List<String>();
            for(String field : fieldVsObjectMap.keySet()){
                if(fieldVsObjectMap.get(field).equals('Account')){
                    accFields.add(field);
                }else if(fieldVsObjectMap.get(field).equals('Opportunity')){
                    oppFields.add(field);
                }
            }
            String oppQueryStr = 'SELECT Id, AccountId';
            if(!oppFields.isEmpty()){
                for(String field : oppFields){
                    oppQueryStr += ', '+field;
                }
            }
            oppQueryStr = oppQueryStr + ' FROM Opportunity WHERE Id IN (\''+String.join(taskVsOppMap.values(),'\',\'')+'\') AND AccountId != null';
            System.debug('oppQueryStr : '+oppQueryStr);
            List<Opportunity> oppList = Database.query(oppQueryStr,AccessLevel.SYSTEM_MODE);
            if(!oppList.isEmpty()){
                oppMap = new Map<Id, Opportunity>(oppList);
            }
            System.debug('oppMap : '+oppMap);
            for(String taskId : taskVsOppMap.keySet()){
                if(!oppMap.isEmpty() && oppMap.containsKey(taskVsOppMap.get(taskId))){
                    taskVsOpportunityMap.put(taskId,oppMap.get(taskVsOppMap.get(taskId)));
                    accIds.add(oppMap.get(taskVsOppMap.get(taskId)).AccountId);
                }
            }
            System.debug('accIds : '+accIds);
            if(!accIds.isEmpty()){
                String accQueryStr = 'SELECT Id';
                if(!accFields.isEmpty()){
                    for(String field : accFields){
                        accQueryStr += ', '+field;
                    }
                }
                accQueryStr = accQueryStr + ' FROM Account WHERE Id IN (\''+String.join(accIds,'\',\'')+'\')';
                System.debug('accQueryStr : '+accQueryStr);
                List<Account> accList = Database.query(accQueryStr,AccessLevel.SYSTEM_MODE);
                if(!accList.isEmpty()){
                    accMap = new Map<Id, Account>(accList);
                }
                System.debug('accMap : '+accMap);
                for(String taskId : taskVsOpportunityMap.keySet()){
                    if(!accMap.isEmpty() && accMap.containsKey(taskVsOpportunityMap.get(taskId).AccountId)){
                        taskVsAccountMap.put(taskId,accMap.get(taskVsOpportunityMap.get(taskId).AccountId));
                    }
                }
            }
        }
        if(newList != null && !newList.isEmpty()){
            for(BSF_Task_Checklist__c taskChecklist: newList){
                if(String.isNotBlank(taskChecklist.TaskLookup__c) && String.isNotBlank(taskChecklist.Unique_Name__c) 
                        && fieldVsObjectMap.containsKey(taskChecklist.Unique_Name__c) && !taskVsOppMap.isEmpty()
                        && taskVsOppMap.containsKey(taskChecklist.TaskLookup__c)){
                            if(fieldVsObjectMap.get(taskChecklist.Unique_Name__c).equals('Account') && !taskVsAccountMap.isEmpty()
                                    && taskVsAccountMap.containsKey(taskChecklist.TaskLookup__c) 
                                    && taskVsAccountMap.get(taskChecklist.TaskLookup__c).get(taskChecklist.Unique_Name__c) != null){
                                        Object value = taskVsAccountMap.get(taskChecklist.TaskLookup__c).get(taskChecklist.Unique_Name__c);
                                        String fieldName = metadataMap.get(taskVsSubjectMap.get(taskChecklist.TaskLookup__c)).get(taskChecklist.Unique_Name__c).Input_API_Name__c;
                                        taskChecklist.put(fieldName,UpdateTaskChecklistEventHandler.getFieldValue(fieldName,String.valueOf(value)));
                            }else if(fieldVsObjectMap.get(taskChecklist.Unique_Name__c).equals('Opportunity') && !taskVsOpportunityMap.isEmpty()
                                    && taskVsOpportunityMap.containsKey(taskChecklist.TaskLookup__c) 
                                    && taskVsOpportunityMap.get(taskChecklist.TaskLookup__c).get(taskChecklist.Unique_Name__c) != null){
                                        Object value = taskVsOpportunityMap.get(taskChecklist.TaskLookup__c).get(taskChecklist.Unique_Name__c);
                                        String fieldName = metadataMap.get(taskVsSubjectMap.get(taskChecklist.TaskLookup__c)).get(taskChecklist.Unique_Name__c).Input_API_Name__c;
                                        taskChecklist.put(fieldName,UpdateTaskChecklistEventHandler.getFieldValue(fieldName,String.valueOf(value)));
                            }
                }
            }
        }
    }
    public static void processChecklistUpdates(List<BSF_Task_Checklist__c> newList, Map<Id, BSF_Task_Checklist__c> oldMap) {
        Map<String,List<BSF_Task_Checklist__c>> taskvsChecklistMap = new Map<String,List<BSF_Task_Checklist__c>>();
        Map<String,Id> taskVsOppMap = new Map<String,Id>();
        Map<String,Opportunity> taskVsOpportunityMap = new Map<String,Opportunity>();
        Map<String,Account> taskVsAccountMap = new Map<String,Account>();
        List<BSF_Task_Checklist__c> checklistsToProcess = new List<BSF_Task_Checklist__c>();
        /*Map<String,String> fieldVsObjectMap = new Map<String,String>();
        if(!taskVsFieldVsObjectMap.isEmpty() && taskVsFieldVsObjectMap.containsKey(BSF_Constants.POST_DRIVE_ANALYSIS_TASK)){
            fieldVsObjectMap = taskVsFieldVsObjectMap.get(BSF_Constants.POST_DRIVE_ANALYSIS_TASK);
        }*/
        if(newList != null && !newList.isEmpty() && oldMap != null && !oldMap.isEmpty()
                && !metadataMap.isEmpty()){
                    for(BSF_Task_Checklist__c taskChecklist: newList) {
                        if(taskChecklist.Id != null && oldMap.containsKey(taskChecklist.Id)
                                && String.isNotBlank(taskChecklist.TaskType__c) && metadataMap.containsKey(taskChecklist.TaskType__c)
                                && String.isNotBlank(taskChecklist.TaskLookup__c) && String.isNotBlank(taskChecklist.Unique_Name__c) 
                                && taskVsFieldVsObjectMap.containsKey(taskChecklist.TaskType__c) && taskVsFieldVsObjectMap.get(taskChecklist.TaskType__c).containsKey(taskChecklist.Unique_Name__c)){
                                    if(!taskvsChecklistMap.containsKey(taskChecklist.TaskLookup__c)){
                                        taskvsChecklistMap.put(taskChecklist.TaskLookup__c,new List<BSF_Task_Checklist__c>());
                                    }
                                    taskvsChecklistMap.get(taskChecklist.TaskLookup__c).add(taskChecklist);
                        }
                    }
        }
        System.debug('taskvsChecklistMap : '+taskvsChecklistMap);
        if(!taskvsChecklistMap.isEmpty()){
            List<Task> taskList = [SELECT Id, 
                                            Subject, 
                                            WhatId, 
                                            Status 
                                    FROM Task 
                                    WHERE Id IN: taskvsChecklistMap.keySet()
                                    AND Subject IN :subjectList
                                    AND Status NOT IN ('Completed','Cancelled')
                                    WITH SYSTEM_MODE];
            for(Task task : taskList){
                if(((String)task.WhatId).startsWith(oppPrefix)){
                    for(BSF_Task_Checklist__c checklist : taskvsChecklistMap.get(task.Id)){
                        String fieldName = metadataMap.get(checklist.TaskType__c).get(checklist.Unique_Name__c).Input_API_Name__c;
                        if(oldMap.get(checklist.Id).get(fieldName) != checklist.get(fieldName)){
                            checklistsToProcess.add(checklist);
                            taskVsOppMap.put(task.Id,task.WhatId);
                        }
                    }
                }
            }
        }
        System.debug('checklistsToProcess : '+checklistsToProcess);
        if(!taskVsOppMap.isEmpty()){
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            Map<Id,Account> accMap = new Map<Id,Account>();
            List<Id> accIds = new List<Id>();
            Set<String> oppFields = new Set<String>();
            Set<String> accFields = new Set<String>();
            for(Map<String,String> fieldVsObjectMap : taskVsFieldVsObjectMap.values()){
                for(String field : fieldVsObjectMap.keySet()){
                    if('Account'.equalsIgnoreCase(fieldVsObjectMap.get(field))){
                        accFields.add(field.trim().toLowerCase());
                    }else if('Opportunity'.equalsIgnoreCase(fieldVsObjectMap.get(field))){
                        oppFields.add(field.trim().toLowerCase());
                    }
                }
            }
            String oppQueryStr = 'SELECT Id, AccountId';
            if(!oppFields.isEmpty()){
                for(String field : oppFields){
                    oppQueryStr += ', '+field;
                }
            }
            oppQueryStr = oppQueryStr + ' FROM Opportunity WHERE Id IN (\''+String.join(taskVsOppMap.values(),'\',\'')+'\') AND AccountId != null';
            System.debug('oppQueryStr : '+oppQueryStr);
            List<Opportunity> oppList = Database.query(oppQueryStr,AccessLevel.SYSTEM_MODE);
            if(!oppList.isEmpty()){
                oppMap = new Map<Id, Opportunity>(oppList);
            }
            System.debug('oppMap : '+oppMap);
            for(String taskId : taskVsOppMap.keySet()){
                if(!oppMap.isEmpty() && oppMap.containsKey(taskVsOppMap.get(taskId))){
                    taskVsOpportunityMap.put(taskId,oppMap.get(taskVsOppMap.get(taskId)));
                    accIds.add(oppMap.get(taskVsOppMap.get(taskId)).AccountId);
                }
            }
            System.debug('accIds : '+accIds);
            if(!accIds.isEmpty()){
                String accQueryStr = 'SELECT Id';
                if(!accFields.isEmpty()){
                    for(String field : accFields){
                        accQueryStr += ', '+field;
                    }
                }
                accQueryStr = accQueryStr + ' FROM Account WHERE Id IN (\''+String.join(accIds,'\',\'')+'\')';
                System.debug('accQueryStr : '+accQueryStr);
                List<Account> accList = Database.query(accQueryStr,AccessLevel.SYSTEM_MODE);
                if(!accList.isEmpty()){
                    accMap = new Map<Id, Account>(accList);
                }
                System.debug('accMap : '+accMap);
                for(String taskId : taskVsOpportunityMap.keySet()){
                    if(!accMap.isEmpty() && accMap.containsKey(taskVsOpportunityMap.get(taskId).AccountId)){
                        taskVsAccountMap.put(taskId,accMap.get(taskVsOpportunityMap.get(taskId).AccountId));
                    }
                }
            }
        }
        System.debug('taskVsOpportunityMap : '+taskVsOpportunityMap);
        System.debug('taskVsAccountMap : '+taskVsAccountMap);
        if(!checklistsToProcess.isEmpty()){
            updateAccountAndOpportunity(checklistsToProcess,taskVsOpportunityMap,taskVsAccountMap,BSF_Constants.POST_DRIVE_ANALYSIS_TASK);
        }
    }
    public static Map<String, Map<String, Task_Checklist_Setting__mdt>> getMetaDataMap() {
        Map<String, Map<String, Task_Checklist_Setting__mdt>> metadataMap = new Map<String, Map<String, Task_Checklist_Setting__mdt>>();
        Map<String, Task_Checklist_Setting__mdt> checklistSettings = Task_Checklist_Setting__mdt.getAll();
        for(String key: checklistSettings.keySet()){
            if(String.isNotBlank(checklistSettings.get(key).Subject__c) && String.isNotBlank(checklistSettings.get(key).Unique_Name__c)){
                if(!metadataMap.containsKey(checklistSettings.get(key).Subject__c)){
                    metadataMap.put(checklistSettings.get(key).Subject__c,new Map<String, Task_Checklist_Setting__mdt>());
                }
                if(!metadataMap.get(checklistSettings.get(key).Subject__c).containsKey(checklistSettings.get(key).Unique_Name__c)){
                    metadataMap.get(checklistSettings.get(key).Subject__c).put(checklistSettings.get(key).Unique_Name__c,checklistSettings.get(key));
                }
            }
        }
        return metadataMap;
    }
    public static Map<String, Map<String,String>> getFieldVsObjectMap(Map<String, Map<String, Task_Checklist_Setting__mdt>> metaDataMap) {
        Map<String, Map<String,String>> fieldVsObjectMap = new Map<String, Map<String,String>>();
        if(metaDataMap != null && !metaDataMap.isEmpty()){
            for(String subject: metaDataMap.keySet()){
                Map<String,String> fieldMap = new Map<String,String>();
                for(String uniqueName: metaDataMap.get(subject).keySet()){
                    if(String.isNotBlank(uniqueName) && uniqueName.trim().endsWith('__c') 
                            && String.isNotBlank(metaDataMap.get(subject).get(uniqueName).Field_Mapping_Object__c)){
                                
                                fieldMap.put(
                                    uniqueName.trim(), 
                                    metaDataMap.get(subject).get(uniqueName).Field_Mapping_Object__c.trim()
                                );
                    }
                }
                if(!fieldMap.isEmpty()){
                    fieldVsObjectMap.put(subject,fieldMap);
                }
            }
        }
        return fieldVsObjectMap;
    }
    public static void updateAccountAndOpportunity(List<BSF_Task_Checklist__c> newList, Map<String,Opportunity> taskVsOpportunityMap, Map<String,Account> taskVsAccountMap, String subject){
        Map<Id,Account> accountsToUpdate = new Map<Id,Account>();
        Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();

        if(newList != null && !newList.isEmpty() && !subjectList.isEmpty() && !taskVsFieldVsObjectMap.isEmpty()){
            for(BSF_Task_Checklist__c taskChecklist : newList){
                
                if(String.isNotBlank(taskChecklist.TaskLookup__c) && String.isNotBlank(taskChecklist.Unique_Name__c)
                        && taskVsFieldVsObjectMap.containsKey(taskChecklist.TaskType__c)) {
                            
                    Map<String, String> uniqueNameMap = taskVsFieldVsObjectMap.get(taskChecklist.TaskType__c);
                    String uName = taskChecklist.Unique_Name__c.trim();

                    if (uniqueNameMap.containsKey(uName)) {
                        String targetObject = uniqueNameMap.get(uName);
                        String fieldName = metadataMap.get(taskChecklist.TaskType__c).get(uName).Input_API_Name__c;
                        Object fieldValue = taskChecklist.get(fieldName);

                        if(fieldValue instanceof String && (String.isBlank((String) fieldValue) || (String)fieldValue == '--none--')){
                            fieldValue = null;
                        }

                        if('Account'.equalsIgnoreCase(targetObject) && taskVsAccountMap != null && taskVsAccountMap.containsKey(taskChecklist.TaskLookup__c)){
                            if(taskVsAccountMap.get(taskChecklist.TaskLookup__c).get(uName) != fieldValue){
                                Account accObj;
                                if(accountsToUpdate.containsKey(taskVsAccountMap.get(taskChecklist.TaskLookup__c).Id)){
                                    accObj = accountsToUpdate.get(taskVsAccountMap.get(taskChecklist.TaskLookup__c).Id);
                                }else{
                                    accObj = new Account(Id = taskVsAccountMap.get(taskChecklist.TaskLookup__c).Id);
                                }
                                accObj.put(uName, fieldValue);
                                accountsToUpdate.put(accObj.Id,accObj);
                            }
                        } 
                        else if('Opportunity'.equalsIgnoreCase(targetObject) && taskVsOpportunityMap != null && taskVsOpportunityMap.containsKey(taskChecklist.TaskLookup__c)){
                            if(taskVsOpportunityMap.get(taskChecklist.TaskLookup__c).get(uName) != fieldValue){
                                Opportunity oppObj;
                                if(oppsToUpdate.containsKey(taskVsOpportunityMap.get(taskChecklist.TaskLookup__c).Id)){
                                    oppObj = oppsToUpdate.get(taskVsOpportunityMap.get(taskChecklist.TaskLookup__c).Id);
                                }else{
                                    oppObj = new Opportunity(Id = taskVsOpportunityMap.get(taskChecklist.TaskLookup__c).Id);
                                }
                                oppObj.put(uName, fieldValue);
                                oppsToUpdate.put(oppObj.Id,oppObj);
                            }
                        }
                    }
                }
            }
        }
        
        System.debug('oppsToUpdate : '+oppsToUpdate);
        System.debug('accountsToUpdate : '+accountsToUpdate);
        
        if(!oppsToUpdate.isEmpty()){
            update oppsToUpdate.values();
        }
        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate.values();
        }
    }
    public static void updateTaskChecklist(Map<Id,Sobject> sobjectMap, Map<Id,List<String>> fieldMap, Map<Id,List<String>> sobjectVsTaskMap){
        List<Update_Task_Checklist__e> updateCheckListEvents = new List<Update_Task_Checklist__e>();
        if(sobjectMap != null && !sobjectMap.isEmpty() && fieldMap != null && !fieldMap.isEmpty() && sobjectVsTaskMap != null && !sobjectVsTaskMap.isEmpty()){
            for(Id objId : sobjectMap.keySet()){
                if(fieldMap.containsKey(objId)){
                    for(String field : fieldMap.get(objId)){
                        if(sobjectVsTaskMap.containsKey(objId)){
                            for(String taskId : sobjectVsTaskMap.get(objId)){
                                if(metadataMap.get(BSF_Constants.POST_DRIVE_ANALYSIS_TASK).containsKey(field)){
                                    Update_Task_Checklist__e event = new Update_Task_Checklist__e();
                                    event.Task_Id__c = taskId;
                                    event.CheckList_Name__c = field;
                                    event.Field_Api_Name__c = metadataMap.get(BSF_Constants.POST_DRIVE_ANALYSIS_TASK).get(field).Input_API_Name__c;
                                    if(sobjectMap.get(objId).get(field) != null){
                                        event.Value__c = String.valueOf(sobjectMap.get(objId).get(field));
                                    }
                                    updateCheckListEvents.add(event);
                                }
                            }
                        }
                    }
                }
            }
        }
        System.debug('updateCheckListEvents : '+updateCheckListEvents);
        if(!updateCheckListEvents.isEmpty()){
            List<Database.SaveResult> results = EventBus.publish(updateCheckListEvents);
        }
    }
    public static void updateTaskChecklist(List<Sobject> newList, Map<Id, Sobject> oldMap){
        Map<Id,Account> accMap = new Map<Id,Account>();
        Map<Id,List<String>> fieldChangedMap = new Map<Id,List<String>>();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        Map<String,String> fieldVsObjectMap = new Map<String,String>();
        if(!taskVsFieldVsObjectMap.isEmpty() && taskVsFieldVsObjectMap.containsKey(BSF_Constants.POST_DRIVE_ANALYSIS_TASK)){
            fieldVsObjectMap = taskVsFieldVsObjectMap.get(BSF_Constants.POST_DRIVE_ANALYSIS_TASK);
        }
        if(newList != null && !newList.isEmpty() && metadataMap.containsKey(BSF_Constants.POST_DRIVE_ANALYSIS_TASK) 
                && !fieldVsObjectMap.isEmpty()){
                    List<String> oppFields = new List<String>();
                    List<String> accFields = new List<String>();
                    for(String field : fieldVsObjectMap.keySet()){
                        if(fieldVsObjectMap.get(field).equals('Account')){
                            accFields.add(field);
                        }else if(fieldVsObjectMap.get(field).equals('Opportunity')){
                            oppFields.add(field);
                        }
                    }
                    for(Sobject sobj : newList){
                        System.debug('sobj : '+JSON.serialize(sobj));
                        if(sobj.getSObjectType() == Account.SObjectType && sobj.get('Id') != null  && checkFieldValueChanged(sobj,oldMap,accFields)){
                            accMap.put((Id)sobj.get('Id'),(Account)sobj);
                            fieldChangedMap.put((Id)sobj.get('Id'),getFieldChanged(sobj,oldMap,accFields));
                        }else if(sobj.getSObjectType() == Opportunity.SObjectType && sobj.get('Id') != null && checkFieldValueChanged(sobj,oldMap,oppFields)){
                            oppMap.put((Id)sobj.get('Id'),(Opportunity)sobj);
                            fieldChangedMap.put((Id)sobj.get('Id'),getFieldChanged(sobj,oldMap,oppFields));
                        }
                    }
        }
        System.debug('fieldChangedMap : '+fieldChangedMap);
        System.debug('accMap : '+accMap);
        if(!accMap.isEmpty()){
            updateTaskChecklistForAccounts(accMap,fieldChangedMap);
        }
        System.debug('oppMap : '+oppMap);
        if(!oppMap.isEmpty()){
            updateTaskChecklistForOpportunities(oppMap,fieldChangedMap);
        }
    }
    public static Boolean checkFieldValueChanged(Sobject sobj, Map<Id, Sobject> oldMap, List<String> fieldList){
        Boolean fieldChanged = false;
        if(sobj != null && fieldList != null && !fieldList.isEmpty()){
            System.debug('sobj.get(\'Id\') : '+sobj.get('Id'));
            System.debug('oldMap.containsKey((Id)sobj.get(\'Id\')) : '+oldMap.containsKey((Id)sobj.get('Id')));
            if(oldMap == null || oldMap.isEmpty()){
                fieldChanged = true;
            }else if(sobj.get('Id') != null && oldMap.containsKey((Id)sobj.get('Id'))){
                for(String field : fieldList){
                    System.debug('field : fieldList : '+field);
                    System.debug('sobj.get(field) : '+sobj.get(field));
                    System.debug('oldMap.get((Id)sobj.get(\'Id\')).get(field) : '+oldMap.get((Id)sobj.get('Id')).get(field));
                    if(sobj.get(field) != oldMap.get((Id)sobj.get('Id')).get(field)){
                        fieldChanged = true;
                    }
                }
            }
        }
        System.debug('fieldChanged : '+fieldChanged);
        return fieldChanged;
    }
    public static List<String> getFieldChanged(Sobject sobj, Map<Id, Sobject> oldMap, List<String> fieldList){
        List<String> fieldChangedList = new List<String>();
        if(sobj != null && fieldList != null && !fieldList.isEmpty()){
            if(oldMap == null || oldMap.isEmpty()){
                fieldChangedList = fieldList;
            }else if(sobj.get('Id') != null && oldMap.containsKey((Id)sobj.get('Id'))){
                for(String field : fieldList){
                    if(sobj.get(field) != oldMap.get((Id)sobj.get('Id')).get(field)){
                        fieldChangedList.add(field);
                    }
                }
            }
        }
        return fieldChangedList;
    }
    public static void updateTaskChecklistForAccounts(Map<Id,Account> accMap, Map<Id,List<String>> fieldChangedMap){
        Map<Id,List<String>> accVsTaskMap = new Map<Id,List<String>>();
        if(accMap != null && !accMap.isEmpty() && fieldChangedMap != null && !fieldChangedMap.isEmpty()){
            Map<Id,Id> oppVsAccMap = new Map<Id,Id>();
            List<Opportunity> oppList = [SELECT Id, 
                                                AccountId
                                            FROM Opportunity
                                            WHERE AccountId IN :accMap.keySet()
                                            WITH SYSTEM_MODE];
            for(Opportunity opp : oppList){
                oppVsAccMap.put(opp.Id,opp.AccountId);
            }
            if(!oppVsAccMap.isEmpty()){
                List<Task> allTasks = [SELECT Id, 
                                                WhatId 
                                        FROM Task 
                                        WHERE Subject = :BSF_Constants.POST_DRIVE_ANALYSIS_TASK
                                        AND Status NOT IN ('Completed','Cancelled')
                                        AND WhatId IN :oppVsAccMap.keySet()
                                        WITH SYSTEM_MODE];
                for(Task task : allTasks){
                    if(!accVsTaskMap.containsKey(oppVsAccMap.get(task.WhatId))){
                        accVsTaskMap.put(oppVsAccMap.get(task.WhatId),new List<String>());
                    }
                    accVsTaskMap.get(oppVsAccMap.get(task.WhatId)).add(task.Id);
                }
            }
        }
        System.debug('accVsTaskMap : '+accVsTaskMap);
        if(!accVsTaskMap.isEmpty()){
            updateTaskChecklist(accMap,fieldChangedMap,accVsTaskMap);
        }
    }
    public static void updateTaskChecklistForOpportunities(Map<Id,Opportunity> oppMap, Map<Id,List<String>> fieldChangedMap){
        Map<Id,List<String>> oppVsTaskMap = new Map<Id,List<String>>();
        if(oppMap != null && !oppMap.isEmpty() && fieldChangedMap != null && !fieldChangedMap.isEmpty()){
            List<Task> allTasks = [SELECT Id, 
                                            WhatId 
                                    FROM Task 
                                    WHERE Subject = :BSF_Constants.POST_DRIVE_ANALYSIS_TASK
                                    AND Status NOT IN ('Completed','Cancelled')
                                    AND WhatId IN :oppMap.keySet()
                                    WITH SYSTEM_MODE];
            for(Task task : allTasks){
                if(!oppVsTaskMap.containsKey(task.WhatId)){
                    oppVsTaskMap.put(task.WhatId,new List<String>());
                }
                oppVsTaskMap.get(task.WhatId).add(task.Id);
            }
        }
        System.debug('oppVsTaskMap : '+oppVsTaskMap);
        if(!oppVsTaskMap.isEmpty()){
            updateTaskChecklist(oppMap,fieldChangedMap,oppVsTaskMap);
        }
    }
    public static List<String> getSubjectList() {
        List<String> subjectList = new List<String>{};
        List<Task_Definition__c> def = [SELECT Name, 
                                            Task_Type__c 
                                        FROM Task_Definition__c
                                        WHERE Task_Type__c IN (:BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_SBPM, :BSF_Constants.TASK_TYPE_POST_DRIVE_ANALYSIS_AM,:BSF_Constants.TASK_TYPE_RECRUITMENT_STRATEGY_MEETING)
                                        AND Name != null];
        for(Task_Definition__c taskDef : def){
            subjectList.add(taskDef.Name);
        }
        return subjectList;
    }
}