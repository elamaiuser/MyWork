public class skedUtils {
    
    public static void concactString(List<string> targetList, string sourceStr) {
        if (!String.isBlank(sourceStr)) {
            concactSetString(targetList, new Set<string> {sourceStr});
        }
    }
    
    public static void concactSetString(List<string> targetList, Set<string> sourceList) {
        if (sourceList != null && !sourceList.isEmpty()) {
            for(String sourceStr : sourceList) {
                string lowerCaseValue = sourceStr.toLowerCase();
                if (!targetList.contains(lowerCaseValue) && !String.isBlank(lowerCaseValue)) {
                    targetList.add(lowerCaseValue);
                }
            }
        }
    }
    
    public static string addNewItemToMultiPicklist(string picklistValue, string newValue) {
        List<string> values = new List<string>();
        if (!string.isBlank(picklistValue)) {
            values = picklistValue.split(';');
        }
        if (!values.contains(newValue)) {
            values.add(newValue);
        }
        return string.join(values, ';');
    }

    public static string removeItemFromMultiPicklist(string picklistValue, string itemToRemove) {
        List<string> values = new List<string>();
        if (!string.isBlank(picklistValue)) {
            values = picklistValue.split(';');
        }

        Integer foundIndex = values.indexOf(itemToRemove);
        if (foundIndex != -1) {
            values.remove(foundIndex);
        }
        return string.join(values, ';');
    }
    
    public static object getFieldValue(string input, string fieldType) {
        object result;
        if (fieldType == 'date') {
            result = Json.deserialize('"' + input + '"', Date.class);
        }
        else if (fieldType == 'datetime') {
            result = Json.deserialize('"' + input + '"', DateTime.class);
        }
        else if (fieldType == 'time') {
            result = Json.deserialize('"' + input + '"', Time.class);
        }
        else if (fieldType == 'boolean') {
            boolean booleanValue = boolean.valueOf(input);
            result = boolean.valueOf(input);
        }
        else if (fieldType == 'double') {
            result = Json.deserialize(input, Decimal.class);
        }
        else if (fieldType == 'percent') {
            String modifiedInput = input.replace('%', '');
            result = Json.deserialize(modifiedInput, Decimal.class);
        }
        else {
            result = input;
        }
        
        return result;
    }
    
    public static string formatFieldValue(string input, string fieldType) {
        string result = '';
        if (input != NULL && input != 'null') {
            result = input;
            if (fieldType == 'date') {
                input = input.substring(0, 10);
                Date dateValue = skedDateTimeUtils.getDateFromIsoString(input);
                DateTime dtValue = DateTime.newInstance(dateValue, Time.newInstance(0, 0, 0, 0));
                result = dtValue.format(skedDateTimeUtils.DATE_FORMAT);
            }
            if (fieldType == 'datetime') {
                DateTime dtValue = skedDateTimeUtils.getDateTimeFromIsoString(input);
                result = dtValue.format(skedDateTimeUtils.DATE_TIME_FORMAT);
            }
            if (fieldType == 'time') {
                string[] timeParts = input.split(':');
                integer hour = integer.valueOf(timeParts[0]);
                integer minute = integer.valueOf(timeParts[1]);
                string period = hour < 12 ? 'AM' : 'PM';
                if (hour > 12) {
                    hour = hour - 12;
                }
                result = skedUtils.padLeft(string.valueOf(hour), '0', 2) + ':' + skedUtils.padLeft(string.valueOf(minute), '0', 2) + ' ' + period;
            }
            if (fieldType == 'boolean') {
                boolean booleanValue = boolean.valueOf(input);
                result = booleanValue ? 'Checked' : 'Unchecked';
            }
            if (fieldType == 'double') {
                result = string.valueOf(Decimal.valueOf(input).setScale(2));
            }
        }
        
        return result;
    }
    
    public static string combineAddress(string street1, string street2, string street3, string city, string state, string postalCode, string country) {
        string street = street1;
        if (!string.isBlank(street2)) {
            street += ' ' + street2;
        }
        if (!string.isBlank(street3)) {
            street += ' ' + street3;
        }
        return combineAddress(street, city, state, postalCode, country);
    }

    public static string combineAddress(string street, string city, string state, string postalCode, string country) {
        string address = street;
        if (!string.isBlank(city)) {
            address += ', ' + city;
        }
        if (!string.isBlank(state)) {
            address += ', ' + state;
        }
        if (!string.isBlank(postalCode)) {
            address += ' ' + postalCode;
        }
        if (!string.isBlank(country)) {
            address += ', ' + country;
        }
        return address;
    }

    public static List<string> convertSetToList(Set<Id> inputIds) {
        List<string> results = new List<string>();
        for (Id inputId : inputIds) {
            results.add(inputId);
        }
        return results;
    }

    public static Set<string> getFieldNameFromTemplate(string template) {
        Set<string> filedsWithHierarchy = new Set<string>();
        string extractedFields = extractTemplateToFieldString(template);
        for (string item : extractedFields.split(',')) {
            filedsWithHierarchy.add(item);
        }

        return filedsWithHierarchy;
    }

    public static Set<string> getSiteNamesFromTemplate(string template) {
        Set<string> siteNames = new Set<string>();
        string siteNamestring = extractSiteNamesFromTemplate(template);
        for (string item : siteNamestring.split(',')) {
            siteNames.add(item);
        }

        return siteNames;
    }

    public static Set<Id> getIdsFromList(List<sObject> records) {
        Set<Id> results = new Set<Id>();
        for (sObject record : records) {
            string recordId = string.valueOf(record.get('Id'));
            results.add(recordId);
        }
        return results;
    }

    public static Set<Id> getIdsFromList(List<skedModels.modelBase> models) {
        Set<Id> results = new Set<Id>();
        for (skedModels.modelBase model : models) {
            results.add(model.id);
        }
        return results;
    }

    public static string padLeft(string input, string character, integer length) {
        if (input.length() < length) {
            while (input.length() < length) {
                input = character + input;
            }
        }
        return input;
    }
    
    //TODO: move to commonService
    public static List<skedModels.jobStatusSetting> getJobStatusSettings() {
        List<skedModels.jobStatusSetting> result = new List<skedModels.jobStatusSetting>();

        skedModels.jobStatusSetting queuedSetting = new skedModels.jobStatusSetting();
        queuedSetting.jobStatus = skedConstants.JOB_STATUS_QUEUED;
        queuedSetting.backgroundColor = '#c9cacc';
        queuedSetting.textColor = '#fff';
        result.add(queuedSetting);

        skedModels.jobStatusSetting pendingAllocationSetting = new skedModels.jobStatusSetting();
        pendingAllocationSetting.jobStatus = skedConstants.JOB_STATUS_PENDING_ALLOCATION;
        pendingAllocationSetting.backgroundColor = '#787878';
        pendingAllocationSetting.textColor = '#fff';
        result.add(pendingAllocationSetting);

        skedModels.jobStatusSetting pendingDispatchSetting = new skedModels.jobStatusSetting();
        pendingDispatchSetting.jobStatus = skedConstants.JOB_STATUS_PENDING_DISPATCH;
        pendingDispatchSetting.backgroundColor = '#faa928';
        pendingDispatchSetting.textColor = '#fff';
        result.add(pendingDispatchSetting);

        skedModels.jobStatusSetting dispatchedSetting = new skedModels.jobStatusSetting();
        dispatchedSetting.jobStatus = skedConstants.JOB_STATUS_DISPATCHED;
        dispatchedSetting.backgroundColor = '#74b1d4';
        dispatchedSetting.textColor = '#fff';
        result.add(dispatchedSetting);

        skedModels.jobStatusSetting readySetting = new skedModels.jobStatusSetting();
        readySetting.jobStatus = skedConstants.JOB_STATUS_READY;
        readySetting.backgroundColor = '#286091';
        readySetting.textColor = '#fff';
        result.add(readySetting);

        skedModels.jobStatusSetting enRouteSetting = new skedModels.jobStatusSetting();
        enRouteSetting.jobStatus = skedConstants.JOB_STATUS_EN_ROUTE;
        enRouteSetting.backgroundColor = '#bc8ebe';
        enRouteSetting.textColor = '#fff';
        result.add(enRouteSetting);

        skedModels.jobStatusSetting onSiteSetting = new skedModels.jobStatusSetting();
        onSiteSetting.jobStatus = skedConstants.JOB_STATUS_ON_SITE;
        onSiteSetting.backgroundColor = '#944292';
        onSiteSetting.textColor = '#fff';
        result.add(onSiteSetting);

        skedModels.jobStatusSetting inProgressSetting = new skedModels.jobStatusSetting();
        inProgressSetting.jobStatus = skedConstants.JOB_STATUS_IN_PROGRESS;
        inProgressSetting.backgroundColor = '#620c5f';
        inProgressSetting.textColor = '#fff';
        result.add(inProgressSetting);

        skedModels.jobStatusSetting completeSetting = new skedModels.jobStatusSetting();
        completeSetting.jobStatus = skedConstants.JOB_STATUS_COMPLETE;
        completeSetting.backgroundColor = '#19cf5e';
        completeSetting.textColor = '#fff';
        result.add(completeSetting);

        skedModels.jobStatusSetting cancelledSetting = new skedModels.jobStatusSetting();
        cancelledSetting.jobStatus = skedConstants.JOB_STATUS_CANCELLED;
        cancelledSetting.backgroundColor = '#df4040';
        cancelledSetting.textColor = '#fff';
        result.add(cancelledSetting);

        return result;
    }
    
    public static Map<string, integer> getMapWeekdayIndex() {
        return getMapWeekdayIndex('sun');
    }

    public static Map<string, integer> getMapWeekdayIndex(string firstDayOfWeek) {
        Map<string, integer> mapWeekdayIndex = new Map<string, integer>();
        mapWeekdayIndex.put('sun', 0);
        mapWeekdayIndex.put('mon', 1);
        mapWeekdayIndex.put('tue', 2);
        mapWeekdayIndex.put('wed', 3);
        mapWeekdayIndex.put('thu', 4);
        mapWeekdayIndex.put('fri', 5);
        mapWeekdayIndex.put('sat', 6);
        
        integer currentFirstDayIndex = mapWeekdayIndex.get(firstDayOfWeek);
        integer difference = mapWeekdayIndex.size() - currentFirstDayIndex;
        for (string weekday : mapWeekdayIndex.keySet()) {
            integer index = mapWeekdayIndex.get(weekday);
            index = Math.mod(index + difference, mapWeekdayIndex.size());
            mapWeekdayIndex.put(weekday, index);
        }
        
        return mapWeekdayIndex;
    }

    public static Map<string, string> getMapRoleToPremiumOpPay() {
        Map<string, string> mapRoleToPremiumOpPay = new Map<string, string>();
        mapRoleToPremiumOpPay.put('2RBC', '2RBC');
        mapRoleToPremiumOpPay.put('2RBC Sign-off', '2RBC');
        mapRoleToPremiumOpPay.put('Apheresis Charge', 'Charge');
        mapRoleToPremiumOpPay.put('Charge', 'Charge');
        mapRoleToPremiumOpPay.put('Charge - 2RBC', 'Charge');
        mapRoleToPremiumOpPay.put('Charge - Special Collections', 'Charge');
        mapRoleToPremiumOpPay.put('Charge Mentor', 'Charge');
        mapRoleToPremiumOpPay.put('Drive Lead', 'Charge');
        mapRoleToPremiumOpPay.put('Licensed Nurse', 'Charge');
        mapRoleToPremiumOpPay.put('Special Collections Charge', 'Charge');
        mapRoleToPremiumOpPay.put('Driver', 'Driver');
        mapRoleToPremiumOpPay.put('Driver - DOT', 'Driver');
        mapRoleToPremiumOpPay.put('Driver CDL A', 'Driver');
        mapRoleToPremiumOpPay.put('Driver CDL B', 'Driver');
        mapRoleToPremiumOpPay.put('Competent Driver', 'OJI');
        mapRoleToPremiumOpPay.put('OJI', 'OJI');
        mapRoleToPremiumOpPay.put('Translator', 'Translator');
        return mapRoleToPremiumOpPay;
    }

    public static Map<String, List<String>> getMapPremiumOpPayToRole() {
        Map<String, List<String>> mapPremiumOpPayToRole = new Map<String, List<String>>();
        mapPremiumOpPayToRole.put('Charge', new List<String>{
            'Apheresis Charge', 'Charge', 'Charge - 2RBC', 'Charge - Special Collections',
            'Charge Mentor', 'Drive Lead', 'Licensed Nurse', 'Special Collections Charge'
        });

        mapPremiumOpPayToRole.put('2RBC', new List<String>{
            '2RBC', '2RBC Sign-off'
        });

        mapPremiumOpPayToRole.put('Driver', new List<String>{
            'Driver', 'Driver - DOT', 'Driver CDL A', 'Driver CDL B'
        });

        mapPremiumOpPayToRole.put('OJI', new List<String>{
            'Competent Driver', 'OJI'
        });

        mapPremiumOpPayToRole.put('Translator', new List<String>{
            'Translator'
        });

        return mapPremiumOpPayToRole;
    }

    public static Set<Id> getParentIds(List<sObject> records, string parentApiName) {
        Set<Id> parentIds = new Set<Id>();
        for (sObject record : records) {
            if (record.get(parentApiName) != null) {
                parentIds.add((Id)record.get(parentApiName));
            }
        }

        return parentIds;
    }

    public static List<skedModels.selectOption> getPickListOptions(string objectApiName, string fieldApiName) {
        List<string> picklistValues = getPickListValues(objectApiName, fieldApiName);

        List<skedModels.selectOption> result = new List<skedModels.selectOption>();
        for (string picklistValue : picklistValues) {
            result.add(new skedModels.selectOption(picklistValue, picklistValue));
        }
        return result;
    }

    public static List<string> getPickListValues(string objectApiName, string fieldApiName) {
        List<string> picklistValues = new List<string>();

        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
        DescribeSObjectResult objDescribe = targetType.getDescribe();
        map<String, SObjectField> mapFields = objDescribe.fields.getmap();
        SObjectField fieldType = mapFields.get(fieldApiName);
        DescribeFieldResult fieldResult = fieldType.getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple) {
            picklistValues.add(f.getValue());
        }
        return picklistValues;
    }

    public static object getSourceFieldValue(sObject record, string apiFieldName) {
        object outputValue;
        if (record != NULL && !string.isBlank(apiFieldName)) {
            string fullApiFieldNamePath = apiFieldName;
            sObject parentObject = record;
            integer parentIndex = fullApiFieldNamePath.indexOf('.');
            
            while (parentIndex != -1) {
                string parentObjectName = fullApiFieldNamePath.subString(0, fullApiFieldNamePath.indexOf('.'));
                parentObject = parentObject.getSObject(parentObjectName);
                
                fullApiFieldNamePath = fullApiFieldNamePath.subString(fullApiFieldNamePath.indexOf('.') + 1, fullApiFieldNamePath.length());
                parentIndex = fullApiFieldNamePath.indexOf('.');
                
                if (parentObject == null) {
                    return null;
                }
            }
            
            outputValue = parentObject.get(fullApiFieldNamePath);
        }
        return outputValue;
    }

    public static Integer getTravelTime(Location location1, Location location2) {
        if (skedSetting.instance.Admin.velocity <= 0) {
            return 0;
        }
        integer travelTime = -1;
        if (location1 == NULL || location2 == NULL) {
            return travelTime;
        }
        double dist = location1.getDistance(location2, skedSetting.instance.Admin.distanceMeasurementUnit);

        travelTime = ((dist / skedSetting.instance.Admin.velocity) * 60).intValue();
        return travelTime;
    }

    public static integer parsePeriod(string periodPattern) {
        List<string> parts = periodPattern.split(' ');
        integer duration = 0;
        for (string part : parts) {
            integer partValue = integer.valueOf(part.subString(0, part.length() - 1));
            if (part.contains('d')) {
                duration += partValue;
            }
            else if (part.contains('w')) {
                duration += partValue * 7;
            }
        }

        return duration;
    }

    private static Long keyCount = 0;
    public static string getKey() {
        keyCount++;
        Long currentTick = system.now().getTime();
        return skedConstants.TEMPORARY_ID_PREFIX + String.valueOf(currentTick) + keyCount;
    }

    public static Date getMinFromDates(List<Date> inputDates) {
        Date minDate = NULL;
        for (Date inputDate : inputDates) {
            if (minDate == NULL || (inputDate != NULL && inputDate < minDate)) {
                minDate = inputDate;
            }
        }
        return minDate;
    }

    public static Date getMaxFromDates(List<Date> inputDates) {
        Date maxDate = NULL;
        for (Date inputDate : inputDates) {
            if (maxDate == NULL || (inputDate != NULL && inputDate > maxDate)) {
                maxDate = inputDate;
            }
        }
        return maxDate;
    }

    public static void scheduleUniqueJobInSeconds(string schedulableClassName, Schedulable schedulableInstance, Integer seconds, Boolean isUnique) {
        String jobSearchText = '%' + schedulableClassName + '%'; 
        List<CronTrigger> runningScheduleQuery = [SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :jobSearchText AND (State = 'EXECUTING' OR State = 'WAITING')
        ];
        if (runningScheduleQuery.isEmpty() || !isUnique) {
            Datetime nextFireTime = Datetime.now().addSeconds(seconds);
            Decimal ss = nextFireTime.second();
            Decimal min = nextFireTime.minute();
            Decimal hour = nextFireTime.hour();
            string dayOfMonth = String.valueOf(nextFireTime.day());
            string month = String.valueOf(nextFireTime.month());
            string year = String.valueOf(nextFireTime.year());
            //parse to cron expression
            String nextFireTimeCronExpression = String.valueOf(ss) + ' ' + String.valueOf(min) + ' ' + String.valueOf(hour) + ' ' + dayOfMonth + ' ' +  month +' ? ' + year + '-' + year;
            System.schedule(schedulableClassName + '_' + String.valueOf(nextFireTime.getTime()), nextFireTimeCronExpression, schedulableInstance);
        }
    }

    public static void createDefaultTravelTimeSlots(Set<Id> collectionOpIds) {
        if (collectionOpIds.isEmpty()) {
            return;
        }

        Set<Id> existingTravelTimeSlotCollectionOpIds = new Set<Id>();
        for (AggregateResult ar : [SELECT sked_Collection_Operation__c FROM sked_Travel_Time_Slot__c WHERE sked_Collection_Operation__c IN :collectionOpIds GROUP BY sked_Collection_Operation__c]) {
            existingTravelTimeSlotCollectionOpIds.add((Id)ar.get('sked_Collection_Operation__c'));
        }

        List<sked_Travel_Time_Slot__c> travelTimeSlotsToInsert = new List<sked_Travel_Time_Slot__c>();

        for (Id collectionOpId : collectionOpIds) {
            if (!existingTravelTimeSlotCollectionOpIds.contains(collectionOpId)) {
                for (String weekday : WEEKDAYS) {
                    for (SlotTemplate slot : DEFAULT_SLOTS) {
                        sked_Travel_Time_Slot__c travelTimeSlot = new sked_Travel_Time_Slot__c();
                        travelTimeSlot.sked_Collection_Operation__c = collectionOpId;
                        travelTimeSlot.sked_Weekday__c = weekday;
                        travelTimeSlot.Name = slot.label;
                        travelTimeSlot.sked_Start_Time__c = slot.startTime;
                        travelTimeSlot.sked_End_Time__c = slot.endTime;
                        travelTimeSlotsToInsert.add(travelTimeSlot);
                    }
                }                
            }
        }
        if (!travelTimeSlotsToInsert.isEmpty()) {
            insert travelTimeSlotsToInsert;
        }
    }

    /************************************************ Private methods ***********************************************/
    private static string extractTemplateToFieldString(string template) {
        if (!string.isBlank(template)) {
            string field = template.substringBetween('{{','}}');
            if (!String.isBlank(field)) {
                return field + ',' + extractTemplateToFieldString(template.replace('{{' + field + '}}', ''));
            }
            else {
                return '';
            }
        }
        else {
            return '';
        }
    }

    private static string extractSiteNamesFromTemplate(string template) {
        if (!string.isBlank(template)) {
            string siteName = template.substringBetween('!$','$');
            if (!String.isBlank(siteName)) {
                return siteName + ',' + extractSiteNamesFromTemplate(template.replace('!$' + siteName + '$', ''));
            }
            else {
                return '';
            }
        }
        else {
            return '';
        }
    }
    
    // Define the default Travel Time slots structure for new Collection Operations
    private static final List<SlotTemplate> DEFAULT_SLOTS = new List<SlotTemplate>{
        new SlotTemplate('Morning', 0, 800),    // 00:00 to 08:00
        new SlotTemplate('Day', 800, 1600),     // 08:00 to 16:00
        new SlotTemplate('Evening', 1600, 2359) // 16:00 to 23:59
    };

    private static final List<String> WEEKDAYS = new List<String>{
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    };
    

    /************************************************ Helper Class ***********************************************/
    private class SlotTemplate {
        public String label;
        public Integer startTime;
        public Integer endTime;

        public SlotTemplate(String label, Integer startTime, Integer endTime) {
            this.label = label;
            this.startTime = startTime;
            this.endTime = endTime;
        }
    }
}