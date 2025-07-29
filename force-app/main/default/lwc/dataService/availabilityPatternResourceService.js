import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';
import { isNullOrEmpty } from 'c/slwcUtils';

class availabilityPatternResourceService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked__Availability_Pattern_Resource__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

        if (query.resourceIds && query.resourceIds.length) {
            queryBuilder.addCondition({ template: "sked__Resource__c IN {0}", value: query.resourceIds, type: "array_string" });
        }
        if (query.patternIds && query.patternIds.length) {
            queryBuilder.addCondition({ template: "sked__Availability_Pattern__c IN {0}", value: query.patternIds, type: "array_string" });
        }
        if (query.startDate) {
            queryBuilder.addCondition({ template: "sked_Start_Date__c >= {0}", value: query.startDate });
        }
        if (query.endDate) {
            queryBuilder.addCondition({ template: "sked_End_Date__c <= {0}", value: query.endDate });
        }
        if (!isNullOrEmpty(query.resourceName)) {
            queryBuilder.addCondition({ template: "sked__Resource__r.Name LIKE '%{0}%'", value: query.resourceName.trim() });
        }
    }
   
}

class availabilityPatternResourceQueryModel extends queryModelBase {
    resourceIds;
    patternIds;
    startDate;
    endDate;
    resourceName;
}

export {
    availabilityPatternResourceService,
    availabilityPatternResourceQueryModel
}