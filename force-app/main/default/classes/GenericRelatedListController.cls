/**
* @File Name          : GenericRelatedListController.cls
* @Description        : Controller for generic related lsit
* @Author             : 
* Ver       Date            Author      		  Modification
* 1.0    01/11/2020                             Initial Version
**/
public class GenericRelatedListController {

    /**
     * get result base on the soql paramaters
     * @param  recordId record id
     * @param  columnName display column name
     * @param  soqlQuery query to find record
     * @param  limits record search limit
     * @param  recordOffset for lazy loading
     * @return wrapperClass   return wrapper class of rcord and other values
     */ 
    @AuraEnabled
    public static wrapperClass getRecords(
        String[] recordId, 
        String columnName, 
        String soqlQuery, 
        Integer limits, 
        Integer recordOffset,
        String fieldwithOrderBy){
            
        System.debug( 'recordId is in getRecord ' + recordId );
        String sanitizedSoql = soqlQuery;
        List<sObject> sObjectList;
        wrapperClass wrapperClass = new wrapperClass();
        List<String> recordIds = recordId;
        List<String> soqlQueryList = new List<String>();
        try {
            // HRP-16273 & HRP-16417 SECURITY VALIDATION =================
            DynamicSoqlUtil.validateSoql(sanitizedSoql);
            // Extract object name safely
            String objectName = DynamicSoqlUtil.extractObjectName(sanitizedSoql);

            // Enforce object whitelist
            DynamicSoqlUtil.validateObject('GenericRelatedListController',objectName);

            //String soqlQueryForAll = sanitizedSoql;
            if(sanitizedSoql.contains('Task')||sanitizedSoql.contains('task'))
            {
              sanitizedSoql += ' recordIds OR Delegate__c IN: recordIds)';  
            } else
            {
              sanitizedSoql += ' recordIds';
            }
            if ((sanitizedSoql.contains('(')) || sanitizedSoql.contains(')'))
            { 
            String soqlQuery1;
              if(sanitizedSoql.contains('('))
              {
                soqlQuery1 = sanitizedSoql.substringAfter('(');
              }
              if(soqlQuery1.contains(')'))
              {
                soqlQuery1 = soqlQuery1.substringBefore(')');
              }
              if(soqlQuery1.containsIgnoreCase('SELECT')){
                soqlQuery1 += ' recordIds';
              }
              string subquery = '('+soqlQuery1+') ';
              sanitizedSoql = sanitizedSoql.substringBefore('(')+subquery+sanitizedSoql.substringAfter(')');
            }
            String orderByClause = '';
            
            if(String.isNotBlank(fieldwithOrderBy)) {
                // Assuming the format is 'fieldName ASC/DESC'
                //orderByClause = 'ORDER BY ' + fieldwithOrderBy;
                //HRP-16273 & HRP-16417 Secure ORDER BY
                orderByClause = DynamicSoqlUtil.getSafeOrderBy(fieldwithOrderBy, objectName);
            } else {
                // Default ordering
                orderByClause = 'ORDER BY CreatedDate DESC';
            }
           //soqlQuery += ' Order by CreatedDate DESC limit '+limits+' Offset '+recordOffset;
            sanitizedSoql += ' ' + orderByClause + ' limit :limits Offset :recordOffset';
            System.debug('sanitizedSoql is ' + sanitizedSoql );
            String trustedSoql = sanitizedSoql;
            //sObjectList = Database.Query(soqlQuery);
            sObjectList = DynamicSoqlUtil.safeQuery(trustedSoql,'GenericRelatedListController',recordIds,limits,recordOffset);

            system.debug( 'sObjectList is ' + sObjectList );
            wrapperClass.sObjectList = sObjectList;
            System.debug('wrapperClass.sObjectList: ' + wrapperClass.sObjectList);
            //Integer recordCount = Database.Query(soqlQueryForAll).size();
            Integer recordCount = sObjectList.size();
            wrapperClass.counts = recordCount;
            String[] firstSplit;
            if(sanitizedSoql.contains('select')){
                firstSplit = sanitizedSoql.split('select');
            }else if(sanitizedSoql.contains('Select')){
                firstSplit = sanitizedSoql.split('Select');
            }else if(sanitizedSoql.contains('SELECT')){
                firstSplit = sanitizedSoql.split('SELECT');
            }
            String[] secondSplit;
            if(sanitizedSoql.contains('from')){
                secondSplit = firstSplit[1].split('from');
            }else if(sanitizedSoql.contains('From')){
                secondSplit = firstSplit[1].split('From');
            }else if(sanitizedSoql.contains('FROM')){
                secondSplit = firstSplit[1].split('FROM');
            }
            String[] columnApiName = secondSplit[0].split(','); 
            String[] objName = secondSplit[1].split(' ');
            Set<String> filtterdArraySet= new Set<String>(secondSplit[0].split(','));
            List<String> filtterdArrayList = secondSplit[0].split(',');
            String[] filtterdArray = secondSplit[0].split(',');
            
            System.debug( 'recordIds is ' + recordIds );
            
            List<String> columList = columnName.split(',');
            Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map <String, Schema.SObjectField> fieldMap = schemaMap.get(objName[1]).getDescribe().fields.getMap();
            
            String combineColumnName = '';
            for(Integer i = 0 ; i < filtterdArrayList.size(); i++){
                combineColumnName += filtterdArrayList[i].trim()+',';
            }
			System.debug( 'recordIds is ' + recordIds );
            String objectAPIName = '';
            String keyPrefix = recordIds[0].substring(0,3);
            for( Schema.SObjectType obj : Schema.getGlobalDescribe().Values() ){
                String prefix = obj.getDescribe().getKeyPrefix();
                if(prefix == keyPrefix){
                    objectAPIName = obj.getDescribe().getName();
                    break;
                }
            }
			sObject obj;
            System.debug( 'objectAPIName is ' + objectAPIName );
            if( objectAPIName != 'ContentDocument' && objectAPIName !=  'Task' ){
                String queryStr = 'Select Name from '+ String.escapeSingleQuotes(objectAPIName) +' where Id in :recordIds limit 1';
                obj = Database.Query(queryStr);
            }
            combineColumnName = combineColumnName.removeEnd(',');
            wrapperClass.columnNames = combineColumnName;
            wrapperClass.objectName = objectAPIName;
            wrapperClass.recordName = obj;
			System.debug('Final wrapperClass: ' + wrapperClass);
        } catch (Exception e) {
            System.debug( 'exception  msg:' + e.getMessage() + ' line number ' + e.getLineNumber() );
            System.debug( 'HRP-16273 Exception  Stack' + e.getStackTraceString() );
            throw new AuraHandledException(e.getMessage());
        }
        return wrapperClass;
    }

    /**
     * Delete record on the actions
     * @param  lstRecordId record id
     * @return void
     */
    @AuraEnabled
    public static void deleteRecords(Id lstRecordId){
        try {
            String objName = lstRecordId.getSObjectType().getDescribe().getName();
            sObject sObj = Schema.getGlobalDescribe().get(objName).newSObject();
            sObj.put('Id', lstRecordId);
            delete sObj;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class wrapperClass{
        @AuraEnabled public List<sObject> sObjectList {get; set;}
        @AuraEnabled public Integer counts {get; set;}
        @AuraEnabled public String columnNames {get; set;}
        @AuraEnabled public String objectName {get; set;}
        @AuraEnabled public sObject recordName {get; set;}
    }

}