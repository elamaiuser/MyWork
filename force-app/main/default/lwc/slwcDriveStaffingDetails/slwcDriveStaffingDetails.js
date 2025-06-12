import TIME_ZONE from '@salesforce/i18n/timeZone';
import skedGoogleMapApis from '@salesforce/resourceUrl/skedGoogleMapApis';
import {
    dataService, debugLogService, driveQueryModel, driveService, driveShiftTagService, resourceService,
    exceptionService, jobAllocationService, jobQueryModel, jobService, sObjectType
} from 'c/dataService';
import {
    cloneDeep, compact, each, extend, find, groupBy, isEqual, keyBy, map, orderBy, remove, some, uniqBy, uniqueId, uniqWith, isString
} from 'c/lodash';
import {
    DateTime
} from 'c/luxon';
import {
    fireEvent, registerListener, unregisterAllListeners
} from 'c/pubsub';
import * as slwcAvailator from 'c/slwcAvailator';
import { ASSET_TYPE, DRIVE_STATUS, RESOURCE_ROLE, JOB_ALLOCATION_STATUS, JOB_STATUS, MANUALLY_CREATED_FROM, RESOURCE_ROLE_GROUP, RESOURCE_TYPE } from 'c/slwcConstants';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DriveHelper } from 'c/slwcDriveGenerator';
import * as slwcUtils from 'c/slwcUtils';
import {
    classNames
} from 'c/slwcUtils';
import {
    CurrentPageReference
} from 'lightning/navigation';
import {
    loadScript
} from 'lightning/platformResourceLoader';
import {
    ShowToastEvent
} from 'lightning/platformShowToastEvent';
import {
    api, LightningElement,
    track, wire
} from 'lwc';

const TABS = {
    DETAILS: 'details',
    STAFFING: 'staffing',
    EXCEPTIONS: 'exception'
}
const LIST_PINNED = {
    RECOMMENDATED: "recommendated",
    ALTERNATIVE: "alternative"
}
const TYPE_RESOURCE = {
    RESOURCE: "Person",
    VEHICLE: "Vehicle",
    EQUIPMENT: "Equipment"
}
const ICON_DEFAULT = {
    EQUIPMENT:  'custom:custom19',
    PERSON: 'standard:user'
}
const VEHICLE_ICON_DEFAULT = {
    BUS: 'custom:custom36',
    SCU: 'custom:custom31'
}
const POPOVER_EVENT = {
    HIDE_ALL: 'popover:hideAll'
}
const COLUMNS = [{
        label: 'Exception',
        fieldName: 'exception',
        initialWidth: 120
    },
    {
        label: 'Job #',
        fieldName: 'job',
        initialWidth: 70
    },
    {
        label: 'Resource',
        fieldName: 'resource'
    },
];
const MODE = {
    LOCAL: 'local',
    SERVER: 'server'
};

export default class SlwcDriveStaffingDetails extends LightningElement {
    driveHelper = new DriveHelper();

    @wire(CurrentPageReference) pageRef;

    @api isOpen = false;
    @api mode = MODE.SERVER;
    @api drive;
    @api readOnly = false;
    @api disableTransfer = false;
    @api disableCreateJob = false;
    @api disableEditJob = false;
    @api allocateAssetsOnly = false;
    @api schedulingConsoleTerritoryKeys = [];

