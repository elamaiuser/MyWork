import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { exceptionQueryModel, exceptionService } from 'c/dataService';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import * as slwcUtils from "c/slwcUtils";
import * as slwcDateUtils from 'c/slwcDateUtils';
import { pick } from 'c/lodash';

const DRIVE_EXCEPTION_COLUMNS = [
    { label: 'Name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, initialWidth: 100, wrapText: true, typeAttributes:{label: { fieldName: 'name' }, target: '_blank'}},
    { label: 'Drive', fieldName: 'driveUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes:{label: { fieldName: 'driveName' }, target: '_blank'}},
    { label: 'Drive ID', fieldName: 'ufid', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true },
    { label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', initialWidth: 125, typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
    { label: 'Job Type', fieldName: 'jobType', type: 'text', hideDefaultActions: false, wrapText: true, initialWidth: 125 },
    { label: 'Resource', fieldName: 'resourceName', type: 'text', hideDefaultActions: true, initialWidth: 200, wrapText: true },
    { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, cellAttributes: {wrapText: true} },
    { label: 'Conflicting Drive', fieldName: 'conflictedDriveUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes:{label: { fieldName: 'conflictedDriveName' }, target: '_blank'}},
    { label: 'Conflicting Activity', fieldName: 'conflictedActivityUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes:{label: { fieldName: 'activityTitle' }, target: '_blank'}},
    { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true }
    /*{
    { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true } 
         { label: 'Job', fieldName: 'jobUrl', type: 'url', hideDefaultActions: false, wrapText: true, initialWidth: 125, typeAttributes:{label: { fieldName: 'jobName' }, target: '_blank'}},
    */
];

const RESOURCE_EXCEPTION_COLUMNS = [
    { label: 'Name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, initialWidth: 150, wrapText: true, typeAttributes:{label: { fieldName: 'name' }, target: '_blank'}},
    { label: 'Resource', fieldName: 'resourceUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes:{label: { fieldName: 'resourceName' }, target: '_blank'}},
    { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, cellAttributes: {wrapText: true} },
    { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, initialWidth: 150, wrapText: true },
    { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, initialWidth: 150, wrapText: true }
];

export default class SlwcExceptionList extends LightningElement {
    initialized = false;
    selectedExceptionLog = [];

    get btnCloseExceptionLabel() {
        return `Close Exception (${this.selectedExceptionLog.length} selected)`;
    }

    get btnCloseExceptionDisabled() {
        return this.selectedExceptionLog.length === 0;
    }

    get filterMode() {
        if (this.exceptionType === "drive") {
            return "driveExceptionLog";
        }
        else if (this.exceptionType === "resource") {
            return  "resourceExceptionLog";
        }
        return null;
    }

    get columns() {
        if (this.exceptionType === "drive") {
            return DRIVE_EXCEPTION_COLUMNS;
        }
        else if (this.exceptionType === "resource") {
            return  RESOURCE_EXCEPTION_COLUMNS;
        }
        return null;
    }

    get isValidQueryModel() {
        return this.territoryKeys && this.territoryKeys.length;
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

    get pageName() {
        return 'schedulingConsole:exceptionConsole'
    }

    get dateUtils() {
        return slwcDateUtils.getInstance({
            timezone: TIME_ZONE
        });
    }

    @wire(CurrentPageReference) pageRef;

    @api exceptionType;

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
    @track enableInfiniteLoading = true;
    @track exceptionLog = [];
    @track includesAdditionalDays = 0;

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
            if (!this.filters.collectionOperationValues.territoryCollectionOperations) {
                this.filters.collectionOperationValues.territoryCollectionOperations = [];
            }
            if (!this.filters.startDate || !this.filters.endDate) {
                const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
                this.filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), firstDay).toISODate();
                this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
                  day: 42
                }).toISODate();
            }
        }
    }  

    renderedCallback() {
        if(!this.initialized) {
            this.initialized = true;
        }
    }

    fetchExceptionData() {
        let query = new exceptionQueryModel();

        let exceptionCodes = [];
        let driveTypes = [];
        let operationTypes = [];
        let resourceDriveTypes = [];
        if (this.exceptionType === "drive") {
            query.exceptionType = "drive";
            const territoryKeys = this.territoryKeys;
            if (!territoryKeys.length) {
                return Promise.resolve([]);
            }
            query.territoryKeys = territoryKeys;
            exceptionCodes = this.filters.exceptionCodes;
            driveTypes = this.filters.driveTypes;
            operationTypes = this.filters.operationTypes;
        }
        else if (this.exceptionType === "resource") {
            resourceDriveTypes = this.filters.resourceDriveTypes;
            query.exceptionType = "resource";
            exceptionCodes.push("RESOURCE_DUPLICATE_SENIORITY_RANKING");
        }

        query.exceptionCodes = exceptionCodes;
        query.priorities = this.filters.priorities;
        query.driveTypes = driveTypes;
        query.operationTypes = operationTypes;
        query.resourceDriveTypes = resourceDriveTypes;
        query.statuses = this.filters.statuses;
        query.startDate  = this.filters.startDate;
        query.endDate = this.filters.endDate;
        query.collectionOperationIds = this.collectionOperations.map(item => item.id);

        if (this.filters.searchText && this.filters.searchField) {
            query.queryText = this.filters.searchText;
            query.searchColumns = [this.filters.searchField];
        }
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
                    if (exception.driveId) {
                        exception.driveUrl = '/' + exception.driveId;
                    }
                    else {
                        exception.driveUrl = '';
                    }
                    if (exception.jobId) {
                        exception.jobUrl = '/' + exception.jobId;
                    }
                    else {
                        exception.jobUrl = '';
                    }
                    if (exception.resourceId) {
                        exception.resourceUrl = '/' + exception.resourceId;
                    }
                    if (exception.conflictedDrive) {
                        exception.conflictedDriveUrl = '/' + exception.conflictedDrive;
                    }
                    else {
                        exception.conflictedDriveUrl = '';
                    }
                    if (exception.activityId) {
                        exception.conflictedActivityUrl = '/' + exception.activityId;
                    }
                    else {
                        exception.conflictedActivityUrl = '';
                    }
                    //12840-when drive and conflicted drive are same, activity is present, use conflict with Activity title instead
                    if (exception.conflictedDrive === exception.driveId && (exception.activityTitle || '').trim() !== '') {
                        exception.exception = 'Conflict with '+exception.activityTitle;
                    }

                })
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

    handleCollectionOperationChanged(event) {
        this.filters.collectionOperationValues = {
            divisions: event.detail.selectedDivisions,
            arcRegions: event.detail.selectedARCRegions,
            districts: event.detail.selectedDistricts,
            territoryCollectionOperations: event.detail.selectedTerritoryCollectionOperations
        }
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
        
        this.showSpinner = true;
        this.enableInfiniteLoading = false;
        this.exceptionLog = [];
        this.fetchExceptionData()
            .then(result => {
                this.exceptionLog = result;
                this.enableInfiniteLoading = true;
            })
            .finally(() => {
                this.showSpinner = false;
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
        this.showSpinner = true;
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
                this.showSpinner = false;
            });
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