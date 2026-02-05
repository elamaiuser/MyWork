@isTest(SeeAllData = false)
private class InformaticaStandardAddress_Test {

    static testMethod void testAddressMethod() {
        InformaticaStandardAddress testInstance = new InformaticaStandardAddress();
        testInstance.City = 'Test City';
        testInstance.State = 'Test State';
        testInstance.Zip = '10000';
        testInstance.Line1 = 'Test Address Line 1';
        testInstance.Line2 = 'Test Address Line 2';
        testInstance.DeliveryPointConfirmation = 'Test';
        testInstance.DeliveryPointFootnote1 = 'Test Footnote 1';
        testInstance.DeliveryPointFootnote2 = 'Test Footnote 2';
        testInstance.GeoCodingStatus = 'Test';
        testInstance.HighRise = 'Test';
        testInstance.Latitude = '42.2763257';
        testInstance.Longitude = '-71.0342786';
        
        Test.startTest();
        
        String testFullAddress = testInstance.FullAddress;
        Assert.isTrue(!String.isBlank(testFullAddress) && testFullAddress.startsWith('Test Address Line 1'));
            
        Test.stopTest();
    }
}