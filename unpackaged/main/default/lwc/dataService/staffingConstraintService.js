import { dataService, queryModelBase } from './base';

class staffingConstraintService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked_Staffing_Constraint__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.collectionOpIds) {
            queryBuilder.addCondition({template: "sked_Collection_Operation__c IN {0}", value: query.collectionOpIds, type: "array_string"});
        }
        if (query.driveTypes && query.driveTypes.length) {
            queryBuilder.addCondition({template: "sked_Drive_Type__c IN {0}", value: query.driveTypes, type: "array_string"});
        }
        if (query.startDate && query.endDate) {
            queryBuilder.addCondition({template: "sked_Date_of_Constraint__c >= {0}", value: query.startDate});
            queryBuilder.addCondition({template: "sked_Date_of_Constraint__c <= {0}", value: query.endDate});
        }
        if (query.selectedDates && query.selectedDates.length) {
            queryBuilder.addCondition({template: "sked_Date_of_Constraint__c IN {0}", value: query.selectedDates, type: "array"});
        }
    }
}

class staffingConstraintQueryModel extends queryModelBase {
    collectionOpIds;
    driveTypes;
    endDate;
    startDate;
    selectedDates;
}

export {
  staffingConstraintService,
  staffingConstraintQueryModel
}