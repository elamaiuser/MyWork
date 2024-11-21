@isTest
global class skedWorkdayPTOApprovalMock_Invalid implements HttpCalloutMock {
    String errorMsg;

    global skedWorkdayPTOApprovalMock_Invalid(String errorMsg) {
        this.errorMsg = errorMsg;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(
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
        res.setStatusCode(500);
        return res;
    }
}