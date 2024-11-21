@isTest
private class skedRoleTimeVarianceUtils_Test {
    @isTest
    static void testGetAdjustmentsToAddBufferForRelatedJobs() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        Id testLocationId = mapTestData.get('testLocation1').Id;
        List<skedRoleTimeVarianceAdjustment> adjustments = skedRoleTimeVarianceUtils.getAdjustmentsToAddBufferForRelatedJobs(
            new List<sked_Role_Time_Variance__c> {
                new sked_Role_Time_Variance__c(
                    sked_Effective_Start_Date__c = Date.today(),
                    sked_Effective_End_Date__c = Date.today().addDays(1),
                    sked_Variance_Applies_to__c = String.join(new List<String>{
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME
                    }, ';'),
                    sked_Resource_Role_Group__c = 'Staff roles',
                    sked_Location__c = testLocationId,
                    sked_Variation_Amount__c = 30,
                    sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD,
                    sked_Days_Of_Week__c = 'Monday'
                ),
                new sked_Role_Time_Variance__c(
                    sked_Effective_Start_Date__c = Date.today(),
                    sked_Effective_End_Date__c = Date.today().addDays(1),
                    sked_Variance_Applies_to__c = String.join(new List<String>{
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME
                    }, ';'),
                    sked_Resource_Role_Group__c = 'Staff roles',
                    sked_Location__c = testLocationId,
                    sked_Variation_Amount__c = 30,
                    sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_SUBTRACT,
                    sked_Days_Of_Week__c = 'Monday;Tuesday'
                )
            }
        );

