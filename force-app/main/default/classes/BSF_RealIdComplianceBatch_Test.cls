// Tests for REAL ID compliance batch and scheduler
@isTest
private class BSF_RealIdComplianceBatch_Test {
    
    @isTest
    static void testBatchExecution_Success() {
        // Set up org-level config so batch uses a known filter date and batch size
        insert new BSF_Workday_RealID_Config__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Name = 'Default',
            Initial_Backfill_Date__c = Date.newInstance(2025, 1, 1),
            Batch_Size__c = 50
        );

        // Create test resources
        List<sked__Resource__c> testResources = new List<sked__Resource__c>();
        
        // In Workday response, should become compliant with expiration date
        sked__Resource__c resource1 = new sked__Resource__c(
            Name = 'Test Resource 1',
            sked_Employee_ID__c = '109850',
            sked_REAL_ID_Compliant_indicator__c = false,
            sked__Resource_Type__c = 'Person'
        );
        testResources.add(resource1);
        
        // Also in Workday response
        sked__Resource__c resource2 = new sked__Resource__c(
            Name = 'Test Resource 2',
            sked_Employee_ID__c = '109856',
            sked_REAL_ID_Compliant_indicator__c = false,
            sked__Resource_Type__c = 'Person'
        );
        testResources.add(resource2);
        
        // Not in Workday response, should be left alone
        sked__Resource__c resource3 = new sked__Resource__c(
            Name = 'Test Resource 3',
            sked_Employee_ID__c = '999999',
            sked_REAL_ID_Compliant_indicator__c = true,
            sked__Resource_Type__c = 'Person'
        );
        testResources.add(resource3);
        
        insert testResources;
        
        Test.setMock(HttpCalloutMock.class, new WorkdayRealIdMock());
        
        Test.startTest();
        BSF_RealIdComplianceBatch batch = new BSF_RealIdComplianceBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Check the results
        List<sked__Resource__c> updatedResources = [
            SELECT Id,
                   sked_Employee_ID__c,
                   sked_REAL_ID_Compliant_indicator__c,
                   Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE Id IN :testResources
            ORDER BY sked_Employee_ID__c
        ];
        
        sked__Resource__c r1 = getResourceById(updatedResources, resource1.Id);
        System.assertEquals(true, r1.sked_REAL_ID_Compliant_indicator__c, 'Resource 1 should be TRUE');
        System.assertEquals(Date.newInstance(2025, 12, 31), r1.Real_ID_Expiration_Date__c,
                            'Resource 1 should have expiration date from Workday');
        
        sked__Resource__c r2 = getResourceById(updatedResources, resource2.Id);
        System.assertEquals(true, r2.sked_REAL_ID_Compliant_indicator__c, 'Resource 2 should be TRUE');
        System.assertEquals(Date.newInstance(2026, 1, 15), r2.Real_ID_Expiration_Date__c,
                            'Resource 2 should have expiration date from Workday');
        
        sked__Resource__c r3 = getResourceById(updatedResources, resource3.Id);
        System.assertEquals(true, r3.sked_REAL_ID_Compliant_indicator__c,
                            'Resource 3 should be unchanged because it is not in Workday report');
        System.assertEquals(null, r3.Real_ID_Expiration_Date__c,
                            'Resource 3 should not get an expiration date');
        
