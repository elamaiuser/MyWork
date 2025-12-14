import { LightningElement, track, api } from 'lwc';
import {
    loadStyle
} from 'lightning/platformResourceLoader';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { driveQueryModel, driveService, debugLogService, sObjectType } from 'c/dataService';
import { DateTime } from 'c/luxon';
import { groupBy, result } from 'c/lodash';
import { classNames, generateColors } from 'c/slwcUtils';
import { DRIVE_STATUS, DRIVE_OPERATION_TYPE, DRIVE_TYPE, LINK_DRIVE_TYPE, DRIVE_REQUEST_CHANGE_STATUS, DRIVE_CHANGE_REQUEST_TYPE } from 'c/slwcConstants';
import { drivesGeneratorInstance } from 'c/slwcDriveGenerator';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import customLWCStyle from '@salesforce/resourceUrl/skedLWCCustomStyle'

export default class SlwcDriveCalendarDriveList extends LightningElement {
    @track showSpinner = false;
    @track driveList;
    @track filteredList;
    @track hasResult = false;
    @track driveStatusGroups = [];
    @track totalDrives = 0;
    @track btnConfirmDisabled = true;
    @track selectedRows = [];
    @track cancelDriveModalData = {};
    @track linkedDriveModalData = {};
    @track confirmImpactedDrivesModalData = {};
    @track confirmModalData = {};
    @track confirmDrivesResultModalData = {};
    @track sortedBy;
    @track sortedDirection;

    @track driveSideMenuData = {
        shown: false,
        recordId: null
    }

    _filters = {};
    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {        
        this._filters = value;
        this.getDriveList();
    }
    @api isReadonly = false;
    @api includesAdditionalDays = 0;

    selectedStatus = null;

    get hideCheckboxColumn() {
        return this.isReadonly || this.selectedStatus === DRIVE_STATUS.CANCEL || this.selectedStatus === DRIVE_STATUS.COMPLETE;
    }

    get showConfirmBtn() {
        return [DRIVE_STATUS.DRAFT, DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE].includes(this.selectedStatus);
    }
    
    get showRemoveHoldBtn() {
        return [DRIVE_STATUS.HOLD].includes(this.selectedStatus);
    }

    get showCompleteBtn() {
        return [DRIVE_STATUS.CONFIRMED].includes(this.selectedStatus);
    }

    get showCancelBtn() {
        return [DRIVE_STATUS.DRAFT, DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD].includes(this.selectedStatus);
    }

    get selectedDrivesWithinCurrentWeek() {
        return (this.selectedRows || []).filter(drive => drive.driveDate >= this.filters.startDate && drive.driveDate <= this.filters.endDate);
    }
    
    get confirmBtnDisabled() {
        return !this.selectedDrivesWithinCurrentWeek.length;
    }

    get completeBtnDisabled() {
        return !this.selectedDrivesWithinCurrentWeek.length;
    }

    get removeHoldBtnDisabled() {
        return !this.selectedDrivesWithinCurrentWeek.length;
    }

    get cancelBtnDisabled() {
        return !this.selectedDrivesWithinCurrentWeek.length;
    }

    get isAllocateAssetsOnly() {
        return [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE].includes(this.selectedStatus);
    }

