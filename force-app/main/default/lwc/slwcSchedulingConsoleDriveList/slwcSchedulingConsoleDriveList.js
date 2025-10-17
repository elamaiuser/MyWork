import { LightningElement, track, wire, api } from 'lwc';
import { DateTime } from 'c/luxon';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { pick, omit } from 'c/lodash';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class SlwcSchedulingConsoleDriveList extends LightningElement {
  @api isReadonly = false;
  
  initialized = false;

  @wire(CurrentPageReference) pageRef;

  @track showSpinner = false;
  @track filters = {
    collectionOperationValues: {
      divisions: [],
      arcRegions: [],
      districts: [],
      territoryCollectionOperations: []
    },
    startDate: null,
    endDate: null
  }

  @track includesAdditionalDays = 1;

  get pageName() {
    return "schedulingConsole:driveList";
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  get collectionOperations() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => item.collectionOperation);
  }

  get territoryKeys() {
    if (!this.filters || !this.filters.collectionOperationValues) [];
    return this.filters.collectionOperationValues.territoryCollectionOperations.map(item => `${item.territoryId}:${item.collectionOperationId}`);
  }

  get collectionOperationFirstDay() {
    if (!this.collectionOperations || !this.collectionOperations.length) return;
    return this.collectionOperations[0].workWeekFirstDay;
  }

  get driveListFilters() {
    return omit(this.filters, ['procedureTypes', 'driveOperationTypes']);
  }

  get collectionOperationDateRange() {
    if (!this.filters || !this.filters.startDate || !this.filters.endDate) return {
      startDate: null,
      endDate: null
    };

    return {
      startDate: this.filters.startDate,
      endDate: this.filters.endDate
    }
  }

  connectedCallback() {
    if (!this.initialized) {
      let lastSearchQuery = this.getLastQuery();
      if (lastSearchQuery) {
        this.filters = {
          ...this.filters,
          ...lastSearchQuery
        };
      }

      if (!this.filters.collectionOperationValues.territoryCollectionOperations) {
        this.filters.collectionOperationValues.territoryCollectionOperations = [];
      }

      if (!this.filters.startDate || !this.filters.endDate) {
        const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
        this.filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), firstDay).toISODate();
        this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
          day: 6
        }).toISODate()
      }
    }
  }

  renderedCallback() {
    if (!this.initialized) {
      this.initialized = true;
    }
  }

  handleOnChange(event) {
    if (event.type === 'weekdatechange') {
      this.filters = {
        ...this.filters, 
        startDate: event.detail.startDate,
        endDate: event.detail.endDate
      }
      this.setLastQuery();
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

  validateFilters() {
    if (this.filters.startDate) {
      const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
      this.filters.startDate = this.dateUtils.startOfWeek(this.filters.startDate, firstDay).toISODate();
      this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
        day: 6
      }).toISODate()
    }
  }

  handleSearch(event = {
    detail: {}
  }) {
    this.validateFilters();
    const { filters } = event.detail;
    this.filters = {
        ...this.filters,
        ...filters,
        territoryKeys: this.territoryKeys
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