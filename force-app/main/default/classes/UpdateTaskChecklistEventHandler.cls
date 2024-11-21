public without sharing class UpdateTaskChecklistEventHandler {
    public static Map<String, Schema.SObjectField> checklistFieldMap = Schema.sObjectType.BSF_Task_Checklist__c.fields.getMap();
    public static void processEvents(List<Update_Task_Checklist__e> eventList){
        Set<String> taskIds = new Set<String>();
        Set<String> checklistNames = new Set<String>();
        List<BSF_Task_Checklist__c> checklistsToUpdate = new List<BSF_Task_Checklist__c>();
        if(eventList != null && !eventList.isEmpty()){
            for(Update_Task_Checklist__e event : eventList){
                if(String.isNotBlank(event.Task_Id__c) && String.isNotBlank(event.CheckList_Name__c) 
                        && String.isNotBlank(event.Field_Api_Name__c) && checklistFieldMap.containsKey(event.Field_Api_Name__c)){
                            checklistNames.add(event.CheckList_Name__c);
                            taskIds.add(event.Task_Id__c);
                }
            }
            System.debug('taskIds : '+taskIds);
            System.debug('checklistNames : '+checklistNames);
            Map<String,BSF_Task_Checklist__c> checklistMap = getChecklistMap(taskIds,checklistNames);
            System.debug('checklistMap : '+checklistMap);
            for(Update_Task_Checklist__e event : eventList){
                if(String.isNotBlank(event.Task_Id__c) && String.isNotBlank(event.CheckList_Name__c) 
                        && String.isNotBlank(event.Field_Api_Name__c) && checklistFieldMap.containsKey(event.Field_Api_Name__c)
                        && checklistMap.containsKey(event.Task_Id__c+'-'+event.CheckList_Name__c)){
                            if(checklistMap.get(event.Task_Id__c+'-'+event.CheckList_Name__c).get(event.Field_Api_Name__c) != getFieldValue(event.Field_Api_Name__c,event.Value__c)){
                                BSF_Task_Checklist__c checklistObj = new BSF_Task_Checklist__c(Id = checklistMap.get(event.Task_Id__c+'-'+event.CheckList_Name__c).Id);
                                checklistObj.put(event.Field_Api_Name__c,getFieldValue(event.Field_Api_Name__c,event.Value__c));
                                System.debug('checklistObj : '+checklistObj);
                                checklistsToUpdate.add(checklistObj);
                            }
                }
            }
        }
        if(!checklistsToUpdate.isEmpty()){
            System.debug('checklistsToUpdate : '+checklistsToUpdate);
            Database.update(checklistsToUpdate,false,AccessLevel.SYSTEM_MODE); 
        }
    }

    public static Map<String,BSF_Task_Checklist__c> getChecklistMap(Set<String> taskIds, Set<String> checklistNames){
        Map<String,BSF_Task_Checklist__c> checklistMap = new Map<String,BSF_Task_Checklist__c>();
        if(!taskIds.isEmpty() && !checklistNames.isEmpty()){
            List<BSF_Task_Checklist__c> checklists = [SELECT Id, 
                                                            Name, 
                                                            Unique_Name__c, 
                                                            Input_Long_Text_Area__c, 
                                                            Input_Short_Text_1__c, 
                                                            Input_Short_Text_2__c, 
                                                            Input_Checkbox__c, 
                                                            Picklist_Input_1__c, 
                                                            Picklist_Input_2__c, 
                                                            TaskLookup__c, 
                                                            TaskType__c, 
                                                            OpportunityLookup__c 
                                                        FROM BSF_Task_Checklist__c
                                                        WHERE TaskLookup__c IN : taskIds
                                                        AND Unique_Name__c IN : checklistNames
                                                        WITH SYSTEM_MODE];
            System.debug('checklists count : '+checklists.size());
            for(BSF_Task_Checklist__c checklist : checklists){
                checklistMap.put(checklist.TaskLookup__c+'-'+checklist.Unique_Name__c,checklist);
            }
        }
        return checklistMap;
    }
    public static Object getFieldValue(String fieldName, String fieldvalue){
        Object obj;
        Schema.DisplayType fielddataType = checklistFieldMap.get(fieldName).getDescribe().getType();
        if(fielddataType == Schema.DisplayType.MULTIPICKLIST || fielddataType == Schema.DisplayType.PICKLIST
                || fielddataType == Schema.DisplayType.STRING || fielddataType == Schema.DisplayType.TEXTAREA) {
                    obj = fieldvalue;
        }else if(fielddataType == Schema.DisplayType.CURRENCY || fielddataType == Schema.DisplayType.DOUBLE) {
            obj = String.isNotBlank(fieldvalue) ? Decimal.valueOf(fieldvalue) : null;
        }else if(fielddataType == Schema.DisplayType.INTEGER || fielddataType == Schema.DisplayType.LONG) {
            obj = String.isNotBlank(fieldvalue) ? Integer.valueOf(fieldvalue) : null;
        }else if(fielddataType == Schema.DisplayType.BOOLEAN){
            obj = String.isNotBlank(fieldvalue) ? Boolean.valueOf(fieldvalue) : false;
        }
        return obj;
    }
}