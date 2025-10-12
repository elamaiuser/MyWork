import { LightningElement, track, api } from 'lwc';
import { dataService, resourceService, resourceQueryModel, driveService, driveQueryModel, activityService, activityQueryModel, jobService, jobQueryModel, activityResourceService, activityResourceQueryModel, sObjectType, jobAllocationService } from 'c/dataService';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getValueFromEvent, classNames } from 'c/slwcUtils';
import { orderBy, groupBy, uniqueId, compact } from 'c/lodash';
import searchTemplate from './search.html';
import selectEventTemplate from './selectEvent.html';
import selectAllocationTemplate from './selectAllocation.html';
import callOutTemplate from './callOut.html';
import selectResourceTemplate from './selectResource.html';
import USER_ID from "@salesforce/user/Id";
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { DateTime } from 'c/luxon';
import { DRIVE_STATUS, JOB_ALLOCATION_STATUS, RESOURCE_ROLE_GROUP, RESOURCE_TYPE } from 'c/slwcConstants';
import * as slwcAvailator from 'c/slwcAvailator';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from "c/slwcDateUtils";



const STEP = {
  SEARCH: 1,
  SELECT_EVENT: 2,
  SELECT_ALLOCATION: 3,
  REPLACE_RESOURCE: 4,
  CALL_OUT_FORM: 5,
}

const EVENT_TYPE = {
  ACTIVITY: 'Activity',
  DRIVE: 'Drive'
}

const STEP_SETTINGS = {
  [STEP.SEARCH]: {
    value: STEP.SEARCH,
    label: 'Search',
    validate: function(scope) {
      return scope.validateStepSearch();
    },
    init: function(scope) {
      return scope.initStepSearch();
    },
    render: searchTemplate
  },
  [STEP.SELECT_EVENT]: {
    value: STEP.SELECT_EVENT,
    label: 'Select Event',
    validate: function(scope) {
      return scope.validateStepSelectEvent();
    },
    init: function(scope) {
      return scope.initStepSelectEvent();
    },
    render: selectEventTemplate
  },
  [STEP.SELECT_ALLOCATION]: {
    value: STEP.SELECT_ALLOCATION,
    label: 'Select Allocation',
    validate: function(scope) {
      return scope.validateStepSelectAllocation();
    },
    init: function(scope) {
      return scope.initStepSelectAllocation();
    },
    render: selectAllocationTemplate
  },
  [STEP.CALL_OUT_FORM]: {
    value: STEP.CALL_OUT_FORM,
    label: 'Call Out',
    validate: function(scope) {
      return scope.validateStepCallOut();
    },
    init: function(scope) {
      return scope.initStepCallOut();
    },
    render: callOutTemplate
  },
  [STEP.REPLACE_RESOURCE]: {
    value: STEP.REPLACE_RESOURCE,
    label: 'Replacement',
    validate: function(scope) {
      return scope.validateStepReplaceResource();
    },
    init: function(scope) {
      return scope.initStepReplaceResource();
    },
    render: selectResourceTemplate
  },
}

export default class SlwcOnCallCallOutManagement extends LightningElement {
  @api fullScreen = false;

  @track showSpinner = false;
  @track confirmModalData = {};
  @track step = STEP.SEARCH;
  @track timezoneSidId = TIME_ZONE;

  @track filters = {};
  @track events = [];
  @track selectedEvent = null;
  
  @track allocations = [];
  @track selectedAllocationData = null;
  
  @track callOutData = null;
  
  @track resources = [];
  @track filteredResources = [];
  @track selectedResource = null;
  @track selectResourceFilters = {
    searchText: ''
  };
  
  get customClass() {
    return {
      modal: classNames('slds-modal slds-fade-in-open', {
        'full-screen': this.fullScreen
      }),
    }
  }

  get eventTypeOptions() {
    return [{
        value: EVENT_TYPE.DRIVE,
        label: EVENT_TYPE.DRIVE
    }, {
        value: EVENT_TYPE.ACTIVITY,
        label: EVENT_TYPE.ACTIVITY
    }]
  }

  get showDriveUfid() {
    return this.filters.eventType === EVENT_TYPE.DRIVE;
  }

  get nextButtonDisabled() {
    if(this.step === STEP.SELECT_EVENT) {
      if(!this.selectedEvent) return true;
    }

    if(this.step === STEP.SELECT_ALLOCATION) {
      if(!this.selectedAllocationData) return true;
    }

    if(this.step === STEP.REPLACE_RESOURCE) {
      if(this.isAllocateResourceMode && !this.selectedResource) return true;
    }

    return false;
  }

