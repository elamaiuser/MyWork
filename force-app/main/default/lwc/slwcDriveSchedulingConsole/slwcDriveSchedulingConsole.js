import { LightningElement, track, wire, api } from 'lwc';
import TIME_ZONE from "@salesforce/i18n/timeZone";
import { DateTime } from 'c/luxon';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { calendarMonthHelper } from "c/slwcHelpers";
import { cloneDeep, pick, omit } from 'c/lodash';
import { userService } from 'c/dataService';
import { DriveHelper } from 'c/slwcDriveGenerator';

const DEFAULT_CALENDAR_SETTINGS = {
    timezone: TIME_ZONE,
    firstDay: 0
};
const driveHelper = new DriveHelper();

export default class SlwcDriveSchedulingConsole extends LightningElement {
    @api displayMode;
    @api isReadonly = false;
    loginUser;

    _calendarHelper = null;
    get calendarHelper() {
        if (!this._calendarHelper) {
            this._calendarHelper = new calendarMonthHelper(DEFAULT_CALENDAR_SETTINGS);
        }
        return this._calendarHelper;
    }

    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        })
    }

    get pageName() {
        return "schedulingConsole:" + this.displayMode;
    }
    
    get filtersMode() {
        if(this.displayMode === 'productGoalCalendar') {
            return 'productGoalCalendar';
        } else {
            return 'driveScheduling';
        }
    }

    get collectionOperations() {
        if (!this.filters || !this.filters.collectionOperationValues) {
            return [];
        }
        return this.filters.collectionOperationValues.collectionOperations;
    }
    
    get collectionOperationDateRange() {
        if (!this.filters || !this.filters.selectedMonth) return {
            startDate: null,
            endDate: null
        };
    
        const selectedMonth = this.filters.selectedMonth || DateTime.local().toISODate()
        let { startDate, endDate } = this.calendarHelper.getDateRange(selectedMonth);
        startDate = this.dateUtils.startOf(startDate, 'week');
        endDate = this.dateUtils.endOf(endDate, 'week');

        return {
            startDate: startDate,
            endDate: endDate
        }
    }

    get timeBlockEnabled() {
        return this.displayMode === 'productGoalCalendar';
    }

    get autoSelectTimeBlocks() {
        return driveHelper.isAPSUser(this.loginUser);
    }

		get driveCalendarFilter() {
			let result = this.filters;
			if (this.displayMode == "productGoalCalendar") {
				result = omit(this.filters, ['driveTypes', 'searchText']);
			}
			else if (this.displayMode == "productivityCalendar") {
				result = omit(this.filters, ['searchText']);
			}
			return result;
		}

    initialized = false;
    @wire(CurrentPageReference) pageRef;

    @track showSpinner = false;
    @track filters = {
        collectionOperationValues: {
            divisions: [],
            arcRegions: [],
            districts: [],
            territoryCollectionOperations: [],
            timeBlocks: [],
            isFilteringMissingTimeBlock: false
        },
        selectedMonth: DateTime.local().toISODate()
    }

    connectedCallback() {
        //init settings
        if (!this.initialized) {
            let lastSearchQuery = this.getLastQuery();
            if (lastSearchQuery) {
                this.filters = {
                    ...this.filters,
                    ...lastSearchQuery
                };
            }
        }
        this.retrieveLoginUser();
    }

    retrieveLoginUser() {
        const svc = new userService();
        svc.getLoginUser().then(result => {
            this.loginUser = result.returnedData;
        });
    }  
    
    renderedCallback() {
        if (!this.initialized) {
          this.initialized = true;
        }
    }

    handleOnMonthChanged(event) {
        this.filters = {
            ...this.filters, 
            selectedMonth: event.detail.selectedDate
        }
        this.setLastQuery();
    }

    handleSelectDate(event) {
        const selectedDateIso = event.detail.selectedDate;
        let filters = cloneDeep(this.driveCalendarFilter);
        
        if (this.displayMode == "productGoalCalendar") {
            fireEvent(this.pageRef, 'driveCalendar:showDayModal', {startDate: selectedDateIso, endDate: selectedDateIso, filters: filters});
        }
        else if (this.displayMode == "productivityCalendar") {
            fireEvent(this.pageRef, 'productivityCalendar:showDriveList', {startDate: selectedDateIso, endDate: selectedDateIso, filters: filters});
        }
    }

    handleSelectWeek(event) {
        const startDateIso = event.detail.weekStartDate;
        let endDateIso = DateTime.fromFormat(startDateIso, 'yyyy-MM-dd').plus({day: 6}).toISODate();
        let filters = cloneDeep(this.driveCalendarFilter);

        if (this.displayMode == "productGoalCalendar") {
            fireEvent(this.pageRef, 'driveCalendar:showDayModal', {startDate: startDateIso, endDate: endDateIso, filters: filters});
        }
        else if (this.displayMode == "productivityCalendar") {
            fireEvent(this.pageRef, 'productivityCalendar:showDriveList', {startDate: startDateIso, endDate: endDateIso, filters: filters});
        }
    }

    handleCollectionOperationChanged(event) {
        this.filters.collectionOperationValues = {
            divisions: event.detail.selectedDivisions,
            arcRegions: event.detail.selectedARCRegions,
            districts: event.detail.selectedDistricts,
            territoryCollectionOperations: event.detail.selectedTerritoryCollectionOperations
        }
        
        this.handleSearch();
    }

    handleTimeBlockChanged(event) {
        this.filters.collectionOperationValues = {
            divisions: event.detail.selectedDivisions,
            arcRegions: event.detail.selectedARCRegions,
            districts: event.detail.selectedDistricts,
            territoryCollectionOperations: event.detail.selectedTerritoryCollectionOperations,
            timeBlocks: event.detail.selectedTimeBlocks,
            isFilteringMissingTimeBlock: event.detail.isFilteringMissingTimeBlock
        }
    
        this.handleSearch();
      }

    handleSearch(event = {
        detail: {}
    }) {
        const { filters } = event.detail;
        this.filters = {
            ...this.filters,
            ...filters
        };
        this.setLastQuery();
    }

    setLastQuery() {
        slwcUtils.setLastQuery(this.pageName, this.filters);
        slwcUtils.setLastQuery('schedulingConsole', pick(this.filters, ['collectionOperationValues']));
      }
    
      getLastQuery() {
        let tabQuery = slwcUtils.getLastQuery(this.pageName);
        let schedulingConsoleQuery = slwcUtils.getLastQuery('schedulingConsole');
        let collectionOperationValues =  (schedulingConsoleQuery || {}).collectionOperationValues || {
          divisions: [],
          arcRegions: [],
          districts: [],
          territoryCollectionOperations: []
        };
        if(tabQuery && tabQuery.collectionOperationValues) {
          collectionOperationValues.territoryCollectionOperations = tabQuery.collectionOperationValues.territoryCollectionOperations || [];
        }
        return {
          ...tabQuery,
          collectionOperationValues: collectionOperationValues
        };
      }
}