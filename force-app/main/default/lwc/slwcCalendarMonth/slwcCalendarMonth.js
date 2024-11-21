import { LightningElement, api, track, wire} from 'lwc';
import { extend, isArray, cloneDeep, padStart, find } from 'c/lodash';
import { CurrentPageReference } from 'lightning/navigation';
import { classNames } from 'c/slwcUtils';
import { DateTime } from 'c/luxon';
import { CALENDAR_FIELD_TYPE, CALENDAR_EVENT_LEVEL } from 'c/slwcConstants';
import { calendarMonthHelper } from 'c/slwcHelpers';
import { fireEvent } from 'c/pubsub';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcDateUtils from 'c/slwcDateUtils';

const DEFAULT_CALENDAR_SETTINGS = {
  timezone: TIME_ZONE,
  calendarStep: 30,
  calendarStart: 0,
  calendarEnd: 2400,
  firstDay: 0
}

export default class SlwcCalendarMonth extends LightningElement {
  initialized = false;
  eventRegistered = false;
  @api hideLegend = false;
  @api settings = null;
  @api metadata = null;
  @api configData = null;
  @api disableCreateInPast = false;
  @api disableCreate = false;
  @wire(CurrentPageReference) pageRef;

  _selectedMonth = {};
  @api
  get selectedMonth() {
    return this._selectedMonth;
  }
  set selectedMonth(value) {
    this._selectedMonth = value;

    if (this.initialized) {
      this.gridData = this.processGridData(this._data) || {}
    }
  }

  _data = null;
  @track gridData = null;
  @api
  get calendarData() {
    return this._data;
  }
  set calendarData(data) {
    this._data = data;

    if (this.initialized) {
      this.gridData = this.processGridData(this._data) || {}
    }
  }

  get timezone() {
    const timezone = this.settings ? this.settings.timezone : null;
    if (!timezone) return null;
    return DateTime.local().setZone(timezone).toFormat('ZZZZ');
  }

  get dateUtils() {
    return slwcDateUtils.getInstance(this.settings);
  }
  
  _calendarHelper = null;
  get calendarHelper() {
    if (!this._calendarHelper) {
      this._calendarHelper = new calendarMonthHelper(this.settings);
    }
    return this._calendarHelper;
  }

  get customStyle() {
    return {
    }
  }

  get customClass() {
  }

  get today() {
    return DateTime.local().toJSDate();
  }

  get weekDays() {
    return this.calendarHelper.buildWeekDays();
  }

  get calendarWeeks() {
    if(!this.selectedMonth) return [];

    let calendarWeeks = this.calendarHelper.buildCalendarWeeks(this.selectedMonth, this.today);

    if(this.gridData) {
      calendarWeeks.forEach(week => {
        week.days.forEach(day => {
          day.canAddEvent = true;
          if(this.disableCreateInPast) {
            day.canAddEvent = !day.isInPast;
          }

          if(this.disableCreate) {
            day.canAddEvent = false;
          }
          
          day.allEvents = this.gridData.allEventsByDate[day.dateIso] || [];
          day.allEventsLength = day.allEvents.length;
        })
      })
    }
    return calendarWeeks;
  }

  constructor() {
    super();
  }

  connectedCallback() {
    this.settings = this.initSettings(this.settings)
    this.metadata = this.initMetadata(this.metadata)
    this.configData = this.initConfigData(this.configData)

    if (!this.initialized) {
      this.gridData = this.processGridData(this._data) || {}
      this.initialized = true;
    }
  }
  
  renderedCallback() {
    this.registerEvents();
  }

  disconnectedCallback() {
    this.unregisterEvents();
  }

  registerEvents = () => {
    if(this.eventRegistered) return;
  }

  unregisterEvents = () => {
  }

  initSettings = (settings) => {
    return  extend(DEFAULT_CALENDAR_SETTINGS, settings);
  }

  initMetadata = (metadata) => {
    return metadata;
  }

  initConfigData = (configData) => {
    return configData;
  }

