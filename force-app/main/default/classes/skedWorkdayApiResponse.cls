public abstract class skedWorkdayApiResponse {
    public Integer statusCode;
    public Id resourceId;
    public String employeeId;
    public Boolean isSuccess;
    public String message;
    public String request;
    public String response;


    public skedWorkdayApiResponse(String request) {
        this.message = 'Success';
        this.request = request;
        this.isSuccess = true;
    }
}