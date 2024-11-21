import { LightningElement, api, track, wire } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { classNames, addAlphaToColor} from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { isFunction, isArray, uniqueId, padStart, compact } from 'c/lodash';
import { CALENDAR_FIELD_TYPE, CALENDAR_EVENT_LEVEL } from 'c/slwcConstants';
import { DateTime } from 'c/luxon';

export default class SlwcCalendarCard extends LightningElement {
  @api record = null;
  @api timeslotData = null;
  @api settings = null;
  @api metadata = null;
  @api configData = null;

  get dateUtils() {
    return slwcDateUtils.getInstance(this.settings);
  }

  get isDataValid() {
    return this.record && this.timeslotData;
  }

  get ojectTypeMetadata() {
    return (this.metadata && this.record) ? this.metadata.find(item => item.objectType === this.record.objectType) : null;
  }

  get isReadonly() {
    return this.ojectTypeMetadata && this.ojectTypeMetadata.readonly;
  }

  get hideInfos() {
    //temporary
    //TODO: need to find a way to make this work in both calendarCard and calendarCarcMonth with the same calendarMetadata.js
    return this.ojectTypeMetadata && this.ojectTypeMetadata.level === CALENDAR_EVENT_LEVEL.ONE;
  }

  get customStyle() {
    if (!this.isDataValid) return;
    const timeslotData = this.timeslotData;
    let eventTypeSetting = (this.configData && this.configData.eventTypeSettings) ?
      this.configData.eventTypeSettings.find(item => {
        const foundEventType = item.eventType === (isFunction(this.ojectTypeMetadata.eventTypeSettingsField) ? this.ojectTypeMetadata.eventTypeSettingsField(this.record) : this.record[this.ojectTypeMetadata.eventTypeSettingsField])
        return item.objectType === this.record.objectType && foundEventType
      }) : null;
    eventTypeSetting = eventTypeSetting || {};
    const alpha = (this.ojectTypeMetadata ? this.ojectTypeMetadata.opacity : null) || 100;

    return {
      eventContainerWrapper: [
        `position: ${this.ojectTypeMetadata && this.ojectTypeMetadata.level === CALENDAR_EVENT_LEVEL.THREE ? 'relative' : ''}`
      ].join(';'),
      eventContainer: [
        `height: ${timeslotData.h}rem`,
        `top: ${timeslotData.y}rem`,
        `left: ${timeslotData.x}%`,
        `width: ${timeslotData.w}%`
      ].join(';'),
      eventBox: [
        `background-color: ${addAlphaToColor(eventTypeSetting.backgroundColor, alpha)}`,
        `color: ${eventTypeSetting.color}`,
        `border-color: ${addAlphaToColor(eventTypeSetting.color, alpha)}`,
        `height: ${timeslotData.b}rem`,
        this.isReadonly ? 'border: none' : '',
        this.isReadonly ? 'margin-left: -1px' : '',
        this.isReadonly ? 'margin-right: -1px' : '',
        this.isReadonly ? 'border-radius: 0' : ''
      ].join(';')
    }
  }

  get customClass() {
    if (!this.isDataValid) return;
    const timeslotData = this.timeslotData;

    return {
      eventContainer: classNames('hco-rac-event-container', {
        'readonly': false, //item.readonly,
        'travel-time--oor': timeslotData.travelBeforeGrid,
        'start-time--oor': timeslotData.startBeforeGrid,
        'end-time--oor': timeslotData.endAfterGrid,
        'highlighted': false //$ctrl.highlightedException.job.id === item.id
      }),
      eventBox: classNames('hco-rac-event-box', {
        'hco-rac-event-box--small': timeslotData.b <= 3.5
      })
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
          class: classNames({
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