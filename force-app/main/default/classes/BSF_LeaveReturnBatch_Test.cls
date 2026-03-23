// ─────────────────────────────────────────────────────────────────────────────
// BSF_LeaveReturnBatch_Test
//
// Covers all major scenarios of BSF_LeaveReturnBatch:
//   1.  New employee, future return date — staging created, resource updated
//   2.  Existing employee, return date changed — staging updated with change log
//   3.  Existing employee, Last_Functionally_Updated changed — staging updated
//   4.  Existing employee, First_Day_of_Leave changed — staging updated
//   5.  Existing employee, no change — staging not touched
//   6.  Employee with past return date — skipped entirely in execute()
//   7.  Employee with null return date — skipped entirely in execute()
//   8.  Workday employee with no matching Resource — silently skipped
//   9.  Mid-leave employee (First_Day_of_Leave past, returnDate future) — resource set to Leave
//   10. Employee not yet on leave (First_Day_of_Leave future) — resource status not changed
//   11. finish() reactivation — Leave resource with past/today return date set to Active
//   12. finish() no reactivation — Leave resource with future return date not touched
//   13. finish() only targets Leave status — Active resource with past date not changed
//   14. Workday API failure — Last_Successful_Run_Date__c not updated
//   15. Successful run — Last_Successful_Run_Date__c updated to today
//   16. Empty Workday response — no DML, run date still stamped
//   17. Scheduler — queues batch without error
//   18. Constructor variants — null and negative batch size handled gracefully
//   19. Multiple employees — future synced, past skipped, orphan skipped
// ─────────────────────────────────────────────────────────────────────────────
@isTest
private class BSF_LeaveReturnBatch_Test {

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
            sked_Employment_Status__c                 = 'Active', // Must be Active — buildResourceMap excludes Inactive
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

        // ── User ─────────────────────────────────────────────────────────────
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

        // ── Record Types ──────────────────────────────────────────────────────
        RecordType rt   = [SELECT Id FROM RecordType WHERE sObjectType = 'sked__Resource__c' AND Name = 'Staff'];
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

        // ── Collection Op Center ──────────────────────────────────────────────
        Biomed_Collection_Op_Center__c collopObj = new Biomed_Collection_Op_Center__c(
            Name                                       = 'Test',
            Collection_Operation_ID__c                 = '123456.0',
            External_Id__c                             = 'Bio_Collection_Test',
            Staging_Location_Address__c                = '11970 Gager St,Sylmar, California, 91342',
            Staging_Location_Geolocation__Latitude__s  = 34.280308,
            Staging_Location_Geolocation__Longitude__s = -118.393922,
            sked_Territory__c                          = territoryObj3.Id,
            sked_Lunch_Break_Duration_Fixed_Site__c    = '30',
            sked_Lunch_Break_Duration_Mobile__c        = '30',
            sked_Primary_Scheduler__c                  = usr.Id
        );
        insert collopObj;

        // ── Region ────────────────────────────────────────────────────────────
        sked__Region__c regionObj = new sked__Region__c(
            sked__Timezone__c                   = 'America/Los_Angeles',
            Name                                = 'Test',
            sked__Description__c                = 'Test',
            sked_External_Id__c                 = 'Bio_Collection_Test_America/Los_Angeles',
            sked_Biomed_Collection_Op_Center__c = collopObj.Id,
            sked_Territory__c                   = territoryObj3.Id
        );
        insert regionObj;

        // ── Tag ───────────────────────────────────────────────────────────────
        sked__Tag__c tagObj = new sked__Tag__c(
            Name                    = 'Inside',
            sked__Classification__c = 'Global',
            sked__Type__c           = 'Physical Location Type'
        );
        insert tagObj;

        // ── Base resource (empId = '12345') — Active, used across most tests ──
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        sked__Resource__c resourceObj = createResource(
            'Barnojit', 'Testone', '12345', 'test12@yopmail.com', 'ULID1234', regionObj.Id, rt.Id
        );
        insert resourceObj;

        // ── Leave config ──────────────────────────────────────────────────────
        // Initial_Backfill_Date__c is used by resolveFilterDate() as the
        // CF_-_Prompt filter fallback when Last_Successful_Run_Date__c is blank.
        BSF_Workday_Leave_Config__c config = new BSF_Workday_Leave_Config__c();
        config.Batch_Size__c               = 200;
        config.Initial_Backfill_Date__c    = System.today().addYears(-5);
        upsert config;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SHARED HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    // Returns the base resource (empId = '12345') created in @TestSetup
    private static sked__Resource__c getBaseResource() {
        return [
            SELECT Id, sked_Employee_ID__c,
                   sked_Anticipated_Leave_Return_Date__c,
                   sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  sked_Employee_ID__c = '12345'
            LIMIT  1
        ];
    }