  processGridData = (data) => {
    if(!this.settings) return null;

    var gridData = cloneDeep(data || {});
    var allDayEvents = [];
    var builtGridData = {
      today: this.today,
      timezone: this.settings.timezone,
      allDayEventsByDate: {},
      allDayEventsCount: 0,
      allEventsByDate: {}
    };

    var processData = (items, mapObject) => {
      if (isArray(items) && items.length > 0) {
        items.forEach((item) => {
          const startDate = this.calendarHelper.parseDateString(item.start);
          const endDate = this.calendarHelper.parseDateString(item.finish);
        
          //TODO
          // if (item.scheduleId) {
          //   item.schedule = _.find(gridData.schedules, { id: item.scheduleId });
          // }

          // if (this.calendarHelper.isAllDayEvent(item)) {
          //   allDayEvents.push(item);
          // } else {
          //   // var dateKey = dateUtil.dateToString(item.startDate);
          //   var dateKey = DateTime.fromJSDate(new Date(startDate.date)).toISODate();

          //   // push item to data map
          //   if (!isArray(mapObject[dateKey])) {
          //     mapObject[dateKey] = [];
          //   }

          //   mapObject[dateKey].push(item);
          // }

          let _endDate = cloneDeep(endDate);
          if(endDate.time === 0) {
            _endDate.endTime = 2400;
            _endDate.date.setDate(_endDate.date.getDate() - 1);
          }

          var diff = this.dateUtils.diffDays(startDate.date, _endDate.date);
          for (let i = 0; i <= diff; i++) {
            let tmpDate = DateTime.fromJSDate(startDate.date).plus({
              days: i
            }).toJSDate();
            let tempItem = cloneDeep(item);
            let tempStartDate = this.calendarHelper.parseDateString(tempItem.start);
            let tempEndDate = this.calendarHelper.parseDateString(tempItem.finish);

            tempStartDate.date = cloneDeep(tmpDate);
            tempStartDate.time = i === 0 ? startDate.time : 0;
            tempEndDate.date = cloneDeep(tmpDate);
            tempEndDate.time = i === diff ? endDate.time : 2400;

            if(tempEndDate.time === 2400 || tempEndDate.time === 0) {
              tempEndDate.time = 0;
              tempEndDate.date = DateTime.fromJSDate(tempEndDate.date).plus({
                days: 1
              }).toJSDate();
            }

            tempItem.start = this.calendarHelper.stringifyDateString(tempStartDate);
            tempItem.finish = this.calendarHelper.stringifyDateString(tempEndDate);

            let dateKey = DateTime.fromJSDate(tmpDate).toISODate();
            // push item to data map
            if (!isArray(mapObject[dateKey])) {
              mapObject[dateKey] = [];
            }

            mapObject[dateKey].push(tempItem);
          }
        });
      }
    };

    this.metadata.forEach(item => {
      if (!builtGridData[item.fieldName + 'ByDate']) {
        builtGridData[item.fieldName + 'ByDate'] = [];
      }

      processData(gridData[item.fieldName], builtGridData[item.fieldName + 'ByDate']);
    }) 

    // concat all events to a single array
    this.calendarWeeks.forEach(week => {
      week.days.forEach(day => {
        var eventsAndAvailability = this.metadata.reduce((result, item) => {
          return result.concat(builtGridData[item.fieldName + 'ByDate'][day.dateIso] || []);
        }, [])
        var allEvents, event;

        allEvents = extend([], builtGridData.allDayEventsByDate[day.dateIso]);

        if (eventsAndAvailability.length > 0) {
          for (var i = 0; i < allEvents.length; i++) {
            event = allEvents[i];
            if (event.redundant) {
              allEvents[i] = eventsAndAvailability[0];
              eventsAndAvailability.splice(0, 1);

              if (eventsAndAvailability.length === 0) {
                break;
              }
            }
          }

          if (eventsAndAvailability.length > 0) {
            allEvents = allEvents.concat(eventsAndAvailability);
          }
        }

        builtGridData.allEventsByDate[day.dateIso] = allEvents;
      })
    });

    return builtGridData;
  };

  handleAddEvent = (event) => {
    const dateIso = event.currentTarget.dataset.id;
    const addEvent = new CustomEvent('addevent', {
      detail: {
        start: {
          date: dateIso,
          time: 0
        },
        finish: {
          date: dateIso,
          time: 0
        }
      }
    });
    this.dispatchEvent(addEvent);
  }
}