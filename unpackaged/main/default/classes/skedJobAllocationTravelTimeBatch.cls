global class skedJobAllocationTravelTimeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    protected skedSkeduloApiManager apiManager;
    protected List<string> drivingRoles;
    protected Set<Id> jobAllocationIds;
    protected Set<Id> processedResourceIds;
    
    global skedJobAllocationTravelTimeBatch(Set<Id> jobAllocationIds) {
        this.jobAllocationIds = jobAllocationIds;
        this.initialize();
    }
    
    global List<sObject> start(Database.BatchableContext BC) {
        return [SELECT Id, sked__Resource__c, sked__Job__c, sked_Optimization_Run__c,
                sked_GeoService_Travel_Time_To__c, sked_GeoService_Travel_Distance_To__c,
                sked_Geoservice_Travel_Time_Back__c, sked_GeoService_Travel_Distance_Back__c,
                sked_Travel_Time_To__c, sked_Travel_Time_Back__c, sked_Is_Relocated_Resource__c,
                sked__Job__r.sked_Travel_Time__c, sked__Job__r.sked_Travel_Time2__c,
                sked__Job__r.sked__Start__c, sked__Job__r.sked__Finish__c,
                sked__Job__r.sked_Resource_Role__c, 
                sked__Job__r.sked_Drive__r.sked_Type_of_Drive__c,
                sked__Job__r.sked_Drive__r.sked_Drive_Date__c,
                sked__Job__r.sked_Drive__r.sked_Drive_Site__c,
                sked__Job__r.sked_Drive__r.sked_Travel_Time_Included__c,
                sked__Job__r.sked_Drive__r.sked_Collection_Operation__c,
                sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
                FROM sked__Job_Allocation__c
                WHERE Id IN :this.jobAllocationIds
                AND (sked_Travel_Time_To__c = NULL OR sked_Travel_Time_Back__c = NULL)
                AND sked__Job__r.sked_Drive__r.sked_Collection_Operation__c != NULL
                AND sked__Job__r.sked_Drive__r.sked_Drive_Site__c != NULL
                AND (sked__Resource__r.sked__GeoLocation__Latitude__s != NULL AND sked__Resource__r.sked__GeoLocation__Longitude__s != NULL)
        ];
    }
    
    global void execute(Database.BatchableContext BC, List<sked__Job_Allocation__c> skedAllocations) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Id> driveIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> siteIds = new Set<Id>();
        
        Date firstDriveDate = System.today();
        Date lastDriveDate = System.today();
        
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
        	collectionOperationIds.add(skedAllocation.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c);
            collectionOperationIds.add(skedAllocation.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c);
            
            driveIds.add(skedAllocation.sked__Job__r.sked_Drive__c);
            
            resourceIds.add(skedAllocation.sked__Resource__c);
            
            siteIds.add(skedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Site__c);
            
            if (skedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c < firstDriveDate) {
                firstDriveDate = skedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
            }

            if (skedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c > lastDriveDate) {
                lastDriveDate = skedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
            }
        }
        
        Map<Id, sked__Resource__c> mapResourceById = this.getMapResource(resourceIds, firstDriveDate, lastDriveDate);
        Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById = this.getMapCollectionOperation(collectionOperationIds);
        Map<Id, sked__Location__c> mapSiteById = this.getMapSite(siteIds);
        
        masterDataWrapper data = this.initializeDistanceMatrixData(skedAllocations, mapResourceById, mapCollectionOperationById, mapSiteById);
        data.mapTravelElementByLatLngKey = this.getTravelTimeDictionary(data);
        
        Map<Id, sked__Job__c> mapDriverJobByDriveId = this.getMapDriveAndDriverJob(driveIds);
        this.overrideTravelTimeDictionary(data, mapDriverJobByDriveId);
        
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            this.populateJobAllocationTravelData(data, skedAllocation);
        }
        
        update skedAllocations;
        
        this.processedResourceIds.addAll(resourceIds);
    }
    
    global void finish(Database.BatchableContext BC) {
        //verify if job allocations are created by optimization run
        List<sked__Job_Allocation__c> jaQuery = [SELECT Id, sked_Optimization_Run__c
                                                 FROM sked__Job_Allocation__c
                                                 WHERE Id IN : this.jobAllocationIds
                                                 AND sked_Optimization_Run__c != NULL
                                                 LIMIT 1];
        if (!jaQuery.isEmpty()) {
            slwcOptimizationService.evaluateOptimizationRunResult(jaQuery.get(0).sked_Optimization_Run__c);
        }
        
        skedJobAllocationPostProcessBatch.batchSetting batchSetting = new skedJobAllocationPostProcessBatch.batchSetting();
        Database.executeBatch(new skedJobAllocationPostProcessBatch(batchSetting, this.jobAllocationIds), 100);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void initialize() {
        this.processedResourceIds = new Set<Id>();
        this.jobAllocationIds = jobAllocationIds;
        this.apiManager = new skedSkeduloApiManager();
        
        this.drivingRoles = new List<String>();
        List<sked_Resource_Role_Group__c> drivingRoleGroupQuery = [SELECT Id, sked_Resource_Roles__c
                                                                   FROM sked_Resource_Role_Group__c
                                                                   WHERE sked_Resource_Role_Group__c = 'Driving roles'];
        if (!drivingRoleGroupQuery.isEmpty()) {
            sked_Resource_Role_Group__c drivingRoleGroup = drivingRoleGroupQuery.get(0);
            if (drivingRoleGroup.sked_Resource_Roles__c != NULL) {
                this.drivingRoles = drivingRoleGroup.sked_Resource_Roles__c.split(';');
            }
        }
    }
    
    private Map<Id, Biomed_Collection_Op_Center__c> getMapCollectionOperation(Set<Id> collectionOperationIds) {
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
    
    private Map<Id, sked__Job__c> getMapDriveAndDriverJob(Set<Id> driveIds) {
        Map<Id, sked__Job__c> mapDriverJobByDriveId = new Map<Id, sked__Job__c>();
        
        List<sked__Job__c> drivingRoleJobs = [SELECT Id, sked_Drive__c, sked_Travel_Time__c, sked_Travel_Time2__c,
                                              sked_Drive__r.sked_Collection_Operation__c, sked_Drive__r.sked_Drive_Site__c,
                                              sked_Drive__r.sked_Drive_Date__c
                                              FROM sked__Job__c
                                              WHERE sked_Drive__c IN :driveIds
                                              AND sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
                                              AND sked_Resource_Role__c IN :this.drivingRoles];
        for (sked__Job__c skedJob : drivingRoleJobs) {
            mapDriverJobByDriveId.put(skedJob.sked_Drive__c, skedJob);
        }
        return mapDriverJobByDriveId;
    }
    
    private Map<Id, sked__Resource__c> getMapResource(Set<Id> resourceIds, Date firstDriveDate, Date lastDriveDate) {
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
    
    private Map<Id, sked__Location__c> getMapSite(Set<Id> siteIds) {
        return new Map<Id, sked__Location__c>([
            SELECT Id, sked__Geolocation__Latitude__s, sked__Geolocation__Longitude__s
            FROM sked__Location__c
            WHERE Id IN :siteIds
        ]);
    }
    
    private masterDataWrapper initializeDistanceMatrixData(
        List<sked__Job_Allocation__c> skedAllocations, 
        Map<Id, sked__Resource__c> mapResourceById,
        Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById,
        Map<Id, sked__Location__c> mapSiteById) 
    {
        masterDataWrapper result = new masterDataWrapper();
        result.mapCollectionOperationById = mapCollectionOperationById;
        result.mapSiteById = mapSiteById;
        
        Map<Id, skedSkeduloApiData.latlng> mapOriginById = new Map<Id, skedSkeduloApiData.latlng>(); 
        Map<String, skedSkeduloApiData.latlng> mapOriginByKey = new Map<String, skedSkeduloApiData.latlng>();
        
        Map<Id, skedSkeduloApiData.latlng> mapDestinationById = new Map<Id, skedSkeduloApiData.latlng>(); 
        Map<String, skedSkeduloApiData.latlng> mapDestinationByKey = new Map<String, skedSkeduloApiData.latlng>();
        
        for (sked__Job_Allocation__c skedAllocation : skedAllocations) {
            Date driveDate = skedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
            boolean isDrivingRoleJob = this.drivingRoles.contains(skedAllocation.sked__Job__r.sked_Resource_Role__c);
            
            Id driveCollectionOperationId = skedAllocation.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c;
            Biomed_Collection_Op_Center__c driveCo = mapCollectionOperationById.get(driveCollectionOperationId);
            
            sked__Resource__c skedResource = mapResourceById.get(skedAllocation.sked__Resource__c);
            skedSkeduloApiData.latlng origin = this.getResourceGeolocation(skedResource, mapCollectionOperationById, driveDate);
            
            boolean isRelocatedResource = FALSE;
            if (skedResource.sked__Resource_Overrides__r != NULL && !skedResource.sked__Resource_Overrides__r.isEmpty()) {
                for (sked__Resource_Override__c temporaryLocation : skedResource.sked__Resource_Overrides__r) {
                    boolean isCOMatched = temporaryLocation.sked_Collection_Operation__c == skedAllocation.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c;
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
                result.relocatedJobAllocationIds.add(skedAllocation.Id);
                skedAllocation.sked_Is_Relocated_Resource__c = TRUE;
            }
            
            
            if (isDrivingRoleJob == TRUE && isRelocatedResource == TRUE && driveCo.sked_Relocated_Driver_TT_from_Drive_CO__c == FALSE) {
                Id resourceOwnCOId = skedAllocation.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
                origin = this.getStagingGeolocation(resourceOwnCOId, mapCollectionOperationById, driveDate);
            }
            
            if (origin.lat != NULL && origin.lng != NULL) {
                String key = origin.lat + ' ' + origin.lng;
                mapOriginByKey.put(key, origin);
                mapOriginById.put(skedAllocation.Id, origin);
            }
            
            sked__Location__c skedSite = mapSiteById.get(skedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Site__c);
            skedSkeduloApiData.latlng destination = new skedSkeduloApiData.latlng();
            destination.lat = skedSite.sked__Geolocation__Latitude__s;
            destination.lng = skedSite.sked__Geolocation__Longitude__s;
            
            if (isDrivingRoleJob == TRUE) {
                if (isRelocatedResource == FALSE || driveCo.sked_Relocated_Driver_TT_from_Drive_CO__c == TRUE) {
                    destination = this.getStagingGeolocation(driveCollectionOperationId, mapCollectionOperationById, driveDate);
                }
            }
            
            if (destination.lat != NULL && destination.lng != NULL) {
                String key = destination.lat + ' ' + destination.lng;
                mapDestinationByKey.put(key, destination);
                mapDestinationById.put(skedAllocation.Id, destination);
            }
        }
        
        result.mapOriginById = mapOriginById;
        result.mapOriginByKey = mapOriginByKey;
        result.mapDestinationById = mapDestinationById;
        result.mapDestinationByKey = mapDestinationByKey;
        
        return result;
    }
    
    private Map<string, skedSkeduloApiData.Element> getTravelTimeDictionary(masterDataWrapper data) {
        Map<string, skedSkeduloApiData.Element> mapElementByKey = new Map<string, skedSkeduloApiData.Element>();
        
        List<skedSkeduloApiData.latlng> resourceLocations = data.mapOriginByKey.values();
        List<skedSkeduloApiData.latlng> jobLocations = data.mapDestinationByKey.values();
        
        skedSkeduloApiData.distanceMatrixResult travelToData = apiManager.calculateDistanceMatrix(resourceLocations, jobLocations);
        if (travelToData != null && travelToData.result != null && travelToData.result.matrix != null) {
            for (integer i = 0; i < travelToData.result.matrix.size(); i++) {
                skedSkeduloApiData.latlng origin = resourceLocations.get(i);
                List<skedSkeduloApiData.Element> elements = travelToData.result.matrix.get(i);
                for (integer j = 0; j < elements.size(); j++) {
                    skedSkeduloApiData.Element element = elements.get(j);
                    skedSkeduloApiData.latlng destination = jobLocations.get(j);
                    
                    string key = this.getTravelTimeKey(origin, destination);
                    mapElementByKey.put(key, element);
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
                    
                    string key = this.getTravelTimeKey(origin, destination);
                    mapElementByKey.put(key, element);
                }
            }
        }
        return mapElementByKey;
    }
    
    private string getTravelTimeKey(skedSkeduloApiData.latlng origin, skedSkeduloApiData.latlng destination) {
        return origin.lat + ' ' + origin.lng + ':' + destination.lat + ' ' + destination.lng;
    }
    
    private void overrideTravelTimeDictionary(masterDataWrapper data, Map<Id, sked__Job__c> mapDriverJobByDriveId) {
        for (sked__Job__c skedJob : mapDriverJobByDriveId.values()) {
            sked__Location__c skedSite = data.mapSiteById.get(skedJob.sked_Drive__r.sked_Drive_Site__c);
            skedSkeduloApiData.latlng siteGeolocation = new skedSkeduloApiData.latlng();
            siteGeolocation.lat = skedSite.sked__Geolocation__Latitude__s;
            siteGeolocation.lng = skedSite.sked__Geolocation__Longitude__s;
            
            Id driveCollectionOperationId = skedJob.sked_Drive__r.sked_Collection_Operation__c;
            skedSkeduloApiData.latlng stagingGeolocation = this.getStagingGeolocation(driveCollectionOperationId, data.mapCollectionOperationById, skedJob.sked_Drive__r.sked_Drive_Date__c);
            
            if (siteGeolocation.lat != NULL && siteGeolocation.lng != NULL && stagingGeolocation.lat != NULL && stagingGeolocation.lng != NULL) {
                string stagingToSiteKey = this.getTravelTimeKey(stagingGeolocation, siteGeolocation);
                this.rewriteElementTravelTime(data.mapTravelElementByLatLngKey, stagingToSiteKey, skedJob.sked_Travel_Time__c);
                
                string siteToStagingKey = this.getTravelTimeKey(siteGeolocation, stagingGeolocation);
                this.rewriteElementTravelTime(data.mapTravelElementByLatLngKey, siteToStagingKey, skedJob.sked_Travel_Time2__c);
            }
        }
    }
    
    private void rewriteElementTravelTime(Map<string, skedSkeduloApiData.Element> mapTravelElementByLatLngKey, string key, Decimal travelTimeMinutes) {
        if (travelTimeMinutes != NULL && mapTravelElementByLatLngKey.containsKey(key)) {
            skedSkeduloApiData.Element element = mapTravelElementByLatLngKey.get(key);
            if (element != null) {
                if (element.duration != NULL) {
                    element.duration.durationInSeconds = Integer.valueOf(travelTimeMinutes * 60);
                }
            }
        }
    }
    
    private void populateJobAllocationTravelData(masterDataWrapper data, sked__Job_Allocation__c skedAllocation) {
        decimal travelTimeTo, travelTimeBack; 
        decimal travelDistanceTo, travelDistanceBack;
        
        skedSkeduloApiData.latlng origin = data.mapOriginById.get(skedAllocation.Id);
        skedSkeduloApiData.latlng destination = data.mapDestinationById.get(skedAllocation.Id);
        
        if (origin != NULL && destination != NULL) {
            string travelTokey = this.getTravelTimeKey(origin, destination);
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
            
            string travelBackkey = this.getTravelTimeKey(destination, origin);
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
            
            skedAllocation.sked_Geoservice_Travel_Time_To__c = travelTimeTo;
            skedAllocation.sked_Geoservice_Travel_Distance_To__c = travelDistanceTo;
            skedAllocation.sked_Geoservice_Travel_Time_Back__c = travelTimeBack;
            skedAllocation.sked_Geoservice_Travel_Distance_Back__c = travelDistanceBack;
            skedAllocation.sked_Travel_Time_To__c = 0;
            skedAllocation.sked_Travel_Time_Back__c = 0;
            
            boolean isRelocatedResource = data.relocatedJobAllocationIds.contains(skedAllocation.Id);

            Biomed_Collection_Op_Center__c driveCo = data.mapCollectionOperationById.get(skedAllocation.sked__Job__r.sked_Drive__r.sked_Collection_Operation__c);
            boolean isCoNoTravelTime = driveCo.sked_No_Travel_Time__c;
            
            sked_Drive__c skedDrive = skedAllocation.sked__Job__r.sked_Drive__r;
            boolean isTravelTimeIncludedAllRoles = (skedDrive.sked_Type_of_Drive__c == 'Mobile' && skedDrive.sked_Travel_Time_Included__c == 'All Roles')
                || (skedDrive.sked_Type_of_Drive__c == 'Fixed Site' && skedDrive.sked_Travel_Time_Included__c == 'All Roles');
            boolean isDrivingRoleJob = this.drivingRoles.contains(skedAllocation.sked__Job__r.sked_Resource_Role__c);
            
            boolean recalculateTravelTimeRule1 = isDrivingRoleJob;
            boolean recalculateTravelTimeRule2 = !isDrivingRoleJob && !isCoNoTravelTime && (isTravelTimeIncludedAllRoles || isRelocatedResource);            
            boolean requireRecalculateTravelTime = recalculateTravelTimeRule1 || recalculateTravelTimeRule2;
            
            if (isDrivingRoleJob) {
                if (isRelocatedResource == FALSE || driveCo.sked_Relocated_Driver_TT_from_Drive_CO__c == TRUE) {
                    if (skedAllocation.sked__Job__r.sked_Travel_Time__c != NULL) {
                        travelTimeTo = skedAllocation.sked__Job__r.sked_Travel_Time__c;
                    }
                    if (skedAllocation.sked__Job__r.sked_Travel_Time2__c != NULL) {
                        travelTimeBack = skedAllocation.sked__Job__r.sked_Travel_Time2__c;
                    }
                }
            }
            
            if (requireRecalculateTravelTime) {
                decimal includedTravelTimeTo = skedAllocation.sked__Job__r.sked_Travel_Time__c != NULL ? skedAllocation.sked__Job__r.sked_Travel_Time__c : 0;
                decimal includedTravelTimeBack = skedAllocation.sked__Job__r.sked_Travel_Time2__c != NULL ? skedAllocation.sked__Job__r.sked_Travel_Time2__c : 0;
                
                skedAllocation.sked_Travel_Time_To__c = travelTimeTo;
                skedAllocation.sked_Travel_Time_Back__c = travelTimeBack;
                skedAllocation.sked__Start__c = skedAllocation.sked__Job__r.sked__Start__c.addMinutes(integer.valueOf(includedTravelTimeTo - travelTimeTo));
                skedAllocation.sked__Set_End__c = skedAllocation.sked__Job__r.sked__Finish__c.addMinutes(integer.valueOf(travelTimeBack - includedTravelTimeBack));
                skedAllocation.sked__Duration__c = skedDateTimeUtils.getDifferentMinutes(skedAllocation.sked__Start__c, skedAllocation.sked__Set_End__c);
            }
        }
    }
    
    private sked_Collection_Op_Staging_Location__c getCOSLByDate(Biomed_Collection_Op_Center__c collectionOperation, Date inputDate) {
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
    
    private skedSkeduloApiData.latlng getResourceGeolocation(sked__Resource__c skedResource, Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById, Date selectedDate) {
        skedSkeduloApiData.latlng origin = new skedSkeduloApiData.latlng();
        origin.lat = skedResource.sked__GeoLocation__Latitude__s;
        origin.lng = skedResource.sked__GeoLocation__Longitude__s;
        
        if (skedResource.sked_Address_Referenced_for_Scheduling__c == 'Work' && skedResource.Use_CO_Address_for_Scheduling__c == TRUE) {
            Id resourceOwnCOId = skedResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;
            origin = this.getStagingGeolocation(resourceOwnCOId, mapCollectionOperationById, selectedDate);
        }
        
        return origin;
    }
    
    private skedSkeduloApiData.latlng getStagingGeolocation(Id collectionOperationId, Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById, Date selectedDate) {
        skedSkeduloApiData.latlng origin = new skedSkeduloApiData.latlng();
        
        Biomed_Collection_Op_Center__c ownCO = mapCollectionOperationById.get(collectionOperationId);
        sked_Collection_Op_Staging_Location__c cosl = getCOSLByDate(ownCO, selectedDate);
        
        if (cosl != NULL) {
            origin.lat = cosl.sked_Staging_Location__r.sked_Geolocation__Latitude__s;
            origin.lng = cosl.sked_Staging_Location__r.sked_Geolocation__Longitude__s;
        }
        
        return origin;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class masterDataWrapper {
        public Set<Id> relocatedJobAllocationIds;
        public Map<Id, skedSkeduloApiData.latlng> mapOriginById;
        public Map<String, skedSkeduloApiData.latlng> mapOriginByKey;
        public Map<Id, skedSkeduloApiData.latlng> mapDestinationById;
        public Map<String, skedSkeduloApiData.latlng> mapDestinationByKey;
        public Map<string, skedSkeduloApiData.Element> mapTravelElementByLatLngKey;

        public Map<Id, Biomed_Collection_Op_Center__c> mapCollectionOperationById;
        Map<Id, sked__Location__c> mapSiteById;
        
        public masterDataWrapper() {
            this.relocatedJobAllocationIds = new Set<Id>();
        }
    }
    
}