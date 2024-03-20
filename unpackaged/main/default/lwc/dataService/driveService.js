import { dataService, queryModelBase, sObjectType } from './base';
import { accountTagService, accountTagQueryModel } from './accountTagService';
import { locationTagService, locationTagQueryModel } from './locationTagService';
import { driveShiftService, driveShiftQueryModel } from './driveShiftService';
import { jobService, jobQueryModel } from './jobService';
import { driveDeliveryJobService, driveDeliveryJobQueryModel } from './driveDeliveryJobService';
import { resourceService, resourceQueryModel } from './resourceService';
import auraProxy from 'c/auraProxy';
import { keyBy, remove } from 'c/lodash';
import { isNullOrEmpty } from 'c/slwcUtils';
import { PROCEDURE_TYPE } from 'c/slwcConstants';

import * as autoMapper from 'c/autoMapper';
import dataStorageInstance from './dataStorage';

class driveService extends dataService {

    constructor() {
        super();
        this.sObjectApiName = 'sked_Drive__c';
    }

    getQueryConditions(query) {
        let queryBuilder = query.getQueryBuilder(this.sObjectApiName);
        if (query.collectionOpId) {
            queryBuilder.addCondition({ template: "sked_Collection_Operation__c = {0}", value: query.collectionOpId, type: "string" });
        }
        if (query.collectionOpIds && query.collectionOpIds.length) {
            queryBuilder.addCondition({ template: "sked_Collection_Operation__c IN {0}", value: query.collectionOpIds, type: "array_string" });
        }
        if (query.territoryKeys && query.territoryKeys.length) {
            queryBuilder.addCondition({ template: "sked_Territory_Key__c IN {0}", value: query.territoryKeys, type: "array_string" });
        }
        if (query.opportunityIds && query.opportunityIds.length) {
            queryBuilder.addCondition({ template: "sked_Opportunity__c IN {0}", value: query.opportunityIds, type: "array_string" });
        }
        if (query.accountIds && query.accountIds.length) {
            queryBuilder.addCondition({ template: 'sked_Account__c IN {0}', value: query.accountIds, type: "array_string" });
        }
        if (query.locationIds && query.locationIds.length) {
            queryBuilder.addCondition({ template: 'sked_Drive_Site__c IN {0}', value: query.locationIds, type: "array_string" });
        }
        if (query.operationTypes && query.operationTypes.length) {
            queryBuilder.addCondition({ template: 'sked_Operation_Type__c IN {0}', value: query.operationTypes, type: "array_string" });
        }
        if (query.accountTypes && query.accountTypes.length) {
            queryBuilder.addCondition({ template: 'sked_Account__r.Type IN {0}', value: query.accountTypes, type: "array_string" });
        }
        if (query.accountIndustryCodes && query.accountIndustryCodes.length) {
            queryBuilder.addCondition({ template: 'sked_Account__r.Industry_Code__c IN {0}', value: query.accountIndustryCodes, type: "array_string" });
        }
        if (query.eventTypes && query.eventTypes.length) {
            queryBuilder.addCondition({ template: 'sked_Type_of_Drive__c IN {0}', value: query.eventTypes, type: "array_string" });
        }
        if (query.excludedIds && query.excludedIds.length) {
            queryBuilder.addCondition({ template: 'Id NOT IN {0}', value: query.excludedIds, type: "array_string" });
        }
        if (query.recruitedBys && query.recruitedBys.length) {
            queryBuilder.addCondition({ template: 'sked_Recruited_By__c IN {0}', value: query.recruitedBys, type: "array_string" });
        }
        if (query.optimizationStatuses && query.optimizationStatuses.length) {
            queryBuilder.addCondition({ template: "sked_Optimization_Status__c IN {0}", value: query.optimizationStatuses, type: "array_string" });
        }
        if (query.pendingActionReasonCodes && query.pendingActionReasonCodes.length) {
            queryBuilder.addCondition({ template: "sked_Pending_Action_Reason_Code__c INCLUDES{0}", value: query.pendingActionReasonCodes, type: "array_string" });
        }
        if (query.pendingActions && query.pendingActions.length) {
            queryBuilder.addCondition({ template: "sked_Pending_Action__c IN {0}", value: query.pendingActions, type: "array_string" });
        }
        if (query.markets && query.markets.length) {
            let marketQueries = [];
            query.markets.map(market => {
                marketQueries.push(`sked_Market__c = '${market}'`);
            })
            queryBuilder.addCondition({ template: `(${marketQueries.join(' OR ')})` });
        }
        if (query.stages && query.stages.length) {
            queryBuilder.addCondition({ template: "sked_Stage__c IN {0}", value: query.stages, type: "array_string" });
        }
        if (query.statuses && query.statuses.length) {
            queryBuilder.addCondition({ template: "sked_Status__c IN {0}", value: query.statuses, type: "array_string" });
        }
        if (query.approvalStatuses && query.approvalStatuses.length) {
            queryBuilder.addCondition({ template: "sked_Approval_Status__c IN {0}", value: query.approvalStatuses, type: "array_string" });
        }
        if (query.siteTypes && query.siteTypes.length) {
            queryBuilder.addCondition({ template: 'sked_Drive_Site__r.sked_Physical_Location_Type__c IN {0}', value: query.siteTypes, type: "array_string" });
        }
        if (query.startDate) {
            queryBuilder.addCondition({ template: "sked_Drive_Date__c >= {0}", value: query.startDate });
        }
        if (query.endDate) {
            queryBuilder.addCondition({ template: "sked_Drive_Date__c <= {0}", value: query.endDate });
        }
        if (query.selectedDates && query.selectedDates.length) {
            queryBuilder.addCondition({ template: "sked_Drive_Date__c IN {0}", value: query.selectedDates, type: "array" });
        }
        if (query.isNotLinkedDrive) {
            if(query.linkedDriveIds && query.linkedDriveIds.length) {
                queryBuilder.addCondition({ template: "(sked_Linked_Drives__c = NULL OR (sked_Linked_Drives__c != NULL AND sked_Linked_Drives__c IN {0}))", value: query.linkedDriveIds, type: "array_string" });
            } else {
                queryBuilder.addCondition({ template: "sked_Linked_Drives__c = NULL" });
            }
        }
        if (query.showOnlyLinkedEvents) {
            queryBuilder.addCondition({template: "sked_Linked_Drives__c != NULL" });
        }
        if(!isNullOrEmpty(query.ufid)) {
            queryBuilder.addCondition({template: "sked_UFID__c LIKE '%{0}%'", value: query.ufid.trim() });
        }
        if (query.procedureTypes && query.procedureTypes.length) {
            if(query.procedureTypes.includes(PROCEDURE_TYPE._2RBC) && query.procedureTypes.includes(PROCEDURE_TYPE.WB)) {
                queryBuilder.addCondition({template: "(sked_WB_Projected_Procedures__c > 0 OR sked_2RBC_Projected_Procedures__c > 0)"});
            } else {
                if(query.procedureTypes.includes(PROCEDURE_TYPE._2RBC)) {
                    queryBuilder.addCondition({template: "sked_2RBC_Projected_Procedures__c > 0"});
                }
    
                if(query.procedureTypes.includes(PROCEDURE_TYPE.WB)) {
                    queryBuilder.addCondition({template: "sked_WB_Projected_Procedures__c > 0"});
                }
            }
        }

        queryBuilder.addCondition({ template: "sked_Surrogate_Drive_for__c = NULL" });

        if (query.accountManagerPortfolioIds && query.accountManagerPortfolioIds.length) {
            queryBuilder.addCondition({ template: "Account_Manager_Portfolio__c IN {0}", value: query.accountManagerPortfolioIds, type: "array_string" });
        }

        if (query.districtManagerPortfolioIds && query.districtManagerPortfolioIds.length) {
            queryBuilder.addCondition({ template: "District_Manager_Portfolio__c IN {0}", value: query.districtManagerPortfolioIds, type: "array_string" });
        }

        queryBuilder.orderClause = "ORDER BY sked_Drive_Date__c ASC";
        //Related List
        if (query.includes(sObjectType.DRIVE_SHIFT)) {
            let subQueryBuilder = query.getQueryBuilder("sked_Drive_Shift__c");
            subQueryBuilder.orderClause = "ORDER BY sked_Start__c ASC";
        }
        if (query.includes(sObjectType.JOB)) {
            let subQueryBuilder = query.getQueryBuilder("sked__Job__c");
        }
        if (query.includes(sObjectType.EXCEPTION)) {
            let subQueryBuilder = query.getQueryBuilder("skedHC__Exception__c");
            subQueryBuilder.addCondition({ template: "skedHC__Status__c != 'Closed'" });
            subQueryBuilder.orderClause = "ORDER BY skedHC__Job__r.Name ASC NULLS LAST";
        }
    }

