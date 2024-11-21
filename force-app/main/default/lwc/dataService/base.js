import * as autoMapper from 'c/autoMapper';
import queryBuilder from './queryBuilder';
import { DateTime } from 'c/luxon';
import { orderBy, differenceBy, get } from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';
import dataStorageInstance from './dataStorage';
import auraProxy from 'c/auraProxy';

class dataService {
  sObjectApiName;

  constructor(sObjectApiName) {
    this.sObjectApiName = sObjectApiName;
  }

  compareRecords(sObjectApiName, newRecord, oldRecord) {
    if (newRecord && !oldRecord) return newRecord;
    if (!newRecord.id || newRecord.id.startsWith('temp_')) return newRecord;

    let changes = {};
    let config = autoMapper.mappingConfigContainerInstance.getMappingConfig(sObjectApiName);

    config.fieldConfigs.forEach(element => {
      // invalid domainFieldName 
      if (element.domainFieldName.indexOf(".") > -1) return;
      if (element.domainFieldName === 'id') return;
      if (config.readonlyFields.indexOf(element.sObjectFieldPath) > -1) return;
      if (config.masterFields.indexOf(element.sObjectFieldPath) > -1 && newRecord.id != null && newRecord.id != undefined && newRecord.id != '') return;
      if (!Object.hasOwn(newRecord, element.domainFieldName)) return;

      switch (element.mappingType) {
        case autoMapper.MAPPING_TYPE.time:
          if (newRecord[element.domainFieldName] !== oldRecord[element.domainFieldName]) {
            changes[element.domainFieldName] = slwcUtils.convertTimeStrToTime(newRecord[element.domainFieldName]);
          }
          break;

        case autoMapper.MAPPING_TYPE.related:
          if (newRecord[element.domainFieldName].id !== oldRecord[element.domainFieldName].id) {
            changes[element.domainFieldName] = newRecord[element.domainFieldName];
          }
          break;

        case autoMapper.MAPPING_TYPE.relatedList:
          break;

        default:
          if (newRecord[element.domainFieldName] !== oldRecord[element.domainFieldName]) {
            changes[element.domainFieldName] = newRecord[element.domainFieldName];
          }
          break;
      }
    });

    return changes;
  }

  checkChanges(sObjectApiName, newData, originalData, checkChanges = false) {
    const result = {
      flattenDeleted: [],
      updatedRecordMap: {}
    }

    const loop = (_sObjectApiName, _newData, _originalData, _result, settings = {
      deleteAll: false
    }) => {
      let config = autoMapper.mappingConfigContainerInstance.getMappingConfig(_sObjectApiName);

      config.fieldConfigs.forEach(element => {
        // invalid domainFieldName 
        if (element.domainFieldName.indexOf(".") > -1) return;
        if (!Object.hasOwn(_newData, element.domainFieldName)) return;

        switch (element.mappingType) {
          case autoMapper.MAPPING_TYPE.relatedList:
            let newRecords = get(_newData, element.domainFieldName, []);
            if (!newRecords) {
              newRecords = [];
            }
            let oldRecords = get(_originalData, element.domainFieldName, []);
            if (!oldRecords) {
              oldRecords = [];
            }
            let deletedRecords = [];
            if (settings.deleteAll) {
              deletedRecords = newRecords;
            } else {
              deletedRecords = differenceBy(oldRecords, newRecords, (record) => record.key);
            }

            let deletedKeys = [];
            if (deletedRecords.length) {
              deletedRecords.forEach(record => {
                if (record.id) {
                  let parentFieldConfig = autoMapper.mappingConfigContainerInstance.getMappingConfig(element.relatedListSObjectName);
                  let parentIdField = parentFieldConfig.fieldConfigs.find(config => config.sObjectFieldPath === element.parentFieldName);
                  _result.flattenDeleted.push({
                    id: record.id,
                    parentId: record[parentIdField.domainFieldName]
                  });
                }
                deletedKeys.push(record.key);
                loop(element.relatedListSObjectName, record, null, _result, {
                  deleteAll: true
                })
              })
            }

            let notDeletedNewRecords = newRecords.filter(record => !deletedKeys.includes(record.key));
            if (notDeletedNewRecords.length) {
              notDeletedNewRecords.forEach(newRecord => {
                let oldRecord = oldRecords.find(record => record.key === newRecord.key);
                loop(element.relatedListSObjectName, newRecord, oldRecord, _result);
              })
            }

            break;
          default:
            break;
        }
      });

      //if changed
      if(checkChanges) {
        if(_newData.id) {
          _result.updatedRecordMap[_newData.id] = this.compareRecords(_sObjectApiName, _newData, _originalData);
        }
      }
    }

    loop(sObjectApiName, newData, originalData, result);

    let wrapper = autoMapper.autoMapperInstance.mapToSObject(sObjectApiName, newData, result.updatedRecordMap);

    const transformedResult = {
      deleted: slwcUtils.buildTree(result.flattenDeleted),
      wrapper
    }

    return transformedResult;
  }

