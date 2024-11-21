@isTest
private class skedProcessEventResult_Test {
    @isTest
    static void skedProcessEventResult_Test() {
        skedProcessEventResult res = new skedProcessEventResult();
        try {
            insert new Account();
        }
        catch (Exception ex) {
            res.addError(ex);
        }
    }
}