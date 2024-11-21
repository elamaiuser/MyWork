public abstract class skedWorkdayApiRequest {
    public Id resourceId;
    public String employeeId;

    public skedWorkdayApiRequest() {}

    public skedWorkdayApiRequest(Id resourceId, String employeeId) {
        this.resourceId = resourceId;
        this.employeeId = employeeId;
    }
}