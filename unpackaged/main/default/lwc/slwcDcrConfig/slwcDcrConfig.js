import { LightningElement, track } from 'lwc';
import { keyBy, orderBy, groupBy,cloneDeep,mapKeys } from 'c/lodash';
import { getValueFromEvent } from 'c/slwcUtils';
import customLWCStyle from '@salesforce/resourceUrl/skedLWCCustomStyle'
import {
  loadStyle
} from 'lightning/platformResourceLoader';
import { dcrPeriodService,dcrFieldService, dcrRoleFieldService} from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const ACTIONS = {
  Y: 'Y',
  X: 'X',
  SYSTEM: 'System',
  PROCESS: 'Process',
  PROMPT: 'Prompt',
  EXCEPTION: 'Exception'
}

export default class SlwcDcrConfig extends LightningElement {
  @track initialized = false;
  @track showSpinner = false;
  @track dcrGridData = [];
  @track dcrGridHeader = [];
  @track dcrRoleFieldMap = {};
  @track dcrFieldMap = {};
  
  get actionOptions() {
    return Object.values(ACTIONS).map(action => {
      return {
        label: action,
        value: action
      }
    });
  }
  
  get customClass() {
    return {
    }
  }
  
  get customStyle() {
    return {
    }
  };

  connectedCallback() {
    this.init();
  }

  disconnectedCallback() {

  }

  renderedCallback() {
    Promise.all([
        loadStyle(this, customLWCStyle)
    ])
    .then(() => {
    })
  }

