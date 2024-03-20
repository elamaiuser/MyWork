import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';
import { isNullOrEmpty } from 'c/slwcUtils';

class jobAllocationService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked__Job_Allocation__c';
    }
    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.collectionOperationIds && query.collectionOperationIds.length) {
            queryBuilder.addCondition({ template: "sked__Job__r.sked_Drive__r.sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string" });
        }
        if (query.driveIds && query.driveIds.length) {
            queryBuilder.addCondition({ template: "sked__Job__r.sked_Drive__c IN {0}", value: query.driveIds, type: "array_string" });
        }
        if (query.jobIds && query.jobIds.length) {
            queryBuilder.addCondition({ template: "sked__Job__c IN {0}", value: query.jobIds, type: "array_string" });
        }
        if (query.driveShiftIds && query.driveShiftIds.length) {
            queryBuilder.addCondition({ template: "sked__Job__r.sked_Drive_Shift__c IN {0}", value: query.driveShiftIds, type: "array_string" });
        }
        if (query.resourceIds && query.resourceIds.length) {
            queryBuilder.addCondition({ template: "sked__Resource__c IN {0}", value: query.resourceIds, type: "array_string" });
        }
        if (query.excludedResourceIds && query.excludedResourceIds.length) {
            queryBuilder.addCondition({ template: "sked__Resource__c NOT IN {0}", value: query.excludedResourceIds, type: "array_string" });
        }
        if (query.statuses && query.statuses.length) {
            queryBuilder.addCondition({ template: "sked__Status__c IN {0}", value: query.statuses, type: "array_string" });
        }
        if (query.resourceRoles && query.resourceRoles.length) {
            queryBuilder.addCondition({ template: "sked_Resource_Role__c IN {0}", value: query.resourceRoles, type: "array_string" });
        }
        if (query.resourceTypes && query.resourceTypes.length) {
            queryBuilder.addCondition({ template: "sked__Resource__r.sked__Resource_Type__c IN {0}", value: query.resourceTypes, type: "array_string" });
        }
        if (query.startDate && query.endDate) {
            queryBuilder.addCondition({ template: "sked_Start_Date__c >= {0}", value: query.startDate });
            queryBuilder.addCondition({ template: "sked_Start_Date__c <= {0}", value: query.endDate });
        }
        if (query.driveTypes && query.driveTypes.length) {
            queryBuilder.addCondition({ template: "sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c IN {0}", value: query.driveTypes, type: "array_string" });
        }
        if(!isNullOrEmpty(query.driveUfid)) {
            queryBuilder.addCondition({template: "sked__Job__r.sked_Drive__r.sked_UFID__c LIKE '%{0}%'", value: query.driveUfid.trim() });
        }
        if(!isNullOrEmpty(query.resourceName)) {
            queryBuilder.addCondition({template: "sked__Resource__r.Name LIKE '%{0}%'", value: query.resourceName.trim() });
        }

        if (query.callOut) {
            if (query.callOutTypes && query.callOutTypes.length) {
                queryBuilder.addCondition({ template: "sked_Call_Out_Type__c IN {0}", value: query.callOutTypes, type: "array_string" });
            } else {
                queryBuilder.addCondition({ template: "sked_Call_Out_Type__c != NULL" });
            }

            if (query.callOutReasonCodes && query.callOutReasonCodes.length) {
                queryBuilder.addCondition({ template: "sked_Call_Out_Reason_Code__c IN {0}", value: query.callOutReasonCodes, type: "array_string" });
            }
        }
        if (query.driveStartDate && query.driveEndDate) {
            queryBuilder.addCondition({ template: "sked__Job__r.sked_Drive__r.sked_Drive_Date__c >= {0}", value: query.driveStartDate });
            queryBuilder.addCondition({ template: "sked__Job__r.sked_Drive__r.sked_Drive_Date__c <= {0}", value: query.driveEndDate });
        }
    }

    getAssetDataCompact = (params) => auraProxy.getInstance().getAssetDataCompact(params);
    getResourceData = (params) => auraProxy.getInstance().getResourceData(params);
    getLinkedDrivesResourceIds = (params) => auraProxy.getInstance().getLinkedDrivesResourceIds(params);
}
class jobAllocationQueryModel extends queryModelBase {
    collectionOperationIds;
    driveIds;
    jobIds;
    driveShiftIds;
    endDate;
    statuses;
    resourceIds;
    excludedResourceIds;
    resourceRoles;
    resourceTypes;
    startDate;
    callOut;
    driveStartDate;
    driveEndDate;
    callOutType;
    callOutReasonCode;
    resourceName;
    driveUfid;
    driveTypes;
}

export {
    jobAllocationService,
    jobAllocationQueryModel
}