  createRecurringEvents(model, recurringData) {
    if (recurringData && recurringData.isRecurring) {
      let allEvents = [model];

      let mapWeekdayIndex = slwcUtils.getMapWeekdayIndex();
      let startDate = DateTime.fromISO(recurringData.fromDate, { zone: recurringData.timezoneSidId });
      let endDate = DateTime.fromISO(recurringData.toDate, { zone: recurringData.timezoneSidId });
      let startDateWeekday = startDate.toFormat('EEE').toLowerCase();
      let startDateWeekdayIndex = mapWeekdayIndex.get(startDateWeekday);
      let startEndDaysDifference = endDate.diff(startDate, ['days']).values.days;
      let noOfWeeks = recurringData.weeks.length;

      let sourceEventStart = DateTime.fromISO(model.start, { zone: recurringData.timezoneSidId });
      let sourceEventStartDate = sourceEventStart.startOf('day');
      let sourceEventFinish = DateTime.fromISO(model.finish, { zone: recurringData.timezoneSidId });

      recurringData.weeks.forEach((week, weekIndex) => {
        week.forEach((weekday) => {
          let weekdayIndex = mapWeekdayIndex.get(weekday);
          let daysDifference = weekdayIndex - startDateWeekdayIndex + 7 * weekIndex;
          while (daysDifference <= startEndDaysDifference) {
            if (daysDifference > 0) {
              let recurringDate = startDate.plus({ day: daysDifference });
              let daysDifferenceToSource = recurringDate.diff(sourceEventStartDate, ['days']).values.days;
              let recurringEvent = { ...model };
              recurringEvent.start = sourceEventStart.plus({ day: daysDifferenceToSource }).toUTC().toISO();
              recurringEvent.finish = sourceEventFinish.plus({ day: daysDifferenceToSource }).toUTC().toISO();
              allEvents.push(recurringEvent);
            }
            daysDifference += 7 * noOfWeeks;
          }
        });
      });
      allEvents = orderBy(allEvents, ['start'], ['asc']);
      if (!model.id) {
        let recurringSchedule = {};
        let recurringScheduleMappingConfig = autoMapper.mappingConfigContainerInstance.getMappingConfig('sked__Recurring_Schedule__c');
        let relatedListFieldConfig = recurringScheduleMappingConfig.fieldConfigs
          .find((fieldConfig) => fieldConfig.mappingType == autoMapper.MAPPING_TYPE.relatedList
            && fieldConfig.relatedListSObjectName == this.sObjectApiName);
        recurringSchedule[relatedListFieldConfig.domainFieldName] = allEvents;
        return recurringSchedule;
      }
    }
    return null;
  }

  delete(model) {
    return this.deleteList([model]);
  }

  deleteList(models) {
    let recordIds = [];
    models.forEach((model) => {
      recordIds.push(model.id);
    });

    return auraProxy.getInstance().dynamicDelete({
      sObjectApiName: this.sObjectApiName,
      recordIds: recordIds
    })
      .then((result) => {
        return result;
      })
  }

  save(model, {
    checkChanges
  } = {
    checkChanges: false
  }) {
    return this.saveList([model], {
      checkChanges
    });
  }