    getDefaultTags(accountIds = [], driveSiteIds = []) {
        let request = [];
        if (accountIds.length) {
            let accountTagQuery = new accountTagQueryModel();
            accountTagQuery.accountIds = accountIds;
            let accountTagSvc = new accountTagService();
            let accountTagQueryStr = accountTagSvc.buildQuery(accountTagQuery);
            request.push({ 'key': 'AccountTag', 'query': accountTagQueryStr });
        }
        if (driveSiteIds.length) {
            let locationTagQuery = new locationTagQueryModel();
            locationTagQuery.locationIds = driveSiteIds;
            let locationTagSvc = new locationTagService();
            let locationTagQueryStr = locationTagSvc.buildQuery(locationTagQuery);
            request.push({ 'key': 'LocationTag', 'query': locationTagQueryStr });
        }

        return this.queryDataByQueries(request).then((data) => {
            let result = {
                accountTags: [],
                locationTags: []
            };
            let accountTagData = data.find(element => element.key == 'AccountTag');
            if (accountTagData.result && accountTagData.result.length) {
                result.accountTags = autoMapper.autoMapperInstance.mapToArray('sked__Account_Tag__c', accountTagData.result);
            }
            let locationTagData = data.find(element => element.key == 'LocationTag');
            if (locationTagData.result && locationTagData.result.length) {
                result.locationTags = autoMapper.autoMapperInstance.mapToArray('sked_Location_Tag__c', locationTagData.result);
            }

            dataStorageInstance.add(result.accountTags);
            dataStorageInstance.add(result.locationTags);
            return result;
        })
    }