  get isAllocateResourceMode() {
    if(this.step !== STEP.REPLACE_RESOURCE) {
      return false;
    }

    return !this.selectedAllocationData.callOutModalData.resourceId;
  }

  render() {
    return STEP_SETTINGS[this.step].render;
  }

  connectedCallback() {
    this.init();
  }
  
  exceptionHandler = (error) => {
    this.dispatchEvent(new ShowToastEvent({
        message: error.message,
        variant: 'error',
        mode: 'dismissable',
    }));
  }

  showLoading = () => {
    this.showSpinner = true;
  };

  hideLoading = () => {
    this.showSpinner = false;
  };

  
  init() {
    this.showLoading();
    Promise.all([
      this.retrieveCustomSettings(),
      this.retrieveLoginUserResource()
    ])
    .then(([{resourceRoleGroups}, resource]) => {
      if(!resource) {
        this.showConfirmModal({
          mode: 'error',
          title: 'Error',
          message: 'This screen cannot be loaded as you do not have an Active Resource record associated. Please contact your administrator for assistance.',
          confirmBtnLabel: 'none',
          cancelBtnLabel: 'none'
        });

        return;
      }

      this.resourceRoleGroups = resourceRoleGroups;
      const isTeamSupervisor = this.isTeamSupervisor(resource, resourceRoleGroups);
      if(!isTeamSupervisor) {
        this.showConfirmModal({
          mode: 'error',
          title: 'Error',
          message: 'Only team supervisor resources can access this form.',
          confirmBtnLabel: 'none',
          cancelBtnLabel: 'none'
        });

        return;
      }

      this.initFilters();
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  initFilters() {
    const today = DateTime.fromObject({
      zone: TIME_ZONE
    }).toISODate();

    this.filters = {
      collectionOperation: null,
      eventType: EVENT_TYPE.DRIVE,
      eventDate: today,
      driveUfid: ''
    }
  }

  isTeamSupervisor(resource, resourceRoleGroups) {
    if(!resource || !resourceRoleGroups) return [];

    const teamSupervisorRoles = resourceRoleGroups['Supervisory roles'] || [];
    const resourceRoles = resource.roles ? resource.roles.split(';') : [];

    const hasAnyTeamSupervisorRole = resourceRoles.find(resourceRole => teamSupervisorRoles.includes(resourceRole));
    return !!hasAnyTeamSupervisorRole;
  }

  retrieveCustomSettings() {
    return Promise.resolve()
      .then(() => {
        let service = new dataService();
        return service.getCustomSettings({ settingKeys: ['resourceRoleGroups'] })
          .then((result) => {
            return {
              resourceRoleGroups: result.returnedData.resourceRoleGroups
            }
          })
      });
  }

  retrieveLoginUserResource() {
    let service = new resourceService();
    let query = new resourceQueryModel();
    query.userIds = [USER_ID];
    return service.query(query)
    .then(([resource]) => {
      return resource;
    })
  }

  handleBack(initAgain = false) {
    this.step = this.step - 1;

    if(initAgain === true) {
      this.showLoading();
      STEP_SETTINGS[this.step].init(this)
        .catch(error => this.exceptionHandler(error))
        .finally(this.hideLoading);
    }
  }

  handleNext(event, forceStep) {
    this.showLoading();
    STEP_SETTINGS[this.step].validate(this)
    .then(result => {
      if(!result) {
        return;
      }

      this.step = forceStep ?? (this.step + 1);
      return STEP_SETTINGS[this.step].init(this);
    })
    .catch(error => this.exceptionHandler(error))
    .finally(this.hideLoading);
  }

  handleFiltersChanged(event) {
    event.stopPropagation();

    if(event.detail && event.detail.selection) {
      this.filters[event.currentTarget.name] = event.detail.selection;
    } else {
      let value = getValueFromEvent(event);
      this.filters[event.currentTarget.name] = value;
    }
  }

  initStepSearch = () => {
    return Promise.resolve();
  }

  validateStepSearch = () => {
    return Promise.resolve()
    .then(() => {
      const allValid = [
        ...this.template.querySelectorAll('lightning-input'), 
        ...this.template.querySelectorAll('c-slwc-multi-picklist'),
        ...this.template.querySelectorAll('c-slwc-lookup'),
        ...this.template.querySelectorAll('lightning-radio-group')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

      return allValid;
    })
  }

  initStepSelectEvent = () => {
    //reset values
    this.events = [];
    this.selectedEvent = null;

    return Promise.resolve()
    .then(() => {
      if(this.filters.eventType === EVENT_TYPE.DRIVE) {
        let service = new driveService();
        let queryModel = new driveQueryModel();
        queryModel.ufid = this.filters.driveUfid;
        queryModel.collectionOpIds = this.filters.collectionOperation ? [this.filters.collectionOperation.id] : [];
        queryModel.startDate = this.filters.eventDate;
        queryModel.endDate = this.filters.eventDate;
        queryModel.statuses = [
          DRIVE_STATUS.SYSTEM_GENERATED,
          DRIVE_STATUS.TENTATIVE,
          DRIVE_STATUS.CONFIRMED
        ];
        return service.query(queryModel)
          .then((result = []) => {
            return result.map(item => {
              return {
                ...item,
                isDrive: true
              }
            })
          });
      } else {
        let service = new activityService();
        let queryModel = new activityQueryModel();
        queryModel.startDate = this.filters.eventDate;
        queryModel.endDate = this.filters.eventDate;
        queryModel.collectionOperationIds = this.filters.collectionOperation ? [this.filters.collectionOperation.id] : [];
        queryModel.isGroupActivity = true;
        return service.query(queryModel)
          .then((result = []) => {
            return result.map(item => {
              return {
                ...item,
                isGroupActivity: true
              }
            })
          });
      }
    })
    .then((result = []) => {
      this.events = orderBy(result, ['startDate', 'name'], ['asc', 'asc']);
    })
  }

  validateStepSelectEvent = () => {
    return Promise.resolve(!!this.selectedEvent);
  }

  initStepSelectAllocation = () => {
    //reset values
    this.allocationGroups = [];
    this.selectedAllocationData = null;

    return Promise.resolve()
    .then(() => {
      if(this.selectedEvent.isDrive) {
        let service = new jobService();
        let queryModel = new jobQueryModel();
        queryModel.driveIds = [this.selectedEvent.id];
        queryModel.subQueryIndicator = sObjectType.JOB_ALLOCATION;
        return service.query(queryModel)
          .then((result = []) => {
            return result.filter(item => !!item.resourceRole).map(item => {
              if(!item.jobAllocations) {
                item.jobAllocations = [];
              }

              const quantity = item.quantity;
              const remainingSlots = Math.max(quantity - item.jobAllocations.length, 0);
              const jobAllocations = item.jobAllocations;
              if(remainingSlots > 0) {
                for(let i = 0; i < remainingSlots; i++) {
                  jobAllocations.push({
                    id: uniqueId('temp_job_allocation_'),
                    resourceName: 'Empty Allocation',
                    jobId: item.id,
                    start: item.start,
                    end: item.finish,
                    resourceId: null,
                    resourceRole: null,
                  });
                }
              }
              return {
                ...item,
                resourceRoleText: compact([item.resourceRole, item.dualRole]).join('/'),
                jobAllocations: jobAllocations
              }
            });
          });
      } else {
        let service = new activityResourceService();
        let queryModel = new activityResourceQueryModel();
        queryModel.activityIds = [this.selectedEvent.id];
        return service.query(queryModel)
          .then((result = []) => {
            const activityResources = result.filter(item => {
              return item.resource.resourceType === RESOURCE_TYPE.PERSON;
            });
            activityResources.push({
              id: uniqueId('temp_activity_resource_'),
              resource: {
                name: 'Empty Allocation'
              },
              start: this.selectedEvent.start,
              finish: this.selectedEvent.finish,
              resourceId: null
            });
            return [{
              ...this.selectedEvent,
              activityResources
            }]
          });
      }
    })
    .then((result = []) => {
      const orderedResult = orderBy(result, ['startDate', 'name'], ['asc', 'asc']);

      if(this.selectedEvent.isDrive) {
        const groupedJobsByDriveShiftId = groupBy(orderedResult, 'driveShiftId');
        this.allocationGroups = Object.keys(groupedJobsByDriveShiftId).map(driveShiftId => {
          const jobs = groupedJobsByDriveShiftId[driveShiftId];
          return {
            id: driveShiftId,
            name: jobs[0].driveShiftName,
            jobs
          }
        });
      } else {
        this.allocationGroups = result;
      }
    })
  }

  validateStepSelectAllocation = () => {
    return Promise.resolve(!!this.selectedAllocationData)
  }

  handleSelectEvent = (event) => {
    const { id } = event.currentTarget.dataset;
    let selectedEvent = null;
    this.events.forEach(record => {
      record["classes"] = "";

      if(record.id === id) {
        selectedEvent = record;
        record["classes"] = "selected-item"
      }
    })

    this.selectedEvent = selectedEvent;
  }

  handleSelectAllocation = (event) => {
    const { id } = event.currentTarget.dataset;
    let selectedAllocationData = null;

    if(this.selectedEvent.isDrive) {
      this.allocationGroups.forEach(driveShift => {
        driveShift.jobs.forEach(job => {
          job.jobAllocations.forEach(jobAllocation => {
            if(jobAllocation.id === id) {
              selectedAllocationData = {
                jobAllocationId: id,
                jobAllocation: jobAllocation,
                job: job,
                driveShift: driveShift,
                callOutModalData: {
                  driveDate: job.driveDate,
                  resourceId: jobAllocation.resourceId,
                  duration: jobAllocation.resource?.dailyTimeOffHours
                }
              }
            }
          });
        })
      });
    } else {
      this.allocationGroups.forEach(activity => {
        activity.activityResources.forEach(activityResource => {
          if(activityResource.id === id) {
            selectedAllocationData = {
              activityResourceId: id,
              activityResource: activityResource,
              activity: activity,
              callOutModalData: {
                driveDate: activity.startDate,
                resourceId: activityResource.resourceId,
                duration: activityResource.resource?.dailyTimeOffHours
              }
            }
          }
        })
      });
    }

    if(!selectedAllocationData) return;

    this.selectedAllocationData = selectedAllocationData;
    this.handleNext();
  }

  initStepCallOut = () => {
    //reset values
    this.callOutData = null;
 
    return Promise.resolve()
    .then(() => {
      let service = new resourceService();
      let queryModel = new resourceQueryModel();
      queryModel.recordIds = [this.selectedAllocationData.callOutModalData.resourceId];
      return service.query(queryModel)
        .then(([resource]) => {
          this.selectedAllocationData.callOutModalData.duration = resource.dailyTimeOffHours;
        });
    })
  }

  handleBackCallOutModal = () => {
    this.handleBack();
  }

  validateStepReplaceResource = () => Promise.resolve(true);

  processResource = (posAl) => {
    const isDrive = this.selectedEvent.isDrive;

    let resource = {
      ...posAl.resource,
      exceptionLog: posAl.exceptionLog,
      categoryText: compact([posAl.resource.category, posAl.resource.employmentType]).join(' - '),
    }

    const resourceHoursRecord =  resource.resourceHoursRecords && resource.resourceHoursRecords.length ? resource.resourceHoursRecords[0] : null;
    const weeklyHoursInMinutes = (resourceHoursRecord ? resourceHoursRecord.totalWorkingTime : null) || 0;
    const weeklyHours = +(weeklyHoursInMinutes / 60).toFixed(2);

    let travelData = null;
    let isSecondaryCO = false;
    let isTemporaryCO = false;

    if(posAl) {
      isSecondaryCO = posAl.isSecondaryCO;
      isTemporaryCO = posAl.isTemporaryCO;
    }

    if(isDrive && posAl && resource.resourceType === RESOURCE_TYPE.PERSON) {
      const isDrivingRole = slwcAvailator.isJobBelongToDrivingRolesGroup(posAl.job, {
        resourceRoleGroups: this.resourceRoleGroups
      });

      if(isDrivingRole) {
        travelData = [{
          key: RESOURCE_ROLE_GROUP.DRIVING_ROLES,
          ...posAl.travelTimeGroup[RESOURCE_ROLE_GROUP.DRIVING_ROLES]
        }];
      } else {
        travelData = [{
          key: RESOURCE_ROLE_GROUP.STAFF_ROLES,
          ...posAl.travelTimeGroup[RESOURCE_ROLE_GROUP.STAFF_ROLES]
        }];
      }
    }
    
    const getAvailabilityPatternResourceNamesForAllocation = this.getAvailabilityPatternResourceNamesForAllocation(posAl);
    resource = {
      ...resource,
      noException: !posAl.exceptionLog?.length,
      weeklyHours,
      weeklyHoursInMinutes,
      travelData: travelData || [],
      isSecondaryCO,
      isTemporaryCO,
      getAvailabilityPatternResourceNamesForAllocation
    }
    
    return resource;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: TIME_ZONE
    });
  }
 /**
  * Returns an array string of the pattern names of availability pattern resources
  * for the resource in possibleAllocation whose startDate is less than the job's driveDate and 
  * end date is either null or greater than or equal to the job's driveDate
  * 
  * @param {Object} possibleAllocation - The possible allocation object containing job and resource.
  * @returns {Array} - Array of availability pattern resource names.
  * 
  */
 getAvailabilityPatternResourceNamesForAllocation(possibleAllocation) {
   if (
      !possibleAllocation ||
      !possibleAllocation.resource ||
      !Array.isArray(possibleAllocation.resource.availabilityPatternResources) ||
      !possibleAllocation.job ||
      !possibleAllocation.job.driveDate 
   ) {
      return '';
   }

  const driveDate = possibleAllocation.job.driveDate;
  return possibleAllocation.resource.availabilityPatternResources
      .filter(apr =>
          apr.startDate &&
          (this.dateUtils.compareDateJS(apr.startDate, driveDate) < 0 &&
           (!apr.endDate || this.dateUtils.compareDateJS(apr.endDate, driveDate) >= 0)
          )
      )
      .map(apr => apr.patternName)
      .filter(Boolean)
  }
  

  initStepReplaceResource = () => {
    //Reset values
    this.resources = [];
    this.filteredResources = [];
    this.selectedResource = null;
    this.selectResourceFilters = {
      searchText: ''
    };

    const isDrive = this.selectedEvent.isDrive;
    const collectionOperationIds = isDrive ? [this.selectedAllocationData.job.collectionOperationId] : [this.selectedAllocationData.activity.collectionOperationId];
    const jobs = [isDrive ? this.selectedAllocationData.job : {
      id: uniqueId(`temp_job_`),
      start: isDrive ? this.selectedAllocationData.jobAllocation.start : this.selectedAllocationData.activityResource.start,
      finish: isDrive ? this.selectedAllocationData.jobAllocation.end : this.selectedAllocationData.activityResource.finish,
      driveDate: this.selectedAllocationData.callOutModalData.driveDate,
      collectionOperationIds: collectionOperationIds
    }];
    
    const availator = slwcAvailator.getInstance({
      mapApis: window.google ? window.google.maps : null
    })

    return Promise.resolve()
    .then(() => {
      if(!isDrive) return [];
      
      const service = new driveService();
      const queryModel = new driveQueryModel();
      queryModel.recordIds = [this.selectedAllocationData.job.driveId];
      return service.query(queryModel);
    })
    .then(([drive]) => {
      return availator.fetchResourcesDataCallOutReplacement(jobs, drive,{
        timezoneSidId: TIME_ZONE,
        collectionOperationIds: collectionOperationIds,
      })
    })
    //HRP-14118
  .then(() => {
      return this.selectedEvent.isDrive ? availator.fetchJobTags(this.selectedAllocationData.job.driveId): Promise.resolve([]); //HRP-15881
    })

    .then(() => {
      return availator.buildScheduledAllocations({
        ignoreDedicatedSiteRule: true
      })
    })
    .then((result) => {
      let validPossibleAllocations = (result.possibleAllocations || []).filter(posAl => {
        const anyInvalidException = (posAl.exceptionLog || []).find(exception => {
          const hasConflictToPTOException = exception.exceptionCode === 'RESOURCE_TIME_CONFLICT' && !!exception.availabilityId;
        // const invalidTagException = ['MISSING_REQUIRED_TAG', 'RESOURCE_ROLE_RESTRICTED', 'EXPIRED_REQUIRED_TAG'].includes(exception.exceptionCode);
          return hasConflictToPTOException; /*|| invalidTagException;*/
        })
        return !anyInvalidException;
      })
      
      validPossibleAllocations = validPossibleAllocations.filter(posAl => {
        return posAl.resource?.resourceType === RESOURCE_TYPE.PERSON;
      });

      this.resources = validPossibleAllocations.map(posAl => this.processResource(posAl)); 
      this.filterResources();
    })
  }

  handleSelectResource = (event) => {
    const { id } = event.currentTarget.dataset;

    this.resources.forEach(record => {
      record["classes"] = "";
    })

    if(this.selectedResource?.id === id) {
      //deselect
      this.selectedResource = null;      
      return;
    }

    let selectedResource = null;
    this.resources.forEach(record => {
      if(record.id === id) {
        selectedResource = record;
        record["classes"] = "selected-item"
      }
    })

    this.selectedResource = selectedResource;
  }

  handleSelectResourceFiltersChanged = (event) => {
    this.selectResourceFilters.searchText = slwcUtils.getValueFromEvent(event);
    this.filterResources();
  }

  filterResources() {
    const currentAllocatedResourceIds = this.selectedEvent.isDrive ? 
      this.selectedAllocationData.job.jobAllocations.map(item => item.resourceId) : 
      this.selectedAllocationData.activity.activityResources.map(item => item.resourceId);

    this.filteredResources = orderBy(this.resources.filter((item) => {
      if(item.id === this.selectedAllocationData.callOutModalData.resourceId) return false;
      if(currentAllocatedResourceIds.includes(item.id)) return false;

      return item.name
        .toUpperCase()
        .includes(this.selectResourceFilters.searchText.toUpperCase());
    }), [(resource) => {
      if(resource.isOnCall && resource.noException) return 0;
      if(resource.isOnCall) return 1;
      if(resource.noException) return 2;
      return 3;
    }, 'name'], ['asc', 'asc']);
  }

  handleAllocate() {
    this.showLoading();
    Promise.resolve()
    .then(() => {
      if(this.selectedEvent.isDrive) {
        const service = new jobAllocationService();
        return service.save({
          jobId: this.selectedAllocationData.job.id,
          resourceId: this.selectedResource.id,
          status: JOB_ALLOCATION_STATUS.PENDING_DISPATCH
        })
        .then((result) => {
          if(!result.success) throw result;

          let driveSvc = new driveService();
          return driveSvc.dispatchDrives({
            request: {
              driveIds: [this.selectedAllocationData.job.driveId],
              resend: false
            }
          });
        })
        .then(() => {
          return {
            success: true
          }
        })
      } else {
        const service = new activityResourceService();
        return service.save({
          activityId: this.selectedAllocationData.activity.id,
          resourceId: this.selectedResource.id,
        })
      }
    })
    .then((result) => {
      if(!result.success) throw result;
      this.handleNext(null, STEP.SEARCH);
    })
    .catch((e) => {
      this.exceptionHandler(e);
    })
    .finally(() => {
      this.hideLoading();
    })
  }

  validateStepCallOut = () => {
    return Promise.resolve(true)
  }

  handleSaveCallOutModal = (event) => {
    const { callOutType, callOutReason, callOutNotes, callOutReceivedDateTime, timeOffPlan, timeOffReasonCode, usePtoForCallOut, hasTimeOffPlans } = event.detail;

    let params = {
      resourceId: this.selectedAllocationData.callOutModalData.resourceId,
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

    if(this.selectedEvent.isDrive) {
      params.jobId = this.selectedAllocationData.job.id;
    } else {
      params.activityId = this.selectedAllocationData.activity.id;
    }

    this.showLoading();
    let service = new resourceService();
    service.saveCallOut({
      request: params
    }).then(res => {
      if(this.selectedResource) {
        if(this.selectedEvent.isDrive) {
          const service = new jobAllocationService();
          return service.save({
            jobId: this.selectedAllocationData.job.id,
            resourceId: this.selectedResource.id,
            status: JOB_ALLOCATION_STATUS.PENDING_DISPATCH
          })
          .then(() => {
            let driveSvc = new driveService();
            driveSvc.dispatchDrives({
              request: {
                driveIds: [this.selectedAllocationData.job.driveId],
                resend: false
              }
            });
          })
        } else {
          const service = new activityResourceService();
          return service.save({
            activityId: this.selectedAllocationData.activity.id,
            resourceId: this.selectedResource.id,
          })
        }
      }
    })
    .then((res) => {
      this.handleNext(null, STEP.SEARCH);
    })
    .catch(error => this.exceptionHandler(error))
    .finally(() => this.hideLoading());
  }

  /** Confirm Modal **/
  showConfirmModal(confirmModalData) {
    this.confirmModalData = {
      ...confirmModalData,
      isOpen: true
    }
  }

  hideConfirmModal() {
    this.confirmModalData = {};
  }
}