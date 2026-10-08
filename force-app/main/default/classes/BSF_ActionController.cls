public without sharing class BSF_ActionController {
    
    @TestVisible 
    private static List<Action_Override_Config__mdt> mockMetadata = new List<Action_Override_Config__mdt>();

    public class ActionConfig {
        @AuraEnabled public Boolean hasAccess;
        @AuraEnabled public Boolean notFound;
        @AuraEnabled public Boolean isFlow;
        @AuraEnabled public Boolean isModalView;
        @AuraEnabled public String targetName;
        @AuraEnabled public String customTargetLabel;
    }

    @AuraEnabled(cacheable=true)
    public static ActionConfig getTargetConfig(String objectName, String actionType) {
        ActionConfig config = new ActionConfig();
        config.hasAccess = false;
        config.notFound = true;
        config.isFlow = false;

        if (String.isBlank(objectName) || String.isBlank(actionType)) {
            return config;
        }

        List<Action_Override_Config__mdt> configs;
        if (Test.isRunningTest() && !mockMetadata.isEmpty()) {
            configs = mockMetadata;
        } else {
            configs = [SELECT Target_Type__c, 
                                Target_Name__c, 
                       		    Is_Modal_View__c,
                                Custom_Target_Label__c,
                                Allowed_Permission_Sets__c 
                        FROM Action_Override_Config__mdt 
                        WHERE Object_API_Name__c = :objectName 
                        AND Action_Type__c = :actionType 
                        AND Is_Active__c = true
                        LIMIT 1];
        }

        if (!configs.isEmpty()) {
            config.notFound = false;
            Action_Override_Config__mdt mdt = configs[0];

            String permsString = String.isNotBlank(mdt.Allowed_Permission_Sets__c) ? mdt.Allowed_Permission_Sets__c : '';
            Set<String> allowedPermSets = new Set<String>();
            
            for (String p : permsString.split(',')) {
                if (String.isNotBlank(p)) {
                    allowedPermSets.add(p.trim());
                }
            }

            if (allowedPermSets.contains('All')) {
                config.hasAccess = true;
            } 
            else if (!allowedPermSets.isEmpty()) {
                List<PermissionSetAssignment> psaList = [SELECT Id 
                                                        FROM PermissionSetAssignment 
                                                        WHERE AssigneeId = :UserInfo.getUserId() 
                                                        AND PermissionSet.Name IN :allowedPermSets
                                                        LIMIT 1];
                
                if (!psaList.isEmpty()) {
                    config.hasAccess = true;
                }
            }

            if (config.hasAccess) {
                config.isFlow = (mdt.Target_Type__c == 'Flow');
                config.targetName = mdt.Target_Name__c;
                config.isModalView = mdt.Is_Modal_View__c;
                config.customTargetLabel = mdt.Custom_Target_Label__c;
            }
        }
        
        return config;
    }
}