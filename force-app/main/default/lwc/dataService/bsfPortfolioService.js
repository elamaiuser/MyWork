import { dataService, queryModelBase } from "./base";

class bsfPortfolioService extends dataService {
  constructor() {
    super();
    this.sObjectApiName = "BSF_Portfolio__c";
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);

    if (!query.includeExpired) {
        queryBuilder.addCondition({
            template: "Is_Expired__c = FALSE"
        });
    }
  }
}

class bsfPortfolioQueryModel extends queryModelBase {
    includeExpired;
}

export { bsfPortfolioService, bsfPortfolioQueryModel };