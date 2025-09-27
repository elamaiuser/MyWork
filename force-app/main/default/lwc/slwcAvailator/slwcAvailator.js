import * as autoMapper from 'c/autoMapper';
import {
  collectionOperationQueryModel,
  collectionOperationService,
  dataService,
  driveService,
  jobAllocationService,
  skedService,
  sObjectType
} from 'c/dataService';
import { cloneDeep, compact, findIndex, groupBy, isString, keyBy, min, orderBy, remove, uniq, uniqBy, get, uniqueId, chunk } from 'c/lodash';
import { DateTime } from 'c/luxon';
import { ASSET_TYPE, AVAILABILITY_TYPE, RESOURCE_TYPE, TAG, RESOURCE_EMPLOYMENT_STATUS, RESOURCE_ROLE_GROUP, ADDRESS_REFERENCED_FOR_SCHEDULING } from 'c/slwcConstants';
import * as slwcDateUtils from 'c/slwcDateUtils';
import * as slwcUtils from 'c/slwcUtils';

const METRES_TO_MILES_CONSTANT = 0.000621371;
const OBJECT_TYPE = {
  NON_WORKING: 'non-working',
  AVAILABILITY: 'availability',
  JOB_ALLOCATION: 'jobAllocation',
  ACTIVITY: 'activity',
  RESOURCE_OVERRIDE: 'resourceOverride',
  SECONDARY_COLLECTION_OPERATION: 'secondaryCollectionOperation'
}
const PATTERN_TYPE = {
  WEEKLY: 'weekly',
  CUSTOM: 'custom'
}
const EVENT_STATUS = {
  DECLINED: 'Declined'
}
const MAX_TRAVEL_TIME_ORIGIN_CHUNK_SIZE = 100;

/* Utils */
const isJobBelongToDrivingRolesGroup = (job, {
  resourceRoleGroups
}) => {
  const resourceRoleGroup = Object.keys(resourceRoleGroups).find(resourceRoleGroup => {
    return !!resourceRoleGroups[resourceRoleGroup].find(item => item === job.resourceRole);
  })
  return resourceRoleGroup === RESOURCE_ROLE_GROUP.DRIVING_ROLES;
}

const isJobRequireTravelTimes = (isTemporaryCO, job, drive, {
  resourceRoleGroups
}) => {
  const isDrivingRole = isJobBelongToDrivingRolesGroup(job, {
    resourceRoleGroups
  });
  const rule1 = isDrivingRole;
  const rule2 = !isDrivingRole && !drive.collectionOperation?.noTravelTime && (drive.travelTimeIncluded === 'All Roles' || isTemporaryCO);

  return rule1 || rule2;
}

const isDriverJob = (job, onlyCheckResourceRole = false) => {
  if(!job) return false;
  const isNotCdlDriverJob = job.id && !job.id.startsWith('drivercdl');
  const isNotDotDriverJob = job.id && !job.id.startsWith('driverdot');
  if(onlyCheckResourceRole) {
    return isNotCdlDriverJob && isNotDotDriverJob && job.resourceRole === 'Driver' && !job.dualRole;
  }

  return isNotCdlDriverJob && isNotDotDriverJob && (
    job.resourceRole === 'Driver' || job.dualRole === 'Driver'
  )
}

const isResourceTagRestricted = (resourceTag, {
    startDate,
    endDate
}) => {
  if(!resourceTag.restrictionStartDate && !resourceTag.restrictionEndDate) return false;

  if(resourceTag.restrictionEndDate) {
    return resourceTag.restrictionStartDate <= endDate && resourceTag.restrictionEndDate >= startDate;
  } else {
    return resourceTag.restrictionStartDate <= startDate;
  }
}

class dateslotModel {
  timezoneSidId = null;
  startJS = null;
  finishJS = null;
  events = [];
  
  constructor(data) {
    this.timezoneSidId = data.timezoneSidId;
  }

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: this.timezoneSidId
    })
  }

  addEvent(startTime, endTime, objectType, isAvailable) {
    const _addAvailableBlock = (startTime, endTime) => {
      let newEvents = [];
      let removedEvents = [];
  
      this.events.forEach((eventItem) => {
        if (this.dateUtils.compareDateJS(eventItem.startJS, startTime) < 0 && this.dateUtils.compareDateJS(startTime, eventItem.finishJS) < 0) {
          if (this.dateUtils.compareDateJS(endTime, eventItem.finishJS) < 0) {
            let newEvent = {};
            newEvent.startJS = endTime;
            newEvent.finishJS = eventItem.finishJS;
            newEvent.objectType = eventItem.objectType;
            newEvents.push(newEvent);
          }
          eventItem.finishJS = startTime;
        }
        else if (this.dateUtils.compareDateJS(startTime, eventItem.startJS) <= 0) {
          if (this.dateUtils.compareDateJS(endTime, eventItem.finishJS) >= 0) {
            removedEvents.push(eventItem.startJS);
          }
          else if (this.dateUtils.compareDateJS(eventItem.startJS, endTime) < 0 && this.dateUtils.compareDateJS(endTime, eventItem.finishJS) < 0) {
            eventItem.startJS = endTime;
          }
        }
      });
  
      remove(this.events, (event) => {
        return removedEvents.indexOf(event.startJS) > -1;
      });
  
      this.events = this.events.concat(newEvents);
    };
  
    if (isAvailable == true) {
      _addAvailableBlock(startTime, endTime);
    }
    else {
      let newEvent = {};
      newEvent.startJS = startTime;
      newEvent.finishJS = endTime;
      newEvent.objectType = objectType;
      this.events.push(newEvent);
      return newEvent;
    }
    return null;
  }
}

class SlwcAvailator {
  drive;
  driveId;
  mapApis;
  considerDateOnly = false;

