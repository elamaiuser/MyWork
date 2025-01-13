import { mappingConfigContainerInstance, MAPPING_TYPE } from './mappingConfigContainer';
import { get, uniqueId, isEmpty, isString } from 'c/lodash';
import * as slwcUtils from 'c/slwcUtils';

class autoMapper {
    constructor() {
    }

    mapTo(sObjectApiName, sObj) {
        let config = mappingConfigContainerInstance.getMappingConfig(sObjectApiName);
        let object = new Object();
        object.key = uniqueId();
        object.objectType = config.objectType;
        
        config.fieldConfigs.forEach(element => {
            if (element.domainFieldName.indexOf(".") == -1) {
                let fieldVal = get(sObj, element.sObjectFieldPath, null);

                switch (element.mappingType) {
                    case MAPPING_TYPE.direct:
                        object[element.domainFieldName] = fieldVal;
                        break;

                    case MAPPING_TYPE.time:
                        if (!slwcUtils.isNullOrEmpty(fieldVal)) {
                            let timeVal = Number(fieldVal);
                            object[element.domainFieldName] = slwcUtils.convertTimeToTimeStr(timeVal);
                        }
                        break;

                    case MAPPING_TYPE.multiPicklist:
                        if (!slwcUtils.isNullOrEmpty(fieldVal)) {
                            object[element.domainFieldName] = isString(fieldVal) ? fieldVal.split(';') : fieldVal;
                        } else {
                            object[element.domainFieldName] = [];
                        }
                        break;

                    case MAPPING_TYPE.related:
                        if (fieldVal) {
                            object[element.domainFieldName] = this.mapTo(element.relatedSObjectName, fieldVal);
                        }
                        break;

                    case MAPPING_TYPE.relatedList:
                        if (fieldVal) {
                            object[element.domainFieldName] = this.mapToArray(element.relatedListSObjectName, fieldVal);
                        }
                        break;

                    default:
                        break;
                }
            }

        });
        return object;
    }

    mapToArray(sObjectApiName, sObj){
        let mappedItems = [];
        sObj.forEach(element => {
            let item = this.mapTo(sObjectApiName, element);
            mappedItems.push(item);
        });

        return mappedItems;
    }

    mapToSObject(sObjectApiName, model, updatedRecordMap = {}) {
        let config = mappingConfigContainerInstance.getMappingConfig(sObjectApiName);
        let sObject = { 'sobjectType': sObjectApiName };

        let sObjectWrapper = {
            sObj: sObject,
            isChanged: !updatedRecordMap[model.id] || !isEmpty(updatedRecordMap[model.id]), 
            relatedListWrappers: []
        }

        config.fieldConfigs.forEach(element => {
            if (element.sObjectFieldPath.indexOf(".") == -1) {
                let fieldVal = model[element.domainFieldName];
                if (fieldVal != undefined && fieldVal != null) {
                    let canMap = true;
                    if (config.readonlyFields.indexOf(element.sObjectFieldPath) > -1) {
                        canMap = false;
                    }
                    if (config.masterFields.indexOf(element.sObjectFieldPath) > -1 && model.id != null && model.id != undefined && model.id != '') {
                        canMap = false;
                    }
                    if (element.domainFieldName === 'id' && String(fieldVal).startsWith('temp_')) {
                        canMap = false;
                    }
                    
                    if (canMap == true) {
                        switch (element.mappingType) {
                            case MAPPING_TYPE.direct:
                                sObject[element.sObjectFieldPath] = fieldVal;
                                break;
            
                            case MAPPING_TYPE.time:
                                sObject[element.sObjectFieldPath] = slwcUtils.convertTimeStrToTime(fieldVal);
                                break;
            
                            case MAPPING_TYPE.multiPicklist:
                                sObject[element.sObjectFieldPath] = isString(fieldVal) ? fieldVal : fieldVal.join(';');
                                break;

                            case MAPPING_TYPE.relatedList:
                                let childModels = fieldVal;
                                let relatedListWrapper = {
                                    parentField: element.parentFieldName,
                                    sObjectWrappers: [],
                                    sObjectType: element.relatedListSObjectName
                                };
                                if (childModels.length && childModels.length > 0) {
                                    childModels.forEach((child) => {
                                        let childSObj = this.mapToSObject(element.relatedListSObjectName, child, updatedRecordMap);
                                        relatedListWrapper.sObjectWrappers.push(childSObj);
                                    });
                                }
                                sObjectWrapper.relatedListWrappers.push(relatedListWrapper);
                                break;
            
                            default:
                                break;
                        }
                    }
                }
            }
        });

        return sObjectWrapper;
    }

    initiateModel(sObjectApiName) {
        let config = mappingConfigContainerInstance.getMappingConfig(sObjectApiName);
        let object = new Object();
        object.key = Math.random().toString(36).substring(2, 15);
        config.fieldConfigs.forEach(element => {
            switch (element.mappingType) {
                case MAPPING_TYPE.relatedList:
                    object[element.domainFieldName] = [];
                    break;

                default:
                    object[element.domainFieldName] = null;
                    break;
            }
        });
        return object;
    }

}

const autoMapperInstance = new autoMapper();
Object.freeze(autoMapperInstance);

//export default autoMapperInstance;
export {
    autoMapperInstance,
    mappingConfigContainerInstance,
    MAPPING_TYPE
}