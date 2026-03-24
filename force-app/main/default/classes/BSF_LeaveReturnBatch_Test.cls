// ─────────────────────────────────────────────────────────────────────────────
// BSF_LeaveReturnBatch_Test
//
// Covers all major scenarios of BSF_LeaveReturnBatch:
//   1.  New employee, future return date — staging created, resource updated
//   2.  Existing employee, return date changed — staging updated with change log
//   3.  Existing employee, Last_Functionally_Updated changed — staging updated
//   4.  Existing employee, First_Day_of_Leave changed — staging updated
//   5.  Existing employee, no change — staging not touched
//   6.  Employee with past Estimated_Last_Day_of_Leave — treated as Active,
//       staging created, resource return date cleared to null
//   7.  Employee with null return date — treated as Active,
//       staging created (if resource exists), resource return date cleared
//   8.  Workday employee with no matching Resource — silently skipped
//   9.  Mid-leave employee (First_Day_of_Leave past, returnDate future) — resource set to Leave
//   10. Employee not yet on leave (First_Day_of_Leave future) — resource status stays Active
//   11. finish() reactivation — Leave resource with past/today return date set to Active
//   12. finish() no reactivation — Leave resource with future return date not touched
//   13. finish() only targets Leave status — Active resource with past date not changed
//   14. Workday API failure — Last_Successful_Run_Date__c not updated
//   15. Successful run — Last_Successful_Run_Date__c updated to today
//   16. Empty Workday response — no DML, run date still stamped
//   17. Scheduler — queues batch without error
//   18. Constructor variants — null and negative batch size handled gracefully
//   19. Multiple employees — future synced, past treated as Active, orphan skipped
//   20. Inactive resource — not updated even when data changes
//   21. returnDate addDays(1) offset — stored date is Estimated_Last_Day_of_Leave + 1
//   22. Active resource with existing return date — return date cleared when reactivating
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
    // RESOURCE FACTORY
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
    // @TestSetup
    // ─────────────────────────────────────────────────────────────────────────
    @TestSetup
    static void makeData() {

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

        RecordType rt   = [SELECT Id FROM RecordType WHERE sObjectType = 'sked__Resource__c' AND Name = 'Staff'];
        RecordType rtt1 = [SELECT Id FROM RecordType WHERE sObjectType = 'sked_Territory__c'  AND Name = 'Division'];
        RecordType rtt2 = [SELECT Id FROM RecordType WHERE sObjectType = 'sked_Territory__c'  AND Name = 'ARC Region'];
        RecordType rtt3 = [SELECT Id FROM RecordType WHERE sObjectType = 'sked_Territory__c'  AND Name = 'District'];

        sked_Territory__c territoryObj1 = new sked_Territory__c(Name = 'Test Territory', RecordTypeId = rtt1.Id);
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

        sked__Region__c regionObj = new sked__Region__c(
            sked__Timezone__c                   = 'America/Los_Angeles',
            Name                                = 'Test',
            sked__Description__c                = 'Test',
            sked_External_Id__c                 = 'Bio_Collection_Test_America/Los_Angeles',
            sked_Biomed_Collection_Op_Center__c = collopObj.Id,
            sked_Territory__c                   = territoryObj3.Id
        );
        insert regionObj;

        sked__Tag__c tagObj = new sked__Tag__c(
            Name                    = 'Inside',
            sked__Classification__c = 'Global',
            sked__Type__c           = 'Physical Location Type'
        );
        insert tagObj;

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        sked__Resource__c resourceObj = createResource(
            'Barnojit', 'Testone', '12345', 'test12@yopmail.com', 'ULID1234', regionObj.Id, rt.Id
        );
        insert resourceObj;

        BSF_Workday_Leave_Config__c config = new BSF_Workday_Leave_Config__c();
        config.Batch_Size__c               = 200;
        config.Initial_Backfill_Date__c    = System.today().addYears(-5);
        upsert config;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // SHARED HELPERS
    // ─────────────────────────────────────────────────────────────────────────

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

    private static Id getRegionId() {
        return [SELECT Id FROM sked__Region__c WHERE Name = 'Test' LIMIT 1].Id;
    }

    private static Id getResourceRecordTypeId() {
        return [
            SELECT Id FROM RecordType
            WHERE  sObjectType = 'sked__Resource__c'
            AND    Name        = 'Staff'
        ].Id;
    }

    private static Id getStagingRecordTypeId() {
        return [
            SELECT Id FROM RecordType
            WHERE  SObjectType   = 'BSF_Workday_Staging__c'
            AND    DeveloperName = 'Leave_Report'
            LIMIT  1
        ].Id;
    }

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
    // 'Estimated_Last_Day_of_Leave' is the LAST day of leave — the batch
    // adds 1 day to derive the actual return date stored in Salesforce.
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
    //
    // The batch adds 1 day to Estimated_Last_Day_of_Leave to get returnDate.
    // So we pass lastDayOfLeave in the JSON and assert on lastDayOfLeave + 1.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testNewEmployee_FutureReturnDate_StagingCreatedAndResourceUpdated() {
        sked__Resource__c resource = getBaseResource();
        Date lastDayOfLeave = System.today().addDays(29); // batch will store +1 = today+30
        Date expectedReturn = lastDayOfLeave.addDays(1);
        Date firstDay       = System.today().addDays(-5);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
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

        List<BSF_Workday_Staging__c> stagings = [
            SELECT Id, Employee_ID__c, Anticipated_Leave_Return_Date__c,
                   First_Day_of_Leave__c, Sync_Comment__c, Resource__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(1, stagings.size(), 'Expected 1 staging record to be created');
        System.assertEquals(expectedReturn, stagings[0].Anticipated_Leave_Return_Date__c,
            'Staging return date should be Estimated_Last_Day_of_Leave + 1 day');
        System.assertEquals(firstDay, stagings[0].First_Day_of_Leave__c,
            'Staging should hold the first day of leave');
        System.assert(stagings[0].Sync_Comment__c.contains('1st time leave synced from Workday'),
            'Sync comment should record first-time sync');
        System.assertEquals(resource.Id, stagings[0].Resource__c,
            'Staging should be linked to the correct Resource');

        sked__Resource__c updated = [
            SELECT sked_Anticipated_Leave_Return_Date__c, sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals(expectedReturn, updated.sked_Anticipated_Leave_Return_Date__c,
            'Resource return date should be Estimated_Last_Day_of_Leave + 1 day');
        System.assertEquals('Leave', updated.sked_Employment_Status__c,
            'Resource status should be Leave for a mid-leave employee');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 2 — Existing employee, return date changed: staging updated with
    //          change log entry.
    //
    // insertStaging stores expectedOldReturn (already the +1 value).
    // Workday sends a new lastDayOfLeave; batch computes expectedNewReturn = +1.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_ReturnDateChanged_StagingUpdated() {
        sked__Resource__c resource   = getBaseResource();
        Date     expectedOldReturn   = System.today().addDays(11); // already stored as returnDate
        Date     newLastDayOfLeave   = System.today().addDays(29); // Workday sends this
        Date     expectedNewReturn   = newLastDayOfLeave.addDays(1);
        Date     firstDay            = System.today().addDays(-5);
        DateTime lastUpdated         = DateTime.valueOf('2026-01-01 10:00:00');

        insertStaging('12345', resource.Id, expectedOldReturn, lastUpdated, firstDay);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(newLastDayOfLeave),
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

        BSF_Workday_Staging__c updated = [
            SELECT Anticipated_Leave_Return_Date__c, Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(expectedNewReturn, updated.Anticipated_Leave_Return_Date__c,
            'Return date should be updated to Estimated_Last_Day_of_Leave + 1 day');
        System.assert(updated.Sync_Comment__c.contains('Updated from Workday'),
            'Sync comment should record the update');
        System.assert(updated.Sync_Comment__c.contains('Anticipated_Leave_Return_Date'),
            'Sync comment should name the changed field');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 3 — Existing employee, only Last_Functionally_Updated changed:
    //          staging updated even though return date and first day are the same
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_LastUpdatedChanged_StagingUpdated() {
        sked__Resource__c resource  = getBaseResource();
        Date     lastDayOfLeave     = System.today().addDays(29);
        Date     expectedReturn     = lastDayOfLeave.addDays(1);
        Date     firstDay           = System.today().addDays(-5);
        DateTime oldUpdated         = DateTime.valueOf('2025-01-01 10:00:00');
        DateTime newUpdated         = DateTime.valueOf('2026-02-01 10:00:00');

        insertStaging('12345', resource.Id, expectedReturn, oldUpdated, firstDay);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-02-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c updated = [
            SELECT Workday_Last_Functionally_Updated__c, Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(newUpdated, updated.Workday_Last_Functionally_Updated__c,
            'Last_Functionally_Updated should be refreshed');
        System.assert(updated.Sync_Comment__c.contains('Updated from Workday'),
            'Sync comment should record the update');
        System.assert(updated.Sync_Comment__c.contains('Workday_Last_Functionally_Updated'),
            'Sync comment should name the changed field');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 4 — Existing employee, only First_Day_of_Leave changed:
    //          staging updated — exercises the third change-detection signal
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_FirstDayOfLeaveChanged_StagingUpdated() {
        sked__Resource__c resource  = getBaseResource();
        Date     lastDayOfLeave     = System.today().addDays(29);
        Date     expectedReturn     = lastDayOfLeave.addDays(1);
        Date     oldFirstDay        = System.today().addDays(-10);
        Date     newFirstDay        = System.today().addDays(-3);
        DateTime lastUpdated        = DateTime.valueOf('2026-01-01 10:00:00');

        insertStaging('12345', resource.Id, expectedReturn, lastUpdated, oldFirstDay);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
                'First_Day_of_Leave'          => String.valueOf(newFirstDay),
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

        BSF_Workday_Staging__c updated = [
            SELECT First_Day_of_Leave__c, Sync_Comment__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(newFirstDay, updated.First_Day_of_Leave__c,
            'First_Day_of_Leave should be updated to the new value');
        System.assert(updated.Sync_Comment__c.contains('Updated from Workday'),
            'Sync comment should record the update');
        System.assert(updated.Sync_Comment__c.contains('First_Day_of_Leave'),
            'Sync comment should name the changed field');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 5 — Existing employee, no change: staging not touched.
    //
    // insertStaging receives expectedReturn (already the +1 value).
    // Workday sends lastDayOfLeave = expectedReturn - 1 so batch computes the
    // same expectedReturn after adding 1 day — no diff, no upsert.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testExistingEmployee_NoChange_StagingSkipped() {
        sked__Resource__c resource  = getBaseResource();
        Date     lastDayOfLeave     = System.today().addDays(29);
        Date     expectedReturn     = lastDayOfLeave.addDays(1); // what the batch will compute
        Date     firstDay           = System.today().addDays(-5);
        DateTime lastUpdated        = DateTime.valueOf('2026-01-15 10:00:00');

        // Store the already-offset return date so the comparison is equal
        insertStaging('12345', resource.Id, expectedReturn, lastUpdated, firstDay);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
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
    // TEST 6 — Employee with past Estimated_Last_Day_of_Leave:
    //          returnDate (pastDate + 1) is still in the past, so the early
    //          continue guard is REMOVED. The batch now treats this employee
    //          as Active, creates/updates staging, and clears the resource
    //          return date to null.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testPastReturnDate_TreatedAsActive_StagingCreatedReturnDateCleared() {
        sked__Resource__c resource = getBaseResource();

        // Pre-set a return date and Leave status to confirm the batch clears it
        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_Employment_Status__c             = 'Leave';
        resource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(5);
        update resource;

        // Workday sends a last day that is already past —
        // batch computes returnDate = pastLastDay + 1, still <= today
        Date pastLastDay  = System.today().addDays(-2); // returnDate = today - 1
        Date firstDay     = System.today().addDays(-10);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(pastLastDay),
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

        // Staging should now be created (no continue guard)
        Integer stagingCount = [
            SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(1, stagingCount,
            'Staging should be created even for an employee with a past return date');

        // Resource return date should be cleared and status set to Active
        sked__Resource__c updated = [
            SELECT sked_Anticipated_Leave_Return_Date__c, sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals(null, updated.sked_Anticipated_Leave_Return_Date__c,
            'Return date should be cleared to null when employee is reactivated by the batch');
        System.assertEquals('Active', updated.sked_Employment_Status__c,
            'Resource status should be set to Active when return date has passed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 7 — Employee with null return date:
    //          returnDate = null → Active branch → staging created,
    //          resource return date cleared to null.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testNullReturnDate_TreatedAsActive_StagingCreatedReturnDateCleared() {
        sked__Resource__c resource = getBaseResource();

        // Pre-set a return date so we can verify the batch clears it
        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_Employment_Status__c             = 'Leave';
        resource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(10);
        update resource;

        // No Estimated_Last_Day_of_Leave field → returnDate resolves to null
        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'               => '12345',
                'Last_Functionally_Updated' => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'            => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        Integer stagingCount = [
            SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(1, stagingCount,
            'Staging should be created when return date is null (Active branch)');

        sked__Resource__c updated = [
            SELECT sked_Anticipated_Leave_Return_Date__c, sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals(null, updated.sked_Anticipated_Leave_Return_Date__c,
            'Return date should be cleared to null when status resolves to Active');
        System.assertEquals('Active', updated.sked_Employment_Status__c,
            'Resource status should be Active when return date is null');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 8 — Workday employee with no matching Resource: silently skipped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testWorkdayEmployeeWithNoResource_Skipped() {
        Date lastDayOfLeave = System.today().addDays(29);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => 'EMPORPHAN',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
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
        System.assertEquals(0, stagingCount,
            'No staging should be created when no Resource exists in Salesforce');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 9 — Mid-leave employee: resource status set to Leave
    // firstDayOfLeave <= today AND returnDate > today
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testMidLeaveEmployee_ResourceStatusSetToLeave() {
        Date lastDayOfLeave = System.today().addDays(29); // returnDate = today + 30
        Date firstDay       = System.today().addDays(-5);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
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
    // TEST 10 — Employee not yet on leave: resource status stays Active
    // firstDayOfLeave > today
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testEmployeeNotYetOnLeave_ResourceStatusNotChanged() {
        Date lastDayOfLeave  = System.today().addDays(29);
        Date futureFirstDay  = System.today().addDays(5);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
                'First_Day_of_Leave'          => String.valueOf(futureFirstDay),
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

        sked__Resource__c resource = getBaseResource();
        System.assertEquals('Active', resource.sked_Employment_Status__c,
            'Resource status should remain Active when employee has not yet started leave');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 11 — finish() reactivation: Leave resource with return date <= today
    //           is set to Active and return date cleared
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
            SELECT sked_Employment_Status__c, sked_Anticipated_Leave_Return_Date__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals('Active', reactivated.sked_Employment_Status__c,
            'Resource with return date <= today and Leave status should be reactivated');
        System.assertEquals(null, reactivated.sked_Anticipated_Leave_Return_Date__c,
            'Return date should be cleared to null after reactivation in finish()');
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
                'Estimated_Last_Day_of_Leave' => String.valueOf(System.today().addDays(29)),
                'First_Day_of_Leave'          => String.valueOf(System.today().addDays(-5)),
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
        System.assertEquals(0, stagingCount,
            'No staging records should be created for an empty Workday response');

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
    // '12345'    = future return date → staging created, resource updated (Leave)
    // 'EMP_PAST' = past Estimated_Last_Day_of_Leave → Active branch, staging
    //              created, return date cleared
    // 'EMPNORES' = no Resource → silently skipped
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testMultipleEmployees_AllRoutedCorrectly() {
        Date futureLastDay = System.today().addDays(29);  // returnDate = today + 30
        Date pastLastDay   = System.today().addDays(-2);  // returnDate = today - 1 (past)
        Date firstDay      = System.today().addDays(-3);

        sked__Resource__c pastResource = insertExtraResource('EMP_PAST', 'John', 'Past', 'ULID_PAST', 'Leave');
        skedHubBase.BypassUpdateTriggers = true;
        pastResource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(5);
        update pastResource;

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureLastDay),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            },
            new Map<String, String>{
                'Employee_ID'                 => 'EMP_PAST',
                'Estimated_Last_Day_of_Leave' => String.valueOf(pastLastDay),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            },
            new Map<String, String>{
                'Employee_ID'                 => 'EMPNORES',
                'Estimated_Last_Day_of_Leave' => String.valueOf(futureLastDay),
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

        // Future employee — staging created with offset return date
        List<BSF_Workday_Staging__c> staging12345 = [
            SELECT Anticipated_Leave_Return_Date__c, First_Day_of_Leave__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(1, staging12345.size(),
            'Staging should be created for the future-dated employee');
        System.assertEquals(futureLastDay.addDays(1), staging12345[0].Anticipated_Leave_Return_Date__c,
            'Return date should be Estimated_Last_Day_of_Leave + 1 day');
        System.assertEquals(firstDay, staging12345[0].First_Day_of_Leave__c,
            'First day of leave should match');

        // Past employee — staging created (Active branch), return date cleared
        Integer pastCount = [SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = 'EMP_PAST'];
        System.assertEquals(1, pastCount,
            'Staging should be created for a past-dated employee (Active branch, no continue)');

        sked__Resource__c pastUpdated = [
            SELECT sked_Employment_Status__c, sked_Anticipated_Leave_Return_Date__c
            FROM   sked__Resource__c
            WHERE  sked_Employee_ID__c = 'EMP_PAST'
        ];
        System.assertEquals('Active', pastUpdated.sked_Employment_Status__c,
            'Past-dated employee resource should be set to Active');
        System.assertEquals(null, pastUpdated.sked_Anticipated_Leave_Return_Date__c,
            'Return date should be cleared to null when reactivating');

        // Orphan — silently skipped
        Integer orphanCount = [SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = 'EMPNORES'];
        System.assertEquals(0, orphanCount,
            'No staging should be created for an employee with no Resource');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 20 — Inactive resource: not updated even when data changes.
    // The resource update block guards: status != Inactive → skip DML.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testInactiveResource_NotUpdated() {
        sked__Resource__c resource = getBaseResource();

        // Force resource to Inactive — bypass triggers to avoid automation
        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_Employment_Status__c             = 'Inactive';
        resource.sked_Anticipated_Leave_Return_Date__c = null;
        update resource;

        Date lastDayOfLeave = System.today().addDays(29);
        Date firstDay       = System.today().addDays(-5);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-01-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        // buildResourceMap excludes Inactive resources, so resource won't be in
        // the map and neither staging nor the resource itself should be updated.
        Integer stagingCount = [
            SELECT COUNT() FROM BSF_Workday_Staging__c WHERE Employee_ID__c = '12345'
        ];
        System.assertEquals(0, stagingCount,
            'No staging should be created when the resource is Inactive (excluded from buildResourceMap)');

        sked__Resource__c unchanged = [
            SELECT sked_Employment_Status__c, sked_Anticipated_Leave_Return_Date__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals('Inactive', unchanged.sked_Employment_Status__c,
            'Inactive resource status should not be changed by the batch');
        System.assertEquals(null, unchanged.sked_Anticipated_Leave_Return_Date__c,
            'Inactive resource return date should remain null');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 21 — returnDate addDays(1) offset: the value stored in Salesforce
    //           is always Estimated_Last_Day_of_Leave + 1, confirmed on both
    //           the staging record and the resource field.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testReturnDateOffset_StoredDateIsLastDayPlusOne() {
        Date lastDayOfLeave = System.today().addDays(14);
        Date expectedReturn = lastDayOfLeave.addDays(1);
        Date firstDay       = System.today().addDays(-1);

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
                'First_Day_of_Leave'          => String.valueOf(firstDay),
                'Last_Functionally_Updated'   => '2026-03-01T10:00:00.000-08:00',
                'Created_Moment'              => '2025-06-01T08:00:00.000-08:00'
            }
        });

        Test.setMock(HttpCalloutMock.class, new WorkdayMock(json, 200));

        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;

        Test.startTest();
        Database.executeBatch(new BSF_LeaveReturnBatch(), 200);
        Test.stopTest();

        BSF_Workday_Staging__c staging = [
            SELECT Anticipated_Leave_Return_Date__c
            FROM   BSF_Workday_Staging__c
            WHERE  Employee_ID__c = '12345'
        ];
        System.assertEquals(expectedReturn, staging.Anticipated_Leave_Return_Date__c,
            'Staging should store Estimated_Last_Day_of_Leave + 1 day, not the raw Workday date');

        sked__Resource__c resource = [
            SELECT sked_Anticipated_Leave_Return_Date__c
            FROM   sked__Resource__c
            WHERE  sked_Employee_ID__c = '12345'
        ];
        System.assertEquals(expectedReturn, resource.sked_Anticipated_Leave_Return_Date__c,
            'Resource should store Estimated_Last_Day_of_Leave + 1 day, not the raw Workday date');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 22 — Active resource with existing return date cleared when batch
    //           determines employee is Active (future first day of leave).
    //           Ensures the reactivation branch (`if Active → clear return date`)
    //           fires correctly inside execute() for non-Leave transitions.
    // ─────────────────────────────────────────────────────────────────────────
    @isTest
    static void testActiveReactivation_ReturnDateClearedInExecute() {
        sked__Resource__c resource = getBaseResource();

        // Simulate a resource that was previously on leave but Workday now
        // sends a future first day (leave not started) and an existing return date
        skedHubBase.BypassUpdateTriggers = true;
        resource.sked_Anticipated_Leave_Return_Date__c = System.today().addDays(5);
        resource.sked_Employment_Status__c             = 'Active';
        update resource;

        Date lastDayOfLeave  = System.today().addDays(29);
        Date futureFirstDay  = System.today().addDays(10); // leave not started yet → Active branch

        String json = buildWorkdayJson(new List<Map<String, String>>{
            new Map<String, String>{
                'Employee_ID'                 => '12345',
                'Estimated_Last_Day_of_Leave' => String.valueOf(lastDayOfLeave),
                'First_Day_of_Leave'          => String.valueOf(futureFirstDay),
                'Last_Functionally_Updated'   => '2026-03-10T10:00:00.000-08:00',
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
            SELECT sked_Anticipated_Leave_Return_Date__c, sked_Employment_Status__c
            FROM   sked__Resource__c
            WHERE  Id = :resource.Id
        ];
        System.assertEquals(null, updated.sked_Anticipated_Leave_Return_Date__c,
            'Return date should be cleared to null when the batch resolves status to Active');
        System.assertEquals('Active', updated.sked_Employment_Status__c,
            'Resource status should remain Active when leave has not yet started');
    }
}