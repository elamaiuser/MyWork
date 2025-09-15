public class slwcSetting {
    
    public class adminSetting {
        @AuraEnabled public decimal callListRecipient {get;set;}
        @AuraEnabled public decimal callListRecipientNone {get;set;}
        @AuraEnabled public decimal callListRecipientNoneFixedSite {get;set;}
        @AuraEnabled public string distanceMeasurementUnit {get;set;}
        @AuraEnabled public boolean enableResourceCallOut {get;set;}
        @AuraEnabled public boolean enableResourcePto {get;set;}
        @AuraEnabled public decimal excessStaffCapacityThreshold {get;set;}
        @AuraEnabled public string fccCodeFixedSite {get;set;}
        @AuraEnabled public string fccCodeMobile {get;set;}
        @AuraEnabled public string globalJobUrl {get;set;}
        @AuraEnabled public decimal maxRecordSubmissionToWDTimeBlocks {get;set;} 
        @AuraEnabled public boolean opsRecordIntegration {get;set;}
        @AuraEnabled public string opRecordTechSupportEmail {get;set;} 
        @AuraEnabled public decimal siteChangeRestrictionDays {get;set;}
        
        public adminSetting() { 
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.callListRecipient = setting.sked_Admin_Call_List_Recipient__c != NULL ? setting.sked_Admin_Call_List_Recipient__c : 115;
            this.callListRecipientNone = setting.sked_Admin_Call_List_Recipient_None__c != NULL ? setting.sked_Admin_Call_List_Recipient_None__c : 130;
            this.callListRecipientNoneFixedSite = setting.Admin_Call_List_Recipient_None_FS__c != NULL ? setting.Admin_Call_List_Recipient_None_FS__c : 140;
            this.distanceMeasurementUnit = setting.sked_Admin_Distance_Measurement_Unit__c;
            this.enableResourceCallOut = setting.sked_Admin_Enable_Resource_Call_Out__c ;
            this.enableResourcePto = setting.sked_Admin_Enable_Resource_PTO__c; 
            this.excessStaffCapacityThreshold = setting.Admin_Excess_Staff_Capacity_Threshold__c != NULL ? setting.Admin_Excess_Staff_Capacity_Threshold__c : 1;
            this.fccCodeFixedSite = setting.sked_Admin_FCC_Code_Fixed_Site__c;
            this.fccCodeMobile = setting.sked_Admin_FCC_Code_Mobile__c;
            this.globalJobUrl = setting.sked_Admin_Global_JobURL__c;
            this.maxRecordSubmissionToWDTimeBlocks = setting.sked_Max_Record_Submission_WD_TimeBlock__c;
            this.opsRecordIntegration = setting.sked_Admin_Ops_Record_Integration__c;
            this.opRecordTechSupportEmail = setting.sked_Admin_Op_Record_Tech_Support_Email__c;
            this.siteChangeRestrictionDays = setting.sked_Admin_Site_Change_Restriction_Days__c != NULL ? setting.sked_Admin_Site_Change_Restriction_Days__c : 14;
        }
    }
    
    public class lacSetting extends calendarSettingBase {
        @AuraEnabled public integer defaultDuration {get;set;}
        @AuraEnabled public integer startWorkingTime {get;set;}
        @AuraEnabled public Map<string, skedModels.eventTypeSetting> colorMap {get;set;}

        public lacSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = setting.sked_LAC_First_Day__c != NULL ? integer.valueOf(setting.sked_LAC_First_Day__c) : 0;
            this.viewPeriod = setting.sked_LAC_View_Period__c != NULL ? integer.valueOf(setting.sked_LAC_View_Period__c) : 2;
            this.dateFormat = !string.isBlank(setting.sked_LAC_Date_Format__c) ? setting.sked_LAC_Date_Format__c : 'MM/dd/yyyy';
            this.datePickerFormat = !string.isBlank(setting.sked_LAC_Datepicker_Format__c) ? setting.sked_LAC_Datepicker_Format__c : 'D, mm/dd/yy';
            this.weekPickerFormat = !string.isBlank(setting.sked_LAC_Weekpicker_Format__c) ? setting.sked_LAC_Weekpicker_Format__c : 's[M d] - e[M d, yy]';
            this.monthPickerFormat = !string.isBlank(setting.sked_LAC_Monthpicker_Format__c) ? setting.sked_LAC_Monthpicker_Format__c : 'MMM, yyyy';
            this.noOfRecurWeeks = setting.sked_LAC_No_of_Recur_Weeks__c != NULL ? integer.valueOf(setting.sked_LAC_No_of_Recur_Weeks__c) : 10;
            this.calendarStart = setting.sked_LAC_Calendar_Start__c != NULL ? integer.valueOf(setting.sked_LAC_Calendar_Start__c) : 700;
            this.calendarEnd = setting.sked_LAC_Calendar_End__c != NULL ? integer.valueOf(setting.sked_LAC_Calendar_End__c) : 1900;
            this.calendarStep = setting.sked_LAC_Calendar_Step__c != NULL ? integer.valueOf(setting.sked_LAC_Calendar_Step__c) : 30;

            List<string> objectTypes = new List<string>();
            objectTypes.add('locationAvailability');
            objectTypes.add('drive');
            this.eventTypeSettings = getEventTypeSettings(objectTypes);

            //Default duration and start time for event creation
            this.defaultDuration = this.calendarStep;
            this.startWorkingTime = this.calendarStart;
        }
    }
    
    public class pacSetting extends calendarSettingBase {
        @AuraEnabled public integer defaultDuration {get;set;}
        @AuraEnabled public integer startWorkingTime {get;set;}
        @AuraEnabled public Map<string, skedModels.eventTypeSetting> colorMap {get;set;}

        public pacSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = setting.sked_PAC_First_Day__c != NULL ? integer.valueOf(setting.sked_PAC_First_Day__c) : 0;
            this.viewPeriod = setting.sked_PAC_View_Period__c != NULL ? integer.valueOf(setting.sked_PAC_View_Period__c) : 2;
            this.dateFormat = !string.isBlank(setting.sked_PAC_Date_Format__c) ? setting.sked_PAC_Date_Format__c : 'MM/dd/yyyy';
            this.datePickerFormat = !string.isBlank(setting.sked_PAC_Datepicker_Format__c) ? setting.sked_PAC_Datepicker_Format__c : 'D, mm/dd/yy';
            this.weekPickerFormat = !string.isBlank(setting.sked_PAC_Weekpicker_Format__c) ? setting.sked_PAC_Weekpicker_Format__c : 's[M d] - e[M d, yy]';
            this.monthPickerFormat = !string.isBlank(setting.sked_PAC_Monthpicker_Format__c) ? setting.sked_PAC_Monthpicker_Format__c : 'MMM, yyyy';
            this.noOfRecurWeeks = setting.sked_PAC_No_of_Recur_Weeks__c != NULL ? integer.valueOf(setting.sked_PAC_No_of_Recur_Weeks__c) : 10;
            this.calendarStart = setting.sked_PAC_Calendar_Start__c != NULL ? integer.valueOf(setting.sked_PAC_Calendar_Start__c) : 700;
            this.calendarEnd = setting.sked_PAC_Calendar_End__c != NULL ? integer.valueOf(setting.sked_PAC_Calendar_End__c) : 1900;
            this.calendarStep = setting.sked_PAC_Calendar_Step__c != NULL ? integer.valueOf(setting.sked_PAC_Calendar_Step__c) : 30;

            List<string> objectTypes = new List<string>();
            objectTypes.add('clientAvailability');
            objectTypes.add('drive');
            this.eventTypeSettings = getEventTypeSettings(objectTypes);

            //Default duration and start time for event creation
            this.defaultDuration = this.calendarStep;
            this.startWorkingTime = this.calendarStart;
        }
    }
    
    public class racSetting extends calendarSettingBase {
        @AuraEnabled public integer defaultDuration {get;set;}
        @AuraEnabled public integer startWorkingTime {get;set;}
        @AuraEnabled public Map<string, skedModels.eventTypeSetting> colorMap {get;set;}

        public racSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = setting.sked_RAC_First_Day__c != NULL ? integer.valueOf(setting.sked_RAC_First_Day__c) : 0;
            this.viewPeriod = setting.sked_RAC_View_Period__c != NULL ? integer.valueOf(setting.sked_RAC_View_Period__c) : 2;
            this.dateFormat = !string.isBlank(setting.sked_RAC_Date_Format__c) ? setting.sked_RAC_Date_Format__c : 'MM/dd/yyyy';
            this.datePickerFormat = !string.isBlank(setting.sked_RAC_Datepicker_Format__c) ? setting.sked_RAC_Datepicker_Format__c : 'D, mm/dd/yy';
            this.weekPickerFormat = !string.isBlank(setting.sked_RAC_Weekpicker_Format__c) ? setting.sked_RAC_Weekpicker_Format__c : 's[M d] - e[M d, yy]';
            this.monthPickerFormat = !string.isBlank(setting.sked_RAC_Monthpicker_Format__c) ? setting.sked_RAC_Monthpicker_Format__c : 'MMM, yyyy';
            this.noOfRecurWeeks = setting.sked_RAC_No_of_Recur_Weeks__c != NULL ? integer.valueOf(setting.sked_RAC_No_of_Recur_Weeks__c) : 10;
            this.calendarStart = setting.sked_RAC_Calendar_Start__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Start__c) : 700;
            this.calendarEnd = setting.sked_RAC_Calendar_End__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_End__c) : 1900;
            this.calendarStep = setting.sked_RAC_Calendar_Step__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Step__c) : 30;

            List<string> objectTypes = new List<string>();
            objectTypes.add('activity');
            objectTypes.add('availability');
            objectTypes.add('job');
            objectTypes.add('customAvailability');
            this.eventTypeSettings = getEventTypeSettings(objectTypes);

            //Default duration and start time for event creation
            this.defaultDuration = this.calendarStep;
            this.startWorkingTime = this.calendarStart;
        }
    }

    public class travelTimeManager {
        @AuraEnabled public integer driveImpactThreshold {get;set;}
        @AuraEnabled public integer numberOfParallelRequests {get;set;}
        @AuraEnabled public integer refreshInterval {get;set;}
        @AuraEnabled public integer newIndexPriority {get;set;}
        @AuraEnabled public integer manualRefreshPriority {get;set;}
        @AuraEnabled public boolean enableManualRefreshBanner {get;set;}

        public travelTimeManager() {
            sked_Travel_Time_Manager__c setting = sked_Travel_Time_Manager__c.getOrgDefaults();
            this.driveImpactThreshold = setting.sked_Drive_Impact_Threshold__c != NULL ? integer.valueOf(setting.sked_Drive_Impact_Threshold__c) : 15;
            this.numberOfParallelRequests = setting.sked_Number_of_Parallel_Requests__c != NULL ? integer.valueOf(setting.sked_Number_of_Parallel_Requests__c) : 4;
            this.refreshInterval = setting.sked_Refresh_Interval__c != NULL ? integer.valueOf(setting.sked_Refresh_Interval__c) : 180;
            this.newIndexPriority = setting.sked_New_Index_Priority__c != NULL ? integer.valueOf(setting.sked_New_Index_Priority__c) : 1000;
            this.manualRefreshPriority = setting.sked_Manual_Refresh_Priority__c != NULL ? integer.valueOf(setting.sked_Manual_Refresh_Priority__c) : 1000;
            this.enableManualRefreshBanner = setting.sked_Enable_Manual_Refresh_Banner__c;
        }
    }
    
    /********************************************** Abstract Classes *****************************************/
    public abstract class calendarSettingBase {
        @AuraEnabled public integer firstDay {get;set;}
        @AuraEnabled public integer viewPeriod {get;set;}
        @AuraEnabled public string dateFormat {get;set;}
        @AuraEnabled public string datePickerFormat {get;set;}
        @AuraEnabled public string weekPickerFormat {get;set;}
        @AuraEnabled public string monthPickerFormat {get;set;}
        @AuraEnabled public integer noOfRecurWeeks {get;set;}
        @AuraEnabled public integer calendarStart {get;set;}
        @AuraEnabled public integer calendarEnd {get;set;}
        @AuraEnabled public integer calendarStep {get;set;}
        @AuraEnabled public boolean showLegend {get;set;}
        @AuraEnabled public List<eventTypeSetting> eventTypeSettings {get;set;}

        protected List<eventTypeSetting> getEventTypeSettings(List<string> objectTypes) {
            List<eventTypeSetting> results = new List<eventTypeSetting>();
            List<sked_Event_Type_Setting__c> skedEventTypeSettings = [SELECT Id, sked_Item__c, sked_Available_Start__c, sked_Available_End__c,
                                                                        sked_Background_Color__c, sked_Can_Be_Pre_dated__c, sked_Color__c,
                                                                        sked_Short_Name__c, sked_Step__c, sked_Is_Available__c, sked_Show_Legend__c,
                                                                        sked_Category__c
                                                                        FROM sked_Event_Type_Setting__c
                                                                        WHERE sked_Is_Active__c = TRUE
                                                                        AND sked_Category__c IN :objectTypes];
            if (skedEventTypeSettings != NULL && skedEventTypeSettings.size() > 0) {
                for (sked_Event_Type_Setting__c skedEventTypeSetting : skedEventTypeSettings) {
                    eventTypeSetting model = new eventTypeSetting();
                    model.id = skedEventTypeSetting.Id;
                    model.eventType = skedEventTypeSetting.sked_Item__c;
                    model.availableStart = integer.valueOf(skedEventTypeSetting.sked_Available_Start__c);
                    model.availableEnd = integer.valueOf(skedEventTypeSetting.sked_Available_End__c);
                    model.backgroundColor = skedEventTypeSetting.sked_Background_Color__c;
                    model.canBePreDated = skedEventTypeSetting.sked_Can_Be_Pre_dated__c;
                    model.color = skedEventTypeSetting.sked_Color__c;
                    model.shortName = skedEventTypeSetting.sked_Short_Name__c;
                    model.isAvailable = skedEventTypeSetting.sked_Is_Available__c;
                    model.objectType = skedEventTypeSetting.sked_Category__c;
                    model.step = integer.valueOf(skedEventTypeSetting.sked_Step__c);
                    model.showLegend = skedEventTypeSetting.sked_Show_Legend__c;
                    results.add(model);
                }
            }
            return results;
        }
    }
    
    public class eventTypeSetting {
        @AuraEnabled public string id {get;set;}
        @AuraEnabled public string name {get;set;}
        @AuraEnabled public integer availableEnd {get;set;}
        @AuraEnabled public integer availableStart {get;set;}
        @AuraEnabled public string backgroundColor {get;set;}
        @AuraEnabled public boolean canBePreDated {get;set;}
        @AuraEnabled public string category {get;set;}
        @AuraEnabled public string color {get;set;}
        @AuraEnabled public string eventType {get;set;}
        @AuraEnabled public string eventStatus {get;set;}
        @AuraEnabled public boolean isActive {get;set;}
        @AuraEnabled public boolean isAvailable {get;set;}
        @AuraEnabled public string objectType {get;set;}
        @AuraEnabled public string shortName {get;set;}
        @AuraEnabled public boolean showLegend {get;set;}
        @AuraEnabled public integer step {get;set;}
    }

    public class optimizerDefaultWeights {
        @AuraEnabled public integer high {get;set;}
        @AuraEnabled public integer medium {get;set;}
        @AuraEnabled public integer low {get;set;} 

        public optimizerDefaultWeights() {
            Map<String, sked_Optimizer_Default_Weight__mdt> settingsMap = sked_Optimizer_Default_Weight__mdt.getAll();
            this.high = settingsMap.get('High').sked_Default_Value__c != NULL ? Integer.valueOf(settingsMap.get('High').sked_Default_Value__c) : null;
            this.medium = settingsMap.get('Medium').sked_Default_Value__c != NULL ? Integer.valueOf(settingsMap.get('Medium').sked_Default_Value__c) : null;
            this.low = settingsMap.get('Low').sked_Default_Value__c != NULL ? Integer.valueOf(settingsMap.get('Low').sked_Default_Value__c) : null;
        }
    }

    public class optimizerDefaultSettings {
        @AuraEnabled public List<optimizerSetting> optimizerSettings {get;set;}

        public optimizerDefaultSettings() {
            this.optimizerSettings = new List<optimizerSetting>();
            for (sked_Optimizer_Default_Setting__mdt setting : sked_Optimizer_Default_Setting__mdt.getAll().values()) {
                optimizerSetting model = new optimizerSetting();
                model.constraint = setting.sked_Constraint__c;
                model.constraintType = setting.sked_Constraint_Type__c;
                model.defaultWeight = setting.sked_Default_Weight__c;
                model.displayOrder = setting.sked_Display_Order__c?.intValue();
                model.displayType = setting.sked_Display_Type__c;
                model.driveType = setting.sked_Drive_Type__c;
                model.enabled = setting.sked_Enabled__c;
                this.optimizerSettings.add(model);
            }
        }
    }

    public class optimizerSetting {
        @AuraEnabled public string constraint {get;set;}
        @AuraEnabled public string constraintType {get;set;}
        @AuraEnabled public string defaultWeight {get;set;}
        @AuraEnabled public integer displayOrder {get;set;}
        @AuraEnabled public string displayType {get;set;}
        @AuraEnabled public string driveType {get;set;}
        @AuraEnabled public boolean enabled {get;set;}
    }

    public class redcrossVolunteerMatrixSettings {
        @AuraEnabled public List<redcrossVolunteerMatrixSetting> redcrossVolunteerMatrixSettings {get;set;}

        public redcrossVolunteerMatrixSettings() {
            this.redcrossVolunteerMatrixSettings = new List<redcrossVolunteerMatrixSetting>();
            for (Volunteer_Staffing_Matrix__mdt setting : Volunteer_Staffing_Matrix__mdt.getAll().values()) {
                redcrossVolunteerMatrixSetting model = new redcrossVolunteerMatrixSetting();
                model.isHighSchoolDrive = setting.High_School_Drive__c;
                model.minDonorValue = setting.Min_Anticipated_Registered_Donors__c;
                model.maxDonorValue = setting.Max_Anticipated_Registered_Donors__c;
                model.volunteerQuantity = setting.Volunteer_Quantity__c;
                model.driveType = setting.Drive_Type__c;
                model.operationType = setting.Operation_Type__c;
                this.redcrossVolunteerMatrixSettings.add(model);
            }
        }
    }

    public class redcrossVolunteerMatrixSetting {
        @AuraEnabled public boolean isHighSchoolDrive {get;set;}
        @AuraEnabled public decimal minDonorValue {get;set;}
        @AuraEnabled public decimal maxDonorValue {get;set;}
        @AuraEnabled public decimal volunteerQuantity {get;set;}
        @AuraEnabled public string driveType {get;set;}
        @AuraEnabled public string operationType {get;set;}
    }
}