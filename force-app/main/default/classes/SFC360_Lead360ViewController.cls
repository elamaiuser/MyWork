/**
 * Controller for SFC360 Lead / Account 360 view.
 *
 * This class:
 *  - Fetches Unified Account Id from Data Cloud
 *  - Queries multiple Data Cloud objects using ANSI SQL
 *  - Aggregates Blood Drive, Training, Revenue, Activity, Contracts, Gifts data
 *  - Returns data in wrapper classes for LWC / Aura components
 *
 * All queries are executed using ConnectApi.CdpQuery (Data Cloud).
 */
public with sharing class SFC360_Lead360ViewController {

    // -----------------------------
    // Data Cloud SQL Queries
    // -----------------------------
    // These constants store ANSI SQL queries used to fetch
    // various Account and Activity details from Data Cloud.

    // Fetch related Account details excluding Leads
    public static final String SQL_ACCOUNT_DETAILS = 'SELECT DISTINCT ' +
        'ssot__Account__dlm.KQ_Id__c AS org_name, ' +
        'ssot__Account__dlm.ssot__Name__c AS acc_name, ' +
        'addr.Address, ' +
        'addr.City, ' +
        'addr.State, ' +
        'addr.ZipCode, ' +
        'phn.Phone, ' +
        'ssot__User__dlm.ssot__FullName__c AS account_manager_name__c, ' +
        'ssot__Account__dlm.ssot__Id__c AS account_rec_id__c ' +
        'FROM UnifiedssotAccountUa1__dlm ' +
        'JOIN UnifiedLinkssotAccountUa1__dlm ' +
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c ' +
        'JOIN ssot__Account__dlm ' +
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c ' +
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c ' +
        'LEFT JOIN ( ' +
            'SELECT ' +
                'ssot__PartyId__c, ' +
                'KQ_Id__c, ' +
                'MAX(ssot__AddressLine1__c) AS Address, ' +
                'MAX(ssot__CityId__c) AS City, ' +
                'MAX(ssot__StateProvinceId__c) AS State, ' +
                'MAX(ssot__PostalCodeId__c) AS ZipCode ' +
            'FROM ssot__ContactPointAddress__dlm ' +
            'GROUP BY ssot__PartyId__c, KQ_Id__c ' +
        ') addr ' +
        'ON ssot__Account__dlm.ssot__Id__c = addr.ssot__PartyId__c ' +
        'AND ssot__Account__dlm.KQ_Id__c = addr.KQ_Id__c ' +
        'LEFT JOIN ( ' +
            'SELECT ' +
                'ssot__PartyId__c, ' +
                'KQ_Id__c, ' +
                'MAX(ssot__FormattedE164PhoneNumber__c) AS Phone ' +
            'FROM ssot__ContactPointPhone__dlm ' +
            'GROUP BY ssot__PartyId__c, KQ_Id__c ' +
        ') phn ' +
        'ON ssot__Account__dlm.ssot__Id__c = phn.ssot__PartyId__c ' +
        'AND ssot__Account__dlm.KQ_Id__c = phn.KQ_Id__c ' +
        'LEFT JOIN ssot__User__dlm ' +
        'ON ssot__Account__dlm.ssot__OwnerId__c = ssot__User__dlm.ssot__Id__c ' +
        'AND ssot__Account__dlm.KQ_OwnerId__c = ssot__User__dlm.KQ_Id__c ' +
        'WHERE ssot__Account__dlm.ssot__AccountTypeId__c != \'Lead\' ' +
        'AND UnifiedssotAccountUa1__dlm.ssot__Id__c = {0}';
    
    // Base query used to derive Unified Account Id
    private static final String SQL_GET_UNIFIED_ID_BASE =
        'SELECT UnifiedssotAccountUa1__dlm.ssot__Id__c AS unified_account_id__c ' +
        'FROM UnifiedssotAccountUa1__dlm ' +
        'JOIN UnifiedLinkssotAccountUa1__dlm ' +
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c ' +
        'JOIN ssot__Account__dlm ' +
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c ' +
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c';

    // Fetches account managers mapped to unified account
    private static final String SQL_ACCOUNT_MANAGERS =
        'SELECT account_manager_name__c, account_manager_email__c, org_identifier__c ' +
        'FROM SFC_Lead360_Account_Managers__cio ' +
        'WHERE unified_account_id__c = {0}';

    // Fetches CGTS-specific account managers
    private static final String SQL_ACCOUNT_MANAGERS_CGTS =
        'SELECT account_manager_name__c, account_manager_email__c, org_identifier__c ' +
        'FROM SFC_Lead360_CGTS_Account_Managers__cio ' +
        'WHERE unified_account_id__c = {0}';    

    // Fetches activity counts grouped by closed/open and source
    private static final String SQL_ACTIVITY_SUMMARY =
        'SELECT account_id__c, activity_count__c, is_closed__c, source_system__c ' +
        'FROM SFC360_Account_Activity_Summary__cio ' +
        'WHERE unified_account_id__c = {0}';

    // Fetches detailed activity records ordered by date
    private static final String SQL_ACTIVITY_MODAL =
        'SELECT activity_date__c, completed_datetime__c, is_closed__c, priority__c, source_system__c, ' +
        'status__c, subject__c, task_sub_type__c, task_owner_name__c, task_id__c ' +
        'FROM SFC360_Account_Activity__cio ' +
        'WHERE account_id__c = {0} ' +
        'ORDER BY activity_date__c DESC';

    // Fetches count of related Account records (Account Id starts with 001)
    private static final String SQL_RELATED_ACC =
        'SELECT COUNT(account_name__c) AS account_count ' +
        'FROM SFC_Lead360_Account_Managers__cio ' +
        'WHERE account_id__c LIKE \'001%\' and unified_account_id__c = {0}';

    /**
     * Main entry point called from UI.
     *
     * Steps:
     *  1. Validate input parameters
     *  2. Fetch Unified Account Id based on source object (Account / Lead)
     *  3. Populate all 360 view sections using helper methods
     *
     * @param params Map containing source record Id and object API name
     * @return ConstituentDataWrapper populated with 360 data
     */
    @AuraEnabled
    public static ConstituentDataWrapper queryDataCloud(Map<String, Object> params) {
        ConstituentDataWrapper result = new ConstituentDataWrapper();
        if (params == null) {
            return result;
        }

        // Extract parameters safely
        String objectAPIName = safeGetString(params, 'dataSourceObjectId');
        String recId = safeGetString(params, 'sourceRecId');
        if (String.isBlank(objectAPIName) || String.isBlank(recId)) {
            return result;
        }

        // Get Unified Account Id from Data Cloud
        String ufid = getUnifiedId(objectAPIName, recId);
        System.debug('------ufid :' + ufid);
        if (String.isBlank(ufid)) {
            return result;
        }
        result.unifiedId = ufid;

        // Populate different sections of 360 view        
        populateAccountManagers(ufid, result);
        populateCGTSAccountManagers(ufid, result);       
        populateActivitySummary(ufid, result);
        populateRelatedAccountsCount(ufid, result);

        return result;
    }

    /**
     * Fetches activity details for Activity modal popup.
     * Groups activities by Month / Year.
     *
     * @param accId Account Id
     * @return ActivityModalWrapper containing grouped activity records
     */
    @AuraEnabled
    public static ActivityModalWrapper queryActivityModal(String accId) {
        ActivityModalWrapper result = new ActivityModalWrapper();
        if (String.isBlank(accId)) {
            return result;
        }

        String sql = String.format(SQL_ACTIVITY_MODAL, new List<String>{'\'' + accId + '\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;

        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) {
            return result;
        }

        Map<String, List<Activities>> tempMap = new Map<String, List<Activities>>();
        List<String> orderedKeys = new List<String>();
        List<Activities> noDateActivities = new List<Activities>();

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) {
                continue;
            }

            Activities act = new Activities();
            act.taskId = safeGetString(row, 'task_id__c');
            act.subject = safeGetString(row, 'subject__c');
            String compDate = safeGetString(row, 'completed_datetime__c');
            if (!String.isBlank(compDate)) {
                // keep only date part if datetime
                if (compDate.contains('T')) {
                    compDate = compDate.split('T')[0];
                }
            }
            act.completeDate = compDate;
            act.status = safeGetString(row, 'status__c');
            act.priority = safeGetString(row, 'priority__c');
            act.isClosed = safeGetString(row, 'is_closed__c');
            act.type = safeGetString(row, 'task_sub_type__c');
            act.ownerName = safeGetString(row, 'task_owner_name__c');
            act.isUpcoming = (act.status != null && !act.status.equalsIgnoreCase('Completed'));

            String dt = safeGetString(row, 'activity_date__c');
            if (!String.isBlank(dt)) {
                try {
                    Date toDateTime = Date.valueOf(dt);
                    DateTime activityDate = DateTime.newInstance(toDateTime.year(), toDateTime.month(), toDateTime.day());
                    String monthName = activityDate.format('MMMM');
                    String year = String.valueOf(activityDate.year());
                    String currentYear = String.valueOf(Date.today().year());
                    String formattedDate = (year == currentYear) ? (monthName + ' - ' + year) : year;

                    if (!tempMap.containsKey(formattedDate)) {
                        tempMap.put(formattedDate, new List<Activities>());
                        orderedKeys.add(formattedDate);
                    }
                    tempMap.get(formattedDate).add(act);
                } catch (Exception e) {
                    // parsing failed -> treat as no date
                    noDateActivities.add(act);
                }
            } else {
                noDateActivities.add(act);
            }
        }

        List<ActivityGroup> orderedActivityGroups = new List<ActivityGroup>();
        for (String key : orderedKeys) {
            ActivityGroup ag = new ActivityGroup();
            ag.groupLabel = key;
            ag.activities = tempMap.get(key);
            orderedActivityGroups.add(ag);
        }
        if (!noDateActivities.isEmpty()) {
            ActivityGroup others = new ActivityGroup();
            others.groupLabel = 'Others';
            others.activities = noDateActivities;
            orderedActivityGroups.add(others);
        }
        result.activityData = orderedActivityGroups;
        return result;
    }

    /**
     * Fetches related Account details for modal popup.
     *
     * @param unifiedAccId Unified Account Id
     * @return AccountDetailsModalWrapper containing account records
     */
    @AuraEnabled
    public static AccountDetailsModalWrapper queryRelatedAccountDetails(String unifiedAccId) {
        AccountDetailsModalWrapper result = new AccountDetailsModalWrapper();
        List<AccountDetails> accountDetailsList = new List<AccountDetails>();
        if (String.isBlank(unifiedAccId)) {
            return result;
        }
        String sql = String.format(SQL_ACCOUNT_DETAILS, new List<String>{'\'' + unifiedAccId + '\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        System.debug('------query  :' + sql);
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        System.debug('------resp  :' + resp);
        if (resp == null || resp.rowCount == 0) {
            return result;
        }

        for (Object record : resp.data) {
            Map<String, Object> row = deserializeData(record);
            if (row == null) {
                continue;
            }
            AccountDetails accRelatedDetail = new AccountDetails();
            accRelatedDetail.accountName = safeGetString(row, 'acc_name');
            accRelatedDetail.orgName = safeGetString(row, 'org_name');
            accRelatedDetail.accRecId = safeGetString(row, 'account_rec_id__c');
            accRelatedDetail.accManager = safeGetString(row, 'account_manager_name__c');
            accRelatedDetail.accAddress = safeGetString(row, 'Address');
            accRelatedDetail.accCity = safeGetString(row, 'City');
            accRelatedDetail.accState = safeGetString(row, 'State');
            accRelatedDetail.accZipcode = safeGetString(row, 'ZipCode');
            accRelatedDetail.accPhone = safeGetString(row, 'Phone');
            accountDetailsList.add(accRelatedDetail);
        }
        result.accountData = accountDetailsList;
        System.debug('------result of acc details  :' + JSON.serialize(result));
        return result;
    }

    /**
     * Returns Unified Account Id for given source record.
     *
     * Supports:
     *  - Account
     *  - Lead
     *
     * @param objectAPIName Source object name
     * @param recId Source record Id
     * @return Unified Account Id from Data Cloud
     */
    private static String getUnifiedId(String objectAPIName, String recId) {
        if (String.isBlank(objectAPIName) || String.isBlank(recId)) {
            return null;
        }

        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        String sql = SQL_GET_UNIFIED_ID_BASE;
        String safeRecId = String.escapeSingleQuotes(recId);
        if (objectAPIName.equalsIgnoreCase('Account')) {
            sql += ' WHERE ssot__Account__dlm.ssot__Id__c = \'' + safeRecId + '\'';
        } else if (objectAPIName.equalsIgnoreCase('Lead')) {
            sql += ' JOIN ssot__Lead__dlm ' +
                'ON ssot__Account__dlm.ssot__Id__c = ssot__Lead__dlm.ssot__Id__c ' +
                'AND ssot__Account__dlm.KQ_Id__c = ssot__Lead__dlm.KQ_Id__c ' +
                'WHERE ssot__Lead__dlm.ssot__Id__c = \'' + safeRecId + '\'';
        } else {
            // other object types not supported
            return null;
        }

        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) {
            return null;
        }

        try {
            String ufidFromResponse = '';
            for (Object record : resp.data) {
                Map<String, Object> row = deserializeData(record);
                if (row == null) {
                    return null;
                }
                ufidFromResponse = safeGetString(row, 'unified_account_id__c');
            }
            return ufidFromResponse;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Fetches Account Managers and groups them
     * by organization (HS, FR, TS, BioMed).
     */
    private static void populateAccountManagers(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) {
            return;
        }
        String sql = String.format(SQL_ACCOUNT_MANAGERS, new List<String>{'\'' + ufid + '\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) {
            result.accAmDetails = new Map<String, List<ConstituentDataWrapper.AMDetail>>();
            return;
        }

        List<ConstituentDataWrapper.AMDetail> bioMed = new List<ConstituentDataWrapper.AMDetail>();
        List<ConstituentDataWrapper.AMDetail> hs = new List<ConstituentDataWrapper.AMDetail>();
        List<ConstituentDataWrapper.AMDetail> fr = new List<ConstituentDataWrapper.AMDetail>();
        List<ConstituentDataWrapper.AMDetail> ts = new List<ConstituentDataWrapper.AMDetail>();

        for (Object record : resp.data) {
            Map<String, Object> row = deserializeData(record);
            if (row == null) {
                continue;
            }
            String org = safeGetString(row, 'org_identifier__c');
            String name = safeGetString(row, 'account_manager_name__c');
            String email = safeGetString(row, 'account_manager_email__c');
            if (String.isBlank(name) || String.isBlank(email) || String.isBlank(org)) {
                continue;
            }

            ConstituentDataWrapper.AMDetail d = new ConstituentDataWrapper.AMDetail(name, email, org);
            if (org.equalsIgnoreCase('BioMedSF')) {
                bioMed.add(d);
            } else if (org.equalsIgnoreCase('HospitalSales')) {
                hs.add(d);
            } else if (org.equalsIgnoreCase('FundRaising')) {
                fr.add(d);
            } else if (org.equalsIgnoreCase('TrainingServices')) {
                ts.add(d);
            }
        }
        System.debug('bioMedAM ' + bioMed + '\n' + 'HSAM ' + hs + '\n' + 'FRAM ' + fr + '\n' + 'TSAM ' + ts);

        result.accAmDetails = new Map<String, List<ConstituentDataWrapper.AMDetail>>();
        result.accAmDetails.put('TrainingServices', ts);
        result.accAmDetails.put('BioMedSF', bioMed);
        result.accAmDetails.put('HospitalSales', hs);
        result.accAmDetails.put('Fundraising', fr);
    }

    /**
     * Fetches Account Managers for CGTS and groups them
     * by organization (HS).
     */
    private static void populateCGTSAccountManagers(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) {
            return;
        }
        String sql = String.format(SQL_ACCOUNT_MANAGERS_CGTS, new List<String>{'\'' + ufid + '\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        List<ConstituentDataWrapper.AMDetail> cgts = new List<ConstituentDataWrapper.AMDetail>();
        if (resp != null && resp.rowCount > 0) {
            for (Object record : resp.data) {
                Map<String, Object> row = deserializeData(record);
                if (row == null) {
                    continue;
                }
                String org = safeGetString(row, 'org_identifier__c');
                String name = safeGetString(row, 'account_manager_name__c');
                String email = safeGetString(row, 'account_manager_email__c');
                if (String.isBlank(name) || String.isBlank(email)) {
                    continue;
                }
                if (org != null && org.equalsIgnoreCase('HospitalSales')) {
                    cgts.add(new ConstituentDataWrapper.AMDetail(name, email, org));
                }
            }
        }
        // ensure map exists
        if (result.accAmDetails == null) {
            result.accAmDetails = new Map<String, List<ConstituentDataWrapper.AMDetail>>();
        }
        result.accAmDetails.put('Cell Gene Therapy', cgts);
    }

    /**
     * Populates Activity summary counts by organization.
     *
     * Organizations:
     *  - FRF (Fundraising)
     *  - HS  (Hospital Sales)
     *  - TS  (Transfusion Services)
     *
     * Separates:
     *  - Total activities
     *  - Open activities
     */
    private static void populateActivitySummary(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) {
            return;
        }
        String sql = String.format(SQL_ACTIVITY_SUMMARY, new List<String>{'\'' + ufid + '\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) {
            return;
        }

        Integer frfTotalCount = 0;
        Integer hsTotalCount = 0;
        Integer frfOpenCount = 0;
        Integer hsOpenCount = 0;
        Integer tsOpenCount = 0;
        Integer tsTotalCount = 0;

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) {
                continue;
            }
            String org = safeGetString(row, 'source_system__c');
            String isClosed = safeGetString(row, 'is_closed__c');
            Integer activityCount = safeGetInteger(row, 'activity_count__c');
            String accountId = safeGetString(row, 'account_id__c');

            if (activityCount == null) {
                activityCount = 0;
            }

            if (org.equalsIgnoreCase('FundRaising')) {
                frfTotalCount += activityCount;
                if ('false'.equalsIgnoreCase(isClosed)) {
                    frfOpenCount += activityCount;
                }
                result.frActivityAccId = accountId;
            } else if (org.equalsIgnoreCase('HospitalSales')) {
                hsTotalCount += activityCount;
                if ('false'.equalsIgnoreCase(isClosed)) {
                    hsOpenCount += activityCount;
                }
                result.hsActivityAccId = accountId;
            } else if (org.equalsIgnoreCase('TrainingServices')) {
                tsTotalCount += activityCount;
                if ('false'.equalsIgnoreCase(isClosed)) {
                    tsOpenCount += activityCount;
                }
                result.tsActivityAccId = accountId;
            }
        }

        result.openActivityFR = frfOpenCount;
        result.totalActivityFR = frfTotalCount;
        result.openActivityHS = hsOpenCount;
        result.totalActivityHS = hsTotalCount;
        result.openActivityTS = tsOpenCount;
        result.totalActivityTS = tsTotalCount;
    }

    /**
     * Populates count of related Accounts.
     *
     * Counts:
     *  - Accounts linked to unified account
     *  - Only Account records (Id starts with 001)
     */
    private static void populateRelatedAccountsCount(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) {
            return;
        }
        String sql = String.format(SQL_RELATED_ACC, new List<String>{'\'' + ufid + '\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) {
            return;
        }

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) {
                continue;
            }
            result.numberOfAccounts = safeGetInteger(row, 'account_count');
        }
    }

    // -----------------------------
    // Utility / Safe Helper Methods
    // -----------------------------

    /**
     * Safely converts an Object value to Integer.
     *
     * Handles:
     *  - Integer values directly
     *  - String values
     *  - Nulls and invalid formats gracefully
     *
     * @param v Input object
     * @return Integer value or null if conversion fails
     */
    private static Integer safeConvertToInteger(Object v) {
        if (v == null) {
            return null;
        }
        try {
            if (v instanceof Integer) {
                return (Integer) v;
            }
            String s = String.valueOf(v);
            if (String.isBlank(s)) {
                return null;
            }
            return Integer.valueOf(s.split('\\.')[0]); // handle decimals
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Safely fetches an Integer value from a Map.
     *
     * @param m Source map
     * @param key Field key
     * @return Integer value or null
     */
    private static Integer safeGetInteger(Map<String, Object> m, String key) {
        if (m == null) {
            return null;
        }
        Object v = m.get(key);
        return safeConvertToInteger(v);
    }

    /**
     * Safely extracts String value from Map.
     *
     * @param params Source map
     * @param key Field key
     * @return String value or null
     */
    public static String safeGetString(Map<String, Object> params, String key) {
        if (params == null || String.isBlank(key)) {
            return null;
        }
        Object v = params.get(key);
        if (v == null) {
            return null;
        }
        return String.valueOf(v);
    }

    /**
     * Executes ANSI SQL safely and returns Data Cloud response.
     * Any exception is caught to avoid breaking UI.
     *
     * @param q Query input
     * @return Query output or null if execution fails
     */
    public static ConnectApi.CdpQueryOutput safeQueryAnsiSql(ConnectApi.CdpQueryInput q) {
        try {
            ConnectApi.CdpQueryOutput responseData = ConnectApi.CdpQuery.queryAnsiSql(q);
            System.debug('responseData ' + responseData);
            return responseData;
        } catch (Exception e) {
            System.debug('CDP queryAnsiSql failed: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Converts Data Cloud row object into Map<String, Object>
     * using JSON serialization.
     *
     * @param record Row object from Data Cloud response
     * @return Deserialized map or null if deserialization fails
     */
    public static Map<String, Object> deserializeData(Object record) {
        if (record == null) {
            return null;
        }
        try {
            String serializedResp = JSON.serialize(record);
            Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(serializedResp);
            return row;
        } catch (Exception e) {
            System.debug('deserializeData failed: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Wrapper for Related Account Details modal.
     */
    public with sharing class AccountDetailsModalWrapper {
        @AuraEnabled public List<AccountDetails> accountData { get; set; }
    }

    /**
     * Represents individual related Account details.
     */
    public with sharing class AccountDetails {
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String orgName { get; set; }
        @AuraEnabled public String accRecId { get; set; }
        @AuraEnabled public String accManager { get; set; }
        @AuraEnabled public String accAddress { get; set; }
        @AuraEnabled public String accCity { get; set; }
        @AuraEnabled public String accState { get; set; }
        @AuraEnabled public String accZipcode { get; set; }
        @AuraEnabled public String accPhone { get; set; }
    }    

    /**
     * Wrapper for Activity modal.
     * Groups activities by category or source.
     */
    public with sharing class ActivityModalWrapper {
        @AuraEnabled public List<ActivityGroup> activityData { get; set; }
    }

    /**
     * Represents a single Activity record.
     */
    public with sharing class Activities {
        @AuraEnabled public String taskId { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String completeDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String isClosed { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Boolean isUpcoming { get; set; }
        @AuraEnabled public String ownerName { get; set; }
    }

    /**
     * Groups activities under a common label
     * (e.g., FR, HS, TS, Upcoming, Completed).
     */
    public with sharing class ActivityGroup {
        @AuraEnabled public String groupLabel { get; set; }
        @AuraEnabled public List<Activities> activities { get; set; }
    }
}