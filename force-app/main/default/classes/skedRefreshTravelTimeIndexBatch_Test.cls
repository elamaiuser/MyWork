@isTest
private class skedRefreshTravelTimeIndexBatch_Test {
    @isTest
    static void skedRefreshTravelTimeIndexBatchBase_Test() {
        skedRefreshTravelTimeIndexBatchBase batch = new skedRefreshTravelTimeIndexBatchBase();
        Database.executeBatch(batch, 200);
    }
}