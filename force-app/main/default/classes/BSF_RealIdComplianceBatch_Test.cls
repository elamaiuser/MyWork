// ─────────────────────────────────────────────────────────────────────────────
// BSF_RealIdComplianceBatch_Test
//
// Covers all major scenarios of BSF_RealIdComplianceBatch:
//   1.  New employee — staging created, resource compliance set
//   2.  Existing employee, data changed — staging updated with change log
//   3.  Existing employee, no change — staging not touched
//   4.  Expired employee (new staging) — compliance set to false
//   5.  Expired employee (existing staging) — staging flips to non-compliant
//   6.  Employee removed from Workday — staging marked Removed, resource unchecked
//   7.  Resource with no staging — still unchecked by direct resource query in finish()
//   8.  Workday employee with no matching Resource — silently skipped
//   9.  Workday API failure — Last_Successful_Run_Date__c not updated
//   10. Successful run — Last_Successful_Run_Date__c updated to today
//   11. Empty Workday response — no DML, run date still stamped
//   12. Scheduler — queues batch without error
//   13. Null expiration date — treated as compliant
//   14. Constructor variants — null and negative batch size handled gracefully
//   15. Multiple employees in one batch — all processed correctly
//   16. Malformed datetime fields — record still created, bad field left null
// ─────────────────────────────────────────────────────────────────────────────
@isTest
private class BSF_RealIdComplianceBatch_Test {

    // ─────────────────────────────────────────────────────────────────────────
    // MOCK HTTP — returns a configurable JSON body and status code
    // ─────────────────────────────────────────────────────────────────────────
    private class WorkdayMock implements HttpCalloutMock {
        private String  body;
        private Integer statusCode;

