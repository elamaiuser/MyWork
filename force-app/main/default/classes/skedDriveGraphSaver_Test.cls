@isTest
private class skedDriveGraphSaver_Test {
    @isTest
    static void testSave_insertsNewShiftAndStampsParentDriveId() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        ctx.driveShifts.add(new sked_Drive_Shift__c()); // Id == null -> must be inserted
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        List<sked_Drive_Shift__c> shifts = [SELECT Id, sked_Drive__c FROM sked_Drive_Shift__c WHERE sked_Drive__c = :drive.Id];
        System.assertEquals(1, shifts.size(), 'The new shift must be inserted');
        System.assertEquals(drive.Id, shifts[0].sked_Drive__c, 'The new shift must be stamped with the parent drive Id');
    }

    @isTest
    static void testSave_newShiftWithTags_insertsTagsStampedWithTheNewShiftsRealId() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        sked__Tag__c tag = new sked__Tag__c(Name = 'Lift Gate');
        insert tag;

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        ctx.driveShifts.add(new sked_Drive_Shift__c()); // Id == null -> must be inserted
        skedDriveShiftTagCalculator.TagResult tagResult = new skedDriveShiftTagCalculator.TagResult();
        tagResult.tagId = tag.Id;
        tagResult.minimumQuantity = 1;
        ctx.tagsByNewShiftIndex.put(0, new List<skedDriveShiftTagCalculator.TagResult>{ tagResult });
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        sked_Drive_Shift__c insertedShift = [SELECT Id FROM sked_Drive_Shift__c WHERE sked_Drive__c = :drive.Id];
        List<sked_Drive_Shift_Tag__c> persistedTags = [SELECT sked_Tag__c, sked_Minimum_Quantity__c FROM sked_Drive_Shift_Tag__c WHERE sked_Drive_Shift__c = :insertedShift.Id];
        System.assertEquals(1, persistedTags.size(), 'The new shift\'s tag must be inserted');
        System.assertEquals(tag.Id, persistedTags[0].sked_Tag__c, 'The persisted tag must reference the correct sked__Tag__c');
    }

    @isTest
    static void testSave_deletesSlotAbsentFromCurrentContext() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Slot__c slot = new sked__Slot__c(sked_Drive_Shift__c = shift.Id, Name = 'Test Slot', sked_Status__c = 'Open');
        insert slot;

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        ctx.slotsByShiftId.remove(shift.Id); // simulate the engine removing this shift's slots
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM sked__Slot__c WHERE Id = :slot.Id],
            'A slot present in the snapshot but absent from the current context must be deleted');
    }

    @isTest
    static void testSave_stripsReadonlyAndMasterFieldsFromDriveUpdate() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Id originalOpportunityId = drive.sked_Opportunity__c;

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        ctx.drive.sked_Total_Slots__c = 42; // a genuinely trackable, non-excluded field change
        ctx.drive.sked_Opportunity__c = null; // attempt to touch a master field - must be stripped
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        sked_Drive__c reloaded = [SELECT sked_Total_Slots__c, sked_Opportunity__c FROM sked_Drive__c WHERE Id = :drive.Id];
        System.assertEquals(42, reloaded.sked_Total_Slots__c, 'Non-excluded field changes must be saved');
        System.assertEquals(originalOpportunityId, reloaded.sked_Opportunity__c,
            'A master field change must be stripped from the update and never touch the database');
    }

    @isTest
    static void testSave_deletesJobAbsentFromCurrentContextAndCascadesToItsAllocation() {
        skedTestDataFactory factory = new skedTestDataFactory('us', 30);
        factory.setupCommonTestData();
        Map<String, sObject> testData = factory.setupDriveData();
        sked_Drive__c drive = (sked_Drive__c) testData.get('testDrive1');
        Id regionId = [SELECT Id FROM sked__Region__c LIMIT 1].Id;

        sked_Drive_Shift__c shift = new sked_Drive_Shift__c(sked_Drive__c = drive.Id);
        insert shift;
        sked__Job__c removedJob = new sked__Job__c(
            sked_Drive_Shift__c = shift.Id, sked_Resource_Role__c = 'Driver', sked__Quantity__c = 1,
            sked__Region__c = regionId, sked__Duration__c = 60
        );
        insert removedJob;
        sked__Resource__c resource = new sked__Resource__c(Name = 'Test Driver', sked__Is_Active__c = true);
        insert resource;
        sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(sked__Job__c = removedJob.Id, sked__Resource__c = resource.Id);
        insert allocation;

        Test.startTest();
        skedDriveRegenContext ctx = skedDriveRegenContextLoader.load(drive.Id);
        ctx.jobsByShiftId.get(shift.Id).clear(); // simulate the engine computing this role's quantity down to zero
        skedDriveGraphSaver.save(ctx);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM sked__Job__c WHERE Id = :removedJob.Id],
            'A job present in the snapshot but absent from the current context must be deleted');
        System.assertEquals(0, [SELECT COUNT() FROM sked__Job_Allocation__c WHERE Id = :allocation.Id],
            'Job Allocation is a MasterDetail child of Job, so deleting the removed job must cascade-delete its allocation too');
    }

    // Self-contained fake-Id builder (no DML, no external test utility) - standard Apex
    // pattern: key prefix + zero-padded numeric suffix, valid Id format for any sObject type.
    private static Id fakeId(Schema.SObjectType objType, Integer uniqueNumber) {
        String keyPrefix = objType.getDescribe().getKeyPrefix();
        String numericPart = String.valueOf(uniqueNumber);
        String padded = numericPart.leftPad(12, '0');
        return Id.valueOf(keyPrefix + padded);
    }

    @isTest
    static void testIsChanged_identicalRecordsReturnsFalse() {
        Id driveId = fakeId(sked_Drive__c.SObjectType, 1);
        sked_Drive__c current = new sked_Drive__c(Id = driveId, sked_Total_Slots__c = 10);
        sked_Drive__c snapshot = new sked_Drive__c(Id = driveId, sked_Total_Slots__c = 10);

        Boolean changed = skedDriveGraphSaver.isChanged(current, snapshot, new Set<String>());

        System.assertEquals(false, changed, 'Two records with identical populated field values must not be flagged as changed');
    }

    @isTest
    static void testIsChanged_excludedFieldDifferenceIsIgnored() {
        Id driveId = fakeId(sked_Drive__c.SObjectType, 2);
        Id oppId1 = fakeId(Opportunity.SObjectType, 3);
        Id oppId2 = fakeId(Opportunity.SObjectType, 4);
        sked_Drive__c current = new sked_Drive__c(Id = driveId, sked_Total_Slots__c = 10, sked_Opportunity__c = oppId1);
        sked_Drive__c snapshot = new sked_Drive__c(Id = driveId, sked_Total_Slots__c = 10, sked_Opportunity__c = oppId2);

        Boolean changed = skedDriveGraphSaver.isChanged(current, snapshot,
            new Set<String>{ 'sked_Opportunity__c' });

        System.assertEquals(false, changed,
            'A difference on an excluded field alone must not be flagged as a real change');
    }
}
