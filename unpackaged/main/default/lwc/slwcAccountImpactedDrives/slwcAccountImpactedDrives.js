import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { maxBy, minBy, chunk } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { serial } from 'c/slwcUtils';

import { DRIVE_STATUS, DRIVE_TYPE } from 'c/slwcConstants';
import { fixedSiteProcedureProjectionService, fixedSiteProcedureProjectionQueryModel, driveService, driveQueryModel } from 'c/dataService';
import { drivesGeneratorInstance } from 'c/slwcDriveGenerator';

import TIME_ZONE from '@salesforce/i18n/timeZone';

const COLUMNS = [
    { label: 'Name', fieldName: 'recordUrl', type: 'url', hideDefaultActions: true, wrapText: true, typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
    { label: 'Drive Date', fieldName: 'driveDate', type: 'date-local', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' }, hideDefaultActions: true },
    { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true, wrapText: true }
];

export default class SlwcAccountImpactedDrives extends LightningElement {
    @api recordId;
    
    @track showSpinner = false;
    @track fixedSiteProcedureProjections = [];
    @track drives = [];
    @track columns = COLUMNS;
    @track selectedDriveIds = [];
    @track progressBarData = {};

    get btnUpdateDisabled() {
        return this.selectedDriveIds.length === 0;
    };

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.intialize();
        }
    }

    intialize() {
        this.showSpinner = true;
        return Promise.all([
            this.retrieveFixedSiteProcedureProjections()
        ])
        .then(() => {
            return this.retrieveImpactDrives();    
        })
        .finally(() => {
            this.showSpinner = false;
        });
    }

    showProgressBar({
        message,
        processedRecords = 0,
        totalRecords = 0
    }) {
        this.progressBarData = {
            isOpen: true,
            message,
            processedRecords,
            totalRecords
        }
    }

    updateProgressBar({ message, processedRecords }) {
        this.progressBarData = {
            ...this.progressBarData,
            message,
            processedRecords
        }
    }

    hideProgressBar() {
        this.progressBarData = {}
    }

    retrieveFixedSiteProcedureProjections() {
        return Promise.resolve()
        .then(() => {
            let fixedSiteProcedureProjectionSvc = new fixedSiteProcedureProjectionService();
            let query = new fixedSiteProcedureProjectionQueryModel();
            query.accountIds = [this.recordId];
            query.impactDrives = true;

            return fixedSiteProcedureProjectionSvc.query(query)
                .then((result) => {
                    this.fixedSiteProcedureProjections = result;
                });
        });
    }

    retrieveImpactDrives() {
        return Promise.resolve()
        .then(() => {
            if (this.fixedSiteProcedureProjections && this.fixedSiteProcedureProjections.length) {
                const today = DateTime.fromObject({
                    zone: TIME_ZONE
                  }).toISODate();
              
                let startDate = minBy(this.fixedSiteProcedureProjections.map(item => item.effectiveStartDate), startDate => {
                    return startDate || '1900-01-01';
                });
                if (!startDate || startDate < today) {
                    startDate = today;
                }

                let endDate = maxBy(this.fixedSiteProcedureProjections.map(item => item.effectiveEndDate), endDate => {
                    return endDate || '2999-12-30';
                });

                let driveSvc = new driveService();
                let query = new driveQueryModel();
                query.accountIds = [this.recordId];
                query.startDate = startDate;
                query.endDate = endDate;
                query.eventTypes = [DRIVE_TYPE.FIXED_SITE];
                query.statuses = [DRIVE_STATUS.SYSTEM_GENERATED, DRIVE_STATUS.DRAFT, DRIVE_STATUS.TENTATIVE, DRIVE_STATUS.CONFIRMED, DRIVE_STATUS.HOLD];

                return driveSvc.query(query)
                    .then((result) => {
                        result.forEach((drive) => {
                            drive.recordUrl = '/' + drive.id;
                        });
                        this.drives = result;
                    });
            }
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleRowSelection(event) {
        this.selectedDriveIds = (event.detail.selectedRows || []).map(item => item.id);
    }

    handleUpdateImpactedDrives() {
        this.showProgressBar({
            message: 'Preparing data...',
            totalRecords: this.selectedDriveIds.length,
        });

        return Promise.resolve()
            .then(() => {
                return drivesGeneratorInstance.initialize(this.selectedDriveIds);
            })
            .then(() => {
                const DRIVES_PER_CHUNK = 5;
                const updatedDrives = drivesGeneratorInstance.proposeDriveShifts();
                const driveSvc = new driveService();
                const promises = chunk(updatedDrives, DRIVES_PER_CHUNK).map(drives => {
                    return () => {
                        this.updateProgressBar({
                            message: 'Updating...',
                            processedRecords: this.progressBarData.processedRecords + drives.length
                        });
                        return driveSvc.saveList(drives);
                    }
                });
            
                if (!promises.length) {
                    return Promise.resolve();
                }
                return serial(promises)
            })
            .then(() => {
                let fixedSiteProcedureProjectionSvc = new fixedSiteProcedureProjectionService();
                return fixedSiteProcedureProjectionSvc.saveList(this.fixedSiteProcedureProjections.map(fixedSiteProcedureProjection => {
                    fixedSiteProcedureProjection.impactDrives = false;

                    return {
                        id: fixedSiteProcedureProjection.id,
                        impactDrives: fixedSiteProcedureProjection.impactDrives
                    }
                }))
            })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Drives are updated successfully!',
                        variant: 'success'
                    })
                );
                this.handleCancel();
            })
            .catch(error => {
                console.log(error);
                if(error && error.message) {
                    this.dispatchEvent(new ShowToastEvent({
                        message: error.message,
                        variant: 'error',
                        mode: 'dismissable'
                    }));
                }
            })
            .finally(() => {
                this.hideProgressBar();
            });
    }
}