  //local keepData
  collectionOperationId;
  collectionOperationIds = [];
  arcRegionIds = [];
  travelTimeVelocity = 35;
  timezoneSidId = null;
  jobs = [];
  resources = [];
  availabilityPatterns = [];
  availabilityPatternsMap;
  exceptionSettings = [];
  exceptionSettingsMap;
  groupActivities = [];
  resourceRoleGroups = [];
  callOutJobAllocations = [];
  tradedJobAllocations = [];
  prevCancelledJobAllocations = [];
  resourceOverrides = [];
  maxCDLDOTDurationInMinutes = 60;
  travelTimeMap = {};
  resourceCollectionOperationDataMap = {};

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: this.timezoneSidId
    })
  }

  constructor(data) {
    this.drive = data.drive;
    this.driveId = data.driveId;
    this.mapApis = data.mapApis;
    this.considerDateOnly = data.considerDateOnly;
    console.log('>>> Init Availator', this)
  }

  populateDateTime(rawData) {
    let startDateTime = this.dateUtils.getDateTimeInfo(this.considerDateOnly ? (rawData.startDate || rawData.start) : rawData.start);
    if(startDateTime) {
      rawData.startJS = startDateTime.dateTime;
      rawData.startDate = startDateTime.date;
      rawData.startTime = startDateTime.timeNumber
    }

    let endDateTime = this.dateUtils.getDateTimeInfo(this.considerDateOnly ? (rawData.endDate || rawData.finish || rawData.end) : rawData.finish || rawData.end);
    if(endDateTime) {
      rawData.finishJS = this.considerDateOnly ? DateTime.fromJSDate(endDateTime.dateTime).endOf('days').toJSDate() : endDateTime.dateTime;
      rawData.endDate = endDateTime.date;
      rawData.endTime = this.considerDateOnly ? 2359 : endDateTime.timeNumber
    }

    return rawData;
  }

  getLocationKey(location1, location2) {
    return `from:${location1.latitude}:${location1.longitude}|to:${location2.latitude}:${location2.longitude}`
  }

  getTravelTime(location1, location2) {
    if (!location1?.longitude || !location2?.longitude) {
      return undefined;
    }
    
    const locationKey = this.getLocationKey(location1, location2);
    if(this.travelTimeMap[locationKey] && !slwcUtils.isNullOrEmpty(this.travelTimeMap[locationKey].travelTime)) {
      return this.travelTimeMap[locationKey].travelTime;
    }
    
    if (this.travelTimeVelocity <= 0) {
      return 0;
    }
    let travelTime = -1;
    let dist = this.calculateDistance(location1, location2);
    travelTime = +Number((dist / this.travelTimeVelocity) * 60).toFixed(0);
    return travelTime;
  }

  calculateDistance(location1, location2) {
    if (!location1?.longitude || !location2?.longitude) {
      return undefined;
    }

    const locationKey = this.getLocationKey(location1, location2);
    if(this.travelTimeMap[locationKey] && !slwcUtils.isNullOrEmpty(this.travelTimeMap[locationKey].distance)) {
      return this.travelTimeMap[locationKey].distance;
    }

    if(!this.mapApis) return 0;
    let distance = 0, point1, point2;
    if (location1 && location1.latitude && location1.longitude) {
        point1 = new this.mapApis.LatLng(location1.latitude, location1.longitude);
    }
    if (location2 && location2.latitude && location2.longitude) {
        point2 = new this.mapApis.LatLng(location2.latitude, location2.longitude);
    }
    if (point1 && point2) {
        distance = this.mapApis.geometry.spherical.computeDistanceBetween(point1, point2); // in metres
        distance = distance * METRES_TO_MILES_CONSTANT; // convert to miles
    }
    return distance;
  };

  doTransformResources(skedResources, groupActivities, callOutJobAllocations, tradedJobAllocations, prevCancelledJobAllocations, resourceOverrides, resourceHoursRecordDetails) {
    let groupActivitiesMap = keyBy(groupActivities, "id");
    let callOutJobAllocationsMap = groupBy(callOutJobAllocations, "resourceId");
    let tradedJobAllocationsMap = groupBy(tradedJobAllocations, "resourceId"); 
    let prevCancelledJobAllocationsMap = groupBy(prevCancelledJobAllocations, "resourceId"); 
    let resourceOverridesMap = groupBy(resourceOverrides, "resourceId");
    let resourceHoursRecordDetailsMap = groupBy(resourceHoursRecordDetails, "resourceHoursRecordId");

    return (skedResources || []).map((skedResource) => {
      let resource = autoMapper.autoMapperInstance.mapTo('sked__Resource__c', skedResource);

      resource.terminationDate = min(compact([resource.terminationDate, resource.plannedTerminationDate]));
      
      resource.isOnCall = false;
      (resource.availabilities || []).forEach((availability) => {
        if(availability.eventType !== AVAILABILITY_TYPE.ON_CALL) return;
        if (availability.start < this.drive.maxShiftEnd && this.drive.minShiftStart < availability.finish) {
          resource.isOnCall = true;
        }
      });

      resource.isVolunteer = false;
      (resource.customAvailabilities || []).forEach((customAvailability) => {
        if (customAvailability.type === 'Volunteer') {
          if (customAvailability.start < this.drive.maxShiftEnd && this.drive.minShiftStart < customAvailability.finish) {
            resource.isVolunteer = true;
          }
        }
      });

      resource.isAccountBlacklisted = false;
      resource.isAccountWhitelisted = false;
      (resource.accountResourceScores || []).forEach((accountResourceScore) => {
        if (accountResourceScore.accountId == this.drive.accountId) {
          resource.isAccountBlacklisted = accountResourceScore.blacklisted;
          resource.isAccountWhitelisted = accountResourceScore.whitelisted;
        }
      });

      resource.isLocationBlacklisted = false;
      resource.isLocationWhitelisted = false;
      (resource.locationResourceScores || []).forEach((locationResourceScore) => {
        if (locationResourceScore.locationId == this.drive.driveSiteId) {
          resource.isLocationBlacklisted = locationResourceScore.blacklisted;
          resource.isLocationWhitelisted = locationResourceScore.whitelisted;
        }
      });

      resource.activities = (resource.activities || []).map((activity) => {
        activity.objectType = OBJECT_TYPE.ACTIVITY;
        this.populateDateTime(activity);
        return activity;
      });

      resource.availabilities = (resource.availabilities || []).map((availability) => {
        availability.objectType = OBJECT_TYPE.AVAILABILITY;
        this.populateDateTime(availability);
        return availability;
      });

      resource.customAvailabilities = (resource.customAvailabilities || []).map((customAvailability) => {
        customAvailability.objectType = OBJECT_TYPE.AVAILABILITY;
        this.populateDateTime(customAvailability);
        return customAvailability;
      });
      
      resource.groupActivities = (resource.activityResources || []).map((activityResource) => {
        let groupActivity = groupActivitiesMap[activityResource.activityId];
        groupActivity.objectType = OBJECT_TYPE.ACTIVITY;
        groupActivity.start = activityResource.start || groupActivity.start;
        groupActivity.finish = activityResource.finish || groupActivity.finish;
        this.populateDateTime(groupActivity);
        return groupActivity;
      });

      resource.jobAllocations = (resource.jobAllocations || []).map((item) => {
        item.latitude = item.job.latitude;
        item.longitude = item.job.longitude;
        item.driveName = item.job.driveName;
        if (item.startWithTravelTime) {
          item.start = item.startWithTravelTime;
        }
        item.objectType = OBJECT_TYPE.JOB_ALLOCATION;
        this.populateDateTime(item);
        return item;
      });
      
      resource.events = resource.activities.concat(resource.groupActivities).concat(resource.jobAllocations);
      
      resource.availabilityPatternResources = (resource.availabilityPatternResources || []).map((availabilityPatternResource) => {
        this.populateDateTime(availabilityPatternResource);
        return availabilityPatternResource;
      });
      
      resource.callOutJobAllocations = (callOutJobAllocationsMap[resource.id] || []).map((jobAllocation) => {
        jobAllocation.objectType = OBJECT_TYPE.JOB_ALLOCATION;
        this.populateDateTime(jobAllocation);
        return jobAllocation;
      });
      resource.callOutJobIds = resource.callOutJobAllocations.map(jobAllocation => jobAllocation.jobId);
      resource.isCallOut = resource.callOutJobIds.length > 0;

      resource.tradedJobAllocations = (tradedJobAllocationsMap[resource.id] || []).map((jobAllocation) => {
        jobAllocation.objectType = OBJECT_TYPE.JOB_ALLOCATION;
        this.populateDateTime(jobAllocation);
        return jobAllocation;
      })
      resource.tradedJobIds = resource.tradedJobAllocations.map(jobAllocation => jobAllocation.jobId);
      resource.isTraded = resource.tradedJobIds.length > 0;

      resource.prevCancelledJobAllocations = [];
      (prevCancelledJobAllocationsMap[resource.id] || []).forEach(jobAllocation => {
        if (jobAllocation.driveId !== this.driveId && jobAllocation.driveDate === this.drive.driveDate) {
          resource.prevCancelledJobAllocations.push(jobAllocation);
        }
      })
      resource.isPrevCancelled = resource.prevCancelledJobAllocations.length > 0;

      resource.resourceOverrides = resourceOverridesMap[resource.id] || [];

      if(!resource.secondaryCollectionOperations) {
        resource.secondaryCollectionOperations = [];
      }

      resource.resourceHoursRecords = (resource.resourceHoursRecords || []).map((resourceHoursRecord) => {
        resourceHoursRecord.details = resourceHoursRecordDetailsMap[resourceHoursRecord.id] || [];
        return resourceHoursRecord;
      });

      if(!resource.resourceTags) {
        resource.resourceTags = [];
      }
      
      return resource;
    });
  }

  doTransformGroupActivities(data) {
    let groupActivities = (data || []).map((skedActivity) => {
      let groupActivity = autoMapper.autoMapperInstance.mapTo('sked__Activity__c', skedActivity);
      this.populateDateTime(groupActivity);
      return groupActivity;
    });
    groupActivities = orderBy(groupActivities, ['start'], ['asc']);
    return groupActivities;
  }

  doTransformJobAllocations(data) {
    let jobAllocations = (data || []).map((skedJobAllocation) => {
      let jobAllocation = autoMapper.autoMapperInstance.mapTo('sked__Job_Allocation__c', skedJobAllocation);
      this.populateDateTime(jobAllocation);
      return jobAllocation;
    });
    jobAllocations = orderBy(jobAllocations, ['start'], ['asc']);
    return jobAllocations;
  }

  doTransformResourceOverrides(data) {
    let resourceOverrides = (data || []).map((skedResourceOverride) => {
      let resourceOverride = autoMapper.autoMapperInstance.mapTo('sked__Resource_Override__c', skedResourceOverride);
      resourceOverride.objectType = OBJECT_TYPE.RESOURCE_OVERRIDE;
      return resourceOverride;
    });
    resourceOverrides = orderBy(resourceOverrides, ['start'], ['asc']);
    return resourceOverrides;
  }

  doTransformAvailabilityPatterns(data) {
    let availabilityPatterns = (data || []).map((skedAvailabilityPattern) => {
      let availabilityPattern = autoMapper.autoMapperInstance.mapTo('sked__Availability_Pattern__c', skedAvailabilityPattern);
      return availabilityPattern;
    });
    return availabilityPatterns;
  }

  doTransformResourceHoursRecordDetails(data) {
    let resourceHoursRecordDetails = (data || []).map((skedResourceHoursRecordDetail) => {
      let resourceHoursRecordDetail = autoMapper.autoMapperInstance.mapTo('sked_Resource_Hours_Record_Detail__c', skedResourceHoursRecordDetail);
      return resourceHoursRecordDetail;
    });
    return resourceHoursRecordDetails;
  }

  doTransformJobs(data) {
    let jobs = (data || []).map((item) => {
      item.objectType = OBJECT_TYPE.JOB_ALLOCATION;
      item.quantity = item.quantity || 0;
      return this.populateDateTime(item);
    })
    jobs = orderBy(jobs, ['start'], ['asc']);
    return jobs;
  }

  fetchJobs() {
    let service = new driveService();
    return service.getDriveById(this.driveId)
    .then((result) => {
      if(!result) {
        throw Error('Cannot fetch jobs');
      }

      this.drive = result;
      this.timezoneSidId = result.driveSite && result.driveSite.timezoneSidId;
      this.collectionOperationIds = [result.collectionOperationId];

      result.driveShifts.forEach(item => {
        this.jobs = this.jobs.concat(this.doTransformJobs(item.jobs));
      });
    });
  }

//HRP-14118

