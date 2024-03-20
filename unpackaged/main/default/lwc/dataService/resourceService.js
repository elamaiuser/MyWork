import { dataService, queryModelBase, sObjectType } from './base';
import auraProxy from 'c/auraProxy';

class resourceService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Resource__c';
  }
  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.collectionOpId) {
          queryBuilder.addCondition({template: "sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c = {0}", value: query.collectionOpId, type: "string"});
      }
      if (query.collectionOpIds && query.collectionOpIds.length) {
          queryBuilder.addCondition({template: "sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN {0}", value: query.collectionOpIds, type: "array_string"});
      }
      if (query.userIds && query.userIds.length) {
          queryBuilder.addCondition({template: "sked__User__c IN {0}", value: query.userIds, type: "array_string"});
      }
      if (query.resourceTypes && query.resourceTypes.length) {
          queryBuilder.addCondition({template: "sked__Resource_Type__c IN {0}", value: query.resourceTypes, type: "array_string"});
      }
      if (query.resourceRoles && query.resourceRoles.length) {
          queryBuilder.addCondition({template: "sked_Roles__c INCLUDES{0}", value: query.resourceRoles, type: "array_string"});
      }
      if (query.assetTypes && query.assetTypes.length) {
          queryBuilder.addCondition({template: 'sked_Asset_Type__c IN {0}', value: query.assetTypes, type: "array_string"});
      }
      queryBuilder.addCondition({template: 'sked__Is_Active__c = TRUE'});
      if (query.includes(sObjectType.AVAILABILITY)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Availability__c");
      }
      if (query.includes(sObjectType.CUSTON_AVAILABILITY)) {
          let subQueryBuilder = query.getQueryBuilder("sked_Custom_Availability__c");
      }
      if (query.includes(sObjectType.ACTIVITY)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Activity__c");
      }
      if (query.includes(sObjectType.JOB_ALLOCATION)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Job_Allocation__c");
          subQueryBuilder.addCondition({template: "sked__Status__c != 'Deleted'"});
      }
      if (query.includes(sObjectType.RESOURCE_TAG)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Resource_Tag__c");
          subQueryBuilder.addCondition({template: "(sked_Role_Status__c = NULL OR sked_Role_Status__c = 'Active')"});
      }
  }

  getPatternResources = (params) => auraProxy.getInstance().getPatternResources(params);
  getResourceTemplates = (params) => auraProxy.getInstance().getResourceTemplates(params);
  saveCallOut = (params) => auraProxy.getInstance().saveCallOut(params);
}
class resourceQueryModel extends queryModelBase {
  collectionOpId;
  collectionOpIds;
  resourceRoles;
  resourceTypes;
  assetTypes;
  userIds;
}

export {
  resourceService,
  resourceQueryModel
}