import { dataService, queryModelBase, sObjectType } from './base';

class driveChangeRequestService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked_Drive_Change_Request__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.driveIds && query.driveIds.length) {
            queryBuilder.addCondition({ template: "sked_Drive__c IN {0}", value: query.driveIds, type: "array_string" });
        }
        if (query.opportunityIds && query.opportunityIds.length) {
            queryBuilder.addCondition({ template: "sked_Drive__r.sked_Opportunity__c IN {0}", value: query.opportunityIds, type: "array_string" });
        }
        if (query.accountIds && query.accountIds.length) {
            queryBuilder.addCondition({ template: "sked_Drive__r.sked_Account__c IN {0}", value: query.accountIds, type: "array_string" });
        }
        if (query.statuses && query.statuses.length) {
            queryBuilder.addCondition({ template: "sked_Status__c IN {0}", value: query.statuses, type: "array_string" });
        }
        if (query.types && query.types.length) {
            queryBuilder.addCondition({ template: "sked_Type__c INCLUDES {0}", value: query.types, type: "array_string" });
        }
        if (query.collectionOperationIds && query.collectionOperationIds.length) {
            queryBuilder.addCondition({ template: "(sked_Drive__r.sked_Collection_Operation__c IN {0} OR sked_New_Collection_Operation__c IN {0})", value: query.collectionOperationIds, type: "array_string" });
        }
        if (query.territoryKeys && query.territoryKeys.length) {
            queryBuilder.addCondition({ template: "((sked_New_Collection_Operation__c = NULL AND sked_Drive__r.sked_Territory_Key__c IN {0}) OR (sked_New_Collection_Operation__c != NULL AND sked_New_Territory_Key__c IN {0}))", value: query.territoryKeys, type: "array_string" });
        }
        if (query.driveTypes && query.driveTypes.length) {
            queryBuilder.addCondition({ template: "sked_Drive__r.sked_Type_of_Drive__c IN {0}", value: query.driveTypes, type: "array_string" });
        }
        if (query.driveStartDate && query.driveEndDate) {
            queryBuilder.addCondition({ template: "sked_Drive__r.sked_Drive_Date__c <= {0}", value: query.driveEndDate });
            queryBuilder.addCondition({ template: "sked_Drive__r.sked_Drive_Date__c >= {0}", value: query.driveStartDate });
        }
        if (query.driveContentions && query.driveContentions.length) {
            queryBuilder.addCondition({ template: "((sked_Status__c = 'Approved by System' AND sked_Drive_Contention__c = NULL) OR sked_Drive_Contention__c INCLUDES {0})", value: query.driveContentions, type: "array_string" });
        }
        if (query.submissionStartDate && query.submissionEndDate) {
            queryBuilder.addCondition({ template: "(DAY_ONLY(CreatedDate) <= {0} OR DAY_ONLY(LastModifiedDate) <= {0})", value: query.submissionEndDate });
            queryBuilder.addCondition({ template: "(DAY_ONLY(CreatedDate) >= {0} OR DAY_ONLY(LastModifiedDate) >= {0})", value: query.submissionStartDate });
        }
        if (query.createdByIds && query.createdByIds.length) {
            queryBuilder.addCondition({ template: "CreatedById IN {0}", value: query.createdByIds, type: "array_string" });
        }
        if (query.includes(sObjectType.DRIVE_CHANGE_REQUEST_ITEM)) {
            let subQueryBuilder = query.getQueryBuilder("sked_Drive_Change_Request_Item__c");
            if(query.ignoreHiddenDriveChangeRequestItems) {
                subQueryBuilder.addCondition({template: "sked_Is_Hidden__c = FALSE"});
            }
            subQueryBuilder.orderClause = 'ORDER BY CreatedDate DESC';
        }
        queryBuilder.orderClause = 'ORDER BY CreatedDate DESC, Id ASC';
    }
}

class driveChangeRequestQueryModel extends queryModelBase {
    collectionOperationIds;
    territoryKeys;
    createdByIds;
    driveIds;
    driveTypes;
    opportunityIds;
    accountIds;
    statuses;
    driveContentions;
    submissionStartDate;
    submissionEndDate;
    driveStartDate;
    driveEndDate;
    types;
    ignoreHiddenDriveChangeRequestItems;
}

export {
    driveChangeRequestService,
    driveChangeRequestQueryModel
}