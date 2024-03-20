import { dataService, queryModelBase } from './base';
import { holidayCollectionOperationService, holidayCollectionOperationQueryModel } from './holidayCollectionOperationService';
import * as autoMapper from 'c/autoMapper';
import dataStorageInstance from './dataStorage';

class holidayService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked__Holiday__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.global == true || query.global == false) {
          queryBuilder.addCondition({template: "sked__Global__c = {0}", value: query.global});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked__Start_Date__c <= {0}", value: query.endDate});
          queryBuilder.addCondition({template: "sked__End_Date__c >= {0}", value: query.startDate});
      }
  }

  getHolidays(collectionOperationIds, startDate, endDate) {
      let holidayCollectionOperationQuery = new holidayCollectionOperationQueryModel();
      holidayCollectionOperationQuery.collectionOperationIds = collectionOperationIds;
      holidayCollectionOperationQuery.startDate = startDate;
      holidayCollectionOperationQuery.endDate = endDate;
      let holidayCollectionOperationSvc = new holidayCollectionOperationService();
      let holidayCollectionOperationQueryStr = holidayCollectionOperationSvc.buildQuery(holidayCollectionOperationQuery);

      let globalHolidayQuery = new holidayQueryModel();
      globalHolidayQuery.startDate = startDate;
      globalHolidayQuery.endDate = endDate;
      globalHolidayQuery.global = true;
      let globalHolidayQueryStr = this.buildQuery(globalHolidayQuery);

      let request = [
          { 'key': 'HolidayCollectionOperation', 'query': holidayCollectionOperationQueryStr },
          { 'key': 'GlobalHoliday', 'query': globalHolidayQueryStr }
      ];

      return this.queryDataByQueries(request).then((data) => {
        let holidayCollectionOperationData = data.find(element => element.key == 'HolidayCollectionOperation');
        let holidayCollectionOperations = autoMapper.autoMapperInstance.mapToArray('sked_Holiday_Collection_Operation__c', holidayCollectionOperationData.result);

        let globalHolidayData = data.find(element => element.key == 'GlobalHoliday');
        let globalHolidays = autoMapper.autoMapperInstance.mapToArray('sked__Holiday__c', globalHolidayData.result);

        let holidays = [...globalHolidays];
        (holidayCollectionOperations || []).forEach((holidayCollectionOperation) => {
            holidays.push(holidayCollectionOperation.holiday);
        });

        dataStorageInstance.add(holidays);
        return holidays;
      });
  }
}
class holidayQueryModel extends queryModelBase {
  endDate;
  global;
  startDate;
}

export {
  holidayService,
  holidayQueryModel
}