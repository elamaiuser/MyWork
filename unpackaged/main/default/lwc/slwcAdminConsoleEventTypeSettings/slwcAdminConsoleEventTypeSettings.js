import { LightningElement, track, api } from 'lwc';
import { classNames, getValueFromEvent, isNullOrEmpty } from 'c/slwcUtils';
import * as autoMapper from 'c/autoMapper';
import { eventTypeSettingService } from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const TAB = {
  JOB: {
    id: 'jobTypes',
    label: 'Job Type',
    objectType: 'job'
  },
  ACTIVITY: {
    id: 'activityTypes',
    label: 'Activity Type',
    objectType: 'activity'
  },
  AVAILABILITY: {
    id: 'availabilityTypes',
    label: 'Availability Type',
    objectType: 'availability'
  },
  CLIENT_AVAILABILITY: {
    id: 'clientAvailabilityTypes',
    label: 'Client Availability Type',
    objectType: 'clientAvailability'
  },
  CUSTOM_AVAILABILITY: {
    id: 'customAvailabilityTypes',
    label: 'Custom Availability Type',
    objectType: 'customAvailability'
  },
  LOCATION_AVAILABILITY: {
    id: 'locationAvailabilityType',
    label: 'Location Availability Type',
    objectType: 'locationAvailability',
    typeFixed: true
  }
}

const SETTINGS_INPUT_TYPE = {
  TEXT: 'text',
  SELECT: 'select',
  TIME_PICKER: 'time-picker',
  COLOR_PICKER: 'color-picker',
  CHECKBOX_TOGGLE: 'checkbox-toggle',
  NUMBER: 'number'
};

const SETTINGS_TABLE_COLUMNS = {
  EVENT_TYPE: {
    id: 'eventType',
    label: 'Event Type',
    class: 'slds-cell-wrap event-type__col',
    inputType: SETTINGS_INPUT_TYPE.TEXT,
    disableInFixedType: true
  },
  SHORT_NAME: {
    id: 'shortName',
    label: 'Short Name',
    class: 'slds-cell-wrap short-name__col',
    inputType: SETTINGS_INPUT_TYPE.TEXT,
    disableInFixedType: true
  },
  AVAILABLE_START: {
    id: 'availableStart',
    label: 'Available Start',
    class: 'slds-cell-wrap avail-start__col',
    inputType: SETTINGS_INPUT_TYPE.TIME_PICKER
  },
  AVAILABLE_END: {
    id: 'availableEnd',
    label: 'Available End',
    class: 'slds-cell-wrap avail-end__col',
    inputType: SETTINGS_INPUT_TYPE.TIME_PICKER
  },
  BACKGROUND_COLOR: {
    id: 'backgroundColor',
    label: 'Background Color',
    class: 'slds-cell-wrap background-color__col',
    inputType: SETTINGS_INPUT_TYPE.COLOR_PICKER
  },
  COLOR: {
    id: 'color',
    label: 'Color',
    class: 'slds-cell-wrap color__col',
    inputType: SETTINGS_INPUT_TYPE.COLOR_PICKER
  },
  STEP: {
    id: 'step',
    label: 'Step',
    class: 'slds-cell-wrap step__col',
    inputType: SETTINGS_INPUT_TYPE.NUMBER
  },
  IS_AVAILABLE: {
    id: 'isAvailable',
    label: 'Is Available',
    class: 'slds-cell-wrap is-available__col',
    inputType: SETTINGS_INPUT_TYPE.CHECKBOX_TOGGLE
  },
  SHOW_LEGEND: {
    id: 'showLegend',
    label: 'Show Legend',
    class: 'slds-cell-wrap show-legend__col',
    inputType: SETTINGS_INPUT_TYPE.CHECKBOX_TOGGLE
  },
  IS_ACTIVE: {
    id: 'isActive',
    label: 'Is Active',
    class: 'slds-cell-wrap is-active__col',
    inputType: SETTINGS_INPUT_TYPE.CHECKBOX_TOGGLE
  }
};

