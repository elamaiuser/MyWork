import { dataService, queryModelBase, sObjectType } from './base';

class staffingDecisionMatrixService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Staffing_Decision_Matrix__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.isSubQuery) {
          queryBuilder.addCondition({template: "Id IN :allIds"});
      }

      if (query.includes(sObjectType.LUNCH_BREAK_DEFINITION)) {
          let subQueryBuilder = query.getQueryBuilder("sked_Lunch_Break_Definition__c");
      }
  }
}

class staffingDecisionMatrixQueryModel extends queryModelBase {
  isSubQuery;
}

export {
  staffingDecisionMatrixService,
  staffingDecisionMatrixQueryModel
}