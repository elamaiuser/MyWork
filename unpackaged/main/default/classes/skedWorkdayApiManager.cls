public class skedWorkdayApiManager {
    static final String WD_JWT_AUD = 'wd';
    static final String WD_JWT_SUB = 'Skedulo ISU';

    static final String HTTP_METHOD_GET = 'GET';
    static final String HTTP_METHOD_POST = 'POST';

    private static String getAccessToken() {
        if (Test.isRunningTest()) return 'test-token';
        
        sked_Workday_Token_Credentials__c settings = sked_Workday_Token_Credentials__c.getOrgDefaults();
        Auth.JWT jwt = new Auth.JWT();
        jwt.setSub(WD_JWT_SUB);
        jwt.setAud(WD_JWT_AUD);
        jwt.setIss(settings.sked_Client_ID__c);
        Auth.JWS jws = new Auth.JWS(jwt, settings.sked_Certificate_Name__c);
        String token = jws.getCompactSerialization();
        Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(settings.sked_Token_Endpoint__c, jws);

        return bearer.getAccessToken();
    }

    private static HttpRequest getHttpRequest(String endpoint, String method) {
        HttpRequest request = new Httprequest();
        String authorizationHeader = 'Bearer ' + getAccessToken();
        request.setHeader('Authorization', authorizationHeader);
        request.setHeader('X-Frame-Options', 'SAMEORIGIN');
        request.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        request.setHeader('X-Content-Type-Options', 'nosniff');
        request.setHeader('Content-Security-Policy', 'default-src "self"');
        request.setHeader('Referrer-Policy', 'strict-origin');
        request.setHeader('Set-Cookie', 'secure; HttpOnly; Samesite=lax');
        request.setHeader('Access-Control-Allow-Methods', 'GET, POST HEAD');
        request.setEndpoint(endpoint);
        request.setMethod(method);

        return request;
    }

    public static processTimeOffResponse processTimeOffApproval(processTimeOffRequest ptoRequest) {
        sked_Workday_XML_Template__mdt xml = [
            SELECT Id, sked_Template__c, sked_Endpoint__c, sked_Namespace__c
            FROM sked_Workday_XML_Template__mdt
            WHERE DeveloperName = 'Push_Vacation_Approval'
        ];

        String xmlTemplate = xml.sked_Template__c;
        xmlTemplate = xmlTemplate.replaceAll('%EMPLOYEE_ID%', ptoRequest.employeeId);
        xmlTemplate = xmlTemplate.replaceAll('%COMMENT%', ptoRequest.comment == null ? '' : ptoRequest.comment);
        xmlTemplate = xmlTemplate.replace('%TIME_OFF_ID%', ptoRequest.ptoEntryId);
        xmlTemplate = xmlTemplate.replace('%PTO_DATE%', String.valueOf(ptoRequest.ptoDate));
        xmlTemplate = xmlTemplate.replace('%PTO_REASON%', ptoRequest.ptoReason);
        xmlTemplate = xmlTemplate.replace('%HOURS_REQUESTED%', ptoRequest.hoursRequested);

        HttpRequest req = getHttpRequest(xml.sked_Endpoint__c, HTTP_METHOD_POST);
        req.setBody(xmlTemplate);

        processTimeOffResponse result = new processTimeOffResponse();
        try {
            Http h = new Http();
            HttpResponse res = h.send(req);
    
            string response = res.getBody();
            integer statusCode = res.getStatusCode();

            if (statusCode != 200) {
                DOM.Document docx = new DOM.Document();
                docx.load(response);
        
                skedXMLUtils utils = new skedXMLUtils(xml.sked_Namespace__c);
                Dom.XmlNode fault = utils.getResponseBody(docx);
                result.isSuccess = false;
                result.faultString = utils.getChild(fault, 'faultstring').getText();
            } else {
                result.isSuccess = true;
            }
        } catch (Exception e) { 
            System.debug('CAUGHT EXCEPTION :: ' + e.getMessage());
        }

        return result;
    }

    public static void adjustTimeOff(adjustTimeOffRequest adjustPtoRequest) {
        sked_Workday_XML_Template__mdt xml = [
            SELECT Id, sked_Template__c, sked_Endpoint__c, sked_Namespace__c
            FROM sked_Workday_XML_Template__mdt
            WHERE DeveloperName = 'Adjust_Time_Off_Request'
        ];

        String xmlTemplate = xml.sked_Template__c;
        xmlTemplate = xmlTemplate.replaceAll('%EMPLOYEE_ID%', adjustPtoRequest.employeeId);
        xmlTemplate = xmlTemplate.replaceAll('%COMMENT%', adjustPtoRequest.comment);
        xmlTemplate = xmlTemplate.replace('%PTO_ID%', adjustPtoRequest.ptoEntryId);
        xmlTemplate = xmlTemplate.replace('%ADJUSTMENT%', adjustPtoRequest.adjustment);

        HttpRequest req = getHttpRequest(xml.sked_Endpoint__c, HTTP_METHOD_POST);
        req.setBody(xmlTemplate);

        Http h = new Http();
        HttpResponse res = h.send(req);

        string response = res.getBody();
        string status = res.getStatus();
        integer statusCode = res.getStatusCode();
    }


    public static getTimeOffReportResponse getTimeOffReport(getTimeOffReportRequest getTimeOffRequest) {
        sked_Workday_XML_Template__mdt xml = [
            SELECT Id, sked_Template__c, sked_Endpoint__c, sked_Namespace__c
            FROM sked_Workday_XML_Template__mdt
            WHERE DeveloperName = 'Get_Time_Off_Report'
        ];

        String xmlTemplate = xml.sked_Template__c;
        xmlTemplate = xmlTemplate.replace('%EMPLOYEE_ID%', getTimeOffRequest.employeeId);
        xmlTemplate = xmlTemplate.replace('%START_DATE%', String.valueOf(Date.newInstance(getTimeOffRequest.selectedYear, 1, 1)));
        xmlTemplate = xmlTemplate.replace('%END_DATE%', String.valueOf(Date.newInstance(getTimeOffRequest.selectedYear, 12, 31)));

        HttpRequest req = getHttpRequest(xml.sked_Endpoint__c, HTTP_METHOD_GET);
        req.setBody(xmlTemplate);

        getTimeOffReportResponse result = new getTimeOffReportResponse();
        try {
            Http h = new Http();
            HttpResponse res = h.send(req);
    
            string response = res.getBody();
            integer statusCode = res.getStatusCode();

            System.debug('RESPONSE :: ' + response);
    
            if (statusCode == 200) {
                DOM.Document docx = new DOM.Document();
                docx.load(response);
        
                skedXMLUtils utils = new skedXMLUtils(xml.sked_Namespace__c);
                Dom.XmlNode xreportData = utils.getResponseBody(docx);
                List<Dom.XmlNode> reportEntries = utils.getChildNodes(xreportData, 'Report_Entry');
        
                result.employeeId = getTimeOffRequest.employeeId;
                result.timeOffReports = new List<timeOffReport>();
                
                for (Dom.XmlNode reportEntry : reportEntries) {
                    List<Dom.XmlNode> timeOffDetails = utils.getChildNodes(reportEntry, 'Time_Off_Completed_Details_group');
                    for (Dom.XmlNode timeOffDetail : timeOffDetails) {
                        timeOffReport report = new timeOffReport();
                        Dom.XmlNode timeOffTypeNode = utils.getChild(timeOffDetail, 'Time_Off_Type_for_Time_Off_Entry');
                        List<Dom.XmlNode> timeOffTypeIds = utils.getChildNodes(timeOffTypeNode, 'ID');
                        for (Dom.XmlNode timeOffTypeId : timeOffTypeIds) {
                            if (utils.getAttribute(timeOffTypeId, 'type') == 'Time_Off_Type_ID') {
                                report.timeOffType = timeOffTypeId.getText();
                            }
                        }
                        
                        
                        report.timeoffDate = parseDate(utils.getChild(timeOffDetail, 'date').getText());
                        report.amount = Decimal.valueOf(utils.getChild(timeOffDetail, 'Amount').getText());
                        result.timeOffReports.add(report);
                    }
                }
            } else {
                throw new skedException('Request Failed');
            }
        } catch (Exception exc) {
            System.debug('EXCEPTION :: ' + exc.getMessage());
        }

        return result;
    }

    public static getTimeOffPlanBalancesResponse getTimeOffPlanBalances(getTimeOffPlanBalancesRequest ptoPlanBalanceRequest) {
        sked_Workday_XML_Template__mdt xml = [
            SELECT Id, sked_Endpoint__c, sked_Namespace__c
            FROM sked_Workday_XML_Template__mdt
            WHERE DeveloperName = 'Get_Time_Off_Plan_Balances'
        ];

        String endpoint = xml.sked_Endpoint__c.replace('%EMPLOYEE_ID%', ptoPlanBalanceRequest.employeeId);
        endpoint = endpoint.replace('%EFFECTIVE_DATE%', String.valueOf(Date.newInstance(ptoPlanBalanceRequest.selectedYear, 12, 31)));

        HttpRequest req = getHttpRequest(endpoint, HTTP_METHOD_GET);
 
        getTimeOffPlanBalancesResponse result = new getTimeOffPlanBalancesResponse();
        result.employeeId = ptoPlanBalanceRequest.employeeId;
        try {
            Http h = new Http();
            HttpResponse res = h.send(req);
    
            string response = res.getBody();
            integer statusCode = res.getStatusCode();
    
            if (statusCode == 200) {
                DOM.Document docx = new DOM.Document();
                docx.load(response);

                skedXMLUtils utils = new skedXMLUtils(xml.sked_Namespace__c);
                Dom.XmlNode xreportData = docx.getRootElement();
                List<Dom.XmlNode> reportEntries = utils.getChildNodes(xreportData, 'Report_Entry');
                for (Dom.XmlNode reportEntry : reportEntries) {
                    List<Dom.XmlNode> eligibleTimeOffPlans = utils.getChildNodes(reportEntry, 'Eligible_Time_Off_Plans_for_Worker_group');
                    for (Dom.XmlNode eligibleTimeOffPlan : eligibleTimeOffPlans) {
                        Dom.XmlNode timeOffPlan = utils.getChild(eligibleTimeOffPlan, 'time_off_plan');
                        if (utils.getAttribute(timeOffPlan, 'Descriptor').contains(skedConstants.UNAVAILABILITY_TYPE_PTO)) {
                            result.pto = new timeOffBalance(Decimal.valueOf(utils.getChild(eligibleTimeOffPlan, 'beg_period_bal').getText())); 
                        } else if (utils.getAttribute(timeOffPlan, 'Descriptor').contains(skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY)) {
                            result.floatingHoliday = new timeOffBalance(Decimal.valueOf(utils.getChild(eligibleTimeOffPlan, 'beg_period_bal').getText()));
                        }
                    }
                }

            }
        } catch (Exception exc) {
            System.debug('EXCEPTION :: ' + exc.getMessage());
        }

        return result;
    }

    /******************************************* Private method *******************************************/
    private static Date parseDate(String dateStr) {
        List<String> dateParts = dateStr.split('-');
        return Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
    }
    
    /******************************************* Nested Classes *******************************************/
    public class getTimeOffReportRequest {
        public String employeeId;
        public Integer selectedYear;
    }

    public class getTimeOffReportResponse {
        public String employeeId;
        public List<timeOffReport> timeOffReports;
    }

    public class timeOffReport {
        public Decimal amount;
        public Date timeOffDate;
        public String timeOffType;
    }

    public class processTimeOffRequest {
        public String employeeId;
        public String ptoEntryId;
        public Date ptoDate;
        public String hoursRequested;
        public String ptoReason;
        public String comment;
    }

    public class processTimeOffResponse {
        public Boolean isSuccess;
        public String faultString;
    }

    public class adjustTimeOffRequest {
        public String employeeId;
        public String ptoEntryId;
        public String adjustment;
        public String comment;
    }

    public class adjustTimeOffResponse {
        // TBC
    }

    public class getTimeOffPlanBalancesRequest {
        public String employeeId;
        public Integer selectedYear;
    }

    public class getTimeOffPlanBalancesResponse {
        public String employeeId;
        public timeOffBalance pto;
        public timeOffBalance floatingHoliday;

        public getTimeOffPlanBalancesResponse() {
            this.pto = new timeOffBalance();
            this.floatingHoliday = new timeOffBalance();
        }
    }

    public class timeOffBalance {
        public Decimal hoursLeft;
        public Decimal approved;
        public Decimal taken;

        public timeOffBalance() {
            this.hoursLeft = 0;
            this.approved = 0;
            this.taken = 0;
        }

        public timeOffBalance(Decimal hoursLeft) {
            this.hoursLeft = hoursLeft;
            this.approved = 0;
            this.taken = 0;
        }
    }
}