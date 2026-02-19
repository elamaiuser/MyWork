public with sharing class TimeBlockComplianceReportController {
    public Date startDate { get; set; }
    public Date endDate { get; set; }
    public List<String> coList { get; set; }
    public List<Map<String, String>> reportData { get; set; }
    public DatableConfigWrapper wrapper { get; set; }
    public String acm { get; set; }

    private static final Set<String> ALLOWED_SORT_FIELDS = new Set<String>{
        'division', 'region', 'co', 'district', 'driveName', 'status', 'driveDate',
        'shiftStartTime', 'shiftEndTime', 'tbName', 'tbStartTime', 'tbEndTime',
        'tbEffStart', 'tbEffEnd', 'accountManager', 'staffRequested', 'siteName',
        'siteAddress', 'siteZip', 'type', 'violation', 'contentionResolution',
        'driveLink', 'tbLink', 'coLink', 'siteLink', 'accountManagerLink',
        'rowId','divisionLink','regionLink','districtLink'
    };

    private static final Map<String, String> SORT_FIELD_MAPPING = new Map<String, String>{
        'driveLink' => 'driveName',
        'tbLink' => 'tbName',
        'coLink' => 'co',
        'siteLink' => 'siteName',
        'accountManagerLink' => 'accountManager',
        'divisionLink' => 'division',
        'regionLink' => 'region',
        'districtLink' => 'district'
    };

    // Fields that need special sort keys (date/time)
    private static final Map<String, String> SORT_KEY_OVERRIDES = new Map<String, String>{
        'driveDate'       => 'driveDate__sort',
        'shiftStartTime'  => 'shiftStartTime__sort',
        'shiftEndTime'    => 'shiftEndTime__sort',
        'tbStartTime'     => 'tbStartTime__sort',
        'tbEndTime'       => 'tbEndTime__sort',
        'tbEffStart'      => 'tbEffStart__sort',
        'tbEffEnd'        => 'tbEffEnd__sort'
    };

    public Map<String, String> getSummary() {
        return wrapper != null ? wrapper.summary : new Map<String, String>();
    }

    public TimeBlockComplianceReportController() {
        String startParam          = ApexPages.currentPage().getParameters().get('startdate');
        String endParam            = ApexPages.currentPage().getParameters().get('enddate');
        String coParam             = ApexPages.currentPage().getParameters().get('co');
        String statusParam         = ApexPages.currentPage().getParameters().get('driveStatusFilter');
        String violationOnlyParam  = ApexPages.currentPage().getParameters().get('violationOnly');
        String timeBlockParam      = ApexPages.currentPage().getParameters().get('timeBlockFilter');
        String accountManagerParam = ApexPages.currentPage().getParameters().get('accountManagerName');

        startDate = String.isNotBlank(startParam) ? Date.valueOf(startParam) : null;
        endDate   = String.isNotBlank(endParam) ? Date.valueOf(endParam) : null;

        coList = String.isNotBlank(coParam) ? coParam.split(',') : new List<String>();
        List<String> driveStatusFilter = String.isNotBlank(statusParam) ? statusParam.split(',') : new List<String>();
        List<String> timeBlockIds      = String.isNotBlank(timeBlockParam) ? timeBlockParam.split(',') : new List<String>();

        Boolean onlyViolations = violationOnlyParam == 'true';

        if (String.isNotBlank(accountManagerParam) && accountManagerParam.toLowerCase() != 'undefined') {
            acm = accountManagerParam.trim();
        } else {
            acm = null;
        }

        wrapper = TimeBlockComplianceReportController.searchReport(
            startDate, endDate, coList, driveStatusFilter, onlyViolations, timeBlockIds, acm, null, null
        );
        reportData = wrapper != null ? wrapper.dataWrapper : new List<Map<String, String>>();
    }

    public class DatableConfigWrapper {
        @AuraEnabled public List<Map<String, String>> dataWrapper;
        @AuraEnabled public List<Map<String, Object>> columnsInfo;
        @AuraEnabled public Map<String, String> summary;
    }

    @AuraEnabled(cacheable=true)
    public static DatableConfigWrapper searchReport(
        Date startDateParam,
        Date endDateParam,
        List<String> coIds,
        List<String> driveStatusList,
        Boolean onlyViolations,
        List<String> timeBlockIds,
        String accountManagerName,
        String sortField,
        String sortDirection
    ) {
        DatableConfigWrapper wrapper = new DatableConfigWrapper();
        wrapper.dataWrapper = new List<Map<String, String>>();
        wrapper.columnsInfo = new List<Map<String, Object>>{
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
                'label' => 'Collection Operation',
                'fieldName' => 'coLink',
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{ 'fieldName' => 'co' },
                    'target' => '_blank'
                },
                'sortable' => true,
                'initialWidth' => 180
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
                'label' => 'District',
                'fieldName' => 'districtLink',
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{ 'fieldName' => 'district' },
                    'target' => '_blank'
                },
                'sortable' => true,
                'initialWidth' => 160
            },
            new Map<String, Object>{
                'label' => 'Drive Status',
                'fieldName' => 'status',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 130
            },
            new Map<String, Object>{
                'label' => 'Drive Date',
                'fieldName' => 'driveDate',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 120
            },
            new Map<String, Object>{
                'label' => 'Start Time',
                'fieldName' => 'shiftStartTime',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 110
            },
            new Map<String, Object>{
                'label' => 'End Time',
                'fieldName' => 'shiftEndTime',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 110
            },
            new Map<String, Object>{
                'label' => 'Time Block Name',
                'fieldName' => 'tbLink',
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{ 'fieldName' => 'tbName' },
                    'target' => '_blank'
                },
                'sortable' => true,
                'initialWidth' => 200
            },
            new Map<String, Object>{
                'label' => 'Time Block Start',
                'fieldName' => 'tbStartTime',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 140
            },
            new Map<String, Object>{
                'label' => 'Time Block End',
                'fieldName' => 'tbEndTime',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 140
            },
            new Map<String, Object>{
                'label' => 'TB Effective Start',
                'fieldName' => 'tbEffStart',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 150
            },
            new Map<String, Object>{
                'label' => 'TB Effective End',
                'fieldName' => 'tbEffEnd',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 150
            },
            new Map<String, Object>{
                'label' => 'Account Manager',
                'fieldName' => 'accountManagerLink',
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{ 'fieldName' => 'accountManager' },
                    'target' => '_blank'
                },
                'sortable' => true,
                'initialWidth' => 180
            },
            new Map<String, Object>{
                'label' => 'Staff Requested',
                'fieldName' => 'staffRequested',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 140
            },
            new Map<String, Object>{
                'label' => 'Site Name',
                'fieldName' => 'siteLink',
                'type' => 'url',
                'typeAttributes' => new Map<String, Object>{
                    'label' => new Map<String, Object>{ 'fieldName' => 'siteName' },
                    'target' => '_blank'
                },
                'sortable' => true,
                'initialWidth' => 200
            },
            new Map<String, Object>{
                'label' => 'Site Address',
                'fieldName' => 'siteAddress',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 240
            },
            new Map<String, Object>{
                'label' => 'Site Zip',
                'fieldName' => 'siteZip',
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
                'label' => 'Violation',
                'fieldName' => 'violation',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 110
            },
            new Map<String, Object>{
                'label' => 'Reason',
                'fieldName' => 'contentionResolution',
                'type' => 'text',
                'sortable' => true,
                'initialWidth' => 220
            }
        };


        if (String.isNotBlank(accountManagerName)) {
            accountManagerName = '%' + String.escapeSingleQuotes(accountManagerName) + '%';
        }

        String shiftQuery =
            'SELECT Id, sked_Start_Time__c, sked_End_Time__c, sked_Time_Block__c, sked_Time_Block__r.Name, sked_Time_Block__r.Start_Time__c, sked_Time_Block__r.End_Time__c, ' +
            'sked_Time_Block__r.Days_of_Week__c, sked_Contention_Resolution__c, sked_Drive__c, sked_Drive__r.Name, ' +
            'sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Status__c, sked_Drive__r.sked_Collection_Operation__c, ' +
            'sked_Drive__r.sked_Collection_Operation__r.Name, sked_Drive__r.Account_Manager__r.Name, sked_Drive__r.Account_Manager__c, ' +
            'sked_Drive__r.sked_Total_Staff_Requested__c, ' +
            'sked_Drive__r.sked_Drive_Site__r.Name, sked_Drive__r.sked_Drive_Site__r.sked_Address_1__c, sked_Drive__r.sked_Drive_Site__c, ' +
            'sked_Drive__r.sked_Drive_Site__r.sked_Zip_Code__c, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.Id, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.Name, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Id, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Name, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Id, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.sked_Parent__r.Name, ' +
            'sked_Drive__r.sked_Drive_Site__r.Operation_Type__c, sked_Drive__r.sked_Type_of_Drive__c ' +
            'FROM sked_Drive_Shift__c WHERE sked_Drive__r.sked_Drive_Date__c >= :startDateParam ' +
            'AND sked_Drive__r.sked_Drive_Date__c <= :endDateParam ' +
            'AND sked_Drive__r.sked_Collection_Operation__c IN :coIds ';

        if (driveStatusList != null && !driveStatusList.isEmpty()) {
            shiftQuery += ' AND sked_Drive__r.sked_Status__c IN :driveStatusList ';
        }
        if (String.isNotBlank(accountManagerName)) {
            shiftQuery += ' AND sked_Drive__r.Account_Manager__r.Name LIKE :accountManagerName';
        }
        if (timeBlockIds != null && !timeBlockIds.isEmpty()) {
            shiftQuery += ' AND sked_Time_Block__c IN :timeBlockIds';
        }

        shiftQuery += ' AND (sked_Drive__r.sked_Drive_Site__r.Operation_Type__c = \'Non Integrated WB\' OR sked_Drive__r.sked_Type_of_Drive__c = \'Mobile\')';

        List<sked_Drive_Shift__c> shifts = Database.query(shiftQuery);

        Map<Id, List<Collection_Operation_Time_Block__c>> coTbMap = new Map<Id, List<Collection_Operation_Time_Block__c>>();
        String tbQuery =
            'SELECT Collection_Operation__c, Time_Block__r.Name, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c, ' +
            'Time_Block__r.Days_of_Week__c, Effective_Start_Date__c, Effective_End_Date__c, Time_Block__c ' +
            'FROM Collection_Operation_Time_Block__c WHERE Collection_Operation__c IN :coIds';
        if (timeBlockIds != null && !timeBlockIds.isEmpty()) {
            tbQuery += ' AND Time_Block__c IN :timeBlockIds';
        }

        List<Collection_Operation_Time_Block__c> tbList = Database.query(tbQuery);

        for (Collection_Operation_Time_Block__c cotb : tbList) {
            if (!coTbMap.containsKey(cotb.Collection_Operation__c)) {
                coTbMap.put(cotb.Collection_Operation__c, new List<Collection_Operation_Time_Block__c>());
            }
            coTbMap.get(cotb.Collection_Operation__c).add(cotb);
        }

        Map<Id, Time_Block__c> tbMap = new Map<Id, Time_Block__c>();
        for (Collection_Operation_Time_Block__c cotb : tbList) {
            if (cotb.Time_Block__c != null && !tbMap.containsKey(cotb.Time_Block__c)) {
                tbMap.put(cotb.Time_Block__c, cotb.Time_Block__r);
            }
        }

        Integer violations = 0;

        for (sked_Drive_Shift__c shift : shifts) {
            Date driveDate = shift.sked_Drive__r.sked_Drive_Date__c;
            String dayOfWeek = DateTime.newInstance(driveDate, Time.newInstance(0, 0, 0, 0)).format('EEEE');
            List<Collection_Operation_Time_Block__c> cotbs = coTbMap.get(shift.sked_Drive__r.sked_Collection_Operation__c);

            String violationReason = '';
            String matchedStart = '', matchedEnd = '', effStart = '', effEnd = '', tbName = '';
            Date effStartDate, effEndDate;
            Boolean isViolation = false;

            Time_Block__c assignedTB = tbMap.get(shift.sked_Time_Block__c);

            if (assignedTB != null) {
                matchedStart = formatTime(assignedTB.Start_Time__c);
                matchedEnd = formatTime(assignedTB.End_Time__c);
                tbName = assignedTB.Name;

                if (cotbs != null) {
                    for (Collection_Operation_Time_Block__c cotb : cotbs) {
                        if (cotb.Time_Block__c == shift.sked_Time_Block__c) {
                            effStartDate = cotb.Effective_Start_Date__c;
                            effEndDate   = cotb.Effective_End_Date__c;
                            effStart = effStartDate != null ? String.valueOf(effStartDate) : '';
                            effEnd   = effEndDate != null ? String.valueOf(effEndDate) : '';
                            break;
                        }
                    }
                }

                if (assignedTB.Days_of_Week__c != null && assignedTB.Days_of_Week__c.contains(dayOfWeek)) {
                    if (!(assignedTB.Start_Time__c <= shift.sked_Start_Time__c && assignedTB.End_Time__c >= shift.sked_End_Time__c)) {
                        isViolation = true;
                        violationReason = 'Outside Time Block';
                    }
                } else {
                    isViolation = true;
                    violationReason = 'Day Mismatch in Time Block';
                }
            } else {
                Integer matchTime = 0;
                Integer matchDayDate = 0;

                if (cotbs != null && !cotbs.isEmpty()) {
                    for (Collection_Operation_Time_Block__c cotb : cotbs) {
                        Time_Block__c tb = tbMap.get(cotb.Time_Block__c);
                        if (tb == null) continue;

                        Boolean dateMatch = driveDate >= cotb.Effective_Start_Date__c && driveDate <= cotb.Effective_End_Date__c;
                        Boolean dayMatch = tb.Days_of_Week__c != null && tb.Days_of_Week__c.contains(dayOfWeek);

                        if (dateMatch && dayMatch) {
                            matchDayDate++;
                            if (tb.Start_Time__c <= shift.sked_Start_Time__c && tb.End_Time__c >= shift.sked_End_Time__c) {
                                matchTime++;
                            }
                        }
                    }

                    if (matchDayDate == 0) {
                        isViolation = false;
                        violationReason = 'No Matching Time Block for Day/Date';
                    } else if (matchTime == 0) {
                        isViolation = true;
                        violationReason = 'Missing Time Block';
                    } else if (matchTime > 1) {
                        isViolation = true;
                        violationReason = 'Fits Multiple Time Blocks';
                    }
                } else {
                    isViolation = false;
                    violationReason = 'No Time Block Available';
                }
            }

            if (shift.sked_Contention_Resolution__c != null) {
                isViolation = true;
                violationReason = shift.sked_Contention_Resolution__c;
            }

            if (!onlyViolations || isViolation) {
                Map<String, String> row = buildRow(
                    shift,
                    !isViolation,
                    matchedStart,
                    matchedEnd,
                    effStart,
                    effEnd,
                    tbName,
                    violationReason,
                    driveDate,
                    effStartDate,
                    effEndDate,
                    shift.sked_Start_Time__c,
                    shift.sked_End_Time__c,
                    assignedTB != null ? assignedTB.Start_Time__c : null,
                    assignedTB != null ? assignedTB.End_Time__c : null
                );

                wrapper.dataWrapper.add(row);
                if (isViolation) violations++;
            }
        }
        if (String.isNotBlank(sortField)) {
            String mappedSortField = SORT_FIELD_MAPPING.containsKey(sortField) ? SORT_FIELD_MAPPING.get(sortField) : sortField;
            if (ALLOWED_SORT_FIELDS.contains(mappedSortField)) {
                sortDataList(wrapper.dataWrapper, mappedSortField, sortDirection);
            }
        }

        Integer totalRecords = wrapper.dataWrapper.size();
        Integer violationPercentage = totalRecords > 0
            ? Integer.valueOf(Math.round((Decimal)violations * 100 / totalRecords))
            : 0;

        wrapper.summary = new Map<String, String>{
            'totalRecords' => String.valueOf(totalRecords),
            'totalViolations' => String.valueOf(violations),
            'violationPercentage' => String.valueOf(violationPercentage)
        };
        return wrapper;
    }
	@TestVisible
    private static void sortDataList(List<Map<String, String>> dataList, String fieldName, String direction) {
        if (dataList == null || dataList.size() < 2) return;

        Boolean isAscending = String.isBlank(direction) || direction.equalsIgnoreCase('asc');

        String effectiveField = SORT_KEY_OVERRIDES.containsKey(fieldName)
            ? SORT_KEY_OVERRIDES.get(fieldName)
            : fieldName;

        List<Map<String, String>> sorted = mergeSortMaps(dataList, effectiveField, isAscending);
        dataList.clear();
        dataList.addAll(sorted);
    }
	@TestVisible
    private static List<Map<String, String>> mergeSortMaps(List<Map<String, String>> input, String fieldName, Boolean isAscending) {
        Integer n = input.size();
        if (n <= 1) return input;

        Integer mid = n / 2;
        List<Map<String, String>> left = new List<Map<String, String>>();
        List<Map<String, String>> right = new List<Map<String, String>>();

        for (Integer i = 0; i < mid; i++) left.add(input[i]);
        for (Integer i = mid; i < n; i++) right.add(input[i]);

        left = mergeSortMaps(left, fieldName, isAscending);
        right = mergeSortMaps(right, fieldName, isAscending);

        return mergeMaps(left, right, fieldName, isAscending);
    }
		@TestVisible
    private static List<Map<String, String>> mergeMaps(
        List<Map<String, String>> left,
        List<Map<String, String>> right,
        String fieldName,
        Boolean isAscending
    ) {
        List<Map<String, String>> outList = new List<Map<String, String>>();
        Integer i = 0, j = 0;

        while (i < left.size() && j < right.size()) {
            String a = normalizeSortValue(left[i].get(fieldName));
            String b = normalizeSortValue(right[j].get(fieldName));

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
    private static String normalizeSortValue(String v) {
        return v == null ? '' : v.trim().toLowerCase();
    }

    private static Map<String, String> buildRow(
        sked_Drive_Shift__c shift,
        Boolean matched,
        String tbStart,
        String tbEnd,
        String effStart,
        String effEnd,
        String tbName,
        String contentionResolution,
        Date driveDate,
        Date tbEffStartDate,
        Date tbEffEndDate,
        Time shiftStart,
        Time shiftEnd,
        Time tbStartTime,
        Time tbEndTime
    ) {
        Map<String, String> row = new Map<String, String>();

        row.put('rowId', (String)shift.Id);

        row.put('driveId', shift.sked_Drive__c);
        row.put('timeBlockId', shift.sked_Time_Block__c);
        row.put('coId', shift.sked_Drive__r.sked_Collection_Operation__c);
        row.put('siteId', shift.sked_Drive__r.sked_Drive_Site__c);
        row.put('accountManagerId', shift.sked_Drive__r.Account_Manager__c);

        row.put('driveName', shift.sked_Drive__r.Name);
        row.put('status', shift.sked_Drive__r.sked_Status__c);

        // display strings
        row.put('driveDate', driveDate != null ? String.valueOf(driveDate) : '');
        row.put('shiftStartTime', formatTime(shiftStart));
        row.put('shiftEndTime', formatTime(shiftEnd));

        row.put('tbStartTime', tbStart);
        row.put('tbEndTime', tbEnd);
        row.put('tbEffStart', effStart);
        row.put('tbEffEnd', effEnd);
        row.put('tbName', tbName);

        row.put('accountManager', shift.sked_Drive__r.Account_Manager__r != null ? shift.sked_Drive__r.Account_Manager__r.Name : '');
        row.put('staffRequested', String.valueOf(shift.sked_Drive__r.sked_Total_Staff_Requested__c));

        row.put('siteName', shift.sked_Drive__r.sked_Drive_Site__r?.Name);
        row.put('siteAddress', shift.sked_Drive__r.sked_Drive_Site__r?.sked_Address_1__c);
        row.put('siteZip', shift.sked_Drive__r.sked_Drive_Site__r?.sked_Zip_Code__c);

        row.put('co', shift.sked_Drive__r.sked_Collection_Operation__r.Name);
        row.put('region', shift.sked_Drive__r.sked_Collection_Operation__r?.sked_Territory__r?.sked_Parent__r?.Name);
        row.put('district', shift.sked_Drive__r.sked_Collection_Operation__r?.sked_Territory__r?.Name);
        row.put('division', shift.sked_Drive__r.sked_Collection_Operation__r?.sked_Territory__r?.sked_Parent__r?.sked_Parent__r?.Name);

        row.put('type', shift.sked_Drive__r.sked_Type_of_Drive__c == 'Mobile'
            ? 'Mobile'
            : shift.sked_Drive__r.sked_Drive_Site__r?.Operation_Type__c);

        row.put('violation', matched ? 'false' : 'true');
        row.put('contentionResolution', contentionResolution);

        // ✅ hidden sort keys (CPU efficient: computed once per row)
        row.put('driveDate__sort', dateSortKey(driveDate));
        row.put('tbEffStart__sort', dateSortKey(tbEffStartDate));
        row.put('tbEffEnd__sort', dateSortKey(tbEffEndDate));

        row.put('shiftStartTime__sort', timeSortKey(shiftStart));
        row.put('shiftEndTime__sort', timeSortKey(shiftEnd));

        row.put('tbStartTime__sort', timeSortKey(tbStartTime));
        row.put('tbEndTime__sort', timeSortKey(tbEndTime));

        Id districtTerrId = shift.sked_Drive__r.sked_Collection_Operation__r?.sked_Territory__r?.Id;
        Id regionTerrId   = shift.sked_Drive__r.sked_Collection_Operation__r?.sked_Territory__r?.sked_Parent__r?.Id;
        Id divisionTerrId = shift.sked_Drive__r.sked_Collection_Operation__r?.sked_Territory__r?.sked_Parent__r?.sked_Parent__r?.Id;

        if (districtTerrId != null) row.put('districtLink', '/lightning/r/sked_Territory__c/' + districtTerrId + '/view');
        if (regionTerrId != null) row.put('regionLink', '/lightning/r/sked_Territory__c/' + regionTerrId + '/view');
        if (divisionTerrId != null) row.put('divisionLink', '/lightning/r/sked_Territory__c/' + divisionTerrId + '/view');

        if (shift.sked_Drive__c != null) row.put('driveLink', '/lightning/r/sked_Drive__c/' + shift.sked_Drive__c + '/view');
        if (shift.sked_Time_Block__c != null) row.put('tbLink', '/lightning/r/Time_Block__c/' + shift.sked_Time_Block__c + '/view');
        if (shift.sked_Drive__r.sked_Collection_Operation__c != null) row.put('coLink', '/lightning/r/Collection_Operation__c/' + shift.sked_Drive__r.sked_Collection_Operation__c + '/view');
        if (shift.sked_Drive__r.sked_Drive_Site__c != null) row.put('siteLink', '/lightning/r/sked_Drive_Site__c/' + shift.sked_Drive__r.sked_Drive_Site__c + '/view');
        if (shift.sked_Drive__r.Account_Manager__c != null) row.put('accountManagerLink', '/lightning/r/User/' + shift.sked_Drive__r.Account_Manager__c + '/view');

        return row;
    }
    @TestVisible
    private static String formatTime(Time t) {
        if (t == null) return '';
        String h = t.hour() < 10 ? '0' + t.hour() : String.valueOf(t.hour());
        String m = t.minute() < 10 ? '0' + t.minute() : String.valueOf(t.minute());
        return h + ':' + m;
    }
	@TestVisible
    private static String dateSortKey(Date d) {
        if (d == null) return '';
        String y = String.valueOf(d.year());
        String m = d.month() < 10 ? '0' + d.month() : String.valueOf(d.month());
        String day = d.day() < 10 ? '0' + d.day() : String.valueOf(d.day());
        return y + m + day; // yyyyMMdd
    }
	@TestVisible
    private static String timeSortKey(Time t) {
        if (t == null) return '';
        Integer mins = (t.hour() * 60) + t.minute();
        String s = String.valueOf(mins);
        while (s.length() < 5) s = '0' + s; // 00000..01439
        return s;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTimeBlockPicklistByCO(List<String> coIds) {
        Set<Id> tbIds = new Set<Id>();
        for (Collection_Operation_Time_Block__c cotb : [
            SELECT Time_Block__c
            FROM Collection_Operation_Time_Block__c
            WHERE Collection_Operation__c IN :coIds
        ]) {
            if (cotb.Time_Block__c != null) tbIds.add(cotb.Time_Block__c);
        }

        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Time_Block__c tb : [SELECT Id, Name FROM Time_Block__c WHERE Id IN :tbIds ORDER BY Name]) {
            options.add(new Map<String, String>{ 'label' => tb.Name, 'value' => tb.Id });
        }
        return options;
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
}