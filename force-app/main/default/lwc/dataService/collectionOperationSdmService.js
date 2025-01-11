import { dataService, queryModelBase } from './base';
import { staffingDecisionMatrixService, staffingDecisionMatrixQueryModel } from './staffingDecisionMatrixService';
import * as autoMapper from 'c/autoMapper';
import dataStorageInstance from './dataStorage';

class collectionOperationSdmService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Collection_Operation_SDM__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
    if (query.collectionOpIds && query.collectionOpIds.length) {
      queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOpIds, type: "array_string"});
    }
    if (query.startDate && query.endDate) {
      queryBuilder.addCondition({template: "(sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= {0})", value: query.endDate});
      queryBuilder.addCondition({template: "(sked_Effective_End_date__c = NULL OR sked_Effective_End_date__c >= {0})", value: query.startDate});
    }
    if (query.sdmRecordTypes && query.sdmRecordTypes.length) {
      queryBuilder.addCondition({template: "sked_Staffing_Decision_Matrix__r.RecordType.Name IN {0}", value: query.sdmRecordTypes, type: "array_string"});
    }
  }

  getStaffingDecisionMatrices(collectionOpIds, sdmRecordTypes, startDate, endDate) {
    let collectionOperationSdmQuery = new collectionOperationSdmQueryModel();
    collectionOperationSdmQuery.collectionOpIds = collectionOpIds;
    collectionOperationSdmQuery.startDate = startDate;
    collectionOperationSdmQuery.endDate = endDate;
    collectionOperationSdmQuery.sdmRecordTypes = sdmRecordTypes;

    let collectionOperationSdmQueryStr = this.buildQuery(collectionOperationSdmQuery);

    let sdmQuery = new staffingDecisionMatrixQueryModel();
    sdmQuery.isSubQuery = true;
    let service = new staffingDecisionMatrixService();
    let sdmQueryStr = service.buildQuery(sdmQuery);

    let request = [
        { 'key': 'CollectionOperationSDM', 'query': collectionOperationSdmQueryStr, 'fieldToExtractId': 'sked_Staffing_Decision_Matrix__c' },
        { 'key': 'SDM', 'query': sdmQueryStr }
    ];

    return this.queryDataByQueries(request).then((data) => {
      let sdmData = data.find(element => element.key == 'SDM');
      let staffingDecisionMatrix = autoMapper.autoMapperInstance.mapToArray('sked_Staffing_Decision_Matrix__c', sdmData.result);

      let collectionOperationSDMData = data.find(element => element.key == 'CollectionOperationSDM');
      let collectionOperationSDM = autoMapper.autoMapperInstance.mapToArray('sked_Collection_Operation_SDM__c', collectionOperationSDMData.result);

      dataStorageInstance.add(staffingDecisionMatrix);
      dataStorageInstance.add(collectionOperationSDM);
      return ({
          staffingDecisionMatrix,
          collectionOperationSDM
      });
    });
  }
}

class collectionOperationSdmQueryModel extends queryModelBase { 
  collectionOpIds;
  startDate;
  endDate;
  sdmRecordTypes;
}

export {
  collectionOperationSdmService,
  collectionOperationSdmQueryModel
}