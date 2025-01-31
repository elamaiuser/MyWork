import { dataService, queryModelBase } from './base';

class groupMemberService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'GroupMember';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        queryBuilder.addCondition({template: "UserOrGroupId = '{0}'", value: query.userId});
        queryBuilder.addCondition({template: "Group.Type = '{0}'", value: 'Queue'});
    }
}
class groupMemberQueryModel extends queryModelBase {
    userId;
}

export {
  groupMemberService,
  groupMemberQueryModel
}