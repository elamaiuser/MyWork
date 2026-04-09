/**
 * @Description        : Apex controller for the genericRelatedListLWC component.
 *                       Replaces the legacy GenericRelatedListController used by the Aura version.
 *                       Eliminates SOQL injection by:
 *                         - Validating objectApiName against Schema.getGlobalDescribe()
 *                         - Validating each SELECT field against the object's field map
 *                         - Restricting filterFieldApiName to word characters via regex (\w+)
 *                         - Validating ORDER BY field against the field map
 *                         - Parsing additionalFilter with regex and escaping all values
 *                         - Binding the WHERE clause value via :recordId (never concatenated)
 * @Author             :
 * Ver       Date            Author              Modification
 * 1.0       2024                                Initial Version (LWC rewrite of GenericRelatedListController)
 */
public class GenericRelatedListLWCController {

    @AuraEnabled(cacheable=false)
    public static wrapperClass getRecords(
        String[]  recordId,
        String    columnLabels,
        String    objectApiName,
        String    fieldsApiNames,
        String    filterFieldApiName,
        Integer   recordLimit,
        Integer   recordOffset,
        String    fieldwithOrderBy,
        String    additionalFilter
    ) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        String objKey = (objectApiName != null) ? objectApiName.trim().toLowerCase() : '';
        if (!globalDescribe.containsKey(objKey)) {
            throw new AuraHandledException('Invalid object API name: ' + objectApiName);
        }
        Schema.DescribeSObjectResult objDescribe = globalDescribe.get(objKey).getDescribe();
        Map<String, Schema.SObjectField> fieldMap  = objDescribe.fields.getMap();

        List<String> safeSelectFields   = new List<String>{ 'Id' };
        List<String> userColumnApiNames = new List<String>();
        Set<String>  addedFields        = new Set<String>{ 'id' };

        if (String.isNotBlank(fieldsApiNames)) {
            for (String field : fieldsApiNames.split(',')) {
                String trimmed = field.trim();
                String key     = trimmed.toLowerCase();
                if (fieldMap.containsKey(key) && !addedFields.contains(key)) {
                    safeSelectFields.add(trimmed);
                    userColumnApiNames.add(trimmed);
                    addedFields.add(key);
                }
            }
        }

        if (String.isBlank(filterFieldApiName) ||
            !Pattern.matches('\\w+', filterFieldApiName.trim())) {
            throw new AuraHandledException(
                'Invalid filter field API name format: ' + filterFieldApiName
            );
        }
        String safeFilterField = filterFieldApiName.trim();

        String safeOrderBy = 'CreatedDate DESC';
        if (String.isNotBlank(fieldwithOrderBy)) {
            String[] parts      = fieldwithOrderBy.trim().split('\\s+');
            String   orderField = parts[0].trim();
            if (fieldMap.containsKey(orderField.toLowerCase())) {
                safeOrderBy = orderField;
                if (parts.size() > 1) {
                    String dir = parts[1].trim().toUpperCase();
                    safeOrderBy += (dir == 'ASC' || dir == 'DESC') ? ' ' + dir : ' DESC';
                } else {
                    safeOrderBy += ' DESC';
                }
            }
        }

        String additionalWhereClause = '';
        if (String.isNotBlank(additionalFilter)) {
            additionalWhereClause = ' AND (' + buildSafeAdditionalFilter(additionalFilter, fieldMap) + ')';
        }

        Integer safeLimit  = (recordLimit  != null && recordLimit  > 0) ? recordLimit  : 5;
        Integer safeOffset = (recordOffset != null && recordOffset >= 0) ? recordOffset : 0;
        Integer queryLimit = safeLimit + 1;
        
        String whereClause;
        
        if (objDescribe.getName() == 'Task') {
            whereClause = '(' + safeFilterField + ' IN :recordId OR Delegate__c IN :recordId)';
        } else {
            whereClause = safeFilterField + ' IN :recordId';
        }
        
        String safeQuery =
            'SELECT '    + String.join(safeSelectFields, ', ') +
            ' FROM '     + objDescribe.getName() +
            ' WHERE '    + whereClause +
            additionalWhereClause +
            ' ORDER BY ' + safeOrderBy +
            ' LIMIT :queryLimit OFFSET :safeOffset';

        List<SObject> allResults = Database.query(safeQuery);
        Boolean hasMore = allResults.size() > safeLimit;
        List<SObject> sObjectList = new List<SObject>();
        Integer displayCount = hasMore ? safeLimit : allResults.size();
        for (Integer i = 0; i < displayCount; i++) {
            sObjectList.add(allResults[i]);
        }

        wrapperClass result  = new wrapperClass();
        result.sObjectList   = sObjectList;
        result.hasMore       = hasMore;
        result.counts        = sObjectList.size();
        result.columnNames   = String.join(userColumnApiNames, ',');
        result.objectName    = objDescribe.getName();

