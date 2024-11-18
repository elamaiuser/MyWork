public with sharing class SiteSuitabilityController {
    @AuraEnabled
    public static Map<String, Map<String, String>> getSiteSuitabilitychecklist(String siteId){
        Map<String, Map<String, String>> siteSuitabilityFieldMap = new Map<String, Map<String, String>>();
        Map<String, Site_Suitability_Checklist_Setting__mdt> siteSuitabilityMdtMap = new Map<String, Site_Suitability_Checklist_Setting__mdt>();
        List<String> siteSuitabilityChecklistFields = new List<String>();

        // List<Site_Suitability_Checklist_Setting__mdt> siteSuitabilityMdt = Site_Suitability_Checklist_Setting__mdt.getAll().values();
        List<Site_Suitability_Checklist_Setting__mdt> siteSuitabilityMdt = [SELECT Id, MasterLabel, Category__c, UI_Text__c, IsCheckbox__c, Additional_Text__c FROM Site_Suitability_Checklist_Setting__mdt];
        for(Site_Suitability_Checklist_Setting__mdt mdt : siteSuitabilityMdt ){
            siteSuitabilityMdtMap.put(mdt.MasterLabel, mdt);      
            if (mdt.IsCheckbox__c) {
                siteSuitabilityChecklistFields.add(mdt.MasterLabel);
            }  
        }

        List<Site_Suitability_Checklist__c> siteSuitabilityList = [SELECT Id, UniqueName__c, Value__c FROM Site_Suitability_Checklist__c WHERE Site__c  =:siteId];
        if (siteSuitabilityChecklistFields.size()>siteSuitabilityList.size()) {
            for (Site_Suitability_Checklist__c field : siteSuitabilityList) {
                if (siteSuitabilityChecklistFields.contains(field.UniqueName__c)) {
                    siteSuitabilityChecklistFields.remove(siteSuitabilityChecklistFields.indexOf(field.UniqueName__c));
                }
            }
        } else {
            siteSuitabilityChecklistFields.clear();
        }

        List<Site_Suitability_Checklist__c> siteSuitabilityRecordsToInsert = new List<Site_Suitability_Checklist__c>();
        if (!siteSuitabilityChecklistFields.isEmpty()) {
            for (String field : siteSuitabilityChecklistFields) {
                siteSuitabilityRecordsToInsert.add( new Site_Suitability_Checklist__c(UniqueName__c=field, Value__c=false, Site__c=siteId));
            }
        }
        if (!siteSuitabilityRecordsToInsert.isEmpty()) {
            try {
                Database.SaveResult[] sr = Database.insert(siteSuitabilityRecordsToInsert, true);
                System.debug('sr: '+sr);
            } catch (DMLException e) {
                System.debug('Unable to Perform the DML Operation on SSC : ' +e.getMessage());
                throw new AuraHandledException('Unable to Perform the DML Operation on SSC : ' +e.getMessage());
            }
            siteSuitabilityList = [SELECT Id, UniqueName__c, Value__c FROM Site_Suitability_Checklist__c WHERE Site__c  =:siteId];
        }

        Map<String, Site_Suitability_Checklist__c> siteSuitabilityRecMap = new Map<String, Site_Suitability_Checklist__c>();
        for (Site_Suitability_Checklist__c record : siteSuitabilityList) {
            siteSuitabilityRecMap.put(record.UniqueName__c, record);
        }
        
        try {
            for(String mdt : siteSuitabilityMdtMap.keyset() ){
                Map<String, String> fieldDescMap = new Map<String, String>();
                if (siteSuitabilityRecMap.containsKey(mdt)) {
                    fieldDescMap.put('Id', siteSuitabilityRecMap.get(mdt).Id);
                    fieldDescMap.put('label', siteSuitabilityMdtMap.get(mdt).UI_Text__c);
                    fieldDescMap.put('category', siteSuitabilityMdtMap.get(mdt).Category__c);
                    fieldDescMap.put('value', String.valueOf(siteSuitabilityRecMap.get(mdt).Value__c));
                    fieldDescMap.put('additional_text', siteSuitabilityMdtMap.get(mdt).Additional_Text__c);
                } else {
                    fieldDescMap.put('label', siteSuitabilityMdtMap.get(mdt).UI_Text__c);
                    fieldDescMap.put('category', siteSuitabilityMdtMap.get(mdt).Category__c);
                }           
                siteSuitabilityFieldMap.put(mdt, fieldDescMap);
             }
             System.debug('siteSuitabilityFieldMap==> '+siteSuitabilityFieldMap);
        } catch (Exception e) {
            System.debug('Error in controller: '+e);
            throw new AuraHandledException('Error in controller: '+e.getMessage());
        }
        return siteSuitabilityFieldMap;
    }

    @AuraEnabled
    public static Boolean checkEditAccess() {
        Boolean hasEditAccess = false;
        Id profileId= userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        Site_Suitability_Checklist_Setting__mdt siteSuitabilityMdt = [SELECT Id, MasterLabel, Category__c, UI_Text__c FROM Site_Suitability_Checklist_Setting__mdt WHERE MasterLabel='AllowedProfileList' LIMIT 1];
        if(siteSuitabilityMdt.UI_Text__c!=null)
            hasEditAccess = siteSuitabilityMdt.UI_Text__c.split(';').contains(profileName);
        return hasEditAccess;
    }
}