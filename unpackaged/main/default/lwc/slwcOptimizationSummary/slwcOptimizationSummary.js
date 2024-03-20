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
    uniqBy,
    each,
    get,
    groupBy,
    orderBy,
    omit,
    uniqueId
} from 'c/lodash';
import {
    sObjectType,
    driveService,
    driveQueryModel,
    optimizationQueueService,
    optimizationQueueQueryModel
} from 'c/dataService';
import {
    classNames,
    camelize,
} from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';

import customLWCStyle from '@salesforce/resourceUrl/skedLWCCustomStyle'
const actions = [
    { label: 'View details', name: 'show_details' },
];
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
                optimizationQueue.dataGrouped = this.mapData(arrGrouped);
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

    setCss(allocation, quantity) {
        if(allocation === undefined || quantity === undefined) {
            return 'color-gray background-gray-light important'
        } else if (allocation == 0) {
            return 'color-gray background-red-light important'
        } else if (allocation == quantity) {
            return 'color-gray background-green-light important'
        } else if (allocation < quantity) {
            return 'color-gray background-yellow-light important'
        } else {
            return 'color-gray background-gray-light important'
        }
    }

    setCssDriveShift(allocation, quantity) {
        if(allocation === undefined || quantity === undefined) {
            return 'color-default-text background-gray-super-light important'
        } else if (allocation == 0) {
            return 'color-default-text background-red-super-light important'
        } else if (allocation == quantity) {
            return 'color-default-text background-green-super-light important'
        } else if (allocation < quantity) {
            return 'color-default-text background-yellow-super-light important'
        } else {
            return 'color-default-text background-gray-super-light important'
        }
    }

    generateSectionClass(item) {
        return classNames('slds-section', {
            'has-data': item.hasData,
            'slds-is-open': item.expanded
        });
    }

    mapData(arrGrouped) {
        let dataGrouped = [];
        each(arrGrouped, itemGrouped => {
            const rawData = itemGrouped.data;
            let roleList = []
            let data = []
            const res = rawData.map(drive => {
                let driveRecord = {
                    name: `${drive.name} - ${drive.ufid}`,
                    driveId: drive.id,
                    projectedRegisteredDonors:drive.projectedRegisteredDonors,
                    hasException: drive.hasException,
                    hasExceptionClass: drive.hasException ?'slds-current-color color-error show-exception':'hide-exception'
                };

                const driveShiftRecord = drive.driveShifts.map(driveShiftItem => {
                    let driveShiftItemRecord = {
                        name: driveShiftItem.name,
                        id: driveShiftItem.id,
                        driveId: drive.id,
                    };

                    (driveShiftItem.jobs || []).forEach((job) => {
                        if(!(job.resourceRole || job.assetType)) return;

                        const fieldName = camelize(job.resourceRole || job.assetType);

                        driveShiftItemRecord[fieldName + 'Class'] = this.setCssDriveShift()
                        driveShiftItemRecord["hasExceptionClass"] = 'hide-exception';

                        if (job.driveShiftId == driveShiftItem.id) {
                            driveShiftItemRecord[fieldName] = `${job.jobAllocationCount}/${job.quantity}`;
                            driveShiftItemRecord[fieldName + 'Class'] = this.setCssDriveShift(job.jobAllocationCount, job.quantity)
                            if (driveRecord[fieldName]) {
                                const numberArr = driveRecord[fieldName].split('/');
                                driveRecord[fieldName] = `${parseInt(numberArr[0]) + job.jobAllocationCount}/${parseInt(numberArr[1]) + job.quantity}`
                                driveRecord[fieldName + 'Class'] = this.setCss(parseInt(numberArr[0]) + job.jobAllocationCount, parseInt(numberArr[1]) + job.quantity)
                            } else {
                                driveRecord[fieldName] = `${job.jobAllocationCount}/${job.quantity}`
                                driveRecord[fieldName + 'Class'] = this.setCss(job.jobAllocationCount, job.quantity)
                            }
                        }

                        let roleTag = (job.jobTags || []).find(jobTag => {
                            return jobTag.tag && jobTag.tag.name === (job.resourceRole || job.assetType);
                        })
                        let rolePriority = roleTag ? roleTag.tag.priority : Number.MAX_SAFE_INTEGER;
                        
                        roleList.push({
                            priority: rolePriority,
                            role: job.resourceRole || job.assetType
                        })
                    })
                    
                    return driveShiftItemRecord
                })
                driveRecord["_children"] = driveShiftRecord
                data.push(driveRecord)
            })
            roleList = uniqBy(roleList, item => item.role);
            roleList = orderBy(roleList, ['priority', 'role'], ['asc', 'asc']);
            roleList = roleList.map(item => ({
                type: 'text',
                fieldName: camelize(item.role),
                cellAttributes: { class: { fieldName: camelize(item.role) + 'Class' }},
                label: item.role,
            }))

            roleList = [{
                type: 'text',
                fieldName: 'name',
                label: "Drive Name - Drive ID",
                wrapText: true,
                cellAttributes: { wrapText: true },
                initialWidth: 380,
            },
            {
                type: 'action',
                typeAttributes: { rowActions: actions },
                cellAttributes: {iconName: 'utility:info', class: {fieldName: 'hasExceptionClass'}},
            }, ...roleList]

            let newItem = {
                key: uniqueId(),
                dateIso: itemGrouped.dateIso,
                data: data,
                columns: roleList,
                hasData: data.length,
                expanded: false 
            };
            newItem.class = this.generateSectionClass(newItem);
            dataGrouped.push(newItem);
        })

        return dataGrouped;
    }

    handleRowAction(event) {
        console.log('handleRowAction', event);
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'show_details':
                this.openDriveSideMenu(row.driveId)
                break;
            default:
        }
    }

    toggleExpand(event) {
        const dateIso = event.currentTarget.dataset['dateIso'];
        const optimizationQueueId = event.currentTarget.dataset['optimizationQueueId'];
        let optimizationQueue = this.optimizationQueues.find(item => item.id === optimizationQueueId);
        if(!optimizationQueue) return;

        let item = optimizationQueue.dataGrouped.find(item => item.dateIso === dateIso);
        if(!item) return;

        item.expanded = !item.expanded;
        item.class = this.generateSectionClass(item);
    }

    toggleCollapseAll(event) {
        const optimizationQueueId = get(event, 'currentTarget.dataset.optimizationQueueId');
        let optimizationQueue = this.optimizationQueues.find(item => item.id === optimizationQueueId);
        let optimizationQueues = [];
        if(optimizationQueue) {
            optimizationQueues = [optimizationQueue]
        } else {
            optimizationQueues = this.optimizationQueues;
        }

        optimizationQueues.forEach(optimizationQueue => {
            optimizationQueue.dataGrouped.forEach(item => {
                item.expanded = false;
                item.class = this.generateSectionClass(item);
            })
        })
    }

    toggleExpandAll(event) {
        const optimizationQueueId = get(event, 'currentTarget.dataset.optimizationQueueId');
        let optimizationQueue = this.optimizationQueues.find(item => item.id === optimizationQueueId);
        let optimizationQueues = [];
        if(optimizationQueue) {
            optimizationQueues = [optimizationQueue]
        } else {
            optimizationQueues = this.optimizationQueues;
        }

        optimizationQueues.forEach(optimizationQueue => {
            optimizationQueue.dataGrouped.forEach(item => {
                item.expanded = true;
                item.class = this.generateSectionClass(item);
            })
        })
    }

    handleClose() {
        const closeEvent = new CustomEvent('close', {});
        this.dispatchEvent(closeEvent);
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
}