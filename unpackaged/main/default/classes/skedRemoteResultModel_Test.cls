@isTest
private class skedRemoteResultModel_Test {
    @isTest
    static void skedRemoteResultModel_Test() {
        skedRemoteResultModel resultModel = new skedRemoteResultModel();

        Map<String, Object> testViewData = new Map<String, Object>();
        testViewData.put('user', UserInfo.getUserType());

        resultModel = new skedRemoteResultModel(testViewData);

        SavePoint sp = Database.setSavepoint();
        try {
            insert new Account();
        } catch(Exception ex) {
            resultModel.getError(ex);
            resultModel.getError(ex, sp);
        }
    }
}