@isTest
private class skedWorkdayAbsenceManagementSvcTest {
	@isTest static void Adjust_Time_Off_Http(){
		Test.setMock(HttpCalloutMock.class, new skedWorkdayAbsenceManagementHttpMock());
		skedWorkdayAbsenceManagement testObject = new skedWorkdayAbsenceManagement();
		testObject.Adjust_Time_Off_Http(null, null);		
	}
	@isTest static void Enter_Time_Off_Http(){
		Test.setMock(HttpCalloutMock.class, new skedWorkdayAbsenceManagementHttpMock());
		skedWorkdayAbsenceManagement testObject = new skedWorkdayAbsenceManagement();
		testObject.Enter_Time_Off_Http(null, null);	
	}
}