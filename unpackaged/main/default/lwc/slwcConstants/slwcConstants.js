export const CALENDAR_FIELD_TYPE = {
  DATE: 'date',
  TIME: 'time',
  SHORT_TIME: 'shortTime',
  DATETIME: 'datetime',
  LOOKUP: 'lookup',
  TEXT: 'text'
}
  
export const CALENDAR_EVENT_LEVEL = {
  ONE: 1,
  TWO: 2,
  THREE: 3
}

export const PAC_LAYOUT_MODE = {
  WEEKS: 'weeks',
  MONTH: 'month'
}

export const PLAN_DRIVE_SLOT_COLOR_SETTING = {
  [true]: '#59b66e',
  [false]: '#d23331'
}

export const ACCOUNT_AVAILABILITY_PREFERENCE = {
  NEUTRAL: 'Neutral',
  PREFERRED: 'Preferred',
  NOT_PREFERRED: 'NotPreferred'
}

export const PLAN_DRIVE_SLOT_BACKGROUND_COLOR_SETTING = {
  [ACCOUNT_AVAILABILITY_PREFERENCE.NEUTRAL]: 'transparent',
  [ACCOUNT_AVAILABILITY_PREFERENCE.PREFERRED]: '#59b66e1a',
  [ACCOUNT_AVAILABILITY_PREFERENCE.NOT_PREFERRED]: '#ffff0057'
}

export const SLOT_TYPE = {
  _2RBC: '2RBC',
  WB: 'Whole Blood',
  PLATELET: 'Platelet',
  PLASMA: 'Plasma'
}

export const PROCEDURE_TYPE = {
  _2RBC: '2RBC',
  WB: 'WB',
  PLATELET: 'Platelet',
  PLASMA: 'Plasma'
}

export const PLAN_DRIVE_ERROR_MESSAGE_MAP = {
  'Exceed Operation Drive Limit': 'Exceed Operation Drive Limit',
  'Exceed 2RBC Operational Limit': 'Exceed 2RBC Operational Limit',
  'Exceed DOT Operational Limit': 'Exceed DOT Operational Limit',
  'Exceed CDL Operational Limit': 'Exceed CDL Operational Limit',
  'Insufficient Resources': 'Insufficient Resources',
  'Out of Operational Hours': 'The Drive times are outside the Operational hours set for the Collection Operation.'
}

export const JOB_ALLOCATION_STATUS = {
  COMPLETE: 'Complete',
  CONFIRMED: 'Confirmed',
  EN_ROUTE: 'En Route',
  CHECKED_IN: 'Checked In',
  DECLINED: 'Declined',
  DELETED: 'Deleted',
  DISPATCHED: 'Dispatched',
  PENDING_DISPATCH: 'Pending Dispatch',
  IN_PROGRESS: 'In Progress'
}

export const JOB_STATUS = {
  CANCELLED: 'Cancelled',
  COMPLETE: 'Complete',
  DISPATCHED: 'Dispatched',
  IN_PROGRESS: 'In Progress',
  PENDING_ALLOCATION: 'Pending Allocation',
  PENDING_DISPATCH: 'Pending Dispatch',
  QUEUED: 'Queued',
  READY: 'Ready',
  ON_SITE: 'On Site',
  EN_ROUTE: 'En Route'
}

export const RESOURCE_TYPE = {
  PERSON: 'Person',
  ASSET: 'Asset'
}

export const RESOURCE_ROLE_GROUP = {
  DRIVING_ROLES: 'Driving roles',
  SUPERVISORY_ROLES: 'Supervisory roles',
  STAFF_ROLES: 'Staff roles'
}

export const RESOURCE_ROLE = {
  x2RBC: '2RBC',
  VPHH: 'VP/HH',
  DRIVER: 'Driver'
}

export const ASSET_TYPE = {
  VEHICLE: 'Vehicle',
  EQUIPMENT: 'Equipment'
}

export const DRIVE_TYPE = {
  FIXED_SITE: 'Fixed Site',
  MOBILE: 'Mobile'
}

export const DRIVE_STATUS = {
  SYSTEM_GENERATED: 'System Generated',
  DRAFT: 'Draft',
  TENTATIVE: 'Tentative',
  CONFIRMED: 'Confirmed',
  COMPLETE: 'Complete',
  HOLD: 'Hold',
  CANCEL: 'Cancel'
}

export const DRIVE_REQUEST_CHANGE_STATUS = {
  PENDING: 'Pending',
  APPROVED: 'Approved',
  REJECTED: 'Rejected',
  CANCELLED: 'Cancelled',
  SUBMITTED: 'Submitted',
  APPROVED_BY_SYSTEM: 'Approved by System',
  WAITING_FOR_DM_APPROVAL: 'Waiting for DM Approval',
  WAITING_FOR_APS_APPROVAL: 'Waiting for APS Approval',
  APS_WAITING_FOR_DRD_FEEDBACK: 'APS Waiting for DRD Feedback',
  DM_WAITING_FOR_DRD_FEEDBACK: 'DM Waiting for DRD Feedback',
}

