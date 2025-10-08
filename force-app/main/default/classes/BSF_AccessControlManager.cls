/**
 * @description Processes Access Control Rules for Permission Sets using efficient, bulk DML.
 *              This framework manages Object, Field, Apex Class, and Visualforce Page permissions.
 *              It is designed to be run as an automated post-deployment step.
 * @important The user executing this needs the "Manage Profiles and Permission Sets" permission.
 */
public without sharing class BSF_AccessControlManager {

    /**
     * @description Entry point: processes all 'Permission Set' rules for a specific release tag.
     * @param releaseTag The value in the Release_Tag__c field of the rules to process.
     */
    public static void processRulesByReleaseTag(String releaseTag) {
        System.debug(LoggingLevel.INFO, 'Starting AccessControlManager for release tag: ' + releaseTag);

        List<BSF_Access_Control_Rule__mdt> rules = [
            SELECT Rule_Type__c, Target_API_Names__c, SObject_API_Name__c,
                   Field_API_Names__c, PermissionsRead__c, PermissionsCreate__c,
                   PermissionsEdit__c, PermissionsDelete__c, Component_API_Names__c, Is_Enabled__c
            FROM BSF_Access_Control_Rule__mdt
            WHERE Release_Tag__c = :releaseTag AND Target_Type__c = 'Permission Set'
        ];

        if (rules.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'No Permission Set rules found for release tag: ' + releaseTag + '. Execution finished.');
            return;
        }

        Map<String, List<BSF_Access_Control_Rule__mdt>> rulesByType = new Map<String, List<BSF_Access_Control_Rule__mdt>>();
        for (BSF_Access_Control_Rule__mdt rule : rules) {
            String ruleType = String.isBlank(rule.Rule_Type__c) ? '' : rule.Rule_Type__c.trim();
            if (!rulesByType.containsKey(ruleType)) {
                rulesByType.put(ruleType, new List<BSF_Access_Control_Rule__mdt>());
            }
            rulesByType.get(ruleType).add(rule);
        }

        if (rulesByType.containsKey('Object/Field')) {
            processFieldAndObjectPermissions(rulesByType.get('Object/Field'));
        }
        if (rulesByType.containsKey('Apex Class')) {
            processJunctionPermissions(rulesByType.get('Apex Class'), 'ApexClass', 'PermissionSetApexClassAccess', 'ApexClassId');
        }
        if (rulesByType.containsKey('Visualforce Page')) {
            processJunctionPermissions(rulesByType.get('Visualforce Page'), 'ApexPage', 'PermissionSetApexPageAccess', 'ApexPageId');
        }
        System.debug(LoggingLevel.INFO, 'AccessControlManager finished processing for release tag: ' + releaseTag);
    }

    /**
     * @description Processes rules for Object and Field Level Security.
     * @param rules A list of 'Object/Field' type rules to process.
     */
    private static void processFieldAndObjectPermissions(List<BSF_Access_Control_Rule__mdt> rules) {
        System.debug(LoggingLevel.INFO, 'Processing ' + rules.size() + ' Object/Field rules...');

        Set<String> permSetNames = new Set<String>();
        Set<String> objectApiNames = new Set<String>();
        Set<String> fullFieldApiNames = new Set<String>();

        for (BSF_Access_Control_Rule__mdt rule : rules) {
            permSetNames.addAll(cleanSplit(rule.Target_API_Names__c));
            String objName = String.isBlank(rule.SObject_API_Name__c) ? '' : rule.SObject_API_Name__c.trim();
            if (objName != '') {
                objectApiNames.add(objName);
                for (String fieldName : cleanSplit(rule.Field_API_Names__c)) {
                    fullFieldApiNames.add(objName + '.' + fieldName);
                }
            }
        }
        if (permSetNames.isEmpty() || objectApiNames.isEmpty()) return;

        Map<String, Id> permSetNameToIdMap = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames]) permSetNameToIdMap.put(ps.Name, ps.Id);

        Map<String, Map<String, Schema.SObjectField>> objectFieldMaps = new Map<String, Map<String, Schema.SObjectField>>();
        for (String objName : objectApiNames) {
            try { objectFieldMaps.put(objName, Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap()); } 
            catch (Exception e) { System.debug(LoggingLevel.WARN, 'Could not describe SObject "' + objName + '". Rules for this object will be skipped.'); }
        }

        Set<Id> permSetIds = new Set<Id>(permSetNameToIdMap.values());
        Map<String, FieldPermissions> existingFieldPerms = new Map<String, FieldPermissions>();
        if (!fullFieldApiNames.isEmpty()) {
            for (FieldPermissions fp : [SELECT Id, ParentId, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE ParentId IN :permSetIds AND Field IN :fullFieldApiNames]) {
                existingFieldPerms.put(fp.ParentId + '-' + fp.Field, fp);
            }
        }
        Map<String, ObjectPermissions> existingObjectPerms = new Map<String, ObjectPermissions>();
        if (!permSetIds.isEmpty() && !objectApiNames.isEmpty()) {
             for (ObjectPermissions op : [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete FROM ObjectPermissions WHERE ParentId IN :permSetIds AND SobjectType IN :objectApiNames]) {
                existingObjectPerms.put(op.ParentId + '-' + op.SobjectType, op);
            }
        }
       
        List<sObject> recordsToInsert = new List<sObject>();
        List<sObject> recordsToUpdate = new List<sObject>();

        for (BSF_Access_Control_Rule__mdt rule : rules) {
            String sObjectName = String.isBlank(rule.SObject_API_Name__c) ? '' : rule.SObject_API_Name__c.trim();
            if (sObjectName == '') continue;

            List<String> psNames = cleanSplit(rule.Target_API_Names__c);
            List<String> fieldNames = cleanSplit(rule.Field_API_Names__c);

            for (String psName : psNames) {
                Id permSetId = permSetNameToIdMap.get(psName);
                if (permSetId == null) continue;

                if (fieldNames.isEmpty()) {
                    String key = permSetId + '-' + sObjectName;
                    ObjectPermissions op = existingObjectPerms.get(key);
                    if (op == null) {
                        recordsToInsert.add(new ObjectPermissions(ParentId=permSetId, SobjectType=sObjectName, PermissionsRead=rule.PermissionsRead__c, PermissionsCreate=rule.PermissionsCreate__c, PermissionsEdit=rule.PermissionsEdit__c, PermissionsDelete=rule.PermissionsDelete__c));
                    } else if (op.PermissionsRead!=rule.PermissionsRead__c || op.PermissionsCreate!=rule.PermissionsCreate__c || op.PermissionsEdit!=rule.PermissionsEdit__c || op.PermissionsDelete!=rule.PermissionsDelete__c) {
                        op.PermissionsRead=rule.PermissionsRead__c; op.PermissionsCreate=rule.PermissionsCreate__c; op.PermissionsEdit=rule.PermissionsEdit__c; op.PermissionsDelete=rule.PermissionsDelete__c;
                        recordsToUpdate.add(op);
                    }
                } else {
                    Map<String, Schema.SObjectField> fieldMap = objectFieldMaps.get(sObjectName);
                    if (fieldMap == null) continue;
                    for (String fieldName : fieldNames) {
                        Schema.SObjectField token = fieldMap.get(fieldName);
                        if (token == null) { System.debug(LoggingLevel.WARN, 'Field "' + sObjectName + '.' + fieldName + '" not found. Skipping.'); continue; }
                        
                        Boolean effectiveEdit = rule.PermissionsEdit__c && token.getDescribe().isUpdateable();
                        String fullFieldApiName = sObjectName + '.' + fieldName;
                        String key = permSetId + '-' + fullFieldApiName;
                        FieldPermissions fp = existingFieldPerms.get(key);

                        if (fp == null) {
                            recordsToInsert.add(new FieldPermissions(ParentId=permSetId, SobjectType=sObjectName, Field=fullFieldApiName, PermissionsRead=rule.PermissionsRead__c, PermissionsEdit=effectiveEdit));
                        } else if (fp.PermissionsRead != rule.PermissionsRead__c || fp.PermissionsEdit != effectiveEdit) {
                            fp.PermissionsRead=rule.PermissionsRead__c; fp.PermissionsEdit=effectiveEdit;
                            recordsToUpdate.add(fp);
                        }
                    }
                }
            }
        }
        
        Integer insertedCount = recordsToInsert.size();
        Integer updatedCount = recordsToUpdate.size();
        executeDml(recordsToInsert, 'insert');
        executeDml(recordsToUpdate, 'update');
        System.debug(LoggingLevel.INFO, 'Object/Field processing summary - Inserted: ' + insertedCount + ', Updated: ' + updatedCount);
    }

    /**
     * @description Generic helper to process junction permissions like PermissionSetApexClassAccess.
     * @param rules A list of component-type rules to process.
     * @param childEntityType The API name of the component (e.g., 'ApexClass').
     * @param junctionSObjectName The API name of the junction object (e.g., 'PermissionSetApexClassAccess').
     * @param childRelationshipName The relationship field name on the junction object (e.g., 'ApexClassId').
     */
    private static void processJunctionPermissions(List<BSF_Access_Control_Rule__mdt> rules, String childEntityType, String junctionSObjectName, String childRelationshipName) {
        System.debug(LoggingLevel.INFO, 'Processing ' + rules.size() + ' ' + childEntityType + ' access rules...');

        Set<String> permSetNames = new Set<String>();
        Set<String> componentNames = new Set<String>();

        for (BSF_Access_Control_Rule__mdt rule : rules) {
            permSetNames.addAll(cleanSplit(rule.Target_API_Names__c));
            componentNames.addAll(cleanSplit(rule.Component_API_Names__c));
        }
        if (permSetNames.isEmpty() || componentNames.isEmpty()) return;

        Map<String, Id> permSetNameToIdMap = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames]) permSetNameToIdMap.put(ps.Name, ps.Id);

        Map<String, Id> componentNameToIdMap = new Map<String, Id>();
        for (SObject component : Database.query('SELECT Id, Name FROM ' + childEntityType + ' WHERE Name IN :componentNames')) {
            componentNameToIdMap.put((String)component.get('Name'), (Id)component.get('Id'));
        }
        
        Set<String> existingKeys = new Set<String>();
        Set<Id> parentIds = new Set<Id>(permSetNameToIdMap.values());
        Set<Id> childIds = new Set<Id>(componentNameToIdMap.values());
        if (!parentIds.isEmpty() && !childIds.isEmpty()) {
            for (SObject existing : Database.query('SELECT ParentId, ' + childRelationshipName + ' FROM ' + junctionSObjectName + ' WHERE ParentId IN :parentIds AND ' + childRelationshipName + ' IN :childIds')) {
                existingKeys.add(existing.get('ParentId') + '-' + existing.get(childRelationshipName));
            }
        }
        
        List<SObject> recordsToInsert = new List<SObject>();
        SObjectType junctionType = Schema.getGlobalDescribe().get(junctionSObjectName);
        Boolean hasEnabledField = junctionType.getDescribe().fields.getMap().containsKey('Enabled');

        for (BSF_Access_Control_Rule__mdt rule : rules) {
            if (!rule.Is_Enabled__c) continue;
            for (String psName : cleanSplit(rule.Target_API_Names__c)) {
                Id parentId = permSetNameToIdMap.get(psName);
                if (parentId == null) continue;
                for (String compName : cleanSplit(rule.Component_API_Names__c)) {
                    Id childId = componentNameToIdMap.get(compName);
                    if (childId == null) continue;
                    
                    String key = parentId + '-' + childId;
                    if (!existingKeys.contains(key)) {
                        SObject newRecord = junctionType.newSObject();
                        newRecord.put('ParentId', parentId);
                        newRecord.put(childRelationshipName, childId);
                        if (hasEnabledField) newRecord.put('Enabled', true);
                        recordsToInsert.add(newRecord);
                        existingKeys.add(key);
                    }
                }
            }
        }
        
        Integer insertedCount = recordsToInsert.size();
        executeDml(recordsToInsert, 'insert');
        System.debug(LoggingLevel.INFO, childEntityType + ' processing summary - Inserted: ' + insertedCount);
    }

    /**
     * @description Safely splits a comma-separated string into a list of trimmed, non-blank strings.
     * @param input The string to split.
     * @return A list of clean string tokens.
     */
    private static List<String> cleanSplit(String input) {
        List<String> results = new List<String>();
        if (String.isNotBlank(input)) {
            for (String item : input.split(',')) {
                String trimmedItem = item.trim();
                if (String.isNotBlank(trimmedItem)) {
                    results.add(trimmedItem);
                }
            }
        }
        return results;
    }

    /**
     * @description Safe DML execution helper to prevent entire transaction failure.
     * @param records The list of records to perform DML on.
     * @param operation The DML operation as a string ('insert' or 'update').
     */
    private static void executeDml(List<SObject> records, String operation) {
        if (records == null || records.isEmpty()) return;
        try {
            if (operation == 'insert') insert records;
            else if (operation == 'update') update records;
            System.debug(LoggingLevel.INFO, 'SUCCESS: Performed ' + operation + ' on ' + records.size() + ' records for SObject ' + records[0].getSObjectType());
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'DML Error during ' + operation + ' on ' + records[0].getSObjectType() + '. Message: ' + e.getMessage());
        }
    }
}