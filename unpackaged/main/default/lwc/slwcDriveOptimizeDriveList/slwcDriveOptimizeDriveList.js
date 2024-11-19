import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { DateTime } from 'c/luxon';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { driveQueryModel, driveService, optimizationRunService, optimizationRunQueryModel, sObjectType } from 'c/dataService';
import { groupBy, uniq, pick, cloneDeep } from 'c/lodash';
import * as slwcUtils from "c/slwcUtils";
import * as slwcDateUtils from 'c/slwcDateUtils';
import { OPTIMIZATION_STATUS, LINK_DRIVE_TYPE } from 'c/slwcConstants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const actions = [
    { label: 'View details', name: 'show_details' },
];
export default class SlwcDriveOptimizeDriveList extends LightningElement {
    @track initialized = false;
    @track showSpinner = false;
    @track driveList;
    @track filteredList;
    @track hasResult = false;
    @track statusGroups = [];
    @track totalDrives = 0;
    @track optimizeConfirmModalData = {};
    @track dispatchDriveModalData = {};
    @track linkedDriveModalData = {};
    isEditable = false;
    draftValues = [];

    @track selectedDriveIdsMap = {
        [OPTIMIZATION_STATUS.PENDING]: [],
        [OPTIMIZATION_STATUS.IN_PROGRESS]: [],
        [OPTIMIZATION_STATUS.COMPLETED]: [],
        [OPTIMIZATION_STATUS.ERROR]: []
    };

    @track driveSideMenuData = {
        shown: false,
        recordId: null
    }
    
    @track filters = {
        collectionOperationValues: {
            divisions: [],
            arcRegions: [],
            districts: [],
            territoryCollectionOperations: []
        },
        startDate: null,
        endDate: null,
        driveTypes: []
    }

    get optimizationEnabled() {
        //HRP-5074: Temporarily allow to optimize multiple collection operation in same ARC Region
        const districtIds = uniq((this.territoryKeys || []).map(item => item.split(':')[0]));
        const districts = (this.districts || []).filter(item => districtIds.includes(item.id));
        const arcRegionIds = uniq(districts.map(item => item.parentId));
        return arcRegionIds.length === 1;
    }
    
    get selectedDriveIds() {
        return Object.values(this.selectedDriveIdsMap).reduce((result, item) => {
            return result.concat(item) 
        }, []);
    }
    get selectedPendingDriveIds() {
        return this.selectedDriveIdsMap[OPTIMIZATION_STATUS.PENDING] || [];
    }

    selectedStatus = null;

    get pageName() {
        return 'schedulingConsole:driveOptimizer';
    }

    get dateUtils() {
        return slwcDateUtils.getInstance({
            timezone: TIME_ZONE
        });
    }

    get hideCheckboxColumn() {
        return this.selectedStatus === OPTIMIZATION_STATUS.IN_PROGRESS;
    }

    get btnOptimizeDisabled() {
        return this.selectedDriveIds.length === 0;
    };

    get btnOptimizeLabel() {
        return `Optimize (${this.selectedDriveIds.length} selected)`;
    };

    get btnDispatchDisabled() {
        return this.selectedDriveIds.length === 0;
    };

    get btnDispatchLabel() {
        return `Dispatch (${this.selectedDriveIds.length} selected)`;
    };