    _recordId = null;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (this.initialized) {
            this.init();
        }
    }

    _jobId;
    @api
    get jobId() {
        return this._jobId;
    }

    set jobId(value) {
        this._jobId = value;
        if (this.initialized) {
            this.onClickUnpin();   

            if (value) {
                this.preSelectJob(value);
            }
        }
    }

    @api
    get driveId() {
        return this.recordId;
    }

    _optimizationQueue;
    @api
    get optimizationQueue() {
        return this._optimizationQueue;
    }
    set optimizationQueue(value) {
        this._optimizationQueue = value;

        if (this.initialized) {}
    }

    @api isLoading() {
        return this.showSpinner;
    }

    @track listDrive = [];
    @track isPinned = false;
    @track initialized = false;
    @track showSpinnerCount = 0;

    @track driveId2 = null;
    @track driveDetail1;
    @track driveDetail2;
    get nameDrive1() {
        return this.driveDetail1 ? this.driveDetail1.name : null;
    }
    get nameDrive2() {
        return this.driveDetail2 ? this.driveDetail2.name : null;
    }
    get driveSite1() {
        return this.driveDetail1 ? this.driveDetail1.driveSite : null;
    }
    get driveSite2() {
        return this.driveDetail2 ? this.driveDetail2.driveSite: null;
    }

    @track activeTab = TABS.DETAILS;
    @track timezoneSidId;
    @track dragSrcEl = null;
    @track resources = [];
    @track resourceRoleGroups = [];
    @track drivingRoleGroup = [];
    @track resourcesFilterList = [];
    @track resourceTagsOption = []
    @track columns = COLUMNS;
    @track dataException = []
    @track jobIdPin = null;
    @track availator1 = null;
    @track availator2 = null;
    @track resourceFilters = null;
    @track resourceSort = null;
    @track currentJobItemEl = null;
    @track currenResourceItemEl = null;
    @track dragEnterCounter = 0;
    @track listPossibleAllocations = [];
    @track listResourceAvailable = [];
    @track listResourceUnavailable = [];
    @track radioPinValue = LIST_PINNED.RECOMMENDATED
    @track radioTypeValue = TYPE_RESOURCE.RESOURCE
    @track isTransfer = false;

    @track dispatchDriveModalData = {};
    @track callOutModalData = {};
    @track addRoleModalData = {};
    @track jobAllocationModalData = {};
    @track confirmModalData = {};

    linkedDriveResourceMap = {};
    
    get dateUtils() {
        return slwcDateUtils.getInstance({
          timezone: TIME_ZONE
        });
    }

    get TABS() {
        return TABS;
    }

    get customStyle() {
        return {
            sideMenu: classNames('drive-details-side-menu', {
                'is-open': this.isOpen
            }),
            detailsTabLink: classNames('slds-tabs_default__item slds-text-title_caps', {
                'slds-is-active': this.showDetailsTab
            }),
            staffingTabLink: classNames('slds-tabs_default__item slds-text-title_caps', {
                'slds-is-active': this.showStaffingTab
            }),
            exceptionsTabLink: classNames('slds-tabs_default__item slds-text-title_caps', {
                'slds-is-active': this.showExceptionsTab
            })
        }
    }
    
    get isFixedSiteDrive() {
        return this.driveHelper.isFixedSiteDrive(this.driveDetail1);
    }

    get showDetailsTab() {
        return this.activeTab === TABS.DETAILS;
    }

    get showStaffingTab() {
        return this.activeTab === TABS.STAFFING;
    }
    get showDetailsTabClass() {
        return classNames('tab-content', {
            "hide-tab": this.activeTab != TABS.DETAILS,
        })
    }

    get showStaffingTabClass() {
        return classNames('tab-content', {
            "hide-tab": this.activeTab != TABS.STAFFING,
        })
    }

    get listDriveOption() {
        return this.listDrive.filter(item => item.value != this.recordId).map(item => ({
            ...item, 
            selected: this.driveId2 && (item.value == this.driveId2)
        }))
    }
    get showExceptionsTab() {
        return this.activeTab === TABS.EXCEPTIONS;
    }
    get showExceptionsTabClass() {
        return classNames('tab-content', {
            "hide-tab": this.activeTab != TABS.EXCEPTIONS,
        })
    }
    get filterListOptions() {
        return [{
                label: 'Recommended',
                value: LIST_PINNED.RECOMMENDATED
            },
            {
                label: 'Alternative',
                value: LIST_PINNED.ALTERNATIVE
            },
        ];
    }
    get typeOptions() {
        return this.allocateAssetsOnly ? [
            {
                label: 'Vehicle',
                value: TYPE_RESOURCE.VEHICLE
            },
            {
                label: 'Equipment',
                value: TYPE_RESOURCE.EQUIPMENT
            }
        ] : [{
                label: 'Resource',
                value: TYPE_RESOURCE.RESOURCE
            },
            {
                label: 'Vehicle',
                value: TYPE_RESOURCE.VEHICLE
            },
            {
                label: 'Equipment',
                value: TYPE_RESOURCE.EQUIPMENT
            }
        ];
    }

    get showSpinner() {
        return this.showSpinnerCount > 0;
    }
    get isRecommendations() {
        return this.radioPinValue == LIST_PINNED.RECOMMENDATED;
    }
    get showResolve() {
        return find(this.dataException,driveItem => {
            return find(driveItem.driveShifts,(dsItem => {
                return find(dsItem.jobs,(jobItem => {
                    return find(jobItem.jobAllocations,(jaItem => {
                        return jaItem.isSelected
                    }))
                }))
            }))
        })
    }
    get vehicleMode() {
        return this.radioTypeValue == TYPE_RESOURCE.RESOURCE;
    }
    get filterMode() {
        return this.isPinned ? 'PINNED_JOB' : 'ALL_JOBS'
    }

    get drive1StaffCapacity() {
        if(!this.driveDetail1 || !this.driveDetail1.staffCapacity) return 0;
        return Math.ceil(Number(this.driveDetail1.staffCapacity));
    }

    get filterVariant() {
        return this.allocateAssetsOnly ? 'DEFAULT' : 'DISTANCE_SORTABLE';
    }

    get hasUnsavedAllocations() {
        return find(this.driveDetail1.driveShifts, driveShift => {
            return find(driveShift.jobs, (driveShiftJob => {
                return find(driveShiftJob.jobAllocations, (jobAllocation => {
                    return slwcUtils.isNullOrEmpty(jobAllocation.id)
                }))
            }))
        });
    }

    renderedCallback() {
        registerListener('saveJobModal', this.handleSaveJob, this);

        registerListener('showAddRoleModal', this.handleShowAddRoleModal, this);

        registerListener('showDeleteDriveShiftTagConfirmModal', this.handleShowDeleteDriveShiftTagConfirmModal, this);
        registerListener('saveDriveShiftTagInAllocationModal', this.handleSaveDriveShiftTag, this);

        if (this.isOpen && !this.initialized) {
            this.init();
            this.initialized = true;
        }
    }
    disconnectedCallback() {
        unregisterAllListeners(this);
    }
    init() {
        // this.recordId = 'a2o8I000002Ezp3';
        // this.isOpen = true;
        // this.allocateAssetsOnly = true;
        // this.disableTransfer = true;
        // this.disableCreateJob = true;
        // this.disableEditJob = true;
        // this.mode = MODE.LOCAL;
        /* **** */

        this.mode = this.mode || MODE.SERVER;
        this.driveDetail1 = null;
        this.driveDetail2 = null;
        this.resources = [];
        this.setDefaultValues();
        
        if(this.recordId) {
            this.showLoading();
            this.handleRemoveDrive();
            this.onClickUnpin();
            return Promise.resolve()
                .then(() => {
                    if (!window.google) {
                        return loadScript(this, skedGoogleMapApis)
                            .catch((e) => {})
                    }
                })
                .then(() => {
                    return Promise.all([
                        this.retrieveCustomSettings()
                    ]);
                })
                .then(() => {
                    this.availator1 = slwcAvailator.getInstance(this.mode === MODE.LOCAL ? {
                        drive: cloneDeep(this.drive),
                        mapApis: window.google ? window.google.maps : null
                    } : {
                        driveId: this.recordId,
                        mapApis: window.google ? window.google.maps : null
                    })
    
                    return Promise.all([
                        this.getLinkedDriveResources(),
                        (this.allocateAssetsOnly && this.mode === MODE.LOCAL) ? this.availator1.fetchAssetsData() : this.availator1.fetchData()
                        
                    ])
                    .then(() => {
                        this.availator1.setupDriverJobs();
                        return this.availator1.buildScheduledAllocations()
                    })
                    .then((result) => {
                        if (result.possibleAllocations) {
                            this.listPossibleAllocations = this.buildPossibleAllocations(result.possibleAllocations);
                        }
                        if (result.drive) {
                            this.driveDetail1 = this.buildDrive(result.drive);
                            this.updateDriverJobs(this.driveDetail1);
                            this.updateDriveShiftTagExceptions(this.driveDetail1);
                        }
                        if (result.resources) {
                            this.resources = this.buildResources(result.resources);
                            this.handleFilter();
                        }
                        
                        this.resources.forEach(resource => {
                            this.validateExceptions(resource, true);
                        });
                        
                        if(!this.disableTransfer) {
                            return this.getDrivesWithJobs();
                        }

                    })
                })
                .then(() => {
                    if (this.jobId) {
                        this.preSelectJob(this.jobId);
                    }
                })
                .catch(error => this.exceptionHandler(error))
                .finally(this.hideLoading)
        }
    }

    retrieveCustomSettings() {
        let settingKeys = ["resourceRoleGroups"];
        return Promise.resolve()
        .then(() => {
            let service = new dataService();
            return service.getCustomSettings({ settingKeys: settingKeys })
            .then((result) => {
                this.resourceRoleGroups = result.returnedData.resourceRoleGroups;
                this.drivingRoleGroup = [];
                Object.keys(this.resourceRoleGroups).forEach((key) => {
                    if (key === RESOURCE_ROLE_GROUP.DRIVING_ROLES) {
                        this.drivingRoleGroup = this.resourceRoleGroups[key];
                    }
                });
            })
        });        
      }

    buildJobTagString(jobTags = []) {
        return orderBy(
            jobTags.map(item => item.tag.name),
            [item => item],
            ['asc']
        ).join(', ');
    }

    updateDriveShiftTagExceptions(drive) {
        if(!drive) return;

        (drive.driveShifts || []).forEach(driveShift => {
            driveShift.driveShiftTagExceptions = [];
            if(!driveShift || !driveShift.driveShiftTags || !driveShift.driveShiftTags.length) return;
    
            const driveShiftTags = driveShift.driveShiftTags;
            const allDriveShiftAllocations = (driveShift.jobs || []).reduce((allAllocations, job) => {
                return allAllocations.concat(this.getJobAllocations(job));
            }, []);
            const allResources = allDriveShiftAllocations.map(jobAllocation => jobAllocation.resource).filter(item => item);
            let exceptions = [];
            driveShiftTags.forEach(driveShiftTag => {
                let numberOfValidResources = 0;
                allResources.forEach(resource => {
                    const canHandleDriveShiftTag = (resource.resourceTagsDisplay || []).find(resourceTag => {
                        return resourceTag.details.find(resourceTagDetail => resourceTagDetail.id === driveShiftTag.tagId);
                    });
                    if(canHandleDriveShiftTag) {
                        numberOfValidResources++;
                    }
                })
    
                if(numberOfValidResources < driveShiftTag.minimumQuantity) {
                    exceptions.push(`Not enough ${driveShiftTag.tag.name}`);
                }
            })
            driveShift.driveShiftTagExceptions = exceptions;
        });
    }

    updateDriverJobs(drive) {
        if(!drive || !drive.driveShifts || !drive.driveShifts.length) return;
        if(this.allocateAssetsOnly) return;
        
        let {
            noOfDotVehicles,
            noOfCdlVehicles
        } = this.getNumberOfDotAndCdlDrivers(drive);

        drive.driveShifts.forEach(driveShift => {
            let driverJob = driveShift.jobs.find(job => this.driveHelper.isDriverJob(job, true));
            if(!driverJob) {
                driverJob = driveShift.jobs.find(job => this.driveHelper.isDriverJob(job, false));
            };
            if(!driverJob) return;

            let dotDriverJob = driveShift.jobs.find(job => job.id.startsWith('driverdot'));
            let cdlDriverJob = driveShift.jobs.find(job => job.id.startsWith('drivercdl'));
            let leftOverJobAllocations = [];
            driverJob.quantity = driverJob.originalQuantity || 0;
            
            if(noOfDotVehicles > 0) {
                driverJob.quantity = driverJob.quantity - noOfDotVehicles;
                Object.assign(dotDriverJob, {
                    start: driverJob.start,
                    finish: driverJob.finish,
                    startJS: driverJob.startJS,
                    finishJS: driverJob.finishJS,
                    startDate: driverJob.startDate,
                    startTime: driverJob.startTime,
                    endDate: driverJob.endDate,
                    endTime: driverJob.endTime,
                    quantity: noOfDotVehicles,
                    isShown: !!driverJob.isShown
                })
            } else {
                dotDriverJob.quantity = null;
                dotDriverJob.isShown = false;
                leftOverJobAllocations = leftOverJobAllocations.concat(cloneDeep(dotDriverJob.jobAllocations || []));
                dotDriverJob.jobAllocations = [];
            }

            if(noOfCdlVehicles > 0) {
                driverJob.quantity = driverJob.quantity - noOfCdlVehicles;
                Object.assign(cdlDriverJob, {
                    start: driverJob.start,
                    finish: driverJob.finish,
                    startJS: driverJob.startJS,
                    finishJS: driverJob.finishJS,
                    startDate: driverJob.startDate,
                    startTime: driverJob.startTime,
                    endDate: driverJob.endDate,
                    endTime: driverJob.endTime,
                    quantity: noOfCdlVehicles,
                    isShown: !!driverJob.isShown
                });
            } else {
                cdlDriverJob.quantity = null;
                cdlDriverJob.isShown = false;
                leftOverJobAllocations = leftOverJobAllocations.concat(cloneDeep(cdlDriverJob.jobAllocations || []));
                cdlDriverJob.jobAllocations = [];
            }

            if(driverJob.quantity < 0) {
                driverJob.quantity = 0;
            }

            if(leftOverJobAllocations.length) {
                leftOverJobAllocations.forEach(jobAllocation => {
                    jobAllocation.CDL = false;
                    jobAllocation.DOT = false;
                    jobAllocation.jobId = driverJob.id;
                    driverJob.jobAllocations.push(jobAllocation);
                })
            }

            this.sumUpJobData(dotDriverJob);
            this.sumUpJobData(cdlDriverJob);
            this.sumUpJobData(driverJob);
        })
    }

    getNumberOfDotAndCdlDrivers(drive, includeDeletedJobAllocations = false) {
        let result = {
            noOfDotVehicles: 0,
            noOfCdlVehicles: 0
        }
        if(!drive || !drive.driveShifts || !drive.driveShifts.length) return result;

        const vehicleJob = drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.VEHICLE);
        if(!vehicleJob) return result;
        
        let jobAllocations = includeDeletedJobAllocations ? vehicleJob.jobAllocations : this.getJobAllocations(vehicleJob);
        jobAllocations.forEach((jobAllocation) => {
            if (jobAllocation.resource.DOT) {
                result.noOfDotVehicles += 1;
            }
            else if (jobAllocation.resource.CDL) {
                result.noOfCdlVehicles += 1;
            }
        });

        return result;
    }

    handleShowDeleteDriveShiftTagConfirmModal(detail) {
        let { driveShift, driveShiftTag } = detail
           
        this.confirmModalData = {
            isOpen: true,
            title: "Delete Drive Shift Tag",
            message: "Are you sure you want to delete this tag?",
            onClose: (confirm) => {
                if(confirm) {
                    this.showLoading();
                    this.deleteDriveShiftTag(driveShiftTag)
                    .then(() => {
                        let [result, indexDriveShift, drive] = this.getDriveShiftById(driveShift.id);
                        remove(result.driveShiftTags, item => item.key === driveShiftTag.key);
                        result.driveShiftTags = [...result.driveShiftTags];

                        this.updateDriveShiftTagExceptions(drive);
                    })
                    .catch(error => this.exceptionHandler(error))
                    .finally(() => this.hideLoading());
                }

                this.handleCloseConfirmModal();
            },
            detail: detail
        } 
    }

    handleCloseConfirmModal(){
        this.confirmModalData = {};
    }

    handleSaveDriveShiftTag(detail) {
        let { driveShift, driveShiftTag } = detail
        let [result, indexDriveShift, drive] = this.getDriveShiftById(driveShift.id);

        this.showLoading();
        this.saveDriveShiftTag(driveShiftTag)
        .then((id) => {
            driveShiftTag.id = id;

            let found = result.driveShiftTags.find(item => item.key === driveShiftTag.key);
            if(found) {
               found = extend(found, driveShiftTag);
            } else {
                result.driveShiftTags.push(driveShiftTag)
            }

            result.driveShiftTags = [...result.driveShiftTags];

            this.updateDriveShiftTagExceptions(drive);
        })
        .catch(error => this.exceptionHandler(error))
        .finally(() => {
            this.hideLoading();
        });
    }
    handleSaveJob(detail) {
        let [driveShift, indexDriveShift] = this.getDriveShiftById(detail.shiftId)
        let job = detail.job;
        let jobNew = this.driveHelper.applyRoleTimeDataToJob({
            ...job,
            start: this.driveHelper.newDateTime(driveShift.driveDate, driveShift.startTime, this.timezoneSidId),
            finish: this.driveHelper.newDateTime(driveShift.driveDate, driveShift.endTime, this.timezoneSidId),
        }, job, {
            lunchBreak: driveShift.lunchBreak,
            lunchBreakBeforeDrawHours: driveShift.lunchBreakBeforeDrawHours,
            lunchBreakDuration: driveShift.lunchBreakDuration
        });

        if(detail.action == 'create') {
            jobNew = {
                ...jobNew,
                jobTagsStr: this.buildJobTagString(job.jobTags || []),
                start: jobNew.start.toISOString(),
                finish: jobNew.finish.toISOString(),
                jobAllocations: [],
                jobAllocationCount: 0,
                totalAllocatedVehiclesCapacity: 0,
                willAllocations: Array.from(Array(job.quantity || 0), (item, index) => ({
                    key: 'willAllocations' + index + 'job' + job.key
                })),
                classQuantity: classNames(
                    "slds-text-color_inverse-weak"
                )
            }
            driveShift.jobs.push(jobNew)
        }

        if (job.start !== jobNew.start || job.finish !== jobNew.finish) {
            jobNew.jobAllocations = (jobNew.jobAllocations || []).map(jobAllocation => {
                const { start, end } =  this.getDefaultJobAllocationTimes({
                    ...jobAllocation,
                    start: jobNew.start,
                    end: jobNew.finish,
                    jobNew
                });
                return {
                    ...jobAllocation,
                    start: start,
                    end: end,
                    duration: DateTime.fromISO(end, {
                        zone: this.timezoneSidId
                    }).diff(DateTime.fromISO(start, {
                        zone: this.timezoneSidId
                    })).as('minutes')
                }
            });
        }

        this.showLoading();
        this.saveJob(jobNew)
        .then((id) => {
            let service = new jobService();
            let queryModel = new jobQueryModel();
            queryModel.subQueryIndicator = sObjectType.JOB_TAG | sObjectType.JOB_ALLOCATION;
            queryModel.recordIds = [id];
            return service.query(queryModel)
        })
        .then(([job]) => {
            (job.jobAllocations || []).forEach(item => {
                item.resource = this.resources.find(resource => resource.id === item.resourceId) || item.resource;
            })

            if(indexDriveShift <= this.driveDetail1.driveShifts.length){
                this.availator1.updateData(job, indexDriveShift);
                return this.availator1.buildScheduledAllocations()
                .then((result) => {
                    if (result.possibleAllocations) {
                        this.listPossibleAllocations = this.buildPossibleAllocations(result.possibleAllocations);
                    }
                    if (result.drive) {
                        this.driveDetail1 = this.buildDrive(result.drive);
                        this.updateDriverJobs(this.driveDetail1);
                        this.updateDriveShiftTagExceptions(this.driveDetail1);

                        this.resources.forEach(resource => {
                            this.validateExceptions(resource, true);
                        });
                    }

                    this.updateStyleResource();
                })
            } else {
                this.availator2.updateData(job, indexDriveShift - this.driveDetail1.driveShifts.length);
                return this.availator2.buildScheduledAllocations()
                .then((result) => {
                    if (result.possibleAllocations) {
                        this.listPossibleAllocations = this.buildPossibleAllocations(result.possibleAllocations);
                    }
                    if (result.drive) {
                        this.driveDetail2 = this.buildDrive(result.drive);
                        this.updateDriverJobs(this.driveDetail2);
                        this.updateDriveShiftTagExceptions(this.driveDetail2);

                        this.resources.forEach(resource => {
                            this.validateExceptions(resource, true);
                        });
                    }

                    this.updateStyleResource();
                });
            }
        })
        .catch(error => this.exceptionHandler(error))
        .finally(() => {
            this.hideLoading();
            this.onClickUnpin();
        });
    }
    cancelJob(event) {
        const jobId = event.currentTarget.dataset.id;
        let job = null;
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        each([...driveShifts, ...driveShifts2], item => {
            const jobItem = item.jobs.filter(itemSub => {
                return itemSub.id == jobId
            });
            if (jobItem.length > 0) {
                job = jobItem[0]
            }
        })

        this.showConfirmModal({
            title: 'Confirm Cancel Job',
            message: 'Are you sure you want to cancel this job?',
            onClose: (result) => {
                this.hideConfirmModal();
                if (result) {
                    let service = new jobService();

                    this.showLoading();
                    return service.save({
                        id: job.id,
                        jobStatus: JOB_STATUS.CANCELLED
                    }).then(result => {
                        if(result.success) {
                            const event = new ShowToastEvent({
                                message: 'Job was cancelled successfully.',
                                variant: 'success',
                                mode: 'dismissable'
                            });
                            this.dispatchEvent(event);

                            job.jobStatus = JOB_STATUS.CANCELLED;
                            job.isShown = false;
                        } else {
                            throw result;
                        }
                    })
                    .catch(error => this.exceptionHandler(error))
                    .finally(() => this.hideLoading());
                }
            }
        });
    }
    editJob(event) {
        const jobId = event.currentTarget.dataset.id;
        let [ job, driveShift, jobIndex, drive ] = this.getJobById(jobId);

        let quantity = job.quantity;
        if(job.resourceRole === RESOURCE_ROLE.DRIVER) {
            let {
                noOfDotVehicles,
                noOfCdlVehicles
            } = this.getNumberOfDotAndCdlDrivers(drive, false);
            
            quantity = (job.quantity || 0) + noOfDotVehicles + noOfCdlVehicles;
        }

        let eventValues = {
            action: "edit",
            type: "allocationModal",
            enableAddress: true,
            resourceType: job.resourceRole ? TYPE_RESOURCE.RESOURCE: TYPE_RESOURCE.VEHICLE, 
            driveShift: driveShift,
            drive: drive,
            job: {
                ...job,
                quantity: quantity
            }
        };
        fireEvent(this.pageRef, 'showJobModal', eventValues);
    }
    createJob(event) {
        const shiftId = event.currentTarget.dataset['shiftId'];
        const driveId = event.currentTarget.dataset['driveId'];

        let drive = this.driveDetail1;
        if(driveId !== drive.id) {
            drive = this.driveDetail2
        }
        const [driveShift] = this.getDriveShiftById(shiftId);

        let eventValues = {
            action: "create",
            type: "allocationModal",
            enableAddress: true,
            driveShift: driveShift,
            drive: drive,
            resourceType: TYPE_RESOURCE.RESOURCE,
            job: null
        };

        if (this.hasUnsavedAllocations) {
            this.showConfirmModal({
                title: 'Drive Shift has Unsaved Allocations',
                message: 'Creating a job will cause unsaved allocations to be discarded. Do you wish to continue?',
                onClose: (result) => {
                    this.hideConfirmModal();
                    if (result) {
                        fireEvent(this.pageRef, 'showJobModal', eventValues);
                    }
            }});            
        } else {
            fireEvent(this.pageRef, 'showJobModal', eventValues);
        }
    }
    handleDragStart(e) {
        let resourceItemEl = null
        fireEvent(this.pageRef, 'popover:event', {
            event: POPOVER_EVENT.HIDE_ALL
        });
        for (var element = e.target; element; element = element.parentNode) {
            if (element.classList && element.classList.contains('resource-drap')) {
                resourceItemEl = element;
                break;
            }
        }
        // console.log("handleDragStart",resourceItemEl,e);
        e.dataTransfer.effectAllowed = 'move';
        const resourceId = e.currentTarget.dataset['id'];
        const resourceDetail = this.getResourceById(resourceId);
        e.dataTransfer.setData('resourceId', resourceId);
        this.dragSrcEl = e.target;

        const listjobEl = this.template.querySelectorAll('.job-item');
        listjobEl.forEach(el => {
            const clonedDriveDetails1 = this.cloneDrive(this.driveDetail1);
            const clonedDriveDetails2 = this.cloneDrive(this.driveDetail2);
            
            const jobId = el.dataset.id;
            const [jobDetail, driveShift] = this.getJobById(jobId);

            this.validateExceptions({
                resourceId: resourceId,
                resource: resourceDetail,
                job: jobDetail,
                jobId: jobId
            }, false, clonedDriveDetails1, clonedDriveDetails2);
        });
      
        const listJobAvailable = this.getListJobAvailable(resourceId);
        const listJobUnavailable = this.getListJobUnavailable(resourceId);
        listjobEl.forEach(el => {
            const jobId = el.dataset.id
            const [jobDetail, driveShift] = this.getJobById(jobId);
            if((resourceDetail.resourceType == TYPE_RESOURCE.RESOURCE && jobDetail.resourceRole) || (resourceDetail.assetType && resourceDetail.assetType == jobDetail.assetType)){
                const isResourceAllocated = this.isResourceAllocatedToDriveShift(resourceDetail, driveShift);
                if (
                    !isResourceAllocated && listJobAvailable.includes(jobId) && !el.classList.contains('job-disabled') && !el.classList.contains('job-hover-disabled')) {
                    el.classList.add('hco-job-droppable_hover');
                } else if (
                    !isResourceAllocated && listJobUnavailable.includes(jobId) && !el.classList.contains('job-disabled') && !el.classList.contains('job-hover-disabled')) {
                    el.classList.add('hco-job-droppable-warning_hover');
                }
            } else {
                el.classList.add('job-hover-disabled');
            }
        })
    }

    handleDragOver(e) {
        let jobItemEl = null
        for (var element = e.target; element; element = element.parentNode) {
            if (element.classList && element.classList.contains('job-item')) {
                jobItemEl = element;
                break;
            }
        }
        if (jobItemEl.classList.contains('hco-job-droppable_hover')) {
            jobItemEl.classList.add('job-hover');
        }
        if (jobItemEl.classList.contains('hco-job-droppable-warning_hover')) {
            jobItemEl.classList.add('job-hover_warning');
        }
        // console.log("handleDragOver",jobItemEl);
        if (e.preventDefault) {
            e.preventDefault();
        }
        e.dataTransfer.dropEffect = 'move';
        return false;
    }

    handleDragLeave(e) {
        let jobItemEl = null
        for (var element = e.target; element; element = element.parentNode) {
            if (element.classList && element.classList.contains('job-item')) {
                jobItemEl = element;
                break;
            }
        }
        jobItemEl.classList.remove('job-hover');
        jobItemEl.classList.remove('job-hover_warning');
        // console.log("handleDragLeave",jobItemEl);
        e.preventDefault();
        e.stopPropagation();
        this.dragEnterCounter--;

        if (this.dragEnterCounter === 0 && this.currentJobItemEl) {
            this.currentJobItemEl.classList.remove('hco-job-droppable_hover');
            this.currentJobItemEl.classList.remove('hco-job-droppable-warning_hover');
            this.currentJobItemEl.classList.remove('job-hover_warning');
            this.currentJobItemEl.classList.remove('job-hover');
            this.currentJobItemEl = null;
        }
        return false;
    }

    handleDrop(e) {
        if(!this.dragSrcEl) return;
        
        let jobItemEl = null;
        // console.log("handleDrop",e.dataTransfer.getData('resourceId'), e.target);
        this.dragSrcEl.style.opacity = 1;
        for (var element = e.target; element; element = element.parentNode) {
            if (element.classList && element.classList.contains('job-item')) {
                jobItemEl = element;
                break;
            }
        }
        const {id} = jobItemEl && jobItemEl.dataset;
        if (id && !jobItemEl.classList.contains('job-disabled') && !jobItemEl.classList.contains('job-hover-disabled') && (jobItemEl.classList.contains('job-hover_warning') || jobItemEl.classList.contains('job-hover'))) {
            // this.dragSrcEl.style.background = '#D8EDFF';
            this.allocate(e.dataTransfer.getData('resourceId'), id)
        }
        return false;
    }

    handleDragEnd(e) {
        // console.log("handleDragEnd",e.target,this.currentJobItemEl);
        const listjobEl = this.template.querySelectorAll('.job-item');
        listjobEl.forEach(el => {
            el.classList.remove('hco-job-droppable_hover');
            el.classList.remove('hco-job-droppable-warning_hover');
            el.classList.remove('job-hover_warning');
            el.classList.remove('job-hover');
            el.classList.remove('job-hover-disabled');
        })
        if (this.currentJobItemEl) {
            this.dragEnterCounter = 0
            this.currentJobItemEl.classList.remove('hco-job-droppable_hover');
            this.currentJobItemEl.classList.remove('hco-job-droppable-warning_hover');
            this.currentJobItemEl.classList.remove('job-hover_warning');
            this.currentJobItemEl.classList.remove('job-hover');
            this.currentJobItemEl.classList.remove('job-hover-disabled');
            this.currentJobItemEl = null;
        }
    }

    handleResourceAction(event) {
        const action = event.detail.action;
        if(action === 'unallocate') {
            if (event.detail.record.driveShiftTradeId) { 
                this.showConfirmModal({
                    title: 'Confirm Unallocate Resource',
                    message: 'The staff had traded onto this shift. Are you sure you want to unallocate?',
                    onClose: (result) => {
                        this.hideConfirmModal();
                        if (result) {
                            this.removeResource(event.detail.record);
                        }
                    }
                });
            }
            else {
                this.removeResource(event.detail.record);
            }
        } else if(action === 'lock' || action === 'guard') {
            this.handleLockAction(event.detail.record, action);
        } else if(action === 'callOut') {
            this.handleShowCallOutModal(event.detail.record);
        } else if (action === 'edit') {
            this.handleShowEditJobAllocationModal(event.detail.record);
        }
    }
    
    handleLockAction(detail, action){
        console.log("handleLockAction");
        let [ job ] = this.getJobById(detail.jobId);
        let ja =  find(job.jobAllocations, item => item.key == detail.key);
        if (action === 'lock') {
            ja.locked = !ja.locked;
        } else if (action === 'guard') {
            ja.guarded = !ja.guarded;
        }
        ja.isLocked = ja.locked || ja.guarded;
    }
    
    removeResource(event) {
        const resourceId = event.resourceId;
        const jobId = event.jobId;
        let [ job, driveShift, jobIndex, drive ] = this.getJobById(jobId);
        let jobAllocations = job.jobAllocations || [];
        const jobAllocation = jobAllocations.find(item => item.resourceId == resourceId && item.status !== JOB_ALLOCATION_STATUS.DELETED)
        if(jobAllocation.id) {
            jobAllocation.status = JOB_ALLOCATION_STATUS.DELETED;
            jobAllocation.isDeleted = true;
        } else {
            remove(jobAllocations, item => item.resourceId == resourceId);
        }

        this.populateDefaultJobAllocationTimes(drive, {
            id: resourceId
        });
        this.sumUpJobData(job);
        this.updateStyleResource();
        this.buildException();
        this.updateDriveShiftTagExceptions(drive);
        if(job.assetType === ASSET_TYPE.VEHICLE) {
            this.updateDriverJobs(drive);
        }
        this.validateExceptions({
            ...jobAllocation,
            status: JOB_ALLOCATION_STATUS.DELETED
        }, true);
    }

    getResourceStyle(resource, resourceAllocated = [], resourceAllocated2 = []) {
        const allocatedToDrive1 = resourceAllocated.find(item => item.resourceId === resource.id);
        const allocatedToDrive2 = this.driveId2 ? resourceAllocated2.find(item => item.resourceId === resource.id) : null;
        const allocatedToPinnedJob = this.isPinned && (
            allocatedToDrive1 && allocatedToDrive1.jobId === this.jobIdPin || 
            allocatedToDrive2 && allocatedToDrive2.jobId === this.jobIdPin
        );
        const backgroundColor = allocatedToPinnedJob ? '#b5dcfe' : '#D8EDFF';
        const style = (
            allocatedToDrive1 || allocatedToDrive2
        ) ? `background: ${backgroundColor}` : '';
        return {
            style,
            draggable: true, //!(resourceAllocated.includes(resource.id) && ((this.driveId2 == null) || resourceAllocated2.includes(resource.id))),
        }
    }

    updateStyleResource() {
        const resourceAllocated = this.getListResourceAllocated(this.driveDetail1 ? this.driveDetail1.driveShifts: []);
        const resourceAllocated2 = this.getListResourceAllocated(this.driveDetail2 ? this.driveDetail2.driveShifts: []);

        this.resources = this.resources.map(item => {
            const { style, draggable } = this.getResourceStyle(item, resourceAllocated, resourceAllocated2)

            return {
                ...item,
                style: style,
                draggable: draggable
            }
        });
        this.handleFilter();
    }

    getResourceIcon(resource) {
        if(!resource) return;
        if(resource.assetType === TYPE_RESOURCE.VEHICLE) {
            return VEHICLE_ICON_DEFAULT[(resource.category || '').toUpperCase()] || VEHICLE_ICON_DEFAULT.SCU;
        } else {
            return resource.assetType && ICON_DEFAULT[resource.assetType.toUpperCase()] || ICON_DEFAULT[TYPE_RESOURCE.RESOURCE.toUpperCase()]
        }
    }

    getJobAllocations(job) {
        if(!job || !job.jobAllocations) return [];
        return job.jobAllocations.filter(jobAllocation => jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED);
    }

    sumUpJobData(job) {
        if(!job.jobAllocations) {
            job.jobAllocations = [];
        }
        const jobQuantity = job.quantity || 0;
        const jobAllocations = this.getJobAllocations(job);
        job.jobAllocationCount = jobAllocations.length;
        job.totalAllocatedVehiclesCapacity = 0;

        if(job.assetType === TYPE_RESOURCE.VEHICLE) {
            (jobAllocations || []).forEach(ja => {
                job.totalAllocatedVehiclesCapacity = job.totalAllocatedVehiclesCapacity + Number((ja.resource || {}).presDonorCapacity || 0);
            })
        }
        job.willAllocations = (job.quantity > jobAllocations.length) && Array.from(Array(jobQuantity - jobAllocations.length), (item, index) => ({
            key: 'willAllocations' + index + 'job' + job.key
        })) || [];
        job.classQuantity = classNames({
            "slds-text-color_inverse-weak": jobAllocations.length <= jobQuantity,
            "color-error": jobAllocations.length > job.quantity
        });
    }

    allocate(resourceId, jobId) {
        let [job, driveShift, jobIndex, drive] = this.getJobById(jobId);
        const resource = this.getResourceById(resourceId);
        const posAl = this.listPossibleAllocations.find(itemEx => itemEx.resourceId == resourceId && itemEx.jobId == jobId) || null;
        let exceptionLog = [];
        if(posAl && !posAl.isAvailable && posAl.exceptionLog) {
            exceptionLog = posAl.exceptionLog || []
        }
        if(!job.jobAllocations) {
            job.jobAllocations = [];
        }
        const jobAllocations = job.jobAllocations || [];
        let newJobAllocation = null;
        let existingJobAllocation = find(jobAllocations, item => item.resourceId == resourceId)
        const { start, end } =  this.getDefaultJobAllocationTimes({
            start: job.start,
            end: job.finish,
            travelTimeTo: posAl?.estimatedTravelTimeTo,
            travelTimeBack: posAl?.estimatedTravelTimeBack,
            isRelocatedResource: posAl?.isTemporaryCO || false,
            job
        });
        if(!existingJobAllocation) {
            newJobAllocation = {
                jobId,
                resourceId,
                key: resourceId,
                resource,
                start: start,
                end: end,
                icon: this.getResourceIcon(resource),
                exceptionLog: exceptionLog,
                travelTimeTo: posAl?.estimatedTravelTimeTo,
                travelTimeBack: posAl?.estimatedTravelTimeBack,
                geoServiceTravelTimeTo: posAl?.estimatedTravelData?.travelTimeTo,
                geoServiceTravelTimeBack: posAl?.estimatedTravelData?.travelTimeBack,
                geoServiceTravelDistanceTo: posAl?.estimatedTravelData?.travelDistanceTo,
                geoServiceTravelDistanceBack: posAl?.estimatedTravelData?.travelDistanceBack,
                isRelocatedResource: posAl?.isTemporaryCO || false,
                DOT: false,
                CDL: false,
                additionalRoles: job.dualRole ? [job.dualRole] : [],
                additionalRolesString: job.dualRole
            };
            job.jobAllocations.push(newJobAllocation);
        } else {
            if(existingJobAllocation.status === JOB_ALLOCATION_STATUS.DELETED) {
                existingJobAllocation = extend(existingJobAllocation, {
                    start: start,
                    end: end,
                    exceptionLog: exceptionLog,
                    travelTimeTo: posAl?.estimatedTravelTimeTo,
                    travelTimeBack: posAl?.estimatedTravelTimeBack,
                    isRelocatedResource: posAl?.isTemporaryCO || false,
                    geoServiceTravelTimeTo: posAl?.estimatedTravelData?.travelTimeTo,
                    geoServiceTravelTimeBack: posAl?.estimatedTravelData?.travelTimeBack,
                    geoServiceTravelDistanceTo: posAl?.estimatedTravelData?.travelDistanceTo,
                    geoServiceTravelDistanceBack: posAl?.estimatedTravelData?.travelDistanceBack,
                    DOT: false,
                    CDL: false
                })
                delete existingJobAllocation.status;
                delete existingJobAllocation.isDeleted;

                newJobAllocation = existingJobAllocation;
            }
        }

        this.populateDefaultJobAllocationTimes(drive, resource);
        this.sumUpJobData(job);
        if(job.assetType === ASSET_TYPE.VEHICLE) {
            this.updateDriverJobs(drive);
        }
        this.updateDriveShiftTagExceptions(drive);
        this.updateStyleResource();
        this.validateExceptions(newJobAllocation, true);
    }

    validateExceptions(newJobAllocation, isAllocated = false, driveDetail1 = this.driveDetail1, driveDetail2 = this.driveDetail2) {
        if(!newJobAllocation) return;

        const isResource = !newJobAllocation.resourceId;
        const resource = isResource ? newJobAllocation : newJobAllocation.resource;
        if(resource.resourceType !== RESOURCE_TYPE.PERSON || !resource.resourceHoursRecord) return;

        if(!isResource) {
            const currentPossibleAllocation = this.listPossibleAllocations.find(item => item.resourceId === newJobAllocation.resourceId && item.jobId === newJobAllocation.jobId);
            if(!newJobAllocation.exceptionLog) {
                newJobAllocation.exceptionLog = currentPossibleAllocation ? currentPossibleAllocation.exceptionLog : [];
            }
        }
       
        const resourceMaxHoursPerWeekInMinutes = (resource.maxHoursPerWeek || 0) * 60;
        const currentWeeklyHoursInMinutes = resource.weeklyHoursInMinutes || 0;
        const resourceHoursRecord = resource.resourceHoursRecord;
        let totalMinutesOfOldAllocationsDeleted = 0;
        let totalMinutesOfNewAllocations = 0;
        let allAllocationsNeedToUpdateExceptions = [];
        
        let allDriveShifts = driveDetail1.driveShifts;
        if(this.driveId2) {
            allDriveShifts = allDriveShifts.concat(driveDetail2.driveShifts);
        }

        //try to allocate resource to temp drive
        if(!isAllocated) {
            allDriveShifts.forEach(driveShift => {
                driveShift.jobs.forEach(job => {
                    if(job.id === newJobAllocation.jobId && newJobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
                        if(!job.jobAllocations.find(jobAllocation => jobAllocation.resourceId === newJobAllocation.resourceId && jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED)) {
                            job.jobAllocations.push(newJobAllocation);
                        }
                    } 
                })
            });
        }

        if(!isResource) {
            this.populateDefaultJobAllocationTimes(driveDetail1, resource);
            this.populateDefaultJobAllocationTimes(driveDetail2, resource);    
        }
       
        allDriveShifts.forEach(driveShift => {
            driveShift.jobs.forEach(job => {
                job.jobAllocations.forEach(jobAllocation => {
                    if(jobAllocation.resourceId !== resource.id) return;
                    
                    const duration = DateTime.fromISO(jobAllocation.end || jobAllocation.job.finish, {
                        zone: this.timezoneSidId
                    }).diff(DateTime.fromISO(jobAllocation.start || jobAllocation.job.start, {
                        zone: this.timezoneSidId
                    })).as('minutes');

                    if(jobAllocation.id) {
                        if(jobAllocation.status === JOB_ALLOCATION_STATUS.DELETED) {
                            totalMinutesOfOldAllocationsDeleted += duration;
                        }
                    } else {
                        if(jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
                            totalMinutesOfNewAllocations += duration;
                        }
                    }

                    allAllocationsNeedToUpdateExceptions.push(jobAllocation);
                });
            });
        });

        const weeklyHoursInMinutes = currentWeeklyHoursInMinutes + totalMinutesOfNewAllocations - totalMinutesOfOldAllocationsDeleted;
        const allocationExceptionLogMap = {};
        if(weeklyHoursInMinutes > resourceMaxHoursPerWeekInMinutes) {
            let exceptionText = this.availator1.getExceptionTextByCode('MAXIMUM_WEEKLY_HOURS_VIOLATION')
            if(exceptionText) {
                exceptionText = exceptionText.replace('{{weekStartDate}}', DateTime.fromFormat(resourceHoursRecord.startDate, 'yyyy-MM-dd').toFormat('MM/dd/yyyy'))
            }

            allAllocationsNeedToUpdateExceptions.forEach(jobAllocation => {
                allocationExceptionLogMap[`${jobAllocation.resourceId}-${jobAllocation.jobId}`] = cloneDeep(jobAllocation.exceptionLog.filter(item => item.exceptionCode !== 'MAXIMUM_WEEKLY_HOURS_VIOLATION'));
                allocationExceptionLogMap[`${jobAllocation.resourceId}-${jobAllocation.jobId}`].push({
                    exception: exceptionText,
                    exceptionCode: 'MAXIMUM_WEEKLY_HOURS_VIOLATION',
                    key: uniqueId('exception_ja'),
                    resource: jobAllocation.resource,
                    icon: this.getResourceIcon(jobAllocation.resource),
                    isSelected:  false
                });
            });
        } else {
            allAllocationsNeedToUpdateExceptions.forEach(jobAllocation => {
                allocationExceptionLogMap[`${jobAllocation.resourceId}-${jobAllocation.jobId}`] = cloneDeep(jobAllocation.exceptionLog.filter(item => item.exceptionCode !== 'MAXIMUM_WEEKLY_HOURS_VIOLATION'));
            });
        }

        allAllocationsNeedToUpdateExceptions.forEach(jobAllocation => {
            if(isAllocated) {
                jobAllocation.exceptionLog = allocationExceptionLogMap[`${jobAllocation.resourceId}-${jobAllocation.jobId}`];
            }

            const possibleAllocation = this.listPossibleAllocations.find(possibleAllocation => possibleAllocation.resourceId === jobAllocation.resourceId && possibleAllocation.jobId === jobAllocation.jobId);
            
            //update possibleAllocation
            if(possibleAllocation) {
                const updatedExceptionLog = allocationExceptionLogMap[`${possibleAllocation.resourceId}-${possibleAllocation.jobId}`] || [];
                possibleAllocation.exceptionLog = updatedExceptionLog;
                possibleAllocation.isAvailable = possibleAllocation.isResourceAvailable && !updatedExceptionLog.length;
            }
        });
    }

    buildException() {
        const _buildExceptionData = (drive) => {
            if(!drive) return null;

            let result = {
                name: drive.name,
                id: drive.id,
                key: uniqueId('drive_'),
                driveShifts: [],
                isSelected: false
            }
            
            each(drive.driveShifts || [], itemDriveShifts => {
                let dsList = []
                each(itemDriveShifts.jobs, jobItem => {
                    let exceptionLogList = []
                    let jobAllocations = this.getJobAllocations(jobItem);

                    each(jobAllocations, jaItem => {
                        exceptionLogList = exceptionLogList.concat((jaItem.exceptionLog || []).filter(ex => ex.status != 'Resolved').map(exception => ({
                            exception: exception.exception,
                            exceptionCode: exception.exceptionCode,
                            eventURL: exception.eventURL,
                            id: exception.id,
                            key: uniqueId('exception_ja'),
                            resource: jaItem.resource,
                            icon: this.getResourceIcon(jaItem.resource),
                            isSelected:  false
                        })))
                    })
                    if(exceptionLogList.length > 0) {
                        dsList.push({
                            isSelected: false,
                            job: jobItem.resourceRole || jobItem.assetType,
                            id: jobItem.id,
                            key: uniqueId('exception_job'),
                            jobAllocations: exceptionLogList
                        })
                    }
                })
                if (dsList.length > 0) {
                    result.driveShifts.push({
                        isSelected: false,
                        driveShift: itemDriveShifts.name,
                        key: uniqueId('exception_driveShift'),
                            id: itemDriveShifts.id,
                            jobs: dsList
                    })
                }
            })
            return result;
        }

        if(this.activeTab !== TABS.EXCEPTIONS){
            return;
        }

        this.dataException = []
        const ds1 = _buildExceptionData(this.driveDetail1);
        if (ds1 && ds1.driveShifts.length > 0) {
            this.dataException.push(ds1);
        }
        
        const ds2 = _buildExceptionData(this.driveDetail2);
        if (ds2 && ds2.driveShifts.length > 0) {
            this.dataException.push(ds2);
        }
        console.log("dataException", this.dataException);
    }

    handleOnChange(event) {
        const eventName = event.target.name;
        const value = slwcUtils.getValueFromEvent(event)
        switch (eventName) {
            case "selectDrive":
                {   
                    const {index} = event.currentTarget.dataset;
                    const driveShifts = this.dataException[index].driveShifts;
                    this.dataException[index].exceptions.forEach(item => {
                        item.isSelected = value
                    })
                    this.dataException[index].driveShifts = driveShifts.map(item => ({
                        ...item,
                        isSelected: value,
                        jobs: item.jobs.map(itemPa => ({
                            ...itemPa,
                            isSelected: value,
                            jobAllocations: this.getJobAllocations(itemPa).map(itemSub => ({
                                ...itemSub,
                                isSelected: value 
                            }))
                        })) 
                    }))
                    
                }
                break;
            case "selectDriveShift":
                {
                    const {indexDrive,index} = event.currentTarget.dataset;
                    const jobs = this.dataException[indexDrive].driveShifts[index].jobs;
                    this.dataException[indexDrive].driveShifts[index].jobs = jobs.map(item => ({
                        ...item,
                        isSelected: value,
                        jobAllocations: this.getJobAllocations(item).map(itemSub => ({
                            ...itemSub,
                            isSelected: value 
                        }))
                    })) 
                }
                break;
            case "selectJob":
                {
                    const {indexDrive,indexDriveShift,index} = event.currentTarget.dataset;
                    const jobAllocations = this.getJobAllocations(this.dataException[indexDrive].driveShifts[indexDriveShift].jobs[index]);
                    this.dataException[indexDrive].driveShifts[indexDriveShift].jobs[index].jobAllocations = jobAllocations.map(item => ({
                        ...item,
                        isSelected: value 
                    })) 
                }
                break;
            case "selectException":
                {
                    const {indexDrive,indexDriveShift,indexJob,index} = event.currentTarget.dataset;
                    this.dataException[indexDrive].driveShifts[indexDriveShift].jobs[indexJob].jobAllocations[index].isSelected = value 
                }
                break;
            case "selectDriveDetail":
                {
                    const {indexDrive,indexDriveDetail} = event.currentTarget.dataset;
                    this.dataException[indexDrive].exceptions[indexDriveDetail].isSelected = value 
                }
                break;
                
            default:
                break;
        }
    }

    getDrivesWithJobs = () => {
        let service = new driveService();
        let driveQuery = new driveQueryModel();
        const firstDay = this.dateUtils.getFirstDayValue(this.driveDetail1.collectionOperation.workWeekFirstDay);
        driveQuery.territoryKeys = this.schedulingConsoleTerritoryKeys;
        driveQuery.startDate = this.dateUtils.startOfWeek(this.driveDetail1.driveDate, firstDay).toISODate();
        driveQuery.endDate = DateTime.fromISO(driveQuery.startDate).plus({
          day: 6
        }).toISODate();
        driveQuery.statuses = [DRIVE_STATUS.CONFIRMED];
        
        return service.query(driveQuery)
            .then((result) => {
                this.listDrive = result.map(item => ({
                    label: item.name,
                    value: item.id,
                    type: item.typeOfDrive,
                    driveDate: item.driveDate,
                    start: item.minShiftStart,
                    end: item.maxShiftEnd,
                    timezoneSidId: item.driveSite && item.driveSite.timezoneSidId
                }))
            })
            .catch(error => this.exceptionHandler(error))
    }

    getLinkedDriveResources() {
        let service = new jobAllocationService();
        return service.getLinkedDrivesResourceIds({
            driveId: this.recordId
        })
        .then((result) => {
            const resourceIds = (result || {}).returnedData || [];
            this.linkedDriveResourceMap = keyBy(resourceIds, item => item);
        })
    }

    exceptionHandler = (error) => {
        new debugLogService().captureDebugLog(error, this.recordId);
        this.dispatchEvent(new ShowToastEvent({
            message: error.message,
            variant: 'error',
            mode: 'dismissable',
        }));
    }

    showLoading = () => {
        this.showSpinnerCount++;
    }

    hideLoading = () => {
        this.showSpinnerCount--;
        if (this.showSpinnerCount < 0) {
            this.showSpinnerCount = 0;
        }
    }
    buildResource(item) {
        const hasLinkedDrive = this.linkedDriveResourceMap[item.id];
        const resourceAllocated = this.getListResourceAllocated(this.driveDetail1 ? this.driveDetail1.driveShifts: []);
        const resourceAllocated2 = this.getListResourceAllocated(this.driveDetail2 ? this.driveDetail2.driveShifts: []);

        (item.resourceTags || []).forEach(item => {
            item.tag && this.resourceTagsOption.push({
                value: item.tag.id,
                label: item.tag.name,
            })
        })

        let groupResourceTag;
        if(item.assetType === TYPE_RESOURCE.VEHICLE) {
            groupResourceTag = {
                'Mobile Type': (item.mobileType || []).map(item => {
                    return {
                        key: item,
                        tag: {
                            id: item,
                            name: item
                        }
                    } 
                }),
                'Certification': (item.resourceTags || []).filter(tagItem => tagItem.tag.type === 'Certification')
            }
        } else {
            groupResourceTag = groupBy(item.resourceTags, tagItem => tagItem.tag.type)
            if(!groupResourceTag['Certification']){
                groupResourceTag['Certification'] = []
            }
            if(!groupResourceTag['Role'] && !item.assetType){
                groupResourceTag['Role'] = []
            }
        }

        let resourceTagsDisplay = map(groupResourceTag, (groupItem, key) => {
            return {
                key: key,
                keyRender: uniqueId(key),
                value: groupItem.length,
                details: orderBy(groupItem.map(item => {
                    return {
                        value: item.tag && item.tag.name,
                        key: item.key + item.name,
                        id: item.tag.id,
                        isRestricted: item.tag.type === 'Role' && slwcAvailator.isResourceTagRestricted(item, {
                            startDate: this.driveDetail1?.driveDate,
                            endDate: this.driveDetail1?.driveDate
                        })
                    }
                }), ['value'], ['asc'])
            }
        })
        resourceTagsDisplay = orderBy(resourceTagsDisplay, [(resourceTag) => {
            let orderList = ['Role', 'Certification', 'Physical Location Type', 'Drive Type', 'Asset Type', 'Mobile Type'];
            return orderList.findIndex(item => item.toLowerCase() === resourceTag.key.toLowerCase())
        }], ['asc']);

        const resourceHoursRecord =  item.resourceHoursRecords && item.resourceHoursRecords.length ? item.resourceHoursRecords[0] : null;
        const weeklyHoursInMinutes = (resourceHoursRecord ? resourceHoursRecord.totalWorkingTime : null) || 0;
        const weeklyHours = +(weeklyHoursInMinutes / 60).toFixed(2);

        const { style, draggable } = this.getResourceStyle(item, resourceAllocated, resourceAllocated2)

        let travelData = null;
        let isSecondaryCO = false;
        let isTemporaryCO = false;

        const firstPossibleAllocateJobHasTravelTime = this.listPossibleAllocations.find((allocation) => (
            allocation.resourceId === item.id && allocation.travelTimeGroup
        ));

        const firstPossibleAllocateJob = this.listPossibleAllocations.find((allocation) => (
            allocation.resourceId === item.id
        ));

        if(firstPossibleAllocateJob) {
            isSecondaryCO = firstPossibleAllocateJob.isSecondaryCO;
            isTemporaryCO = firstPossibleAllocateJob.isTemporaryCO;
        }

        if(firstPossibleAllocateJobHasTravelTime && item.resourceType === TYPE_RESOURCE.RESOURCE) {
            travelData = Object.keys(firstPossibleAllocateJob.travelTimeGroup).map(key => {
                return {
                    key,
                    ...firstPossibleAllocateJob.travelTimeGroup[key]
                }
            });
        }
        
        return {
            ...item,
            key: `resource${item.key}`,
            email: item.email,
            id: item.id,
            mobilePhone: item.mobilePhone,
            name: item.name,
            hasLinkedDrive: hasLinkedDrive,
            categoryText: compact([item.category, item.employmentType]).join(' - '),
            isPerson: item.resourceType === TYPE_RESOURCE.RESOURCE,
            isVehicle: item.assetType === TYPE_RESOURCE.VEHICLE,
            isOnCall: item.isOnCall,
            isVolunteer: item.isVolunteer,
            weeklyHours: weeklyHours,
            weeklyHoursInMinutes: weeklyHoursInMinutes,
            resourceHoursRecord: resourceHoursRecord, 
            isCallOut: item.isCallOut,
            isAccountBlacklisted: item.isAccountBlacklisted,
            isAccountWhitelisted: item.isAccountWhitelisted,
            isLocationBlacklisted: item.isLocationBlacklisted,
            isLocationWhitelisted: item.isLocationWhitelisted,
            resourceTagsDisplay: resourceTagsDisplay,
            style: style,
            draggable: draggable,
            category: item.category,
            photoUrl: item.photoUrl,
            assetType: item.assetType,
            resourceType: item.resourceType,
            icon: this.getResourceIcon(item),
            travelData: travelData || [],
            isSecondaryCO,
            isTemporaryCO
        }
    }
    buildResources(result) {
        const res = result.map(item => {
            return this.buildResource(item);
        })

        this.resourceTagsOption = uniqWith(this.resourceTagsOption, isEqual)
        return res;
    }

    getResourceById(resourceId) {
        return find(this.resources, item => item.id == resourceId)
    }
    getDriveShiftById(driveShiftId) {
        let result = null;
        let shiftIndexTemp = 0;
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        let drive = null;

        each([...driveShifts, ...driveShifts2], (shiftItem, shiftIndex) => {
            if (!result && driveShiftId) {
                if (shiftItem.id == driveShiftId) {
                    shiftIndexTemp = shiftIndex;
                    result = shiftItem;
                    drive = shiftIndex < driveShifts.length ? this.driveDetail1 : this.driveDetail2;
                }
            }
        })
        return [result, shiftIndexTemp, drive];
    }
    getJobById(jobId) {
        let result = null;
        let shiftTemp = null;
        let jobIndexTemp = 0;
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        let drive = null;

        each([...driveShifts, ...driveShifts2], (shiftItem, shiftIndex) => {
           if (!result) {
                result = find(shiftItem.jobs, (jobItem, jobIndex) => {
                    if (jobItem.id == jobId) {
                        shiftTemp = shiftItem;
                        jobIndexTemp = jobIndex;
                        drive = shiftIndex < driveShifts.length ? this.driveDetail1 : this.driveDetail2;
                        return true
                    }
                })
            }
        })
        return [result, shiftTemp, jobIndexTemp, drive];
    }

    formatTime(time) {
        return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
    }
    cloneDrive = (drive) => {
        return JSON.parse(JSON.stringify(drive));
    };
    buildDrive(drive) {
        console.log('drive in buildDrive ', drive);
        this.timezoneSidId = drive && drive.driveSite && drive.driveSite.timezoneSidId;

        let driveDetail = {
            ...drive,
            location: drive && drive.driveSite && drive.driveSite.name,
        };

        driveDetail.driveShifts = drive && drive.driveShifts.map((item, index) => {
            const jobs = item.jobs.map(job => {
                let jobTag = (job.jobTags || []).find(jobTag => {
                    return jobTag.tag && jobTag.tag.name === (job.resourceRole || job.assetType);
                })
                let jobPriority = jobTag ? jobTag.tag.priority : Number.MAX_SAFE_INTEGER;
                let jobAllocations = job.jobAllocations;
                const isManuallyCreatedFromStaffingModal = job.isManuallyCreated && job.manuallyCreatedFrom === MANUALLY_CREATED_FROM.STAFFING_MODAL;

                let tempJob = {
                    ...job,
                    key: job.key,
                    jobUrl: (job.id && !job.id.includes('temp_job_')) ? ('/' + job.id
                        .replace('driverdot', '')
                        .replace('drivercdl', '')) : null,
                    originalQuantity: job.quantity,
                    jobPriority: jobPriority,
                    isPin: false,
                    isShown: driveDetail.doNotUseVehicle ? 
                        (this.allocateAssetsOnly ? job.assetType === ASSET_TYPE.EQUIPMENT : (job.assetType === ASSET_TYPE.EQUIPMENT || job.resourceRole)) : 
                        (this.allocateAssetsOnly ? job.assetType : (job.assetType || job.resourceRole)),
                    isVehicleJob: job.assetType === TYPE_RESOURCE.VEHICLE,
                    isManuallyCreatedFromStaffingModal: isManuallyCreatedFromStaffingModal,
                    class: classNames('hco-job-header slds-grid job-item', {
                        'is-sub-job': job.isSubJob,
                        'manually-created-staffing-modal': isManuallyCreatedFromStaffingModal
                    }),
                    resourceRole: job.resourceRole,
                    resourceRoleText: compact([job.resourceRole, job.dualRole]).join('/'),
                    jobTagsStr: this.buildJobTagString(job.jobTags || []),
                    jobAllocations: jobAllocations && jobAllocations.map(itemJa => {
                        const posAl = this.listPossibleAllocations.find(itemEx => itemEx.resourceId == itemJa.resourceId && itemEx.jobId == itemJa.jobId && !itemEx.isAvailable) || null
                        const exceptionLog = posAl && posAl.exceptionLog.length > 0 && posAl.exceptionLog || [];

                        return {
                            ...itemJa,
                            id: itemJa.id,
                            jobId: itemJa.jobId,
                            additionalRolesString: (itemJa.additionalRoles || []).join(', '),
                            isDeleted: itemJa.status === JOB_ALLOCATION_STATUS.DELETED,
                            icon: this.getResourceIcon(itemJa.resource),
                            timezoneSidId: this.timezoneSidId,
                            resource: this.buildResource(itemJa.resource),
                            resourceId: itemJa.resourceId,
                            exceptionLog: exceptionLog,
                            hasDriveShiftTrade: !!itemJa.driveShiftTradeId,
                            isRequestingStaff: itemJa.driveShiftTrade && itemJa.driveShiftTrade.requestingStaffId === itemJa.resourceId,
                            requestingStaffUrl: itemJa.driveShiftTrade ? ('/' + itemJa.driveShiftTrade.requestingStaffId) : '',
                            tradingStaffUrl: itemJa.driveShiftTrade ? ('/' + itemJa.driveShiftTrade.tradingStaffId) : '',
                            tradingDriveShiftUrl: itemJa.driveShiftTrade ? ('/' + itemJa.driveShiftTrade.tradingStaffDriveShiftId) : '',
                            requestingDriveShiftUrl: itemJa.driveShiftTrade ? ('/' + itemJa.driveShiftTrade.requestingStaffDriveShiftId) : '',
                            key: itemJa.key
                        }
                    }) || null
                }
                this.sumUpJobData(tempJob);
                return tempJob;
            })
            return {
                ...item,
                isShown: this.allocateAssetsOnly ? index === 0 : true,
                name: item.name,
                jobs: orderBy(jobs, ['jobPriority', (job) => {
                    return job.resourceRole || job.assetType
                }], ['asc', 'asc']),
                start: item && item.start,
                finish: item && item.finish,
                id: item.id,
                driveDate: drive.driveDate,
                key: item.key
            }
        })

        return driveDetail
    }

    buildPossibleAllocations(data) {
        // console.log('buildPossibleAllocations:', JSON.stringify(data));
        return data.map(item => ({
            ...item
        }))

    }

    getListJobAvailable(resourceId) {
        return this.listPossibleAllocations.filter(item => (item.resourceId == resourceId && item.isAvailable)).map(item => {
            return item.jobId
        })
    }
    getListResourceAvailable(jobId, isAvailable = false) {
        if(!jobId) return [];

        return this.listPossibleAllocations
            .filter(item => {
                return item.jobId === jobId && item.isAvailable === isAvailable;
            })
            .map(item => ({
                ...item,
                resourceId: item.resourceId
            }))
    }
    getListJobUnavailable(resourceId) {
        return this.listPossibleAllocations.filter(item => (item.resourceId == resourceId && (item.isAvailable == false))).map(item => {
            return item.jobId
        })
    }
    isResourceAllocatedToDriveShift(resource, driveShift) {
        return (driveShift.jobs || []).find(job => {
            let jobAllocations = this.getJobAllocations(job);
            return (jobAllocations || []).find(jobAllocation => jobAllocation.resourceId === resource.id);
        });
    }
    getDefaultJobAllocationTimes(jobAllocation) {
        let [ job, driveShift, jobIndex, drive ] = this.getJobById(jobAllocation.jobId || jobAllocation.job.id);

        const ja = this.driveHelper.calculateJATimesWithTravel(jobAllocation, drive, {
            timezoneSidId: this.timezoneSidId,
            resourceRoleGroups: this.resourceRoleGroups
        });

        return {
            start: ja.start,
            end: ja.end
        }
    }
    populateDefaultJobAllocationTimes(drive, resource) {
        if(!drive || !resource) return;
        if(drive.driveShifts.length <= 1) return;

        let allocationDriveShiftMap = {};
        drive.driveShifts.forEach((driveShift, _driveShiftIndex) => {
            driveShift.jobs.forEach(_job => {
                const jobAllocations = this.getJobAllocations(_job);
                const isAllocated = jobAllocations.find(jobAllocation => jobAllocation.resourceId === resource.id);
                if(isAllocated) {
                    if(!allocationDriveShiftMap[driveShift.key]) {
                        allocationDriveShiftMap[driveShift.key] = {
                            job: _job,
                            allocations: []
                        }
                    }

                    allocationDriveShiftMap[driveShift.key].allocations.push(isAllocated);
                }
            })  
        })

        if(Object.keys(allocationDriveShiftMap).length < 2) { //allocated to < 2 shifts
            Object.keys(allocationDriveShiftMap).forEach((driveShiftKey, driveShiftIndex) => {
                const allocations = allocationDriveShiftMap[driveShiftKey].allocations;
                const job = allocationDriveShiftMap[driveShiftKey].job;
                allocations.forEach(jobAllocation => {
                    const { start, end } =  this.getDefaultJobAllocationTimes({
                        ...jobAllocation,
                        start: job.start,
                        end: job.finish,
                        job
                    });
                    jobAllocation.start = start;
                    jobAllocation.end = end;
                });
            });
            return;
        }

        Object.keys(allocationDriveShiftMap).forEach((driveShiftKey, driveShiftIndex) => {
            const allocations = allocationDriveShiftMap[driveShiftKey].allocations;
            const job = allocationDriveShiftMap[driveShiftKey].job;
            allocations.forEach(jobAllocation => {
                const { start, end } = this.getDefaultJobAllocationTimes({
                    ...jobAllocation,
                    start: job.start,
                    end: job.finish,
                    job
                });
                
                if(driveShiftIndex === 0) {
                    //first shift
                    const nextDriveShift = drive.driveShifts[driveShiftIndex + 1];
                    jobAllocation.start = start;
                    jobAllocation.end = this.driveHelper.newDateTime(nextDriveShift.driveDate, nextDriveShift.startTime, this.timezoneSidId).toISOString();
                } else if(driveShiftIndex === Object.keys(allocationDriveShiftMap).length - 1) {
                    const previousDriveShift = drive.driveShifts[driveShiftIndex -1];
                    jobAllocation.start = this.driveHelper.newDateTime(previousDriveShift.driveDate, previousDriveShift.endTime, this.timezoneSidId).toISOString();
                    jobAllocation.end = end;
                } else {
                    const previousDriveShift = drive.driveShifts[driveShiftIndex -1];
                    const nextDriveShift = drive.driveShifts[driveShiftIndex + 1];
                    jobAllocation.start = this.driveHelper.newDateTime(previousDriveShift.driveDate, previousDriveShift.endTime, this.timezoneSidId).toISOString();
                    jobAllocation.end = this.driveHelper.newDateTime(nextDriveShift.driveDate, nextDriveShift.startTime, this.timezoneSidId).toISOString();
                }
            })
        })
        
        return allocationDriveShiftMap;
    }

    getListResourceAllocated(driveShifts = []) {
        let result = [];
        each(driveShifts, item => {
            each(item.jobs, job => {
                let jobAllocations = this.getJobAllocations(job);
                each(jobAllocations, jobAllocation => {
                    result.push(jobAllocation)
                })
            })
        })
        return result;
    }
    setDefaultValues = () => {
        this.activeTab = this.readOnly ? TABS.DETAILS : TABS.STAFFING;
        
        this.radioTypeValue = this.allocateAssetsOnly ? TYPE_RESOURCE.VEHICLE : TYPE_RESOURCE.RESOURCE;

        this.resourceFilters = {
            callOut: false,
            onCall: false,
            assignedToLinkedDrives: false,
            weeklyHours: false,
            selectedResourcesTag: [],
            selectedResourceRoles: [],
            selectedResourceEmploymentTypes: [],
            weeklyHoursRange: {
                start: 0,
                end: 100
            },
            queryText: ''
        }

        this.resourceSort = {
            sortBy: 'name',
            sortDirection: 'asc'
        }

        if(this.readOnly) {
            this.disableTransfer = true;
            this.disableCreateJob = true;
            this.disableEditJob = true;
        }
    }

    changeTab = (event) => {
        const newTab = event.currentTarget.dataset['value'];
        this.activeTab = newTab;
        this.buildException();
    }

    isResourceTerminated = (resource, drive) => {
        if(resource.resourceType === RESOURCE_TYPE.ASSET) return false;
        if(!resource.terminationDate) return false;
        if(!drive) return false;

        return resource.terminationDate <= drive.driveDate;
    }

    isResourceInactive = (resource, drive) => {
        if(resource.resourceType === RESOURCE_TYPE.PERSON) return false;
        if(!drive) return false;

        if(resource.effectiveDate && resource.effectiveDate > drive.driveDate) {
            return true;
        }

        if(!resource.isActive) {
            return true;
        }

        return false;
    }

    handleFilter() {
        const filter = this.resourceFilters;
        
        this.resourcesFilterList = [...this.resources];
        //hide all terminated or inactive resources
        this.resourcesFilterList = this.resourcesFilterList.filter(item => {
            const isTerminatedForDrive1 = this.isResourceTerminated(item, this.driveDetail1);
            const isInactiveForDrive1 = this.isResourceInactive(item, this.driveDetail1); 
            let isTerminatedForDrive2 = false;
            let isInactiveForDrive2 = false; 
            if(this.isTransfer) {
                isTerminatedForDrive2 = this.isResourceTerminated(item, this.driveDetail2);
                isInactiveForDrive2 = this.isResourceInactive(item, this.driveDetail2); 

                return (!isTerminatedForDrive1 && !isInactiveForDrive1) || (!isTerminatedForDrive2 && !isInactiveForDrive2);
            } else {
                return !isTerminatedForDrive1 && !isInactiveForDrive1;
            }
        });

        if(!this.isPinned){
            if(this.radioTypeValue == TYPE_RESOURCE.RESOURCE){
                this.resourcesFilterList = this.resourcesFilterList.filter(item => item.resourceType == TYPE_RESOURCE.RESOURCE)
            } else if(this.radioTypeValue == TYPE_RESOURCE.EQUIPMENT){
                this.resourcesFilterList = this.resourcesFilterList.filter(item => item.assetType == TYPE_RESOURCE.EQUIPMENT)
            } else {
                this.resourcesFilterList = this.resourcesFilterList.filter(item => item.assetType == TYPE_RESOURCE.VEHICLE)
            }
        }

        if (filter && typeof (filter) == 'object') {
            if (this.isPinned) {
                if(filter.callOut) {
                    this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                        return item.callOutJobIds.includes(this.jobIdPin);
                    });
                }
            }
            
            if (filter.queryText) {
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    return item.name.toUpperCase().includes(filter.queryText.toUpperCase())
                });
            }

            if (filter.selectedResourcesTag.length > 0) {
                const selectedResourcesTag = filter.selectedResourcesTag.map(item => item.selected && item.value);
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    return some(item.resourceTagsDisplay, itemSub => {
                        return some(itemSub.details, itemDetail => selectedResourcesTag.includes(itemDetail.id))
                    })
                });
            }

            if (filter.selectedResourceRoles.length > 0) {
                const selectedResourceRoles = filter.selectedResourceRoles.map(item => item.selected && item.value);
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    const canHandleRole = (item.resourceTagsDisplay || []).find(itemSub => {
                        if(itemSub.key !== 'Role') return false;
                        return some(itemSub.details, itemDetail => selectedResourceRoles.includes(itemDetail.value))
                    });

                    return canHandleRole;
                });  
            }

            if (filter.selectedResourceEmploymentTypes.length > 0) {
                const selectedResourceEmploymentTypes = filter.selectedResourceEmploymentTypes.map(item => item.selected && item.value);
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    return selectedResourceEmploymentTypes.includes(item.employmentType);
                });
            }

            if (filter.onCall) {
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    return item.isOnCall;
                });
            }

            if (filter.assignedToLinkedDrives) {
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    return item.hasLinkedDrive;
                });
            }

            if (filter.weeklyHours && filter.weeklyHoursRange) {
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    return item.resourceType !== TYPE_RESOURCE.RESOURCE || item.weeklyHours >= filter.weeklyHoursRange.start && item.weeklyHours <= filter.weeklyHoursRange.end;
                });
            }
        }

        if (this.isPinned) {
            const [jobDetail] = this.getJobById(this.jobIdPin);

            this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                let result = false;
                if((item.resourceType == TYPE_RESOURCE.RESOURCE && jobDetail.resourceRole) || (item.assetType && item.assetType == jobDetail.assetType)){
                    let temp = this.isRecommendations ? this.listResourceAvailable : this.listResourceUnavailable;
                    each(temp, itemResource => {
                        if (itemResource.resourceId == item.id) {
                            if(item.resourceType == TYPE_RESOURCE.RESOURCE){
                                const firstPossibleAllocateJob = this.listPossibleAllocations.find((allocation) => (
                                    allocation.resourceId === item.id && allocation.jobId === jobDetail.id && allocation.travelTimeGroup
                                ));
                    
                                if(firstPossibleAllocateJob) {
                                    item.travelData = Object.keys(firstPossibleAllocateJob.travelTimeGroup).map(key => {
                                        return {
                                            key,
                                            ...firstPossibleAllocateJob.travelTimeGroup[key]
                                        }
                                    });
                                }
                            }

                            result = true;
                            return false;
                        }
                    })

                    item.isCallOut = item.callOutJobIds.includes(this.jobIdPin);
                    item.isTraded = item.tradedJobIds.includes(this.jobIdPin);
                }
                return result;
            })
        }

        this.setResourceException();
        this.handleSort();
    }
    handleSort() {
        const resourceSort = this.resourceSort;
        if (resourceSort && resourceSort.sortBy && resourceSort.sortDirection) {
            this.resourcesFilterList = orderBy(this.resourcesFilterList, [(resource) => {
                if(resourceSort.sortBy === 'drivingRolesTravelDistanceTo') {
                    return (resource.travelData || [])[0]?.travelDistanceTo;
                } else if (resourceSort.sortBy === 'drivingRolesTravelDistanceBack') {
                    return (resource.travelData || [])[0]?.travelDistanceBack;
                } else if (resourceSort.sortBy === 'staffRolesTravelDistanceTo') {
                    return (resource.travelData || [])[1]?.travelDistanceTo;
                } else if (resourceSort.sortBy === 'staffRolesTravelDistanceBack') {
                    return (resource.travelData || [])[1]?.travelDistanceBack;
                } else {
                    return resource[resourceSort.sortBy];
                }
            }], [resourceSort.sortDirection]);
        }
    }
    handleClose() {
        this.initialized = false;
        this.onClickUnpin();
        this.dispatchEvent(new CustomEvent('close', {
            detail: {

            }
        }));
    }

    saveJob = (job) => {
        let service = new jobService();

        return service.save(job, {
            checkChanges: true
        }).then(result => {
            if(result.success) {
                const event = new ShowToastEvent({
                    message: 'Job was saved successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);

                return result.returnedData && result.returnedData.length > 0 && result.returnedData[0].Id
            } else {
                throw result;
            }
        })
    }

    deleteDriveShiftTag = (driveShiftTag) => {
        let service = new driveShiftTagService();

        return service.delete({
            id: driveShiftTag.id
        }).then(result => {
            const event = new ShowToastEvent({
                message: 'Drive Shift Tag was deleted successfully.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        })
        .catch(error => this.exceptionHandler(error))
    }
    saveDriveShiftTag = (driveShiftTag) => {
        let service = new driveShiftTagService();

        return service.save(driveShiftTag).then(result => {
                const event = new ShowToastEvent({
                    message: 'Drive Shift Tag was saved successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                if(result.success) {
                    return result.returnedData && result.returnedData.length > 0 && result.returnedData[0].Id
                } else {
                    return null
                }
            })
            .catch(error => this.exceptionHandler(error))
    }

    buildSaveParams(includeDeletedJAs = false) {
        let driveUpdate = [
            this.mapDataToServer(this.driveDetail1, includeDeletedJAs),
        ];
        if (this.driveId2) {
            driveUpdate = [...driveUpdate, this.mapDataToServer(this.driveDetail2)]
        }
        
        let jobsToSave = [];
        driveUpdate.forEach(drive => {
            drive.driveShifts.forEach(driveShift => {
                driveShift.jobs.forEach(job => {
                    jobsToSave.push({
                        _dataKey: job._dataKey,
                        id: job.id,
                        key: job.key,
                        excludeFromOptimizer: !!job.excludeFromOptimizer,
                        jobAllocations: (job.jobAllocations || []).map(jobAllocation => {
                            if (!slwcUtils.isNullOrEmpty(jobAllocation.end) && !slwcUtils.isNullOrEmpty(jobAllocation.start)) {
                                jobAllocation.duration = DateTime.fromISO(isString(jobAllocation.end) ? jobAllocation.end : jobAllocation.end.toISOString(), {
                                    zone: this.timezoneSidId
                                }).diff(DateTime.fromISO(isString(jobAllocation.start) ? jobAllocation.start : jobAllocation.start.toISOString(), {
                                    zone: this.timezoneSidId
                                })).as('minutes');
                            }
                            let clonedJobAllocation = cloneDeep(jobAllocation);
                            delete clonedJobAllocation.exceptionLog;
    
                            return clonedJobAllocation;
                        })
                    })
                })
            })
        });

        return {
            driveUpdate,
            jobsToSave
        }
    }

    handleSave() {
        const { driveUpdate, jobsToSave } = this.buildSaveParams();
        
        if(this.mode === MODE.LOCAL) {
            this.dispatchEvent(new CustomEvent('save', {
                detail: {
                    drives: driveUpdate,
                    jobs: jobsToSave
                }
            }));
        } else {
            let service = new jobService();
            this.showLoading()
            return service.saveList(jobsToSave, {
                checkChanges: true
            }).then(result => {
                const event = new ShowToastEvent({
                    message: 'Resource Allocations were updated successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            })
            .then(() => {
                this.dispatchEvent(new CustomEvent('save', {
                    detail: {
                    }
                }));

                this.initialized = false;
            })
            .catch(error => this.exceptionHandler(error))
            .finally(() => {
                this.hideLoading();
            });
        }
    }
    
    handleSaveAndDispatch() {
        this.showConfirmModal({
            title: 'Confirm Save & Dispatch',
            message: 'Are you sure you want to save and dispatch?',
            onClose: (result) => {
                this.hideConfirmModal();
                if (result) {
                    const { driveUpdate, jobsToSave } = this.buildSaveParams();

                    let service = new jobService();
                    this.showLoading()
                    return service.saveList(jobsToSave, {
                        checkChanges: true
                    }).then(result => {
                        const event = new ShowToastEvent({
                            message: 'Resource Allocations were updated successfully.',
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);
                    })
                    .then(() => {
                        this.dispatchEvent(new CustomEvent('save', {
                            detail: {
                            }
                        }));

                        this.showDispatchDriveModal();
                    })
                    .catch(error => this.exceptionHandler(error))
                    .finally(() => {
                        this.hideLoading();
                        fireEvent(this.pageRef, 'optimizationSummary:refresh');
                    });
                }
            }
        });
    }

    handleResolve(){
        let service = new exceptionService();
        const exceptionsToSave = this.mapExceptionResolveToServer(this.dataException)

        this.showLoading()
        return service.saveList(exceptionsToSave).then(result => {
            const event = new ShowToastEvent({
                message: 'Exception were updated successfully.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        })
        .catch(error => this.exceptionHandler(error))
        .finally(() => {
            //TODO: bad code => doesn't need to refresh the whole component
            this.hideLoading();
            fireEvent(this.pageRef, 'optimizationSummary:refresh');
            this.init();
            this.onClickUnpin();
        })
    }
    mapExceptionResolveToServer(drives = []) {
        let exceptionLog = [];
        drives.map(driveItem => {
            driveItem.driveShifts.map(dsItem => {
                dsItem.jobs.map(jobItem => {
                    jobItem.jobAllocations.map(jaItem => {
                        exceptionLog.push({
                            id: jaItem.id,
                            status: (jaItem.isSelected) ? "Resolved" : (jaItem.status || 'Open')
                        })
                    })
                })
            })
        })
        return exceptionLog;
    }
    mapDataToServer(drive, includeDeleted = false) {
        let driveToSave = cloneDeep(drive);

        let {
            noOfDotVehicles,
            noOfCdlVehicles
        } = this.getNumberOfDotAndCdlDrivers(drive, includeDeleted);

        driveToSave.driveShifts.forEach(driveShift => {
            let driverJob = driveShift.jobs.find(job => this.driveHelper.isDriverJob(job, true));
            if (!driverJob) {
                driverJob = driveShift.jobs.find(job => this.driveHelper.isDriverJob(job, false));
            }

            if(driverJob) {
                driveShift.jobs.forEach(job => {
                    if (noOfDotVehicles > 0 && job.id && job.id.startsWith('driverdot')) {
                        (job.jobAllocations || []).forEach(jobAllocation => {
                            const found = (driverJob.jobAllocations || []).find(jobAllocation2 => {
                                return jobAllocation2.resourceId === jobAllocation.resourceId;
                            });

                            (jobAllocation.exceptionLog || []).forEach(exceptionLog => {
                                exceptionLog.jobId = exceptionLog.jobId ? exceptionLog.jobId.replace('driverdot', '') : '';
                            });

                            if(!found) {
                                driverJob.jobAllocations.push({
                                    ...jobAllocation,
                                    jobId: jobAllocation.jobId ? jobAllocation.jobId.replace('driverdot', '') : '',
                                    DOT: true
                                })
                            }
                        })
                    }
                    if (noOfCdlVehicles > 0 && job.id && job.id.startsWith('drivercdl')) {
                        (job.jobAllocations || []).forEach(jobAllocation => {
                            const found = (driverJob.jobAllocations || []).find(jobAllocation2 => {
                                return jobAllocation2.resourceId === jobAllocation.resourceId;
                            });

                            (jobAllocation.exceptionLog || []).forEach(exceptionLog => {
                                exceptionLog.jobId = exceptionLog.jobId ? exceptionLog.jobId.replace('drivercdl', '') : '';
                            });

                            if(!found) {
                                driverJob.jobAllocations.push({
                                    ...jobAllocation,
                                    jobId: jobAllocation.jobId ? jobAllocation.jobId.replace('drivercdl', '') : '',
                                    CDL: true
                                })
                            }
                        })
                    }
                })

                driverJob.quantity = (driverJob.quantity || 0) + noOfDotVehicles + noOfCdlVehicles;
                if(driverJob.quantity <= 0) {
                    driverJob.quantity = null;
                }
            }
            
            //remove all sub jobs 
            remove(driveShift.jobs, job => job.isSubJob);
        })

        return driveToSave;
    }
    handleRadioListFilter(event) {
        this.radioPinValue = event.detail.value;
        this.handleFilter()
    }
    handleRadioResourceListFilter(event) {
        this.radioTypeValue = event.detail.value;
        this.handleFilter()
    }
    onFilterChanged(event) {
        if (event.detail.value && typeof (event.detail.value) == 'object') {
            this.resourceFilters = event.detail.value;
            this.handleFilter();
        }
    }
    onSortChanged(event) {
        if (event.detail.value && typeof (event.detail.value) == 'object') {
            this.resourceSort = event.detail.value;
            this.handleSort();
        }
    }
    onClickPin(event) {
        const jobId = event.currentTarget.dataset.id;
        this.pinJob(jobId);
    }
    onClickUnpin() {
        this.jobIdPin = null;
        this.radioPinValue = LIST_PINNED.RECOMMENDATED;
        this.isPinned = false;
        this.resourceSort = this.resourceSort || {
            sortBy: 'name',
            sortDirection: 'asc'
        }
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        each([...driveShifts, ...driveShifts2], item => {
            item.jobs.map(itemSub => {
                itemSub.isPin = false;
                itemSub.class = classNames('hco-job-header slds-grid job-item', {
                    'is-sub-job': itemSub.isSubJob,
                    'manually-created-staffing-modal': itemSub.isManuallyCreatedFromStaffingModal
                })
            });
        })
        const listjobEl = this.template.querySelectorAll('.job-item');
        listjobEl.forEach(el => {
            el.classList.remove('job-disabled');
        })
        this.listResourceAvailable = [];
        this.listResourceUnavailable = [];
        this.updateStyleResource();
    }
    onClickIncludeFromOptimizer(event) {
        const jobId = event.currentTarget.dataset.id;
        
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        each([...driveShifts, ...driveShifts2], item => {
            const jobItem = item.jobs.find(itemSub => {
                return itemSub.id == jobId
            });
            if (jobItem) {
                jobItem.excludeFromOptimizer = false
            }
        })
    }
    onClickExcludeFromOptimizer(event) {
        const jobId = event.currentTarget.dataset.id;
        
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        each([...driveShifts, ...driveShifts2], item => {
            const jobItem = item.jobs.find(itemSub => {
                return itemSub.id == jobId
            });
            if (jobItem) {
                jobItem.excludeFromOptimizer = true
            }
        })
    }
    handleAddDrive() {
        this.isTransfer = true;
        this.driveId2 = null;
        this.driveDetail2 = null;
        this.onClickUnpin();
    }
    handleRemoveDrive() {
        this.isTransfer = false;
        this.driveId2 = null;
        this.driveDetail2 = null;
    }
    handleSelectDrive(event) {
        this.driveId2 = event.detail.value;
        this.fetchDrive2(this.driveId2);
    }

    transferJobAllocations(sourceJob, destinationJob, destinationDrive, newJobAllocations) {
        let existingdestinationJobResourceIds = (destinationJob.jobAllocations || []).map(ja => ja.resourceId);
        let transferredResourceIds = [];
        (sourceJob.jobAllocations || []).forEach(ja => {
            let isValidToTransfer = ja.status !== JOB_ALLOCATION_STATUS.DELETED
                                    && (!ja.resource.dedicatedToSiteId || ja.resource.dedicatedToSiteId === destinationDrive.driveSiteId);
            if (isValidToTransfer) {
                if (!existingdestinationJobResourceIds.includes(ja.resourceId)) {
                    const posAl = this.listPossibleAllocations.find(itemEx => itemEx.resourceId == ja.resourceId && itemEx.jobId == destinationJob.id && !itemEx.isAvailable) || null
                    let exceptionLog = [];
                    if(posAl && posAl.exceptionLog) {
                        exceptionLog = posAl && posAl.exceptionLog || []
                    }

                    let newJa = {
                        jobId: destinationJob.id,
                        job: destinationJob,
                        key: ja.key,
                        icon:ja.icon,
                        resourceId: ja.resourceId,
                        resource: ja.resource,
                        CDL: ja.CDL,
                        DOT: ja.DOT,
                        exceptionLog: exceptionLog,
                        travelTimeTo: posAl?.estimatedTravelTimeTo,
                        travelTimeBack: posAl?.estimatedTravelTimeBack,
                        geoServiceTravelTimeTo: posAl?.estimatedTravelData?.travelTimeTo,
                        geoServiceTravelTimeBack: posAl?.estimatedTravelData?.travelTimeBack,
                        geoServiceTravelDistanceTo: posAl?.estimatedTravelData?.travelDistanceTo,
                        geoServiceTravelDistanceBack: posAl?.estimatedTravelData?.travelDistanceBack,
                        isRelocatedResource: posAl?.isTemporaryCO || false
                    };

                    destinationJob.jobAllocations.push(newJa);
                    newJobAllocations.push(newJa);
                }
                ja.status = JOB_ALLOCATION_STATUS.DELETED;

                transferredResourceIds.push(ja.resourceId);
            }
        });

        (destinationJob.jobAllocations || []).forEach(ja => {
            if (!slwcUtils.isNullOrEmpty(transferredResourceIds) && !transferredResourceIds.includes(ja.resourceId)) {
                ja.status = JOB_ALLOCATION_STATUS.DELETED;
            }
        });
    }

    handleTransfer() {
        this.showConfirmModal({
            title: 'Confirm Transfer Drive',
            message: 'Are you sure you want to transfer this drive?',
            onClose: (result) => {
                this.hideConfirmModal();
                if (result) {
                    let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
                    let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
                    let jobAllocationsNeedToPostProcess = [];
                    driveShifts?.forEach((driveShift, index) => {
                        if(!driveShifts2[index]) return;

                        driveShift.jobs?.forEach(job => {
                            let jobDS2 = find(driveShifts2[index].jobs, itemJobDS2 => {
                                return (itemJobDS2.resourceRole && itemJobDS2.resourceRole == job.resourceRole) || 
                                       (itemJobDS2.assetType && itemJobDS2.assetType == job.assetType);
                            });
                            if (jobDS2) {
                                this.transferJobAllocations(job, jobDS2, this.driveDetail2, jobAllocationsNeedToPostProcess);
                                this.sumUpJobData(jobDS2);
                            }
                        })
                    });
            
                    const { jobsToSave } = this.buildSaveParams(true);
                    const driveId2 = this.driveDetail2.id;
                    let service = new jobService();
                    this.showLoading();

                    return service.saveList(jobsToSave, {
                        checkChanges: true
                    })
                    .then(() => {
                        const event = new ShowToastEvent({
                            message: 'Drive Staff were transferred successfully.',
                            variant: 'success',
                            mode: 'dismissable'
                        });
                        this.dispatchEvent(event);
                    })
                    .then(() => {
                       return this.init();
                    })
                    .then(() => {
                        this.handleAddDrive();
                        this.handleSelectDrive({
                            detail: {
                                value: driveId2
                            }
                        })
                    })
                    .catch(error => this.exceptionHandler(error))
                    .finally(() => this.hideLoading());
                }
            }
        });
    }

    fetchDrive2(driveId) {
        this.showLoading();
        this.availator2 = slwcAvailator.getInstance({
            driveId,
            mapApis: window.google ? window.google.maps : null
        })
        this.availator2.fetchData()
            .then(() => {
                this.availator2.setupDriverJobs();
                return this.availator2.buildScheduledAllocations();
            })
            .then((result) => {
                if (result.possibleAllocations) {
                    this.listPossibleAllocations = [...this.listPossibleAllocations, ...this.buildPossibleAllocations(result.possibleAllocations)]
                }
                if (result.drive) {
                    this.driveDetail2 = this.buildDrive(result.drive);
                    this.updateDriverJobs(this.driveDetail2);
                    this.updateDriveShiftTagExceptions(this.driveDetail2);
                    this.buildException();
                }
                if (result.resources) {
                    this.resources = [...this.buildResources(result.resources), ...this.resources];
                    this.resources = uniqBy(this.resources, item => item.id)
                    this.handleFilter();
                }

                this.resources.forEach(resource => {
                    this.validateExceptions(resource, true);
                });
            })
            .catch(error => this.exceptionHandler(error))
            .finally(this.hideLoading)
    }

    toggleDriveShiftTagsSection(event) {
        const shiftKey = event.currentTarget.dataset['value'];
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        let driveShift = driveShifts.concat(driveShifts2).find(item => item.key === shiftKey);
        if(!driveShift) return;

        driveShift.driveShftTagsSesctionExpanded = !driveShift.driveShftTagsSesctionExpanded;
    }
    
    showDispatchDriveModal() {
        let drives = [this.driveDetail1];
        
        if(this.isTransfer && this.driveDetail2) {
            drives.push(this.driveDetail2);
        }

        this.dispatchDriveModalData = {
            isOpen: true,
            drives: drives
        };
    }

    hideDispatchDriveModal(event) {
        const result = event.detail.result;
        this.dispatchDriveModalData = {};

        this.dispatchEvent(new CustomEvent('dispatched', {
            detail: {
                result
            }
        }));
    }

    /* Call out modal */
    handleShowCallOutModal(detail) {
        const [ job ] = this.getJobById(detail.jobId);
        const resourceDetail = this.getResourceById(detail.resourceId);
        this.callOutModalData = {
            isOpen: true,
            jobId: detail.jobId,
            jobAllocationId: detail.id,
            driveDate: job.driveDate,
            resourceId: detail.resourceId,
            duration: resourceDetail.dailyTimeOffHours
        }
    }

    handleCloseCallOutModal() {
        this.callOutModalData = {};
    }

    handleSaveCallOutModal(event) {
        const { jobAllocationId, jobId } = this.callOutModalData;
        const [ job ] = this.getJobById(jobId);
        const [driveShift, indexDriveShift] = this.getDriveShiftById(job.driveShiftId)
        const { callOutType , callOutReason, callOutNotes, callOutReceivedDateTime, timeOffPlan, timeOffReasonCode, usePtoForCallOut, hasTimeOffPlans } = event.detail;
        const jobAllocation = find(job.jobAllocations, item => item.id == jobAllocationId);

        let params = {
          resourceId: jobAllocation.resourceId,
          jobId: jobId
            .replace('driverdot', '')
            .replace('drivercdl', ''),
          callOutReported: true,
          callOutType: callOutType,
          callOutReason: callOutReason,
          callOutNotes: callOutNotes,
          callOutReceivedDateTime: callOutReceivedDateTime,
          timeOffPlan: timeOffPlan,
          timeOffReasonCode: timeOffReasonCode,
          usePtoForCallOut: usePtoForCallOut,
          hasTimeOffPlans: hasTimeOffPlans
        };
          
        this.showLoading();
        let service = new resourceService();
        service.saveCallOut({
          request: params
        }).then(res => {
            let message = 'Call out Captured Sucessfully.';
            if (!usePtoForCallOut) {
                message += ' No associated Time-Off created.';
            }

            this.dispatchEvent(new ShowToastEvent({
                message: message,
                variant: 'success',
                mode: 'dismissable',
            }));
  
          this.handleCloseCallOutModal();
        })
        .then(() => {
            let service = new jobService();
            let queryModel = new jobQueryModel();
            queryModel.subQueryIndicator = sObjectType.JOB_TAG | sObjectType.JOB_ALLOCATION;
            queryModel.recordIds = [jobId];
            return service.query(queryModel)
        })
        .then(([job]) => {
            if(indexDriveShift <= this.driveDetail1.driveShifts.length){
                this.availator1.updateData(job, indexDriveShift);

                return this.availator1.buildScheduledAllocations()
                .then((result) => {
                    if (result.possibleAllocations) {
                        this.listPossibleAllocations = this.buildPossibleAllocations(result.possibleAllocations);
                    }
                    if (result.drive) {
                        this.driveDetail1 = this.buildDrive(result.drive);
                        this.updateDriverJobs(this.driveDetail1);
                        this.updateDriveShiftTagExceptions(this.driveDetail1);

                        this.resources.forEach(resource => {
                            this.validateExceptions(resource, true);
                        });
                    }

                    this.updateStyleResource();
                })
            } else {
                this.availator2.updateData(job, indexDriveShift - this.driveDetail1.driveShifts.length);
                return this.availator2.buildScheduledAllocations()
                .then((result) => {
                    if (result.possibleAllocations) {
                        this.listPossibleAllocations = this.buildPossibleAllocations(result.possibleAllocations);
                    }
                    if (result.drive) {
                        this.driveDetail2 = this.buildDrive(result.drive);
                        this.updateDriverJobs(this.driveDetail2);
                        this.updateDriveShiftTagExceptions(this.driveDetail2);

                        this.resources.forEach(resource => {
                            this.validateExceptions(resource, true);
                        });
                    }

                    this.updateStyleResource();
                });
            }
        })
        .catch(error => this.exceptionHandler(error))
        .finally(() => this.hideLoading());
    }

    /* Edit Job Allocation modal */
    handleShowEditJobAllocationModal(detail) {
        let { jobId } = detail;
        let [ job, driveShift, jobIndex, drive ] = this.getJobById(jobId);

        this.jobAllocationModalData = {
            isOpen: true,
            drive: drive,
            job: job,
            jobAllocation: detail
        }
    }

    handleCloseEditJobAllocationModal() {
        this.jobAllocationModalData = {};
    }

    handleSaveEditJobAllocationModal(event) {
        let { job , jobAllocation } = this.jobAllocationModalData; 

        let [ tempJob ] = this.getJobById(job.id);
        let tempJobAllocation =  find(job.jobAllocations, item => item.id == jobAllocation.id)

        tempJobAllocation = extend(tempJobAllocation, event.detail);
        tempJob = extend(tempJob, {
            jobAllocationTimeSource: false
        })

        this.validateExceptions(tempJobAllocation, true);
        this.handleCloseEditJobAllocationModal();
    }

    /* Add role modal */
    handleShowAddRoleModal(detail) {
        this.addRoleModalData = {
            isOpen: true,
            jobId: detail.jobId,
            jobAllocation: detail.jobAllocation,
            resource: detail.resource
        }
    }

    handleCloseAddRoleModal() {
        this.addRoleModalData = {};
    }

    handleSaveAddRoleModal(event) {
        let { jobId, jobAllocation } = this.addRoleModalData;
        let [ job ] = this.getJobById(jobId);
        let ja = find(job.jobAllocations, item => item.key == jobAllocation.key)
        ja.additionalRoles = event.detail.roles
        ja.additionalRolesString = (ja.additionalRoles || []).join(', ');
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

    pinJob(jobId, radioPinValue) {
        let job = null;
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        each([...driveShifts, ...driveShifts2], item => {
            const jobItem = item.jobs.filter(itemSub => {
                itemSub.isPin = false;
                itemSub.class = classNames('hco-job-header slds-grid job-item', {
                    'is-sub-job': itemSub.isSubJob,
                    'manually-created-staffing-modal': itemSub.isManuallyCreatedFromStaffingModal
                })
                return itemSub.id == jobId
            });
            if (jobItem.length > 0) {
                job = jobItem[0]
            }
        })
        if (!job) return;

        this.radioPinValue = radioPinValue || LIST_PINNED.RECOMMENDATED;
        this.jobIdPin = jobId;
        this.isPinned = true;
        this.resourceSort = this.resourceSort || {
            sortBy: 'name',
            sortDirection: 'asc'
        }
        job.isPin = true
        job.class = classNames('hco-job-header slds-grid job-item pinned', {
            'is-sub-job': job.isSubJob,
            'manually-created-staffing-modal': job.isManuallyCreatedFromStaffingModal
        })

        const clonedDriveDetails1 = this.cloneDrive(this.driveDetail1);
        const clonedDriveDetails2 = this.cloneDrive(this.driveDetail2);
        this.resources.forEach(resource => {
            this.validateExceptions({
                resource: resource,
                resourceId: resource.id,
                job: job,
                jobId: job.id
            }, false, clonedDriveDetails1, clonedDriveDetails2);
        })
        
        this.listResourceAvailable = this.getListResourceAvailable(jobId, true);
        this.listResourceUnavailable = this.getListResourceAvailable(jobId, false);
        const listjobEl = this.template.querySelectorAll('.job-item');
        listjobEl.forEach(el => {
            const jobIdEl = el.dataset.id;

            if (jobIdEl != jobId) {
                el.classList.add('job-disabled');
            } else {
                el.classList.remove('job-disabled');
            }
        })
        this.updateStyleResource();
    }

    preSelectJob(jobId) {
        let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        let driveShifts2 = this.driveDetail2 ? (this.driveDetail2.driveShifts || []) : [];
        let subJob = [...driveShifts, ...driveShifts2].map(item => item.jobs).flat().find(job => job.id === `driverdot${jobId}` || job.id === `drivercdl${jobId}`);
        if (subJob && subJob.isShown) {
            this.pinJob(subJob.id, LIST_PINNED.ALTERNATIVE);
        } else {
            this.pinJob(jobId, LIST_PINNED.ALTERNATIVE);
        }

        this.scrollToViewPinJob();
    }

    scrollToViewPinJob() {
        setTimeout(() => {
            let element = this.template.querySelector('.job-item.pinned');
            element?.scrollIntoView({ behavior: "instant", block: "center"})
        });
    }

    setResourceException() {
        each(this.resourcesFilterList, item => {
            item.exceptionLog = this.isPinned
                ? this.listPossibleAllocations.find(allocation => allocation.resourceId === item.id && allocation.jobId === this.jobIdPin)?.exceptionLog || []
                : [];
        });
    }
}