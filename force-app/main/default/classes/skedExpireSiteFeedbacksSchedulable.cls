public class skedExpireSiteFeedbacksSchedulable implements Schedulable {
    public void execute(SchedulableContext SC) {
        Set<String> siteFeedbackExcludedStatuses = new Set<String>{
            skedConstants.RTV_FEEDBACK_STATUS_APPROVED,
            skedConstants.RTV_FEEDBACK_STATUS_REJECTED,
            skedConstants.RTV_FEEDBACK_STATUS_EXPIRED
        };

        List<sked_Site_Feedback__c> feedbacks = [
            SELECT Id, sked_Status__c
            FROM sked_Site_Feedback__c
            WHERE sked_Status__c NOT IN :siteFeedbackExcludedStatuses
            AND (sked_Effective_End_Date__c < TODAY)
        ];

        for (sked_Site_Feedback__c feedback : feedbacks) {
            feedback.sked_Status__c = skedConstants.RTV_FEEDBACK_STATUS_EXPIRED;
        }

        update feedbacks;
    }
}