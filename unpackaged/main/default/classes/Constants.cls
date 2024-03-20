//@Description - This constant class is used in Drive Generation Related Classes. It holds the constants required in drive generation

public with sharing class Constants {
    public static final string PROCEDURE_TYPE_PLATELET = 'Platelet';
    public static final string PROCEDURE_TYPE_PLASMA = 'Plasma';
    public static final string PROCEDURE_TYPE_WB = 'WB';
    public static final string PROCEDURE_TYPE_2RBC = '2RBC';
    public static final string APHERESIS_CHARGE = 'Apheresis Charge';
    public static final string APHERESIS = 'Apheresis';
    public static final string EQUIPMENT = 'Equipment';
    public static final string DONOR_AMBASSADOR = 'Donor Ambassador';
    public static final string APPOINTMENT_TYPE_WB = 'Whole Blood';
    public static final string ACCOUNT_OPERATION_TYPE_INTEGRATED = 'Integrated';
    
    public static final string FIX_SITE_OPP = 'Fixed Site';

    //---------------------------Site Operation Types ---------------------------------------
    public static final string INTEGRATED_OPERATION_TYPE = 'Integrated';
    public static final string NON_INTEGRATED_WB_OPERATION_TYPE = 'Non Integrated WB';
    public static final string NON_INTEGRATED_APH_OPERATION_TYPE = 'Non Integrated APH';
    // ---------------------------------------------------------------------------------------
    public static final string MOBILE_SITE_OPP = 'Mobile';
    public static final string DRIVE_STATUS_DRAFT = 'Draft';
    public static final string DRIVE_STATUS_CONFIRMED = 'Confirmed';
    public static final string DRIVE_STATUS_TENTATIVE = 'Tentative';
    public static final string CALENDAR_BUILD_STATUS_QUALIFIED = 'Qualified';
    public static final string JOB_TYPE_VEHICLE = 'Vehicle';
    public static final string JOB_TYPE_EQUIPMENT = 'Equipment';
    public static final string DRIVE_STATUS_CANCELLED = 'Cancel';
    public static final string AVAILABILITY_STATUS_APPROVED = 'Approved';
    public static final string ALLOCATION_STATUS_DELETED = 'Deleted';
    public static final string DRIVE_STATUS_SYSTEM_GENERATED = 'System Generated';
    public static final string JOB_TYPE_DRIVER = 'Driver';
    public static final string JOB_TYPE_DRIVER_SUPPORT = 'Driver Support';
    public static final string JOB_TYPE_VP_HH = 'VP/HH';
    public static final string JOB_TYPE_CHARGE = 'Charge';
    public static final string DRIVE_LOCATION_INSIDE = 'Inside';
    public static final string SOURCE_CALENDAR_BUILD = 'Calendar Build';
    public static final string OPERATION_DRIVE_2RBC_LIMIT = '2RBC Limit';
    public static final string OPERATION_DRIVE_CDL_LIMIT = 'CDL Limit';
    public static final string OPERATION_DRIVE_DOT_LIMIT = 'DOT Limit';
    public static final String TAG_TYPE_CERTIFICATION = 'Certification'; // HRP-11295
    public static final String JOB_TAG_RESOURCETYPE_PERSON = 'Person'; // HRP-11295
    public static final String JOB_TAG_RESOURCETYPE_PLT = 'Physical Location Type'; // HRP-11295

    //-----------------------------------Slot Multiplier Percentages--------------------------------------------
    // User for Calculating WB slot count on both Mobile Drive and Non-Integrated WB FS Drive

    public static final Decimal CALL_LIST_RECEIPIENT_SLOTMULTIPLIER = 1.15;
    public static final Decimal NO_CALL_LIST_RECEIPIENT_SLOTMULTIPLIER = 1.4;

    //-----------------------------------------------------------------------------------------------------------

    //-----------------------------------Fixed Site Appointment Patterns--------------------------------------------

    public static final String GROUPED_PATTERN = 'Grouped';
    public static final String EVEN_PATTERN = 'Even';
    public static final String EVEN_4_PATTERN = 'Even - 4 Interval';
    //-----------------------------------------------------------------------------------------------------------


    //-----------------------------------Drive Generation Relared Terminologies--------------------------------------------

    public static final String CALENDAR_BUILD_FIXED_SITE_DRIVE = 'Calendar Build - Fixed Site Drive';
    public static final String CALENDAR_BUILD_MOBILE_DRIVE = 'Calendar Build - Mobile Drive';
    public static final String FIXED_SITE_DRIVE_GEN = 'Regular Drive Generation - Fixed Site';
    public static final String MOBILE_DRIVE_GEN = 'Regular Drive Generation - Mobile';
    public static final String TECHNICAL_ISSSUE = 'Technical Issue';
    public static final String DATA_ISSSUE = 'Missing Required Data Issue';
    public static final String CATEGORY = 'Drive Generation';
    public static final String EMAIL_SUBJECT = 'Drive Generation Error';
    public static final String DRIVE_GEN_BATCH = 'CreateSkedDrivesBatch';
    public static final String BATCH_METHOD = 'Batch Execute';
    public static final String ERROR_LOG_TYPE = 'Error';
    public static final String ERROR_DESC_DATA_ISSUE = 'Missing Required Data';
    public static final String FIXED_SITE_DRIVE_GENEERRATOR = 'CreateSkedDrive';
    public static final String FIXED_SITE_DRIVE_GEN_METHOD = 'createDrives';
    public static final String MOBILE_DRIVE_GENEERRATOR = 'GenerateMobileDrive';
    public static final String MOBILE_DRIVE_GEN_METHOD = 'generateDrives';

    //-----------------------------------------------------------------------------------------------------------
    
    // Drive Service Roles

    public static final String PRIMARY_CONTACT = 'Primary Contact';

}