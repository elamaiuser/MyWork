@isTest
private class DriveWorksheetReportControllerTest {
    @isTest
    private static void testSearch1(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = 'ABCD';
        classObj.searchRegion = 'ABCD';
        classObj.searchType = 'Fixed Site';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch2(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = '';
        classObj.searchRegion = 'ABCD';
        classObj.searchType = 'Fixed Site';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch3(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = 'ABCD';
        classObj.searchRegion = '';
        classObj.searchType = 'Fixed Site';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch4(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = 'ABCD';
        classObj.searchRegion = 'ABCD';
        classObj.searchType = 'Both';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch5(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = '';
        classObj.searchRegion = '';
        classObj.searchType = 'Fixed Site';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch6(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = 'ABCD';
        classObj.searchRegion = '';
        classObj.searchType = 'Both';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch7(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = '';
        classObj.searchRegion = 'ABCD';
        classObj.searchType = 'Both';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch8(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = '';
        classObj.searchRegion = '';
        classObj.searchType = 'Both';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        //System.assertEquals(0,classObj.ReportDataWrapperList.size(),'List is blank');
    }
    @isTest
    private static void testSearch9(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = 'ABCD';
        classObj.searchRegion = 'ABCD';
        classObj.searchType = 'Fixed Site';
        classObj.searchStartDate = null;
        classObj.searchEndDate = null;
        Test.startTest();
        classObj.search();
        Test.stopTest();
        System.assertEquals(null,classObj.ReportDataWrapperList,'List is blank');
    }
    @isTest
    private static void testSearch10(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = 'ABCD';
        classObj.searchRegion = 'ABCD';
        classObj.searchType = 'Fixed Site';
        classObj.searchStartDate = Date.newInstance(11,11,1998);
        classObj.searchEndDate = null;
        Test.startTest();
        classObj.search();
        Test.stopTest();
        System.assertEquals(null,classObj.ReportDataWrapperList,'List is blank');
    }
    @isTest
    private static void testSearch11(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.searchCollOp = 'ABCD';
        classObj.searchRegion = 'ABCD';
        classObj.searchType = 'Fixed Site';
        classObj.searchStartDate = null;
        classObj.searchEndDate = Date.Today();
        Test.startTest();
        classObj.search();
        Test.stopTest();
        System.assertEquals(null,classObj.ReportDataWrapperList,'List is blank');
    }
    @isTest
    private static void testExportToPdf1(){
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.ReportDataWrapperList = new List<DriveWorksheetReportController.ReportDataWrapper>();
        sked_Drive__c drv = new sked_Drive__c();
        drv.Id = Schema.getGlobalDescribe().get('sked_Drive__c').getDescribe().getKeyPrefix() + '000000000001';
        classObj.ReportDataWrapperList.add(new DriveWorksheetReportController.ReportDataWrapper(drv));
        for(DriveWorksheetReportController.ReportDataWrapper wrapData : classObj.ReportDataWrapperList){
            wrapData.isSelected = true;             
        } 
        Test.startTest();
        PageReference pr = classObj.ExportToPdf();
        Test.stopTest();
        System.assertNotEquals(null,pr,'Page Reference is null');
    }
    @isTest
    private static void testExportToPdf2(){
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(Name = 'Collection Operation 1',
                                                                                                        sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                                                                                                        sked_Lunch_Break_Duration_Mobile__c = '30',
                                                                                                        sked_Hold_Threshold__c = 100,
                                                                                                        Staging_Location_Geolocation__Latitude__s = 37.7450046,
                                                                                                        Staging_Location_Geolocation__Longitude__s = -122.4816244,
                                                                                                        sked_Work_Week_First_Day__c = 'Sunday');
        insert testCollectionOperation1;
        sked__Region__c reg = new sked__Region__c(Name = 'ABCD',
                                                        sked__Timezone__c = 'America/New_York');
        insert reg;
        DriveWorksheetReportController classObj = new DriveWorksheetReportController();
        classObj.ReportDataWrapperList = new List<DriveWorksheetReportController.ReportDataWrapper>();
        sked_Drive__c drv = new sked_Drive__c();
        drv.Id = Schema.getGlobalDescribe().get('sked_Drive__c').getDescribe().getKeyPrefix() + '000000000001';
        classObj.ReportDataWrapperList.add(new DriveWorksheetReportController.ReportDataWrapper(drv));
        for(DriveWorksheetReportController.ReportDataWrapper wrapData : classObj.ReportDataWrapperList){
            wrapData.isSelected = true;             
        } 
        Test.startTest();
        classObj.getRegionlist();
        classObj.getCollectionOperationlist();
        Test.stopTest();
    }
}