public class skedJobAllocationTravelTimeService {
    private static List<String> drivingRoles {
        get {
            if (drivingRoles == null) {
                drivingRoles = new List<String>();
                List<sked_Resource_Role_Group__c> drivingRoleGroupQuery = [SELECT Id, sked_Resource_Roles__c
                                                                        FROM sked_Resource_Role_Group__c
                                                                        WHERE sked_Resource_Role_Group__c = 'Driving roles'];
                if (!drivingRoleGroupQuery.isEmpty()) {
                    sked_Resource_Role_Group__c drivingRoleGroup = drivingRoleGroupQuery.get(0);
                    if (drivingRoleGroup.sked_Resource_Roles__c != NULL) {
                        drivingRoles = drivingRoleGroup.sked_Resource_Roles__c.split(';');
                    }
                }
            }
            return drivingRoles;
        }
        private set;
    }

    private static skedSkeduloApiManager apiManager {
        get {
            if (apiManager == null) {
                apiManager = new skedSkeduloApiManager();
            }
            return apiManager;
        }
        private set;
    }

    public static jobAllocationTravelDataResult calculateTravelTime(jobAllocationTravelDataRequest request) {
        List<jobAllocationModel> jobAllocationModels = fetchJobAllocationData(request.jobAllocationRequestModels);
        calculateTravelTime(jobAllocationModels);

        jobAllocationTravelDataResult result = new jobAllocationTravelDataResult();
        result.collect(jobAllocationModels);
        return result;
    }

    ///////////////////////////// Private Methods /////////////////////////////
    private static List<jobAllocationModel> fetchJobAllocationData(List<jobAllocationRequestModel> jobAllocationRequests) {
        Set<Id> jobAllocationIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        for (jobAllocationRequestModel request : jobAllocationRequests) {
            if (request.jobAllocationId != NULL) {
                jobAllocationIds.add(request.jobAllocationId);
            } else {
                resourceIds.add(request.resourceId);
                jobIds.add(request.jobId);
            }
        }

        Map<Id, sked__Job_Allocation__c> map_id_jobAllocation = getMapJobAllocation(jobAllocationIds);
        Map<Id, sked__Resource__c> map_id_resource = getMapResource(resourceIds);
        Map<Id, sked__Job__c> map_id_job = getMapJob(jobIds);

        List<jobAllocationModel> jobAllocationModels = new List<jobAllocationModel>();
        for (jobAllocationRequestModel request: jobAllocationRequests) {
            jobAllocationModel model;
            if (request.jobAllocationId != NULL) {
                model = initJobAllocationModelByJobAllocationId(request.jobAllocationId, map_id_jobAllocation);
            } else {
                model = initJobAllocationModelByResourceIdAndJobId(request.resourceId, request.jobId, map_id_resource, map_id_job);
            }

            if (model != null) {
                jobAllocationModels.add(model);
            }
        }

        return jobAllocationModels;
    }

    private static jobAllocationModel initJobAllocationModelByJobAllocationId(Id jobAllocationId, Map<Id, sked__Job_Allocation__c> map_id_jobAllocation) {
        jobAllocationModel model;
        sked__Job_Allocation__c jobAllocation = map_id_jobAllocation.get(jobAllocationId);
        if (jobAllocation != null) {
            model = new jobAllocationModel(jobAllocation);
        }

        return model;
    }

    private static jobAllocationModel initJobAllocationModelByResourceIdAndJobId(Id resourceId, Id jobId, Map<Id, sked__Resource__c> map_id_resource, Map<Id, sked__Job__c> map_id_job) {
        jobAllocationModel model;
        sked__Resource__c resource = map_id_resource.get(resourceId);
        sked__Job__c job = map_id_job.get(jobId);
        if (resource != null && job != null) {
            model = new jobAllocationModel(resource, job);
        }

        return model;
    }

