import { dataService, queryModelBase, sObjectType } from './base';

class jobService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Job__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.isSubDriveQuery) {
          queryBuilder.addCondition({template: "sked_Drive__c IN :allIds"});
      }
      if (query.driveIds && query.driveIds.length) {
          queryBuilder.addCondition({template: "sked_Drive__c IN {0}", value: query.driveIds, type: "array_string"});
      }
      if (query.driveShiftIds && query.driveShiftIds.length) {
          queryBuilder.addCondition({template: "sked_Drive_Shift__c IN {0}", value: query.driveShiftIds, type: "array_string"});
      }
      if (query.collectionOperationIds && query.collectionOperationIds.length) {
          queryBuilder.addCondition({template: "sked__Region__r.sked_Biomed_Collection_Op_Center__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.accountIds && query.accountIds.length) {
          queryBuilder.addCondition({template: "sked__Account__c IN {0}", value: query.accountIds, type: "array_string"});
      }
      if (query.driveStatuses && query.driveStatuses.length) {
          queryBuilder.addCondition({template: "sked_Drive__r.sked_Status__c IN {0}", value: query.driveStatuses, type: "array_string"});
      }
      if (query.assetTypes && query.assetTypes.length) {
        queryBuilder.addCondition({template: "sked_Asset_Type__c IN {0}", value: query.assetTypes, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Drive__r.sked_Drive_Date__c >= {0}", value: query.startDate});
          queryBuilder.addCondition({template: "sked_Drive__r.sked_Drive_Date__c <= {0}", value: query.endDate});
      }
      queryBuilder.addCondition({template: "sked__Job_Status__c != 'Cancelled'"});
      
      if (query.includes(sObjectType.JOB_ALLOCATION)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Job_Allocation__c");
          if(!query.includeDeletedJobAllocs){
            subQueryBuilder.addCondition({template: "sked__Status__c != 'Deleted'"});
          }          
      }
      if (query.includes(sObjectType.JOB_TAG)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Job_Tag__c");
          //subQueryBuilder.addCondition({template: "sked_SystemCreated__c = FALSE"});
      }
      if (query.includes(sObjectType.SLOT)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Slot__c");
      }
  }
}

class jobQueryModel extends queryModelBase {
  accountIds;
  collectionOperationIds;
  driveIds;
  driveShiftIds;
  driveStatuses;
  endDate;
  startDate;
  assetTypes;

  isSubDriveQuery;
  includeDeletedJobAllocs;
}

export {
  jobService,
  jobQueryModel
}