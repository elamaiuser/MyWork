public class skedWorkdayAbsenceManagement {
	public String endpoint_x;
	public String version;

	private static final String s_ns0 = 'urn:com.workday/bsvc';
	private static final String nsBsvc = 'xmlns:bsvc';
	public Map<String,String> inputHttpHeaders_x;
	public Map<String,String> outputHttpHeaders_x;
	public String clientCertName_x;
	public String clientCert_x;
	public String clientCertPasswd_x;
	public Integer timeout_x;
	public String requestXML;//HRP-13728
	public skedWorkdayAbsenceManagementBsvc.Workday_Common_HeaderType header;
	private transient String header_hns = 'header=urn:com.workday/bsvc';
	private transient String[] ns_map_type_info = new String[]{s_ns0,'skedWorkdayAbsenceManagementBsvc'};

	public skedWorkdayAbsenceManagement() {
		sked_Workday_XML_Template__mdt xml = [
			SELECT Id, sked_Endpoint__c, sked_Namespace__c, sked_Version__c
			FROM sked_Workday_XML_Template__mdt 
			WHERE DeveloperName = 'Absence_Management'
		];
		this.version = xml.sked_Version__c;
		this.endpoint_x = xml.sked_Endpoint__c + this.version;
	}

	public HttpResponse Adjust_Time_Off_Http(skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_Parameters,skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_DataType Adjust_Time_Off_Data) {
		DOM.Document doc = new DOM.Document();
		DOM.XmlNode body = skedWorkdayApiManager.populateDoc(doc);
		DOM.XmlNode methodNode = body.addChildElement('Adjust_Time_Off_Request', s_ns0, 'bsvc');	
		methodNode.setAttribute(nsBsvc, s_ns0);
		methodNode.setAttribute('bsvc:version', version);		
		skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_RequestType request_x = new skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_RequestType(Business_Process_Parameters,Adjust_Time_Off_Data);
		request_x.populateXmlNode(methodNode);
		requestXML = skedWorkdayUtils.fetchXML(doc);//-----------HRP-13728
		
		HttpRequest req = skedWorkdayApiManager.getHttpRequest(endpoint_x, 'POST');
		req.setBodyDocument(doc);
		Http http = new Http();
		return http.send(req);
	}

	public HttpResponse Enter_Time_Off_Http(skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType Business_Process_Parameters, skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_DataType Enter_Time_Off_Data) {
		DOM.Document doc = new DOM.Document();
		DOM.XmlNode body = skedWorkdayApiManager.populateDoc(doc);
		DOM.XmlNode methodNode = body.addChildElement('Enter_Time_Off_Request', s_ns0, 'bsvc');
		methodNode.setAttribute(nsBsvc, s_ns0);
		methodNode.setAttribute('bsvc:version', version);
		skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_RequestType request_x = new skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_RequestType(Business_Process_Parameters,Enter_Time_Off_Data);
		request_x.populateXmlNode(methodNode);
		requestXML = skedWorkdayUtils.fetchXML(doc);//-----------HRP-13728
		
		HttpRequest req = skedWorkdayApiManager.getHttpRequest(endpoint_x, 'POST');
		req.setBodyDocument(doc);
		Http http = new Http();
		return http.send(req);
	}
}