  saveList(models, {
    checkChanges
  } = {
    checkChanges: false
  }) {
    let wrappers = [];
    let deletedRecords = [];
    models.forEach((model) => {
      const originalData = model._dataKey ? dataStorageInstance.get(model._dataKey) : null;
      const { deleted, wrapper } = this.checkChanges(this.sObjectApiName, model, originalData, checkChanges);
      deletedRecords = deletedRecords.concat(deleted);

      wrappers.push(wrapper);
    });

    return auraProxy.getInstance().dynamicUpsert({
      wrappers: wrappers,
      deletedRecords: deletedRecords
    })
      .then(result => {
        return result;
      })
  }

  query(queryModel) {
    let queryStr = this.buildQuery(queryModel);
    return auraProxy.getInstance().executeQuery({
      query: queryStr
    })
      .then((data) => {
        let result = autoMapper.autoMapperInstance.mapToArray(this.sObjectApiName, data);
        dataStorageInstance.add(result);
        return result;
      })
  }

  buildQuery(queryModel) {
    let builder = queryModel.getQueryBuilder(this.sObjectApiName);
    builder.fields = [];
    builder.conditions = [];

    builder.setFromClause(this.sObjectApiName);

    if (this.getQueryConditions) {
      this.getQueryConditions(queryModel);
    }

    let mappingConfig = autoMapper.mappingConfigContainerInstance.getMappingConfig(this.sObjectApiName);
    mappingConfig.fieldConfigs.forEach(element => {
      switch (element.mappingType) {
        case autoMapper.MAPPING_TYPE.related:
          this.addRelatedObjectFields(builder, element.relatedSObjectName, element.sObjectFieldPath);
          break;

        case autoMapper.MAPPING_TYPE.relatedList:
          if (queryModel.mapObjectQueryBuilder.has(element.relatedListSObjectName)) {
            let subObjectBuilder = queryModel.mapObjectQueryBuilder.get(element.relatedListSObjectName);
            subObjectBuilder.fields = [];
            //subObjectBuilder.conditions = [];
            this.addRelatedListObjectFields(subObjectBuilder, element.relatedListSObjectName, element.sObjectFieldPath);

            let subQueryStatement = '({0})';
            subQueryStatement = subQueryStatement.replace('{0}', subObjectBuilder.toString());
            builder.addField(subQueryStatement);
          }
          break;

        default:
          builder.addField(element.sObjectFieldPath);
          break;
      }
    });

    if (queryModel.recordIds && queryModel.recordIds.length) {
      builder.cleanConditions();
      builder.addCondition({ template: "Id IN {0}", value: queryModel.recordIds, type: "array_string" });
    }
    else {
      if (queryModel.queryText && queryModel.searchColumns) {
        let searchConditions = [];
        let pattern = '{0} LIKE \'%{1}%\'';

        queryModel.searchColumns.forEach(searchColumn => {
          let searchCondition = pattern.replace('{0}', searchColumn).replace('{1}', queryModel.queryText);
          searchConditions.push(searchCondition);
        });

        let finalSearchCondition = searchConditions.join(' OR ');
        finalSearchCondition = searchConditions.length > 1 ? '(' + finalSearchCondition + ')' : finalSearchCondition;
        builder.conditions.push(finalSearchCondition);
      }
      if (queryModel.excludedRecordIds && queryModel.excludedRecordIds.length) {
        builder.addCondition({ template: "Id NOT IN {0}", value: queryModel.excludedRecordIds, type: "array_string" });
      }
    }

    if (queryModel.orderBy && queryModel.orderAscending) {
      let orderByFieldConfig = mappingConfig.fieldConfigs.find(item => item.domainFieldName === queryModel.orderBy);
      if (orderByFieldConfig) {
        let orderByClause = `ORDER BY ${orderByFieldConfig.sObjectFieldPath} ${queryModel.orderAscending}, ID asc`;
        builder.orderClause = orderByClause;
      }
    }

    if (queryModel.pageNo && queryModel.pageSize) {
      builder.limit = queryModel.pageSize;
      builder.offset = (queryModel.pageNo - 1) * queryModel.pageSize;
    }
    else {
      if (queryModel.limit) {
        builder.limit = queryModel.limit;
      }
      if (queryModel.offset) {
        builder.offset = queryModel.offset;
      }
    }
    return builder.toString();
  }

