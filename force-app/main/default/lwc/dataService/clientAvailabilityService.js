import { dataService, queryModelBase } from './base';
import { recurringScheduleService } from './recurringScheduleService';
import { driveService, driveQueryModel } from './driveService';
import * as autoMapper from 'c/autoMapper';
import dataStorageInstance from './dataStorage';

class clientAvailabilityService extends dataService {
    constructor() {
        super();
        this.sObjectApiName = 'sked__Client_Availability__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.accountIds && query.accountIds.length) {
            queryBuilder.addCondition({ template: "sked__Account__c IN {0}", value: query.accountIds, type: "array_string" });
        }
        if (query.startDate && query.endDate) {
            queryBuilder.addCondition({ template: "DAY_ONLY(sked__Start__c) >= {0}", value: query.startDate });
            queryBuilder.addCondition({ template: "DAY_ONLY(sked__Start__c) <= {0}", value: query.endDate });
        }
        queryBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
    }

    getClientAvailability(query) {
        let clientAvailabilityQuery = new clientAvailabilityQueryModel();
        clientAvailabilityQuery.accountIds = [query.accountId];
        clientAvailabilityQuery.endDate = query.endDate;
        clientAvailabilityQuery.startDate = query.startDate;
        let clientAvailabilityQueryStr = this.buildQuery(clientAvailabilityQuery);

        let driveQuery = new driveQueryModel();
        driveQuery.accountIds = [query.accountId];
        driveQuery.endDate = query.endDate;
        driveQuery.startDate = query.startDate;
        let driveSvc = new driveService();
        let driveQueryStr = driveSvc.buildQuery(driveQuery);

        let request = [
            { 'key': 'ClientAvailability', 'query': clientAvailabilityQueryStr },
            { 'key': 'Drive', 'query': driveQueryStr }
        ];

        return this.queryDataByQueries(request).then((data) => {
            let clientAvailabilityData = data.find(element => element.key == 'ClientAvailability');
            let clientAvailabilities = autoMapper.autoMapperInstance.mapToArray('sked__Client_Availability__c', clientAvailabilityData.result);

            let driveData = data.find(element => element.key == 'Drive');
            let drives = autoMapper.autoMapperInstance.mapToArray('sked_Drive__c', driveData.result);

            let result = {
                clientAvailabilities: clientAvailabilities,
                drives: drives
            }

            dataStorageInstance.add(clientAvailabilities);
            dataStorageInstance.add(drives);
            return result;
        })
    }

    saveEvent(model, recurringData) {
        if (recurringData && recurringData.isRecurring) {
            let recurringSchedule = this.createRecurringEvents(model, recurringData);
            let recurringScheduleSvc = new recurringScheduleService();
            return recurringScheduleSvc.save(recurringSchedule);
        }
    }
}

class clientAvailabilityQueryModel extends queryModelBase {
    accountIds;
    endDate;
    startDate;
}

export {
    clientAvailabilityService,
    clientAvailabilityQueryModel
}