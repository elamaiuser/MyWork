public class slwcSetting {
    
    public class adminSetting {
        @AuraEnabled public decimal callListRecipient {get;set;}
        @AuraEnabled public decimal callListRecipientNone {get;set;}
        @AuraEnabled public string distanceMeasurementUnit {get;set;}
        @AuraEnabled public boolean enableResourceCallOut {get;set;}
        @AuraEnabled public boolean enableResourcePto {get;set;}
        @AuraEnabled public string fccCodeFixedSite {get;set;}
        @AuraEnabled public string fccCodeMobile {get;set;}
        @AuraEnabled public string globalJobUrl {get;set;}
        @AuraEnabled public boolean opsRecordIntegration {get;set;}
        @AuraEnabled public decimal siteChangeRestrictionDays {get;set;}
        
        public adminSetting() { 
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.callListRecipient = setting.sked_Admin_Call_List_Recipient__c;
            this.callListRecipientNone = setting.sked_Admin_Call_List_Recipient_None__c;
            this.distanceMeasurementUnit = setting.sked_Admin_Distance_Measurement_Unit__c;
            this.enableResourceCallOut = setting.sked_Admin_Enable_Resource_Call_Out__c ;
            this.enableResourcePto = setting.sked_Admin_Enable_Resource_PTO__c;
            this.fccCodeFixedSite = setting.sked_Admin_FCC_Code_Fixed_Site__c;
            this.fccCodeMobile = setting.sked_Admin_FCC_Code_Mobile__c;
            this.globalJobUrl = setting.sked_Admin_Global_JobURL__c;
            this.opsRecordIntegration = setting.sked_Admin_Ops_Record_Integration__c;
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

}