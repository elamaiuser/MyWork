@isTest
private class slwcSkedApiService_Test {
    @isTest
    static void getAddressPredictions_Test() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);

        Test.startTest();
            String prediction = slwcSkedApiService.getAddressPredictions('test');
        Test.stopTest();

        System.assert(prediction != null);
    }

    @isTest
    static void getGeocode_Test() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);

        Test.startTest();
            String prediction = slwcSkedApiService.getGeocode('test');
        Test.stopTest();

        System.assert(prediction != null);
    }

    @isTest
    static void getPlaceDetails_Test() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);

        Test.startTest();
            String prediction = slwcSkedApiService.getPlaceDetails('test', 'test');
        Test.stopTest();

        System.assert(prediction != null);
    }

    @isTest
    static void calculateDistanceMatrix_Test() {
        skedMockTest mockTest = new skedMockTest();
        Test.setMock(HttpCalloutMock.class, mockTest);

        Test.startTest();
            slwcAuraResult prediction = slwcSkedApiService.calculateDistanceMatrix(null, null);
        Test.stopTest();

        System.assert(prediction != null);
    }
}