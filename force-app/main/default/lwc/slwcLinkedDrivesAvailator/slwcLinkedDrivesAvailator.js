import { LightningElement } from 'lwc';
import * as slwcUtils from 'c/slwcUtils';
import * as slwcDateUtils from 'c/slwcDateUtils';
import { DateTime } from 'c/luxon';
import { cloneDeep, minBy, maxBy, keyBy, uniq, remove, orderBy, compact, groupBy, uniqBy, findIndex, isNaN, isString, get} from 'c/lodash';
import {
  sObjectType,
  dataService,
  driveService,
  jobAllocationService,
  skedService
} from 'c/dataService';
import * as autoMapper from 'c/autoMapper';
import { AVAILABILITY_TYPE, TAG, RESOURCE_TYPE, ASSET_TYPE, RESOURCE_ROLE_GROUP, RESOURCE_EMPLOYMENT_STATUS } from 'c/slwcConstants';

const METRES_TO_MILES_CONSTANT = 0.000621371;
const OBJECT_TYPE = {
  NON_WORKING: 'non-working',
  AVAILABILITY: 'availability',
  JOB_ALLOCATION: 'jobAllocation',
  ACTIVITY: 'activity',
  RESOURCE_OVERRIDE: 'resourceOverride'
}
const PATTERN_TYPE = {
  WEEKLY: 'weekly',
  CUSTOM: 'custom'
}
const EVENT_STATUS = {
  DECLINED: 'Declined'
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

class SlwcLinkedDrivesAvailator {
  linkedDrives;
  mapApis;

  //local keepData
  collectionOperationId;
  travelTimeVelocity = 35;
  timezoneSidId = null;
  jobs = [];
  resources = [];
  exceptionSettings = [];
  exceptionSettingsMap;
  availabilityPatterns = [];
  availabilityPatternsMap;
  groupActivities = [];
  resourceRoleGroups = [];
  callOutJobAllocations = [];
  resourceOverrides = [];
  maxCDLDOTDurationInMinutes = 60;
  travelTimeMap = {};

  get dateUtils() {
    return slwcDateUtils.getInstance({
      timezone: this.timezoneSidId
    })
  }

  constructor(data) {
    this.linkedDrives = data.linkedDrives;
    this.mapApis = data.mapApis;

    console.log('>>> Init Linked Drives Availator', this)
  }

  populateDateTime(rawData) {
    let startDateTime = this.dateUtils.getDateTimeInfo(rawData.start);
    if(startDateTime) {
      rawData.startJS = startDateTime.dateTime;
      rawData.startDate = startDateTime.date;
      rawData.startTime = startDateTime.timeNumber
    }

    let endDateTime = this.dateUtils.getDateTimeInfo(rawData.finish || rawData.end);
    if(endDateTime) {
      rawData.finishJS = endDateTime.dateTime;
      rawData.endDate = endDateTime.date;
      rawData.endTime = endDateTime.timeNumber
    }

    return rawData;
  }

  getLocationKey(location1, location2) {
    return `from:${location1.lat}:${location1.lng}|to:${location2.lat}:${location2.lng}`
  }

  getTravelTime(location1, location2) {
    if (!location1 || !location2) {
      return 0;
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
    if (!location1 || !location2) {
      return 0;
    }

    const locationKey = this.getLocationKey(location1, location2);
    if(this.travelTimeMap[locationKey] && !slwcUtils.isNullOrEmpty(this.travelTimeMap[locationKey].distance)) {
      return this.travelTimeMap[locationKey].distance;
    }

    if(!this.mapApis) return 0;
    let distance = 0, point1, point2;
    if (location1 && location1.lat && location1.lng) {
        point1 = new this.mapApis.LatLng(location1.lat, location1.lng);
    }
    if (location2 && location2.lat && location2.lng) {
        point2 = new this.mapApis.LatLng(location2.lat, location2.lng);
    }
    if (point1 && point2) {
        distance = this.mapApis.geometry.spherical.computeDistanceBetween(point1, point2); // in metres
        distance = distance * METRES_TO_MILES_CONSTANT; // convert to miles
    }
    return distance;
  };

  doTransformResources(skedResources, groupActivities, callOutJobAllocations, resourceOverrides) {
    let groupActivitiesMap = keyBy(groupActivities, "id");
    let callOutJobAllocationsMap = groupBy(callOutJobAllocations, "resourceId");
    let resourceOverridesMap = groupBy(resourceOverrides, "resourceId");
    const drive = this.linkedDrives[0];
    return (skedResources || []).map((skedResource) => {
      let resource = autoMapper.autoMapperInstance.mapTo('sked__Resource__c', skedResource);

      resource.isOnCall = false;
      resource.isAccountBlacklisted = false;
      resource.isAccountWhitelisted = false;
      (resource.accountResourceScores || []).forEach((accountResourceScore) => {
        if (accountResourceScore.accountId == drive.accountId) {
          resource.isAccountBlacklisted = accountResourceScore.blacklisted;
          resource.isAccountWhitelisted = accountResourceScore.whitelisted;
        }
      });

      resource.isLocationBlacklisted = false;
      resource.isLocationWhitelisted = false;
      (resource.locationResourceScores || []).forEach((locationResourceScore) => {
        if (locationResourceScore.locationId == drive.driveSiteId) {
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
      
      resource.groupActivities = (resource.activityResources || []).map((activityResource) => {
        // HRP-17888: clone -- shared, the last resource processed set start/finish for all of them.
        let groupActivity = { ...groupActivitiesMap[activityResource.activityId] };
        groupActivity.objectType = OBJECT_TYPE.ACTIVITY;
        groupActivity.start = activityResource.start || groupActivity.start;
        groupActivity.finish = activityResource.finish || groupActivity.finish;
        this.populateDateTime(groupActivity);
        return groupActivity;
      });

      resource.jobAllocations = (resource.jobAllocations || []).map((item) => {
        item.latitude = item.job.latitude;
        item.longitude = item.job.longitude;
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
      })
      
      resource.callOutJobAllocations = (callOutJobAllocationsMap[resource.id] || []).map((jobAllocation) => {
        jobAllocation.objectType = OBJECT_TYPE.JOB_ALLOCATION;
        this.populateDateTime(jobAllocation);
        return jobAllocation;
      });
      resource.callOutJobIds = resource.callOutJobAllocations.map(jobAllocation => jobAllocation.jobId);

      resource.resourceOverrides = resourceOverridesMap[resource.id] || [];

      if(!resource.resourceHoursRecords) {
        resource.resourceHoursRecords = [];
      }

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
      this.populateDateTime(resourceOverride);
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

  doTransformJobs(data) {
    let jobs = (data || []).map((item) => {
      item.objectType = OBJECT_TYPE.JOB_ALLOCATION;
      item.quantity = item.quantity || 0;
      return this.populateDateTime(item);
    })
    jobs = orderBy(jobs, ['start'], ['asc']);
    return jobs;
  }

  fetchJobs(fetchAssetsOnly = false) {
    let service = new driveService();
    const linkedDriveIds = this.linkedDrives.map(linkedDrive => linkedDrive.id);
    return service.getDrivesByIds(linkedDriveIds)
    .then((result) => {
      if(!result) {
        throw Error('Cannot fetch jobs');
      }

      this.linkedDrives = result;
      this.timezoneSidId = this.linkedDrives[0].driveSite && this.linkedDrives[0].driveSite.timezoneSidId;
      this.collectionOperationIds = uniq(this.linkedDrives.map(item => item.collectionOperationId));

      this.linkedDrives.forEach(linkedDrive => {
        linkedDrive.driveShifts.forEach(driveShift => {
          const jobs = this.doTransformJobs(driveShift.jobs);
          jobs.forEach(job => {
            if(fetchAssetsOnly) {
              if(job.assetType === ASSET_TYPE.EQUIPMENT || job.assetType === ASSET_TYPE.VEHICLE) {
                this.jobs.push(job);
              }
            } else {
              this.jobs.push(job);
            }
          })
        });
      })
    });
  }

  fetchResources(pageNo = 1, totalRecords, getAssetsOnly) {
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

    const drive = this.linkedDrives[0];
    let request = {
      accountIds: [drive.accountId],
      collectionOperationIds: this.collectionOperationIds,
      locationIds: [drive.driveSiteId],
      inputDates: inputDates,
      jobIds: this.jobs.filter(job => !!job.id).map(job => job.id),
      pageSize: 200,
      pageNo: pageNo,
      getAssetsOnly: !!getAssetsOnly,
      timezoneSidId: drive.driveSite.timezoneSidId
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

        let returnResourceOverrides = this.doTransformResourceOverrides(result.returnedData.resourceOverrides);
        this.resourceOverrides = this.resourceOverrides.concat(returnResourceOverrides);

        let returnedResources = this.doTransformResources(result.returnedData.resources, this.groupActivities, this.callOutJobAllocations, this.resourceOverrides);
        this.resources = this.resources.concat(returnedResources);

        if (pageNo == 1) {
          totalRecords = result.returnedData.totalRecords;
        }
        if (this.resources.length < totalRecords) {
          return this.fetchResources(pageNo + 1, totalRecords, getAssetsOnly);
        }
      });
  }

  fetchData(fetchAssetsOnly = false) {
    console.log('>>> Start fetching data', new Date());
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start retrieveCustomSettings', new Date());
      return this.retrieveCustomSettings();
    })
    .then(() => {
      console.log('>>> Start fetching jobs', new Date());
      return this.fetchJobs(fetchAssetsOnly);
    })
    .then(() => {
      console.log('>>> Start fetching resources', new Date());
      return this.fetchResources(1, null, fetchAssetsOnly);
    })
    .then(() => {
      console.log('>>> Finished Fetching data', new Date());
      console.log('>>> jobs', this.jobs);
      console.log('>>> resources', this.resources);
    })
  }

  prepareTravelTimeMatrix(inputJobIds) {
    let originsMap = [];
    let destinationsMap = [];

    const setOriginsDestinations = (location1, location2) => {
      const originKey = `${location1.lat}-${location1.lng}`;
      originsMap[originKey] = {
        lat: location1.lat,
        lng: location1.lng
      }

      const destinationKey = `${location2.lat}-${location2.lng}`;
      destinationsMap[destinationKey] = {
        lat: location2.lat,
        lng: location2.lng
      }
    }
    
    this.resources.forEach((resource) => {
      if (!resource.mapDateslot) {
        return;
      }

      this.jobs.forEach((job) => {
        const drive = this.linkedDrives.find(linkedDrive => linkedDrive.id === job.driveId);
        let isTemporaryCO = false;
        let overrideLat = resource.latitude;
        let overrideLng = resource.longitude;
        let resourceCollectionOperationId = resource.collectionOperationId;
        let overrideRegion = resource.resourceOverrides.find((item) => {
          return item.startDate <= this.dateUtils.dateToStringNative(job.startDate) && this.dateUtils.dateToStringNative(job.endDate) <= item.endDate;
        }); 
        if (overrideRegion) {
          resourceCollectionOperationId = overrideRegion.collectionOperationId;

          if (resourceCollectionOperationId !== job.collectionOperationId) {
            return;
          }
          else {
            if (resourceCollectionOperationId !== resource.collectionOperationId) {
              isTemporaryCO = true;
              
              if(overrideRegion.isTravelRequired) {
                overrideLat = overrideRegion.geoLocationLatitude;
                overrideLng = overrideRegion.geoLocationLongitude;
              }
            }
          }
        }

        if(!isTemporaryCO) {
          if(resource.dedicatedToSiteId && resource.dedicatedToSiteId !== drive.driveSiteId) {
            return;
          }
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

        let isResourceAvailable = true;
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
            isResourceAvailable = false;
            break;
          }

          if (this.dateUtils.compareDateJS(event.finishJS, job.startJS) <= 0) {
            previousEvent = event;
          }
          if (this.dateUtils.compareDateJS(event.startJS, job.finishJS) >= 0) {
            nextEvent = event;
          }
        }

        if (job.longitude) {
          if (previousEvent && previousEvent.longitude) {
            let location1 = {lat: previousEvent.latitude, lng: previousEvent.longitude};
            let location2 = {lat: job.latitude, lng: job.longitude};
            setOriginsDestinations(location1, location2);
          } 
          else {
            if (overrideLat) {
              let location1 = {lat: overrideLat, lng: overrideLng};
              let location2 = {lat: job.latitude, lng: job.longitude};
              setOriginsDestinations(location1, location2);
            }
          }
          
          if (nextEvent && nextEvent.longitude) {
            let location1 = {lat: job.latitude, lng: job.longitude};
            let location2 = {lat: nextEvent.latitude, lng: nextEvent.longitude};
            setOriginsDestinations(location1, location2);
          }
        }
      });
    });

    this.travelTimeMap = {};
    let service = new skedService();
    const origins = Object.values(originsMap);
    const destinations = Object.values(destinationsMap);
    return service.calculateDistanceMatrix({
      origins: origins, 
      destinations: destinations
    })
    .then((result) => {
      if(!result || !result.returnedData || !result.returnedData.result || !result.returnedData.result.matrix) return;
      const matrixData = result.returnedData.result.matrix || [];
      
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
        event.startDate = tempDt;
        event.startTime = isFirstDay ? item.startTime : 0;
        event.endDate = isLastDay ? item.endDate : this.dateUtils.addDay(tempDt, 1);
        event.endTime = isLastDay ? item.endTime : 0;
        resourceAvailability.push(event);
        tempDt = this.dateUtils.addDay(tempDt, 1);
      }
    })

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

  getExceptionTextByCode(exceptionCode) {
    if(!exceptionCode) return null;
    if (this.exceptionSettingsMap[exceptionCode] && this.exceptionSettingsMap[exceptionCode].exception) {
      return this.exceptionSettingsMap[exceptionCode].exception;
    } 

    return null;
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
          let weekNo = ((daysDifference - (weekdayIndex - startDateWeekdayIndex)) / 7) + 1;
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

  calculateDefaultEstimatedTravelTimeForJobAllocation = (travelTimeFrom, drive, resource, job) => {
    let defaultEstimatedTravelTime = 0;
    let isResourceDriveSameCo = resource.collectionOperationId === drive.collectionOperationId;
    let isTravelTimeIncludedForAllRoles = drive.travelTimeIncluded === 'All Roles';

    const resourceRoleGroup = Object.keys(this.resourceRoleGroups).find(resourceRoleGroup => {
      return !!this.resourceRoleGroups[resourceRoleGroup].find(item => item === job.resourceRole);
    })
    const isDriver = resourceRoleGroup === RESOURCE_ROLE_GROUP.DRIVING_ROLES;

    let requiresTravelTime = !isResourceDriveSameCo || (!isDriver && isTravelTimeIncludedForAllRoles);
    if (requiresTravelTime) {
      defaultEstimatedTravelTime = !slwcUtils.isNullOrEmpty(travelTimeFrom) ? + Math.ceil(travelTimeFrom).toFixed(0) : null;
    }
    return defaultEstimatedTravelTime;
  }

  isDriverJob(job) {
    if(!job) return false;
    const isNotCdlDriverJob = job.id && !job.id.startsWith('drivercdl');
    const isNotDotDriverJob = job.id && !job.id.startsWith('driverdot');
    return isNotCdlDriverJob && isNotDotDriverJob && (job.resourceRole === 'Driver' || job.dualRole === 'Driver')
  }
  
  setupDriverJobs() {
    remove(this.jobs, job => {
      return job.id && (job.id.startsWith('driverdot') || job.id.startsWith('drivercdl'));
    });

    this.linkedDrives.forEach(drive => {
      if(!drive || !drive.driveShifts) return;

      //reset 
      drive.driveShifts.forEach(driveShift => {
        remove(driveShift.jobs, job => {
          return job.id && (job.id.startsWith('driverdot') || job.id.startsWith('drivercdl'));
        });
      });

      drive.driveShifts.forEach(driveShift => {
        const driverJob = driveShift.jobs.find(job => this.isDriverJob(job));
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
    });
  }

  buildScheduledAllocations({
    ignoreDedicatedSiteRule = false
  } = {}) {
    return Promise.resolve()
    .then(() => {
      console.log('>>> Start building data', new Date());

      let resourcesMap = keyBy(this.resources, "id");
      
      let inputDates = uniqBy(
        this.jobs.map((item) => {
          return item.startDate;
        }).concat(this.jobs.map((item) => {
          return item.endDate;
        })), item => this.dateUtils.dateToStringNative(item)
      );

      let inputJobIds = uniq(this.jobs.map(item => item.id));

      console.log('>>> before load generateWorkingTimeForResources', new Date());
      let workingTimeResourceMap = this.generateWorkingTimeForResources(resourcesMap, inputDates, this.timezoneSidId);

      console.log('>>>>>>> before load working time', new Date());
      this.loadWorkingTime(workingTimeResourceMap, resourcesMap, inputDates);

      console.log('>>> Start loading resource events', new Date());
      this.loadResourceEvents(resourcesMap);

      console.log('>>> Start prepare travel time matrix', new Date());
      return this.prepareTravelTimeMatrix(inputJobIds)
        .then(() => {
          console.log('>>> Start calculating availability', new Date());
          this.resources.forEach((resource) => {
            resource.possibleAllocations = [];
          });

          this.resources.forEach((resource) => {     
            if (!resource.mapDateslot) {
              return;
            }

            this.jobs.forEach((job) => {
              const drive = this.linkedDrives.find(linkedDrive => linkedDrive.id === job.driveId);
              let overrideLat = resource.latitude;
              let overrideLng = resource.longitude;
              let isTemporaryCO = false;
              let resourceCollectionOperationId = resource.collectionOperationId;
              let overrideRegion = resource.resourceOverrides.find((item) => {
                return item.startDate <= this.dateUtils.dateToStringNative(job.startDate) && this.dateUtils.dateToStringNative(job.endDate) <= item.endDate;
              }); 
              let exceptionLog = [];
              let resourceIsNotAvailableForCO = false;

              if (overrideRegion) {
                resourceCollectionOperationId = overrideRegion.collectionOperationId;

                if (resourceCollectionOperationId !== job.collectionOperationId) {
                  resourceIsNotAvailableForCO = true;
                }
                else {
                  if (resourceCollectionOperationId !== resource.collectionOperationId) {
                    isTemporaryCO = true;

                    if(overrideRegion.isTravelRequired) {
                      overrideLat = overrideRegion.geoLocationLatitude;
                      overrideLng = overrideRegion.geoLocationLongitude;
                    }
                  }
                }
              }

              if(!isTemporaryCO) {
                if(!ignoreDedicatedSiteRule && resource.dedicatedToSiteId && resource.dedicatedToSiteId !== drive.driveSiteId) {
                  return;
                }
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
              const resourcePrimaryCollectionOperationId = resourceCollectionOperationId;
              const resourceSecondaryCollectionOperationIds = (resource.secondaryCollectionOperations || []).map(item => item.collectionOperationId);
              
              if(resourcePrimaryCollectionOperationId !== job.collectionOperationId &&
                !resourceSecondaryCollectionOperationIds.includes(job.collectionOperationId) && 
                !isTemporaryCO ) {
                resourceIsNotAvailableForCO = true;
              }

              if(resourceIsNotAvailableForCO) {
                let exceptionMsg = 'Resource is not available for Collection Operation';
                if (this.exceptionSettingsMap["RESOURCE_NOT_AVAILABLE_FOR_CO"] && this.exceptionSettingsMap["RESOURCE_NOT_AVAILABLE_FOR_CO"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["RESOURCE_NOT_AVAILABLE_FOR_CO"].exception;
                }

                let exception = {
                  driveId: drive.id,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: 'RESOURCE_NOT_AVAILABLE_FOR_CO'
                };

                exceptionLog.push(exception);
              }
              
              //validate account blacklisted
              if(resource.isAccountBlacklisted) {
                let exceptionMsg = 'Resource in declined account';
                if (this.exceptionSettingsMap["RESOURCE_ACCOUNT_DECLINED"] && this.exceptionSettingsMap["RESOURCE_ACCOUNT_DECLINED"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["RESOURCE_ACCOUNT_DECLINED"].exception;
                }
                let exception = {
                  driveId: drive.id,
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
                  driveId: drive.id,
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
                const tagRestricted = resourceTag.restrictionStartDate && resourceTag.restrictionEndDate && 
                  resourceTag.restrictionStartDate <= job.driveDate && resourceTag.restrictionEndDate >= job.driveDate;

                if (tagStartDateValid && !tagRestricted) {
                  validTagNames.push(resourceTag.tag.name);
                } else {
                  if (tagRestricted) {
                    restrictedTagNames.push(resourceTag.tag.name);
                  }
                }
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

                  if (!expiredTagNames.includes(jobTag.tag.name) && !restrictedTagNames.includes(jobTag.tag.nam)) {
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
                  isResourceAvailable = false;
                  let exception = {
                    driveId: job.driveId,
                    jobId: job.id,
                    resourceId: resource.id,
                    exception: "",
                    exceptionCode: "RESOURCE_TIME_CONFLICT"
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
                    }
                    else if (event.objectType == OBJECT_TYPE.ACTIVITY) {
                      exception.activityId = event.id;
                    }
                    else if (event.objectType == OBJECT_TYPE.JOB_ALLOCATION) {
                      exception.conflictedJobAllocationId = event.id;
                    }
                  }
                  exceptionLog.push(exception);
                  break;
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

              if (resource.longitude) {
                startFromLocation = {lat: resource.latitude, lng: resource.longitude};
              }
              if (job.longitude) {
                if (previousEvent && previousEvent.longitude) {
                  let location1 = {lat: previousEvent.latitude, lng: previousEvent.longitude};
                  let location2 = {lat: job.latitude, lng: job.longitude};
                  //previous job to current job
                  startFromLocation = location1;
                  goToLocation = location2;
                } 
                else {
                  if (overrideLat) {
                    let location1 = {lat: overrideLat, lng: overrideLng};
                    let location2 = {lat: job.latitude, lng: job.longitude};
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

                if (nextEvent && nextEvent.longitude) {
                  let location1 = {lat: job.latitude, lng: job.longitude};
                  let location2 = {lat: nextEvent.latitude, lng: nextEvent.longitude};
                  travelTimeTo = this.getTravelTime(location1, location2);
                  if (this.dateUtils.compareDateJS(this.dateUtils.addMinute(job.finishJS, travelTimeTo), nextEvent.startJS) > 0) {
                    isResourceAvailable = false;
                  }
                }
              }
              const estimatedTravelTime = this.calculateDefaultEstimatedTravelTimeForJobAllocation(travelTimeFrom, drive, resource, job);
              if (!slwcUtils.isNullOrEmpty(resource.maxTravelTime) && travelTimeFrom > resource.maxTravelTime) {
                let exceptionMsg = 'Maximum Travel Time Violation';
                if (this.exceptionSettingsMap["MAXIMUM_TRAVEL_TIME_VIOLATION"] && this.exceptionSettingsMap["MAXIMUM_TRAVEL_TIME_VIOLATION"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["MAXIMUM_TRAVEL_TIME_VIOLATION"].exception;
                }
                let exception = {
                  driveId: drive.id,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: 'MAXIMUM_TRAVEL_TIME_VIOLATION'
                };
                exceptionLog.push(exception);
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
                      driveId: drive.id,
                      jobId: job.id,
                      resourceId: resource.id,
                      exception: exceptionMsg,
                      exceptionCode: 'TURNAROUND_TIME_VIOLATION'
                    };
                    exceptionLog.push(exception);
                }
              }
              
              let hasDrivingRole = false;
              Object.keys(this.resourceRoleGroups).forEach((key) => {
                if (key === 'Driving roles') {
                  return this.resourceRoleGroups[key].forEach((item) => {
                    if (item === job.resourceRole) {
                      hasDrivingRole = true;
                    }
                  });
                }
              });

              if (hasDrivingRole && this.dateUtils.compareDateJS(job.finishJS, this.dateUtils.addMinute(job.startJS, this.maxCDLDOTDurationInMinutes)) > 0) {
                let exceptionMsg = 'CDL/DOT staff cannot be scheduled to drive a CDL/DOT vehicle for a shift length that exceeds {{hours}} hours';
                if (this.exceptionSettingsMap["CDL_DOT_HOURS_VIOLATION"] && this.exceptionSettingsMap["CDL_DOT_HOURS_VIOLATION"].exception) {
                  exceptionMsg = this.exceptionSettingsMap["CDL_DOT_HOURS_VIOLATION"].exception;
                }
                exceptionMsg = exceptionMsg.replace('{{hours}}', +(this.maxCDLDOTDurationInMinutes / 60).toFixed(3));

                let exception = {
                  driveId: drive.id,
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
                  driveId: drive.id,
                  jobId: job.id,
                  resourceId: resource.id,
                  exception: exceptionMsg,
                  exceptionCode: exceptionCode
                };
                exceptionLog.push(exception);
              }

              let possibleAllocation = {};
              possibleAllocation.resourceId = resource.id;
              possibleAllocation.resource = resource;
              possibleAllocation.jobId = job.id;
              possibleAllocation.job = job;
              possibleAllocation.startFromLocation = startFromLocation;
              possibleAllocation.travelTimeFrom = travelTimeFrom;
              possibleAllocation.estimatedTravelTime = estimatedTravelTime;
              possibleAllocation.travelDistanceFrom = travelDistanceFrom;
              possibleAllocation.isAvailable = isResourceAvailable && !exceptionLog.length;
              possibleAllocation.isQualified = isResourceQualified;
              possibleAllocation.previousEvent = previousEvent;
              possibleAllocation.nextEvent = nextEvent;
              possibleAllocation.isTemporaryCO = isTemporaryCO;
              if (possibleAllocation.nextEvent) {
                possibleAllocation.travelTimeTo = travelTimeTo;
                possibleAllocation.goToLocation = goToLocation;
              }
              possibleAllocation.exceptionLog = exceptionLog;

              resource.possibleAllocations.push(possibleAllocation);
            });
          });
      
          console.log('>>> Finished all', new Date());
          return {
            linkedDrives: this.linkedDrives,
            resources: this.resources || [],
            possibleAllocations: (this.resources || []).reduce((result, item) => {
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
    return new SlwcLinkedDrivesAvailator(data);
  }
}