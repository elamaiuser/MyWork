@isTest
private class skedSkeduloApiManager_Test {
    @isTest
    static void upsertAvailabilityPattern_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        skedSkeduloApiData.interval interval = new skedSkeduloApiData.interval();
        interval.startTime = '0800';
        interval.endTime = '1900';

        skedSkeduloApiData.day day = new skedSkeduloApiData.day();
        day.day = 1;
        day.weekday = 'Monday';
        day.intervals = new List<skedSkeduloApiData.interval>{interval};

        skedSkeduloApiData.pattern2 pattern2 = new skedSkeduloApiData.pattern2();
        pattern2.lengthDays = 8;
        pattern2.lengthDays = 3;
        pattern2.days = new List<skedSkeduloApiData.day>{day};

        skedSkeduloApiData.pattern pattern = new skedSkeduloApiData.pattern();
        pattern.UID = 'test-pattern';
        pattern.name = 'pattern';
        pattern.description = 'test pattern';
        pattern.pattern = pattern2;

        skedSkeduloApiData.availabilityPatternPayload payload = new skedSkeduloApiData.availabilityPatternPayload();
        payload.pattern = pattern;
        payload.resources = new List<skedSkeduloApiData.resource>();

        skedSkeduloApiData.resource resource = new skedSkeduloApiData.resource();
        resource.resourceId = testResource.Id;
        resource.UID = 'test-resource-uid';
        resource.start = System.now().addDays(1);
        resource.end_x = System.now().addDays(1).addHours(8);

        payload.resources.add(resource);

        Test.setMock(HttpCalloutMock.class, new skedMockTest());
        Test.startTest();
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            skedSkeduloApiData.upsertAvailabilityPatternResult result = apiManager.upsertAvailabilityPattern(payload);
        Test.stopTest();
    }

    @isTest
    static void getSimplifiedResourceAvailability_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');

        skedSkeduloApiData.simplifiedResourceAvailabilityPayload payload = new skedSkeduloApiData.simplifiedResourceAvailabilityPayload();
        payload.resource_ids = testResource.Id;
        payload.start = '2030-01-01';
        payload.end_x = '2030-12-31';

        Test.setMock(HttpCalloutMock.class, new skedMockTest());
        Test.startTest();
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            skedSkeduloApiData.simplifiedResourceAvailabilityResult result = apiManager.getSimplifiedResourceAvailability(payload);
        Test.stopTest();
    }

    @isTest
    static void triggerOptimizationRun_Test() {
        skedSkeduloApiData.optimizationRunModel model = new skedSkeduloApiData.optimizationRunModel();
        model.uid = 'test-uid';

        Test.setMock(HttpCalloutMock.class, new skedMockTest());
        Test.startTest();
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            skedSkeduloApiData.optimizationRunResult result = apiManager.triggerOptimizationRun(model);
        Test.stopTest();
    }

    @isTest
    static void getTimezonesFromLocation_Test() {
        Location testLocation = Location.newInstance(38.955349, -77.393841);
        Map<string, Location> mapLocation = new Map<String, Location>();
        mapLocation.put('test', testLocation);

        Test.setMock(HttpCalloutMock.class, new skedMockTest());
        Test.startTest();
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            Map<string, skedSkeduloApiData.timezoneResult> result = apiManager.getTimezonesFromLocation(mapLocation);
        Test.stopTest();
    }

    @isTest
    static void findDirections_Test() {

    }

    @isTest
    static void distanceMatrixAsync_Test() {
        Location testLocation = Location.newInstance(38.955349, -77.393841);
        List<string> timeBlocks = new List<String>();
        timeBlocks.add('test-time-block');

        List<Location> origins = new List<Location>();
        origins.add(testLocation);

        List<Location> destinations = new List<Location>();
        destinations.add(testLocation);

        Test.setMock(HttpCalloutMock.class, new skedMockTest());
        Test.startTest();
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            skedSkeduloApiData.distanceMatrixAsyncResult result = apiManager.distanceMatrixAsync(timeBlocks, origins, destinations);
        Test.stopTest();
    }

    @isTest
    static void getTravelTimeSetting_Test() {
        Test.startTest();
            skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
            List<String> result = apiManager.getTravelTimeSetting(UserInfo.getTimeZone().getID());
        Test.stopTest();
    }

    @isTest
    static void codeCoverage() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        
        Test.startTest();
        
        apiManager.notifyDispatch('jobId', 'resourceId');
        apiManager.notifyCancel('jobId');
        apiManager.notifySms('uk', '0123456789', 'This is SMS content.');
        apiManager.notifyOneOff('resourceId', 'push', 'This is one-off content.');
        
        List<string> addresses = new List<String>();
        addresses.add('Address 1');
        addresses.add('Address 2');
        apiManager.getGeocode(addresses);
        
        List<Map<string, decimal>> origins = new List<Map<string, decimal>>();
        Map<string, decimal> origin1 = new Map<string, decimal>();
        origin1.put('lat', 37.7763167);
        origin1.put('lng', -122.4467289);
        origins.add(origin1);
        List<Map<string, decimal>> destinations = new List<Map<string, decimal>>();
        Map<string, decimal> destination1 = new Map<string, decimal>();
        destination1.put('lat', 37.7488728);
        destination1.put('lng', -122.4232724);
        destinations.add(destination1);
        apiManager.calculateDistanceMatrix(origins, destinations);
        
        Test.stopTest();    
    }
    
    @isTest
    static void mainTest_Error() {
        skedMockTest mockTest = new skedMockTest();
        mockTest.isErrorMode = true;
        mockTest.statusCode = 400;
        Test.setMock(HttpCalloutMock.class, mockTest);
        
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        
        Test.startTest();
        
        apiManager.notifyDispatch('jobId', 'resourceId');
        apiManager.notifyCancel('jobId');
        apiManager.notifySms('uk', '0123456789', 'This is SMS content.');
        apiManager.notifyOneOff('resourceId', 'push', 'This is one-off content.');
        
        List<string> addresses = new List<String>();
        addresses.add('Address 1');
        addresses.add('Address 2');
        apiManager.getGeocode(addresses);
        
        List<Map<string, decimal>> origins = new List<Map<string, decimal>>();
        Map<string, decimal> origin1 = new Map<string, decimal>();
        origin1.put('lat', 37.7763167);
        origin1.put('lng', -122.4467289);
        origins.add(origin1);
        List<Map<string, decimal>> destinations = new List<Map<string, decimal>>();
        Map<string, decimal> destination1 = new Map<string, decimal>();
        destination1.put('lat', 37.7488728);
        destination1.put('lng', -122.4232724);
        destinations.add(destination1);
        apiManager.calculateDistanceMatrix(origins, destinations);
        
        try {
            throw new skedCalloutException(404, 'status' , 'response');
        }
        catch (skedCalloutException ex) {
            
        }
        
        Test.stopTest();  
    }   
}