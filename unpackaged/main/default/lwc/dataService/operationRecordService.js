import { dataService, queryModelBase } from './base';
import { isNullOrEmpty } from 'c/slwcUtils';
import auraProxy from 'c/auraProxy';

class operationRecordService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Operation_Record__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.driveIds && query.driveIds.length) {
        queryBuilder.addCondition({template: "sked_Drive__c IN {0}", value: query.driveIds, type: "array_string"});
      }

      if (query.driveShiftIds && query.driveShiftIds.length) {
        queryBuilder.addCondition({template: "sked_Drive_Shift__c IN {0}", value: query.driveShiftIds, type: "array_string"});
      }

      if (query.driveTypes && query.driveTypes.length) {
        queryBuilder.addCondition({template: "sked_Drive_Type__c IN {0}", value: query.driveTypes, type: "array_string"});
      }

      if (query.collectionOperationIds && query.collectionOperationIds.length) {
        queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOperationIds, type: "array_string"});
      }

      if (query.driveStartDate) {
        queryBuilder.addCondition({ template: "sked_Drive_Date__c >= {0}", value: query.driveStartDate });
      }

      if (query.driveEndDate) {
        queryBuilder.addCondition({ template: "sked_Drive_Date__c <= {0}", value: query.driveEndDate });
      }
      
      if(!isNullOrEmpty(query.driveUfid)) {
        queryBuilder.addCondition({template: "sked_Drive__r.sked_UFID__c LIKE '%{0}%'", value: query.driveUfid.trim() });
      }

      let subQueryBuilder = query.getQueryBuilder("sked_Operation_Record_Staff__c");
  }

  generateOperationRecords = (params) => auraProxy.getInstance().generateOperationRecords(params);
  getResourceData = (params) => auraProxy.getInstance().operationRecord_getResourceData(params);
  populateExternalIds = (params) => auraProxy.getInstance().populateExternalIds(params);
  submitOperationRecord = (params) => auraProxy.getInstance().submitOperationRecord(params);
}

class operationRecordQueryModel extends queryModelBase { 
  driveIds;
  driveShiftIds;
  collectionOperationIds;
  driveTypes;
  driveStartDate;
  driveEndDate;
  driveUfid;
}

export {
  operationRecordService,
  operationRecordQueryModel
}