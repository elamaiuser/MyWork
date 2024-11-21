@isTest
private class skedDriveApprovalUtils_Test {

    static testmethod void skedDriveApprovalUtils_Test() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        Biomed_Collection_Op_Center__c testCollectionOperation1 = (Biomed_Collection_Op_Center__c)mapTestData.get('testCollectionOperation1');

        List<string> dmApprovalStatuses = skedDriveApprovalUtils.getDMApprovalStatuses();
        List<string> pendingApprovalStatuses = skedDriveApprovalUtils.getPendingApprovalStatuses();

        System.runAs(new User(Id = UserInfo.getUserId())){
            Set<string> coNames = new Set<string>();
            coNames.add(testCollectionOperation1.Name);
            skedBiomedCollectionOpHandler.createQueues(coNames);
        }

        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments('Submitting request for Drive approval.');
        request.setObjectId(testDrive.Id);
        request.setSubmitterId(UserInfo.getUserId());
        request.setProcessDefinitionNameOrId(null);

        Map<Id, sked_Drive__c> driveById = new Map<Id, sked_Drive__c>();
        driveById.put(testDrive.Id, testDrive);
        System.debug('DRIVE BY ID :: ' + driveById);

        Test.startTest();
            skedDriveApprovalUtils.processDriveApprovals(new List<Approval.ProcessSubmitRequest>{request}, driveById);
        Test.stopTest();

        List<sked__Debug_Log__c> debugLogs = [SELECT Id FROM sked__Debug_Log__c];
        Assert.isFalse(debugLogs.isEmpty());
    }
}