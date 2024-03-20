public class skedStaffingBudgetService extends skedEventService {
    
    protected override void initialize() {
        this.sObjectApiName = 'sked_Staffing_Budget__c';
        this.objectTYpe = 'staffingBudget';
        this.domainType = Type.forName('skedModels.staffingBudget');
    }

    protected virtual override void postSaveRecord(List<skedModels.modelBase> models, List<sObject> records) {
        List<skedModels.staffingBudget> staffingBudgetsModels = (List<skedModels.staffingBudget>) models;
        List<sked_Staffing_Budget__c> staffingBudgetRecords = (List<sked_Staffing_Budget__c>) records;

        Set<Id> collectionOpIds = new Set<Id>();
        Set<Id> staffingBudgetIds = new Set<Id>();

        for (skedModels.staffingBudget sb : staffingBudgetsModels) { 
            staffingBudgetIds.add(sb.id);
        }

        List<sked_Staffing_Budget__c> existingStaffingBudgetRecords = [
            SELECT Id,
            (SELECT Id FROM sked_Staffing_Budget_Collection_Ops__r)
            FROM sked_Staffing_Budget__c
            WHERE Id IN :staffingBudgetIds
        ];

        List<sked_Staffing_Budget_Collection_Op__c> sbCosToDelete = new List<sked_Staffing_Budget_Collection_Op__c>();
        for (sked_Staffing_Budget__c sb : existingStaffingBudgetRecords) {
            for (sked_Staffing_Budget_Collection_Op__c sbCo : sb.sked_Staffing_Budget_Collection_Ops__r) {
                sbCosToDelete.add(sbCo);

            }
        }

        if (!sbCosToDelete.isEmpty()) {
            delete sbCosToDelete;
        }
        
        List<sked_Staffing_Budget_Collection_Op__c> staffingBudgetCollectionOpsToCreate = new List<sked_Staffing_Budget_Collection_Op__c>();
        for (skedModels.staffingBudget sb : staffingBudgetsModels) {
            for (String coId : sb.collectionOperationIds) {
                staffingBudgetCollectionOpsToCreate.add(new sked_Staffing_Budget_Collection_Op__c(
                    sked_Staffing_Budget__c = sb.id,
                    sked_Biomed_Collection_Operation__c = coId
                ));

            }
        }

        if (!staffingBudgetCollectionOpsToCreate.isEmpty()) {
            insert staffingBudgetCollectionOpsToCreate;
        }


    }
    
    protected virtual override skedDataService.saveResult preSaveRecord(List<skedModels.modelBase> models) {
        List<skedModels.staffingBudget> staffingBudgets = (List<skedModels.staffingBudget>)models;
        
        Set<string> uniqueKeys = new Set<string>();
        Set<Date> staffingBudgetDates = new Set<Date>();
        Set<String> collectionOperationIds = new Set<String>();
        for (skedModels.staffingBudget staffingBudget : staffingBudgets) {
            List<string> roles = staffingBudget.roles;
            roles.sort();

            List<String> collectionOpIds = staffingBudget.collectionOperationIds;
            collectionOpIds.sort();
            collectionOperationIds.addAll(collectionOpIds);

            staffingBudget.uniqueKey = string.join(collectionOpIds, ';') + ':' + staffingBudget.staffingBudgetDate + ':' + string.join(roles, ';');
            uniqueKeys.add(staffingBudget.uniqueKey);
            
            Date staffingBudgetDate = skedDateTimeUtils.getDateFromIsoString(staffingBudget.staffingBudgetDate);
            staffingBudgetDates.add(staffingBudgetDate);
        }

        Map<Id, List<sked_Staffing_Budget_Collection_Op__c>> sbcosBySbId = new Map<Id, List<sked_Staffing_Budget_Collection_Op__c>>();
        for (sked_Staffing_Budget_Collection_Op__c staffingBudgetCollectionOp : [
            SELECT Id, sked_Staffing_Budget__c, sked_Biomed_Collection_Operation__c
            FROM sked_Staffing_Budget_Collection_Op__c
            WHERE sked_Biomed_Collection_Operation__c IN :collectionOperationIds
            AND sked_Staffing_Budget__r.sked_Staffing_Budget_Date__c IN :staffingBudgetDates
        ]) {
            List<sked_Staffing_Budget_Collection_Op__c> sbcosForSb = sbcosBySbId.get(staffingBudgetCollectionOp.sked_Staffing_Budget__c);
            if (sbcosForSb == null) {
                sbcosForSb = new List<sked_Staffing_Budget_Collection_Op__c>();
            }

            sbcosForSb.add(staffingBudgetCollectionOp);
            sbcosBySbId.put(staffingBudgetCollectionOp.sked_Staffing_Budget__c, sbcosForSb);
        }

        if (!sbcosBySbId.keySet().isEmpty()) { 
            Map<Id, sked_Staffing_Budget__c> existingStaffingBudgetById = new Map<Id, sked_Staffing_Budget__c>([
                SELECT Id, sked_Roles__c, sked_Staffing_Budget_Date__c,
                (SELECT Id, sked_Biomed_Collection_Operation__c FROM sked_Staffing_Budget_Collection_Ops__r)
                FROM sked_Staffing_Budget__c
                WHERE Id IN :sbcosBySbId.keySet()
                AND sked_Staffing_Budget_Date__c IN :staffingBudgetDates
            ]);

            Map<String, sked_Staffing_Budget__c> staffingBudgetByKey = new Map<String, sked_Staffing_Budget__c>();
            for (Id staffingBudgetId : existingStaffingBudgetById.keySet()) {
                sked_Staffing_Budget__c staffingBudget = existingStaffingBudgetById.get(staffingBudgetId);

                Set<String> collectionOpIdsSet = new Set<String>();
                for (sked_Staffing_Budget_Collection_Op__c sbco : staffingBudget.sked_Staffing_Budget_Collection_Ops__r) {
                    collectionOpIdsSet.add(sbco.sked_Biomed_Collection_Operation__c);
                }
                List<String> collectionOpIds = new List<String>();
                for (String collectionOpId : collectionOpIdsSet) {
                    collectionOpIds.add(collectionOpId);
                }
                collectionOpIds.sort();

                List<string> roles = staffingBudget.sked_Roles__c.split(';');
                roles.sort();

                String sbDateStr = JSON.serialize(staffingBudget.sked_Staffing_Budget_Date__c).replace('"', '');
                string uniqueKey = String.join(collectionOpIds, ';') + ':' + sbDateStr + ':' + string.join(roles, ';');
                staffingBudgetByKey.put(uniqueKey, staffingBudget);
            }

            for (skedModels.staffingBudget staffingBudget : staffingBudgets) {
                if (staffingBudgetByKey.containsKey(staffingBudget.uniqueKey)) {
                    sked_Staffing_Budget__c existingRecord = staffingBudgetByKey.get(staffingBudget.uniqueKey);
                    staffingBudget.id = existingRecord.Id;
                }
            }
        }

        skedDataService.saveResult result = new skedDataService.saveResult();
        result.success = true;
        return result;
    }
    
    protected override void getQueryConditions(skedQueryBuilder queryBuilder, queryModelBase inputModel) {
        queryModel query = (queryModel)inputModel;
        if (query.biomedCollectionOpIds != NULL && !query.biomedCollectionOpIds.isEmpty()) {
            queryBuilder.addCondition('sked_Biomed_Collection_Op_Center__c IN {0}', query.biomedCollectionOpIds);
        }
        if (query.recurringScheduleIds != NULL && !query.recurringScheduleIds.isEmpty()) {
            queryBuilder.addCondition('sked_Recurring_Schedule__c IN {0}', query.recurringScheduleIds);
        }
        if (query.roles != NULL && !query.roles.isEmpty()) {
            queryBuilder.addCondition('sked_Roles__c INCLUDES{0}', query.roles);
        }
        if (query.requestTypes != NULL && !query.requestTypes.isEmpty()) {
            queryBuilder.addCondition('sked_Request_Type__c IN {0}', query.requestTypes);
        }
        if (query.startTime != NULL || !string.isBlank(query.startDate)) {
            Date startDateValue = !string.isBlank(query.startDate) ? skedDateTimeUtils.getDateFromIsoString(query.startDate)
            							: skedDateTimeUtils.getDate(query.startTime, this.timezoneSidId);
            queryBuilder.addCondition('sked_Staffing_Budget_Date__c >= {0}', startDateValue);
        }
        if (query.endTime != NULL || !string.isBlank(query.endDate)) {
            Date endDateValue = !string.isBlank(query.endDate) ? skedDateTimeUtils.getDateFromIsoString(query.endDate)
            							: skedDateTimeUtils.getDate(query.startTime, this.timezoneSidId);
            queryBuilder.addCondition('sked_Staffing_Budget_Date__c <= {0}', endDateValue);
        }
        if (query.excludeEmptySlots == TRUE) {
            queryBuilder.addCondition('(sked_Total_Slots__c != 0 OR sked_Available_Slots__c != 0)');
        }
        
        queryBuilder = query.getQueryBuilder('sked_Staffing_Budget__c');
        queryBuilder.orderClause = 'ORDER BY sked_Staffing_Budget_Date__c ASC';
        
        if (query.includes(skedSObjectType.AVAILABILITY)) {
            skedQueryBuilder availabilityBuilder = query.getQueryBuilder('sked__Availability__c');
        }

        if (query.includes(skedSObjectType.STAFFING_BUDGET_AVAILABILITY)) {
            skedQueryBuilder staffingBudgetAvailabilityBuilder = query.getQueryBuilder('sked_Staffing_Budget_Availability__c');
        }

        if (query.includes(skedSObjectType.STAFFING_BUDGET_COLLECTION_OP)) {
            skedQueryBuilder staffingBudgetCollectionOpBuilder = query.getQueryBuilder('sked_Staffing_Budget_Collection_Op__c');
        }
    }
    
    /*********************************************************** Public ***********************************************************/
    public override List<skedModels.modelBase> getList(skedDataService.queryModelBase inputQuery) {
        List<skedModels.staffingBudget> staffingBudgets = (List<skedModels.staffingBudget>)super.getList(inputQuery);
        for (skedModels.staffingBudget staffingBudget : staffingBudgets) {
            staffingBudget.startDate = staffingBudget.staffingBudgetDate;
            staffingBudget.startTime = 0;
            staffingBudget.endDate = staffingBudget.staffingBudgetDate;
            staffingBudget.endTime = 0;
            staffingBudget.updateStartFinish(this.timezoneSidId);
        }
        return staffingBudgets;
    }
    
    public void saveRecurrence(List<skedModels.staffingBudget> staffingBudgets) {
        sked__Recurring_Schedule__c skedSchedule = new sked__Recurring_Schedule__c();
        insert skedSchedule;
        
        for (skedModels.staffingBudget staffingBudget : staffingBudgets) {
            staffingBudget.scheduleId = skedSchedule.Id;
        }
        saveRecords(staffingBudgets);
    }
    
    public void verifyStaffingBudget(string resourceId, List<skedModels.availability> availabilityList) {
        Set<Date> availabilityDates = new Set<Date>();
        Date currentDate = system.today();
        for (skedModels.availability availability : availabilityList) {
            availability.availabilityDate = skedDateTimeUtils.getDateFromIsoString(availability.startDate);
            availabilityDates.add(availability.availabilityDate);
        }
        
        sked__Resource__c skedResource = [SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                                          (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Tag__r.sked_Priority__c
                                           FROM sked__ResourceTags__r
                                           WHERE sked__Resource__c = :resourceId
                                           AND sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                                           ORDER BY sked__Tag__r.sked_Priority__c ASC NULLS LAST)
                                         FROM sked__Resource__c
                                         WHERE Id = :resourceId];
        string resourcePrimaryRole = skedResource.sked__ResourceTags__r.get(0).sked__Tag__r.Name;

        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>{resourceId => skedResource};
        Map<Id, Set<Date>> datesByResourceId = new Map<Id, Set<Date>>{resourceId => availabilityDates};
        
        Map<Date, List<skedStaffingBudgetWrapper>> staffingBudgetWrappersByDate = skedStaffingBudgetUtils.getSkedStaffingBudgetWrappersByDate(datesByResourceId, resourceById);
        for (skedModels.availability availability : availabilityList) {
            boolean isInside30DayWindow = false;
            Boolean availabilityRequiresValidation = availability.eventType == skedConstants.AVAILABILITY_TYPE_PTO || availability.eventType == skedConstants.AVAILABILITY_TYPE_FLOATING_HOLIDAY;
            availability.timeOffAllowance = availabilityRequiresValidation ? 'No (General)' : 'Yes (General)';

            if (currentDate.daysBetween(availability.availabilityDate) < 30) {
                isInside30DayWindow = true;
            }
            
            if (staffingBudgetWrappersByDate.containsKey(availability.availabilityDate) && availabilityRequiresValidation) {
                List<skedStaffingBudgetWrapper> staffingBudgetsForDate = staffingBudgetWrappersByDate.get(availability.availabilityDate);
                
                boolean isAnyOpenEnrollment = false;
                boolean isAnyOutOfBiddingTime = false;
                boolean isAnyBudgetFull = false;
                boolean isAnyAllHandsOnDeck = false;
                
                for (skedStaffingBudgetWrapper staffingBudgetWrapper : staffingBudgetsForDate) {
                    if (staffingBudgetWrapper.staffingBudget.sked_Request_Type__c == skedConstants.STAFFING_BUDGET_REQUEST_TYPE_ALL_HANDS_ON_DECK) {
                        isAnyAllHandsOnDeck = true;
                    }
                    if (staffingBudgetWrapper.staffingBudget.sked_Request_Type__c == skedConstants.STAFFING_BUDGET_REQUEST_TYPE_OPEN_ENROLLMENT) {
                        isAnyOpenEnrollment = true;
                        if (isAnyOutOfBiddingTime == false) {
                            Date biddingStartDate, biddingEndDate;
                            if (staffingBudgetWrapper.staffingBudget.sked_Bidding_Start_Date__c != NULL) {
                                biddingStartDate = staffingBudgetWrapper.staffingBudget.sked_Bidding_Start_Date__c;
                            }
                            if (staffingBudgetWrapper.staffingBudget.sked_Bidding_End_Date__c != NULL) {
                                biddingEndDate = staffingBudgetWrapper.staffingBudget.sked_Bidding_End_Date__c;
                            }
                            isAnyOutOfBiddingTime = (biddingStartDate != NULL && biddingStartDate > currentDate);
                            isAnyOutOfBiddingTime = isAnyOutOfBiddingTime || (biddingEndDate != NULL && biddingEndDate < currentDate);
                        }
                    }
                    if (staffingBudgetWrapper.availableSlots <= 0) {
                        isAnyBudgetFull = true;
                    }
                }
                
                if (isAnyAllHandsOnDeck) {
                    availability.timeOffAllowance = 'No (All Hands)';
                }
                else if (isAnyOpenEnrollment) {
                    availability.timeOffAllowance = isAnyOutOfBiddingTime ? 'No (Outside Bid Submission Window)' : 'Yes (Queue)';
                }
                else if (isInside30DayWindow) {
                    availability.timeOffAllowance = 'Yes (Queue)';
                }
                else if (!isAnyBudgetFull) {
                    availability.timeOffAllowance = 'Yes (General)';
                }
            }
        }
    }
    
    /*********************************************************** Private ***********************************************************/
    
    /*********************************************************** Nested classes ***********************************************************/
    public class queryModel extends skedEventService.queryModel {
        public List<string> biomedCollectionOpIds;
        public boolean excludeEmptySlots;
        public List<string> roles;
        public List<string> requestTypes;
    }
}