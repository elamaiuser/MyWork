import { dataService, queryModelBase } from './base';
import { calendarMessageCollectionOperationService, calendarMessageCollectionOperationQueryModel } from './calendarMessageCollectionOperationService';
import * as autoMapper from 'c/autoMapper';
import dataStorageInstance from './dataStorage';

class calendarMessageService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Calendar_Message__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.global == true || query.global == false) {
          queryBuilder.addCondition({template: "sked_Global__c = {0}", value: query.global});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "sked_Start_Date__c <= {0}", value: query.endDate});
          queryBuilder.addCondition({template: "sked_End_Date__c >= {0}", value: query.startDate});
      }
  }

  getCalendarMessages(collectionOperationIds, startDate, endDate) {
      let calendarMessageCollectionOperationQuery = new calendarMessageCollectionOperationQueryModel();
      calendarMessageCollectionOperationQuery.collectionOperationIds = collectionOperationIds;
      calendarMessageCollectionOperationQuery.startDate = startDate;
      calendarMessageCollectionOperationQuery.endDate = endDate;
      let calendarMessageCollectionOperationSvc = new calendarMessageCollectionOperationService();
      let calendarMessageCollectionOperationQueryStr = calendarMessageCollectionOperationSvc.buildQuery(calendarMessageCollectionOperationQuery);

      let globalCalendarMessageQuery = new calendarMessageQueryModel();
      globalCalendarMessageQuery.startDate = startDate;
      globalCalendarMessageQuery.endDate = endDate;
      globalCalendarMessageQuery.global = true;
      let globalCalendarMessageQueryStr = this.buildQuery(globalCalendarMessageQuery);

      let request = [
          { 'key': 'calendarMessageCollectionOperation', 'query': calendarMessageCollectionOperationQueryStr },
          { 'key': 'globalCalendarMessage', 'query': globalCalendarMessageQueryStr }
      ];

      return this.queryDataByQueries(request).then((data) => {
        let calendarMessageCollectionOperationData = data.find(element => element.key == 'calendarMessageCollectionOperation');
        let calendarMessageCollectionOperations = autoMapper.autoMapperInstance.mapToArray('sked_CalendarMessage_CollectionOperation__c', calendarMessageCollectionOperationData.result);

        let globalCalendarMessageData = data.find(element => element.key == 'globalCalendarMessage');
        let globalCalendarMessage = autoMapper.autoMapperInstance.mapToArray('sked_Calendar_Message__c', globalCalendarMessageData.result);

        let messages = [...globalCalendarMessage];
        (calendarMessageCollectionOperations || []).forEach((calendarMessageCollectionOperation) => {
          messages.push(calendarMessageCollectionOperation.calendarMessage);
        });

        dataStorageInstance.add(messages);
        return messages;
      });
  }
}
class calendarMessageQueryModel extends queryModelBase {
  endDate;
  global;
  startDate;
}

export {
  calendarMessageService,
  calendarMessageQueryModel
}