import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { cloneDeep, groupBy } from 'c/lodash';
import {
    sObjectType,
    driveService,
    driveQueryModel,
    driveChangeRequestService,
    driveChangeRequestQueryModel
} from 'c/dataService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { DRIVE_TYPE, OPERATION_TYPE, DRIVE_STATUS, DRIVE_REQUEST_CHANGE_STATUS } from 'c/slwcConstants';

const STEP = {
    SELECT_DATES: 1,
    CONFIRM: 2
} 

export default class SlwcRecurrenceDatesPickerModal extends LightningElement {
    @track _isOpen = false;
    @api
    get isOpen() {
        return this._isOpen;
    }
    set isOpen(value) {
        this._isOpen = value;
        if(this._isOpen) {
            this.init();
        }
    }

    @api drive = null;
    @api driveShiftSlot = null;
    @api selectedDays = [];

    @track showSpinner = false;
    @track step;
    @track model = {
        selectedDays: [],
        daysWithDrives: [] 
    }
    
    @wire(CurrentPageReference) pageRef;

    get isSelectDatesStep() {
        return this.step === STEP.SELECT_DATES
    }

    get isConfirmStep() {
        return this.step === STEP.CONFIRM
    }

    connectedCallback() {
    }

    disconnectedCallback() {
    }
    
    showLoading() {
        this.showSpinner = true;
    }
    
    hideLoading() {
        this.showSpinner = false;
    }

    init = () => {
        this.step = STEP.SELECT_DATES;
        this.model = {
            selectedDays: this.selectedDays
        };
    }

    handleOnChange = (event) => {
        this.model.selectedDays = cloneDeep(event.detail.selectedDays);
    }

    handleBack = () => {
        this.step = STEP.SELECT_DATES;
    }

    populateDaysWithDrives = (drives = []) => {
        return Promise.resolve()
            .then(() => {
                return this.retrieveActiveDriveChangeRequests({
                    driveIds: drives.map(item => item.id)
                })
            })
            .then(driveChangeRequests => {
                const mapDriveChangeRequestsByDriveId = groupBy(driveChangeRequests, 'driveId');

                const mapDrivesByDate = groupBy(drives, 'driveDate');
                const result = [];
                this.model.selectedDays.forEach(dateIso => {
                    result.push({
                        dateIso: dateIso,
                        drives: (mapDrivesByDate[dateIso] || []).map(drive => {
                            const errorMessages = [];
                            const hasPendingDCR = !!mapDriveChangeRequestsByDriveId[drive.id]?.length;
                            if(hasPendingDCR) {
                                errorMessages.push("Pending DCR")
                            }
                            return {
                                ...drive,
                                errorMessages
                            }
                        })
                    })
                })
        
                this.model.daysWithDrives = result;
            })
    }

    retrieveActiveDriveChangeRequests({
        driveIds = []
    }) {
        return Promise.resolve()
            .then(() => {
                if (!driveIds.length) return [];

                let dcrService = new driveChangeRequestService();
                let dcrQueryModel = new driveChangeRequestQueryModel();
                dcrQueryModel.driveIds = driveIds;
                dcrQueryModel.statuses = [
                    DRIVE_REQUEST_CHANGE_STATUS.PENDING,
                    DRIVE_REQUEST_CHANGE_STATUS.SUBMITTED,
                    DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_DM_APPROVAL,
                    DRIVE_REQUEST_CHANGE_STATUS.WAITING_FOR_APS_APPROVAL,
                    DRIVE_REQUEST_CHANGE_STATUS.APS_WAITING_FOR_DRD_FEEDBACK,
                    DRIVE_REQUEST_CHANGE_STATUS.DM_WAITING_FOR_DRD_FEEDBACK
                ];
                dcrQueryModel.subQueryIndicator = sObjectType.DRIVE_CHANGE_REQUEST_ITEM;

                return dcrService.query(dcrQueryModel)
                    .then((result) => {
                        return result;
                    });
            })
    }

    handleNext() {
        if(!this.model.selectedDays.length) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least 1 days',
                    variant: 'error'
                })
            );
            return;
        }

        this.showLoading();
        let driveQuery = new driveQueryModel();
        driveQuery.selectedDates = this.model.selectedDays;
        driveQuery.eventTypes = [DRIVE_TYPE.FIXED_SITE];
        driveQuery.operationTypes = [OPERATION_TYPE.INTEGRATED, OPERATION_TYPE.NON_INTEGRATED_APH, OPERATION_TYPE.NON_INTEGRATED_WB];
        driveQuery.collectionOpIds = [this.drive.collectionOperationId];
        driveQuery.locationIds = [this.drive.driveSiteId];
        driveQuery.statuses = [
          DRIVE_STATUS.SYSTEM_GENERATED,
          DRIVE_STATUS.TENTATIVE,
          DRIVE_STATUS.CONFIRMED,
          DRIVE_STATUS.HOLD
        ];
        driveQuery.excludedIds = [this.drive.id];
        driveQuery.isNotLinkedDrive = true;
        driveQuery.subQueryIndicator = sObjectType.DRIVE_SHIFT;

        const driveSvc = new driveService();

        return driveSvc.query(driveQuery)
        .then((result) => {     
            result.forEach((drive) => {
                drive.recordUrl = '/' + drive.id;
            });
            
            return this.populateDaysWithDrives(result);
        })
        .then(() => {
          this.step = STEP.CONFIRM  
        })
        .finally(() => {
            this.hideLoading();
        })
    }

    handleSave() {
        this.dispatchEvent(new CustomEvent('save', {
            detail: {
                selectedDays: this.model.daysWithDrives.filter(day => {
                    return day.drives.length && !!day.drives.find(drive => !drive.errorMessages.length)
                }).map(day => day.dateIso),
                selectedDriveIds: this.model.daysWithDrives.reduce((driveIds, day) => {
                    driveIds.push(...day.drives.filter(drive => !drive.errorMessages.length).map(drive => drive.id))
                    return driveIds;
                }, [])
            }
        }));
        this.closeModal();
    }
    closeModal() {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
            }
        }));
    }
}