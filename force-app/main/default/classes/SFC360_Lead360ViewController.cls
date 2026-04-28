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
// various Account, Activity, Revenue, Training, Blood Drive,
// Gift and Contract details from Data Cloud .

    // Fetch related Account details excluding Leads
    public static final String SQL_ACCOUNT_DETAILS = 'SELECT '+
        'ssot__Account__dlm.ssot__Name__c AS acc_name,'+
        'ssot__Account__dlm.KQ_Id__c AS org_name,'+
        'ssot__Account__dlm.ssot__Id__c AS account_rec_id__c '+
        'FROM UnifiedssotAccountUa1__dlm '+
        'JOIN UnifiedLinkssotAccountUa1__dlm '+
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c '+
        'JOIN ssot__Account__dlm '+
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c '+
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c '+
        'Where ssot__Account__dlm.ssot__AccountTypeId__c!=\'Lead\' ' +
        'AND UnifiedssotAccountUa1__dlm.ssot__Id__c = {0}';

    // Fetch Gift details
    public static final String SQL_GIFT_DETAILS = 'SELECT '+
        'ssot__Account__dlm.ssot__Name__c AS acc_name,'+
        'Gift__dlm.Ask_Account_Id_c__c AS gift_account_id__c,'+
        'Gift__dlm.Gift_Amount_c__c AS gift_amount__c '+
        'FROM UnifiedssotAccountUa1__dlm '+
        'JOIN UnifiedLinkssotAccountUa1__dlm '+
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c '+
        'JOIN ssot__Account__dlm '+
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c '+
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c '+
        'JOIN Gift__dlm ON (ssot__Account__dlm.ssot__Id__c = Gift__dlm.Ask_Account_Id_c__c '+
        'AND ssot__Account__dlm.KQ_Id__c = Gift__dlm.KQ_Ask_Account_Id_c__c) '+
        'Where  UnifiedssotAccountUa1__dlm.ssot__Id__c = {0}';

     // Fetch completed Blood Drive details
    public static final String SQL_COMPLETED_BLOOD_DRIVE_DETAILS = 'SELECT '+
        'Blood_Drives_on_Calendar__dlm.Name__c AS drive_name__c,'+
        'Blood_Drives_on_Calendar__dlm.sked_Status_c__c AS drive_Status_c__c,'+
        'Blood_Drives_on_Calendar__dlm.sked_Drive_Date_c__c AS drive_Date_c__c, '+
        'Blood_Drives_on_Calendar__dlm.KQ_Id__c AS org_name, '+
        'Blood_Drives_on_Calendar__dlm.Id__c AS completed_blood_drives_id__c '+
        'FROM UnifiedssotAccountUa1__dlm '+
        'JOIN UnifiedLinkssotAccountUa1__dlm '+
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c '+
        'JOIN ssot__Account__dlm '+
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c '+
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c '+
        'JOIN Blood_Drives_on_Calendar__dlm ON (ssot__Account__dlm.ssot__Id__c = Blood_Drives_on_Calendar__dlm.sked_Account_c__c '+
        'AND ssot__Account__dlm.KQ_Id__c = Blood_Drives_on_Calendar__dlm.KQ_sked_Account_c__c) '+
        'Where Blood_Drives_on_Calendar__dlm.sked_Status_c__c = \'Complete\' '+
        'AND UnifiedssotAccountUa1__dlm.ssot__Id__c = {0}';
        
    // Fetches planned (confirmed) Blood Drive details for an account
    public static final String SQL_PLANNED_BLOOD_DRIVE_DETAILS = 'SELECT '+
        'Blood_Drives_on_Calendar__dlm.Name__c AS drive_name__c,'+
        'Blood_Drives_on_Calendar__dlm.sked_Status_c__c AS drive_Status_c__c,'+
        'Blood_Drives_on_Calendar__dlm.sked_Drive_Date_c__c AS drive_Date_c__c, '+
        'Blood_Drives_on_Calendar__dlm.KQ_Id__c AS org_name, '+
        'Blood_Drives_on_Calendar__dlm.Id__c AS completed_blood_drives_id__c '+
        'FROM UnifiedssotAccountUa1__dlm '+
        'JOIN UnifiedLinkssotAccountUa1__dlm '+
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c '+
        'JOIN ssot__Account__dlm '+
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c '+
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c '+
        'JOIN Blood_Drives_on_Calendar__dlm ON (ssot__Account__dlm.ssot__Id__c = Blood_Drives_on_Calendar__dlm.sked_Account_c__c '+
        'AND ssot__Account__dlm.KQ_Id__c = Blood_Drives_on_Calendar__dlm.KQ_sked_Account_c__c) '+
        'Where Blood_Drives_on_Calendar__dlm.sked_Status_c__c = \'Confirmed\' '+
        'AND UnifiedssotAccountUa1__dlm.ssot__Id__c = {0}';

   // Fetches completed (closed & not cancelled) training classes 
    public static final String SQL_COMPLETED_COURSE_DETAILS = 'SELECT '+
        'ILT_Class__dlm.Offering_Id_c__c AS training_class__c,'+
        'ILT_Class__dlm.Id__c AS training_class_id__c,'+
        'ssot__Account__dlm.ssot__Name__c AS acc_name '+
        'FROM UnifiedssotAccountUa1__dlm '+
        'JOIN UnifiedLinkssotAccountUa1__dlm '+
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c '+
        'JOIN ssot__Account__dlm '+
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c '+
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c '+
        'JOIN ILT_Class__dlm ON (ssot__Account__dlm.ssot__Id__c = ILT_Class__dlm.Skedulo_Account_c__c '+
        'AND ssot__Account__dlm.KQ_Id__c = ILT_Class__dlm.KQ_Skedulo_Account_c__c) '+
        'Where ILT_Class__dlm.Is_Closed_c__c = \'true\' AND ILT_Class__dlm.redwing_Cancelled_c__c = \'false\' '+
        'AND UnifiedssotAccountUa1__dlm.ssot__Id__c = {0}';

    // Fetches upcoming (not closed, not cancelled) training classes
    public static final String SQL_PLANNED_COURSE_DETAILS = 'SELECT '+
        'ILT_Class__dlm.Offering_Id_c__c AS training_class__c,'+
        'ILT_Class__dlm.Id__c AS training_class_id__c,'+
        'ssot__Account__dlm.ssot__Name__c AS acc_name '+
        'FROM UnifiedssotAccountUa1__dlm '+
        'JOIN UnifiedLinkssotAccountUa1__dlm '+
        'ON UnifiedssotAccountUa1__dlm.ssot__Id__c = UnifiedLinkssotAccountUa1__dlm.UnifiedRecordId__c '+
        'JOIN ssot__Account__dlm '+
        'ON UnifiedLinkssotAccountUa1__dlm.SourceRecordId__c = ssot__Account__dlm.ssot__Id__c '+
        'AND UnifiedLinkssotAccountUa1__dlm.KQ_SourceRecordId__c = ssot__Account__dlm.KQ_Id__c '+
        'JOIN ILT_Class__dlm ON (ssot__Account__dlm.ssot__Id__c = ILT_Class__dlm.Skedulo_Account_c__c '+
        'AND ssot__Account__dlm.KQ_Id__c = ILT_Class__dlm.KQ_Skedulo_Account_c__c) '+
        'Where ILT_Class__dlm.Is_Closed_c__c = \'false\' AND ILT_Class__dlm.redwing_Cancelled_c__c = \'false\' '+
        'AND ILT_Class__dlm.redwing_Start_Date_c__c >= CURRENT_DATE '+
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

    // Fetches count of completed and planned blood drives
    private static final String SQL_BLOOD_DRIVES =
        'SELECT completed_blood_drives__c AS completed_drives__c, ' +
        'planned_blood_drives__c AS planned_drives__c ' +
        'FROM SFC360_Account_Blood_Drives__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches count of completed and planned training classes
    private static final String SQL_TRAINING_CLASSES =
        'SELECT completed_training_classes__c, planned_training_classes__c ' +
        'FROM SFC360_Account_Training_Classes__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches account managers mapped to unified account
    private static final String SQL_ACCOUNT_MANAGERS =
        'SELECT account_manager_name__c, account_manager_email__c, org_identifier__c ' +
        'FROM SFC360_Account_Managers__cio ' +
        'WHERE unified_account_id__c = {0} ';
    
    // Fetches CGTS-specific account managers
    private static final String SQL_ACCOUNT_MANAGERS_CGTS =
        'SELECT account_manager_name__c, account_manager_email__c, org_identifier__c ' +
        'FROM SFC360_Account_Managers_CGTS__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches HS revenue and volume by product category
    private static final String SQL_HS_REVENUE =
        'SELECT cryo_revenue__c, cryo_volume__c, csp_revenue__c, csp_volume__c, ifc_revenue__c, ifc_volume__c, ' +
        'ltowb_revenue__c, ltowb_volume__c, plasma_revenue__c, plasma_volume__c, pools_revenue__c, pools_volume__c, ' +
        'rbc_revenue__c, rbc_volume__c, sdp_revenue__c, sdp_volume__c ' +
        'FROM SFC360_HS_Account_Revenue_v2__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches CGTS opportunity revenue details
    private static final String SQL_CGTS_REVENUE =
        'SELECT opportunity_stage__c, total_product_quantity__c, total_opportunity_amount__c ' +
        'FROM SFC360_CGTS_Account_Revenue__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches gift count and total gift amount
    private static final String SQL_FR =
        'SELECT count_of_gifts__c, total_gift_amount__c ' +
        'FROM SFC360_Account_Fundraising__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches lifetime contract count and amount
    private static final String SQL_CONTRACTS =
        'SELECT hs_account_id__c, lifetime_contract_amount__c, lifetime_contract_count__c ' +
        'FROM SFC360_HS_Account_Contract__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches activity counts grouped by closed/open and source
    private static final String SQL_ACTIVITY_SUMMARY =
        'SELECT account_id__c, activity_count__c, is_closed__c, source_system__c ' +
        'FROM SFC360_Account_Activity_Summary__cio ' +
        'WHERE unified_account_id__c = {0} ';

    // Fetches detailed contract records for modal popup
    private static final String SQL_CONTRACTS_MODAL =
        'SELECT contract_number__c, Contract_Record_Type__c, contract_status__c, contract_archival_status__c, ' +
        'contract_start__c, contract_end__c, total_contract_amount__c ' +
        'FROM HS_Account_Contracts_V2__cio ' +
        'WHERE account_id__c = {0} ';
    
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
        'FROM  SFC360_Account_Managers__cio ' +
        'WHERE account_id__c LIKE \'001%\' and unified_account_id__c = {0} ';

