global class skedSObjectType {

    public static final Integer ACTIVITY = 1;
    public static final Integer ACTIVITY_RESOURCE = 2;
    public static final Integer AVAILABILITY = 4;
    public static final Integer AVAILABILITY_PATTERN_RESOURCE = 8;
    public static final Integer AVAILABILITY_TEMPLATE_ENTRY = 16;
    public static final Integer AVAILABILITY_TEMPLATE_LOCATION = 32;
    public static final Integer AVAILABILITY_TEMPLATE_RESOURCE = 64;
    public static final Integer CLIENT_AVAILABILITY = 128;
    public static final Integer EXCEPTION_LOG = 256;
    public static final Integer JOB = 512;
    public static final Integer JOB_ALLOCATION = 1024;
    public static final Integer JOB_OFFER = 2048;
    public static final Integer JOB_TAG = 2048;
    public static final Integer LOCATION_AVAILABILITY = 8192;
    public static final Integer REGION = 16384;
    public static final Integer RESOURCE_OVERRIDE = 32768;
    public static final Integer RESOURCE_SECONDARY_REGION = 65536;
    public static final Integer RESOURCE_TAG = 131072;
    public static final Integer STAFFING_BUDGET_AVAILABILITY = 262144;
    public static final Integer CUSTOM_AVAILABILITY = 524288;
    public static final Integer STAFFING_BUDGET = 1048576;
    public static final Integer STAFFING_BUDGET_COLLECTION_OP = 2097152;
    public static final Integer STAFFING_BUDGET_SITE = 4194304;
    public static final Integer LOCATION_RESOURCE_SCORE = 8388608;
    public static final Integer ACTIVITY_COLLECTION_OPERATION = 16777216; 

    public static final Integer ACCOUNT_ALL_RELATED = JOB | CLIENT_AVAILABILITY;
    public static final Integer AVAILABILITY_TEMPLATE_ALL_RELATED = AVAILABILITY_TEMPLATE_ENTRY | AVAILABILITY_TEMPLATE_RESOURCE;
    public static final Integer JOB_ALL_RELATED = JOB_TAG | JOB_ALLOCATION | JOB_OFFER;
    public static final Integer LOCATION_ALL_RELATED = JOB | LOCATION_AVAILABILITY | AVAILABILITY_TEMPLATE_LOCATION;
    public static final Integer RESOURCE_ALL_EVENTS = JOB_ALLOCATION | AVAILABILITY | ACTIVITY | CUSTOM_AVAILABILITY;

    public static final Integer RESOURCE_ALL_RELATED = RESOURCE_ALL_EVENTS | RESOURCE_TAG | JOB_OFFER | AVAILABILITY_TEMPLATE_RESOURCE;
    public static final Integer RESOURCE_RAC_DATA = RESOURCE_ALL_EVENTS | RESOURCE_TAG | ACTIVITY_RESOURCE | AVAILABILITY_PATTERN_RESOURCE | RESOURCE_OVERRIDE | RESOURCE_SECONDARY_REGION;

    public static final Integer STAFFING_BUDGET_ALL = STAFFING_BUDGET_COLLECTION_OP | STAFFING_BUDGET_AVAILABILITY | STAFFING_BUDGET_SITE;

}