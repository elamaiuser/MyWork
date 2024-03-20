@isTest
private class skedModels_Test {
    @isTest
    static void event_updateDateTimeFields_Test() {
        skedModels.event testEvent = new skedModels.event();
        testEvent.start = System.now();
        testEvent.finish = System.now();

        Test.startTest();
            testEvent.updateDateTimeFields(UserInfo.getTimeZone().getID());
        Test.stopTest();
    }

    @isTest
    static void event_updateStartFinish_Test() {
        skedModels.event testEvent = new skedModels.event();

        Test.startTest();
            testEvent.updateStartFinish(UserInfo.getTimeZone().getID());
        Test.stopTest();
    }

    @isTest
    static void event_compareTo_Test() {
        skedModels.event testEvent = new skedModels.event();
        testEvent.start = System.now();

        skedModels.event testEvent2 = new skedModels.event();
        testEvent2.start = System.now().addDays(1);

        Test.startTest();
            System.assertEquals(-1, testEvent.compareTo(testEvent2));
            System.assertEquals(1, testEvent2.compareTo(testEvent));
        Test.stopTest();
    }

    @isTest
    static void geometry_constructor_Tests() {
        Location testLocation = Location.newInstance(38.955349, -77.393841);
        skedModels.geometry testGeometry = new skedModels.geometry(testLocation);
        skedModels.geometry testGeometry2 = new skedModels.geometry(38.955349, -77.393841);
    }

    @isTest
    static void clientAvailability_updatePreferredDateTimeFields_Test() {
        skedModels.clientAvailability testClientAvailability = new skedModels.clientAvailability();
        testClientAvailability.preferredStart = System.now();
        testClientAvailability.preferredEnd = System.now();

        Test.startTest();
            testClientAvailability.updatePreferredDateTimeFields(UserInfo.getTimeZone().getID());
        Test.stopTest();
    }

    @isTest
    static void exceptionLog_compareTo_Test() {
        skedModels.exceptionLog testExceptionLog = new skedModels.exceptionLog();
        testExceptionLog.job = new skedModels.job();
        testExceptionLog.job.startDate = '2022-09-05';
        testExceptionLog.job.startTime = 0900;

        skedModels.exceptionLog testExceptionLog2 = new skedModels.exceptionLog();
        testExceptionLog2.job = new skedModels.job();
        testExceptionLog2.job.startDate = '2022-09-05';
        testExceptionLog2.job.startTime = 1700;

        skedModels.exceptionLog testExceptionLog3 = new skedModels.exceptionLog();
        testExceptionLog3.job = new skedModels.job();
        testExceptionLog3.job.startDate = '2022-09-06';
        testExceptionLog3.job.startTime = 1700;

        Test.startTest();
            testExceptionLog.compareTo(testExceptionLog2);
            testExceptionLog.compareTo(testExceptionLog3);
            testExceptionLog2.compareTo(testExceptionLog);
            testExceptionLog2.compareTo(testExceptionLog3);
            testExceptionLog3.compareTo(testExceptionLog);
            testExceptionLog3.compareTo(testExceptionLog2);
        Test.stopTest();
    }

    @isTest 
    static void selectOption_Constructor_Tests() {
        skedModels.selectOption testSelectOption = new skedModels.selectOption('test-value', 'test-text');
        skedModels.selectOption testSelectOption2 = new skedModels.selectOption('test-value', 'test-text', true);
    }
}