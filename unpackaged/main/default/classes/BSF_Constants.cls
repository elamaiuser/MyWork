/* @Description - This constant class includes constants (Record Type , Roles) related to bsf objects and mainly used 
                  in non drive generation related classes
                  
****************************************************************************************************************************8
*/
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
    public static Boolean skipPortfolioAssignmentTrigger = false;
    public static Boolean isEndateBatch = false;
    public static Boolean isdateCheckbeforeInsertUpdate = true;
    
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

    // Admin Profiles
    public static final String SYS_ADMIN = 'System Administrator';
    public static final String GLOBAL_ADMIN = 'Global Admin';
    public static final String APS_ADMIN = 'APS Admin';
    public static final String RECRUITMENT_ADMIN = 'Recruitment Admin';

    //AccountPOrtfolioAssignment Service
    public static final String BYPASS_TEAMDML ='Bypass Team DML';

    // Template Status 
    public static final String ACTIVE_TEMPLATE = 'Active';
    public static final String INACTIVE_TEMPLATE = 'Inactive';

    // Type of Drive Picklist Values
    public static final String MOBILE_DRIVE = 'Mobile';
    public static final String FIXED_SITE_DRIVE = 'Fixed Site';
    
    //Test Class
    public static  Boolean Test_Run = false;

    
}