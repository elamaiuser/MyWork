@isTest
private class skedAvailabilityHandler_Test {

    private static final String PLANNER_USERNAME = 'hrp17429.planner@testleton.com';
    private static final String SCHEDULER_USERNAME = 'hrp17429.scheduler@testleton.com';

    // The test users need the object access their real-world counterparts get from these permission sets,
    // otherwise they cannot be given ownership of the parent resource.
    private static final Map<String, String> PERMISSION_SET_BY_USERNAME = new Map<String, String>{
        PLANNER_USERNAME => 'sked_APS_Planner',
        SCHEDULER_USERNAME => 'sked_APS'
    };

    @TestSetup
    static void setupTestData() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();

        sked__Resource__c testResource = (sked__Resource__c)mapTestData.get('testResource1');
        sked__Resource__c testVehicle = (sked__Resource__c)mapTestData.get('testVehicle1');
        DateTime startTime = testDataFactory.summary.startTime;

        skedHubBase.setBypassAllTriggers(true);
        insert new List<sked__Availability__c>{
            buildAvailability(testResource.Id, startTime),
            buildAvailability(testVehicle.Id, startTime)
        };

        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<User> testUsers = new List<User>{
                buildUser('APS Planner', PLANNER_USERNAME, '429001'),
                buildUser('APS Scheduler', SCHEDULER_USERNAME, '429002')
            };
            insert testUsers;
            assignPermissionSets(testUsers);
        }
        skedHubBase.setBypassAllTriggers(false);
    }

    @isTest
    static void testUpdate_apsPlannerCanEditAssetAvailabilityOutsideRac() {
        sked__Availability__c assetAvailability = getAvailability(skedConstants.RESOURCE_TYPE_ASSET);
        User plannerUser = getUser(PLANNER_USERNAME);
        grantResourceAccess(assetAvailability.sked__Resource__c, plannerUser.Id);

        Test.startTest();
        Database.SaveResult result = extendFinishDate(assetAvailability, plannerUser, FALSE);
        Test.stopTest();

        System.assertEquals(extendedFinishDate(assetAvailability), getFinishDate(assetAvailability.Id),
            'APS Planner should be able to extend an Asset availability outside the RAC, got: ' + result.getErrors());
    }

    @isTest
    static void testUpdate_apsPlannerCannotEditPersonAvailabilityOutsideRac() {
        sked__Availability__c personAvailability = getAvailability(skedConstants.RESOURCE_TYPE_PERSON);
        User plannerUser = getUser(PLANNER_USERNAME);
        grantResourceAccess(personAvailability.sked__Resource__c, plannerUser.Id);

        Test.startTest();
        Database.SaveResult result = extendFinishDate(personAvailability, plannerUser, FALSE);
        Test.stopTest();

        System.assertEquals(skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC, getErrorMessage(result),
            'APS Planner should be redirected to the RAC when editing a Person availability');
    }

    @isTest
    static void testUpdate_apsPlannerCanEditPersonAvailabilityViaRac() {
        sked__Availability__c personAvailability = getAvailability(skedConstants.RESOURCE_TYPE_PERSON);
        User plannerUser = getUser(PLANNER_USERNAME);
        grantResourceAccess(personAvailability.sked__Resource__c, plannerUser.Id);

        Test.startTest();
        Database.SaveResult result = extendFinishDate(personAvailability, plannerUser, TRUE);
        Test.stopTest();

        System.assertEquals(TRUE, result.isSuccess(),
            'APS Planner should still be able to edit a Person availability through the RAC, got: ' + result.getErrors());
    }

    @isTest
    static void testUpdate_apsPlannerMixedBatchBlocksOnlyPersonAvailability() {
        sked__Availability__c assetAvailability = getAvailability(skedConstants.RESOURCE_TYPE_ASSET);
        sked__Availability__c personAvailability = getAvailability(skedConstants.RESOURCE_TYPE_PERSON);
        User plannerUser = getUser(PLANNER_USERNAME);
        grantResourceAccess(assetAvailability.sked__Resource__c, plannerUser.Id);
        grantResourceAccess(personAvailability.sked__Resource__c, plannerUser.Id);

        Test.startTest();
        List<Database.SaveResult> results = extendFinishDates(
            new List<sked__Availability__c>{assetAvailability, personAvailability}, plannerUser, FALSE
        );
        Test.stopTest();

        System.assertEquals(
            new List<String>{NULL, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC},
            new List<String>{getErrorMessage(results.get(0)), getErrorMessage(results.get(1))},
            'Only the Person availability of a mixed batch should be redirected to the RAC'
        );
    }

    @isTest
    static void testUpdate_permittedProfileCanEditPersonAvailabilityOutsideRac() {
        sked__Availability__c personAvailability = getAvailability(skedConstants.RESOURCE_TYPE_PERSON);
        User schedulerUser = getUser(SCHEDULER_USERNAME);
        grantResourceAccess(personAvailability.sked__Resource__c, schedulerUser.Id);

        Test.startTest();
        Database.SaveResult result = extendFinishDate(personAvailability, schedulerUser, FALSE);
        Test.stopTest();

        System.assertEquals(TRUE, result.isSuccess(),
            'APS Scheduler should be unaffected by the Asset-only allowance, got: ' + result.getErrors());
    }

    /*********************************************************** Private methods ***********************************************************/
    private static sked__Availability__c buildAvailability(Id resourceId, DateTime startTime) {
        return new sked__Availability__c(
            sked__Resource__c = resourceId,
            sked__Type__c = 'Available',
            sked__Is_Available__c = TRUE,
            sked__Start__c = startTime.addHours(9),
            sked__Finish__c = startTime.addHours(17),
            sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED
        );
    }

    private static User buildUser(String profileName, String username, String employeeId) {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = :profileName];
        return new User(
            alias = 'tstusr', email = username, emailencodingkey = 'UTF-8', firstName = 'HRP17429',
            lastName = profileName, languagelocalekey = 'en_US', localesidkey = 'en_US',
            profileId = userProfile.Id, country = 'United States', timezonesidkey = 'America/Los_Angeles',
            username = username, UFID__c = employeeId
        );
    }

    private static void assignPermissionSets(List<User> testUsers) {
        Map<String, Id> mapPermissionSetIdByName = new Map<String, Id>();
        for (PermissionSet permissionSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :PERMISSION_SET_BY_USERNAME.values()]) {
            mapPermissionSetIdByName.put(permissionSet.Name, permissionSet.Id);
        }
        
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (User testUser : testUsers) {
            assignments.add(new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = mapPermissionSetIdByName.get(PERMISSION_SET_BY_USERNAME.get(testUser.Username))
            ));
        }
        insert assignments;
    }

    private static sked__Availability__c getAvailability(String resourceType) {
        List<sked__Availability__c> availabilities = [
            SELECT Id, sked__Resource__c, sked__Finish__c
            FROM sked__Availability__c
            WHERE sked__Resource__r.sked__Resource_Type__c = :resourceType
        ];
        System.assertEquals(1, availabilities.size(), 'Expected exactly one ' + resourceType + ' availability in the fixture');
        return availabilities.get(0);
    }

    private static User getUser(String username) {
        return [SELECT Id FROM User WHERE Username = :username];
    }

    private static DateTime getFinishDate(Id availabilityId) {
        return [SELECT sked__Finish__c FROM sked__Availability__c WHERE Id = :availabilityId].sked__Finish__c;
    }

    // Availability sharing is ControlledByParent and sked__Resource__c is Private, so the acting user
    // needs to own the parent resource to reach the record at all under System.runAs.
    private static void grantResourceAccess(Id resourceId, Id userId) {
        skedHubBase.setBypassAllTriggers(true);
        update new sked__Resource__c(Id = resourceId, OwnerId = userId);
        skedHubBase.setBypassAllTriggers(false);
    }

    private static DateTime extendedFinishDate(sked__Availability__c availability) {
        return availability.sked__Finish__c.addDays(1);
    }

    private static Database.SaveResult extendFinishDate(sked__Availability__c availability, User actingUser, Boolean isInitiatedFromService) {
        return extendFinishDates(new List<sked__Availability__c>{availability}, actingUser, isInitiatedFromService).get(0);
    }

    private static List<Database.SaveResult> extendFinishDates(List<sked__Availability__c> availabilities, User actingUser, Boolean isInitiatedFromService) {
        List<sked__Availability__c> availabilitiesToUpdate = new List<sked__Availability__c>();
        for (sked__Availability__c availability : availabilities) {
            availabilitiesToUpdate.add(new sked__Availability__c(
                Id = availability.Id,
                sked__Finish__c = extendedFinishDate(availability)
            ));
        }
        
        List<Database.SaveResult> results;
        System.runAs(actingUser) {
            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = isInitiatedFromService;
            results = Database.update(availabilitiesToUpdate, FALSE);
        }
        return results;
    }

    private static String getErrorMessage(Database.SaveResult result) {
        return result.isSuccess() ? NULL : result.getErrors().get(0).getMessage();
    }
}