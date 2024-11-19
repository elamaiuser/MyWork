public with sharing class TaskChecklistController {
    
    @AuraEnabled
    public static Map<String, CheckListWrapper> getRelatedCheckistRecords(String recordId){
        String Subject = '';
        String taskType = '';
        ID getRecordId;
        getRecordId = recordId;
        String sObjName = getRecordId.getSObjectType().getDescribe().getName();
        ID taskId;
        ID oppId;
        ID lookupId;
        Boolean isOpportunity = false;
        List<BSF_Task_Checklist__c> taskChecklist;
        List<BSF_Task_Checklist__c> taskChecklistToUpdate = new List<BSF_Task_Checklist__c>();
        Map<String, CheckListWrapper> taskChecklistMstr = new Map<String, CheckListWrapper>();
        Map<String, BSF_Task_Checklist__c> taskChecklistRecordMap = new Map<String, BSF_Task_Checklist__c>();
        try {
            List<String> taskSubjectList = new List<String>();
            Schema.DescribeFieldResult objFieldDescribe = Task_Checklist_Setting__mdt.Subject__c.getDescribe();
            List<Schema.PicklistEntry> lstPickListValues = objFieldDescribe.getPickListValues();

            for (Schema.PicklistEntry objPickList : lstPickListValues) {
                taskSubjectList.add(objPickList.getValue());
            }
            if(sObjName.equalsIgnoreCase('Opportunity')){
                taskType = BSF_Constants.RECRUITMENT_PLANNING_TASK;
                isOpportunity = true;
                oppId = recordId;
                String taskFilter = '';
                List<Task> opportunityRelatedTask = [SELECT Id, Subject, What.Type, WhatId FROM Task WHERE WhatId = :recordId AND Subject = :taskType];
                if (!opportunityRelatedTask.isEmpty()) {
                    taskId = opportunityRelatedTask[0].Id;
                    taskFilter = ' OR TaskLookup__c = :taskId ';
                }
                String queryString = 'SELECT ' + getAllFields('BSF_Task_Checklist__c') + ' FROM BSF_Task_Checklist__c WHERE OpportunityLookup__c = :recordId'+taskFilter;
                taskChecklist = Database.query(queryString);
                for (BSF_Task_Checklist__c record : taskChecklist) {
                    taskChecklistRecordMap.put(record.Unique_Name__c, record);
                    if (record.OpportunityLookup__c==null) {
                        taskChecklistToUpdate.add(new BSF_Task_Checklist__c(Id=record.Id, OpportunityLookup__c=recordId));
                    }
                }
                if(!taskChecklistToUpdate.isEmpty())
                    Database.update(taskChecklistToUpdate);
            }
            else if(sObjName.equalsIgnoreCase('Task')){
                List<Task> verifyTask = [SELECT Id, Subject, What.Type, WhatId FROM Task WHERE id = :recordId AND Subject IN :taskSubjectList];
                if (verifyTask.isEmpty()) {
                    return taskChecklistMstr;
                }
                taskId = recordId;
                taskType = verifyTask[0].Subject;
                oppId = verifyTask[0].WhatId;

                String queryString = 'SELECT ' + getAllFields('BSF_Task_Checklist__c') + ' FROM BSF_Task_Checklist__c WHERE TaskLookup__c = :recordId OR OpportunityLookup__c = :oppId';
                taskChecklist = Database.query(queryString);
                for (BSF_Task_Checklist__c record : taskChecklist) {
                    taskChecklistRecordMap.put(record.Unique_Name__c, record);
                    if (record.TaskLookup__c==null) {
                        taskChecklistToUpdate.add(new BSF_Task_Checklist__c(Id=record.Id, TaskLookup__c=recordId));
                    }
                }
                if(!taskChecklistToUpdate.isEmpty())
                    Database.update(taskChecklistToUpdate);
            }
            Map<String, Map<String, String>> taskChecklistFieldMap = new Map<String, Map<String, String>>();
        	Set<String> taskChecklistFields = new Set<String>();
            
            List<CheckListWrapper> taskCheckListMdtWrapper = new List<CheckListWrapper>();
            List<Task_Checklist_Setting__mdt> taskChecklistMdt = Database.query(metadataQuery());
            for(Task_Checklist_Setting__mdt mdt : taskChecklistMdt ){
                System.debug('mdt.Unique_Name__c==> '+mdt.Unique_Name__c);
                CheckListWrapper checklistWrapper = new CheckListWrapper();
                InputWrapper inputWrapper = new InputWrapper();
                Map<String, InputWrapper> inputMap = new Map<String, InputWrapper>();
                if (!taskChecklistMstr.containsKey(mdt.Unique_Name__c)) {
                    checklistWrapper.sectionHeader = mdt.Section_Header__c;
                    checklistWrapper.order = (Integer)mdt.Order__c;
                    checklistWrapper.column = (Integer)mdt.Column__c;
                    inputWrapper.inputLabel = mdt.UI_Text__c;
                    inputWrapper.helpText = mdt.Help_Text__c;
                    inputWrapper.helpTextAlign = (String.isBlank(inputWrapper.inputLabel) || inputWrapper.inputLabel.length() < 40) ? 'top-left' : 'top-right';
                    inputWrapper.hyperlink = mdt.Hyperlink__c;
                    inputWrapper.parent = mdt.Parent__c;
                    inputWrapper.order = (Integer)mdt.Order__c;
                    inputWrapper.variant = mdt.UI_Text__c == null ? 'label-hidden' : '';
                    inputWrapper.inputType = mdt.Input_Type__c;
                    if(mdt.Input_Type__c.equalsIgnoreCase('Picklist')){
                        
                        inputWrapper.picklistOptions =mapPicklistValues(mdt.Picklist_Input_1__c!= null ? mdt.Picklist_Input_1__c : '');
                    }
                    inputMap.put(mdt.Input_API_Name__c, inputWrapper);
                    checklistWrapper.inputs = inputMap;
                    taskChecklistMstr.put(mdt.Unique_Name__c, checklistWrapper);
                } else {
                    inputWrapper.inputLabel = mdt.UI_Text__c;
                    inputWrapper.helpText = mdt.Help_Text__c;
                    inputWrapper.helpTextAlign = (String.isBlank(inputWrapper.inputLabel) || inputWrapper.inputLabel.length() < 40) ? 'top-left' : 'top-right';
                    inputWrapper.hyperlink = mdt.Hyperlink__c;
                    inputWrapper.parent = mdt.Parent__c;
                    inputWrapper.order = (Integer)mdt.Order__c;
                    inputWrapper.variant = mdt.UI_Text__c == null ? 'label-hidden' : '';
                    inputWrapper.inputType = mdt.Input_Type__c;
                    inputMap.put(mdt.Input_API_Name__c, inputWrapper);
                    taskChecklistMstr.get(mdt.Unique_Name__c).inputs.put(mdt.Input_API_Name__c, inputWrapper);
                }
                if (mdt.Is_Dynamic__c) {
                    taskChecklistFields.add(mdt.Unique_Name__c);
                    System.debug('Unique_Name__c==> '+mdt.Unique_Name__c);
                }  
            }
            
            System.debug('taskChecklistFields.size()==> '+taskChecklistFields.size()+' taskChecklist.size()==>'+taskChecklist.size());
            if(taskChecklistFields.size()>taskChecklist.size()){
                for(BSF_Task_Checklist__c field: taskChecklist){
                    if(taskChecklistFields.contains(field.Unique_Name__c)){
                        taskChecklistFields.remove(field.Unique_Name__c);
                    }
                }
            }
            else{
                taskChecklistFields.clear();
            }
            
            List<BSF_Task_Checklist__c> newTaskrecordsToInsert = new List<BSF_Task_Checklist__c>();
            System.debug('taskChecklistFields==> '+taskChecklistFields);
            if(!taskChecklistFields.isEmpty()){
                for(String field : taskChecklistFields){
                    BSF_Task_Checklist__c taskChecklistRecord = new BSF_Task_Checklist__c();
                    taskChecklistRecord.Unique_Name__c = field;
                    taskChecklistRecord.TaskType__c = taskType;
                    taskChecklistRecord.TaskLookup__c = taskId;
                    taskChecklistRecord.OpportunityLookup__c = oppId;
                    newTaskrecordsToInsert.add(taskChecklistRecord);
                }
            }
            if(!newTaskrecordsToInsert.isEmpty()){
                Database.SaveResult[] sr = Database.insert(newTaskrecordsToInsert, true);
                System.debug('sr: '+sr);
                String queryString = '';
                queryString += 'SELECT ' + getAllFields('BSF_Task_Checklist__c') + ' FROM BSF_Task_Checklist__c WHERE TaskLookup__c = :taskId OR OpportunityLookup__c = :oppId';
                taskChecklist = Database.query(queryString);
                for (BSF_Task_Checklist__c record : taskChecklist) {
                    taskChecklistRecordMap.put(record.Unique_Name__c, record);
                }
            }
            System.debug('taskChecklistMstr==> '+taskChecklistMstr);
            for (Task_Checklist_Setting__mdt checklist : taskChecklistMdt) {
                if (taskChecklistMstr.containsKey(checklist.Unique_Name__c)) {
                    Set<String> inputFields = taskChecklistMstr.get(checklist.Unique_Name__c).inputs.keySet();
                    taskChecklistMstr.get(checklist.Unique_Name__c).recordId = taskChecklistRecordMap.get(checklist.Unique_Name__c).Id;
                    System.debug('checklist.Unique_Name__c==> '+checklist.Unique_Name__c);
                    System.debug('inputFields==> '+inputFields);
                    for (String key : inputFields) {
                        String inputType = taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).inputType;
                        System.debug('inputType=> '+inputType);
                        taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).recordId = taskChecklistRecordMap.get(checklist.Unique_Name__c).Id;
                        taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).inputAPIName = key;
                        taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).value = taskChecklistRecordMap.get(checklist.Unique_Name__c).get(key);
                        System.debug('Input Value=> '+taskChecklistRecordMap.get(checklist.Unique_Name__c).get(key));
                        if (inputType.equalsIgnoreCase('Checkbox')) {
                            taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).isCheckbox = true;
                        } else if (inputType.equalsIgnoreCase('Text')) {
                            taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).isTextInput = true;
                        } else if (inputType.equalsIgnoreCase('Number')) {
                            taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).isNumber = true;
                        } else if (inputType.equalsIgnoreCase('Picklist')) {
                            taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).isPicklist = true;
                        } else if (inputType.equalsIgnoreCase('TextArea')) {
                            taskChecklistMstr.get(checklist.Unique_Name__c).inputs.get(key).isTextArea = true;
                        }
                    }
                } else {
                    //for static display texts and non input elements.
                    System.debug('=======');
                }
            }

        } catch (Exception e) {
            throw new AuraHandledException('Line: '+e.getLineNumber()+' '+e.getMessage());
        }

        return taskChecklistMstr;
    }

    @AuraEnabled
    public static Map<String, String> updateTaskChecklist(String recordData) {
        system.debug('recordData '+recordData);
        Map<String, String> updateStatus = new Map<String, String>();
        try {
            List<BSF_Task_Checklist__c> taskChecklistToUpdate = new List<BSF_Task_Checklist__c>();
            taskChecklistToUpdate = (List<BSF_Task_Checklist__c>)JSON.deserialize(recordData, List<BSF_Task_Checklist__c>.class);
            if(!taskChecklistToUpdate.isEmpty()){
                Database.SaveResult[] sr = Database.update(taskChecklistToUpdate, true);
                updateStatus = new Map<String, String>{'isSuccess' => 'true', 'message' => 'Checklist has been successfully saved.' , 'title'=> 'Success', 'variant'=>  'success'};
            }
        } catch (Exception e) {
            updateStatus = new Map<String, String>{'isSuccess' => 'false', 'message' => 'Error occured. '+'Line: '+e.getLineNumber()+' '+e.getMessage(), 'title'=> 'Error saving record', 'variant'=>  'error'};
        }
        return updateStatus;
    }
    
    private static String metadataQuery(){
        String createQuery = '';
        createQuery += 'SELECT ' + getAllFields('Task_Checklist_Setting__mdt') + ' FROM Task_Checklist_Setting__mdt WHERE Subject__c = :taskType';
        return createQuery;
    }
    
    private static String taskChecklistQuery(){
        String createQuery = '';
        createQuery += 'SELECT ' + getAllFields('BSF_Task_Checklist__c') + ' FROM BSF_Task_Checklist__c WHERE TaskLookup__c = :lookupId';
        return createQuery;
    }
    
    private static String getAllFields(String SobjectApiName){
        List<String> fieldNames = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(SobjectApiName).getDescribe().fields.getMap();        
        for(String fieldName : fieldMap.keySet()) {
            fieldNames.add(fieldName);
        }
        String allFields = String.join(fieldNames, ', ');
        return allFields;
    }

    private static List<Object> mapPicklistValues(String options){
         List<Object> picklistOptionsMap = new List<Object>();
         for (String option : options.split(';')) {
             picklistOptionsMap.add(new Map<String, String>{'label' => option.trim(), 'value' => option.trim()});
         }
         return picklistOptionsMap;
    }

    @AuraEnabled
    public static Boolean checkEditAccess() {
        Boolean hasEditAccess = false;
        Id profileId= userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        Task_Checklist_Setting__mdt taskChecklistMdt = [SELECT Id, MasterLabel, UI_Text__c FROM Task_Checklist_Setting__mdt WHERE MasterLabel='AllowedProfileList' LIMIT 1];
        if(taskChecklistMdt.UI_Text__c!=null)
            hasEditAccess = taskChecklistMdt.UI_Text__c.split(';').contains(profileName);
        System.debug('hasEditAccess=> '+hasEditAccess);
        return hasEditAccess;
    }


    public class CheckListWrapper{
        @AuraEnabled public String sectionHeader;
        @AuraEnabled public Integer order;
        @AuraEnabled public Integer column;
        @AuraEnabled public String recordId;
        @AuraEnabled public Map<String, InputWrapper> inputs;
    }

    public class InputWrapper{
        @AuraEnabled public String recordId;
        @AuraEnabled public String inputLabel;
        @AuraEnabled public String inputAPIName;
        @AuraEnabled public String helpText;
        @AuraEnabled public String helpTextAlign;
        @AuraEnabled public String hyperlink;
        @AuraEnabled public String parent;
        @AuraEnabled public Integer order;
        @AuraEnabled public Object value;
        @AuraEnabled public String inputType;
        @AuraEnabled public Boolean isCheckbox;
        @AuraEnabled public Boolean isTextInput;
        @AuraEnabled public Boolean isNumber;
        @AuraEnabled public Boolean isPicklist;
        @AuraEnabled public Boolean isTextArea;
        @AuraEnabled public String variant;
        @AuraEnabled public List<Object> picklistOptions;
    }
}