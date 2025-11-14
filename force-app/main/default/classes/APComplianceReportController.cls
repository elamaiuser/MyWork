/**
* @Description : 
* 1. Controller class for Availability Pattern (AP) Compliance Report (HRP-14511)
* 2. Lists Jobs and Activities scheduled outside assigned Availability Patterns by CO, region, date, drive status, etc.
* 3. Supports export to Excel and Visualforce PDF generation
*
* *********************************************************************************************************************
* Modification Log 
* Date          Developer Name        Comments
* *********************************************************************************************************************
* 08/29/2025    Elam Pandian          Corrected AP Compliance logic for date-specific patterns.
*                                     - Fixed a bug where the query incorrectly used future-dated or expired 
*                                       Availability Patterns for violation checks.
*                                     - The logic now fetches only patterns active within the report's date range.
*                                     - For each job/activity, it performs a lookup to find the single, correct
*                                       pattern that was effective on the specific date the work was performed.
* 06/03/2025    Shubham Tiwari        Initial version - HRP-14511: AP Compliance Report logic
*/


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
        String statusParam = ApexPages.currentPage().getParameters().get('driveStatusFilter');
        String violationOnlyParam = ApexPages.currentPage().getParameters().get('violationOnly');
        String includeTradesParam = ApexPages.currentPage().getParameters().get('includeTrades');
        
        if (String.isNotBlank(coParam)) {
            coList = coParam.split(',');
        } else {
            coList = new List<String>();
        }
        
        List<String> driveStatusFilter = new List<String>();
        if (String.isNotBlank(statusParam)) {
            driveStatusFilter = statusParam.split(',');
        }
        
        Boolean onlyViolations = violationOnlyParam == 'true';
        Boolean includeTrades = includeTradesParam == 'true';
        
        if (String.isNotBlank(startParam)) {
            startDate = Date.valueOf(startParam);
        }
        if (String.isNotBlank(endParam)) {
            endDate = Date.valueOf(endParam);
        }
        
        wrapper = APComplianceReportController.searchReport(startDate, endDate, division, region, coList, driveStatusFilter, onlyViolations, includeTrades);        
        reportData = wrapper != null ? wrapper.dataWrapper : new List<Map<String, String>>();
    }
    
    public class DatableConfigWrapper {
        @AuraEnabled public List<Map<String, String>> dataWrapper { get; set; }
        @AuraEnabled public List<Map<String, Object>> columnsInfo { get; set; }
        @AuraEnabled public Map<String, String> summary { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static DatableConfigWrapper searchReport(Date startDt, Date endDt, String division, String region, List<String> coList, List<String> driveStatusFilter, Boolean violationOnly, Boolean includeTrades) {
        System.debug('--- searchReport Method Input ---');
        System.debug('startDt: ' + startDt);
        System.debug('endDt: ' + endDt);
        System.debug('division: ' + division);
        System.debug('region: ' + region);
        System.debug('coList: ' + coList);
        System.debug('driveStatusFilter: ' + driveStatusFilter);
        System.debug('violationOnly: ' + violationOnly);
        System.debug('includeTrades: ' + includeTrades);
        
        DatableConfigWrapper wrapper = new DatableConfigWrapper();
        wrapper.dataWrapper = new List<Map<String, String>>();
        wrapper.columnsInfo = new List<Map<String, Object>>{
            new Map<String, Object>{ 'label' => 'Resource', 'fieldName' => 'name', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Supervisor', 'fieldName' => 'supervisor', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Drive Name', 'fieldName' => 'driveName', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Job/Activity Name', 'fieldName' => 'JName', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Division', 'fieldName' => 'division', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Region', 'fieldName' => 'region', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'CO', 'fieldName' => 'co', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Start Date', 'fieldName' => 'workDate', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Type', 'fieldName' => 'type', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Role', 'fieldName' => 'role', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Drive Status', 'fieldName' => 'status', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Start Time', 'fieldName' => 'startTime', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'End Time', 'fieldName' => 'endTime', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Availability Pattern Time', 'fieldName' => 'apTime', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Availability Pattern Name', 'fieldName' => 'apName', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'AP Violation', 'fieldName' => 'violation', 'type' => 'text' },
            new Map<String, Object>{ 'label' => 'Exception', 'fieldName' => 'exc', 'type' => 'text' }    
        };
            
        Map<Id, sked__Resource__c> resMap = new Map<Id, sked__Resource__c>(
            [SELECT Id, Name, sked_Supervisor__r.Name,sked_Supervisor_Name__c,
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
        if (resMap.isEmpty()) {
            return wrapper;
        }
        
        Map<Id, List<PatternWithDateRange>> resourcePatternsMap = new Map<Id, List<PatternWithDateRange>>();
        Set<Id> resourceIds = resMap.keySet();
        
        Set<String> idStrings = new Set<String>();
        for (Id i : resourceIds) {
            idStrings.add('\'' + String.valueOf(i) + '\'');
        }
        String idClause = '(' + String.join(idStrings, ',') + ')';
        
        for (sked__Availability_Pattern_Resource__c apr : [
            SELECT sked__Resource__c, sked_Start_Date__c, sked_End_Date__c,
                   sked__Availability_Pattern__r.Name, sked__Availability_Pattern__r.sked__Pattern__c
            FROM sked__Availability_Pattern_Resource__c
            WHERE sked__Resource__c IN :resourceIds
            AND sked_Start_Date__c <= :endDt
            AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :startDt)
        ]) {
            String jsonPattern = apr.sked__Availability_Pattern__r.sked__Pattern__c;
            if (String.isBlank(jsonPattern)) continue;

            Map<String, List<TimeRange>> weeklyMap = new Map<String, List<TimeRange>>();
            Map<String, Object> pattern = (Map<String, Object>) JSON.deserializeUntyped(jsonPattern);
            if (pattern.get('days') == null) continue;

            for (Object dayObj : (List<Object>) pattern.get('days')) {
                Map<String, Object> day = (Map<String, Object>) dayObj;
                String weekday = ((String) day.get('weekday')).toUpperCase();
                List<TimeRange> ranges = new List<TimeRange>();
                if (day.get('intervals') == null) continue;
                for (Object i : (List<Object>) day.get('intervals')) {
                    Map<String, Object> range = (Map<String, Object>) i;
                    Time s = parseTime((String) range.get('startTime'));
                    Time e = parseTime((String) range.get('endTime'));
                    if (s != null && e != null) {
                        ranges.add(new TimeRange(s, e));
                    }
                }
                weeklyMap.put(weekday, ranges);
            }
            
            PatternWithDateRange datedPattern = new PatternWithDateRange(
                apr.sked_Start_Date__c, apr.sked_End_Date__c, 
                apr.sked__Availability_Pattern__r.Name, weeklyMap
            );

            if (!resourcePatternsMap.containsKey(apr.sked__Resource__c)) {
                resourcePatternsMap.put(apr.sked__Resource__c, new List<PatternWithDateRange>());
            }
            resourcePatternsMap.get(apr.sked__Resource__c).add(datedPattern);
        }
        
        Integer jobViolations = 0;
        Integer activityViolations = 0;
        
        String jobSOQL = 
            'SELECT Name,sked__Job__r.Name, sked__Resource__c, sked__Job__r.sked__Type__c, sked_Start_Date__c, sked_Start_Time__c, sked_Set_End_Time__c, ' +
            'sked__Job__r.sked_Drive__r.Name, sked__Job__r.sked__Job_Status__c, sked__Job__r.sked_Drive__r.sked_Status__c, ' +
            'sked__Job__r.sked_Drive_Shift__r.sked_Drive_Operation_Type__c, sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c,sked_Drive_Shift_Trade__c,sked_Call_Out_Type__c ' +
            'FROM sked__Job_Allocation__c ' +
            'WHERE sked_Start_Date__c >= :startDt ' +
            'AND sked_Start_Date__c <= :endDt ' +
            'AND sked__Resource__c IN ' + idClause + ' ' +
            'AND sked__Job__r.sked_Drive__r.sked_Status__c = :driveStatusFilter ';
        
        if (!includeTrades) {
            jobSOQL += 'AND (sked_Drive_Shift_Trade__c = null AND sked_Call_Out_Type__c = null) ';
        }
        
        jobSOQL += 'AND (sked__Job__r.sked_Drive_Shift__r.sked_Drive_Operation_Type__c LIKE \'%Non Integrated%\' ' +
            'OR sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c = \'Mobile\') ORDER BY sked_Start_Date__c desc';
        
        List<sked__Job_Allocation__c> jobAllocList = Database.query(jobSOQL);
        for (sked__Job_Allocation__c job : jobAllocList) {
            String day = getWeekday(job.sked_Start_Date__c);

            PatternWithDateRange activePattern = null;
            if (resourcePatternsMap.containsKey(job.sked__Resource__c)) {
                for (PatternWithDateRange p : resourcePatternsMap.get(job.sked__Resource__c)) {
                    if (job.sked_Start_Date__c >= p.startDate && job.sked_Start_Date__c <= p.endDate) {
                        activePattern = p;
                        break;
                    }
                }
            }
            if (activePattern == null) {
                        continue; // Skip jobs without an availability pattern
                    }
            
            Map<String, List<TimeRange>> patternForDay = (activePattern != null) ? activePattern.weeklySchedule : null;
            Boolean isViolation = !isWithinPattern(day, job.sked_Start_Time__c, job.sked_Set_End_Time__c, patternForDay);
            
            String calloutTradeVal = '';
            if (includeTrades) {
                if (job.sked_Drive_Shift_Trade__c != null) {
                    calloutTradeVal = 'Job - Trade';
                } else if (job.sked_Call_Out_Type__c != null) {
                    calloutTradeVal = 'Job - Callout';
                }
            }

            if (violationOnly && !isViolation) continue;
            if (isViolation) jobViolations++;
            
            wrapper.dataWrapper.add(buildRow(
                resMap.get(job.sked__Resource__c),
                job.sked_Start_Date__c,
                'Job',
                job.sked__Job__r.sked_Drive__r.sked_Status__c,
                isViolation,
                job.sked_Start_Time__c,
                job.sked_Set_End_Time__c,
                (activePattern != null) ? activePattern.weeklySchedule?.get(day) : null,
                (activePattern != null) ? activePattern.patternName : 'No Availability Pattern',
                job.sked__Job__r.sked_Drive__r.Name,
                job.sked__Job__r.Name,
                job.sked__Job__r.sked__Type__c,
                calloutTradeVal
            ));
        }
        
        String activityQuery = 
            'SELECT Id, sked_Drive_Shift_Trade__c, sked__Activity__r.Name,sked__Activity__r.sked_Activity_Title__c,sked__Resource__r.Name, sked__Resource__c, ' +
            'sked_Start_Date__c, sked_Start_Time__c, sked_End_Time__c ' +
            'FROM sked__Activity_Resource__c ' +
            'WHERE sked_Start_Date__c >= :startDt AND sked_Start_Date__c <= :endDt ' +
            'AND sked__Resource__c IN ' + idClause + ' ';
        
        if (!includeTrades) {
            activityQuery += ' AND sked_Drive_Shift_Trade__c = null';
        }
        activityQuery += ' ORDER BY sked_Start_Date__c desc';
        
        List<sked__Activity_Resource__c> Lact = Database.query(activityQuery);
        
        for (sked__Activity_Resource__c act : Lact) {
            String day = getWeekday(act.sked_Start_Date__c);

            PatternWithDateRange activePattern = null;
            if (resourcePatternsMap.containsKey(act.sked__Resource__c)) {
                for (PatternWithDateRange p : resourcePatternsMap.get(act.sked__Resource__c)) {
                    if (act.sked_Start_Date__c >= p.startDate && act.sked_Start_Date__c <= p.endDate) {
                        activePattern = p;
                        break;
                    }
                }
            }
            if (activePattern == null) {
                        continue; // Skip Activity without an availability pattern
                    }
            
            Map<String, List<TimeRange>> patternForDay = (activePattern != null) ? activePattern.weeklySchedule : null;
            Boolean isViolation = !isWithinPattern(day, act.sked_Start_Time__c, act.sked_End_Time__c, patternForDay);
            
            string calloutTradeVal = '';
            if (includeTrades) {
                if (act.sked_Drive_Shift_Trade__c != null) {
                    calloutTradeVal = 'Activity - Trade';
                }
            }

            if (violationOnly && !isViolation) continue;
            if (isViolation) activityViolations++;
            
            wrapper.dataWrapper.add(buildRow(
                resMap.get(act.sked__Resource__c),
                act.sked_Start_Date__c,
                'Activity',
                '',
                isViolation,
                act.sked_Start_Time__c,
                act.sked_End_Time__c,
                (activePattern != null) ? activePattern.weeklySchedule?.get(day) : null,
                (activePattern != null) ? activePattern.patternName : 'No Active Pattern',
                null,
                act.sked__Activity__r.sked_Activity_Title__c,
                '',
                calloutTradeVal
            ));
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
        
        if (includeTrades) {
            wrapper.columnsInfo.add(new Map<String, Object>{
                'label' => 'Trade/Callout', 'fieldName' => 'calloutTrade', 'type' => 'text'
            });
        }        
        return wrapper;
    }
    
    private static Map<String, String> buildRow(sked__Resource__c res, Date workDate, String type, String status, Boolean violation, Time startTime, Time endTime, List<TimeRange> apRanges, String apName,String driveName,string JName,string Role,String calloutTradeVal) {
        Map<String, String> row = new Map<String, String>();
        row.put('name', res?.Name);
        row.put('supervisor', res?.sked_Supervisor__r != null ? res.sked_Supervisor__r.Name : res.sked_Supervisor_Name__c);
        row.put('division', res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.sked_Parent__r?.Name);
        row.put('region', res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.Name);
        row.put('co', res?.sked__Primary_Region__r?.sked_Biomed_Collection_Op_Center__r?.Name);
        row.put('workDate', workDate != null ? workDate.format() : '');
        row.put('type', type);
        row.put('status', status != null ? status : '');
        row.put('startTime', startTime != null ? formatTime(startTime) : '');
        row.put('endTime', endTime != null ? formatTime(endTime) : '');
        row.put('apName',  apName != null ? apName : '');
        row.put('violation', String.valueOf(violation));
        row.put('violationIcon', violation ? 'utility:error' : 'utility:check');
        row.put('driveName', driveName != null ? driveName : '');
        row.put('role',Role);
        row.put('JName',JName);
        row.put('calloutTrade', calloutTradeVal);
        
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

    public List<List<Map<String, String>>> getPaginatedData() {
        List<List<Map<String, String>>> pages = new List<List<Map<String, String>>>();
        
        if (wrapper == null || wrapper.dataWrapper == null || wrapper.dataWrapper.isEmpty()) {
            return pages;
        }
        
        List<Map<String, String>> fullList = wrapper.dataWrapper;
        Integer pageSize = 900; // Must be < 1000 for renderAs="pdf"
        Integer totalSize = fullList.size();
        
        for (Integer i = 0; i < totalSize; i += pageSize) {
            Integer endIndex = Math.min(i + pageSize, totalSize);
            List<Map<String, String>> page = new List<Map<String, String>>();
            
            for (Integer j = i; j < endIndex; j++) {
                page.add(fullList[j]);
            }
            
            pages.add(page);
        }        
        return pages;
    }
    
    private class TimeRange {
        public Time startTime;
        public Time endTime;
        public TimeRange(Time s, Time e) {
            startTime = s;
            endTime = e;
        }
    }

    private class PatternWithDateRange {
        public Date startDate { get; set; }
        public Date endDate { get; set; }
        public String patternName { get; set; }
        public Map<String, List<TimeRange>> weeklySchedule { get; set; }

        public PatternWithDateRange(Date sDate, Date eDate, String name, Map<String, List<TimeRange>> schedule) {
            this.startDate = sDate;            
            this.endDate = (eDate == null) ? Date.newInstance(4000, 1, 1) : eDate;
            this.patternName = name;
            this.weeklySchedule = schedule;
        }
    }        
}