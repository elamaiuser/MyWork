@isTest
private class skedRemoteRequestModel_Test {
    @isTest
    static void populateViewData_Test() {
        Map<String, Object> inputViewData = new Map<String, Object>();
        Decimal item = 5.00;
        inputViewData.put('test', item);
        skedRemoteRequestModel model = new skedRemoteRequestModel();
        model.populateViewData(inputViewData);

        System.assertEquals(item, model.viewData.get('test'));
    }
}