        System.assertEquals(2, adjustments.size());
        System.assertEquals(Date.today(), adjustments[0].startDate);
        System.assertEquals(Date.today().addDays(1), adjustments[0].endDate);
        System.assertEquals('Staff roles', adjustments[0].resourceRoleGroup);
        System.assertEquals(testLocationId, adjustments[0].siteId);
        System.assertEquals(skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME + ';' + skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME, adjustments[0].varianceApplyTo);
        System.assertEquals(30, adjustments[0].adjustAmount);
        System.assertEquals(Date.today(), adjustments[1].startDate);
        System.assertEquals(Date.today().addDays(1), adjustments[1].endDate);
        System.assertEquals('Staff roles', adjustments[1].resourceRoleGroup);
        System.assertEquals(testLocationId, adjustments[1].siteId);
        System.assertEquals(skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME + ';' + skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME, adjustments[1].varianceApplyTo);
        System.assertEquals(-30, adjustments[1].adjustAmount);
        System.assertEquals('Monday', adjustments[0].daysOfWeek);
        System.assertEquals('Monday;Tuesday', adjustments[1].daysOfWeek);
    }

    @isTest
    static void testGetAdjustmentsToRemoveBufferForRelatedJobs() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        Id testLocationId = mapTestData.get('testLocation1').Id;
        List<skedRoleTimeVarianceAdjustment> adjustments = skedRoleTimeVarianceUtils.getAdjustmentsToRemoveBufferForRelatedJobs(
            new List<sked_Role_Time_Variance__c> {
                new sked_Role_Time_Variance__c(
                    sked_Effective_Start_Date__c = Date.today(),
                    sked_Effective_End_Date__c = Date.today().addDays(1),
                    sked_Variance_Applies_to__c = String.join(new List<String>{
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME
                    }, ';'),
                    sked_Resource_Role_Group__c = 'Staff roles',
                    sked_Location__c = testLocationId,
                    sked_Variation_Amount__c = 30,
                    sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD,
                    sked_Days_Of_Week__c = 'Monday'
                ),
                new sked_Role_Time_Variance__c(
                    sked_Effective_Start_Date__c = Date.today(),
                    sked_Effective_End_Date__c = Date.today().addDays(1),
                    sked_Variance_Applies_to__c = String.join(new List<String>{
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                        skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME
                    }, ';'),
                    sked_Resource_Role_Group__c = 'Staff roles',
                    sked_Location__c = testLocationId,
                    sked_Variation_Amount__c = 30,
                    sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_SUBTRACT,
                    sked_Days_Of_Week__c = 'Monday;Tuesday'
                )
            }
        );

        System.assertEquals(2, adjustments.size());
        System.assertEquals(Date.today(), adjustments[0].startDate);
        System.assertEquals(Date.today().addDays(1), adjustments[0].endDate);
        System.assertEquals('Staff roles', adjustments[0].resourceRoleGroup);
        System.assertEquals(testLocationId, adjustments[0].siteId);
        System.assertEquals(skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME + ';' + skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME, adjustments[0].varianceApplyTo);
        System.assertEquals(-30, adjustments[0].adjustAmount);
        System.assertEquals(Date.today(), adjustments[1].startDate);
        System.assertEquals(Date.today().addDays(1), adjustments[1].endDate);
        System.assertEquals('Staff roles', adjustments[1].resourceRoleGroup);
        System.assertEquals(testLocationId, adjustments[1].siteId);
        System.assertEquals(skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME + ';' + skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME, adjustments[1].varianceApplyTo);
        System.assertEquals(30, adjustments[1].adjustAmount);
        System.assertEquals('Monday', adjustments[0].daysOfWeek);
        System.assertEquals('Monday;Tuesday', adjustments[1].daysOfWeek);
    }

    @isTest
    static void testGetAdjustmentsToModifyBufferForRelatedJobs_EffectiveDateChangedOverlapping() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        Id testLocationId = mapTestData.get('testLocation1').Id;

        skedHubBase.setBypassAllTriggers(true);
        sked_Role_Time_Variance__c newRtv = new sked_Role_Time_Variance__c(
            sked_Effective_Start_Date__c = Date.today().addDays(2),
            sked_Effective_End_Date__c = Date.today().addDays(4),
            sked_Variance_Applies_to__c = String.join(new List<String>{
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME
            }, ';'),
            sked_Resource_Role_Group__c = 'Staff roles;Driving roles',
            sked_Location__c = testLocationId,
            sked_Variation_Amount__c = 30,
            sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD,
            sked_Variation_Type__c = 'Safety Video',
            sked_Days_Of_Week__c = 'Monday;Tuesday'
        );
        insert newRtv;
        skedHubBase.setBypassAllTriggers(false);

        Map<Id, sked_Role_Time_Variance__c> rtvOldMap = new Map<Id, sked_Role_Time_Variance__c> {
            newRtv.Id => new sked_Role_Time_Variance__c(
                sked_Effective_Start_Date__c = Date.today(),
                sked_Effective_End_Date__c = Date.today().addDays(3),
                sked_Variance_Applies_to__c = String.join(new List<String>{
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_WRAP_UP_TIME
                }, ';'),
                sked_Resource_Role_Group__c = 'Staff roles;Supervisory roles',
                sked_Location__c = testLocationId,
                sked_Variation_Amount__c = 15,
                sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_SUBTRACT,
                sked_Variation_Type__c = 'Safety Video',
                sked_Days_Of_Week__c = 'Tuesday;Sunday'
            )
        };

        List<skedRoleTimeVarianceAdjustment> adjustments = skedRoleTimeVarianceUtils.getAdjustmentsToModifyBufferForRelatedJobs(
            new List<sked_Role_Time_Variance__c> {
                newRtv
            },
            rtvOldMap
        );

        System.assertEquals(9, adjustments.size());
    }

    @isTest
    static void testGetAdjustmentsToModifyBufferForRelatedJobs_EffectiveDateChangedIncreasingRange() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        Id testLocationId = mapTestData.get('testLocation1').Id;

        skedHubBase.setBypassAllTriggers(true);
        sked_Role_Time_Variance__c newRtv = new sked_Role_Time_Variance__c(
            sked_Effective_Start_Date__c = Date.today(),
            sked_Effective_End_Date__c = Date.today().addDays(4),
            sked_Variance_Applies_to__c = String.join(new List<String>{
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME
            }, ';'),
            sked_Resource_Role_Group__c = 'Staff roles;Driving roles',
            sked_Location__c = testLocationId,
            sked_Variation_Amount__c = 30,
            sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD,
            sked_Variation_Type__c = 'Safety Video',
            sked_Days_Of_Week__c = 'Monday'
        );
        insert newRtv;
        skedHubBase.setBypassAllTriggers(false);

        Map<Id, sked_Role_Time_Variance__c> rtvOldMap = new Map<Id, sked_Role_Time_Variance__c> {
            newRtv.Id => new sked_Role_Time_Variance__c(
                sked_Effective_Start_Date__c = Date.today().addDays(1),
                sked_Effective_End_Date__c = Date.today().addDays(2),
                sked_Variance_Applies_to__c = String.join(new List<String>{
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME
                }, ';'),
                sked_Resource_Role_Group__c = 'Staff roles;Driving roles',
                sked_Location__c = testLocationId,
                sked_Variation_Amount__c = 30,
                sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD,
                sked_Variation_Type__c = 'Safety Video',
                sked_Days_Of_Week__c = 'Monday'
            )
        };

        List<skedRoleTimeVarianceAdjustment> adjustments = skedRoleTimeVarianceUtils.getAdjustmentsToModifyBufferForRelatedJobs(
            new List<sked_Role_Time_Variance__c> {
                newRtv
            },
            rtvOldMap
        );

        System.assertEquals(3, adjustments.size());
    }

    @isTest
    static void testGetAdjustmentsToModifyBufferForRelatedJobs_EffectiveDateChangedDecreasingRange() {
        skedTestDataFactory testDataFactory = new skedTestDataFactory('us', 14);
        Map<String, sObject> mapTestData = testDataFactory.setupCommonTestData();
        Id testLocationId = mapTestData.get('testLocation1').Id;

        skedHubBase.setBypassAllTriggers(true);
        sked_Role_Time_Variance__c newRtv = new sked_Role_Time_Variance__c(
            sked_Effective_Start_Date__c = Date.today().addDays(1),
            sked_Effective_End_Date__c = Date.today().addDays(2),
            sked_Variance_Applies_to__c = String.join(new List<String>{
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
                skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME
            }, ';'),
            sked_Resource_Role_Group__c = 'Staff roles;Driving roles',
            sked_Location__c = testLocationId,
            sked_Variation_Amount__c = 30,
            sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD,
            sked_Variation_Type__c = 'Safety Video',
            sked_Days_Of_Week__c = 'Monday'
        );
        insert newRtv;
        skedHubBase.setBypassAllTriggers(false);

        Map<Id, sked_Role_Time_Variance__c> rtvOldMap = new Map<Id, sked_Role_Time_Variance__c> {
            newRtv.Id => new sked_Role_Time_Variance__c(
                sked_Effective_Start_Date__c = Date.today(),
                sked_Effective_End_Date__c = Date.today().addDays(4),
                sked_Variance_Applies_to__c = String.join(new List<String>{
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_LEAD_TIME,
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_SETUP_TIME,
                    skedConstants.ROLE_TIME_VARIANCE_APPLIES_TO_BREAKDOWN_TIME
                }, ';'),
                sked_Resource_Role_Group__c = 'Staff roles;Driving roles',
                sked_Location__c = testLocationId,
                sked_Variation_Amount__c = 30,
                sked_Buffer_Type__c = skedConstants.ROLE_TIME_VARIANCE_BUFFER_ADD,
                sked_Variation_Type__c = 'Safety Video',
                sked_Days_Of_Week__c = 'Monday'
            )
        };

        List<skedRoleTimeVarianceAdjustment> adjustments = skedRoleTimeVarianceUtils.getAdjustmentsToModifyBufferForRelatedJobs(
            new List<sked_Role_Time_Variance__c> {
                newRtv
            },
            rtvOldMap
        );

        System.assertEquals(3, adjustments.size());
    }
}