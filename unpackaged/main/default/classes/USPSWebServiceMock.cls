@isTest
global class USPSWebServiceMock implements WebServiceMock{
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
               	   System.debug('entered doInvoke->');

       ARCAddressStdProtectedSvcWsdl.addr_std_assessResponseElement respElement = new ARCAddressStdProtectedSvcWsdl.addr_std_assessResponseElement();
       respElement.cln_cnst_line1_addr = '2204 Westcourt Ln';
       respElement.cln_cnst_line2_addr = 'Apt 218';
       respElement.cln_cnst_city_nm = 'Herndon';
       respElement.cln_cnst_state_cd = 'VA';
       respElement.cln_cnst_zip_5 = '20170';
       respElement.USSpecificDeliveryPointValidationConfirmation = 'Y';
        
	   System.debug('respElement created->'+respElement);
       ARCAddressStdProtectedSvcWsdl.addr_std_assesResponseType respType = new ARCAddressStdProtectedSvcWsdl.addr_std_assesResponseType();
       respType.addr_std_assessResponseElement = respElement;
       /*docSample.EchoStringResponse_element respElement = 
           new docSample.EchoStringResponse_element();
       respElement.EchoStringResult = 'Mock response';*/
       response.put('response_x', respType); 
   }
}