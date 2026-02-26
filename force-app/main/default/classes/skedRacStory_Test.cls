@isTest
private class skedRacStory_Test {
    
    static testmethod void testMyAvailability() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        List<string> userTypes = new List<string>();
        userTypes.add('Resource');
        
        User loginUser = new User(
        	Id = UserInfo.getUserId(),
            sked__SkeduloUserType__c = string.join(userTypes, ';')
        );
        update loginUser;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //intialize
        skedRemoteRequestModel initializeRequest = new skedRemoteRequestModel();
        initializeRequest.configKeys = new List<string>();
        initializeRequest.configKeys.add('availabilityTypes');
        skedRemoteResultModel initializeResult = skedRacController.initialize(initializeRequest);
        
        Test.stopTest();
    }

    static testmethod void testAvailabilityPattern() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Region__c testRegion2 = (sked__Region__c)mapTestData.get('testRegion2');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testAsset1 = (sked__Resource__c)mapTestData.get('testAsset1');
        sked__Tag__c testTag1 = (sked__Tag__c)mapTestData.get('testTag1');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //intialize
        skedRemoteRequestModel initializeRequest = new skedRemoteRequestModel();
        initializeRequest.configKeys = new List<string>();
        initializeRequest.configKeys.add('activityTypes');
        initializeRequest.configKeys.add('availabilityTypes');
        initializeRequest.configKeys.add('holidays');
        initializeRequest.configKeys.add('jobTypes');
        initializeRequest.configKeys.add('regions');
        initializeRequest.configKeys.add('serviceLocations');
        initializeRequest.configKeys.add('timezones');
        initializeRequest.configKeys.add('resourceEmploymentTypes');
        initializeRequest.configKeys.add('resourceCategories');
        initializeRequest.configKeys.add('activitySubTypes');
        initializeRequest.configKeys.add('availabilityDeclineReasons');
        initializeRequest.configKeys.add('availabilityStatuses');
        initializeRequest.configKeys.add('biomedCollectionOps');
        initializeRequest.configKeys.add('callOutReasons');
        initializeRequest.configKeys.add('jobCancellationReasons');
        initializeRequest.configKeys.add('jobStatuses');
        initializeRequest.configKeys.add('jobStatusSettings');
        initializeRequest.configKeys.add('locationAvailabilityTypes');
        initializeRequest.configKeys.add('locationTypes');
        initializeRequest.configKeys.add('profiles');
        initializeRequest.configKeys.add('resourceTypes');
        initializeRequest.configKeys.add('roles');
        initializeRequest.configKeys.add('resourceTypes');
        initializeRequest.configKeys.add('staffingBudgetRoles');
        initializeRequest.configKeys.add('staffingBudgetRequestTypes');
        initializeRequest.configKeys.add('skeduloPermissionSets');
        initializeRequest.configKeys.add('skeduloUserTypes');
        initializeRequest.configKeys.add('tags');
        initializeRequest.configKeys.add('territories');
        initializeRequest.configKeys.add('timezones');
        initializeRequest.configKeys.add('skeduloPermissionSets');
        skedRemoteResultModel initializeResult = skedRacController.initialize(initializeRequest);
        
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        sked__Availability_Pattern__c testWeeklyPattern2 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern2');
        
        sked__Availability_Pattern_Resource__c testPatternResource1 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime
        );
        insert testPatternResource1;
        
        sked__Availability_Pattern_Resource__c testPatternResource2 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern2.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime.addDays(7)
        );
        insert testPatternResource2;
        
        //getIndividualResource
        skedRacController.getResourceRequestModel getResourceRequest = new skedRacController.getResourceRequestModel();
        getResourceRequest.viewData = new Map<string, object>();
        getResourceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourceRequest.endDate = testDataFactory.summary.endDateIso;
        getResourceRequest.resourceId = testResource1.Id;
        getResourceRequest.startDate = testDataFactory.summary.startDateIso;
        getResourceRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getResourceResult = skedRacController.getIndividualResourceData(getResourceRequest);
        skedRacController.resourceDataModel resourceDataResult = (skedRacController.resourceDataModel)getResourceResult.data;
        List<skedModels.resource> resources = (List<skedModels.resource>)resourceDataResult.resources;
        
        skedRacController.getResourceRequestModel getResourceDataRequest = new skedRacController.getResourceRequestModel();
        getResourceDataRequest.viewData = new Map<string, object>();
        getResourceDataRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourceDataRequest.endDate = testDataFactory.summary.endDateIso;
        getResourceDataRequest.patternIds = new List<string>();
        getResourceDataRequest.patternIds.add(testWeeklyPattern1.Id);
        getResourceDataRequest.startDate = testDataFactory.summary.startDateIso;
        getResourceDataRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getResourceDataResult = skedRacController.getResourceData(getResourceDataRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testGetResourceData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Region__c testRegion2 = (sked__Region__c)mapTestData.get('testRegion2');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testAsset1 = (sked__Resource__c)mapTestData.get('testAsset1');
        sked__Tag__c testTag1 = (sked__Tag__c)mapTestData.get('testTag1');
        
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        List<string> availabilityTypes = skedUtils.getPickListValues('sked__Availability__c', 'sked__Type__c');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //intialize
        skedRemoteRequestModel initializeRequest = new skedRemoteRequestModel();
        initializeRequest.configKeys = new List<string>();
        initializeRequest.configKeys.add('activityTypes');
        initializeRequest.configKeys.add('availabilityTypes');
        initializeRequest.configKeys.add('holidays');
        initializeRequest.configKeys.add('jobTypes');
        initializeRequest.configKeys.add('regions');
        initializeRequest.configKeys.add('serviceLocations');
        initializeRequest.configKeys.add('timezones');
        initializeRequest.configKeys.add('resourceEmploymentTypes');
        initializeRequest.configKeys.add('resourceCategories');
        skedRemoteResultModel initializeResult = skedRacController.initialize(initializeRequest);
        
        //getResources
        skedRacController.getResourceRequestModel getResourcesRequest = new skedRacController.getResourceRequestModel();
        getResourcesRequest.viewData = new Map<string, object>();
        getResourcesRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourcesRequest.endDate = testDataFactory.summary.endDateIso;
        getResourcesRequest.pageNo = 1;
        getResourcesRequest.pageSize = 25;
        getResourcesRequest.biomedCollectionOpIds = new List<string>();
        getResourcesRequest.biomedCollectionOpIds.add(testCollectionOperation1.Id);
        getResourcesRequest.regionIds = new List<string>();
        getResourcesRequest.regionIds.add(testRegion1.Id);
        getResourcesRequest.startDate = testDataFactory.summary.startDateIso;
        getResourcesRequest.tagIds = new List<string>();
        getResourcesRequest.tagIds.add(testTag1.Id);
        getResourcesRequest.activityTypes = activityTypes;
        getResourcesRequest.availabilityTypes = availabilityTypes;
        getResourcesRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getResourcesResult = skedRacController.getResourceData(getResourcesRequest);
        skedRacController.resourceDataModel resourcesDataResult = (skedRacController.resourceDataModel)getResourcesResult.data;
        List<sked__Resource__c> skedResources = (List<sked__Resource__c>)resourcesDataResult.resources;
        
        //getResources for second region
        getResourcesRequest.regionIds = new List<string>();
        getResourcesRequest.regionIds.add(testRegion2.Id);
        getResourcesResult = skedRacController.getResourceData(getResourcesRequest);
        resourcesDataResult = (skedRacController.resourceDataModel)getResourcesResult.data;
        skedResources = (List<sked__Resource__c>)resourcesDataResult.resources;
        
        //getIndividualResource
        skedRacController.getResourceRequestModel getResourceRequest = new skedRacController.getResourceRequestModel();
        getResourceRequest.viewData = new Map<string, object>();
        getResourceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourceRequest.endDate = testDataFactory.summary.endDateIso;
        getResourceRequest.resourceId = testResource1.Id;
        getResourceRequest.startDate = testDataFactory.summary.startDateIso;
        getResourceRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getResourceResult = skedRacController.getIndividualResourceData(getResourceRequest);
        skedRacController.resourceDataModel resourceDataResult = (skedRacController.resourceDataModel)getResourceResult.data;
        
        List<skedModels.resource> resources = (List<skedModels.resource>)resourceDataResult.resources;
        
        Test.stopTest();
    }
    
    static testmethod void testGetResources() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Region__c testRegion2 = (sked__Region__c)mapTestData.get('testRegion2');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testAsset1 = (sked__Resource__c)mapTestData.get('testAsset1');
        sked__Tag__c testTag1 = (sked__Tag__c)mapTestData.get('testTag1');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        List<string> resourceCategories = skedUtils.getPickListValues('sked__Resource__c', 'sked__Category__c');
        List<string> resourceEmploymentTypes = skedUtils.getPickListValues('sked__Resource__c', 'sked__Employment_Type__c');
        
        //getResources
        skedRacController.getResourceRequestModel getResourcesRequest = new skedRacController.getResourceRequestModel();
        getResourcesRequest.viewData = new Map<string, object>();
        getResourcesRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourcesRequest.endDate = testDataFactory.summary.endDateIso;
        getResourcesRequest.pageNo = 1;
        getResourcesRequest.pageSize = 25;
        getResourcesRequest.regionIds = new List<string>();
        getResourcesRequest.regionIds.add(testRegion1.Id);
        getResourcesRequest.resourceCategories = resourceCategories;
        getResourcesRequest.resourceEmploymentTypes = resourceEmploymentTypes;
        getResourcesRequest.startDate = testDataFactory.summary.startDateIso;
        getResourcesRequest.tagIds = new List<string>();
        getResourcesRequest.tagIds.add(testTag1.Id);
        getResourcesRequest.startDate = testDataFactory.summary.startDateIso;
        getResourcesRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getResourcesResult = skedRacController.getResources(getResourcesRequest);
        
        Test.stopTest();
    }
    
    
    
    static testmethod void testGetTerritories() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //getResources
        skedRacController.getTerritoriesRequestModel getTerritoriesRequest = new skedRacController.getTerritoriesRequestModel();
        getTerritoriesRequest.viewData = new Map<string, object>();
        getTerritoriesRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getTerritoriesRequest.endDate = testDataFactory.summary.endDateIso;
        getTerritoriesRequest.startDate = testDataFactory.summary.startDateIso;
        skedRemoteResultModel getTerritoriesResult = skedRacController.getTerritories(getTerritoriesRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testSaveActivityResources() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = activityTypes.get(0),
            sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE
        );
        insert skedGroupActivity;
        
        sked__Activity_Resource__c skedActivityResource = new sked__Activity_Resource__c(
        	sked__Activity__c = skedGroupActivity.Id,
            sked__Resource__c = testResource1.Id
        );
        insert skedActivityResource;
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        skedRacController.saveActivityResourcesRequestModel saveActivityResourcesRequest = new skedRacController.saveActivityResourcesRequestModel();
        saveActivityResourcesRequest.viewData = new Map<string, object>();
        saveActivityResourcesRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        skedModels.activityResource event = new skedModels.activityResource();
        event.id = skedActivityResource.Id;
        event.activityId = skedGroupActivity.Id;
        event.resourceId = testResource1.Id;
        event.endDate = testDataFactory.summary.startDateIso;
        event.endTime = 1700;
        event.startDate = testDataFactory.summary.startDateIso;
        event.startTime = 900;
        event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveActivityResourcesRequest.activityResources = new List<skedModels.activityResource>();
        saveActivityResourcesRequest.activityResources.add(event);
        
        skedRacController.validateActivityResources(saveActivityResourcesRequest);
        skedRacController.saveActivityResources(saveActivityResourcesRequest);
        
        skedRacController.saveActivityResourceRequestModel saveActivityResourceRequest = new skedRacController.saveActivityResourceRequestModel();
        saveActivityResourceRequest.viewData = new Map<string, object>();
        saveActivityResourceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveActivityResourceRequest.activityResource = event;
        
        skedRacController.saveActivityResource(saveActivityResourceRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testAvailabilityCRUD() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c) mapTestData.get('testWeeklyPattern1');
        
        sked__Availability_Pattern_Resource__c testAvailabilityPatternResource = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Start__c = testDataFactory.summary.startTime
        );
        insert testAvailabilityPatternResource;
        
        List<string> userTypes = new List<string>();
        userTypes.add('Resource');
        
        User loginUser = new User(
        	Id = UserInfo.getUserId(),
            sked__SkeduloUserType__c = string.join(userTypes, ';')
        );
        update loginUser;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //create availability
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 1700;
        saveAvailabilityRequest.event.eventType = 'Available';
        saveAvailabilityRequest.event.notes = 'notes';
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 900;
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        saveAvailabilityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveAvailabilityRequest.event.isAvailable = true;
        skedRemoteResultModel saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        sked__Availability__c availabilityChecking = [SELECT Id, sked__Start__c, sked__Finish__c, sked__Notes__c, sked__Type__c, sked__Resource__c
                                                      FROM sked__Availability__c];
        
        //get event details
        skedRacController.getAvailabilityDetailsRequest getAvailabilityDetailsRequest = new skedRacController.getAvailabilityDetailsRequest();
        getAvailabilityDetailsRequest.viewData = new Map<string, object>();
        getAvailabilityDetailsRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getAvailabilityDetailsRequest.event = new skedModels.availability();
        getAvailabilityDetailsRequest.event.id = availabilityChecking.Id;
        skedRemoteResultModel getEventDetailsResult = skedRacController.getEventDetails(getAvailabilityDetailsRequest);
        
        //edit availability
        saveAvailabilityRequest.event.id = availabilityChecking.Id;
        saveAvailabilityRequest.event.endTime = 1800;
        saveAvailabilityRequest.event.startTime = 1000;
        saveAvailabilityRequest.event.notes = 'updated notes';
        saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        availabilityChecking = [SELECT Id, sked__Start__c, sked__Finish__c, sked__Notes__c, sked__Type__c, sked__Resource__c
                                FROM sked__Availability__c];
        
        skedRemoteResultModel deleteAvailabilityResult = skedRacController.deleteAvailability(saveAvailabilityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testUnavailabilityCRUD() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //create unavailability
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 1700;
        saveAvailabilityRequest.event.eventType = 'PTO';
        saveAvailabilityRequest.event.notes = 'notes';
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 900;
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        saveAvailabilityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel prepareUnavailabilityResult = skedRacController.prepareUnavailabilityRequest(saveAvailabilityRequest);
        
        skedModels.availability event1 = new skedModels.availability();
        event1.endDate = testDataFactory.summary.startDateIso;
        event1.endTime = 1700;
        event1.eventType = 'PTO';
        event1.notes = 'notes';
        event1.startDate = testDataFactory.summary.startDateIso;
        event1.startTime = 900;
        event1.resourceId = testResource1.Id;
        event1.timezoneSidId = testDataFactory.summary.timezoneSidId;
        
        skedModels.availability event2 = new skedModels.availability();
        event2.endDate = testDataFactory.summary.startDateIso;
        event2.endTime = 1700;
        event2.eventType = 'PTO';
        event2.notes = 'notes';
        event2.startDate = Json.serialize(testDataFactory.summary.startDate.addDays(1)).replace('"', '');
        event2.startTime = 900;
        event2.resourceId = testResource1.Id;
        event2.timezoneSidId = testDataFactory.summary.timezoneSidId;
        
        skedRacController.verifyUnavailabilityBalanceRequestModel verifyUnavailabilityBalanceRequest = new skedRacController.verifyUnavailabilityBalanceRequestModel();
        verifyUnavailabilityBalanceRequest.viewData = new Map<string, object>();
        verifyUnavailabilityBalanceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        verifyUnavailabilityBalanceRequest.unavailability = new List<skedModels.availability>();
        verifyUnavailabilityBalanceRequest.unavailability.add(event1);
        verifyUnavailabilityBalanceRequest.unavailability.add(event2);
        skedRemoteResultModel verifyUnavailabilityBalanceResult = skedRacController.verifyUnavailabilityBalance(verifyUnavailabilityBalanceRequest);
        
        skedRacController.saveUnavailabilityRequestModel saveUnavailabilityRequest = new skedRacController.saveUnavailabilityRequestModel();
        saveUnavailabilityRequest.viewData = new Map<string, object>();
        saveUnavailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveUnavailabilityRequest.availability = new List<skedModels.availability>();
        saveUnavailabilityRequest.availability.add(event1);
        saveUnavailabilityRequest.availability.add(event2);
        skedRemoteResultModel saveUnavailabilityResult = skedRacController.saveUnavailability(saveUnavailabilityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testAvailabilityDelete() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c) mapTestData.get('testWeeklyPattern1');
        
        sked__Availability_Pattern_Resource__c testAvailabilityPatternResource = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Start__c = testDataFactory.summary.startTime
        );
        insert testAvailabilityPatternResource;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //create availability
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 1700;
        saveAvailabilityRequest.event.eventType = 'Available';
        saveAvailabilityRequest.event.notes = 'notes';
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 900;
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        saveAvailabilityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveAvailabilityRequest.event.isAvailable = true;
        skedRemoteResultModel saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        sked__Availability__c availabilityChecking = [SELECT Id, sked__Start__c, sked__Finish__c, sked__Notes__c, sked__Type__c, sked__Resource__c
                                                      FROM sked__Availability__c];
        
        //edit availability
        saveAvailabilityRequest.event.id = availabilityChecking.Id;
        saveAvailabilityRequest.events = new List<skedModels.availability>();
        saveAvailabilityRequest.events.add(saveAvailabilityRequest.event);
        skedRemoteResultModel deleteAvailabilityResult = skedRacController.deleteAvailabilities(saveAvailabilityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testRecurringAvailability() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.eventType = 'Available';
        saveAvailabilityRequest.event.notes = 'notes';
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 100;
        saveAvailabilityRequest.event.endTime = 2300;
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        saveAvailabilityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        skedModels.availabilityTemplate template = new skedModels.availabilityTemplate();
        List<skedModels.availabilityTemplateEntry> entries = new List<skedModels.availabilityTemplateEntry>();
        
        for (string weekday : testDataFactory.summary.weekdays) {
            skedModels.availabilityTemplateEntry entry = new skedModels.availabilityTemplateEntry();
            entry.weekday = weekday;
            entry.weekNo = 1;
            entry.endTime = 2300;
            entry.startTime = 100;
            entries.add(entry);
        }
        
        template.availabilityTemplateEntries = entries;
        template.endDate = testDataFactory.summary.endDateIso;
        template.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.recurringOptions.availabilityTemplate = template;
        saveAvailabilityRequest.recurringOptions.skipHolidays = TRUE;
        skedRemoteResultModel saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        //editRecurring all_events
        sked__Availability__c firstAvailability = [SELECT Id, sked_Recurring_Schedule__c FROM sked__Availability__c ORDER BY sked__Start__c ASC LIMIT 1];
        saveAvailabilityRequest.event.id = firstAvailability.Id;
        saveAvailabilityRequest.event.scheduleId = firstAvailability.sked_Recurring_Schedule__c;
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 2330;
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 130;
        saveAvailabilityRequest.event.notes = 'notes edit 1';
        saveAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        saveAvailabilityRequest.recurringOptions.editAction = 'all_events';
        saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        //editRecurring following_events
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 2300;
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 100;
        saveAvailabilityRequest.event.notes = 'notes edit 2';
        saveAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        saveAvailabilityRequest.recurringOptions.editAction = 'following_events';
        saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        //editRecurring same_weekday
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 2330;
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 130;
        saveAvailabilityRequest.event.notes = 'notes edit 3';
        saveAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        saveAvailabilityRequest.recurringOptions.editAction = 'same_weekday';
        saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        //deleteRecurring same_weekday
        saveAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        saveAvailabilityRequest.recurringOptions.editAction = 'same_weekday';
        saveAvailabilityRequest.recurringOptions.isDeleting = true;
        saveAvailabilityResult = skedRacController.deleteAvailability(saveAvailabilityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testRecurringSelectDatesAvailability() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.eventType = 'Available';
        saveAvailabilityRequest.event.notes = 'notes';
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 100;
        saveAvailabilityRequest.event.endTime = 2300;
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        saveAvailabilityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        saveAvailabilityRequest.recurringOptions.dateValues = new Set<Date>();
        saveAvailabilityRequest.recurringOptions.dateValues.add(System.today());
        saveAvailabilityRequest.recurringOptions.dateValues.add(System.today().addDays(1));
        saveAvailabilityRequest.recurringOptions.dateValues.add(System.today().addDays(2));
        skedRemoteResultModel saveAvailabilityResult = skedRacController.saveAvailability(saveAvailabilityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testActivityCRUD() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        List<sked_Staffing_Constraint__c> constraints = new List<sked_Staffing_Constraint__c>();
        sked_Staffing_Constraint__c fixedSiteStaffingConstraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDataFactory.summary.startDate,
            sked_Drive_Type__c = 'Fixed Site',
            sked_Total_Staff_Constraints__c = 20
        );
        constraints.add(fixedSiteStaffingConstraint);
        
        sked_Staffing_Constraint__c mobileStaffingConstraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDataFactory.summary.startDate,
            sked_Drive_Type__c = 'Mobile',
            sked_Total_Staff_Constraints__c = 20
        );
        constraints.add(mobileStaffingConstraint);
        insert constraints;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        skedRacController.saveActivityRequestModel saveActivityRequest = new skedRacController.saveActivityRequestModel();
        saveActivityRequest.viewData = new Map<string, object>();
        saveActivityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveActivityRequest.event = new skedModels.activity();
        saveActivityRequest.event.address = new skedModels.address();
        saveActivityRequest.event.address.fullAddress = 'Retail Unit 2, 2 Regent St, London SW1Y 4PE, United Kingdom';
        saveActivityRequest.event.address.geometry = new skedModels.geometry(51.508105, -0.132901);
        saveActivityRequest.event.biomedCollectionOpId = testCollectionOperation1.Id;
        saveActivityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveActivityRequest.event.endTime = 1700;
        saveActivityRequest.event.eventType = 'Administrative';
        saveActivityRequest.event.isGroupActivity = true;
        saveActivityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveActivityRequest.event.startTime = 900;
        saveActivityRequest.event.reduceFromStaffingConstraint = true;
        saveActivityRequest.event.mobileStaffQuantity = 1;
        saveActivityRequest.event.fixedSiteStaffQuantity = 1;
        saveActivityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel saveActivityResult = skedRacController.saveActivity(saveActivityRequest);
        
        sked__Activity__c activityChecking = [SELECT Id, sked__Start__c, sked__End__c, sked__Type__c, sked__Resource__c, sked__Address__c,
                                              sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s
                                              FROM sked__Activity__c];
        
        saveActivityRequest.event.id = activityChecking.Id;
        saveActivityRequest.event.endTime = 1800;
        saveActivityRequest.event.startTime = 1000;
        saveActivityRequest.event.notes = 'updated notes';
        saveActivityResult = skedRacController.saveActivity(saveActivityRequest);
        
        activityChecking = [SELECT Id, sked__Start__c, sked__End__c, sked__Type__c, sked__Resource__c, sked__Address__c,
                            sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s
                            FROM sked__Activity__c];
        
        skedRemoteResultModel deleteActivityResult = skedRacController.deleteActivity(saveActivityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testApprovalRequest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        List<string> resourceCategories = skedUtils.getPickListValues('sked__Resource__c', 'sked__Category__c');
        
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        
        sked__Availability__c avail = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Available',
            sked__Is_Available__c = TRUE,
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(17),
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING
        );
        insert avail;
        
        sked_Staffing_Budget__c testStaffingBudget = new sked_Staffing_Budget__c(
            sked_Roles__c = '2RBC',
            sked_Drive_Types__c = 'Mobile;Fixed Site',
            sked_Staffing_Budget_Date__c = testDataFactory.summary.startDate,
            sked_Total_Slots__c = 20,
            sked_Request_Type__c = 'Standard'
        );
        insert testStaffingBudget;
        
        sked_Staffing_Budget_Availability__c testStaffingBudgetAvailability = new sked_Staffing_Budget_Availability__c(
        	sked_Availability__c = avail.Id,
        	sked_Staffing_Budget__c = testStaffingBudget.Id
        );
        insert testStaffingBudgetAvailability;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //getPendingAvailabilityRequest
        skedRacController.getPendingAvailabilityRequestModel getPendingAvailabilityRequest = new skedRacController.getPendingAvailabilityRequestModel();
        getPendingAvailabilityRequest.viewData = new Map<string, object>();
        getPendingAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getPendingAvailabilityRequest.endDate = testDataFactory.summary.endDateIso;
        getPendingAvailabilityRequest.pageNo = 1;
        getPendingAvailabilityRequest.pageSize = 25;
        getPendingAvailabilityRequest.regionIds = new List<string>();
        getPendingAvailabilityRequest.regionIds.add(testRegion1.Id);
        getPendingAvailabilityRequest.resourceCategories = resourceCategories;
        getPendingAvailabilityRequest.startDate = testDataFactory.summary.startDateIso;
        getPendingAvailabilityRequest.submissionEndDate = Json.serialize(Date.today()).replace('"', '');
        getPendingAvailabilityRequest.submissionStartDate = Json.serialize(Date.today()).replace('"', '');
        getPendingAvailabilityRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getPendingAvailabilityResult = skedRacController.getPendingAvailability(getPendingAvailabilityRequest);
        
        //approveAvailability 
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.id = avail.Id;
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 1700;
        saveAvailabilityRequest.event.eventType = 'Available';
        saveAvailabilityRequest.event.isAvailable = TRUE;
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 900;
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        skedRemoteResultModel saveAvailabilityResult = skedRacController.approveAvailability(saveAvailabilityRequest);
        
        sked__Availability__c availabilityChecking = [SELECT Id, sked__Status__c, sked_Custom_Status__c
                                                      FROM sked__Availability__c WHERE Id = :avail.Id];

        //waitlistAvailability
        saveAvailabilityResult = skedRacController.waitlistAvailability(saveAvailabilityRequest);
        
        //declineAvailability
        saveAvailabilityResult = skedRacController.declineAvailability(saveAvailabilityRequest);
        
        //cancelAvailability
        saveAvailabilityResult = skedRacController.cancelAvailability(saveAvailabilityRequest);
        
        Test.stopTest();
    }

    static testmethod void testCancelAvailability() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        List<string> resourceCategories = skedUtils.getPickListValues('sked__Resource__c', 'sked__Category__c');
        
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        
        sked__Recurring_Schedule__c testRecurringSchedule = new sked__Recurring_Schedule__c();
        insert testRecurringSchedule;
        
        sked__Availability__c avail = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'Available',
            sked__Is_Available__c = TRUE,
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(17),
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING,
            sked_Recurring_Schedule__c = testRecurringSchedule.Id
        );
        insert avail;
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //approveAvailability 
        skedRacController.saveAvailabilityRequestModel cancelAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        cancelAvailabilityRequest.viewData = new Map<string, object>();
        cancelAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        cancelAvailabilityRequest.event = new skedModels.availability();
        cancelAvailabilityRequest.event.id = avail.Id;
        cancelAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        cancelAvailabilityRequest.event.endTime = 1700;
        cancelAvailabilityRequest.event.eventType = 'Available';
        cancelAvailabilityRequest.event.isAvailable = TRUE;
        cancelAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        cancelAvailabilityRequest.event.startTime = 900;
        cancelAvailabilityRequest.event.resourceId = testResource1.Id;
        cancelAvailabilityRequest.event.scheduleId = testRecurringSchedule.Id;
        cancelAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        cancelAvailabilityRequest.recurringOptions.editAction = 'following_events';
        skedRemoteResultModel saveAvailabilityResult = skedRacController.approveAvailability(cancelAvailabilityRequest);
        
        //cancelAvailability
        saveAvailabilityResult = skedRacController.cancelAvailability(cancelAvailabilityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testPtoFlow() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //create availability
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.eventType = 'Available';
        saveAvailabilityRequest.event.notes = 'notes';
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        saveAvailabilityRequest.recurringOptions = new skedBaseController.recurringOption();
        skedModels.availabilityTemplate template = new skedModels.availabilityTemplate();
        List<skedModels.availabilityTemplateEntry> entries = new List<skedModels.availabilityTemplateEntry>();
        for (string weekday : testDataFactory.summary.weekdays) {
            skedModels.availabilityTemplateEntry entry = new skedModels.availabilityTemplateEntry();
            entry.weekday = weekday;
            entry.weekNo = 1;
            entries.add(entry);
        }
        template.availabilityTemplateEntries = entries;
        template.endDate = testDataFactory.summary.endDateIso;
        template.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.recurringOptions.availabilityTemplate = template;
        saveAvailabilityRequest.recurringOptions.skipHolidays = TRUE;
        
        Test.stopTest();
    }
    
    static testmethod void testGetUnavailabilityStatistic() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        
        sked__Availability__c pto = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Is_Available__c = FALSE,
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED,
            sked__Start__c = testDataFactory.summary.startTime.addHours(8),
            sked__Finish__c = testDataFactory.summary.startTime.addHours(9)
        );
        insert pto;
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        skedRacController.getUnavailabilityStatisticRequestModel getUnavailabilityStatisticRequest = new skedRacController.getUnavailabilityStatisticRequestModel();
        getUnavailabilityStatisticRequest.viewData = new Map<string, object>();
        getUnavailabilityStatisticRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getUnavailabilityStatisticRequest.resourceId = testResource1.Id;
        getUnavailabilityStatisticRequest.selectedDate = testDataFactory.summary.startDateIso;
        
        skedRemoteResultModel getUnavailabilityStatisticResult = skedRacController.getUnavailabilityStatistic(getUnavailabilityStatisticRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testSearch() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        
        skedBaseController.searchRequestModel searchRequest = new skedBaseController.searchRequestModel();
        searchRequest.objectType = 'region';
        searchRequest.queryText = testRegion1.Name;
        searchRequest.criteria = new Map<string, object>();
        searchRequest.criteria.put('name', testRegion1.Name);
        skedRemoteResultModel searchResult = skedRacController.search(searchRequest);
        List<skedModels.region> regions = (List<skedModels.region>)searchResult.data;
        
        Test.stopTest();
    }
    
    static testmethod void testSavePattern() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        skedModels.availabilityPattern availabilityPattern = new skedModels.availabilityPattern();
        availabilityPattern.id = testWeeklyPattern1.Id;
        availabilityPattern.pattern = testWeeklyPattern1.sked__Pattern__c;
        availabilityPattern.hash = testWeeklyPattern1.sked__Hash__c;
        availabilityPattern.validate2CDORule = FALSE;
        availabilityPattern.availabilityPatternResources = new List<skedModels.availabilityPatternResource>();
        skedModels.availabilityPatternResource patternResource = new skedModels.availabilityPatternResource();
        patternResource.resourceId = testResource1.Id;
        patternResource.startDate = testDataFactory.summary.startDateIso;
        availabilityPattern.availabilityPatternResources.add(patternResource);
        
        skedRacController.savePatternRequestModel savePatternRequest = new skedRacController.savePatternRequestModel();
        savePatternRequest.viewData = new Map<string, object>();
        savePatternRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        savePatternRequest.availabilityPattern = availabilityPattern;
        skedRemoteResultModel savePatternResult = skedRacController.savePattern(savePatternRequest);
        
        skedRacController.savePatternResourceRequestModel savePatternResourceRequest = new skedRacController.savePatternResourceRequestModel();
        savePatternResourceRequest.viewData = new Map<string, object>();
        savePatternResourceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        savePatternResourceRequest.availabilityPatternResource = patternResource;
        sked__Availability_Pattern__c skedAvailabilityPattern = [SELECT Id FROM sked__Availability_Pattern__c LIMIT 1];
        savePatternResourceRequest.availabilityPatternResource.availabilityPatternId = skedAvailabilityPattern.Id;
        skedRemoteResultModel savePatternResourceResult = skedRacController.savePatternResource(savePatternResourceRequest);
        
        sked__Availability_Pattern__c testWeeklyPattern2 = new sked__Availability_Pattern__c(
            Name = 'Test Weekly Pattern 2',
            sked__Hash__c = 'weeklyPatternHash',
            sked_Validate_2CDO_Rule__c = FALSE,
            sked__Pattern__c = ''
        );
        insert testWeeklyPattern2;
        sked__Availability_Pattern_Resource__c testPatternResource2 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern2.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime.addDays(7)
        );
        insert testPatternResource2;
        
        skedBaseController.getDataRequestModel getPatternResourceRequest = new skedBaseController.getDataRequestModel();
        getPatternResourceRequest.viewData = new Map<string, object>();
        getPatternResourceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getPatternResourceRequest.recordId = testWeeklyPattern1.Id;
        getPatternResourceRequest.pageSize = 10;
        getPatternResourceRequest.pageNo = 1;
        skedRacController.getPatternResources(getPatternResourceRequest);
        
        skedBaseController.getDataRequestModel getPatternDetailsRequest = new skedBaseController.getDataRequestModel();
        getPatternDetailsRequest.viewData = new Map<string, object>();
        getPatternDetailsRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getPatternDetailsRequest.recordId = skedAvailabilityPattern.Id;
        skedRacController.getPatternDetails(getPatternDetailsRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testPatternRender() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        skedRacController.getResourceRequestModel getResourceRequest = new skedRacController.getResourceRequestModel();
        getResourceRequest.viewData = new Map<string, object>();
        getResourceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourceRequest.endDate = testDataFactory.summary.endDateIso;
        getResourceRequest.resourceId = testResource1.Id;
        getResourceRequest.startDate = testDataFactory.summary.startDateIso;
        getResourceRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getResourceResult = skedRacController.getIndividualResourceData(getResourceRequest);
        
        //test rendering custom pattern
        skedAvailabilityPatternData customPatternData = new skedAvailabilityPatternData();
        customPatternData.type = 'custom';
        customPatternData.lengthDays = 1;
        customPatternData.days = new List<skedAvailabilityPatternData.dayModel>();
        
        skedAvailabilityPatternData.dayModel day = new skedAvailabilityPatternData.dayModel();
        day.day = 1;
        day.intervals = new List<skedAvailabilityPatternData.intervalModel>();
        skedAvailabilityPatternData.intervalModel interval = new skedAvailabilityPatternData.intervalModel();
        interval.startTime = '09:00';
        interval.endTime = '18:00';
        day.intervals.add(interval);
        customPatternData.days.add(day);
        testWeeklyPattern1.sked__Pattern__c = Json.serialize(customPatternData);
        update testWeeklyPattern1;
        
        getResourceResult = skedRacController.getIndividualResourceData(getResourceRequest);
        Test.stopTest();
    }
    
    static testmethod void testResourceOverride() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        
        Test.startTest();
        
        skedRacController.saveResourceOverrideRequestModel request = new skedRacController.saveResourceOverrideRequestModel();
        request.viewData = new Map<string, object>();
        request.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        
        request.resourceOverride = new skedModels.resourceOverride();
        request.resourceOverride.startDate = testDataFactory.summary.startDateIso;
        request.resourceOverride.startTime = 0;
        request.resourceOverride.endDate = testDataFactory.summary.endDateIso;
        request.resourceOverride.endTime = 0;
        request.resourceOverride.resourceId = testResource1.Id;
        request.resourceOverride.address = new skedModels.address();
        request.resourceOverride.address.fullAddress = 'test';
        request.resourceOverride.address.geometry = new skedModels.geometry(0,0);
        request.resourceOverride.travelToStartDate = Json.serialize(testDataFactory.summary.startDate).replace('"', '');
        request.resourceOverride.travelToStartTime = 1000;
        request.resourceOverride.travelToEndDate = Json.serialize(testDataFactory.summary.startDate.addDays(2)).replace('"', '');
        request.resourceOverride.travelToEndTime = 1500;
        request.resourceOverride.travelBackStartDate = Json.serialize(testDataFactory.summary.endDate.addDays(-2)).replace('"', '');
        request.resourceOverride.travelBackStartTime = 1000;
        request.resourceOverride.travelBackEndDate = Json.serialize(testDataFactory.summary.endDate).replace('"', '');
        request.resourceOverride.travelBackEndTime = 1500;
        request.resourceOverride.biomedCollectionOpId = testCollectionOperation1.Id;
        request.resourceOverride.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel result = skedRacController.saveResourceOverride(request);
        
        List<sked__Resource_Override__c> resourceOverrides = [Select Id From sked__Resource_Override__c];
        
        request.resourceOverride.id = resourceOverrides.get(0).Id;
        request.resourceOverride.isTravelRequired = TRUE;
        request.resourceOverride.travelToStartDate = Json.serialize(testDataFactory.summary.startDate).replace('"', '');
        request.resourceOverride.travelToStartTime = 1100;
        request.resourceOverride.travelToEndDate = Json.serialize(testDataFactory.summary.startDate.addDays(2)).replace('"', '');
        request.resourceOverride.travelToEndTime = 1600;
        request.resourceOverride.travelBackStartDate = Json.serialize(testDataFactory.summary.endDate.addDays(-2)).replace('"', '');
        request.resourceOverride.travelBackStartTime = 1100;
        request.resourceOverride.travelBackEndDate = Json.serialize(testDataFactory.summary.endDate).replace('"', '');
        request.resourceOverride.travelBackEndTime = 1600;
        skedRemoteResultModel editResult = skedRacController.saveResourceOverride(request);
        
        skedBaseController.getDataRequestModel getResourceOverrideRequest = new skedBaseController.getDataRequestModel();
        getResourceOverrideRequest.viewData = new Map<string, object>();
        getResourceOverrideRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourceOverrideRequest.recordId = resourceOverrides.get(0).Id;
        skedRemoteResultModel getResourceOverrideResult = skedRacController.getResourceOverride(getResourceOverrideRequest);
        
        request.resourceOverride.Id = resourceOverrides.get(0).Id;
        skedRemoteResultModel deleteResult = skedRacController.deleteResourceOverride(request);
    }
    
    static testmethod void testSaveCallOut() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        sked__Job_Allocation__c jobAllocation = [SELECT sked__Job__c, sked__Resource__c FROM sked__Job_Allocation__c LIMIT 1];
        
        Test.startTest();
        
        skedRacController.saveCallOutRequestModel saveCallOutRequest = new skedRacController.saveCallOutRequestModel();
        saveCallOutRequest.viewData = new Map<string, object>();
        saveCallOutRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveCallOutRequest.jobId = jobAllocation.sked__Job__c;
        saveCallOutRequest.resourceId = jobAllocation.sked__Resource__c;
        saveCallOutRequest.callOutReported = TRUE;
        skedRemoteResultModel saveCallOutResult = skedRacController.saveCallOut(saveCallOutRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testSearchBioMed() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        sked__Job_Allocation__c jobAllocation = [SELECT sked__Job__c, sked__Resource__c FROM sked__Job_Allocation__c LIMIT 1];
        
        Test.startTest();
        
        skedBaseController.getDataRequestModel searchBiomedCollectionOpsRequest = new skedBaseController.getDataRequestModel();
        searchBiomedCollectionOpsRequest.viewData = new Map<string, object>();
        searchBiomedCollectionOpsRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        skedRemoteResultModel searchBiomedCollectionOpsResult = skedRacController.searchBiomedCollectionOps(searchBiomedCollectionOpsRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testSearchDrive() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked_Territory__c testTerritoryParent1 = new sked_Territory__c(
        	Name = 'Test Territory Parent 1',
            RecordTypeId = sked_Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('sked_ARC_Region').getRecordTypeId()
        );
        insert testTerritoryParent1;
        
        sked_Territory__c testTerritory1 = (sked_Territory__c)mapTestData.get('testTerritory1');
        testTerritory1.sked_Parent__c = testTerritoryParent1.Id;
        update testTerritory1;
        
        Test.startTest();
        mapTestData = testDataFactory.setupDriveData();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Job_Allocation__c jobAllocation = [SELECT sked__Job__c, sked__Resource__c FROM sked__Job_Allocation__c LIMIT 1];
        
        skedRacController.searchDrivesRequestModel searchDrivesRequest = new skedRacController.searchDrivesRequestModel();
        searchDrivesRequest.viewData = new Map<string, object>();
        searchDrivesRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        searchDrivesRequest.queryText = 'Test';
        searchDrivesRequest.collectionOperationId = testCollectionOperation1.Id;
        searchDrivesRequest.startDate = testDataFactory.summary.startDateIso;
        searchDrivesRequest.endDate = testDataFactory.summary.endDateIso;
        skedRemoteResultModel searchDrivesResult = skedRacController.searchDrives(searchDrivesRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testStaffingBudget() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        skedRacController.saveStaffingBudgetRequestModel saveStaffingBudgetRequest = new skedRacController.saveStaffingBudgetRequestModel();
        saveStaffingBudgetRequest.viewData = new Map<string, object>();
        saveStaffingBudgetRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveStaffingBudgetRequest.event = new skedModels.staffingBudget();
        saveStaffingBudgetRequest.event.staffingBudgetDate = testDataFactory.summary.startDateIso;
        saveStaffingBudgetRequest.event.roles = new List<string>();
        saveStaffingBudgetRequest.event.roles.add('Driver');
        saveStaffingBudgetRequest.event.driveTypes = new List<string>();
        saveStaffingBudgetRequest.event.driveTypes.add('Mobile');
        saveStaffingBudgetRequest.event.driveTypes.add('Fixed Site');
        saveStaffingBudgetRequest.event.collectionOperationIds = new List<String>();
        saveStaffingBudgetRequest.event.collectionOperationIds.add(testCollectionOperation1.Id);
        
        skedRemoteResultModel saveStaffingBudgetResult = skedRacController.saveStaffingBudget(saveStaffingBudgetRequest);
        
        sked_Staffing_Budget__c skedStaffingBudget = [SELECT Id FROM sked_Staffing_Budget__c WHERE sked_Recurring_Schedule__c = NULL LIMIT 1];
        saveStaffingBudgetRequest.event.Id = skedStaffingBudget.Id;
        skedRemoteResultModel deleteStaffingBudgetResult = skedRacController.deleteStaffingBudget(saveStaffingBudgetRequest);
        
        skedRacController.saveBulkStaffingBudgetRequestModel saveBulkStaffingBudget = new skedRacController.saveBulkStaffingBudgetRequestModel();
        saveBulkStaffingBudget.viewData = new Map<string, object>();
        saveBulkStaffingBudget.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveBulkStaffingBudget.staffingBudgets = new List<skedModels.staffingBudget>();
        
        skedModels.staffingBudget staffingBudgetInput = new skedModels.staffingBudget();
        staffingBudgetInput.staffingBudgetDate = testDataFactory.summary.startDateIso;
        staffingBudgetInput.roles = new List<string>();
        staffingBudgetInput.roles.add('Driver');
        staffingBudgetInput.driveTypes = new List<String>();
        staffingBudgetInput.driveTypes.add('Mobile');
        staffingBudgetInput.driveTypes.add('Fixed Site');
        
        saveBulkStaffingBudget.staffingBudgets.add(staffingBudgetInput);
        skedRemoteResultModel saveBulkStaffingBudgetResult = skedRacController.saveBulkStaffingBudget(saveBulkStaffingBudget);
        
        skedRacController.getStaffingBudgetModel getStaffingBudgetDataRequest = new skedRacController.getStaffingBudgetModel();
        getStaffingBudgetDataRequest.viewData = new Map<string, object>();
        getStaffingBudgetDataRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getStaffingBudgetDataRequest.biomedCollectionOpIds = new List<string>{testCollectionOperation1.Id};
        getStaffingBudgetDataRequest.pageNo = 1;
        getStaffingBudgetDataRequest.pageSize = 10;
        skedRemoteResultModel getStaffingBudgetDataResult = skedRacController.getStaffingBudgetData(getStaffingBudgetDataRequest);
        
        sked_Staffing_Budget__c staffingBudget = [SELECT Id, sked_Recurring_Schedule__c FROM sked_Staffing_Budget__c WHERE sked_Recurring_Schedule__c != NULL LIMIT 1];
        
        skedBaseController.getDataRequestModel getRecurringScheduleRequest = new skedBaseController.getDataRequestModel();
        getRecurringScheduleRequest.viewData = new Map<string, object>();
        getRecurringScheduleRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getRecurringScheduleRequest.recordId = staffingBudget.sked_Recurring_Schedule__c;
        skedRacController.getRecurringSchedule(getRecurringScheduleRequest);
        
        skedBaseController.getDataRequestModel getStaffingBudgetDetailsRequest = new skedBaseController.getDataRequestModel();
        getStaffingBudgetDetailsRequest.viewData = new Map<string, object>();
        getStaffingBudgetDetailsRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getStaffingBudgetDetailsRequest.recordId = staffingBudget.Id;
        skedRemoteResultModel getStaffingBudgetDetailsResult = skedRacController.getStaffingBudgetDetails(getStaffingBudgetDetailsRequest);
        
        skedRacController.saveBulkStaffingBudgetRequestModel deleteStaffingBudgetsRequest = new skedRacController.saveBulkStaffingBudgetRequestModel();
        deleteStaffingBudgetsRequest.viewData = new Map<string, object>();
        deleteStaffingBudgetsRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        deleteStaffingBudgetsRequest.staffingBudgets = new List<skedModels.staffingBudget>();
        skedModels.staffingBudget staffingBudgetToDelete = new skedModels.staffingBudget();
        staffingBudgetToDelete.id = staffingBudget.Id;
        deleteStaffingBudgetsRequest.staffingBudgets.add(staffingBudgetToDelete);
        skedRemoteResultModel deleteStaffingBudgetsResult = skedRacController.deleteStaffingBudgets(deleteStaffingBudgetsRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testCustomAvailability() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        Test.startTest();
        
        skedRacController.saveCustomAvailabilityRequestModel saveCustomAvailabilityRequest = new skedRacController.saveCustomAvailabilityRequestModel();
        saveCustomAvailabilityRequest.viewData = new Map<string, object>();
        saveCustomAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveCustomAvailabilityRequest.event = new skedModels.customAvailability();
        saveCustomAvailabilityRequest.event.isAvailable = TRUE;
        saveCustomAvailabilityRequest.event.notes = 'test';
        saveCustomAvailabilityRequest.event.resourceId = testResource1.Id;
        saveCustomAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveCustomAvailabilityRequest.event.endTime = 1700;
        saveCustomAvailabilityRequest.event.eventType = 'Volunteer';
        saveCustomAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveCustomAvailabilityRequest.event.startTime = 900;
        saveCustomAvailabilityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        
        skedRemoteResultModel saveCustomAvailabilityResult = skedRacController.saveCustomAvailability(saveCustomAvailabilityRequest);
        
        skedRacController.getCustomAvailabilityDetailsRequest getCustomAvailabilityDetailsRequest = new skedRacController.getCustomAvailabilityDetailsRequest();
        getCustomAvailabilityDetailsRequest.viewData = new Map<string, object>();
        getCustomAvailabilityDetailsRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getCustomAvailabilityDetailsRequest.event = new skedModels.customAvailability();
        sked_Custom_Availability__c customAvailability = [SELECT Id FROM sked_Custom_Availability__c LIMIT 1];
        getCustomAvailabilityDetailsRequest.event.Id = customAvailability.Id;
        skedRemoteResultModel getCustomAvailabilityDetailsResult = skedRacController.getCustomAvailabilityDetails(getCustomAvailabilityDetailsRequest);
        
        skedRacController.saveCustomAvailabilityRequestModel cancelCustomAvailabilityRequest = new skedRacController.saveCustomAvailabilityRequestModel();
        cancelCustomAvailabilityRequest.viewData = new Map<string, object>();
        cancelCustomAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        cancelCustomAvailabilityRequest.event = getCustomAvailabilityDetailsRequest.event;
        skedRemoteResultModel cancelCustomAvailabilityResult = skedRacController.cancelCustomAvailability(cancelCustomAvailabilityRequest);

        skedRacController.saveCustomAvailabilityRequestModel deleteCustomAvailabilityRequest = new skedRacController.saveCustomAvailabilityRequestModel();
        deleteCustomAvailabilityRequest.viewData = new Map<string, object>();
        deleteCustomAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        deleteCustomAvailabilityRequest.event = getCustomAvailabilityDetailsRequest.event;
        skedRemoteResultModel deleteCustomAvailabilityResult = skedRacController.deleteCustomAvailability(deleteCustomAvailabilityRequest);
        
        Test.stopTest();
    }
    
    static testmethod void testGetStaffingBudgetsAvailabilities() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c) mapTestData.get('testResource1');
        sked_Staffing_Budget__c testStaffingBudget = (sked_Staffing_Budget__c) mapTestData.get('testStaffingBudget1');
        Biomed_Collection_Op_Center__c testCollectionOperation = (Biomed_Collection_Op_Center__c) mapTestData.get('testCollectionOperation1');
        
        Test.startTest();
        
        testStaffingBudget.sked_Biomed_Collection_Op_Center__c = testCollectionOperation.Id;
        update testStaffingBudget;
        
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = TRUE;
        
        sked__Availability__c resourcePTO = new sked__Availability__c(
            sked__Resource__c = testResource1.Id,
            sked__Type__c = 'PTO',
            sked__Start__c = testStaffingBudget.sked_Staffing_Budget_Date__c.addDays(1),
            sked__Finish__c = testStaffingBudget.sked_Staffing_Budget_Date__c.addDays(1),
            sked__Is_Available__c = FALSE,
            sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
        insert resourcePTO;
        
        List<sked_Staffing_Budget_Availability__c> sbas = [SELECT Id FROM sked_Staffing_Budget_Availability__c];
        
        List<String> availabilityStatuses = new List<String>();
        availabilityStatuses.add(skedConstants.AVAILABILITY_STATUS_APPROVED);
        
        skedRacController.getStaffingBudgetsAvailabilitiesRequestModel model = new skedRacController.getStaffingBudgetsAvailabilitiesRequestModel();
        model.viewData = new Map<string, object>();
        model.availabilityStatuses = availabilityStatuses;
        
        skedRacController.getStaffingBudgetsAvailabilities(model);
        
        Test.stopTest();
    }

    static testmethod void testValidateResourceOverride(){
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
    }

    static testmethod void testGetAvailatorData() {
        List<String> dates = new List<String>();
        Date startDate = System.today();
        Date endDate = System.today().addDays(10);

        while (startDate < endDate) {
            dates.add('' + startDate.year() + '-' + startDate.month() + '-' + startDate.day());
            startDate = startDate.addDays(1);
        }
        dates.add('' + endDate.year() + '-' + endDate.month() + '-' + endDate.day());

        List<Id> accountIds = new List<Id>(); 
        List<Account> testAccounts = [SELECT Id FROM Account];
        for (Account account : testAccounts) { accountIds.add(account.Id); }

        List<Id> collectionOpIds = new List<Id>(); 
        List<Biomed_Collection_Op_Center__c> testCollectionOps = [SELECT Id FROM Biomed_Collection_Op_Center__c];
        for (Biomed_Collection_Op_Center__c collectionOp : testCollectionOps) { collectionOpIds.add(collectionOp.Id); }

        List<Id> jobIds = new List<Id>(); 
        List<sked__Job__c> testJobs = [SELECT Id FROM sked__Job__c];
        for (sked__Job__c job : testJobs) { jobIds.add(job.Id); }

        List<Id> locationIds = new List<Id>(); 
        List<sked__Location__c> testLocations = [SELECT Id FROM sked__Location__c];
        for (sked__Location__c location : testLocations) { locationIds.add(location.Id); }

        skedRacController.getAvailatorDataRequestModel model = new skedRacController.getAvailatorDataRequestModel();
        model.viewData = new Map<string, object>();
        model.accountIds = accountIds;
        model.collectionOperationIds = collectionOpIds;
        model.excludedActivityIds = new List<string>();
        model.excludedDriveIds = new List<string>();
        model.locationIds = locationIds;
        model.inputDates = dates;
        model.jobIds = jobIds;
        model.pageSize = 50;
        model.pageNo = 1;
        model.timezoneSidId = UserInfo.getTimeZone().getID();
        model.getAssetsOnly = false;

        Test.startTest();
        
        skedRacController.getAvailatorData(model);
        
        Test.stopTest();
    }
    
    static testmethod void testGetFixedSitesRelatedToCo() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        
        Test.startTest();
        
        skedRacController.getSitesRequestModel getSitesRequest = new skedRacController.getSitesRequestModel();
        getSitesRequest.viewData = new Map<string, object>();
        getSitesRequest.biomedCollectionOpIds = new List<String>{(String)testCollectionOperation1.Id};
        getSitesRequest.staffingBudgetDate = testDataFactory.summary.startDateIso;
        
        skedRemoteResultModel getSitesResult = skedRacController.getFixedSitesRelatedToCo(getSitesRequest);
        
        Assert.isTrue(getSitesResult.data != NULL);
        
        Test.stopTest();
    }
    
    static testmethod void testValidateBulkStaffingBudgetsAgainstSiteCos() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        Biomed_Collection_Op_Center__c testCollectionOperation2 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation2');
        
        Test.startTest();
        
        skedRacController.validateBulkStaffingBudget validateBulkStaffingBudgetRequest;
        validateBulkStaffingBudgetRequest = new skedRacController.validateBulkStaffingBudget();
        validateBulkStaffingBudgetRequest.viewData = new Map<string, object>();
        validateBulkStaffingBudgetRequest.siteIds = new List<String>{(String)testLocation1.Id};
        validateBulkStaffingBudgetRequest.staffingBudgetDates = new List<String>{testDataFactory.summary.startDateIso};
        validateBulkStaffingBudgetRequest.biomedCollectionOpIds = new List<String>{(String)testCollectionOperation2.Id};
        
        skedRemoteResultModel getValidateResult = skedRacController.validateBulkStaffingBudgetsAgainstSiteCos(validateBulkStaffingBudgetRequest);
        
        sked_Site_Collection_Operation__c testSiteColOp = [SELECT Id, 
                                                           sked_Site__r.Name, sked_Collection_Operation__r.Name,
                                                           sked_Start_Date__c, sked_End_Date__c 
                                                           FROM sked_Site_Collection_Operation__c 
                                                           LIMIT 1];
        
        Assert.isTrue(getValidateResult.success == FALSE);
        Assert.isTrue(getValidateResult.errorMessage.contains(testSiteColOp.sked_Site__r.Name+' is currently associated with '+testSiteColOp.sked_Collection_Operation__r.Name));
        
        // Update Site CO to cover 'No Site CO' scenario
        testSiteColOp.sked_End_Date__c = testDataFactory.summary.endDate.addDays(-1);
        update testSiteColOp;
        
        validateBulkStaffingBudgetRequest = new skedRacController.validateBulkStaffingBudget();
        validateBulkStaffingBudgetRequest.viewData = new Map<string, object>();
        validateBulkStaffingBudgetRequest.siteIds = new List<String>{(String)testLocation1.Id};
        validateBulkStaffingBudgetRequest.staffingBudgetDates = new List<String>{testDataFactory.summary.endDateIso};
        validateBulkStaffingBudgetRequest.biomedCollectionOpIds = new List<String>{(String)testCollectionOperation1.Id};
        
        skedRemoteResultModel getValidateResult_noSiteCo = skedRacController.validateBulkStaffingBudgetsAgainstSiteCos(validateBulkStaffingBudgetRequest);
        
        Assert.isTrue(getValidateResult_noSiteCo.success == FALSE);
        Assert.isTrue(getValidateResult_noSiteCo.errorMessage.contains(testSiteColOp.sked_Site__r.Name+' is no longer associated with any collection operation'));
        
        Test.stopTest();
    }
	static testmethod void testGetResourceData2() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Region__c testRegion2 = (sked__Region__c)mapTestData.get('testRegion2');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testAsset1 = (sked__Resource__c)mapTestData.get('testAsset1');
        sked__Tag__c testTag1 = (sked__Tag__c)mapTestData.get('testTag1');
        
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        List<string> availabilityTypes = skedUtils.getPickListValues('sked__Availability__c', 'sked__Type__c');

        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        sked__Availability_Pattern__c testWeeklyPattern2 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern2');

        sked__Availability_Pattern_Resource__c testPatternResource1 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime
        );
        insert testPatternResource1;
        
        sked__Availability_Pattern_Resource__c testPatternResource2 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern2.Id,
            sked__Resource__c = testResource1.Id, 
            sked__Start__c = testDataFactory.summary.startTime.addDays(7)
        );
        insert testPatternResource2;
    
        
        Test.startTest();
        
        Test.setCurrentPage(new PageReference('skedRAC'));
        
        //intialize
        skedRemoteRequestModel initializeRequest = new skedRemoteRequestModel();
        initializeRequest.configKeys = new List<string>();
        initializeRequest.configKeys.add('activityTypes');
        initializeRequest.configKeys.add('availabilityTypes');
        initializeRequest.configKeys.add('holidays');
        initializeRequest.configKeys.add('jobTypes');
        initializeRequest.configKeys.add('regions');
        initializeRequest.configKeys.add('serviceLocations');
        initializeRequest.configKeys.add('timezones');
        initializeRequest.configKeys.add('resourceEmploymentTypes');
        initializeRequest.configKeys.add('resourceCategories');
        skedRemoteResultModel initializeResult = skedRacController.initialize(initializeRequest);
        
        //getResources
        skedRacController.getResourceRequestModel getResourcesRequest = new skedRacController.getResourceRequestModel();
        getResourcesRequest.viewData = new Map<string, object>();
        getResourcesRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourcesRequest.endDate = testDataFactory.summary.endDateIso;
        getResourcesRequest.pageNo = 1;
        getResourcesRequest.pageSize = 25;
        getResourcesRequest.biomedCollectionOpIds = new List<string>();
        getResourcesRequest.biomedCollectionOpIds.add(testCollectionOperation1.Id);
        getResourcesRequest.regionIds = new List<string>();
        getResourcesRequest.regionIds.add(testRegion1.Id);
        getResourcesRequest.startDate = testDataFactory.summary.startDateIso;
        getResourcesRequest.tagIds = new List<string>();
        getResourcesRequest.tagIds.add(testTag1.Id);
        getResourcesRequest.activityTypes = activityTypes;
        getResourcesRequest.availabilityTypes = availabilityTypes;
        getResourcesRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        getResourcesRequest.hasTemporaryRelocation = true;
        getResourcesRequest.additionalFilterOnDate = testDataFactory.summary.startDateIso;
        getResourcesRequest.hasNoAssignment = true;
        getResourcesRequest.patternIds = new List<string>();
        getResourcesRequest.patternIds.add(testWeeklyPattern1.Id);
        skedRemoteResultModel getResourcesResult = skedRacController.getResourceData(getResourcesRequest);
        skedRacController.resourceDataModel resourcesDataResult = (skedRacController.resourceDataModel)getResourcesResult.data;
        List<sked__Resource__c> skedResources = (List<sked__Resource__c>)resourcesDataResult.resources;
        
        //getResources for second region
        getResourcesRequest.regionIds = new List<string>();
        getResourcesRequest.regionIds.add(testRegion2.Id);
        getResourcesResult = skedRacController.getResourceData(getResourcesRequest);
        resourcesDataResult = (skedRacController.resourceDataModel)getResourcesResult.data;
        skedResources = (List<sked__Resource__c>)resourcesDataResult.resources;
        
        //getIndividualResource
        skedRacController.getResourceRequestModel getResourceRequest = new skedRacController.getResourceRequestModel();
        getResourceRequest.viewData = new Map<string, object>();
        getResourceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getResourceRequest.endDate = testDataFactory.summary.endDateIso;
        getResourceRequest.resourceId = testResource1.Id;
        getResourceRequest.startDate = testDataFactory.summary.startDateIso;
        getResourceRequest.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel getResourceResult = skedRacController.getIndividualResourceData(getResourceRequest);
        skedRacController.resourceDataModel resourceDataResult = (skedRacController.resourceDataModel)getResourceResult.data;
        
        List<skedModels.resource> resources = (List<skedModels.resource>)resourceDataResult.resources;
        
        Test.stopTest();
    }

    static testmethod void testGetGroupActivities() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        
        sked__Activity__c testActivity1 = (sked__Activity__c)mapTestData.get('testGroupActivity1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Territory__c testTerritory1 = (sked_Territory__c)mapTestData.get('testTerritory1');
        
        sked_Activity_Collection_Operation__c testActivityCO = new sked_Activity_Collection_Operation__c(
        	sked_Activity__c = testActivity1.Id,
        	sked_Biomed_Collection_Operation__c = testCollectionOperation1.Id,
            sked_District__c = testTerritory1.Id
        );
        insert testActivityCO;
        
        Test.startTest();
        
        skedRacController.getGroupActivitiesRequestModel getGroupActivitiesRequest = new skedRacController.getGroupActivitiesRequestModel();
        getGroupActivitiesRequest.viewData = new Map<string, object>();
        getGroupActivitiesRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getGroupActivitiesRequest.pageNo = 1;
        getGroupActivitiesRequest.pageSize = 25;
        getGroupActivitiesRequest.activityTypes = new List<string>();
        getGroupActivitiesRequest.activityTypes.add('Administration');
        getGroupActivitiesRequest.endDate = testDataFactory.summary.endDateIso;
        getGroupActivitiesRequest.startDate = testDataFactory.summary.startDateIso;
        getGroupActivitiesRequest.territoryKeys = new List<String>{testTerritory1.Id + ':' + testCollectionOperation1.Id};

        skedRemoteResultModel getGroupActivitiesResult = skedRacController.getGroupActivities(getGroupActivitiesRequest);

        Assert.isTrue(getGroupActivitiesResult.success == TRUE);
        
        Test.stopTest();
    }

    static testmethod void testGetCollectionOperationTimeBlocks() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupRacTestData();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        Time_Block__c testTimeBlock1 = (Time_Block__c)mapTestData.get('testTimeBlock1');
        Test.startTest();
        
        skedRacController.getCollectionOperationTimeBlocksRequestModel getCollectionOperationTimeBlocksRequest = new skedRacController.getCollectionOperationTimeBlocksRequestModel();
        getCollectionOperationTimeBlocksRequest.viewData = new Map<string, object>();
        getCollectionOperationTimeBlocksRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getCollectionOperationTimeBlocksRequest.pageNo = 1;
        getCollectionOperationTimeBlocksRequest.pageSize = 25;
        getCollectionOperationTimeBlocksRequest.collectionOperationIds = new List<string>();
        getCollectionOperationTimeBlocksRequest.collectionOperationIds.add(testCollectionOperation1.Id);
        getCollectionOperationTimeBlocksRequest.endDate = testDataFactory.summary.endDateIso;
        getCollectionOperationTimeBlocksRequest.startDate = testDataFactory.summary.startDateIso;

        skedRemoteResultModel getCollectionOperationTimeBlocksResult = skedRacController.getCollectionOperationTimeBlocks(getCollectionOperationTimeBlocksRequest);

        Assert.isTrue(getCollectionOperationTimeBlocksResult.success == TRUE);
        
        skedModels.collectionOperationTimeBlock cotb = ((List<skedModels.collectionOperationTimeBlock>)getCollectionOperationTimeBlocksResult.data).get(0);
        Assert.isTrue(cotb.timeBlockId == testTimeBlock1.Id);
        
        Test.stopTest();
    }
    
    static testmethod void testValidatePattern() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Availability_Pattern__c testWeeklyPattern1 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern1');
        sked__Availability_Pattern__c testWeeklyPattern2 = (sked__Availability_Pattern__c)mapTestData.get('testWeeklyPattern2');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        sked__Availability_Pattern_Resource__c apResource1 = new sked__Availability_Pattern_Resource__c(
            sked__Availability_Pattern__c = testWeeklyPattern1.Id,
            sked__Resource__c = testResource1.Id,
            sked__Start__c = testDataFactory.summary.startTime
        );
        insert apResource1;
        
        Test.startTest();
        
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        skedModels.availabilityPattern availabilityPattern = new skedModels.availabilityPattern();
        availabilityPattern.id = testWeeklyPattern2.Id;
        availabilityPattern.pattern = testWeeklyPattern2.sked__Pattern__c;
        availabilityPattern.hash = testWeeklyPattern2.sked__Hash__c;
        availabilityPattern.validate2CDORule = FALSE;
        availabilityPattern.availabilityPatternResources = new List<skedModels.availabilityPatternResource>();
        skedModels.availabilityPatternResource patternResource = new skedModels.availabilityPatternResource();
        patternResource.resourceId = testResource1.Id;
        patternResource.startDate = testDataFactory.summary.startDateIso;
        availabilityPattern.availabilityPatternResources.add(patternResource);
        
        skedRacController.savePatternRequestModel savePatternRequest = new skedRacController.savePatternRequestModel();
        savePatternRequest.viewData = new Map<string, object>();
        savePatternRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        savePatternRequest.availabilityPattern = availabilityPattern;

        skedRemoteResultModel validatePatternResult = skedRacController.validatePattern(savePatternRequest);
        Assert.isTrue(validatePatternResult.success == TRUE);
        
        skedModels.availabilityPatternResource returnedPatternResource = ((skedModels.availabilityPattern)validatePatternResult.data).availabilityPatternResources.get(0);
        Assert.isTrue(returnedPatternResource.isOverlapping == TRUE);
        
        skedModels.overlappingPatternResource overlappingPatternResource = returnedPatternResource.overlappingPatternResources.get(0);
        Assert.isTrue(overlappingPatternResource.patternName == 'Test Weekly Pattern 1');
        
        Test.stopTest();
    }
    
    static testMethod void testGetPlaceDetails() {
        Test.startTest();
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        skedRacController.getPlaceDetailsModel getPlaceDetailsRequest = new skedRacController.getPlaceDetailsModel();
        getPlaceDetailsRequest.viewData = new Map<string, object>();
        getPlaceDetailsRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getPlaceDetailsRequest.placeId = 'TEST';
        
        skedRemoteResultModel getPlaceDetailsResult = skedRacController.getPlaceDetails(getPlaceDetailsRequest);
        Test.stopTest();
    }
    
    static testMethod void testGetAddressPredictions() {
        Test.startTest();
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        
        skedRacController.getgetAddressPredictionsModel getAddressPredictionRequest = new skedRacController.getgetAddressPredictionsModel();
        getAddressPredictionRequest.viewData = new Map<string, object>();
        getAddressPredictionRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getAddressPredictionRequest.queryText = 'TEST';
        
        skedRemoteResultModel getAddressPredictionResult = skedRacController.getAddressPredictions(getAddressPredictionRequest);
        Test.stopTest();
    }
    
    @isTest
    static void testGetEventDetails() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        
        // Set sked__Resource__c.sked_Daily_Time_Off_Hours__c
        testResource1.sked_Daily_Time_Off_Hours__c = 8.00;
        update testResource1;

        //create unavailability #1
        skedRacController.saveAvailabilityRequestModel saveUnAvailabilityRequest1 = new skedRacController.saveAvailabilityRequestModel();
        saveUnAvailabilityRequest1.viewData = new Map<string, object>();
        saveUnAvailabilityRequest1.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveUnAvailabilityRequest1.event = new skedModels.availability();
        saveUnAvailabilityRequest1.event.endDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest1.event.endTime = 1300;
        saveUnAvailabilityRequest1.event.eventType = 'PTO';
        saveUnAvailabilityRequest1.event.notes = 'notes saveUnAvailabilityRequest1';
        saveUnAvailabilityRequest1.event.startDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest1.event.startTime = 900;
        saveUnAvailabilityRequest1.event.resourceId = testResource1.Id;
        saveUnAvailabilityRequest1.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveUnAvailabilityRequest1.event.isAvailable = false;
        skedRemoteResultModel saveAvailabilityResult1 = skedRacController.saveAvailability(saveUnAvailabilityRequest1);

        sked__Availability__c availabilityChecking1 = [
            SELECT Id, sked__Start__c, sked__Finish__c, sked__Notes__c, sked__Type__c, sked__Resource__c
            FROM sked__Availability__c
            LIMIT 1
        ];
        
        Test.startTest();

        //get event details #1
        skedRacController.getAvailabilityDetailsRequest getAvailabilityDetailsRequest1 = new skedRacController.getAvailabilityDetailsRequest();
        getAvailabilityDetailsRequest1.viewData = new Map<string, object>();
        getAvailabilityDetailsRequest1.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getAvailabilityDetailsRequest1.event = new skedModels.availability();
        getAvailabilityDetailsRequest1.event.id = availabilityChecking1.Id;
        getAvailabilityDetailsRequest1.event.startDate = testDataFactory.summary.startDateIso;
        getAvailabilityDetailsRequest1.event.endDate = testDataFactory.summary.endDateIso;
        skedRemoteResultModel getEventDetailsResult1 = skedRacController.getEventDetails(getAvailabilityDetailsRequest1);

        // System.debug('assertEquals getEventDetailsResult1.success (true):' + getEventDetailsResult1.success);
        System.assertEquals(true, getEventDetailsResult1.success);

        //create unavailability #2
        skedRacController.saveAvailabilityRequestModel saveUnAvailabilityRequest2 = new skedRacController.saveAvailabilityRequestModel();
        saveUnAvailabilityRequest2.viewData = new Map<string, object>();
        saveUnAvailabilityRequest2.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveUnAvailabilityRequest2.event = new skedModels.availability();
        saveUnAvailabilityRequest2.event.endDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest2.event.endTime = 1700;
        saveUnAvailabilityRequest2.event.eventType = 'Floating Holiday';
        saveUnAvailabilityRequest2.event.notes = 'notes saveUnAvailabilityRequest2';
        saveUnAvailabilityRequest2.event.startDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest2.event.startTime = 1300;
        saveUnAvailabilityRequest2.event.resourceId = testResource1.Id;
        saveUnAvailabilityRequest2.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveUnAvailabilityRequest2.event.isAvailable = false;
        skedRemoteResultModel saveAvailabilityResult2 = skedRacController.saveAvailability(saveUnAvailabilityRequest2);

        sked__Availability__c availabilityChecking2 = [
            SELECT Id, sked__Start__c, sked__Finish__c, sked__Notes__c, sked__Type__c, sked__Resource__c
            FROM sked__Availability__c
            LIMIT 1
        ];

        //get event details #2
        skedRacController.getAvailabilityDetailsRequest getAvailabilityDetailsRequest2 = new skedRacController.getAvailabilityDetailsRequest();
        getAvailabilityDetailsRequest2.viewData = new Map<string, object>();
        getAvailabilityDetailsRequest2.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        getAvailabilityDetailsRequest2.event = new skedModels.availability();
        getAvailabilityDetailsRequest2.event.id = availabilityChecking2.Id;
        getAvailabilityDetailsRequest2.event.startDate = testDataFactory.summary.startDateIso;
        getAvailabilityDetailsRequest2.event.endDate = testDataFactory.summary.endDateIso;
        skedRemoteResultModel getEventDetailsResult2 = skedRacController.getEventDetails(getAvailabilityDetailsRequest2);

        // System.debug('assertEquals getEventDetailsResult2.success (true):' + getEventDetailsResult2.success);
        System.assertEquals(true, getEventDetailsResult2.success);

        Test.stopTest();

    }

    @isTest
    static void testVerifyTimeConflict() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');

        //create unavailability #1
        skedRacController.saveAvailabilityRequestModel saveUnAvailabilityRequest1 = new skedRacController.saveAvailabilityRequestModel();
        saveUnAvailabilityRequest1.viewData = new Map<string, object>();
        saveUnAvailabilityRequest1.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveUnAvailabilityRequest1.event = new skedModels.availability();
        saveUnAvailabilityRequest1.event.endDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest1.event.endTime = 1300;
        saveUnAvailabilityRequest1.event.eventType = 'Floating Holiday';
        saveUnAvailabilityRequest1.event.notes = 'notes saveUnAvailabilityRequest1';
        saveUnAvailabilityRequest1.event.startDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest1.event.startTime = 900;
        saveUnAvailabilityRequest1.event.resourceId = testResource1.Id;
        saveUnAvailabilityRequest1.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveUnAvailabilityRequest1.event.isAvailable = false;
        skedRemoteResultModel saveAvailabilityResult1 = skedRacController.saveAvailability(saveUnAvailabilityRequest1);

        sked__Availability__c existingAvailability = [
            SELECT Id, sked__Start__c, sked__Finish__c, sked__Resource__c
            FROM sked__Availability__c
            LIMIT 1
        ];

        //create unavailability #2
        skedRacController.saveAvailabilityRequestModel saveUnAvailabilityRequest2 = new skedRacController.saveAvailabilityRequestModel();
        saveUnAvailabilityRequest2.viewData = new Map<string, object>();
        saveUnAvailabilityRequest2.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveUnAvailabilityRequest2.event = new skedModels.availability();
        saveUnAvailabilityRequest2.event.endDate = Json.serialize(testDataFactory.summary.startDate.addDays(1)).replace('"', '');
        saveUnAvailabilityRequest2.event.eventType = 'Floating Holiday';
        saveUnAvailabilityRequest2.event.notes = 'notes saveUnAvailabilityRequest2';
        saveUnAvailabilityRequest2.event.startDate = Json.serialize(testDataFactory.summary.startDate.addDays(1)).replace('"', '');
        saveUnAvailabilityRequest2.event.resourceId = testResource1.Id;
        saveUnAvailabilityRequest2.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveUnAvailabilityRequest2.event.isAvailable = false;
        saveUnAvailabilityRequest2.event.isAllDay = true;
        skedRemoteResultModel saveAvailabilityResult2 = skedRacController.saveAvailability(saveUnAvailabilityRequest2);

        //create unavailability #3
        skedRacController.saveAvailabilityRequestModel saveUnAvailabilityRequest3 = new skedRacController.saveAvailabilityRequestModel();
        saveUnAvailabilityRequest3.viewData = new Map<string, object>();
        saveUnAvailabilityRequest3.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveUnAvailabilityRequest3.event = new skedModels.availability();
        saveUnAvailabilityRequest3.event.endDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest3.event.endTime = 1430;
        saveUnAvailabilityRequest3.event.eventType = 'Floating Holiday';
        saveUnAvailabilityRequest3.event.notes = 'notes saveUnAvailabilityRequest3';
        saveUnAvailabilityRequest3.event.startDate = testDataFactory.summary.startDateIso;
        saveUnAvailabilityRequest3.event.startTime = 1330;
        saveUnAvailabilityRequest3.event.resourceId = testResource1.Id;
        saveUnAvailabilityRequest3.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        saveUnAvailabilityRequest3.event.isAvailable = false;
        skedRemoteResultModel saveAvailabilityResult3 = skedRacController.saveAvailability(saveUnAvailabilityRequest3);

        Test.startTest();
                
        //create new unavailability
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest.viewData = new Map<string, object>();
        saveAvailabilityRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest.event = new skedModels.availability();
        saveAvailabilityRequest.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.endTime = 1700;
        saveAvailabilityRequest.event.eventType = 'PTO';
        saveAvailabilityRequest.event.notes = 'notes saveAvailabilityRequest';
        saveAvailabilityRequest.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest.event.startTime = 900;
        saveAvailabilityRequest.event.resourceId = testResource1.Id;
        saveAvailabilityRequest.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel prepareUnavailabilityResult = skedRacController.prepareUnavailabilityRequest(saveAvailabilityRequest);

        // System.debug('assertEquals prepareUnavailabilityResult.success (true):' + prepareUnavailabilityResult.success);
        System.assertEquals(true, prepareUnavailabilityResult.success);

        //create new unavailability
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest1 = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest1.viewData = new Map<string, object>();
        saveAvailabilityRequest1.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest1.event = new skedModels.availability();
        saveAvailabilityRequest1.event.endDate = Json.serialize(testDataFactory.summary.startDate.addDays(4)).replace('"', '');
        saveAvailabilityRequest1.event.endTime = 1700;
        saveAvailabilityRequest1.event.eventType = 'PTO';
        saveAvailabilityRequest1.event.notes = 'notes saveAvailabilityRequest1';
        saveAvailabilityRequest1.event.startDate = Json.serialize(testDataFactory.summary.startDate.addDays(4)).replace('"', '');
        saveAvailabilityRequest1.event.startTime = 900;
        saveAvailabilityRequest1.event.resourceId = testResource1.Id;
        saveAvailabilityRequest1.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel prepareUnavailabilityResult1 = skedRacController.prepareUnavailabilityRequest(saveAvailabilityRequest1);

        // System.debug('assertEquals prepareUnavailabilityResult1.success (true):' + prepareUnavailabilityResult1.success);
        System.assertEquals(true, prepareUnavailabilityResult1.success);

        //create new unavailability
        skedRacController.saveAvailabilityRequestModel saveAvailabilityRequest2 = new skedRacController.saveAvailabilityRequestModel();
        saveAvailabilityRequest2.viewData = new Map<string, object>();
        saveAvailabilityRequest2.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        saveAvailabilityRequest2.event = new skedModels.availability();
        saveAvailabilityRequest2.event.endDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest2.event.endTime = 1700;
        saveAvailabilityRequest2.event.eventType = 'Floating Holiday';
        saveAvailabilityRequest2.event.notes = 'notes saveAvailabilityRequest2';
        saveAvailabilityRequest2.event.startDate = testDataFactory.summary.startDateIso;
        saveAvailabilityRequest2.event.startTime = 900;
        saveAvailabilityRequest2.event.resourceId = testResource1.Id;
        saveAvailabilityRequest2.event.timezoneSidId = testDataFactory.summary.timezoneSidId;
        skedRemoteResultModel prepareUnavailabilityResult2 = skedRacController.prepareUnavailabilityRequest(saveAvailabilityRequest2);

        // System.debug('assertEquals prepareUnavailabilityResult2.success (true):' + prepareUnavailabilityResult2.success);
        System.assertEquals(true, prepareUnavailabilityResult2.success);

        skedModels.availability event1 = new skedModels.availability();
        event1.endDate = testDataFactory.summary.startDateIso;
        event1.endTime = 1700;
        event1.eventType = 'PTO';
        event1.notes = 'notes event1';
        event1.startDate = testDataFactory.summary.startDateIso;
        event1.startTime = 900;
        event1.resourceId = testResource1.Id;
        event1.timezoneSidId = testDataFactory.summary.timezoneSidId;
        event1.isAllDay = false;

        skedModels.availability event2 = new skedModels.availability();
        event2.endDate = Json.serialize(testDataFactory.summary.startDate.addDays(1)).replace('"', '');
        event2.endTime = 2359;
        event2.eventType = 'PTO';
        event2.notes = 'notes event2';
        event2.startDate = Json.serialize(testDataFactory.summary.startDate.addDays(1)).replace('"', '');
        event2.startTime = 0000;
        event2.resourceId = testResource1.Id;
        event2.timezoneSidId = testDataFactory.summary.timezoneSidId;
        event2.isAllDay = true;

        skedModels.availability event3 = new skedModels.availability();
        event3.endDate = Json.serialize(testDataFactory.summary.startDate.addDays(-1)).replace('"', '');
        event3.endTime = 2359;
        event3.eventType = 'PTO';
        event3.notes = 'notes event3';
        event3.startDate = Json.serialize(testDataFactory.summary.startDate.addDays(-1)).replace('"', '');
        event3.startTime = 0000;
        event3.resourceId = testResource1.Id;
        event3.timezoneSidId = testDataFactory.summary.timezoneSidId;
        event3.isAllDay = true;

        skedModels.availability event4 = new skedModels.availability();
        event4.endDate = testDataFactory.summary.startDateIso;
        event4.endTime = 1700;
        event4.eventType = 'Floating Holiday';
        event4.notes = 'notes event4';
        event4.startDate = testDataFactory.summary.startDateIso;
        event4.startTime = 900;
        event4.resourceId = testResource1.Id;
        event4.timezoneSidId = testDataFactory.summary.timezoneSidId;
        event4.isAllDay = false;
        event4.id = existingAvailability.id;

        skedRacController.verifyUnavailabilityBalanceRequestModel verifyUnavailabilityBalanceRequest = new skedRacController.verifyUnavailabilityBalanceRequestModel();
        verifyUnavailabilityBalanceRequest.viewData = new Map<string, object>();
        verifyUnavailabilityBalanceRequest.viewData.put('timezoneSidId', testDataFactory.summary.timezoneSidId);
        verifyUnavailabilityBalanceRequest.unavailability = new List<skedModels.availability>();
        verifyUnavailabilityBalanceRequest.unavailability.add(event1);
        verifyUnavailabilityBalanceRequest.unavailability.add(event2);
        verifyUnavailabilityBalanceRequest.unavailability.add(event3);
        verifyUnavailabilityBalanceRequest.unavailability.add(event4);
        skedRemoteResultModel verifyUnavailabilityBalanceResult = skedRacController.verifyUnavailabilityBalance(verifyUnavailabilityBalanceRequest);

        // System.debug('assertEquals verifyUnavailabilityBalanceResult.success (false):' + verifyUnavailabilityBalanceResult.success);
        System.assertEquals(false, verifyUnavailabilityBalanceResult.success);

        Test.stopTest();

    }

    @isTest
    static void skedAvailabilityService_convertToTime_throws_onInvalidHourOrMinute() {
        // Arrange
        Integer[] badValues = new Integer[] { 2400, 2360 };

        for (Integer bad : badValues) {
            Boolean threw = false;
            try {
                // Act
                skedAvailabilityService.convertToTime(bad);
            } catch (IllegalArgumentException ex) {
                // Assert
                threw = true;
                System.assert(ex.getMessage().contains('Invalid time'),
                    'Message should contain a helpful reason. Got: ' + ex.getMessage());
            }
            System.assert(threw, 'Expected IllegalArgumentException for value: ' + bad);
        }
    }

}