export const DRIVE_APPROVAL_STATUS = {
  NOT_SUBMITTED: 'Not Submitted',
  SUBMITTED: 'Submitted',
  WAITING_FOR_DM_APPROVAL: 'Waiting for DM Approval',
  WAITING_FOR_APS_APPROVAL: 'Waiting for APS Approval',
  APS_WAITING_FOR_DRD_FEEDBACK: 'APS Waiting for DRD Feedback',
  DM_WAITING_FOR_DRD_FEEDBACK: 'DM Waiting for DRD Feedback',
  APPROVED: 'Approved',
  REJECTED: 'Rejected'
}

export const RTV_APPROVAL_STATUS = {
  NOT_SUBMITTED: 'Not Submitted',
  SUBMITTED: 'Submitted',
  WAITING_FOR_DM_APPROVAL: 'Waiting for DM Approval',
  WAITING_FOR_CM_APPROVAL: 'Waiting for CM Approval',
  WAITING_FOR_APS_APPROVAL: 'Waiting for APS Approval',
  APPROVED: 'Approved',
  REJECTED: 'Rejected',
  EXPIRED: 'Expired'
}

export const AVAILABILITY_STATUS = {
  PENDING: 'Pending',
  WAITLIST: 'Waitlist',
  APPROVED: 'Approved',
  DECLINED: 'Declined',
  EXPIRED: 'Expired',
  CANCELLED: 'Cancelled',
  APPROVED_FROM_WAITLIST: 'Approved From Waitlist'
}

export const OPERATION_TYPE = { 
  INTEGRATED: 'Integrated',
  NON_INTEGRATED_WB: 'Non Integrated WB',
  NON_INTEGRATED_APH: 'Non Integrated APH'
}

export const OPTIMIZATION_STATUS = {
  PENDING: 'Pending',
  IN_PROGRESS: 'In Progress',
  COMPLETED: 'Completed',
  COMPLETE: 'Complete', // HRP-12509
  POST_PROCESS: 'Post Process',
  ERROR: 'Error',
  CLOSED: 'Closed'
}

export const TAG = {
  DRIVER: 'Driver',
  DRIVER_CDL: 'Driver CDL B',
  DRIVER_DOT: 'Driver - DOT'
}

export const PENDING_ACTION = {
  CANCEL_IN_PROCESS: 'Cancel In Process',
  DRIVE_SUBMISSION: 'Drive Submission',
  DRIVE_CHANGE_REQUEST: 'Drive Change Request'
}

export const DRIVE_DELIVERY_JOBS_TYPE = {
  PICK_UP : 'Pick Up',
  VOL_PICK_UP : 'VOL Pick Up',
  BAG : 'Bag'
}

export const DRIVE_DELIVERY_JOB_DISPLAY_MODE = {
  TAB: 'Tab',
  WIDGET: 'Widget'
}

export const SITE_FEEDBACK_ACCESS_MODE = {
  DRD: 'drd',
  RESOURCE: 'resource'
}

export const DRIVE_SHIFT_TRADE_TYPE = {
  NONE: 'None',
  DRIVE_SHIFT: 'Drive Shift',
  ACTIVITY: 'Activity',
  AVAILABLE_DAY: 'Available Day'
}

export const DRIVE_SHIFT_TRADE_STATUS = {
  SUBMITTED: 'Submitted',
  PENDING_APPROVAL: 'Pending Approval',
  WAITING_FOR_REQUESTING_STAFF_ACKNOWLEDGE: 'Waiting for Requesting Staff Acknowledge',
  WAITING_FOR_TRADING_STAFF_ACKNOWLEDGE: 'Waiting for Trading Staff Acknowledge',
  CANCELLED: 'Cancelled',
  EXPIRED: 'Expired'
}

export const DRIVE_CONTENTION = {
  DRIVE_LIMIT: 'Exceed Operation Drive Limit',
  x2RBC_LIMIT: 'Exceed 2RBC Operational Limit',
  DOT_LIMIT: 'Exceed DOT Operational Limit',
  CDL_LIMIT: 'Exceed CDL Operational Limit',
  OUT_OF_OPERATIONAL_HOURS: 'Out of Operational Hours',
  LACKING_EQUIPMENT: 'Lacking of equipment',
  LACKING_VEHICLE: 'Lacking of vehicles',
  WITHIN_42_DAYS: 'Within 42 days',
  INSUFFICIENT_RESOURCES: 'Insufficient Resources',
  PART_OF_LINKED_DRIVE: 'Part of Linked Drive',
  MULTI_SHIFT_DRIVE: 'Multi Shift Drive',
  CONFIRM_WITHIN_42_DAYS: 'Confirmed within 42 days',
  DUAL_ROLE_REMOVAL: 'Dual Role Removal',
  STAFFING_COMPLEMENT_CHANGED: 'Staffing Complement Changed',
  CO_CHANGED_CROSS_REGIONS: 'Collection Operation Change cross regions',
  ASSETS_NOT_SHARED_WITH_NEW_CO: 'Assets are not shared with new Collection Operation',
  EXCESS_STAFF_CAPACITY: 'Excess Staff Capacity'
}

