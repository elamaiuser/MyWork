public class skedWorkdayImportTimeBlockRequest extends skedWorkdayApiRequest {
    public Date shiftTradeDate;
    public String timeEntryCode;
    public String comment;
    public Decimal quantity;

    public skedWorkdayImportTimeBlockRequest(String resourceId, String employeeId, String timeEntryCode, String approverEmail, Decimal quantity, Date shiftTradeDate) {
        super(resourceId, employeeId);
        this.shiftTradeDate = shiftTradeDate;
        this.comment = 'BSF: Approved By ' + approverEmail;
        this.quantity = quantity;
        this.timeEntryCode = timeEntryCode;
    }
}