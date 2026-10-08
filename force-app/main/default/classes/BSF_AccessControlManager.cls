/**
 * @author Elam Pandian
 * @date 10/08/2025
 * @description Processes Access Control Rules for Permission Sets using efficient, bulk DML.
 *              This framework manages Object, Field, Apex Class, and Visualforce Page permissions.
 *              It creates a comprehensive summary log and detailed CSV attachment for complete auditability.
 * @important The user executing this needs the "Manage Profiles and Permission Sets" permission.
 */
public without sharing class BSF_AccessControlManager {

    /**
     * @description DTO to capture specific, row-level details of what was changed or skipped.
     */
    private class ChangeDetail {
        String operation;
        String componentType;
        String targetName;
        String permSetName;
        String accessLevel;

        public ChangeDetail(String operation, String componentType, String targetName, String permSetName, String accessLevel) {
            this.operation = operation;
            this.componentType = componentType;
            this.targetName = targetName;
            this.permSetName = permSetName;
            this.accessLevel = accessLevel;
        }
    }

    /**
     * @description DTO to accumulate statistics and warnings from a single execution run.
     */
    private class RunSummary {
        Integer objInserted = 0, objUpdated = 0, fldInserted = 0, fldUpdated = 0;
        Integer apexInserted = 0, pageInserted = 0;
        Integer missingPS = 0, missingComp = 0, missingFields = 0, undescribableObjects = 0;
        Integer dmlFailures = 0;
        List<String> missingFieldList = new List<String>();
        List<String> undescribedObjectList = new List<String>();
        List<String> dmlErrors = new List<String>();
        Datetime startedAt, endedAt;
        List<ChangeDetail> detailedLogs = new List<ChangeDetail>();
    }
    
    /**
     * @description Queueable class that handles inserting the final summary log asynchronously.
     */
    public class AccessControlLogQueueable implements Queueable {
        private final String releaseTag;
        private final RunSummary summary;

        public AccessControlLogQueueable(String releaseTag, RunSummary summary) {
            this.releaseTag = releaseTag;
            this.summary = summary;
        }

        public void execute(QueueableContext context) {
            try {
                String shortMsg = 'ACM run summary';
                String longMsg = 'Release Tag: ' + releaseTag +
                        ' | Started: ' + String.valueOf(summary.startedAt) + ' | Ended: ' + String.valueOf(summary.endedAt) +
                        ' | ObjInserted: ' + summary.objInserted + ' | ObjUpdated: ' + summary.objUpdated +
                        ' | FldInserted: ' + summary.fldInserted + ' | FldUpdated: ' + summary.fldUpdated +
                        ' | ApexInserted: ' + summary.apexInserted + ' | PageInserted: ' + summary.pageInserted +
                        ' | MissingPS: ' + summary.missingPS + ' | MissingComp: ' + summary.missingComp +
                        ' | MissingFields: ' + summary.missingFields + ' | UndescribableObjects: ' + summary.undescribableObjects +
                        ' | DmlFailures: ' + summary.dmlFailures;

                if (!summary.missingFieldList.isEmpty()) {
                    List<String> missingFieldsSubList = new List<String>();
                    Integer maxMissingFields = Math.min(10, summary.missingFieldList.size());
                    for(Integer i = 0; i < maxMissingFields; i++) {
                        missingFieldsSubList.add(summary.missingFieldList[i]);
                    }
                    longMsg += ' | MissingFieldSamples: ' + String.join(missingFieldsSubList, ',');
                }
                if (!summary.undescribedObjectList.isEmpty()) {
                    List<String> undescribedObjectsSubList = new List<String>();
                    Integer maxUndescribedObjects = Math.min(10, summary.undescribedObjectList.size());
                    for(Integer i = 0; i < maxUndescribedObjects; i++) {
                        undescribedObjectsSubList.add(summary.undescribedObjectList[i]);
                    }
                    longMsg += ' | UndescribedObjectSamples: ' + String.join(undescribedObjectsSubList, ',');
                }
                if (!summary.dmlErrors.isEmpty()) {
                    List<String> dmlErrorsSubList = new List<String>();
                    Integer maxDmlErrors = Math.min(5, summary.dmlErrors.size());
                    for(Integer i = 0; i < maxDmlErrors; i++) {
                        dmlErrorsSubList.add(summary.dmlErrors[i]);
                    }
                    longMsg += ' | DmlErrorSamples: ' + String.join(dmlErrorsSubList, ' || ');
                }

                String typeVal = (summary.dmlFailures > 0) ? 'Error' :
                                ((summary.missingPS > 0 || summary.missingComp > 0 || summary.missingFields > 0 || summary.undescribableObjects > 0) ? 'Debug Log' : 'Success');
                
                BSF_Error_Log__c row = new BSF_Error_Log__c();
                row.Process_Name__c = 'Access Control Manager';
                row.ApexClass__c = 'BSF_AccessControlManager';
                row.Method__c = 'processRulesByReleaseTag';
                row.Functionality__c = 'Run Summary';
                row.Type__c = typeVal;
                row.Error_Description__c = shortMsg.left(255);
                row.Error_Description_Long__c = longMsg.left(131072);                
                
                Database.SaveResult result = Database.insert(row, false);

                if (result.isSuccess() && !summary.detailedLogs.isEmpty()) {
                    String csvContent = 'Operation,Component Type,Target API Name,Permission Set,Access Granted / Details\n';
                    
                    for (ChangeDetail log : summary.detailedLogs) {
                        csvContent += '"' + log.operation + '","' 
                                    + log.componentType + '","' 
                                    + log.targetName + '","' 
                                    + log.permSetName + '","' 
                                    + log.accessLevel + '"\n';
                    }
                    
                    ContentVersion cv = new ContentVersion();
                    cv.Title = 'Detailed_Access_Log_' + releaseTag + '.csv';
                    cv.PathOnClient = 'Detailed_Access_Log_' + releaseTag + '.csv';
                    cv.VersionData = Blob.valueOf(csvContent);
                    insert cv;
                    
                    Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = conDocId;
                    cdl.LinkedEntityId = row.Id;
                    cdl.ShareType = 'V';
                    insert cdl;
                }
                
                if (!result.isSuccess()) {
                    System.debug(LoggingLevel.WARN, 'BSF_Error_Log__c single-row insert failed: ' + result.getErrors()[0].getMessage());
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'BSF_Error_Log__c single-row insert failed: ' + e.getMessage());
            }
        }
    }

    public static void processRulesByReleaseTag(String releaseTag) {
        System.debug(LoggingLevel.INFO, 'Starting AccessControlManager for release tag: ' + releaseTag);
        RunSummary summary = new RunSummary();
        summary.startedAt = System.now();

        List<BSF_Access_Control_Rule__mdt> rules = [
            SELECT Rule_Type__c, Target_API_Names__c, SObject_API_Name__c,
                   Field_API_Names__c, PermissionsRead__c, PermissionsCreate__c,
                   PermissionsEdit__c, PermissionsDelete__c, Component_API_Names__c, Is_Enabled__c
            FROM BSF_Access_Control_Rule__mdt
            WHERE Release_Tag__c = :releaseTag AND Target_Type__c = 'Permission Set'
        ];

        if (rules.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'No Permission Set rules found. Execution finished.');
            summary.endedAt = System.now();
            System.enqueueJob(new AccessControlLogQueueable(releaseTag, summary));
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
            processFieldAndObjectPermissions(rulesByType.get('Object/Field'), summary);
        }
        if (rulesByType.containsKey('Apex Class')) {
            processJunctionPermissionsWithSetupEntityAccess(rulesByType.get('Apex Class'), 'ApexClass', summary);
        }
        if (rulesByType.containsKey('Visualforce Page')) {
            processJunctionPermissionsWithSetupEntityAccess(rulesByType.get('Visualforce Page'), 'ApexPage', summary);
        }

        System.debug(LoggingLevel.INFO, 'AccessControlManager finished processing for release tag: ' + releaseTag);
        summary.endedAt = System.now();
        System.enqueueJob(new AccessControlLogQueueable(releaseTag, summary));
    }

    private static void processFieldAndObjectPermissions(List<BSF_Access_Control_Rule__mdt> rules, RunSummary summary) {
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
        if (permSetNames.isEmpty() || objectApiNames.isEmpty()) {
            return;
        }

        Map<String, Id> permSetNameToIdMap = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames AND IsOwnedByProfile = false]) {
            permSetNameToIdMap.put(ps.Name, ps.Id);
        }

        Map<String, Map<String, Schema.SObjectField>> objectFieldMaps = new Map<String, Map<String, Schema.SObjectField>>();
        for (String objName : objectApiNames) {
            try {
                objectFieldMaps.put(objName, Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap());
            } catch (Exception e) { 
                System.debug(LoggingLevel.WARN, 'Could not describe SObject "' + objName + '".');
                summary.undescribableObjects++;
                if (summary.undescribedObjectList.size() < 20) {
                    summary.undescribedObjectList.add(objName);
                }
                summary.detailedLogs.add(new ChangeDetail('Skipped', 'Object', objName, 'All Targets', 'Could not describe SObject'));
            }
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
             for (ObjectPermissions op : [
                 SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete,
                        PermissionsViewAllRecords, PermissionsModifyAllRecords 
                 FROM ObjectPermissions 
                 WHERE ParentId IN :permSetIds AND SobjectType IN :objectApiNames]) {
                existingObjectPerms.put(op.ParentId + '-' + op.SobjectType, op);
            }
        }
       
        Map<Id, ObjectPermissions> objPermsToUpdateMap = new Map<Id, ObjectPermissions>();
        Map<Id, FieldPermissions> fldPermsToUpdateMap = new Map<Id, FieldPermissions>();
        List<ObjectPermissions> objPermsToInsert = new List<ObjectPermissions>();
        List<FieldPermissions> fldPermsToInsert = new List<FieldPermissions>();

        Set<String> queuedObjPermKeys = new Set<String>();
        Set<String> queuedFieldPermKeys = new Set<String>();

        for (BSF_Access_Control_Rule__mdt rule : rules) {
            String sObjectName = String.isBlank(rule.SObject_API_Name__c) ? '' : rule.SObject_API_Name__c.trim();
            if (sObjectName == '') continue;

            List<String> psNames = cleanSplit(rule.Target_API_Names__c);
            List<String> rawFieldNames = cleanSplit(rule.Field_API_Names__c);

            if (rawFieldNames.isEmpty()) {
                // --- OBJECT LEVEL PERMISSIONS ---
                for (String psName : psNames) {
                    Id permSetId = permSetNameToIdMap.get(psName);
                    if (permSetId == null) {
                        summary.missingPS++;
                        summary.detailedLogs.add(new ChangeDetail('Skipped', 'Object Permission', sObjectName, psName, 'Permission Set not found or is owned by Profile'));
                        continue;
                    }

                    String key = permSetId + '-' + sObjectName;
                    ObjectPermissions op = existingObjectPerms.get(key);
                    
                    Boolean targetRead = rule.PermissionsRead__c != null ? rule.PermissionsRead__c : false;
                    Boolean targetCreate = rule.PermissionsCreate__c != null ? rule.PermissionsCreate__c : false;
                    Boolean targetEdit = rule.PermissionsEdit__c != null ? rule.PermissionsEdit__c : false;
                    Boolean targetDelete = rule.PermissionsDelete__c != null ? rule.PermissionsDelete__c : false;

                    if (op == null) {
                        if (!queuedObjPermKeys.contains(key)) {
                            objPermsToInsert.add(new ObjectPermissions(
                                ParentId = permSetId, 
                                SobjectType = sObjectName, 
                                PermissionsRead = targetRead, 
                                PermissionsCreate = targetCreate, 
                                PermissionsEdit = targetEdit, 
                                PermissionsDelete = targetDelete
                            ));
                            queuedObjPermKeys.add(key);
                            summary.objInserted++;                        
                            summary.detailedLogs.add(new ChangeDetail('Insert', 'Object', sObjectName, psName, 'R:'+targetRead+' C:'+targetCreate+' E:'+targetEdit+' D:'+targetDelete));
                        }
                    } else {
                        Boolean targetModifyAll = op.PermissionsModifyAllRecords;
                        Boolean targetViewAll = op.PermissionsViewAllRecords;

                        if (!targetRead || !targetCreate || !targetEdit || !targetDelete) {
                            targetModifyAll = false;
                        }
                        if (!targetRead) {
                            targetViewAll = false;
                        }

                        if (op.PermissionsRead != targetRead || 
                            op.PermissionsCreate != targetCreate || 
                            op.PermissionsEdit != targetEdit || 
                            op.PermissionsDelete != targetDelete ||
                            op.PermissionsModifyAllRecords != targetModifyAll ||
                            op.PermissionsViewAllRecords != targetViewAll) {

                            op.PermissionsRead = targetRead; 
                            op.PermissionsCreate = targetCreate; 
                            op.PermissionsEdit = targetEdit; 
                            op.PermissionsDelete = targetDelete;
                            op.PermissionsModifyAllRecords = targetModifyAll;
                            op.PermissionsViewAllRecords = targetViewAll;

                            if (!objPermsToUpdateMap.containsKey(op.Id)) {
                                summary.objUpdated++;
                                summary.detailedLogs.add(new ChangeDetail('Update', 'Object', sObjectName, psName, 'R:'+targetRead+' C:'+targetCreate+' E:'+targetEdit+' D:'+targetDelete));
                            }
                            objPermsToUpdateMap.put(op.Id, op);
                        }
                    }
                }
            } else {
                // --- FIELD LEVEL PERMISSIONS ---
                Map<String, Schema.SObjectField> fieldMap = objectFieldMaps.get(sObjectName);
                if (fieldMap == null) continue;

                Map<String, Schema.DescribeFieldResult> validFieldsMap = new Map<String, Schema.DescribeFieldResult>();
                for (String fieldName : rawFieldNames) {
                    Schema.SObjectField token = fieldMap.get(fieldName);
                    if (token == null) {
                        summary.missingFields++;
                        if (summary.missingFieldList.size() < 25) {
                            summary.missingFieldList.add(sObjectName + '.' + fieldName);
                        }
                        summary.detailedLogs.add(new ChangeDetail('Skipped', 'Field (Missing)', sObjectName + '.' + fieldName, 'All Targets', 'Field API Name not found on SObject'));
                        continue;
                    }
                    Schema.DescribeFieldResult fieldDescribe = token.getDescribe();

                    if (!fieldDescribe.isPermissionable()) {
                        summary.detailedLogs.add(new ChangeDetail('Skipped', 'Field (Non-Permissionable)', sObjectName + '.' + fieldName, 'All Targets', 'Field is non-permissionable (Master-Detail, Formula, or System)'));
                        continue;
                    }
                    validFieldsMap.put(fieldName, fieldDescribe);
                }

                if (validFieldsMap.isEmpty()) continue;

                for (String psName : psNames) {
                    Id permSetId = permSetNameToIdMap.get(psName);
                    if (permSetId == null) {
                        summary.missingPS++;
                        summary.detailedLogs.add(new ChangeDetail('Skipped', 'Field Permission', sObjectName, psName, 'Permission Set not found or is owned by Profile'));
                        continue;
                    }

                    for (String fieldName : validFieldsMap.keySet()) {
                        Schema.DescribeFieldResult fieldDescribe = validFieldsMap.get(fieldName);
                        Boolean effectiveEdit = rule.PermissionsEdit__c && fieldDescribe.isUpdateable();
                        String fullFieldApiName = sObjectName + '.' + fieldName;
                        String key = permSetId + '-' + fullFieldApiName;

                        FieldPermissions fp = existingFieldPerms.get(key);
                        if (fp == null) {
                            if (!queuedFieldPermKeys.contains(key)) {
                                fldPermsToInsert.add(new FieldPermissions(
                                    ParentId = permSetId, 
                                    SobjectType = sObjectName, 
                                    Field = fullFieldApiName, 
                                    PermissionsRead = rule.PermissionsRead__c, 
                                    PermissionsEdit = effectiveEdit
                                ));
                                queuedFieldPermKeys.add(key);
                                summary.fldInserted++;
                                summary.detailedLogs.add(new ChangeDetail('Insert', 'Field', fullFieldApiName, psName, 'Read:'+rule.PermissionsRead__c+' Edit:'+effectiveEdit));
                            }
                        } else if (fp.PermissionsRead != rule.PermissionsRead__c || fp.PermissionsEdit != effectiveEdit) {
                            fp.PermissionsRead = rule.PermissionsRead__c; 
                            fp.PermissionsEdit = effectiveEdit;

                            if (!fldPermsToUpdateMap.containsKey(fp.Id)) {
                                summary.fldUpdated++;
                                summary.detailedLogs.add(new ChangeDetail('Update', 'Field', fullFieldApiName, psName, 'Read:'+rule.PermissionsRead__c+' Edit:'+effectiveEdit));
                            }
                            fldPermsToUpdateMap.put(fp.Id, fp);
                        }
                    }
                }
            }
        }
        
        executeDml(objPermsToInsert, 'insert', summary);
        executeDml(fldPermsToInsert, 'insert', summary);
        executeDml(objPermsToUpdateMap.values(), 'update', summary);
        executeDml(fldPermsToUpdateMap.values(), 'update', summary);
    }

    private static void processJunctionPermissionsWithSetupEntityAccess(List<BSF_Access_Control_Rule__mdt> rules, String childEntityType, RunSummary summary) {
        System.debug(LoggingLevel.INFO, 'Processing ' + rules.size() + ' ' + childEntityType + ' access rules via SetupEntityAccess...');

        Set<String> permSetNames = new Set<String>();
        Set<String> componentNames = new Set<String>();
        for (BSF_Access_Control_Rule__mdt rule : rules) {
            permSetNames.addAll(cleanSplit(rule.Target_API_Names__c));
            componentNames.addAll(cleanSplit(rule.Component_API_Names__c));
        }
        if (permSetNames.isEmpty() || componentNames.isEmpty()) {
            return;
        }

        Map<String, Id> permSetNameToId = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames AND IsOwnedByProfile = false]) {
            permSetNameToId.put(ps.Name, ps.Id);
        }

        Map<String, Id> compNameToId = new Map<String, Id>();
        Set<String> allowedEntityTypes = new Set<String>{'ApexClass', 'ApexPage'};
        if (allowedEntityTypes.contains(childEntityType)) {
            String query = 'SELECT Id, Name FROM ' + childEntityType + ' WHERE Name IN :componentNames';
            for (SObject comp : Database.query(query)) {
                compNameToId.put((String)comp.get('Name'), (Id)comp.get('Id'));
            }
        }

        Set<Id> psIds = new Set<Id>(permSetNameToId.values());
        Set<Id> compIds = new Set<Id>(compNameToId.values());
        Set<String> existing = new Set<String>();
        if (!psIds.isEmpty() && !compIds.isEmpty()) {
            for (SetupEntityAccess sea : [SELECT ParentId, SetupEntityId FROM SetupEntityAccess WHERE ParentId IN :psIds AND SetupEntityId IN :compIds]) {
                existing.add(sea.ParentId + '-' + sea.SetupEntityId);
            }
        }

        List<SetupEntityAccess> inserts = new List<SetupEntityAccess>();
        for (BSF_Access_Control_Rule__mdt rule : rules) {
            if (!rule.Is_Enabled__c) {
                continue;
            }
            for (String psName : cleanSplit(rule.Target_API_Names__c)) {
                Id parentId = permSetNameToId.get(psName);
                if (parentId == null) {
                    summary.missingPS++;
                    summary.detailedLogs.add(new ChangeDetail('Skipped', childEntityType, 'N/A', psName, 'Permission Set not found or is owned by Profile'));
                    continue;
                }
                for (String compName : cleanSplit(rule.Component_API_Names__c)) {
                    Id setupEntityId = compNameToId.get(compName);
                    if (setupEntityId == null) {
                        summary.missingComp++;
                        summary.detailedLogs.add(new ChangeDetail('Skipped', childEntityType, compName, psName, childEntityType + ' not found in org'));
                        continue;
                    }
                    String key = parentId + '-' + setupEntityId;
                    if (!existing.contains(key)) {
                        inserts.add(new SetupEntityAccess(ParentId = parentId, SetupEntityId = setupEntityId));
                        existing.add(key);
                        if (childEntityType == 'ApexClass') {
                            summary.apexInserted++;
                        }
                        if (childEntityType == 'ApexPage') {
                            summary.pageInserted++;
                        }
                        summary.detailedLogs.add(new ChangeDetail('Insert', childEntityType, compName, psName, 'Enabled'));
                    }
                }
            }
        }
        executeDml(inserts, 'insert', summary);
    }

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

    private static void executeDml(List<SObject> records, String operation, RunSummary summary) {
        if (records == null || records.isEmpty()) {
            return;
        }

        List<Database.SaveResult> saveResults;
        if (operation == 'insert') {
            saveResults = Database.insert(records, false);
        } else if (operation == 'update') {
            saveResults = Database.update(records, false);
        }

        Integer failureCount = 0;
        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult sr = saveResults[i];
            if (!sr.isSuccess()) {
                failureCount++;
                SObject failedRecord = records[i];
                String recordDetail = '';
                String targetPermSet = 'N/A';

                if (failedRecord instanceof FieldPermissions) {
                    FieldPermissions fp = (FieldPermissions) failedRecord;
                    recordDetail = fp.Field;
                    targetPermSet = String.valueOf(fp.ParentId);
                } else if (failedRecord instanceof ObjectPermissions) {
                    ObjectPermissions op = (ObjectPermissions) failedRecord;
                    recordDetail = op.SobjectType;
                    targetPermSet = String.valueOf(op.ParentId);
                } else if (failedRecord instanceof SetupEntityAccess) {
                    SetupEntityAccess sea = (SetupEntityAccess) failedRecord;
                    recordDetail = String.valueOf(sea.SetupEntityId);
                    targetPermSet = String.valueOf(sea.ParentId);
                }

                for (Database.Error err : sr.getErrors()) {
                    String errMsg = operation.toUpperCase() + ' Error -> ' + err.getMessage();
                    System.debug(LoggingLevel.ERROR, errMsg);
                    summary.dmlFailures++;
                    if (summary.dmlErrors.size() < 10) {
                        summary.dmlErrors.add(errMsg);
                    }
                    // LOG DML ERROR TO CSV ATTACHMENT AS WELL
                    summary.detailedLogs.add(new ChangeDetail('Error (' + operation.toUpperCase() + ')', failedRecord.getSObjectType().getDescribe().getName(), recordDetail, targetPermSet, err.getMessage()));
                }
            }
        }

        if (failureCount == 0) {
            System.debug(LoggingLevel.INFO, 'SUCCESS: Performed ' + operation + ' on ' + records.size() + ' records for ' + records[0].getSObjectType());
        }
    }
}