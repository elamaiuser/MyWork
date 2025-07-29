global class skedModels {
    
    global virtual class modelBase {
        public string id;
        public string name;
        public string recordTypeName;
        public user createdBy;
        public string createdOnDate;
        public integer createdOnTime;
        public user lastModifiedBy;
        public string lastModifiedDate;
        public integer lastModifiedTime;
        public boolean selected;
        public string action;
        public boolean isEditable;
        public string objectType;
        public string temporaryId;
    }
    
    global virtual class event extends modelBase implements Comparable {
        public address address;
        public decimal duration;
        public string endDate;
        public integer endTime;
        public string eventType;
        public transient DateTime finish;
        public transient Location geoLocation;
        public boolean isAllDay;
        public boolean isAllTimePreferred;
        public integer startTimeInMinutes;
        public integer endTimeInMinutes;
        public string scheduleId;
        public string scheduleDescription;
        public string startDate;
        public integer startTime;
        public transient DateTime start;
        public string status;
        public string timezone;
        public string timezoneSidId;
        
        public void updateDateTimeFields(string inputTimezoneSidId) {
            this.startDate = this.start.format(skedDateTimeUtils.DATE_ISO_FORMAT, inputTimezoneSidId);
            this.endDate = this.finish.format(skedDateTimeUtils.DATE_ISO_FORMAT, inputTimezoneSidId);
            this.startTime = integer.valueOf(this.start.format('Hmm', inputTimezoneSidId));
            this.endTime = integer.valueOf(this.finish.format('Hmm', inputTimezoneSidId));
            this.startTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(this.startTime);
            this.endTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(this.endTime);
        }
        
        public void updateStartFinish(string inputTimezoneSidId) {
            if (this.startTime == NULL || this.endTime == NULL) {
                this.startTime = 0;
                this.endTime = 0;
            }
            this.start = skedDateTimeUtils.newDateTimeInstance(this.startDate, this.startTime, inputTimezoneSidId);
            this.finish = skedDateTimeUtils.newDateTimeInstance(this.endDate, this.endTime, inputTimezoneSidId);
        }
        
        public virtual Integer compareTo(Object compareTo) {
            event compareToRecord = (event)compareTo;
            Integer returnValue = 0;
            
            if (start > compareToRecord.start) {
                returnValue = 1;
            }
            else if (start < compareToRecord.start) {
                returnValue = -1;
            }
            return returnValue;
        }
    }
    
    global virtual class eventOwner extends modelBase {
        public address address {get;set;}
        public transient Location geoLocation;
        
        public List<event> availability {get;set;}
        public List<event> events {get;set;}
    }
    
    global virtual class address {
        public string fullAddress;
        public string postalCode;
        public geometry geometry;
    }
    
    global virtual class geometry {
        public decimal lat;
        public decimal lng;
        
        public geometry(Location geoLocation) {
            if (geoLocation != null) {
                this.lat = geoLocation.getLatitude();
                this.lng = geoLocation.getLongitude();
            }
        }
        
        public geometry(decimal lat, decimal lng) {
            this.lat = lat;
            this.lng = lng;
        }
    }
    
    global virtual class journey {
        public geometry origin;
        public geometry destination;
        public integer travelTime;
        public decimal distance;
        public string status;
    }

    global virtual class startEnd extends modelBase {
        public Date startDate;
        public Date endDate;
    }
    
    /************************************************ SALESFORCE OBJECT MODELS ************************************************/
    global virtual class account extends modelBase {
        public address address;
        public string availabilityType;
        public string directContactId;
        public contact directContact;
        public string phone;
        public string photoUrl;
        public string regionId;
        
        public List<clientAvailability> clientAvailabilities;
        public List<job> jobs;
    }
    
    global virtual class caseModel extends modelBase {
        public string accountId;
        public string contactId;
        public string caseNumber;
    }
    
    global virtual class contact extends modelBase {
        public string accountId;
        public address address;
        public string birthdate;
        public string email;
        public string firstName;
        public boolean isPrimary;
        public string lastName;
        public string phone;
    }
    
    global virtual class user extends modelBase {
        public string photoUrl;
    }
    
    /************************************************ SKEDULO MANAGED OBJECT MODELS ************************************************/
    global virtual class accountResourceScore {
        public string accountId;
        public string resourceId;
        public boolean whitelisted;
        public boolean blacklisted;
    }

    global virtual class locationResourceScore {
        public string locationId;
        public string locationResourceRelationship;
        public string locationType;
        public string resourceId;
    }
    
    global virtual class activity extends event {
        public decimal activityResourceCount;
        public string activityTitle;
        public address address;
        public string arcRegionId;
        public territory arcRegion;
        public string biomedCollectionOpId;
        public string districtId;
        public string driveId;
        public drive drive;
        public string eventType;
        public decimal fixedSiteStaffQuantity;
        public Boolean inheritResourcesFromDrive;
        public boolean isGroupActivity;
        public string linkedDrivesId;
        public linkedDrives linkedDrives;
        public decimal mobileStaffQuantity;
        public string notes;
        public decimal quantity;
        public boolean reduceFromStaffingConstraint;
        public string regionId;
        public string resourceId;
        public string resourceOverrideId;
        public boolean showOnCalendar;
        public string subtype;
        public string timezoneSidId;
        public string timezone;
        public List<String> biomedCollectionOpIds;
        public List<string> driveTypes;
        public List<string> districtIds;
        public List<activityCollectionOperation> activityCollectionOperations;
        public List<activityResource> activityResources;  
    }

    global virtual class activityCollectionOperation extends event {
        public string activityId;
        public string biomedCollectionOpId;
        public string districtId;
        public string territoryKey;
        public activity activity;
        public biomedCollectionOp biomedCollectionOp;
    }
    
    global virtual class activityResource extends event {
        public string activityId;
        public activity activity;
        public driveShiftTrade driveShiftTrade;
        public string resourceId;
        public resource resource;
    }
    
    global virtual class availability extends event {
        public string approvalReason;
        public boolean bypassAutoApprovalProcess;
        public string callOutForActivityId;
        public activity callOutForActivity;
        public string callOutForDriveId;
        public drive callOutForDrive;
        public string callOutNotes;
        public string callOutReason;
        public string callOutReceivedDate;
        public integer callOutReceivedTime;
        public string callOutType;
        public string declineReason;
        public string exceptionCode;
        public boolean integrateWithWorkday;
        public boolean isAvailable;
        public boolean isException;
        public string notes;
        public string otherDeclineReason;
        public string remainingSlots;
        public resource resource;
        public string resourceId;
        public boolean waitlistConfirmed;
        public Decimal ranking;
        public staffingBudget staffingBudget;
        public string lastModifiedById;
        public boolean approvedViaAutomation;
        public string biddingType;
        public List<staffingBudgetAvailability> staffingBudgetAvailabilities;
        public List<exceptionLog> exceptionLogs;
        public string timeOffReasonCode;
        public string workdaySyncMessage;
        public string workdaySyncStatus;
        
        public transient Date availabilityDate;
    }
    
    global virtual class availabilityCapacitySetting extends modelBase {
        public integer lowerPercentage;
        public integer upperPercentage;
        public string backgroundColor;
        public boolean showLegend;
    }
    
    global virtual class availabilityPattern extends modelBase {
        public string description;
        public string hash;
        public string pattern;
        public boolean validate2CDORule;
        public skedAvailabilityPatternData patternData;
        public List<availabilityPatternResource> availabilityPatternResources;
    }
    
    global virtual class availabilityPatternResource extends modelBase {
        public string availabilityPatternId;
        public availabilityPattern availabilityPattern;
        public string endDate;
        public integer endTime;
        public string resourceId;
        public resource resource;
        public string startDate;
        public integer startTime;
        public string status;
    }
    
    global virtual class availabilityTemplate extends modelBase {
        public string endDate;
        public string startDate;
        public string timezoneSidId;
        public List<availabilityTemplateEntry> availabilityTemplateEntries;
        public List<availabilityTemplateResource> availabilityTemplateResources;
    }
    
    global virtual class availabilityTemplateEntry extends modelBase {
        public string availabilityTemplateId;
        public integer endTime;
        public boolean isAllDay;
        public integer startTime;
        public integer weekNo;
        public string weekday;
    }
    
    global virtual class availabilityTemplateResource extends modelBase {
        public string availabilityTemplateId;
        public string resourceId;
        public resource resource;
    }

    global virtual class customAvailability extends event {
        public boolean isAvailable;
        public string notes;
        public resource resource;
        public string resourceId;
    }
    
    global virtual class holiday extends modelBase {
        public string biomedCollectionOpId;
        public string endDate;
        public boolean isGlobal;
        public string regionId;
        public string startDate;
    }
    
    global virtual class job extends event {
        public string accountId;
        public account account;
        public string cancellationReason;
        public string cancellationReasonNotes;
        public string contactId;
        public contact contact;
        public string description;
        public string driveName;
        public string driveUFID;
        public boolean inheritAccountTasks;
        public boolean isCareTeam;
        public decimal jobAllocationCount;
        public string jobStatus;
        public string notes;
        public decimal quantity;
        public string rescheduleJobId;
        public string regionId;
        public region region;
        public string recurringScheduleId;
        public recurringSchedule recurringSchedule;
        public string serviceLocationId;
        public serviceLocation serviceLocation;
        public string supportPlanId;
        public string supportPlanName;
        public decimal totalProductsProjected;
        
        public List<job> followups;
        public List<jobAllocation> jobAllocations;
        public List<resourceJobOffer> jobOffers;
        public List<jobTag> jobTags;
        public List<jobAllocation> possibleAllocations;
    }
    
    global virtual class jobAllocation extends event {
        public List<string> additionalRoles;
        public string calloutNotes;
        public string calloutReasonCode;
        public string callOutReceivedDate;
        public integer callOutReceivedTime;
        public boolean calloutReported;
        public string calloutType;
        public driveShiftTrade driveShiftTrade;
        public boolean isAvailable;
        public boolean isQualified;
        public boolean isHandledExceptionFromClient;
        public string jobId;
        public job job;
        public string resourceId;
        public resource resource;
        public geometry startFromLocation;
        public integer travelTimeFrom;
        public decimal travelDistanceFrom;
        public geometry goToLocation;
        public integer travelTimeTo;
        public decimal travelDistanceTo;
        public boolean guarded;
        
        public transient event previousEvent;
        public transient event nextEvent;
    }
    
    global virtual class jobTag extends modelBase {
        public string jobId;
        public string tagId;
        public tag tag;
    }

    global virtual class linkedDrives extends modelBase {
        public string linkedDriveType;
    }
    
    global virtual class resource extends eventOwner {
        public accountResourceScore accountResourceScore;
        public string anticipatedLeaveReturnDate;
        public string arcRegionName;
        public string biomedCollectionOpId;
        public string biomedCollectionOpName;
        public string category;
        public decimal dailyTimeOffHours;
        public string districtName;
        public string effectiveDate;
        public string email;
        public string employmentStatus;
        public string employmentType;
        public string mobilePhone;
        public string photoUrl;
        public string plannedTerminationDate;
        public decimal presDonorCapacity;
        public decimal quantity;
        public decimal rating;
        public string regionId;
        public region region;
        public string resourceType;
        public boolean restrictsToFullDayPto;
        public string roles;
        public string seniorityDate;
        public string terminationDate;
        public string timezoneSidId;
        public string userId;
        public string userType;
        public decimal manualRankingPriority;
        public List<activity> activities;
        public List<activityResource> activityResources;
        public List<availability> availabilities;
        public List<availabilityPatternResource> availabilityPatternResources;
        public List<customAvailability> customAvailabilities;
        public List<jobAllocation> jobAllocations;
        public List<resourceTag> resourceTags;
        public List<resourceOverride> resourceOverrides;
        public List<resourceRegion> resourceRegions;
        public List<locationResourceScore> locationResourceScores;
        
        public integer noOfAvailableJobs;
        public integer noOfJobs;
        public transient DateTime firstTagExpiry;
        public transient List<skedModels.event> templateEvents;
    }
    
    global virtual class resourceBiomedCollectionOp extends modelBase {
        public string biomedCollectionOpId;
        public string resourceId;
    }
    
    global virtual class resourceJobOffer extends modelBase {
        public string jobId;
        public string jobEndDate;
        public integer jobEndTime;
        public string jobStartDate;
        public integer jobStartTime;
        public string resourceId;
        public string status;
        public integer travelTimeFrom;
        public decimal travelDistanceFrom;
        public job job;
        public resource resource;
    }
    
    global virtual class resourceOverride extends modelBase {
        public address address;
        public biomedCollectionOp biomedCollectionOp;
        public string biomedCollectionOpId;
        public string description;
        public string districtId;
        public string endDate;
        public integer endTime;
        public boolean isTravelRequired;
        public resource resource;
        public string resourceId;
        public string startDate;
        public integer startTime;
        public string timezone;
        public string timezoneSidId;
        public string travelToStartDate;
        public integer travelToStartTime;
        public string travelToEndDate;
        public integer travelToEndTime;
        public string travelBackStartDate;
        public integer travelBackStartTime;
        public string travelBackEndDate;
        public integer travelBackEndTime;
    }
    
    global virtual class resourceRegion extends modelBase {
        public string endDate;
        public integer endTime;
        public region region;
        public string regionId;
        public resource resource;
        public string resourceId;
        public string startDate;
        public integer startTime;
    }
    
    global virtual class resourceTag extends modelBase {
        public string expiryDate;
        public integer expiryTime;
        public DateTime expiry;
        public string resourceId;
        public string restrictionStartDate;
        public string restrictionEndDate;
        public string roleStatus;
        public string startDate;
        public integer startTime;
        public DateTime start;
        public string tagId;
        public tag tag;
    }
    
    global virtual class resourceTimeOffBudget extends modelBase {
        public string resourceId;
        public string startDate;
        public string endDate;
        public decimal availableHours;
        public decimal requiredHours;
        
        public transient Date startDateValue;
        public transient Date endDateValue;
    }
    
    global virtual class region extends modelBase {
        public string collectionOperationId;
        public string territoryId;
        public string timezoneSidId;
    }
    
    global virtual class recurringSchedule extends modelBase {
        public string description;
        public boolean skipHolidays;
        
        public List<activity> activities;
        public List<availability> availabilities;
        public List<clientAvailability> clientAvailabilities;
        public List<job> jobs;
        
        public List<event> events;
        
        //To be removed
        public string eventType {get;set;}
        public string objectType {get;set;}
    }
    
    global virtual class serviceLocation extends eventOwner {
        public string accountId;
        public string name;
        public address address;
        public string description;
        public string regionId;
        public string biomedCollectionOpId;
        public string biomedCollectionOpName;
        public string timezoneSidId;
        public region region;
        public biomedCollectionOp biomedCollectionOp;
        public List<locationAvailability> locationAvailabilities;
        public List<job> jobs;
    }

    global virtual class siteCollectionOperation extends modelBase {
        public biomedCollectionOp biomedCollectionOp;
        public serviceLocation site;
        public string biomedCollectionOpId;
        public string biomedCollectionOpName;
        public string endDate;
        public string startDate;
        public string siteId;
    }
    
    global virtual class tag extends modelBase {
        public string expiryDate;
        public integer expiryTime;
        public decimal priority;
        public string tagType;
        public transient DateTime expiryDateTime;
    }
    
    global virtual class userFilter extends modelBase {
        public string userId;
        public string category;
        public string jsonData;
    }
    
    /************************************************ SKEDULO CUSTOM MODELS ************************************************/
    global virtual class accidentIncidentReport extends modelBase {
        public string incidentType;
        public string createdDate;
        public resource createdBy;
        public string createdById;
    }
    
    global virtual class biomedCollectionOp extends modelBase {
        public address stagingLocation;
        public string territoryId;
        public List<region> regions;
        public boolean waitlistEnabled;
        public string name;
    }
    
    global virtual class clientAvailability extends event {
        public string accountId;
        public account account;
        public string contactId;
        public contact contact;
        public boolean isAllTimePreferred;
        public boolean isAvailable;
        public string notes;
        public string patientId;
        public DateTime preferredEnd;
        public string preferredEndDate;
        public integer preferredEndTime;
        public DateTime preferredStart;
        public string preferredStartDate;
        public integer preferredStartTime;
        public string serviceLocationId;
        
        public void updatePreferredDateTimeFields(string inputTimezoneSidId) {
            if (this.preferredStart != NULL) {
                this.preferredStartDate = this.preferredStart.format(skedDateTimeUtils.DATE_ISO_FORMAT, inputTimezoneSidId);
                this.preferredStartTime = integer.valueOf(this.preferredStart.format('Hmm', inputTimezoneSidId));
            }
            if (this.preferredEnd != NULL) {
                this.preferredEndDate = this.preferredEnd.format(skedDateTimeUtils.DATE_ISO_FORMAT, inputTimezoneSidId);
                this.preferredEndTime = integer.valueOf(this.preferredEnd.format('Hmm', inputTimezoneSidId));
            }
        }
    }
    
    global virtual class displaySetting extends modelBase {
        public integer availableEnd;
        public integer availableStart;
        public string backgroundColor;
        public string category;
        public string color;
        public string eventType;
        public string eventStatus;
        public boolean isActive;
        public boolean showLegend;
    }

    global virtual class drive extends modelBase {
        public string collectionOperationId;
        public string driveDate;
        public string UFID;
    }

    global virtual class driveShiftTrade extends modelBase {
        public string apsNotes;
        public string requestingStaffTradingEventName;
        public string requestingStaffTradingEventDate;
        public string requestingStaffTradingType;
        public string requestingStaffId;
        public string requestingStaffName;
        public string tradingStaffTradingEventName;
        public string tradingStaffTradingEventDate;
        public string tradingStaffTradingType;
        public string tradingStaffId;
        public string tradingStaffName;
    }
    
    global virtual class exceptionLog extends modelBase implements Comparable {
        public string exceptionCode;
        public string patientName;
        public skedModels.job job;
        public skedModels.jobAllocation jobAllocation;
        public skedModels.resource resource;
        
        public virtual Integer compareTo(Object compareTo) {
            exceptionLog compareToRecord = (exceptionLog)compareTo;
            Integer returnValue = 0;
            
            if (job.startDate > compareToRecord.job.startDate) {
                returnValue = 1;
            }
            else if (job.startDate < compareToRecord.job.startDate) {
                returnValue = -1;
            }
            else {
                if (job.startTime > compareToRecord.job.startTime) {
                    returnValue = 1;
                }
                else if (job.startTime < compareToRecord.job.startTime) {
                    returnValue = -1;
                }
            }
            return returnValue;
        }
    }
    
    global virtual class expense extends modelBase {
        public string expenseType;
        public string createdDate;
        public resource createdBy;
        public string createdById;
    }
    
    global virtual class eventTypeSetting extends displaySetting {
        public string objectType;
        public boolean canBePreDated;
        public boolean isAvailable;
        public string shortName;
        public integer step;
        public boolean integratedWithWorkday;
    }
    
    global virtual class jobStatusSetting {
        public string jobStatus {get;set;}
        public string backgroundColor {get;set;}
        public string textColor {get;set;}
    }
    
    global virtual class locationAvailability extends event {
        public boolean isAvailable;
        public string serviceLocationId;
        public serviceLocation serviceLocation;
        public string notes;
    }
    
    global virtual class permissionSetAssignmentRule extends modelBase {
        public string id;
        public string name;
        public List<string> permissionSetIds;
        public string profileId;
        public string skeduloUserType;
    }
    
    global virtual class selectOption {
        public string id;
        public string name;
        public boolean selected;
        
        public selectOption(string value, string text) {
            this.id = value;
            this.name = text;
            this.selected = false;
        }
        
        public selectOption(string value, string text, boolean selected) {
            this.id = value;
            this.name = text;
            this.selected = selected;
        }
    }

    global virtual class stagingLocation extends modelBase {
        public address address;
        public transient Location geolocation;
        public staffingBudget staffingBudget;
    }

    global virtual class staffingBudgetAvailability extends modelBase {
        public availability availability;
        public staffingBudget staffingBudget;
        public String availabilityId;
        public String availabilityStatus;
        public String staffingBudgetId;
    }
    
    global virtual class staffingBudget extends event {
        public decimal approvedSlots;
        public decimal availableSlots;
        public string arcRegionName;
        public string biddingEndDate;
        public string biddingStartDate;
        public string biomedCollectionOpId;
        public biomedCollectionOp biomedCollectionOp;
        public string convertToStandardOn;
        public string districtName;
        public List<string> driveTypes;
        public string pendingSlots;
        public string requestType;
        public List<string> roles;
        public string staffingBudgetDate;
        public decimal totalSlots;
        public string uniqueKey;
        public List<staffingBudgetAvailability> staffingBudgetAvailabilities;
        public List<availability> availabilities;
        public List<String> collectionOperationIds;
        public List<String> siteIds;
        public List<staffingBudgetCollectionOp> staffingBudgetCollectionOps;
        public List<staffingBudgetSite> staffingBudgetSites;
    }

    global virtual class staffingBudgetCollectionOp extends modelBase {
        public biomedCollectionOp biomedCollectionOp;
        public staffingBudget staffingBudget;
        public string biomedCollectionOpId;
        public string staffingBudgetId;
    }

    global virtual class staffingBudgetSite extends modelBase {
        public serviceLocation site;
        public staffingBudget staffingBudget;
        public biomedCollectionOp biomedCollectionOp;
        public string siteId;
        public string staffingBudgetId;
        public string biomedCollectionOpId;
        public string biomedCollectionOpName;
    }
    
    global virtual class supportNote extends modelBase {
        public string supportNote;
        public string noteType;
        public string createdDate;
        public resource createdBy;
        public string createdById;
    }
    
    global virtual class supportPlan extends modelBase {
        public string accountId;
    }
    
    global virtual class territory extends modelBase {
        public string endDate;
        public string parentId;
        public string startDate;
        public List<territoryCollectionOperation> territoryCollectionOperations;
    }
    
    global virtual class territoryCollectionOperation extends modelBase {
        public string collectionOperationId;
        public string endDate;
        public string startDate;
        public string territoryId;
    }
}