fetchJobTags(driveId){
  let service = new driveService();
  return service.getDriveById(driveId)
      .then((result) => {
          if (!result) {
              throw new Error('Cannot fetch jobs');
          }
          //Getting the jobTags
          result.driveShifts.forEach(driveShift => {
            driveShift.jobs.forEach(job => {
                if (job.jobTags && job.jobTags.length > 0) {
                    job.jobTags.forEach(tag => {
                      // Find matching job in this.jobs by ID
                        let matchingJob = this.jobs.find(j => j.id === tag.jobId);
                        if (matchingJob) {
                            
                            if (!matchingJob.jobTags) {
                                matchingJob.jobTags = [];
                            }
                            // Avoid duplicate tags
                            if (!matchingJob.jobTags.some(t => t.id === tag.id)) {
                                matchingJob.jobTags.push(tag);
                            }
                        }
                    });
                }
            });
        });
    });

}



  fetchResources(pageNo = 1, totalRecords, getAssetsOnly, additionalFilters) {
    let inputDates = [];
    this.jobs.forEach((item) => {
      let tempDt = new Date(item.startDate);
      while (this.dateUtils.compareDateJS(tempDt, item.endDate) <= 0) {
        let dateIso = this.dateUtils.dateToStringNative(tempDt);
        if (!inputDates.includes(dateIso)) {
          inputDates.push(dateIso);
        }
        tempDt = this.dateUtils.addDay(tempDt, 1);
      }
    });
    
    if(!inputDates.length) {
      return;
    }

    let request = {
      accountIds: this.drive.accountId ? [this.drive.accountId] : [],
      collectionOperationIds: this.collectionOperationIds,
      arcRegionIds: this.arcRegionIds,
      locationIds: this.drive.driveSiteId ? [this.drive.driveSiteId] : [],
      inputDates: inputDates,
      jobIds: this.jobs.filter(job => !!job.id).map(job => job.id),
      excludedDriveIds: this.excludedDriveIds || [],
      excludedActivityIds: this.excludedActivityIds || [],
      pageSize: 200,
      pageNo: pageNo,
      getAssetsOnly: !!getAssetsOnly,
      timezoneSidId: this.drive?.driveSite?.timezoneSidId || this.timezoneSidId
    }
    if(additionalFilters) {
      if(additionalFilters.recordIds.length) {
        request.recordIds = additionalFilters.recordIds;
      }
    }
    let service = new jobAllocationService();
    return service.getResourceData({request : request})
      .then((result) => {
        if (!result) {
          throw Error('Cannot fetch resources');
        }
        let returnAvailabilityPatterns = this.doTransformAvailabilityPatterns(result.returnedData.availabilityPatterns);
        this.availabilityPatterns = this.availabilityPatterns.concat(returnAvailabilityPatterns);
        this.availabilityPatternsMap = keyBy(this.availabilityPatterns, "id");

        let returnGroupActivities = this.doTransformGroupActivities(result.returnedData.groupActivities);
        this.groupActivities = this.groupActivities.concat(returnGroupActivities);

        let returnCallOutJobAllocations = this.doTransformJobAllocations(result.returnedData.calloutJobAllocations);
        this.callOutJobAllocations = this.callOutJobAllocations.concat(returnCallOutJobAllocations);

        let returnTradedJobAllocations = this.doTransformJobAllocations(result.returnedData.tradedJobAllocations);
        this.tradedJobAllocations = this.tradedJobAllocations.concat(returnTradedJobAllocations);

        let returnPrevCancelledJobAllocations = this.doTransformJobAllocations(result.returnedData.prevCancelledJobAllocations);
        this.prevCancelledJobAllocations = this.prevCancelledJobAllocations.concat(returnPrevCancelledJobAllocations);

        let returnResourceOverrides = this.doTransformResourceOverrides(result.returnedData.resourceOverrides);
        this.resourceOverrides = this.resourceOverrides.concat(returnResourceOverrides);

        let returnResourceHoursRecordDetails = this.doTransformResourceHoursRecordDetails(result.returnedData.resourceHoursRecordDetails);

        let returnedResources = this.doTransformResources(
          result.returnedData.resources,
          this.groupActivities,
          this.callOutJobAllocations,
          this.tradedJobAllocations,
          this.prevCancelledJobAllocations,
          this.resourceOverrides,
          returnResourceHoursRecordDetails
        );
        this.resources = this.resources.concat(returnedResources);

        if (pageNo == 1) {
          totalRecords = result.returnedData.totalRecords;
        }
        if (this.resources.length < totalRecords) {
          return this.fetchResources(pageNo + 1, totalRecords, getAssetsOnly, additionalFilters);
        }
      });
  }

  fetchData() {
    console.log('>>> Start fetching data', new Date());
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start retrieveCustomSettings', new Date());
      return this.retrieveCustomSettings();
    })
    .then(() => {
      console.log('>>> Start fetching jobs', new Date());
      return this.fetchJobs();
    })
    .then(() => {
      console.log('>>> Start fetching resources', new Date());
      return this.fetchResources();
    })
    .then(() => {
      console.log('>>> Finished Fetching data', new Date());
      console.log('>>> jobs', this.jobs);
      console.log('>>> resources', this.resources);
    })
  }

  fetchAssetsData() {
    console.log('>>> Start fetching data', new Date());
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start retrieveCustomSettings', new Date());
      return this.retrieveCustomSettings();
    })
    .then(() => {
      this.timezoneSidId = this.drive.driveSite && this.drive.driveSite.timezoneSidId;
      this.collectionOperationIds = [this.drive.collectionOperationId];

      let assetJobs = [];
      if(this.drive.driveShifts && this.drive.driveShifts.length) {
        this.drive.driveShifts.forEach(driveShift => {
          driveShift.jobs?.forEach(job => {
            if(!job.id) {
              job.id = uniqueId('temp_job_');
            }
          })
        });
        assetJobs = (this.drive.driveShifts[0].jobs || []).filter(job => {
          return [ASSET_TYPE.VEHICLE, ASSET_TYPE.EQUIPMENT].includes(job.assetType);
        });
      }
      
      this.jobs = assetJobs.map(job => {
        let startLuxon = DateTime.fromISO(isString(job.start) ? job.start : job.start.toISOString(), {
          zone: this.timezoneSidId
        });
        let endLuxon =  DateTime.fromISO(isString(job.finish) ? job.finish : job.finish.toISOString(), {
          zone: this.timezoneSidId
        });
        let currentDriveDate = startLuxon.toFormat('yyyy-MM-dd');
        let diff = this.dateUtils.diffDays(currentDriveDate, this.drive.driveDate);
        startLuxon = startLuxon.plus({
          days: diff
        })
        endLuxon = endLuxon.plus({
          days: diff
        })

        return this.doTransformJobs([{
          ...job,
          actualStart: job.start,
          actualFinish: job.finish,
          driveDate: this.drive.driveDate,
          start: startLuxon.toUTC().toISO(),
          finish: endLuxon.toUTC().toISO()
        }])[0];
      })
    })
    .then(() => {
      console.log('>>> Start fetching resources', new Date());
      return this.fetchResources(1, null, true);
    })
    .then(() => {
      console.log('>>> Finished Fetching data', new Date());
      console.log('>>> jobs', this.jobs);
      console.log('>>> resources', this.resources);
    })
  }
  
  fetchAssetsDataDriveCalendar(jobs, {
    timezoneSidId,
    excludedDriveIds = [],
    excludedActivityIds = [],
    collectionOperationIds = []
  }) {
    console.log('>>> Start fetching data', new Date());
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start retrieveCustomSettings', new Date());
      return this.retrieveCustomSettings();
    })
    .then(() => {
      this.timezoneSidId = timezoneSidId;
      this.collectionOperationIds = collectionOperationIds;
      this.jobs = this.doTransformJobs(jobs);
      this.excludedDriveIds = excludedDriveIds;
      this.excludedActivityIds = excludedActivityIds;
      this.drive = {};
    })
    .then(() => {
      console.log('>>> Start fetching resources', new Date());
      return this.fetchResources(1, null, true);
    })
    .then(() => {
      console.log('>>> Finished Fetching data', new Date());
      console.log('>>> jobs', this.jobs);
      console.log('>>> resources', this.resources);
    })
  }

  fetchResourcesDataCallOutReplacement(jobs, drive, {
    timezoneSidId,
    excludedDriveIds = [],
    excludedActivityIds = [],
    collectionOperationIds = []
  }) {
    console.log('>>> Start fetching data', new Date());
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start retrieveCustomSettings', new Date());
      return this.retrieveCustomSettings();
    })
    .then(() => {
      this.timezoneSidId = timezoneSidId;
      this.collectionOperationIds = collectionOperationIds;
      this.jobs = this.doTransformJobs(jobs);
      this.excludedDriveIds = excludedDriveIds;
      this.excludedActivityIds = excludedActivityIds;
      this.drive = drive || {};
    })
    .then(() => {
      console.log('>>> Start fetching resources', new Date());
      return this.fetchResources(1, null, false);
    })
    .then(() => {
      console.log('>>> Finished Fetching data', new Date());
      console.log('>>> jobs', this.jobs);
      console.log('>>> resources', this.resources);
    })
  }

  fetchDataForDriveGenerator(drive, jobs, resources) {
    console.log('>>> Start fetching data', new Date());
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start retrieveCustomSettings', new Date());
      return this.retrieveCustomSettings();
    })
    .then(() => {
      this.timezoneSidId = drive.driveSite && drive.driveSite.timezoneSidId;
      this.collectionOperationIds = [drive.collectionOperationId];
      this.jobs = this.doTransformJobs(jobs);
      this.drive = drive;
    })
    .then(() => {
      console.log('>>> Start fetching resources', new Date());
      return this.fetchResources(1, null, false, {
        recordIds: resources.map(item => item.id)
      });
    })
    .then(() => {
      console.log('>>> Finished Fetching data', new Date());
      console.log('>>> jobs', this.jobs);
      console.log('>>> resources', this.resources);
    })
  }

  fetchResourceDataForTrade(jobs, {
    timezoneSidId,
    collectionOperationIds = [],
    arcRegionIds = [],
    resourceIds = []
  }) {
    console.log('>>> Start fetching data', new Date());
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start retrieveCustomSettings', new Date());
      return this.retrieveCustomSettings();
    })
    .then(() => {
      this.timezoneSidId = timezoneSidId;
      this.collectionOperationIds = collectionOperationIds;
      this.arcRegionIds = arcRegionIds;
      this.jobs = this.doTransformJobs(jobs);
      this.drive = {};
    })
    .then(() => {
      console.log('>>> Start fetching resources', new Date());
      return this.fetchResources(1, null, false, {
        recordIds: resourceIds
      });
    })
    .then(() => {
      console.log('>>> Finished Fetching data', new Date());
      console.log('>>> jobs', this.jobs);
      console.log('>>> resources', this.resources);
    })
  }
  
  updateData(job,indexDriveShift){
    const indexJobInJobs = findIndex(this.jobs,{'id': job.id} )
    const indexJobInDriveShifts= findIndex(this.drive.driveShifts[indexDriveShift].jobs,{'id': job.id} )
    const transformedJobs = this.doTransformJobs([job]);
    if(indexJobInDriveShifts !== -1){
      this.jobs[indexJobInJobs] = transformedJobs[0]
      this.drive.driveShifts[indexDriveShift].jobs[indexJobInDriveShifts] = transformedJobs[0]
    } else {
      this.jobs = this.jobs.concat(transformedJobs);
      this.drive.driveShifts[indexDriveShift].jobs = this.drive.driveShifts[indexDriveShift].jobs.concat(transformedJobs)
    }
  }

  validateJobCollectionOperation(job, collectionOperationId) {
    const jobCollectionOperationIds = (job.collectionOperationIds ? job.collectionOperationIds : [job.collectionOperationId]).map(item => item);
    return jobCollectionOperationIds.includes(collectionOperationId);
  }
  
  getResourceStagingLocation(resource, driveDate) {
    const collectionOperationStagingLocations = this.collectionOperationDataMap[resource.collectionOperationId]?.collectionOpStagingLocations || [];
    const collectionOperationStagingLocation = collectionOperationStagingLocations.find(item => (!item.startDate || item.startDate <= driveDate) && (!item.endDate || driveDate <= item.endDate));
    const stagingLocation = collectionOperationStagingLocation?.stagingLocation;
    return {
      geoLocationLatitude: stagingLocation ? stagingLocation.geoLocationLatitude : null,
      geoLocationLongitude: stagingLocation ? stagingLocation.geoLocationLongitude : null
    }
  }

  getDriveStagingLocation(drive) {
    const { driveDate, collectionOperationId } = drive;
    const collectionOperationStagingLocations = this.collectionOperationDataMap[collectionOperationId]?.collectionOpStagingLocations || [];
    const collectionOperationStagingLocation = collectionOperationStagingLocations.find(item => (!item.startDate || item.startDate <= driveDate) && (!item.endDate || driveDate <= item.endDate));
    const stagingLocation = collectionOperationStagingLocation?.stagingLocation;
    return {
      geoLocationLatitude: stagingLocation ? stagingLocation.geoLocationLatitude : null,
      geoLocationLongitude: stagingLocation ? stagingLocation.geoLocationLongitude : null
    }
  }

  getResourceLocation(resource, resourceStagingLocation) {
    if(resource.addressReferencedForScheduling === ADDRESS_REFERENCED_FOR_SCHEDULING.WORK && resource.useCOAddressForScheduling) {
      return resourceStagingLocation;
    }
    
    return {
      latitude: resource.latitude,
      longitude: resource.longitude,
    }
  }
  
  prepareCollectionOperationDataMap(collectionOperationIds = []) {
    this.collectionOperationDataMap = {};
    return Promise.resolve()
    .then(() => {
      if(!collectionOperationIds.length) {
        return;
      }
      
      let service = new collectionOperationService();
      let queryModel = new collectionOperationQueryModel();
      queryModel.recordIds = collectionOperationIds;
      queryModel.subQueryIndicator = sObjectType.COLLECTION_OPERATION_STAGING_LOCATION;
      return service.query(queryModel);
    })
    .then((collectionOperations = []) => {
      this.collectionOperationDataMap = keyBy(collectionOperations, 'id');
    });
  }

  buildGeolocationKey = (location) => {
    if(!location) return null;
    return `${location.latitude}-${location.longitude}`;
  }
  
  prepareTravelTimeMatrix(inputJobIds) {
    let travelToMap = {
      originsMap: {},
      destinationsMap: {}
    }

    let travelBackMap = {
      originsMap: {},
      destinationsMap: {}
    }

    const setOriginsDestinations = (location1, location2, travelMap = {}) => {
      if(!location1.longitude || !location2.longitude) return;

      const originKey = this.buildGeolocationKey(location1);
      travelMap.originsMap[originKey] = {
        latitude: location1.latitude,
        longitude: location1.longitude
      }

      const destinationKey = this.buildGeolocationKey(location2);
      travelMap.destinationsMap[destinationKey] = {
        latitude: location2.latitude,
        longitude: location2.longitude
      }
    }

    const mapResult = (origins, destinations, matrixData = []) => {
      if(!matrixData.length) return;

      for(let i = 0; i < origins.length; i++) {
        for(let j = 0; j < destinations.length; j++) {
          const locationKey = this.getLocationKey(origins[i], destinations[j]);
          const result = matrixData[i][j];
          let data = {
            distance: null,
            travelTime: null
          };
          if(result) {
            if(result.distance) {
              data.distance = result.distance.distanceInMeters * METRES_TO_MILES_CONSTANT;
            }
            if(result.duration) {
              data.travelTime = result.duration.durationInSeconds / 60;
            }
          }
          this.travelTimeMap[locationKey] = data;
        }
      }
    }
    
    this.resources.forEach((resource) => {
      if (!resource.mapDateslot) {
        return;
      }

      this.jobs.forEach((job) => {
        let isTemporaryCO = false;
        let resourceLatitude = resource.latitude;
        let resourceLongitude = resource.longitude;
        let jobStartLatitude = job.latitude;
        let jobStartLongitude = job.longitude;
        let jobEndLatitude = job.latitude;
        let jobEndLongitude = job.longitude;
        const travelRoutes = this.getTravelRoutesFromResourceToJob(resource, job);
        const _isJobBelongToDrivingRolesGroup = isJobBelongToDrivingRolesGroup(job, {
          resourceRoleGroups: this.resourceRoleGroups
        });
        const travelRoute = _isJobBelongToDrivingRolesGroup ? travelRoutes[RESOURCE_ROLE_GROUP.DRIVING_ROLES] : travelRoutes[RESOURCE_ROLE_GROUP.STAFF_ROLES];
        let resourceCollectionOperationId = resource.collectionOperationId;
        let overrideRegion = resource.resourceOverrides.find((item) => {
          return item.startDate <= this.dateUtils.dateToStringNative(job.startDate) && this.dateUtils.dateToStringNative(job.endDate) <= item.endDate;
        }); 
        if (overrideRegion) {
          resourceCollectionOperationId = overrideRegion.collectionOperationId;

          if (!this.validateJobCollectionOperation(job, resourceCollectionOperationId)) {
            return;
          }
          else {
            if (resourceCollectionOperationId !== resource.collectionOperationId) {
              isTemporaryCO = true;

              if(overrideRegion.isTravelRequired) {
                resourceLatitude = overrideRegion.geoLocationLatitude;
                resourceLongitude = overrideRegion.geoLocationLongitude;
              }
            }
          }
        } 

        if(!isTemporaryCO) {
          if(resource.dedicatedToSiteId && resource.dedicatedToSiteId !== this.drive.driveSiteId) {
            return;
          }

          const { geoLocationLatitude, geoLocationLongitude } = this.getResourceStagingLocation(resource, job.driveDate);
          jobStartLatitude = geoLocationLatitude;
          jobStartLongitude = geoLocationLongitude;
        }
        
        let isValid = true;
        let dateSlotEvents = [];
        let tempDt = new Date(job.startDate);
        while (this.dateUtils.compareDateJS(tempDt, job.endDate) <= 0) {
          let dateIso = this.dateUtils.dateToStringNative(tempDt);
          if (resource.mapDateslot[dateIso]) {
            let tempDateSlotEvents = resource.mapDateslot[dateIso].events;
            dateSlotEvents = dateSlotEvents.concat(tempDateSlotEvents);
          }
          else {
            isValid = false;
            break;
          }
          tempDt = this.dateUtils.addDay(tempDt, 1);
        }
        if (!isValid) {
          return;
        }
        
        if(travelRoute) {
          //travel to
          setOriginsDestinations({
            latitude: travelRoute.origin.latitude, 
            longitude: travelRoute.origin.longitude
          }, {
            latitude: travelRoute.destination.latitude, 
            longitude: travelRoute.destination.longitude
          }, travelToMap);

          //travel back
          setOriginsDestinations({
            latitude: travelRoute.destination.latitude, 
            longitude: travelRoute.destination.longitude
          }, {
            latitude: travelRoute.origin.latitude, 
            longitude: travelRoute.origin.longitude
          }, travelBackMap);
        }
        
        dateSlotEvents = orderBy(dateSlotEvents, [(item) => {
          return item.startJS.getTime();
        }], ['asc']);

        let previousEvent, nextEvent;      
        for (let i = 0; i < dateSlotEvents.length; i++) {
          let event = dateSlotEvents[i];
          if (event.objectType === OBJECT_TYPE.JOB_ALLOCATION) {
            if (inputJobIds.indexOf(event.jobId) > -1 || event.status === EVENT_STATUS.DECLINED) {
              continue;
            }
          }
          if (this.dateUtils.compareDateJS(job.finishJS, event.startJS) < 0 && nextEvent) {
            break;
          }

          if (this.dateUtils.compareDateJS(event.startJS, job.finishJS) < 0 &&
            this.dateUtils.compareDateJS(event.finishJS, job.startJS) > 0 && 
            (event.objectType !== OBJECT_TYPE.AVAILABILITY || (event.objectType === OBJECT_TYPE.AVAILABILITY && !event.isAvailable))
          ) {
            break;
          }

          if (this.dateUtils.compareDateJS(event.finishJS, job.startJS) <= 0) {
            previousEvent = event;
          }
          if (this.dateUtils.compareDateJS(event.startJS, job.finishJS) >= 0) {
            nextEvent = event;
          }
        }

        if (previousEvent && previousEvent.longitude) {
          let location1 = {latitude: previousEvent.latitude, longitude: previousEvent.longitude};
          let location2 = {latitude: jobStartLatitude, longitude: jobStartLongitude};
          setOriginsDestinations(location1, location2, travelToMap);
        } 
        
        if (nextEvent && nextEvent.longitude) {
          let location1 = {latitude: jobEndLatitude, longitude: jobEndLongitude};
          let location2 = {latitude: nextEvent.latitude, longitude: nextEvent.longitude};
          setOriginsDestinations(location1, location2, travelToMap);
        }
      });
    });

    this.travelTimeMap = {};
    let service = new skedService();
    let originsDestinationsChunks = [];
    chunk(Object.values(travelToMap.originsMap) || [], MAX_TRAVEL_TIME_ORIGIN_CHUNK_SIZE).forEach(originsMapChunk => {
      const origins = originsMapChunk;
      const destinations = Object.values(travelToMap.destinationsMap) || [];
      originsDestinationsChunks.push({
        origins,
        destinations
      });
    });

    chunk(Object.values(travelBackMap.destinationsMap) || [], MAX_TRAVEL_TIME_ORIGIN_CHUNK_SIZE).forEach(destinationsMapChunk => {
      const origins = Object.values(travelBackMap.originsMap) || [];
      const destinations = destinationsMapChunk;
      originsDestinationsChunks.push({
        origins,
        destinations
      });
    });

    const promises = originsDestinationsChunks.map(originsDestinationsChunk => {
      return () => {
        const origins = originsDestinationsChunk.origins;
        const destinations = originsDestinationsChunk.destinations;
        return service.calculateDistanceMatrix({
          origins: origins.map(item => {
            return {
              lat: item.latitude,
              lng: item.longitude
            }
          }), 
          destinations: destinations.map(item => {
            return {
              lat: item.latitude,
              lng: item.longitude
            }
          }),
          departureTime: this.drive.minShiftStart
        })
        .then(result => {
          const matrixData = result?.returnedData?.result?.matrix || [];
          mapResult(origins, destinations, matrixData);
        })
      };
    });

    return Promise.resolve()
    .then(() => {
      return slwcUtils.serial(promises);
    })
    .then(() => {
      return this.overrideTravelTimeData(this.travelTimeMap);
    })
  }

  overrideTravelTimeData(travelTimeMapData) {
    if(!travelTimeMapData) return;

    const driverJob = this.jobs.find(job => {
      return isJobBelongToDrivingRolesGroup(job, {
        resourceRoleGroups: this.resourceRoleGroups
      })
    });

    if(!driverJob) return travelTimeMapData;

    return Promise.resolve()
    .then(() => {
      const { geoLocationLatitude, geoLocationLongitude } = this.getDriveStagingLocation(this.drive);
      const { latitude, longitude } = driverJob;

      const driveStagingLocationToSiteLocationKey = this.getLocationKey({
        latitude: geoLocationLatitude,
        longitude: geoLocationLongitude
      }, {
        latitude,
        longitude
      });

      const siteLocationTodriveStagingLocationKey =  this.getLocationKey({
        latitude,
        longitude
      }, {
        latitude: geoLocationLatitude,
        longitude: geoLocationLongitude
      });

      if(!slwcUtils.isNullOrEmpty(driverJob.travelTime)) {
        if(travelTimeMapData[driveStagingLocationToSiteLocationKey]) {
          travelTimeMapData[driveStagingLocationToSiteLocationKey].travelTime = driverJob.travelTime;
        } else {
          travelTimeMapData[driveStagingLocationToSiteLocationKey] = {
            travelTime: driverJob.travelTime,
            distance: -1
          }
        }
      }

      if(!slwcUtils.isNullOrEmpty(driverJob.travelTime2)) {
        if(travelTimeMapData[siteLocationTodriveStagingLocationKey]) {
          travelTimeMapData[siteLocationTodriveStagingLocationKey].travelTime = driverJob.travelTime2;
        } else {
          travelTimeMapData[siteLocationTodriveStagingLocationKey] = {
            travelTime: driverJob.travelTime2,
            distance: -1
          }
        }
      }

      return travelTimeMapData;
    })
  }

  retrieveCustomSettings() {
    let settingKeys = ["resourceRoleGroups", "maxCDLDOTDuration", "exceptionSettings"];
    return Promise.resolve()
    .then(() => {
        let service = new dataService();
        return service.getCustomSettings({ settingKeys: settingKeys })
        .then((result) => {
            this.resourceRoleGroups = result.returnedData.resourceRoleGroups;
            this.maxCDLDOTDurationInMinutes = result.returnedData.maxCDLDOTDuration * 60;
            this.exceptionSettings = autoMapper.autoMapperInstance.mapToArray('sked_Exception_Setting__c', result.returnedData.exceptionSettings);
            this.exceptionSettingsMap = keyBy(this.exceptionSettings, "exceptionCode");
        })
    });        
  }

  loadResourceEvents(resourcesMap) {
    Object.keys(resourcesMap).forEach(resourceId => {
      let resource = resourcesMap[resourceId];
      let resourceEvents = resource.events || [];
      let resourceUnavailabilities = (resource.availabilities || []).filter(item => {
        return !item.isAvailable;
      });

      resourceEvents.concat(resourceUnavailabilities).forEach((item) => {
        let tempDt = new Date(item.startDate);
        while (this.dateUtils.compareDateJS(tempDt, item.endDate) <= 0) {
          let dateIso = this.dateUtils.dateToStringNative(tempDt);
          if(resource.mapDateslot[dateIso]) {
            resource.mapDateslot[dateIso].events.push(item);
          }
          tempDt = this.dateUtils.addDay(tempDt, 1);
        }
      });
    })
  }
  
  populateWorkingEvents (resource, inputDates, timezoneSidId) {
    let templateEvents = this.getPatternEvents(resource, inputDates, timezoneSidId);
    let resourceAvailability = [];
    resource.availabilities.filter((item) => {
      return item.isAvailable;
    }).forEach((item) => {
      let tempDt = new Date(item.startDate);
      while (this.dateUtils.compareDateJS(tempDt, new Date(item.endDate)) <= 0) {
        let event = {};
        let isFirstDay = this.dateUtils.compareDateJS(tempDt, new Date(item.startDate)) === 0;
        let isLastDay = this.dateUtils.compareDateJS(tempDt, new Date(item.endDate)) === 0;
        event.id = item.id;
        event.name = item.name;
        event.objectType = OBJECT_TYPE.AVAILABILITY;
        event.start = this.dateUtils.parseDateTimeInfo(tempDt, isFirstDay ? item.startTime : 0);
        event.finish = this.dateUtils.parseDateTimeInfo(isLastDay ? item.endDate : this.dateUtils.addDay(tempDt, 1), isLastDay ? item.endTime : 0);
        this.populateDateTime(event);
        
        resourceAvailability.push(event);
        tempDt = this.dateUtils.addDay(tempDt, 1);
      }
    });

    (resource.customAvailabilities || []).forEach((item) => {
      let tempDt = new Date(item.startDate);
      while (this.dateUtils.compareDateJS(tempDt, new Date(item.endDate)) <= 0) {
        let event = {};
        let isFirstDay = this.dateUtils.compareDateJS(tempDt, new Date(item.startDate)) === 0;
        let isLastDay = this.dateUtils.compareDateJS(tempDt, new Date(item.endDate)) === 0;
        event.id = item.id;
        event.name = item.name;
        event.objectType = OBJECT_TYPE.AVAILABILITY;
        event.start = this.dateUtils.parseDateTimeInfo(tempDt, isFirstDay ? item.startTime : 0);
        event.finish = this.dateUtils.parseDateTimeInfo(isLastDay ? item.endDate : this.dateUtils.addDay(tempDt, 1), isLastDay ? item.endTime : 0);
        this.populateDateTime(event);

        resourceAvailability.push(event);
        tempDt = this.dateUtils.addDay(tempDt, 1);
      }
    });

    resourceAvailability = resourceAvailability.concat(templateEvents);
    resourceAvailability = orderBy(resourceAvailability, [(item) => {
      return item.startDate.getTime();
    }, 'startTime'], ['asc', 'asc']);
    return resourceAvailability;
  }

  generateWorkingTimeForResources(resourcesMap, inputDates, timezoneSidId) {
    let workingEvents = {};
    
    Object.keys(resourcesMap).forEach((resourceId) => {
      let resource = resourcesMap[resourceId];
      if (!resource || resource.resourceType === RESOURCE_TYPE.ASSET) {
        workingEvents[resourceId] = {}
        return;
      }

      let resourceAvailabilities = this.populateWorkingEvents(resource, inputDates, timezoneSidId);
      workingEvents[resourceId] = groupBy(resourceAvailabilities, (item) => {
        return this.dateUtils.dateToStringNative(item.startDate);
      });
    });
    return workingEvents;
  }

  loadWorkingTime(workingTimeResourceMap, resourcesMap, inputDates) {
    
    Object.keys(workingTimeResourceMap).forEach((resourceId) => {
      let resource = resourcesMap[resourceId];
      if (!resource) {
        return;
      }

      for (let i = 0; i < inputDates.length; i++) {
        let inputDate = inputDates[i];
        let dateslot = new dateslotModel({
          timezoneSidId: this.timezoneSidId
        });
        dateslot.startJS = inputDate;
        dateslot.finishJS = this.dateUtils.addDay(inputDate, 1);
        let key = this.dateUtils.dateToStringNative(inputDate);
        if (!resource.mapDateslot) {
          resource.mapDateslot = {};
        }
        resource.mapDateslot[key] = dateslot;
        // if (this.holidays.contains(inputDate)) {
        //     continue;
        // }
        if (resource.resourceType !== 'Asset') {
          dateslot.addEvent(dateslot.startJS, dateslot.finishJS, OBJECT_TYPE.NON_WORKING, false, null);
          let events = workingTimeResourceMap[resourceId][key] || [];
          for (let j = 0; j < events.length; j++) {
            let event = events[j];
            dateslot.addEvent(event.startJS, event.finishJS, OBJECT_TYPE.AVAILABILITY, true, null);
          }
        }
      }
    });
  }

  getPatternEvents(resource, inputDates, timezoneSidId) {
    let resourcePatternEvents = [];
    
    (resource.availabilityPatternResources || []).forEach((availabilityPatternResource) => {
      let patternData = this.availabilityPatternsMap[availabilityPatternResource.availabilityPatternId].pattern;
      patternData = JSON.parse(patternData)
      if (patternData.type === PATTERN_TYPE.WEEKLY) {
        let patternEvents = this.getWeeklyPatternEvents({
          ...availabilityPatternResource,
          resource: resource
        }, patternData, inputDates, timezoneSidId);
        resourcePatternEvents = resourcePatternEvents.concat(patternEvents);
      }
      else if (patternData.type === PATTERN_TYPE.CUSTOM) {
        let patternEvents = this.getCustomPatternEvents(availabilityPatternResource, patternData, inputDates, timezoneSidId);
        resourcePatternEvents = resourcePatternEvents.concat(patternEvents);
      }
    })
    
    return resourcePatternEvents;
  }

  getCustomPatternEvents(patternResource, patternData, inputDates, timezoneSidId) {
    let patternEvents = [];
    let mapDayPattern = {};
    patternData.days.forEach((day) => {
      mapDayPattern[day.day] = day;
    });
    
    inputDates.forEach((inputDate) => {
      if (this.dateUtils.compareDateJS(patternResource.startDate, inputDate) <= 0 && (!patternResource.endDate || this.dateUtils.compareDateJS(inputDate, patternResource.endDate) <= 0)) {
        let daysDifference = this.dateUtils.diffDays(patternResource.startDate, inputDate);
        let dayTh = (patternData.lengthDays == 1 ? 1 : (daysDifference % patternData.lengthDays)) + 1;
        if (mapDayPattern[dayTh]) {
          let day = mapDayPattern[dayTh];
          let dayEvents = this.generateDayEvents(day, inputDate, timezoneSidId);
          patternEvents = patternEvents.concat(dayEvents);
        }
      }
    });

    return patternEvents;
  }

  getWeeklyPatternEvents(patternResource, patternData, inputDates, timezoneSidId) {
    let patternEvents = [];
    let mapWeekdayPattern = {};
    const resource = patternResource.resource;
    const workWeekFirstDay = (get(resource, 'primaryRegion.collectionOperationWorkWeekFirstDay') || 'Sunday').substring(0, 3).toLowerCase();
    const mapWeekdayIndex = slwcUtils.getMapWeekdayIndex(workWeekFirstDay);
    patternData.days.forEach((day) => {
      mapWeekdayPattern[day.weekday.toLowerCase()] = day;
    });
    let startDateWeekday = DateTime.fromISO(isString(patternResource.startDate) ? patternResource.startDate : patternResource.startDate.toISOString()).toFormat('ccc').toLowerCase();
    let startDateWeekdayIndex = mapWeekdayIndex.get(startDateWeekday);
    
    inputDates.forEach((inputDate) => {
      if (this.dateUtils.compareDateJS(patternResource.startDate, inputDate) <= 0 && (!patternResource.endDate || this.dateUtils.compareDateJS(inputDate, patternResource.endDate) <= 0)) {
        let weekday = DateTime.fromJSDate(inputDate).toFormat('ccc').toLowerCase();

        if (mapWeekdayPattern[weekday]) {
          let weekdayIndex = mapWeekdayIndex.get(weekday);
          let daysDifference = this.dateUtils.diffDays(patternResource.startDate, inputDate);
          let weekNo = Math.floor((daysDifference - (weekdayIndex - startDateWeekdayIndex)) / 7) + 1;
          if (patternData.repeatWeeks == 1 || weekNo % patternData.repeatWeeks == 1) {
            if (mapWeekdayPattern[weekday]) {
              let day = mapWeekdayPattern[weekday];
              let dayEvents = this.generateDayEvents(day, inputDate, timezoneSidId);
              patternEvents = patternEvents.concat(dayEvents);
            }
          }
        }
      }
    });
    return patternEvents;
  }

  generateDayEvents(day, inputDateDt, timezoneSidId) {
    let dayEvents = [];
    
    if (day.intervals && day.intervals.length) {
      day.intervals.forEach((interval) => {
        let startWorkingInMinutes = this.dateUtils.convertTimeStrToTimeNumber(interval.startTime);
        let endWorkingInMinutes = this.dateUtils.convertTimeStrToTimeNumber(interval.endTime);
        endWorkingInMinutes = endWorkingInMinutes === 0 ? 2400 : endWorkingInMinutes;
        
        let startDateTimeInfo = this.dateUtils.correctPatternDateTimes(inputDateDt, startWorkingInMinutes, timezoneSidId);
        let endDateTimeInfo = this.dateUtils.correctPatternDateTimes(
          endWorkingInMinutes === 2400 ? this.dateUtils.addDay(inputDateDt, 1) : inputDateDt, 
          endWorkingInMinutes === 2400 ? 0 : endWorkingInMinutes, 
          timezoneSidId
        );
       
        let event = {};
        event.objectType = OBJECT_TYPE.AVAILABILITY;
        event.eventType = 'template';
        event.startDate = startDateTimeInfo.date;
        event.endDate = endDateTimeInfo.date;
        event.startTime = startDateTimeInfo.timeNumber
        event.endTime = endDateTimeInfo.timeNumber;
        event.startJS = startDateTimeInfo.dateTime;
        event.finishJS = endDateTimeInfo.dateTime;
        dayEvents.push(event);
      });
    }
    return dayEvents;
  }

  syncDriveData(drive) {
    if(!drive || !this.drive) return;

    this.drive = {
      ...this.drive,
      ...drive
    }
  }

  isDriverJob(job, onlyCheckResourceRole = false) {
    return isDriverJob(job, onlyCheckResourceRole);
  }

  setupDriverJobs() {
    if(!this.drive || !this.drive.driveShifts) return;

    //reset 
    this.drive.driveShifts.forEach(driveShift => {
      remove(driveShift.jobs, job => {
        return job.id && (job.id.startsWith('driverdot') || job.id.startsWith('drivercdl'));
      });
    });
    
    remove(this.jobs, job => {
      return job.id && (job.id.startsWith('driverdot') || job.id.startsWith('drivercdl'));
    });

    this.drive.driveShifts.forEach(driveShift => {
      let driverJob = driveShift.jobs.find(job => this.isDriverJob(job, true));
      if(!driverJob) {
        driverJob = driveShift.jobs.find(job => this.isDriverJob(job, false));
      }
      if(!driverJob) return;
      if(!driverJob.jobAllocations) {
        driverJob.jobAllocations = [];
      }
      if(!driverJob.jobTags) {
        driverJob.jobTags = [];
      }

      let driverDotJob = cloneDeep(driverJob);
      driverDotJob.id = `driverdot${driverJob.id}`;
      driverDotJob.key = `driverdot${driverJob.key}`;

      if(driverDotJob.resourceRole === 'Driver') {
        driverDotJob.resourceRole = TAG.DRIVER_DOT;
      } else {
        driverDotJob.dualRole = TAG.DRIVER_DOT;
      }

      driverDotJob.isSubJob = true;

      driverDotJob.jobTags.forEach((jobTag) => {
        if (jobTag.tag.name === TAG.DRIVER) {
          jobTag.tag.name = TAG.DRIVER_DOT;
        }
      });
      
      driverDotJob.jobAllocations.forEach(jobAllocation => {
        jobAllocation.jobId = driverDotJob.id;
      });

      remove(driverDotJob.jobAllocations, (jobAllocation) => {
        return !jobAllocation.DOT;
      });

      let driverCdlJob = cloneDeep(driverJob);
      driverCdlJob.id = `drivercdl${driverJob.id}`;
      driverCdlJob.key = `drivercdl${driverJob.key}`;
      if(driverCdlJob.resourceRole === 'Driver') {
        driverCdlJob.resourceRole = TAG.DRIVER_CDL;
      } else {
        driverCdlJob.dualRole = TAG.DRIVER_CDL;
      }
      driverCdlJob.isSubJob = true;

      driverCdlJob.jobTags.forEach((jobTag) => {
        if (jobTag.tag.name === TAG.DRIVER) {
          jobTag.tag.name = TAG.DRIVER_CDL;
        }
      });

      driverCdlJob.jobAllocations.forEach(jobAllocation => {
        jobAllocation.jobId = driverCdlJob.id;
      });

      remove(driverCdlJob.jobAllocations, (jobAllocation) => {
          return !jobAllocation.CDL;
      });
      
      remove(driverJob.jobAllocations, (jobAllocation) => {
        return jobAllocation.CDL || jobAllocation.DOT;
      });

      driveShift.jobs.push(driverDotJob);
      driveShift.jobs.push(driverCdlJob);
      this.jobs.push(driverDotJob);
      this.jobs.push(driverCdlJob);
    });
  }

  calculateDefaultEstimatedTravelTimeForJobAllocation = (travelTimeGroup, job, isTemporaryCO, drive) => {
    const _isJobBelongToDrivingRolesGroup = isJobBelongToDrivingRolesGroup(job, {
      resourceRoleGroups: this.resourceRoleGroups
    })
    const travelRoute = _isJobBelongToDrivingRolesGroup ? travelTimeGroup[RESOURCE_ROLE_GROUP.DRIVING_ROLES] : travelTimeGroup[RESOURCE_ROLE_GROUP.STAFF_ROLES];
    const relocatedDriverTTFromDriveCO = !!this.collectionOperationDataMap[drive.collectionOperationId]?.relocatedDriverTTFromDriveCO;

    let travelTimeTo = 0;
    let travelTimeBack = 0;
    let requiresTravelTime = isJobRequireTravelTimes(isTemporaryCO, job, drive, {
      resourceRoleGroups: this.resourceRoleGroups
    });
    if (requiresTravelTime) {
      travelTimeTo = !slwcUtils.isNullOrEmpty(travelRoute.travelTimeTo) ? Math.ceil(travelRoute.travelTimeTo) : null;
      travelTimeBack = !slwcUtils.isNullOrEmpty(travelRoute.travelTimeBack) ? + Math.ceil(travelRoute.travelTimeBack) : null;

      if(_isJobBelongToDrivingRolesGroup && 
        (!isTemporaryCO || relocatedDriverTTFromDriveCO)) {
        if(!slwcUtils.isNullOrEmpty(job.travelTime)) {
          travelTimeTo = Math.ceil(job.travelTime);
        }

        if(!slwcUtils.isNullOrEmpty(job.travelTime2)) {
          travelTimeBack = Math.ceil(job.travelTime2);
        }
      }
    }
    return {
      travelTimeTo: travelTimeTo,
      travelTimeBack: travelTimeBack
    };
  }

  getExceptionTextByCode(exceptionCode) {
    if(!exceptionCode) return null;
    if (this.exceptionSettingsMap[exceptionCode] && this.exceptionSettingsMap[exceptionCode].exception) {
      return this.exceptionSettingsMap[exceptionCode].exception;
    } 

    return null;
  }

  getTravelRoutesFromResourceToJob(resource, job) {
    if(resource.resourceType !== RESOURCE_TYPE.PERSON) return {};
    let result = {
      [RESOURCE_ROLE_GROUP.DRIVING_ROLES]: null,
      [RESOURCE_ROLE_GROUP.STAFF_ROLES]: null
    }
  
    let resourceOverride = resource.resourceOverrides.find((item) => {
      const isDateValid = item.startDate <= this.dateUtils.dateToStringNative(job.startDate) && this.dateUtils.dateToStringNative(job.endDate) <= item.endDate;
      const isCOValid = item.collectionOperationId === job.collectionOperationId && item.collectionOperationId !== resource.collectionOperationId;
      return isDateValid && isCOValid;
    }); 
    const isTemporaryAllocated = !!resourceOverride;
    const relocatedDriverTTFromDriveCO = !!this.collectionOperationDataMap[this.drive.collectionOperationId]?.relocatedDriverTTFromDriveCO;
    const { geoLocationLatitude: driveStagingLocationLatitude, geoLocationLongitude: driveStagingLocationLongitude } = this.getDriveStagingLocation(this.drive);
    const { geoLocationLatitude: resourceStagingLocationLatitude, geoLocationLongitude: resourceStagingLocationLongitude } = this.getResourceStagingLocation(resource, job.driveDate);
    const { latitude: resourceLatitude, longitude: resourceLongitude } = this.getResourceLocation(resource, {
      latitude: resourceStagingLocationLatitude,
      longitude: resourceStagingLocationLongitude
    });
    
    if (isTemporaryAllocated) {
      if (relocatedDriverTTFromDriveCO) {
        result[RESOURCE_ROLE_GROUP.DRIVING_ROLES] = {
          origin: {
            latitude: resourceLatitude,
            longitude: resourceLongitude
          },
          destination: {
            latitude: driveStagingLocationLatitude,
            longitude: driveStagingLocationLongitude
          }
        }
      } else {
        result[RESOURCE_ROLE_GROUP.DRIVING_ROLES] = {
          origin: {
            latitude: resourceStagingLocationLatitude,
            longitude: resourceStagingLocationLongitude
          },
          destination: {
            latitude: job.latitude,
            longitude: job.longitude
          }
        }
      }
      
      result[RESOURCE_ROLE_GROUP.STAFF_ROLES] = {
        origin: {
          latitude: resourceOverride.isTravelRequired ? resourceOverride.geoLocationLatitude : resourceLatitude,
          longitude: resourceOverride.isTravelRequired ? resourceOverride.geoLocationLongitude : resourceLongitude
        },
        destination: {
          latitude: job.latitude,
          longitude: job.longitude
        }
      }
    } else {
      result[RESOURCE_ROLE_GROUP.DRIVING_ROLES] = {
        origin: {
          latitude: resourceLatitude,
          longitude: resourceLongitude
        },
        destination: {
          latitude: driveStagingLocationLatitude,
          longitude: driveStagingLocationLongitude
        }
      }
  
      result[RESOURCE_ROLE_GROUP.STAFF_ROLES] = {
        origin: {
          latitude: resourceLatitude,
          longitude: resourceLongitude
        },
        destination: {
          latitude: job.latitude,
          longitude: job.longitude
        }
      }
    }
    
    return result;
  }

  buildScheduledAllocations({
    ignoreExistingAllocations = false,
    ignoreDedicatedSiteRule = false
  } = {}) {
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start building data', new Date());

      let resourcesMap = keyBy(this.resources, "id");
      
      let inputDates = compact(uniqBy(
        this.jobs.map((item) => {
          return item.startDate;
        }).concat(this.jobs.map((item) => {
          return item.endDate;
        })), item => this.dateUtils.dateToStringNative(item)
      ));
  
      let inputJobIds = uniq(this.jobs.map(item => item.id));
  
      console.log('>>> before load generateWorkingTimeForResources', new Date());
      let workingTimeResourceMap = this.generateWorkingTimeForResources(resourcesMap, inputDates, this.timezoneSidId);
        
      console.log('>>>>>>> before load working time', new Date());
      this.loadWorkingTime(workingTimeResourceMap, resourcesMap, inputDates);
  
      console.log('>>> Start loading resource events', new Date());
      this.loadResourceEvents(resourcesMap);
        
      console.log('>>> Start prepare travel time matrix', new Date());
      
      return this.prepareCollectionOperationDataMap(uniq([
        ...this.resources.map(resource => resource.collectionOperationId),
        this.drive.collectionOperationId
      ].filter(id => id)))
        .then(() => {
          return this.prepareTravelTimeMatrix(inputJobIds);
        })
        .then(() => {
          console.log('>>> Start calculating availability', new Date());
          this.jobs.forEach((job) => {
            job.possibleAllocations = [];
          });
      
          let removedResourceIds = [];
          this.resources.forEach((resource) => {
            if (!resource.mapDateslot) {
              return;
            }

            let numberOfValidJobs = 0;
            this.jobs.forEach((job) => {
              let resourceLatitude = resource.latitude;
              let resourceLongitude = resource.longitude;
              let jobStartLatitude = job.latitude;
              let jobStartLongitude = job.longitude;
              let jobEndLatitude = job.latitude;
              let jobEndLongitude = job.longitude;
              let resourceCollectionOperationId = resource.collectionOperationId;
              const resourcePrimaryCollectionOperationId = resourceCollectionOperationId;
              const resourceSecondaryCollectionOperationIds = (resource.secondaryCollectionOperations || [])
                .filter(item => {
                  return (!item.startDate || item.startDate <= this.dateUtils.dateToStringNative(job.startDate)) && 
                    (!item.endDate || this.dateUtils.dateToStringNative(job.endDate) <= item.endDate);
                })
                .map(item => item.collectionOperationId);
              let isPrimaryCO = false;
              let isTemporaryCO = false;
              let isSecondaryCO = false;
              let overrideRegion = resource.resourceOverrides.find((item) => {
                return item.startDate <= this.dateUtils.dateToStringNative(job.startDate) && this.dateUtils.dateToStringNative(job.endDate) <= item.endDate;
              }); 
              let exceptionLog = [];
              let resourceIsNotAvailableForCO = false;

              isPrimaryCO = this.validateJobCollectionOperation(job, resourcePrimaryCollectionOperationId);
              if (!isPrimaryCO && !!resourceSecondaryCollectionOperationIds.find(resourceSecondaryCOId => {
                return this.validateJobCollectionOperation(job, resourceSecondaryCOId);
              })) {
                isSecondaryCO = true;
              }

              if (overrideRegion) {
                resourceCollectionOperationId = overrideRegion.collectionOperationId;
      
                if (!this.validateJobCollectionOperation(job, resourceCollectionOperationId)) {
                  resourceIsNotAvailableForCO = true;
                }
                else {
                  if (resourceCollectionOperationId !== resource.collectionOperationId) {
                    isTemporaryCO = true;

                    if(overrideRegion.isTravelRequired) {
                      resourceLatitude = overrideRegion.geoLocationLatitude;
                      resourceLongitude = overrideRegion.geoLocationLongitude;
                    }
                  }
                }
              }

              if(!isTemporaryCO) {
                if(!ignoreDedicatedSiteRule && resource.dedicatedToSiteId && resource.dedicatedToSiteId !== this.drive.driveSiteId) {
                  return;
                }
                const { geoLocationLatitude, geoLocationLongitude } = this.getResourceStagingLocation(resource, job.driveDate);
                jobStartLatitude = geoLocationLatitude;
                jobStartLongitude = geoLocationLongitude;
              }
              
              let isValid = true;
              let dateSlotEvents = [];
              let tempDt = new Date(job.startDate);
              while (this.dateUtils.compareDateJS(tempDt, job.endDate) <= 0) {
                let dateIso = this.dateUtils.dateToStringNative(tempDt);
                if (resource.mapDateslot[dateIso]) {
                  let tempDateSlotEvents = resource.mapDateslot[dateIso].events;
                  dateSlotEvents = dateSlotEvents.concat(tempDateSlotEvents);
                }
                else {
                  isValid = false;
                  break;
                }
                tempDt = this.dateUtils.addDay(tempDt, 1);
              }
              if (!isValid) {
                return;
              }
              
              dateSlotEvents = orderBy(dateSlotEvents, [(item) => {
                return item.startJS.getTime();
              }], ['asc']);
      
              //validate collection operation
              if(!isPrimaryCO &&
                !isSecondaryCO && 
                !isTemporaryCO
              ) {
                resourceIsNotAvailableForCO = true;
              }

              if(resourceIsNotAvailableForCO) {
                let exceptionMsg = 'Resource is not available for Collection Operation';
                if (this.exceptionSettingsMap["RESOURCE_NOT_AVAILABLE_FOR_CO"] && this.exceptionSettingsMap["RESOURCE_NOT_AVAILABLE_FOR_CO"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["RESOURCE_NOT_AVAILABLE_FOR_CO"].exception;
                }

                let exception = {
                  driveId: this.driveId,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: 'RESOURCE_NOT_AVAILABLE_FOR_CO'
                };

                exceptionLog.push(exception);
              }

              //validate maximum working days per week
              if (resource.resourceHoursRecords && resource.maxWorkingDaysPerWeek) {
                const matchedResourceHoursRecord = resource.resourceHoursRecords.find((resourceHoursRecord) => {
                  return this.dateUtils.compareDateJS(this.drive.driveDate, resourceHoursRecord.startDate) >= 0
                      && this.dateUtils.compareDateJS(this.drive.driveDate, resourceHoursRecord.endDate) <= 0
                });

                if (matchedResourceHoursRecord) {
                  let workingDates = new Set([this.drive.driveDate]);
                  (matchedResourceHoursRecord.details || []).forEach(detail => {
                    let tempDt = new Date(detail.startDate);
                    while (this.dateUtils.compareDateJS(tempDt, detail.endDate) <= 0) {
                      workingDates.add(this.dateUtils.dateToStringNative(tempDt));
                      tempDt = this.dateUtils.addDay(tempDt, 1);
                    }
                  });

                  if (workingDates.size > resource.maxWorkingDaysPerWeek) {
                    let exceptionMsg = `Maximum weekly work days violation. Week: ${matchedResourceHoursRecord.startDate}`;
                    if (this.exceptionSettingsMap["MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION"] && this.exceptionSettingsMap["MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION"].exception) {
                      exceptionMsg = this.exceptionSettingsMap["MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION"].exception.replace("{{weekStartDate}}", matchedResourceHoursRecord.startDate);
                    }

                    let exception = {
                      driveId: this.driveId,
                      jobId: job.id,
                      resource: resource.id,
                      exception: exceptionMsg,
                      exceptionCode: 'MAXIMUM_WEEKLY_WORK_DAYS_VIOLATION'
                    };
                    exceptionLog.push(exception);
                  }
                }
              }

              //validate account blacklisted
              if(resource.isAccountBlacklisted) {
                let exceptionMsg = 'Resource in declined account';
                if (this.exceptionSettingsMap["RESOURCE_ACCOUNT_DECLINED"] && this.exceptionSettingsMap["RESOURCE_ACCOUNT_DECLINED"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["RESOURCE_ACCOUNT_DECLINED"].exception;
                }
                let exception = {
                  driveId: this.driveId,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: 'RESOURCE_ACCOUNT_DECLINED'
                };
                exceptionLog.push(exception);
              }
      
              //validate location blacklisted
              if(resource.isLocationBlacklisted) {
                let exceptionMsg = 'Resource in declined location';
                if (this.exceptionSettingsMap["RESOURCE_SITE_DECLINED"] && this.exceptionSettingsMap["RESOURCE_SITE_DECLINED"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["RESOURCE_SITE_DECLINED"].exception;
                }
                let exception = {
                  driveId: this.driveId,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: 'RESOURCE_SITE_DECLINED'
                };
                exceptionLog.push(exception);
              }
      
              //validate tags
              const validTagNames = [];
              const expiredTagNames = [];
              const restrictedTagNames = [];
              (resource.resourceTags || []).forEach((resourceTag) => {
                if(!resourceTag.tag) return;

                const tagStartDateValid = resourceTag.startDate <= job.driveDate;
                const tagRestricted = isResourceTagRestricted(resourceTag, {
                  startDate: job.driveDate,
                  endDate: job.driveDate
                })

                if (tagStartDateValid && !tagRestricted) {
                  validTagNames.push(resourceTag.tag.name);
                } else {
                  if (tagRestricted) {
                    restrictedTagNames.push(resourceTag.tag.name);
                  }
                }
                //console.log('slwc Availator => tagStartDateValid =>',tagStartDateValid,' validTagNames=>',validTagNames,' restrictedTagNames=>',restrictedTagNames);
              });
              (job.jobTags || []).forEach((jobTag) => {
                if (!jobTag.tag) return;

                if (!validTagNames.includes(jobTag.tag.name)) {
                  let tagExceptions = [];
                  if(expiredTagNames.includes(jobTag.tag.name)) {
                    tagExceptions.push({
                      exceptionText: `Expired required tag ${jobTag.tag.name}`,
                      exceptionCode: 'EXPIRED_REQUIRED_TAG'
                    })
                  }

                  if(restrictedTagNames.includes(jobTag.tag.name)) {
                    tagExceptions.push({
                      exceptionText: `Restricted required tag ${jobTag.tag.name}`,
                      exceptionCode: 'RESOURCE_ROLE_RESTRICTED'
                    })
                  }

                  if (!expiredTagNames.includes(jobTag.tag.name) && !restrictedTagNames.includes(jobTag.tag.name)) {
                    tagExceptions.push({
                      exceptionText: `Missing required tag ${jobTag.tag.name}`,
                      exceptionCode: 'MISSING_REQUIRED_TAG'
                    })
                  }

                  tagExceptions.forEach(tagException => {
                    const { exceptionText, exceptionCode } = tagException;
                    let exception = {
                      driveId: this.driveId,
                      jobId: job.id,
                      resourceId: resource.id,
                      exception: exceptionText,
                      exceptionCode: exceptionCode
                    };
  
                    exceptionLog.push(exception);
                  });
                }
              });
      
              let isResourceAvailable = true;
              let isResourceQualified = true;
      
              let previousEvent, nextEvent;

              const sortedJobAllocations = orderBy(resource.events.filter(event => event.objectType === OBJECT_TYPE.JOB_ALLOCATION), ['start'], ['asc']);
              const previousJobAllocation = sortedJobAllocations.findLast(event => {
                return this.dateUtils.compareDateJS(event.startJS, job.startJS) < 0;
              });
              const nextJobAllocation = sortedJobAllocations.find(event => {
                return this.dateUtils.compareDateJS(event.startJS, job.startJS) > 0;
              });

              /* In case of assets, if job start and drive date matches, 
                1. either job actually starts on the drive date
                2. or it starts the day before and it has been transformed to the drive date (fetchAssetData)
              In any case, we need to transform the events as well for a consistent comparison */
              
              if(!job.actualStart) job.actualStart = job.start;
              if(!job.actualFinish) job.actualFinish = job.finish;

              const isEventTransformationNeeded = this.dateUtils.compareDateJS(job.start, job.actualStart) !== 0;

              for (let i = 0; i < dateSlotEvents.length; i++) {
                let event = dateSlotEvents[i];
                if(exceptionLog.find(item => item?.availabilityId === event.id || item?.conflictedJobAllocationId === event.id || item?.activityId === event.id)) continue;
                
                if(isEventTransformationNeeded) {
                  let diff = this.dateUtils.diffDays(event.startJS, event.finishJS);
                  if(diff === 0) diff = this.dateUtils.diffDays(job.startJS, job.finishJS);
                  
                  event = {
                    ...event, 
                    startJS: this.dateUtils.addDay(event.startJS, diff), 
                    finishJS: this.dateUtils.addDay(event.finishJS, diff)
                  };
                }
                
                if (event.objectType === OBJECT_TYPE.JOB_ALLOCATION) {
                  if (!ignoreExistingAllocations) {
                    if (inputJobIds.indexOf(event.jobId) > -1 || event.status === EVENT_STATUS.DECLINED) {
                      continue;
                    }
                  }
                }
                if (this.dateUtils.compareDateJS(job.finishJS, event.startJS) < 0 && nextEvent) {
                  break;
                }
      
                if (this.dateUtils.compareDateJS(event.startJS, job.finishJS) < 0 &&
                  this.dateUtils.compareDateJS(event.finishJS, job.startJS) > 0 && 
                  (event.objectType !== OBJECT_TYPE.AVAILABILITY || (event.objectType === OBJECT_TYPE.AVAILABILITY && !event.isAvailable))
                ) {
                  isResourceAvailable = false;
                  let exception = {
                    driveId: this.driveId,
                    jobId: job.id,
                    resourceId: resource.id,
                    exception: "",
                    exceptionCode: "RESOURCE_TIME_CONFLICT",
                    eventURL:""
                  };
                  if (event.objectType === OBJECT_TYPE.NON_WORKING) {
                    isResourceQualified = false;
                    exception.exception = "Non-working time";
                  }
                  else {
                    exception.exception = "Conflict with " + event.name;
                    if (event.objectType == OBJECT_TYPE.AVAILABILITY && !event.isAvailable) {
                      exception.availabilityId = event.id;
                      exception.exception = event.eventType;

                      if(event.eventType === 'Call Out') {
                        exception.exception = event.callOutType; 
                      }
                    }
                    else if (event.objectType == OBJECT_TYPE.ACTIVITY) {
                      exception.exception = "Conflict with " + event.activityTitle;
                      let baseUrl = window.location.origin;
                      console.log(baseUrl);
                      let fullUrl=baseUrl+'/lightning/r/sked__Activity__c/'+event.id+'/view';
                      exception.eventURL=fullUrl;
                      exception.activityId = event.id;
                    }
                    else if (event.objectType == OBJECT_TYPE.JOB_ALLOCATION) {
                      let baseUrl = window.location.origin;
                      console.log(baseUrl);
                      let fullUrl=baseUrl+'/lightning/r/sked_Drive__c/'+event.driveId+'/view';
                      exception.eventURL=fullUrl;
                      exception.exception = "Conflict with "+event.driveName;
                      exception.conflictedJobAllocationId = event.id;
                    }
                  }
                  exceptionLog.push(exception);
                }
      
                if (this.dateUtils.compareDateJS(event.finishJS, job.startJS) <= 0) {
                  previousEvent = event;
                  // if (event.objectType === OBJECT_TYPE.JOB_ALLOCATION) {
                  //   previousJobAllocation = event;
                  // }
                }
                if (this.dateUtils.compareDateJS(event.startJS, job.finishJS) >= 0) {
                  nextEvent = event;
                  // if (event.objectType === OBJECT_TYPE.JOB_ALLOCATION) {
                  //   nextJobAllocation = event;
                  // }
                }
              }
      
              let travelTimeFrom, travelTimeTo;
              let travelDistanceFrom;
              let startFromLocation, goToLocation;
              
              //default
              if (resourceLongitude) {
                startFromLocation = {latitude: resourceLatitude, longitude: resourceLongitude};
              }

              if(job.resourceRole) {
                if (jobStartLongitude) {
                  if (previousEvent && previousEvent.longitude) {
                    let location1 = {latitude: previousEvent.latitude, longitude: previousEvent.longitude};
                    let location2 = {latitude: jobStartLatitude, longitude: jobStartLongitude};
                    //previous job to current job
                    startFromLocation = location1;
                    goToLocation = location2;
                  } 
                  else {
                    if (resourceLatitude) {
                      let location1 = {latitude: resourceLatitude, longitude: resourceLongitude};
                      let location2 = {latitude: jobStartLatitude, longitude: jobStartLongitude};
                      //resource default location or resource override location to current job
                      startFromLocation = location1;
                      goToLocation = location2;
                    }
                  }
  
                  if(startFromLocation && goToLocation) {
                    travelTimeFrom = this.getTravelTime(startFromLocation, goToLocation);
                    travelDistanceFrom = this.calculateDistance(startFromLocation, goToLocation);
  
                    if(previousEvent && previousEvent.longitude) {
                      if (this.dateUtils.compareDateJS(this.dateUtils.addMinute(previousEvent.finishJS, travelTimeFrom), job.startJS) > 0) {
                        isResourceAvailable = false;
                      }
                    }
                  }
  
                  if (nextEvent && nextEvent.longitude && jobEndLatitude) {
                    let location1 = {latitude: jobEndLatitude, longitude: jobEndLongitude};
                    let location2 = {latitude: nextEvent.latitude, longitude: nextEvent.longitude};
                    travelTimeTo = this.getTravelTime(location1, location2);
                    if (this.dateUtils.compareDateJS(this.dateUtils.addMinute(job.finishJS, travelTimeTo), nextEvent.startJS) > 0) {
                      isResourceAvailable = false;
                    }
                  }
                }

                if (!slwcUtils.isNullOrEmpty(travelTimeFrom) && 
                  !slwcUtils.isNullOrEmpty(resource.maxTravelTime) && 
                  travelTimeFrom > resource.maxTravelTime
                ) {
                  let exceptionMsg = 'Maximum Travel Time Violation';
                  if (this.exceptionSettingsMap["MAXIMUM_TRAVEL_TIME_VIOLATION"] && this.exceptionSettingsMap["MAXIMUM_TRAVEL_TIME_VIOLATION"].exception) {
                    exceptionMsg = this.exceptionSettingsMap["MAXIMUM_TRAVEL_TIME_VIOLATION"].exception;
                  }
                  let exception = {
                    driveId: this.driveId,
                    jobId: job.id,
                    resourceId: resource.id,
                    exception: exceptionMsg,
                    exceptionCode: 'MAXIMUM_TRAVEL_TIME_VIOLATION'
                  };
                  exceptionLog.push(exception);
                }
              }
              
              let isConflict = (previousJobAllocation && this.dateUtils.compareDateJS(previousJobAllocation.finishJS, job.startJS) > 0)
                            || (nextJobAllocation && this.dateUtils.compareDateJS(nextJobAllocation.startJS, job.finishJS) < 0);
              if (!isConflict) {
                if ((previousJobAllocation && this.dateUtils.compareDateJS(previousJobAllocation.finishJS, this.dateUtils.addMinute(job.startJS, -resource.turnaroundTime*60)) > 0)
                  || (nextJobAllocation && this.dateUtils.compareDateJS(nextJobAllocation.startJS, this.dateUtils.addMinute(job.finishJS, resource.turnaroundTime*60)) < 0)) {
                    let exceptionMsg = 'Turnaround Time Violation';
                    if (this.exceptionSettingsMap["TURNAROUND_TIME_VIOLATION"] && this.exceptionSettingsMap["TURNAROUND_TIME_VIOLATION"].exception) {
                      exceptionMsg = this.exceptionSettingsMap["TURNAROUND_TIME_VIOLATION"].exception;
                    }
                    let exception = {
                      driveId: this.driveId,
                      jobId: job.id,
                      resourceId: resource.id,
                      exception: exceptionMsg,
                      exceptionCode: 'TURNAROUND_TIME_VIOLATION'
                    };
                    exceptionLog.push(exception);
                }
              }
              
              const _isJobBelongToDrivingRolesGroup = isJobBelongToDrivingRolesGroup(job, {
                resourceRoleGroups: this.resourceRoleGroups
              });

              if (_isJobBelongToDrivingRolesGroup && this.dateUtils.compareDateJS(job.finishJS, this.dateUtils.addMinute(job.startJS, this.maxCDLDOTDurationInMinutes)) > 0) {
                let exceptionMsg = 'CDL/DOT staff cannot be scheduled to drive a CDL/DOT vehicle for a shift length that exceeds {{hours}} hours';
                if (this.exceptionSettingsMap["CDL_DOT_HOURS_VIOLATION"] && this.exceptionSettingsMap["CDL_DOT_HOURS_VIOLATION"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["CDL_DOT_HOURS_VIOLATION"].exception;
                }
                exceptionMsg = exceptionMsg.replace('{{hours}}', +(this.maxCDLDOTDurationInMinutes / 60).toFixed(3));
      
                let exception = {
                  driveId: this.driveId,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: 'CDL_DOT_HOURS_VIOLATION'
                };
                exceptionLog.push(exception);
              }
      
              let isActive = true;
              let employmentStatus = resource.employmentStatus;
              let isPendingTermination = false;
              if (resource.resourceType === RESOURCE_TYPE.ASSET) {
                isActive = resource.isActive;
              }
              else {
                if (resource.terminationDate && resource.terminationDate <= job.driveDate) {
                  isActive = false;
                  isPendingTermination = true;
                } else if (employmentStatus === RESOURCE_EMPLOYMENT_STATUS.LEAVE) {
                  isActive = resource.anticipatedLeaveReturnDate && resource.anticipatedLeaveReturnDate <= job.driveDate;
                } else if (employmentStatus === RESOURCE_EMPLOYMENT_STATUS.INACTIVE) {
                  isActive = false;
                }
              }
      
              if (!isActive) {
                exceptionLog = [];
                let exceptionCode = 'RESOURCE_IS_INACTIVE';
                let exceptionMsg = 'Resource is inactive';
                if (this.exceptionSettingsMap["RESOURCE_IS_INACTIVE"] && this.exceptionSettingsMap["RESOURCE_IS_INACTIVE"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["RESOURCE_IS_INACTIVE"].exception;
                }

                if (isPendingTermination && this.exceptionSettingsMap["RESOURCE_PENDING_TERMINATION"] && this.exceptionSettingsMap["RESOURCE_PENDING_TERMINATION"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["RESOURCE_PENDING_TERMINATION"].exception;
                  exceptionCode = 'RESOURCE_PENDING_TERMINATION';
                }

                let exception = {
                  driveId: this.driveId,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: exceptionCode
                };
                exceptionLog.push(exception);
              }
              
              let estimatedTravelTimeTo = null;
              let estimatedTravelTimeBack = null;
              let travelTimeGroup = null;
              let estimatedTravelData = null;
              const travelRoutes = this.getTravelRoutesFromResourceToJob(resource, job);
              if(travelRoutes[RESOURCE_ROLE_GROUP.DRIVING_ROLES] && travelRoutes[RESOURCE_ROLE_GROUP.STAFF_ROLES]) {
                const drivingRoleTravelRoute = travelRoutes[RESOURCE_ROLE_GROUP.DRIVING_ROLES];
                const staffRoleTravelRoute = travelRoutes[RESOURCE_ROLE_GROUP.STAFF_ROLES];
                travelTimeGroup = {
                  [RESOURCE_ROLE_GROUP.DRIVING_ROLES]: {
                    travelTimeTo: this.getTravelTime(drivingRoleTravelRoute.origin, drivingRoleTravelRoute.destination),
                    travelDistanceTo: this.calculateDistance(drivingRoleTravelRoute.origin, drivingRoleTravelRoute.destination),
                    travelTimeBack: this.getTravelTime(drivingRoleTravelRoute.destination, drivingRoleTravelRoute.origin),
                    travelDistanceBack: this.calculateDistance(drivingRoleTravelRoute.destination, drivingRoleTravelRoute.origin)
                  },
                  [RESOURCE_ROLE_GROUP.STAFF_ROLES]: {
                    travelTimeTo: this.getTravelTime(staffRoleTravelRoute.origin, staffRoleTravelRoute.destination),
                    travelDistanceTo: this.calculateDistance(staffRoleTravelRoute.origin, staffRoleTravelRoute.destination),
                    travelTimeBack: this.getTravelTime(staffRoleTravelRoute.destination, staffRoleTravelRoute.origin),
                    travelDistanceBack: this.calculateDistance(staffRoleTravelRoute.destination, staffRoleTravelRoute.origin)
                  }
                }
                const travelData = this.calculateDefaultEstimatedTravelTimeForJobAllocation(travelTimeGroup, job, isTemporaryCO, this.drive);
                estimatedTravelTimeTo = travelData?.travelTimeTo;
                estimatedTravelTimeBack = travelData?.travelTimeBack;

                estimatedTravelData = travelTimeGroup[_isJobBelongToDrivingRolesGroup ? RESOURCE_ROLE_GROUP.DRIVING_ROLES : RESOURCE_ROLE_GROUP.STAFF_ROLES];
              }

              let possibleAllocation = {};
              possibleAllocation.resourceId = resource.id;
              possibleAllocation.resource = resource;
              possibleAllocation.jobId = job.id;
              possibleAllocation.job = job;
              possibleAllocation.isResourceAvailable = isResourceAvailable;
              possibleAllocation.isAvailable = possibleAllocation.isResourceAvailable && !exceptionLog.length;
              possibleAllocation.isQualified = isResourceQualified;
              possibleAllocation.previousEvent = previousEvent;
              possibleAllocation.nextEvent = nextEvent;
              possibleAllocation.isTemporaryCO = isTemporaryCO;
              possibleAllocation.isSecondaryCO = isSecondaryCO;
              possibleAllocation.startFromLocation = startFromLocation;
              possibleAllocation.estimatedTravelTimeTo = estimatedTravelTimeTo;
              possibleAllocation.estimatedTravelTimeBack = estimatedTravelTimeBack;
              possibleAllocation.estimatedTravelData = estimatedTravelData;
              if (possibleAllocation.nextEvent) {
                possibleAllocation.travelTimeTo = travelTimeTo;
                possibleAllocation.goToLocation = goToLocation;
              }
              possibleAllocation.travelTimeGroup = travelTimeGroup;
              possibleAllocation.exceptionLog = exceptionLog;
              
              job.possibleAllocations.push(possibleAllocation);
              numberOfValidJobs++;
            });

            if(numberOfValidJobs === 0) {
              removedResourceIds.push(resource.id);
            }
          });
          
          if(removedResourceIds.length) {
            this.resources = this.resources.filter(resource => {
              return !removedResourceIds.includes(resource.id);
            })
          }
          console.log('>>> Finished all', new Date());
          return {
            drive: this.drive,
            resources: this.resources || [],
            possibleAllocations: (this.jobs || []).reduce((result, item) => {
              result = result.concat(item.possibleAllocations || []);
              delete item.possibleAllocations;
              return result;
            }, [])
          }
        });
    });
  }
}

export default {
  getInstance: (data) => {
    return new SlwcAvailator(data);
  },
  isJobRequireTravelTimes,
  isJobBelongToDrivingRolesGroup,
  isDriverJob,
  isResourceTagRestricted
}