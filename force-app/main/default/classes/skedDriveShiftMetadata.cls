/**
 * Neutral, drive-type-agnostic shift metadata - the fields skedLunchBreakCalculator (and any other
 * shared calculator) needs regardless of drive type. skedMobileDriveShiftCalculator.DriveShiftMetadata
 * extends this, adding Mobile-only fields (key, label, aptSetup, procedure projections, role-time
 * data) - existing Mobile code accessing driveDate/startTime/endTime/lunchBreakSettings on that type
 * keeps working unchanged via inheritance.
 */
public virtual class skedDriveShiftMetadata {
    public Date driveDate;
    public Time startTime;
    public Time endTime;
    public skedLunchBreakSettings lunchBreakSettings;
}
