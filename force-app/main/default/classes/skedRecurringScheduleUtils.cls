public class skedRecurringScheduleUtils implements callable {

    public static void publishUpdateAvailabilityCountEvent(List<sked__Availability__c> availabilities) {
        Set<Id> recurringScheduleIds = new Set<Id>();

        for (sked__Availability__c avail : availabilities) {
            if (avail.sked_Recurring_Schedule__c != null) {
                recurringScheduleIds.add(avail.sked_Recurring_Schedule__c);
            }
        }

        if (!recurringScheduleIds.isEmpty()) {
            skedFutureCallEventHandler.publishFutureCallEvent('skedRecurringScheduleUtils', 'updateAvailabilityCount', recurringScheduleIds);   
        }
    }
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'updateAvailabilityCount' {
                    updateAvailabilityCount((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedAvailabilityHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }
        return result;
    }

    public static void updateAvailabilityCount(Set<Id> recurringScheduleIds) {
        List<sked__Recurring_Schedule__c> recurringSchedules = [
            SELECT Id, sked_Availability_Count__c,
            (SELECT Id, sked__Status__c FROM sked_Availabilities__r)
            FROM sked__Recurring_Schedule__c
            WHERE Id IN :recurringScheduleIds
        ];

        Set<String> cancelledStatuses = new Set<String>{skedConstants.AVAILABILITY_STATUS_DECLINED, skedConstants.AVAILABILITY_STATUS_CANCELLED};
        for (sked__Recurring_Schedule__c recurringSchedule : recurringSchedules) {
            Integer availabilityCount = 0;
            for (sked__Availability__c availability : recurringSchedule.sked_Availabilities__r) {
                if (!cancelledStatuses.contains(availability.sked__Status__c)) {
                    availabilityCount++;
                }
            }
            recurringSchedule.sked_Availability_Count__c = availabilityCount;
        }

        update recurringSchedules;
    }


}