@isTest
private class skedWorkdayTimeTrackingSvcTest {
	@isTest static void Import_Reported_Time_Blocks_Http(){
		Test.setMock(HttpCalloutMock.class, new skedWorkdayTimeTrackingHttpMock());
		skedWorkdayTimeTracking testObject = new skedWorkdayTimeTracking();
		testObject.Import_Reported_Time_Blocks_Http(null);		
	}
}