/**
 * @author Elam Pandian
 * @date 10/08/2025
 * @description Processes Access Control Rules for Permission Sets using efficient, bulk DML.
 *              This framework manages Object, Field, Apex Class, and Visualforce Page permissions.
 *              It includes a robust logging mechanism that creates a single, comprehensive summary
 *              log for each run in a custom bsf_errorlog__c object for complete auditability.
 * @important The user executing this needs the "Manage Profiles and Permission Sets" permission.
 */
public without sharing class BSF_AccessControlManager {

    /**
     * @description DTO to capture specific, row-level details of what was changed.
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
     * @description A private inner class used as a data transfer object (DTO) to accumulate
     *              all statistics and warnings from a single execution run.
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
     * @description A Queueable inner class that handles inserting the final summary log.
     *              This runs in a separate, asynchronous transaction to prevent Mixed DML errors
     *              that occur when mixing setup and non-setup object DML.
     */
    public class AccessControlLogQueueable implements Queueable {
        private final String releaseTag;
        private final RunSummary summary;

        /**
         * @description Constructor to pass the necessary logging data to the async job.
         * @param releaseTag The release tag that initiated the run.
         * @param summary The completed RunSummary object containing all metrics.
         */
        public AccessControlLogQueueable(String releaseTag, RunSummary summary) {
            this.releaseTag = releaseTag;
            this.summary = summary;
        }

    	/**
         * @description The main execution body of the Queueable job. It builds and inserts the
         *              single, comprehensive summary log record.
         * @param context The context for the Queueable job.
         */
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
                    // 1. Build the CSV Header
                    String csvContent = 'Operation,Component Type,Target API Name,Permission Set,Access Granted\n';
                    
                    // 2. Build the CSV Rows
                    for (ChangeDetail log : summary.detailedLogs) {
                        csvContent += '"' + log.operation + '","' 
                                    + log.componentType + '","' 
                                    + log.targetName + '","' 
                                    + log.permSetName + '","' 
                                    + log.accessLevel + '"\n';
                    }
                    
                    // 3. Create the File (ContentVersion)
                    ContentVersion cv = new ContentVersion();
                    cv.Title = 'Detailed_Access_Log_' + releaseTag + '.csv';
                    cv.PathOnClient = 'Detailed_Access_Log_' + releaseTag + '.csv';
                    cv.VersionData = Blob.valueOf(csvContent);
                    insert cv;
                    
                    // 4. Link the File to the Error Log Record
                    Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = conDocId;
                    cdl.LinkedEntityId = row.Id; // Attach to the newly created Error Log record
                    cdl.ShareType = 'V'; // Viewer permission
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

    /**
     * @description Main entry point for the framework. Initializes a RunSummary, retrieves all
     *              'Permission Set' rules for a given release tag, and orchestrates processing.
     * @param releaseTag The unique identifier from the Release_Tag__c field used to select which
     *                   Access_Control_Rule__mdt records to process.
     */
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

    /**
     * @description Processes rules for Object and Field Level Security, updating the RunSummary object.
     * @param rules A list of 'Object/Field' type rules to process.
     * @param summary The central RunSummary object to accumulate metrics and warnings.
     */
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
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames]) {
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
             for (ObjectPermissions op : [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete FROM ObjectPermissions WHERE ParentId IN :permSetIds AND SobjectType IN :objectApiNames]) {
                existingObjectPerms.put(op.ParentId + '-' + op.SobjectType, op);
            }
        }
       
        // FIX: Separate lists for specific sObject types to prevent DML chunking limit errors
        List<ObjectPermissions> objPermsToInsert = new List<ObjectPermissions>();
        List<ObjectPermissions> objPermsToUpdate = new List<ObjectPermissions>();
        List<FieldPermissions> fldPermsToInsert = new List<FieldPermissions>();
        List<FieldPermissions> fldPermsToUpdate = new List<FieldPermissions>();

        for (BSF_Access_Control_Rule__mdt rule : rules) {
            String sObjectName = String.isBlank(rule.SObject_API_Name__c) ? '' : rule.SObject_API_Name__c.trim();
            if (sObjectName == '') {
                continue;
            }
            for (String psName : cleanSplit(rule.Target_API_Names__c)) {
                Id permSetId = permSetNameToIdMap.get(psName);
                if (permSetId == null) {
                    continue;
                }
                List<String> fieldNames = cleanSplit(rule.Field_API_Names__c);
                if (fieldNames.isEmpty()) {
                    String key = permSetId + '-' + sObjectName;
                    ObjectPermissions op = existingObjectPerms.get(key);
                    if (op == null) {
                        objPermsToInsert.add(new ObjectPermissions(ParentId=permSetId, SobjectType=sObjectName, PermissionsRead=rule.PermissionsRead__c, PermissionsCreate=rule.PermissionsCreate__c, PermissionsEdit=rule.PermissionsEdit__c, PermissionsDelete=rule.PermissionsDelete__c));
                        summary.objInserted++;                        
                        summary.detailedLogs.add(new ChangeDetail('Insert', 'Object', sObjectName, psName, 'R:'+rule.PermissionsRead__c+' C:'+rule.PermissionsCreate__c+' E:'+rule.PermissionsEdit__c+' D:'+rule.PermissionsDelete__c));
                    } else if (op.PermissionsRead!=rule.PermissionsRead__c || op.PermissionsCreate!=rule.PermissionsCreate__c || op.PermissionsEdit!=rule.PermissionsEdit__c || op.PermissionsDelete!=rule.PermissionsDelete__c) {
                        op.PermissionsRead=rule.PermissionsRead__c; op.PermissionsCreate=rule.PermissionsCreate__c; op.PermissionsEdit=rule.PermissionsEdit__c; op.PermissionsDelete=rule.PermissionsDelete__c;
                        objPermsToUpdate.add(op);
                        summary.objUpdated++;
                        summary.detailedLogs.add(new ChangeDetail('Update', 'Object', sObjectName, psName, 'R:'+rule.PermissionsRead__c+' C:'+rule.PermissionsCreate__c+' E:'+rule.PermissionsEdit__c+' D:'+rule.PermissionsDelete__c));
                    }
                } else {
                    Map<String, Schema.SObjectField> fieldMap = objectFieldMaps.get(sObjectName);
                    if (fieldMap == null) {
                        continue;
                    }
                    for (String fieldName : fieldNames) {
                        Schema.SObjectField token = fieldMap.get(fieldName);
                        if (token == null) {
                            System.debug(LoggingLevel.WARN, 'Field "' + sObjectName + '.' + fieldName + '" not found. Skipping.');
                            summary.missingFields++;
                            if (summary.missingFieldList.size() < 25) {
                                summary.missingFieldList.add(sObjectName + '.' + fieldName);
                            }
                            continue;
                        }
                        Schema.DescribeFieldResult fieldDescribe = token.getDescribe();
    
    					// Skip fields that cannot have FLS applied (Master-Detail, System fields, etc.)
    					if (!fieldDescribe.isPermissionable()) {
        					System.debug(LoggingLevel.INFO, 'Skipping non-permissionable field: ' + sObjectName + '.' + fieldName);
        					continue;
   						}
                        Boolean effectiveEdit = rule.PermissionsEdit__c && fieldDescribe.isUpdateable();
                        String fullFieldApiName = sObjectName + '.' + fieldName;
                        String key = permSetId + '-' + fullFieldApiName;
                        FieldPermissions fp = existingFieldPerms.get(key);
                        if (fp == null) {
                            fldPermsToInsert.add(new FieldPermissions(ParentId=permSetId, SobjectType=sObjectName, Field=fullFieldApiName, PermissionsRead=rule.PermissionsRead__c, PermissionsEdit=effectiveEdit));
                            summary.fldInserted++;
                            summary.detailedLogs.add(new ChangeDetail('Insert', 'Field', fullFieldApiName, psName, 'Read:'+rule.PermissionsRead__c+' Edit:'+effectiveEdit));
                        } else if (fp.PermissionsRead != rule.PermissionsRead__c || fp.PermissionsEdit != effectiveEdit) {
                            fp.PermissionsRead=rule.PermissionsRead__c; fp.PermissionsEdit=effectiveEdit;
                            fldPermsToUpdate.add(fp);
                            summary.fldUpdated++;
                            summary.detailedLogs.add(new ChangeDetail('Update', 'Field', fullFieldApiName, psName, 'Read:'+rule.PermissionsRead__c+' Edit:'+effectiveEdit));
                        }
                    }
                }
            }
        }
        
        // FIX: Execute DML on each specific list independently. 
        // Your executeDml helper already checks if the list is empty, making this perfectly safe.
        executeDml(objPermsToInsert, 'insert', summary);
        executeDml(fldPermsToInsert, 'insert', summary);
        executeDml(objPermsToUpdate, 'update', summary);
        executeDml(fldPermsToUpdate, 'update', summary);
    }

    /**
     * @description Processes component access rules using the generic SetupEntityAccess object.
     * @param rules A list of component-type rules to process.
     * @param childEntityType The API name of the component (e.g., 'ApexClass', 'ApexPage').
     * @param summary The central RunSummary object to accumulate metrics and warnings.
     */
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
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permSetNames]) {
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
                    continue;
                }
                for (String compName : cleanSplit(rule.Component_API_Names__c)) {
                    Id setupEntityId = compNameToId.get(compName);
                    if (setupEntityId == null) {
                        summary.missingComp++;
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

    /**
     * @description Utility method to safely split a comma-separated string into a list of
     *              trimmed, non-blank strings.
     * @param input The raw, comma-separated string from the metadata rule.
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
     * @description Centralized, safe DML execution helper. It wraps DML operations in a try-catch
     *              block and updates the RunSummary object with any failures.
     * @param records The list of SObjects to perform DML on.
     * @param operation The DML operation as a string ('insert' or 'update').
     * @param summary The central RunSummary object to update in case of DML failure.
     */
    private static void executeDml(List<SObject> records, String operation, RunSummary summary) {
        if (records == null || records.isEmpty()) {
            return;
        }
        try {
            if (operation == 'insert') {
                insert records;
            } else if (operation == 'update') {
                update records;
            }
            System.debug(LoggingLevel.INFO, 'SUCCESS: Performed ' + operation + ' on ' + records.size() + ' records for ' + records[0].getSObjectType());
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'DML Error during ' + operation + ' on ' + records[0].getSObjectType() + '. Message: ' + e.getMessage());
            summary.dmlFailures++;
            if (summary.dmlErrors.size() < 10) {
                summary.dmlErrors.add(e.getMessage());
            }
        }
    }
}