export const DRIVE_CONTENTION_RESOLUTION = {
  ELECT_DRIVE_LIMIT: 'Elect to overbook drives',
  ELECT_2RBC_LIMIT: 'Elect to overbook 2RBC',
  ELECT_DOT_LIMIT: 'Elect to overbook DOT',
  ELECT_CDL_LIMIT: 'Elect to overbook CDL',
  ELECT_OUT_OF_OPERATIONAL_HOURS: 'Elect to run drive outside of Operational Hours',
  ELECT_LACKING_VEHICLE_USE_RENTAL: 'Use rental vehicles',
  ELECT_LACKING_VEHICLE_INSUFFICIENT_CAPACITY: 'Elect to use a vehicle with insufficient capacity',
  ELECT_WITHIN_42_DAYS: 'Elect to approve the drive that is submitted within 42 days',
  ELECT_INSUFFICIENT_RESOURCES: 'Elect to overbook staff',
  ELECT_PART_OF_LINKED_DRIVE: 'Elect to acknowledge the drive that is part of Linked Drive',
  ELECT_MULTI_SHIFT_DRIVE: 'Elect to acknowledge the drive that is multi shift drive',
  ELECT_CONFIRM_WITHIN_42_DAYS: 'Elect to approve the drive that is confirmed within 42 days',
  ELECT_DUAL_ROLE_REMOVAL: 'Elect to acknowledge dual role removal',
  ELECT_STAFFING_COMPLEMENT_CHANGED_ACCEPT_NEW_CHANGE: 'Accept New Staffing Complement',
  ELECT_STAFFING_COMPLEMENT_CHANGED_KEEP_CURRENT: 'Keep Current Staffing Complement',
  ELECT_CO_CHANGED_CROSS_REGIONS_REMOVE_FROM_LINKED_DRIVE: 'Remove from Linked Drive',
  ELECT_ASSETS_NOT_SHARED_WITH_NEW_CO: 'Elect to acknowledge the drive has assets that are not shared with new Collection Operation',
  ELECT_EXCESS_STAFF_CAPACITY: 'Elect to Proceed with Excess Staff Capacity'
}

export const DRIVE_CHANGE_REQUEST_ITEM_TYPE = {
  CHANGE: 'Change',
  IMPACT: 'Impact'
}

export const OPPORTUNITY_STAGE = {
  DISCOVERY: 'Discovery',
  SOLICITATION: 'Solicitation',
  COMMITTED: 'Committed',
  CLOSED: 'Closed'
}

export const RESOURCE_EMPLOYMENT_STATUS = {
  INACTIVE: 'Inactive',
  ACTIVE: 'Active',
  LEAVE: 'Leave'
}

export const LINK_DRIVE_TYPE = {
  MULTI_DAY: 'Multi Day',
  SINGLE_DAY: 'Same Day'
}

export const DRIVE_CHANGE_REQUEST_TYPE = {
  USER_CHANGE: 'User Change',
  COLLECTION_OPERATION_CHANGE: 'Collection Operation Change',
  ROLE_TIME_VARIANCE_CHANGE: 'Role Time Variance Change',
  ROLE_TIME_DETAIL_CHANGE: 'Role Time Detail Change',
  SITE_ADDRESS_CHANGE: 'Site Address Change',
  TRAVEL_TIME_CHANGE: 'Travel Time Change',
  REGENERATE_DRIVE: 'Regenerate Drive'
}

export const MANUALLY_CREATED_FROM = {
  STAFFING_MODAL: 'Staffing Modal',
  DRIVE_SCHEDULING: 'Drive Scheduling'
}

export const AVAILABILITY_TYPE = {
  ON_CALL: 'On Call'
}

export const OPERATION_DRIVE_LIMIT_TYPE = {
  DRIVE_LIMIT: 'Drive Limit',
  x2RBC_LIMIT: '2RBC Limit',
  DOT_LIMIT: 'DOT Limit',
  CDL_LIMIT: 'CDL Limit',
}

export const FIXED_SITE_APPOINTMENT_PATTERN = { 
  GROUPED: 'Grouped',
  EVEN: 'Even',
  EVEN_4_INTERVAL: 'Even - 4 Interval'
}

export const ADDRESS_REFERENCED_FOR_SCHEDULING = {
  WORK: 'Work',
  HOME: 'Home',
  SATELLITE: 'Satellite'
}

export const COLLECTION_OPERATION = {
  NON_COLLECTION_AREA: 'Non-Collection Area'
}

export const MAX_MIN_DATES_ISO = {
  MIN_DATE_ISO: '1900-01-01',
  MAX_DATE_ISO: '4000-12-31'
}

export const FIELD_TYPE = {
  TEXT: 'text',
  PICKLIST: 'picklist',
  MULTIPICKLIST: 'multipicklist',
  DATE: 'date',
  LOOKUP: 'lookup',
  NUMBER: 'number'
}

export const OPTIMIZER_SETTING_CONSTRAINT_TYPE = {
  SOFT: "Soft Constraint",
  HARD: "Hard Constraint"
}

export const OPTIMIZER_SETTING_DISPLAY_TYPE = {
  PICKLIST: 'Picklist',
  CHECKBOX: 'Checkbox'
}