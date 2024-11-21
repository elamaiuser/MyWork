public class skedCalloutException extends Exception {
    
    public integer statusCode;
    public string status;
    public string response;
    
    public skedCalloutException(integer statusCode, string status, string response) {
        this.statusCode = statusCode;
        this.status = status;
        this.response = response;
    }

}