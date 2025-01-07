public class skedWorkdayGetTimeOffReportRequest extends skedWorkdayApiRequest {
    public Date startDate;
    public Date endDate;

    public skedWorkdayGetTimeOffReportRequest(Id resourceId, String employeeId, Date startDate, Date endDate) {
        super(resourceId, employeeId);
        this.startDate = startDate;
        this.endDate = endDate;
    }
}