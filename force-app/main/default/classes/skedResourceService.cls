global class skedResourceService extends skedDataService {

    public override void initialize() {
        this.sObjectApiName = 'sked__Resource__c';
        this.objectType = 'resource';
        this.domainType = Type.forName('skedModels.resource');
    }

    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        Date startDate, endDate, additionalFilterOnDate;
        if (!string.isBlank(query.startDate)) {
            startDate = skedDateTimeUtils.getDateFromIsoString(query.startDate);
        }
        if (!string.isBlank(query.endDate)) {
            endDate = skedDateTimeUtils.getDateFromIsoString(query.endDate);
        }
        if (!string.isBlank(query.additionalFilterOnDate)) {
            additionalFilterOnDate = skedDateTimeUtils.getDateFromIsoString(query.additionalFilterOnDate);
        }

        string assignmentResourceCoCondition;
        if (query.biomedCollectionOpIds != NULL && !query.biomedCollectionOpIds.isEmpty()) {
            string biomedCollectionOpCondition = queryBuilder.generateCondition('sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN {0}', query.biomedCollectionOpIds);
            assignmentResourceCoCondition = queryBuilder.generateCondition('sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN {0}', query.biomedCollectionOpIds);
            
            //secondary biomed collection ops
            skedResourceRegionService resourceRegionService = (skedResourceRegionService)skedServiceFactory.instance.resolve('sked__Resource_Region__c');
            skedResourceRegionService.queryModel resourceRegionQuery = new skedResourceRegionService.queryModel();
            resourceRegionQuery.biomedCollectionOpIds = query.biomedCollectionOpIds;
            if (query.startDate != NULL && query.endDate != NULL) {
                resourceRegionQuery.startTime = startDate;
                resourceRegionQuery.endTime = endDate;
            }
            
            List<string> secondaryCOResourceIds = resourceRegionService.getResourceIds(resourceRegionQuery);
            
            //temporary CO
            skedResourceOverrideService resourceOverrideService = (skedResourceOverrideService)skedServiceFactory.instance.resolve('sked__Resource_Override__c');
            skedResourceOverrideService.queryModel resourceOverrideQuery = new skedResourceOverrideService.queryModel();
            resourceOverrideQuery.biomedCollectionOpIds = query.biomedCollectionOpIds;
            if (query.startDate != NULL && query.endDate != NULL) {
                resourceOverrideQuery.startDate = startDate;
                resourceOverrideQuery.endDate = endDate;
            }
            
            List<string> temporaryCOResourceIds = resourceOverrideService.getResourceIds(resourceOverrideQuery);
            
            List<string> predefinedResourceIds = new List<string>();
            if (!secondaryCOResourceIds.isEmpty()) {
                predefinedResourceIds.addAll(secondaryCOResourceIds);
            }
            if (!temporaryCOResourceIds.isEmpty()) {
                predefinedResourceIds.addAll(temporaryCOResourceIds);
            }
            
            if (!predefinedResourceIds.isEmpty()) {
                string additionalResourceIdsCondition = queryBuilder.generateCondition('Id IN {0}', predefinedResourceIds);
                biomedCollectionOpCondition = '(' + biomedCollectionOpCondition + ' OR ' + additionalResourceIdsCondition + ')';

                string additionalResourceIdsConditionForAssignment = queryBuilder.generateCondition('sked__Resource__c IN {0}', predefinedResourceIds);
                assignmentResourceCoCondition = '(' + assignmentResourceCoCondition + ' OR ' + additionalResourceIdsCondition + ')';
            }
            queryBuilder.conditions.add(biomedCollectionOpCondition);
        }
        if (query.regionIds != NULL && !query.regionIds.isEmpty()) {
            string regionCondition = queryBuilder.generateCondition('sked__Primary_Region__c IN {0}', query.regionIds);
            
            skedResourceRegionService resourceRegionService = (skedResourceRegionService)skedServiceFactory.instance.resolve('sked__Resource_Region__c');
            skedResourceRegionService.queryModel resourceRegionQuery = new skedResourceRegionService.queryModel();
            resourceRegionQuery.regionIds = query.regionIds;
            //resourceRegionQuery.startTime = query.startTime;
            //resourceRegionQuery.endTime = query.endTime;
            
            List<string> resourceIds = resourceRegionService.getResourceIds(resourceRegionQuery);
            if (!resourceIds.isEmpty()) {
                string secondRegionCondition = queryBuilder.generateCondition('Id IN {0}', resourceIds);
                regionCondition = '(' + regionCondition + ' OR ' + secondRegionCondition + ')';
            }
            queryBuilder.conditions.add(regionCondition);
        }
        if (query.patternIds != NULL && !query.patternIds.isEmpty()) {
            skedAvailabilityPatternResourceService patternResourceService = (skedAvailabilityPatternResourceService) skedServiceFactory.instance.resolve('sked__Availability_Pattern_Resource__c');
            skedAvailabilityPatternResourceService.queryModel patternResourceQuery = new skedAvailabilityPatternResourceService.queryModel();
            patternResourceQuery.availabilityPatternIds = query.patternIds;
            patternResourceQuery.startDate = query.startDate;
            patternResourceQuery.endDate = query.endDate;
            
            List<String> resourceIds = patternResourceService.getResourceIds(patternResourceQuery);
            string patternCondition = 'Id = NULL';
            if (!resourceIds.isEmpty()) {
                patternCondition = queryBuilder.generateCondition('Id IN {0}', resourceIds);
            }
            queryBuilder.conditions.add(patternCondition);
        }
        if (query.resourceTypes != NULL && !query.resourceTypes.isEmpty()) {
            queryBuilder.addCondition('sked__Resource_Type__c IN {0}', query.resourceTypes);
        }
        if (query.employmentTypes != NULL && !query.employmentTypes.isEmpty()) {
            queryBuilder.addCondition('(sked__Resource_Type__c = \'Asset\' OR (sked__Resource_Type__c = \'Person\' AND sked__Employment_Type__c IN {0}))', query.employmentTypes);
        }
        if (query.categories != NULL && !query.categories.isEmpty()) {
            queryBuilder.addCondition('sked__Category__c IN {0}', query.categories);
        }

        List<String> matchingTagResourceIds = new List<String>();
        if (query.tagIds != NULL && !query.tagIds.isEmpty()) {
            integer noOfRequiredTags = query.tagIds.size();

            skedQueryBuilder resourceTagQueryBuilder = new skedQueryBuilder();
            resourceTagQueryBuilder.setFromClause('sked__Resource_Tag__c');
            resourceTagQueryBuilder.setGroupBy('sked__Resource__c');

            resourceTagQueryBuilder.addField('sked__Resource__c resourceId');
            resourceTagQueryBuilder.addField('COUNT(sked__Tag__c) noOfTags');

            resourceTagQueryBuilder.addCondition('sked__Tag__c IN {0}', query.tagIds);
            if (query.tagExpiry != NULL) {
                resourceTagQueryBuilder.addCondition('(sked_Expiry_Date__c = NULL OR sked_Expiry_Date__c >= {0})', query.tagExpiry);
            }

            if (query?.activeTagsOnly == true) {
                resourceTagQueryBuilder.addCondition('sked_Role_Status__c = {0}', skedConstants.TAG_ROLE_STATUS_ACTIVE);
            }

            query.predefinedRecordIds = new List<String>();

            List<AggregateResult> aggregateResults = Database.query(resourceTagQueryBuilder.toString());
            for (AggregateResult result : aggregateResults) {
                string resourceId = (string)result.get('resourceId');
                integer noOfTags = (integer)result.get('noOfTags');
                if (query.matchAllSelectedTags != null && query.matchAllSelectedTags && noOfTags != noOfRequiredTags) {
                    continue;
                }
                matchingTagResourceIds.add(resourceId);
            }
        }

        List<String> availabilityAndActivityResourceIds;
        if (query.availabilityTypes != null && !query.availabilityTypes.isEmpty()) {
            skedQueryBuilder availabilityQueryBuilder = new skedQueryBuilder();
            availabilityQueryBuilder.setFromClause('sked__Availability__c');
            availabilityQueryBuilder.setGroupBy('sked__Resource__c');

            availabilityQueryBuilder.addField('sked__Resource__c resourceId');
            availabilityQueryBuilder.addField('COUNT(Id) numAvailabilities');

            availabilityQueryBuilder.addCondition('sked__Type__c IN {0}', query.availabilityTypes);
            availabilityQueryBuilder.addCondition('sked__Type__c NOT IN {0}', query.excludedAvailabilityTypes);
            availabilityQueryBuilder.addCondition('sked_Start_Date__c <= {0}', endDate);
            availabilityQueryBuilder.addCondition('sked_Finish_Date__c >= {0}', startDate);

            if (!matchingTagResourceIds.isEmpty()) {
                availabilityQueryBuilder.addCondition('sked__Resource__c IN {0}', matchingTagResourceIds);
            }

            availabilityAndActivityResourceIds = new List<String>();
            query.predefinedRecordIds = new List<String>();
            
            List<AggregateResult> aggregateResults = Database.query(availabilityQueryBuilder.toString());
            for (AggregateResult result : aggregateResults) {
                String resourceId = (String) result.get('resourceId');
                Integer numAvailabilities = (Integer) result.get('numAvailabilities');
                if (numAvailabilities > 0) {
                    availabilityAndActivityResourceIds.add(resourceId);
                }
            }
        }

        if (query.activityTypes != null && !query.activityTypes.isEmpty()) {
            skedQueryBuilder activityQueryBuilder = new skedQueryBuilder();
            activityQueryBuilder.setFromClause('sked__Activity_Resource__c');
            activityQueryBuilder.setGroupBy('sked__Resource__c');

            activityQueryBuilder.addField('sked__Resource__c resourceId');
            activityQueryBuilder.addField('COUNT(Id) numActivities');

            activityQueryBuilder.addCondition('sked__Activity__r.sked__Type__c IN {0}', query.activityTypes);
            activityQueryBuilder.addCondition('sked__Activity__r.sked_Start_Date__c <= {0}', endDate);
            activityQueryBuilder.addCondition('sked__Activity__r.sked_End_Date__c >= {0}', startDate);

            if (!matchingTagResourceIds.isEmpty()) {
                activityQueryBuilder.addCondition('sked__Resource__c IN {0}', matchingTagResourceIds);
            }

            if (availabilityAndActivityResourceIds == null) {
                availabilityAndActivityResourceIds = new List<String>();
            }
            query.predefinedRecordIds = new List<String>();
            
            List<AggregateResult> aggregateResults = Database.query(activityQueryBuilder.toString());
            for (AggregateResult result : aggregateResults) {
                String resourceId = (String) result.get('resourceId');
                Integer numActivities = (Integer) result.get('numActivities');
                if (numActivities > 0) {
                    availabilityAndActivityResourceIds.add(resourceId);
                }
            }
        }

        List<String> temporaryResourceIds;
        if (query.hasTemporaryRelocation == true && additionalFilterOnDate != null) {
            skedQueryBuilder resourceOverrideQueryBuilder = new skedQueryBuilder();
            resourceOverrideQueryBuilder.setFromClause('sked__Resource_Override__c');
            resourceOverrideQueryBuilder.setGroupBy('sked__Resource__c');

            resourceOverrideQueryBuilder.addField('sked__Resource__c resourceId');
            resourceOverrideQueryBuilder.addField('COUNT(Id) numOverrides');

            resourceOverrideQueryBuilder.addCondition('sked_End_Date__c >= {0}', additionalFilterOnDate);
            resourceOverrideQueryBuilder.addCondition('sked_Start_Date__c <= {0}', additionalFilterOnDate);

            if (!matchingTagResourceIds.isEmpty()) {
                resourceOverrideQueryBuilder.addCondition('sked__Resource__c IN {0}', matchingTagResourceIds);
            }
            if (availabilityAndActivityResourceIds != NULL && !availabilityAndActivityResourceIds.isEmpty()) {
                resourceOverrideQueryBuilder.addCondition('sked__Resource__c IN {0}', availabilityAndActivityResourceIds);
            }

            temporaryResourceIds = new List<String>();
            query.predefinedRecordIds = new List<String>();

            List<AggregateResult> aggregateResults = Database.query(resourceOverrideQueryBuilder.toString());
            for (AggregateResult result : aggregateResults) {
                String resourceId = (String) result.get('resourceId');
                Integer numOverrides = (Integer) result.get('numOverrides');
                if (numOverrides > 0) {
                    temporaryResourceIds.add(resourceId);
                }
            }
        }

        if (query.predefinedRecordIds != null) {
            if (temporaryResourceIds != null) {
                query.predefinedRecordIds.addAll(temporaryResourceIds);
            } 
            else if (availabilityAndActivityResourceIds != null) {
                query.predefinedRecordIds.addAll(availabilityAndActivityResourceIds);
            } 
            else if (!matchingTagResourceIds.isEmpty()) {
                query.predefinedRecordIds.addAll(matchingTagResourceIds);
            }
        }

        if (query.hasNoAssignment == true) {
            Set<Id> resourceIdsHaveAssignment = new Set<Id>();

            skedQueryBuilder jobAllocationQueryBuilder = new skedQueryBuilder();
            jobAllocationQueryBuilder.setFromClause('sked__Job_Allocation__c');
            jobAllocationQueryBuilder.setGroupBy('sked__Resource__c');

            jobAllocationQueryBuilder.addField('sked__Resource__c resourceId');
            jobAllocationQueryBuilder.addField('COUNT(Id) numAllocations');

            jobAllocationQueryBuilder.addCondition('sked_Start_Date__c <= {0}', additionalFilterOnDate);
            jobAllocationQueryBuilder.addCondition('sked_Set_End_Date__c >= {0}', additionalFilterOnDate);
            jobAllocationQueryBuilder.addCondition('sked__Status__c != {0}', skedConstants.JOB_ALLOCATION_STATUS_DELETED);

            if (query.predefinedRecordIds != null && !query.predefinedRecordIds.isEmpty()) {
                jobAllocationQueryBuilder.addCondition('sked__Resource__c IN {0}', query.predefinedRecordIds);
            }
            else {
                jobAllocationQueryBuilder.addCondition(assignmentResourceCoCondition);
            }

            List<AggregateResult> jaAggregateResults = Database.query(jobAllocationQueryBuilder.toString());
            for (AggregateResult result : jaAggregateResults) {
                String resourceId = (String) result.get('resourceId');
                Integer numAllocations = (Integer) result.get('numAllocations');
                if (numAllocations > 0) {
                    resourceIdsHaveAssignment.add(resourceId);
                }
            }

            skedQueryBuilder activityResourceQueryBuilder = new skedQueryBuilder();
            activityResourceQueryBuilder.setFromClause('sked__Activity_Resource__c');
            activityResourceQueryBuilder.setGroupBy('sked__Resource__c');

            activityResourceQueryBuilder.addField('sked__Resource__c resourceId');
            activityResourceQueryBuilder.addField('COUNT(Id) numActivity');

            activityResourceQueryBuilder.addCondition('sked_Start_Date__c <= {0}', additionalFilterOnDate);
            activityResourceQueryBuilder.addCondition('sked_End_Date__c >= {0}', additionalFilterOnDate);

            if (query.predefinedRecordIds != null && !query.predefinedRecordIds.isEmpty()) {
                activityResourceQueryBuilder.addCondition('sked__Resource__c IN {0}', query.predefinedRecordIds);
            }
            else {
                activityResourceQueryBuilder.addCondition(assignmentResourceCoCondition);
            }

            List<AggregateResult> arAggregateResults = Database.query(activityResourceQueryBuilder.toString());
            for (AggregateResult result : arAggregateResults) {
                String resourceId = (String) result.get('resourceId');
                Integer numActivity = (Integer) result.get('numActivity');
                if (numActivity > 0) {
                    resourceIdsHaveAssignment.add(resourceId);
                }
            }

            if (resourceIdsHaveAssignment != NULL && !resourceIdsHaveAssignment.isEmpty()) {
                queryBuilder.addCondition('Id NOT IN {0}', resourceIdsHaveAssignment);
            }
        }

        queryBuilder.addCondition('((sked__Resource_Type__c = \'Person\' AND sked_Employment_Status__c != \'Inactive\') OR (sked__Resource_Type__c = \'Asset\' AND sked__Is_Active__c = TRUE))');
        queryBuilder.orderClause = 'ORDER BY Name ASC';
        
        if (query.includes(skedSObjectType.RESOURCE_TAG)) {
            skedQueryBuilder resourceTagBuilder = query.getQueryBuilder('sked__Resource_Tag__c');
            if (query.tagExpiry != NULL) {
                resourceTagBuilder.addCondition('(sked_Expiry_Date__c = NULL OR sked_Expiry_Date__c >= {0})', query.tagExpiry);
                resourceTagBuilder.addCondition('(sked_Start_Date__c = NULL OR sked_Start_Date__c <= {0})', query.tagExpiry);
            }
            if (query?.activeTagsOnly == true) {
                resourceTagBuilder.addCondition('sked_Role_Status__c = \'Active\'');
            }
        }
        if (query.includes(skedSObjectType.JOB_ALLOCATION)) {
            skedQueryBuilder jobAllocationBuilder = query.getQueryBuilder('sked__Job_Allocation__c');
            if (query.jobAllocationStatuses != NULL && !query.jobAllocationStatuses.isEmpty()) {
                jobAllocationBuilder.addCondition('sked__Status__c IN {0}', query.jobAllocationStatuses);
            }
            else {
            	jobAllocationBuilder.addCondition('sked__Status__c NOT IN {0}', new List<string> {skedConstants.JOB_ALLOCATION_STATUS_DELETED, skedConstants.JOB_ALLOCATION_STATUS_DECLINED});
            }
            jobAllocationBuilder.addCondition('sked__Job__r.sked__Job_Status__c != {0}', skedConstants.JOB_STATUS_CANCELLED);
            if (query.startTime != NULL && query.endTime != NULL) {
                jobAllocationBuilder.addCondition('sked__Start__c < {0}', query.endTime);
                jobAllocationBuilder.addCondition('sked__Set_End__c > {0}', query.startTime);
                jobAllocationBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
            }
            if (startDate != NULL && endDate != NULL) {
                jobAllocationBuilder.addCondition('sked__Job__r.sked_Start_Date__c <= {0}', endDate);
                jobAllocationBuilder.addCondition('sked__Job__r.sked_Finish_Date__c >= {0}', startDate);
                jobAllocationBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
            }
        }
        if (query.includes(skedSObjectType.AVAILABILITY)) {
            skedQueryBuilder availabilityBuilder = query.getQueryBuilder('sked__Availability__c');
            List<string> statusList = query.availabilityStatuses;
            if (statusList == NULL || statusList.isEmpty()) {
                statusList = new List<string>();
                statusList.add(skedConstants.AVAILABILITY_STATUS_APPROVED);
                statusList.add(skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_PENDING);
                statusList.add(skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_WAITLIST);
                statusList.add(skedConstants.AVAILABILITY_STATUS_PENDING);
                statusList.add(skedConstants.AVAILABILITY_STATUS_WAITLIST);
                statusList.add(skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL);
                statusList.add(skedConstants.AVAILABILITY_STATUS_PROCESSING_ADJUSTMENT);
                statusList.add(skedConstants.AVAILABILITY_STATUS_PROCESSING_CANCELLATION);
            }
            availabilityBuilder.addCondition('sked_Custom_Status__c IN {0}', statusList);
            if (query.startTime != NULL && query.endTime != NULL) {
                availabilityBuilder.addCondition('sked__Start__c < {0}', query.endTime);
                availabilityBuilder.addCondition('sked__Finish__c > {0}', query.startTime);
                availabilityBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
            }
            if (startDate != NULL && endDate != NULL) {
                availabilityBuilder.addCondition('sked_Start_Date__c <= {0}', endDate);
                availabilityBuilder.addCondition('sked_Finish_Date__c >= {0}', startDate);
                availabilityBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
            }
            if (query.availabilityTypes != null && !query.availabilityTypes.isEmpty()) {
                availabilityBuilder.addCondition('sked__Type__c IN {0}', query.availabilityTypes);
            }
            if (query.excludedAvailabilityTypes != null && !query.excludedAvailabilityTypes.isEmpty()) {
                availabilityBuilder.addCondition('sked__Type__c NOT IN {0}', query.excludedAvailabilityTypes);
            }
        }
        if (query.includes(skedSObjectType.ACTIVITY)) {
            skedQueryBuilder activityBuilder = query.getQueryBuilder('sked__Activity__c');
            if (query.startTime != NULL && query.endTime != NULL) {
                activityBuilder.addCondition('sked__Start__c < {0}', query.endTime);
                activityBuilder.addCondition('sked__End__c > {0}', query.startTime);
                activityBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
            }
            if (startDate != NULL && endDate != NULL) {
                activityBuilder.addCondition('sked_Start_Date__c <= {0}', endDate);
                activityBuilder.addCondition('sked_End_Date__c >= {0}', startDate);
                activityBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
            }
        }
        if (query.includes(skedSObjectType.AVAILABILITY_TEMPLATE_RESOURCE)) {
            skedQueryBuilder resourceTemplateBuilder = query.getQueryBuilder('sked__Availability_Template_Resource__c');
            resourceTemplateBuilder.orderClause = 'ORDER BY sked__Availability_Template__r.sked__Start__c ASC';
        }
        if (query.includes(skedSObjectType.AVAILABILITY_PATTERN_RESOURCE)) {
            skedQueryBuilder patternResourceBuilder = query.getQueryBuilder('sked__Availability_Pattern_Resource__c');
            patternResourceBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
        }
        if (query.includes(skedSObjectType.ACTIVITY_RESOURCE)) {
            skedQueryBuilder activityResourceBuilder = query.getQueryBuilder('sked__Activity_Resource__c');
            if (query.startTime != NULL && query.endTime != NULL) {
                activityResourceBuilder.addCondition('sked__Activity__r.sked__Start__c < {0}', query.endTime);
                activityResourceBuilder.addCondition('sked__Activity__r.sked__End__c > {0}', query.startTime);
            }
            if (startDate != NULL && endDate != NULL) {
                activityResourceBuilder.addCondition('sked__Activity__r.sked_Start_Date__c <= {0}', endDate);
                activityResourceBuilder.addCondition('sked__Activity__r.sked_End_Date__c >= {0}', startDate);
            }
            activityResourceBuilder.orderClause = 'ORDER BY sked__Activity__r.sked__Start__c ASC';
        }
        if (query.includes(skedSObjectType.RESOURCE_OVERRIDE)) {
            skedQueryBuilder resourceOverrideBuilder = query.getQueryBuilder('sked__Resource_Override__c');
            if (query.startTime != NULL && query.endTime != NULL) {
                resourceOverrideBuilder.addCondition('sked__Start__c < {0}', query.endTime);
                resourceOverrideBuilder.addCondition('sked__End__c > {0}', query.startTime);
            }
            if (startDate != NULL && endDate != NULL) {
                resourceOverrideBuilder.addCondition('sked_Start_Date__c <= {0}', endDate);
                resourceOverrideBuilder.addCondition('sked_End_Date__c >= {0}', startDate);
            }
            resourceOverrideBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
        }
        if (query.includes(skedSObjectType.RESOURCE_SECONDARY_REGION)) {
            skedQueryBuilder resourceSecondaryRegionBuilder = query.getQueryBuilder('sked_Resource_Biomed_Collection_Op__c');
            if (startDate != NULL && endDate != NULL) {
                string condition = '( (sked_Start_Date__c = NULL AND sked_End_Date__c = NULL) OR (sked_Start_Date__c != NULL AND sked_End_Date__c = NULL AND sked_Start_Date__c <= {1}) OR (sked_Start_Date__c <= {1} AND sked_End_Date__c >= {0}) )';
                condition = condition.replace('{0}', Json.serialize(query.startDate).replace('"', ''));
                condition = condition.replace('{1}', Json.serialize(query.endDate).replace('"', ''));
                
                resourceSecondaryRegionBuilder.addCondition(condition);
            }
            resourceSecondaryRegionBuilder.orderClause = 'ORDER BY sked_Start_Date__c ASC';
        }
        if (query.includes(skedSObjectType.CUSTOM_AVAILABILITY)) {
            skedQueryBuilder customAvailabilityBuilder = query.getQueryBuilder('sked_Custom_Availability__c');
            if (query.startTime != NULL && query.endTime != NULL) {
                customAvailabilityBuilder.addCondition('sked_Start__c < {0}', query.endTime);
                customAvailabilityBuilder.addCondition('sked_Finish__c > {0}', query.startTime);
                customAvailabilityBuilder.orderClause = 'ORDER BY sked_Start__c ASC';
            }
            if (startDate != NULL && endDate != NULL) {
                customAvailabilityBuilder.addCondition('sked_Start_Date__c <= {0}', endDate);
                customAvailabilityBuilder.addCondition('sked_Finish_Date__c >= {0}', startDate);
                customAvailabilityBuilder.orderClause = 'ORDER BY sked_Start_Date__c ASC';
            }
            if (query.customAvailabilityStatuses != null && !query.customAvailabilityStatuses.isEmpty()) {
                customAvailabilityBuilder.addCondition('sked_Status__c IN {0}', query.customAvailabilityStatuses);
            }
        }
        if(query.includes(skedSObjectType.LOCATION_RESOURCE_SCORE)) {
            system.debug('here');
            skedQueryBuilder locationResourceScoreBuilder = query.getQueryBuilder('sked__Location_Resource_Score__c');
            if(query.locationResourceRelationShip != NULL) {
                locationResourceScoreBuilder.addCondition('sked_Location_Resource_Relationship__c = {0}', query.locationResourceRelationShip);
            }
        }
    }

    /*********************************************************** Public ***********************************************************/
    public override List<skedModels.modelBase> getList(skedDataService.queryModelBase inputQuery) {
        List<skedModels.resource> resources = (List<skedModels.resource>)super.getList(inputQuery);

        for (skedModels.resource resource : resources) {
            if (resource.activities != NULL && !resource.activities.isEmpty()) {
                for (skedModels.activity activity : resource.activities) {
                    activity.updateStartFinish(this.timezoneSidId);
                }
            }
            if (resource.availabilities != NULL && !resource.availabilities.isEmpty()) {
                for (skedModels.availability availability : resource.availabilities) {
                    availability.updateStartFinish(this.timezoneSidId);
                }
            }
            if (resource.jobAllocations != NULL && !resource.jobAllocations.isEmpty()) {
                for (skedModels.jobAllocation jobAllocation : resource.jobAllocations) {
                    jobAllocation.updateStartFinish(this.timezoneSidId);
                }
            }
        }

        return resources;
    }

    public void populateNonWorkingEvents(List<skedModels.resource> resources, Set<Date> inputDates, DateTime startTime, DateTime endTime) {
        Set<Id> resourceIds = new Set<Id>();
        for (skedModels.resource resource : resources) {
            resourceIds.add(resource.id);
        }
        skedAvailabilityPatternService patternService = (skedAvailabilityPatternService)skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
        Map<Id, List<skedModels.event>> mapResourceTemplateEvents = patternService.getPatternEvents(resourceIds, inputDates);
        
        for (skedModels.resource resource : resources) {
            List<skedModels.event> resourceAvailability = new List<skedModels.event>();
            if (resource.availability == NULL) {
                resource.availability = new List<skedModels.event>();
            }
            
            resourceAvailability.addAll(resource.availability);

            List<skedModels.event> templateEvents = mapResourceTemplateEvents.get(resource.id);
            resource.templateEvents = templateEvents;
            
            if (templateEvents != NULL && !templateEvents.isEmpty()) {
                resourceAvailability.addAll(templateEvents);
            }

            resourceAvailability.sort();

            List<skedModels.event> resourceNonWorkingEvents = new List<skedModels.event>();
            if (!resourceAvailability.isEmpty()) {
                for (integer i = 0; i < resourceAvailability.size(); i++) {
                    skedModels.event availability = resourceAvailability.get(i);
                    if (availability.objectType == 'availability' && availability.eventType != 'template') {
                        skedModels.availability avail = (skedModels.availability)availability;
                        if (avail.isAvailable == FALSE && avail.startDate != avail.endDate) {
                            List<skedModels.event> nonWorkingEvents = generateNonWorkingEvents(availability.start, availability.finish, this.timezoneSidId);
                            resourceNonWorkingEvents.addAll(nonWorkingEvents);
                        }
                    }
                    if (i == resourceAvailability.size() - 1) {
                        if (availability.finish < endTime) {
                            List<skedModels.event> nonWorkingEvents = generateNonWorkingEvents(availability.finish, endTime, this.timezoneSidId);
                            resourceNonWorkingEvents.addAll(nonWorkingEvents);
                        }
                    }
                    if (i == 0) {
                        if (availability.start > startTime) {
                            List<skedModels.event> nonWorkingEvents = generateNonWorkingEvents(startTime, availability.start, this.timezoneSidId);
                            resourceNonWorkingEvents.addAll(nonWorkingEvents);
                        }
                    }
                    skedModels.event nextAvailability;
                    integer nextIndex = i + 1;
                    while (nextIndex < resourceAvailability.size()) {
                        nextAvailability = resourceAvailability.get(nextIndex);
                        if (nextAvailability.finish > availability.finish) {
                            break;
                        }
                        nextIndex++;
                    }
                    if (nextAvailability != NULL && availability.finish < nextAvailability.start) {
                        List<skedModels.event> nonWorkingEvents = generateNonWorkingEvents(availability.finish, nextAvailability.start, this.timezoneSidId);
                        resourceNonWorkingEvents.addAll(nonWorkingEvents);
                    }
                    i = nextIndex - 1;
                }
            }
            else {
                List<skedModels.event> nonWorkingEvents = generateNonWorkingEvents(startTime, endTime, this.timezoneSidId);
                resourceNonWorkingEvents.addAll(nonWorkingEvents);
            }
            
            resource.availability.addAll(resourceNonWorkingEvents);
        }
    }

    /*********************************************************** Nested classes ***********************************************************/
    private List<skedModels.event> generateNonWorkingEvents(DateTime start, DateTime finish, string timezoneSidId) {
        List<skedModels.event> events = new List<skedModels.event>();
        DateTime firstDateStart = skedDateTimeUtils.getStartOfDate(start, timezoneSidId);
        DateTime lastDateEnd = skedDateTimeUtils.getEndOfDate(finish, timezoneSidId);
        DateTime tempDt = firstDateStart;
        while (tempDt < lastDateEnd) {
            DateTime eventDateEnd = skedDateTimeUtils.addDays(tempDt, 1, timezoneSidId);
            skedModels.event event = new skedModels.event();
            event.objectType = 'availability';
            event.eventType = 'non-working';
            event.start = start > tempDt ? start : tempDt;
            event.finish = finish < eventDateEnd ? finish : eventDateEnd;
            event.updateDateTimeFields(timezoneSidId);
            events.add(event);
            tempDt = eventDateEnd;
        }
        return events;
    }

    /*********************************************************** Nested classes ***********************************************************/
    global class queryModel extends skedDataService.queryModelBase {
        public Boolean activeTagsOnly;
        public List<String> activityTypes;
        public List<string> availabilityStatuses;
        public List<String> availabilityTypes;
        public List<string> biomedCollectionOpIds;
        public List<string> categories;
        public List<string> customAvailabilityStatuses;
        public List<string> employmentTypes;
        public string endDate;
        public DateTime endTime;
        public List<String> excludedAvailabilityTypes;
        public boolean hasNoAssignment;
        public boolean hasTemporaryRelocation;
        public string additionalFilterOnDate;
        public List<string> jobAllocationStatuses;
        public List<string> locationIds;
        public Boolean matchAllSelectedTags;
        public List<string> patternIds;
        public List<string> resourceTypes;
        public List<string> regionIds;
        public DateTime startTime;
        public string startDate;
        public Date tagExpiry;
        public List<string> tagIds;
        public List<string> templateIds;
        public String locationResourceRelationShip;
    }

}