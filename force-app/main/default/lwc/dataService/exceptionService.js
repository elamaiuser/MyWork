import { dataService, queryModelBase } from './base';

class exceptionService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'skedHC__Exception__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOperationIds && query.collectionOperationIds.length) {
          queryBuilder.addCondition({template: "(sked_Drive__r.sked_Collection_Operation__c IN {0} OR sked_Conflicted_Drive__r.sked_Collection_Operation__c IN {0} OR skedHC__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN {0})", value: query.collectionOperationIds, type: "array_string"});
      }
      if (query.territoryKeys && query.territoryKeys.length) {
        const collectionOperationIds = query.territoryKeys.map(territoryKey => {
          return `'${territoryKey.split(':')[1]}'`;
        });
        queryBuilder.addCondition({template: `(sked_Drive__r.sked_Territory_Key__c IN {0} OR skedHC__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN (${collectionOperationIds.join(',')}))`, value: query.territoryKeys, type: "array_string"});
      }
      if (query.arcRegionIds && query.arcRegionIds.length) {
        queryBuilder.addCondition({template: `sked_Linked_Drive__r.sked_ARC_Region__c IN {0}`, value: query.arcRegionIds, type: "array_string"});
      }
      if (query.exceptionCodes && query.exceptionCodes.length) {
          queryBuilder.addCondition({template: "sked_Exception_Code__c IN {0}", value: query.exceptionCodes, type: "array_string"});
      }
      if (query.priorities && query.priorities.length) {
          queryBuilder.addCondition({template: "sked_Priority__c IN {0}", value: query.priorities, type: "array_string"});
      }
      if (query.driveTypes && query.driveTypes.length) {
        queryBuilder.addCondition({template: "sked_Drive__r.sked_Type_of_Drive__c IN {0}", value: query.driveTypes, type: "array_string"});
      }
      if (query.activityTypes && query.activityTypes.length) {
        queryBuilder.addCondition({template: "skedHC__Activity__r.sked__Type__c IN {0}", value: query.activityTypes, type: "array_string"});
      }
      if (query.activitySubTypes && query.activitySubTypes.length) {
        queryBuilder.addCondition({template: "skedHC__Activity__r.sked_Subtype__c IN {0}", value: query.activitySubTypes, type: "array_string"});
      }
      if (query.operationTypes && query.operationTypes.length) {
        queryBuilder.addCondition({template: "sked_Drive__r.sked_Operation_Type__c IN {0}", value: query.operationTypes, type: "array_string"});
      }
      if (query.resourceDriveTypes && query.resourceDriveTypes.length) {
        queryBuilder.addCondition({template: "skedHC__Resource__r.sked_Drive_Type__c INCLUDES {0}", value: query.resourceDriveTypes, type: "array_string"});
      }
      if (query.driveIds && query.driveIds.length) {
          queryBuilder.addCondition({template: "sked_Drive__c IN {0}", value: query.driveIds, type: "array_string"});
      }
      if (query.statuses && query.statuses.length) {
          queryBuilder.addCondition({template: "skedHC__Status__c IN {0}", value: query.statuses, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
        if (query.exceptionType == "drive") {
          queryBuilder.addCondition({ template: `( 
            (sked_Drive__r.sked_Drive_Date__c <= ${query.endDate} AND sked_Drive__r.sked_Drive_Date__c >= ${query.startDate}) OR 
            (sked_Resource_Hours_Record__r.sked_Start_Date__c <= ${query.endDate} AND sked_Resource_Hours_Record__r.sked_End_Date__c >= ${query.startDate})
          )` });
        } else if (query.exceptionType == "linkedDrive") {
          queryBuilder.addCondition({ template: `( 
            sked_Linked_Drive__r.sked_Earliest_Drive_Date__c <= ${query.endDate} AND sked_Linked_Drive__r.sked_Latest_Drive_Date__c >= ${query.startDate}
          )` });
        } else if (query.exceptionType == "tbs") {
          queryBuilder.addCondition({ template: `( 
            sked_Drive__r.sked_Drive_Date__c <= ${query.endDate} AND sked_Drive__r.sked_Drive_Date__c >= ${query.startDate}
          )` });
        } else if (query.exceptionType == "activity") {
          queryBuilder.addCondition({ template: `( 
            skedHC__Activity__r.sked_Start_Date__c <= ${query.endDate} AND skedHC__Activity__r.sked_End_Date__c >= ${query.startDate}
          )` });
        }
      }
      
      if (query.exceptionType == "drive") {
        queryBuilder.orderClause = 'ORDER BY sked_Drive__r.sked_Drive_Date__c ASC, skedHC__Job__r.Name ASC NULLS LAST'
      } else if (query.exceptionType == "tbs") {
        queryBuilder.orderClause = 'ORDER BY sked_Drive__r.sked_Drive_Date__c ASC, sked_Drive_Shift__r.Name ASC NULLS LAST'
      } else if (query.exceptionType == "resource") {
        queryBuilder.orderClause = 'ORDER BY CreatedDate ASC';
      } else  if (query.exceptionType == "linkedDrive") {
        queryBuilder.orderClause = 'ORDER BY sked_Linked_Drive__r.sked_Earliest_Drive_Date__c ASC, sked_Linked_Drive__r.sked_Latest_Drive_Date__c ASC, sked_Linked_Drive__r.Name ASC NULLS LAST'
      } else  if (query.exceptionType == "activity") {
        queryBuilder.orderClause = 'ORDER BY skedHC__Activity__r.sked_Start_Date__c ASC, skedHC__Activity__r.sked_End_Date__c ASC, skedHC__Activity__r.sked_Activity_Title__c ASC NULLS LAST'
      }
  }
}

class exceptionQueryModel extends queryModelBase { 
  collectionOperationIds;
  territoryKeys;
  driveIds;
  arcRegionIds;
  endDate;
  exceptionCodes;
  priorities;
  driveTypes;
  operationTypes;
  resourceDriveTypes;
  startDate;
  statuses;
  exceptionType;
}

export {
  exceptionService,
  exceptionQueryModel
}