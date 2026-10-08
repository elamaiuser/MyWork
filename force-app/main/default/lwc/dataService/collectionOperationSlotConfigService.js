import { dataService, queryModelBase } from './base';

class collectionOperationSlotConfigService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = 'sked_Collection_Operation_Slot_Config__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (query.collectionOperationId) {
      queryBuilder.addCondition({ template: 'sked_Collection_Operation__c = {0}', value: query.collectionOperationId, type: "string" });
    }
  }
}

class collectionOperationSlotConfigQueryModel extends queryModelBase {
  collectionOperationId;
}

export {
  collectionOperationSlotConfigService,
  collectionOperationSlotConfigQueryModel
}
