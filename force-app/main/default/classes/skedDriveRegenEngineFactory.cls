public class skedDriveRegenEngineFactory {
    @TestVisible public static skedDriveRegenEngine testEngineOverride;

    // Returns null for drive types/operation types with no engine wired up yet. This factory
    // body IS the extension point: no metadata, no flags, nothing else to deploy or flip when a
    // new drive type's engine ships.
    public static skedDriveRegenEngine getEngine(String typeOfDrive, String operationType) {
        if (testEngineOverride != null) {
            return testEngineOverride;
        }
        if (typeOfDrive == skedConstants.DRIVE_TYPE_MOBILE) {
            return new skedMobileDriveRegenEngine();
        }
        if (typeOfDrive == skedConstants.DRIVE_TYPE_FIXED_SITE && operationType == skedConstants.OPERATION_TYPE_WB) {
            return new skedFixedSiteWbDriveRegenEngine();
        }
        if (typeOfDrive == skedConstants.DRIVE_TYPE_FIXED_SITE && operationType != skedConstants.OPERATION_TYPE_WB) {
            return new skedFixedSiteDriveRegenEngine();
        }
        // DRIVE_TYPE_RSMO (skedConstants.cls) is a valid picklist value with no LWC generator of its
        // own - the LWC's dispatch falls through to Mobile for every non-Fixed-Site drive type, but
        // this factory gates on DRIVE_TYPE_MOBILE specifically, so RSMO stays null on purpose.
        return null;
    }
}
