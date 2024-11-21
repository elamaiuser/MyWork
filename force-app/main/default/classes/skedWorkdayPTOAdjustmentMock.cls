@isTest
public class skedWorkdayPTOAdjustmentMock implements HttpCalloutMock {
    String errorMsg;
    Boolean isErrorMode;

    public skedWorkdayPTOAdjustmentMock() {
        this.isErrorMode = false;
    }

    public skedWorkdayPTOAdjustmentMock(String errorMsg) {
        this.isErrorMode = true;
        this.errorMsg = errorMsg;
    }
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        if (!this.isErrorMode) {
            res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
                '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<env:Body>' +
                        '<wd:Time_Off_Event_Response xmlns:wd="urn:com.workday/bsvc" wd:version="v31.0">' +
                            '<wd:Time_Off_Event_Reference>' +
                                '<wd:ID wd:type="WID">902cb04ce6da1009fc5318078e560000</wd:ID>' +
                            '</wd:Time_Off_Event_Reference>' +
                            '<wd:Time_Off_Entry_References>' +
                                '<wd:Time_Off_Entry_Reference>' +
                                    '<wd:ID wd:type="WID">902cb04ce6da1009fc5318a10a450000</wd:ID>' +
                                    '<wd:ID wd:type="Time_Off_Entry_ID">TIME_OFF_ENTRY-6-5169359</wd:ID>' +
                                '</wd:Time_Off_Entry_Reference>' +
                            '</wd:Time_Off_Entry_References>' +
                        '</wd:Time_Off_Event_Response>' +
                    '</env:Body>' +
                '</env:Envelope>'
            );
        }

        if (this.isErrorMode) {
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
        }
        res.setStatusCode(this.isErrorMode ? 500 : 200);
        return res;
    }
}