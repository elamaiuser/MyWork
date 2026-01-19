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

    private static final Set<String> ALLOWED_SORT_FIELDS = new Set<String>{
        'name','supervisor','driveName','JName','division','region','co','workDate','type','JOT','role','status',
        'startTime','endTime','apTime','apName','violation','StaffingReason','exc','AType','Subtype','calloutTrade'
    };

    private static final Map<String, String> SORT_FIELD_MAPPING = new Map<String, String>{
        'resourceLink'   => 'name',
        'supervisorLink' => 'supervisor',
        'driveLink'      => 'driveName',
        'jobLink'        => 'JName',
        'divisionLink'   => 'division',
        'regionLink'     => 'region',
        'coLink'         => 'co',
        'apLink'         => 'apName'
    };

    private static final Map<String, String> SORT_KEY_FIELD = new Map<String, String>{
        'workDate'  => 'workDate_sort',
        'startTime' => 'startTime_sort',
        'endTime'   => 'endTime_sort'
    };

    public APComplianceReportController() {
        String startParam = ApexPages.currentPage().getParameters().get('startdate');
        String endParam   = ApexPages.currentPage().getParameters().get('enddate');
        division          = ApexPages.currentPage().getParameters().get('division');
        region            = ApexPages.currentPage().getParameters().get('region');

        String coParam            = ApexPages.currentPage().getParameters().get('co');
        String statusParam        = ApexPages.currentPage().getParameters().get('driveStatusFilter');
        String violationOnlyParam = ApexPages.currentPage().getParameters().get('violationOnly');
        String excludeTradesParam = ApexPages.currentPage().getParameters().get('excludeTrades');

        coList = String.isNotBlank(coParam) ? coParam.split(',') : new List<String>();
        List<String> driveStatusFilter = String.isNotBlank(statusParam) ? statusParam.split(',') : new List<String>();
        String opTypeParam = ApexPages.currentPage().getParameters().get('driveOperationTypeFilter');
		List<String> driveOperationTypeFilter = String.isNotBlank(opTypeParam) ? opTypeParam.split(',') : new List<String>();


        Boolean onlyViolations = (violationOnlyParam == 'true');
        Boolean excludeTrades  = (excludeTradesParam == 'true');

        if (String.isNotBlank(startParam)) startDate = Date.valueOf(startParam);
        if (String.isNotBlank(endParam))   endDate   = Date.valueOf(endParam);

        wrapper = APComplianceReportController.searchReport(
    startDate, endDate, division, region, coList, driveStatusFilter, driveOperationTypeFilter,
        onlyViolations, excludeTrades,
        null, null
    );

        reportData = wrapper != null ? wrapper.dataWrapper : new List<Map<String, String>>();
    }

    public class DatableConfigWrapper {
        @AuraEnabled public List<Map<String, String>> dataWrapper { get; set; }
        @AuraEnabled public List<Map<String, Object>> columnsInfo { get; set; }
        @AuraEnabled public Map<String, String> summary { get; set; }
    }

    @AuraEnabled(cacheable=true)
