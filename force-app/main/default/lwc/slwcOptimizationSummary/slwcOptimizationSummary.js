import TIME_ZONE from '@salesforce/i18n/timeZone';
import {
    LightningElement,
    track,
    api,
    wire
} from 'lwc';
import {
    loadStyle
} from 'lightning/platformResourceLoader';
import {
    CurrentPageReference
} from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from "c/pubsub";
import * as autoMapper from 'c/autoMapper';
import {
    each,
    groupBy
} from 'c/lodash';
import {
    sObjectType,
    driveService,
    optimizationQueueService,
    optimizationQueueQueryModel
} from 'c/dataService';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';

import customLWCStyle from '@salesforce/resourceUrl/skedLWCCustomStyle'

export default class SlwcOptimizationSummary extends LightningElement {
    _optimizationRun;
    @api
    get optimizationRun() {
        return this._optimizationRun;
    }
    set optimizationRun(value) {
        this._optimizationRun = value;

        if(this.initialized) {
            this.getOptimizationQueues();
        }
    }
    @api schedulingConsoleTerritoryKeys= [];
    
    @track showSpinnerCount = 0;
    @track initialized = false;
    @track gridData;
    @track optimizationQueues = [];

    @track driveSideMenuData = {
        shown: false,
        recordId: null
    }
    @track dispatchDriveModalData = {}

    pageName = 'driveCalendar:optimizationSummary';
    activeSectionMessage = '';

    @wire(CurrentPageReference) pageRef;
    get dateUtils() {
        return slwcDateUtils.getInstance({
            timezone: TIME_ZONE
        });
    }
    get showSpinner() {
        return this.showSpinnerCount > 0;
    }
    get allDrives() {
        let drives = [];
        this.optimizationQueues.forEach(optimizationQueue => {
            optimizationQueue.drives.forEach(drive => {
                drives.push(drive);
            })
        })
        return drives;
    }
    get btnDispatchDisabled() {
        return !this.allDrives || !this.allDrives.length
    }
    
    connectedCallback() {
        //init settings
        if (!this.initialized) {
        }
    }
    registerEvents = () => {
        registerListener('optimizationSummary:refresh', this.getOptimizationQueues, this);
    }
    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, customLWCStyle)
        ])
        .then(() => {

        })

        if(!this.initialized) {
            this.getOptimizationQueues();
            this.initialized = true;
        }
        this.registerEvents();

    }

    /** Custom functions **/
    showLoading = () => {
        this.showSpinnerCount++;
    }
    hideLoading = () => {
        this.showSpinnerCount--;
        if (this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        }
    }

    fillInDataForAPeriod = (data, startDate, endDate) => {
        const dateGrouped = groupBy(data, 'driveDate');
        const _startDate = this.dateUtils.dateIso2DateTime(startDate);
        const _endDate = this.dateUtils.dateIso2DateTime(endDate);
        const diff = this.dateUtils.diffDays(_startDate.date, _endDate.date);
        const result = {};
        for(let i = 0; i <= diff; i++) {
            const currentDate = DateTime.fromJSDate(_startDate.date).plus({
                days: i
            });
            const currentDateIso = this.dateUtils.date2dateIso(currentDate.toJSDate());

            result[currentDateIso] = dateGrouped[currentDateIso] || [];
        }
        return result;
    }

    getOptimizationQueues = () => {
        if (!this.optimizationRun) {
            //TODO: error handler
            return;
        }

        let optimizationQueueSvc = new optimizationQueueService();
        let optimizationQueueQuery = new optimizationQueueQueryModel();
        optimizationQueueQuery.optimizationRunIds = [this.optimizationRun.id];
        optimizationQueueQuery.subQueryIndicator = sObjectType.OPTIMIZATION_QUEUE_ITEM;

        this.showLoading();
        optimizationQueueSvc.query(optimizationQueueQuery)
        .then(result => {
            let promises = (result || []).map(optimizationQueue => {
                let driveSvc = new driveService();
                let driveIds = [];
                (optimizationQueue.optimizationQueueItems || []).forEach((item) => {
                    driveIds.push(item.driveId);
                });
    
                return driveSvc.getDrivesByIds(driveIds)
                .then(result => {
                    return {
                        ...optimizationQueue,
                        drives: result || []
                    }
                })
            })

            return Promise.all(promises);
        })
        .then(result => {
            this.optimizationQueues = result || [];

            this.optimizationQueues.forEach(optimizationQueue => {
                const dataGrouped = this.fillInDataForAPeriod(optimizationQueue.drives, optimizationQueue.startDate, optimizationQueue.endDate); 
                let arrGrouped = [];
                each(dataGrouped, (item, dateIso) => {
                    arrGrouped.push({ data: item, dateIso: dateIso });
                })
                optimizationQueue.dataGrouped = arrGrouped;
            })
            
            this.toggleExpandAll();
        })
        .catch(error => this.exceptionHandler(error, true))
        .finally(this.hideLoading);
    }

    exceptionHandler = (error, silentError = false) => {
        console.log(error);

        if (!silentError) {
        }
    }

    handleClose() {
        const closeEvent = new CustomEvent('close', {});
        this.dispatchEvent(closeEvent);
    }

    openDriveSideMenu(driveId, jobId) {
        const driveStaffingDetailsCmp = this.template.querySelector('c-slwc-drive-staffing-details');
        if(driveStaffingDetailsCmp && driveStaffingDetailsCmp.isLoading()) return;
        
        this.driveSideMenuData = {
            shown: true,
            recordId: driveId,
            jobId: jobId
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

    showDispatchDriveModal() {
        let drives = this.allDrives || [];
        this.dispatchDriveModalData = {
            isOpen: true,
            drives: drives
        };
    }

    hideDispatchDriveModal(event) {
        const result = event.detail.result;
        this.dispatchDriveModalData = {};

        if(result) {
        }
    }

    handleRoleClick(event) {
        this.openDriveSideMenu(event.detail.driveId, event.detail.jobId);
    }
}