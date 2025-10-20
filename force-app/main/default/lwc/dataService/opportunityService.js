import { dataService, queryModelBase, sObjectType } from './base';
import auraProxy from 'c/auraProxy';

class opportunityService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'Opportunity';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
    if (query.collectionOperationIds && query.collectionOperationIds.length) {
        queryBuilder.addCondition({template: "Collections_Zip_Code__r.Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
    }
    if (query.driveTypes && query.driveTypes.length) {
        queryBuilder.addCondition({template: "Type_of_Drive__c IN {0}", value: query.driveTypes, type: "array_string"});
    }
    if (query.processingStatuses && query.processingStatuses.length) {
        queryBuilder.addCondition({template: "Processing_Status__c IN {0}", value: query.processingStatuses, type: "array_string"});
    }
    if (query.startDate) {
        queryBuilder.addCondition({template: "Drive_Date__c >= {0}", value: query.startDate});
    }
    if (query.endDate) {
        queryBuilder.addCondition({template: "Drive_Date__c <= {0}", value: query.endDate});
    }
    if (query.selectedDates && query.selectedDates.length) {
        queryBuilder.addCondition({template: "Drive_Date__c IN {0}", value: query.selectedDates, type: "array"});
    }
    queryBuilder.addCondition({template: "Drive_Status__c != 'Cancel'"});
    queryBuilder.orderClause = "ORDER BY Drive_Date__c ASC";

    if (query.includes(sObjectType.DRIVE)) {
    let subQueryBuilder = query.getQueryBuilder("sked_Drive__c");
    }
    if (query.includes(sObjectType.OPPORTUNITY_CONTACT_ROLE)) {
    let subQueryBuilder = query.getQueryBuilder("OpportunityContactRole");
    }
  }

  cloneOpportunity = (params) => auraProxy.getInstance().cloneOpportunity(params);
}

class opportunityQueryModel extends queryModelBase { 
  collectionOperationIds;
  driveTypes;
  endDate;
  selectedDates;
  startDate;
  processingStatuses;
}

export {
  opportunityService,
  opportunityQueryModel
}