    private static Map<Id, sked__Job_Allocation__c> getMapJobAllocation(Set<Id> jobAllocationIds) {
        return new Map<Id, sked__Job_Allocation__c>([
            SELECT Id,
                sked_GeoService_Travel_Time_To__c, sked_GeoService_Travel_Distance_To__c,
                sked_Geoservice_Travel_Time_Back__c, sked_GeoService_Travel_Distance_Back__c,
                sked_Travel_Time_To__c, sked_Travel_Time_Back__c, sked_Is_Relocated_Resource__c,
                sked__Start__c, sked__Set_End__c, sked__Duration__c,
                sked__Job__r.sked_Travel_Time__c, sked__Job__r.sked_Travel_Time2__c,
                sked__Job__r.sked__Start__c, sked__Job__r.sked__Finish__c,
                sked__Job__r.sked_Resource_Role__c, 
                sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c,
                sked__Job__r.sked_Drive__r.sked_Drive_Date__c,
                sked__Job__r.sked_Drive__r.sked_Drive_Site__c,
                sked__Job__r.sked_Drive__r.sked_Travel_Time_Included__c,
                sked__Job__r.sked_Drive__r.sked_Collection_Operation__c,
                sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                 sked__Job__r.sked_Dual_Role__c
            FROM sked__Job_Allocation__c
            WHERE Id IN :jobAllocationIds
            AND sked__Job__r.sked_Drive__r.sked_Collection_Operation__c != NULL
            AND sked__Job__r.sked_Drive__r.sked_Drive_Site__c != NULL
        ]);
    }

    private static Map<Id, sked__Resource__c> getMapResource(Set<Id> resourceIds) {
        return new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    }

    private static Map<Id, sked__Job__c> getMapJob(Set<Id> jobIds) {
        return new Map<Id, sked__Job__c>([
            SELECT Id,sked_Travel_Time__c, sked_Travel_Time2__c,
                sked__Start__c, sked__Finish__c, sked__Duration__c,
                sked_Resource_Role__c, 
                sked_Dual_Role__c,
                sked_Drive__r.sked_Type_of_Drive__c,
                sked_Drive__r.sked_Drive_Date__c,
                sked_Drive__r.sked_Drive_Site__c,
                sked_Drive__r.sked_Travel_Time_Included__c,
                sked_Drive__r.sked_Collection_Operation__c
            FROM sked__Job__c
            WHERE Id IN :jobIds
            AND sked_Drive__r.sked_Collection_Operation__c != NULL
            AND sked_Drive__r.sked_Drive_Site__c != NULL
        ]);
    }

    private static void calculateTravelTime(List<jobAllocationModel> jobAllocationModels) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Id> driveIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> siteIds = new Set<Id>();
        
        Date firstDriveDate = System.today();
        Date lastDriveDate = System.today();
        
        for (jobAllocationModel jobAllocationModel : jobAllocationModels) {
        	collectionOperationIds.add(jobAllocationModel.jobDriveCollectionOperationId);
            collectionOperationIds.add(jobAllocationModel.resourcePrimaryCollectionOperationId);
            
            driveIds.add(jobAllocationModel.jobDriveId);
            
            resourceIds.add(jobAllocationModel.resourceId);
            
            siteIds.add(jobAllocationModel.jobDriveSiteId);
            
            if (jobAllocationModel.jobDriveDate < firstDriveDate) {
                firstDriveDate = jobAllocationModel.jobDriveDate;
            }

            if (jobAllocationModel.jobDriveDate > lastDriveDate) {
                lastDriveDate = jobAllocationModel.jobDriveDate;
            }
        }

        Map<Id, sked__Resource__c> mapResourceById = getMapResource(resourceIds, firstDriveDate, lastDriveDate);
        Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById = getMapCollectionOperation(collectionOperationIds);
        Map<Id, sked__Location__c> mapSiteById = getMapSite(siteIds);
        masterDataWrapper data = initializeDistanceMatrixData(jobAllocationModels, mapResourceById, mapCollectionOperationById, mapSiteById);
        data.mapTravelElementByLatLngKey = getTravelTimeDictionary(data);
        Map<Id, sked__Job__c> mapDriverJobByDriveId = getMapDriveAndDriverJob(driveIds);
        overrideTravelTimeDictionary(data, mapDriverJobByDriveId);
        
