import TIME_ZONE from '@salesforce/i18n/timeZone';
import skedGoogleMapApis from '@salesforce/resourceUrl/skedGoogleMapApis';
import {
    dataService, debugLogService, driveQueryModel, driveService, driveShiftTagService, resourceService,
    linkedDrivesService, linkedDrivesQueryModel,
    exceptionService, jobAllocationService, jobQueryModel, jobService, sObjectType
} from 'c/dataService';
import {
    get, cloneDeep, compact, each, extend, find, groupBy, isEqual, keyBy, map, orderBy, remove, some, uniqBy, uniqueId, uniqWith, isString, differenceBy
} from 'c/lodash';
import {
    DateTime
} from 'c/luxon';
import {
    fireEvent, registerListener, unregisterAllListeners
} from 'c/pubsub';
import * as slwcLinkedDrivesAvailator from 'c/slwcLinkedDrivesAvailator';
import { ASSET_TYPE, DRIVE_TYPE, JOB_ALLOCATION_STATUS, JOB_STATUS, RESOURCE_ROLE_GROUP, RESOURCE_TYPE } from 'c/slwcConstants';
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

export default class SlwcLinkedDriveStaffingDetails extends LightningElement {
    driveHelper = new DriveHelper();

    @wire(CurrentPageReference) pageRef;

    @api isOpen = false;
    @api drive;
    @api readOnly = false;
    
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

    @track listDrive = [];
    @track initialized = false;
    @track showSpinnerCount = 0;

    @track linkedDrive;
    @track linkedDriveDetails;

    get driveName() {
        return this.linkedDriveDetails ? this.linkedDriveDetails.linkedDrive.name : null;
    }

