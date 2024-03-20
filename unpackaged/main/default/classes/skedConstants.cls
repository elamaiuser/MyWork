public class skedConstants {
    
    public static final Decimal METTER_PER_MILE = 1609.34;
    public static final string NO_TRAVEL_TIME_DATA = 'NO DATA';

    public static final string ACCCOUNT_AVAILABILITY_TYPE_AVAILABILITY_ONLY = 'Availability Only';
    public static final string ACCCOUNT_AVAILABILITY_TYPE_UNAVAILABILITY_ONLY = 'Unavailability Only';

    public static final string OPERATION_TYPE_INTEGRATED = 'Integrated';
    public static final string OPERATION_TYPE_WB = 'Non Integrated WB';
    public static final string OPERATION_TYPE_APH = 'Non Integrated APH';

    public static final string ACCCOUNT_RESOURCE_SCORE_DECLINED = 'Declined';
    public static final string ACCCOUNT_RESOURCE_SCORE_PREFERRED = 'Preferred';

    public static final string ACCOUNT_TYPE_EDUCATION = 'Education';

    public static final string ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL = 'High School';

    public static final string ACCCOUNT_TEAM_ROLE_POWER_BOOKER = 'Power Booker';

    public static final string ACTION_INSERT = 'create';
    public static final string ACTION_UPDATE = 'update';
    public static final string ACTION_DELETE = 'delete';
    
    public static final string ACTIVITY_TYPE_ON_CALL = 'On Call';
    public static final string ACTIVITY_TYPE_AFTER_HOURS_CALL_OUT_MANAGEMENT = 'After Hours Call Out Management';

    public static final string ACTIVITY_INSERT_BATCH_STARTED = 'Successfully initiated a batch process to create activities. You will receive an email when this process completes.';

    public static final string ADDRESS_REFERECENED_FOR_SCHEDULING_HOME = 'Home';
    public static final string ADDRESS_REFERECENED_FOR_SCHEDULING_WORK = 'Work';
    public static final string ADDRESS_REFERECENED_FOR_SCHEDULING_SATELLITE = 'Satellite';

    public static final string ASSET_TYPE_EQUIPMENT = 'Equipment';
    public static final string ASSET_TYPE_VEHICLE = 'Vehicle';

    public static final string ASYNC_JOB_STATUS_COMPLETE = 'Complete';
    public static final string ASYNC_JOB_STATUS_ERROR = 'Error';
    public static final string ASYNC_JOB_STATUS_PENDING = 'Pending';

    public static final string ASYNC_JOB_TYPE_JOB_OPTIMIZATION_RESULT = 'Job Optimization Result';

    public static final string AVAILABILITY_EXEPTION_CODE = 'Staff Assigned to a New Primary Role';

    public static final string AVAILABILITY_STATUS_APPROVED = 'Approved';
    public static final string AVAILABILITY_STATUS_CANCELLED = 'Cancelled';
    public static final string AVAILABILITY_STATUS_DECLINED = 'Declined';
    public static final string AVAILABILITY_STATUS_EXPIRED = 'Expired';
    public static final string AVAILABILITY_STATUS_PENDING = 'Pending';
    public static final string AVAILABILITY_STATUS_WAITLIST = 'Waitlist';

    public static final String AVAILABILITY_STAFFING_BUDGET_NO_CAPACITY = 'Unable to approve Unavailability due to insufficient Staffing Budget balance';
    public static final String AVAILABILITY_CRUD_MUST_COME_FROM_RAC = 'Unable to complete operation - Please use the Resource Availability Console to perform Availability/Activity related actions';
    public static final String DRIVE_CRUD_MUST_COME_FROM_RECORD_PAGE = 'Unable to complete operation - Please use the Drive Record Page to perform Drive/Job/Allocation related actions';

    public static final string AVAILABILITY_TYPE_CALL_OUT = 'Call Out';
    public static final string AVAILABILITY_TYPE_FLOATING_HOLIDAY = 'Floating Holiday';
    public static final string AVAILABILITY_TYPE_PTO = 'PTO';
    public static final string AVAILABILITY_TYPE_SICK = 'Sick';
    public static final string AVAILABILITY_TYPE_ON_CALL = 'On Call';

    public static final string AVAILABILITY_TYPE_AVAILABILITY_TEMPLATE_OVERRIDE = 'Availability Template Override';

    public static final string AVAILABILITY_CALLOUT_TYPE_CALL_OUT = 'Call Out';
    public static final string AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL = 'Late Arrival';

    public static final String AVAILABILITY_WD_SYNC_STATUS_SUCCESS = 'Success';
    public static final String AVAILABILITY_WD_SYNC_STATUS_FAILED = 'Failed';

    public static final string CALENDAR_BUILD_STATUS_QUALIFIED = 'Qualified';
    public static final string CALENDAR_BUILD_STATUS_UNQUALIFIED = 'Unqualified';

    public static final string DRIVE_OPTIMIZATION_STATUS_PENDING = 'Pending';

    public static final string DRIVE_PENDING_ACTION_CANCEL_IN_PROCESS = 'Cancel In Process';
    public static final string DRIVE_PENDING_ACTION_DRIVE_CHANGE_REQUEST = 'Drive Change Request';
    public static final string DRIVE_PENDING_ACTION_DRIVE_SUBMISSION = 'Drive Submission';

    public static final string DRIVE_STATUS_APPROVED = 'Approved';
    public static final string DRIVE_STATUS_CANCEL = 'Cancel';
    public static final string DRIVE_STATUS_COMPLETE = 'Complete';
    public static final string DRIVE_STATUS_CONFIRMED = 'Confirmed';
    public static final string DRIVE_STATUS_DRAFT = 'Draft';
    public static final string DRIVE_STATUS_HOLD = 'Hold';
    public static final string DRIVE_STATUS_PENDING_ACTION = 'Pending Action';
    public static final string DRIVE_STATUS_SUBMITTED = 'Submitted';
    public static final string DRIVE_STATUS_SYSTEM_GENERATED = 'System Generated';
    public static final string DRIVE_STATUS_TENTATIVE = 'Tentative';

    public static final String DRIVE_TYPE_FIXED_SITE = 'Fixed Site';
    public static final String DRIVE_TYPE_MOBILE = 'Mobile';
    public static final String DRIVE_TYPE_RSMO = 'RSMO';

    public static final string DRIVE_CHANGE_REQUEST_STATUS_APPROVED = 'Approved';
    public static final string DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM = 'Approved by System';
    public static final string DRIVE_CHANGE_REQUEST_STATUS_CANCELLED = 'Cancelled';
    public static final string DRIVE_CHANGE_REQUEST_STATUS_REJECTED = 'Rejected';
    public static final string DRIVE_CHANGE_REQUEST_STATUS_PENDING = 'Pending';
    public static final string DRIVE_CHANGE_REQUEST_STATUS_SUBMITTED = 'Submitted';
    public static final string DRIVE_CHANGE_REQUEST_TYPE_COLLECTION_OP = 'Collection Operation Change';
    public static final string DRIVE_CHANGE_REQUEST_TYPE_REGENERATE_DRIVE = 'Regenerate Drive';
    public static final string DRIVE_CHANGE_REQUEST_TYPE_RTD_CHANGE = 'Role Time Detail Change';
    public static final string DRIVE_CHANGE_REQUEST_TYPE_RTV_CHANGE = 'Role Time Variance Change';
    public static final string DRIVE_CHANGE_REQUEST_TYPE_USER_CHANGE = 'User Change';
    public static final string DRIVE_CHANGE_REQUEST_TYPE_SITE_ADDRESS_CHANGE = 'Site Address Change';
    public static final string DRIVE_CHANGE_REQUEST_TYPE_TRAVEL_TIME_CHANGE = 'Travel Time Change';

    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_CUTOFF_REQUIREMENT = 'Shift Trade doesn\'t meet cutoff requirements';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DUPLICATE_TRADE = 'Requesting User Shift is part of other Trade';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DUPLICATE_TRADE = 'Trading User Shift is part of other Trade';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_EXCEEDS_MAX_HOUR = 'Requesting User exceeds Max Hours per week';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_EXCEEDS_MAX_HOUR = 'Trading User exceeds Max Hours per week';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION = 'Requesting User has a TAT Contention';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_TAT_CONTENTION = 'Trading User has a TAT Contention';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_UNQUALIFIED = 'Requesting User unqualified';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_UNQUALIFIED = 'Trading User unqualified';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_DRIVE_PART_OF_LINKED = 'Requesting User Drive is part of Linked Drive';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_DRIVE_PART_OF_LINKED = 'Trading User Drive is part of Linked Drive';

    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_CANCELLED = 'Denied (cancelled)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_CUTOFF_DAYS = 'Denied (cutoff days)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_DUPLICATE = 'Denied (duplicate)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_HOURS = 'Denied (hours)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_ROLE = 'Denied (role)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_TRAVEL_DISTANCE = 'Denied (travel distance)';

    public static final string DRIVE_SHIFT_TRADE_STATUS_APPROVED = 'Approved';
    public static final string DRIVE_SHIFT_TRADE_STATUS_CANCELLED = 'Cancelled';
    public static final string DRIVE_SHIFT_TRADE_STATUS_DENIED = 'Denied';
    public static final string DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL = 'Pending Approval';
    public static final string DRIVE_SHIFT_TRADE_STATUS_WAITING_FOR_TRADING_STAFF_ACKNOWLEDGE = 'Waiting for Trading Staff Acknowledge';

    public static final string EXCEPTION_CODE_CDL_DOT_HOURS_VIOLATION = 'CDL_DOT_HOURS_VIOLATION';
    public static final string EXCEPTION_CODE_CERT_ADDED_42DAYS = 'CERT_ADDED_42DAYS';
    public static final string EXCEPTION_CODE_DRIVE_CHANGE_REQUEST_SUBMITTED = 'DRIVE_CHANGE_REQUEST_SUBMITTED';
    public static final string EXCEPTION_CODE_DRIVE_COLLECTION_OPERATION_CHANGED = 'DRIVE_COLLECTION_OPERATION_CHANGED';
    public static final string EXCEPTION_CODE_EQUIPMENT_REDUCED = 'EQUIPMENT_REDUCED';
    public static final string EXCEPTION_CODE_EXPIRED_REQUIRED_TAG = 'EXPIRED_REQUIRED_TAG';
    public static final string EXCEPTION_CODE_MAXIMUM_TRAVEL_TIME_VIOLATION = 'MAXIMUM_TRAVEL_TIME_VIOLATION';
    public static final string EXCEPTION_CODE_MAXIMUM_WEEKLY_HOURS_VIOLATION = 'MAXIMUM_WEEKLY_HOURS_VIOLATION';
    public static final string EXCEPTION_CODE_MINIMUM_QUANTITY_NOT_MET = 'MINIMUM_QUANTITY_NOT_MET';
    public static final string EXCEPTION_CODE_MISSING_REQUIRED_TAG = 'MISSING_REQUIRED_TAG';
    public static final string EXCEPTION_CODE_RESOURCE_ACCOUNT_DECLINED = 'RESOURCE_ACCOUNT_DECLINED';
    public static final string EXCEPTION_CODE_RESOURCE_DATA_CHANGED = 'RESOURCE_DATA_CHANGED';
    public static final string EXCEPTION_CODE_RESOURCE_DUPLICATE_SENIORITY_RANKING = 'RESOURCE_DUPLICATE_SENIORITY_RANKING';
    public static final string EXCEPTION_CODE_RESOURCE_SITE_DECLINED = 'RESOURCE_SITE_DECLINED';
    public static final string EXCEPTION_CODE_RESOURCE_IS_INACTIVE = 'RESOURCE_IS_INACTIVE';
    public static final string EXCEPTION_CODE_RESOURCE_PENDING_TERMINATION = 'RESOURCE_PENDING_TERMINATION';
    public static final string EXCEPTION_CODE_RESOURCE_ROLE_STATUS_CHANGED = 'RESOURCE_ROLE_STATUS_CHANGED';
    public static final string EXCEPTION_CODE_RESOURCE_TIME_CONFLICT = 'RESOURCE_TIME_CONFLICT';
    public static final string EXCEPTION_CODE_ROLE_TIME_DETAIL_CHANGED = 'ROLE_TIME_DETAIL_CHANGED';
    public static final string EXCEPTION_CODE_ROLE_TIME_VARIANCE_CHANGED = 'ROLE_TIME_VARIANCE_CHANGED';
    public static final string EXCEPTION_CODE_STAFFING_CONSTRAINT_CHANGED = 'STAFFING_CONSTRAINT_CHANGED';
    public static final string EXCEPTION_CODE_TURNAROUND_TIME_VIOLATION = 'TURNAROUND_TIME_VIOLATION';
    public static final string EXCEPTION_CODE_RESOURCE_OUT_OF_CO = 'RESOURCE_OUT_OF_CO';
    public static final string EXCEPTION_CODE_RESOURCE_NOT_AVAILABLE_FOR_CO = 'RESOURCE_NOT_AVAILABLE_FOR_CO';
    public static final string EXCEPTION_CODE_RESOURCE_ROLE_RESTRICTED = 'RESOURCE_ROLE_RESTRICTED';
    public static final string EXCEPTION_CODE_MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION = 'MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION';
    public static final string EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION = 'MINIMUM_WEEKLY_WORK_DAYS_VIOLATION';

    public static final Map<String, String> MAP_EXCEPTION_CODE_TO_DEFAULT_EXCEPTION_MESSAGE = new Map<String, String> {
        EXCEPTION_CODE_MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION => 'Maximum weekly work days violation. Week: {{weekStartDate}}',
        EXCEPTION_CODE_MINIMUM_WEEKLY_WORK_DAYS_VIOLATION => 'Minimum weekly work days violation. Week: {{weekStartDate}}'
    };

    public static final string EXCEPTION_LOG_STATUS_CLOSED = 'Closed';
    public static final string EXCEPTION_LOG_STATUS_OPEN = 'Open';

    public static final String EVENT_TYPE_NOT_AVAILABLE = 'non-working';
    public static final String EVENT_TYPE_JOB_SINGLE = 'single-job';
    public static final String EVENT_TYPE_JOB_GROUP_EVENT = 'group-event-job';

    public static final string JOB_CANCELLATION_REASON_RESCHEDULED = 'Rescheduled';

    public static final string JOB_STATUS_CANCELLED = 'Cancelled';
    public static final string JOB_STATUS_COMPLETE = 'Complete';
    public static final string JOB_STATUS_DISPATCHED = 'Dispatched';
    public static final string JOB_STATUS_IN_PROGRESS = 'In Progress';
    public static final string JOB_STATUS_PENDING_ALLOCATION = 'Pending Allocation';
    public static final string JOB_STATUS_PENDING_DISPATCH = 'Pending Dispatch';
    public static final string JOB_STATUS_QUEUED = 'Queued';
    public static final string JOB_STATUS_READY = 'Ready';
    public static final string JOB_STATUS_ON_SITE = 'On Site';
    public static final string JOB_STATUS_EN_ROUTE = 'En Route';

    public static final string JOB_RESOURCE_ROLE_DRIVE_LEAD = 'Drive Lead';
    public static final string JOB_RESOURCE_ROLE_DRIVER = 'Driver';
    public static final string JOB_RESOURCE_ROLE_TEAM_SUPERVISOR = 'Team Supervisor';

    public static final string JOB_ALLOCATION_STATUS_COMPLETE = 'Complete';
    public static final string JOB_ALLOCATION_STATUS_CONFIRMED = 'Confirmed';
    public static final string JOB_ALLOCATION_STATUS_EN_ROUTE = 'En Route';
    public static final string JOB_ALLOCATION_STATUS_CHECKED_IN = 'Checked In';
    public static final string JOB_ALLOCATION_STATUS_DECLINED = 'Declined';
    public static final string JOB_ALLOCATION_STATUS_DELETED = 'Deleted';
    public static final string JOB_ALLOCATION_STATUS_DISPATCHED = 'Dispatched';
    public static final string JOB_ALLOCATION_STATUS_PENDING_DISPATCH = 'Pending Dispatch';
    public static final string JOB_ALLOCATION_STATUS_IN_PROGRESS = 'In Progress';

    public static final string JOB_OFFER_STATUS_PENDING = 'Pending';
    public static final string JOB_OFFER_STATUS_CANCELLED = 'Cancelled';

    public static final string JOB_VOLUNTEER_ROLE_DONOR_AMBASSADOR = 'Donor Ambassador';
    public static final string JOB_VOLUNTEER_ROLE_MEDICAL_SCREENER = 'Regulated - Medical Screener';
    public static final string JOB_TYPE_INITIAL_EVALUATION = 'Initial Evaluation';
    public static final string JOB_TYPE_TREATMENT = 'Treatment';
    public static final string JOB_TYPE_GROUP_EVENT = 'Group Event';
    public static final string JOB_TYPE_MEDICAL_SCREENER = 'Regulated - Medical Screeners';

    public static final string LINKED_DRIVE_TYPE_SINGLE = 'Same Day';
    public static final string LINKED_DRIVE_TYPE_MULTI = 'Multi Day';

    public static final string LOCATION_RESOURCE_SCORE_DECLINED = 'Declined';
    public static final string LOCATION_RESOURCE_SCORE_PREFERRED = 'Preferred';

    public static final string LOCATION_TYPE_OUTSIDE = 'Outside';
    public static final string LOCATION_TYPE_INSIDE = 'Inside';
    public static final string LOCATION_TYPE_INSIDE_OUTSIDE = 'Inside/Outside';

    public static final string OPERATION_STATUS_SUBMITTED = 'Submitted';
    public static final string OP_RECORD_DELETE_INVALID_PERMISSION = 'Failed to delete Operation Record due to invalid permissions.';
    public static final string OP_RECORD_SUBMIT_200 = 'Op Record successfully submitted.';
    public static final string OP_RECORD_SUBMIT_400 = 'Op Record submission failed due to problem with Op Record or Staff. Check to make sure Op Record and Staffing is complete and correct, and retry. Contact BSF support or system administrator with the Op Record Name or Drive ID for assistance.';
    public static final string OP_RECORD_SUBMIT_500 = 'Op Record submission failed due to problem with Azure server or database.  Please contact BSF support or system administrator Op Record Name or Drive ID for assistance, and wait a few minutes before retrying.';

    public static final string OPPORTUNITY_STAGE_CANCELLED = 'Cancelled';
    public static final string OPPORTUNITY_STAGE_CLOSED = 'Closed';

    public static final string OPTIMIZATION_QUEUE_STATUS_COMPLETE = 'Complete';
    public static final string OPTIMIZATION_QUEUE_STATUS_IN_PROGRESS = 'In Progress';
    public static final string OPTIMIZATION_QUEUE_STATUS_PENDING = 'Pending';
    public static final string OPTIMIZATION_QUEUE_STATUS_ERROR = 'Error';

    public static final string OPTIMIZATION_RUN_STATUS_CLOSED = 'Closed';
    public static final string OPTIMIZATION_RUN_STATUS_COMPLETE = 'Complete';
    public static final string OPTIMIZATION_RUN_STATUS_ERROR = 'Error';
    public static final string OPTIMIZATION_RUN_STATUS_IN_PROGRESS = 'In Progress';
    public static final string OPTIMIZATION_RUN_STATUS_PENDING = 'Pending';
    public static final string OPTIMIZATION_RUN_STATUS_POST_PROCESS = 'Post Process';

    public static final string RESOURCE_EMPLOYMENT_STATUS_LEAVE = 'Leave';
    public static final string RESOURCE_EMPLOYMENT_STATUS_ACTIVE = 'Active';
    public static final string RESOURCE_EMPLOYMENT_STATUS_INACTIVE = 'Inactive';

    public static final string RESOURCE_TYPE_PERSON = 'Person';
    public static final string RESOURCE_TYPE_ASSET = 'Asset';

    public static final string RESOURCE_CATEGORY_BUS = 'Bus';

    public static final string RESOURCE_JOB_OFFER_STATUS_PENDING = 'Pending';
    public static final string RESOURCE_JOB_OFFER_STATUS_RESOURCEJOBOFFERCANCELLED = 'ResourceOfferCancelled';

    public static final string RESOURCE_ROLE_GROUP_DRIVING_ROLES = 'Driving roles';
    public static final string RESOURCE_ROLE_GROUP_SUPERVISORY_ROLES = 'Supervisory roles';
    public static final string RESOURCE_ROLE_GROUP_STAFF_ROLES = 'Staff roles';

    public static final string RESOURCE_ASSET_CRUD_REQUIRES_SYSADMIN = 'Creation/Updates of Asset resources requires System Administrator/Global Admin privileges';

    public static final String ROLE_TIME_VARIANCE_BUFFER_ADD = 'Add';
    public static final String ROLE_TIME_VARIANCE_BUFFER_SUBTRACT = 'Subtract';

    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME = 'Lead Time';
    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME = 'Setup Time';
    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME = 'Breakdown Time';
    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_WRAP_UP_TIME = 'Wrap-up Time';
    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_TO = 'Travel Time To';
    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_TRAVEL_TIME_FROM = 'Travel Time From';
    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_SITE_LOSGISTICS_TO = 'Site Logistics To';
    public static final String ROLE_TIME_VARIANCE_APPLIES_TO_SITE_LOSGISTICS_BACK = 'Site Logistics Back';

    public static final string SITE_FEEDBACK_STATUS_APPROVED = 'Approved';
    public static final string SITE_FEEDBACK_STATUS_SUBMITTED = 'Submitted';

    public static final string STAFFING_BUDGET_REQUEST_TYPE_ALL_HANDS_ON_DECK = 'Unavailability Day';
    public static final string STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT = 'Bidding Period';
    public static final string STAFFING_BUDGET_REQUEST_TYPE_STANDARD = 'Standard';

    public static final string SUPPORT_PLAN_STATUS_ACTIVE = 'Active';
    public static final string SUPPORT_PLAN_STATUS_CLOSED = 'Closed';

    public static final string TAG_TRAINEE = 'Trainee';
    public static final string TAG_NO_TRAINEE = 'No Trainee';
    public static final string TAG_TEAM_SUPERVISOR = 'Team Supervisor';
    public static final string TAG_DRIVE_LEAD = 'Drive Lead';
    public static final string TAG_FIXED_SITE = 'Fixed Site';
    public static final string TAG_MOBILE = 'Mobile';


    public static final string TAG_ROLE_STATUS_ACTIVE = 'Active';
    public static final string TAG_ROLE_STATUS_INACTIVE = 'Inactive';
    public static final string TAG_ROLE_STATUS_PENDING = 'Pending';

    public static final string TAG_TYPE_ASSET_TYPE = 'Asset Type';
    public static final string TAG_TYPE_CERTIFICATION = 'Certification';
    public static final string TAG_TYPE_DRIVE_TYPE = 'Drive Type';
    public static final string TAG_TYPE_PHYSICAL_LOCATION_TYPE = 'Physical Location Type';
    public static final string TAG_TYPE_ROLE = 'Role';

    public static final string TAG_RESOURCE_TYPE_PERSON = 'Person';
    public static final string TAG_RESOURCE_TYPE_VEHICLE = 'Vehicle';
    public static final string TAG_RESOURCE_TYPE_EQUIPMENT = 'Equipment';

    public static final string USER_TYPE_ADMIN = 'Admin';
    public static final string USER_TYPE_SCHEDULER = 'Scheduler';

    public static final string PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS = 'DCRs';
    public static final string PROFILE_QUEUE_PENDING_ACTIONS = 'PAs';
    public static final string PROFILE_QUEUE_ROLE_TIME_VARIANCES = 'RTVs';
    public static final string PROFILE_QUEUE_DRIVE_SHIFT_TRADES = 'DSTs';
    public static final string PROFILE_QUEUE_DM_PENDING_ACTIONS = 'DMPA';
    public static final string PROFILE_QUEUE_DM_DRIVE_CHANGE_REQUESTS = 'DMDCR';

    public static final string TAG_ROLE_ID_GATEKEEPER_TAG = '-T-';

    public static final string UNAVAILABILITY_TYPE_FLOATING_HOLIDAY = 'Floating Holiday';
    public static final string UNAVAILABILITY_TYPE_PTO = 'PTO';
    public static final string UNAVAILABILITY_TYPE_SICK = 'Sick';
    public static final string UNAVAILABILITY_TYPE_UNAVAILABLE = 'Unavailable';

    public static final String WD_PTO_7_DAY_LAG_ID = 'Planned - PTO - 7 Day Lag - Time Off';
    public static final String WD_PTO_PLANNED = 'Planned';
    public static final String WD_PTO_UNPLANNED = 'Unplanned';

    /* Internal coding */
    public static final string CUSTOM_FIELDS_EXTENSION = '__c';

    public static final string EXCEPTION_CONCURRENCY = 'CONCURRENCY_ERROR';
    public static final string EXCEPTION_CONCURRENCY_PATIENT = 'CONCURRENCY_PATIENT_ERROR';

    public static final string HOLIDAY_GLOBAL = 'global';

    public static final string TEMPORARY_ID_PREFIX = 'temp_';

    public static final string GROUP_TYPE_QUEUE = 'Queue';

    public static final date EARLIEST_START_DATE = Date.newInstance(1900, 01, 01);
    public static final date LATEST_END_DATE = Date.newInstance(4000, 12, 31);

    /* User Profile Object Access */
    public static final string SYSTEM_USER_AUTOPROC = 'autoproc';

    public static final string TARGET_TYPE_USER = 'User';
    public static final string TARGET_TYPE_PROFILE = 'Profile';

    public static final string TRIGGER_ACTION_INSERT = 'insert';
    public static final string TRIGGER_ACTION_UPDATE = 'update';
    public static final string TRIGGER_ACTION_DELETE = 'delete';

    /* Travel Time Index Items */
    public static final string TTII_DIRECTION_SITE_TO_CO = 'SiteToCO:';
    public static final string TTII_DIRECTION_CO_TO_SITE = 'COToSite:';
}