public class skedResourceOverrideUtils {
    public static List<sked__Job_Allocation__c> getJobAllocationsForOverrides(Map<Id, skedModels.startEnd> modelsByResource) {
        List<sked__Job_Allocation__c> jobAllocations = new List<sked__Job_Allocation__c>();

        if (!modelsByResource.keySet().isEmpty()) {
            skedQueryBuilder queryBuilder = new skedQueryBuilder();
            queryBuilder.setFromClause('sked__Job_Allocation__c');
            queryBuilder.addFields(new List<String>{'Id', 'sked__Resource__c', 'sked__Job__c'});
            queryBuilder.setIsOrQuery(true);

            String statusCondition = queryBuilder.generateCondition('sked__Status__c NOT IN {0}', new List<String>{
                skedConstants.JOB_ALLOCATION_STATUS_DECLINED,
                skedConstants.JOB_ALLOCATION_STATUS_DELETED
            });

            for (Id resourceId : modelsByResource.keySet()) {
                skedModels.startEnd model = modelsByResource.get(resourceId);
                String resourceCondition = queryBuilder.generateCondition('sked__Resource__c = {0}', resourceId);
                String startDateCondition = queryBuilder.generateCondition('sked_Start_Date__c >= {0}', model.startDate);
                String endDateCondition = queryBuilder.generateCondition('sked_Start_Date__c <= {0}', model.endDate);
                queryBuilder.addConditionGroup(new List<String>{resourceCondition, startDateCondition, endDateCondition, statusCondition});
            }

            jobAllocations.addAll((List<sked__Job_Allocation__c>) Database.query(queryBuilder.toString()));
        }

        return jobAllocations;
    }
}