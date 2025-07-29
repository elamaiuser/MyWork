public class skedMappingConfigContainer {
    
    public static final string CUSTOM_FIELDS_EXTENSION = '__c';
    
    /************************************************************* Singleton stuff *************************************************************/
    private static skedMappingConfigContainer mInstance;
    
    public static skedMappingConfigContainer instance {
        get {
            if (mInstance == null) {
                mInstance = new skedMappingConfigContainer();
            }
            return mInstance;
        }
    }
    
    private skedMappingConfigContainer() {
        this.mapConfig = new Map<string, mappingConfigModel>();
    }
    
    /************************************************************* AutoMapperconfigContainer *************************************************************/
    protected Map<string, mappingConfigModel> mapConfig;
    
    public mappingConfigModel getMappingConfig(string sObjectType) {
        mappingConfigModel mappingConfig;
        if (!this.mapConfig.containsKey(sObjectType)) {
            //TODO: need to remove hard-code on the below code for handling class name
            string className = sObjectType.removeEnd(CUSTOM_FIELDS_EXTENSION);
            className = className.startsWith('skedHC_') ? className.remove('skedHC_') : className;
            className = className.startsWith('sked_') ? className.remove('sked_') : className;
            className = className.endsWith('Model') ? className.remove('Model') : className;
            className = className.remove('_');
            className = 'skedMappingConfigContainer.' + className + 'MappingConfigFactory';
            Type mappingConfigFactoryType = Type.forName(className);
            
            mappingConfigFactory factoryInstance = (mappingConfigFactory)mappingConfigFactoryType.newInstance();
            mappingConfig = factoryInstance.process();
            this.mapConfig.put(sObjectType, mappingConfig);
        }
        else {
            mappingConfig = this.mapConfig.get(sObjectType);
        }
        return mappingConfig;
    }
    
    /************************************************************* Nested class *************************************************************/
    public class mappingConfigModel {
        public string sObjectName;
        public string objectType;
        public List<fieldConfigModel> fieldConfigs;
        public Set<string> readonlyFields;
        public Set<string> masterDetailFields;
        
        public mappingConfigModel() {
            this.fieldConfigs = new List<fieldConfigModel>();
        }
        
        public fieldConfigModel addFieldConfig(string sObjectFieldPath, string domainFieldName, string mappingType) {
            fieldConfigModel fieldConfig = new fieldConfigModel();
            fieldConfig.sObjectFieldPath = sObjectFieldPath;
            fieldConfig.sObjectFieldPaths = sObjectFieldPath.split('\\.');
            fieldConfig.domainFieldName = domainFieldName;
            fieldConfig.mappingType = mappingType;
            this.fieldConfigs.add(fieldConfig);
            return fieldConfig;
        }
        
        public fieldConfigModel addFieldConfig(string sObjectFieldPath, string domainFieldName, string mappingType, Type relatedObjectDomainType, string relatedSObjectName) {
            fieldConfigModel fieldConfig = new fieldConfigModel();
            fieldConfig.sObjectFieldPath = sObjectFieldPath;
            fieldConfig.sObjectFieldPaths = sObjectFieldPath.split('\\.');
            fieldConfig.domainFieldName = domainFieldName;
            fieldConfig.mappingType = mappingType;
            fieldConfig.relatedObjectDomainType = relatedObjectDomainType;
            fieldConfig.relatedSObjectName = relatedSObjectName;
            this.fieldConfigs.add(fieldConfig);
            return fieldConfig;
        }
        
        public fieldConfigModel addFieldConfig(string sObjectFieldPath, string domainFieldName, string mappingType, string relatedListSObjectName) {
            fieldConfigModel fieldConfig = new fieldConfigModel();
            fieldConfig.sObjectFieldPath = sObjectFieldPath;
            fieldConfig.sObjectFieldPaths = sObjectFieldPath.split('\\.');
            fieldConfig.domainFieldName = domainFieldName;
            fieldConfig.mappingType = mappingType;
            fieldConfig.relatedListSObjectName = relatedListSObjectName;
            this.fieldConfigs.add(fieldConfig);
            return fieldConfig;
        }
    }
    
    public class fieldConfigModel {
        public string sObjectFieldPath;
        public List<string> sObjectFieldPaths;
        public string domainFieldName;
        public string mappingType;
        public Type relatedObjectDomainType;
        public string relatedSObjectName;
        public string relatedListSObjectName;
    }
    
    /************************************************************* Mapping Config Factory *************************************************************/
    public virtual class mappingConfigFactory {
        public virtual mappingConfigModel process() {
            return null;
        }
    }
    
    public class accountMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'Account';
            mappingConfig.objectType = 'account';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('Phone', 'phone', 'direct');
            
            mappingConfig.addFieldConfig('sked_Client_Availabilities__r', 'clientAvailabilities', 'relatedList', 'sked__Client_Availability__c');
            mappingConfig.addFieldConfig('sked__Jobs__r', 'jobs', 'relatedList', 'sked__Job__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class activityMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Activity__c';
            mappingConfig.objectType = 'activity';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('sked__Address__c', 'address', 'fullAddress');
            mappingConfig.addFieldConfig('sked__End__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
            mappingConfig.addFieldConfig('sked__Notes__c', 'notes', 'direct');
            mappingConfig.addFieldConfig('sked__Quantity__c', 'quantity', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked__Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked__Type__c', 'eventType', 'direct');
            mappingConfig.addFieldConfig('sked_Activity_Resource_Count__c', 'activityResourceCount', 'direct');
            mappingConfig.addFieldConfig('sked_Activity_Title__c', 'activityTitle', 'direct');
            mappingConfig.addFieldConfig('sked_District__c', 'districtId', 'direct');
            mappingConfig.addFieldConfig('sked_Drive__c', 'driveId', 'direct');
            mappingConfig.addFieldConfig('sked_Drive__r', 'drive', 'related', skedModels.drive.class, 'sked_Drive__c');
            mappingConfig.addFieldConfig('sked_Linked_Drives__c', 'linkedDrivesId', 'direct');
            mappingConfig.addFieldConfig('sked_Linked_Drives__r', 'linkedDrives', 'related', skedModels.linkedDrives.class, 'sked_Linked_Drives__c');
            mappingConfig.addFieldConfig('sked_Fixed_Site_Staff_Quantity__c', 'fixedSiteStaffQuantity', 'direct');
            mappingConfig.addFieldConfig('sked_Is_All_Day__c', 'isAllDay', 'direct');
            mappingConfig.addFieldConfig('sked_Is_Group_Activity__c', 'isGroupActivity', 'direct');
            mappingConfig.addFieldConfig('sked_Inherit_Resources_From_Drive__c', 'inheritResourcesFromDrive', 'direct');
            mappingConfig.addFieldConfig('sked_Mobile_Staff_Quantity__c', 'mobileStaffQuantity', 'direct');
            mappingConfig.addFieldConfig('sked_Recurring_Schedule__c', 'scheduleId', 'direct');
            mappingConfig.addFieldConfig('sked_Recurring_Schedule__r.sked__Description__c', 'scheduleDescription', 'direct');
            mappingConfig.addFieldConfig('sked_Reduce_From_Staffing_Constraint__c', 'reduceFromStaffingConstraint', 'direct');
            mappingConfig.addFieldConfig('sked_Region__c', 'regionId', 'direct');
            mappingConfig.addFieldConfig('sked_Region__r.sked_Biomed_Collection_Op_Center__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_Resource_Override__c', 'resourceOverrideId', 'direct');
            mappingConfig.addFieldConfig('sked_Show_On_Calendar__c', 'showOnCalendar', 'direct');
            mappingConfig.addFieldConfig('sked_Drive_Types__c', 'driveTypes', 'multiPicklist');
            mappingConfig.addFieldConfig('sked_Subtype__c', 'subtype', 'direct');
            mappingConfig.addFieldConfig('sked_Territory_Key__c', 'territoryKey', 'direct');
            mappingConfig.addFieldConfig('sked_ARC_Region__c', 'arcRegionId', 'direct');
            mappingConfig.addFieldConfig('sked_ARC_Region__r', 'arcRegion', 'related', skedModels.territory.class, 'sked_Territory__c');
            mappingConfig.addFieldConfig('activity', 'objectType', 'value');
            
            
            mappingConfig.addFieldConfig('sked__Activity_Resources__r', 'activityResources', 'relatedList', 'sked__Activity_Resource__c');
            mappingConfig.addFieldConfig('sked_Activity_Collection_Operations__r', 'activityCollectionOperations', 'relatedList', 'sked_Activity_Collection_Operation__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked__Resource__c');
            return mappingConfig;
        }
    }
    
    public class activityResourceMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Activity_Resource__c';
            mappingConfig.objectType = 'activityResource';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Activity__c', 'activityId', 'direct');
            mappingConfig.addFieldConfig('sked__Activity__r', 'activity', 'related', skedModels.activity.class, 'sked__Activity__c');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r', 'resource', 'related', skedModels.resource.class, 'sked__Resource__c');
            mappingConfig.addFieldConfig('sked_End__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked_Start1__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', 'direct');

            mappingConfig.addFieldConfig('sked_Drive_Shift_Trade__r', 'driveShiftTrade', 'related', skedModels.driveShiftTrade.class, 'sked_Drive_Shift_Trade__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.readonlyFields.add('sked_Timezone__c');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked__Activity__c');
            mappingConfig.masterDetailFields.add('sked__Resource__c');
            return mappingConfig;
        }
    }

    public class activityCollectionOperationMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Activity_Collection_Operation__c';
            mappingConfig.objectType = 'activityCollectionOperation';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Activity__c', 'activityId', 'direct');
            mappingConfig.addFieldConfig('sked_Activity__r', 'activity', 'related', skedModels.activity.class, 'sked__Activity__c');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Operation__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Operation__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'Biomed_Collection_Op_Center__c');
            mappingConfig.addFieldConfig('sked_District__c', 'districtId', 'direct');
            mappingConfig.addFieldConfig('sked_Territory_Key__c', 'territoryKey', 'direct');

            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.readonlyFields.add('sked_Territory_Key__c');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked_Activity__c');
            mappingConfig.masterDetailFields.add('sked_Biomed_Collection_Operation__c');
            return mappingConfig;
        }
    }
    
    public class availabilityMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Availability__c';
            mappingConfig.objectType = 'availability';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('sked_Last_Modified_By__c', 'lastModifiedById', 'direct');
            mappingConfig.addFieldConfig('sked_Last_Modified_By__r', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('sked__Finish__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked__Is_Available__c', 'isAvailable', 'direct');
            mappingConfig.addFieldConfig('sked__Notes__c', 'notes', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r.Name', 'resource.name', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r.sked_Roles__c', 'resource.roles', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r.sked_Seniority_Date__c', 'resource.seniorityDate', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r', 'resource', 'related', skedModels.resource.class, 'sked__Resource__c');
            mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked__Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked__Type__c', 'eventType', 'direct');
            mappingConfig.addFieldConfig('sked_Approval_Reason__c', 'approvalReason', 'direct');
            mappingConfig.addFieldConfig('sked_Bypass_Auto_Approval_Process__c', 'bypassAutoApprovalProcess', 'direct');
            mappingConfig.addFieldConfig('sked_Waitlist_Confirmed__c', 'waitlistConfirmed', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_for_Activity__c', 'callOutForActivityId', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_for_Activity__r', 'callOutForActivity', 'related', skedModels.activity.class, 'sked__Activity__c');
            mappingConfig.addFieldConfig('sked_Call_Out_For_Drive__c', 'callOutForDriveId', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_For_Drive__r', 'callOutForDrive', 'related', skedModels.drive.class, 'sked_Drive__c');
            mappingConfig.addFieldConfig('sked_Call_Out_Notes__c', 'callOutNotes', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_Reason_Code__c', 'callOutReason', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_Type__c', 'callOutType', 'direct');
            mappingConfig.addFieldConfig('sked_DateTime_Call_Out_Received__c', 'callOutReceived', 'datetime');
            mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked_Custom_Status__c', 'status', 'direct');
            mappingConfig.addFieldConfig('sked_Decline_Reason__c', 'declineReason', 'direct');
            mappingConfig.addFieldConfig('sked_Exception_Code__c', 'exceptionCode', 'direct');
            mappingConfig.addFieldConfig('sked_Integrate_With_Workday__c', 'integrateWithWorkday', 'direct');
            mappingConfig.addFieldConfig('sked_Is_All_Day__c', 'isAllDay', 'direct');
            mappingConfig.addFieldConfig('sked_Is_Exception__c', 'isException', 'direct');
            mappingConfig.addFieldConfig('sked_Other_Decline_Reason__c', 'otherDeclineReason', 'direct');
            mappingConfig.addFieldConfig('sked_Ranking__c', 'ranking', 'direct');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__r.sked_Request_Type__c', 'requestType', 'direct');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__r', 'staffingBudget', 'related', skedModels.staffingBudget.class, 'sked_Staffing_Budget__c');
            mappingConfig.addFieldConfig('sked_Recurring_Schedule__c', 'scheduleId', 'direct');
            mappingConfig.addFieldConfig('sked_Recurring_Schedule__r.sked__Description__c', 'scheduleDescription', 'direct');
            mappingConfig.addFieldConfig('sked_Approved_Via_Automation__c', 'approvedViaAutomation', 'direct');
            mappingConfig.addFieldConfig('sked_Bidding_Type__c', 'biddingType', 'direct');
            mappingConfig.addFieldConfig('sked_Time_Off_Reason_Code__c', 'timeOffReasonCode', 'direct');
            mappingConfig.addFieldConfig('sked_Workday_Sync_Message__c', 'workdaySyncMessage', 'direct');
            mappingConfig.addFieldConfig('sked_Workday_Sync_Status__c', 'workdaySyncStatus', 'direct');
            mappingConfig.addFieldConfig('availability', 'objectType', 'value');
            
            mappingConfig.addFieldConfig('skedHC__Exception_Log__r', 'exceptionLogs', 'relatedList', 'skedHC__Exception__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget_Availabilities__r', 'staffingBudgetAvailabilities', 'relatedList', 'sked_Staffing_Budget_Availability__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.readonlyFields.add('sked_Is_Exception__c');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked__Resource__c');
            return mappingConfig;
        }
    }
    
    public class availabilityPatternMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Availability_Pattern__c';
            mappingConfig.objectType = 'availabilityPattern';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('sked__Description__c', 'description', 'direct');
            mappingConfig.addFieldConfig('sked__Hash__c', 'hash', 'direct');
            mappingConfig.addFieldConfig('sked__Pattern__c', 'pattern', 'direct');
            mappingConfig.addFieldConfig('sked_Validate_2CDO_Rule__c', 'validate2CDORule', 'direct');
            
			mappingConfig.addFieldConfig('sked__Availability_Pattern_Resources__r', 'availabilityPatternResources', 'relatedList', 'sked__Availability_Pattern_Resource__c');
            
            return mappingConfig;
        }
    }
    
    public class availabilityPatternResourceMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Availability_Pattern_Resource__c';
            mappingConfig.objectType = 'availabilityPatternResource';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Availability_Pattern__c', 'availabilityPatternId', 'direct');
            mappingConfig.addFieldConfig('sked__Availability_Pattern__r', 'availabilityPattern', 'related', skedModels.availabilityPattern.class, 'sked__Availability_Pattern__c');
            mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r.Name', 'resource.name', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r', 'resource', 'related', skedModels.resource.class, 'sked__Resource__c');
            mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', 'direct');
            mappingConfig.addFieldConfig('sked__Status__c', 'status', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked__Availability_Pattern__c');
            mappingConfig.masterDetailFields.add('sked__Resource__c');
            
            return mappingConfig;
        }
    }
    
    public class availabilityTemplateMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Availability_Template__c';
            mappingConfig.objectType = 'availabilityTemplate';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('sked__Finish__c', 'endDate', 'date');
            mappingConfig.addFieldConfig('sked__Start__c', 'startDate', 'date');
            
            mappingConfig.addFieldConfig('sked__Availability_Template_Entries__r', 'availabilityTemplateEntries', 'relatedList', 'sked__Availability_Template_Entry__c');
            mappingConfig.addFieldConfig('sked__Availability_Template_Resources__r', 'availabilityTemplateResources', 'relatedList', 'sked__Availability_Template_Resource__c');
            
            return mappingConfig;
        }
    }
    
    public class availabilityTemplateEntryMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Availability_Template_Entry__c';
            mappingConfig.objectType = 'availabilityTemplateEntry';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Availability_Template__c', 'availabilityTemplateId', 'direct');
            mappingConfig.addFieldConfig('sked__Finish_Time__c', 'endTime', 'direct');
            mappingConfig.addFieldConfig('sked__Start_Time__c', 'startTime', 'direct');
            mappingConfig.addFieldConfig('sked__Weekday__c', 'weekday', 'direct');
            mappingConfig.addFieldConfig('sked_Is_All_Day__c', 'isAllDay', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked__Availability_Template__c');
            return mappingConfig;
        }
    }
    
    public class availabilityTemplateResourceMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Availability_Template_Resource__c';
            mappingConfig.objectType = 'availabilityTemplateResource';
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Availability_Template__c', 'availabilityTemplateId', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r.Id', 'resource.id', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r.Name', 'resource.name', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r.sked__User__r.SmallPhotoUrl', 'resource.photoUrl', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__r', 'resource', 'related', skedModels.resource.class, 'sked__Resource__c');
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked__Availability_Template__c');
            mappingConfig.masterDetailFields.add('sked__Resource__c');
            return mappingConfig;
        }
    }
    
    public class biomedCollectionOpCenterMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'Biomed_Collection_Op_Center__c';
            mappingConfig.objectType = 'biomedCollectionOp';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('Staging_Location_Address__c', 'stagingLocation', 'fullAddress');
            mappingConfig.addFieldConfig('Staging_Location_Geolocation__c', 'stagingLocation', 'addressLocation');
            mappingConfig.addFieldConfig('sked_Regions__r', 'regions', 'relatedList', 'sked__Region__c');
            mappingConfig.addFieldConfig('sked_Waitlist_Enabled__c', 'waitlistEnabled', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class caseMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'Case';
            mappingConfig.objectType = 'caseModel';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('AccountId', 'accountId', 'direct');
            mappingConfig.addFieldConfig('CaseNumber', 'name', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class clientAvailabilityMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Client_Availability__c';
            mappingConfig.objectType = 'clientAvailability';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Account__c', 'patientId', 'direct');
            mappingConfig.addFieldConfig('sked__End__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked__Is_Available__c', 'isAvailable', 'direct');
            mappingConfig.addFieldConfig('sked__Preferred_Start__c', 'preferredStart', 'datetime');
            mappingConfig.addFieldConfig('sked__Preferred_End__c', 'preferredEnd', 'datetime');
            mappingConfig.addFieldConfig('sked__Recurring_Schedule__c', 'scheduleId', 'direct');
            mappingConfig.addFieldConfig('sked__Recurring_Schedule__r.sked__Description__c', 'scheduleDescription', 'direct');
            mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked_Is_All_Time_Preferred__c', 'isAllTimePreferred', 'direct');
            mappingConfig.addFieldConfig('sked_Notes__c', 'notes', 'direct');
            mappingConfig.addFieldConfig('sked_Service_Location__c', 'serviceLocationId', 'direct');
            mappingConfig.addFieldConfig('clientAvailability', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class contactMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'Contact';
            mappingConfig.objectType = 'contact';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('AccountId', 'accountId', 'direct');
            mappingConfig.addFieldConfig('Birthdate', 'birthdate', 'direct');
            mappingConfig.addFieldConfig('Email', 'email', 'direct');
            mappingConfig.addFieldConfig('FirstName', 'firstName', 'direct');
            mappingConfig.addFieldConfig('LastName', 'lastName', 'direct');
            mappingConfig.addFieldConfig('Phone', 'phone', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }

    public class customAvailabilityMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Custom_Availability__c';
            mappingConfig.objectType = 'customAvailability';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('sked_Finish__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked_Is_Available__c', 'isAvailable', 'direct');
            mappingConfig.addFieldConfig('sked_Notes__c', 'notes', 'direct');
            mappingConfig.addFieldConfig('sked_Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked_Resource__r.Name', 'resource.name', 'direct');
            mappingConfig.addFieldConfig('sked_Resource__r.sked_Roles__c', 'resource.roles', 'direct');
            mappingConfig.addFieldConfig('sked_Resource__r.sked_Seniority_Date__c', 'resource.seniorityDate', 'direct');
            mappingConfig.addFieldConfig('sked_Resource__r', 'resource', 'related', skedModels.resource.class, 'sked__Resource__c');
            mappingConfig.addFieldConfig('sked_Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked_Type__c', 'eventType', 'direct');
            mappingConfig.addFieldConfig('sked_Status__c', 'status', 'direct');
            mappingConfig.addFieldConfig('sked_Is_All_Day__c', 'isAllDay', 'direct');
            mappingConfig.addFieldConfig('customAvailability', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }

    public class driveMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Drive__c';
            mappingConfig.objectType = 'drive';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', 'direct');
            mappingConfig.addFieldConfig('sked_Drive_Date__c', 'driveDate', 'direct');
            mappingConfig.addFieldConfig('sked_UFID__c', 'UFID', 'direct');
            mappingConfig.addFieldConfig('sked_District__c', 'territoryId', 'direct');
            mappingConfig.addFieldConfig('sked_District__r', 'territory', 'related', skedModels.territory.class, 'sked_Territory__c');

            return mappingConfig;
        }
    }

    public class driveShiftTradeMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Drive_Shift_Trade__c';
            mappingConfig.objectType = 'driveShiftTrade';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('sked_APS_Notes__c', 'apsNotes', 'direct');
            mappingConfig.addFieldConfig('sked_Requesting_Staff_Trading_Event_Name__c', 'requestingStaffTradingEventName', 'direct');
            mappingConfig.addFieldConfig('sked_Requesting_Staff_Trading_Event_Date__c', 'requestingStaffTradingEventDate', 'direct');
            mappingConfig.addFieldConfig('sked_Requesting_Staff_Trading_Type__c', 'requestingStaffTradingType', 'direct');
            mappingConfig.addFieldConfig('sked_Requesting_Staff__c', 'requestingStaffId', 'direct');
            mappingConfig.addFieldConfig('sked_Requesting_Staff__r.Name', 'requestingStaffName', 'direct');
            mappingConfig.addFieldConfig('sked_Trading_Staff_Trading_Event_Name__c', 'tradingStaffTradingEventName', 'direct');
            mappingConfig.addFieldConfig('sked_Trading_Staff_Trading_Event_Date__c', 'tradingStaffTradingEventDate', 'direct');
            mappingConfig.addFieldConfig('sked_Trading_Staff_Trading_Type__c', 'tradingStaffTradingType', 'direct');
            mappingConfig.addFieldConfig('sked_Trading_Staff__c', 'tradingStaffId', 'direct');
            mappingConfig.addFieldConfig('sked_Trading_Staff__r.Name', 'tradingStaffName', 'direct');

            return mappingConfig;
        }
    }
    
    public class exceptionMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'skedHC__Exception__c';
            mappingConfig.objectType = 'exceptionLog';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('skedHC__Exception__c', 'exceptionCode', 'direct');
            mappingConfig.addFieldConfig('skedHC__Job__r.sked__Account__r.Name', 'job.account.name', 'direct');
            mappingConfig.addFieldConfig('skedHC__Job__r.Name', 'job.name', 'direct');
            mappingConfig.addFieldConfig('skedHC__Job__r', 'job', 'related', skedModels.job.class, 'sked__Job__c');
            mappingConfig.addFieldConfig('skedHC__Job_Allocation__r', 'jobAllocation', 'related', skedModels.jobAllocation.class, 'sked__Job_Allocation__c');
            mappingConfig.addFieldConfig('skedHC__Resource__r', 'resource', 'related', skedModels.resource.class, 'sked__Resource__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.readonlyFields.add('CreatedDate');
            return mappingConfig;
        }
    }
    
    public class holidayMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Holiday__c';
            mappingConfig.objectType = 'holiday';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__End_Date__c', 'endDate', 'direct');
            mappingConfig.addFieldConfig('sked__Global__c', 'isGlobal', 'direct');
            mappingConfig.addFieldConfig('sked__Start_Date__c', 'startDate', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class holidayRegionMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Holiday_Region__c';
            mappingConfig.objectType = 'holidayRegion';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('sked__Holiday__r.Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Holiday__r.sked__End_Date__c', 'endDate', 'direct');
            mappingConfig.addFieldConfig('sked__Holiday__r.sked__Global__c', 'isGlobal', 'direct');
            mappingConfig.addFieldConfig('sked__Holiday__r.sked__Start_Date__c', 'startDate', 'direct');
            mappingConfig.addFieldConfig('sked__Region__c', 'regionId', 'direct');
            mappingConfig.addFieldConfig('sked__Region__r.sked_Biomed_Collection_Op_Center__c', 'biomedCollectionOpId', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class jobMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Job__c';
            mappingConfig.objectType = 'job';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Account__c', 'accountId', 'direct');
            mappingConfig.addFieldConfig('sked__Account__r', 'account', 'related', skedModels.account.class, 'Account');
            mappingConfig.addFieldConfig('sked__Address__c', 'address', 'fullAddress');
            mappingConfig.addFieldConfig('sked__Contact__c', 'contactId', 'direct');
            mappingConfig.addFieldConfig('sked__Contact__r', 'contact', 'related', skedModels.contact.class, 'Contact');
            mappingConfig.addFieldConfig('sked__Description__c', 'description', 'direct');
            mappingConfig.addFieldConfig('sked__Duration__c', 'duration', 'direct');
            mappingConfig.addFieldConfig('sked__Finish__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked__Job_Allocation_Count__c', 'jobAllocationCount', 'direct');
            mappingConfig.addFieldConfig('sked__Job_Status__c', 'jobStatus', 'direct');
            mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
            mappingConfig.addFieldConfig('sked__Location__c', 'serviceLocationId', 'direct');
            mappingConfig.addFieldConfig('sked__Notes_Comments__c', 'notes', 'direct');
            mappingConfig.addFieldConfig('sked__Quantity__c', 'quantity', 'direct');
            mappingConfig.addFieldConfig('sked__Recurring_Schedule__c', 'scheduleId', 'direct');
            mappingConfig.addFieldConfig('sked__Recurring_Schedule__r.sked__Description__c', 'scheduleDescription', 'direct');
            mappingConfig.addFieldConfig('sked__Region__c', 'regionId', 'direct');
            mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked__Type__c', 'eventType', 'direct');
            mappingConfig.addFieldConfig('sked_Cancellation_Reason__c', 'cancellationReason', 'direct');
            mappingConfig.addFieldConfig('sked_Cancellation_Reason_Notes__c', 'cancellationReasonNotes', 'direct');
            mappingConfig.addFieldConfig('sked_Drive__r.Name', 'driveName', 'direct');
            mappingConfig.addFieldConfig('sked_Drive__r.sked_Total_Products_Projected__c', 'totalProductsProjected', 'direct');
            mappingConfig.addFieldConfig('sked_Drive__r.sked_UFID__c', 'driveUFID', 'direct');
            
            mappingConfig.addFieldConfig('sked__Job_Allocations__r', 'jobAllocations', 'relatedList', 'sked__Job_Allocation__c');
            mappingConfig.addFieldConfig('sked__JobTags__r', 'jobTags', 'relatedList', 'sked__Job_Tag__c');
            
            mappingConfig.addFieldConfig('job', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.readonlyFields.add('sked__Job_Allocation_Count__c');
            
            return mappingConfig;
        }
    }
    
    public class jobAllocationMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Job_Allocation__c';
            mappingConfig.objectType = 'jobAllocation';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Set_End__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked__Job__r', 'job', 'related', skedModels.job.class, 'sked__Job__c');
            mappingConfig.addFieldConfig('sked__Resource__r', 'resource', 'related', skedModels.resource.class, 'sked__Resource__c');
            mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked__Status__c', 'status', 'direct');
            mappingConfig.addFieldConfig('sked_Is_Handled_Exception_from_Client__c', 'isHandledExceptionFromClient', 'direct');
            mappingConfig.addFieldConfig('sked_Additional_Roles__c', 'additionalRoles', 'multiPicklist');
            mappingConfig.addFieldConfig('sked_Call_Out_Notes__c', 'calloutNotes', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_Reason_Code__c', 'calloutReasonCode', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_Reported__c', 'calloutReported', 'direct');
            mappingConfig.addFieldConfig('sked_Call_Out_Type__c', 'calloutType', 'direct');
            mappingConfig.addFieldConfig('sked_DateTime_Call_Out_Received__c', 'callOutReceived', 'datetime');
            mappingConfig.addFieldConfig('sked_Guarded__c', 'guarded', 'direct');
            mappingConfig.addFieldConfig('jobAllocation', 'objectType', 'value');

            mappingConfig.addFieldConfig('sked_Drive_Shift_Trade__r', 'driveShiftTrade', 'related', skedModels.driveShiftTrade.class, 'sked_Drive_Shift_Trade__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class jobTagMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Job_Tag__c';
            mappingConfig.objectType = 'jobTag';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Job__c', 'jobId', 'direct');
            mappingConfig.addFieldConfig('sked__Tag__c', 'tagId', 'direct');
            mappingConfig.addFieldConfig('sked__Tag__r', 'tag', 'related', skedModels.tag.class, 'sked__Tag__c');
            mappingConfig.addFieldConfig('jobTag', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }

    public class linkedDrivesMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Linked_Drives__c';
            mappingConfig.objectType = 'linkedDrives';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Linked_Drive_Type__c', 'linkedDriveType', 'direct');
            
            return mappingConfig;
        }
    }
    
    public class locationMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Location__c';
            mappingConfig.objectType = 'serviceLocation';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked__Account__c', 'accountId', 'direct');
            mappingConfig.addFieldConfig('sked__Address__c', 'address', 'fullAddress');
            mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
            mappingConfig.addFieldConfig('sked__Region__c', 'regionId', 'direct');
            mappingConfig.addFieldConfig('sked__Region__r', 'region', 'related', skedModels.region.class, 'sked__Region__c');
            mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_Collection_Operation_Name__c', 'biomedCollectionOpName', 'direct');
            mappingConfig.addFieldConfig('sked_Collection_Operation__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'Biomed_Collection_Op_Center__c');
            mappingConfig.addFieldConfig('sked__Jobs__r', 'jobs', 'relatedList', 'sked__Job__c');
            mappingConfig.addFieldConfig('sked_Location_Availabilities__r', 'locationAvailabilities', 'relatedList', 'sked_Location_Availability__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.readonlyFields.add('sked_Collection_Operation_Name__c');
            return mappingConfig;
        }
    }
    
    public class locationAvailabilityMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Location_Availability__c';
            mappingConfig.objectType = 'locationAvailability';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('sked_Finish__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked_Is_All_Day__c', 'isAllDay', 'direct');
            mappingConfig.addFieldConfig('sked_Is_Available__c', 'isAvailable', 'direct');
            mappingConfig.addFieldConfig('sked_Location__c', 'serviceLocationId', 'direct');
            mappingConfig.addFieldConfig('sked_Notes__c', 'notes', 'direct');
            mappingConfig.addFieldConfig('sked_Recurring_Schedule__c', 'scheduleId', 'direct');
            mappingConfig.addFieldConfig('sked_Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked_Type__c', 'eventType', 'direct');
            mappingConfig.addFieldConfig('locationAvailability', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked_Location__c');
            return mappingConfig;
        }
    }

    public class locationResourceScoreMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Location_Resource_Score__c';
            mappingConfig.objectType = 'locationResourceScore';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Location__c', 'locationId', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked_Location_Resource_Relationship__c', 'locationResourceRelationship', 'direct');
            mappingConfig.addFieldConfig('sked__Location__r.RecordType.Name', 'locationType', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            return mappingConfig;
        }
    }
    
    public class recurringScheduleMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Recurring_Schedule__c';
            mappingConfig.objectType = 'recurringSchedule';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Description__c', 'description', 'direct');
            mappingConfig.addFieldConfig('sked_Skip_Holidays__c', 'skipHolidays', 'direct');
            
            mappingConfig.addFieldConfig('sked_Activities__r', 'activities', 'relatedList', 'sked__Activity__c');
            mappingConfig.addFieldConfig('sked_Availabilities__r', 'availabilities', 'relatedList', 'sked__Availability__c');
            mappingConfig.addFieldConfig('sked__Jobs__r', 'jobs', 'relatedList', 'sked__Job__c');
            mappingConfig.addFieldConfig('sked_Client_Availabilities__r', 'clientAvailabilities', 'relatedList', 'sked__Client_Availability__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            return mappingConfig;
        }
    }
    
    public class regionMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Region__c';
            mappingConfig.objectType = 'region';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__c', 'collectionOperationId', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__r.Name', 'collectionOperationName', 'direct');
            mappingConfig.addFieldConfig('sked_Territory__c', 'territoryId', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class resourceMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Resource__c';
            mappingConfig.objectType = 'resource';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Asset_Type__c', 'assetType', 'direct');
            mappingConfig.addFieldConfig('sked__Category__c', 'category', 'direct');
            mappingConfig.addFieldConfig('sked__Email__c', 'email', 'direct');
            mappingConfig.addFieldConfig('sked__Employment_Type__c', 'employmentType', 'direct');
            mappingConfig.addFieldConfig('sked__Mobile_Phone__c', 'mobilePhone', 'direct');
            mappingConfig.addFieldConfig('sked__Primary_Region__c', 'regionId', 'direct');
            mappingConfig.addFieldConfig('sked__Primary_Region__r.sked__Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Restricts_to_Full_day_PTO__c', 'restrictsToFullDayPto', 'direct');
            mappingConfig.addFieldConfig('sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c', 'workWeekFirstDay', 'direct');
            mappingConfig.addFieldConfig('sked__Primary_Region__r.Name', 'regionName', 'direct');
            mappingConfig.addFieldConfig('sked__Resource_Type__c', 'resourceType', 'direct');
            mappingConfig.addFieldConfig('sked__User__c', 'userId', 'direct');
            mappingConfig.addFieldConfig('sked__User__r.SmallPhotoUrl', 'photoUrl', 'direct');
            mappingConfig.addFieldConfig('sked__User__r.sked__skeduloUserType__c', 'userType', 'direct');
            mappingConfig.addFieldConfig('sked__Home_Address__c', 'address', 'fullAddress');
            mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
            mappingConfig.addFieldConfig('sked_Anticipated_Leave_Return_Date__c', 'anticipatedLeaveReturnDate', 'date');
            mappingConfig.addFieldConfig('sked_ARC_Region_Name__c', 'arcRegionName', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center_Name__c', 'biomedCollectionOpName', 'direct');
            mappingConfig.addFieldConfig('sked_Daily_Time_Off_Hours__c', 'dailyTimeOffHours', 'direct');
            mappingConfig.addFieldConfig('sked_District_Name__c', 'districtName', 'direct'); 
            mappingConfig.addFieldConfig('sked_Effective_Date__c', 'effectiveDate', 'direct'); 
            mappingConfig.addFieldConfig('sked_Employment_Status__c', 'employmentStatus', 'direct'); 
            mappingConfig.addFieldConfig('sked_Pres_Donor_Capacity__c', 'presDonorCapacity', 'direct');
            mappingConfig.addFieldConfig('sked_Quantity__c', 'quantity', 'direct');
            mappingConfig.addFieldConfig('sked_Roles__c', 'roles', 'direct');
            mappingConfig.addFieldConfig('sked_Planned_Termination_Date__c', 'plannedTerminationDate', 'date');
            mappingConfig.addFieldConfig('sked_Seniority_Date__c', 'seniorityDate', 'date');
            mappingConfig.addFieldConfig('sked_Termination_Date__c', 'terminationDate', 'date');
            mappingConfig.addFieldConfig('sked_Manual_Ranking_Priority__c', 'manualRankingPriority', 'direct');
            
            mappingConfig.addFieldConfig('sked__Job_Allocations__r', 'jobAllocations', 'relatedList', 'sked__Job_Allocation__c');
            mappingConfig.addFieldConfig('sked__Availabilities1__r', 'availabilities', 'relatedList', 'sked__Availability__c');
            mappingConfig.addFieldConfig('sked__Activities__r', 'activities', 'relatedList', 'sked__Activity__c');
            mappingConfig.addFieldConfig('sked_Custom_Availabilities__r', 'customAvailabilities', 'relatedList', 'sked_Custom_Availability__c');
            mappingConfig.addFieldConfig('sked__ResourceTags__r', 'resourceTags', 'relatedList', 'sked__Resource_Tag__c');
            mappingConfig.addFieldConfig('sked_Resource_Biomed_Collection_Ops__r', 'resourceBiomedCollectionOps', 'relatedList', 'sked_Resource_Biomed_Collection_Op__c');
            mappingConfig.addFieldConfig('sked__Resource_Overrides__r', 'resourceOverrides', 'relatedList', 'sked__Resource_Override__c');
            mappingConfig.addFieldConfig('sked__Resource_Regions__r', 'resourceRegions', 'relatedList', 'sked__Resource_Region__c');
            mappingConfig.addFieldConfig('sked__Activity_Resources__r', 'activityResources', 'relatedList', 'sked__Activity_Resource__c');
            mappingConfig.addFieldConfig('sked__Availability_Template_Resources__r', 'availabilityTemplateResources', 'relatedList', 'sked__Availability_Template_Resource__c');
            mappingConfig.addFieldConfig('sked__Availability_Pattern_Resources__r', 'availabilityPatternResources', 'relatedList', 'sked__Availability_Pattern_Resource__c');
            mappingConfig.addFieldConfig('sked__Location_Resource_Scores__r', 'locationResourceScores', 'relatedList', 'sked__Location_Resource_Score__c');

            mappingConfig.readonlyFields = new Set<string>();
            return mappingConfig;
        }
    }
    
    public class resourceBiomedCollectionOpMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Resource_Biomed_Collection_Op__c';
            mappingConfig.objectType = 'resourceBiomedCollectionOp';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__c ', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', 'date');
            mappingConfig.addFieldConfig('sked_Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', 'date');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'Biomed_Collection_Op_Center__c');
            mappingConfig.addFieldConfig('resourceBiomedCollectionOp', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class resourceJobOfferMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Resource_Job_Offer__c';
            mappingConfig.objectType = 'resourceJobOffer';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Job_Offer__r.sked__Job__c', 'jobId', 'direct');
            mappingConfig.addFieldConfig('sked__Job_Offer__r.sked__Job__r.sked__Start__c', 'jobStart', 'datetime');
            mappingConfig.addFieldConfig('sked__Job_Offer__r.sked__Job__r.sked__Finish__c', 'jobEnd', 'datetime');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Status__c', 'status', 'direct');
            mappingConfig.addFieldConfig('resourceJobOffer', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }
    
    public class resourceOverrideMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Resource_Override__c';
            mappingConfig.objectType = 'resourceOverride';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');
            mappingConfig.addFieldConfig('sked__Description__c', 'description', 'direct');
            mappingConfig.addFieldConfig('sked__End__c', 'end', 'datetime');
            mappingConfig.addFieldConfig('sked__GeoLocation__c', 'address', 'addressLocation');
            mappingConfig.addFieldConfig('sked__Home_Address__c', 'address', 'fullAddress');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_District__c', 'districtId', 'direct');
            mappingConfig.addFieldConfig('sked_Is_Travel_Required__c', 'isTravelRequired', 'direct');
            mappingConfig.addFieldConfig('sked_Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked_Travel_To_Start__c', 'travelToStart', 'datetime');
            mappingConfig.addFieldConfig('sked_Travel_To_End__c', 'travelToEnd', 'datetime');
            mappingConfig.addFieldConfig('sked_Travel_Back_Start__c', 'travelBackStart', 'datetime');
            mappingConfig.addFieldConfig('sked_Travel_Back_End__c', 'travelBackEnd', 'datetime');
            mappingConfig.addFieldConfig('sked_Collection_Operation__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'Biomed_Collection_Op_Center__c');
            mappingConfig.addFieldConfig('resourceOverride', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked__Resource__c');
            return mappingConfig;
        }
    }
    
    public class resourceRegionMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Resource_Region__c';
            mappingConfig.objectType = 'resourceRegion';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Region__c', 'regionId', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            
            return mappingConfig;
        }
    }
    
    public class resourceTagMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Resource_Tag__c';
            mappingConfig.objectType = 'resourceTag';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Resource__c', 'resourceId', 'direct');
            mappingConfig.addFieldConfig('sked__Tag__c', 'tagId', 'direct');
            mappingConfig.addFieldConfig('sked__Expiry_Date__c', 'expiry', 'datetime');
            mappingConfig.addFieldConfig('sked_Expiry_Date__c', 'expiryDate', 'date');
            mappingConfig.addFieldConfig('sked__Tag__r', 'tag', 'related', skedModels.tag.class, 'sked__Tag__c');
            mappingConfig.addFieldConfig('sked_Restriction_Start_Date__c', 'restrictionStartDate', 'date');
            mappingConfig.addFieldConfig('sked_Restriction_End_Date__c', 'restrictionEndDate', 'date');
            mappingConfig.addFieldConfig('sked_Role_Status__c', 'roleStatus', 'direct');
            mappingConfig.addFieldConfig('sked_Start__c', 'start', 'datetime');
            mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', 'date');
            mappingConfig.addFieldConfig('resourceTag', 'objectType', 'value');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            return mappingConfig;
        }
    }

    public class staffingBudgetAvailabilityMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Staffing_Budget_Availability__c';
            mappingConfig.objectType = 'staffingBudgetAvailability';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r', 'availability', 'related', skedModels.availability.class, 'sked__Availability__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__c', 'staffingBudgetId', 'direct');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__r', 'staffingBudget', 'related', skedModels.staffingBudget.class, 'sked_Staffing_Budget__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__r.sked_Approved_Slots_Rollup__c', 'approvedSlots', 'direct');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__r.sked_Pending_Slots_Rollup__c', 'pendingSlots', 'direct');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__r.sked_Wait_List_Slots_Rollup__c', 'approvedSlots', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r.sked__Resource__r.Name', 'resource.name', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r.sked__Resource__r.sked_Seniority_Date__c', 'resource.seniorityDate', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r.sked__Start__c', 'start', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r.sked__Type__c', 'type', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r.sked__Status__c', 'status', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r.sked_Ranking__c', 'ranking', 'direct');
            mappingConfig.addFieldConfig('sked_Availability__r.CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('sked_Availability__r.CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('sked_Availability__r.sked_Last_Modified_By__r', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('sked_Availability__r.LastModifiedDate', 'lastModified', 'datetime');

            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');

            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked_Availability__c');
            mappingConfig.masterDetailFields.add('sked_Staffing_Budget__c');
            return mappingConfig;
        }
    }
    
    public class staffingBudgetMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Staffing_Budget__c';
            mappingConfig.objectType = 'staffingBudget';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Approved_Slots_Rollup__c', 'approvedSlots', 'direct');
            mappingConfig.addFieldConfig('sked_Bidding_End_Date__c', 'biddingEndDate', 'date');
            mappingConfig.addFieldConfig('sked_Bidding_Start_Date__c', 'biddingStartDate', 'date');
            mappingConfig.addFieldConfig('sked_Available_Slots__c', 'availableSlots', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_ARC_Region_Name__c', 'arcRegionName', 'direct');
            mappingConfig.addFieldConfig('sked_District_Name__c', 'districtName', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Op_Center__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'sked_Biomed_Collection_Op_Center__c');
            mappingConfig.addFieldConfig('sked_Convert_to_Standard_On__c', 'convertToStandardOn', 'date');
            mappingConfig.addFieldConfig('sked_Drive_Types__c', 'driveTypes', 'multiPicklist');
            mappingConfig.addFieldConfig('sked_Pending_Slots_Rollup__c', 'pendingSlots', 'direct');
            mappingConfig.addFieldConfig('sked_Recurring_Schedule__c', 'scheduleId', 'direct');
            mappingConfig.addFieldConfig('sked_Request_Type__c', 'requestType', 'direct');
            mappingConfig.addFieldConfig('sked_Region__r.sked__Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked_Roles__c', 'roles', 'multiPicklist');
            mappingConfig.addFieldConfig('sked_Staffing_Budget_Date__c', 'staffingBudgetDate', 'date');
            mappingConfig.addFieldConfig('sked_Total_Slots__c', 'totalSlots', 'direct');

            mappingConfig.addFieldConfig('CreatedBy', 'createdBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('CreatedDate', 'createdOn', 'datetime');
            mappingConfig.addFieldConfig('LastModifiedBy', 'lastModifiedBy', 'related', skedModels.user.class, 'User');
            mappingConfig.addFieldConfig('LastModifiedDate', 'lastModified', 'datetime');

            mappingConfig.addFieldConfig('sked_Availabilities__r', 'availabilities', 'relatedList', 'sked__Availability__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget_Availabilities__r', 'staffingBudgetAvailabilities', 'relatedList', 'sked_Staffing_Budget_Availability__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget_Collection_Ops__r', 'staffingBudgetCollectionOps', 'relatedList', 'sked_Staffing_Budget_Collection_Op__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget_Sites__r', 'staffingBudgetSites', 'relatedList', 'sked_Staffing_Budget_Site__c');

            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            mappingConfig.readonlyFields.add('sked_Approved_Slots_Rollup__c');
            mappingConfig.readonlyFields.add('sked_Available_Slots__c');
            return mappingConfig;
        }
    }

    public class staffingBudgetCollectionOpMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Staffing_Budget_Collection_Op__c';
            mappingConfig.objectType = 'staffingBudgetCollectionOp';

            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Operation__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_Biomed_Collection_Operation__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'sked_Biomed_Collection_Op_Center__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__c', 'staffingBudgetId', 'direct');

            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');

            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked_Biomed_Collection_Operation__c');
            mappingConfig.masterDetailFields.add('sked_Staffing_Budget__c');
            return mappingConfig;
        }
    }

    public class staffingBudgetSiteMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Staffing_Budget_Site__c';
            mappingConfig.objectType = 'staffingBudgetSite';

            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Specific_Collection_Operation__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'Biomed_Collection_Op_Center__c');
            mappingConfig.addFieldConfig('sked_Specific_Collection_Operation__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_Specific_Collection_Operation__r.Name', 'biomedCollectionOpName', 'direct');
            mappingConfig.addFieldConfig('sked_Location__c', 'siteId', 'direct');
            mappingConfig.addFieldConfig('sked_Location__r.Name', 'siteName', 'direct');
            mappingConfig.addFieldConfig('sked_Location__r', 'site', 'related', skedModels.serviceLocation.class, 'sked__Location__c');
            mappingConfig.addFieldConfig('sked_Staffing_Budget__c', 'staffingBudgetId', 'direct');

            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');

            mappingConfig.masterDetailFields = new Set<String>();
            mappingConfig.masterDetailFields.add('sked_Location__c');
            mappingConfig.masterDetailFields.add('sked_Staffing_Budget__c');
            return mappingConfig;
        }
    }

    public class siteCollectionOperationMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Site_Collection_Operation__c';
            mappingConfig.objectType = 'siteCollectionOperation';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'biomedCollectionOpId', 'direct');
            mappingConfig.addFieldConfig('sked_Collection_Operation__r.Name', 'biomedCollectionOpName', 'direct');
            mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', 'direct');
            mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', 'direct');
            mappingConfig.addFieldConfig('sked_Site__c', 'siteId', 'direct');
            mappingConfig.addFieldConfig('sked_Site__r.sked_Timezone__c', 'timezoneSidId', 'direct');
            mappingConfig.addFieldConfig('sked_Site__r', 'site', 'related', skedModels.serviceLocation.class, 'sked__Location__c');
            mappingConfig.addFieldConfig('sked_Collection_Operation__r', 'biomedCollectionOp', 'related', skedModels.biomedCollectionOp.class, 'Biomed_Collection_Op_Center__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            return mappingConfig;
        }
    }
    
    public class tagMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked__Tag__c';
            mappingConfig.objectType = 'tag';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked__Type__c', 'tagType', 'direct');
            mappingConfig.addFieldConfig('sked_Priority__c', 'priority', 'direct');
            return mappingConfig;
        }
    }
    
    public class territoryMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Territory__c';
            mappingConfig.objectType = 'territory';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('RecordType.Name', 'recordTypeName', 'direct');
            mappingConfig.addFieldConfig('End_Date__c', 'endDate', 'date');
            mappingConfig.addFieldConfig('Start_Date__c', 'startDate', 'date');
            mappingConfig.addFieldConfig('sked_Parent__c', 'parentId', 'direct');
            
            mappingConfig.addFieldConfig('sked_Territory_Collection_Operations__r', 'territoryCollectionOperations', 'relatedList', 'sked_Territory_Collection_Operation__c');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            return mappingConfig;
        }
    }
    
    public class territoryCollectionOperationMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_Territory_Collection_Operation__c';
            mappingConfig.objectType = 'territoryCollectionOperation';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('sked_Collection_Operation__c', 'collectionOperationId', 'direct');
            mappingConfig.addFieldConfig('sked_End_Date__c', 'endDate', 'direct');
            mappingConfig.addFieldConfig('sked_Start_Date__c', 'startDate', 'direct');
            mappingConfig.addFieldConfig('sked_Territory__c', 'collectionOperatioterritoryId', 'direct');
            mappingConfig.addFieldConfig('sked_Territory__r.sked_High_Drive_Productivity_Threshold__c', 'highDriveProductivityThreshold', 'direct');
            mappingConfig.addFieldConfig('sked_Territory__r.sked_Mid_Drive_Productivity_Threshold__c', 'midDriveProductivityThreshold', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            return mappingConfig;
        }
    }
    
    public class userMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'User';
            mappingConfig.objectType = 'user';
            
            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('Name', 'name', 'direct');
            mappingConfig.addFieldConfig('SmallPhotoUrl', 'photoUrl', 'direct');
            
            mappingConfig.readonlyFields = new Set<string>();
            mappingConfig.readonlyFields.add('Name');
            
            return mappingConfig;
        }
    }
    
    public class userFilterMappingConfigFactory extends mappingConfigFactory {
        public override mappingConfigModel process() {
            mappingConfigModel mappingConfig = new mappingConfigModel();
            mappingConfig.sObjectName = 'sked_User_Filter__c';
            mappingConfig.objectType = 'userFilter';

            mappingConfig.addFieldConfig('Id', 'id', 'direct');
            mappingConfig.addFieldConfig('sked_User__c', 'userId', 'direct');
            mappingConfig.addFieldConfig('sked_Category__c', 'category', 'direct');
            mappingConfig.addFieldConfig('sked_JSON_Data__c', 'jsonData', 'direct');
            return mappingConfig;
        }
    }
    
}