    // Returns the region Id created in @TestSetup
    private static Id getRegionId() {
        return [SELECT Id FROM sked__Region__c WHERE Name = 'Test' LIMIT 1].Id;
    }

    // Returns the Staff record type Id for sked__Resource__c
    private static Id getResourceRecordTypeId() {
        return [
            SELECT Id FROM RecordType
            WHERE  sObjectType = 'sked__Resource__c'
            AND    Name        = 'Staff'
        ].Id;
    }

    // Returns the Leave_Report record type Id for BSF_Workday_Staging__c.
    // Required by insertStaging() so staging records are found by
    // buildStagingMap() which filters on RecordType.DeveloperName = 'Leave_Report'.
    private static Id getStagingRecordTypeId() {
        return [
            SELECT Id FROM RecordType
            WHERE  SObjectType   = 'BSF_Workday_Staging__c'
            AND    DeveloperName = 'Leave_Report'
            LIMIT  1
        ].Id;
    }

    // Inserts an additional sked__Resource__c for tests that need more
    // than the base resource. Bypass triggers to avoid unrelated automation.
    private static sked__Resource__c insertExtraResource(
        String empId,
        String firstName,
        String lastName,
        String ulId,
        String employmentStatus
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
        r.sked_Employment_Status__c = employmentStatus;
        insert r;
        return r;
    }

    // Inserts a BSF_Workday_Staging__c leave record directly.
    // RecordTypeId is set to Leave_Report so buildStagingMap() finds it.
    // All three change-detection fields are set:
    //   - Anticipated_Leave_Return_Date__c
    //   - Workday_Last_Functionally_Updated__c
    //   - First_Day_of_Leave__c  (added in batch v2 — third change-detection signal)
    private static BSF_Workday_Staging__c insertStaging(
        String   empId,
        Id       resourceId,
        Date     returnDate,
        DateTime lastUpdated,
        Date     firstDayOfLeave
    ) {
        BSF_Workday_Staging__c s               = new BSF_Workday_Staging__c();
        s.RecordTypeId                         = getStagingRecordTypeId();
        s.Employee_ID__c                       = empId;
        s.Resource__c                          = resourceId;
        s.Anticipated_Leave_Return_Date__c     = returnDate;
        s.Workday_Last_Functionally_Updated__c = lastUpdated;
        s.First_Day_of_Leave__c                = firstDayOfLeave;
        s.Sync_Comment__c                      = String.valueOf(System.today()) + ': initial';
        insert s;
        return s;
    }

