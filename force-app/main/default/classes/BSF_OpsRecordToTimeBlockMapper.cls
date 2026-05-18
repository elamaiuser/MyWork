/**
 * Maps Ops Record request and staff data to Workday Reported_Time_Block_DataType
 * for base time and premium time. Used by BSF_WorkdayOpsRecordDirectService and batch.
 */
public with sharing class BSF_OpsRecordToTimeBlockMapper {
    public static final String TIME_ENTRY_BASE = 'Time Worked';
    public static final String TIME_ENTRY_CHARGE = 'Charge';
    public static final String TIME_ENTRY_DRC = 'Double Red Cell (DRC)';
    public static final String TIME_ENTRY_TRANSLATOR = 'Translator';
    public static final String TIME_ENTRY_DRIVER = 'Driver';
    public static final String TIME_ENTRY_OJI = 'Instructor';
    public static final String TIME_ENTRY_LATE_END = 'Drive End Time';
    public static final String TIME_ENTRY_CA_MISSED_SHORT_REST_BREAK = 'TIME_ENTRY_CODE-3-112';
    public static final Decimal QUANTITY_PREMIUM = 1;
    

    /**
     * Wrapper for staff + GMT shift times (from SF) for building time blocks.
     */
    public class StaffWithTimes {
        public skedOpsRecordApiData.opsRecordStaffDetail detail;
        public DateTime shiftStartGmt;
        public DateTime shiftEndGmt;
        public String staffRecordId; // BSF GUID for comment (e.g. sked_Operation_Record_Staff__c Id)
        public String approverEmail;
    }

    /**
     * Wrapper for premium block creation so comment metadata remains per staff row.
     */
    public class PremiumStaffContext {
        public skedOpsRecordApiData.opsRecordStaffDetail detail;
        public String staffRecordId;
        public String approverEmail;
    }

    /**
     * Builds base time blocks for employees who need them (no time in Workday yet).
     * One block per staff. Uses IANA timezone to format In/Out with offset.
     * Returns the list of blocks and a  list of In/Out formatted strings for SOAP XML update.
     */
    public static BaseTimeBlockResult buildBaseTimeBlocks(
        List<BSF_OpsRecordToTimeBlockMapper.StaffWithTimes> staffList,
        Set<String> employeeIdsNeedingBase,
        Map<String, String> employeeIdToIanaTimezone,
        Date driveDate
    ) {
        BaseTimeBlockResult result = new BaseTimeBlockResult();
        result.blocks = new List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType>();
        result.dateTimeFormats = new List<Map<String, String>>();

        for (BSF_OpsRecordToTimeBlockMapper.StaffWithTimes st : staffList) {
            String empId = String.valueOf(st.detail.personID);
            if (empId == null || empId == '0' || !employeeIdsNeedingBase.contains(empId)) { // Skip if employee ID is null, empty, or not in the list of employees needing base time.   
                continue;
            }
            String tzIana = employeeIdToIanaTimezone != null ? employeeIdToIanaTimezone.get(empId) : null;
            if (String.isBlank(tzIana)) {
                // Fallback to Pacific time if Workday doesn't send a timezone
                tzIana = 'America/Los_Angeles';
            }
            String inFormatted = null;
            String outFormatted = null;
            if (st.shiftStartGmt != null) {
                inFormatted = st.shiftStartGmt.format('yyyy-MM-dd\'T\'HH:mm:ssXXX', tzIana);
            }
            if (st.shiftEndGmt != null) {
                outFormatted = st.shiftEndGmt.format('yyyy-MM-dd\'T\'HH:mm:ssXXX', tzIana);
            }
            skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType block = new skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType();
            block.Worker_Reference = buildWorkerReference(empId);
            block.Date_x = driveDate;
            block.Time_Entry_Code_Reference = buildTimeEntryReference(TIME_ENTRY_BASE);
            String approverEmail = String.isNotBlank(st.approverEmail) ? st.approverEmail : '';
            block.Comment = 'BSF: Approved by ' + approverEmail + ' | BSF GUID: ' + (String.isNotBlank(st.staffRecordId) ? st.staffRecordId : '');
            block.Delete_Time_Block = false;
            // If No Meal is selected on the staff record, add the custom worktag so Workday removes the lunch deduction.
            if (st.detail != null && st.detail.noMeal) {
                block.Custom_Worktag_01_Reference = '30 Min Deduct';
            }
            if (st.shiftStartGmt != null) {
                block.In_Date_Time = st.shiftStartGmt;
            }
            if (st.shiftEndGmt != null) {
                block.Out_Date_Time = st.shiftEndGmt;
            }
            result.blocks.add(block);
            Map<String, String> fmt = new Map<String, String>();
            if (inFormatted != null) {
                fmt.put('In_Date_Time', inFormatted);
            }
            if (outFormatted != null) {
                fmt.put('Out_Date_Time', outFormatted);
            }
            result.dateTimeFormats.add(fmt);
        }
        return result;
    }

    /**
     * Builds premium time blocks. One block per premium type per staff; quantity 1.
     * No In/Out time or timezone needed.
     */
    public static List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> buildPremiumTimeBlocks(
        List<BSF_OpsRecordToTimeBlockMapper.PremiumStaffContext> staffContexts,
        Date driveDate
    ) {
        List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> blocks = new List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType>();
        for (BSF_OpsRecordToTimeBlockMapper.PremiumStaffContext staffCtx : staffContexts) {
            if (staffCtx == null || staffCtx.detail == null) {
                continue;
            }
            skedOpsRecordApiData.opsRecordStaffDetail sd = staffCtx.detail;
            String empId = String.valueOf(sd.personID);
            if (empId == null || empId == '0') {
                continue;
            }
            String guid = staffCtx.staffRecordId;
            String approverEmail = String.isNotBlank(staffCtx.approverEmail) ? staffCtx.approverEmail : '';
            String comment = 'BSF: Approved by ' + approverEmail + (String.isNotBlank(guid) ? ' | BSF GUID: ' + guid : '');

            if (sd.premiumCharge) {
                blocks.add(buildPremiumBlock(empId, driveDate, TIME_ENTRY_CHARGE, comment));
            }
            if (sd.premiumDRC) {
                blocks.add(buildPremiumBlock(empId, driveDate, TIME_ENTRY_DRC, comment));
            }
            if (sd.premiumTranslator) {
                blocks.add(buildPremiumBlock(empId, driveDate, TIME_ENTRY_TRANSLATOR, comment));
            }
            if (sd.premiumDriver) {
                blocks.add(buildPremiumBlock(empId, driveDate, TIME_ENTRY_DRIVER, comment));
            }
            if (sd.premiumOJI) {
                blocks.add(buildPremiumBlock(empId, driveDate, TIME_ENTRY_OJI, comment));
            }
            if (sd.premiumLateEnd) {
                blocks.add(buildPremiumBlock(empId, driveDate, TIME_ENTRY_LATE_END, comment));
            }
            if (sd.restBreaksNotTaken != null && sd.restBreaksNotTaken > 0) {
                blocks.add(buildPremiumBlock(
                    empId,
                    driveDate,
                    TIME_ENTRY_CA_MISSED_SHORT_REST_BREAK,
                    comment,
                    sd.restBreaksNotTaken
                ));
            }
        }
        return blocks;
    }

    public class BaseTimeBlockResult {
        public List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> blocks;
        public List<Map<String, String>> dateTimeFormats;
    }

    private static skedWorkdayTimeTrackingBsvc.WorkerObjectType buildWorkerReference(String employeeId) {
        skedWorkdayTimeTrackingBsvc.WorkerObjectIDType idType = new skedWorkdayTimeTrackingBsvc.WorkerObjectIDType();
        idType.type_x = 'Employee_ID';
        idType.input = employeeId;
        skedWorkdayTimeTrackingBsvc.WorkerObjectType worker = new skedWorkdayTimeTrackingBsvc.WorkerObjectType();
        worker.ID = new List<skedWorkdayTimeTrackingBsvc.WorkerObjectIDType>{ idType };
        return worker;
    }

    private static skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType buildTimeEntryReference(String timeEntryCode) {
        skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType idType = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType();
        idType.type_x = 'Time_Code_Reference_ID';
        idType.input = timeEntryCode;
        skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType ref = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType();
        ref.ID = new List<skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType>{ idType };
        return ref;
    }

    private static skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType buildPremiumBlock(
        String employeeId,
        Date driveDate,
        String timeEntryCode,
        String comment
    ) {
        return buildPremiumBlock(employeeId, driveDate, timeEntryCode, comment, QUANTITY_PREMIUM);
    }

    private static skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType buildPremiumBlock(
        String employeeId,
        Date driveDate,
        String timeEntryCode,
        String comment,
        Decimal quantity
    ) {
        skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType block = new skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType();
        block.Worker_Reference = buildWorkerReference(employeeId);
        block.Date_x = driveDate;
        block.Time_Entry_Code_Reference = buildTimeEntryReference(timeEntryCode);
        block.Quantity = quantity;
        block.Comment = comment;
        block.Delete_Time_Block = false;
        return block;
    }
}