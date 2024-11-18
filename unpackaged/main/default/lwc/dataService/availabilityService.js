import { isNullOrEmpty } from 'c/slwcUtils';
import auraProxy from 'c/auraProxy';
import { dataService, queryModelBase, sObjectType } from './base';
import { jobAllocationQueryModel, jobAllocationService } from './jobAllocationService';
import { activityResourceQueryModel, activityResourceService } from './activityResourceService';
import { AVAILABILITY_STATUS, JOB_ALLOCATION_STATUS } from 'c/slwcConstants';
import * as autoMapper from 'c/autoMapper';

class availabilityService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked__Availability__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.startDate && query.endDate) {
            queryBuilder.addCondition({ template: "sked_Start_Date__c >= {0}", value: query.startDate });
            queryBuilder.addCondition({ template: "sked_Start_Date__c <= {0}", value: query.endDate });
        }
        
        if (query.statuses && query.statuses.length) {
            queryBuilder.addCondition({ template: "sked_Custom_Status__c IN {0}", value: query.statuses, type: "array_string" });
        }

        if (query.resourceIds && query.resourceIds.length) {
            queryBuilder.addCondition({ template: "sked__Resource__c IN {0}", value: query.resourceIds, type: "array_string" });
        }

        if(!isNullOrEmpty(query.isAvailable)) {
            queryBuilder.addCondition({ template: "sked__Is_Available__c = {0}", value: query.isAvailable, type: "boolean" });
        }

        if(!isNullOrEmpty(query.callOutTypes)) {
            if (query.callOutTypes && query.callOutTypes.length) {
                queryBuilder.addCondition({ template: "sked_Call_Out_Type__c IN {0}", value: query.callOutTypes, type: "array_string" });
            } else {
                queryBuilder.addCondition({ template: "sked_Call_Out_Type__c != NULL" });
            }
        }

        if (query.callOutReasonCodes && query.callOutReasonCodes.length) {
            queryBuilder.addCondition({ template: "sked_Call_Out_Reason_Code__c IN {0}", value: query.callOutReasonCodes, type: "array_string" });
        }

        if (query.callOutForActivity) {
            queryBuilder.addCondition({ template: "sked_Call_Out_for_Activity__c != NULL" });

            if (query.territoryKeys && query.territoryKeys.length) {
                queryBuilder.addCondition({ template: 'sked_Call_Out_for_Activity__r.sked_Territory_Key__c IN {0}', value: query.territoryKeys, type: "array_string" });
            }
        }

        if (query.callOutForJobAllocation) {
            queryBuilder.addCondition({ template: "sked_Call_Out_for_Job_Allocation__c != NULL" });

            if (query.territoryKeys && query.territoryKeys.length) {
                queryBuilder.addCondition({ template: 'sked_Call_Out_for_Job_Allocation__r.sked__Job__r.sked_Drive__r.sked_Territory_Key__c IN {0}', value: query.territoryKeys, type: "array_string" });
            }
        }
    }

    getUnavailabilityStatistic = (params) => auraProxy.getInstance().getUnavailabilityStatistic(params);
}

class availabilityQueryModel extends queryModelBase {
    territoryKeys
    endDate;
    selectedDates;
    startDate;
    callOutTypes;
    callOutReasonCodes;
    callOutForJobAllocation;
    callOutForActivity;
    statuses;
    resourceIds;
    isAvailable;
}

export {
    availabilityQueryModel,
    availabilityService
}