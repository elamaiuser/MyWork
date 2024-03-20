global class skedSkeduloApiData {

    public virtual class resultBase extends skedCalloutResultBase {
        public error error;
        public List<error> errors;
    }

    public class error {
        public string errorType;
        public string message;
        public string errorKey;
        public string path;
    }
    
    /* NOTIFICATION */
    global class notificationResult extends resultBase {
        public notificationReturnedData result;
    }
    
    public class notificationReturnedData {
        public string jobId;
        public List<allocationData> results;
    }
    
    public class allocationData {
        public string resourceId;
        public string protocol;
        public error error;
    }

    /* SMS Message */
    public class smsResult extends resultBase {
        public smsReturnedData result;
    }

    public class smsReturnedData {
        public boolean success;
    }

    /* One Off */
    public class oneOffResult extends resultBase {
        public oneOffReturnedData result;
    }

    public class oneOffReturnedData {
        public string protocol;
    }

    /* GEOCODE */
    public class geocodeResult extends resultBase {
        public list<geocodeResultItem> result;
    }

    public class geocodeResultItem {
        public geocodeSuccess geocodeSuccess;
        public geocodeFailure geocodeFailure;
    }

    public class geocodeSuccess {
        public string address;
        public latlng latlng;
    }

    public class latlng {
        @AuraEnabled public decimal lng {get;set;}
        @AuraEnabled public decimal lat {get;set;}
    }
    
    public class geocodeFailure {
        public string address;
        public geocodeFailureReason reason;
    }
    
    public class geocodeFailureReason {
        public string msg;
    }

    /* DISTANCE MATRIX */
    public class distanceMatrixResult extends resultBase {
        @AuraEnabled public Matrix result {get;set;}
    }
    
    public class Matrix {
        @AuraEnabled public List<List<Element>> matrix {get;set;}
    }
    
    public class Distance {
        @AuraEnabled public integer distanceInMeters {get;set;}
    }
    
    public class Duration {
        @AuraEnabled public integer durationInSeconds {get;set;}
    }
    
    public class Element {
        @AuraEnabled public Distance distance {get;set;}
        @AuraEnabled public Duration duration {get;set;}
        @AuraEnabled public string status {get;set;}
    }
    
    public class distanceMatrixAsyncResult extends resultBase {
        public string id;
    }
    
    public class distanceMatrixAsyncModel {
        public List<List<distanceModel>> values;
        public DateTime fromTime;
        public DateTime toTime;
    }
    
    public class distanceModel {
        public string status;
        public decimal duration;
        public decimal distance;
    }
    
    /* RESOUCE AVAILABILITY */
    global class simplifiedResourceAvailabilityResult extends resultBase {
        public List<simplifiedResourceAvailability> result;
    }

    global class simplifiedResourceAvailability {
        public string resourceId;
        public List<simplifiedAvailability> mergedAvailabilities;
        //public List<availabilityEntry> entries;
    }

    global class simplifiedAvailability {
        public DateTime start;
        public DateTime end_x;
    }

    /*global class availabilityEntry {
        public string templateId;
        public string templateEntryId;
        public string name;
        public string type;
        public DateTime start;
        public DateTime end_x;
        public boolean available;
    }*/

    global class simplifiedResourceAvailabilityPayload {
        public string resource_ids;
        public string start;
        public string end_x;
        public boolean mergedAvailabilities;
    }
    
    /* Timezone */
    public class timezoneResult extends resultBase {
        public Decimal dstOffset;
        public Decimal rawOffset;
        public String timeZoneId;
    }
    
    /* Availability Pattern Result */
    global class upsertAvailabilityPatternResult extends resultBase {
        public string created;
        public string result;
    }
    
    /* Availability Pattern Payload*/
    public class interval {
        public string startTime;
        public string endTime;
    }
    
    public class day {
        public integer day;
        public string weekday;
        public List<interval> intervals;
    }
    
    public class pattern2 {
        public integer lengthDays;
        public integer repeatWeeks;
        public List<day> days;
        public string type;
    }
    
    public class pattern {
        public string UID;
        public string name;
        public string description;
        public pattern2 pattern;
    }
    
    public class resource {
        public string UID;
        public string resourceId;
        public DateTime start;
        public DateTime end_x;
    }
    
    public class availabilityPatternPayload {
        public pattern pattern;
        public List<resource> resources;
    }

    public class schedulingOptions {
        public boolean assumeResourceCanTravelAfterEnd;
        public boolean assumeResourceCanTravelBeforeStart;
        public boolean balanceWorkload;
        public boolean minimizeResources;
        public boolean jobTimeAsTimeConstraint;
        public boolean preferJobTimeOverTimeConstraint;
        public boolean respectSchedule;
        public boolean ignoreTravelTimes;
        public boolean ignoreTravelTimeFirstJob;
        public boolean ignoreTravelTimeLastJob;
        //public boolean optimizedJobsOnly;
        public integer maxTravelTimeInMinutes;
        public integer padding;
        public integer snapUnit;
    }

    public class responseConfig {
        public boolean optimizedJobsOnly;
    }

    /* RESOURCE AVAILABILITY */
    public class resourceAvailabilityResult extends resultBase {
        public Map<string, resourceAvailability> result;
    }

    public class resourceAvailability {
        public List<timeslot> available;
        public List<timeslot> unavailable;
        public List<shift> shifts;
        public List<region> regions;
    }

    public class shift {
        public string UID;
        public string start;
        public string end_x;
        public string locationId;
        public string regionId;
        public string displayName;
    }

    public class region {
        public string start;
        public string end_x;
        public List<string> regionIds;
    }

    public class timeslot {
        public string start;
        public string end_x;
    }

    /* SCHEDULE FOR JOB */
    public class scheduleForJobResult extends resultBase {
        public scheduleForJob result;
    }

    public class scheduleForJob {
        public score score;
        public integer timeToSolve;
        public list<route> routes;
        public List<scheduled> unscheduled;
    }

    public class score {
        public integer hardScore;
        public integer mediumScore;
        public integer softScore;
    }

    public class route {
        public string resourceId;
        public string resourceName;
        public List<routeDetail> route;
    }

    public class routeDetail {
        public string jobId;
        public string jobName;
        public string start;
        public integer duration;
        public integer travelTime;
        public string type;
    }

    public class scheduled {
        public string jobId;
        public string jobName;
        public List<string> jobReasons;
        public Map<string, resourceReason> resourceReasons;
    }

    public class resourceReason {
        public string name;
        public string address;
        public List<string> reasons;
    }
    
    /* OPTIMIZATION */
    public class optimizationRunModel {
        public string uid;
    }
    
    public class optimizationRunResult extends resultBase {
        public boolean success;
    }

    /* OPTIMIZATION FEATURE MODEL */
    public class featureSolveResponseResult {
        public string id;
    }

    public class featureSolveResponse extends resultBase {
        public featureSolveResponseResult result;
    } 

    public class featureModel {
        public string solver;
        public List<featureAllocation> allocations;
        public List<featureResource> resources;
        public List<featureStatute> statutes;
        public List<featureLocation> locations;
        public List<featureSharedAttribute> sharedAttributes;
        public featureSchedulingPeriod schedulingPeriod;
        public string timezone;
        public featureMeta meta;
        public featureOptions options;
    }

    public class featureOptions {
        public boolean hard;
        public boolean locations;
    }


    public class featureSchedulingPeriod {
        public DateTime start;
        public DateTime end_x;
    }

    public class featureMeta {
        public List<optMetaJobAllocation> allocationMeta;
    }

    public class featureSharedAttribute {
        public string id;
        public List<string> allocations;
        public string attributeId;
        public Double minimumQuantity;
    }

    public class featureStatute {
        public string id;
        public integer minimumRestPeriodBetweenAllocations;
        public integer maximumHoursForPlanningPeriod;
        public integer minimumHoursForPlanningPeriod;
    }

    public class featureLocation {
        public string id;
        public Double latitude;
        public Double longitude;
    }

    public class optMetaJobAllocation {
        public string featureAllocId;
        public string existingAllocationId;
        public string jobId;
    }

    public class featureAllocation {
        public string id;
        public DateTime start;
        public Double duration;
        public string resourceId;
        public string locationId;
        public integer priority;
        public boolean locked;
        public List<featureAttributeRequirement> attributeRequirements;
        public featureResourceConstraint resourceConstraints;
        public List<string> preferredResourceIds;
    }

    public class featureAttributeRequirement {
        public string id;
        public Double weighting;
    }

    public class featureResourceConstraint {
        public string type;
        public List<string> resources;
    }

    public class featureResource {
        public string id;
        public string primaryAttributeId;
        public string statuteId;
        public List<featureResourceAttribute> attributes;
        public string locationId;
        public List<featureAvailability> availability;
        public integer efficiency;
    }

    public class featureResourceAttribute {
        public string id;
        public DateTime expiry;
    }

    public class featureAvailability {
        public DateTime from_x;
        public DateTime to;
    }
    
    /* Optimization Run */
    public class optimizationRunDiffResult extends ResultBase {
        public string solver;
        public Map<string, optimizationDiffAllocation> allocations;
    }
    
    public class optimizationDiffAllocation {
        public string deallocation;
        public string allocation;
    }
    
    public class optimizationRunMetaResult extends ResultBase {
        public List<allocationMetaItem> allocationMeta;
    }
    
    public class allocationMetaItem {
        public string jobId;
        public string featureAllocId;
        public string existingAllocationId;
    }

    /* Geo Direction */
    public class directionsRequest {
        public latlng origin;
        public latlng destination;
    }
    global class directionsResult extends resultBase {
        public directionsResultData result;
    }
    public class directionsResultData {
        public List<List<direction>> routes;
    }

    public class direction {
        public leg leg;
        public travelInfo travelInfo;
    }
    public class leg {
        public latlng origin;
        public latlng destination;
        public List<String> avoid;
    }
    public class travelInfo {
        public duration duration;
        public distance distance;
        public string status; 
    }
    
}