public static DatableConfigWrapper searchReport(
    Date startDt,
    Date endDt,
    String division,
    String region,
    List<String> coList,
    List<String> driveStatusFilter,
    List<String> driveOperationTypeFilter,
    Boolean violationOnly,
    Boolean excludeTrades,
    String sortField,
    String sortDirection
) {
    DatableConfigWrapper wrapper = new DatableConfigWrapper();
    wrapper.dataWrapper = new List<Map<String, String>>();
    wrapper.columnsInfo = new List<Map<String, Object>>{
    new Map<String, Object>{
        'label' => 'Resource',
        'fieldName' => 'resourceLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'name' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 180
    },
    new Map<String, Object>{
        'label' => 'Supervisor',
        'fieldName' => 'supervisorLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'supervisor' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 180
    },
    new Map<String, Object>{
        'label' => 'Drive Name',
        'fieldName' => 'driveLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'driveName' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 200
    },
    new Map<String, Object>{
        'label' => 'Drive Operation Type',
        'fieldName' => 'JOT',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 170
    },
    new Map<String, Object>{
        'label' => 'Job/Activity Name',
        'fieldName' => 'jobLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'JName' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 200
    },
    new Map<String, Object>{
        'label' => 'Division',
        'fieldName' => 'divisionLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'division' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 140
    },
    new Map<String, Object>{
        'label' => 'Region',
        'fieldName' => 'regionLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'region' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 140
    },
    new Map<String, Object>{
        'label' => 'CO',
        'fieldName' => 'coLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'co' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 160
    },

    new Map<String, Object>{
        'label' => 'Start Date',
        'fieldName' => 'workDate',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 120
    },
    new Map<String, Object>{
        'label' => 'Type',
        'fieldName' => 'type',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 110
    },
    new Map<String, Object>{
        'label' => 'Role',
        'fieldName' => 'role',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 140
    },
    new Map<String, Object>{
        'label' => 'Drive Status',
        'fieldName' => 'status',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 130
    },
    new Map<String, Object>{
        'label' => 'Start Time',
        'fieldName' => 'startTime',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 110
    },
    new Map<String, Object>{
        'label' => 'End Time',
        'fieldName' => 'endTime',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 110
    },
    new Map<String, Object>{
        'label' => 'Availability Pattern Time',
        'fieldName' => 'apTime',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 190
    },

    new Map<String, Object>{
        'label' => 'Availability Pattern Name',
        'fieldName' => 'apLink',
        'type' => 'url',
        'typeAttributes' => new Map<String, Object>{
            'label' => new Map<String, Object>{ 'fieldName' => 'apName' },
            'target' => '_blank'
        },
        'sortable' => true,
        'initialWidth' => 220
    },

    new Map<String, Object>{
        'label' => 'AP Violation',
        'fieldName' => 'violation',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 120
    },
    new Map<String, Object>{
        'label' => 'Staffing Reason',
        'fieldName' => 'StaffingReason',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 180
    },
    new Map<String, Object>{
        'label' => 'Exception',
        'fieldName' => 'exc',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 140
    },
    new Map<String, Object>{
        'label' => 'Activity Type',
        'fieldName' => 'AType',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 140
    },
    new Map<String, Object>{
        'label' => 'Activity SubType',
        'fieldName' => 'Subtype',
        'type' => 'text',
        'sortable' => true,
        'initialWidth' => 160
    }
};


    if (!excludeTrades) {
        wrapper.columnsInfo.add(new Map<String, Object>{
            'label' => 'Trade/Callout', 'fieldName' => 'calloutTrade', 'type' => 'text', 'sortable' => true
        });
    }

    Map<Id, sked__Resource__c> resMap = new Map<Id, sked__Resource__c>([
        SELECT Id, Name,
            sked_Supervisor__c, sked_Supervisor__r.Name, sked_Supervisor_Name__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Name,
            sked__Primary_Region__r.sked_Territory__r.Id,
            sked__Primary_Region__r.sked_Territory__r.Name,
            sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.Id,
            sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.Name,
            sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Id,
            sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name
        FROM sked__Resource__c
        WHERE sked__Resource_Type__c = 'Person'
        AND sked__Primary_Region__r.sked_Territory__r.sked_Parent__r.sked_Parent__c = :division
        AND sked__Primary_Region__r.sked_Territory__r.sked_Parent__c = :region
        AND sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :coList
    ]);

    if (resMap.isEmpty()) {
        wrapper.summary = new Map<String, String>{
            'totalRecords' => '0','jobViolations' => '0','activityViolations' => '0',
            'totalViolations' => '0','violationPercentage' => '0'
        };
        return wrapper;
    }

    Set<Id> resourceIds = resMap.keySet();

    Set<String> idStrings = new Set<String>();
    for (Id i : resourceIds) idStrings.add('\'' + String.valueOf(i) + '\'');
    String idClause = '(' + String.join(idStrings, ',') + ')';

    Map<Id, List<PatternWithDateRange>> resourcePatternsMap = new Map<Id, List<PatternWithDateRange>>();
    for (sked__Availability_Pattern_Resource__c apr : [
        SELECT sked__Resource__c, sked_Start_Date__c, sked_End_Date__c,
               sked__Availability_Pattern__c,
               sked__Availability_Pattern__r.Name,
               sked__Availability_Pattern__r.sked__Pattern__c
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
                if (s != null && e != null) ranges.add(new TimeRange(s, e));
            }
            weeklyMap.put(weekday, ranges);
        }

        PatternWithDateRange datedPattern = new PatternWithDateRange(
            apr.sked_Start_Date__c,
            apr.sked_End_Date__c,
            apr.sked__Availability_Pattern__c,
            apr.sked__Availability_Pattern__r.Name,
            weeklyMap
        );

        if (!resourcePatternsMap.containsKey(apr.sked__Resource__c)) {
            resourcePatternsMap.put(apr.sked__Resource__c, new List<PatternWithDateRange>());
        }
        resourcePatternsMap.get(apr.sked__Resource__c).add(datedPattern);
    }

    Integer jobViolations = 0;
    Integer activityViolations = 0;
    Integer rowCounter = 0;

    String jobSOQL =
        'SELECT Name, sked__Job__c, sked__Job__r.Name, sked__Resource__c, sked__Job__r.sked__Type__c, ' +
        'sked_Start_Date__c, sked_Start_Time__c, sked_Set_End_Time__c, ' +
        'sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive__r.Name, sked__Job__r.sked_Drive__r.sked_Status__c, ' +
        'sked__Job__r.sked_Drive__r.sked_Drive_Operation_Type__c, sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c, ' +
        'sked_Drive_Shift_Trade__c, sked_Call_Out_Type__c, sked_Staffing_Reason__c ' +
        'FROM sked__Job_Allocation__c ' +
        'WHERE sked_Start_Date__c >= :startDt and sked__Status__c != \'Deleted\'' +
        'AND sked_Start_Date__c <= :endDt ' +
        'AND sked__Resource__c IN ' + idClause + ' ';

    if (driveStatusFilter != null && !driveStatusFilter.isEmpty()) {
        jobSOQL += 'AND sked__Job__r.sked_Drive__r.sked_Status__c IN :driveStatusFilter ';
    }

    if (excludeTrades) {
        jobSOQL += 'AND (sked_Drive_Shift_Trade__c = null AND sked_Staffing_Reason__c != \'Callout replacement\') ';
    }

    if (driveOperationTypeFilter != null && !driveOperationTypeFilter.isEmpty()) {
    jobSOQL += buildDriveOperationTypeWhere(driveOperationTypeFilter);
	}

    List<sked__Job_Allocation__c> jobAllocList = Database.query(jobSOQL);
    for (sked__Job_Allocation__c job : jobAllocList) {
        String day = getWeekday(job.sked_Start_Date__c);

        PatternWithDateRange activePattern = null;
        if (resourcePatternsMap.containsKey(job.sked__Resource__c)) {
            for (PatternWithDateRange p : resourcePatternsMap.get(job.sked__Resource__c)) {
                if (job.sked_Start_Date__c >= p.startDate && job.sked_Start_Date__c <= p.endDate) {
                    activePattern = p; break;
                }
            }
        }
        if (activePattern == null) continue;

        Boolean isTradeOrCallout = (job.sked_Drive_Shift_Trade__c != null) || (job.sked_Staffing_Reason__c == 'Callout replacement');

        Boolean isViolation = !isWithinPattern(day, job.sked_Start_Time__c, job.sked_Set_End_Time__c, activePattern.weeklySchedule);
        //if (isTradeOrCallout) isViolation = false;

        String calloutTradeVal = '';
        if (!excludeTrades && isTradeOrCallout) {
            if (job.sked_Drive_Shift_Trade__c != null) calloutTradeVal = 'Job - Trade';
            else calloutTradeVal = 'Job - Callout';
        }

        if (violationOnly && !isViolation) continue;
        if (isViolation) jobViolations++;
        String jotDisplay = (job.sked__Job__r != null && job.sked__Job__r.sked_Drive__r != null)
        ? job.sked__Job__r.sked_Drive__r.sked_Drive_Operation_Type__c
        : '';



        Map<String, String> row = buildRow(
            resMap.get(job.sked__Resource__c),
            job.sked_Start_Date__c,
            'Job',
            job.sked__Job__r.sked_Drive__r != null ? job.sked__Job__r.sked_Drive__r.sked_Status__c : '',
            isViolation,
            job.sked_Start_Time__c,
            job.sked_Set_End_Time__c,
            activePattern,
            job.sked__Job__r.sked_Drive__c,
            job.sked__Job__r.sked_Drive__r != null ? job.sked__Job__r.sked_Drive__r.Name : '',
            job.sked__Job__c,
            jotDisplay,
            job.sked__Job__r != null ? job.sked__Job__r.Name : '',
            job.sked__Job__r != null ? job.sked__Job__r.sked__Type__c : '',
            job.sked_Staffing_Reason__c,
            calloutTradeVal,
            '',
            ''
        );
        row.put('rowKey', String.valueOf(++rowCounter));
        wrapper.dataWrapper.add(row);
    }

    List<String> excludedTypes = new List<String>{ 'After Hours Call Out Management', 'On Call', 'Training' };

    String activityQuery =
        'SELECT Id, sked_Drive_Shift_Trade__c, sked__Activity__c, sked__Activity__r.Name, sked__Activity__r.sked_Activity_Title__c, ' +
        'sked__Activity__r.sked__Type__c, sked__Activity__r.sked_Subtype__c, sked__Resource__c, ' +
        'sked_Start_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Staffing_Reason__c ' +
        'FROM sked__Activity_Resource__c ' +
        'WHERE sked_Start_Date__c >= :startDt ' +
        'AND sked_Start_Date__c <= :endDt ' +
        'AND sked__Activity__r.sked__Type__c NOT IN :excludedTypes ' +
        'AND sked__Resource__c IN ' + idClause + ' ';

    if (excludeTrades) {
        activityQuery += 'AND (sked_Drive_Shift_Trade__c = null AND sked_Staffing_Reason__c != \'Callout replacement\') ';
    }
    activityQuery += 'ORDER BY sked_Start_Date__c desc';

    List<sked__Activity_Resource__c> Lact = Database.query(activityQuery);
    for (sked__Activity_Resource__c act : Lact) {
        String day = getWeekday(act.sked_Start_Date__c);

        PatternWithDateRange activePattern = null;
        if (resourcePatternsMap.containsKey(act.sked__Resource__c)) {
            for (PatternWithDateRange p : resourcePatternsMap.get(act.sked__Resource__c)) {
                if (act.sked_Start_Date__c >= p.startDate && act.sked_Start_Date__c <= p.endDate) {
                    activePattern = p; break;
                }
            }
        }
        if (activePattern == null) continue;

        Boolean isTradeOrCallout = (act.sked_Drive_Shift_Trade__c != null) || (act.sked_Staffing_Reason__c == 'Callout replacement');

        Boolean isViolation = !isWithinPattern(day, act.sked_Start_Time__c, act.sked_End_Time__c, activePattern.weeklySchedule);
        //if (isTradeOrCallout) isViolation = false;

        String calloutTradeVal = '';
        if (!excludeTrades && isTradeOrCallout) {
            if (act.sked_Drive_Shift_Trade__c != null) calloutTradeVal = 'Activity - Trade';
            else calloutTradeVal = 'Activity - Callout';
        }

        if (violationOnly && !isViolation) continue;
        if (isViolation) activityViolations++;

        Map<String, String> row = buildRow(
            resMap.get(act.sked__Resource__c),
            act.sked_Start_Date__c,
            'Activity',
            '',
            isViolation,
            act.sked_Start_Time__c,
            act.sked_End_Time__c,
            activePattern,
            null,
            '',
            act.sked__Activity__c,
            '',
            act.sked__Activity__r != null ? act.sked__Activity__r.sked_Activity_Title__c : '',
            '',
            act.sked_Staffing_Reason__c,
            calloutTradeVal,
            act.sked__Activity__r != null ? act.sked__Activity__r.sked__Type__c : '',
            act.sked__Activity__r != null ? act.sked__Activity__r.sked_Subtype__c : ''
        );
        row.put('rowKey', String.valueOf(++rowCounter));
        wrapper.dataWrapper.add(row);
    }

    Integer totalRecords = wrapper.dataWrapper.size();
    Integer totalViolations = jobViolations + activityViolations;
    Integer violationPercentage = totalRecords > 0
        ? Integer.valueOf(Math.round((Decimal)totalViolations * 100 / totalRecords))
        : 0;

    if (String.isNotBlank(sortField)) {
        String mapped = SORT_FIELD_MAPPING.containsKey(sortField) ? SORT_FIELD_MAPPING.get(sortField) : sortField;
        if (ALLOWED_SORT_FIELDS.contains(mapped)) {
            sortDataList(wrapper.dataWrapper, mapped, sortDirection);
        }
    }

    wrapper.summary = new Map<String, String>{
        'totalRecords' => String.valueOf(totalRecords),
        'jobViolations' => String.valueOf(jobViolations),
        'activityViolations' => String.valueOf(activityViolations),
        'totalViolations' => String.valueOf(totalViolations),
        'violationPercentage' => String.valueOf(violationPercentage)
    };

    return wrapper;
}
		@TestVisible
    private static void sortDataList(List<Map<String, String>> dataList, String fieldName, String direction) {
        if (dataList == null || dataList.size() < 2) return;
        Boolean isAscending = String.isBlank(direction) || direction.equalsIgnoreCase('asc');

        String actualField = SORT_KEY_FIELD.containsKey(fieldName) ? SORT_KEY_FIELD.get(fieldName) : fieldName;
        Boolean isKeyField = SORT_KEY_FIELD.containsKey(fieldName);

        List<Map<String, String>> sorted = mergeSortMaps(dataList, actualField, isAscending, isKeyField);
        dataList.clear();
        dataList.addAll(sorted);
    }
	@TestVisible
    private static List<Map<String, String>> mergeSortMaps(List<Map<String, String>> input, String fieldName, Boolean isAscending, Boolean isKeyField) {
        Integer n = input.size();
        if (n <= 1) return input;

        Integer mid = n / 2;
        List<Map<String, String>> left = new List<Map<String, String>>();
        List<Map<String, String>> right = new List<Map<String, String>>();

        for (Integer i = 0; i < mid; i++) left.add(input[i]);
        for (Integer i = mid; i < n; i++) right.add(input[i]);

        left = mergeSortMaps(left, fieldName, isAscending, isKeyField);
        right = mergeSortMaps(right, fieldName, isAscending, isKeyField);

        return mergeMaps(left, right, fieldName, isAscending, isKeyField);
    }
	@TestVisible
    private static List<Map<String, String>> mergeMaps(
        List<Map<String, String>> left,
        List<Map<String, String>> right,
        String fieldName,
        Boolean isAscending,
        Boolean isKeyField
    ) {
        List<Map<String, String>> outList = new List<Map<String, String>>();
        Integer i = 0, j = 0;

        while (i < left.size() && j < right.size()) {
            String aRaw = left[i].get(fieldName);
            String bRaw = right[j].get(fieldName);

            String a = isKeyField ? normalizeKeySortValue(aRaw) : normalizeTextSortValue(aRaw);
            String b = isKeyField ? normalizeKeySortValue(bRaw) : normalizeTextSortValue(bRaw);

            Integer cmp = a.compareTo(b);
            Boolean takeLeft = isAscending ? (cmp <= 0) : (cmp >= 0);
            if (takeLeft) { outList.add(left[i]); i++; }
            else { outList.add(right[j]); j++; }
        }

        while (i < left.size()) { outList.add(left[i]); i++; }
        while (j < right.size()) { outList.add(right[j]); j++; }

        return outList;
    }
	@TestVisible
    private static String normalizeTextSortValue(String v) {
        return v == null ? '' : v.toLowerCase();
    }
	@TestVisible
    private static String normalizeKeySortValue(String v) {
        return v == null ? '' : v;
    }

    private static Map<String, String> buildRow(
        sked__Resource__c res,
        Date workDate,
        String type,
        String status,
        Boolean violation,
        Time startTime,
        Time endTime,
        PatternWithDateRange activePattern,
        Id driveId,
        String driveName,
        Id jobOrActivityId,
        String JOT,
        String JName,
        String Role,
        String StaffingReason,
        String calloutTradeVal,
        String AType,
        String Subtype
    ) {
        Map<String, String> row = new Map<String, String>();

        row.put('name', res != null ? res.Name : '');
        String supName = (res != null && res.sked_Supervisor__r != null) ? res.sked_Supervisor__r.Name : (res != null ? res.sked_Supervisor_Name__c : '');
        row.put('supervisor', supName);

        String divName = res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.sked_Parent__r?.Name;
        String regName = res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.Name;
        String coName  = res?.sked__Primary_Region__r?.sked_Biomed_Collection_Op_Center__r?.Name;

        row.put('division', divName != null ? divName : '');
        row.put('region', regName != null ? regName : '');
        row.put('co', coName != null ? coName : '');

        row.put('workDate', workDate != null ? workDate.format() : '');
        row.put('workDate_sort', workDate != null ? dateSortKey(workDate) : '');

        row.put('type', type);
        row.put('role', Role != null ? Role : '');
        row.put('status', status != null ? status : '');

        row.put('startTime', startTime != null ? formatTime(startTime) : '');
        row.put('startTime_sort', startTime != null ? timeSortKey(startTime) : '');

        row.put('endTime', endTime != null ? formatTime(endTime) : '');
        row.put('endTime_sort', endTime != null ? timeSortKey(endTime) : '');

        row.put('apName', activePattern != null ? activePattern.patternName : '');
        row.put('violation', String.valueOf(violation));
        row.put('StaffingReason', StaffingReason != null ? StaffingReason : '');
        row.put('calloutTrade', calloutTradeVal != null ? calloutTradeVal : '');
        row.put('AType', AType != null ? AType : '');
        row.put('Subtype', Subtype != null ? Subtype : '');

        row.put('driveName', driveName != null ? driveName : '');
        row.put('JName', JName != null ? JName : '');
         row.put('JOT', JOT != null ? JOT : '');

        if (activePattern != null && activePattern.weeklySchedule != null) {
            String wk = getWeekday(workDate);
            List<TimeRange> apRanges = activePattern.weeklySchedule.get(wk);

            if (apRanges != null && !apRanges.isEmpty()) {
                List<String> times = new List<String>();
                for (TimeRange t : apRanges) {
                    times.add(formatTime(t.startTime) + '-' + formatTime(t.endTime));
                }
                row.put('apTime', String.join(times, '; '));
            } else {
                row.put('apTime', '');
            }
        } else {
            row.put('apTime', '');
        }

        String exc = 'No Exception';
        if (violation) {
            exc = (type == 'Job') ? 'Non-working time' : 'Activity outside of Availability Pattern';
        }
        row.put('exc', exc);

        if (res != null) {
            row.put('resourceLink', '/lightning/r/sked__Resource__c/' + res.Id + '/view');
        }
        if (res != null && res.sked_Supervisor__c != null) {
            row.put('supervisorLink', '/lightning/r/User/' + res.sked_Supervisor__c + '/view');
        }
        if (driveId != null) {
            row.put('driveLink', '/lightning/r/sked_Drive__c/' + driveId + '/view');
        }
        if (jobOrActivityId != null) {
            if (type == 'Job') row.put('jobLink', '/lightning/r/sked__Job__c/' + jobOrActivityId + '/view');
            else row.put('jobLink', '/lightning/r/sked__Activity__c/' + jobOrActivityId + '/view');
        } else {
            row.put('jobLink', '');
        }

        Id divId = res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.sked_Parent__r?.Id;
        Id regId = res?.sked__Primary_Region__r?.sked_Territory__r?.sked_Parent__r?.Id;
        Id coId  = res?.sked__Primary_Region__r?.sked_Biomed_Collection_Op_Center__c;

        if (divId != null) row.put('divisionLink', '/lightning/r/sked_Territory__c/' + divId + '/view');
        if (regId != null) row.put('regionLink', '/lightning/r/sked_Territory__c/' + regId + '/view');
        if (coId  != null) row.put('coLink', '/lightning/r/Collection_Operation__c/' + coId + '/view');

        if (activePattern != null && activePattern.patternId != null) {
            row.put('apLink', '/lightning/r/sked__Availability_Pattern__c/' + activePattern.patternId + '/view');
        }

        return row;
    }

    private static String formatTime(Time t) {
        if (t == null) return '';
        String h = t.hour() < 10 ? '0' + t.hour() : String.valueOf(t.hour());
        String m = t.minute() < 10 ? '0' + t.minute() : String.valueOf(t.minute());
        return h + ':' + m;
    }

    private static String dateSortKey(Date d) {
        Integer y = d.year();
        Integer m = d.month();
        Integer day = d.day();
        String mm = m < 10 ? '0' + String.valueOf(m) : String.valueOf(m);
        String dd = day < 10 ? '0' + String.valueOf(day) : String.valueOf(day);
        return String.valueOf(y) + mm + dd;
    }

    private static String timeSortKey(Time t) {
        Integer mins = (t.hour() * 60) + t.minute();
        String s = String.valueOf(mins);
        while (s.length() < 4) s = '0' + s;
        return s;
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
            if (jobNextDay && patternNextDay && (jobStart >= rangeStart || jobEnd <= rangeEnd)) return true;
        }
        return false;
    }

    public List<List<Map<String, String>>> getPaginatedData() {
        List<List<Map<String, String>>> pages = new List<List<Map<String, String>>>();
        if (wrapper == null || wrapper.dataWrapper == null || wrapper.dataWrapper.isEmpty()) return pages;

        List<Map<String, String>> fullList = wrapper.dataWrapper;
        Integer pageSize = 900;
        Integer totalSize = fullList.size();

        for (Integer i = 0; i < totalSize; i += pageSize) {
            Integer endIndex = Math.min(i + pageSize, totalSize);
            List<Map<String, String>> page = new List<Map<String, String>>();
            for (Integer j = i; j < endIndex; j++) page.add(fullList[j]);
            pages.add(page);
        }
        return pages;
    }

    private class TimeRange {
        public Time startTime;
        public Time endTime;
        public TimeRange(Time s, Time e) { startTime = s; endTime = e; }
    }

    private class PatternWithDateRange {
        public Date startDate { get; set; }
        public Date endDate { get; set; }
        public Id patternId { get; set; }
        public String patternName { get; set; }
        public Map<String, List<TimeRange>> weeklySchedule { get; set; }

        public PatternWithDateRange(Date sDate, Date eDate, Id pid, String name, Map<String, List<TimeRange>> schedule) {
            this.startDate = sDate;
            this.endDate = (eDate == null) ? Date.newInstance(4000, 1, 1) : eDate;
            this.patternId = pid;
            this.patternName = name;
            this.weeklySchedule = schedule;
        }
    }
    @TestVisible
private static String buildDriveOperationTypeWhere(List<String> driveOperationTypeFilter) {
    if (driveOperationTypeFilter == null || driveOperationTypeFilter.isEmpty()) return '';

    Set<String> sel = new Set<String>();
    for (String s : driveOperationTypeFilter) {
        if (String.isNotBlank(s)) sel.add(s.trim());
    }
    if (sel.isEmpty()) return '';
    return ' AND sked__Job__r.sked_Drive__r.sked_Drive_Operation_Type__c IN :driveOperationTypeFilter ';
}

}