    getDriveById(driveId, driveSubQueryIndicator) {
        let driveQuery = new driveQueryModel();
        driveQuery.recordIds = [driveId];
        if (driveSubQueryIndicator) {
            driveQuery.subQueryIndicator = driveSubQueryIndicator;
        }
        let driveQueryStr = this.buildQuery(driveQuery);

        let driveShiftQuery = new driveShiftQueryModel();
        driveShiftQuery.driveIds = [driveId];
        driveShiftQuery.subQueryIndicator = sObjectType.SLOT | sObjectType.DRIVE_SHIFT_TAG;
        let driveShiftSvc = new driveShiftService();
        let driveShiftQueryStr = driveShiftSvc.buildQuery(driveShiftQuery);

        let jobQuery = new jobQueryModel();
        jobQuery.driveIds = [driveId];
        jobQuery.subQueryIndicator = sObjectType.JOB_ALLOCATION | sObjectType.JOB_TAG;
        let jobSvc = new jobService();
        let jobQueryStr = jobSvc.buildQuery(jobQuery);

        let driveDeliveryJobQuery = new driveDeliveryJobQueryModel();
        driveDeliveryJobQuery.driveIds = [driveId];
        driveDeliveryJobQuery.subQueryIndicator = sObjectType.DRIVE_BAG;
        let driveDeliveryJobSvc = new driveDeliveryJobService();
        let driveDeliveryJobQueryStr = driveDeliveryJobSvc.buildQuery(driveDeliveryJobQuery);

        let request = [
            { 'key': 'drive', 'query': driveQueryStr },
            { 'key': 'driveShift', 'query': driveShiftQueryStr },
            { 'key': 'job', 'query': jobQueryStr },
            { 'key': 'driveDeliveryJob', 'query': driveDeliveryJobQueryStr }
        ];

        return this.queryDataByQueries(request).then((data) => {
            let driveData = data.find(element => element.key == 'drive');
            let drive = autoMapper.autoMapperInstance.mapTo('sked_Drive__c', driveData.result[0]);

            let driveShiftData = data.find(element => element.key == 'driveShift');
            let driveShifts = autoMapper.autoMapperInstance.mapToArray('sked_Drive_Shift__c', driveShiftData.result);

            let jobData = data.find(element => element.key == 'job');
            let jobs = autoMapper.autoMapperInstance.mapToArray('sked__Job__c', jobData.result);

            let driveDeliveryJobData = data.find(element => element.key == 'driveDeliveryJob');
            let driveDeliveryJobs = autoMapper.autoMapperInstance.mapToArray('sked_Drive_Delivery_Job__c', driveDeliveryJobData.result);

            drive.driveShifts = driveShifts;
            drive.driveDeliveryJobs = driveDeliveryJobs;

            let mapDriveShift = new Map();
            driveShifts.forEach((driveShift) => {
                if (!driveShift.driveShiftTags) {
                    driveShift.driveShiftTags = [];
                }

                mapDriveShift.set(driveShift.id, driveShift);
            });

            let mapJobAllocation = new Map();
            let resourceIds = [];
            jobs.forEach((job) => {
                let driveShift = mapDriveShift.get(job.driveShiftId);
                if (driveShift) {
                    if (!driveShift.jobs) {
                        driveShift.jobs = [];
                    }
                    driveShift.jobs.push(job);
                }

                (job.jobAllocations || []).forEach((jobAllocation) => {
                    mapJobAllocation.set(jobAllocation.id, jobAllocation);
                    resourceIds.push(jobAllocation.resourceId);
                });

                dataStorageInstance.add(job);
            });

            let deletedExceptionLogIds = [];
            (drive.exceptionLog || []).forEach((exception) => {
                let jobAllocation = mapJobAllocation.get(exception.jobAllocationId);
                if (jobAllocation) {
                    if (!jobAllocation.exceptionLog) {
                        jobAllocation.exceptionLog = [];
                    }
                    jobAllocation.exceptionLog.push(exception);
                    deletedExceptionLogIds.push(exception.id);
                }
            })

            if (deletedExceptionLogIds.length) {
                remove(drive.exceptionLog || [], exceptionLog => deletedExceptionLogIds.includes(exceptionLog.id))
            }

            if (resourceIds.length) {
                let resourceQuery = new resourceQueryModel();
                resourceQuery.recordIds = resourceIds;
                resourceQuery.subQueryIndicator = sObjectType.RESOURCE_TAG;
                let resourceSvc = new resourceService();

                return resourceSvc.query(resourceQuery)
                    .then((resources) => {
                        let resourcesMap = keyBy(resources, 'id');
                        mapJobAllocation.forEach((ja, jaId) => {
                            ja.resource = ja.resourceId ? resourcesMap[ja.resourceId] : null
                            if (!ja.resource.resourceHoursRecords) {
                                ja.resource.resourceHoursRecords = [];
                            }

                            if (!ja.resource.resourceTags) {
                                ja.resource.resourceTags = [];
                            }
                        })

                        dataStorageInstance.add(drive);
                        return drive;
                    })
            } else {
                dataStorageInstance.add(drive);
                return drive;
            }
        });
    }

