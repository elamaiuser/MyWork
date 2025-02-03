import { dataService, queryModelBase } from './base';
import auraProxy from 'c/auraProxy';

class userService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'User';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.orderClause = 'ORDER BY Name ASC';
  }

  getLoginUser = (params) => auraProxy.getInstance().getLoginUser(params);
}

class userQueryModel extends queryModelBase {}

export {
  userService,
  userQueryModel
}