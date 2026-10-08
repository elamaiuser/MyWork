/**
 * Neutral, drive-type-agnostic proposed shift - the shift record and its jobs, which is all
 * skedLunchBreakCalculator (and any other shared calculator) needs regardless of drive type.
 * skedMobileDriveJobBuilder.ProposedDriveShift extends this, adding Mobile-only fields (slots,
 * jobAllocationsByJobId, jobTagsByJobIndex) - existing Mobile code accessing shiftRecord/jobs on
 * that type keeps working unchanged via inheritance.
 */
public virtual class skedProposedDriveShift {
    public sked_Drive_Shift__c shiftRecord;
    public List<sked__Job__c> jobs = new List<sked__Job__c>();
}
