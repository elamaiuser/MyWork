public class DetermineTaskOwnerInvocable {
    
    public static TaskHierarchyContext createOwnerkHierarchy(Set<Id> oppIds){
        TaskHierarchyContext thc = new TaskHierarchyContext();
        thc.roleHierarchyMap = BSF_TaskPlanningService.buildRoleHierarchyMap(oppIds);
        thc.fallbackHierarchyMap = BSF_TaskPlanningService.getRoleFallbackHierarchyMap();
        return thc; 
        
    }
    @InvocableMethod(
        label='Determine Task Owner'
        description='Determines the owner of a task based on the task type and the role hierarchy of the associated opportunity'
        category='Task'
    )
    public static void assignTaskOwner(List<InputWrapper> invocableInput){
        Set<Id> oppIds = new Set<Id>();
        List<Task> tasksToInsert = new List<Task>();
        Map<String, String> typeVsOwnerMap = new Map<String, String>();
        List<String> taskTypes;
        

        for(InputWrapper input : invocableInput){
            taskTypes=input.taskTypes;
            for(Task tsk : input.tasks){
                tasksToInsert.add(tsk);
                if(tsk.WhatId != null && tsk.WhatId.getSObjectType() == Opportunity.sObjectType){
                    oppIds.add(tsk.WhatId);
                }
            }
        }

        List<Task_Definition__c> taskDefList = [SELECT Name, Task_Type__c, Assigned_To__c FROM Task_Definition__c WHERE Task_Type__c IN :taskTypes ];
        for(Task_Definition__c td : taskDefList){
            if(!typeVsOwnerMap.containsKey(td.Task_Type__c)){
                typeVsOwnerMap.put(td.Task_Type__c, td.Assigned_To__c);
            }
        }

        TaskHierarchyContext taskHierCtxt = createOwnerkHierarchy(oppIds);  
        for(Task tsk : tasksToInsert){
            tsk.OwnerId = BSF_TaskPlanningService.determineTaskOwner(typeVsOwnerMap.get(tsk.Type), taskHierCtxt.roleHierarchyMap.get(tsk.WhatId), taskHierCtxt.fallbackHierarchyMap);
        }

        if (!tasksToInsert.isEmpty()) {
             Database.SaveResult[] srList = Database.insert(tasksToInsert, false);
            List<BSF_Error_Log__c> errorList = BSF_Utilities.createErrorLog(srList,'Post Drive Analysis Task Creation','DetermineTaskOwnerInvocable','assignTaskOwner','Error','Task Insert Failed');
            if(!errorList.isEmpty()){
                Database.insert(errorList, false);
            }
        }
    }
    
    public class TaskHierarchyContext {
        public Map<Id, Map<String, Id>> roleHierarchyMap;
        public Map<String, List<String>> fallbackHierarchyMap;
    }
    

    public class InputWrapper {
        @InvocableVariable(label='Tasks' required=true)
        public List<Task> tasks;
        @InvocableVariable(label='Task Types' required=true)
        public List<String> taskTypes;
    }

}