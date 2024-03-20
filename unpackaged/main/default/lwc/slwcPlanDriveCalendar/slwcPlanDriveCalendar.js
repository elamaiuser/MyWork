import TIME_ZONE from '@salesforce/i18n/timeZone';
import {
  operationDriveLimitQueryModel,
  operationDriveLimitService,
  staffingConstraintQueryModel,
  staffingConstraintService,
  resourceQueryModel,
  resourceService
} from 'c/dataService';
import { DateTime } from 'c/luxon';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { ASSET_TYPE, DRIVE_TYPE, RESOURCE_TYPE, PLAN_DRIVE_SLOT_BACKGROUND_COLOR_SETTING, PLAN_DRIVE_SLOT_COLOR_SETTING } from 'c/slwcConstants';
import { calendarMonthHelper, planDriveDateHelper } from 'c/slwcHelpers';
import { classNames } from 'c/slwcUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, track, wire } from 'lwc';
import { DriveHelper } from 'c/slwcDriveGenerator';
import { groupBy, uniqueId, extend } from 'c/lodash';
import * as slwcAvailator from 'c/slwcAvailator';
import * as slwcDateUtils from 'c/slwcDateUtils';

const DEFAULT_CALENDAR_SETTINGS = {
  timezone: TIME_ZONE,
  firstDay: 0
}

export default class SlwcPlanDriveCalendar extends LightningElement {
  initialized = false;

  @wire(CurrentPageReference) pageRef;

  @api defaultDate = null;
  
  _selectedMonth = null;
  @api
  get selectedMonth() {
    return this._selectedMonth;
  }
  set selectedMonth(value) {
    this._selectedMonth = value;

    if (this.initialized) {
      this.rebuildCalendar();
    }
  }

  _opportunity = null;
  @api
  get opportunity() {
    return this._opportunity;
  }
  set opportunity(value) {
    this._opportunity = value;

    if (this.initialized) {
      this.rebuildCalendar();
    }
  }
  
  @api masterData = {};

  driveHelper = new DriveHelper();

  _calendarHelper = null;
  get calendarHelper() {
    if (!this._calendarHelper) {
      this._calendarHelper = new calendarMonthHelper(DEFAULT_CALENDAR_SETTINGS);
    }
    return this._calendarHelper;
  }

  _planDriveHelper = null;
  get planDriveHelper() {
    if (!this._planDriveHelper) {
      this._planDriveHelper = new planDriveDateHelper(DEFAULT_CALENDAR_SETTINGS);
    }
    return this._planDriveHelper;
  }

  @track collectionOperations = [];
  @track dayStatusMapping = {};
  @track dayAccountAvailabilityMapping = {};
  @track showSpinnerCount = 0;
  
  get showSpinner() {
    return this.showSpinnerCount > 0;
  }

  get customStyle() {
    return {
    }
  }

  get customClass() {
    return {
    }
  }

  get today() {
    return DateTime.local().toJSDate();
  }

  get celendarHeader() {
    if(!this.selectedMonth) return null;
    const selectedMonth = DateTime.fromString(this.selectedMonth, 'yyyy-MM-dd').toJSDate();
    return DateTime.fromJSDate(selectedMonth).toFormat('MMMM yyyy');
  }

  get collectionOperationIds() {
    return (this.collectionOperations || []).map(item => item.id);
  }
  
  get weekDays() {
    return this.calendarHelper.buildWeekDays(true);
  }

