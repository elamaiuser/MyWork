@IsTest
private class BSF_OpsRecordToTimeBlockMapper_Test {
    

    @IsTest
    static void buildBaseTimeBlocks_setsNoMealWorktagAndFormatsDateTimes() {
        // Prepare a single staff detail needing base time with No Meal selected.
        skedOpsRecordApiData.opsRecordStaffDetail sd = new skedOpsRecordApiData.opsRecordStaffDetail();
        sd.personID = 123;
        sd.email = 'user@example.org';
        sd.noMeal = true;

        BSF_OpsRecordToTimeBlockMapper.StaffWithTimes s = new BSF_OpsRecordToTimeBlockMapper.StaffWithTimes();
        s.detail = sd;
        s.shiftStartGmt = DateTime.newInstance(2026, 1, 1, 8, 0, 0);
        s.shiftEndGmt = DateTime.newInstance(2026, 1, 1, 16, 0, 0);
        s.staffRecordId = 'staff-guid-1';

        List<BSF_OpsRecordToTimeBlockMapper.StaffWithTimes> staffList =
            new List<BSF_OpsRecordToTimeBlockMapper.StaffWithTimes>{ s };

        Set<String> needBase = new Set<String>{ '123' };
        Map<String, String> tzMap = new Map<String, String>{ '123' => 'America/New_York' };

        BSF_OpsRecordToTimeBlockMapper.BaseTimeBlockResult result =
            BSF_OpsRecordToTimeBlockMapper.buildBaseTimeBlocks(
                staffList,
                needBase,
                tzMap,
                'approver@example.org',
                Date.newInstance(2026, 1, 1)
            );

        System.assertEquals(1, result.blocks.size(), 'Expected one base block');
        skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType block = result.blocks[0];
        System.assertEquals('30 Min Deduct', block.Custom_Worktag_01_Reference,
            'No Meal should set the 30 Min Deduct custom worktag');
        System.assertEquals(BSF_OpsRecordToTimeBlockMapper.TIME_ENTRY_BASE,
            block.Time_Entry_Code_Reference.ID[0].input);

        System.assertEquals(1, result.dateTimeFormats.size(), 'Expected one dateTimeFormats entry');
        Map<String, String> fmt = result.dateTimeFormats[0];
        System.assert(fmt.containsKey('In_Date_Time'), 'In_Date_Time should be present');
        System.assert(fmt.containsKey('Out_Date_Time'), 'Out_Date_Time should be present');
    }

    @IsTest
    static void buildPremiumTimeBlocks_createsBlocksForSelectedPremiums() {
        skedOpsRecordApiData.opsRecordStaffDetail sd = new skedOpsRecordApiData.opsRecordStaffDetail();
        sd.personID = 456;
        sd.email = 'premium@example.org';
        sd.premiumCharge = true;
        sd.premiumTranslator = true;
        sd.premiumDriver = true;

        List<skedOpsRecordApiData.opsRecordStaffDetail> staffDetails =
            new List<skedOpsRecordApiData.opsRecordStaffDetail>{ sd };

        Map<String, String> staffIdToGuid = new Map<String, String>{ '456' => 'staff-guid-2' };

        List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> blocks =
            BSF_OpsRecordToTimeBlockMapper.buildPremiumTimeBlocks(
                staffDetails,
                Date.newInstance(2026, 1, 2),
                'approver2@example.org',
                staffIdToGuid
            );

        // We set three premiums above; expect three blocks, all with Quantity = 1.
        System.assertEquals(3, blocks.size(), 'Expected one block per selected premium');
        for (skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType b : blocks) {
            System.assertEquals(BSF_OpsRecordToTimeBlockMapper.QUANTITY_PREMIUM, b.Quantity);
            System.assertEquals(false, b.Delete_Time_Block);
            System.assertEquals('456', b.Worker_Reference.ID[0].input);
        }
    }
}