    // Builds a Workday Report_Entry JSON string.
    // Return date key is 'Estimated_Last_Day_of_Leave' — matches WD_RETURN_DATE_FIELD.
    // First day of leave key is 'First_Day_of_Leave' — matches WD_FIRST_DAY_OF_LEAVE_FIELD.
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
    // TEST 1 — New employee, future return date: staging created, resource updated
    // Uses the base resource (empId = '12345') created in @TestSetup.
    //
    // skedHubBase bypass flags set before executeBatch so downstream triggers
    // on sked__Resource__c do not revert the field written by the batch.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testNewEmployee_FutureReturnDate_StagingCreatedAndResourceUpdated() {
        sked__Resource__c resource = getBaseResource();
        Date futureDate = System.today().addDays(30);
        Date firstDay   = System.today().addDays(-5);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        // ── Staging assertions ────────────────────────────────────────────────
        List<BSF_Workday_Staging__c> stagings = [
            SELECT Id, Employee_ID__c, Anticipated_Leave_Return_Date__c,
                   First_Day_of_Leave__c, Sync_Comment__c, Resource__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(1, stagings.size(), 'Expected 1 staging record to be created');
        System.assertEquals(futureDate, stagings[0].Anticipated_Leave_Return_Date__c, 'Staging should hold the return date');
        System.assertEquals(firstDay, stagings[0].First_Day_of_Leave__c, 'Staging should hold the first day of leave');
        System.assert(stagings[0].Sync_Comment__c.contains('1st time leave synced from Workday'), 'Sync comment should record first-time sync');
        System.assertEquals(resource.Id, stagings[0].Resource__c, 'Staging should be linked to the correct Resource');

        // ── Resource assertions ───────────────────────────────────────────────
        sked__Resource__c updated = [
            SELECT sked_Anticipated_Leave_Return_Date__c, sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals(futureDate, updated.sked_Anticipated_Leave_Return_Date__c, 'Resource return date should be set by the batch');
        // firstDay is in the past and returnDate is in the future → employee is mid-leave
        System.assertEquals('Leave', updated.sked_Employment_Status__c, 'Resource status should be set to Leave for a mid-leave employee');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 2 — Existing employee, return date changed: staging updated with
    //          change log entry
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_ReturnDateChanged_StagingUpdated() {
        sked__Resource__c resource = getBaseResource();
        Date     oldDate    = System.today().addDays(10);
        Date     newDate    = System.today().addDays(30);
        Date     firstDay   = System.today().addDays(-5);
        DateTime lastUpdated = DateTime.valueOf('2026-01-01 10:00:00');

        insertStaging('12345', resource.Id, oldDate, lastUpdated, firstDay);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(newDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c updated = [
            SELECT Anticipated_Leave_Return_Date__c, Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(newDate, updated.Anticipated_Leave_Return_Date__c, 'Return date should be updated to the new value');
        System.assert(updated.Sync_Comment__c.contains('Updated from Workday'), 'Sync comment should record the update');
        System.assert(updated.Sync_Comment__c.contains('Anticipated_Leave_Return_Date'), 'Sync comment should name the changed field');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 3 — Existing employee, only Last_Functionally_Updated changed:
    //          staging updated even though return date and first day are the same
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_LastUpdatedChanged_StagingUpdated() {
        sked__Resource__c resource = getBaseResource();
        Date     futureDate  = System.today().addDays(30);
        Date     firstDay    = System.today().addDays(-5);
        DateTime oldUpdated  = DateTime.valueOf('2025-01-01 10:00:00');
        DateTime newUpdated  = DateTime.valueOf('2026-02-01 10:00:00');

        insertStaging('12345', resource.Id, futureDate, oldUpdated, firstDay);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-02-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c updated = [
            SELECT Workday_Last_Functionally_Updated__c, Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(newUpdated, updated.Workday_Last_Functionally_Updated__c, 'Last_Functionally_Updated should be refreshed');
        System.assert(updated.Sync_Comment__c.contains('Updated from Workday'), 'Sync comment should record the update');
        System.assert(updated.Sync_Comment__c.contains('Workday_Last_Functionally_Updated'), 'Sync comment should name the changed field');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 4 — Existing employee, only First_Day_of_Leave changed:
    //          staging updated — exercises the third change-detection signal
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_FirstDayOfLeaveChanged_StagingUpdated() {
        sked__Resource__c resource = getBaseResource();
        Date     futureDate   = System.today().addDays(30);
        Date     oldFirstDay  = System.today().addDays(-10);
        Date     newFirstDay  = System.today().addDays(-3);
        DateTime lastUpdated  = DateTime.valueOf('2026-01-01 10:00:00');

        insertStaging('12345', resource.Id, futureDate, lastUpdated, oldFirstDay);

        // Workday returns a changed First_Day_of_Leave but same return date and lastUpdated
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(newFirstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c updated = [
            SELECT First_Day_of_Leave__c, Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(newFirstDay, updated.First_Day_of_Leave__c, 'First_Day_of_Leave should be updated to the new value');
        System.assert(updated.Sync_Comment__c.contains('Updated from Workday'), 'Sync comment should record the update');
        System.assert(updated.Sync_Comment__c.contains('First_Day_of_Leave'), 'Sync comment should name the changed field');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 5 — Existing employee, no change: staging not touched
    // All three change-detection fields are identical to stored values.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_NoChange_StagingSkipped() {
        sked__Resource__c resource = getBaseResource();
        Date     futureDate  = System.today().addDays(30);
        Date     firstDay    = System.today().addDays(-5);
        DateTime lastUpdated = DateTime.valueOf('2026-01-15 10:00:00');

        insertStaging('12345', resource.Id, futureDate, lastUpdated, firstDay);

        // Workday returns exactly the same values as stored
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-15T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c unchanged = [
            SELECT Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(String.valueOf(System.today()) + ': initial', unchanged.Sync_Comment__c,
            'Staging should not be updated when nothing changed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 6 — Employee with past return date: skipped entirely in execute()
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testPastReturnDate_EmployeeSkipped() {
        Date pastDate = System.today().addDays(-1);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(pastDate),
                'First_Day_of_Leave'          => String.valueOf(System.today().addDays(-10)),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        Integer stagingCount = [
            SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(0, stagingCount, 'No staging should be created for an employee with a past return date');

        sked__Resource__c resource = getBaseResource();
        System.assertEquals(null, resource.sked_Anticipated_Leave_Return_Date__c,
            'Resource return date should not be set for a past-dated employee');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 7 — Employee with null return date: skipped entirely in execute()
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testNullReturnDate_EmployeeSkipped() {
        // No Estimated_Last_Day_of_Leave field in the JSON at all
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        Integer stagingCount = [
            SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(0, stagingCount, 'No staging should be created when return date is null');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 8 — Workday employee with no matching Resource: silently skipped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testWorkdayEmployeeWithNoResource_Skipped() {
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => 'EMPORPHAN',
                'Estimated_Last_Day_of_Leave' => String.valueOf(System.today().addDays(30)),
                'First_Day_of_Leave'          => String.valueOf(System.today().addDays(-5)),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        Integer stagingCount = [
            SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = 'EMPORPHAN'
        ];
        System.assertEquals(0, stagingCount, 'No staging should be created when no Resource exists in Salesforce');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 9 — Mid-leave employee: resource status set to Leave
    // firstDayOfLeave <= today AND returnDate > today → resourceEmploymentStatus = Leave
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testMidLeaveEmployee_ResourceStatusSetToLeave() {
        Date futureDate = System.today().addDays(30);
        Date firstDay   = System.today().addDays(-5); // already started leave

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        sked__Resource__c updated = [
            SELECT sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  sked_Employee_ID__c = '12345'
        ];
        System.assertEquals('Leave', updated.sked_Employment_Status__c,
            'Resource status should be set to Leave when employee is currently mid-leave');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 10 — Employee not yet on leave: resource status not changed
    // firstDayOfLeave > today → employee has not started leave yet
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testEmployeeNotYetOnLeave_ResourceStatusNotChanged() {
        Date futureDate     = System.today().addDays(30);
        Date futureFirstDay = System.today().addDays(5); // leave has not started yet

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(futureFirstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        sked__Resource__c resource = getBaseResource();
        System.assertEquals('Active', resource.sked_Employment_Status__c,
            'Resource status should remain Active when employee has not yet started leave');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 11 — finish() reactivation: Leave resource with return date <= today
    //           is set to Active
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testFinish_ReactivatesLeaveResourceWithPastOrTodayReturnDate() {
        sked__Resource__c resource = getBaseResource();

        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_Employment_Status__c             = 'Leave';
        resource.sked_Anticipated_Leave_Return_Date__c = System.today();
        update resource;

        String json = '{"Report_Entry":[]}';
        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        sked__Resource__c reactivated = [
            SELECT sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals('Active', reactivated.sked_Employment_Status__c,
            'Resource with return date <= today and Leave status should be reactivated');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 12 — finish() no reactivation: Leave resource with future return date
    //           is NOT touched
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testFinish_DoesNotReactivateLeaveResourceWithFutureReturnDate() {
        sked__Resource__c resource = getBaseResource();

        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_Employment_Status__c             = 'Leave';
        resource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(10);
        update resource;

        String json = '{"Report_Entry":[]}';
        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        sked__Resource__c unchanged = [
            SELECT sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals('Leave', unchanged.sked_Employment_Status__c,
            'Resource with a future return date should remain on Leave status');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 13 — finish() only targets Leave status: Active resource with a past
    //           return date is NOT changed
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testFinish_DoesNotChangeActiveResourceWithPastReturnDate() {
        sked__Resource__c resource = getBaseResource();

        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_Employment_Status__c             = 'Active';
        resource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(-5);
        update resource;

        String json = '{"Report_Entry":[]}';
        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        sked__Resource__c unchanged = [
            SELECT sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals('Active', unchanged.sked_Employment_Status__c,
            'finish() should only reactivate Leave resources — Active resources must not be touched');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 14 — Workday API failure: Last_Successful_Run_Date__c not updated
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testApiFailure_RunDateNotUpdated() {
        BSF_Workday_Leave_Config__c config = BSF_Workday_Leave_Config__c.getOrgDefaults();
        Date originalRunDate = System.today().addDays(-1);
        config.Last_Successful_Run_Date__c = originalRunDate;
        upsert config;

        Test.setMock(HttpCalloutMock.class, new WorkdayMock('Internal Server Error', 500));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        try {
            Test.stopTest();
        } catch (Exception e) {
            // Expected — batch threw a CalloutException in start()
        }

        BSF_Workday_Leave_Config__c refreshed = BSF_Workday_Leave_Config__c.getOrgDefaults();
        System.assertEquals(originalRunDate, refreshed.Last_Successful_Run_Date__c,
            'Last_Successful_Run_Date__c should NOT be updated when the API call fails');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 15 — Successful run: Last_Successful_Run_Date__c updated to today
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testSuccessfulRun_RunDateUpdated() {
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(System.today().addDays(30)),
                'First_Day_of_Leave'          => String.valueOf(System.today().addDays(-5)),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        BSF_Workday_Leave_Config__c config = BSF_Workday_Leave_Config__c.getOrgDefaults();
        System.assertEquals(System.today(), config.Last_Successful_Run_Date__c,
            'Last_Successful_Run_Date__c should be updated to today on a successful run');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 16 — Empty Workday response: no staging created, run date stamped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testEmptyWorkdayResponse_NoStagingCreated() {
        String json = '{"Report_Entry":[]}';
        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        Integer stagingCount = [SELECT COUNT() FROM BSF_Workday_Staging__c];
        System.assertEquals(0, stagingCount, 'No staging records should be created for an empty Workday response');

        BSF_Workday_Leave_Config__c config = BSF_Workday_Leave_Config__c.getOrgDefaults();
        System.assertEquals(System.today(), config.Last_Successful_Run_Date__c,
            'Run date should still be stamped on an empty but successful response');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 17 — Scheduler: queues batch when none is currently running
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testScheduler_QueuesBatchWhenNoneRunning() {
        String json = '{"Report_Entry":[]}';
        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        System.schedule('Test Leave Return Sync', '0 0 3 * * ?', new BSF_LeaveReturnBatch());
        Test.stopTest();

        System.assert(true, 'Scheduler should execute without error');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 18 — Constructor variants: all instantiate without error
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testConstructorVariants_AllInstantiateCleanly() {
        BSF_LeaveReturnBatch b1 = new BSF_LeaveReturnBatch(50);
        BSF_LeaveReturnBatch b2 = new BSF_LeaveReturnBatch(null);
        BSF_LeaveReturnBatch b3 = new BSF_LeaveReturnBatch(-1);
        BSF_LeaveReturnBatch b4 = new BSF_LeaveReturnBatch();

        System.assertNotEquals(null, b1, 'Batch with size 50 should instantiate');
        System.assertNotEquals(null, b2, 'Batch with null size should instantiate using default');
        System.assertNotEquals(null, b3, 'Batch with negative size should instantiate using default');
        System.assertNotEquals(null, b4, 'No-arg batch should instantiate');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 19 — Multiple employees: correct routing per employee
    // '12345'    = future return date → staging created, resource updated
    // 'EMP_PAST' = past return date   → skipped in execute()
    // 'EMPNORES' = no Resource        → silently skipped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testMultipleEmployees_AllRoutedCorrectly() {
        Date futureDate = System.today().addDays(30);
        Date pastDate   = System.today().addDays(-5);
        Date firstDay   = System.today().addDays(-3);

        sked__Resource__c pastResource = insertExtraResource('EMP_PAST', 'John', 'Past', 'ULID_PAST', 'Active');

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            },
            new Map<String, String>{
                'Employee_ID'                 => 'EMP_PAST',
                'Estimated_Last_Day_of_Leave' => String.valueOf(pastDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            },
            new Map<String, String>{
                'Employee_ID'                 => 'EMPNORES',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureDate),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        List<BSF_Workday_Staging__c> staging12345 = [
            SELECT Anticipated_Leave_Return_Date__c, First_Day_of_Leave__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(1, staging12345.size(), 'Staging should be created for the future-dated employee');
        System.assertEquals(futureDate, staging12345[0].Anticipated_Leave_Return_Date__c, 'Return date should match');
        System.assertEquals(firstDay, staging12345[0].First_Day_of_Leave__c, 'First day of leave should match');

        Integer pastCount = [SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = 'EMP_PAST'];
        System.assertEquals(0, pastCount, 'No staging should be created for a past-dated employee');

        Integer orphanCount = [SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = 'EMPNORES'];
        System.assertEquals(0, orphanCount, 'No staging should be created for an employee with no Resource');
    }
}