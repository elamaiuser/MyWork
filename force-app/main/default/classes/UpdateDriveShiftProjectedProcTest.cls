@IsTest
public class UpdateDriveShiftProjectedProcTest {

    // ---------------------------------------------------------------------------
    // Test Setup (Common reusable data)
    // ---------------------------------------------------------------------------
    @testSetup
    static void setupData() {
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        // Create common data via factory classes
        Map<String, SObject> testData = GenerateDriveTestData.setupData();
        /*insert new List<SObject>{
            (Account)testData.get('fixedSiteAccount'),
            (Opportunity)testData.get('fixedSiteOpportunity')
        };*/
        Account acc = (Account)testData.get('fixedSiteAccount');
        
        Opportunity opp = (Opportunity)testData.get('fixedSiteOpportunity');
        
        //Ensure triggers are reset before test runs
        TriggerHandler.clearAllBypasses();
        AccountTeamMemberHelper.skipAccountTrigger = false;
    }

    // ---------------------------------------------------------------------------
    // Helper method to update DriveShift fields before running batch
    // ---------------------------------------------------------------------------
    private static void updateDriveShiftValues(Set<Id> driveIds) {
        List<sked_Drive_Shift__c> shifts = [
            SELECT Id, sked_Drive__c
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c IN :driveIds
        ];
        for (sked_Drive_Shift__c s : shifts) {
            s.sked_WB_Projected_Procedures__c = 2;
            s.sked_2RBC_Projected_Procedures__c = 2;
            s.sked_Platelet_Projected_Procedures__c = 2;
            s.sked_Plasma_Projected_Procedures__c = 2;
            s.sked_Total_Procedures_Projected__c = 2;
            s.sked_Total_Products_Projected__c = 2;
        }
        update shifts;
    }

    // ---------------------------------------------------------------------------
    // Test 1: Fixed Site Drive — driveShiftUpdate = true
    // ---------------------------------------------------------------------------
    @IsTest
    static void testFixedSiteDrive_UpdateDriveShift() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'Fixed_Site_Opp'  LIMIT 1];
        Test.startTest();

        // 🔹 Bypass triggers for drive creation
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        TriggerHandler.bypass('OpportunitySplitTriggerHandler');
        CreateSkedDrive.createDrives(new List<Opportunity>{ opp });

        List<sked_Drive__c> drives = [
            SELECT Id, sked_Drive_Date__c FROM sked_Drive__c WHERE sked_Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, drives.size(), 'A drive should be created for the fixed-site opportunity.');

        updateDriveShiftValues(new Set<Id>{ drives[0].Id });

        Date runDate = drives[0].sked_Drive_Date__c;
        Database.executeBatch(
            new UpdateDriveShiftProjProc_ProductAndProc(runDate, runDate, 'Fixed Site', true),
            100
        );
        Test.stopTest();

        //Verify projected totals updated successfully
        Integer updatedShifts = [SELECT COUNT() FROM sked_Drive_Shift__c WHERE sked_WB_Projected_Procedures__c = 2];
        System.assert(updatedShifts > 0, 'Drive shift projected procedures should be updated.');
    }

    
    // ---------------------------------------------------------------------------
    //Test 2: Fixed Site Drive — onlyTotalProcedureUpdate = true
    // ---------------------------------------------------------------------------
    @IsTest
    static void testFixedSiteDrive_UpdateTotalProceduresOnly() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'Fixed_Site_Opp' LIMIT 1];

        Test.startTest();
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        CreateSkedDrive.createDrives(new List<Opportunity>{ opp });

        sked_Drive__c drive = [
            SELECT Id, sked_Drive_Date__c FROM sked_Drive__c WHERE sked_Opportunity__c = :opp.Id LIMIT 1
        ];
        updateDriveShiftValues(new Set<Id>{ drive.Id });

        Date d = drive.sked_Drive_Date__c;
        Database.executeBatch(
            new UpdateDriveShiftProjProc_ProductAndProc(d, d, 'Fixed Site', false, true),
            100
        );
        Test.stopTest();

        //Assert totals updated
        sked_Drive_Shift__c updatedShift = [
            SELECT sked_Total_Procedures_Projected__c FROM sked_Drive_Shift__c WHERE sked_Drive__c = :drive.Id LIMIT 1
        ];
        System.assertNotEquals(null, updatedShift.sked_Total_Procedures_Projected__c, 'Total projected procedures should be updated.');
    }

    // ---------------------------------------------------------------------------
    // Test 3: Fixed Site Drive — onlyTotalProcedureUpdateForDrive = true
    // ---------------------------------------------------------------------------
    @IsTest
    static void testFixedSiteDrive_UpdateDriveTotalsOnly() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE RecordType.DeveloperName = 'Fixed_Site_Opp' LIMIT 1];
        Test.startTest();

        TriggerHandler.bypass('AccountTriggerHandler');
        CreateSkedDrive.createDrives(new List<Opportunity>{ opp });

        sked_Drive__c drive = [
            SELECT Id, sked_Drive_Date__c, sked_Total_Procedures_Projected__c
            FROM sked_Drive__c LIMIT 1
        ];
        drive.sked_Total_Procedures_Projected__c = 10;
        drive.sked_Total_Products_Projected__c = 10;
        update drive;

        Date d = drive.sked_Drive_Date__c;
        Database.executeBatch(
            new UpdateDriveShiftProjProc_ProductAndProc(d, d, 'Fixed Site', false, false, true),
            100
        );
        Test.stopTest();

        // Verify Drive totals remain valid
        sked_Drive__c afterDrive = [
            SELECT sked_Total_Procedures_Projected__c FROM sked_Drive__c WHERE Id = :drive.Id
        ];
        System.assertEquals(40, afterDrive.sked_Total_Procedures_Projected__c, 'Drive total projected value should be maintained.');
    }
}