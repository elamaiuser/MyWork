/************************************************************************************************************************
 * 
 * Description:     General helper class
 * 
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author              Brief Mod Description
 * 07/26/23     Fitsum Worku		Updates per HRP-10179 moved the method "sendEmail" from ResourceUserAllocationBatch
 * 									to this helper class so that it's reusable from multiple places.  For outbound emails,
 * 									the only way the "From" address can be configured for programatically generated emails
 * 									is via org wide email addresses.
 * 08/05/24    Priti Jana           Added new method to get same day porevious year for HRP-12706
 * 04/02/2026   Souvik Mukherjee    Changed Logic for HRP-17095 to Correct getSameDayOfNextYear method so that Cslculatation of Calender Build Roll Over Drive date is corrected.
 *                                  such that after adding 1 year to the drive that of the drive being rolled if the day of week is same as that of the source drive
 *                                  date, then the logic to decrement the next year drive date to find the date on the same day of week is skipped.
 ***********************************************************************************************************************/

public with sharing class Helper {
    public enum SearchStyle {
        BEFORE,    //If there is no exact result, return the closest one before the needle
        AFTER,     //If there is no exact result, return the closest one after the needle
        EXACT //If there is no exact result, return null
    }
    
    public static final Integer STATUS_OK {
		get {
			return 200;
		}
	}
    public static final Integer STATUS_ERROR {
		get {
			return 500;
		}
	}
    public static final Integer STATUS_TIMEOUT {
		get {
			return 408;
		}
	}
    public static final Integer STATUS_NOTFOUND {
		get {
			return 404;
		}
	}

    public static final String YES {
		get {
			return 'Yes';
		}
	}
    public static final String NO {
		get {
			return 'No';
		}
	}

    //used to test non async in testing
    public static Boolean disableAsync = false;
    
    public static Date today {
        get{
            today = !Test.isRunningTest() ||
                        (Test.isRunningTest() && today == null) ? 
                        System.today() : 
                        today;

            return today;
        }
     set;
    }
    /**
    * @description - determines if futur/async methods can be called
    * @return true if async methods can be called
    */
    public static Boolean canExecuteAsync()
    {
        Boolean sysLimitation = !System.isBatch() && !System.isFuture() && !disableAsync;

        Integer numFutureCalls = Limits.getFutureCalls();
        Integer futureLimit = Limits.getLimitFutureCalls();
        Boolean limitAsync = false;

        limitAsync = futureLimit > 0 ? numFutureCalls / futureLimit > .95 : limitAsync;

        return sysLimitation && !limitAsync;
    }

    /**
    * @description checks if running user in a profile set
    * @param profiles - set of profile names that have permission
    * @param profileId - profile id that needs to be validated
    * @param contains - checking if profile exists in profiles or does not exist in profiles
    * @return true if running user is in profile set
    */
    public static Boolean validateProfilePermission(Set<String> profiles, String profileId, Boolean contains)
    {
        Profile profile = [SELECT Name
                            FROM Profile
                            WHERE Id = :profileId
                            LIMIT 1 ];

        return contains ? 
                profiles.contains(profile.Name) 
                : !profiles.contains(profile.Name);
    }

    /**
    * @description checks if running user in permission set
    * @param permissionSets - set of permission sets to check
    * @param userId - user id to check if has permission set
    * @return true if user assigned permission set
    */
    public static Boolean validatePermissionSetAssignment(Set<String> permissionSets, String userId)
    {
        List<PermissionSetAssignment> psas = [SELECT Id 
                                                FROM PermissionSetAssignment 
                                                WHERE PermissionSetId IN (SELECT Id 
                                                                            FROM PermissionSet 
                                                                            WHERE Name in :permissionSets) 
                                                    AND AssigneeId IN (SELECT Id 
                                                                        FROM User 
                                                                        WHERE Id = :UserInfo.getUserId()) 
                                            ];
        return psas.size() > 0;
    }

    /**
    * @description Retrieve a List of fieldnames for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @return A list of fieldnames
    */ 
    private static Map<String, List<String>> fieldsByObjectMap = new Map<String, List<String>>();
    public static List<String> getFields(Schema.DescribeSObjectResult objectType) {
        if (fieldsByObjectMap.get(String.valueOf(objectType)) == null) {
            Map<String, Schema.SObjectField> fieldMap = objectType.fields.getMap();
            List<String> fieldList = new List<String>();
            for(String k : fieldMap.keyset()) fieldList.add(String.valueOf(fieldMap.get(k)));
            fieldsByObjectMap.put(String.valueOf(objectType), fieldList);
        }
        return fieldsByObjectMap.get(String.valueOf(objectType));
    }

    /**
    * @description Retrieve a List of fieldnames with the object name as a prefix "Account.Name", etc for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @return A list of fieldnames
    */ 
    private static Map<String, List<String>> fieldsByObjectWithPrefixMap = new Map<String, List<String>>();
    public static List<String> getFieldsWithPrefix(Schema.DescribeSObjectResult objectType) {
        return getFieldsWithPrefix(objectType, false);
    }
    
    /**
    * @description Retrieve a List of fieldnames with the object name as a prefix "Account.Name", etc for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @param parentRelationshipFormat Boolean if set to true, will replace the prefix with the ParentRelationship format (e.g for Custom Objects __c -> __r)
    * @return A list of fieldnames
    */ 
    public static List<String> getFieldsWithPrefix(Schema.DescribeSObjectResult objectType, Boolean parentRelationshipFormat) {
        String prefix = objectType.getName();
        System.Debug('prefix : ' + prefix);
        System.Debug('parentRelationshipFormat : ' + parentRelationshipFormat);
        if(parentRelationshipFormat) {
            prefix = prefix.replaceAll('__c', '__r');
        }
        System.Debug('prefix : ' + prefix);
        if (fieldsByObjectWithPrefixMap.get(String.valueOf(prefix)) == null) {
            Map<String, Schema.SObjectField> fieldMap = objectType.fields.getMap();
            List<String> fieldList = new List<String>();
            for(String k : fieldMap.keyset()) fieldList.add(prefix + '.' + String.valueOf(fieldMap.get(k)));
            fieldsByObjectWithPrefixMap.put(String.valueOf(prefix), fieldList);
        }

        return fieldsByObjectWithPrefixMap.get(String.valueOf(prefix));
    }
    
    /**
    * @description Update User Map with User Details
    * @param NONE
    * @return Cached Map
    */ 
    private static Map<Id, User> userMap = new Map<Id, User>();
    public static Map<Id, User> getUserDetails(List<Id> userIds) {
        Set<Id> userSetInternal = new Set<Id>();
        for(Id userId : userIds) {
            if(!userSetInternal.contains(userId)) {
               userSetInternal.add(userId);
            }
        }
        if(!userSetInternal.isEmpty()) {
            Set<String> f = new Set<String>(Helper.getFields(Schema.SObjectType.User));
            f.remove('Address');
            f.remove('ProfilePhotoId');
            String userSelection = String.join(new List<String>(f), ',');
            String query = 'SELECT ' + String.valueOf(userSelection) + 
                ' FROM User ' +
                ' WHERE Id in :userSetInternal';
            userMap.putAll((List<User>) Database.query(query));
        }
        return userMap; 
    }
    
    /**
    * @description Get details for a User
    * @param userId
    * @return User
    */ 
    public static User getUserDetail(Id userId) {
        return Helper.getUserDetails(new List<Id>{userId}).get(userId);
    }
    
    
    
    /**
    * @description Retrieve a Map of fields for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @return A Map of fieldnames to SObjectField
    */ 
    private static Map<String, Map<String, Schema.SObjectField>> fieldNameMapByObjectMap = new Map<String, Map<String, Schema.SObjectField>>();
    public static Map<String, Schema.SObjectField> getFieldsMap(Schema.DescribeSObjectResult objectType) {
        if (fieldNameMapByObjectMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            fieldNameMapByObjectMap.put(String.valueOf(objectType.getKeyPrefix()), objectType.fields.getMap());
        }
        
        return fieldNameMapByObjectMap.get(String.valueOf(objectType.getKeyPrefix()));
    }

    public static Map<String, Schema.SObjectField> getFieldsMap(Schema.SObjectType objectType) {
        if (fieldNameMapByObjectMap.get(String.valueOf(objectType)) == null) {
            fieldNameMapByObjectMap.put(String.valueOf(objectType), objectType.getDescribe().fields.getMap());
        }
        
        return fieldNameMapByObjectMap.get(String.valueOf(objectType));
    }
    
    /**
    * @description Retrieve a Map of fields for a given sObject
    * @param sObject the object
    * @return A Map of fieldnames to SObjectField
    */ 
    public static Map<String, Schema.SObjectField> getFieldsMapBySObject(sObject sObj) {
        //return getFieldsMap(sObj.getSObjectType().getDescribe());
        return getFieldsMap(sObj.getSObjectType());
    }
    
    /**
    * @description Retrieve a Map of RecordType Names for a given SObjectType
    * @param objectType SObjectType to retrieve record types for
    * @return A Map of RecordType labels to RecordTypeInfo
    */ 
    private static Map<String, Map<String, Schema.RecordTypeInfo>> recordTypeInfosByObjectMap = new Map<String, Map<String, Schema.RecordTypeInfo>>();
    public static Map<String, Schema.RecordTypeInfo> getRecordTypeInfosByName(Schema.DescribeSObjectResult objectType) {
        if (recordTypeInfosByObjectMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            recordTypeInfosByObjectMap.put(String.valueOf(objectType.getKeyPrefix()), objectType.getRecordTypeInfosByName());        
        }
        return recordTypeInfosByObjectMap.get(String.valueOf(objectType.getKeyPrefix()));
    }
    
    /**
    * @description Retrieve a Map of RecordType Names for a given SObjectType
    * @param objectType SObjectType to retrieve record types for
    * @return A Map of RecordType developer names to RecordType
    */ 
    private static Map<String, Map<String, RecordType>> recordTypesByDeveloperNameMap = new Map<String, Map<String, RecordType>>();
    public static Map<String, RecordType> getRecordTypesByDeveloperName(Schema.DescribeSObjectResult objectType) {
        
        if (recordTypesByDeveloperNameMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            RecordType[] rts = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = :objectType.getName() AND IsActive = TRUE];
            Map<String, RecordType> rtMap = new Map<String, RecordType>();
            for(RecordType rt : rts) {
                rtMap.put(rt.DeveloperName, rt);
            }
            recordTypesByDeveloperNameMap.put(String.valueOf(objectType.getKeyPrefix()), rtMap);        
        }
        return recordTypesByDeveloperNameMap.get(String.valueOf(objectType.getKeyPrefix()));
    }
    
    //For testing purposes, you can set the Production override by setting this static variable
    public static boolean isProductionOverride = false;
    public static boolean IsProduction() {
        if(isProductionOverride) {
            return true;
        }
        else {
            return ( UserInfo.getOrganizationId() == '00DE0000000IBOaMAO' );
        }
    }
    
     /**
    * @description Retrieve a Map of RecordType Names for a given SObjectType
    * @param objectType SObjectType to retrieve record types for
    * @return A Map of RecordType ids to RecordTypeInfo
    */ 
    private static Map<String, Map<Id, Schema.RecordTypeInfo>> recordTypeInfosByIdObjectMap = new Map<String, Map<Id, Schema.RecordTypeInfo>>();
    public static Map<Id, Schema.RecordTypeInfo> getRecordTypeInfosById(Schema.DescribeSObjectResult objectType) {
        if (recordTypeInfosByIdObjectMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            recordTypeInfosByIdObjectMap.put(String.valueOf(objectType.getKeyPrefix()), objectType.getRecordTypeInfosById());        
        }
        return recordTypeInfosByIdObjectMap.get(String.valueOf(objectType.getKeyPrefix()));
    }
    
    /**
    * @description Meant to populate any sObject within a Map Id->Name
    * @param map String->String (String) Map
    * @param idToNameMap List of sObject
    * @param keyToMap String, value to use as the key
    * @param valueToMap String, value to use as the value for id
    * @return void
    */ 
    public static void addToMap(Map<String, String> idToNameMap, List<SObject> listToMap, String keyToMap, String valueToMap) {
        for(sObject obj : listToMap) {
            idToNameMap.put(String.valueOf(obj.get(keyToMap)), String.valueOf(obj.get(valueToMap)));
        }
    }


    /**
    * @description used to remove a set of fields from a query string, so the fields are not queried
    * @param string to remove the fields from
    * @param fields to be removed
    */
    public static String omitFields(String fields, Set<String> omitFields){
        if(String.isBlank(fields) || fields == null) return '';

        if(omitFields == null || omitFields.isEmpty()) return fields;
        fields = fields.replace(' ','');

        for(String field: omitFields){
            if(fields.containsIgnoreCase(',' + field)){
                fields = fields.replace(',' + field,'');
            }else if(fields.containsIgnoreCase(field + ',')){
                fields = fields.replace(field + ',','');              
            }else if(fields.containsIgnoreCase(', ' + field)){
                fields = fields.replace(', ' + field,'');
            }else if(fields.containsIgnoreCase(field + ', ')){
                fields = fields.replace(field + ', ','');
            }
        }
        return fields.trim();
    }


    /**
    * @description given a string it will produce a nice formatted number, if is decimal assumes 2 decimal places
    * @param string value of a number, either integer or decimal
    * @return nicely formatted number with ","
    */ 
    public static String formatNumber(String num){
        if(String.isBlank(num)) return '';

        String numFormatted = '';
        Integer len = num.length();
        Boolean containsDecimal = num.indexOf('.') > -1;
        if(len <= 6 && containsDecimal){//123.56
            numFormatted = num;
        }else if(len > 6 && containsDecimal){//1234.67
            numFormatted = formatNumber(num.substring(0, len-6)) + ',' + num.substring( len - 6,len);
        }else if(len > 3 && !containsDecimal){//1234567
            numFormatted = formatNumber(num.substring(0, len-3)) + ',' + num.substring( len - 3,len);
        }else{//123
            numFormatted = num;
        }
        return numFormatted;
    }

    // commented because no reference found
    // public static Database.SaveResult[] forcedInsert(SObject[] o) {
    //     Database.SaveResult[] result;
    //     while (result == null) { 
    //         try { 
    //             result = Database.insert(o);             
                
    //         } catch (DmlException e) {
    //             if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
    //                 throw e;
    //             }
    //         }
    //     }
    //     return result;
    // }

    public static Database.SaveResult[] forcedInsert(SObject[] o) {
        Database.SaveResult[] result;
        while (result == null) { 
            try { 
                result = Database.insert(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    /**
     * updateLogErrors executes Database.update and writes errors to the debug log
     * @param  records   records to be updated
     * @param  allOrNone specifies whether the operation allows partial success
     */
    public static void updateLogErrors(SObject[] records, Boolean allOrNone)
    {
        Helper.logErrors(Database.update(records, allOrNone));
    }

    /**
     * insertLogErrors executes Database.insert and writes errors to the debug log
     * @param  records   records to be inserted
     * @param  allOrNone specifies whether the operation allows partial success
     */
    public static void insertLogErrors(SObject[] records, Boolean allOrNone)
    {
        Helper.logErrors(Database.insert(records, allOrNone));
    }

    /**
     * logErrors logs the errors from Database.saveResult
     * @param  results save results from Update/Insert
     */
    public static void logErrors(List<Database.SaveResult> results)
    {
        for(Database.SaveResult sr: results)
        {
            if(!sr.isSuccess())
            {
                String msg = String.isBlank(sr.getId()) ? '' : sr.getId() + ': ';
                System.debug(LoggingLevel.ERROR, msg + String.join(sr.getErrors(),';'));
            }
        }
    }

    public static String urlEncode(String stringValue)
    {
        String returnString = '';
        if(String.isBlank(stringValue)) return returnString;
        return EncodingUtil.urlEncode(String.valueOf(stringValue),'UTF-8');
    }
    
    public static String urlDecode(String stringValue)
    {
        String returnString = '';
        if(String.isBlank(stringValue)) return returnString;
        return EncodingUtil.urlDecode(String.valueOf(stringValue), 'UTF-8');
    }

    public static String base64Encode(String stringValue)
    {
        String returnString = '';
        if(String.isBlank(stringValue)) return returnString;
        return EncodingUtil.base64Encode(Blob.valueOf(stringValue));
    }

    public static Date getDate(Datetime dt)
    {
        return Date.newInstance(dt.year(), dt.month(), dt.day());
    }

    /**
     * @description generates a cron expression
     * @param  min         minute job should run, Integer between 0 - 59, defaults to 0
     * @param  hour        hour job should run, Integer between 0-59, defaults to every hour  ('*')
     * @param  dayOfMonth  day of month job should run, Integer between 1-31, defaults to everyday ('*')
     * @param  month       month job should run, Integer between 1-12, defaults to every month ('*')
     * @param  dayOfWeek   day of the week job should run, 1-7 where 1 = Sunday, SUN-SAT, 7#2 = 2nd Saturday of the month, 6L = Last Friday of the month
	 * 						if you do anything other then 1-7, you must set dayOfMonth defaults to ?
     * @return             a string of the cron expression
     */
    public static String getCronExpression(Integer min, Integer hour, String dayOfMonth, Integer month, String dayOfWeek)
    {
        //default seconds to zero
        String cronExp = '0 '; 
        //default to run on the hour
        cronExp = min == null ? cronExp + '0 ' : cronExp + min + ' ';
        //default to run every hour
        cronExp = hour == null ? cronExp + '* ' : cronExp + hour + ' '; 
        //default to run everyday
        cronExp = String.isBlank(dayOfMonth) ? cronExp + '* ' : cronExp + dayOfMonth + ' ';
        //default to run every month
        cronExp = month == null ? cronExp + '* ' : cronExp + month + ' ';
        //default to unset
        cronExp = String.isBlank(dayOfWeek) ? cronExp + '?' : cronExp + dayOfWeek;

        return cronExp;
    }

    public static Map<String, String> createObjectMap(String obj)
    {
        Map<String, String> attributeMap = new Map<String, String>();
        for(String str: obj.split(','))
        {
            List<String> keyValue = str.contains('=') ? str.split('=') : str.split(':');
            String key = keyValue[0].replace('=', '').replace('{', '').replace('}','').replace('"','').trim();
            String value = keyValue.size() > 1 ? keyValue[1].replace('=', '').replace('{', '').replace('}','').replace('"','').trim() : '';
            attributeMap.put(key, value);
        }

        return attributeMap;
    }

    /**
    * @description consumes objects that are not identified in parsing
    * @param parser - the parser to consume the object from
    */
    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == System.JSONToken.END_OBJECT ||
                curr == System.JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }

    /**
    * @description ensures day of month does not exceed days in month
    * @param month - month to be validating
    * @param day - day of month
    * @param year - year that month resides in (leap year)
    * @return either day or last day of the given month
    */
    public static Integer checkEndOfMonth(Integer year, Integer month, Integer day)
    {
        System.debug(year +'-' + month + '-' + day);
        Date dt = Date.newInstance(year, month, day);
        if(dt.month() != month)
        {
            return Date.daysInMonth(year, month);
        }

        return day;
    }

    /**
    * @description returns milliseconds based on date and time attributes provided
    *   if all parameters are null returns System.now().getTime()
    * @param dt - Date - if null uses today
    * @param hour - hour part of time if null uses 0
    * @param minute - minute part of time if null uses 0
    * @param seconds - seconds part of time if null uses 0
    * @return Long value of the milliseconds
    */
    public static Long getTimeByDate(Date dt, Integer hour, Integer minute, Integer seconds)
    {
        if(dt == null
            && hour == null
            && minute == null
            && seconds == null)
        {
            return System.now().getTime();
        }

        //if dt is null use today
        dt = dt == null ? System.today() : dt;

        //if hour is null set to 0
        hour = hour == null ? 0 : hour;

        //if minute is null set to 0
        minute = minute == null ? 0 : minute;

        //if seconds is null set to 0
        seconds = seconds == null ? 0 : seconds;

        return Datetime.newInstance(dt.year(), dt.month(), dt.day(), hour, minute, seconds).getTime();
    }


    /**
    * @description determine if user is a partner user
    * @return true if they are a partner user
    */
    public static Boolean isPartnerUser()
    {
        return UserInfo.getUserType().containsIgnoreCase('Partner');
    }

    /**
     * @description cast String to data type value
     * @param dataType - the data type the value should be cast to
     * @param strValue - value as a string
     * @return value as its appropriate datatype
     */
    public static Object setValue(String datatype, String strValue)
    {
        Object value;
        if(String.isBlank(datatype)
            || datatype.equalsIgnoreCase('String')
            || String.isBlank(strValue))
        {
            value = strValue;
        }
        else if(datatype.equalsIgnoreCase('Integer'))
        {
            value = Integer.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('Decimal'))
        {
            value = Decimal.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('Date'))
        {
            value = Date.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('DateTime'))
        {
            value = DateTime.valueOf(strValue);
        }

        return value;
    }

    /**
     * formatDateTimeSOQL applies formatting for DateTime field for soql
     * @param  dt DateTime to be formatted
     * @return    a string in format needed for soql
     * @created December 2019
     */
    public static String formatDateTimeSOQL(DateTime dt)
    {
        return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }
    
    
    public static Date AddBusinessDays(Date startDate, Integer businessDaysToAdd ){
        
        //Add or decrease business days
        Date finalDate = startDate;
        Integer direction = businessDaysToAdd < 0 ? -1 : 1;
        while(businessDaysToAdd != 0){            
            finalDate = finalDate.addDays(direction);            
            if (!IsWeekend(finalDate))                
            {                
                businessDaysToAdd -= direction;                
            }            
        }  
        return finalDate;        
    }
    
    //Check if a date is a weekend day
    public static Boolean IsWeekend(Date myDate){
        
        String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');        
        return 'Sat'.equals(myDateString) || 'Sun'.equals(myDateString);        
    }

    //Method that subtracts calendar days from a given date but makes sure the result doesn't fall on a weekend.
    //If the new date falls on a saturday, it returns the Friday before.  If the new date falls on a Sunday, it 
    //returns the Monday following.
    public static Date getCalendarDaysNoWeekend(Date startDate, Integer calendarDaysToGoBack) {
   
        Integer offset = 0;

        Date newDate = startDate - calendarDaysToGoBack;
        Datetime dt = DateTime.newInstance(newDate, Time.newInstance(12, 0, 0, 0));             //Modified for HRP-17095
        String dayOfWeek = dt.format('E');

        if(dayOfWeek == 'Sat')
        {
            offset = -1;
        }
        else if(dayOfWeek == 'Sun')
        {
            offset = 1;
        }
        return newDate + offset;
    }
    /**
     * getSameDayOfNextYear add a year to a date and adjusts so that it falls on the same day
     * @param   dt DateTime that we are adding one year to
     * @return  a new date which is one year from dt
     * @created July 2021
     */
    Public static DateTime getSameDayOfNextYear(Date incomingDate){
        
        Datetime dateNextYear;
        DateTime dt = DateTime.newInstance(incomingDate, Time.newInstance(12, 0, 0, 0));        //Modified for HRP-17095

        String dayOfWeek = dt.format('EEEE');
        DateTime newDate = dt.addYears(1);
        String nextYearDayOfWeek = newDate.format('EEEE');                                      //Modified for HRP-17095
       
        If(dayOfWeek != nextYearDayOfWeek){                                                     //Added for HRP-17095
            for(Integer i=1; i<=7; i++){
                DateTime newDates = newDate.addDays(-i);
                String newDayOfWeek = newDates.format('EEEE');
                if(dayOfWeek == newDayOfWeek){
                    dateNextYear = newDates;
                    break;
                }   
            }
        } else {                                                                                //Start: Added for HRP-17095
            dateNextYear = newDate;
        }                                                                                       //End: Added for HRP-17095
        return dateNextYear;
    }

    /** HRP-12706 --> Starts Here
     * getSameDayOfPrevYear subtract a year to a date and adjusts so that it falls on the same day
     * @param   dt DateTime that we are subtracting one year from
     * @return  a new date which is one year to dt
     * @created August 2024
     */
    
     public static DateTime getSameDayOfPrevYear(Date incomingDate) {
        
        Datetime datePrevYear;
        DateTime dt = DateTime.newInstance(incomingDate, Time.newInstance(12, 0, 0, 0));        //Modified for HRP-17095

        String dayOfWeek = dt.format('EEEE');
        DateTime newDate = dt.addYears(-1);
        String prevYearDayOfWeek = newDate.format('EEEE');                                      //Modified for HRP-17095
       
        If(dayOfWeek != prevYearDayOfWeek){                                                     //Added for HRP-17095
            for(Integer i=1; i<=7; i++) {
                DateTime newDates = newDate.addDays(i);
                String newDayOfWeek = newDates.format('EEEE');
                if(dayOfWeek == newDayOfWeek) {
                    datePrevYear = newDates;
                    break;
                }   
            }
        } else {                                                                                //Start: Added for HRP-17095
            datePrevYear = newDate;
        }                                                                                       //End: Added for HRP-17095
        return datePrevYear;
    }
    
    public static string getStartEndTimeLabelText(String incomingTimeValue){
        
        string result;
        
        switch on (incomingTimeValue) {
            
            when '0000' {
                result = '12:00 AM';
            }
            when '0015' {
                result = '12:15 AM';
            }
            when '0030' {
                result = '12:30 AM';
            }
            when '0045' {
                result = '12:45 AM';
            }
            when '0100' {
                result = '1:00 AM';
            }
            when '0115' {
                result = '1:15 AM';
            }
            when '0130' {
                result = '1:30 AM';
            }
            when '0145' {
                result = '1:45 AM';
            }
            when '0200' {
                result = '2:00 AM';
            }
            when '0215' {
                result = '2:15 AM';
            }
            when '0230' {
                result = '2:30 AM';
            }
            when '0245' {
                result = '2:45 AM';
            }
            when '0300' {
                result = '3:00 AM';
            }
            when '0315' {
                result = '3:15 AM';
            }
            when '0330' {
                result = '3:30 AM';
            }
            when '0345' {
                result = '3:45 AM';
            }
            when '0400' {
                result = '4:00 AM';
            }
            when '0415' {
                result = '4:15 AM';
            }
            when '0430' {
                result = '4:30 AM';
            }
            when '0445' {
                result = '4:45 AM';
            }
            when '0500' {
                result = '5:00 AM';
            }
            when '0515' {
                result = '5:15 AM';
            }
            when '0530' {
                result = '5:30 AM';
            }
            when '0545' {
                result = '5:45 AM';
            }
            when '0600' {
                result = '6:00 AM';
            }
            when '0615' {
                result = '6:15 AM';
            }
            when '0630' {
                result = '6:30 AM';
            }
            when '0645' {
                result = '6:45 AM';
            }
            when '0700' {
                result = '7:00 AM';
            }
            when '0715' {
                result = '7:15 AM';
            }
            when '0730' {
                result = '7:30 AM';
            }
            when '0745' {
                result = '7:45 AM';
            }
            when '0800' {
                result = '8:00 AM';
            }
            when '0815' {
                result = '8:15 AM';
            }
            when '0830' {
                result = '8:30 AM';
            }
            when '0845' {
                result = '8:45 AM';
            }
            when '0900' {
                result = '9:00 AM';
            }
            when '0915' {
                result = '9:15 AM';
            }
            when '0930' {
                result = '9:30 AM';
            }
            when '0945' {
                result = '9:45 AM';
            }
            when '1000' {
                result = '10:00 AM';
            }
            when '1015' {
                result = '10:15 AM';
            }
            when '1030' {
                result = '10:30 AM';
            }
            when '1045' {
                result = '10:45 AM';
            }
            when '1100' {
                result = '11:00 AM';
            }
            when '1115' {
                result = '11:15 AM';
            }
            when '1130' {
                result = '11:30 AM';
            }
            when '1145' {
                result = '11:45 AM';
            }
            when '1200' {
                result = '12:00 PM';
            }
            when '1215' {
                result = '12:15 PM';
            }
            when '1230' {
                result = '12:30 PM';
            }
            when '1245' {
                result = '12:45 PM';
            }
            when '1300' {
                result = '1:00 PM';
            }
            when '1315' {
                result = '1:15 PM';
            }
            when '1330' {
                result = '1:30 PM';
            }
            when '1345' {
                result = '1:45 PM';
            }
            when '1400' {
                result = '2:00 PM';
            }
            when '1415' {
                result = '2:15 PM';
            }
            when '1430' {
                result = '2:30 PM';
            }
            when '1445' {
                result = '2:45 PM';
            }
            when '1500' {
                result = '3:00 PM';
            }
            when '1515' {
                result = '3:15 PM';
            }
            when '1530' {
                result = '3:30 PM';
            }
            when '1545' {
                result = '3:45 PM';
            }
            when '1600' {
                result = '4:00 PM';
            }
            when '1615' {
                result = '4:15 PM';
            }
            when '1630' {
                result = '4:30 PM';
            }
            when '1645' {
                result = '4:45 PM';
            }
            when '1700' {
                result = '5:00 PM';
            }
            when '1715' {
                result = '5:15 PM';
            }
            when '1730' {
                result = '5:30 PM';
            }
            when '1745' {
                result = '5:45 PM';
            }
            when '1800' {
                result = '6:00 PM';
            }
            when '1815' {
                result = '6:15 PM';
            }
            when '1830' {
                result = '6:30 PM';
            }
            when '1845' {
                result = '6:45 PM';
            }
            when '1900' {
                result = '7:00 PM';
            }
            when '1915' {
                result = '7:15 PM';
            }
            when '1930' {
                result = '7:30 PM';
            }
            when '1945' {
                result = '7:45 PM';
            }
            when '2000' {
                result = '8:00 PM';
            }
            when '2015' {
                result = '8:15 PM';
            }
            when '2030' {
                result = '8:30 PM';
            }
            when '2045' {
                result = '8:45 PM';
            }
            when '2100' {
                result = '9:00 PM';
            }
            when '2115' {
                result = '9:15 PM';
            }
            when '2130' {
                result = '9:30 PM';
            }
            when '2145' {
                result = '9:45 PM';
            }
            when '2200' {
                result = '10:00 PM';
            }
            when '2215' {
                result = '10:15 PM';
            }
            when '2230' {
                result = '10:30 PM';
            }
            when '2245' {
                result = '10:45 PM';
            }
            when '2300' {
                result = '11:00 PM';
            }
            when '2315' {
                result = '11:15 PM';
            }
            when '2330' {
                result = '11:30 PM';
            }
            when '2345' {
                result = '11:45 PM';
            }
        }
        return result;
    }
    
    /*Start HRP-10179 
    As part of HRP-10179 moved this sendEmail method from ResourceUserAllocationBatch to this helper class so it can be re-used from other areas.
    params:
		toAddress:  	A list of email addresses that the caller should get from a system label
		orgWideEmailId: If this is null, the "From" in the email will show the email address of the user who initiated the email
                        If this is not null, "From" in the email will show the appropriate org wide email address
    	addNoReplyMsg:  If flag is true, we add a "please don't reply" message to the top of the email body
    */
    @TestVisible
    public static void sendEmail(Map<Exception,String> common_exception_map, Map<Id, String> dml_error_map, 
                           List<string> toAddress, string orgWideEmailId, boolean addNoReplyMsg, String subject){
        try{
            if((dml_error_map!= null && dml_error_map.size() > 0) || (common_exception_map != null && common_exception_map.size() > 0)){
                //String emailBody = '<html><table><thead><tr><th>Error Details</th><th>Record Id</th></tr></thead><tbody>';
                String emailBody = '<html><table><thead>';
                if(addNoReplyMsg){
                    emailBody = emailBody + '<tr><th>This is a sytem generated email, please do not reply</th></tr>';
                }
                emailBody = emailBody + '<tr><th>Error Details</th><th>Record Id</th></tr></thead><tbody>';
                    
                if(dml_error_map.size() > 0){
                    for(Id recordId : dml_error_map.keySet()){
                        emailBody = emailBody + dml_error_map.get(recordId)+ '</td><td>'+recordId;
                    }
                }
                if(common_exception_map.size() > 0){
                    for(Exception exr : common_exception_map.keySet()){
                        System.debug(exr.getLineNumber() + ': ' + exr.getMessage());
                        emailBody = emailBody + '<tr><td>'+exr.getMessage()+' Stacktress: '+exr.getStackTraceString()+exr.getLineNumber()+'</td><td>'+common_exception_map.get(exr)+'</td></tr>';
                    }
                }
                System.debug('emailBody : '+emailBody);
                emailBody = emailBody + '</tbody></table></html>';
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                //List<String> emailIds = System.label.BSF_SUPPORT_EMAIL_ID.split(',');
                if(!string.isEmpty(orgWideEmailId)) {
                	message.setOrgWideEmailAddressId(orgWideEmailId);
                }
                message.toAddresses = toAddress;
                message.optOutPolicy = 'FILTER';
                message.subject = subject;
                message.setHtmlBody(emailBody);
                Messaging.SingleEmailMessage[] messages =  new List<Messaging.SingleEmailMessage> {message};
                String notificationkey = BSF_Constants.taskSubjectKeyMap.get('Error in CB Drive Creation');
                BSF_EmailNotification.sendEmails(messages,notificationkey, NULL);
            }
        }catch(Exception expm){}
    }
    //End HRP-10179
}