    @track activeTab = TABS.STAFFING;
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
    @track availator = null;
    @track resourceFilters = null;
    @track resourceSort = null;
    @track currentJobItemEl = null;
    @track currenResourceItemEl = null;
    @track dragEnterCounter = 0;
    @track listPossibleAllocations = [];
    @track mapResourceJobPossibleAllocations = {};
    @track radioPinValue = LIST_PINNED.RECOMMENDATED
    @track radioTypeValue = TYPE_RESOURCE.RESOURCE

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
            staffingTabLink: classNames('slds-tabs_default__item slds-text-title_caps', {
                'slds-is-active': this.showStaffingTab
            }),
            exceptionsTabLink: classNames('slds-tabs_default__item slds-text-title_caps', {
                'slds-is-active': this.showExceptionsTab
            })
        }
    }

    get showStaffingTab() {
        return this.activeTab === TABS.STAFFING;
    }

    get showExceptionsTab() {
        return this.activeTab === TABS.EXCEPTIONS;
    }

    get showStaffingTabClass() {
        return classNames('tab-content', {
            "hide-tab": this.activeTab != TABS.STAFFING,
        })
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
        return [{
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
        }];
    }

    get showSpinner() {
        return this.showSpinnerCount > 0;
    }

    get isRecommendations() {
        return this.radioPinValue == LIST_PINNED.RECOMMENDATED;
    }
    
    get vehicleMode() {
        return this.radioTypeValue == TYPE_RESOURCE.RESOURCE;
    }
    
    get filterMode() {
        return this.isJobPinned ? 'PINNED_JOB' : 'ALL_JOBS'
    }

    get isJobPinned() {
        return !!this.jobIdPin;
    }
    
    get selectedChildJobs() {
        return this.pinnedJobWrapper.childJobWrappers
            .filter(item => item.selected)
            .map(item => item.job);
    }

    renderedCallback() {
        registerListener('showAddRoleModal', this.handleShowAddRoleModal, this);

        registerListener('showDeleteDriveShiftTagConfirmModal', this.handleShowDeleteDriveShiftTagConfirmModal, this);
        registerListener('saveDriveShiftTagInAllocationModal', this.handleSaveDriveShiftTag, this);

        if (!this.initialized) {
            this.init();
            this.initialized = true;
        }
    }
    disconnectedCallback() {
        unregisterAllListeners(this);
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

    init() {
        // this.recordId = 'a25P0000001IDTzIAO';
        // this.isOpen = true;
        /* **** */

        this.linkedDrive = null;
        this.linkedDriveDetails = null;
        this.resources = [];
        this.setDefaultValues();
        
        if(this.recordId) {
            this.showLoading();
            this.onClickUnpin();
            Promise.resolve()
                .then(() => {
                    if (!window.google) {
                        return loadScript(this, skedGoogleMapApis)
                            .catch((e) => {})
                    }
                })
                .then(() => {
                    return Promise.all([
                        this.retrieveLinkedDrive(this.recordId),
                        this.retrieveCustomSettings()
                    ]);
                })
                .then(() => {
                    this.availator = slwcLinkedDrivesAvailator.getInstance({
                        linkedDrives: this.linkedDrive.drives,
                        mapApis: window.google ? window.google.maps : null
                    });
                  
                    return Promise.all([
                        this.retrieveLinkedDriveResources(),
                        this.availator.fetchData(false)
                        
                    ])
                    .then(() => {
                        this.availator.setupDriverJobs();
                        return this.availator.buildScheduledAllocations()
                    })
                    .then((result) => {
                        if (result.resources) {
                            const { possibleAllocations, mapResourceJobPossibleAllocations } = this.buildPossibleAllocations(result.possibleAllocations);
                            this.listPossibleAllocations = possibleAllocations;
                            this.mapResourceJobPossibleAllocations = mapResourceJobPossibleAllocations;
                        }
                        
                        if (result.linkedDrives) {
                            this.linkedDrive.drives = result.linkedDrives;
                            this.linkedDriveDetails = this.buildLinkedDrives(this.linkedDrive, result.resources);
                            this.updateDriverJobs(this.linkedDriveDetails.driveWrapper);
                            this.updateDriveShiftTagExceptions(this.linkedDriveDetails.driveWrapper);
                        }

                        if (result.resources) {
                            this.resources = this.buildResources(result.resources);
                            this.handleFilter();
                        }

                        this.resources.forEach(resource => {
                            this.validateExceptions(resource, true);
                        });
                    })
                })
                .catch(error => this.exceptionHandler(error))
                .finally(this.hideLoading)
        }
    }

    setDefaultValues() {
        this.activeTab = TABS.STAFFING;
        
        this.radioTypeValue = TYPE_RESOURCE.RESOURCE;

        this.resourceFilters = {
            callOut: false,
            onCall: false,
            assignedToLinkedDrives: false,
            selectedResourcesTag: [],
            selectedResourceRoles: [],
            selectedResourceEmploymentTypes: [],
            weeklyHoursRange: {
                start: 0,
                end: 40
            },
            queryText: ''
        }

        this.resourceSort = {
            sortBy: 'name',
            sortDirection: 'asc'
        }
    }

    updateDriverJobs(driveWrapper) {
        if(!driveWrapper || !driveWrapper.driveShifts || !driveWrapper.driveShifts.length) return;
        if(this.allocateAssetsOnly) return;
        
        let {
            noOfDotVehicles,
            noOfCdlVehicles
        } = this.getNumberOfDotAndCdlDrivers(driveWrapper);

        driveWrapper.driveShifts.forEach(driveShift => {
            let driverJob = driveShift.jobs.find(job => this.driveHelper.isDriverJob(job));
            
            if(!driverJob) return;

            let dotDriverJob = driveShift.jobs.find(job => job.id.startsWith('driverdot'));
            let cdlDriverJob = driveShift.jobs.find(job => job.id.startsWith('drivercdl'));
            let leftOverJobAllocations = [];
            driverJob.quantity = driverJob.originalQuantity || 0;
            
            if(dotDriverJob) {
                if(noOfDotVehicles > 0) {
                    driverJob.quantity = driverJob.quantity - noOfDotVehicles;
                    dotDriverJob.quantity = noOfDotVehicles;
                    dotDriverJob.isShown = driverJob.isShown && true;
                } else {
                    dotDriverJob.quantity = null;
                    dotDriverJob.isShown = false;
                    dotDriverJob.jobAllocations = [];
                    dotDriverJob.childJobs.forEach(childJob => {
                        leftOverJobAllocations = leftOverJobAllocations.concat(cloneDeep(dotDriverJob.jobAllocations || []));
                        childJob.jobAllocations = [];
                    });
                }
            }
            
            if(cdlDriverJob) {
                if(noOfCdlVehicles > 0) {
                    driverJob.quantity = driverJob.quantity - noOfCdlVehicles;
                    cdlDriverJob.quantity = noOfCdlVehicles;
                    cdlDriverJob.isShown = driverJob.isShown && true;
                } else {
                    cdlDriverJob.quantity = null;
                    cdlDriverJob.isShown = false;
                    cdlDriverJob.jobAllocations = [];
                    cdlDriverJob.childJobs.forEach(childJob => {
                        leftOverJobAllocations = leftOverJobAllocations.concat(cloneDeep(childJob.jobAllocations || []));
                        childJob.jobAllocations = [];
                    });
                }    
            }
            
            if(driverJob.quantity < 0) {
                driverJob.quantity = 0;
            }

            if(leftOverJobAllocations.length) {
                leftOverJobAllocations.forEach(jobAllocation => {
                    const jobId = jobAllocation.jobId
                        .replace('driverdot', '')
                        .replace('drivercdl', '');
                    jobAllocation.CDL = false;
                    jobAllocation.DOT = false;
                    driverJob.childJobs.forEach(childJob => {
                        if(childJob.id !== jobId) return;
                        childJob.jobAllocations.push(jobAllocation);
                    });

                    this.sumUpParentJobData(driverJob);
                })
            }

            this.sumUpJobData(dotDriverJob);
            this.sumUpJobData(cdlDriverJob);
            this.sumUpJobData(driverJob);
        })
    }

    allocate(resourceId, jobId) {
        let [job, driveShift, jobIndex, drive, parentJob] = this.getJobById(jobId);
        let jobsToAllocate = [job];
        if(this.isJobPinned) {
            jobsToAllocate = this.selectedChildJobs;
        } else {
            jobsToAllocate = job.childJobs || [];
        }

        if(!jobsToAllocate.length) return;

        const resource = this.getResourceById(resourceId);
        jobsToAllocate.forEach(job => {
            const posAl = this.listPossibleAllocations.find(itemEx => itemEx.resourceId == resourceId && itemEx.jobId == job.id) || null;

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
            const { start, end } =  this.getDefaultJobAllocationTimes(job);
            if(!existingJobAllocation) {
                newJobAllocation = {
                    jobId: job.id,
                    resourceId,
                    key: resourceId,
                    resource,
                    start: start,
                    end: end,
                    icon: this.getResourceIcon(resource),
                    exceptionLog: exceptionLog,
                    estimatedTravelTime: (posAl || {}).estimatedTravelTime,
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
                        estimatedTravelTime: posAl.estimatedTravelTime,
                        DOT: false,
                        CDL: false
                    })
                    delete existingJobAllocation.status;
                    delete existingJobAllocation.isDeleted;

                    newJobAllocation = existingJobAllocation;
                }
            }

            this.sumUpJobData(job);
            // this.populateDefaultJobAllocationTimes(drive, resource);
            this.validateExceptions(newJobAllocation, true);
        })

        this.updateDriveShiftTagExceptions(this.linkedDriveDetails.driveWrapper);
        this.sumUpParentJobData(this.isJobPinned ? parentJob : job);
        if(job.assetType === ASSET_TYPE.VEHICLE) {
            this.updateDriverJobs(this.linkedDriveDetails.driveWrapper);
        }
        this.updateStyleResource();
    }

    unallocate(event) {
        const resourceId = event.resourceId;
        const jobId = event.jobId;
        let [job, driveShift, jobIndex, drive, parentJob] = this.getJobById(jobId);
        let jobsToUnallocate = [job];
        if(this.isJobPinned) {
            if(job.assetType) {
                jobsToUnallocate = parentJob.childJobs;
            } else {
                jobsToUnallocate = [job];
            }
        } else {
            jobsToUnallocate = job.childJobs || [];
        }

        if(!jobsToUnallocate.length) return;

        jobsToUnallocate.forEach(job => {
            let jobAllocations = job.jobAllocations || [];
            const jobAllocation = jobAllocations.find(item => item.resourceId == resourceId && item.status !== JOB_ALLOCATION_STATUS.DELETED)
            if(!jobAllocation) return;

            if(jobAllocation.id) {
                jobAllocation.status = JOB_ALLOCATION_STATUS.DELETED;
                jobAllocation.isDeleted = true;
            } else {
                remove(jobAllocations, item => item.resourceId == resourceId);
            }

            this.sumUpJobData(job);
            this.validateExceptions({
                ...jobAllocation,
                status: JOB_ALLOCATION_STATUS.DELETED
            }, true);
        });

        // this.populateDefaultJobAllocationTimes(drive, {
        //     id: resourceId
        // });
        this.updateDriveShiftTagExceptions(this.linkedDriveDetails.driveWrapper);   
        this.sumUpParentJobData(this.isJobPinned ? parentJob : job);     
        if(job.assetType === ASSET_TYPE.VEHICLE) {
            this.updateDriverJobs(this.linkedDriveDetails.driveWrapper);
        }
        this.updateStyleResource();
    }

    updateStyleResource() {
        let driveShifts = this.linkedDriveDetails ? (this.linkedDriveDetails.driveWrapper.driveShifts || []) : [];
        const resourceAllocated = this.getListResourceAllocated(driveShifts);

        this.resources = this.resources.map(item => {
            const { style, draggable } = this.getResourceStyle(item, resourceAllocated)

            return {
                ...item,
                style: style,
                draggable: draggable
            }
        });
        this.handleFilter();
    }

    /* Process Data */ 
    buildResource(item) {
        const hasLinkedDrive = this.linkedDriveResourceMap[item.id];
        let driveShifts = this.linkedDriveDetails?.driveWrapper.driveShifts || [];
        let linkedDriveDates = this.linkedDriveDetails?.linkedDrive.drives.map(item => item.driveDate) || [];
        linkedDriveDates.sort();
        const firstDriveDate = linkedDriveDates[0]; 
        const lastDriveDate = linkedDriveDates[linkedDriveDates.length - 1];
        const resourceAllocated = this.getListResourceAllocated(driveShifts);

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
                        id: item.tag.id
                    }
                }), ['value'], ['asc'])
            }
        })
        resourceTagsDisplay = orderBy(resourceTagsDisplay, [(resourceTag) => {
            let orderList = ['Role', 'Certification', 'Physical Location Type', 'Drive Type', 'Asset Type', 'Mobile Type'];
            return orderList.findIndex(item => item.toLowerCase() === resourceTag.key.toLowerCase())
        }], ['asc']);

        const resourceHoursRecords = (item.resourceHoursRecords || []).filter(record => {
            return record.startDate <= lastDriveDate && record.endDate >= firstDriveDate;
        });

        const weeklyHoursArray = resourceHoursRecords.map(record => {
            const weeklyHoursInMinutes = record?.totalWorkingTime || 0;
            const weeklyHours = +(weeklyHoursInMinutes / 60).toFixed(2);

            return {
                label: DateTime.fromFormat(record.startDate, 'yyyy-MM-dd').toFormat('MM/dd/yyyy'),
                resourceHoursRecord: record,
                weeklyHoursInMinutes,
                weeklyHours
            }
        });

        const { style, draggable } = this.getResourceStyle(item, resourceAllocated)

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
            weeklyHoursArray: weeklyHoursArray,
            resourceHoursRecords: resourceHoursRecords, 
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
            icon: this.getResourceIcon(item)
        }
    }
    buildResources(result) {
        const res = result.map(item => {
            return this.buildResource(item);
        })

        this.resourceTagsOption = uniqWith(this.resourceTagsOption, isEqual)
        return res;
    }

    buildLinkedDrives = (linkedDrive, allResources = []) => {
        const mergeJobs = (oldJobs = [], newJobs = [], drive) => {
            newJobs.forEach((newJob) => {
                newJob.drive = {
                    projectedRegisteredDonors: drive.projectedRegisteredDonors
                };
                const oldJob = oldJobs.find(item => {
                    if (newJob.resourceRole) {
                        return item.resourceRole === newJob.resourceRole;
                    } else if (newJob.assetType) {
                        return item.assetType === newJob.assetType;
                    }
                    return false;
                });
                if(oldJob) {
                    oldJob.childJobs.push(newJob);
                } else {
                    let temp = cloneDeep(newJob);
                    temp.id = uniqueId('parent_job_');
                    temp.key = temp.id;
                    if(newJob.id.startsWith('drivercdl')) {
                        temp.id = temp.key = 'drivercdl' + temp.id;
                    }

                    if(newJob.id.startsWith('driverdot')) {
                        temp.id = temp.key = 'driverdot' + temp.id;
                    }
                    temp.childJobs = [newJob];
                    oldJobs.push(temp);
                }
            });

            return oldJobs;
        };

        const mergeDriveShifts = (linkedDrives, driveShiftIndex) => {
            let parentDriveShift;
            if(linkedDrives[0].driveShifts.length - 1 > driveShiftIndex);

            let driveShiftJobs = [];
            linkedDrives.forEach(drive => {
                if(driveShiftIndex > drive.driveShifts.length - 1) return;
                if(!parentDriveShift) {
                    parentDriveShift = cloneDeep(drive.driveShifts[driveShiftIndex]);
                    parentDriveShift.id = uniqueId('parent_drive_shift_');
                    parentDriveShift.key = parentDriveShift.id;
                    parentDriveShift.childDriveShifts = [];
                }
                
                parentDriveShift.childDriveShifts.push(drive.driveShifts[driveShiftIndex]);
                driveShiftJobs = mergeJobs(driveShiftJobs, drive.driveShifts[driveShiftIndex].jobs, drive);
            });

            parentDriveShift.jobs = driveShiftJobs.map(job => {
                job.childJobs = job.childJobs.map(childJob => {
                    return this.buildJob(childJob, allResources);
                });

                return job;
            });

            return parentDriveShift;
        }

        //merge linked drives into 1
        let linkedDriveWraper = {
            linkedDrive: linkedDrive,
            driveWrapper: {
                ...linkedDrive.drives[0],
                driveShifts: []
            }
        };

        let maxNumberOfDriveShifts = 0;
        linkedDrive.drives.forEach(drive => {
            if(drive.driveShifts.length > maxNumberOfDriveShifts) maxNumberOfDriveShifts = drive.driveShifts.length;
        });

        for(let i = 0; i < maxNumberOfDriveShifts; i++) {
            linkedDriveWraper.driveWrapper.driveShifts.push(mergeDriveShifts(linkedDrive.drives, i));
        }

        linkedDriveWraper.driveWrapper = this.buildDrive(linkedDriveWraper.driveWrapper, allResources);
        return linkedDriveWraper;
    }

    buildJob(job, allResources = []) {
        let jobTag = (job.jobTags || []).find(jobTag => {
            return jobTag.tag && jobTag.tag.name === (job.resourceRole || job.assetType);
        })
        let jobPriority = jobTag ? jobTag.tag.priority : Number.MAX_SAFE_INTEGER;
        let jobAllocations = job.jobAllocations;
        const isParentJob = job.id.includes('parent_job_');

        let tempJob = {
            ...job,
            key: job.key,
            jobUrl: (job.id && !job.id.includes('temp_job_')) ? ('/' + job.id
                .replace('driverdot', '')
                .replace('drivercdl', '')) : null,
            originalQuantity: job.quantity,
            jobPriority: jobPriority,
            isParentJob: isParentJob,
            isShown: this.allocateAssetsOnly ? job.assetType : (job.assetType || job.resourceRole),
            isVehicleJob: job.assetType === TYPE_RESOURCE.VEHICLE,
            class: classNames('hco-job-header slds-grid job-item', {
                'is-sub-job': job.isSubJob
            }),
            resourceRole: job.resourceRole,
            resourceRoleText: compact([job.resourceRole, job.dualRole]).join('/'),
            jobTagsStr: this.buildJobTagString(job.jobTags || []),
            jobAllocations: jobAllocations && jobAllocations.map(itemJa => {
                const posAl = this.listPossibleAllocations.find(itemEx => itemEx.resourceId == itemJa.resourceId && itemEx.jobId == itemJa.jobId && !itemEx.isAvailable) || null
                const exceptionLog = posAl && posAl.exceptionLog.length > 0 && posAl.exceptionLog || [];
                const resource = allResources.find(item => item.id === itemJa.resourceId);
                return {
                    ...itemJa,
                    id: itemJa.id,
                    jobId: itemJa.jobId,
                    additionalRolesString: (itemJa.additionalRoles || []).join(', '),
                    isDeleted: itemJa.status === JOB_ALLOCATION_STATUS.DELETED,
                    icon: this.getResourceIcon(itemJa.resource),
                    timezoneSidId: this.timezoneSidId,
                    resource: this.buildResource(resource || itemJa.resource),
                    resourceId: itemJa.resourceId,
                    exceptionLog: isParentJob ? itemJa.exceptionLog : exceptionLog,
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

        if(isParentJob) {
            this.sumUpParentJobData(tempJob);
        }
        this.sumUpJobData(tempJob);
        return tempJob;
    }

    buildDrive(drive, allResources = []) {
        this.timezoneSidId = drive && drive.driveSite && drive.driveSite.timezoneSidId;

        let driveDetail = {
            ...drive,
            location: drive && drive.driveSite && drive.driveSite.name,
        };

        driveDetail.driveShifts = drive && drive.driveShifts.map((item, index) => {
            const jobs = item.jobs.map(job => {
                return this.buildJob(job, allResources);
            });

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

    buildPossibleAllocations(possibleAllocations = []) {
        let mapResourceJobPossibleAllocations = groupBy(possibleAllocations, 'resourceId');
        Object.keys(mapResourceJobPossibleAllocations).forEach(resourceId => {
            let mapAvailablePossibleAllocations = {};
            let mapUnavailablePossibleAllocations = {};

            mapResourceJobPossibleAllocations[resourceId].forEach(possibleAllocation => {
                if(possibleAllocation.isAvailable) {
                    mapAvailablePossibleAllocations[possibleAllocation.jobId] = possibleAllocation;
                } else {
                    mapUnavailablePossibleAllocations[possibleAllocation.jobId] = possibleAllocation;
                }
            });

            mapResourceJobPossibleAllocations[resourceId] = {
                mapAvailablePossibleAllocations,
                mapUnavailablePossibleAllocations
            }
        });

        return {
            possibleAllocations,
            mapResourceJobPossibleAllocations
        };
    }

    /* Drag & Drop */
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
        //TODO: slow performance
        // listjobEl.forEach(el => {
        //     const jobId = el.dataset.id;
        //     const [job, driveShift] = this.getJobById(jobId);

        //     const clonedDriveWrapper = this.cloneDrive(this.linkedDriveDetails.driveWrapper);            
        //     this.validateExceptions({
        //         resourceId: resourceId,
        //         resource: resourceDetail,
        //         job: job,
        //         jobId: jobId
        //     }, false, clonedDriveWrapper);
        // });

        listjobEl.forEach(el => {
            const jobId = el.dataset.id;
            const [job, driveShift] = this.getJobById(jobId);

            if((resourceDetail.resourceType == TYPE_RESOURCE.RESOURCE && job.resourceRole) || (resourceDetail.assetType && resourceDetail.assetType == job.assetType)){
                const isResourceAllocated = this.isResourceAllocatedToDriveShift(resourceDetail, driveShift);
                if(!isResourceAllocated && !el.classList.contains('job-disabled') && !el.classList.contains('job-hover-disabled')) {
                    const isAvailable = this.isResourceAvailableForJob(resourceDetail, job, !this.isJobPinned);
                    if (isAvailable === true) {
                        el.classList.add('hco-job-droppable_hover');
                    } else if (isAvailable === false) {
                        el.classList.add('hco-job-droppable-warning_hover');
                    }
                }
            } else {
                el.classList.add('job-hover-disabled');
            }
        });
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
        this.dragSrcEl.style.opacity = 1;
        for (var element = e.target; element; element = element.parentNode) {
            if (element.classList && element.classList.contains('job-item')) {
                jobItemEl = element;
                break;
            }
        }
        const {id} = jobItemEl && jobItemEl.dataset;
        if (id && !jobItemEl.classList.contains('job-disabled') && !jobItemEl.classList.contains('job-hover-disabled') && (jobItemEl.classList.contains('job-hover_warning') || jobItemEl.classList.contains('job-hover'))) {
            this.allocate(e.dataTransfer.getData('resourceId'), id)
        }
        return false;
    }

    handleDragEnd(e) {
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

    /* Actions */
    changeTab = (event) => {
        const newTab = event.currentTarget.dataset['value'];
        this.activeTab = newTab;
        this.buildException();
    }
    onClickPin(event) {
        this.radioPinValue = LIST_PINNED.RECOMMENDATED;
        const jobId = event.currentTarget.dataset.id;
        let [job, shiftTemp, jobIndexTemp, drive, parentJob] = this.getJobById(jobId);

        this.resourceSort = this.resourceSort || {
            sortBy: 'name',
            sortDirection: 'asc'
        }

        this.jobIdPin = jobId;
        this.pinnedJobWrapper = {
            job: job,
            name: job.resourceRoleText || job.assetType,
            childJobWrappers: job.childJobs.map(childJob => {
                return {
                    key: childJob.key,
                    selected: true,
                    job: childJob
                }
            })
        };

        const clonedDriveWrapper = this.cloneDrive(this.linkedDriveDetails.driveWrapper);
        this.resources.forEach(resource => {
            this.validateExceptions({
                resource: resource,
                resourceId: resource.id,
                job: job,
                jobId: job.id
            }, false, clonedDriveWrapper);
        })
        
        this.updateStyleResource();
    }
    onClickUnpin() {
        this.jobIdPin = null;
        this.radioPinValue = LIST_PINNED.RECOMMENDATED;
        this.resourceSort = this.resourceSort || {
            sortBy: 'name',
            sortDirection: 'asc'
        }
        // let driveShifts = this.driveDetail1 ? (this.driveDetail1.driveShifts || []) : [];
        // each([...driveShifts], item => {
        //     item.jobs.map(itemSub => {
        //         itemSub.isPin = false;
        //         itemSub.class = classNames('hco-job-header slds-grid job-item', {
        //             'is-sub-job': itemSub.isSubJob
        //         })
        //     });
        // })
        // const listjobEl = this.template.querySelectorAll('.job-item');
        // listjobEl.forEach(el => {
        //     el.classList.remove('job-disabled');
        // })

        this.pinnedJobWrapper = {
            childJobWrappers: []
        };
        this.updateStyleResource();
    }
    onClickIncludeFromOptimizer(event) {
        const jobId = event.currentTarget.dataset.id;
        let [job, driveShift, jobIndex, drive, parentJob] = this.getJobById(jobId);

        if(!job) return;

        job.excludeFromOptimizer = false
        if (!this.isJobPinned) {
            job.childJobs.forEach(childJob => {
                childJob.excludeFromOptimizer = false;
            })
        } else {
            this.sumUpParentJobData(parentJob); 
        }
    }
    onClickExcludeFromOptimizer(event) {
        const jobId = event.currentTarget.dataset.id;
        let [job, driveShift, jobIndex, drive, parentJob] = this.getJobById(jobId);

        if(!job) return;

        job.excludeFromOptimizer = true
        if (!this.isJobPinned) {
            job.childJobs.forEach(childJob => {
                childJob.excludeFromOptimizer = true;
            })
        } else {
            this.sumUpParentJobData(parentJob); 
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
                            this.unallocate(event.detail.record);
                        }
                    }
                });
            }
            else {
                this.unallocate(event.detail.record);
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
        const jobId = detail.jobId;
        let [job, driveShift, jobIndex, drive, parentJob] = this.getJobById(jobId);
        let jobsToLocked = [job];
        if(this.isJobPinned) {
            jobsToLocked = [job];
        } else {
            jobsToLocked = job.childJobs || [];
        }

        jobsToLocked.forEach(job => {
            let ja = find(this.getJobAllocations(job), item => item.resourceId == detail.resourceId)
            if(ja) {
                if (action === 'lock') {
                    ja.locked = !detail.locked;
                } else if (action === 'guard') {
                    ja.guarded = !detail.guarded;
                }
                ja.isLocked = ja.locked || ja.guarded;
            }
        })

        this.sumUpParentJobData(this.isJobPinned ? parentJob :job);
    }
    handleChildJobSelected(event) {
        const key = event.currentTarget.dataset['key'];
        const job = this.pinnedJobWrapper.childJobWrappers.find(item => item.key === key);
        if(!job) return;

        job.selected = !job.selected;
    }
    checkAvailabilitySelectedJobs() {
        this.showLoading();
        setTimeout(() => {
            this.handleFilter();
            this.hideLoading();
        }, 1000);
    }
    handleClose() {
        this.initialized = false;
        this.onClickUnpin();
        this.dispatchEvent(new CustomEvent('close', {
            detail: {

            }
        }));
    }

    /* Exceptions */
    updateDriveShiftTagExceptions(driveWrapper) {
        if(!driveWrapper) return;

        (driveWrapper.driveShifts || []).forEach(parentDriveShift => {
            parentDriveShift.driveShiftTagExceptions = [];

            parentDriveShift.childDriveShifts.forEach(driveShift => {
                driveShift.driveShiftTagExceptions = [];

                if(!driveShift || !driveShift.driveShiftTags || !driveShift.driveShiftTags.length) return;

                const driveShiftTags = driveShift.driveShiftTags;

                let allDriveShiftAllocations = [];
                (parentDriveShift.jobs || []).forEach(parentJob => {
                    parentJob.childJobs.forEach(childJob => {
                        if(childJob.driveShiftId !== driveShift.id) return;
                        const jobAllocations = this.getJobAllocations(childJob);
                        allDriveShiftAllocations = allDriveShiftAllocations.concat(jobAllocations);
                    })
                })

                const allResources = allDriveShiftAllocations.map(jobAllocation => jobAllocation.resource);
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

                if(exceptions.length > 0) {
                    driveShift.driveShiftTagExceptions = exceptions;

                    parentDriveShift.driveShiftTagExceptions.push({
                        driveShift: driveShift,
                        exceptions: exceptions
                    })
                }
            })
        });
    }

    validateExceptions(newJobAllocation, isAllocated = false, driveWrapper = this.linkedDriveDetails.driveWrapper) {
        const isSameWeek = (resourceHoursRecord, job) => {
            if(!resourceHoursRecord) return false;
            return resourceHoursRecord.startDate <= job.startDate && job.startDate <= resourceHoursRecord.endDate;
        };
        if(!newJobAllocation) return;

        const isResource = !newJobAllocation.resourceId;
        const resource = isResource ? newJobAllocation : newJobAllocation.resource;
        if(resource.resourceType !== RESOURCE_TYPE.PERSON || !resource.resourceHoursRecords.length) return;

        if(!isResource) {
            const currentPossibleAllocation = this.listPossibleAllocations.find(item => item.resourceId === newJobAllocation.resourceId && item.jobId === newJobAllocation.jobId);
            if(!newJobAllocation.exceptionLog) {
                newJobAllocation.exceptionLog = currentPossibleAllocation ? currentPossibleAllocation.exceptionLog : [];
            }
        }
        
        let allDriveShifts = driveWrapper.driveShifts;

        //try to allocate resource to temp drive
        if(!isAllocated) {
            allDriveShifts.forEach(driveShift => {
                driveShift.jobs.forEach(parentJob => {
                    parentJob.childJobs.forEach(job => {
                        if(newJobAllocation.jobId.includes('parent_job_')) {
                            if(parentJob.id !== newJobAllocation.jobId) return;
                        } else {
                            if(job.id !== newJobAllocation.jobId) return;
                        }

                        if(job.id === newJobAllocation.jobId && newJobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED) {
                            if(!job.jobAllocations.find(jobAllocation => jobAllocation.resourceId === newJobAllocation.resourceId && jobAllocation.status !== JOB_ALLOCATION_STATUS.DELETED)) {
                                job.jobAllocations.push(newJobAllocation);
                            }
                        } 
                    })
                })
            });
        }
       
        resource.resourceHoursRecords.forEach(record => {
            const resourceMaxHoursPerWeekInMinutes = (resource.maxHoursPerWeek || 0) * 60;
            const resourceHoursRecord = record;
            const currentWeeklyHoursInMinutes = resourceHoursRecord?.totalWorkingTime || 0;
            let allAllocationsNeedToUpdateExceptions = [];
            let totalMinutesOfOldAllocationsDeleted = 0;
            let totalMinutesOfNewAllocations = 0;

            allDriveShifts.forEach(driveShift => {
                driveShift.jobs.forEach(parentJob => {
                    parentJob.childJobs.forEach(job => {
                        if(!isSameWeek(resourceHoursRecord, job)) {
                            return;
                        }
    
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
            });
    
            const weeklyHoursInMinutes = currentWeeklyHoursInMinutes + totalMinutesOfNewAllocations - totalMinutesOfOldAllocationsDeleted;
            const allocationExceptionLogMap = {};
            if(weeklyHoursInMinutes > resourceMaxHoursPerWeekInMinutes) {
                let exceptionText = this.availator.getExceptionTextByCode('MAXIMUM_WEEKLY_HOURS_VIOLATION')
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
                let jobList = [];

                each(itemDriveShifts.jobs, jobItem => {
                    let childJobs = [];

                    each(jobItem.childJobs, childJobItem => {
                        let jobAllocations = this.getJobAllocations(childJobItem);
                        let exceptionLog = [];
                        each(jobAllocations, jaItem => {
                            exceptionLog = exceptionLog.concat((jaItem.exceptionLog || []).filter(ex => ex.status != 'Resolved').map(exception => ({
                                exception: exception.exception,
                                exceptionCode: exception.exceptionCode,
                                id: exception.id,
                                key: uniqueId('exception_ja'),
                                resource: jaItem.resource,
                                icon: this.getResourceIcon(jaItem.resource),
                                isSelected:  false
                            })))
                        })

                        if(exceptionLog.length > 0) {
                            childJobs.push({
                                job: childJobItem,
                                exceptionLog: exceptionLog,
                                key: uniqueId('exception_child_job'),
                            })
                        }
                    })

                    if(childJobs.length > 0) {
                        jobList.push({
                            isSelected: false,
                            job: jobItem.resourceRole || jobItem.assetType,
                            id: jobItem.id,
                            key: uniqueId('exception_job'),
                            childJobs: childJobs
                        })
                    }
                })
                
                if (jobList.length > 0) {
                    result.driveShifts.push({
                        isSelected: false,
                        driveShift: itemDriveShifts.name,
                        key: uniqueId('exception_driveShift'),
                        id: itemDriveShifts.id,
                        jobs: jobList
                    })
                }
            })
            return result;
        }

        if(this.activeTab !== TABS.EXCEPTIONS){
            return;
        }

        this.dataException = []
        const ds1 = _buildExceptionData(this.linkedDriveDetails.driveWrapper);
        if (ds1 && ds1.driveShifts.length > 0) {
            this.dataException.push(ds1);
        }
    }

    /* Handle Save */
    buildSaveParams() {
        let driveUpdate = [this.linkedDriveDetails.driveWrapper].map(drive => {
            return this.mapDataToServer(drive);
        });
        
        let jobsToSave = [];
        driveUpdate.forEach(drive => {
            drive.driveShifts.forEach(driveShift => {
                driveShift.jobs.forEach(parentJob => {
                    parentJob.childJobs.forEach(job => {
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
            })
        });

        return {
            driveUpdate,
            jobsToSave
        }
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

    handleSave() {
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

            this.initialized = false;
        })
        .catch(error => this.exceptionHandler(error))
        .finally(() => {
            this.hideLoading();
        });
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

    mapDataToServer(drive) {
        let driveToSave = cloneDeep(drive);

        let {
            noOfDotVehicles,
            noOfCdlVehicles
        } = this.getNumberOfDotAndCdlDrivers(drive);

        driveToSave.driveShifts.forEach(driveShift => {
            let parentDriverJob = driveShift.jobs.find(job => this.driveHelper.isDriverJob(job));

            if(parentDriverJob) {
                parentDriverJob.childJobs.forEach((driverJob, driverJobIndex) => {
                    driveShift.jobs.forEach(parentJob => {
                        if (noOfDotVehicles > 0 && parentJob.id && parentJob.id.startsWith('driverdot')) {
                            const job = parentJob.childJobs[driverJobIndex];
                            if(!job) return;
                            
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
                        if (noOfCdlVehicles > 0 && parentJob.id && parentJob.id.startsWith('drivercdl')) {
                            const job = parentJob.childJobs[driverJobIndex];
                            if(!job) return;
                            
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
                })
            }
            
            //remove all sub jobs 
            remove(driveShift.jobs, job => job.isSubJob);
        })

        return driveToSave;
    }

    /* Fetch */
    retrieveLinkedDriveResources() {
        this.linkedDriveResourceMap = {};
        return;
    }

    retrieveLinkedDrive(recordId) {
        const service = new linkedDrivesService();
        let queryModel = new linkedDrivesQueryModel();
        queryModel.recordIds = [recordId];
        return service.query(queryModel)
            .then(([linkedDrive]) => {
                this.linkedDrive = linkedDrive;
            })
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
                    if (key === 'Driving roles') {
                        this.drivingRoleGroup = this.resourceRoleGroups[key];
                    }
                });
            })
        });        
    }

    /* Resource Filters */
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
    handleFilter() {
        const filter = this.resourceFilters;
        
        this.resourcesFilterList = [...this.resources];
        if(!this.isJobPinned){
            if(this.radioTypeValue == TYPE_RESOURCE.RESOURCE){
                this.resourcesFilterList = this.resourcesFilterList.filter(item => item.resourceType == TYPE_RESOURCE.RESOURCE)
            } else if(this.radioTypeValue == TYPE_RESOURCE.EQUIPMENT){
                this.resourcesFilterList = this.resourcesFilterList.filter(item => item.assetType == TYPE_RESOURCE.EQUIPMENT)
            } else {
                this.resourcesFilterList = this.resourcesFilterList.filter(item => item.assetType == TYPE_RESOURCE.VEHICLE)
            }
        }

        if (filter && typeof (filter) == 'object') {
            if (this.isJobPinned) {
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

            if (filter.weeklyHoursRange) {
                this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                    if(item.resourceType !== TYPE_RESOURCE.RESOURCE) return true;

                    const allValid = !item.weeklyHoursArray.find(item => {
                        return !(item.weeklyHours >= filter.weeklyHoursRange.start && item.weeklyHours <= filter.weeklyHoursRange.end);
                    });

                    return allValid;
                });
            }
        }

        if (this.isJobPinned) {
            let [job, driveShift, jobIndex, drive, parentJob] = this.getJobById(this.jobIdPin);

            this.resourcesFilterList = this.resourcesFilterList.filter(item => {
                if((item.resourceType == TYPE_RESOURCE.RESOURCE && job.resourceRole) || (item.assetType && item.assetType == job.assetType)){
                    const selectedChildJobs = this.selectedChildJobs;
                    if(!selectedChildJobs.length) return false;

                    let availableForAllChildJobs = true;
                    let atLeastValidFor1ChildJob = false;

                    selectedChildJobs.forEach(childJob => {
                        if(!this.mapResourceJobPossibleAllocations[item.id]?.mapAvailablePossibleAllocations?.[childJob.id]) {
                            availableForAllChildJobs = false;
                        }
        
                        if(this.mapResourceJobPossibleAllocations[item.id]?.mapUnavailablePossibleAllocations?.[childJob.id] || 
                            this.mapResourceJobPossibleAllocations[item.id]?.mapAvailablePossibleAllocations?.[childJob.id]) {
                            atLeastValidFor1ChildJob = true;
                        }
                    });
                    
                    //TODO
                    // item.isCallOut = item.callOutJobIds.includes(this.jobIdPin);
                    
                    if(this.isRecommendations) {
                        return availableForAllChildJobs;
                    } else {
                        return atLeastValidFor1ChildJob;
                    }
                }
                return false;
            })
        }
     
        this.handleSort();
    }
    handleSort() {
        const resourceSort = this.resourceSort;
        if (resourceSort && resourceSort.sortBy && resourceSort.sortDirection) {
            this.resourcesFilterList = orderBy(this.resourcesFilterList, [resourceSort.sortBy], [resourceSort.sortDirection]);
        }
    }

    /* Utils */
    getNumberOfDotAndCdlDrivers(drive) {
        let result = {
            noOfDotVehicles: 0,
            noOfCdlVehicles: 0
        }
        if(!drive || !drive.driveShifts || !drive.driveShifts.length) return result;

        const vehicleJob = drive.driveShifts[0].jobs.find(job => job.assetType === ASSET_TYPE.VEHICLE);
        if(!vehicleJob) return result;
        
        let jobAllocations = this.getJobAllocations(vehicleJob);
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

    getResourceStyle(resource, resourceAllocated = [], resourceAllocated2 = []) {
        const allocatedToDrive1 = resourceAllocated.find(item => item.resourceId === resource.id);
        const allocatedToDrive2 = this.driveId2 ? resourceAllocated2.find(item => item.resourceId === resource.id) : null;
        const allocatedToPinnedJob = this.isJobPinned && (
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
        let parentJob = null;
        let shiftTemp = null;
        let jobIndexTemp = 0;
        let driveShifts = this.linkedDriveDetails ? (this.linkedDriveDetails.driveWrapper.driveShifts || []) : [];
        let drive = null;

        each([...driveShifts], (shiftItem, shiftIndex) => {
            each(shiftItem.jobs, (jobItem, jobIndex) => {
                if (jobItem.id == jobId) {
                    result = jobItem;
                    shiftTemp = shiftItem;
                    jobIndexTemp = jobIndex;
                    drive = this.linkedDriveDetails.driveWrapper;
                    return;
                }

                if(this.isJobPinned) {
                    const temp = (jobItem.childJobs || []).find((childJobItem) => {
                        return childJobItem.id === jobId;
                    })

                    if(temp) {
                        shiftTemp = shiftItem;
                        jobIndexTemp = jobIndex;
                        drive = this.linkedDriveDetails.driveWrapper;
                        result = temp;
                        parentJob = jobItem;
                        return;
                    }
                }
            })
        })
        
        return [result, shiftTemp, jobIndexTemp, drive, parentJob];
    }
    getListJobAvailable(resourceId) {
        return this.listPossibleAllocations.filter(item => (item.resourceId == resourceId && item.isAvailable)).map(item => {
            return item.jobId
        })
    }
    getListJobUnavailable(resourceId) {
        return this.listPossibleAllocations.filter(item => (item.resourceId == resourceId && (item.isAvailable == false))).map(item => {
            return item.jobId
        })
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
    isResourceAvailableForJob(resource, job, isParentJob) {
        if(isParentJob) {
            let availableForAllChildJobs = true;
            let atLeastValidFor1ChildJob = false;
            job.childJobs.forEach(childJob => {
                if(!this.mapResourceJobPossibleAllocations[resource.id]?.mapAvailablePossibleAllocations?.[childJob.id]) {
                    availableForAllChildJobs = false;
                }

                if(this.mapResourceJobPossibleAllocations[resource.id]?.mapAvailablePossibleAllocations?.[childJob.id] ||
                    this.mapResourceJobPossibleAllocations[resource.id]?.mapUnavailablePossibleAllocations?.[childJob.id]) {
                    atLeastValidFor1ChildJob = true;
                }
            });

            if(availableForAllChildJobs) {
                return true;
            } else if (atLeastValidFor1ChildJob) {
                return false;
            } else {
                return undefined;
            }
        } else {
            if(this.mapResourceJobPossibleAllocations[resource.id]?.mapAvailablePossibleAllocations?.[job.id]) {
                return true;
            } else if(this.mapResourceJobPossibleAllocations[resource.id]?.mapUnavailablePossibleAllocations?.[job.id]) {
                return false;
            } else {
                return undefined;
            }

        }
    }
    isResourceAllocatedToDriveShift(resource, driveShift) {
        return (driveShift.jobs || []).find(job => {
            let jobAllocations = this.getJobAllocations(job);
            return (jobAllocations || []).find(jobAllocation => jobAllocation.resourceId === resource.id);
        });
    }
    getDefaultJobAllocationTimes(job) {
        if(!job) return {
            start: null,
            end: null
        }

        return {
            start: job.start,
            end: job.finish
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
                    jobAllocation.start = job.start;
                    jobAllocation.end = job.finish;
                });
            });
            return;
        }

        Object.keys(allocationDriveShiftMap).forEach((driveShiftKey, driveShiftIndex) => {
            const allocations = allocationDriveShiftMap[driveShiftKey].allocations;
            const job = allocationDriveShiftMap[driveShiftKey].job;
            allocations.forEach(jobAllocation => {
                if(driveShiftIndex === 0) {
                    //first shift
                    const nextDriveShift = drive.driveShifts[driveShiftIndex + 1];
                    jobAllocation.start = job.start;
                    jobAllocation.end = this.driveHelper.newDateTime(nextDriveShift.driveDate, nextDriveShift.startTime, this.timezoneSidId).toISOString();
                } else if(driveShiftIndex === Object.keys(allocationDriveShiftMap).length - 1) {
                    const previousDriveShift = drive.driveShifts[driveShiftIndex -1];
                    jobAllocation.start = this.driveHelper.newDateTime(previousDriveShift.driveDate, previousDriveShift.endTime, this.timezoneSidId).toISOString();
                    jobAllocation.end = job.finish;
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

    sumUpParentJobData(parentJob) {
        //quantity
        let quantity = 0;
        parentJob.childJobs.forEach(childJob => {
            if(childJob.quantity > quantity) {
                quantity = childJob.quantity;
            }
        });
        parentJob.quantity = quantity;

        //allocations
        let jobAllocations = [];
        parentJob.childJobs.forEach(childJob => {
            const childJobAllocations = this.getJobAllocations(childJob);
            childJobAllocations.forEach(jobAllocation => {
                if(!jobAllocations.find(item => item.resourceId === jobAllocation.resourceId)) {
                    jobAllocations.push({
                        ...jobAllocation,
                        jobId: parentJob.id
                    });
                }
            })
        });
        parentJob.jobAllocations = jobAllocations;

        //job allocation locked
        parentJob.jobAllocations.forEach(parentJobAllocation => {
            let allChildJobAllocationsLocked = true;
            parentJob.childJobs.forEach(childJob => {
                const childJobAllocations = this.getJobAllocations(childJob);
                const childJobAllocation = childJobAllocations.find(item => item.resourceId === parentJobAllocation.resourceId);
                if(childJobAllocation && !childJobAllocation.isLocked) {
                    allChildJobAllocationsLocked = false;
                }
            });

            parentJobAllocation.locked = allChildJobAllocationsLocked;
            parentJobAllocation.isLocked = parentJobAllocation.locked || parentJobAllocation.guarded;
        });

        //excludeFromOptimizer 
        let allChildJobsExcludedFromOptimizer = true;
        parentJob.childJobs.forEach(childJob => { 
            if(!childJob.excludeFromOptimizer) {
                allChildJobsExcludedFromOptimizer = false;
            }
        });
        parentJob.excludeFromOptimizer = allChildJobsExcludedFromOptimizer;

        //exceptions
        parentJob.jobAllocations.forEach(parentJobAllocation => {
            parentJobAllocation.exceptionLog = [];
            parentJob.childJobs.forEach(childJob => {
                const childJobAllocations = this.getJobAllocations(childJob);
                const childJobAllocation = childJobAllocations.find(item => item.resourceId === parentJobAllocation.resourceId);
                if(childJobAllocation) {
                    parentJobAllocation.exceptionLog = parentJobAllocation.exceptionLog.concat((childJobAllocation.exceptionLog || []).map(item => {
                        return {
                            ...item,
                            jobId: childJob.id,
                            job: childJob
                        }
                    }));
                }
            });

            const mapExceptionLogByJobId = groupBy(parentJobAllocation.exceptionLog, 'jobId');
            parentJobAllocation.exceptionLogToDisplay = Object.keys(mapExceptionLogByJobId).map(jobId => {
                return {
                    key: uniqueId(),
                    job: mapExceptionLogByJobId[jobId][0].job,
                    exceptionLog: mapExceptionLogByJobId[jobId]
                }
            })
        });

        this.sumUpJobData(parentJob);
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

        return job;
    }
    formatTime(time) {
        return DateTime.fromFormat(time, 'HH:mm:ss.SSS').toFormat('h:mm a');
    }
    cloneDrive = (drive) => {
        return JSON.parse(JSON.stringify(drive));
    };
    convertHours(minutes) {
        minutes = Math.floor(minutes);
        const min = Math.round(minutes % 60)
        const hours = Math.round(Math.floor(minutes / 60))
        return `${hours}h ${min}m`
    }
    buildJobTagString(jobTags = []) {
        return orderBy(
            jobTags.map(item => item.tag.name),
            [item => item],
            ['asc']
        ).join(', ');
    }

    /* Drive Shift Tags */
    toggleDriveShiftTagsSection(event) {
        const shiftKey = event.currentTarget.dataset['value'];
        let driveShifts = this.linkedDriveDetails ? (this.linkedDriveDetails.driveWrapper.driveShifts || []) : [];
        let driveShift = driveShifts.find(item => item.key === shiftKey);
        if(!driveShift) return;

        driveShift.driveShftTagsSesctionExpanded = !driveShift.driveShftTagsSesctionExpanded;
    }
    
    /* Dispatch Drive modal */
    showDispatchDriveModal() {
        let drives = this.linkedDrive.drives;
        this.dispatchDriveModalData = {
            isOpen: true,
            drives: drives
        };
    }

    hideDispatchDriveModal(event) {
        const result = event.detail.result;
        this.dispatchDriveModalData = {};
    }

    /* Call out modal */
    handleShowCallOutModal(detail) {
        this.callOutModalData = {
            isOpen: true,
            jobId: detail.jobId,
            jobAllocationId: detail.id
        }
    }

    handleShowCallOutModal(detail) {
        const [ job ] = this.getJobById(detail.jobId);
        const resourceDetail = this.getResourceById(detail.resourceId);
        let durationHours = (detail.duration/60).toFixed(2);
        let callOutDuration = durationHours > resourceDetail.dailyTimeOffHours ? resourceDetail.dailyTimeOffHours : durationHours;
        this.callOutModalData = {
            isOpen: true,
            jobId: detail.jobId,
            jobAllocationId: detail.id,
            driveDate: job.driveDate,
            resourceId: detail.resourceId,
            duration: callOutDuration
        }
    }

    handleCloseCallOutModal() {
        this.callOutModalData = {};
    }

    handleSaveCallOutModal(event) {
        const { jobAllocationId, jobId } = this.callOutModalData;
        const [ job ] = this.getJobById(jobId);
        const [driveShift, indexDriveShift] = this.getDriveShiftById(job.driveShiftId)
        const { callOutType , callOutReason, callOutNotes, callOutReceivedDateTime } = event.detail;
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
          callOutReceivedDateTime: callOutReceivedDateTime
        };
        
        this.showLoading();
        let service = new resourceService();
        service.saveCallOut({
          request: params
        }).then(res => {
          this.dispatchEvent(new ShowToastEvent({
            message: 'Call out successfully.',
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
                this.availator.updateData(job, indexDriveShift);
                this.availator.setupDriverJobs();

                return this.availator.buildScheduledAllocations()
                .then((result) => {
                    if (result.possibleAllocations) {
                        const { possibleAllocations, mapResourceJobPossibleAllocations } = this.buildPossibleAllocations(result.possibleAllocations);
                        this.listPossibleAllocations = possibleAllocations;
                        this.mapResourceJobPossibleAllocations = mapResourceJobPossibleAllocations;
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
        let ja =  find(job.jobAllocations, item => item.id == jobAllocation.id)
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
}