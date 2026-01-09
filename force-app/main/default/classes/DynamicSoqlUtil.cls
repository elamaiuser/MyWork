public with sharing class DynamicSoqlUtil {
    /**
     * Returns allowed object API names for a given Apex component/class
     */
    public static Set<String> getAllowedObjects(String componentName) {
        Set<String> allowedObjects = new Set<String>();

        for (Allowed_Dynamic_SOQL_Object__mdt rec : [
            SELECT Object_API_Name__c
            FROM Allowed_Dynamic_SOQL_Object__mdt
            WHERE Component_Name__c = :componentName
            AND Is_Active__c = true
        ]) {
            if (String.isNotBlank(rec.Object_API_Name__c)) {
                allowedObjects.add(rec.Object_API_Name__c.toUpperCase());
            }
        }
        System.debug('HRP-16273  allowedObjects:'+allowedObjects);
        return allowedObjects;
    }

    /**
     * Validates object access for dynamic SOQL
     */
    public static void validateObject(
        String componentName,
        String objectApiName
    ) {
        Set<String> allowed = getAllowedObjects(componentName);
        System.debug('HRP-16273 allowed :'+allowed);
        if (allowed.isEmpty()) {
            System.debug('No allowed objects configured for component: ' + componentName);
            throw new AuraHandledException(
                'No allowed objects configured for component: ' + componentName
            );
        }

        // Normalize allowed objects to lowercase
        Set<String> allowedLower = new Set<String>();
        for (String obj : allowed) {
            if (obj != null) {
                allowedLower.add(obj.toLowerCase());
            }
        }
        // Normalize incoming object name
        String incomingObject = objectApiName != null ? objectApiName.toLowerCase() : null;

        if (!allowedLower.contains(incomingObject)) {
            System.debug('Dynamic SOQL not allowed for object: ' + objectApiName);
            throw new AuraHandledException(
                'Dynamic SOQL not allowed for object: ' + objectApiName
            );
        }
    }

    /**
     * Extract object name from SOQL safely
     * Example: SELECT Id, Name FROM Account WHERE ...
     */
    public static String extractObjectName(String soql) {
        if (String.isBlank(soql)) {
            return null;
        }

        String upper = soql.toUpperCase();
        Integer fromIndex = upper.indexOf(' FROM ');
        if (fromIndex == -1) {
            return null;
        }

        String afterFrom = soql.substring(fromIndex + 6).trim();
        String objecName = afterFrom.split('\\s+')[0].toUpperCase();
        System.debug('HRP-16273  objecName:'+objecName);
        return objecName;
    }


    public static void validateSoql(String soql) {
        String lower = soql.toLowerCase();
        System.debug('HRP-16273  soql lower query :'+lower);
        // Hard blocks
        List<String> forbidden = new List<String>{
            'delete ', 'update ', 'insert ', 'merge ',
            'union ', 'group by ', 'having ',            
            'select select', '--', '/*', '*/'
        };

        for (String keyword : forbidden) {
            if (lower.contains(keyword)) {
                throw new AuraHandledException('Invalid SOQL');
            }
        }
    }

    public static String getSafeOrderBy(
        String fieldwithOrderBy,
        String objectName) {
            
        if (String.isBlank(fieldwithOrderBy)) {
            return 'ORDER BY CreatedDate DESC';
        }

        // Case-insensitive regex using (?i)
        Pattern p = Pattern.compile(
            '(?i)^[a-zA-Z0-9_]+(\\s+(ASC|DESC))?$'
        );
        Matcher m = p.matcher(fieldwithOrderBy.trim());

        if (!m.matches()) {
            throw new AuraHandledException('Invalid ORDER BY clause');
        }

        // Field whitelist validation
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap();

        String fieldName = fieldwithOrderBy.split('\\s+')[0];

        if (!fieldMap.containsKey(fieldName)) {
            throw new AuraHandledException('Invalid sort field');
        }

        return 'ORDER BY ' + String.escapeSingleQuotes(fieldwithOrderBy.trim());
    }

     /**
     * Executes a SOQL query safely using metadata-driven allow list
     */
    public static List<sObject> safeQuery(
        String soql,
        String componentName,
        List<String> recordIds,
        Integer limits,
        Integer recordOffset
    ) {
        validateSoql(soql);

        String objectName = extractObjectName(soql);
        if (String.isBlank(objectName)) {
            throw new AuraHandledException('Unable to determine object from query');
        }

        Set<String> allowedObjects = getAllowedObjects(componentName);

        if (!allowedObjects.contains(objectName)) {
            throw new AuraHandledException(
                'SOQL access denied for object: ' + objectName
            );
        }

        return Database.query(soql, AccessLevel.USER_MODE);
    }
}