    getDrivesByIds(driveIds, excludeExceptions = false) {
        let driveQuery = new driveQueryModel();
        driveQuery.recordIds = driveIds;

        if (!excludeExceptions) {
            driveQuery.subQueryIndicator = sObjectType.EXCEPTION;
        }

        let driveQueryStr = this.buildQuery(driveQuery);

        let driveShiftQuery = new driveShiftQueryModel();
        driveShiftQuery.driveIds = driveIds;
        driveShiftQuery.subQueryIndicator = sObjectType.SLOT | sObjectType.DRIVE_SHIFT_TAG;
        let driveShiftSvc = new driveShiftService();
        let driveShiftQueryStr = driveShiftSvc.buildQuery(driveShiftQuery);

        let jobQuery = new jobQueryModel();
        jobQuery.driveIds = driveIds;
        jobQuery.subQueryIndicator = sObjectType.JOB_ALLOCATION | sObjectType.JOB_TAG;
        let jobSvc = new jobService();
        let jobQueryStr = jobSvc.buildQuery(jobQuery);

        let driveDeliveryJobQuery = new driveDeliveryJobQueryModel();
        driveDeliveryJobQuery.driveIds = driveIds;
        driveDeliveryJobQuery.subQueryIndicator = sObjectType.DRIVE_BAG;
        let driveDeliveryJobSvc = new driveDeliveryJobService();
        let driveDeliveryJobQueryStr = driveDeliveryJobSvc.buildQuery(driveDeliveryJobQuery);

        let request = [
            { 'key': 'drive', 'query': driveQueryStr },
            { 'key': 'driveShift', 'query': driveShiftQueryStr },
            { 'key': 'job', 'query': jobQueryStr },
            { 'key': 'driveDeliveryJob', 'query': driveDeliveryJobQueryStr }
        ];

        return this.queryDataByQueries(request).then((data) => {
            let driveData = data.find(element => element.key == 'drive');
            let drives = autoMapper.autoMapperInstance.mapToArray('sked_Drive__c', driveData.result);

            let driveShiftData = data.find(element => element.key == 'driveShift');
            let driveShifts = autoMapper.autoMapperInstance.mapToArray('sked_Drive_Shift__c', driveShiftData.result);

            let jobData = data.find(element => element.key == 'job');
            let jobs = autoMapper.autoMapperInstance.mapToArray('sked__Job__c', jobData.result);

            let driveDeliveryJobData = data.find(element => element.key == 'driveDeliveryJob');
            let driveDeliveryJobs = autoMapper.autoMapperInstance.mapToArray('sked_Drive_Delivery_Job__c', driveDeliveryJobData.result);

            drives.forEach(drive => {
                drive.driveShifts = driveShifts.filter(driveShift => driveShift.driveId === drive.id);
                drive.driveDeliveryJobs = driveDeliveryJobs.filter(driveDeliveryJob => driveDeliveryJob.driveId === drive.id);

                let mapDriveShift = new Map();
                drive.driveShifts.forEach((driveShift) => {
                    if (!driveShift.driveShiftTags) {
                        driveShift.driveShiftTags = [];
                    }

                    mapDriveShift.set(driveShift.id, driveShift);
                });


                let mapJobAllocation = new Map();
                jobs.forEach((job) => {
                    let driveShift = mapDriveShift.get(job.driveShiftId);
                    if (driveShift) {
                        if (!driveShift.jobs) {
                            driveShift.jobs = [];
                        }

                        driveShift.jobs.push(job);
                    }

                    (job.jobAllocations || []).forEach((jobAllocation) => {
                        mapJobAllocation.set(jobAllocation.id, jobAllocation);
                    });

                    dataStorageInstance.add(job);
                });

                let deletedExceptionLogIds = [];
                (drive.exceptionLog || []).forEach((exception) => {
                    let jobAllocation = mapJobAllocation.get(exception.jobAllocationId);
                    if (jobAllocation) {
                        if (!jobAllocation.exceptionLog) {
                            jobAllocation.exceptionLog = [];
                        }
                        jobAllocation.exceptionLog.push(exception);
                        deletedExceptionLogIds.push(exception.id);
                    }
                })

                if (deletedExceptionLogIds.length) {
                    remove(drive.exceptionLog || [], exceptionLog => deletedExceptionLogIds.includes(exceptionLog.id))
                }
            })

            dataStorageInstance.add(drives);
            return drives;
        });
    }