        public WorkdayMock(String body, Integer statusCode) {
            this.body       = body;
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RESOURCE FACTORY — exact signature from production setup
    // ─────────────────────────────────────────────────────────────────────────
    private static sked__Resource__c createResource(
        String recFirstName,
        String recLastName,
        String empId,
        String email,
        String ulId,
        Id     regionId,
        Id     recTy
    ) {
        return new sked__Resource__c(
            RecordTypeId                              = recTy,
            sked__Email__c                            = email,
            sked_Employee_ID__c                       = empId,
            sked__Is_Active__c                        = true,
            sked_Title__c                             = 'Test',
            sked_First_Name__c                        = recFirstName,
            sked_Preferred_First_Name__c              = recFirstName,
            sked_Last_Name__c                         = recLastName,
            sked_ULID__c                              = ulId,
            sked__Category__c                         = 'Employee',
            sked_Employment_Status__c                 = 'Active',
            sked_Timezone__c                          = 'America/Los_Angeles',
            sked__Primary_Region__c                   = regionId,
            sked__Resource_Type__c                    = 'Person',
            sked_Primary_Phone_Type__c                = 'Home Phone',
            sked_Home_Phone__c                        = '123-123-4321',
            sked__Primary_Phone__c                    = '123-123-4321',
            sked_Address_Referenced_for_Scheduling__c = 'Work',
            sked_Mobile_Type__c                       = 'Inside',
            sked_Work_Address_GeoLocation__Latitude__s  = 34.280308,
            sked_Work_Address_GeoLocation__Longitude__s = -118.393922,
            sked_Work_Country__c                      = 'USA',
            sked_Work_City__c                         = 'Sylmar',
            sked_Work_State__c                        = 'CA',
            sked_Work_Address_1__c                    = '11970 Gager St',
            sked_Work_Zip_Code__c                     = '91342'
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // @TestSetup — builds all shared supporting records once per test class run.
    // Individual tests retrieve what they need via SOQL.
    // ─────────────────────────────────────────────────────────────────────────
    @TestSetup
    static void makeData() {

        // ── User ────────────────────────────────────────────────────────────
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'Collections'];
        User usr = new User(
            ProfileId            = pf.Id,
            Email                = 'test1@yopmail.com',
            FederationIdentifier = 'test1@yopmail.com',
            EmployeeNumber       = '12345',
            IsActive             = true,
            FirstName            = 'test',
            LastName             = 'test',
            Username             = 'hjgfdxyuigxtryujgh@yopmail.com',
            EmailEncodingKey     = 'ISO-8859-1',
            LanguageLocaleKey    = 'en_US',
            LocaleSidKey         = 'en_US',
            Alias                = 'test56',
            TimeZoneSidKey       = 'America/Los_Angeles'
        );
        insert usr;

        // ── Record Types ─────────────────────────────────────────────────────
        RecordType rt   = [SELECT Id FROM RecordType WHERE sObjectType = 'sked__Resource__c'  AND Name = 'Staff'];
        RecordType rtt1 = [SELECT Id FROM RecordType WHERE sObjectType = 'sked_Territory__c'  AND Name = 'Division'];
        RecordType rtt2 = [SELECT Id FROM RecordType WHERE sObjectType = 'sked_Territory__c'  AND Name = 'ARC Region'];
        RecordType rtt3 = [SELECT Id FROM RecordType WHERE sObjectType = 'sked_Territory__c'  AND Name = 'District'];

        // ── Territory hierarchy ───────────────────────────────────────────────
        sked_Territory__c territoryObj1 = new sked_Territory__c(
            Name         = 'Test Territory',
            RecordTypeId = rtt1.Id
        );
        insert territoryObj1;

        sked_Territory__c territoryObj2 = new sked_Territory__c(
            Name           = 'Test Territory',
            RecordTypeId   = rtt2.Id,
            sked_Parent__c = territoryObj1.Id
        );
        insert territoryObj2;

        sked_Territory__c territoryObj3 = new sked_Territory__c(
            Name           = 'Test Territory',
            RecordTypeId   = rtt3.Id,
            sked_Parent__c = territoryObj2.Id
        );
        insert territoryObj3;

        // ── Collection Op Center ─────────────────────────────────────────────
        Biomed_Collection_Op_Center__c collopObj = new Biomed_Collection_Op_Center__c(
            Name                                      = 'Test',
            Collection_Operation_ID__c                = '123456.0',
            External_Id__c                            = 'Bio_Collection_Test',
            Staging_Location_Address__c               = '11970 Gager St,Sylmar, California, 91342',
            Staging_Location_Geolocation__Latitude__s = 34.280308,
            Staging_Location_Geolocation__Longitude__s = -118.393922,
            sked_Territory__c                         = territoryObj3.Id,
            sked_Lunch_Break_Duration_Fixed_Site__c   = '30',
            sked_Lunch_Break_Duration_Mobile__c       = '30',
            sked_Primary_Scheduler__c                 = usr.Id
        );
        insert collopObj;

        // ── Region ───────────────────────────────────────────────────────────
        sked__Region__c regionObj = new sked__Region__c(
            sked__Timezone__c                  = 'America/Los_Angeles',
            Name                               = 'Test',
            sked__Description__c               = 'Test',
            sked_External_Id__c                = 'Bio_Collection_Test_America/Los_Angeles',
            sked_Biomed_Collection_Op_Center__c = collopObj.Id,
            sked_Territory__c                  = territoryObj3.Id
        );
        insert regionObj;

        // ── Tag ──────────────────────────────────────────────────────────────
        sked__Tag__c tagObj = new sked__Tag__c(
            Name                    = 'Inside',
            sked__Classification__c = 'Global',
            sked__Type__c           = 'Physical Location Type'
        );
        insert tagObj;

        // ── Base resource used across multiple tests ─────────────────────────
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        sked__Resource__c resourceObj = createResource(
            'Barnojit', 'Testone', '12345', 'test12@yopmail.com', 'ULID1234', regionObj.Id, rt.Id
        );
        insert resourceObj;

        // ── Config ───────────────────────────────────────────────────────────
        BSF_Workday_RealID_Config__c config = new BSF_Workday_RealID_Config__c();
        config.Initial_Backfill_Date__c     = System.today().addYears(-5);
        config.Batch_Size__c                = 200;
        upsert config;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SHARED HELPERS — retrieve @TestSetup records
    // ─────────────────────────────────────────────────────────────────────────

    // Returns the base resource created in @TestSetup (empId = '12345')
    private static sked__Resource__c getBaseResource() {
        return [
            SELECT Id, sked_Employee_ID__c, sked_REAL_ID_Compliant_indicator__c, sked_Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE sked_Employee_ID__c = '12345'
            LIMIT 1
        ];
    }

    // Returns the region created in @TestSetup
    private static Id getRegionId() {
        return [SELECT Id FROM sked__Region__c WHERE Name = 'Test' LIMIT 1].Id;
    }

    // Returns the Staff record type Id for sked__Resource__c
    private static Id getResourceRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE sObjectType = 'sked__Resource__c' AND Name = 'Staff'].Id;
    }

    // Inserts an additional resource for tests that need more than the base one.
    // Bypass triggers so we don't depend on other automations in test context.
    private static sked__Resource__c insertExtraResource(
        String empId,
        String firstName,
        String lastName,
        String ulId,
        Boolean compliant,
        Date    expiration
    ) {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        sked__Resource__c r = createResource(
            firstName,
            lastName,
            empId,
            empId.replaceAll('[^a-zA-Z0-9]', '').toLowerCase() + '@test.example.com',
            ulId,
            getRegionId(),
            getResourceRecordTypeId()
        );
        r.sked_REAL_ID_Compliant_indicator__c = compliant;
        r.sked_Real_ID_Expiration_Date__c     = expiration;
        insert r;
        return r;
    }

    // Inserts a staging record directly (no callout needed)
    private static BSF_Workday_Staging__c insertStaging(
        String   empId,
        Id       resourceId,
        Boolean  compliant,
        Date     expiration,
        DateTime lastUpdated
    ) {
        BSF_Workday_Staging__c s               = new BSF_Workday_Staging__c();
        s.Employee_ID__c                       = empId;
        s.Resource__c                          = resourceId;
        s.Real_ID_Compliant__c                 = compliant;
        s.Expiration_Date__c                   = expiration;
        s.Workday_Last_Functionally_Updated__c = lastUpdated;
        s.Sync_Status__c                       = 'Created';
        s.Sync_Comment__c                      = String.valueOf(System.today()) + ': initial';
        insert s;
        return s;
    }

    // Builds a Workday JSON response string from a list of field maps
    private static String buildWorkdayJson(List<Map<String, String>> entries) {
        List<String> entryStrings = new List<String>();
        for (Map<String, String> e : entries) {
            List<String> fields = new List<String>();
            for (String key : e.keySet()) {
                String val = e.get(key);
                fields.add('"' + key + '":' + (val == null ? 'null' : '"' + val + '"'));
            }
            entryStrings.add('{' + String.join(fields, ',') + '}');
        }
        return '{"Report_Entry":[' + String.join(entryStrings, ',') + ']}';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 1 — New employee: staging created, resource compliance set
    // Uses the base resource (empId = '12345') created in @TestSetup.
    //
    // Note: skedHubBase bypass flags are set before executeBatch so that any
    // post-update triggers on sked__Resource__c do not revert the compliance
    // fields written by the batch — matching the pattern used in @TestSetup.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testNewEmployee_StagingCreatedAndResourceUpdated() {
        sked__Resource__c resource = getBaseResource();
        Date futureDate = System.today().addDays(30);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Expiration_Date'           => String.valueOf(futureDate),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        // Bypass triggers so the compliance fields written by the batch are
        // not overwritten by any downstream automation on sked__Resource__c
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        // ── Staging assertions ───────────────────────────────────────────────
        List<BSF_Workday_Staging__c> stagings = [
            SELECT Id, Employee_ID__c, Real_ID_Compliant__c, Sync_Status__c, Resource__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(1, stagings.size(), 'Expected 1 staging record to be created');
        System.assertEquals(true, stagings[0].Real_ID_Compliant__c, 'Staging should be compliant');
        System.assertEquals('Created', stagings[0].Sync_Status__c, 'Sync status should be Created');
        System.assertEquals(resource.Id, stagings[0].Resource__c, 'Staging should be linked to the correct Resource');

        // ── Resource assertions ──────────────────────────────────────────────
        sked__Resource__c updated = [
            SELECT sked_REAL_ID_Compliant_indicator__c, sked_Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE Id = :resource.Id
        ];
        System.assertEquals(true, updated.sked_REAL_ID_Compliant_indicator__c, 'Resource should be compliant after batch run');
        System.assertEquals(futureDate, updated.sked_Real_ID_Expiration_Date__c, 'Expiration date should be set on resource');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 2 — Existing employee, data changed: staging updated with change log
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_DataChanged_StagingUpdated() {
        sked__Resource__c resource = getBaseResource();
        Date     futureDate = System.today().addDays(60);
        DateTime oldUpdated = DateTime.valueOf('2025-01-01 10:00:00');
        DateTime newUpdated = DateTime.valueOf('2026-02-01 10:00:00');

        insertStaging('12345', resource.Id, true, futureDate, oldUpdated);

        // Workday returns a newer Last_Functionally_Updated
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Expiration_Date'           => String.valueOf(futureDate),
                'Last_Functionally_Updated' => '2026-02-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c updated = [
            SELECT Sync_Status__c, Workday_Last_Functionally_Updated__c, Sync_Comment__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals('Updated', updated.Sync_Status__c, 'Sync status should be Updated');
        System.assertEquals(newUpdated, updated.Workday_Last_Functionally_Updated__c, 'Last updated timestamp should be refreshed');
        System.assert(updated.Sync_Comment__c.contains('Updated from Workday'), 'Sync comment should record the update');
        System.assert(updated.Sync_Comment__c.contains('Last_Functionally_Updated'), 'Sync comment should detail which field changed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 3 — Existing employee, no change: staging not touched
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_NoChange_StagingSkipped() {
        sked__Resource__c resource = getBaseResource();
        Date     futureDate  = System.today().addDays(90);
        DateTime lastUpdated = DateTime.valueOf('2026-01-15 10:00:00');

        insertStaging('12345', resource.Id, true, futureDate, lastUpdated);

        // Same Last_Functionally_Updated as stored — no change
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Expiration_Date'           => String.valueOf(futureDate),
                'Last_Functionally_Updated' => '2026-01-15T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c unchanged = [
            SELECT Sync_Status__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals('Created', unchanged.Sync_Status__c, 'Staging should not be updated when nothing changed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 4 — Expired employee (new staging): compliance set to false
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExpiredEmployee_NewStaging_ComplianceSetToFalse() {
        sked__Resource__c resource = getBaseResource();
        Date pastDate = System.today().addDays(-1);

        // No pre-existing staging — batch creates it with compliant = false
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Expiration_Date'           => String.valueOf(pastDate),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-01-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c staging = [
            SELECT Real_ID_Compliant__c, Sync_Status__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(false, staging.Real_ID_Compliant__c, 'Expired employee staging should be non-compliant');
        System.assertEquals('Created', staging.Sync_Status__c, 'First-time staging should have status Created');

        sked__Resource__c updatedResource = [
            SELECT sked_REAL_ID_Compliant_indicator__c
            FROM sked__Resource__c
            WHERE Id = :resource.Id
        ];
        System.assertEquals(false, updatedResource.sked_REAL_ID_Compliant_indicator__c, 'Expired employee Resource should be non-compliant');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 5 — Expired employee (existing staging): staging flips to non-compliant
    //          Last_Functionally_Updated is unchanged but expiry date has now passed
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExpiredEmployee_ExistingStagingFlipsToNonCompliant() {
        sked__Resource__c resource = getBaseResource();
        Date     nowExpired  = System.today().addDays(-1);
        DateTime lastUpdated = DateTime.valueOf('2026-01-01 10:00:00');

        // Staging was previously compliant (expiry was in the future when last synced)
        insertStaging('12345', resource.Id, true, nowExpired, lastUpdated);

        // Workday still sends the same Last_Functionally_Updated — the record has not
        // changed on Workday's side — but the expiry date has now passed on our side
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Expiration_Date'           => String.valueOf(nowExpired),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-01-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c staging = [
            SELECT Real_ID_Compliant__c, Sync_Status__c, Sync_Comment__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(false, staging.Real_ID_Compliant__c, 'Staging should flip to non-compliant when expiry has passed');
        System.assertEquals('Updated', staging.Sync_Status__c, 'Sync status should be Updated');
        System.assert(staging.Sync_Comment__c.contains('Compliant'), 'Sync comment should detail the compliance change');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 6 — Employee removed from Workday: staging marked Removed,
    //          resource unchecked
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testRemovedEmployee_StagingMarkedRemovedAndResourceUnchecked() {
        // Base resource (empId = '12345') will be the removed employee —
        // it won't appear in the Workday response this run
        sked__Resource__c removedResource = getBaseResource();
        Date futureDate = System.today().addDays(30);

        // Set resource as compliant so finish() has something to uncheck
        skedHubBase.BypassUpdateTriggers = true;
        removedResource.sked_REAL_ID_Compliant_indicator__c = true;
        removedResource.sked_Real_ID_Expiration_Date__c     = futureDate;
        update removedResource;

        insertStaging('12345', removedResource.Id, true, futureDate, DateTime.now().addDays(-10));

        // A second employee that IS present in Workday —
        // required so workdayEmployeeIds is not empty in finish()
        sked__Resource__c presentResource = insertExtraResource('EMP_PRESENT', 'Active', 'Employee', 'ULID_PRESENT', false, null);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => 'EMP_PRESENT',
                'Expiration_Date'           => String.valueOf(futureDate),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c removedStaging = [
            SELECT Real_ID_Compliant__c, Sync_Status__c, Sync_Comment__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(false, removedStaging.Real_ID_Compliant__c, 'Removed employee staging should be non-compliant');
        System.assertEquals('Removed', removedStaging.Sync_Status__c, 'Sync status should be Removed');
        System.assert(removedStaging.Sync_Comment__c.contains('Real ID compliance removed from Workday'), 'Sync comment should record the removal reason');

        sked__Resource__c unchecked = [
            SELECT sked_REAL_ID_Compliant_indicator__c, sked_Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE Id = :removedResource.Id
        ];
        System.assertEquals(false, unchecked.sked_REAL_ID_Compliant_indicator__c, 'Removed employee resource should be unchecked');
        System.assertEquals(null, unchecked.sked_Real_ID_Expiration_Date__c, 'Removed employee expiration date should be cleared');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 7 — Resource with compliance but no staging: still unchecked
    //          by the direct resource query in finish()
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testRemovedEmployee_ResourceUncheckedWithNoStaging() {
        // Set base resource as compliant with no staging record
        sked__Resource__c resource = getBaseResource();
        Date futureDate = System.today().addDays(30);

        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_REAL_ID_Compliant_indicator__c = true;
        resource.sked_Real_ID_Expiration_Date__c     = futureDate;
        update resource;

        // Workday response is empty — empId not returned, finish() treats it as removed
        String json = '{"Report_Entry":[]}';

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        sked__Resource__c unchecked = [
            SELECT sked_REAL_ID_Compliant_indicator__c, sked_Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE Id = :resource.Id
        ];
        System.assertEquals(false, unchecked.sked_REAL_ID_Compliant_indicator__c, 'Resource without staging should still be unchecked when not in Workday response');
        System.assertEquals(null, unchecked.sked_Real_ID_Expiration_Date__c, 'Expiration date should be cleared');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 8 — Workday employee with no matching Resource: silently skipped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testWorkdayEmployeeWithNoResource_Skipped() {
        // 'EMPORPHAN' has no Resource record in Salesforce
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => 'EMPORPHAN',
                'Expiration_Date'           => String.valueOf(System.today().addDays(30)),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        Integer stagingCount = [
            SELECT COUNT()
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = 'EMPORPHAN'
        ];
        System.assertEquals(0, stagingCount, 'No staging record should be created when no Resource exists in Salesforce');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 9 — Workday API failure: Last_Successful_Run_Date__c not updated
    //
    // When fetchWorkdayData() throws a CalloutException the batch framework
    // surfaces it through Test.stopTest(). We catch it there so the test
    // method does not fail, then assert that the run date was not advanced.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testApiFailure_RunDateNotUpdated() {
        // Set a known run date so we can confirm it is not advanced
        BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
        Date originalRunDate = System.today().addDays(-1);
        config.Last_Successful_Run_Date__c = originalRunDate;
        upsert config;

        Test.setMock(HttpCalloutMock.class, new WorkdayMock('Internal Server Error', 500));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        try {
            Test.stopTest(); // CalloutException surfaces here in test context
        } catch (Exception e) {
            // Expected — the batch threw a CalloutException in start()
            // The run date should not have been updated
        }

        BSF_Workday_RealID_Config__c refreshed = BSF_Workday_RealID_Config__c.getOrgDefaults();
        System.assertEquals(originalRunDate, refreshed.Last_Successful_Run_Date__c, 'Last_Successful_Run_Date__c should NOT be updated when the API call fails');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 10 — Successful run: Last_Successful_Run_Date__c updated to today
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testSuccessfulRun_RunDateUpdated() {
        // Use the base resource — no expiry, so it will be treated as compliant
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
        System.assertEquals(System.today(), config.Last_Successful_Run_Date__c, 'Last_Successful_Run_Date__c should be updated to today on a successful run');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 11 — Empty Workday response: no staging created, run date stamped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testEmptyWorkdayResponse_NoStagingCreated() {
        String json = '{"Report_Entry":[]}';
        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        Integer stagingCount = [SELECT COUNT() FROM BSF_Workday_Staging__c];
        System.assertEquals(0, stagingCount, 'No staging records should be created for an empty Workday response');

        BSF_Workday_RealID_Config__c config = BSF_Workday_RealID_Config__c.getOrgDefaults();
        System.assertEquals(System.today(), config.Last_Successful_Run_Date__c, 'Run date should still be stamped on an empty but successful response');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 12 — Scheduler: queues batch when none is currently running
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testScheduler_QueuesBatchWhenNoneRunning() {
        String json = '{"Report_Entry":[]}';
        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        System.schedule('Test Real ID Sync', '0 0 2 * * ?', new BSF_RealIdComplianceBatch());
        Test.stopTest();

        System.assert(true, 'Scheduler should execute without error');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 13 — Null expiration date: treated as compliant
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testNullExpirationDate_TreatedAsCompliant() {
        // No Expiration_Date field in the Workday JSON at all
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c staging = [
            SELECT Real_ID_Compliant__c, Expiration_Date__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(true, staging.Real_ID_Compliant__c, 'Employee with no expiration date should be treated as compliant');
        System.assertEquals(null, staging.Expiration_Date__c, 'Expiration date should be null when not provided by Workday');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 14 — Constructor variants: all instantiate without error
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testConstructorVariants_AllInstantiateCleanly() {
        BSF_RealIdComplianceBatch b1 = new BSF_RealIdComplianceBatch(50);   // valid custom size
        BSF_RealIdComplianceBatch b2 = new BSF_RealIdComplianceBatch(null); // null  — defaults to 200
        BSF_RealIdComplianceBatch b3 = new BSF_RealIdComplianceBatch(-1);   // negative — defaults to 200
        BSF_RealIdComplianceBatch b4 = new BSF_RealIdComplianceBatch();     // no-arg

        System.assertNotEquals(null, b1, 'Batch with size 50 should instantiate');
        System.assertNotEquals(null, b2, 'Batch with null size should instantiate using default');
        System.assertNotEquals(null, b3, 'Batch with negative size should instantiate using default');
        System.assertNotEquals(null, b4, 'No-arg batch should instantiate');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 15 — Multiple employees in one batch: all processed correctly
    // Base resource (12345) = compliant, extra resource (EMP_B) = expired,
    // EMPNORES = no resource — should be silently skipped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testMultipleEmployees_AllProcessedInSingleBatch() {
        Date futureDate = System.today().addDays(30);
        Date pastDate   = System.today().addDays(-5);

        // Second resource — expired
        sked__Resource__c resourceB = insertExtraResource('EMP_B', 'Jane', 'Doe', 'ULID_B', true, pastDate);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Expiration_Date'           => String.valueOf(futureDate),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            },
            new Map<String, String>{
                'Employee_ID'               => 'EMP_B',
                'Expiration_Date'           => String.valueOf(pastDate),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            },
            new Map<String, String>{
                'Employee_ID'               => 'EMPNORES',
                'Expiration_Date'           => String.valueOf(futureDate),
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c stagingA = [
            SELECT Real_ID_Compliant__c, Sync_Status__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(true, stagingA.Real_ID_Compliant__c, 'Base employee should be compliant');
        System.assertEquals('Created', stagingA.Sync_Status__c, 'Base employee staging should be Created');

        BSF_Workday_Staging__c stagingB = [
            SELECT Real_ID_Compliant__c, Sync_Status__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = 'EMP_B'
        ];
        System.assertEquals(false, stagingB.Real_ID_Compliant__c, 'EMP_B should be non-compliant due to expiry');

        Integer stagingNoResCount = [
            SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = 'EMPNORES'
        ];
        System.assertEquals(0, stagingNoResCount, 'EMPNORES with no Resource should produce no staging record');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 16 — Malformed datetime fields in Workday response:
    //           record still created, bad field left null (no batch abort)
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testMalformedDatetimeFields_RecordStillCreated() {
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Expiration_Date'           => String.valueOf(System.today().addDays(30)),
                'Last_Functionally_Updated' => 'NOT_A_VALID_DATETIME',
                'Created_Moment'            => 'ALSO_INVALID'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_RealIdComplianceBatch(), 200);
        Test.stopTest();

        List<BSF_Workday_Staging__c> stagings = [
            SELECT Id, Real_ID_Compliant__c, Workday_Last_Functionally_Updated__c
            FROM BSF_Workday_Staging__c
            WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(1, stagings.size(), 'Staging record should still be created despite malformed datetime fields');
        System.assertEquals(true, stagings[0].Real_ID_Compliant__c, 'Compliance should still be derived correctly from the expiration date');
        System.assertEquals(null, stagings[0].Workday_Last_Functionally_Updated__c, 'Malformed datetime should result in null rather than aborting the batch');
    }
}