    get columns() {
        let results = [];
        results.push({label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', cellAttributes: { class: { fieldName: 'driveDateClass' }}, typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true } );
        results.push({label: 'Drive Name', fieldName: 'driveNameData', type: 'driveName', hideDefaultActions: false, wrapText: true, hideDefaultActions: true, sortable: true } );
        if ([DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE].includes(this.selectedStatus)) {
            results.push({
                type: 'action',
                typeAttributes: { rowActions: [
                    { label: 'View details', name: 'show_details' }
                ] },
            })
        }
        results.push({fieldName: 'linkedDrive', type: 'linkedDrive', initialWidth: 155, hideDefaultActions: true, wrapText: true, typeAttributes: {
            iconClicked: (event) => {
                this.handleLinkedDriveIconClicked(event.currentTarget.dataset['value'])
            }
        }});
        
        results.push({label: 'Collection Operation', fieldName: 'collectionOperationName', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true } );
        results.push({label: 'City', fieldName: 'city', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true } );
        if (this.selectedStatus === DRIVE_STATUS.DRAFT) {
            results.push({label: 'Rank', fieldName: 'rank', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true, wrapText: true } );
        }
        if (this.selectedStatus === DRIVE_STATUS.CONFIRMED) {
            results.push({label: 'Optimization Status', fieldName: 'optimizationStatus', type: 'text', hideDefaultActions: true, wrapText: true } );
        }
        results.push({label: 'Start Time', fieldName: 'startTimeStr', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true } );
        results.push({label: 'End Time', fieldName: 'endTimeStr', type: 'text', hideDefaultActions: true, wrapText: true, sortable: true } );
        results.push({label: '# of Staff Requested', fieldName: 'totalStaffRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: '# of Staff Scheduled', fieldName: 'staffAllocated', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        if (this.selectedStatus === DRIVE_STATUS.DRAFT) {
            results.push({label: 'Physical Location Type', fieldName: 'type', type: 'text', hideDefaultActions: true,wrapText: true } );
        }
        results.push({label: 'Vehicle Types', fieldName: 'vehicleTypes', type: 'text', hideDefaultActions: true, wrapText: true } );
        results.push({label: '# of Machines Requested', fieldName: 'totalEquipmentRequested', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: '# of Machines Allocated', fieldName: 'equipmentAllocated', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Projected Procedures', fieldName: 'totalProceduresProjected', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        results.push({label: 'Projected Products', fieldName: 'totalProductsProjected', type: 'number', cellAttributes: { alignment: 'left' }, hideDefaultActions: true } );
        return results;
    }

    connectedCallback() {
        this.initialize();
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, customLWCStyle)
        ])
        .then(() => {

        })
    }

    exceptionHandler = (error) => {
        new debugLogService().captureDebugLog(error);
        if(error && error.message) {
            this.dispatchEvent(new ShowToastEvent({
                message: error.message,
                variant: 'error',
                mode: 'dismissable',
            }));
        }
    }

    initialize() {
        let driveStatuses = [DRIVE_STATUS.DRAFT, DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.COMPLETE, DRIVE_STATUS.HOLD, DRIVE_STATUS.CANCEL];
        driveStatuses.forEach((driveStatus) => {
            let driveStatusGroup = {
                class: 'slds-grid slds-grid_vertical-align-center scheduling-status__filter-item',
                status: driveStatus,
                totalDrives: 0,
                name: driveStatus
            };

            driveStatusGroup.countClass = classNames('drives-count', {
                'status__draft': driveStatus === DRIVE_STATUS.DRAFT,
                'status__system-generated': driveStatus === DRIVE_STATUS.SYSTEM_GENERATED,
                'status__tentative': driveStatus === DRIVE_STATUS.TENTATIVE,
                'status__confirmed': driveStatus === DRIVE_STATUS.CONFIRMED,
                'status__complete': driveStatus === DRIVE_STATUS.COMPLETE,
                'status__hold': driveStatus === DRIVE_STATUS.HOLD,
                'status__cancelled': driveStatus === DRIVE_STATUS.CANCEL
            });
            this.driveStatusGroups.push(driveStatusGroup);
        });
    }

    currentGetDriveListPromise = Promise.resolve();
    getDriveList() {
        const territoryKeys = this.filters.territoryKeys || [];
        if(!territoryKeys.length) {
            return this.currentGetDriveListPromise.then(() => {
                this.totalDrives = 0;
                this.driveList = [];
                this.countDriveByStatus();
                this.filterDriveList(this.selectedStatus || DRIVE_STATUS.CONFIRMED);
                return Promise.resolve();
            })
        }

        let startDate = this.filters.startDate;
        let endDate = this.filters.endDate;

        if(this.includesAdditionalDays > 0) {
            startDate = DateTime.fromISO(startDate).minus({
                day: this.includesAdditionalDays
            }).toISODate();
            endDate = DateTime.fromISO(endDate).plus({
                day: this.includesAdditionalDays
            }).toISODate()
        }

        this.showSpinner = true;
        let driveQuery = new driveQueryModel();
        driveQuery.territoryKeys = territoryKeys;
        driveQuery.startDate = startDate;
        driveQuery.endDate = endDate;
        driveQuery.eventTypes = this.filters.driveTypes;
        driveQuery.stages = this.filters.stages;
        //driveQuery.statuses = this.filters.driveStatuses;
        driveQuery.accountTypes = this.filters.accountTypes;
        driveQuery.accountIndustryCodes = this.filters.accountIndustryCodes;
        driveQuery.procedureTypes = this.filters.procedureTypes;
        driveQuery.showOnlyLinkedEvents = this.filters.showOnlyLinkedEvents;
        driveQuery.showOnlyDualRolesAutoGeneratedDrives = this.filters.showOnlyDualRolesAutoGeneratedDrives;
        // driveQuery.recruitedBys = this.filters.recruitedBys;
        driveQuery.markets = (this.filters.markets || []).map(market => {
            return market.id;
        });
        driveQuery.accountManagerPortfolioIds = (this.filters.accountManagerPortfolios || []).map(accountManagerPortfolio => {
            return accountManagerPortfolio.id;
        });
        driveQuery.districtManagerPortfolioIds = (this.filters.districtManagerPortfolios || []).map(districtManagerPortfolio => {
            return districtManagerPortfolio.id;
        })

        //driveQuery.operationTypes = this.filters.operationTypes;
        driveQuery.driveOperationTypes = this.filters.driveOperationTypes;
        driveQuery.subQueryIndicator = sObjectType.JOB | sObjectType.DRIVE_SHIFT;

        // driveQuery.daysOfWeek = this.filters.daysOfWeek;
        if (this.filters.searchText && this.filters.searchField) {
            driveQuery.queryText = this.filters.searchText;
            driveQuery.searchColumns = [this.filters.searchField];
        }
        
        let service = new driveService();
        this.currentGetDriveListPromise = service.query(driveQuery)
            .then((result) => {
                let drives = [];
                if (result && result.length) {
                    result
                    .filter(drive => {
                        const selectedTimeBlocks = this.filters.collectionOperationValues?.timeBlocks || [];
                        const selectedTimeBlockIds = selectedTimeBlocks.map(item => item.value);
                        if(!selectedTimeBlockIds.length) return true;

                        const isFixedSiteDrive = drive.driveOperationType === DRIVE_OPERATION_TYPE.FIXED_SITE;
                        if(isFixedSiteDrive) return true;

                        const anyDriveShiftMatchTimeBlock = !!drive.driveShifts?.find(driveShift => {
                            return selectedTimeBlockIds.includes(driveShift.timeBlockId);
                        });

                        return anyDriveShiftMatchTimeBlock;
                    })
                    .forEach((drive) => {
                        drive.recordPageUrl = '/' + drive.id;
                        drive.driveNameData = {
                            id: drive.id,
                            name: drive.name,
                            totalStaffRequested: drive.totalStaffRequested,
                            staffAllocated: drive.staffAllocated
                        };
                        
                        drive.linkedDrive = drive.linkedDriveId ? {
                            id: drive.linkedDriveId,
                            driveId: drive.id,
                            name: drive.linkedDriveName,
                            linkedDriveType: drive.linkedDriveType,
                            url: '/' + drive.linkedDriveId
                        } : null;

                        drive.type = drive.opportunity.type;
                        drive.collectionOperationName = drive.collectionOperation.name;
                        drive.city = drive.driveSite.city;
                        drive.startTimeStr = this.formatTime(drive.startTime);
                        drive.endTimeStr = this.formatTime(drive.endTime);

                        /*drive.driveDateClass = (drive.driveDate < this.filters.startDate || 
                            drive.driveDate > this.filters.endDate) ? 'background-gray-outside' : 'background-blue-super-light important'; */
                        drive.driveDateClass = this.getDriveDateClass(drive.driveDate);

                        drives.push(drive);
                    });
                }
                this.totalDrives = drives.length;
                this.driveList = drives;

                this.updateLinkedDrivesStyle();
                this.countDriveByStatus();

                this.filterDriveList(this.selectedStatus || DRIVE_STATUS.CONFIRMED);
            })
            .catch((error) => {
                console.log(error);
            })
            .finally(() => {
                this.showSpinner = false;
            });

        return this.currentGetDriveListPromise;
    }

    getDriveDateClass(driveDate) {
        if (driveDate < this.filters.startDate || driveDate > this.filters.endDate) {
            return 'background-gray-outside';
        }
        const dayOfWeek = DateTime.fromISO(driveDate).weekday;
        switch(dayOfWeek) {
            case 1:
                return 'background-orange-monday';
            case 2:
                return 'background-skyblue-tuesday';
            case 3:
                return 'background-orchid-wednesday';
            case 4:
                return 'background-bluishgreen-thursday';
            case 5:
                return 'background-chartreuse-friday';
            case 6:
                return 'background-brightblue-saturday';
            case 7:
                return 'background-burntOrange-sunday';
            default:
                return '';
        }
    }

    countDriveByStatus() {
        let drivesGroupByStatus = groupBy(this.driveList, 'status');
        this.driveStatusGroups.forEach((group) => {
            group.totalDrives = 0;
            if (drivesGroupByStatus[group.status]) {
                group.totalDrives = drivesGroupByStatus[group.status].length;
            }
        });
    }

    updateLinkedDrivesStyle() {
        let drivesGroupByLinkedDrive = groupBy(this.driveList.filter(drive => !!drive.linkedDriveId), (drive) => {
            return drive.linkedDriveId;
        });
        const colors = generateColors(Object.keys(drivesGroupByLinkedDrive).length);

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

    handleFilterDrives(event) {
        let selectedStatus = event.currentTarget.dataset['value'];
        this.filterDriveList(selectedStatus);
    }

    filterDriveList(driveStatus) {
        this.selectedStatus = driveStatus;
        this.filteredList = this.driveList.filter((drive) => drive.status === driveStatus);
        this.driveStatusGroups.forEach((group) => {
            group.class = classNames('slds-grid slds-grid_vertical-align-center scheduling-status__filter-item', {
                'is-selected': group.status === driveStatus
            });
        });
        if (this.sortedBy && this.sortedDirection) {
            this.sortData(this.sortedBy, this.sortedDirection);
        }
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldName, sortDirection) {
        let dataToSort = [...this.filteredList];
        let keyValue = (obj) => {
            switch (fieldName) {
                case 'driveNameData':
                    return obj.driveNameData ? obj.driveNameData.name : '';
                case 'startTimeStr':
                    return obj.startTime;
                case 'endTimeStr':
                    return obj.endTime;
                default:
                    return obj[fieldName];
            }
        };

        const reverse = sortDirection === 'asc' ? 1 : -1;
        dataToSort.sort((a, b) => {
            let valueA = keyValue(a) || '';
            let valueB = keyValue(b) || '';
            if(typeof valueA === 'string' && typeof valueB === 'string') {
                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();
            }
            let result = 0;
            if (valueA > valueB) {
                result = 1;
            } else if (valueA < valueB) { 
                result = -1;
            }

            return result * reverse;
        });
        this.filteredList = dataToSort;
    }
        

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows || [];
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
        // this.closeDriveSideMenu();
        this.handleRefresh();
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'show_details':
                this.openDriveSideMenu(row.id)
                break;
            default:
        }
    }

    updateConfirmDriveStatus(driveList) {
        const nextStatusMap = {
            [DRIVE_STATUS.DRAFT]: DRIVE_STATUS.CONFIRMED,
            [DRIVE_STATUS.SYSTEM_GENERATED]: DRIVE_STATUS.CONFIRMED,
            [DRIVE_STATUS.TENTATIVE]: DRIVE_STATUS.CONFIRMED,
            [DRIVE_STATUS.CONFIRMED]: DRIVE_STATUS.COMPLETE
        }

        if(!driveList || !driveList.length) return [];

        return driveList.map(drive => {
            return {
                id: drive.id,
                status: nextStatusMap[drive.status]
            }
        })
    }

    saveDrives(drives) {
        if(!drives || !drives.length) return Promise.resolve();

        this.showSpinner = true;
        let service = new driveService();
        return service.saveList(drives)
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    message: 'Drives are updated successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
                return this.handleRefresh();
            })
            .catch((e) => this.exceptionHandler(e))
            .finally(() => {
                this.showSpinner = false;
            });
    }

    confirmDrives(drives = []) {
        let impactedDrives = [];
        let confirmedDrives = [];
        return Promise.resolve()
        .then(() => {
            confirmedDrives = drives //all mobile drives
                .filter(drive => !drive.typeOfDrive || drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE)
                .map((drive) => {
                    return {
                        id: drive.id,
                        status: DRIVE_STATUS.CONFIRMED
                    }
                })
    
            let mobileDriveIds = drives
                .filter(drive => drive.typeOfDrive === DRIVE_TYPE.MOBILE)
                .map(drive => drive.id);
            
            return drivesGeneratorInstance.initialize(mobileDriveIds);
        })
        .then(() => {
            //recalculate vehicles 
            let allDrivesEnoughVehicles = drivesGeneratorInstance.proposeVehicles();
            if(!allDrivesEnoughVehicles) {
                throw {
                    errorMessage: 'Not enough vehicles for all selected drives. Please remove some drives.'
                }
            }

            drivesGeneratorInstance.drives.forEach(drive => {
                drive.status = DRIVE_STATUS.CONFIRMED;
                if(drive.impactedVehicleMessages && drive.impactedVehicleMessages.length) {
                    impactedDrives.push(drive);
                } else {
                    confirmedDrives.push(drive);
                }
            })
        })
        .then(() => {
            return {
                impactedDrives,
                confirmedDrives
            }
        })
    }

    checkForAnyDriveOutsideCurrentWeek(doAction) {
        const anyDriveOutsideCurrentWeek = this.selectedRows.find(drive => {
            return drive.driveDate < this.filters.startDate || drive.driveDate > this.filters.endDate
        })

        if(anyDriveOutsideCurrentWeek) {
            this.showConfirmModal({
                title: 'Confirmation',
                message: 'You may only take action on Drives which fall within the currently selected work week.\nDo you want to continue?',
                onClose: (result) => {
                    this.hideConfirmModal();
                    if (result) {
                        doAction()
                    }
                },
                confirmBtnLabel: 'Yes',
                cancelBtnLabel: 'No'
            });
            return;
        }
        
        doAction();
    }

    validateConfirmDrives(drives) {
        return Promise.resolve()
        .then(() => {
            if(!drives || !drives.length) return [];

            let service = new driveService();
            let queryModel = new driveQueryModel();
            queryModel.recordIds = drives.map(drive => drive.id);
            queryModel.subQueryIndicator = sObjectType.DRIVE_CHANGE_REQUEST;
            queryModel.driveChangeRequestStatuses = [
                                DRIVE_REQUEST_CHANGE_STATUS.PENDING,
                                DRIVE_REQUEST_CHANGE_STATUS.SUBMITTED,
                                DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL,
                                DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL,
                                DRIVE_REQUEST_CHANGE_STATUS.APS_WAITING_FOR_DRD_FEEDBACK,
                                DRIVE_REQUEST_CHANGE_STATUS.DM_WAITING_FOR_DRD_FEEDBACK
            ];
            queryModel.driveChangeRequestType = [DRIVE_CHANGE_REQUEST_TYPE.USER_CHANGE];
            return service.query(queryModel);
        })
        .then((drives) => {
            return drives.map(drive => {
                const validateDriveRule1 = !!drive.primaryContactId || drive.typeOfDrive === DRIVE_TYPE.FIXED_SITE;
                const validateDriveRule2 = !(drive && drive.driveChangeRequests && drive.driveChangeRequests.length > 0 && drive.driveChangeRequests[0].type.includes(DRIVE_CHANGE_REQUEST_TYPE.USER_CHANGE));
                const passed = validateDriveRule1 && validateDriveRule2;
                const messages = [];
                if (!validateDriveRule1) {
                    messages.push('Please add a contact with a drive service role of Primary Contact before proceeding.');
                }
                if (!validateDriveRule2) {
                    messages.push('Please process the [User Change] Drive Change Request prior to updating the Drive.');
                }
                const message = passed
                                ? 'Successfully confirmed drive.'
                                : messages.join('\n');
                return {
                    id: drive.id,
                    passed: passed,
                    drive: drive,
                    message: message
                }
            });
        });
    }

    handleConfirmBtn() {
        const doConfirm = () => {
            let service = new driveService();
            this.showSpinner = true;
            this.validateConfirmDrives(this.selectedDrivesWithinCurrentWeek)
            .then((confirmDrivesResult) => {
                let drivesCanConfirm = confirmDrivesResult.filter(item => item.passed);
                if(!drivesCanConfirm.length) {
                    return confirmDrivesResult;
                }

                return service.saveList(drivesCanConfirm.map(drive => {
                    return {
                        id: drive.id,
                        status: DRIVE_STATUS.CONFIRMED
                    }
                }))
                .then(() => {
                    return confirmDrivesResult;
                });
            })
            .then((confirmDrivesResult) => {
                this.showConfirmDrivesResultModal(confirmDrivesResult);
            })
            .catch((e) => this.exceptionHandler(e))
            .finally(() => {
                this.showSpinner = false;
            });
        }
        this.checkForAnyDriveOutsideCurrentWeek(doConfirm)
    }

    handleCompleteBtn() {
        const doComplete = () => {
            let drivesToSave = this.updateConfirmDriveStatus(this.selectedDrivesWithinCurrentWeek);
            return this.saveDrives(drivesToSave);
        }
        this.checkForAnyDriveOutsideCurrentWeek(doComplete)
    }

    handleCancelBtn() {
        const doCancel = () => {
            this.showCancelDriveModal(this.selectedDrivesWithinCurrentWeek);
        }
        this.checkForAnyDriveOutsideCurrentWeek(doCancel)        
    }

    handleRemoveHoldBtn() {
        const doRemoveHold = () => {
            let drivesToSave = (this.selectedDrivesWithinCurrentWeek || []).map((drive) => {
                return {
                    id: drive.id,
                    status: DRIVE_STATUS.DRAFT
                }
            })
            return this.saveDrives(drivesToSave);
        }
        this.checkForAnyDriveOutsideCurrentWeek(doRemoveHold)
    }

    handleRefresh() {
        this.sortedBy = null;
        this.sortedDirection = null;
        return this.getDriveList();
    }

    showCancelDriveModal = (drives) => {
        this.cancelDriveModalData = {
            shown: true,
            drives: drives || []
        }
    }

    closeCancelDriveModal = (event) => {
        this.cancelDriveModalData = {};
        const result = !!event.detail.result;
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

    showConfirmImpactedDrivesModal = (confirmedDrives, impactedDrives) => {
        this.confirmImpactedDrivesModalData = {
            shown: true,
            confirmedDrives: confirmedDrives,
            impactedDrives: impactedDrives
        }
    }

    closeConfirmImpactedDrivesModal = (event) => {
        this.confirmImpactedDrivesModalData = {};
    }
    
    handleSaveConfirmImpactedDrivesModal = (event) => {
        const impactedDrives = event.detail.drives || [];
        const confirmedDrives = this.confirmImpactedDrivesModalData.confirmedDrives || [];
        this.confirmImpactedDrivesModalData = {};

        this.saveDrives(confirmedDrives.concat(impactedDrives));
    }

    formatTime(time) {
        if (!time) {
            return '';
        }
        return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
    }

    showConfirmDrivesResultModal = (confirmDrivesResult) => {
        this.confirmDrivesResultModalData = {
            shown: true,
            confirmDrivesResult: confirmDrivesResult
        }
    }

    closeConfirmDrivesResultModal = (event) => {
        this.confirmDrivesResultModalData = {};
        return this.handleRefresh();
    }

    /** Confirm Modal **/
    showConfirmModal(confirmModalData) {
        this.confirmModalData = {...confirmModalData,
            isOpen: true
        }
    }

    hideConfirmModal() {
        this.confirmModalData = {};
    }
}