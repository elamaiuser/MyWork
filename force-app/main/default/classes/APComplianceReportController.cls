public with sharing class APComplianceReportController {
    public Date startDate { get; set; }
    public Date endDate { get; set; }
    public String division { get; set; }
    public String region { get; set; }
    public List<String> coList { get; set; }
    public List<Map<String, String>> reportData { get; set; }
    public APComplianceReportController.DatableConfigWrapper wrapper { get; set; }
    
    public APComplianceReportController() {
    String startParam = ApexPages.currentPage().getParameters().get('startdate');
    String endParam = ApexPages.currentPage().getParameters().get('enddate');
    division = ApexPages.currentPage().getParameters().get('division');
    region = ApexPages.currentPage().getParameters().get('region');

    String coParam = ApexPages.currentPage().getParameters().get('co');
    if (String.isNotBlank(coParam)) {
        coList = coParam.split(','); //
    } else {
        coList = new List<String>();
    }

    if (String.isNotBlank(startParam)) {
        startDate = Date.valueOf(startParam);
    }
    if (String.isNotBlank(endParam)) {
        endDate = Date.valueOf(endParam);
    }

    wrapper = searchReport(startDate, endDate, division, region, coList);
    reportData = wrapper != null ? wrapper.dataWrapper : new List<Map<String, String>>();
}

    
    
    public class DatableConfigWrapper {
        @AuraEnabled public List<Map<String, String>> dataWrapper { get; set; }
        @AuraEnabled public List<Map<String, Object>> columnsInfo { get; set; }
        @AuraEnabled public Map<String, String> summary { get; set; }
    }
    
@AuraEnabled(cacheable=true)
public static DatableConfigWrapper searchReport(Date startDt, Date endDt, String division, String region, List<String> coList) {
    System.debug('>>> searchReport called with startDt=' + startDt + ', endDt=' + endDt + ', division=' + division + ', region=' + region + ', co=' + coList);
		Integer jobViolations = 0;
		Integer activityViolations = 0;
    DatableConfigWrapper wrapper = new DatableConfigWrapper();
    wrapper.dataWrapper = new List<Map<String, String>>();
    wrapper.columnsInfo = new List<Map<String, Object>>{
        new Map<String, Object>{ 'label' => 'Resource', 'fieldName' => 'name', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Supervisor', 'fieldName' => 'supervisor', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Drive Name', 'fieldName' => 'driveName', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Division', 'fieldName' => 'division', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Region', 'fieldName' => 'region', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'CO', 'fieldName' => 'co', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Work Date', 'fieldName' => 'workDate', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Type', 'fieldName' => 'type', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Role', 'fieldName' => 'role', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Drive Status', 'fieldName' => 'status', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Start Time', 'fieldName' => 'startTime', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'End Time', 'fieldName' => 'endTime', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Availability Pattern Time', 'fieldName' => 'apTime', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'Availability Pattern Name', 'fieldName' => 'apName', 'type' => 'text' },
        new Map<String, Object>{ 'label' => 'AP Violation', 'fieldName' => 'violation', 'type' => 'text'},
        new Map<String, Object>{ 'label' => 'Exception', 'fieldName' => 'exc', 'type' => 'text' }
    };

    Map<Id, sked__Resource__c> resMap = new Map<Id, sked__Resource__c>(
        [SELECT Id, Name, sked_Supervisor__r.Name,
                sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Name,
                sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.Name,
                sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name
         FROM sked__Resource__c
         WHERE sked__Resource_Type__c = 'Person'
         AND sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.sked_Parent__c = :division
         AND sked__Primary_Region__r.sked_Territory__r.sked_Parent__c = :region
         AND sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :coList
        ]
    );
    if (resMap.isEmpty()) return wrapper;

    Map<Id, Map<String, List<TimeRange>>> resourceApMap = new Map<Id, Map<String, List<TimeRange>>>();
    Map<Id, String> apNameMap = new Map<Id, String>();
    for (sked__Availability_Pattern_Resource__c apr : [
        SELECT sked__Resource__c, sked__Availability_Pattern__r.Name, sked__Availability_Pattern__r.sked__Pattern__c
        FROM sked__Availability_Pattern_Resource__c
        WHERE sked__Resource__c IN :resMap.keySet()
    ]) {
        String jsonPattern = apr.sked__Availability_Pattern__r.sked__Pattern__c;
        apNameMap.put(apr.sked__Resource__c, apr.sked__Availability_Pattern__r.Name);
        if (String.isBlank(jsonPattern)) continue;

        Map<String, Object> pattern = (Map<String, Object>) JSON.deserializeUntyped(jsonPattern);
        Map<String, List<TimeRange>> weeklyMap = new Map<String, List<TimeRange>>();
        for (Object dayObj : (List<Object>) pattern.get('days')) {
            Map<String, Object> day = (Map<String, Object>) dayObj;
            String weekday = ((String) day.get('weekday')).toUpperCase();
            List<TimeRange> ranges = new List<TimeRange>();
            for (Object i : (List<Object>) day.get('intervals')) {
                Map<String, Object> range = (Map<String, Object>) i;
                Time s = parseTime((String) range.get('startTime'));
                Time e = parseTime((String) range.get('endTime'));
                if (s != null && e != null) ranges.add(new TimeRange(s, e));
            }
            weeklyMap.put(weekday, ranges);
        }
        resourceApMap.put(apr.sked__Resource__c, weeklyMap);
    }

    for (sked__Job_Allocation__c job : [
        SELECT Name,sked__Resource__c,sked__Job__r.sked__Type__c, sked_Start_Date__c, sked_Start_Time__c, sked_Set_End_Time__c,sked__Job__r.sked_Drive__r.Name,
               sked__Job__r.sked__Job_Status__c, sked__Job__r.sked_Drive__r.sked_Status__c,sked__Job__r.sked_Drive_Shift__r.sked_Drive_Operation_Type__c,sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c
        FROM sked__Job_Allocation__c
        WHERE (sked__Job__r.sked_Drive_Shift__r.sked_Drive_Operation_Type__c like '%Non Integrated%' OR sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c = 'Mobile') AND 
                sked_Start_Date__c >= :startDt AND sked_Start_Date__c <= :endDt AND 
                sked__Job__r.sked_Drive__r.sked_Status__c = 'Complete' AND 
                sked__Resource__c IN :resMap.keySet()
    ]) {
        String day = getWeekday(job.sked_Start_Date__c);
        Boolean isViolation = !isWithinPattern(day, job.sked_Start_Time__c, job.sked_Set_End_Time__c, resourceApMap.get(job.sked__Resource__c));
        if (isViolation) jobViolations++;
        wrapper.dataWrapper.add(buildRow(resMap.get(job.sked__Resource__c), job.sked_Start_Date__c, 'Job', job.sked__Job__r.sked__Job_Status__c, isViolation, job.sked_Start_Time__c, job.sked_Set_End_Time__c, resourceApMap.get(job.sked__Resource__c)?.get(day), apNameMap.get(job.sked__Resource__c),Job.sked__Job__r.sked_Drive__r.Name,job.sked__Job__r.sked__Type__c));
        System.debug('>>> Job Allocation Id: ' + job.Id);
    System.debug('>>> Job Status: ' + job.sked__Job__r.sked__Job_Status__c);
    System.debug('>>> Resource Id: ' + job.sked__Resource__c);
    System.debug('>>> Work Date: ' + job.sked_Start_Date__c);
    }

    for (sked__Activity__c act : [
        SELECT Name, sked__Resource__c, sked_Start_Date__c, sked_Start_Time__c, sked_End_Time__c
        FROM sked__Activity__c
        WHERE sked_Start_Date__c >= :startDt AND sked_Start_Date__c <= :endDt
        AND sked__Resource__c IN :resMap.keySet()
    ]) {
        String day = getWeekday(act.sked_Start_Date__c);
        Boolean isViolation = !isWithinPattern(day, act.sked_Start_Time__c, act.sked_End_Time__c, resourceApMap.get(act.sked__Resource__c));
        if (isViolation) activityViolations++;
        wrapper.dataWrapper.add(buildRow(resMap.get(act.sked__Resource__c), act.sked_Start_Date__c, 'Activity', '', isViolation, act.sked_Start_Time__c, act.sked_End_Time__c, resourceApMap.get(act.sked__Resource__c)?.get(day), apNameMap.get(act.sked__Resource__c),Null,act.Name));
    }
    Integer totalRecords = wrapper.dataWrapper.size();
    Integer totalViolations = jobViolations + activityViolations;
    Integer violationPercentage = totalRecords > 0 ? Integer.valueOf(Math.round((Decimal)totalViolations * 100 / totalRecords)) : 0;
    
    wrapper.summary = new Map<String, String>{
        'totalRecords' => String.valueOf(totalRecords),
        'jobViolations' => String.valueOf(jobViolations),
        'activityViolations' => String.valueOf(activityViolations),
        'totalViolations' => String.valueOf(totalViolations),
        'violationPercentage' => String.valueOf(violationPercentage)
    };

    return wrapper;
}

private static Map<String, String> buildRow(sked__Resource__c res, Date workDate, String type, String status, Boolean violation, Time startTime, Time endTime, List<TimeRange> apRanges, String apName,String driveName,string Role) {
    Map<String, String> row = new Map<String, String>();
    row.put('name', res?.Name);
    row.put('supervisor', res?.sked_Supervisor__r?.Name);
    row.put('division', res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.sked_Parent__r?.Name);
    row.put('region', res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.Name);
    row.put('co', res?.sked__Primary_Region__r?.sked_Biomed_Collection_Op_Center__r?.Name);
   	row.put('workDate', workDate != null ? workDate.format() : '');
    row.put('type', type);
    row.put('status', status != null ? status : '');
    row.put('startTime', startTime != null ? formatTime(startTime) : '');
    row.put('endTime', endTime != null ? formatTime(endTime) : '');
    row.put('apName', apName);
    row.put('violation', String.valueOf(violation));
    row.put('violationIcon', violation ? 'utility:error' : 'utility:check');
    row.put('driveName', driveName != null ? driveName : '');
    row.put('role',Role);

    if (apRanges != null && !apRanges.isEmpty()) {
        List<String> times = new List<String>();
        for (TimeRange t : apRanges) {
            times.add(formatTime(t.startTime) + '-' + formatTime(t.endTime));
        }
        row.put('apTime', String.join(times, '; '));
    } else {
        row.put('apTime', '');
    }
    String exc = 'No Exception';
    if (violation) {
        exc = (type == 'Job') ? 'Non-working time' : 'Activity outside of Availability Pattern';
    }
    row.put('exc', exc);

    return row;
}

private static String formatTime(Time t) {
    if (t == null) return '';
    String h = t.hour() < 10 ? '0' + t.hour() : String.valueOf(t.hour());
    String m = t.minute() < 10 ? '0' + t.minute() : String.valueOf(t.minute());
    return h + ':' + m;
}



private static String getWeekday(Date dt) {
    DateTime dtTime = DateTime.newInstance(dt.year(), dt.month(), dt.day());
    return dtTime.format('E').toUpperCase();
}


private static Time parseTime(String t) {
    if (String.isBlank(t)) return null;
    List<String> parts = t.split(':');
    Integer h = Integer.valueOf(parts[0]);
    Integer m = parts.size() > 1 ? Integer.valueOf(parts[1]) : 0;
    Integer s = parts.size() > 2 ? Integer.valueOf(parts[2]) : 0;
    return Time.newInstance(h, m, s, 0);
}

    private static Boolean isWithinPattern(String weekday, Time startTime, Time endTime, Map<String, List<TimeRange>> pattern) {
    if (pattern == null || !pattern.containsKey(weekday)) return false;

    Integer jobStart = startTime.hour() * 60 + startTime.minute();
    Integer jobEnd = endTime.hour() * 60 + endTime.minute();
    Boolean jobNextDay = jobEnd < jobStart;

    for (TimeRange range : pattern.get(weekday)) {
        Integer rangeStart = range.startTime.hour() * 60 + range.startTime.minute();
        Integer rangeEnd = range.endTime.hour() * 60 + range.endTime.minute();
        if (rangeStart == 0 && rangeEnd == 0) return true;
		 Boolean patternNextDay = rangeEnd < rangeStart;
        if (jobNextDay && !patternNextDay) return false;
        if (jobStart >= rangeStart && jobEnd <= rangeEnd) return true;
        if (jobNextDay && patternNextDay &&
            (jobStart >= rangeStart || jobEnd <= rangeEnd)) return true;
    }

    return false;
}

private class TimeRange {
    public Time startTime;
    public Time endTime;
    public TimeRange(Time s, Time e) {
        startTime = s;
        endTime = e;
    }
}



}