import { dataService, queryModelBase } from './base';
import { roleTimeVarianceService, roleTimeVarianceQueryModel } from './roleTimeVarianceService';
import { DateTime } from 'c/luxon';
import * as autoMapper from 'c/autoMapper';
import * as slwcUtils from 'c/slwcUtils';
import dataStorageInstance from './dataStorage';

class roleTimeDetailService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Role_Time_Detail__c';
  }

  getQueryConditions(query) {
    let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
    if (query.collectionOpIds && query.collectionOpIds.length) {
        queryBuilder.addCondition({template: "(sked_Type__c = 'Global' OR sked_Collection_Operation__c IN {0})", value: query.collectionOpIds, type: "array_string"});
    }
    if (query.daysOfWeek && query.daysOfWeek.length) {
        queryBuilder.addCondition({template: "sked_Days_of_Week__c INCLUDES{0}", value: query.daysOfWeek, type: "array_string"});
    }
    if (query.driveTypes && query.driveTypes.length) {
        queryBuilder.addCondition({template: "sked_Drive_Type__c IN {0}", value: query.driveTypes, type: "array_string"});
    }
    if (query.mobileTypes && query.mobileTypes.length) {
        queryBuilder.addCondition({template: "sked_Mobile_Type__c IN {0}", value: query.mobileTypes, type: "array_string"});
    }
    if (query.startDate && query.endDate) {
        queryBuilder.addCondition({template: "(sked_Effective_Start_Date__c = NULL OR sked_Effective_Start_Date__c <= {0})", value: query.endDate});
        queryBuilder.addCondition({template: "(sked_Effective_End_date__c = NULL OR sked_Effective_End_date__c >= {0})", value: query.startDate});
    }
  }

  getRoleTimeData(startDate, endDate, collectionOpIds, driveSiteIds, driveTypes, mobileTypes) {
      let roleTimeDetailQuery = new roleTimeDetailQueryModel();
      roleTimeDetailQuery.collectionOpIds = collectionOpIds;
      roleTimeDetailQuery.startDate = startDate;
      roleTimeDetailQuery.endDate = endDate;
      let daysOfWeek = [];
      if (!slwcUtils.isNullOrEmpty(startDate) && startDate === endDate) {
        let dayOfWeek = DateTime.fromFormat(startDate, 'yyyy-MM-dd').toFormat('cccc');
        daysOfWeek = [dayOfWeek];
      }
      roleTimeDetailQuery.daysOfWeek = daysOfWeek;
      roleTimeDetailQuery.driveTypes = driveTypes;
      roleTimeDetailQuery.mobileTypes = mobileTypes;
      let roleTimeDetailQueryStr = this.buildQuery(roleTimeDetailQuery);
      
      let roleTimeVariancelQuery = new roleTimeVarianceQueryModel();
      roleTimeVariancelQuery.driveSiteIds = driveSiteIds;
      roleTimeVariancelQuery.startDate = startDate;
      roleTimeVariancelQuery.endDate = endDate;
      roleTimeVariancelQuery.daysOfWeek = daysOfWeek;
      let roleTimeVarianceSvc = new roleTimeVarianceService();
      let roleTimeVariancelQueryStr = roleTimeVarianceSvc.buildQuery(roleTimeVariancelQuery);

      let request = [
          { 'key': 'RoleTimeDetail', 'query': roleTimeDetailQueryStr },
          { 'key': 'RoleTimeVariance', 'query': roleTimeVariancelQueryStr }
      ];

      return this.queryDataByQueries(request).then((data) => {
        let roleTimeDetailData = data.find(element => element.key == 'RoleTimeDetail');
        let roleTimeDetails = autoMapper.autoMapperInstance.mapToArray('sked_Role_Time_Detail__c', roleTimeDetailData.result);

        let roleTimeVarianceData = data.find(element => element.key == 'RoleTimeVariance');
        let roleTimeVariances = autoMapper.autoMapperInstance.mapToArray('sked_Role_Time_Variance__c', roleTimeVarianceData.result);

        let result = {
            roleTimeDetails: roleTimeDetails,
            roleTimeVariances: roleTimeVariances
        }

        dataStorageInstance.add(result.roleTimeDetails);
        dataStorageInstance.add(result.roleTimeVariances);

        return result;
      });
  }
}

class roleTimeDetailQueryModel extends queryModelBase {
  collectionOpIds;
  daysOfWeek;
  driveTypes;
  endDate;
  mobileTypes;
  startDate;
}

export {
  roleTimeDetailService,
  roleTimeDetailQueryModel
}