  buildCountQuery(queryModel) {
    let countBuilder = new queryBuilder();
    countBuilder.addField('Count()');
    countBuilder.setFromClause(this.sObjectApiName);
    if (this.getQueryConditions) {
      this.getQueryConditions(countBuilder, query);
    }

    if (queryModel.recordIds && queryModel.recordIds.length) {
      countBuilder.cleanConditions();
      countBuilder.addCondition({ template: "Id IN {0}", value: queryModel.recordIds, type: "array_string" });
    }
    else {
      if (queryModel.queryText && queryModel.searchColumns) {
        let searchConditions = [];
        let pattern = '{0} LIKE \'%{1}%\'';

        queryModel.searchColumns.forEach(searchColumn => {
          let searchCondition = pattern.replace('{0}', searchColumn).replace('{1}', queryModel.queryText);
          searchConditions.push(searchCondition);
        });

        let finalSearchCondition = searchConditions.join(' OR ');
        finalSearchCondition = searchConditions.length > 1 ? '(' + finalSearchCondition + ')' : finalSearchCondition;
        countBuilder.conditions.push(finalSearchCondition);
      }
      if (queryModel.excludedRecordIds && queryModel.excludedRecordIds.length) {
        countBuilder.addCondition({ template: "Id NOT IN {0}", value: queryModel.excludedRecordIds, type: "array_string" });
      }
    }

    return countBuilder.toString();
  }

  addRelatedObjectFields(objQueryBuilder, relatedSObjectName, relatedFieldAnchor) {
    let relatedObjectMappingConfig = autoMapper.mappingConfigContainerInstance.getMappingConfig(relatedSObjectName);
    relatedObjectMappingConfig.fieldConfigs.forEach(mapping => {
      if (mapping.mappingType == autoMapper.MAPPING_TYPE.direct || mapping.mappingType == autoMapper.MAPPING_TYPE.time) {
        objQueryBuilder.addField(relatedFieldAnchor + '.' + mapping.sObjectFieldPath);
      }
    });
  }

  addRelatedListObjectFields(subObjectBuilder, relatedListSObjectName, sObjectFieldPath) {
    subObjectBuilder.setFromClause(sObjectFieldPath);

    let subObjectConfig = autoMapper.mappingConfigContainerInstance.getMappingConfig(relatedListSObjectName);
    subObjectConfig.fieldConfigs.forEach(subObjectFieldConfig => {
      switch (subObjectFieldConfig.mappingType) {
        case autoMapper.MAPPING_TYPE.related:
          this.addRelatedObjectFields(subObjectBuilder, subObjectFieldConfig.relatedSObjectName, subObjectFieldConfig.sObjectFieldPath);
          break;

        case autoMapper.MAPPING_TYPE.relatedList:
          break;

        default:
          subObjectBuilder.addField(subObjectFieldConfig.sObjectFieldPath);
          break;
      }
    });
  }

  queryData() {
    return auraProxy.getInstance().executeQuery({
      query: this.getQuery()
    })
      .then((data) => {
        let result = autoMapper.autoMapperInstance.mapToArray(this.sObjectApiName, data);
        dataStorageInstance.add(result);
        return result;
      })
  }

  queryDataByQueries(queries) {
    return auraProxy.getInstance().executeQueries({
      request: queries
    }).then((data) => {
      return data;
    })
  }
  
  getSObjectName = (params) => auraProxy.getInstance().getSObjectName(params);
  getCustomSettings = (params) => auraProxy.getInstance().getCustomSettings(params);
  getPicklistOptions = (params) => auraProxy.getInstance().getPicklistOptions(params);
  getMapDependentOptions = (params) => auraProxy.getInstance().getMapDependentOptions(params);
}

class queryModelBase {
  recordIds;
  excludedRecordIds;
  subQueryIndicator;
  queryText;
  orderBy;
  orderAscending;
  pageNo;
  pageSize;
  limit;
  offset;
  searchColumns;
  mapObjectQueryBuilder;

  includes(sObjectEnum) {
    return this.subQueryIndicator && (this.subQueryIndicator & sObjectEnum) > 0;
  }

  getQueryBuilder(objectName) {
    if (!this.mapObjectQueryBuilder) {
      this.mapObjectQueryBuilder = new Map();
    }
    if (!this.mapObjectQueryBuilder.has(objectName)) {
      this.mapObjectQueryBuilder.set(objectName, new queryBuilder());
    }
    return this.mapObjectQueryBuilder.get(objectName);
  }
}


