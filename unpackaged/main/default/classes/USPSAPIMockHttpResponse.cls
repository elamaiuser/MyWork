@isTest
global class USPSAPIMockHttpResponse implements HttpCalloutMock {

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        System.debug('Entered mock API');
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('http://example.com/example/test', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();

        if(req.getEndpoint().contains('http://www.informatica.com/wsdl/')){
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{ "cln_cnst_line1_addr": "2204 Westcourt Ln", "cln_cnst_line2_addr": "Apt 218", "cln_cnst_city_nm": "Herndon", "cln_cnst_state_cd": "VA", "cln_cnst_zip_5": "20170", "USSpecificDeliveryPointValidationConfirmation": "Y" }');
        res.setStatusCode(200);
         }
    
            return res;

    }
}