export default class SlwcAdminConsoleEventTypeSettings extends LightningElement {
  @api isReadonly = false;
  @track currentTab = TAB.JOB.id;
  @track eventTypeSettings = [];
  @track showSpinner = false;
  @track tabValidationMap = {};

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    })
  }

  get TAB() {
    return TAB;
  }

  get tabs() {
    let tabValidationMap = this.tabValidationMap || {};
    return Object.values(TAB).map((tab) => {
      tab.hasError = (tabValidationMap[tab.objectType] || {}).hasError;
      tab.class = classNames('slds-tabs_default__item slds-m-right_xxx-small', {
        'slds-is-active': tab.id === this.currentTab
      });
      return tab;
    })
  }

  get showEmptyMessage() {
    return (this.filteredEventTypeSettings || []).length <= 0;
  }

  get columns() {
    return Object.values(SETTINGS_TABLE_COLUMNS).map(column => {
      column.showTextInput = column.inputType === SETTINGS_INPUT_TYPE.TEXT;
      column.showTimeInput = column.inputType === SETTINGS_INPUT_TYPE.TIME_PICKER;
      column.showToggleInput = column.inputType === SETTINGS_INPUT_TYPE.CHECKBOX_TOGGLE;
      column.showColorInput = column.inputType === SETTINGS_INPUT_TYPE.COLOR_PICKER;
      column.showNumberInput = column.inputType === SETTINGS_INPUT_TYPE.NUMBER;
      return column;
    })
  }

  get filteredEventTypeSettings() {
    let objectTypeSetting = Object.values(TAB).find(item => item.id === this.currentTab);
    return (this.eventTypeSettings || []).filter(item => {
      return item.category === objectTypeSetting.objectType
    })
  }

  connectedCallback() {
    this.init();
  }

  disconnectedCallback() {
  }
  
  showLoading() {
    this.showSpinner = true;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  selectTab(event) {
    const newTab = event.currentTarget.dataset['value']; 
    this.currentTab = newTab; 

    setTimeout(() => this.validate())
  }

  parseTimeNumberToTimeStringIso(timeNumber) {
    if(isNullOrEmpty(timeNumber)) return null;

    let timeValParser = /^([0-1][0-9]|2[0-4])([0-5][0-9])$/;
    let	parsedTimeVal = timeValParser.exec(('0000' + timeNumber).substr(-4));
    let hVal = parsedTimeVal[1];
    let mVal = parsedTimeVal[2];
    
    return `${hVal}:${mVal}:00.000`;
  }

  parseTimeStringIsoToTimeNumber(timeStrIso) {
    if(isNullOrEmpty(timeStrIso)) return null;

    let	parsedTimeVal = timeStrIso.split(':');
    let hVal = parsedTimeVal[0];
    let mVal = parsedTimeVal[1];
    
    return Number(`${hVal}${mVal}`);
  }


  doTransformEventTypeSettings(items) {
    return items.map(item => {
      item.availableStart = this.parseTimeNumberToTimeStringIso(item.availableStart);
      item.availableEnd = this.parseTimeNumberToTimeStringIso(item.availableEnd);
      return item;
    })
  }

  fetchData() {
    this.showLoading();
    let service = new eventTypeSettingService();
    return service.getEventTypeSettings()
    .then((result) => {
      let settings = autoMapper.autoMapperInstance.mapToArray('sked_Event_Type_Setting__c', result.returnedData);
      this.eventTypeSettings = this.doTransformEventTypeSettings(settings);
    })
    .catch((e) => {})
    .finally(() => this.hideLoading())
  }

  handleOnChange(event) {
    let id = event.currentTarget.dataset['item'];
    let item = this.eventTypeSettings.find(item => item.id === id);
    if(!item) return;

    let value = getValueFromEvent(event);
    item[event.currentTarget.name] = value;

    this.validate();
  }

  refresh() {
    this.fetchData();
  }
  
  setErrors(inputQuery, errorMessage) {
    let allInputs = [];
    
    if(inputQuery) {
      allInputs = [...this.template.querySelectorAll(inputQuery)];
    }  else {
      allInputs = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')];
    }

    allInputs.forEach((inputCmp) => {
      inputCmp.setCustomValidity(errorMessage || '');
      inputCmp.reportValidity();
    });
  }

  validate() {
    this.setErrors();
    this.tabValidationMap = {};
    let valid = true;
    this.eventTypeSettings.forEach(item => {
      if(!this.tabValidationMap[item.category]) {
        this.tabValidationMap[item.category] = {
          hasError: false
        };
      }

      var requiredFields = ['item', 'backgroundColor', 'color'];
      requiredFields.forEach(field => {
        if(isNullOrEmpty(item[field])) {
          this.tabValidationMap[item.category].hasError = true;
          valid = false;
        }
      })

      if(!isNullOrEmpty(item.availableStart) && !isNullOrEmpty(item.availableEnd)) {
        if(item.availableStart >= item.availableEnd && item.availableEnd !== '00:00:00.000') {
          this.tabValidationMap[item.category].hasError = true;
          valid = false;

          this.setErrors(`.${item.id} .availableStart`, 'Invalid Available Start');
          this.setErrors(`.${item.id} .availableEnd`, 'Invalid Available End');
        }
      }
    })

    return valid;
  }

  save() {
    let valid = this.validate();
    if(!valid) {
      const event = new ShowToastEvent({
        message: 'Invalid settings input.',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(event);

      return;
    }

    let eventTypeSettings = this.eventTypeSettings.map(item => {
      return {...item, ...{
        availableStart: this.parseTimeStringIsoToTimeNumber(item.availableStart),
        availableEnd: this.parseTimeStringIsoToTimeNumber(item.availableEnd)
      }}
    })

    this.showLoading();
    let service = new eventTypeSettingService();
    service.saveList(eventTypeSettings)
    .then(result => {
      if(!result.success) {
        throw result;
      }
      
      const event = new ShowToastEvent({
        message: 'Event Type Settings has been saved successfully.',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(event);
    })
    .catch((e) => {})
    .finally(() => this.hideLoading())
  }

  init() {
    this.currentTab = TAB.JOB.id;
    this.refresh();
  }
}