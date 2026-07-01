global class skedSetting {

    private skedAppSetting appSetting;
    public skedAppSetting App {
        get {
            if (appSetting == null) {
                appSetting = new skedAppSetting();
            }
            return appSetting;
        }
    }

    private skedAdminSetting adminSetting;
    public skedAdminSetting Admin {
        get {
            if (adminSetting == null) {
                adminSetting = new skedAdminSetting();
            }
            return adminSetting;
        }
    }

    private skedBookingGridSetting bgSetting;
    public skedBookingGridSetting BG {
        get {
            if (bgSetting == null) {
                bgSetting = new skedBookingGridSetting();
            }
            return bgSetting;
        }
    }
    
    private skedEcSetting ecSetting;
    public skedEcSetting EC {
        get {
            if (ecSetting == null) {
                ecSetting = new skedEcSetting();
            }
            return ecSetting;
        }
    }
    
    private skedEmailSetting emailSetting;
    public skedEmailSetting Email {
        get {
            if (emailSetting == null) {
                emailSetting = new skedEmailSetting();
            }
            return emailSetting;
        }
    }

    private skedLacSetting lacSetting;
    public skedLacSetting LAC {
        get {
            if (lacSetting == null) {
                lacSetting = new skedLacSetting();
            }
            return lacSetting;
        }
    }

    private skedNotificationManager notificationManager;
    public skedNotificationManager Notification {
        get {
            if (notificationManager == null) {
                notificationManager = new skedNotificationManager();
            }
            return notificationManager;
        }
    }

    private skedPacSetting pacSetting;
    public skedPacSetting PAC {
        get {
            if (pacSetting == null) {
                pacSetting = new skedPacSetting();
            }
            return pacSetting;
        }
    }

    private skedRacSetting racSetting;
    public skedRacSetting RAC {
        get {
            if (racSetting == null) {
                racSetting = new skedRacSetting();
            }
            return racSetting;
        }
    }
    
    private skedTravelTimeManager travelTimeManager;
    public skedTravelTimeManager TravelTime {
        get {
            if (travelTimeManager == null) {
                travelTimeManager = new skedTravelTimeManager();
            }
            return travelTimeManager;
        }
    }

    private skedTTIRRStuckJobConfigSetting stuckTTIRRSetting;
    public skedTTIRRStuckJobConfigSetting stuckTTIRR {
        get {
            if(stuckTTIRRSetting == NULL) {
                stuckTTIRRSetting = new skedTTIRRStuckJobConfigSetting();
            }
            return stuckTTIRRSetting;
        }
    }

    private skedJAPostProcessBatchConfigSetting jaPostProcessBatchConfigSetting;
    public skedJAPostProcessBatchConfigSetting jaPostProcessBatchConfig {
        get {
            if(jaPostProcessBatchConfigSetting == NULL) {
                jaPostProcessBatchConfigSetting = new skedJAPostProcessBatchConfigSetting();
            }
            return jaPostProcessBatchConfigSetting;
        }
    }

    /*********************************************************** Singleton stuffs ***********************************************************/
    private static skedSetting mInstance = null;

    public static skedSetting instance {
        get {
            if (mInstance == null) {
                mInstance = new skedSetting();
            }
            return mInstance;
        }
    }

    /*********************************************************** Private constructor ***********************************************************/
    private skedSetting() {}

    /*********************************************************** Nested Classes ***********************************************************/
    public class skedAppSetting {
        public string activeComponent;
        public string timezoneSidId;
        public boolean daylightSavingDetected;

        private Map<string, Set<Date>> mMapHoliday;
        public Map<string, Set<Date>> mapHoliday {
            get {
                if (mMapHoliday == NULL) {
                    mMapHoliday = getMapHoliday();
                }
                return mMapHoliday;
            }
        }

        public skedAppSetting() {
            this.timezoneSidId = UserInfo.getTimeZone().getID();
            this.daylightSavingDetected = true;
        }

        public void setTimezoneSidId(string inputTimezoneSidId) {
            this.timezoneSidId = inputTimezoneSidId;
        }

        public void detectDaylightSaving(Date startDate, Date endDate) {
            detectDaylightSaving(DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)), DateTime.newInstance(endDate, Time.newInstance(0, 0, 0, 0)));
        }

        public void detectDaylightSaving(DateTime startTime, DateTime endTime) {
            Timezone tz = Timezone.getTimezone(this.timezoneSidId);
            this.daylightSavingDetected = tz.getOffset(startTime) != tz.getOffset(endTime);
        }

        private Map<string, Set<Date>> getMapHoliday() {
            Map<string, Set<Date>> mapHolidays = new Map<string, Set<Date>>();
            Date currentDate = system.now().date().addDays(-1);//buffer for different timezone

            List<sked__Holiday__c> skedGlobalHolidays = [SELECT Id, sked__Start_Date__c, sked__End_Date__c
                                                         FROM sked__Holiday__c
                                                         WHERE sked__Global__c = TRUE
                                                         AND sked__End_Date__c >= :currentDate];
            List<sked__Holiday_Region__c> skedRegionHolidays = [SELECT Id, sked__Holiday__r.sked__Start_Date__c, sked__Holiday__r.sked__End_Date__c,
                                                                sked__Region__c
                                                                FROM sked__Holiday_Region__c
                                                                WHERE sked__Holiday__r.sked__End_Date__c >= :currentDate];

            Set<Date> globalHolidays = new Set<Date>();
            for (sked__Holiday__c globalHoliday : skedGlobalHolidays) {
                Date tempDate = globalHoliday.sked__Start_Date__c;
                while (tempDate <= globalHoliday.sked__End_Date__c) {
                    globalHolidays.add(tempDate);
                    tempDate = tempDate.addDays(1);
                }
            }
            mapHolidays.put(skedConstants.HOLIDAY_GLOBAL, globalHolidays);

            for (sked__Holiday_Region__c regionHoliday : skedRegionHolidays) {
                Set<Date> regionHolidays;
                if (mapHolidays.containsKey(regionHoliday.sked__Region__c)) {
                    regionHolidays = mapHolidays.get(regionHoliday.sked__Region__c);
                } else {
                    regionHolidays = new Set<Date>();
                }

                Date tempDate = regionHoliday.sked__Holiday__r.sked__Start_Date__c;
                while (tempDate <= regionHoliday.sked__Holiday__r.sked__End_Date__c) {
                    regionHolidays.add(tempDate);
                    tempDate = tempDate.addDays(1);
                }

                if (!mapHolidays.containsKey(regionHoliday.sked__Region__c)) {
                    mapHolidays.put(regionHoliday.sked__Region__c, regionHolidays);
                }
            }
            return mapHolidays;
        }
    }

    public class skedAdminSetting {
        public decimal adhocDriverSupportCapacity;
        public string bsfSupportEmail;
        public boolean dateTimeConversion;
        public string distanceMeasurementUnit;
        public boolean enableResourceCallOut;
        public boolean enableObjectSync;
        public boolean enableOperationRecordLog;
        public boolean enableResourcePto;
        public boolean enableWorkdayLogging;
        public boolean exavaluIntegration;
        public string fccCodeFixedSite;
        public string fccCodeMobile;
        public boolean geographicPreferences;
        public string jobURL;
        public Integer maxCDLDOTDuration;
        public boolean migrationMode;
        public integer nightlyMaxAutoApprovalRequests;
        public integer numAutoExpireDays;
        public string opsRecordApiUrl;
        public string opsRecordClientSecret;
        public string publicSiteURL;
        public Boolean runOptimizationOnDev;
        public string schedulersGroupEmail;
        public string smsCountryCodeAbbreviation;
        public integer tagExpiryAlertDays;
        public integer optimizationTimeout;
        public integer velocity;
        public boolean opsRecordIntegration;
        public boolean workdayIntegration;
        public integer daysToValidateWorkDaysException;
        public integer rtvAPSApprovalWindow;

        public skedAdminSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.adhocDriverSupportCapacity = setting.sked_Admin_Adhoc_Driver_Support_Capacity__c != NULL ? (decimal)setting.sked_Admin_Adhoc_Driver_Support_Capacity__c : 2.2;
            this.bsfSupportEmail = setting.sked_Admin_BSF_Support_Email__c != NULL ? setting.sked_Admin_BSF_Support_Email__c : 'bsfsupport@redcross.org';
            this.jobURL = setting.sked_Admin_Global_JobURL__c != NULL ? setting.sked_Admin_Global_JobURL__c : '';
            this.dateTimeConversion = setting.sked_Admin_DateTime_Conversion__c;
            this.distanceMeasurementUnit = setting.sked_Admin_Distance_Measurement_Unit__c;
            this.enableResourceCallOut = setting.sked_Admin_Enable_Resource_Call_Out__c ;
            this.enableObjectSync = setting.sked_Admin_Enable_Object_Sync__c;
            this.enableOperationRecordLog = setting.sked_Admin_Enable_Operation_Record_Log__c;
            this.enableResourcePto = setting.sked_Admin_Enable_Resource_PTO__c;
            this.enableWorkdayLogging = setting.sked_Admin_Enable_Workday_Logging__c;
            this.exavaluIntegration = setting.sked_Admin_Exavalu_Integration__c;
            this.fccCodeFixedSite = setting.sked_Admin_FCC_Code_Fixed_Site__c;
            this.fccCodeMobile = setting.sked_Admin_FCC_Code_Mobile__c;
            this.geographicPreferences = TRUE;
            this.maxCDLDOTDuration = setting.sked_Max_CDL_DOT_Duration__c != NULL ? integer.valueOf(setting.sked_Max_CDL_DOT_Duration__c) : 14;
            this.migrationMode = setting.sked_Admin_Migration_Mode__c;
            this.nightlyMaxAutoApprovalRequests = setting.sked_Nightly_Max_Auto_Approval_Requests__c != null ? integer.valueOf(setting.sked_Nightly_Max_Auto_Approval_Requests__c) : 10000;
            this.numAutoExpireDays = setting.sked_Num_Auto_Expire_Days__c != null ? integer.valueOf(setting.sked_Num_Auto_Expire_Days__c) : 10000;
            this.opsRecordApiUrl = setting.sked_Ops_Record_API_URL__c;
            this.opsRecordClientSecret = setting.sked_Ops_Record_Client_Scer__c;
            this.publicSiteURL = setting.sked_Public_Site_URL__c;
            this.runOptimizationOnDev = setting.sked_Run_Optimization_on_Dev__c;
            this.schedulersGroupEmail = setting.sked_Admin_Schedulers_Group_Email__c;
            this.smsCountryCodeAbbreviation = setting.sked_Admin_SMS_Country_Code_Abbreviation__c;
            this.tagExpiryAlertDays = setting.sked_Admin_Tag_Expiry_Alert_Days__c != NULL ? integer.valueOf(setting.sked_Admin_Tag_Expiry_Alert_Days__c) : 60;
            this.optimizationTimeout = setting.sked_Optimization_Timeout__c != NULL ? Integer.valueOf(setting.sked_Optimization_Timeout__c) : 6;
            this.velocity = 30;
            this.opsRecordIntegration = setting.sked_Admin_Ops_Record_Integration__c;
            this.workdayIntegration = setting.sked_Admin_Workday_Integration__c;
            this.daysToValidateWorkDaysException = setting.sked_Admin_Days_To_Validate_Work_Days_Ex__c != NULL ? integer.valueOf(setting.sked_Admin_Days_To_Validate_Work_Days_Ex__c) : 7;
            this.rtvAPSApprovalWindow = setting.sked_RTV_APS_Approval_Window__c != NULL ? integer.valueOf(setting.sked_RTV_APS_Approval_Window__c) : 42;
        }
    }

    public class skedBookingGridSetting extends skedCalendarSettingBase {
        public skedBookingGridSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.firstDay = setting.sked_RAC_First_Day__c != NULL ? integer.valueOf(setting.sked_RAC_First_Day__c) : 0;
            this.viewPeriod = setting.sked_RAC_View_Period__c != NULL ? integer.valueOf(setting.sked_RAC_View_Period__c) : 2;
            this.dateFormat = !string.isBlank(setting.sked_RAC_Date_Format__c) ? setting.sked_RAC_Date_Format__c : 'MM/dd/yyyy';
            this.datePickerFormat = !string.isBlank(setting.sked_RAC_Datepicker_Format__c) ? setting.sked_RAC_Datepicker_Format__c : 'D, mm/dd/yy';
            this.noOfRecurWeeks = setting.sked_RAC_No_of_Recur_Weeks__c != NULL ? integer.valueOf(setting.sked_RAC_No_of_Recur_Weeks__c) : 10;
            this.calendarStart = setting.sked_RAC_Calendar_Start__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Start__c) : 700;
            this.calendarEnd = setting.sked_RAC_Calendar_End__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_End__c) : 1900;
            this.calendarStep = setting.sked_RAC_Calendar_Step__c != NULL ? integer.valueOf(setting.sked_RAC_Calendar_Step__c) : 30;
        }
    }
    
    public class skedEcSetting {
        public integer daysToValidate;
        
        public skedEcSetting() {
            sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
            this.daysToValidate = setting.sked_EC_Days_to_Validate__c != NULL ? integer.valueOf(setting.sked_EC_Days_to_Validate__c) : 30;
        }
    }
    
    public class skedEmailSetting {
        public string apsDirectors;
        public string bhqApsStaffSchedulingManagers;
        public string bhqApsStaffSchedulingTimekeeping;
        public string bhqCollectionsPlanningScheduling;
        public string bitTechnicalSupport;
        public string oppDOCSyncErrorEmail;
        
        public skedEmailSetting() {
            sked_Email_Setting__c setting = sked_Email_Setting__c.getOrgDefaults();
            this.apsDirectors = setting.sked_APS_Directors__c;
            this.bhqApsStaffSchedulingTimekeeping = setting.sked_BHQ_APS_Staff_SchedulingTimekeeping__c;
            this.bhqApsStaffSchedulingManagers = setting.sked_BHQ_APS_Staff_Scheduling_Managers__c;
            this.bhqCollectionsPlanningScheduling = setting.sked_BHQ_Collections_Planning_Scheduling__c;
            this.bitTechnicalSupport = setting.sked_BIT_Technical_Support__c;
            this.oppDOCSyncErrorEmail = setting.sked_Opp_DOC_Sync_Error_Email__c;
        }
    }

    public class skedLacSetting extends skedCalendarSettingBase {
        public transient Map<string, skedModels.eventTypeSetting> colorMap;

        public skedLacSetting() {
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
            this.showLegend = setting.sked_LAC_Show_Legend__c;

            List<string> objectTypes = new List<string>();
            objectTypes.add('locationAvailability');
            objectTypes.add('job');
            this.mapShiftTypeSetting = getMapShiftTypeSetting(objectTypes);
        }
    }
    
    public class skedNotificationManager {
        public boolean notificationGenerationEnabled;

        public skedNotificationManager() {
            sked_Notification_Manager__c setting = sked_Notification_Manager__c.getOrgDefaults();
            this.notificationGenerationEnabled = setting.sked_Notification_Generation_Enabled__c;
        }
    }

    public class skedPacSetting extends skedCalendarSettingBase {
        public integer defaultDuration;
        public integer startWorkingTime;
        public transient Map<string, skedModels.eventTypeSetting> colorMap;

        public skedPacSetting() {
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
            objectTypes.add('job');
            this.mapShiftTypeSetting = getMapShiftTypeSetting(objectTypes);

            //Default duration and start time for event creation
            this.defaultDuration = this.calendarStep;
            this.startWorkingTime = this.calendarStart;
        }
    }

    public class skedRacSetting extends skedCalendarSettingBase {
        public boolean autoApproveAvailability;
        public Integer autoApprovalCutoffDays;
        public boolean enableActivity;
        public boolean enableAvailabilityTemplate;
        public boolean respectResourceTimezone;
        public Integer maxActivityRecurringYears;
        public Integer staffingBudgetChunkSize;

        public skedRacSetting() {
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
            this.autoApproveAvailability = setting.sked_RAC_Auto_Approve_Availability__c;
            this.autoApprovalCutoffDays = setting.sked_RAC_Auto_Approval_Cutoff_Days__c != NULL ? integer.valueOf(setting.sked_RAC_Auto_Approval_Cutoff_Days__c) : 30;
            this.enableActivity = setting.sked_RAC_Enable_Activity__c;
            this.enableAvailabilityTemplate = setting.sked_RAC_Enable_Availability_Template__c;
            this.respectResourceTimezone = setting.sked_RAC_Respect_Resource_Timezone__c;
            this.showLegend = setting.sked_RAC_Show_Legend__c;
            this.maxActivityRecurringYears = Integer.valueOf(setting.sked_RAC_Max_Activity_Recurring_Years__c);
            this.staffingBudgetChunkSize = Integer.valueOf(setting.sked_RAC_SB_Chunk_Size__c);
            
            List<string> objectTypes = new List<string>();
            objectTypes.add('availability');
            objectTypes.add('activity');
            objectTypes.add('job');
            objectTypes.add('customAvailability');
            this.mapShiftTypeSetting = getMapShiftTypeSetting(objectTypes);
            this.filters = getUserFilters();
        }
    }
    
    public class skedTravelTimeManager {
        public integer driveImpactThreshold;
        public integer numberOfParallelRequests;
        public integer refreshInterval;
        public integer newIndexPriority;
        public integer manualRefreshPriority;
        public boolean enableManualRefreshBanner;
        public integer maxTravelTimeIndexItemsForPeriodicRefresh;
        public integer coGroupIndexRefreshPriority;
        public string travelTimeRefreshEndpoint;
        
        public skedTravelTimeManager() {
            sked_Travel_Time_Manager__c setting = sked_Travel_Time_Manager__c.getOrgDefaults();
            this.driveImpactThreshold = setting.sked_Drive_Impact_Threshold__c != NULL ? integer.valueOf(setting.sked_Drive_Impact_Threshold__c) : 15;
            this.numberOfParallelRequests = setting.sked_Number_of_Parallel_Requests__c != NULL ? integer.valueOf(setting.sked_Number_of_Parallel_Requests__c) : 4;
            this.refreshInterval = setting.sked_Refresh_Interval__c != NULL ? integer.valueOf(setting.sked_Refresh_Interval__c) : 180;
            this.newIndexPriority = setting.sked_New_Index_Priority__c != NULL ? integer.valueOf(setting.sked_New_Index_Priority__c) : 1000;
            this.manualRefreshPriority = setting.sked_Manual_Refresh_Priority__c != NULL ? integer.valueOf(setting.sked_Manual_Refresh_Priority__c) : 1000;
            this.enableManualRefreshBanner = setting.sked_Enable_Manual_Refresh_Banner__c;
            this.maxTravelTimeIndexItemsForPeriodicRefresh = setting.sked_Max_TTI_Items_For_Periodic_Refresh__c != NULL ? integer.valueOf(setting.sked_Max_TTI_Items_For_Periodic_Refresh__c) : 10000;
            this.coGroupIndexRefreshPriority = setting.sked_CO_Group_Index_Refresh_Priority__c != NULL ? integer.valueOf(setting.sked_CO_Group_Index_Refresh_Priority__c) : 1000;
            this.travelTimeRefreshEndpoint = setting.sked_TTI_Refresh_Endpoint__c;
        }
    }

    public class skedTTIRRStuckJobConfigSetting {
        public Boolean enableAutoReschedule;
        public Boolean isActive;
        public Decimal maxRetries;
        public Decimal stuckThresholdMins;
        public Decimal rescheduleIntervalMins;

        public skedTTIRRStuckJobConfigSetting() {
            sked_TTIRR_Stuck_Job_Config_Setting__c setting = sked_TTIRR_Stuck_Job_Config_Setting__c.getOrgDefaults();
            this.enableAutoReschedule = setting.sked_Enable_Auto_Reschedule__c;
            this.isActive = setting.sked_Is_Active__c;
            this.maxRetries = setting.sked_Maximum_Retries__c;
            this.stuckThresholdMins = setting.sked_Stuck_Threshold_Minutes__c;
            this.rescheduleIntervalMins = setting.sked_Reschedule_Interval_Minutes__c;
        } 
    }

    public class skedJAPostProcessBatchConfigSetting {
        public integer maxRetries;
        public integer allowedNumberOfJobsInFlexQueue;
        public integer rescheduleIntervalSeconds;

        public skedJAPostProcessBatchConfigSetting() {
            sked_JA_Post_Process_Config__c setting = sked_JA_Post_Process_Config__c.getOrgDefaults();
            this.allowedNumberOfJobsInFlexQueue = setting.sked_Allowed_No_of_Jobs_in_Flex_Queue__c.intValue();
            this.maxRetries = setting.sked_Allowed_Maximum_Retries__c.intValue();
            this.rescheduleIntervalSeconds = setting.sked_Reschedule_Interval_Sec_Flex_Queue__c.intValue();
        } 
    }

    /*********************************************************** Abstract Classes ***********************************************************/
    public abstract class skedCalendarSettingBase {
        public integer firstDay;
        public integer viewPeriod;
        public string dateFormat;
        public string datePickerFormat;
        public string weekPickerFormat;
        public string monthPickerFormat;
        public integer noOfRecurWeeks;
        public integer calendarStart;
        public integer calendarEnd;
        public integer calendarStep;
        public boolean showLegend;
        public List<skedModels.userFilter> filters;
        public transient Map<string, skedModels.eventTypeSetting> mapShiftTypeSetting;

        protected Map<string, skedModels.eventTypeSetting> getMapShiftTypeSetting(List<string> objectTypes) {
            Map<string, skedModels.eventTypeSetting> results = new Map<string, skedModels.eventTypeSetting>();
            List<sked_Event_Type_Setting__c> skedShiftTypeSettings = [SELECT Id, sked_Item__c, sked_Available_Start__c, sked_Available_End__c,
                                                                        sked_Background_Color__c, sked_Can_Be_Pre_dated__c, sked_Color__c,
                                                                        sked_Short_Name__c, sked_Step__c, sked_Is_Available__c, sked_Show_Legend__c,
                                                                        sked_Category__c, sked_Integrated_with_Workday__c
                                                                        FROM sked_Event_Type_Setting__c
                                                                        WHERE sked_Is_Active__c = TRUE
                                                                        AND sked_Category__c IN :objectTypes];
            if (skedShiftTypeSettings != NULL && skedShiftTypeSettings.size() > 0) {
                for (sked_Event_Type_Setting__c skedShiftTypeSetting : skedShiftTypeSettings) {
                    skedModels.eventTypeSetting model = new skedModels.eventTypeSetting();
                    model.id = skedShiftTypeSetting.Id;
                    model.eventType = skedShiftTypeSetting.sked_Item__c;
                    model.availableStart = integer.valueOf(skedShiftTypeSetting.sked_Available_Start__c);
                    model.availableEnd = integer.valueOf(skedShiftTypeSetting.sked_Available_End__c);
                    model.backgroundColor = skedShiftTypeSetting.sked_Background_Color__c;
                    model.canBePreDated = skedShiftTypeSetting.sked_Can_Be_Pre_dated__c;
                    model.color = skedShiftTypeSetting.sked_Color__c;
                    model.shortName = skedShiftTypeSetting.sked_Short_Name__c;
                    model.isAvailable = skedShiftTypeSetting.sked_Is_Available__c;
                    model.objectType = skedShiftTypeSetting.sked_Category__c;
                    model.step = integer.valueOf(skedShiftTypeSetting.sked_Step__c);
                    model.showLegend = skedShiftTypeSetting.sked_Show_Legend__c;
                    model.integratedWithWorkday = skedShiftTypeSetting.sked_Integrated_with_Workday__c;
                    results.put(model.objectType + ':' + model.eventType, model);
                }
            }
            return results;
        }

        protected Map<string, skedModels.displaySetting> getMapdisplaySetting(string category) {
            Map<string, skedModels.displaySetting> results = new Map<string, skedModels.displaySetting>();
            List<sked_Event_Type_Setting__c> skedShiftTypeSettings = [SELECT Id, sked_Item__c, sked_Background_Color__c,
                                                                        sked_Color__c, sked_Show_Legend__c
                                                                        FROM sked_Event_Type_Setting__c
                                                                        WHERE sked_Is_Active__c = TRUE
                                                                        AND sked_Category__c = :category];
            if (skedShiftTypeSettings != NULL && skedShiftTypeSettings.size() > 0) {
                for (sked_Event_Type_Setting__c skedShiftTypeSetting : skedShiftTypeSettings) {
                    skedModels.displaySetting model = new skedModels.displaySetting();
                    model.id = skedShiftTypeSetting.Id;
                    model.backgroundColor = skedShiftTypeSetting.sked_Background_Color__c;
                    model.color = skedShiftTypeSetting.sked_Color__c;
                    model.showLegend = skedShiftTypeSetting.sked_Show_Legend__c;
                    results.put(skedShiftTypeSetting.sked_Item__c, model);
                }
            }
            return results;
        }
        
        protected List<skedModels.userFilter> getUserFilters() {
            List<skedModels.userFilter> result = new List<skedModels.userFilter>();
            List<sked_User_Filter__c> skedUserFilters = [SELECT Id, sked_User__c, sked_JSON_Data__c, sked_Category__c
                                                         FROM sked_User_Filter__c
                                                         WHERE sked_User__c = :UserInfo.getUserId()];
            for (sked_User_Filter__c filter : skedUserFilters) {
                skedModels.userFilter model = new skedModels.userFilter();
                model.id = filter.Id;
                model.category = filter.sked_Category__c;
                model.userId = filter.sked_User__c;
                model.jsonData = filter.sked_JSON_Data__c;
                result.add(model);
            }
            return result;
        }
    }

}