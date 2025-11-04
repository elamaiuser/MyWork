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
    { label: 'Created Date', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, initialWidth: 150, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'createdDateStr' }, target: '_blank'}},
    { label: 'Drive', fieldName: 'driveUrl', type: 'url', hideDefaultActions: false, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'driveName' }, target: '_blank'}},
    { label: 'Drive ID', fieldName: 'ufid', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true, sortable: true },
    { label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', initialWidth: 100, sortable: true, typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
    { label: 'Job Type', fieldName: 'jobType', type: 'text', hideDefaultActions: false, wrapText: true, initialWidth: 125, sortable: true },
    { label: 'Resource', fieldName: 'resourceName', type: 'text', hideDefaultActions: true, initialWidth: 200, wrapText: true, sortable: true },
    { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true, cellAttributes: {wrapText: true} },
    { label: 'Conflicting Drive', fieldName: 'conflictedDriveUrl', type: 'url', hideDefaultActions: false, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'conflictedDriveName' }, target: '_blank'}},
    { label: 'Conflicting Activity', fieldName: 'conflictedActivityUrl', type: 'url', hideDefaultActions: false, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'activityTitle' }, target: '_blank'}},
    { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true, sortable: true }
    /*{
    { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true } 
         { label: 'Job', fieldName: 'jobUrl', type: 'url', hideDefaultActions: false, wrapText: true, initialWidth: 125, typeAttributes:{label: { fieldName: 'jobName' }, target: '_blank'}},
    */
];

const ACTIVITY_EXCEPTION_COLUMNS = [
    { label: 'Created Date', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, initialWidth: 150, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'createdDateStr' }, target: '_blank'}},
    { label: 'Activity Title', fieldName: 'activityUrl', type: 'url', hideDefaultActions: false, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'activityTitle' }, target: '_blank'}},
    {
      label: 'Start', fieldName: 'activityStart', type: 'date', hideDefaultActions: true, sortable: true, typeAttributes: {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: TIME_ZONE
      }
    },
    {
      label: 'End', fieldName: 'activityEnd', type: 'date', hideDefaultActions: true, sortable: true, typeAttributes: {
        year: 'numeric',
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        timeZone: TIME_ZONE
      }
    },
    { label: 'Type', fieldName: 'activityType', type: 'text', hideDefaultActions: false, wrapText: true, initialWidth: 125, sortable: true },
    { label: 'Sub Type', fieldName: 'activitySubType', type: 'text', hideDefaultActions: false, wrapText: true, initialWidth: 125, sortable: true },
    { label: 'Resource', fieldName: 'resourceName', type: 'text', hideDefaultActions: true, initialWidth: 200, wrapText: true, sortable: true },
    { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true, cellAttributes: {wrapText: true} },
    { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true, sortable: true }
];

const RESOURCE_EXCEPTION_COLUMNS = [
    { label: 'Created Date', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, initialWidth: 150, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'createdDateStr' }, target: '_blank'}},
    { label: 'Resource', fieldName: 'resourceUrl', type: 'url', hideDefaultActions: false, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'resourceName' }, target: '_blank'}},
    { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true, cellAttributes: {wrapText: true} },
    { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, initialWidth: 150, wrapText: true, sortable: true },
    { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, initialWidth: 150, wrapText: true, sortable: true }
];

