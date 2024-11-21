public with sharing class InformaticaAddressStandardization {
    public static InformaticaStandardAddress getStandardAddress(InputAddress inputAddress) {
        InformaticaStandardAddress result = null;
        /*if(Test.isRunningTest()){ 
            result = new InformaticaStandardAddress();
                result.Line1 = '2204 Westcourt Ln';
                result.Line2 = 'Apt 218';
                result.City = 'Herndon';
                result.State = 'VA';
                result.Zip = '20170';
                result.DeliveryPointConfirmation = 'y';

                return result;
        } */ 

		try{
            ARCAddressStdProtectedSvcWsdl.addr_std_assesRequestElement_element req = new ARCAddressStdProtectedSvcWsdl.addr_std_assesRequestElement_element();
            req.addr_line1 = inputAddress.addressLine1;
            req.addr_line2 = inputAddress.addressLine2;
            /*if(String.isNotBlank(addressToStandardize.unitNumber)){
                req.addr_line2 = addressToStandardize.unitNumber;
            }*/
            
            req.city = inputAddress.city;
            req.state = inputAddress.State;
            req.zip5 = inputAddress.zip5;
            req.country_name = 'US';

            // Configure the proxy call
            ARCAddressStdProtectedSvc.wkf_idq_addr_std_assessmentPort proxy = new ARCAddressStdProtectedSvc.wkf_idq_addr_std_assessmentPort();
            proxy.timeout_x = 20000; 
            proxy.Security = new ARCAddressStdProtectedSvc.SecurityHeader();
            proxy.Security.UsernameToken = new ARCAddressStdProtectedSvc.UsernameToken_element();
            proxy.Security.UsernameToken.Username = '{!$Credential.UserName}';
            proxy.Security.UsernameToken.Password = '{!$Credential.Password}';

            ARCAddressStdProtectedSvcWsdl.addr_std_assessResponseElement resp = null;
            try {
                resp = proxy.wkf_idq_addr_std_assessmentOperation(req);
                System.debug('response->'+resp);
                System.debug('Is USPS Delivery Point Confirmation->'+resp.USSpecificDeliveryPointValidationConfirmation);
                String jsonFormatString = JSON.serializePretty(resp);
                System.debug('the string is'+jsonFormatString);
            }
            catch(System.CalloutException calloutEx) {
                resp = null;
                String exMsg = calloutEx.getMessage();
                System.debug('InformaticaAddressStandarization.getStandardAddress() - ' + exMsg);
                if(String.isNotBlank(exMsg)) {
                    exMsg.contains('Read timed out');
                    System.debug('InformaticaAddressStandarization.getStandardAddress() - Timed out.');
                }
                
            }
               
            // Process response
            if(resp != null && resp.cln_cnst_line1_addr != null){ 
            	result = new InformaticaStandardAddress();
                result.Line1 = resp.cln_cnst_line1_addr;
            	if(String.isNotBlank(resp.cln_cnst_line2_addr)) { 
                    result.Line2 = resp.cln_cnst_line2_addr; 
                }
                result.City = resp.cln_cnst_city_nm;
                result.State = resp.cln_cnst_state_cd;
                result.Zip = resp.cln_cnst_zip_5;
                result.DeliveryPointConfirmation = resp.USSpecificDeliveryPointValidationConfirmation;
                result.DeliveryPointFootnote1 = resp.USSpecificDeliveryPointValidationFootnote1;
                result.DeliveryPointFootnote2 = resp.USSpecificDeliveryPointValidationFootnote2;
                result.HighRise = resp.USSpecificHighRiseDefault;
                result.Latitude = resp.GeoCodingLatitude;
                result.Longitude = resp.GeoCodingLongitude;
                result.GeoCodingStatus = resp.GeoCodingGeocodingStatus;
           	}
        } catch (Exception ex){
        	System.debug('InformaticaAddressStandarization.getStandardAddress() - ' + ex.getMessage());
        }
		system.debug('result from the call'+result);
        return result;
    }
}