public with sharing class RecruitmentPlanningController {
	@AuraEnabled
    public static boolean checkTaskSubject(String taskId){
        List<Task> verifyTask = [select id,Subject from Task where Subject IN ('Recruitment Task - System Generated') And ID = :taskId limit 1];
        if(verifyTask != NULL && verifyTask.size() > 0){
            system.debug('line 6'+verifyTask);
            system.debug('line 7'+verifyTask.size());
            return True;
        }
        return False;
    }
    
    @AuraEnabled
    public static String fetchMetadata(){
        String UIText = '';
        List<Recruitment_Planning_Checklist_Setting__mdt> getMetadata = [Select Id, Category__c, IsCheckbox__c, UI_Text__c, Label From Recruitment_Planning_Checklist_Setting__mdt];
        UIText += getMetadata[0].UI_Text__c;
        
        return UIText;
    }
    @AuraEnabled
    public static Map<String, Map<String, String>> getRecruitmentChecklist(String taskId){
        Map<String, Map<String, String>> recruitmentFieldMap = new Map<String, Map<String, String>>();
        Map<String, Recruitment_Planning_Checklist_Setting__mdt> recruitmentChecklistMdtMap = new Map<String, Recruitment_Planning_Checklist_Setting__mdt>();
        List<String> recruitmentChecklistFields = new List<String>();
        
        List<Recruitment_Planning_Checklist_Setting__mdt> recruitmentMdt = [SELECT Id, MasterLabel, Category__c, UI_Text__c, IsCheckbox__c, URL_Link__c, Help_Text__c FROM Recruitment_Planning_Checklist_Setting__mdt];
        for(Recruitment_Planning_Checklist_Setting__mdt mdt : recruitmentMdt ){
            recruitmentChecklistMdtMap.put(mdt.MasterLabel, mdt);      
            if (mdt.IsCheckbox__c) {
                recruitmentChecklistFields.add(mdt.MasterLabel);
            }  
        }
        
         List<Recruitment_Planning_Meeting_Checklist__c> recruitmentPlanningList = [SELECT Id, Unique_Name__c, Details__c, Checkbox__c, AA_Projection__c, Latino_Projection__c FROM Recruitment_Planning_Meeting_Checklist__c WHERE TaskID__c  =:taskId];
        if (recruitmentChecklistFields.size()>recruitmentPlanningList.size()) {
            for (Recruitment_Planning_Meeting_Checklist__c field : recruitmentPlanningList) {
                if (recruitmentChecklistFields.contains(field.Unique_Name__c)) {
                    recruitmentChecklistFields.remove(recruitmentChecklistFields.indexOf(field.Unique_Name__c));
                }
            }
        } else {
            recruitmentChecklistFields.clear();
        }

        List<Recruitment_Planning_Meeting_Checklist__c> recruitmentPlanningRecordsToInsert = new List<Recruitment_Planning_Meeting_Checklist__c>();
        if (!recruitmentChecklistFields.isEmpty()) {
            for (String field : recruitmentChecklistFields) {
                recruitmentPlanningRecordsToInsert.add( new Recruitment_Planning_Meeting_Checklist__c(Unique_Name__c=field, Checkbox__c=false, Details__c ='', TaskID__c=taskId));
            }
        }
        if (!recruitmentPlanningRecordsToInsert.isEmpty()) {
            try {
                Database.SaveResult[] sr = Database.insert(recruitmentPlanningRecordsToInsert, true);
                System.debug('sr: '+sr);
            } catch (DMLException e) {
                System.debug('Unable to Perform the DML Operation on SSC : ' +e.getMessage());
                throw new AuraHandledException('Unable to Perform the DML Operation on SSC : ' +e.getMessage());
            }
            recruitmentPlanningList = [SELECT Id, Unique_Name__c, Details__c, Checkbox__c, AA_Projection__c, Latino_Projection__c FROM Recruitment_Planning_Meeting_Checklist__c WHERE TaskID__c  =:taskId];
        }

        Map<String, Recruitment_Planning_Meeting_Checklist__c> recruitmentPlanningRecMap = new Map<String, Recruitment_Planning_Meeting_Checklist__c>();
        for (Recruitment_Planning_Meeting_Checklist__c record : recruitmentPlanningList) {
            recruitmentPlanningRecMap.put(record.Unique_Name__c, record);
        }
        
        try {
            for(String mdt : recruitmentChecklistMdtMap.keyset() ){
                Map<String, String> fieldDescMap = new Map<String, String>();
                if (recruitmentPlanningRecMap.containsKey(mdt)) {
                    fieldDescMap.put('Id', recruitmentPlanningRecMap.get(mdt).Id);
                    fieldDescMap.put('label', recruitmentChecklistMdtMap.get(mdt).UI_Text__c);
                    fieldDescMap.put('category', recruitmentChecklistMdtMap.get(mdt).Category__c);
                    fieldDescMap.put('url', recruitmentChecklistMdtMap.get(mdt).URL_Link__c);
                    fieldDescMap.put('tooltip', recruitmentChecklistMdtMap.get(mdt).Help_Text__c);
                    fieldDescMap.put('value', String.valueOf(recruitmentPlanningRecMap.get(mdt).Checkbox__c));
                    fieldDescMap.put('details', recruitmentPlanningRecMap.get(mdt).Details__c);
                    fieldDescMap.put('AA', String.valueOf(recruitmentPlanningRecMap.get(mdt).AA_Projection__c));
                    fieldDescMap.put('latino', String.valueOf(recruitmentPlanningRecMap.get(mdt).Latino_Projection__c));
                } else {
                    fieldDescMap.put('label', recruitmentChecklistMdtMap.get(mdt).UI_Text__c);
                    fieldDescMap.put('category', recruitmentChecklistMdtMap.get(mdt).Category__c);
                }           
                recruitmentFieldMap.put(mdt, fieldDescMap);
                system.debug('line 81'+fieldDescMap.get('details')+'..'+fieldDescMap.get('category'));
             }
            
        } catch (Exception e) {
            System.debug('Error in controller: '+e);
            throw new AuraHandledException('Error in controller: '+e.getMessage());
        }
        return recruitmentFieldMap;
    }
}