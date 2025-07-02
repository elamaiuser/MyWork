public with sharing class TimeBlockComplianceReportController {
    public Date startDate { get; set; }
    public Date endDate { get; set; }
    public List<String> coList { get; set; }
    public List<Map<String, String>> reportData { get; set; }
    public DatableConfigWrapper wrapper { get; set; }
    public String acm { get; set; }
    public Map<String, String> getSummary() {
        return wrapper != null ? wrapper.summary : new Map<String, String>();
    }
    
    public TimeBlockComplianceReportController() {
        String startParam         = ApexPages.currentPage().getParameters().get('startdate');
        String endParam           = ApexPages.currentPage().getParameters().get('enddate');
        String coParam            = ApexPages.currentPage().getParameters().get('co');
        String statusParam        = ApexPages.currentPage().getParameters().get('driveStatusFilter');
        String violationOnlyParam = ApexPages.currentPage().getParameters().get('violationOnly');
        String timeBlockParam     = ApexPages.currentPage().getParameters().get('timeBlockFilter');
        String accountManagerParam = ApexPages.currentPage().getParameters().get('accountManagerName');
        
        startDate = String.isNotBlank(startParam) ? Date.valueOf(startParam) : null;
        endDate = String.isNotBlank(endParam) ? Date.valueOf(endParam) : null;
        
        coList = String.isNotBlank(coParam) ? coParam.split(',') : new List<String>();
        List<String> driveStatusFilter = String.isNotBlank(statusParam) ? statusParam.split(',') : new List<String>();
        List<String> timeBlockIds = String.isNotBlank(timeBlockParam) ? timeBlockParam.split(',') : new List<String>();
        
        Boolean onlyViolations = violationOnlyParam == 'true';
        
        if (String.isNotBlank(accountManagerParam) && accountManagerParam.toLowerCase() != 'undefined') {
            acm = accountManagerParam.trim();
        } else {
            acm = null;
        }
        
        wrapper = TimeBlockComplianceReportController.searchReport(
            startDate,
            endDate,
            coList,
            driveStatusFilter,
            onlyViolations,
            timeBlockIds,
            acm
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
        String accountManagerName 
    ) {
        System.debug('--- searchReport Method Input ---');
        System.debug('startDt: ' + startDateParam);
        System.debug('endDt: ' + endDateParam);
        System.debug('coList: ' + coIds);
        System.debug('driveStatusFilter: ' + driveStatusList);
        System.debug('violationOnly: ' + onlyViolations);
        
        DatableConfigWrapper wrapper = new DatableConfigWrapper();
        wrapper.dataWrapper = new List<Map<String, String>>();
        wrapper.columnsInfo = new List<Map<String, Object>>{
            new Map<String, Object>{ 'label' => 'Division', 'fieldName' => 'division', 'type' => 'text' },    
                new Map<String, Object>{ 'label' => 'Region', 'fieldName' => 'region', 'type' => 'text' },
                    new Map<String, Object>{ 'label' => 'Collection Operation', 'fieldName' => 'co', 'type' => 'text' },
                        new Map<String, Object>{ 'label' => 'District', 'fieldName' => 'district', 'type' => 'text' },   
                            new Map<String, Object>{ 'label' => 'Drive Name', 'fieldName' => 'driveName', 'type' => 'text' },
                                new Map<String, Object>{ 'label' => 'Drive Status', 'fieldName' => 'status', 'type' => 'text' },
                                    new Map<String, Object>{ 'label' => 'Drive Date', 'fieldName' => 'driveDate', 'type' => 'text' },
                                        new Map<String, Object>{ 'label' => 'Start Time', 'fieldName' => 'shiftStartTime', 'type' => 'text' },
                                            new Map<String, Object>{ 'label' => 'End Time', 'fieldName' => 'shiftEndTime', 'type' => 'text' },
                                                new Map<String, Object>{ 'label' => 'Time Block Name', 'fieldName' => 'tbName', 'type' => 'text' },
                                                    new Map<String, Object>{ 'label' => 'Time Block Start', 'fieldName' => 'tbStartTime', 'type' => 'text' },
                                                        new Map<String, Object>{ 'label' => 'Time Block End', 'fieldName' => 'tbEndTime', 'type' => 'text' },
                                                            new Map<String, Object>{ 'label' => 'TB Effective Start', 'fieldName' => 'tbEffStart', 'type' => 'text' },
                                                                new Map<String, Object>{ 'label' => 'TB Effective End', 'fieldName' => 'tbEffEnd', 'type' => 'text' },
                                                                    new Map<String, Object>{ 'label' => 'Account Manager', 'fieldName' => 'accountManager', 'type' => 'text' },
                                                                        new Map<String, Object>{ 'label' => 'Staff Requested', 'fieldName' => 'staffRequested', 'type' => 'text' },
                                                                            new Map<String, Object>{ 'label' => 'Projection', 'fieldName' => 'projection', 'type' => 'text' },
                                                                                new Map<String, Object>{ 'label' => 'Site Name', 'fieldName' => 'siteName', 'type' => 'text' },
                                                                                    new Map<String, Object>{ 'label' => 'Site Address', 'fieldName' => 'siteAddress', 'type' => 'text' },
                                                                                        new Map<String, Object>{ 'label' => 'Site Zip', 'fieldName' => 'siteZip', 'type' => 'text' },
                                                                                            new Map<String, Object>{ 'label' => 'Type', 'fieldName' => 'type', 'type' => 'text' },
                                                                                                new Map<String, Object>{ 'label' => 'Violation', 'fieldName' => 'violation', 'type' => 'text' },
                                                                                                    new Map<String, Object>{ 'label' => 'Reason', 'fieldName' => 'contentionResolution', 'type' => 'text' }
        };
            
            if (String.isNotBlank(accountManagerName)) {
                accountManagerName = '%' + String.escapeSingleQuotes(accountManagerName) + '%';
            }
        
        String shiftQuery = 'SELECT Id, sked_Start_Time__c, sked_End_Time__c,sked_Time_Block__c,sked_Time_Block__r.Name, sked_Time_Block__r.Start_Time__c, sked_Time_Block__r.End_Time__c, ' +
            'sked_Time_Block__r.Days_of_Week__c, sked_Contention_Resolution__c, sked_Drive__c, sked_Drive__r.Name, ' +
            'sked_Drive__r.sked_Drive_Date__c, sked_Drive__r.sked_Status__c, sked_Drive__r.sked_Collection_Operation__c, ' +
            'sked_Drive__r.sked_Collection_Operation__r.Name, sked_Drive__r.Account_Manager__r.Name, ' +
            'sked_Drive__r.sked_Total_Staff_Requested__c, sked_Drive__r.Projection__c, ' +
            'sked_Drive__r.sked_Drive_Site__r.Name, sked_Drive__r.sked_Drive_Site__r.sked_Address_1__c, ' +
            'sked_Drive__r.sked_Drive_Site__r.sked_Zip_Code__c, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.Name, ' +
            'sked_Drive__r.sked_Collection_Operation__r.sked_Territory__r.sked_Parent__r.Name, ' +
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
        String tbQuery = 'SELECT Collection_Operation__c, Time_Block__r.Name, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c, ' +
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
    Boolean isViolation = false;

    Time_Block__c assignedTB = tbMap.get(shift.sked_Time_Block__c);
    if (assignedTB != null) {
        matchedStart = formatTime(assignedTB.Start_Time__c);
        matchedEnd = formatTime(assignedTB.End_Time__c);
        tbName = assignedTB.Name;
        if (cotbs != null) {
        for (Collection_Operation_Time_Block__c cotb : cotbs) {
            if (cotb.Time_Block__c == shift.sked_Time_Block__c) {
                effStart = String.valueOf(cotb.Effective_Start_Date__c);
                effEnd = String.valueOf(cotb.Effective_End_Date__c);
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
        isViolation = false;
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
            violationReason
        );
        wrapper.dataWrapper.add(row);
        if (isViolation) violations++;
    }
}

Integer totalRecords = wrapper.dataWrapper.size();
Integer violationPercentage = totalRecords > 0 ? Integer.valueOf(Math.round((Decimal)violations * 100 / totalRecords)) : 0;
wrapper.summary = new Map<String, String>{
    'totalRecords' => String.valueOf(totalRecords),
    'totalViolations' => String.valueOf(violations),
    'violationPercentage' => String.valueOf(violationPercentage)
};
return wrapper;

    }
    
    
    
    private static Map<String, String> buildRow(
        sked_Drive_Shift__c shift,
        Boolean matched,
        String tbStart,
        String tbEnd,
        String effStart,
        String effEnd,
        string tbName,
        String contentionResolution
    ) {
        Map<String, String> row = new Map<String, String>();
        row.put('driveName', shift.sked_Drive__r.Id);
        row.put('status', shift.sked_Drive__r.sked_Status__c);
        row.put('driveDate', String.valueOf(shift.sked_Drive__r.sked_Drive_Date__c));
        row.put('shiftStartTime', formatTime(shift.sked_Start_Time__c));
        row.put('shiftEndTime', formatTime(shift.sked_End_Time__c));
        row.put('tbStartTime', tbStart);
        row.put('tbEndTime', tbEnd);
        row.put('tbEffStart', effStart);
        row.put('tbEffEnd', effEnd);
        row.put('tbName',tbName);
        row.put('accountManager', shift.sked_Drive__r.Account_Manager__r != null ? shift.sked_Drive__r.Account_Manager__r.Name : '');
        row.put('staffRequested', String.valueOf(shift.sked_Drive__r.sked_Total_Staff_Requested__c));
        row.put('projection', String.valueOf(shift.sked_Drive__r.Projection__c));
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
        return row;
    }
    
    private static String formatTime(Time t) {
        if (t == null) return '';
        String h = t.hour() < 10 ? '0' + t.hour() : String.valueOf(t.hour());
        String m = t.minute() < 10 ? '0' + t.minute() : String.valueOf(t.minute());
        return h + ':' + m;
    }
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTimeBlockPicklistByCO(List<String> coIds) {
        System.debug('>>> CO IDs passed to getTimeBlockPicklistByCO: ' + coIds);
        
        Set<Id> tbIds = new Set<Id>();
        for (Collection_Operation_Time_Block__c cotb : [
            SELECT Time_Block__c 
            FROM Collection_Operation_Time_Block__c 
            WHERE Collection_Operation__c IN :coIds
        ]) {
            if (cotb.Time_Block__c != null) {
                tbIds.add(cotb.Time_Block__c);
            }
        }
        
        System.debug('>>> Time Block IDs mapped from CO: ' + tbIds);
        
        List<Map<String, String>> options = new List<Map<String, String>>();
        for (Time_Block__c tb : [
            SELECT Id, Name 
            FROM Time_Block__c 
            WHERE Id IN :tbIds 
            ORDER BY Name
        ]) {
            options.add(new Map<String, String>{
                'label' => tb.Name,
                    'value' => tb.Id
                    });
        }
        
        System.debug('>>> Final Time Block options: ' + options);
        
        return options;
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
    
    
}