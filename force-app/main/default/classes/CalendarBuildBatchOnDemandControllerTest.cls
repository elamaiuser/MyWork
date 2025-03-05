/*
* This Test class covering the following Classes
* CalendarBuildBatchOnDemandController (87%)
* AdhocCalendarBuildRunEvent (PE Trigger) (92%)
* */
/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************
 * 09/16/2024                 Priti Jana                HRP-12706
 * 02/27/2025				  Priti Jana				HRP-11368 (New test method added)
 *****************************************************************************
*/

@isTest(SeeAllData = false)
public class CalendarBuildBatchOnDemandControllerTest {
    
    static testMethod void testMethod1() {
        Test.startTest();
        Id testJobId = CalendarBuildBatchOnDemandController.executeBatchJob();
        Assert.areNotEqual(testJobId, NULL);
        Test.stopTest();
    }
    
    static testMethod void testMethod2() {
        Test.startTest();
        Id testJobId = CalendarBuildBatchOnDemandController.executeBatchUpdateJob();
        Assert.areNotEqual(testJobId, NULL);
        Test.stopTest();
    }
    
    static testMethod void testMethod3() {
        Test.startTest();
        Id testJobId = CalendarBuildBatchOnDemandController.executeBatchUpdateJob();
        AsyncApexJob asyncJobInfo = CalendarBuildBatchOnDemandController.getBatchJobStatus(testJobId);
        Assert.areNotEqual(asyncJobInfo, NULL);
        Test.stopTest();
    }
    
    static testMethod void testMethod4() {
        Test.startTest();
        Integer testBatchSize = CalendarBuildBatchOnDemandController.getDraftDrivesBatchSize();
        Assert.areEqual(1, testBatchSize);
        Test.stopTest();
    }
    
    static testMethod void testMethod5() {
        Test.startTest();
        Integer testBatchSize = CalendarBuildBatchOnDemandController.getSysGenDrivesBatchSize();
        Assert.areEqual(1, testBatchSize);
        Test.stopTest();
    }
    
    //HRP-11368: New Test Method added
    static testMethod void testMethod6() {
        Test.startTest();
        CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput adhocCbInput = new CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput();
        adhocCbInput.bookingStrategy = 'Test';
        adhocCbInput.opportunitySource = 'Adhoc Calendar Build';
        adhocCbInput.selectedOpportunities = new List<Opportunity>();
        CalendarBuildBatchOnDemandController.triggerAdhocCBRunAndGetJobId(new List<CalendarBuildBatchOnDemandController.AdhocCalendarBuildInput>{adhocCbInput});
        Test.stopTest();
    }

}