    getDrivesWithJobs(query) {
        query.subQueryIndicator = sObjectType.DRIVE_SHIFT | sObjectType.JOB;

        return new Promise((resolve, reject) => {
            this.query(query)
                .then((drives) => {
                    drives.forEach((drive) => {
                        let mapDriveShift = new Map();
                        drive.driveShifts.forEach((driveShift) => {
                            mapDriveShift.set(driveShift.id, driveShift);
                        });

                        drive.jobs.forEach((job) => {
                            let driveShift = mapDriveShift.get(job.driveShiftId);
                            if (driveShift) {
                                if (!driveShift.jobs) {
                                    driveShift.jobs = [];
                                }
                                driveShift.jobs.push(job);
                            }
                        });
                        drive.jobs = [];
                    })

                    resolve(drives);
                })
                .catch((error) => {
                    reject(error);
                });
        });
    }

    getDrives_OptimizeDriveList(driveQuery) {
        let driveQueryStr = this.buildQuery(driveQuery);

        let jobQuery = new jobQueryModel();
        jobQuery.isSubDriveQuery = true;
        jobQuery.subQueryIndicator = sObjectType.JOB_ALLOCATION;
        let jobSvc = new jobService();
        let jobQueryStr = jobSvc.buildQuery(jobQuery);

        let request = [
            { 'key': 'drive', 'query': driveQueryStr },
            { 'key': 'job', 'query': jobQueryStr }
        ];

        return this.queryDataByQueries(request).then((data) => {
            let driveData = data.find(element => element.key == 'drive');
            let drives = autoMapper.autoMapperInstance.mapToArray('sked_Drive__c', driveData.result);

            let jobData = data.find(element => element.key == 'job');
            let jobs = autoMapper.autoMapperInstance.mapToArray('sked__Job__c', jobData.result);

            let mapDrive = new Map();
            drives.forEach((drive) => {
                mapDrive.set(drive.id, drive);
            });

            jobs.forEach((job) => {
                let drive = mapDrive.get(job.driveId);
                if (drive) {
                    if (!drive.jobs) {
                        drive.jobs = [];
                    }
                    drive.jobs.push(job);
                }
            });

            dataStorageInstance.add(drives);
            return drives;
        });
    }

    dispatchDrives = (params) => auraProxy.getInstance().dispatchDrives(params);
    captureDriveImpact = (params) => auraProxy.getInstance().captureDriveImpact(params);
    searchDriveSite = (params) => auraProxy.getInstance().searchDriveSite(params);
    getTerritoryKeys = (params) => auraProxy.getInstance().getTerritoryKeys(params);
    validateDraftDrive = (params) => auraProxy.getInstance().validateDraftDrive(params);
}

class driveQueryModel extends queryModelBase {
    accountIds;
    operationTypes;
    accountTypes;
    accountIndustryCodes;
    approvalStatuses;
    collectionOpId;
    collectionOpIds;
    territoryKeys;
    endDate;
    eventTypes;
    excludedIds;
    locationIds;
    market;
    opportunityIds;
    optimizationStatuses;
    pendingActionReasonCodes;
    pendingActions;
    procedureTypes;
    recruitedBys;
    selectedDates;
    siteTypes;
    startDate;
    stages;
    statuses;
    isNotLinkedDrive;
    showOnlyLinkedEvents;
    ufid;
    accountManagerPortfolioIds;
    districtManagerPortfolioIds;
}

export {
    driveService,
    driveQueryModel
}