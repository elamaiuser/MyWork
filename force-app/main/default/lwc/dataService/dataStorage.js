import { isArray, uniqueId, cloneDeep } from 'c/lodash';

class DataStorage {
  recordsMap = {};

  get = (dataKey) => {
    return this.recordsMap[dataKey];
  }

  add = (records) => {
    if(!records) return;
    records = isArray(records) ? records : [records];
    
    records.forEach(record => {
      if(!record._dataKey) {
        record._dataKey = uniqueId('data_key_');
      }

      this.recordsMap[record._dataKey] = cloneDeep(record);
    })
  }

  delete = (records) => {
    if(!records) return;
    records = isArray(records) ? records : [records];

    records.forEach(record => {
      if(record._dataKey) {
        delete this.recordsMap[record._dataKey];
      }
    })
  }
}

const dataStorageInstance = new DataStorage();
Object.freeze(dataStorageInstance);

export default dataStorageInstance;