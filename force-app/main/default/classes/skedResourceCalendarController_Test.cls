@isTest
private class skedResourceCalendarController_Test {
    @isTest
    static void skedResourceCalendarController_Test() {
        skedResourceCalendarController controller = new skedResourceCalendarController();
        System.assert(controller.resourceId == null);
    }
}