/**
 * Main entry point called from UI.
 *
 * Steps:
 *  1. Validate input parameters
 *  2. Fetch Unified Account Id based on source object (Account / Lead)
 *  3. Populate all 360 view sections using helper methods
 *
 * params Map containing source record Id and object API name
 * return ConstituentDataWrapper populated with 360 data
 */

    @AuraEnabled
    public static ConstituentDataWrapper queryDataCloud(Map<String, Object> params ){
        ConstituentDataWrapper result = new ConstituentDataWrapper();
        if (params == null) return result;

        // Extract parameters safely
        String objectAPIName = safeGetString(params, 'dataSourceObjectId');
        String recId = safeGetString(params, 'sourceRecId');
        if (String.isBlank(objectAPIName) || String.isBlank(recId)) {
            return result;
        }

        // Get Unified Account Id from Data Cloud
        String ufid = getUnifiedId(objectAPIName, recId);
        System.debug('------ufid :'+ufid);
        if (String.isBlank(ufid)) {
            return result;
        }
        result.unifiedId = ufid;

        // Populate different sections of 360 view
        populateBloodDriveData(ufid, result);
        populateTrainingData(ufid, result);
        populateAccountManagers(ufid, result);
        populateCGTSAccountManagers(ufid, result);
        populateHospitalSalesAndCGTS(ufid, result);
        populateFundraising(ufid, result);
        populateContracts(ufid, result);
        populateActivitySummary(ufid, result);
        populateRelatedAccountsCount(ufid, result);
        
        return result;
    }
    
    /**
     * Fetches contract details for Contract modal popup.
     */
    @AuraEnabled
    public static ContractModalWrapper queryContractModal(String accId) {
        ContractModalWrapper result = new ContractModalWrapper();
        if (String.isBlank(accId)) return result;

        String sql = String.format(SQL_CONTRACTS_MODAL, new List<String>{'\''+accId+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;

        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) return result;

        List<Map<String, String>> contractDataList = new List<Map<String, String>>();
        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) continue;

            Map<String, String> contractData = new Map<String, String>();
            Decimal contractNo = safeGetDecimal(row, 'contract_number__c');
            Decimal contractAmt = safeGetDecimal(row, 'total_contract_amount__c');
            if (contractNo != null) contractNo = contractNo.setScale(0);
            if (contractAmt != null) contractAmt = contractAmt.setScale(3);

            contractData.put('ContractNumber', contractNo == null ? null : String.valueOf(contractNo));
            contractData.put('Type', safeGetString(row, 'Contract_Record_Type__c'));
            contractData.put('Status', safeGetString(row, 'contract_status__c'));
            contractData.put('IsActive', safeGetString(row, 'contract_archival_status__c'));
            contractData.put('StartDate', safeGetString(row, 'contract_start__c'));
            contractData.put('EndDate', safeGetString(row, 'contract_end__c'));
            contractData.put('TotalAmount', contractAmt == null ? null : String.valueOf(contractAmt));
            contractDataList.add(contractData);
        }
        result.contractDataList = contractDataList;
        return result;
    }

    /**
     * Fetches activity details for Activity modal popup.
     * Groups activities by Month / Year.
     */
    @AuraEnabled
    public static ActivityModalWrapper queryActivityModal(String accId) {
        ActivityModalWrapper result = new ActivityModalWrapper();
        if (String.isBlank(accId)) return result;

        String sql = String.format(SQL_ACTIVITY_MODAL, new List<String>{'\''+accId+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;

        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) return result;

        Map<String, List<Activities>> tempMap = new Map<String, List<Activities>>();
        List<String> orderedKeys = new List<String>();
        List<Activities> noDateActivities = new List<Activities>();

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) continue;

            Activities act = new Activities();
            act.TaskId = safeGetString(row, 'task_id__c');
            act.Subject = safeGetString(row, 'subject__c');
            String compDate = safeGetString(row, 'completed_datetime__c');
            if (!String.isBlank(compDate)) {
                // keep only date part if datetime
                if (compDate.contains('T')) compDate = compDate.split('T')[0];
            }
            act.CompleteDate = compDate;
            act.Status = safeGetString(row, 'status__c');
            act.Priority = safeGetString(row, 'priority__c');
            act.IsClosed = safeGetString(row, 'is_closed__c');
            act.Type = safeGetString(row, 'task_sub_type__c');
            act.OwnerName = safeGetString(row, 'task_owner_name__c');
            act.IsUpcoming = (act.Status != null && !act.Status.equalsIgnoreCase('Completed'));

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
     * Fetches course details based on status
     * (Completed / Planned).
     */    
    @AuraEnabled
    public static CourseDetailsModalWrapper queryCourseDetails( String unifiedAccId , String statusForCourse ){
        CourseDetailsModalWrapper result = new CourseDetailsModalWrapper();
        List<CourseDetails> courseDetailsList = new List<CourseDetails>();
        if (String.isBlank(unifiedAccId)) return result;
        String sql ='';
        if (statusForCourse.equalsIgnoreCase('Completed')){
            sql = String.format(SQL_COMPLETED_COURSE_DETAILS, new List<String>{'\''+unifiedAccId+'\''});
        }
        else{
            sql = String.format(SQL_PLANNED_COURSE_DETAILS, new List<String>{'\''+unifiedAccId+'\''});
        }
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        System.debug('------query  :'+sql);
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        System.debug('------resp  :'+resp);
        if (resp == null || resp.rowCount == 0) return result;
        
        for (Object record : resp.data) {
            Map<String, Object> row = deserializeData(record);
            if (row == null) continue;
            CourseDetails courseRelatedDetail = new CourseDetails();
            courseRelatedDetail.trainingClass = safeGetString(row, 'training_class__c');
            courseRelatedDetail.courseId = safeGetString(row, 'training_class_id__c');
            courseRelatedDetail.accountName = safeGetString(row, 'acc_name');
            courseDetailsList.add(courseRelatedDetail);
        }
        result.courseData = courseDetailsList;
        System.debug('------result of course details  :'+JSON.serialize(result));
        return result;
    }

    /**
     * Fetches Blood Drive details for modal popup.
     *
     * Supports:
     *  - Completed Blood Drives
     *  - Planned (Confirmed) Blood Drives
     *
     * param unifiedAccId    Unified Account Id
     * param statusForDrive  Drive status (Completed / Planned)
     * return BloodDriveDetailsModalWrapper containing drive records
     */
    @AuraEnabled
    public static BloodDriveDetailsModalWrapper queryDriveDetails( String unifiedAccId , String statusForDrive ){
        BloodDriveDetailsModalWrapper result = new BloodDriveDetailsModalWrapper();
        List<DriveDetails> driveDetailsList = new List<DriveDetails>();
        if (String.isBlank(unifiedAccId)) return result;
        String sql ='';
        if (statusForDrive.equalsIgnoreCase('Completed')){
            sql = String.format(SQL_COMPLETED_BLOOD_DRIVE_DETAILS, new List<String>{'\''+unifiedAccId+'\''});
        }
        else{
            sql = String.format(SQL_PLANNED_BLOOD_DRIVE_DETAILS, new List<String>{'\''+unifiedAccId+'\''});
        }
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        System.debug('------query  :'+sql);
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        System.debug('------resp  :'+resp);
        if (resp == null || resp.rowCount == 0) return result;
        
        for (Object record : resp.data) {
            Map<String, Object> row = deserializeData(record);
            if (row == null) continue;
            DriveDetails driveRelatedDetail = new DriveDetails();
            driveRelatedDetail.driveName = safeGetString(row, 'drive_name__c');
            driveRelatedDetail.driveStatus = safeGetString(row, 'drive_Status_c__c');
            driveRelatedDetail.driveDate = safeGetString(row, 'drive_Date_c__c');
            driveRelatedDetail.orgName = safeGetString(row, 'org_name');
            driveRelatedDetail.driveRecId = safeGetString(row, 'completed_blood_drives_id__c');
            driveDetailsList.add(driveRelatedDetail);
        }
        result.driveData = driveDetailsList;
        System.debug('------result of gift details  :'+JSON.serialize(result));
        return result;
    }

    /**
     * Fetches Gift details for modal popup.
     *
     * param unifiedAccId Unified Account Id
     * return GiftDetailsModalWrapper containing gift records
     */
    @AuraEnabled
    public static GiftDetailsModalWrapper queryGiftDetails( String unifiedAccId ){
        GiftDetailsModalWrapper result = new GiftDetailsModalWrapper();
        List<GiftDetails> giftDetailsList = new List<GiftDetails>();
        if (String.isBlank(unifiedAccId)) return result;
        String sql = String.format(SQL_GIFT_DETAILS, new List<String>{'\''+unifiedAccId+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        System.debug('------query  :'+sql);
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        System.debug('------resp  :'+resp);
        if (resp == null || resp.rowCount == 0) return result;
        
        for (Object record : resp.data) {
            Map<String, Object> row = deserializeData(record);
            if (row == null) continue;
            GiftDetails giftRelatedDetail = new GiftDetails();
            giftRelatedDetail.accountName = safeGetString(row, 'acc_name');
            giftRelatedDetail.giftAmount = safeGetString(row, 'gift_amount__c');
            giftRelatedDetail.accRecId = safeGetString(row, 'gift_account_id__c');
            giftDetailsList.add(giftRelatedDetail);
        }
        result.giftData = giftDetailsList;
        System.debug('------result of gift details  :'+JSON.serialize(result));
        return result;
    }

    /**
     * Fetches related Account details for modal popup.
     *
     * param unifiedAccId Unified Account Id
     * return AccountDetailsModalWrapper containing account records
     */
    @AuraEnabled
    public static AccountDetailsModalWrapper queryRelatedAccountDetails( String unifiedAccId ){
        AccountDetailsModalWrapper result = new AccountDetailsModalWrapper();
        List<AccountDetails> accountDetailsList = new List<AccountDetails>();
        if (String.isBlank(unifiedAccId)) return result;
        String sql = String.format(SQL_ACCOUNT_DETAILS, new List<String>{'\''+unifiedAccId+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        System.debug('------query  :'+sql);
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        System.debug('------resp  :'+resp);
        if (resp == null || resp.rowCount == 0) return result;
        
        for (Object record : resp.data) {
            Map<String, Object> row = deserializeData(record);
            if (row == null) continue;
            AccountDetails accRelatedDetail = new AccountDetails();
            accRelatedDetail.accountName = safeGetString(row, 'acc_name');
            accRelatedDetail.orgName = safeGetString(row, 'org_name');
            accRelatedDetail.accRecId = safeGetString(row, 'account_rec_id__c');
            accountDetailsList.add(accRelatedDetail);
        }
        result.accountData = accountDetailsList;
        System.debug('------result of acc details  :'+JSON.serialize(result));
        return result;
    }
       
    /**
     * Returns Unified Account Id for given source record.
     *
     * Supports:
     *  - Account
     *  - Lead
     *
     * param objectAPIName Source object name
     * param recId Source record Id
     * return Unified Account Id from Data Cloud
     */
    private static String getUnifiedId(String objectAPIName, String recId) {
        if (String.isBlank(objectAPIName) || String.isBlank(recId)) return null;
        
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        String sql = SQL_GET_UNIFIED_ID_BASE;
         String safeRecId = String.escapeSingleQuotes(recId);
        if (objectAPIName.equalsIgnoreCase('Account')) {
            sql += ' WHERE ssot__Account__dlm.ssot__Id__c = \'' + safeRecId + '\'';
        } else if (objectAPIName.equalsIgnoreCase('Lead')) {
            sql += ' JOIN ssot__Lead__dlm '+
        'ON ssot__Account__dlm.ssot__Id__c = ssot__Lead__dlm.ssot__Id__c ' +
        'AND ssot__Account__dlm.KQ_Id__c = ssot__Lead__dlm.KQ_Id__c '+
        'WHERE ssot__Lead__dlm.ssot__Id__c = \'' + safeRecId + '\'';
        } else {
            // other object types not supported
            return null;
        }
        
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) return null;
        
        try {
            String ufidFromResponse = '';
            for(Object record : resp.data){
            Map<String, Object> row = deserializeData(record);
            if (row == null) return null;
                ufidFromResponse = safeGetString(row,'unified_account_id__c');
            }
            return ufidFromResponse ;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Populates completed and planned Blood Drive counts
     * into the result wrapper.
     */
    private static void populateBloodDriveData(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) return;
        System.debug('------query 1  :'+SQL_BLOOD_DRIVES);
        String sql = String.format(SQL_BLOOD_DRIVES, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        System.debug('------query  :'+sql);
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        System.debug('------resp  :'+resp);
        if (resp == null || resp.rowCount == 0) return;
        try {
            for(Object record : resp.data){
            Map<String, Object> row = deserializeData(record);
            if (row == null) return ;
                result.recordsCompleted = safeGetString(row, 'completed_drives__c');
                result.plannedDrives = safeGetString(row, 'planned_drives__c');
            }
           
        } catch (Exception e) {
            // ignore and move on
        }
    }

    /**
     * Populates planned and completed Training Classes data.
     */    
    private static void populateTrainingData(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) return;
        String sql = String.format(SQL_TRAINING_CLASSES, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        System.debug('------query  :'+sql);
        System.debug('------resp  :'+resp);
        if (resp == null || resp.rowCount == 0) return;
        try {
            for (Object record : resp.data) {
                Map<String, Object> row = deserializeData(record);
                if (row == null) continue;
                result.plannedCourses = safeGetString(row, 'planned_training_classes__c');
                result.coursesCompleted = safeGetString(row, 'completed_training_classes__c');
            }
        }  catch (Exception e) {
            // ignore and move on
        }
    }

    /**
     * Fetches Account Managers and groups them
     * by organization (HS, FR, TS, BioMed).
     */
    private static void populateAccountManagers(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) return;
        String sql = String.format(SQL_ACCOUNT_MANAGERS, new List<String>{'\''+ufid+'\''});
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
            if (row == null) continue;
            String org = safeGetString(row, 'org_identifier__c');
            String name = safeGetString(row, 'account_manager_name__c');
            String email = safeGetString(row, 'account_manager_email__c');
            if (String.isBlank(name) || String.isBlank(email) || String.isBlank(org)) continue;

            ConstituentDataWrapper.AMDetail d = new ConstituentDataWrapper.AMDetail(name, email, org);
            if (org.equalsIgnoreCase('BMSF')) bioMed.add(d);
            else if (org.equalsIgnoreCase('HS')) hs.add(d);
            else if (org.equalsIgnoreCase('FRF')) fr.add(d);
            else if (org.equalsIgnoreCase('TS')) ts.add(d);
        }
        System.debug(
            'bioMedAM ' + bioMed + '\n'+ 'HSAM ' + hs + '\n'+ 'FRAM ' + fr + '\n'+ 'TSAM ' + ts
            );
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
        if (String.isBlank(ufid) || result == null) return;
        String sql = String.format(SQL_ACCOUNT_MANAGERS_CGTS, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        List<ConstituentDataWrapper.AMDetail> cgts = new List<ConstituentDataWrapper.AMDetail>();
        if (resp != null && resp.rowCount > 0) {
            for (Object record : resp.data) {
                Map<String, Object> row = deserializeData(record);
                if (row == null) continue;
                String org = safeGetString(row, 'org_identifier__c');
                String name = safeGetString(row, 'account_manager_name__c');
                String email = safeGetString(row, 'account_manager_email__c');
                if (String.isBlank(name) || String.isBlank(email)) continue;
                if (org != null && org.equalsIgnoreCase('HS')) {
                    cgts.add(new ConstituentDataWrapper.AMDetail(name, email, org));
                }
            }
        }
        // ensure map exists
        if (result.accAmDetails == null) result.accAmDetails = new Map<String, List<ConstituentDataWrapper.AMDetail>>();
        result.accAmDetails.put('Cell Gene Therapy', cgts);
    }

    /**
     * Fetches Hospital Sales and CGTS revenue data
     * and formats it for UI consumption.
     */
    private static void populateHospitalSalesAndCGTS(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) return;

        // HS revenue
        String sqlHS = String.format(SQL_HS_REVENUE, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput qhs = new ConnectApi.CdpQueryInput();
        qhs.sql = sqlHS;
        ConnectApi.CdpQueryOutput respHS = safeQueryAnsiSql(qhs);
        if (respHS != null && respHS.rowCount > 0) {
            // We will expect one row with revenue/volume pairs
            // Products order array
            List<String> pdts = new List<String>{'Cryo','CSP','IFC','LTOWB','Plasma','Pools','RBC','SDP'};
            List<Decimal> dataList = new List<Decimal>();

            for (Object recObj : respHS.data) {
                Map<String, Object> row = deserializeData(recObj);
                if (row == null) continue;
                // iterate values - maintain defensive casting
                for (Object v : row.values()) {
                    Decimal d = safeConvertToDecimal(v);
                    dataList.add(d);
                }
            }

            // Convert to map product -> [rev, vol] if present
            Map<String, List<Decimal>> hsMap = new Map<String, List<Decimal>>();
            Integer i = 0;
            for (String product : pdts) {
                if (i + 1 >= dataList.size()) break;
                Decimal rev = dataList[i];
                Decimal vol = dataList[i + 1];
                List<Decimal> vals = new List<Decimal>();
                if (rev != null && rev != 0) vals.add(rev.setScale(3));
                if (vol != null && vol != 0) vals.add(vol.setScale(3));
                if (!vals.isEmpty()) hsMap.put(product, vals);
                i += 2;
            }
            result.HSRevenueData = hsMap;
        }

        // CGTS revenue
        String sqlCGTS = String.format(SQL_CGTS_REVENUE, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput qcgts = new ConnectApi.CdpQueryInput();
        qcgts.sql = sqlCGTS;
        ConnectApi.CdpQueryOutput respCGTS = safeQueryAnsiSql(qcgts);
        if (respCGTS != null && respCGTS.rowCount > 0) {
            List<List<String>> cgtsList = new List<List<String>>();
            for (Object recObj : respCGTS.data) {
                Map<String, Object> row = deserializeData(recObj);
                if (row == null) continue;
                String stage = safeGetString(row, 'opportunity_stage__c');
                String productCount = safeGetString(row, 'total_product_quantity__c');
                String totalValue = safeGetString(row, 'total_opportunity_amount__c');
                if (!String.isBlank(stage) || !String.isBlank(productCount) || !String.isBlank(totalValue)) {
                    cgtsList.add(new List<String>{stage, productCount, totalValue});
                }
            }
            result.CGTSRevenue = cgtsList;
        }
    }
    
    /**
     * Populates Fundraising summary data.
     *
     * Fetches:
     *  - Total number of gifts
     *  - Total gift amount
     */
    private static void populateFundraising(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) return;
        String sql = String.format(SQL_FR, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) return;

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) continue;
            result.giftCount = safeGetString(row, 'count_of_gifts__c');
            result.totalGiftAmount = safeGetString(row, 'total_gift_amount__c');
        }
    }

    /**
     * Populates Contract summary information.
     *
     * Fetches:
     *  - HS Account Id
     *  - Lifetime contract amount
     *  - Lifetime contract count
     */    
    private static void populateContracts(String ufid, ConstituentDataWrapper result) {
        if (String.isBlank(ufid) || result == null) return;
        String sql = String.format(SQL_CONTRACTS, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) return;

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) continue;
            result.hsAccId = safeGetString(row, 'hs_account_id__c');
            Decimal amt = safeGetDecimal(row, 'lifetime_contract_amount__c');
            Integer cnt = safeGetInteger(row, 'lifetime_contract_count__c');
            result.lifetimeContractAmount = amt == null ? null : String.valueOf(amt.setScale(3));
            result.lifetimeContractCount = cnt == null ? null : String.valueOf(cnt);
        }
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
        if (String.isBlank(ufid) || result == null) return;
        String sql = String.format(SQL_ACTIVITY_SUMMARY, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) return;

        Integer frfTotalCount = 0;
        Integer hsTotalCount = 0;
        Integer frfOpenCount = 0;
        Integer hsOpenCount = 0;
        Integer tsOpenCount = 0;
        Integer tsTotalCount = 0;

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) continue;
            String org = safeGetString(row, 'source_system__c');
            String isClosed = safeGetString(row, 'is_closed__c');
            Integer activityCount = safeGetInteger(row, 'activity_count__c');
            String accountId = safeGetString(row, 'account_id__c');

            if (activityCount == null) activityCount = 0;

            if ('FRF'.equalsIgnoreCase(org)) {
                frfTotalCount += activityCount;
                if ('false'.equalsIgnoreCase(isClosed)) frfOpenCount += activityCount;
                result.frActivityAccId = accountId;
            } else if ('HS'.equalsIgnoreCase(org)) {
                hsTotalCount += activityCount;
                if ('false'.equalsIgnoreCase(isClosed)) hsOpenCount += activityCount;
                result.hsActivityAccId = accountId;
            } else if ('TS'.equalsIgnoreCase(org)) {
                tsTotalCount += activityCount;
                if ('false'.equalsIgnoreCase(isClosed)) tsOpenCount += activityCount;
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
        if (String.isBlank(ufid) || result == null) return;
        String sql = String.format(SQL_RELATED_ACC, new List<String>{'\''+ufid+'\''});
        ConnectApi.CdpQueryInput q = new ConnectApi.CdpQueryInput();
        q.sql = sql;
        ConnectApi.CdpQueryOutput resp = safeQueryAnsiSql(q);
        if (resp == null || resp.rowCount == 0) return;

        for (Object recObj : resp.data) {
            Map<String, Object> row = deserializeData(recObj);
            if (row == null) continue;
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
     * param v Input object
     * return Integer value or null if conversion fails
     */    
    private static Integer safeConvertToInteger(Object v) {
        if (v == null) return null;
        try {
            if (v instanceof Integer) return (Integer) v;
            String s = String.valueOf(v);
            if (String.isBlank(s)) return null;
            return Integer.valueOf(s.split('\\.')[0]); // handle decimals
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Safely converts an Object value to Decimal.
     *
     * Handles:
     *  - Decimal, Integer, Double types
     *  - Numeric String values
     *  - Nulls and invalid formats gracefully
     *
     * param v Input object
     * return Decimal value or null if conversion fails
     */    
    private static Decimal safeConvertToDecimal(Object v) {
        if (v == null) return null;
        try {
            if (v instanceof Decimal) return (Decimal) v;
            if (v instanceof Integer) return Decimal.valueOf((Integer) v);
            if (v instanceof Double) return Decimal.valueOf(Double.valueOf(String.valueOf(v)));
            String s = String.valueOf(v);
            if (String.isBlank(s)) return null;
            return Decimal.valueOf(s);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Safely fetches a Decimal value from a Map.
     *
     * param m   Source map
     * param key Field key
     * return Decimal value or null
     */        
    private static Decimal safeGetDecimal(Map<String, Object> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        return safeConvertToDecimal(v);
    }

    /**
     * Safely fetches an Integer value from a Map.
     *
     * param m   Source map
     * param key Field key
     * return Integer value or null
     */
    private static Integer safeGetInteger(Map<String, Object> m, String key) {
        if (m == null) return null;
        Object v = m.get(key);
        return safeConvertToInteger(v);
    }

    /**
     * Safely extracts String value from Map.
     */
    public static String safeGetString(Map<String, Object> params, String key) {
        if (params == null || String.isBlank(key)) return null;
        Object v = params.get(key);
        if (v == null) return null;
        return String.valueOf(v);
    }

    /**
     * Executes ANSI SQL safely and returns Data Cloud response.
     * Any exception is caught to avoid breaking UI.
     */    
    public static ConnectApi.CdpQueryOutput safeQueryAnsiSql(ConnectApi.CdpQueryInput q) {
        try {
            ConnectApi.CdpQueryOutput responseData = ConnectApi.CdpQuery.queryAnsiSql(q);
            System.debug(
                'responseData ' + responseData
                );
            return responseData;
        } catch (Exception e) {
            System.debug('CDP queryAnsiSql failed: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Converts Data Cloud row object into Map<String, Object>
     * using JSON serialization.
     */    
    public static Map<String, Object> deserializeData(Object record){
        if (record == null) return null;
        try {
        String serializedResp = JSON.serialize(record) ;
        Map<String, Object> row = (Map<String, Object>) JSON.deserializeUntyped(serializedResp);
        return row ;
        }catch (Exception e) {
            System.debug('deserializeData failed: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Wrapper for Course Details modal.
     * Holds list of related course records.
     */   
    public with sharing class CourseDetailsModalWrapper {
        @AuraEnabled public List<CourseDetails> courseData { get; set; }
    }

    /**
     * Represents individual Course details.
     */
    public with sharing class CourseDetails {
        @AuraEnabled public String trainingClass {get;set;}
        @AuraEnabled public String courseId {get;set;}
        @AuraEnabled public String accountName {get;set;}
    }

    /**
     * Wrapper for Blood Drive Details modal.
     */
    public with sharing class BloodDriveDetailsModalWrapper {
        @AuraEnabled public List<DriveDetails> driveData { get; set; }
    }

    /**
     * Represents individual Blood Drive details.
     */    
    public with sharing class DriveDetails {
        @AuraEnabled public String driveName {get;set;}
        @AuraEnabled public String driveStatus {get;set;}
        @AuraEnabled public String driveDate {get;set;}
        @AuraEnabled public String orgName {get;set;}
        @AuraEnabled public String driveRecId {get;set;}
    }

    /**
     * Wrapper for Gift Details modal.
     */    
    public with sharing class GiftDetailsModalWrapper {
        @AuraEnabled public List<GiftDetails> giftData { get; set; }
    }

    /**
     * Represents individual Gift details.
     */    
    public with sharing class GiftDetails {
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String giftAmount {get;set;}
        @AuraEnabled public String accRecId {get;set;}
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
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String orgName {get;set;}
        @AuraEnabled public String accRecId {get;set;}
    }

    /**
     * Wrapper for Contract details modal.
     */    
    public with sharing class ContractModalWrapper {
        @AuraEnabled public List<Map<String , String>> contractDataList {get;set;}
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
        @AuraEnabled public String TaskId {get;set;}
        @AuraEnabled public String Subject {get;set;}
        @AuraEnabled public String CompleteDate {get;set;}
        @AuraEnabled public String Status {get;set;}
        @AuraEnabled public String Priority {get;set;}
        @AuraEnabled public String IsClosed {get;set;}
        @AuraEnabled public String Type {get;set;}
        @AuraEnabled public Boolean IsUpcoming {get;set;}
        @AuraEnabled public String OwnerName {get;set;}
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