        for (jobAllocationModel jobAllocationModel : jobAllocationModels) {
            populateJobAllocationTravelData(data, jobAllocationModel);
        }
    }

    private static Map<Id, sked__Resource__c> getMapResource(Set<Id> resourceIds, Date firstDriveDate, Date lastDriveDate) {
        return new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
            sked_Address_Referenced_for_Scheduling__c, Use_CO_Address_for_Scheduling__c,
            sked__Geolocation__Latitude__s, sked__Geolocation__Longitude__s,
            (SELECT Id, sked_Collection_Operation__c, sked_Start_Date__c, sked_End_Date__c,
             sked__Geolocation__Latitude__s, sked__Geolocation__Longitude__s,
             sked_Is_Travel_Required__c
             FROM sked__Resource_Overrides__r
             WHERE sked_End_Date__c >= :firstDriveDate AND sked_Start_Date__c <= :lastDriveDate)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    }

    private static Map<Id, Biomed_Collection_Op_Center__c> getMapCollectionOperation(Set<Id> collectionOperationIds) {
        return new Map<Id, Biomed_Collection_Op_Center__c>([
            SELECT Id, sked_No_Travel_Time__c, sked_Relocated_Driver_TT_from_Drive_CO__c,
            (SELECT Id, sked_Start_Date__c, sked_End_Date__c,
             sked_Staging_Location__r.sked_Geolocation__Latitude__s,
             sked_Staging_Location__r.sked_Geolocation__Longitude__s
             FROM sked_Collection_Op_Staging_Locations__r)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id IN :collectionOperationIds
        ]);
    }

    private static Map<Id, sked__Location__c> getMapSite(Set<Id> siteIds) {
        return new Map<Id, sked__Location__c>([
            SELECT Id, sked__Geolocation__Latitude__s, sked__Geolocation__Longitude__s
            FROM sked__Location__c
            WHERE Id IN :siteIds
        ]);
    }

    private static masterDataWrapper initializeDistanceMatrixData(
        List<jobAllocationModel> jobAllocationModels, 
        Map<Id, sked__Resource__c> mapResourceById,
        Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById,
        Map<Id, sked__Location__c> mapSiteById) 
    {
        masterDataWrapper result = new masterDataWrapper();
        result.mapCollectionOperationById = mapCollectionOperationById;
        result.mapSiteById = mapSiteById;
        
        Map<String, skedSkeduloApiData.latlng> mapOriginByKey = new Map<String, skedSkeduloApiData.latlng>(); 
        Map<String, skedSkeduloApiData.latlng> mapOriginByGeoKey = new Map<String, skedSkeduloApiData.latlng>();
        
        Map<String, skedSkeduloApiData.latlng> mapDestinationByKey = new Map<String, skedSkeduloApiData.latlng>(); 
        Map<String, skedSkeduloApiData.latlng> mapDestinationByGeoKey = new Map<String, skedSkeduloApiData.latlng>();
        
        for (jobAllocationModel jobAllocationModel : jobAllocationModels) {
            Date driveDate = jobAllocationModel.jobDriveDate;
            boolean isDrivingRoleJob = drivingRoles.contains(jobAllocationModel.jobResourceRole) ||  drivingRoles.contains(jobAllocationModel.jobDualRole);
            
            Id driveCollectionOperationId = jobAllocationModel.jobDriveCollectionOperationId;
            Biomed_Collection_Op_Center__c driveCo = mapCollectionOperationById.get(driveCollectionOperationId);
            
            sked__Resource__c skedResource = mapResourceById.get(jobAllocationModel.resourceId);
            skedSkeduloApiData.latlng origin = getResourceGeolocation(skedResource, mapCollectionOperationById, driveDate);
            
            boolean isRelocatedResource = FALSE;
            if (skedResource.sked__Resource_Overrides__r != NULL && !skedResource.sked__Resource_Overrides__r.isEmpty()) {
                for (sked__Resource_Override__c temporaryLocation : skedResource.sked__Resource_Overrides__r) {
                    boolean isCOMatched = temporaryLocation.sked_Collection_Operation__c == jobAllocationModel.jobDriveCollectionOperationId;
                    boolean isDriveDateMatched = temporaryLocation.sked_Start_Date__c <= driveDate && temporaryLocation.sked_End_Date__c >= driveDate;
                    
                    if (isCOMatched && isDriveDateMatched) {
                        isRelocatedResource = TRUE;
                        
                        if (temporaryLocation.sked_Is_Travel_Required__c == TRUE) {
                            if (temporaryLocation.sked__Geolocation__Latitude__s != NULL && temporaryLocation.sked__Geolocation__Longitude__s != NULL) {
                                origin.lat = temporaryLocation.sked__Geolocation__Latitude__s;
                                origin.lng = temporaryLocation.sked__GeoLocation__Longitude__s;
                            }
                        }
                    }
                }
            }
            
            if (isRelocatedResource == TRUE) {
                result.relocatedJobAllocationKeys.add(jobAllocationModel.getKey());
                jobAllocationModel.isRelocatedResource = TRUE;
            }
            
            
            if (isDrivingRoleJob == TRUE && isRelocatedResource == TRUE && driveCo.sked_Relocated_Driver_TT_from_Drive_CO__c == FALSE) {
                Id resourceOwnCOId = jobAllocationModel.resourcePrimaryCollectionOperationId;
                origin = getStagingGeolocation(resourceOwnCOId, mapCollectionOperationById, driveDate);
            }
            
            if (origin.lat != NULL && origin.lng != NULL) {
                String geoKey = origin.lat + ' ' + origin.lng;
                mapOriginByGeoKey.put(geoKey, origin);
                mapOriginByKey.put(jobAllocationModel.getKey(), origin);
            }
            
            sked__Location__c skedSite = mapSiteById.get(jobAllocationModel.jobDriveSiteId);
            skedSkeduloApiData.latlng destination = new skedSkeduloApiData.latlng();
            destination.lat = skedSite.sked__Geolocation__Latitude__s;
            destination.lng = skedSite.sked__Geolocation__Longitude__s;
            
            if (isDrivingRoleJob == TRUE) {
                if (isRelocatedResource == FALSE || driveCo.sked_Relocated_Driver_TT_from_Drive_CO__c == TRUE) {
                    destination = getStagingGeolocation(driveCollectionOperationId, mapCollectionOperationById, driveDate);
                }
            }
            
            if (destination.lat != NULL && destination.lng != NULL) {
                String geoKey = destination.lat + ' ' + destination.lng;
                mapDestinationByGeoKey.put(geoKey, destination);
                mapDestinationByKey.put(jobAllocationModel.getKey(), destination);
            }
        }
        
        result.mapOriginByKey = mapOriginByKey;
        result.mapOriginByGeoKey = mapOriginByGeoKey;
        result.mapDestinationByKey = mapDestinationByKey;
        result.mapDestinationByGeoKey = mapDestinationByGeoKey;
        
        return result;
    }

    private static skedSkeduloApiData.latlng getResourceGeolocation(sked__Resource__c skedResource, Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById, Date selectedDate) {
        skedSkeduloApiData.latlng origin = new skedSkeduloApiData.latlng();
        origin.lat = skedResource.sked__GeoLocation__Latitude__s;
        origin.lng = skedResource.sked__GeoLocation__Longitude__s;
        
        if (skedResource.sked_Address_Referenced_for_Scheduling__c == 'Work' && skedResource.Use_CO_Address_for_Scheduling__c == TRUE) {
            Id resourceOwnCOId = skedResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
            origin = getStagingGeolocation(resourceOwnCOId, mapCollectionOperationById, selectedDate);
        }
        
        return origin;
    }

    private static skedSkeduloApiData.latlng getStagingGeolocation(Id collectionOperationId, Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById, Date selectedDate) {
        skedSkeduloApiData.latlng origin = new skedSkeduloApiData.latlng();
        
        Biomed_Collection_Op_Center__c ownCO = mapCollectionOperationById.get(collectionOperationId);
        sked_Collection_Op_Staging_Location__c cosl = getCOSLByDate(ownCO, selectedDate);
        
        if (cosl != NULL) {
            origin.lat = cosl.sked_Staging_Location__r.sked_Geolocation__Latitude__s;
            origin.lng = cosl.sked_Staging_Location__r.sked_Geolocation__Longitude__s;
        }
        
        return origin;
    }

    private static Map<string, skedSkeduloApiData.Element> getTravelTimeDictionary(masterDataWrapper data) {
        Map<string, skedSkeduloApiData.Element> mapElementByGeoKey = new Map<string, skedSkeduloApiData.Element>();
        
        List<skedSkeduloApiData.latlng> resourceLocations = data.mapOriginByGeoKey.values();
        List<skedSkeduloApiData.latlng> jobLocations = data.mapDestinationByGeoKey.values();
        
        skedSkeduloApiData.distanceMatrixResult travelToData = apiManager.calculateDistanceMatrix(resourceLocations, jobLocations);
        if (travelToData != null && travelToData.result != null && travelToData.result.matrix != null) {
            for (integer i = 0; i < travelToData.result.matrix.size(); i++) {
                skedSkeduloApiData.latlng origin = resourceLocations.get(i);
                List<skedSkeduloApiData.Element> elements = travelToData.result.matrix.get(i);
                for (integer j = 0; j < elements.size(); j++) {
                    skedSkeduloApiData.Element element = elements.get(j);
                    skedSkeduloApiData.latlng destination = jobLocations.get(j);
                    
                    string geoKey = getTravelTimeKey(origin, destination);
                    mapElementByGeoKey.put(geoKey, element);
                }
            }
        }
        
        skedSkeduloApiData.distanceMatrixResult travelBackData = apiManager.calculateDistanceMatrix(jobLocations, resourceLocations);
        if (travelBackData != null && travelBackData.result != null && travelBackData.result.matrix != null) {
            for (integer i = 0; i < travelBackData.result.matrix.size(); i++) {
                skedSkeduloApiData.latlng origin = jobLocations.get(i);
                List<skedSkeduloApiData.Element> elements = travelBackData.result.matrix.get(i);
                for (integer j = 0; j < elements.size(); j++) {
                    skedSkeduloApiData.Element element = elements.get(j);
                    skedSkeduloApiData.latlng destination = resourceLocations.get(j);
                    
                    string geoKey = getTravelTimeKey(origin, destination);
                    mapElementByGeoKey.put(geoKey, element);
                }
            }
        }
        return mapElementByGeoKey;
    }
    
    private static string getTravelTimeKey(skedSkeduloApiData.latlng origin, skedSkeduloApiData.latlng destination) {
        return origin.lat + ' ' + origin.lng + ':' + destination.lat + ' ' + destination.lng;
    }

    private static Map<Id, sked__Job__c> getMapDriveAndDriverJob(Set<Id> driveIds) {
        Map<Id, sked__Job__c> mapDriverJobByDriveId = new Map<Id, sked__Job__c>();
        
        List<sked__Job__c> drivingRoleJobs = [SELECT Id, sked_Drive__c, sked_Travel_Time__c, sked_Travel_Time2__c,
                                              sked_Drive__r.sked_Collection_Operation__c, sked_Drive__r.sked_Drive_Site__c,
                                              sked_Drive__r.sked_Drive_Date__c
                                              FROM sked__Job__c
                                              WHERE sked_Drive__c IN :driveIds
                                              AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                              AND sked_Resource_Role__c IN :drivingRoles];
        for (sked__Job__c skedJob : drivingRoleJobs) {
            mapDriverJobByDriveId.put(skedJob.sked_Drive__c, skedJob);
        }
        return mapDriverJobByDriveId;
    }

    private static void overrideTravelTimeDictionary(masterDataWrapper data, Map<Id, sked__Job__c> mapDriverJobByDriveId) {
        for (sked__Job__c skedJob : mapDriverJobByDriveId.values()) {
            sked__Location__c skedSite = data.mapSiteById.get(skedJob.sked_Drive__r.sked_Drive_Site__c);
            skedSkeduloApiData.latlng siteGeolocation = new skedSkeduloApiData.latlng();
            siteGeolocation.lat = skedSite.sked__Geolocation__Latitude__s;
            siteGeolocation.lng = skedSite.sked__Geolocation__Longitude__s;
            
            Id driveCollectionOperationId = skedJob.sked_Drive__r.sked_Collection_Operation__c;
            skedSkeduloApiData.latlng stagingGeolocation = getStagingGeolocation(driveCollectionOperationId, data.mapCollectionOperationById, skedJob.sked_Drive__r.sked_Drive_Date__c);
            
            if (siteGeolocation.lat != NULL && siteGeolocation.lng != NULL && stagingGeolocation.lat != NULL && stagingGeolocation.lng != NULL) {
                string stagingToSiteKey = getTravelTimeKey(stagingGeolocation, siteGeolocation);
                rewriteElementTravelTime(data.mapTravelElementByLatLngKey, stagingToSiteKey, skedJob.sked_Travel_Time__c);
                
                string siteToStagingKey = getTravelTimeKey(siteGeolocation, stagingGeolocation);
                rewriteElementTravelTime(data.mapTravelElementByLatLngKey, siteToStagingKey, skedJob.sked_Travel_Time2__c);
            }
        }
    }
    
    private static void rewriteElementTravelTime(Map<string, skedSkeduloApiData.Element> mapTravelElementByLatLngKey, string key, Decimal travelTimeMinutes) {
        if (travelTimeMinutes != NULL && mapTravelElementByLatLngKey.containsKey(key)) {
            skedSkeduloApiData.Element element = mapTravelElementByLatLngKey.get(key);
            if (element != null) {
                if (element.duration != NULL) {
                    element.duration.durationInSeconds = Integer.valueOf(travelTimeMinutes * 60);
                }
            }
        }
    }

    private static void populateJobAllocationTravelData(masterDataWrapper data, jobAllocationModel jobAllocationModel) {
        decimal travelTimeTo, travelTimeBack; 
        decimal travelDistanceTo, travelDistanceBack;
        
        skedSkeduloApiData.latlng origin = data.mapOriginByKey.get(jobAllocationModel.getKey());
        skedSkeduloApiData.latlng destination = data.mapDestinationByKey.get(jobAllocationModel.getKey());
        
        if (origin != NULL && destination != NULL) {
            string travelTokey = getTravelTimeKey(origin, destination);
            if (data.mapTravelElementByLatLngKey.containsKey(travelTokey)) {
                skedSkeduloApiData.Element element = data.mapTravelElementByLatLngKey.get(travelTokey);
                if (element != null) {
                    if (element.duration != NULL) {
                        travelTimeTo = Math.ceil(decimal.valueOf(element.duration.durationInSeconds) / 60);
                    }
                    if (element.distance != NULL) {
                        travelDistanceTo = Math.ceil(decimal.valueOf(element.distance.distanceInMeters) / skedConstants.METTER_PER_MILE);
                    }
                }
            }
            
            string travelBackkey = getTravelTimeKey(destination, origin);
            if (data.mapTravelElementByLatLngKey.containsKey(travelBackkey)) {
                skedSkeduloApiData.Element element = data.mapTravelElementByLatLngKey.get(travelBackkey);
                if (element != null) {
                    if (element.duration != NULL) {
                        travelTimeBack = Math.ceil(decimal.valueOf(element.duration.durationInSeconds) / 60);
                    }
                    if (element.distance != NULL) {
                        travelDistanceBack = Math.ceil(decimal.valueOf(element.distance.distanceInMeters) / skedConstants.METTER_PER_MILE);
                    }
                }
            }
            
            jobAllocationModel.geoServiceTravelTimeTo = travelTimeTo;
            jobAllocationModel.geoServiceTravelDistanceTo = travelDistanceTo;
            jobAllocationModel.geoServiceTravelTimeBack = travelTimeBack;
            jobAllocationModel.geoServiceTravelDistanceBack = travelDistanceBack;
            jobAllocationModel.travelTimeTo = 0;
            jobAllocationModel.travelTimeBack = 0;
            
            boolean isRelocatedResource = data.relocatedJobAllocationKeys.contains(jobAllocationModel.getKey());

            Biomed_Collection_Op_Center__c driveCo = data.mapCollectionOperationById.get(jobAllocationModel.jobDriveCollectionOperationId);
            boolean isCoNoTravelTime = driveCo.sked_No_Travel_Time__c;
            
            boolean isTravelTimeIncludedAllRoles = (jobAllocationModel.jobDriveType == 'Mobile' && jobAllocationModel.jobDriveTravelTimeIncluded == 'All Roles')
                || (jobAllocationModel.jobDriveType == 'Fixed Site' && jobAllocationModel.jobDriveTravelTimeIncluded == 'All Roles');
            boolean isDrivingRoleJob = drivingRoles.contains(jobAllocationModel.jobResourceRole) ||  drivingRoles.contains(jobAllocationModel.jobDualRole);
        
            boolean recalculateTravelTimeRule1 = isDrivingRoleJob;
            boolean recalculateTravelTimeRule2 = !isDrivingRoleJob && !isCoNoTravelTime && (isTravelTimeIncludedAllRoles || isRelocatedResource);            
            boolean requireRecalculateTravelTime = recalculateTravelTimeRule1 || recalculateTravelTimeRule2;
            
            if (isDrivingRoleJob) {
                if (isRelocatedResource == FALSE || driveCo.sked_Relocated_Driver_TT_from_Drive_CO__c == TRUE) {
                    if (jobAllocationModel.jobTravelTimeTo != NULL) {
                        travelTimeTo = jobAllocationModel.jobTravelTimeTo;
                    }
                    if (jobAllocationModel.jobTravelTimeBack != NULL) {
                        travelTimeBack = jobAllocationModel.jobTravelTimeBack;
                    }
                }
            }
            
            if (requireRecalculateTravelTime) {
                decimal includedTravelTimeTo = jobAllocationModel.jobTravelTimeTo != NULL ? jobAllocationModel.jobTravelTimeTo : 0;
                decimal includedTravelTimeBack = jobAllocationModel.jobTravelTimeBack != NULL ? jobAllocationModel.jobTravelTimeBack : 0;
                
                jobAllocationModel.travelTimeTo = travelTimeTo;
                jobAllocationModel.travelTimeBack = travelTimeBack;
                jobAllocationModel.start = jobAllocationModel.jobStart.addMinutes(integer.valueOf(includedTravelTimeTo - travelTimeTo));
                jobAllocationModel.setEnd = jobAllocationModel.jobFinish.addMinutes(integer.valueOf(travelTimeBack - includedTravelTimeBack));
                jobAllocationModel.duration = skedDateTimeUtils.getDifferentMinutes(jobAllocationModel.start, jobAllocationModel.setEnd);
            }
        }
    }

    private static sked_Collection_Op_Staging_Location__c getCOSLByDate(Biomed_Collection_Op_Center__c collectionOperation, Date inputDate) {
        sked_Collection_Op_Staging_Location__c result;
        if (collectionOperation.sked_Collection_Op_Staging_Locations__r != NULL) {
            for (sked_Collection_Op_Staging_Location__c cosl : collectionOperation.sked_Collection_Op_Staging_Locations__r) {
                boolean isStartDateMatched = cosl.sked_Start_Date__c == NULL || cosl.sked_Start_Date__c <= inputDate;
                boolean isEndDateMatched = cosl.sked_End_Date__c == NULL || cosl.sked_End_Date__c >= inputDate;
                if (isStartDateMatched && isEndDateMatched) {
                    result = cosl;
                }
            }
        }
        return result;
    }

    private static String buildKeyFromResourceJobId(String resourceId, String jobId) {
        return resourceId + '-' + jobId;
    }

    /////////////////////////////  Nested Classes /////////////////////////////
    private class masterDataWrapper {
        public Set<String> relocatedJobAllocationKeys;
        public Map<String, skedSkeduloApiData.latlng> mapOriginByKey;
        public Map<String, skedSkeduloApiData.latlng> mapOriginByGeoKey;
        public Map<String, skedSkeduloApiData.latlng> mapDestinationByKey;
        public Map<String, skedSkeduloApiData.latlng> mapDestinationByGeoKey;
        public Map<string, skedSkeduloApiData.Element> mapTravelElementByLatLngKey;

        public Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById;
        Map<Id, sked__Location__c> mapSiteById;
        
        public masterDataWrapper() {
            this.relocatedJobAllocationKeys = new Set<String>();
        }
    }

    public class jobAllocationTravelDataResult {
        private Map<String, jobAllocationModel> map_key_jobAllocationModel;

        public jobAllocationModel getJobAllocationById(String jobAllocationId) {
            return map_key_jobAllocationModel.get(jobAllocationId);
        }

        public jobAllocationModel getJobAllocationByResourceJobId(String resourceId, String jobId) {
            return map_key_jobAllocationModel.get(jobAllocationModel.buildKeyFromResourceJobId(resourceId, jobId));
        }

        private void collect(List<jobAllocationModel> jobAllocationModels) {
            for (jobAllocationModel jobAllocationModel : jobAllocationModels) {
                map_key_jobAllocationModel.put(jobAllocationModel.getKey(), jobAllocationModel);
            }
        }

        public jobAllocationTravelDataResult() {
            this.map_key_jobAllocationModel = new Map<String, jobAllocationModel>();
        }
    }

    public class jobAllocationModel {
        public String id;
        public String jobId;
        public String resourceId;
        public Decimal geoServiceTravelTimeTo;
        public Decimal geoServiceTravelTimeBack;
        public Decimal geoServiceTravelDistanceTo;
        public Decimal geoServiceTravelDistanceBack;
        public Decimal travelTimeTo;
        public Decimal travelTimeBack;
        public Boolean isRelocatedResource;
        public Datetime start;
        public Datetime setEnd;
        public Decimal duration;
        public Decimal jobTravelTimeTo;
        public Decimal jobTravelTimeBack;
        public Datetime jobStart;
        public Datetime jobFinish;
        public String jobResourceRole;
        public String jobDriveId;
        public String jobDriveType;
        public Date jobDriveDate;
        public String jobDriveSiteId;
        public String jobDriveTravelTimeIncluded;
        public String jobDriveCollectionOperationId;
        public String resourcePrimaryCollectionOperationId;
        public String jobDualRole;

        public jobAllocationModel(sked__Job_Allocation__c jobAllocation) {
            this.id = jobAllocation.Id;
            this.resourceId = jobAllocation.sked__Resource__c;
            this.jobId = jobAllocation.sked__Job__c;
            this.geoServiceTravelTimeTo = jobAllocation.sked_GeoService_Travel_Time_To__c;
            this.geoServiceTravelTimeBack = jobAllocation.sked_GeoService_Travel_Time_Back__c;
            this.geoServiceTravelDistanceTo = jobAllocation.sked_GeoService_Travel_Distance_To__c;
            this.geoServiceTravelDistanceBack = jobAllocation.sked_GeoService_Travel_Distance_Back__c;
            this.travelTimeTo = jobAllocation.sked_Travel_Time_To__c;
            this.travelTimeBack = jobAllocation.sked_Travel_Time_Back__c;
            this.isRelocatedResource = jobAllocation.sked_Is_Relocated_Resource__c;
            this.start = jobAllocation.sked__Start__c;
            this.setEnd = jobAllocation.sked__Set_End__c;
            this.duration = jobAllocation.sked__Duration__c;
            this.jobTravelTimeTo = jobAllocation.sked__Job__r.sked_Travel_Time__c;
            this.jobTravelTimeBack = jobAllocation.sked__Job__r.sked_Travel_Time2__c;
            this.jobStart = jobAllocation.sked__Job__r.sked__Start__c;
            this.jobFinish = jobAllocation.sked__Job__r.sked__Finish__c;
            this.jobResourceRole = jobAllocation.sked__Job__r.sked_Resource_Role__c;
            this.jobDriveId = jobAllocation.sked__Job__r.sked_Drive__c;
            this.jobDriveType = jobAllocation.sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c;
            this.jobDriveDate = jobAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
            this.jobDriveSiteId = jobAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Site__c;
            this.jobDriveTravelTimeIncluded = jobAllocation.sked__Job__r.sked_Drive__r.sked_Travel_Time_Included__c;
            this.jobDriveCollectionOperationId = jobAllocation.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c;
            this.resourcePrimaryCollectionOperationId = jobAllocation.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
            this.jobDualRole = jobAllocation.sked__Job__r.sked_Dual_Role__c;//HRP-15933
        }

        public jobAllocationModel(sked__Resource__c resource, sked__Job__c job) {
            this.jobId = job.Id;
            this.resourceId = resource.Id;
            this.jobTravelTimeTo = job.sked_Travel_Time__c;
            this.jobTravelTimeBack = job.sked_Travel_Time2__c;
            this.jobStart = job.sked__Start__c;
            this.jobFinish = job.sked__Finish__c;
            this.jobResourceRole = job.sked_Resource_Role__c;
            this.jobDriveId = job.sked_Drive__c;
            this.jobDriveType = job.sked_Drive__r.sked_Type_of_Drive__c;
            this.jobDriveDate = job.sked_Drive__r.sked_Drive_Date__c;
            this.jobDriveSiteId = job.sked_Drive__r.sked_Drive_Site__c;
            this.jobDriveTravelTimeIncluded = job.sked_Drive__r.sked_Travel_Time_Included__c;
            this.jobDriveCollectionOperationId = job.sked_Drive__r.sked_Collection_Operation__c;
            this.resourcePrimaryCollectionOperationId = resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
            this.start = job.sked__Start__c;
            this.setEnd = job.sked__Finish__c;
            this.duration = job.sked__Duration__c;
            this.jobDualRole = job.sked_Dual_Role__c;//HRP-15933
        }

        public String getKey() {
            return this.id != null ? this.id : buildKeyFromResourceJobId(this.resourceId, this.jobId);
        }
    }

    public class jobAllocationTravelDataRequest {
        
        public List<jobAllocationRequestModel> jobAllocationRequestModels;

        public jobAllocationTravelDataRequest() {
            this.jobAllocationRequestModels = new List<jobAllocationRequestModel>();
        }
    }

    public class jobAllocationRequestModel {
        public Id jobAllocationId;
        public Id resourceId;
        public Id jobId;

        public jobAllocationRequestModel(Id resourceId, Id jobId) {
            this.resourceId = resourceId;
            this.jobId = jobId;
        }

        public jobAllocationRequestModel(Id jobAllocationId) {
            this.jobAllocationId = jobAllocationId;
        }
    }
}