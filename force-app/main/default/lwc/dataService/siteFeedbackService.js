import { dataService, queryModelBase } from './base';

class siteFeedbackService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked_Site_Feedback__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.siteName) {
            queryBuilder.addCondition({
                template: `sked_Site__r.Name LIKE {0}`,
                value: queryBuilder.toSearchText(query.siteName),
                type: "string"
            });
        }

        if (query.createdByIds && query.createdByIds.length) {
            queryBuilder.addCondition({ template: "CreatedById IN {0}", value: query.createdByIds, type: "array_string" });
        }
        if (query.collectionOperationIds && query.collectionOperationIds.length) {
            queryBuilder.addCondition({ template: "sked_Drive__r.sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string" });
        }
        if (query.territoryKeys && query.territoryKeys.length) {
            queryBuilder.addCondition({ template: "sked_Drive__r.sked_Territory_Key__c IN {0}", value: query.territoryKeys, type: "array_string" });
        }
        if (query.siteIds && query.siteIds.length) {
            queryBuilder.addCondition({ template: "sked_Site__c IN {0}", value: query.siteIds, type: "array_string" });
        }
        if (query.jobIds && query.jobIds.length) {
            queryBuilder.addCondition({ template: "sked_Job__c IN {0}", value: query.jobIds, type: "array_string" });
        }
        if (query.statuses && query.statuses.length) {
            queryBuilder.addCondition({ template: "sked_Status__c IN {0}", value: query.statuses, type: "array_string" });
        }
        if (query.submissionStartDate && query.submissionEndDate) {
            queryBuilder.addCondition({ template: "DAY_ONLY(CreatedDate) <= {0}", value: query.submissionEndDate });
            queryBuilder.addCondition({ template: "DAY_ONLY(CreatedDate) >= {0}", value: query.submissionStartDate });
        }
        if (query.queryDRDFeedback) {
            queryBuilder.addCondition({ template: "sked_Job__c = NULL" });
        }
        if (query.excludeExpiry) {
            queryBuilder.addCondition({ template: "(sked_Effective_End_Date__c = NULL OR sked_Effective_End_Date__c >= TODAY)" });
        }
        queryBuilder.orderClause = 'ORDER BY CreatedDate DESC';
        console.log('queryBuilder :: ',queryBuilder);
        
    }
}

class siteFeedbackQueryModel extends queryModelBase {
    collectionOperationIds;
    territoryKeys;
    createdByIds;
    jobIds;
    siteIds;
    statuses;
    submissionEndDate;
    submissionStartDate;
    queryDRDFeedback;
    siteName;
    excludeExpiry;
}

export {
    siteFeedbackService,
    siteFeedbackQueryModel
}