public class skedActivityResourceUtils {
    
    public static List<sked__Availability__c> getAvailabilityRecordsForOnCalls(List<sked__Activity_Resource__c> activityResources) {
        skedQueryBuilder queryBuilder = new skedQueryBuilder();
        queryBuilder.setFromClause('sked__Availability__c');
        queryBuilder.addFields(new List<String>{'Id', 'sked__Resource__c', 'sked__Start__c', 'sked__Finish__c'});
        queryBuilder.setIsOrQuery(true);

        for (sked__Activity_Resource__c activityResource : activityResources) {
            String resourceCondition = queryBuilder.generateCondition('sked__Resource__c = {0}', activityResource.sked__Resource__c);
            String startDateCondition = queryBuilder.generateCondition('sked__Start__c = {0}', activityResource.sked_Start1__c);
            String endDateCondition = queryBuilder.generateCondition('sked__Finish__c = {0}', activityResource.sked_End__c);
            String isOnCallCondition = queryBuilder.generateCondition('sked__Type__c = {0}', skedConstants.AVAILABILITY_TYPE_ON_CALL);
            queryBuilder.addConditionGroup(new List<String>{resourceCondition, startDateCondition, endDateCondition, isOnCallCondition});
        }

        return Database.query(queryBuilder.toString());
    }
    
}