    get districts() {
        if (!this.filters || !this.filters.collectionOperationValues) [];
        return this.filters.collectionOperationValues.districts;
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
    
    get hasExistingOptimizationRun() {
        if (this.driveList && this.driveList.length) {
            let inProgressDrives = this.driveList.filter((drive) => {
                return drive.optimizationStatus === 'In Progress';
            });
            return inProgressDrives.length > 0;
        }
        return false;
    }

    get columns() {
        let results = [];
        results.push({label: 'Collection Operation', fieldName: 'collectionOperationName', type: 'text', hideDefaultActions: false, wrapText: true, hideDefaultActions: true } );
        results.push({label: 'Drive Name', fieldName: 'recordPageUrl', type: 'url', hideDefaultActions: false, wrapText: true, typeAttributes: {label: { fieldName: 'name' }, target: '_blank' }, hideDefaultActions: true } );
        if (this.selectedStatus != "In Progress") {
            results.push({
                type: 'action',
                typeAttributes: { rowActions: actions },
            })
        }
        // results.push({fieldName: 'linkedDrive', type: 'linkedDrive', initialWidth: 155, hideDefaultActions: true, wrapText: true, typeAttributes: {
        //     iconClicked: (event) => {
        //         this.handleLinkedDriveIconClicked(event.currentTarget.dataset['value'])
        //     }
        // }});
        results.push({label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: "numeric", month: "short", day: "2-digit" }, hideDefaultActions: true } );
        results.push({label: 'Event Type', fieldName: 'typeOfDrive', type: 'text', hideDefaultActions: true, wrapText: true } );
        results.push({label: 'Vehicle Types', fieldName: 'vehicleTypes', type: 'text', hideDefaultActions: true, wrapText: true } );
        results.push({label: 'Min Shift Start', fieldName: 'minShiftStart', type: 'date', typeAttributes: { hour: "numeric", minute: "2-digit", timeZone: TIME_ZONE }, hideDefaultActions: true } );
        results.push({label: 'Max Shift End', fieldName: 'maxShiftEnd', type: 'date', typeAttributes: { hour: "numeric", minute: "2-digit", timeZone: TIME_ZONE }, hideDefaultActions: true } );
        results.push({label: 'Staff Requested', fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Staff Scheduled', fieldName: 'staffAllocated', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Exclude From Optimizer', fieldName: 'excludeFromOptimizer', type: 'boolean', hideDefaultActions:true, editable: this.isEditable } );
        return results;
    }

    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        //init settings
        if (!this.initialized) {
            this.initialize();
        }
    }  

    renderedCallback() {
        if(!this.initialized) {
            this.handleSearch();
            this.initialized = true;
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    initialize() {
        //init settings
        if (!this.initialized) {
            let lastSearchQuery = this.getLastQuery();
            if (lastSearchQuery) {
                this.filters = {
                    ...this.filters, 
                    ...lastSearchQuery
                };
            } else {
                this.selectedAllByDefault = true;
            }

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
            
            let optimizationStatuses = [OPTIMIZATION_STATUS.PENDING, OPTIMIZATION_STATUS.IN_PROGRESS, OPTIMIZATION_STATUS.COMPLETED, OPTIMIZATION_STATUS.ERROR];
            optimizationStatuses.forEach((status) => {                
                let statusGroup = {
                    class: "slds-grid slds-grid_vertical-align-center scheduling-status__filter-item",
                    status: status,
                    totalDrives: 0
                };
                statusGroup.countClass = slwcUtils.classNames('drives-count', {
                    'status__pending-action': status === OPTIMIZATION_STATUS.PENDING,
                    'status__in-progress': status === OPTIMIZATION_STATUS.IN_PROGRESS,
                    'status__completed': status == OPTIMIZATION_STATUS.COMPLETED,
                    'status__error': status == OPTIMIZATION_STATUS.ERROR
                });
                this.statusGroups.push(statusGroup);
            });
        }
    }

    showLoading() {
        this.showSpinner = true;
    }

    hideLoading() {
        this.showSpinner = false;
    }

    openDriveSideMenu(recordId) {
        const driveStaffingDetailsCmp = this.template.querySelector('c-slwc-drive-staffing-details');
        if(driveStaffingDetailsCmp && driveStaffingDetailsCmp.isLoading()) return;
        
        this.driveSideMenuData = {
            shown: true,
            recordId: recordId
        }
    }

    closeDriveSideMenu() {
        this.driveSideMenuData = {
            shown: false,
            recordId: ''
        }
    }

    saveDriveSideMenu() {
        this.closeDriveSideMenu();
    }

    handleRowAction(event) {
        console.log('handleRowAction', event);
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'show_details':
                this.openDriveSideMenu(row.id)
                break;
            default:
        }
    }

    getDriveList() {
        const territoryKeys = this.territoryKeys;

        if(!territoryKeys.length) {
            this.driveList = [];
            this.totalDrives = 0;
            this.filteredList = [];
            this.countDriveByStatus();
            this.resetSelectedDriveIds();
            return Promise.resolve();
        }

        let driveQuery = new driveQueryModel();
        driveQuery.territoryKeys = territoryKeys;
        driveQuery.startDate = this.filters.startDate;
        driveQuery.endDate = this.filters.endDate;
        driveQuery.eventTypes = this.filters.driveTypes;
        driveQuery.statuses = ['Confirmed'];

        let service = new driveService();
        this.showLoading();
        return service.getDrives_OptimizeDriveList(driveQuery)
            .then((result) => {
                let drives = [];
                if (result && result.length) {
                    result.forEach((drive) => {
                        drive.recordPageUrl = '/' + drive.id;
                        drive.linkedDrive = drive.linkedDriveId ? {
                            id: drive.linkedDriveId,
                            driveId: drive.id,
                            name: drive.linkedDriveName,
                            linkedDriveType: drive.linkedDriveType,
                            url: '/' + drive.linkedDriveId
                        } : null;
                        drives.push(drive);
                    });
                }
                this.totalDrives = drives.length;
                this.driveList = drives;
                this.countDriveByStatus();
                this.updateLinkedDrivesStyle();
                this.resetSelectedDriveIds();
                this.filterDriveList(this.selectedStatus || OPTIMIZATION_STATUS.PENDING);
            })
            .catch((error) => this.exceptionHandler(error))
            .finally(() => {
                this.hideLoading();
            });
    }

    updateLinkedDrivesStyle() {
        let drivesGroupByLinkedDrive = groupBy(this.driveList.filter(drive => !!drive.linkedDriveId), (drive) => {
            return drive.linkedDriveId;
        });
        const colors = slwcUtils.generateColors(Object.keys(drivesGroupByLinkedDrive).length);

        Object.keys(drivesGroupByLinkedDrive).forEach((linkedDriveId, linkedDriveIndex) => {
            const drives = drivesGroupByLinkedDrive[linkedDriveId];
            let color = colors.shift();

            drives.forEach(drive => {
                drive.linkedDrive = {
                    ...drive.linkedDrive,
                    linkedDriveIndex: linkedDriveIndex + 1,
                    isMultiDayLink: drive.linkedDrive.linkedDriveType === LINK_DRIVE_TYPE.MULTI_DAY,
                    customStyle: {
                        iconContainer: `background-color: ${color}`
                    }
                }
            })
        })
    }

    resetSelectedDriveIds() {
        this.selectedDriveIdsMap = {
            [OPTIMIZATION_STATUS.PENDING]: [],
            [OPTIMIZATION_STATUS.IN_PROGRESS]: [],
            [OPTIMIZATION_STATUS.COMPLETED]: [],
            [OPTIMIZATION_STATUS.ERROR]: []
        };
    }

    countDriveByStatus() {
        let drivesGroupByStatus = groupBy(this.driveList, "optimizationStatus");
        this.statusGroups.forEach((group) => {
            group.totalDrives = 0;
            if (drivesGroupByStatus[group.status]) {
                group.totalDrives = drivesGroupByStatus[group.status].length;
                if(group.status === OPTIMIZATION_STATUS.PENDING) {
                    group.totalDrives += (drivesGroupByStatus[undefined] || []).length;
                }
                if(group.status === OPTIMIZATION_STATUS.IN_PROGRESS) {
                    group.totalDrives += (drivesGroupByStatus[OPTIMIZATION_STATUS.POST_PROCESS] || []).length;
                }
            }
        });
    }

    handleFilterDrives(event) {
        this.selectedStatus = event.currentTarget.dataset['value'];
        this.isEditable = this.selectedStatus === OPTIMIZATION_STATUS.COMPLETED ? true : false;        
        this.filterDriveList(this.selectedStatus);
    }

    filterDriveList(optimizationStatus) {
        this.filteredList = (this.driveList || []).filter((drive) => {
            if(optimizationStatus === OPTIMIZATION_STATUS.PENDING) {                
                return !drive.optimizationStatus || drive.optimizationStatus === optimizationStatus;
            }
            if(optimizationStatus === OPTIMIZATION_STATUS.IN_PROGRESS) {                
                return drive.optimizationStatus === OPTIMIZATION_STATUS.IN_PROGRESS || drive.optimizationStatus === OPTIMIZATION_STATUS.POST_PROCESS;
            }            
            return drive.optimizationStatus === optimizationStatus;
        });
        
        this.statusGroups.forEach((group) => {
            group.class = slwcUtils.classNames('slds-grid slds-grid_vertical-align-center scheduling-status__filter-item', {
                'is-selected': group.status == optimizationStatus
            });
        });
        this.selectedStatus = optimizationStatus;

        this.renderingDriveList = true;
        setTimeout(() => {
            this.renderingDriveList = false;
        })
    }

    handleRowSelection(event) {
        if(this.renderingDriveList) return;
        this.selectedDriveIdsMap[this.selectedStatus] = (event.detail.selectedRows || []).map(item => item.id);
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

    handleSearch() {
        this.validateFilters();
        this.getDriveList();
        this.setLastQuery();
    }

    handleRefresh() {
        this.getDriveList()
    }

    handleSave(event) {
        this.showLoading();
       let excludeDrives = event.detail.draftValues.map((item) => {
        return { 
            ...item,
            id: item.id,
            excludeFromOptimizer: item.excludeFromOptimizer            
        }
       });
       this.draftValues = [];       
       let service = new driveService();
       service.saveList(excludeDrives).then((result) => {
        if(!result.success) throw result;
        this.handleRefresh();        
        this.dispatchEvent(new ShowToastEvent({
            message: 'Drives updated successfully',
            variant: 'success',
            mode: 'dismissable'
        }));        
        })
        .catch((error) => this.exceptionHandler(error))
        .finally(this.hideLoading());            
    }

    exceptionHandler = (error) => {        
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }

    showOptimizeConfirmModal() {
        if(this.hasExistingOptimizationRun) {
            this.dispatchEvent(new ShowToastEvent({
                message: 'There is an in progress optimization run. Please wait until it is finished.',
                variant: 'error',
                mode: 'dismissable'
            }));
            return;
        }
        
        let selectedDriveIds = this.selectedDriveIds || [];
        let drives = this.driveList.filter(item => selectedDriveIds.includes(item.id));
        this.optimizeConfirmModalData = {
            isOpen: true,
            drives: drives,
            collectionOperationId: this.collectionOperations[0].id,
            onClose: (result) => {
                this.hideOptimizeConfirmModal();

                if (result) {
                    this.handleRefresh()
                }
            }
        };
    }

    hideOptimizeConfirmModal() {
        this.optimizeConfirmModalData = {};
    }


    showDispatchDriveModal() {
        let selectedDriveIds = this.selectedDriveIds || [];
        let drives = this.driveList.filter(item => selectedDriveIds.includes(item.id));
        this.dispatchDriveModalData = {
            isOpen: true,
            drives: drives
        };
    }

    hideDispatchDriveModal(event) {
        const result = event.detail.result;
        this.dispatchDriveModalData = {};

        if(result) {
            this.handleRefresh();
        }
    }
    
    showLinkedDriveModal = (drive) => {
        this.linkedDriveModalData = {
            shown: true,
            drive: drive
        }
    }

    closeLinkedDriveModal = (event) => {
        this.linkedDriveModalData = {};
        const result = !!event.detail.result;
        if(result) {
            this.handleRefresh();
        }
    }

    handleLinkedDriveIconClicked = (driveId) => {
        const drive = this.driveList.find(item => item.id === driveId);
        if(!drive) return;

        this.showLinkedDriveModal(drive); 
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