const ACCOUNT_AVAILABILITY_PREFERENCE = 1,
  AVAILABILITY = 2,
  ACTIVITY = 4,
  ACTIVITY_RESOURCE = 5,
  CUSTOM_AVAILABILITY = 8,
  DRIVE = 16,
  DRIVE_BAG = 32,
  DRIVE_CHANGE_REQUEST_ITEM = 64,
  DRIVE_SHIFT = 64,
  DRIVE_SHIFT_TAG = 128,
  EXCEPTION = 256,
  JOB = 512,
  JOB_ALLOCATION = 1024,
  JOB_TAG = 2048,
  LUNCH_BREAK_DEFINITION = 4096,
  OPPORTUNITY_CONTACT_ROLE = 8192,
  OPTIMIZATION_QUEUE_ITEM = 16384,
  REGION = 32768,
  RESOURCE_TAG = 65536,
  ROLE_DEFINITION = 131072,
  SLOT = 262144,
  TRAVEL_TIME_INDEX_ITEM = 524288,
  COLLECTION_OPERATION_STAGING_LOCATION = 1048576,
  DRIVE_CHANGE_REQUEST = 2097152,
  COLLECTION_OPERATION_OPTIMIZER_SETTING = 4194304,
  RESOURCE_OVERRIDE = 8388608;

class sObjectType {
  static get ACCOUNT_AVAILABILITY_PREFERENCE() {
    return ACCOUNT_AVAILABILITY_PREFERENCE;
  }
  static get AVAILABILITY() {
    return AVAILABILITY;
  }
  static get ACTIVITY() {
    return ACTIVITY;
  }
  static get ACTIVITY_RESOURCE() {
    return ACTIVITY_RESOURCE;
  }
  static get CUSTOM_AVAILABILITY() {
    return CUSTOM_AVAILABILITY;
  }
  static get DRIVE() {
    return DRIVE;
  }
  static get DRIVE_BAG() {
    return DRIVE_BAG;
  }
  static get DRIVE_CHANGE_REQUEST_ITEM() {
    return DRIVE_CHANGE_REQUEST_ITEM;
  }
  static get DRIVE_SHIFT() {
    return DRIVE_SHIFT;
  }
  static get DRIVE_SHIFT_TAG() {
    return DRIVE_SHIFT_TAG;
  }
  static get EXCEPTION() {
    return EXCEPTION;
  }
  static get JOB() {
    return JOB;
  }
  static get JOB_ALLOCATION() {
    return JOB_ALLOCATION;
  }
  static get JOB_TAG() {
    return JOB_TAG;
  }
  static get LUNCH_BREAK_DEFINITION() {
    return LUNCH_BREAK_DEFINITION;
  }
  static get OPPORTUNITY_CONTACT_ROLE() {
    return OPPORTUNITY_CONTACT_ROLE;
  }
  static get OPTIMIZATION_QUEUE_ITEM() {
    return OPTIMIZATION_QUEUE_ITEM;
  }
  static get REGION() {
    return REGION;
  }
  static get RESOURCE_TAG() {
    return RESOURCE_TAG;
  }
  static get ROLE_DEFINITION() {
    return ROLE_DEFINITION;
  }
  static get SLOT() {
    return SLOT;
  }
  static get TRAVEL_TIME_BREAKDOWN() {
    return TRAVEL_TIME_BREAKDOWN;
  }
  static get TRAVEL_TIME_INDEX_ITEM() {
    return TRAVEL_TIME_INDEX_ITEM;
  }
  static get COLLECTION_OPERATION_STAGING_LOCATION() {
    return COLLECTION_OPERATION_STAGING_LOCATION;
  }
  static get DRIVE_CHANGE_REQUEST() {
    return DRIVE_CHANGE_REQUEST;
  }
  static get COLLECTION_OPERATION_OPTIMIZER_SETTING() {
    return COLLECTION_OPERATION_OPTIMIZER_SETTING;
  }
  static get RESOURCE_OVERRIDE() {
    return RESOURCE_OVERRIDE;
  }
}

export {
  sObjectType,
  dataService,
  queryModelBase
}