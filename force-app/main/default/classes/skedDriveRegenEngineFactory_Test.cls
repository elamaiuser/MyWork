@isTest
private class skedDriveRegenEngineFactory_Test {
    @isTest
    static void testGetEngine_mobile_returnsMobileEngine() {
        System.assert(
            skedDriveRegenEngineFactory.getEngine(skedConstants.DRIVE_TYPE_MOBILE, null) instanceof skedMobileDriveRegenEngine,
            'Phase 5 has shipped - Mobile must resolve to the real Mobile engine');
    }

    @isTest
    static void testGetEngine_wbFixedSite_returnsWbFixedSiteEngine() {
        System.assert(
            skedDriveRegenEngineFactory.getEngine(skedConstants.DRIVE_TYPE_FIXED_SITE, Constants.NON_INTEGRATED_WB_OPERATION_TYPE) instanceof skedFixedSiteWbDriveRegenEngine,
            'Fixed Site + Non Integrated WB must resolve to skedFixedSiteWbDriveRegenEngine now that it ships');
    }

    // DRIVE_TYPE_RSMO is a valid picklist value with no LWC generator of its own - the null
    // fallthrough must stay reachable even after every other drive/operation-type combination
    // resolves to a real engine.
    @isTest
    static void testGetEngine_rsmo_returnsNullEngine() {
        System.assertEquals(null,
            skedDriveRegenEngineFactory.getEngine(skedConstants.DRIVE_TYPE_RSMO, null),
            'RSMO has no wired-up engine and must resolve to null');
    }

    @isTest
    static void testGetEngine_integratedFixedSite_returnsFixedSiteEngine() {
        System.assert(
            skedDriveRegenEngineFactory.getEngine(skedConstants.DRIVE_TYPE_FIXED_SITE, skedConstants.OPERATION_TYPE_INTEGRATED) instanceof skedFixedSiteDriveRegenEngine,
            'Integrated Fixed Site must resolve to the real Fixed Site engine now that it does real regeneration');
    }

    @isTest
    static void testGetEngine_nonIntegratedAphFixedSite_returnsFixedSiteEngine() {
        System.assert(
            skedDriveRegenEngineFactory.getEngine(skedConstants.DRIVE_TYPE_FIXED_SITE, skedConstants.OPERATION_TYPE_APH) instanceof skedFixedSiteDriveRegenEngine,
            'Non-Integrated-APH Fixed Site must resolve to the real Fixed Site engine now that it does real regeneration');
    }

    @isTest
    static void testGetEngine_testOverrideTakesPrecedence() {
        skedDriveRegenEngineFactory.testEngineOverride = new StubEngine();

        System.assert(
            skedDriveRegenEngineFactory.getEngine(skedConstants.DRIVE_TYPE_MOBILE, null) instanceof StubEngine,
            'Test override must let downstream steps be tested against a stub, not the real Mobile engine');
    }

    private class StubEngine implements skedDriveRegenEngine {
        public void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens) {
        }
    }
}