  get calendarWeeks() {
    let selectedMonth = this.selectedMonth || DateTime.local().toISODate()
    if(!selectedMonth) return [];

    let calendarWeeks = this.calendarHelper.buildCalendarWeeks(selectedMonth, this.today);

    calendarWeeks.forEach(week => {
      week.days.forEach(day => {
        this.buildSlot(day, this.dayAccountAvailabilityMapping);
        this.buildDots(day, this.dayStatusMapping);
      })
    })

    return calendarWeeks;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    })
  }
  
  connectedCallback() {
    //init settings

    if (!this.initialized) {
      this.rebuildCalendar();
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
    registerListener('planDrive:forceRefresh', this.rebuildCalendar, this);
  }

  unregisterEvents = () => {
    unregisterAllListeners(this);
  }

  exceptionHandler = (error) => {
    if (error && error.message) {
      this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
      }));
    }
  }

  showLoading = () => {
    this.showSpinnerCount++;
  }

  hideLoading = () => {
      this.showSpinnerCount--;
      if(this.showSpinnerCount < 0) {
          this.showSpinnerCount = 0;
      } 
  }

  buildSlot = (day, dayAccountAvailabilityMapping = {}) => {
    if (!day || day.isOutOfMonth) return;
    
    const dayAccountAvailability = dayAccountAvailabilityMapping[day.dateIso] || {};
    
    day = extend(day, {
      class: classNames(day.class, {
        'selected': day.dateIso === this.defaultDate
      }),
      slotStyle: [
        `background-color: ${PLAN_DRIVE_SLOT_BACKGROUND_COLOR_SETTING[dayAccountAvailability.status]}`
      ].join(';')
    })

    return day;
  }

  buildDots = (day, dayStatusMapping) => {
    day.dots = [];

    if(!day || !dayStatusMapping || day.isOutOfMonth) return;

    const isAvailable = !!(dayStatusMapping[day.dateIso] || {}).isAvailable;
    if(!day.dots) {
      day.dots = [];
    }

    day.dots.push({
      key: uniqueId('dot_'),
      style: [
        `background-color: ${PLAN_DRIVE_SLOT_COLOR_SETTING[isAvailable]}`
      ].join(';')
    })

    return day;
  }

  rebuildCalendar = () => {
    if(!this.opportunity || !this.opportunity.driveSite || !this.selectedMonth) {
      this.dayStatusMapping = {};
      this.dayAccountAvailabilityMapping = {};
      return;
    }

    const selectedMonth = this.selectedMonth;
    const { startDate, endDate } = this.planDriveHelper.getDateRange(selectedMonth);
    this.collectionOperations = this.planDriveHelper.getCollectionOperations(this.opportunity.driveSite, startDate, endDate);

    this.showLoading();
    Promise.resolve()
      .then(() => {
        return Promise.all([
          this.retrieveDriveLimits(),
          this.retrieveStaffingConstraintData(),
          this.retrieveAssets()
        ])
      })
      .then(([driveLimitResult, staffingConstraints, assetsData]) => {
        const { mapEquipmentsByDate, mapVehiclesByDate } = assetsData;
        return this.planDriveHelper.initialize({
          opportunity: this.opportunity,
          collectionOperations: this.collectionOperations,
          startDate: startDate,
          endDate: endDate,
          driveLimits: driveLimitResult,
          staffingConstraints: staffingConstraints,
          mapEquipmentsByDate,
          mapVehiclesByDate,
          accountAvailabilityPreferences: (this.opportunity && this.opportunity.account) ? this.opportunity.account.accountAvailabilityPreferences : [],
        })
      })
      .then(() => {
        this.dayStatusMapping = this.planDriveHelper.generateDayStatusMapping(startDate, endDate);
        this.dayAccountAvailabilityMapping = (this.opportunity && this.opportunity.account) ? this.planDriveHelper.generateDayAccountAvailabilityMapping(startDate, endDate) : [];
      })
      .catch(error => this.exceptionHandler(error, true))
      .finally(this.hideLoading)
  }

  handleSelectDate = (event) => {
    const selectedDate = event.currentTarget.dataset['value'];
    if(!selectedDate) return;

    const data = this.dayStatusMapping[selectedDate];
    const dispatchEvent = new CustomEvent('selectdate', {
      bubbles: true,
      composed: true,
      detail: {
        selectedDate: selectedDate,
        data: data
      }
    });

    this.dispatchEvent(dispatchEvent);
  }

  retrieveAssets() {
    if (!this.collectionOperationIds.length) {
      return Promise.resolve();
    }

    const selectedMonth = this.selectedMonth || DateTime.local().toISODate()
    const { startDate, endDate } = this.planDriveHelper.getDateRange(selectedMonth);
    const diff = this.dateUtils.diffDays(startDate, endDate);
    const jobs = [];
    for (let i = 0; i <= diff; i++) {
      let currentDay = DateTime.fromFormat(startDate, 'yyyy-MM-dd', {
        zone: TIME_ZONE
      }).plus({
        days: i
      });

      const start = currentDay.toUTC().toISO();
      const finish = currentDay.plus({
        hours: 23,
        minutes: 59
      }).toUTC().toISO();

      jobs.push({
        id: uniqueId(`temp_job_`),
        start: start,
        finish: finish,
        driveDate: currentDay.toISODate(),
        collectionOperationIds: this.collectionOperationIds
      })
    }

    this.availator = slwcAvailator.getInstance({
      mapApis: window.google ? window.google.maps : null
    })
    return this.availator.fetchAssetsDataDriveCalendar(jobs, {
      timezoneSidId: TIME_ZONE,
      collectionOperationIds: this.collectionOperationIds
    })
      .then(() => {
        return this.availator.buildScheduledAllocations({
          ignoreDedicatedSiteRule: true
        });
      })
      .then((result) => {
        const validPossibleAllocations = (result.possibleAllocations || []).filter(posAl => {
          const noException = (posAl.exceptionLog || []).length === 0;
          return noException;
        })
        
        let mapVehiclesByDate = groupBy(validPossibleAllocations.filter(posAl => {
          return posAl.resource?.assetType === ASSET_TYPE.VEHICLE;
        }), item => item.job.driveDate);

        let mapEquipmentsByDate = groupBy(validPossibleAllocations.filter(posAl => {
          return posAl.resource?.assetType === ASSET_TYPE.EQUIPMENT;
        }), item => item.job.driveDate);

        Object.keys(mapVehiclesByDate).forEach(dateIso => {
          mapVehiclesByDate[dateIso] = (mapVehiclesByDate[dateIso] || []).map(item => item.resource);
        });
        
        Object.keys(mapEquipmentsByDate).forEach(dateIso => {
          mapEquipmentsByDate[dateIso] = (mapEquipmentsByDate[dateIso] || []).map(item => item.resource);
        });

        return {
          mapEquipmentsByDate,
          mapVehiclesByDate
        }
      })
  }

  retrieveDriveLimits() {
    if (!this.collectionOperationIds.length) {
      return Promise.resolve();
    }

    const selectedMonth = this.selectedMonth || DateTime.local().toISODate()
    const { startDate, endDate } = this.planDriveHelper.getDateRange(selectedMonth);

    let driveLimitQuery = new operationDriveLimitQueryModel();
    driveLimitQuery.effectiveStartDate = startDate;
    driveLimitQuery.effectiveEndDate = endDate;
    driveLimitQuery.collectionOperationIds = this.collectionOperationIds;

    let driveLimitSvc = new operationDriveLimitService();
    this.showLoading();
    return driveLimitSvc.query(driveLimitQuery)
      .then(result => {
        return result;
      })
      .catch(error => this.exceptionHandler(error, true))
      .finally(this.hideLoading);
  }

  retrieveStaffingConstraintData() {
    if (!this.collectionOperationIds.length) {
      return Promise.resolve();
    }

    const selectedMonth = this.selectedMonth || DateTime.local().toISODate()
    const { startDate, endDate } = this.planDriveHelper.getDateRange(selectedMonth);

    let staffingConstraintQuery = new staffingConstraintQueryModel();
    staffingConstraintQuery.startDate = startDate;
    staffingConstraintQuery.endDate = endDate;
    staffingConstraintQuery.collectionOpIds = this.collectionOperationIds;
    staffingConstraintQuery.driveTypes = [this.driveHelper.isFixedSiteDrive(this.opportunity) ? DRIVE_TYPE.FIXED_SITE : DRIVE_TYPE.MOBILE];

    let staffingConstraintSvc = new staffingConstraintService();
    this.showLoading();
    return staffingConstraintSvc.query(staffingConstraintQuery)
      .then(result => {
        return result;
      })
      .catch(error => this.exceptionHandler(error, true))
      .finally(this.hideLoading);
  }
}