const TBS_EXCEPTION_COLUMNS = [
    { label: 'Created Date', fieldName: 'recordUrl', type: 'url', hideDefaultActions: false, initialWidth: 150, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'createdDateStr' }, target: '_blank'}},
    { label: 'Drive', fieldName: 'driveUrl', type: 'url', hideDefaultActions: false, wrapText: true, sortable: true, typeAttributes:{label: { fieldName: 'driveName' }, target: '_blank'}},
    { label: 'Drive Shift', fieldName: 'driveShiftName', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true, sortable: true },
    { label: 'Drive ID', fieldName: 'ufid', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true, sortable: true },
    { label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', initialWidth: 100, sortable: true, typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
    { label: 'Start Time', fieldName: 'startTimeStr', type: 'text', hideDefaultActions: true, initialWidth: 200, wrapText: true, sortable: true },
    { label: 'End Time', fieldName: 'endTimeStr', type: 'text', hideDefaultActions: true, initialWidth: 200, wrapText: true, sortable: true },
    { label: 'Time Block', fieldName: 'driveShiftTimeBlockName', type: 'text', hideDefaultActions: true, initialWidth: 200, wrapText: true, sortable: true },
    { label: 'Exception', fieldName: 'exception', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true, cellAttributes: {wrapText: true} },
    { label: 'Priority', fieldName: 'priority', type: 'text', hideDefaultActions: true, initialWidth: 100, wrapText: true, sortable: true }
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
        } else if (this.exceptionType === "tbs") {
            return  "tbsExceptionLog";
        } else if (this.exceptionType === "activity") {
            return  "activityExceptionLog";
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
        else if (this.exceptionType === "tbs") {
            return  TBS_EXCEPTION_COLUMNS;
        }
        else if (this.exceptionType === "activity") {
            return  ACTIVITY_EXCEPTION_COLUMNS;
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
        if (!this.collectionOperations || !this.collectionOperations.length) return null;
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
    @track sortedBy;
    @track sortedDirection;

    connectedCallback() {
        //init settings
        if (!this.initialized) {
            const lastSearchQuery = this.getLastQuery();
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
        const query = new exceptionQueryModel();

        let exceptionCodes = [];
        let driveTypes = [];
        let operationTypes = [];
        let resourceDriveTypes = [];
        let activityTypes = [];
        let activitySubTypes = [];
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
        else if (this.exceptionType === "activity") {
            query.exceptionType = "activity";
            const territoryKeys = this.territoryKeys;
            if (!territoryKeys.length) {
                return Promise.resolve([]);
            }
            query.territoryKeys = territoryKeys;
            exceptionCodes.push("ACTIVITY_OUTSIDE_OF_AVAILABILITY_PATTERN");
            activityTypes = this.filters.activityTypes;
            activitySubTypes = this.filters.activitySubTypes;
        }
        else if (this.exceptionType === "resource") {
            resourceDriveTypes = this.filters.resourceDriveTypes;
            query.exceptionType = "resource";
            exceptionCodes.push("RESOURCE_DUPLICATE_SENIORITY_RANKING");
        }
        else if (this.exceptionType === "tbs") {
            query.exceptionType = "tbs";
            const territoryKeys = this.territoryKeys;
            if (!territoryKeys.length) {
                return Promise.resolve([]);
            }
            query.territoryKeys = territoryKeys;
            exceptionCodes = this.filters.exceptionCodes;
            operationTypes = this.filters.operationTypes;
        }

        query.exceptionCodes = exceptionCodes;
        query.priorities = this.filters.priorities;
        query.driveTypes = driveTypes;
        query.activityTypes = activityTypes;
        query.activitySubTypes = activitySubTypes;
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
        
        const service = new exceptionService();

        return Promise.resolve()
            .then(() => {
                return service.query(query)
            })
            .then((result) => {
                result.forEach((exception) => {
                    exception.recordUrl = '/' + exception.id;
                    if (exception.createdDate) { 
                        exception.createdDateStr = DateTime.fromISO(exception.createdDate).toLocaleString({ month: 'short', day: '2-digit', year: 'numeric'});
                    }
                    if (exception.activityId) {
                        exception.activityUrl = '/' + exception.activityId;
                    }
                    else {
                        exception.activityId = '';
                    }
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

                    if (this.exceptionType === 'tbs') {
                        exception.startTimeStr = this.formatTime(exception.driveShiftStartTime ?? exception.driveStartTime);
                        exception.endTimeStr = this.formatTime(exception.driveShiftEndTime ?? exception.driveEndTime);
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
                if (this.sortedBy && this.sortedDirection) {
                    this.sortData(this.sortedBy, this.sortedDirection);
                }
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
        
        const target = event.target;
        this.fetchExceptionData()
            .then((result) => {
                if (result.length == 0) {
                    this.enableInfiniteLoading = false;
                }
                else {
                    const currentData = this.exceptionLog;
                    const newData = currentData.concat(result);
                    this.exceptionLog = newData;
                    if (this.sortedBy && this.sortedDirection) {
                        this.sortData(this.sortedBy, this.sortedDirection);
                    }
                }
            })
            .finally(() => {
                target.isLoading = false;
            });
    }

    handleCloseException() {
        const exceptionLog = [];
        this.selectedExceptionLog.forEach((item) => {
            exceptionLog.push({
                id: item.id,
                status: 'Closed'
            });
        });
        this.showSpinner = true;
        const service = new exceptionService();
        service.saveList(exceptionLog)
            .then(() => {
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
        const tabQuery = slwcUtils.getLastQuery(this.pageName);
        const schedulingConsoleQuery = slwcUtils.getLastQuery('schedulingConsole');
        const collectionOperationValues =  (schedulingConsoleQuery || {}).collectionOperationValues || {
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

    formatTime(time) {
        if (!time) {
            return '';
        }
        return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldName, sortDirection) {        
        const dataToSort = JSON.parse(JSON.stringify(this.exceptionLog));
        const reverse = sortDirection === 'asc' ? 1 : -1;
        const getSortValue = (obj) => {
            switch (fieldName) {                
                case 'recordUrl': return obj.createdDate;
                case 'driveUrl': return obj.driveName;
                case 'conflictedDriveUrl': return obj.conflictedDriveName;
                case 'conflictedActivityUrl': return obj.activityTitle;
                case 'activityUrl': return obj.activityTitle;
                case 'resourceUrl': return obj.resourceName;                
                case 'startTimeStr': return obj.driveShiftStartTime ?? obj.driveStartTime;
                case 'endTimeStr': return obj.driveShiftEndTime ?? obj.driveEndTime;
                default: return obj[fieldName];
            }
        };
        
        dataToSort.sort((a, b) => {
            let valueA = getSortValue(a);
            let valueB = getSortValue(b);
            
            const emptyA = valueA === null || valueA === undefined || valueA === '';
            const emptyB = valueB === null || valueB === undefined || valueB === '';
            if (emptyA && emptyB) return 0;
            if (emptyA) return 1;
            if (emptyB) return -1;
            
            if (typeof valueA === 'string' && typeof valueB === 'string') {
                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();
            }

            let result = 0;
            if (valueA < valueB) {
                result = -1;
            } else if (valueA > valueB) {
                result = 1;
            }

            return result * reverse;
        });
        
        this.exceptionLog = dataToSort;
    }
}