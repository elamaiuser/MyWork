public class slwcConstants {
    
    public static final string ACCCOUNT_AVAILABILITY_TYPE_AVAILABILITY_ONLY = 'Availability Only';
    public static final string ACCCOUNT_AVAILABILITY_TYPE_UNAVAILABILITY_ONLY = 'Unavailability Only';
    
    public static final string ACCCOUNT_SCORE_BLACKLIST = 'Do not schedule';
    public static final string ACCCOUNT_SCORE_WHITELIST = 'Preferred';

    public static final string ACTION_INSERT = 'create';
    public static final string ACTION_UPDATE = 'update';
    public static final string ACTION_DELETE = 'delete';
    
    public static final string ASSET_TYPE_EQUIPMENT = 'Equipment';
    public static final string ASSET_TYPE_VEHICLE = 'Vehicle';
    
    public static final string AVAILABILITY_STATUS_APPROVED = 'Approved';
    public static final string AVAILABILITY_STATUS_DECLINED = 'Declined';
    public static final string AVAILABILITY_STATUS_PENDING = 'Pending';
    public static final string AVAILABILITY_STATUS_WAITLIST = 'Waitlist';
    
    public static final string AVAILABILITY_TYPE_AVAILABILITY_TEMPLATE_OVERRIDE = 'Availability Template Override';
    
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_CUTOFF_REQUIREMENT = 'Shift Trade doesn\'t meet cutoff requirements';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_EXCEEDS_MAX_HOUR = 'Requesting User exceeds Max Hours per week';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_EXCEEDS_MAX_HOUR = 'Trading User exceeds Max Hours per week';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_TAT_CONTENTION = 'Requesting User has a TAT Contention';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_TAT_CONTENTION = 'Trading User has a TAT Contention';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_REQUESTING_STAFF_UNQUALIFIED = 'Requesting User unqualified';
    public static final string DRIVE_SHIFT_TRADE_APPROVAL_REASON_TRADING_STAFF_UNQUALIFIED = 'Trading User unqualified';
    
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_CANCELLED = 'Denied (cancelled)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_CUTOFF_DAYS = 'Denied (cutoff days)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_HOURS = 'Denied (hours)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_ROLE = 'Denied (role)';
    public static final string DRIVE_SHIFT_TRADE_DENIED_REASON_TRAVEL_DISTANCE = 'Denied (travel distance)';
    
    public static final string DRIVE_SHIFT_TRADE_STATUS_APPROVED = 'Approved';
    public static final string DRIVE_SHIFT_TRADE_STATUS_DENIED = 'Denied';
    public static final string DRIVE_SHIFT_TRADE_STATUS_PENDING_APPROVAL = 'Pending Approval';
    
    public static final string DRIVE_STATUS_APPROVED = 'Approved';
    public static final string DRIVE_STATUS_CANCEL = 'Cancel';
    public static final string DRIVE_STATUS_CONFIRMED = 'Confirmed';
    public static final string DRIVE_STATUS_DRAFT = 'Draft';
    public static final string DRIVE_STATUS_PENDING_ACTION = 'Pending Action';
    public static final string DRIVE_STATUS_SUBMITTED = 'Submitted';
    public static final string DRIVE_STATUS_TENTATIVE = 'Tentative';

    public static final string DRIVE_TYPE_MOBILE = 'Mobile';

    public static final string EXCEPTION_CODE_TIME_CONFLICT = 'Time conflict.';
    public static final string EXCEPTION_CODE_NO_ALLOCATION = 'No Allocation.';
    public static final string EXCEPTION_CODE_MISSING_LOCATION = 'Missing Location.';
    public static final string EXCEPTION_CODE_ACCOUNT_NOT_AVAILABLE = 'Account is not available.';
    public static final string EXCEPTION_CODE_TERMINATION = 'Termination.';
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

    public static final string JOB_TYPE_INITIAL_EVALUATION = 'Initial Evaluation';
    public static final string JOB_TYPE_TREATMENT = 'Treatment';
    public static final string JOB_TYPE_GROUP_EVENT = 'Group Event';

    public static final string OPPORTUNITY_STAGE_NAME_PLANNING = 'Planning';
    
    public static final string PENDING_ACTION_REASON_CODE_LOW_DRIVE_PRODUCTIVITY = 'Low Drive Productivity';
    public static final string PENDING_ACTION_REASON_CODE_INSUFFICIENT_RESOURCES = 'Insufficient Resources';
    
    public static final string RESOURCE_TYPE_PERSON = 'Person';
    public static final string RESOURCE_TYPE_ASSET = 'Asset';
    
    public static final string RESOURCE_JOB_OFFER_STATUS_PENDING = 'Pending';
    public static final string RESOURCE_JOB_OFFER_STATUS_RESOURCEJOBOFFERCANCELLED = 'ResourceOfferCancelled';
    
    public static final string SLOT_STATUS_OPEN = 'Open';
	
    public static final string STAFFING_BUDGET_REQUEST_TYPE_ALL_HANDS_ON_DECK = 'Unavailability Day';
    public static final string STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT = 'Bidding Period';
    public static final string STAFFING_BUDGET_REQUEST_TYPE_STANDARD = 'Standard';
    
    public static final string SUPPORT_PLAN_STATUS_ACTIVE = 'Active';
    public static final string SUPPORT_PLAN_STATUS_CLOSED = 'Closed';
    
    public static final string TAG_TRAINEE = 'Trainee';
    public static final string TAG_TYPE_ROLE = 'Role';
    
    public static final string USER_TYPE_ADMIN = 'Admin';
    public static final string USER_TYPE_SCHEDULER = 'Scheduler';
	
    /* Internal coding */
    public static final string CUSTOM_FIELDS_EXTENSION = '__c';

    public static final string EXCEPTION_CONCURRENCY = 'CONCURRENCY_ERROR';
    public static final string EXCEPTION_CONCURRENCY_PATIENT = 'CONCURRENCY_PATIENT_ERROR';
    
    public static final string HOLIDAY_GLOBAL = 'global';

    public static final string TEMPORARY_ID_PREFIX = 'temp_';

}