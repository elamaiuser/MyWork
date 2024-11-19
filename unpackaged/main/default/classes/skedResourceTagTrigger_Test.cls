@isTest
private class skedResourceTagTrigger_Test {

    static testmethod void getNewTraineeTagsForResource_ExtendedTag_Test() {
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        List<sked__Tag__c> roleTags =  [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 2];

        Test.startTest();
        
        List<sked__Resource_Tag__c> pendingRoleTags = new List<sked__Resource_Tag__c>();
        sked__Resource_Tag__c firstPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today(),
            sked_Expiry_Date__c = System.today().addYears(1),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(firstPendingTag);
        
        sked__Resource_Tag__c secondPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(1),
            sked_Expiry_Date__c = System.today().addYears(3),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(secondPendingTag);
        
        sked__Resource_Tag__c thirdPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(4),
            sked_Expiry_Date__c = System.today().addYears(5),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(thirdPendingTag);
        
        sked__Resource_Tag__c fourthPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(4).addMonths(6),
            sked_Expiry_Date__c = System.today().addYears(5).addMonths(6),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(fourthPendingTag);
        
        insert pendingRoleTags; 
        List<sked__Resource_Tag__c> traineeTags = skedResourceTagHandler.getNewTraineeTagsForResource(testResource, pendingRoleTags);
        
        for (sked__Resource_Tag__c tag : traineeTags) {
            System.debug(tag);
        }
        
        Test.stopTest();
    }

    static testmethod void getNewNoTraineeTagsForResource_ExistingPendingRoleTag_Test() {
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        List<sked__Tag__c> roleTags =  [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 2];
        
        Test.startTest();
        
        List<sked__Resource_Tag__c> pendingRoleTags = new List<sked__Resource_Tag__c>();
        sked__Resource_Tag__c firstPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today(),
            sked_Expiry_Date__c = null,
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(firstPendingTag);
        
        insert pendingRoleTags; 
        List<sked__Resource_Tag__c> traineeTags = skedResourceTagHandler.getNewTraineeTagsForResource(testResource, pendingRoleTags);
        List<sked__Resource_Tag__c> noTraineeTags = skedResourceTagHandler.getNewNoTraineeTagsForResource(testResource, traineeTags);
        
        Test.stopTest();
    }

    static testmethod void getNewNoTraineeTagsForResource_FuturePendingRoleTags_Test() {
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        List<sked__Tag__c> roleTags =  [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 2];

        Test.startTest();
        
        List<sked__Resource_Tag__c> pendingRoleTags = new List<sked__Resource_Tag__c>();
        sked__Resource_Tag__c firstPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today().addYears(1),
            sked_Expiry_Date__c = System.today().addYears(2),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(firstPendingTag);
        
        sked__Resource_Tag__c secondPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today().addYears(3),
            sked_Expiry_Date__c = null,
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(secondPendingTag);
        
        insert pendingRoleTags; 
        List<sked__Resource_Tag__c> traineeTags = skedResourceTagHandler.getNewTraineeTagsForResource(testResource, pendingRoleTags);
        List<sked__Resource_Tag__c> noTraineeTags = skedResourceTagHandler.getNewNoTraineeTagsForResource(testResource, traineeTags);
        
        Test.stopTest();
    }

    static testmethod void getNewTraineeTagsForResource_NullExpiry_Test() {
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        List<sked__Tag__c> roleTags =  [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 2];

        Test.startTest();
        
        List<sked__Resource_Tag__c> pendingRoleTags = new List<sked__Resource_Tag__c>();
        sked__Resource_Tag__c firstPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today(),
            sked_Expiry_Date__c = null,
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(firstPendingTag);
        
        sked__Resource_Tag__c secondPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(1),
            sked_Expiry_Date__c = System.today().addYears(3),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(secondPendingTag);
        
        sked__Resource_Tag__c thirdPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(4),
            sked_Expiry_Date__c = System.today().addYears(5),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(thirdPendingTag);
        
        sked__Resource_Tag__c fourthPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(4).addMonths(6),
            sked_Expiry_Date__c = System.today().addYears(5).addMonths(6),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        pendingRoleTags.add(fourthPendingTag);
        
        insert pendingRoleTags; 
        List<sked__Resource_Tag__c> traineeTags = skedResourceTagHandler.getNewTraineeTagsForResource(testResource, pendingRoleTags);
        
        Test.stopTest();
    }

