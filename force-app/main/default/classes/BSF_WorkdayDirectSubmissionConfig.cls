/**
 * Reads Workday Direct Submission config from BSF_Workday_Direct_Submission_Config__mdt.
 * Uses first available record; if none or Enable = false, direct submission is disabled.
 */
public with sharing class BSF_WorkdayDirectSubmissionConfig {
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_PROCESSED = 'Processed';
    public static final String STATUS_PARTIAL = 'Failed'; // maintained for backward compatibility; we now treat Failed as the retryable state
    public static final String STATUS_FAILED = 'Failed';
    public static final String STAFF_STATUS_PENDING = 'Pending';
    public static final String STAFF_STATUS_SUCCESS = 'Success';
    public static final String STAFF_STATUS_FAILED = 'Failed';

    private static BSF_Workday_Direct_Submission_Config__mdt cachedConfig;

    /**
     * Returns the first Workday Direct Submission Config record, or null if none.
     */
    public static BSF_Workday_Direct_Submission_Config__mdt getConfig() {
        if (cachedConfig != null) {
            return cachedConfig;
        }
        List<BSF_Workday_Direct_Submission_Config__mdt> configs = [
            SELECT Id, DeveloperName,
                sked_Enable_Direct_Workday_Submission__c,
                sked_WD_Emp_Rpt_URL__c,
                sked_WD_Start_Date_Param__c,
                sked_WD_End_Date_Param__c,
                sked_WD_Worker_Param__c,
                sked_WD_Import_Blocks_URL__c,
                sked_Technical_Team_Distribution_List__c,
                sked_Workday_Max_Retry_Attempts__c,
                sked_Notification_From_Email__c,
                sked_Business_Distribution_List__c,
                sked_Reschedule_Delay_Minutes__c
            FROM BSF_Workday_Direct_Submission_Config__mdt
            LIMIT 1
        ];
        cachedConfig = configs.isEmpty() ? null : configs[0];
        return cachedConfig;
    }

    public static Boolean isDirectWorkdayEnabled() {
        BSF_Workday_Direct_Submission_Config__mdt config = getConfig();
        return config != null && config.sked_Enable_Direct_Workday_Submission__c == true;
    }

    /** Max retry attempts per staff (default 3). */
    public static Integer getMaxRetryAttempts() {
        BSF_Workday_Direct_Submission_Config__mdt config = getConfig();
        if (config == null || config.sked_Workday_Max_Retry_Attempts__c == null) {
            return 3;
        }
        return config.sked_Workday_Max_Retry_Attempts__c.intValue();
    }

    /** Delay in minutes before rescheduling the batch when finish() has errors. Default 15. */
    public static Integer getRescheduleDelayMinutes() {
        BSF_Workday_Direct_Submission_Config__mdt config = getConfig();
        if (config == null || config.sked_Reschedule_Delay_Minutes__c == null) {
            return 15;
        }
        return config.sked_Reschedule_Delay_Minutes__c.intValue();
    }

}