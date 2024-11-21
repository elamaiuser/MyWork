public class skedWorkdayTimeTracking {
	public string endpoint_x;
	public string version;

	private static final String s_ns0 = 'urn:com.workday/bsvc';
	private static final String nsBsvc = 'xmlns:bsvc';
	public Map<String,String> inputHttpHeaders_x;
	public Map<String,String> outputHttpHeaders_x;
	public String clientCertName_x;
	public String clientCert_x;
	public String clientCertPasswd_x;
	public Integer timeout_x;
	public skedWorkdayTimeTrackingBsvc.Workday_Common_HeaderType header;
	private transient String header_hns = 'header=urn:com.workday/bsvc';
	private transient String[] ns_map_type_info = new String[]{'urn:com.workday/bsvc','skedWorkdayTimeTrackingBsvc'};

	public skedWorkdayTimeTracking() {
		sked_Workday_XML_Template__mdt xml = [
			SELECT Id, sked_Endpoint__c, sked_Namespace__c, sked_Version__c
			FROM sked_Workday_XML_Template__mdt 
			WHERE DeveloperName = 'Time_Tracking'
		];
		this.version = xml.sked_Version__c;
		this.endpoint_x = xml.sked_Endpoint__c + this.version;
	}

	public HttpResponse Import_Reported_Time_Blocks_Http(skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType[] Reported_Time_Block_Data) {
		DOM.Document doc = new DOM.Document();
		DOM.XmlNode body = skedWorkdayApiManager.populateDoc(doc);
		DOM.XmlNode methodNode = body.addChildElement('Import_Reported_Time_Blocks_Request', s_ns0, 'bsvc');
		methodNode.setAttribute(nsBsvc, s_ns0);
		methodNode.setAttribute('bsvc:version', version);	
		skedWorkdayTimeTrackingBsvc.Import_Reported_Time_Blocks_RequestType request_x = new skedWorkdayTimeTrackingBsvc.Import_Reported_Time_Blocks_RequestType(Reported_Time_Block_Data);
		request_x.populateXmlNode(methodNode);
		
		HttpRequest req = skedWorkdayApiManager.getHttpRequest(endpoint_x, 'POST');
		req.setBodyDocument(doc);
		Http http = new Http();
		return http.send(req);
	}
}