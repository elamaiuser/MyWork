@isTest
private class slwcArcApiService_Test {
    @isTest
    static void getStandardAddress_Test() {

        slwcArcApiService.inputAddressModel model = new slwcArcApiService.inputAddressModel();
        model.addressLine1 = '101 Test Lane';
        model.addressLine2 = 'Testland';
        model.city = 'Testelon';
        model.state = 'Testex';
        model.zip5 = 'T3ST1NG';

        Test.startTest();
            slwcArcApiService.getStandardAddress(model);
        Test.stopTest();
    }

    @isTest static void informaticaStandardAddressModel_Test() {
        slwcArcApiService.informaticaStandardAddressModel model = new slwcArcApiService.informaticaStandardAddressModel();
        model.Line1 = '101 Test Lane';
        model.Line2 = 'Testland';
        model.City = 'Testelon';
        model.State = 'Testex';
        model.Zip = 'T3ST1NG';
        model.DeliveryPointConfirmation = 'Test';
        model.DeliveryPointFootnote1 = 'Test';
        model.DeliveryPointFootnote2 = 'Test';
        model.HighRise = 'Test';
        model.Latitude = 'Test';
        model.Longitude = 'Test';
        model.GeoCodingStatus = 'Test';
        String address = model.FullAddress;
    }
}