    static testmethod void maintainTraineeRole_ChangeDate_Test(){
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        List<sked__Tag__c> roleTags =  [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 2];
        
        sked__Resource_Tag__c firstPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today(),
            sked_Expiry_Date__c = System.today().addYears(1),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );

        sked__Resource_Tag__c secondPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(2),
            sked_Expiry_Date__c = System.today().addYears(3),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );

        insert new List<sked__Resource_Tag__c>{firstPendingTag, secondPendingTag};

        Test.startTest();
        
        // get Trainee resource tag & update the start date
        sked__Resource_Tag__c pendingTag = [
            SELECT Id, sked_Start_Date__c, sked__Resource__c 
            FROM sked__Resource_Tag__c 
            WHERE sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_PENDING
            ORDER BY sked_Start_Date__c Desc LIMIT 1
        ];
        
        // This is the +2 years tag, changing it to +5 days causes the tags to overlap
        // So we should only have one after this operation completes.
        pendingTag.sked_Start_Date__c = System.today() + 5;
        update pendingTag;
        
        Test.stopTest();   
    }

    static testmethod void maintainTraineeRole_ActivatePendingRoles_Test() {
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        List<sked__Tag__c> roleTags =  [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 2];
        
        sked__Resource_Tag__c firstPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today(),
            sked_Expiry_Date__c = System.today().addYears(1),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );

        sked__Resource_Tag__c secondPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[1].Id,
            sked_Start_Date__c = System.today().addYears(2),
            sked_Expiry_Date__c = System.today().addYears(3),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );

        insert new List<sked__Resource_Tag__c>{firstPendingTag, secondPendingTag};

        Test.startTest();
        
        // get Trainee resource tag & update the start date
        List<sked__Resource_Tag__c> pendingTags = [
            SELECT Id, sked_Start_Date__c, sked__Resource__c 
            FROM sked__Resource_Tag__c 
            WHERE sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_PENDING
            ORDER BY sked_Start_Date__c DESC
        ];
        
        for (sked__Resource_Tag__c rt : pendingTags) {
            rt.sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_ACTIVE;
        }
        
        update pendingTags;
        
        Test.stopTest();  
    }

    static testmethod void populateRecordType_Test() {
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        List<sked__Tag__c> roleTags =  [SELECT Id FROM sked__Tag__c WHERE sked__Type__c = 'Role' LIMIT 2];
        
        sked__Resource_Tag__c firstPendingTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = roleTags[0].Id,
            sked_Start_Date__c = System.today(),
            sked_Expiry_Date__c = System.today().addYears(1),
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_PENDING
        );
        insert firstPendingTag;
    }

    static testmethod void afterDelete_Test() {
        insert new sked__Tag__c(Name = skedConstants.TAG_NO_TRAINEE, sked__Type__c = 'Certification');

        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Tag__c testTag = (sked__Tag__c) mapTestData.get('testTag1');

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob;

        sked__Job_Tag__c testJobTag = new sked__Job_Tag__c(
            sked__Job__c = testJob.Id,
            sked__Tag__c = testTag.Id,
            sked__Required__c = true
        );
        insert testJobTag;

        sked__Resource_Tag__c testResourceTag = new sked__Resource_Tag__c(
            sked__Resource__c = testResource.Id,
            sked__Tag__c = testTag.Id,
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_ACTIVE,
            sked_Start_Date__c = System.today().addDays(-100)
        );
        insert testResourceTag;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Resource__c = testResource.Id,
            sked__Job__c = testJob.Id
        );
        insert testJobAllocation;

        delete testResourceTag;
        
        Test.stopTest();
    }

    static testmethod void manageRoleRestrictedExceptions_OpenTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Tag__c test2RBCTag = (sked__Tag__c) mapTestData.get('testTag2RBC');
        sked__Resource_Tag__c testResourceTag2RBC = (sked__Resource_Tag__c) mapTestData.get('testResource1_testTag2RBC');

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob;

        sked__Job_Tag__c testJobTag = new sked__Job_Tag__c(
            sked__Job__c = testJob.Id,
            sked__Tag__c = test2RBCTag.Id,
            sked__Required__c = true
        );
        insert testJobTag;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Resource__c = testResource.Id,
            sked__Job__c = testJob.Id
        );
        insert testJobAllocation;

        testResourceTag2RBC.sked_Restriction_Start_Date__c = skedConstants.EARLIEST_START_DATE;
        testResourceTag2RBC.sked_Restriction_End_Date__c = skedConstants.LATEST_END_DATE;
        update testResourceTag2RBC;
        
        Test.stopTest();
    }

    static testmethod void manageRoleRestrictedExceptions_ClosedTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();
        mapTestData = testDataFactory.setupDriveData();

        Test.startTest();
        
        sked__Resource__c testResource = (sked__Resource__c) mapTestData.get('testResource1');
        sked_Drive__c testDrive = (sked_Drive__c) mapTestData.get('testDrive1');
        sked__Region__c testRegion = (sked__Region__c) mapTestData.get('testRegion1');
        sked__Tag__c test2RBCTag = (sked__Tag__c) mapTestData.get('testTag2RBC');
        sked__Resource_Tag__c testResourceTag2RBC = (sked__Resource_Tag__c) mapTestData.get('testResource1_testTag2RBC');

        testResourceTag2RBC.sked_Restriction_Start_Date__c = skedConstants.EARLIEST_START_DATE;
        testResourceTag2RBC.sked_Restriction_End_Date__c = skedConstants.LATEST_END_DATE;
        update testResourceTag2RBC;

        sked__Job__c testJob = new sked__Job__c(
            sked__Region__c = testRegion.Id,
            sked__Start__c = DateTime.newInstance(System.today(), Time.newInstance(14,0,0,0)),
            sked__Finish__c = DateTime.newInstance(System.today(), Time.newInstance(20,0,0,0)),
            sked__Duration__c = 60,
            sked__Job_Status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            sked_Drive__c = testDrive.Id,
            sked_Resource_Role__c = '2RBC'
        );
        insert testJob;

        sked__Job_Tag__c testJobTag = new sked__Job_Tag__c(
            sked__Job__c = testJob.Id,
            sked__Tag__c = test2RBCTag.Id,
            sked__Required__c = true
        );
        insert testJobTag;

        sked__Job_Allocation__c testJobAllocation = new sked__Job_Allocation__c(
            sked__Resource__c = testResource.Id,
            sked__Job__c = testJob.Id
        );
        insert testJobAllocation;

        insert new skedHC__Exception__c (
            sked_Drive__c = testDrive.Id,
            skedHC__Job__c = testJob.Id,
            skedHC__Job_Allocation__c = testJobAllocation.Id,
            skedHC__Resource__c = testResource.Id,
            sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_ROLE_RESTRICTED,
            skedHC__Exception__c = 'Resource Role Restricted: ' + test2RBCTag.Name,
            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
        );

        testResourceTag2RBC.sked_Restriction_Start_Date__c = null;
        testResourceTag2RBC.sked_Restriction_End_Date__c = null;
        update testResourceTag2RBC;
        
        Test.stopTest();
    }

    static testmethod void processResourceHighestPriorityRoleChanged_AfterUpdateTest() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', system.today(), 14);
        Map<string, sObject> mapTestData = testDataFactory.setupCommonTestData();

        Test.startTest();

        sked__Availability__c testAvailability1 = new sked__Availability__c(
            sked__Resource__c = mapTestData.get('testResource1').Id,
            sked__Type__c = skedConstants.AVAILABILITY_TYPE_PTO,
            sked__Is_Available__c = FALSE,
            sked__Start__c = Datetime.now().addDays(1),
            sked__Finish__c = Datetime.now().addDays(2).addMinutes(-1),
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
        insert testAvailability1;

        sked__Tag__c testTag2RBC = (sked__Tag__c) mapTestData.get('testTag2RBC');
        testTag2RBC.sked_Priority__c = 1;
        update testTag2RBC;

        sked__Resource_Tag__c testResource1_testTag2RBC = (sked__Resource_Tag__c) mapTestData.get('testResource1_testTag2RBC');
        testResource1_testTag2RBC.sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_INACTIVE;
        update testResource1_testTag2RBC;

        Test.stopTest();
    }
    
}