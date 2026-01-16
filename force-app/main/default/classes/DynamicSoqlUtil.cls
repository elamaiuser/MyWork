public with sharing class DynamicSoqlUtil {


    public static List<sObject> executeDynamicQuery(
        String rawSoql,
        String componentName,
        String fieldWithOrderBy,
        Integer limitSize,
        Integer offsetSize
    ) {
        if (String.isBlank(rawSoql)) {
            System.debug('HRP-16273 Exception : SOQL cannot be empty.');
            throw new AuraHandledException('SOQL cannot be empty');
        }

        //Base SOQL validation
        validateSoql(rawSoql);

        //Parse SOQL into safe components
        ParsedSoql parsed = parseSoql(rawSoql);

        //Object allow-list validation (metadata driven)
        validateObject(componentName, parsed.objectName);

        //Field allow-list validation
        validateFields(parsed.objectName, parsed.fields);

        //Build safe ORDER BY (ONLY here)
        String safeOrderBy =
            getSafeOrderBy(fieldWithOrderBy, parsed.objectName);

        //Build final trusted SOQL
        String finalSoql =
            parsed.baseSoql +
            ' ' + safeOrderBy +
            ' LIMIT ' + limitSize +
            ' OFFSET ' + offsetSize;

        System.debug('HRP-16273 FINAL SOQL => ' + finalSoql);

        return Database.query(finalSoql);
    }

    public static void validateSoql(String soql) {
        String lower = soql.toLowerCase();

        List<String> forbidden = new List<String>{
            'delete ', 'update ', 'insert ', 'merge ',
            'union ', 'group by ', 'having ',
            '--', '/*', '*/'
        };

        for (String keyword : forbidden) {
            if (lower.contains(keyword)) {
                System.debug('HRP-16273 Exception : Invalid SOQL detected.');
                throw new AuraHandledException('Invalid SOQL detected');
            }
        }
    }

    public static void validateObject(
        String componentName,
        String objectApiName
    ) {
        Set<String> allowed = getAllowedObjects(componentName);

        if (allowed.isEmpty()) {
            System.debug('HRP-16273 Exception : No allowed objects configured for ' + componentName);
            throw new AuraHandledException(
                'No allowed objects configured for ' + componentName
            );
        }

        Set<String> allowedLower = new Set<String>();
        for (String obj : allowed) {
            allowedLower.add(obj.toLowerCase());
        }
        String cleanedObjectName = objectApiName.replaceAll('[^a-zA-Z0-9_]', '');
        System.debug('HRP-16273 objectApiName:'+cleanedObjectName.toLowerCase()+' allowedLower:'+allowedLower);
        if (!allowedLower.contains(cleanedObjectName.toLowerCase())) {
            System.debug('HRP-16273 Exception : SOQL access denied for object: ' + objectApiName);
            throw new AuraHandledException(
                'SOQL access denied for object: ' + cleanedObjectName.toLowerCase()
            );
        }
    }

    public static void validateFields(
        String objectName,
        Set<String> fields
    ) {
        System.debug('HRP-16273 validateFields b: objectName: ' + objectName);
        System.debug('HRP-16273 validateFields fields ==>: ' + fields);
        boolean ignoreFieldChecking = false;
        if (objectName.endsWith('s__r)')) {
            objectName = objectName.substring(0, objectName.length() - 5) + '__c';
            ignoreFieldChecking = true;
        }
        System.debug('HRP-16273 validateFields a: objectName: ' + objectName);
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap();
        if(!ignoreFieldChecking){
            for (String fieldName : fields) {
                if(fieldName !='RecordType.Name' && 
                    fieldName !='sked_Territory__r.sked_High_Drive_Productivity_Threshold__c' &&
                    fieldName !='sked_Territory__r.sked_Mid_Drive_Productivity_Threshold__c' &&
                    fieldName !='sked_Territory__r.sked_Parent__c' 
                    ){
                    if (!fieldMap.containsKey(fieldName)) {
                        System.debug('HRP-16273 Exception :Invalid field in SOQL: ' + fieldName);
                        throw new AuraHandledException(
                            'Invalid field in SOQL: ' + fieldName
                        );
                    }
                }
            }
        } 
    }

    public static String getSafeOrderBy(
        String fieldWithOrderBy,
        String objectName) {

        if (String.isBlank(fieldWithOrderBy)) {
            return 'ORDER BY CreatedDate DESC';
        }

        // Allow: FieldName [ASC|DESC]
        Pattern p = Pattern.compile(
            '(?i)^[a-zA-Z0-9_]+(\\s+(ASC|DESC))?$'
        );
        Matcher m = p.matcher(fieldWithOrderBy.trim());

        if (!m.matches()) {
            System.debug('HRP-16273 Exception :Invalid ORDER BY clause.');
            throw new AuraHandledException('Invalid ORDER BY clause');
        }

        String fieldName = fieldWithOrderBy.split('\\s+')[0];

        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap();

        if (!fieldMap.containsKey(fieldName)) {
            System.debug('HRP-16273 Exception :Invalid ORDER BY clause.');
            throw new AuraHandledException('Invalid ORDER BY field');
        }

        return 'ORDER BY ' + fieldWithOrderBy;
    }


    private static ParsedSoql parseSoql(String soql) {
        String cleaned = soql.trim();
        System.debug('HRP-16273 before clean : '+cleaned);
        // Remove ORDER BY / LIMIT / OFFSET safely
        cleaned = cleaned.replaceAll(
            '(?i)\\s+order\\s+by\\s+[a-zA-Z0-9_\\s,]+', ''
        );
        cleaned = cleaned.replaceAll('(?i)\\s+limit\\s+\\d+', '');
        cleaned = cleaned.replaceAll('(?i)\\s+offset\\s+\\d+', '');

        String upper = cleaned.toUpperCase();
        Integer fromIndex = upper.indexOf(' FROM ');
        if (fromIndex == -1) {
            System.debug('HRP-16273 Exception :Invalid SOQL structure.');
            throw new AuraHandledException('Invalid SOQL structure');
        }

        String fieldPart = cleaned.substring(6, fromIndex).trim();
        String fromPart = cleaned.substring(fromIndex + 6).trim();

        String objectName = fromPart.split
        ('\\s+')[0];

        Set<String> fields = new Set<String>();
        for (String f : fieldPart.split(',')) {
            fields.add(f.trim());
        }

        ParsedSoql parsed = new ParsedSoql();
        parsed.baseSoql = cleaned;
        parsed.objectName = objectName;
        parsed.fields = fields;
        System.debug('HRP-16273 after clean : '+cleaned);
        return parsed;
    }

    private static Set<String> getAllowedObjects(String componentName) {
        Set<String> allowedObjects = new Set<String>();

        for (Allowed_Dynamic_SOQL_Object__mdt rec : [
            SELECT Object_API_Name__c
            FROM Allowed_Dynamic_SOQL_Object__mdt
            WHERE Component_Name__c = :componentName
            AND Is_Active__c = true
        ]) {
            allowedObjects.add(rec.Object_API_Name__c);
        }

        return allowedObjects;
    }

    private class ParsedSoql {
        String baseSoql;
        String objectName;
        Set<String> fields;
    }
    public static String buildInClause(String fieldName, List<String> ids) {
        if (ids == null || ids.isEmpty()) {
            System.debug('HRP-16273 Exception :ID list cannot be empty.');
            throw new AuraHandledException('ID list cannot be empty');
        }

        List<String> safeIds = new List<String>();
        for (String idVal : ids) {
            // Validate Salesforce Id
            /*if (!Id.isValid(idVal)) {
                throw new AuraHandledException('Invalid Id in filter');
            } */
            safeIds.add('\'' + String.escapeSingleQuotes(idVal) + '\'');
        }

        return fieldName + ' IN (' + String.join(safeIds, ',') + ')';
    }

    public static String adjustTheBindingFieldName(String soqlQuery, String[] recordIds){
        Pattern inPattern = Pattern.compile('(?i)(\\w+)\\s+IN\\s*:\\s*(\\w+)');
        Matcher matcher = inPattern.matcher(soqlQuery);

        if (matcher.find()) {
            String fieldName = matcher.group(1);   // e.g. AccountId
            String bindVar   = matcher.group(2);   // e.g. recordIds
            System.debug('HRP-16273 fieldName => ' + fieldName+' bindVar => ' + bindVar);
            
            if (bindVar != null && bindVar.toLowerCase() == 'recordids') {
                String inClause = DynamicSoqlUtil.buildInClause(fieldName, recordIds);
                soqlQuery = matcher.replaceFirst(inClause);
            }
        }
        System.debug('HRP-16273 soqlQuery adjustTheBindingFieldName => ' + soqlQuery);
        return soqlQuery;
    }

}
