public with sharing class skedAvailabilityPatternResourceService extends skedDataService {

    protected override void initialize() {
        this.sObjectApiName = 'sked__Availability_Pattern_Resource__c';
        this.objectType = 'availabilityPatternResource';
        this.domainType = Type.forName('skedModels.availabilityPatternResource');
    }

    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        Date startDate = String.isBlank(query.startDate) == false ? skedDateTimeUtils.getDateFromIsoString(query.startDate) : skedDateTimeUtils.MIN_DATE;
        Date endDate = String.isBlank(query.endDate) == false ? skedDateTimeUtils.getDateFromIsoString(query.endDate) : skedDateTimeUtils.MAX_DATE;

        if (query.availabilityPatternIds != NULL && !query.availabilityPatternIds.isEmpty()) {
            queryBuilder.addCondition('sked__Availability_Pattern__c IN {0}', query.availabilityPatternIds);
        }
        queryBuilder.addCondition('(sked_Start_Date__c = NULL OR sked_Start_Date__c <= {0})', endDate);
        queryBuilder.addCondition('(sked_End_Date__c = NULL OR sked_End_Date__c >= {0})', startDate);
    }

    public List<string> getResourceIds(queryModel query) {
        List<sked__Availability_Pattern_Resource__c> skedPatternResources = (List<sked__Availability_Pattern_Resource__c>) query(query);
        Set<String> resourceIds = new Set<String>();
        for (sked__Availability_Pattern_Resource__c skedPatternResource : skedPatternResources) {
            resourceIds.add(skedPatternResource.sked__Resource__c);
        }
        List<String> resourceIdsList = new List<String>();
        resourceIdsList.addAll(resourceIds);
        return resourceIdsList;
    }

    public class queryModel extends skedEventService.queryModel {
        public List<string> availabilityPatternIds;
    }

}