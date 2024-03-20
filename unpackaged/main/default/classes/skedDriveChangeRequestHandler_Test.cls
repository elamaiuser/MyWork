@isTest
private class skedDriveChangeRequestHandler_Test {

    static testmethod void testCountDCR() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        
        Test.startTest();
        
        sked_Drive_Change_Request__c testDriveChangeRequest = new sked_Drive_Change_Request__c(
            sked_Drive__c = testDrive.Id,
            sked_Status__c = 'Pending'
        );
        insert testDriveChangeRequest;
        
        testDriveChangeRequest.sked_Status__c = 'Submitted';
        update testDriveChangeRequest;
        
        delete testDriveChangeRequest;
            
        Test.stopTest();
    }
    
    static testmethod void cancelReject_Approve_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today().addMonths(6), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Biomed_Collection_Op_Center__c opCenter = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');
        sked_Drive__c testDrive = (sked_Drive__c)mapTestData.get('testDrive1');
        sked__Location__c testLocation1 = (sked__Location__c) mapTestData.get('testLocation1');

        Test.startTest();
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            skedBiomedCollectionOpHandler.createQueues(new Set<String>{opCenter.Name});
        }
        
        sked_Drive_Change_Request__c testDcr = new sked_Drive_Change_Request__c();
        testDcr.sked_Auto_Process__c = true;
        testDcr.sked_Description__c = 'Test Request';
        testDcr.sked_Drive__c = testDrive.Id;
        testDcr.sked_Drive_Contention__c = 'Exceed Operation Drive Limit';
        testDcr.sked_Notes__c = 'Test Request';
        testDcr.sked_Reason__c = 'Sponsor Initiated'; 
        testDcr.sked_Route_Approval_Request_To__c = 'Request DM evaluation';
        testDcr.sked_Status__c = 'Pending';

        insert testDcr;
        
        sked_Drive_Change_Request_Item__c testDriveChangeRequestItem = new sked_Drive_Change_Request_Item__c(
            sked_Drive_Change_Request__c = testDcr.Id,
            sked_Old_Value__c = testLocation1.Id,
            sked_New_Value__c = testLocation1.Id,
            sked_Change_Reason__c = 'Test',
            sked_Object_API_Name__c = 'Opportunity',
            sked_Field_API_Name__c = 'Drive_Site__c',
            sked_Type__c = 'Change'
        );
        insert testDriveChangeRequestItem;

        testDcr.sked_Status__c = 'Submitted';
        update testDcr;
        
        slwcApprovalService.approveRejectRequestModel model = new slwcApprovalService.approveRejectRequestModel();
        model.action = 'Reject';
        model.recordId = testDcr.Id;
        model.comments = 'Testing';

        slwcAuraResult approveRejectResult = slwcApprovalService.approveReject(model);

        Test.stopTest();
    }
    
}