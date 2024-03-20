import { dataService, queryModelBase } from './base';
import { driveService, driveQueryModel } from './driveService';
import * as autoMapper from 'c/autoMapper';
import dataStorageInstance from './dataStorage';

class locationAvailabilityService extends dataService {
  constructor() {
      super();
      this.sObjectApiName = 'sked_Location_Availability__c';
  }

  getQueryConditions(query) {
      let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
      if (query.locationIds && query.locationIds.length) {
          queryBuilder.addCondition({template: "sked_Location__c IN {0}", value: query.locationIds, type: "array_string"});
      }
      if (query.startDate && query.endDate) {
          queryBuilder.addCondition({template: "DAY_ONLY(sked_Start__c) >= {0}", value: query.startDate});
          queryBuilder.addCondition({template: "DAY_ONLY(sked_Start__c) <= {0}", value: query.endDate});
      }
      queryBuilder.orderClause = 'ORDER BY sked_Start__c ASC';
  }

  getLocationAvailability(query) {
      let locationAvailabilityQuery = new locationAvailabilityQueryModel();
      locationAvailabilityQuery.locationIds = [query.locationId];
      locationAvailabilityQuery.endDate = query.endDate;
      locationAvailabilityQuery.startDate = query.startDate;
      let locationAvailabilityQueryStr = this.buildQuery(locationAvailabilityQuery);
      
      let driveQuery = new driveQueryModel();
      driveQuery.locationIds = [query.locationId];
      driveQuery.endDate = query.endDate;
      driveQuery.startDate = query.startDate;
      let driveSvc = new driveService();
      let driveQueryStr = driveSvc.buildQuery(driveQuery);

      let request = [
          { 'key': 'LocationAvailability', 'query': locationAvailabilityQueryStr },
          { 'key': 'Drive', 'query': driveQueryStr }
      ];

      return this.queryDataByQueries(request).then((data) => {
        let locationAvailabilityData = data.find(element => element.key == 'LocationAvailability');
        let locationAvailabilities = autoMapper.autoMapperInstance.mapToArray('sked_Location_Availability__c', locationAvailabilityData.result);

        let driveData = data.find(element => element.key == 'Drive');
        let drives = autoMapper.autoMapperInstance.mapToArray('sked_Drive__c', driveData.result);

        let result = {
            locationAvailabilities: locationAvailabilities,
            drives: drives
        }

        dataStorageInstance.add(locationAvailabilities);
        dataStorageInstance.add(drives);
        return result;
      });
  }
}

class locationAvailabilityQueryModel extends queryModelBase { 
  locationIds;
  endDate;
  startDate;
}

export {
  locationAvailabilityService,
  locationAvailabilityQueryModel
}