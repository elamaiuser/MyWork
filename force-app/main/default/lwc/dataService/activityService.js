import { dataService, queryModelBase, sObjectType } from './base';

class activityService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked__Activity__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.collectionOperationIds && query.collectionOperationIds.length) {
            queryBuilder.addCondition({ template: 'sked_Collection_Operation__c IN {0}', value: query.collectionOperationIds, type: "array_string" });
        }
        if (query.territoryKeys && query.territoryKeys.length) {
            queryBuilder.addCondition({ template: "sked_Territory_Key__c IN {0}", value: query.territoryKeys, type: "array_string" });
        }
        if (query.startDate && query.endDate) {
            if (query.overlapsDateRange) {
                queryBuilder.addCondition({ template: "sked_Start_Date__c <= {0}", value: query.endDate });
                // A blank End Date must fall back to the start-within-range test, otherwise an
                // open-ended activity matches every range forever.
                queryBuilder.addCondition({ template: "(sked_End_Date__c >= {0} OR (sked_End_Date__c = NULL AND sked_Start_Date__c >= {0}))", value: query.startDate });
            } else {
                queryBuilder.addCondition({ template: "sked_Start_Date__c >= {0}", value: query.startDate });
                queryBuilder.addCondition({ template: "sked_Start_Date__c <= {0}", value: query.endDate });
            }
        }
        if (query.selectedDates && query.selectedDates.length) {
            queryBuilder.addCondition({ template: "sked_Start_Date__c IN {0}", value: query.selectedDates, type: "array" });
        }
        if (query.driveTypes && query.driveTypes.length) {
            queryBuilder.addCondition({ template: "sked_Drive_Types__c IN {0}", value: query.driveTypes, type: "array_string" });
        }
        if (query.resourceIds && query.resourceIds.length) {
            queryBuilder.addCondition({ template: "sked__Resource__c IN {0}", value: query.resourceIds, type: "array_string" });
        }
        if (query.isGroupActivity != undefined && query.isGroupActivity != null) {
            queryBuilder.addCondition({ template: "sked_Is_Group_Activity__c = {0}", value: query.isGroupActivity });
        }
        if (query.isShowOnCalendar != undefined /*&& query.isShowOnCalendar != null*/) {
            queryBuilder.addCondition({ template: "sked_Show_On_Calendar__c = {0}", value: query.isShowOnCalendar });
        }
        if (query.reduceFromStaffingConstraint != undefined && query.reduceFromStaffingConstraint != null) {
            queryBuilder.addCondition({ template: "sked_Reduce_From_Staffing_Constraint__c = {0}", value: query.reduceFromStaffingConstraint });
        }
        if (query.isShowOnCalendarOrReduceFromStaffingConstraints != undefined && query.isShowOnCalendarOrReduceFromStaffingConstraints && query.isShowOnCalendarOrReduceFromStaffingConstraints) {
            queryBuilder.addCondition({ template: "(sked_Show_On_Calendar__c = true OR sked_Reduce_From_Staffing_Constraint__c = true)"});
        }
        if (query.showOnlyLinkedEvents) {
            queryBuilder.addCondition({ template: "sked_Linked_Drives__c != NULL" });
        }
        //Related List
        if (query.includes(sObjectType.ACTIVITY_RESOURCE)) {
            let subQueryBuilder = query.getQueryBuilder("sked__Activity_Resource__c");
            subQueryBuilder.orderClause = 'ORDER BY sked__Resource__r.Name ASC';
        }
        if (query.includes(sObjectType.ACTIVITY_COLLECTION_OPERATION)) {
            let subQueryBuilder = query.getQueryBuilder("sked_Activity_Collection_Operation__c");
        }
    }
}

class activityQueryModel extends queryModelBase {
    collectionOperationIds
    endDate;
    isGroupActivity;
    isShowOnCalendar;
    reduceFromStaffingConstraint;
    selectedDates;
    startDate;
    showOnlyLinkedEvents;
    isShowOnCalendarOrReduceFromStaffingConstraints;
    driveTypes;
    // Opt-in. Default (unset) keeps the legacy "starts inside the range" test so existing
    // callers are unaffected; making this the default would silently change every caller.
    overlapsDateRange;
}

export {
    activityQueryModel,
    activityService
}