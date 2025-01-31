public class BSF_Constants {
    //Account Roles
	public static final String ACCOUNT_MANAGER = 'Account Manager';
    public static final String AREA_BOOKING_MANAGER = 'Area Booking Manager';
    public static final String DISTRICT_MANAGER = 'District Manager';
    public static final String ACCOUNT_PORTFOLIO = 'Account Portfolio';
    public static final String TEMPORARY_ACCOUNT_MANAGER = 'Temporary Account Manager';
    public static final String SICKLE_CELL_ACCOUNT_MANAGER = 'Sickle Cell Account Manager';
    public static final String NATIONAL_ACCOUNT_MANAGER = 'National Account Manager';
    public static final String Booking_Support = 'Booking Support';
    public static final String RELATIONSHIP_MANAGER = 'Relationship Manager';
    public static final String SUPERVISOR = 'Supervisor';//Recruitment Supervisor
    public static final String FIXED_SITE = 'Fixed Site'; 
    
    //OpportunityRoles
    public static final String OPPORTUNITY_OWNER = 'Opportunity Owner';//HRP-11424
        
	// 3807
	// Add account specialist role for portfolio type without having any record type
	 public static final String ACCOUNT_SPECIALIST = 'Account Specialist';
    
    
    //Taxonomy Record Types
    public static final String BIO_RECRUITMENT_RECORD_TYPE = 'Bio Recruitment CD';
    public static final String BIO_COLLECTION_RECORD_TYPE = 'Bio Collection BSF';
    public static final String TAXO_ACCOUNT_RECORD_TYPE = 'Bio Account Portfolio';
    public static final String TAXO_FIXED_SITE_RECORD_TYPE = 'Bio Fixed Sites';
    public static final String TAXO_SICKLE_CELL_RECORD_TYPE = 'Bio Sickle Cell Portfolio';
    public static final String TAXO_RELATIONSHIP_MGR_RECORD_TYPE = 'Bio Relationship Manager Portfolio';
    public static final String TAXO_NATIOANAL_ACCOUNT_RECORD_TYPE = 'National Account Manager Portfolio';
    public static final String TAXO_SUPERVISOR_RECORD_TYPE = 'Bio Recruitment Supervisor';
    public static final String TAXO_BOOKING_SUPPORT_RECORD_TYPE = 'Bio Booking Support';
    
    //Affiliation Record Types
    public static final String AFFILIATION_RECORD_TYPE = 'Sponsor Recognition';

    //Account Record Types
    public static final String FIXED_SITE_ACCOUNT_RECORD_TYPE = 'Fixed Site Account';
    public static final String MOBILE_ACCOUNT_RECORD_TYPE = 'Mobile Account';
    
    public static final String STRING_NO = 'No';
    public static final String STRING_YES = 'Yes';
    public static final String MARKETING_PROGRAM_REGION = 'Region';
    public static final String MARKETING_PROGRAM_TERITORRY = 'Teritorry';
    public static final String MARKETING_PROGRAM_DISTRICT = 'District';
    public static final String SOBJECT_FIELD_ID = 'Id';
    public static final String SOBJECT_FIELD_NAME = 'Name';
    public static final String SOBJECT_FIELD_PARENTID = 'Marketing_Program__c';
    public static final String SOBJECT_FIELD_NATIONWIDE_AFFILIATION_PROG = 'Nationwide_Marketing_Program__c';
    public static final String SOBJECT_ACCOUNT = 'Account';
    public static final String SOBJECT_OPPORTUNITY = 'opportunity';
    public static final String SOBJECT_OPP_INTERNAL = 'drive';
    public static final String SOBJECT_ACCOUNT_INTERNAL = 'account';
    public static final String SOBJECT_OPP_TEMPLATE_INTERNAL = 'template';
    public static final String SOBJECT_SCOPE_ACCOUNT = 'Account';
    public static final String SOBJECT_SCOPE_DRIVE = 'Drive';
    public static final String SOBJECT_SCOPE_TEMPLATE = 'Template';
    public static final String SOBJECT_SCOPE_BOTH = 'Both';
    
    //Static Variable for skipping Triggers
	public static Boolean skipAccountPortfolioAssignmentTrigger = false;
    public static Boolean skipAccountPortfolioAssignmentUpdateTrigger=false;
    public static Boolean skipAccountPortfolioAssignmentInsertTrigger=false;
    public static Boolean skipAccountPortfolioAssignmentDeleteTrigger=false;
    public static Boolean skipPortfolioAssignmentTrigger = false;
    public static Boolean isEndateBatch = false;
    public static Boolean isdateCheckbeforeInsertUpdate = true;
    public static Boolean isBackEndDelete = false;
    
    //Static boolean Variable for unchecking covering recruiter flag in backend
    public static Boolean isTeamMemberCreatedFromBackend = false;
    
    //Account Object:Account Status
    public static final String acctStatus='Inactive';
    
    //Opportunity Object:Drive Status
    public static final String driveStatusDraft='Draft';
    public static final String driveStatusCancel='Cancel';
    public static final String driveStatusComplete='Complete';

    // Portfolio types
    public static final String REGION_PORTFOLIO_TYPE = 'RDSE';
    public static final String ACCOUNT_BASED = 'Account Based';
    public static final String TERRITORY_BASED = 'TERRITORY Based';

    // Account Team & OpportunitySplit Picklist-Coverage
    public static final string accTeamLoa = 'Leave of Absence (LOA)';
    public static final string accTeamVacant = 'Vacant Territory';
   
    public static final string opSplitLoa = 'Coverage Leave of Absence'; 
    public static final string opSplitVacant = 'Coverage Vacancy';

    // Opportunity Stages
    public static final String STAGE_DISCOVERY = 'Discovery';
    public static final String STAGE_SOLICITATION = 'Solicitation';
    public static final String STAGE_COMMITTED = 'Committed';
    public static final String STAGE_CLOSED = 'Closed';
    public static final String STAGE_CANCELLED = 'Cancelled';

    // Drives on Calendar Status
    public static final String DOC_STATUS_DRAFT = 'Draft';
    public static final String DOC_STATUS_SYS_GEN = 'System Generated';
    public static final String DOC_STATUS_HOLD = 'Hold';
    public static final String DOC_STATUS_TENTATIVE = 'Tentative';
    public static final String DOC_STATUS_CONFIRMED = 'Confirmed';
    public static final String DOC_STATUS_COMPLETE = 'Complete';
    public static final String DOC_STATUS_CANCEL = 'Cancel';
    public static final String DOC_SOURCE = 'Calendar Build';
    
    //Operation Record Status:
    public static final String OPRECORD_STATUS_SUBMITTED = 'Submitted';
    public static final String OPRECORD_STATUS_NOTSUBMITTED = 'Not Submitted';
    
     // Opportunity Sources
     public static final String OPP_SOURCE_CALENDAR_BUILD = 'Calendar Build';
     public static final String OPP_SOURCE_PLAN_A_DRIVE = 'Plan a Drive';
     public static final String OPP_SOURCE_ADHOC = 'Adhoc';
     public static final String OPP_SOURCE_BUSINESS_PLANNING = 'Business Planning';
     public static final String OPP_SOURCE_ADHOC_CALENDAR_BUILD = 'Adhoc Calendar Build'; //HRP-11368


    // Opportunity Contact Roles
    public static final string SECURITY_LIST_RECIPIENT_ROLE = 'Security List Recipient';
    public static final string PRIMARY_CONTACT_ROLE = 'Primary Contact';

    // Task Record Types
    public static final String X72_HOUR_CHECK_IN_RECORD_TYPE = '72 Hour Check In';
    public static final String RECRUITMENT_MEETING_RECORD_TYPE = 'Recruitment Meeting';
    public static final String MARKETING_EXCEPTION_RECORD_TYPE = 'Marketing Exception';
    public static final String GENERAL_TASK_RECORD_TYPE = 'General Task';
    public static final String GENERAL_TASK_FOR_GLOBAL_ACTION_RECORD_TYPE = 'General Task for Global Action';
    public static final String TEAM_PORTFOLIO_ASSIGNMENT_RECORD_TYPE = 'Team Portfolio Assignment';

    // Task Subjects
    public static final String PUBLICITY_REVIEW_NEEDED_TASK = 'Publicity Review Needed';
    public static final String PRE_DRIVE_SECURITY_TASK = 'Security Information Completion';
    public static final String X72_HOUR_CHECK_IN_TASK = '72 Hour Check in - System Generated';
    public static final String RECRUITMENT_TASK = 'Recruitment Task - System Generated';
    public static final String SPONSOR_PLANNING_MEETING_TASK = 'Sponsor Planning Meeting - System Generated';
    public static final String MARKETING_EXCEPTION_TASK = 'Request for Marketing Exception';

    // Task Configuration Days
    public static final Integer PUBLICITY_REVIEW_DAYS_CONFIGURATION = 63;

    // Task Priority
    public static final String HIGH_PRIORITY_TASK = 'High';
    public static final String NORMAL_PRIORITY_TASK = 'Normal';
    public static final String LOW_PRIORITY_TASK = 'Low';

    // Task Status
    public static final String STATUS_NOT_STARTED = 'Not Started';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_CANCELLED = 'Cancelled';

    // Site Record Types
    public static final String MOBILE_SITE_RECORD_TYPE = 'Mobile Site';
    public static final String FIXED_SITE_RECORD_TYPE = 'Fixed Site';

    // Batch Related Stuffs
    public static final String DEFAULT_TERRITORY ='Called from DefaultTerritoryPortfolioBatchHelper';
    

    // Profiles
    public static final String SYS_ADMIN = 'System Administrator';
    public static final String GLOBAL_ADMIN = 'Global Admin';
    public static final String APS_ADMIN = 'APS Admin';
    public static final String RECRUITMENT_ADMIN = 'Recruitment Admin';
    public static final String DRD_PROFILE = 'DRD Profile';
    public static final String DRD_MANAGER = 'DRD Manager';
    public static final String AUTOMATED_PROCESS = 'Automated Process';

    //AccountPortfolioAssignment Service
    public static final String BYPASS_TEAMDML ='Bypass Team DML';
    public static final String ONE_TIME_BATCH ='One Time Batch';//HRP-12390

    // Template Status 
    public static final String ACTIVE_TEMPLATE = 'Active';
    public static final String INACTIVE_TEMPLATE = 'Inactive';

    // Type of Drive Picklist Values
    public static final String MOBILE_DRIVE = 'Mobile';
    public static final String FIXED_SITE_DRIVE = 'Fixed Site';

    //Test Class
    public static  Boolean Test_Run = false;

    public static map<String,String> taskSubjectKeyMap = new map<String,String>
    {'Recruitment Task - System Generated'=>'RecruitmentTask',BSF_Constants.PUBLICITY_REVIEW_NEEDED_TASK=>'PublicityOrderTask',
     'Calendar Build Review'=>'CBUnqualifiedStatus',string.valueof(System.Label.InvalidAccountAddressTaskSubject)=>'AccountInvalidAddress',
      BSF_Constants.PRE_DRIVE_SECURITY_TASK=>'OpportunityPreDriveTask','Drive Generation Failure Email'=>'DriveGenerationFailure',
      'Sponsor Planning Meeting - System Generated'=>'SponsorPlanningMeetingTask','72 Hour Check in - System Generated'=>'ClosedOpportunity72HourTask', 
        'Request for Marketing Exception'=>'MarketingException', 'Error in CB Drive Creation' => 'CBOpportunityGenerationFailure', //HRP-11611
        'Template Order Task' => 'TemplateOrderExpiry',//HRP-12664
        //HRP-11784 
        'Current AM Data integrity review' => 'CurrentAMDataIntegrityReview',
        'Current ABM Data integrity review' => 'CurrentABMDataIntegrityReview',
        'Blood Program Confirmation' => 'BloodProgramConfirmation',
        'Sponsor Introduction' => 'SponsorIntroduction',
        'First Notification to Sponsor' => 'FirstNotificationToSponsor',
        'Current AM Account/Portfolio Review Meeting' => 'CurrentAMAccPortfolioReviewMeeting',
        'Current ABM Account/Portfolio Review Meeting' => 'CurrentABMAccPortfolioReviewMeeting',
        'New AM Account/Portfolio Review Meeting' => 'NewAMAccPortfolioReviewMeeting',
        'New SBPM Account/Portfolio Review Meeting' => 'NewSBPMAccPortfolioReviewMeeting',
        'Template Order Task' => 'TemplateOrderExpiry',//HRP-12664
        //HRP-11784
        'Renew Military MoA' => 'RenewMilitaryMoA'
        }; 

    // Initiated By picklist Values
    public static final String ARC_INITIATED_FIXED = 'ARC Initiated-Fixed';
    public static final String ARC_INITIATED_MOBILE = 'ARC_Initiated_Mobile';
    public static final String SPONSOR_INITIATED_FIXED = 'Sponsor Initiated-Fixed';
    public static final String SPONSOR_INITIATED_MOBILE = 'Sponsor_Initiated_Mobile';

    // Cancellation Reason picklist Values
    public static final String ARC_MANAGEMENT_CANCELLATION_REASON = 'ARC Management';
    public static final String GEO_ALIGNMENT_CANCELLATION_REASON = 'Geo Alignment';

    // Account Status Picklist values
    public static final String ACCOUNT_STATUS_CLOSED = 'Closed';
    public static final String ACCOUNT_STATUS_ACTIVE = 'Active';
    

    //Notification Types
    public static final String NOTIFICATION_TYPE_EMAIL = 'Email';
    public static final String NOTIFICATION_TYPE_SALESFORCEPUSH = 'SalesforcePush';
    public static final String NOTIFICATION_TYPE_ONEOFF = 'Oneoff';
    public static final String NOTIFICATION_TYPE_CUSTOMSMS = 'CustomSMS';
    public static final String NOTIFICATION_TYPE_CALLOUT = 'CallOut';

    //Notification Status
    public static final String NOTIFICATION_STATUS_COMPLETE = 'Email';
    public static final String NOTIFICATION_STATUS_ERROR = 'Email';
    
    //Supervisory role for Jobs and Job Allocation
    public static final String SUPER_ROLE_APHERESIS_CHARGE = 'Apheresis Charge';
    public static final String SUPER_ROLE_CHARGE = 'Charge';
    public static final String SUPER_ROLE_CHARGE_2RBC = 'Charge - 2RBC';
    public static final String SUPER_ROLE_SPECIAL_COLLECTIONS_CHARGE = 'Special Collections Charge';
    public static final String SUPER_ROLE_DRIVE_LEAD = 'Drive Lead';
    public static final String SUPER_ROLE_TEAM_SUPERVISOR = 'Team Supervisor';
    
    //check if called from after delete
    public static  Boolean After_Delete = false;
    
    //HRP-11784 HandOffTasks
    public static final List<String> NoAMChangeTaskList = new List<String>{'Current AM Data integrity review','Current ABM Data integrity review','Blood Program Confirmation'};
    public static final String DRDSystemUser ='DRD System User';
    public static final string currentAMDataReview='Current_AM_Data_integrity_review';
    public static final String HandOffApiName='Account_Handoff_Settings__mdt.';
    public static final string ABM2SUPER='ABM2SUPER';
    public static final string ABM='ABM';
    public static final string AM='AM';
    public static final string Current='Current';
    public static final string Newtask='New';
    
    //HRP-12333 Task Reassignment Matrix Metadata category
    public static final String opportunityTasks='Opportunity Task';
    public static final String handOffTasks='HandOff';
    
    //HRP-13028 MaxDate
    public static final Date maxDate = Date.newInstance(4000,12,31);
    public static final DateTime CURRENT_DATE_TIME = system.now();
    public static final Date CURRENT_DATE = system.today();


    //HRP-12706 --> Starts here
    public static final String ROLLOVER_CONSIDERATION_DO_NOT_ROLL = 'Do Not Roll';
    public static final String  RUN_TYPE_MANUAL = 'Manual';
    public static final String  RUN_TYPE_SCHEDULED = 'Scheduled';

    public static Map<String, List<String>> MAP_BATCHINFO_FIELDSTOUPDATE = new Map<String, List<String>>{
        'Drive Status Correction' => new List<String>{'Status_Correction_Batch_Status__c', 'Status_Correction_Batch_Execution_Date__c'},
        'Calendar Build' => new List<String>{'CB_Batch_Status__c', 'CB_Batch_Execution_Date__c'},
        'Drive Generation' => new List<String>{'Drive_Gen_Batch_Status__c', 'Drive_Gen_Batch_Execution_Date__c'},
        'Sys Gen Run - FS' => new List<String>{'FS_Sys_Gen_Batch_Run_Status__c', 'FS_Sys_Gen_Batch_Run_Date__c'},
        'Sys Gen Run - Mobile' => new List<String>{'Mobile_Sys_Gen_Batch_Run_Status__c', 'Mobile_Sys_Gen_Batch_Run_Date__c'}
    };

    public static Map<String, List<String>> MAP_BATCHINFO_CBERRORLOGFIELDS = new Map<String, List<String>>{
        'Drive Status Correction' => new List<String>{'Drive__c', 'Operation_Record__c'},
        'Calendar Build' => new List<String>{'Opportunity__c'},
        'Drive Generation' => new List<String>{'Opportunity__c'},
        'Sys Gen Run - FS' => new List<String>{'Drive__c'},
        'Sys Gen Run - Mobile' => new List<String>{'Drive__c'}
    };

    public static Map<String, String> MAP_BATCHINFO_CLASSNAME = new Map<String, String>{
        'Drive Status Correction' => 'BSF_Batch_Drive_OpRecordStatusCorrection',
        'Calendar Build' => 'CalendarBuildEvaluateDrivesBatch',
        'Drive Generation' => 'CreateSkedDrivesBatch',
        'Sys Gen Run - FS' => 'DriveResourceAllocationBatch',
        'Sys Gen Run - Mobile' => 'DriveResourceAllocationBatch'
    };

    public static Map<String, String> MAP_DRIVETYPE_BATCHTYPE = new Map<String, String>{
        'Fixed Site' => 'Sys Gen Run - FS',
        'Mobile' => 'Sys Gen Run - Mobile'   
    };
    
    // Batch Status
    public static final String BATCH_STATUS_COMPLETED = 'Completed';
    public static final String BATCH_STATUS_PENDING = 'Pending';
    public static final String BATCH_STATUS_ERROR = 'Error';
    public static final String BATCH_STATUS_NOT_NEEDED = 'Not Needed'; //HRP-11368

    //CB Batches
    public static final String BATCH_CALENDAR_BUILD = 'Calendar Build';
    public static final String BATCH_DRIVE_STATUS_CORRECTION = 'Drive Status Correction';
    public static final String BATCH_DRIVE_GENERATION = 'Drive Generation';
    public static final String BATCH_SYSTEM_GENERATION = 'System Generation';
    public static final String BATCH_SYS_GEN_FS = 'Sys Gen Run - FS';
    public static final String BATCH_SYS_GEN_MOBILE = 'Sys Gen Run - Mobile';

    //HRP-12706 --> Ends here

    public static final String TERRITORY_TYPE_DIVISION = 'Division';
    public static final String TERRITORY_TYPE_ARC_REGION = 'ARC Region';
    public static final String TERRITORY_TYPE_DISTRICT = 'District';

    public static Map<String, Map<String, String>> map_eventType_startEndFieldApiName = new Map<String, Map<String, String>>{
        'sked__Job_Allocation__c' => new Map<String, String>{'Start' => 'sked__Start__c', 'End' => 'sked__Set_End__c'},
        'sked__Availability__c' => new Map<String, String>{'Start' => 'sked__Start__c', 'End' => 'sked__Finish__c'},
        'sked__Activity_Resource__c' => new Map<String, String>{'Start' => 'sked_Start1__c', 'End' => 'sked_End__c'},
        'sked__Activity__c' => new Map<String, String>{'Start' => 'sked__Start__c', 'End' => 'sked__End__c'},
        'sked__Resource_Override__c' => new Map<String, String>{'Start' => 'sked__Start__c', 'End' => 'sked__End__c'}
    };
      
    //HRP-7123 --> 
    public static final String POST_DRIVE_ANALYSIS_TASK = 'Post Drive Analysis';
    public static final String RECRUITMENT_PLANNING_TASK = 'Recruitment Planning Meeting';
    public static final String OPP_TYPE_Mobile = 'Mobile Opp';
    
    public static final String ACCOUNT_TYPE_EDUCATION = 'Education';
    public static final String ACCOUNT_INDUSTRY_CODE_MIDDLE_SCHOOL = 'Middle School';
    public static final String ACCOUNT_INDUSTRY_CODE_ELEMENTARY_SCHOOL = 'Elementary School';   
    public static final String APT_CHANGE_VIA_TEMPLATE = 'Apply Changes to Future Drive';  

    public static final String FEEDER_ONLY_ACCOUNT = 'Feeder Only';
    public static final String FEEDER_PLUS_ACCOUNT = 'Feeder Plus';
}