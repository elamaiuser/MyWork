@isTest
public class skedWorkdayPTOApprovalMock implements HttpCalloutMock {
    String errorMsg;
    Boolean isErrorMode;

    public skedWorkdayPTOApprovalMock() {
        this.isErrorMode = false;
    }

    public skedWorkdayPTOApprovalMock(String errorMsg) {
        this.isErrorMode = true;
        this.errorMsg = errorMsg;
    }
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(!this.isErrorMode ? '' : 
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<SOAP-ENV:Body>' +
                    '<SOAP-ENV:Fault xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wd="urn:com.workday/bsvc">' +
                        '<faultcode>SOAP-ENV:Client.validationError</faultcode>' +
                        '<faultstring>' + this.errorMsg + '</faultstring>' +
                    '</SOAP-ENV:Fault>' +
                '</SOAP-ENV:Body>' +
            '</SOAP-ENV:Envelope>'
        );
        res.setStatusCode(this.isErrorMode ? 500 : 200);
        return res;
    }
}