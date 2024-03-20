import {
    MAPPING_TYPE,
    AccountAvailabilityPreferenceMappingConfigFactory, AccountBridgeApiMappingConfigFactory,
    AccountMappingConfigFactory, AccountResourceScoreMappingConfigFactory, AccountTagMappingConfigFactory,
    ActivityMappingConfigFactory, ActivityResourceMappingConfigFactory,
    AvailabilityMappingConfigFactory, AvailabilityPatternMappingConfigFactory, AvailabilityPatternResourceMappingConfigFactory,
    CalendarMessageCollectionOperationMappingConfigFactory, CalendarMessageMappingConfigFactory,
    ClientAvailabilityMappingConfigFactory, CollectionOperationSdmMappingConfigFactory, CollectionOpMappingConfigFactory, CollectionOpStagingLocationMappingConfigFactory,
    ContactMappingConfigFactory, CustomAvailabilityMappingConfigFactory,
    DcrFieldMappingConfigFactory, DcrPeriodMappingConfigFactory, DcrRoleFieldMappingConfigFactory, DcrRoleMappingConfigFactory, DriveBridgeApiMappingConfigFactory,
    DebugLogMappingConfigFactory, DriveBagMappingConfigFactory, DriveChangeRequestItemMappingConfigFactory, DriveChangeRequestMappingConfigFactory, DriveDeliveryJobMappingConfigFactory,
    DriveMappingConfigFactory, DriveShiftMappingConfigFactory, DriveShiftTagMappingConfigFactory, DriveShiftTradeMappingConfigFactory,
    EventTypeSettingMappingConfigFactory, ExceptionMappingConfigFactory, ExceptionSettingMappingConfigFactory,
    FixedSiteProcedureProjectionMappingConfigFactory, GroupMemberMappingConfigFactory, HolidayCollectionOperationMappingConfigFactory, HolidayMappingConfigFactory,
    JobAllocationMappingConfigFactory, JobMappingConfigFactory, JobTagMappingConfigFactory, LinkedDrivesMappingConfigFactory, 
    LocationAvailabilityMappingConfigFactory, LocationMappingConfigFactory, LocationResourceScoreMappingConfigFactory, LocationTagMappingConfigFactory,
    LunchBreakDefinitionMappingConfigFactory, LunchBreakSettingMappingConfigFactory,
    OperationDriveLimitMappingConfigFactory, OperationDriveLimitOverrideMappingConfigFactory,
    OperationRecordMappingConfigFactory, OperationRecordStaffMappingConfigFactory, 
    OpportunityMappingConfigFactory, OpportunityContactRoleMappingConfigFactory,
    OptimizationQueueItemMappingConfigFactory, OptimizationQueueMappingConfigFactory, OptimizationRunMappingConfigFactory, 
    ProductGoalMappingConfigFactory, RecurringScheduleMappingConfigFactory, RegionMappingConfigFactory, 
    ResourceHoursRecordMappingConfigFactory, ResourceMappingConfigFactory, ResourceOverrideMappingConfigFactory, ResourceSecondaryCollectionOperationMappingConfigFactory, ResourceRoleGroupMappingConfigFactory,
    ResourceTagMappingConfigFactory, RoleTimeDetailMappingConfigFactory, RoleTimeVarianceMappingConfigFactory, 
    SiteBridgeApiMappingConfigFactory, SiteCollectionOperationMappingConfigFactory, SiteFeedbackMappingConfigFactory, SlotMappingConfigFactory, 
    StagingLocationMappingConfigFactory, StaffingConstraintMappingConfigFactory, StaffingDecisionMatrixMappingConfigFactory, TagMappingConfigFactory, TerritoryCollectionOperationMappingConfigFactory,
    TerritoryMappingConfigFactory, TravelTimeIndexItemMappingConfigFactory, UserMappingConfigFactory, BsfPortfolioMappingConfigFactory, StaffSetupExcludedRoleMappingConfigFactory
} from './index.js';

class mappingConfigContainer {
    mapConfig;
    // _instance;
    classesMapping;

