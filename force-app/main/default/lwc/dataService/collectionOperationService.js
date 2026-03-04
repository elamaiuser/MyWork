import { sObjectType, dataService, queryModelBase } from './base';
import { territoryService,  territoryQueryModel } from './territoryService';
import { territoryCollectionOperationService, territoryCollectionOperationQueryModel } from './territoryCollectionOperationService';

import * as autoMapper from 'c/autoMapper';
import dataStorageInstance from './dataStorage';
import auraProxy from 'c/auraProxy';
import { COLLECTION_OPERATION } from 'c/slwcConstants';

class collectionOperationService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'Biomed_Collection_Op_Center__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.addCondition({template: 'sked_Is_Deactivated__c = FALSE'});
      let exludedCONames = [COLLECTION_OPERATION.NON_COLLECTION_AREA];
      queryBuilder.addCondition({template: "Name NOT IN {0}", value: exludedCONames, type: "array_string"});
      if(query.recordIds && query.recordIds.length) {
        queryBuilder.addCondition({ template: "Id IN {0}", value: query.recordIds, type: "array_string" });
      }
      
      queryBuilder.orderClause = 'ORDER BY Name ASC';

      if (query.includes(sObjectType.REGION)) {
          let subQueryBuilder = query.getQueryBuilder("sked__Region__c");
      }

      if (query.includes(sObjectType.COLLECTION_OPERATION_STAGING_LOCATION)) {
        let subQueryBuilder = query.getQueryBuilder("sked_Collection_Op_Staging_Location__c");
      }

      if (query.includes(sObjectType.COLLECTION_OPERATION_OPTIMIZER_SETTING)) {
        let subQueryBuilder = query.getQueryBuilder("sked_CollectionOperationOptimizerSetting__c");
      }

      if (query.includes(sObjectType.COLLECTION_OPERATION_TIME_BLOCK)) {
        let subQueryBuilder = query.getQueryBuilder("Collection_Operation_Time_Block__c");
      }

      if (query.includes(sObjectType.COLLECTION_OPERATION_AVAILABILITY)) {
        let subQueryBuilder = query.getQueryBuilder("Collection_Operation_Availability__c");
      }

      if (query.includes(sObjectType.AVAILABILITY_PATTERN_ROLE)) {
        let subQueryBuilder = query.getQueryBuilder("Availability_Pattern_Role__c");
      }
  }

  getCollectionOperationData(query) {
      let collectionOpQuery = new collectionOperationQueryModel();
      let collectionOpQueryStr = this.buildQuery(collectionOpQuery);

      let territoryQuery = new territoryQueryModel();
      let territorySvc = new territoryService();
      let territoryQueryStr = territorySvc.buildQuery(territoryQuery);

      // let groupMemberQuery = new groupMemberQueryModel();
      // groupMemberQuery.userId = query.userId;
      // let groupMemberSvc = new groupMemberService();
      // let groupMemberQueryStr = groupMemberSvc.buildQuery(groupMemberQuery);

      let request = [
          { 'key': 'collectionOperation', 'query': collectionOpQueryStr },
          { 'key': 'territory', 'query': territoryQueryStr },
          // { 'key': 'groupMembers', 'query': groupMemberQueryStr }
      ];

      return this.queryDataByQueries(request).then((data) => {
        let collectionOperationData = data.find(element => element.key == 'collectionOperation');
        let collectionOperations = autoMapper.autoMapperInstance.mapToArray('Biomed_Collection_Op_Center__c', collectionOperationData.result);

        let territoryData = data.find(element => element.key == 'territory');
        let territories = autoMapper.autoMapperInstance.mapToArray('sked_Territory__c', territoryData.result);

        // let groupMemberData = data.find(element => element.key == 'groupMembers');
        // let groupMembers = autoMapper.autoMapperInstance.mapToArray('GroupMember', groupMemberData.result);
        // let mapCollectionOperationName = groupBy(groupMembers, item => {
        //     let tokens = (item.groupName || '').split(' - ');
        //     let collectionOperationName = tokens[0];
        //     return collectionOperationName;
        // });

        // collectionOperations = collectionOperations.filter(item => {
        //     return mapCollectionOperationName[item.name] && mapCollectionOperationName[item.name].length;
        // });

        let result = {
            territories: territories,
            collectionOperations: collectionOperations
        }

        dataStorageInstance.add(territories);
        dataStorageInstance.add(collectionOperations);
        return result;
      });
  }

  getCollectionOperationDataNew(query) {
    const { startDate, endDate } = query;

    let collectionOpQuery = new collectionOperationQueryModel();
    collectionOpQuery.startDate = startDate;
    collectionOpQuery.endDate = endDate;
    collectionOpQuery.subQueryIndicator = sObjectType.COLLECTION_OPERATION_TIME_BLOCK;
    let collectionOpQueryStr = this.buildQuery(collectionOpQuery);

    let territoryQuery = new territoryQueryModel();
    let territorySvc = new territoryService();
    territoryQuery.startDate = startDate;
    territoryQuery.endDate = endDate;
    let territoryQueryStr = territorySvc.buildQuery(territoryQuery);

    let territoryCollectionOperationSvc = new territoryCollectionOperationService();
    let territoryCollectionOperationQuery = new territoryCollectionOperationQueryModel();
    territoryCollectionOperationQuery.startDate = startDate;
    territoryCollectionOperationQuery.endDate = endDate;
    let territoryCollectionOperationQueryStr = territoryCollectionOperationSvc.buildQuery(territoryCollectionOperationQuery);

    let request = [
        { 'key': 'collectionOperation', 'query': collectionOpQueryStr },
        { 'key': 'territory', 'query': territoryQueryStr },
        { 'key': 'territoryCollectionOperation', 'query': territoryCollectionOperationQueryStr },
    ];

    return this.queryDataByQueries(request).then((data) => {
      let collectionOperationData = data.find(element => element.key == 'collectionOperation');
      let collectionOperations = autoMapper.autoMapperInstance.mapToArray('Biomed_Collection_Op_Center__c', collectionOperationData.result);

      let territoryData = data.find(element => element.key == 'territory');
      let territories = autoMapper.autoMapperInstance.mapToArray('sked_Territory__c', territoryData.result);

      let territoryCollectionOperationData = data.find(element => element.key == 'territoryCollectionOperation');
      let territoryCollectionOperations = autoMapper.autoMapperInstance.mapToArray('sked_Territory_Collection_Operation__c', territoryCollectionOperationData.result);

      let result = {
        territories,
        collectionOperations,
        territoryCollectionOperations
      }

      dataStorageInstance.add(territories);
      dataStorageInstance.add(collectionOperations);
      dataStorageInstance.add(territoryCollectionOperations);
      return result;
    });
  }

  getSkedRegionId(query) {
    return auraProxy.getInstance().getSkedRegionId(query);
  }

  getSkedRegionIdUsingTaxonomy(query) {//HRP-13791 start
    return auraProxy.getInstance().getSkedRegionIdUsingTaxonomy(query);
  }//HRP-13791 end
}

class collectionOperationQueryModel extends queryModelBase { 
  userId;
  recordIds;
  startDate;
  endDate;
}

export {
  collectionOperationService,
  collectionOperationQueryModel
}