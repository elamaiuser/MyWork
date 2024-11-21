import { LightningElement, api } from 'lwc';
import { classNames} from 'c/slwcUtils';
import { isFunction, isArray, uniqueId, padStart, compact } from 'c/lodash';
import { CALENDAR_FIELD_TYPE } from 'c/slwcConstants';
import { DateTime } from 'c/luxon';
import * as slwcDateUtils from 'c/slwcDateUtils';

export default class SlwcCalendarMonthCard extends LightningElement {
  @api record = null;
  @api settings = null;
  @api metadata = null;
  @api configData = null;

  get dateUtils() {
    return slwcDateUtils.getInstance(this.settings);
  }

  get isDataValid() {
    const hasDataFields = this.ojectTypeMetadata && this.ojectTypeMetadata.infoFields && this.ojectTypeMetadata.infoFields.length;
    return this.record && hasDataFields;
  }

  get ojectTypeMetadata() {
    return (this.metadata && this.record) ? this.metadata.find(item => item.objectType === this.record.objectType) : null;
  }

  get isReadonly() {
    return this.ojectTypeMetadata && this.ojectTypeMetadata.readonly;
  }

  get customStyle() {
    if (!this.isDataValid) return;
    let eventTypeSetting = (this.configData && this.configData.eventTypeSettings) ?
      this.configData.eventTypeSettings.find(item => {
        const foundEventType = item.eventType === (isFunction(this.ojectTypeMetadata.eventTypeSettingsField) ? this.ojectTypeMetadata.eventTypeSettingsField(this.record) : this.record[this.ojectTypeMetadata.eventTypeSettingsField])
        return item.objectType === this.record.objectType && foundEventType
      }) : null;
    eventTypeSetting = eventTypeSetting || {};

    return {
      eventBlock: [
        `background-color: ${(this.ojectTypeMetadata.uiSettings || {}).monthCardBackgroundColor}`
      ].join(';'),
      eventTypeIndicator: [
        `background-color: ${eventTypeSetting.backgroundColor}`
      ].join(';')
    }
  }

  get customClass() {
    if (!this.isDataValid) return;

    return {
    }
  }
  
  get cardInfos() {
    if (!this.ojectTypeMetadata || !this.ojectTypeMetadata.infoFields || !this.record) return [];

    const record = this.record;
    let infos = [];
    this.ojectTypeMetadata.infoFields.forEach((field, index) => {
      if(isFunction(field.hideIf)) {
        if(field.hideIf(record)) {
          return;
        }
      }
      
      let value = this.buildInfo(field, record);
      if(value) {
        infos.push({
          key: uniqueId(),
          value: value,
          class: classNames('slds-truncate', {
            'event-name': index === 0,
            'event-meta-info': index !== 0
          })
        })
      }
    })

    return infos;
  }

  get popoverInfo() {
    if (!this.ojectTypeMetadata || !this.ojectTypeMetadata.popoverFields || !this.record) return null;
    
    const record = this.record;
    let headerInfos = [];
    let bodyInfos = [];
    let actions = [];

    this.ojectTypeMetadata.popoverFields.forEach((field, index) => {
      if(isFunction(field.hideIf)) {
        if(field.hideIf(record)) {
          return;
        }
      }

      let value = this.buildInfo(field, record);
      
      const newInfo = {
        key: uniqueId(),
        label: field.label,
        value: value
      };

      if(field.isHeader) {
        headerInfos.push(newInfo)
      } else {
        bodyInfos.push(newInfo)
      }
    })

    this.ojectTypeMetadata.popoverActions.forEach((action) => {
      if(action.hideIf && action.hideIf(this.record)) {

      } else {
        actions.push({
          ...action, 
          key: uniqueId()
        })
      }
    })

    return {
      record: record,
      iconName: this.ojectTypeMetadata.iconName,
      headerInfos: headerInfos,
      bodyInfos: bodyInfos,
      actions: actions
    };
  }
  connectedCallback() {
    //init settings
  }

  renderedCallback() {
    this.registerEvents();
  }

  disconnectedCallback() {
    this.unregisterEvents();
  }

  registerEvents = () => {

  }

  unregisterEvents = () => {

  }

  buildInfo = (field, record) => {
    const _getValue = (_field) => {
      if(isFunction(_field.value)) {
        return _field.value(record);
      } 
      return record[_field.value];
    }
    
    const parts = isArray(field.value) ? field.value : [field];

    return compact(parts.map((part) => {
      if(part.type === CALENDAR_FIELD_TYPE.DATETIME) {
        const date = this.dateUtils.dateIso2DateTime(_getValue(part));
        let timeString = DateTime.fromFormat(padStart(date.time, 3, '0'), 'Hmm').toFormat('h:mm a');
        return DateTime.fromJSDate(date.date).toFormat('MM/dd/yyyy') + ' ' + timeString;  
      }

      if(part.type === CALENDAR_FIELD_TYPE.DATE) {
        const date = this.dateUtils.dateIso2DateTime(_getValue(part));
        return DateTime.fromJSDate(date.date).toFormat('MM/dd/yyyy');
      }

      if(part.type === CALENDAR_FIELD_TYPE.TIME || part.type === CALENDAR_FIELD_TYPE.SHORT_TIME) {
        const timeFormat = part.type === CALENDAR_FIELD_TYPE.SHORT_TIME ? 'h:mma' : 'h:mm a';
        const date = this.dateUtils.dateIso2DateTime(_getValue(part));
        let timeString = DateTime.fromFormat(padStart(date.time, 3, '0'), 'Hmm').toFormat(timeFormat);
        if(part.type === CALENDAR_FIELD_TYPE.SHORT_TIME) {
          timeString = timeString.toLowerCase().replace(':00', '');
        }
        return timeString;  
      }

      if(part.type === CALENDAR_FIELD_TYPE.LOOKUP) {
        return _getValue(part).name;
      }

      return _getValue(part);
    })).join(' - ');
  }
}