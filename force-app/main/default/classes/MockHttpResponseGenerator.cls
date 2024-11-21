@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
        System.assertEquals('https://siteplanrest.azurewebsites.net/api/GetSitePlan', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Accept','/');
        res.setHeader('x-functions-key', 'testkey-qwhIeXVcejhbAzFuF4Oxlw==');
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"image":"test"}');
        res.setStatusCode(200);
        return res;
    }
}