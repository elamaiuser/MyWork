global class skedActivityService extends skedEventService {

    protected override void initialize() {
        this.sObjectApiName = 'sked__Activity__c';
        this.objectTYpe = 'activity';
        this.domainType = Type.forName('skedModels.activity');
    }

    protected virtual override void postSaveRecord(List<skedModels.modelBase> models, List<sObject> records) {
        List<skedModels.activity> activityModels = (List<skedModels.activity>) models;
        Map<Id, sked__Activity__c> map_activityId_activityRecords = new Map<Id, sked__Activity__c>((List<sked__Activity__c>) records);   
        
        //Query existing activity Ids in case of edit and delete existing activity COs
        List<sked__Activity__c> existingActivities = new List<sked__Activity__c>(
            [SELECT Id, 
            (SELECT Id FROM sked_Activity_Collection_Operations__r)
            FROM sked__Activity__c
            WHERE Id IN :map_activityId_activityRecords.keySet()
            ]
        );
		
        system.debug('existingActivities '+existingActivities);
        List<sked_Activity_Collection_Operation__c> activityCosToDelete = new List<sked_Activity_Collection_Operation__c>();
        if(existingActivities != NULL && !existingActivities.isEmpty()) {
            for(sked__Activity__c existingActivity : existingActivities) {
                if(existingActivity.sked_Activity_Collection_Operations__r != NULL && !existingActivity.sked_Activity_Collection_Operations__r.isEmpty())
                activityCosToDelete.addAll(existingActivity.sked_Activity_Collection_Operations__r);
            }  
        }

        if(!activityCosToDelete.isEmpty()) {
            delete activityCosToDelete;
        }

        List<Id> collectionOperationIds = new List<Id>();
        for(skedModels.activity activityModel : activityModels) {
            if(activityModel.biomedCollectionOpIds != NULL && !activityModel.biomedCollectionOpIds.isEmpty()) {
                collectionOperationIds.addAll(activityModel.biomedCollectionOpIds);
            }
        }

        Map<Id, Biomed_Collection_Op_Center__c> map_coId_coInfo = new Map<Id, Biomed_Collection_Op_Center__c>();
        if (!collectionOperationIds.isEmpty()) {
            map_coId_coInfo = new Map<Id, Biomed_Collection_Op_Center__c>(
                [SELECT Id,
                (
                    SELECT Id, sked_End_Date__c, sked_Start_Date__c, sked_Territory__c
                    FROM sked_Territory_Collection_Operations__r
                )
                FROM Biomed_Collection_Op_Center__c
                WHERE Id IN :collectionOperationIds]
            );
        }

        List<sked_Activity_Collection_Operation__c> skedActivityColOpToInsert = new List<sked_Activity_Collection_Operation__c>();
        for(skedModels.activity activityModel : activityModels) {
            for(String coId : activityModel.biomedCollectionOpIds) {
                String districtId;
                if(map_coId_coInfo != NULL && map_coId_coInfo.containsKey(coId)) {
                    Biomed_Collection_Op_Center__c collectionOperation = map_coId_coInfo.get(coId);
                    for (sked_Territory_Collection_Operation__c territoryCO : collectionOperation.sked_Territory_Collection_Operations__r) {
                        boolean isStartDateMatched = territoryCO.sked_Start_Date__c == NULL || territoryCO.sked_Start_Date__c <= skedDateTimeUtils.getDateFromIsoString(activityModel.startDate);
                        boolean isEndDateMatched = territoryCO.sked_End_Date__c == NULL || territoryCO.sked_End_Date__c >= skedDateTimeUtils.getDateFromIsoString(activityModel.startDate);
                        if (isStartDateMatched && isEndDateMatched) {
                            districtId = territoryCO.sked_Territory__c;
                            break;
                        }
                    }
                }
                skedActivityColOpToInsert.add(new sked_Activity_Collection_Operation__c(
                    sked_Activity__c = activityModel.id,
                    sked_Biomed_Collection_Operation__c = coId,
                    sked_District__c = districtId
                ));
            }
        }
        
        if (!skedActivityColOpToInsert.isEmpty()) {
            insert skedActivityColOpToInsert;
        }
    }

    protected override void doAdditionalMap(sObject sObj, skedModels.modelBase model) {
        sked__Activity__c skedActivity = (sked__Activity__c)sObj;
        skedModels.activity activity = (skedModels.activity)model;
        if (string.isBlank(activity.id)) {
            skedActivity.sked__Resource__c = activity.resourceId;
        }
	}

    public override saveResult saveRecurringSchedule(skedModels.recurringSchedule recurringSchedule) {
        saveResult result = new saveResult();
        if (recurringSchedule.events.size() > 200) {
            Database.executeBatch(new skedCreateBulkActivityBatch(recurringSchedule, UserInfo.getUserId(), 0));
            result.success = true;
            result.message = skedConstants.ACTIVITY_INSERT_BATCH_STARTED;
        } else {
            result = baseSaveRecurringSchedule(recurringSchedule);
        }

        return result;
    }

    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        Date startDate, endDate;
        if (!string.isBlank(query.startDate)) {
            startDate = skedDateTimeUtils.getDateFromIsoString(query.startDate);
        }
        if (!string.isBlank(query.endDate)) {
            endDate = skedDateTimeUtils.getDateFromIsoString(query.endDate);
        }
        if (query.territoryKeys != NULL && !query.territoryKeys.isEmpty()) {
            queryBuilder.addCondition('sked_Territory_Key__c IN {0}', query.territoryKeys);
        }
        if (query.biomedCollectionOpIds != NULL && !query.biomedCollectionOpIds.isEmpty()) {
            queryBuilder.addCondition('sked_Region__r.sked_Biomed_Collection_Op_Center__c IN {0}', query.biomedCollectionOpIds);
        }
        if (query.regionIds != NULL && !query.regionIds.isEmpty()) {
            queryBuilder.addCondition('sked_Region__c IN {0}', query.regionIds);
        }
        if (query.resourceIds != NULL && !query.resourceIds.isEmpty()) {
            queryBuilder.addCondition('sked__Resource__c IN {0}', query.resourceIds);
        }
        if (query.activityTypes != NULL && !query.activityTypes.isEmpty()) {
            queryBuilder.addCondition('sked__Type__c IN {0}', query.activityTypes);
        }
        if (query.subTypes != NULL && !query.subTypes.isEmpty()) {
            queryBuilder.addCondition('sked_Subtype__c IN {0}', query.subTypes);
        }
        if (query.resourceCategories != NULL && !query.resourceCategories.isEmpty()) {
            queryBuilder.addCondition('sked__Resource__r.sked__Category__c IN {0}', query.resourceCategories);
        }
        if (query.isGroupActivity != NULL) {
            queryBuilder.addCondition('sked_Is_Group_Activity__c = {0}', query.isGroupActivity);
        }
        if (query.recurringScheduleIds != NULL && !query.recurringScheduleIds.isEmpty()) {
            queryBuilder.addCondition('sked_Recurring_Schedule__c IN {0}', query.recurringScheduleIds);
        }
        if (query.startTime != NULL && query.endTime != NULL) {
            queryBuilder.addCondition('sked__Start__c < {0}', query.endTime);
            queryBuilder.addCondition('sked__End__c > {0}', query.startTime);
        }
        else {
            if (query.startTime != NULL) {
                queryBuilder.addCondition('sked__Start__c >= {0}', query.startTime);
            }
            if (query.endTime != NULL) {
                queryBuilder.addCondition('sked__End__c <= {0}', query.endTime);
            }
        }
        if (startDate != NULL && endDate != NULL) {
            queryBuilder.addCondition('sked_Start_Date__c >= {0}', startDate);
            queryBuilder.addCondition('sked_End_Date__c <= {0}', endDate);
        }
        else {
            if (startDate != NULL) {
                queryBuilder.addCondition('sked_Start_Date__c >= {0}', startDate);
            }
            if (endDate != NULL) {
                queryBuilder.addCondition('sked_End_Date__c <= {0}', endDate);
            }
        }
        if (query.includes(skedSObjectType.ACTIVITY_RESOURCE)) {
            skedQueryBuilder activityResourceBuilder = query.getQueryBuilder('sked__Activity_Resource__c');
            activityResourceBuilder.orderClause = 'ORDER BY sked__Resource__r.Name ASC';
        }
        if (query.includes(skedSObjectType.ACTIVITY_COLLECTION_OPERATION)) {
            skedQueryBuilder activityColOpBuilder = query.getQueryBuilder('sked_Activity_Collection_Operation__c');
        }

        queryBuilder = query.getQueryBuilder('sked__Activity__c');
        queryBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class queryModel extends skedEventService.queryModel {
        public List<string> activityTypes;
        public List<string> biomedCollectionOpIds;
        public boolean isGroupActivity;
        public List<string> regionIds;
        public List<string> resourceCategories;
        public List<string> subTypes;
        public List<string> territoryKeys;
    }

}