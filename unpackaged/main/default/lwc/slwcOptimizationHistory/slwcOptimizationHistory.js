import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { groupBy, uniq, pick, cloneDeep } from 'c/lodash';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DateTime } from 'c/luxon';

import { optimizationRunQueryModel, optimizationRunService, sObjectType } from 'c/dataService';

import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import * as autoMapper from 'c/autoMapper';

import { OPTIMIZATION_STATUS } from 'c/slwcConstants';

const VIEW_MODE = {
    ALL: 'all',
    DETAILS: 'details'
}

export default class SlwcOptimizationHistory extends LightningElement {
    COLUMNS = [
        { label: 'Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes:{label: { fieldName: 'name' }, target: '_blank'}},
        { label: 'Start Date', fieldName: 'startDate', type: 'date-local', typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
        { label: 'End Date', fieldName: 'endDate', type: 'date-local', typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
        { label: 'Created Date', fieldName: 'createdDate', type: 'date-local', typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true },
        { label: 'Created By', type: 'userInfo', fieldName: 'createdBy', typeAttributes: { showPhoto: true} },
        { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, wrapText: true },
        {
            label: '',
            type: 'optimizationRunButton',
            fieldName: 'id',
            hideDefaultActions: true, initialWidth: 180,
            typeAttributes: { 
                canClose: {
                    fieldName: 'canClose'
                },
                clickAction: (event) => {
                    this.handleRowAction({
                        action: event.currentTarget.dataset['action'],
                        value: event.currentTarget.dataset['value']
                    });
                }
            }
        },
    ];

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
    @track optimizationRuns = [];
    @track columns = this.COLUMNS;
    @track selectedAllByDefault = false;
    @track viewMode = VIEW_MODE.ALL;
    @track selectedOptimizationRun = null;
    @track confirmModalData = {};

    get isValidQueryModel() {
        return this.territoryKeys && this.territoryKeys.length;
    }
    
    get pageName() {
        return 'schedulingConsole:driveOptimizer';
    }

    get VIEW_MODE() {
        return VIEW_MODE;
    }
    
    get viewOptimizationRunDetails() {
        return this.viewMode === VIEW_MODE.DETAILS;
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
        //init settings
        if (!this.initialized) {
            let lastSearchQuery = this.getLastQuery();
            if (lastSearchQuery) {
                this.filters = {
                    ...this.filters,
                    ...lastSearchQuery
                };

                if (!this.filters.collectionOperationValues.territoryCollectionOperations) {
                    this.filters.collectionOperationValues.territoryCollectionOperations = [];
                }
            
                if(!this.filters.startDate || !this.filters.endDate) {
                    const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
                    this.filters.startDate = this.dateUtils.startOfWeek(DateTime.local(), firstDay).toISODate();
                    this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
                        day: 6
                    }).toISODate()
                }
            }
            else {
                this.selectedAllByDefault = true;
            }
        }
    }  

    renderedCallback() {
        if(!this.initialized) {
            this.handleSearch();
            this.initialized = true;
        }
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    handleOnChange(event) {
        if (event.type === 'weekdatechange') {
            this.filters.startDate = event.detail.startDate;
            this.filters.endDate = event.detail.endDate;
        }
        else {
            this.filters[event.target.name] = slwcUtils.getValueFromEvent(event);
        }

        this.handleSearch();
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
        if(this.filters.startDate) {
            const firstDay = this.dateUtils.getFirstDayValue(this.collectionOperationFirstDay);
            this.filters.startDate = this.dateUtils.startOfWeek(this.filters.startDate, firstDay).toISODate();
            this.filters.endDate = DateTime.fromISO(this.filters.startDate).plus({
                day: 6
            }).toISODate()
        }
    }

    handleRefresh() {
        return this.handleSearch();
    }

    handleSearch() {
        if (!this.isValidQueryModel) return Promise.resolve();

        this.validateFilters();

        const territoryKeys = this.territoryKeys;
        let service = new optimizationRunService();
        this.showLoading();
        return service.getOptimizationRuns({
            request: {
                territoryKeys: territoryKeys,
                startDate: this.filters.startDate,
                endDate: this.filters.endDate
            }
        })
            .then((result) => {
                let data = autoMapper.autoMapperInstance.mapToArray('sked_Optimization_Run__c', result.returnedData || []);
                data.forEach((item) => {
                    item.recordPageUrl = '/' + item.id;
                    item.canClose = [OPTIMIZATION_STATUS.IN_PROGRESS, OPTIMIZATION_STATUS.POST_PROCESS].includes(item.status);
                    if(item.status === OPTIMIZATION_STATUS.POST_PROCESS) {
                        item.status = OPTIMIZATION_STATUS.IN_PROGRESS;
                    }
                })
                this.optimizationRuns = data;

                this.hideOptimizationRunDetails();
                this.setLastQuery();
            })
            .catch((error) => {
                console.log(error);
            })
            .finally(() => {
                this.hideLoading();
            });

    }

    hideOptimizationRunDetails() {
        this.selectedOptimizationRun = null;
        this.viewMode = this.VIEW_MODE.ALL;
    }

    showOptimizationRunDetails(item) {
        this.selectedOptimizationRun = item;
        this.viewMode = this.VIEW_MODE.DETAILS;
    }

    showCloseOptimizationRunConfirmModal(item) {
        this.showConfirmModal({
            title: 'Close Optimization Run Confirmation',
            message: 'Are you sure you want to close this optimization run?',
            onClose: (result) => {
                this.hideConfirmModal();

                if(result) {
                    this.showLoading();
                    let service = new optimizationRunService();
                    service.save({
                        id: item.id,
                        status: OPTIMIZATION_STATUS.CLOSED
                    })
                    .then(() => {
                        return this.handleRefresh();
                    })
                    .catch((error) => {
                        console.log(error);
                    })
                    .finally(() => {
                        this.hideLoading();
                    });
                }
            }
        });
    }

    handleRowAction(detail) {
        const actionName = detail.action;
        const id = detail.value;
        const row = this.optimizationRuns.find(item => item.id === id);
        if(!row) return;

        switch (actionName) {
            case 'view':
                this.showOptimizationRunDetails(row)
                break;
            case 'close':
                this.showCloseOptimizationRunConfirmModal(row)
                break;
            default:
        }
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

    /** Confirm Modal **/
    showConfirmModal(confirmModalData) {
        this.confirmModalData = {...confirmModalData,
            isOpen: true,
            confirmBtnLabel: confirmModalData.confirmBtnLabel || 'Yes',
            cancelBtnLabel: confirmModalData.cancelBtnLabel || 'No'
        }
    }

    hideConfirmModal() {
        this.confirmModalData = {};
    }
}