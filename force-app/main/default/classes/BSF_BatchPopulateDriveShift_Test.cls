@IsTest
public class BSF_BatchPopulateDriveShift_Test {

    @testSetup
    static void setupData() {
        // ✅ Temporarily bypass heavy triggers for setup data
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');

        // 🔹 Use existing utility for consistent base data
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<String, SObject> testData = testDataSetup.createAndInsertCommonObjects();

        // 🔹 Insert key objects
        Account testAccount = (Account)testData.get('MOBILE_ACCOUNT');
        insert testAccount;

        sked__Tag__c tag = (sked__Tag__c)testData.get('GLOBAL_TAG');
        insert tag;

        sked__Location__c site = (sked__Location__c)testData.get('MOBILE_SITE');
        insert site;

        Opportunity templateOpp = (Opportunity)testData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.AccountId = testAccount.Id;
        templateOpp.Drive_Site__c = site.Id;
        insert templateOpp;

        Opportunity mobileOpp = (Opportunity)testData.get('MOBILE_OPP');
        mobileOpp.AccountId = testAccount.Id;
        mobileOpp.Parent_Template_Id__c = templateOpp.Id;
        mobileOpp.Is_Template__c = false;
        insert mobileOpp;

        // 🔹 Create a sked_Drive and its shifts
        sked_Drive__c drive = new sked_Drive__c(
            sked_Account__c = testAccount.Id,
            sked_Drive_Site__c = site.Id,
            sked_Opportunity__c = mobileOpp.Id,
            sked_Projected_Registered_Donors__c = 30,
            Sked_migrationid__c = '123456'
        );
        insert drive;

        List<sked_Drive_Shift__c> shifts = new List<sked_Drive_Shift__c>{
            new sked_Drive_Shift__c(
                sked_Drive__c = drive.Id,
                sked_Start_Time__c = Time.newInstance(18, 30, 0, 0)
            ),
            new sked_Drive_Shift__c(
                sked_Drive__c = drive.Id,
                sked_Start_Time__c = Time.newInstance(17, 30, 0, 0)
            )
        };
        insert shifts;

        // ✅ Clear trigger bypass after setup
        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
    }

    @isTest
    static void test_BSF_BatchPopulateDriveShift() {
        // 🔹 Fetch existing drive and shifts created in setup
        sked_Drive__c drive = [SELECT Id FROM sked_Drive__c LIMIT 1];
        List<sked_Drive_Shift__c> beforeShifts = [
            SELECT Id, sked_Donors_Scheduled__c
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c = :drive.Id
        ];
        System.assertEquals(2, beforeShifts.size(), 'Two drive shifts should exist before batch run.');

        // 🔹 Run the batch
        Test.startTest();
        Date cutoffDate = System.today().addDays(-10);
        Database.executeBatch(new BSF_BatchPopulateDriveShift(cutoffDate), 200);
        Test.stopTest();

        // 🔹 Re-query updated shifts
        List<sked_Drive_Shift__c> afterShifts = [
            SELECT Id, sked_Donors_Scheduled__c
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c = :drive.Id
        ];

        // 🔹 Validate meaningful outcome
        Boolean anyUpdated = false;
        for (sked_Drive_Shift__c s : afterShifts) {
            if (s.sked_Donors_Scheduled__c != null) {
                anyUpdated = true;
                break;
            }
        }

        System.assert(
            anyUpdated,
            'After BSF_BatchPopulateDriveShift runs, at least one shift should have Donors Scheduled populated.'
        );
    }

    // ✅ Utility method to get record type dynamically
    private static Map<String, Id> recordTypeMap(String sObjectName) {
        Map<String, Id> mapNameId = new Map<String, Id>();
        if (sObjectName != null) {
            for (Schema.RecordTypeInfo info :
                 Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosByName().values()) {
                mapNameId.put(info.getName(), info.getRecordTypeId());
            }
        }
        return mapNameId;
    }
}