  showLoading() {
    this.showSpinner = true;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  init() {
    this.fetchDcrData()
    .then(() => {
      this.initialized = true;
    })
  }

  fetchDcrData() {
    this.showLoading();
    let service = new dcrPeriodService();
    return service.getDcrData()
    .then((dcrData) => {
      let { dcrGridData, dcrFieldMap, dcrRoleFieldMap } = this.buildGridData(dcrData);
      let dcrGridHeader = this.buildGridHeader(dcrData);
      this.dcrRoleFieldMap = dcrRoleFieldMap || {};
      this.dcrFieldMap = dcrFieldMap || {};
      this.dcrGridData = dcrGridData || [];
      this.dcrGridHeader = dcrGridHeader || [];

      this.backupData();
    })
    .catch((e) => console.log(e))
    .finally(() => this.hideLoading())
  }

  backupData() {
    this.backupDcrFieldMap = cloneDeep(this.dcrFieldMap);
    this.backupDcrRoleFieldMap = cloneDeep(this.dcrRoleFieldMap);
  }
  
  buildGridHeader(dcrData) {
    const {
      dcrPeriods,
      dcrRoles
    } = dcrData;

    let groupDcrRoles = groupBy(dcrRoles, 'dcrPeriodId');
    let result = [];
    orderBy(dcrPeriods, ['sortOrder'], ['asc']).forEach(period => {
      result.push({
        period: period,
        roles: orderBy(groupDcrRoles[period.id] || [], ['sortOrder'], ['asc']) 
      })
    })

    return result;
  }

  buildRoleFieldStyle (roleField) {
    if(!roleField) return;
    return {
      textColor: roleField.action === ACTIONS.X ? `color: #d23331;` : ''
    }
  }

  buildGridData(dcrData) {
    let {
      dcrRoleFields, 
      dcrFields,
      dcrPeriods,
      dcrRoles
    } = dcrData;
    let dcrFieldMap = keyBy(dcrFields, 'id')
    let dcrRoleMap = keyBy(dcrRoles, 'id')
    let dcrPeriodMap = keyBy(dcrPeriods, 'id')
    let dcrRoleFieldSorted = orderBy(dcrRoleFields, [
      (item) => dcrFieldMap[item.dcrFieldId].fieldLabel,
      'dcrFieldId', 
      (item) => dcrPeriodMap[dcrRoleMap[item.dcrRoleId].dcrPeriodId].sortOrder,
      (item) => dcrRoleMap[item.dcrRoleId].sortOrder,
    ],['asc', 'asc', 'asc', 'asc'])
    let dcrRoleFieldMap = {};

    let result = [];
    let lastFieldId = null;
    const roleCount = dcrRoles.length;
    
    (dcrPeriods || []).forEach((period, index) => {
      period.customStyle = {
        backgroundColor: `background-color: ${period.backgroundColor};`
      }

      dcrPeriodMap[period.id] = period;
    });

    dcrRoleFieldSorted.forEach((roleField, index) => {
      dcrRoleFieldMap[roleField.id] = roleField;

      roleField.customStyle = this.buildRoleFieldStyle(roleField);

      if (roleField.dcrFieldId === lastFieldId) return;

      lastFieldId = roleField.dcrFieldId
      result.push({
        field: dcrFieldMap[lastFieldId],
        dcrRoleFields: dcrRoleFieldSorted.slice(index, index + roleCount).map(roleField => {
          return {
            roleField: roleField,
            role: dcrRoleMap[roleField.dcrRoleId],
            period: dcrPeriodMap[dcrRoleMap[roleField.dcrRoleId].dcrPeriodId],
            disabled: !dcrFieldMap[lastFieldId].editable
          }
        })
      })
    })

    return {
      dcrGridData: result,
      dcrFieldMap: dcrFieldMap,
      dcrRoleFieldMap: dcrRoleFieldMap
    }
  }

  handleFieldChanged(event) {
    const id = event.currentTarget.dataset['id'];
    const record = this.dcrFieldMap[id];
    if(!record) return;

    record[event.currentTarget.name] = getValueFromEvent(event);
  }

  handleRoleFieldChanged(event) {
    const id = event.currentTarget.dataset['id'];
    const record = this.dcrRoleFieldMap[id];
    if(!record) return;

    record[event.currentTarget.name] = getValueFromEvent(event);
    record.customStyle = this.buildRoleFieldStyle(record);
  }

  handleSave() {
    let roleFieldSaves = [];
    let fieldSaves = [];
    mapKeys(this.dcrRoleFieldMap,(value, key) => {
      if(value.action != this.backupDcrRoleFieldMap[key].action){
        roleFieldSaves.push(value)
      }
    })
    mapKeys(this.dcrFieldMap,(value, key) => {
      if(value.dpUpdated != this.backupDcrFieldMap[key].dpUpdated){
        fieldSaves.push(value)
      }
    })
    let roleFieldservice = new dcrRoleFieldService();
    let fieldservice = new dcrFieldService();
    this.showLoading();
    Promise.all([
      roleFieldservice.saveList(roleFieldSaves),
      fieldservice.saveList(fieldSaves)
    ]).then((result) => {
      let success = true;
      result.forEach(item => {
        if(!item.success){
          success = false
        }
      })
      if(success){
          const event = new ShowToastEvent({
            message: 'Configuration Drive Changes has been saved successfully.',
            variant: 'success',
            mode: 'dismissable'
          });
          this.dispatchEvent(event);
      } else {
        const event = new ShowToastEvent({
          message: 'Error Saving Configuration Drive Changes',
          variant: 'error',
          mode: 'dismissable'
        });
        this.dispatchEvent(event);
      }
    })
    .catch((e) => console.log(e))
    .finally(() => this.hideLoading())
  }

  handleRefresh() {
    this.fetchDcrData();
  }
  
  mouseOverTimeout = null;
  handleMouseOverCell(event) {
    const id = event.currentTarget.dataset['id'];
    const record = this.dcrRoleFieldMap[id];

    if(this.mouseOverTimeout) {
      clearTimeout(this.mouseOverTimeout);
      this.mouseOverTimeout = null;
    }

    this.mouseOverTimeout = setTimeout(function() {
      if(record) {
        record.hovered = true;
      }
    }, 100)
  }
}