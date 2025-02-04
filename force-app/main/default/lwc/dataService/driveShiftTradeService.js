import { isNullOrEmpty } from 'c/slwcUtils';
import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';
import { DRIVE_SHIFT_TRADE_TYPE } from 'c/slwcConstants';

class driveShiftTradeService extends dataService {

    constructor() {
        super();
        this.sObjectApiName = 'sked_Drive_Shift_Trade__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.driveStartDate && query.driveEndDate) {
            queryBuilder.addCondition({ template: "sked_Requesting_Staff_Drive_Date__c <= {0}", value: query.driveEndDate });
            queryBuilder.addCondition({ template: "sked_Requesting_Staff_Drive_Date__c >= {0}", value: query.driveStartDate });
        }

        if (query.activityStartDate && query.activityEndDate) {
            queryBuilder.addCondition({ template: "sked_Requesting_Staff_NCE__r.sked_Start_Date__c <= {0}", value: query.activityStartDate });
            queryBuilder.addCondition({ template: "sked_Requesting_Staff_NCE__r.sked_Start_Date__c >= {0}", value: query.activityEndDate });
        }

        if (query.tradingEventStartDate && query.tradingEventEndDate) {
            queryBuilder.addCondition({ template: `(
                (sked_Requesting_Staff_Trading_Event_Date__c <= ${query.tradingEventEndDate} AND sked_Requesting_Staff_Trading_Event_Date__c >= ${query.tradingEventStartDate}) OR 
                (sked_Trading_Staff_Trading_Event_Date__c <= ${query.tradingEventEndDate} AND sked_Trading_Staff_Trading_Event_Date__c >= ${query.tradingEventStartDate})
            )` });
        }

        if (query.submissionStartDate) {
            queryBuilder.addCondition({ template: `DAY_ONLY(CreatedDate) >= {0}`, value: query.submissionStartDate});
        }

        if (query.submissionEndDate) {
            queryBuilder.addCondition({ template: `DAY_ONLY(CreatedDate) <= {0}`, value: query.submissionEndDate});
        }

        if (query.eventName) {
            queryBuilder.addCondition({
                template: `(sked_Requesting_Staff_Trading_Event_Name__c LIKE {0} OR sked_Trading_Staff_Trading_Event_Name__c LIKE {0})`,
                value: queryBuilder.toSearchText(query.eventName),
                type: "string"
            });
        }

        if (query.ufid) {
            queryBuilder.addCondition({
                template: `(sked_Requesting_Staff_Drive_ID__c LIKE {0} OR sked_Trading_Staff_Drive_ID__c LIKE {0})`,
                value: queryBuilder.toSearchText(query.ufid),
                type: "string"
            });
        }

        if (query.staffName) {
            queryBuilder.addCondition({
                template: `(sked_Requesting_Staff__r.Name LIKE {0} OR sked_Trading_Staff__r.Name LIKE {0})`,
                value: queryBuilder.toSearchText(query.staffName),
                type: "string"
            });
        }

        if (query.collectionOperationIds && query.collectionOperationIds.length) {
            queryBuilder.addCondition({ template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string" });
        }
        if (query.territoryKeys && query.territoryKeys.length) {
            queryBuilder.addCondition({template: "sked_Territory_Key__c IN {0}", value: query.territoryKeys, type: "array_string"});
        }
        if (query.statuses && query.statuses.length) {
            queryBuilder.addCondition({ template: "sked_Status__c IN {0}", value: query.statuses, type: "array_string" });
        }
        if (query.types && query.types.length) {
            queryBuilder.addCondition({ template: "sked_Type__c IN {0}", value: query.types, type: "array_string" });
        }
        if (query.driveTypes && query.driveTypes.length) {
            queryBuilder.addCondition({ template: "sked_Requesting_Staff_Drive__r.sked_Type_of_Drive__c IN {0}", value: query.driveTypes, type: "array_string" });
        }

        if (query.createdByIds && query.createdByIds.length) {
            queryBuilder.addCondition({ template: "CreatedById IN {0}", value: query.createdByIds, type: "array_string" });
        }
        if (query.resourceIds && query.resourceIds.length) {
            queryBuilder.addCondition({ template: "(sked_Requesting_Staff__c IN {0} OR sked_Trading_Staff__c IN {0})", value: query.resourceIds, type: "array_string" });
        }
        if (isNullOrEmpty(query.onlyOneSideTrade)) {
            queryBuilder.addCondition({ template: "sked_Trading_Staff__c != NULL" });
        } else {
            if(query.onlyOneSideTrade) {
                queryBuilder.addCondition({ template: "sked_Trading_Staff__c = NULL" });
            }
        }
        if (query.excludedRequestingStaffIds && query.excludedRequestingStaffIds.length) {
            queryBuilder.addCondition({ template: "sked_Requesting_Staff__c NOT IN {0}", value: query.excludedRequestingStaffIds, type: "array_string" });
        }
        if (query.excludeAvailableDayOneSideTrade) {
            queryBuilder.addCondition({ template: "sked_Requesting_Staff_Trading_Type__c != {0}", value: DRIVE_SHIFT_TRADE_TYPE.AVAILABLE_DAY, type: "string"});
        }
    }

    validateShiftTrades = (params) => auraProxy.getInstance().validateShiftTrades(params);
    autoProcessRequest = (params) => auraProxy.getInstance().autoProcessRequest(params);
}

class driveShiftTradeQueryModel extends queryModelBase {
    collectionOperationIds;
    createdByIds;
    driveEndDate;
    driveStartDate;
    driveTypes;
    excludedRequestingStaffIds;
    onlyOneSideTrade;
    submissionEndDate;
    submissionStartDate;
    tradingEventStartDate;
    tradingEventEndDate
    resourceIds;
    staffName;
    statuses;
    territoryKeys;
    types;
    ufid;
    excludeAvailableDayOneSideTrade
}

export {
    driveShiftTradeService,
    driveShiftTradeQueryModel
}