import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { exceptionQueryModel, exceptionService } from 'c/dataService';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcUtils from "c/slwcUtils";
import * as slwcDateUtils from 'c/slwcDateUtils';
import { cloneDeep, keyBy } from 'c/lodash';
import { collectionOperationService, linkedDrivesService, linkedDrivesQueryModel } from 'c/dataService';

const TERRITORY_TYPE = {
  ARC_REGION: 'ARC Region',
  DIVISION: 'Division',
  DISTRICT: 'District',
  COLLECTION_OPERATION: 'Collection Operation'
};

const LINKED_DRIVE_EXCEPTION_COLUMNS = [
  { label: 'Name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, initialWidth: 120, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
  { label: 'Linked Drive', fieldName: 'linkedDriveUrl', type: 'url', hideDefaultActions: false, initialWidth: 200, wrapText: true, typeAttributes: { label: { fieldName: 'linkedDriveName' }, target: '_blank' } },
  { label: 'Earliest Drive Date', fieldName: 'linkedDriveEarliestDriveDate', type: 'date-local', initialWidth: 140, typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
  { label: 'Latest Drive Date', fieldName: 'linkedDriveLatestDriveDate', type: 'date-local', initialWidth: 140, typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
  { label: 'Drives', fieldName: 'linkedDrive', type: 'linkedDriveDrives', hideDefaultActions: true,  initialWidth: 450, wrapText: true, cellAttributes: { wrapText: true } },
  { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, cellAttributes: { wrapText: true } },
  { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, initialWidth: 120, wrapText: true },
  { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, initialWidth: 120, wrapText: true }
];

export default class SlwcLinkedDriveExceptionList extends LightningElement {
  initialized = false;
  selectedExceptionLog = [];

  get btnCloseExceptionLabel() {
    return `Close Exception (${this.selectedExceptionLog.length} selected)`;
  }

  get btnCloseExceptionDisabled() {
    return this.selectedExceptionLog.length === 0;
  }

  get columns() {
    return LINKED_DRIVE_EXCEPTION_COLUMNS;
  }

  get isValidQueryModel() {
    return this.filters.arcRegions && this.filters.arcRegions.length;
  }

  get arcRegionDateRange() {
    if (!this.filters || !this.filters.startDate || !this.filters.endDate) return {
      startDate: null,
      endDate: null
    };

    return {
      startDate: this.filters.startDate,
      endDate: this.filters.endDate
    }
  }

  get pageName() {
    return 'schedulingConsole:exceptionConsole'
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }

  @wire(CurrentPageReference) pageRef;

  @track showSpinner = false;
  @track filters = {
    arcRegions: [],
    startDate: null,
    endDate: null
  }
  @track enableInfiniteLoading = true;
  @track exceptionLog = [];
  @track includesAdditionalDays = 0;
  @track arcRegionOptions = [];

  showLoading() {
    this.showSpinner = true;
  }

  hideLoading() {
    this.showSpinner = false;
  }

  filterValidTerritoryOptions = (territoryCollectionOperations, allTerritories) => {
    if (!territoryCollectionOperations || !territoryCollectionOperations.length) return [];

    let validDistricts = allTerritories.filter(item => {
      return (territoryCollectionOperations.map(item => item.territoryId).includes(item.id)) && item.recordTypeName === TERRITORY_TYPE.DISTRICT;
    });

    let validARCRegions = allTerritories.filter(item => {
      return (validDistricts.map(item => item.parentId).includes(item.id)) && item.recordTypeName === TERRITORY_TYPE.ARC_REGION;
    });

    let validDivisions = allTerritories.filter(item => {
      return (validARCRegions.map(item => item.parentId).includes(item.id)) && item.recordTypeName === TERRITORY_TYPE.DIVISION;
    });

    return {
      validDistricts,
      validARCRegions,
      validDivisions
    };
  }

  formatDate = (dateIso) => {
    if (!dateIso) return '';
    return DateTime.fromString(dateIso, 'yyyy-MM-dd').toFormat('MM/dd/yyyy')
  }

  buildPicklistOptions = (data) => {
    return data.map(item => {
      const { startDate, endDate } = item;
      const startDateString = this.formatDate(startDate);
      const endDateString = this.formatDate(endDate);

      let description = '';
      if (startDate && !endDate) {
        description = `Valid from ${startDateString}`
      } else if (!startDate && endDate) {
        description = `Valid to ${endDateString}`
      } else if (startDate && endDate) {
        description = `Valid from ${startDateString} to ${endDateString}`
      }

      return {
        ...item,
        value: item.id,
        label: item.name,
        description: item.recordTypeName !== TERRITORY_TYPE.DIVISION ? description : null,
        parentId: item.parentId || item.territoryId,
        recordType: item.recordTypeName || TERRITORY_TYPE.COLLECTION_OPERATION,
        selected: false
      }
    })
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
      if (!this.filters.startDate || !this.filters.endDate) {
        const firstDay = this.dateUtils.getFirstDayValue();
        this.filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), firstDay).toISODate();
        this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
          day: 42
        }).toISODate();
      }

      this.showLoading();
      let service = new collectionOperationService();
      service.getCollectionOperationDataNew({
        startDate: this.filters.startDate,
        endDate: this.filters.endDate
      })
        .then((data) => {
          const territories = data.territories || [];
          const territoryCollectionOperations = data.territoryCollectionOperations || [];        
          const { validARCRegions } = this.filterValidTerritoryOptions(territoryCollectionOperations, territories);
          this.arcRegionOptions = this.buildPicklistOptions(validARCRegions);
          this.filters.arcRegions = cloneDeep(this.arcRegionOptions.filter(item => {
            return !!this.filters.arcRegions.find(selected => selected.value === item.value);
          }))
        })
        .catch((e) => {
          console.log(e);
        })
        .finally(() => this.hideLoading());
    }
  }

  renderedCallback() {
    if (!this.initialized) {
      this.initialized = true;
    }
  }

  fetchExceptionData() {
    let query = new exceptionQueryModel();
    const arcRegions = this.filters.arcRegions;
    if (!arcRegions.length) {
      return Promise.resolve([]);
    }
    query.arcRegionIds = arcRegions.map(item => item.id);
    query.exceptionCodes = this.filters.exceptionCodes;
    query.priorities = this.filters.priorities;
    query.statuses = this.filters.statuses;
    query.startDate = this.filters.startDate;
    query.endDate = this.filters.endDate;
    query.exceptionType = 'linkedDrive';
    query.limit = 20;
    query.offset = (this.exceptionLog || []).length;

    let service = new exceptionService();

    return Promise.resolve()
      .then(() => {
        return service.query(query)
      })
      .then((result) => {
        result.forEach((exception) => {
          exception.recordUrl = '/' + exception.id;
          if (exception.linkedDriveId) {
            exception.linkedDriveUrl = '/' + exception.linkedDriveId;
          }
        })
        return result;
      })
      .then((result) => {
        if(result?.length) {
          const _linkedDrivesService = new linkedDrivesService();
          const _linkedDrivesQueryModel = new linkedDrivesQueryModel();
          _linkedDrivesQueryModel.recordIds = result.map(item => item.linkedDriveId);
          return _linkedDrivesService.query(_linkedDrivesQueryModel)
          .then((linkedDrives) => {
            const mapLinkedDrivesById = keyBy(linkedDrives, 'id');
            result.forEach((exception) => {
              exception.linkedDrive = mapLinkedDrivesById[exception.linkedDriveId];
            })
            return result;
          })
        }
        return result;
      })
      .catch((error) => {
        console.log(error);
      });
  }

  handleOnChange(event) {
    if (event.type === 'daterangechange') {
      this.filters = {
        ...this.filters,
        startDate: event.detail.startDate,
        endDate: event.detail.endDate
      }
      this.handleSearch();
    }
  }

  handleARCRegionChanged(event) {
    this.filters.arcRegions = cloneDeep(event.detail.selectedValues);
    this.handleSearch();
  }


  handleSearch(event = {
    detail: {}
  }) {
    const { filters } = event.detail;
    this.filters = {
      ...this.filters,
      ...filters,
      territoryKeys: this.territoryKeys
    };

    if (!this.isValidQueryModel) return;

    this.showLoading();
    this.enableInfiniteLoading = false;
    this.exceptionLog = [];
    this.fetchExceptionData()
      .then(result => {
        this.exceptionLog = result;
        this.enableInfiniteLoading = true;
      })
      .finally(() => {
        this.hideLoading();
      });

    this.setLastQuery();
  }

  handleRowSelection(event) {
    this.selectedExceptionLog = (event.detail.selectedRows || []);
  }

  handleLoadMoreData(event) {
    //Display a spinner to signal that data is being loaded
    event.target.isLoading = true;

    let target = event.target;
    this.fetchExceptionData()
      .then((result) => {
        if (result.length == 0) {
          this.enableInfiniteLoading = false;
        }
        else {
          const currentData = this.exceptionLog;
          const newData = currentData.concat(result);
          this.exceptionLog = newData;
        }
      })
      .finally(() => {
        target.isLoading = false;
      });
  }

  handleCloseException() {
    let exceptionLog = [];
    this.selectedExceptionLog.forEach((item) => {
      exceptionLog.push({
        id: item.id,
        status: 'Closed'
      });
    });
    this.showLoading();
    let service = new exceptionService();
    service.saveList(exceptionLog)
      .then((result) => {
        this.dispatchEvent(new ShowToastEvent({
          message: 'Exception log was closed successfully.',
          variant: 'success',
          mode: 'dismissable'
        }));
        this.handleSearch();
      })
      .finally(() => {
        this.hideLoading();
      });
  }

  setLastQuery() {
    slwcUtils.setLastQuery(this.pageName, this.filters);
  }

  getLastQuery() {
    let tabQuery = slwcUtils.getLastQuery(this.pageName);
    return tabQuery;
  }
}