    constructor() {
        this.mapConfig = new Map();

        this.classesMapping = {
            'AccountBridgeAPI__xMappingConfigFactory': AccountBridgeApiMappingConfigFactory,
            'DriveBridgeAPI__xMappingConfigFactory': DriveBridgeApiMappingConfigFactory,
            'SiteBridgeAPI__xMappingConfigFactory': SiteBridgeApiMappingConfigFactory,
            'AccountMappingConfigFactory' : AccountMappingConfigFactory,
            'Biomed_Collection_Op_Center__cMappingConfigFactory' : CollectionOpMappingConfigFactory,
            'ContactMappingConfigFactory' : ContactMappingConfigFactory,
            'GroupMemberMappingConfigFactory' : GroupMemberMappingConfigFactory,
            'OpportunityMappingConfigFactory' : OpportunityMappingConfigFactory,
            'OpportunityContactRoleMappingConfigFactory' : OpportunityContactRoleMappingConfigFactory,
            'sked_Linked_Drives__cMappingConfigFactory' : LinkedDrivesMappingConfigFactory,
            'UserMappingConfigFactory' : UserMappingConfigFactory,
            'sked_Account_Availability_Preference__cMappingConfigFactory' : AccountAvailabilityPreferenceMappingConfigFactory,
            'sked__Activity__cMappingConfigFactory' : ActivityMappingConfigFactory,
            'sked__Activity_Resource__cMappingConfigFactory' : ActivityResourceMappingConfigFactory,
            'sked__Account_Tag__cMappingConfigFactory' : AccountTagMappingConfigFactory,
            'sked__Account_Resource_Score__cMappingConfigFactory' : AccountResourceScoreMappingConfigFactory,
            'sked__Availability__cMappingConfigFactory' : AvailabilityMappingConfigFactory,
            'sked__Availability_Pattern__cMappingConfigFactory' : AvailabilityPatternMappingConfigFactory,
            'sked__Availability_Pattern_Resource__cMappingConfigFactory' : AvailabilityPatternResourceMappingConfigFactory,
            'sked_Calendar_Message__cMappingConfigFactory': CalendarMessageMappingConfigFactory,
            'sked_CalendarMessage_CollectionOperation__cMappingConfigFactory': CalendarMessageCollectionOperationMappingConfigFactory,
            'sked__Client_Availability__cMappingConfigFactory' : ClientAvailabilityMappingConfigFactory,
            'sked_Collection_Op_Staging_Location__cMappingConfigFactory' : CollectionOpStagingLocationMappingConfigFactory,
            'sked_Collection_Operation_SDM__cMappingConfigFactory' : CollectionOperationSdmMappingConfigFactory,
            'sked_Custom_Availability__cMappingConfigFactory' : CustomAvailabilityMappingConfigFactory,
            'sked_DCR_Field__cMappingConfigFactory' : DcrFieldMappingConfigFactory,
            'sked_DCR_Period__cMappingConfigFactory' : DcrPeriodMappingConfigFactory,
            'sked_DCR_Role__cMappingConfigFactory' : DcrRoleMappingConfigFactory,
            'sked_DCR_Role_Field__cMappingConfigFactory' : DcrRoleFieldMappingConfigFactory,
            'sked__Debug_Log__cMappingConfigFactory' : DebugLogMappingConfigFactory,
            'sked_Drive__cMappingConfigFactory' : DriveMappingConfigFactory,
            'sked_Drive_Bag__cMappingConfigFactory' : DriveBagMappingConfigFactory,
            'sked_Drive_Change_Request__cMappingConfigFactory' : DriveChangeRequestMappingConfigFactory,
            'sked_Drive_Change_Request_Item__cMappingConfigFactory' : DriveChangeRequestItemMappingConfigFactory,
            'sked_Drive_Delivery_Job__cMappingConfigFactory' : DriveDeliveryJobMappingConfigFactory,
            'sked_Drive_Shift__cMappingConfigFactory' : DriveShiftMappingConfigFactory,
            'sked_Drive_Shift_Trade__cMappingConfigFactory' : DriveShiftTradeMappingConfigFactory,
            'sked_Drive_Shift_Tag__cMappingConfigFactory': DriveShiftTagMappingConfigFactory,
            'sked_Event_Type_Setting__cMappingConfigFactory' : EventTypeSettingMappingConfigFactory,
            'sked_Exception_Setting__cMappingConfigFactory' : ExceptionSettingMappingConfigFactory,
            'sked_Fixed_Site_Procedure_Projection__cMappingConfigFactory' : FixedSiteProcedureProjectionMappingConfigFactory,
            'sked__Holiday__cMappingConfigFactory' : HolidayMappingConfigFactory,
            'sked_Holiday_Collection_Operation__cMappingConfigFactory' : HolidayCollectionOperationMappingConfigFactory,
            'sked__Job__cMappingConfigFactory' : JobMappingConfigFactory,
            'sked__Job_Allocation__cMappingConfigFactory' : JobAllocationMappingConfigFactory,
            'sked__Job_Tag__cMappingConfigFactory' : JobTagMappingConfigFactory,
            'sked__Location__cMappingConfigFactory' : LocationMappingConfigFactory,
            'sked_Location_Availability__cMappingConfigFactory' : LocationAvailabilityMappingConfigFactory,
            'sked_Location_Tag__cMappingConfigFactory' : LocationTagMappingConfigFactory,
            'sked__Location_Resource_Score__cMappingConfigFactory' : LocationResourceScoreMappingConfigFactory,
            'sked_Lunch_Break_Definition__cMappingConfigFactory' : LunchBreakDefinitionMappingConfigFactory,
            'sked_Lunch_Break_Setting__cMappingConfigFactory' : LunchBreakSettingMappingConfigFactory,
            'sked_Operation_Drive_Limit__cMappingConfigFactory' : OperationDriveLimitMappingConfigFactory,
            'sked_Operation_Drive_Limit_Override__cMappingConfigFactory' : OperationDriveLimitOverrideMappingConfigFactory,
            'sked_Operation_Record__cMappingConfigFactory' : OperationRecordMappingConfigFactory,
            'sked_Operation_Record_Staff__cMappingConfigFactory' : OperationRecordStaffMappingConfigFactory,
            'sked_Optimization_Queue__cMappingConfigFactory' : OptimizationQueueMappingConfigFactory,
            'sked_Optimization_Queue_Item__cMappingConfigFactory' : OptimizationQueueItemMappingConfigFactory,
            'sked_Optimization_Run__cMappingConfigFactory' : OptimizationRunMappingConfigFactory,
            'sked_Product_Goal__cMappingConfigFactory' : ProductGoalMappingConfigFactory,
            'sked__Recurring_Schedule__cMappingConfigFactory' : RecurringScheduleMappingConfigFactory,
            'sked__Region__cMappingConfigFactory' : RegionMappingConfigFactory,
            'sked__Resource__cMappingConfigFactory' : ResourceMappingConfigFactory,
            'sked__Resource_Override__cMappingConfigFactory' : ResourceOverrideMappingConfigFactory,
            'sked_Resource_Biomed_Collection_Op__cMappingConfigFactory' : ResourceSecondaryCollectionOperationMappingConfigFactory,
            'sked_Resource_Hours_Record__cMappingConfigFactory': ResourceHoursRecordMappingConfigFactory,
            'sked__Resource_Tag__cMappingConfigFactory' : ResourceTagMappingConfigFactory,
            'sked_Role_Time_Detail__cMappingConfigFactory' : RoleTimeDetailMappingConfigFactory,
            'sked_Role_Time_Variance__cMappingConfigFactory' : RoleTimeVarianceMappingConfigFactory,
            'sked_Site_Collection_Operation__cMappingConfigFactory' : SiteCollectionOperationMappingConfigFactory,
            'sked_Site_Feedback__cMappingConfigFactory' : SiteFeedbackMappingConfigFactory,
            'sked__Slot__cMappingConfigFactory' : SlotMappingConfigFactory,
            'sked_Staging_Location__cMappingConfigFactory' : StagingLocationMappingConfigFactory,
            'sked_Staffing_Constraint__cMappingConfigFactory' : StaffingConstraintMappingConfigFactory,
            'sked_Staffing_Decision_Matrix__cMappingConfigFactory' : StaffingDecisionMatrixMappingConfigFactory,
            'sked__Tag__cMappingConfigFactory' : TagMappingConfigFactory,
            'sked_Territory_Collection_Operation__cMappingConfigFactory': TerritoryCollectionOperationMappingConfigFactory,
            'sked_Territory__cMappingConfigFactory' : TerritoryMappingConfigFactory,
            'sked_Travel_Time_Index_Item__cMappingConfigFactory' : TravelTimeIndexItemMappingConfigFactory,
            'skedHC__Exception__cMappingConfigFactory' : ExceptionMappingConfigFactory,
            'BSF_Portfolio__cMappingConfigFactory' : BsfPortfolioMappingConfigFactory,
            'sked_Staff_Setup_Excluded_Role__cMappingConfigFactory' : StaffSetupExcludedRoleMappingConfigFactory
        };
    }

    getMappingConfig(sObjectType) {
        let mappingConfig;
        if (!this.mapConfig.has(sObjectType)) {
            let className = sObjectType + 'MappingConfigFactory';
            console.log('init factoryInstance: ' + className);
            //implement cache class mapping
            let factoryInstance = new this.classesMapping[className]();
            mappingConfig = factoryInstance.process();
            this.mapConfig.set(sObjectType, mappingConfig);

        } 
        else {
            mappingConfig = this.mapConfig.get(sObjectType);
        }

        return mappingConfig;
    }
}

const mappingConfigContainerInstance = new mappingConfigContainer();
Object.freeze(mappingConfigContainerInstance);

export {
    mappingConfigContainerInstance,
    MAPPING_TYPE
}