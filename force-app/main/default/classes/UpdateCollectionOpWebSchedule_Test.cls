@isTest
private class UpdateCollectionOpWebSchedule_Test {
    
    @isTest
    static void testMethod1() {
        Test.startTest();
        
        Date driveDate = System.today();
    
        List<UpdateCollectionOpWebScheduling.getValues> listOfValues = new List<UpdateCollectionOpWebScheduling.getValues>();
        
        UpdateCollectionOpWebScheduling.getValues getValues = new UpdateCollectionOpWebScheduling.getValues();
        getValues.endTimeInfo = '9:00';
        getValues.driveDate = driveDate;
        listOfValues.add(getValues);
        
        List<UpdateCollectionOpWebScheduling.WrapperClass> testWrapperList = UpdateCollectionOpWebScheduling.getWebDates(listOfValues);
        
        Test.stopTest();
        Assert.isTrue(testWrapperList != null && !testWrapperList.isEmpty()); 
    }
}