        if (recordId != null && !recordId.isEmpty() && recordId[0] != null && recordId[0].length() >= 3) {
            String keyPrefix     = recordId[0].substring(0, 3);
            String parentObjName = '';
            for (Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()) {
                String prefix = sObjType.getDescribe().getKeyPrefix();
                if (prefix == keyPrefix) {
                    parentObjName = sObjType.getDescribe().getName();
                    break;
                }
            }
            if (String.isNotBlank(parentObjName)) {
                Schema.SObjectType parentType = Schema.getGlobalDescribe().get(parentObjName.toLowerCase());
                if (parentType != null) {
                    Schema.DescribeSObjectResult parentDescribe = parentType.getDescribe();
                    if (parentDescribe.fields.getMap().containsKey('name')) {
                        try {
                            List<SObject> parentRecords = Database.query(
                                'SELECT Name FROM ' + parentObjName + ' WHERE Id IN :recordId LIMIT 1'
                            );
                            if (!parentRecords.isEmpty()) {
                                result.recordName = parentRecords[0];
                            }
                        } catch (Exception e) {
                            // Skip name resolution if query fails
                        }
                    }
                }
            }
        }

        return result;
    }

    @AuraEnabled
    public static void deleteRecords(Id lstRecordId) {
        try {
            String  objName = lstRecordId.getSObjectType().getDescribe().getName();
            SObject sObj    = Schema.getGlobalDescribe().get(objName).newSObject();
            sObj.put('Id', lstRecordId);
            delete sObj;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static final Set<String> NO_QUOTE_VALUES = new Set<String>{
        'null', 'true', 'false',
        'today', 'yesterday', 'tomorrow',
        'last_week',  'this_week',  'next_week',
        'last_month', 'this_month', 'next_month',
        'last_quarter', 'this_quarter', 'next_quarter',
        'last_year',  'this_year',  'next_year',
        'last_fiscal_quarter', 'this_fiscal_quarter', 'next_fiscal_quarter',
        'last_fiscal_year',   'this_fiscal_year',    'next_fiscal_year'
    };

    @TestVisible
    private static String buildSafeAdditionalFilter(
        String rawFilter,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        if (String.isBlank(rawFilter)) { return ''; }

        Pattern condPattern = Pattern.compile(
            '(?i)(\\w+)\\s*(!=|<=|>=|NOT\\s+IN|IN|=|<|>)\\s*(\'[^\']*\'|\\([^)]+\\)|[^\\s()\']+)'
        );
        Matcher m = condPattern.matcher(rawFilter);

        String  result  = '';
        Integer lastEnd = 0;

        while (m.find()) {
            result += rawFilter.substring(lastEnd, m.start());

            String fieldName = m.group(1);
            String operator  = m.group(2);
            String rawValue  = m.group(3);

            String opNormal = operator.trim().replaceAll('\\s+', ' ').toUpperCase();

            String safeValue;
            if (rawValue.startsWith('(')) {
                String listContent = rawValue.substring(1, rawValue.length() - 1);
                Pattern itemPattern = Pattern.compile('\'([^\']*)\'|([^,\'\\s]+)');
                Matcher vm = itemPattern.matcher(listContent);
                List<String> safeItems = new List<String>();
                while (vm.find()) {
                    if (vm.group(1) != null) {
                        safeItems.add('\'' + String.escapeSingleQuotes(vm.group(1)) + '\'');
                    } else if (String.isNotBlank(vm.group(2))) {
                        safeItems.add(vm.group(2).trim());
                    }
                }
                safeValue = '(' + String.join(safeItems, ', ') + ')';
            } else if (rawValue.startsWith('\'')) {
                String quotedContent = rawValue.substring(1, rawValue.length() - 1);
                safeValue = '\'' + String.escapeSingleQuotes(quotedContent) + '\'';
            } else {
                String lv = rawValue.toLowerCase();
                Boolean isLiteral = NO_QUOTE_VALUES.contains(lv)
                    || lv.startsWith('last_n_')
                    || lv.startsWith('next_n_')
                    || rawValue.isNumeric();
                safeValue = isLiteral
                    ? rawValue
                    : '\'' + String.escapeSingleQuotes(rawValue) + '\'';
            }

            result += fieldName + ' ' + opNormal + ' ' + safeValue;
            lastEnd = m.end();
        }

        result += rawFilter.substring(lastEnd);

        String stripped = condPattern.matcher(result).replaceAll('');
        stripped = stripped.replaceAll('(?i)\\b(AND|OR|NOT)\\b', '');
        stripped = stripped.replaceAll('[\\s()]+', '');
        stripped = stripped.trim();

        if (String.isNotBlank(stripped)) {
            throw new AuraHandledException(
                'Invalid filter syntax — unexpected tokens after parsing: ' + stripped
            );
        }

        return result.trim();
    }

    public class wrapperClass {
        @AuraEnabled public List<SObject> sObjectList { get; set; }
        @AuraEnabled public Integer       counts      { get; set; }
        @AuraEnabled public Boolean       hasMore     { get; set; }
        @AuraEnabled public String        columnNames { get; set; }
        @AuraEnabled public String        objectName  { get; set; }
        @AuraEnabled public SObject       recordName  { get; set; }
    }
}