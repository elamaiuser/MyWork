@isTest
private class skedStaffingConstraint_Test {
    
    static testmethod void mainTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        Test.startTest();
        
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = activityTypes.get(0),
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE,
            sked_Fixed_Site_Staff_Quantity__c = 5,
            sked_Mobile_Staff_Quantity__c = 5
        );
        insert skedGroupActivity;
        
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
        update testDrive1;
        
        sked_Staffing_Constraint__c staffingConstraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDrive1.sked_Drive_Date__c,
            sked_Drive_Type__c = testDrive1.sked_Type_of_Drive__c,
        	sked_Total_Staff_Constraints__c = 20
        );
        insert staffingConstraint;
        
        sked_Drive_Shift__c driveShift = new sked_Drive_Shift__c(
            sked_Donors_Scheduled__c = 1,
            sked_End_Time__c = Time.newInstance(20,0,0,0),
            sked_Start_Time__c = Time.newInstance(14,0,0,0),
            sked_Drive__c = testDrive1.Id,
            sked_Drive_Date__c = testDrive1.sked_Drive_Date__c,
            sked_Equipment__c = 1,
            sked_Lunch_Break__c = FALSE,
            sked_Lunch_Break_Before_Draw_Hours__c = FALSE,
            sked_Lunch_Break_Duration__c = 0,
            sked_Lunch_Break_End_Time__c = NULL,
            sked_Lunch_Break_Start_Time__c = NULL,
            sked_Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked_Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked_Order__c = 1,
            sked_Sign_Up_Reduction__c = 0,
            sked_Staff_Setup__c = 10,
            sked_Vehicles_Needed__c = 1,
            sked_Volunteer_Setup__c = 1
        );
        insert driveShift;

        staffingConstraint.sked_Total_Staff_Constraints__c = 5;
        update staffingConstraint;
        
        Test.stopTest();
    }

    @isTest
    static void resolveException_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive1 = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Resource__c testResource1 = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Region__c testRegion1 = (sked__Region__c)mapTestData.get('testRegion1');
        sked__Location__c testLocation1 = (sked__Location__c)mapTestData.get('testLocation1');
        
        List<string> activityTypes = skedUtils.getPickListValues('sked__Activity__c', 'sked__Type__c');
        sked__Activity__c skedGroupActivity = new sked__Activity__c(
            sked__Start__c = testDataFactory.summary.startTime.addHours(9),
            sked__End__c = testDataFactory.summary.startTime.addHours(11),
            sked__Type__c = activityTypes.get(0),
        	sked_Region__c = testRegion1.Id,
            sked_Is_Group_Activity__c = TRUE,
            sked_Fixed_Site_Staff_Quantity__c = 5,
            sked_Mobile_Staff_Quantity__c = 5
        );
        insert skedGroupActivity;
        
        testDrive1.sked_Status__c = skedConstants.DRIVE_STATUS_CONFIRMED;
        update testDrive1;
        
        sked_Staffing_Constraint__c staffingConstraint = new sked_Staffing_Constraint__c(
            sked_Collection_Operation__c = testCollectionOperation1.Id,
            sked_Date_of_Constraint__c = testDrive1.sked_Drive_Date__c,
            sked_Drive_Type__c = testDrive1.sked_Type_of_Drive__c,
        	sked_Total_Staff_Constraints__c = 20
        );
        insert staffingConstraint;

        staffingConstraint.sked_Total_Staff_Constraints__c = 25;
        update staffingConstraint;
        Test.stopTest();
    }

}