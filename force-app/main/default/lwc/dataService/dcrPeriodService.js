import { dataService, queryModelBase } from './base';
import { dcrFieldService, dcrFieldQueryModel } from './dcrFieldService';
import { dcrRoleService, dcrRoleQueryModel } from './dcrRoleService';
import { dcrRoleFieldService, dcrRoleFieldQueryModel } from './dcrRoleFieldService';
import * as autoMapper from 'c/autoMapper';

class dcrPeriodService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_DCR_Period__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      queryBuilder.orderClause = 'ORDER BY sked_Sort_Order__c ASC';
  }

  getDcrData() {
      let dcrPeriodQuery = new dcrPeriodQueryModel();
      let dcrPeriodQueryStr = this.buildQuery(dcrPeriodQuery);

      let dcrFieldQuery = new dcrFieldQueryModel();
      let dcrFieldSvc = new dcrFieldService();
      let dcrFieldQueryStr = dcrFieldSvc.buildQuery(dcrFieldQuery);

      let dcrRoleQuery = new dcrRoleQueryModel();
      let dcrRoleSvc = new dcrRoleService();
      let dcrRoleQueryStr = dcrRoleSvc.buildQuery(dcrRoleQuery);

      let dcrRoleFieldQuery = new dcrRoleFieldQueryModel();
      let dcrRoleFieldSvc = new dcrRoleFieldService();
      let dcrRoleFieldQueryStr = dcrRoleFieldSvc.buildQuery(dcrRoleFieldQuery);

      let request = [
          { 'key': 'dcrPeriod', 'query': dcrPeriodQueryStr },
          { 'key': 'dcrField', 'query': dcrFieldQueryStr },
          { 'key': 'dcrRole', 'query': dcrRoleQueryStr },
          { 'key': 'dcrRoleField', 'query': dcrRoleFieldQueryStr }
      ];

      return this.queryDataByQueries(request).then((data) => {
        let dcrPeriodData = data.find(element => element.key == 'dcrPeriod');
        let dcrPeriods = autoMapper.autoMapperInstance.mapToArray('sked_DCR_Period__c', dcrPeriodData.result);

        let dcrFieldData = data.find(element => element.key == 'dcrField');
        let dcrFields = autoMapper.autoMapperInstance.mapToArray('sked_DCR_Field__c', dcrFieldData.result);

        let dcrRoleData = data.find(element => element.key == 'dcrRole');
        let dcrRoles = autoMapper.autoMapperInstance.mapToArray('sked_DCR_Role__c', dcrRoleData.result);

        let dcrRoleFieldData = data.find(element => element.key == 'dcrRoleField');
        let dcrRoleFields = autoMapper.autoMapperInstance.mapToArray('sked_DCR_Role_Field__c', dcrRoleFieldData.result);
        
        let result = {
            dcrPeriods : dcrPeriods,
            dcrFields : dcrFields,
            dcrRoles : dcrRoles,
            dcrRoleFields : dcrRoleFields
        }

        return result;
      });
  }
}

class dcrPeriodQueryModel extends queryModelBase  {}

export {
  dcrPeriodService,
  dcrPeriodQueryModel
}