@isTest
public class skedImportReportedTimeBlocksMock implements HttpCalloutMock {
    public skedImportReportedTimeBlocksMock() {}

    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('<?xml version="1.0" encoding="UTF-8"?>' + 
        '<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">' + 
            '<env:Body><wd:Put_Import_Process_Response xmlns:wd="urn:com.workday/bsvc" wd:version="v42.2">' +
                '<wd:Import_Process_Reference>' +
                    '<wd:ID wd:type="WID">e1b65a4f1bc3101507d1e4e57f090000</wd:ID>' + 
                '</wd:Import_Process_Reference>' +
            '</wd:Put_Import_Process_Response>' +
        '</env:Body></env:Envelope>'
        );
        res.setStatusCode(200);
        return res;
    }
}