        // Config should have Last_Successful_Run_Date__c set after a successful run
        BSF_Workday_RealID_Config__c configAfter = BSF_Workday_RealID_Config__c.getOrgDefaults();
        System.assertEquals(System.today(), configAfter.Last_Successful_Run_Date__c,
                            'Last_Successful_Run_Date__c should be updated on success');
    }
    
    @isTest
    static void testBatchExecution_ApiError() {
        // Create test resource
        sked__Resource__c testResource = new sked__Resource__c(
            Name = 'Test Resource',
            sked_Employee_ID__c = '109850',
            sked_REAL_ID_Compliant_indicator__c = false,
            sked__Resource_Type__c = 'Person'
        );
        insert testResource;
        
        Test.setMock(HttpCalloutMock.class, new WorkdayRealIdMock(true));
        
        Test.startTest();
        try {
            BSF_RealIdComplianceBatch batch = new BSF_RealIdComplianceBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Workday API'), 'Should throw error about Workday API');
        }
    }
    
    @isTest
    static void testBatchExecution_EmptyResponse() {
        // Set up org-level config so we can verify Last_Successful_Run_Date__c update
        insert new BSF_Workday_RealID_Config__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Name = 'Default_Empty',
            Initial_Backfill_Date__c = Date.newInstance(2025, 1, 1)
        );

        // Create test resource
        sked__Resource__c testResource = new sked__Resource__c(
            Name = 'Test Resource',
            sked_Employee_ID__c = '109850',
            sked_REAL_ID_Compliant_indicator__c = true,
            sked__Resource_Type__c = 'Person'
        );
        insert testResource;
        
        Test.setMock(HttpCalloutMock.class, new WorkdayRealIdMock(false, true));
        
        Test.startTest();
        BSF_RealIdComplianceBatch batch = new BSF_RealIdComplianceBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        sked__Resource__c updatedResource = [
            SELECT sked_REAL_ID_Compliant_indicator__c, Real_ID_Expiration_Date__c
            FROM sked__Resource__c
            WHERE Id = :testResource.Id
        ];
        // With an empty Workday response, we should not touch the resource at all
        System.assertEquals(true, updatedResource.sked_REAL_ID_Compliant_indicator__c, 
            'Resource should be unchanged when Workday response is empty');
        System.assertEquals(null, updatedResource.Real_ID_Expiration_Date__c,
            'Resource should not get an expiration date when Workday response is empty');

        // Config should still be updated, since this is a successful (non-error) run
        BSF_Workday_RealID_Config__c configAfter = BSF_Workday_RealID_Config__c.getOrgDefaults();
        System.assertEquals(System.today(), configAfter.Last_Successful_Run_Date__c,
                            'Last_Successful_Run_Date__c should be updated even if Workday response is empty');
    }
    
    @isTest
    static void testScheduler() {
        // Create test resource
        sked__Resource__c testResource = new sked__Resource__c(
            Name = 'Test Resource',
            sked_Employee_ID__c = '109850',
            sked_REAL_ID_Compliant_indicator__c = false,
            sked__Resource_Type__c = 'Person'
        );
        insert testResource;
        
        Test.setMock(HttpCalloutMock.class, new WorkdayRealIdMock());
        
        Test.startTest();
        BSF_RealIdComplianceBatch scheduler = new BSF_RealIdComplianceBatch();
        scheduler.execute(null);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BSF_RealIdComplianceBatch'
        ];
        System.assert(!jobs.isEmpty(), 'Batch job should be created');
    }
    
    @isTest
    static void testScheduler_WithCustomBatchSize() {
        Test.setMock(HttpCalloutMock.class, new WorkdayRealIdMock());
        
        Test.startTest();
        BSF_RealIdComplianceBatch scheduler = new BSF_RealIdComplianceBatch(100);
        scheduler.execute(null);
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BSF_RealIdComplianceBatch'
        ];
        System.assert(!jobs.isEmpty(), 'Batch job should be created');
    }
    
    private static sked__Resource__c getResourceById(List<sked__Resource__c> resources, Id resourceId) {
        for (sked__Resource__c r : resources) {
            if (r.Id == resourceId) {
                return r;
            }
        }
        return null;
    }
    
    // Mock for Workday API responses
    private class WorkdayRealIdMock implements HttpCalloutMock {
        private Boolean isError;
        private Boolean isEmpty;
        
        public WorkdayRealIdMock() {
            this.isError = false;
            this.isEmpty = false;
        }
        
        public WorkdayRealIdMock(Boolean isError) {
            this.isError = isError;
            this.isEmpty = false;
        }
        
        public WorkdayRealIdMock(Boolean isError, Boolean isEmpty) {
            this.isError = isError;
            this.isEmpty = isEmpty;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (isError) {
                res.setStatusCode(500);
                res.setBody('{"error": "Internal Server Error"}');
            } else if (isEmpty) {
                res.setStatusCode(200);
                res.setBody('{"Report_Entry": []}');
            } else {
                res.setStatusCode(200);
                // Mock response matching the expected REAL ID report format,
                // including the Real_ID_Expiration_Date field used by the batch
                res.setBody('{' +
                    '"Report_Entry": [' +
                        '{' +
                            '"Employee_ID": "109850",' +
                            '"Real_ID_Expiration_Date": "2025-12-31"' +
                        '},' +
                        '{' +
                            '"Employee_ID": "109856",' +
                            '"Real_ID_Expiration_Date": "2026-01-15"' +
                        '}' +
                    ']' +
                '}');
            }
            
            return res;
        }
    }
}