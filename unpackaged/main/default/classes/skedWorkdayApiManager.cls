public class skedWorkdayApiManager {
    static final String WD_JWT_AUD = 'wd';
    static final String WD_JWT_SUB = 'Skedulo ISU';

    static final String HTTP_METHOD_GET = 'GET';
    static final String HTTP_METHOD_POST = 'POST';

    public static String getAccessToken() {
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

    public static DOM.XmlNode populateDoc(DOM.Document doc){
		String soapenv = 'http://schemas.xmlsoap.org/soap/envelope/';
		String wsse = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd';
		String bsvc = 'urn:com.workday/bsvc';
		
		DOM.XmlNode envelope = doc.createRootElement('Envelope', soapenv, 'soapenv');
		envelope.setNamespace('wsse', wsse);
		envelope.setNamespace('bsvc', bsvc);
		DOM.XmlNode header = envelope.addChildElement('Header', soapenv, 'soapenv');
		DOM.XmlNode body = envelope.addChildElement('Body', soapenv, 'soapenv');
		return body;
	}

    public static HttpRequest getHttpRequest(String endpoint, String method) {
        HttpRequest request = new Httprequest();
        String authorizationHeader = 'Bearer ' + getAccessToken();
        request.setHeader('Authorization', authorizationHeader);
        request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        request.setHeader('X-Frame-Options', 'SAMEORIGIN');
        request.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        request.setHeader('X-Content-Type-Options', 'nosniff');
        request.setHeader('Content-Security-Policy', 'default-src "self"');
        request.setHeader('Content-Type', 'application/xml; charset=UTF-8');
        request.setHeader('Referrer-Policy', 'strict-origin');
        request.setHeader('Set-Cookie', 'secure; HttpOnly; Samesite=lax');
        request.setHeader('Access-Control-Allow-Methods', 'GET, POST HEAD');
        request.setTimeout(20000);
        request.setEndpoint(endpoint);
        request.setMethod(method);

        return request;
    }

    public static skedWorkdayEnterTimeOffResponse EnterTimeOff(skedWorkdayEnterTimeOffRequest ptoRequest) {
        skedWorkdayAbsenceManagement absenceManagement = new skedWorkdayAbsenceManagement();
        skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType businessProcessParams = new skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType();
        businessProcessParams.Auto_Complete = true;
        businessProcessParams.Run_Now = true;
        businessProcessParams.Discard_On_Exit_Validation_Error = false;

        skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType employeeId = new skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType();
        employeeId.type_x = 'Employee_ID';
        employeeId.input = ptoRequest.employeeId;

        skedWorkdayAbsenceManagementBsvc.WorkerObjectType workerReference = new skedWorkdayAbsenceManagementBsvc.WorkerObjectType();
        workerReference.ID = new List<skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType>();
        workerReference.ID.add(employeeId);

        
        List<skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_Entry_DataType> enterTimeOffEntryData = new List<skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_Entry_DataType>();
        for (skedWorkdayEnterTimeOffRequest.skedWorkdayTimeOffEntry timeOffEntry : ptoRequest.timeOffEntries) {
            skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_Entry_DataType timeOffEntryData = new skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_Entry_DataType();
            timeOffEntryData.Time_Off_Entry_ID = timeOffEntry.ptoEntryId;
            timeOffEntryData.Date_x = timeOffEntry.ptoDate;
            timeOffEntryData.Requested = timeOffEntry.hoursRequested;
            timeOffEntryData.Comment = timeOffEntry.comment;
            skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectIDType timeOffTypeId = new skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectIDType();
            timeOffTypeId.type_x = 'Time_Off_Type_ID';
            timeOffTypeId.input = timeOffEntry.timeOffType;
    
            skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectType timeOffType = new skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectType();
            timeOffType.ID = new List<skedWorkdayAbsenceManagementBsvc.Time_Off_TypeObjectIDType>();
            timeOffType.ID.add(timeOffTypeId);
            timeOffEntryData.Time_Off_Type_Reference = timeOffType;
    
            if (timeOffEntry.timeOffType != skedConstants.UNAVAILABILITY_TYPE_BEREAVEMENT) {
                skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectIDType timeOffReasonId = new skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectIDType();
                timeOffReasonId.type_x = 'Time_Off_Reason_ID';
                timeOffReasonId.input = timeOffEntry.ptoReason;
                
                skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectType timeOffReason = new skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectType();
                timeOffReason.ID = new List<skedWorkdayAbsenceManagementBsvc.Time_Off_ReasonObjectIDType>();
                timeOffReason.ID.add(timeOffReasonId);
                timeOffEntryData.Time_Off_Reason_Reference = timeOffReason;
            }
            enterTimeOffEntryData.add(timeOffEntryData);
        }

        skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_DataType enterTimeOffData = new skedWorkdayAbsenceManagementBsvc.Enter_Time_Off_DataType();
        enterTimeOffData.Turn_Off_Run_Time_Calculations_with_Time_Off_Approval = true;
        enterTimeOffData.Enter_Time_Off_Entry_Data = enterTimeOffEntryData;
        enterTimeOffData.Run_Time_Off_Validations = true;
        enterTimeOffData.Worker_Reference = workerReference;

        skedWorkdayEnterTimeOffResponse result = new skedWorkdayEnterTimeOffResponse(JSON.serialize(enterTimeOffData));
        try {
            HttpResponse res = absenceManagement.Enter_Time_Off_Http(businessProcessParams, enterTimeOffData);
            Dom.Document responseDoc = res.getBodyDocument();
            Dom.XmlNode rootNode = responseDoc.getRootElement();
            result.response = res.getBody();
            result.statusCode = res.getStatusCode();

            if (res.getStatusCode() != 200) {
                Dom.XmlNode bodyNode = rootNode.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XmlNode faultNode = bodyNode.getChildElement('Fault', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XmlNode faultStringNode = faultNode.getChildElement('faultstring', null);
                String faultString = getBsfErrorMessage(faultStringNode.getText());
                result.isSuccess = false;
                result.message = faultString;
            }
		} catch (Exception exc) {
            result.isSuccess = false;
            result.message = exc.getMessage();
		}

        return result;
    }

    public static skedWorkdayAdjustTimeOffResponse AdjustTimeOff(skedWorkdayAdjustTimeOffRequest adjustPtoRequest) {
        skedWorkdayAbsenceManagement absenceManagement = new skedWorkdayAbsenceManagement();
        skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType businessProcessParams = new skedWorkdayAbsenceManagementBsvc.Business_Process_ParametersType();
        businessProcessParams.Auto_Complete = true;
        businessProcessParams.Run_Now = true;
        businessProcessParams.Discard_On_Exit_Validation_Error = false;

        skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType employeeId = new skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType();
        employeeId.type_x = 'Employee_ID';
        employeeId.input = adjustPtoRequest.employeeId;

        skedWorkdayAbsenceManagementBsvc.WorkerObjectType workerReference = new skedWorkdayAbsenceManagementBsvc.WorkerObjectType();
        workerReference.ID = new List<skedWorkdayAbsenceManagementBsvc.WorkerObjectIDType>();
        workerReference.ID.add(employeeId);

        List<skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_Entry_DataType> adjustTimeOffEntryData = new List<skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_Entry_DataType>();
        for (skedWorkdayAdjustTimeOffRequest.skedWorkdayAdjustTimeOffEntry timeOffEntry : adjustPtoRequest.adjustTimeOffEntries) {
            skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectType timeOffEntryReference = new skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectType();
            timeOffEntryReference.ID = new List<skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectIDType>();
            
            skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectIDType timeOffEntryId = new skedWorkdayAbsenceManagementBsvc.Time_Off_EntryObjectIDType();
            timeOffEntryId.type_x = 'Time_Off_Entry_ID'; 
            timeOffEntryId.input = timeOffEntry.ptoEntryId;
            timeOffEntryReference.ID.add(timeOffEntryId);

            skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_Entry_DataType adjustTimeOffEntry = new skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_Entry_DataType();
            adjustTimeOffEntry.Adjustment_to_Requested =  timeOffEntry.adjustment;
            adjustTimeOffEntry.Comment = timeOffEntry.comment;
            adjustTimeOffEntry.Time_Off_Entry_Reference = timeOffEntryReference;
            adjustTimeOffEntryData.add(adjustTimeOffEntry);
        }

        skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_DataType adjustTimeOffData = new skedWorkdayAbsenceManagementBsvc.Adjust_Time_Off_DataType();
        adjustTimeOffData.Adjust_Time_Off_Entry_Data = adjustTimeOffEntryData;
        adjustTimeOffData.Worker_Reference = workerReference;
        
        skedWorkdayAdjustTimeOffResponse result = new skedWorkdayAdjustTimeOffResponse(JSON.serialize(adjustTimeOffData));
        try {
            HttpResponse res = absenceManagement.Adjust_Time_Off_Http(businessProcessParams, adjustTimeOffData);
            Dom.Document responseDoc = res.getBodyDocument();
            Dom.XmlNode rootNode = responseDoc.getRootElement();
            result.response = res.getBody();
            result.statusCode = res.getStatusCode();

            if (res.getStatusCode() != 200) {
                Dom.XmlNode bodyNode = rootNode.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XmlNode faultNode = bodyNode.getChildElement('Fault', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XmlNode faultStringNode = faultNode.getChildElement('faultstring', null);
                String faultString = getBsfErrorMessage(faultStringNode.getText());
                result.isSuccess = false;
                result.message = faultString;
            }
		} catch (Exception exc) {
            result.isSuccess = false;
            result.message = exc.getMessage();
		}

        return result;
    }

    public static skedWorkdayGetPlanBalanceResponse getTimeOffPlanBalances(skedWorkdayGetPlanBalanceRequest ptoPlanBalanceRequest) {
        sked_Workday_XML_Template__mdt xml = [
            SELECT Id, sked_Endpoint__c, sked_Namespace__c
            FROM sked_Workday_XML_Template__mdt
            WHERE DeveloperName = 'Get_Time_Off_Plan_Balances'
        ];

        String endpoint = xml.sked_Endpoint__c.replace('%EMPLOYEE_ID%', ptoPlanBalanceRequest.employeeId);
        endpoint = endpoint.replace('%EFFECTIVE_DATE%', String.valueOf(ptoPlanBalanceRequest.selectedDate));

        HttpRequest req = getHttpRequest(endpoint, HTTP_METHOD_GET);
        String logCategory;
        skedWorkdayGetPlanBalanceResponse result = new skedWorkdayGetPlanBalanceResponse(req.getEndpoint(), ptoPlanBalanceRequest.isCallOut);
        try {
            Http h = new Http();
            HttpResponse res = h.send(req);
            string response = res.getBody();
            integer statusCode = res.getStatusCode();
            result.response = response;
    
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
                        String timeOffPlanDescription = utils.getAttribute(timeOffPlan, 'Descriptor');
                        String planLabel = getPlanLabel(timeOffPlanDescription);
                        Decimal planBalance = Decimal.valueOf(utils.getInnerText(eligibleTimeOffPlan, 'balance'));
                        if (result.timeOffPlansByLabel.containsKey(planLabel)) {
                            result.timeOffPlansByLabel.put(planLabel, new skedWorkdayGetPlanBalanceResponse.timeOffPlan(planLabel, planBalance));
                        }
                    }

                    List<Dom.XmlNode> eligibleTimeOffsForWorkerGroups = utils.getChildNodes(reportEntry, 'All_Eligible_Time_Offs_for_Worker_group');
                    for (Dom.XmlNode eligibleTimeOffReason : eligibleTimeOffsForWorkerGroups) {
                        Dom.XmlNode timeOffReasonsPlan = utils.getChild(eligibleTimeOffReason, 'plan');
                        String planName = getPlanLabel(utils.getAttribute(timeOffReasonsPlan, 'Descriptor'));

                        if (result.timeOffPlansByLabel.containsKey(planName)) {
                            skedWorkdayGetPlanBalanceResponse.timeOffPlan plan = result.timeOffPlansByLabel.get(planName);
                            List<Dom.XmlNode> timeOffReasons = utils.getChildNodes(eligibleTimeOffReason, 'Time_Off_Reasons');
                            for (Dom.XmlNode timeOffReason : timeOffReasons) {
                                String timeOffReasonLabel = utils.getAttribute(timeOffReason, 'Descriptor');
                                if (timeOffReasonLabel.toLowerCase().contains('planned')) {
                                    if (ptoPlanBalanceRequest.isCallOut && timeOffReasonLabel.toLowerCase() != 'unplanned') continue;
                                    Boolean isDefault = getIsDefaultTimeOffReasonCode(timeOffReasonLabel);
                                    List<Dom.XmlNode> timeOffReasonIds = utils.getChildNodes(timeOffReason, 'ID');
                                    for (Dom.XmlNode timeOffReasonId : timeOffReasonIds) {
                                        if (utils.getAttribute(timeOffReasonId, 'type') == 'Time_Off_Reason_ID') {
                                            String timeOffReasonCode = String.valueOf(timeOffReasonId.getText());
                                            plan.timeOffReasons.add(new skedWorkdayGetPlanBalanceResponse.timeOffReason(timeOffReasonLabel, timeOffReasonCode, isDefault));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // If they don't have a sick plan - add a clone of PTO to their sick bank.
                skedWorkdayGetPlanBalanceResponse.timeOffPlan sickPlan = result.timeOffPlansByLabel.get(skedConstants.UNAVAILABILITY_TYPE_SICK);
                skedWorkdayGetPlanBalanceResponse.timeOffPlan ptoPlan = result.timeOffPlansByLabel.get(skedConstants.AVAILABILITY_TYPE_PTO);
                if (sickPlan == null) {
                    sickPlan = ptoPlan.clone(skedConstants.UNAVAILABILITY_TYPE_SICK);
                    sickPlan.balance = 0;
                    result.timeOffPlansByLabel.put(skedConstants.UNAVAILABILITY_TYPE_SICK, sickPlan);
                }
            } else {
                logCategory = statusCode >= 500 ? skedConstants.DEBUG_LOG_CATEGORY_SYSTEM_ERROR : skedConstants.DEBUG_LOG_CATEGORY_VALIDATION_ERROR;
                result.isSuccess = false;
                result.message = res.getBody();
            }
        } catch (Exception exc) {
            logCategory = skedConstants.DEBUG_LOG_CATEGORY_SYSTEM_ERROR;
            result.isSuccess = false;
            result.message = exc.getMessage();
        }

        if (skedSetting.instance.admin.enableWorkdayLogging) {
            sked__Debug_Log__c debugLog = new sked__Debug_Log__c();
            debugLog.sked__Type__c = skedConstants.DEBUG_LOG_TYPE_WORKDAY_API;
            debugLog.sked__Summary__c = 'Get Time Off Plan Balances';
            debugLog.sked__Message__c = result.toString();
            debugLog.sked_Request__c = req.getEndpoint();
            debugLog.sked_Response__c = result.response;
            debugLog.sked_Resource__c = ptoPlanBalanceRequest.resourceId;
            if (logCategory != null) {
                debugLog.sked_Category__c = logCategory;
            }

            insert debugLog;
        }

        return result;
    }

    public static skedWorkdayImportTimeBlockResponse ImportReportedTimeBlocks(List<skedWorkdayImportTimeBlockRequest> requests) {
        skedWorkdayTimeTracking timeTracking = new skedWorkdayTimeTracking();
        List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType> reportedTimeBlockDataList = new List<skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType>();

        for (skedWorkdayImportTimeBlockRequest request : requests) {
            skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType reportedTimeBlockData = new skedWorkdayTimeTrackingBsvc.Reported_Time_Block_DataType();
    
            skedWorkdayTimeTrackingBsvc.WorkerObjectIDType employeeId = new skedWorkdayTimeTrackingBsvc.WorkerObjectIDType();
            employeeId.type_x = 'Employee_ID';
            employeeId.input = request.employeeId;
    
            skedWorkdayTimeTrackingBsvc.WorkerObjectType workerReference = new skedWorkdayTimeTrackingBsvc.WorkerObjectType();
            workerReference.ID = new List<skedWorkdayTimeTrackingBsvc.WorkerObjectIDType>();
            workerReference.ID.add(employeeId);
    
            skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType timeEntryCodeId = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType();
            timeEntryCodeId.type_x = 'Time_Code_Reference_ID';
            timeEntryCodeId.input = request.timeEntryCode;
    
            skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType timeEntryCode = new skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectType();
            timeEntryCode.ID = new List<skedWorkdayTimeTrackingBsvc.Time_Entry_CodeObjectIDType>();
            timeEntryCode.ID.add(timeEntryCodeId);
    
            reportedTimeBlockData.Quantity = request.quantity;
            reportedTimeBlockData.Date_x = request.shiftTradeDate;
            reportedTimeBlockData.Comment = request.comment;
            reportedTimeBlockData.Delete_Time_Block = false;
            reportedTimeBlockData.Worker_Reference = workerReference;
            reportedTimeBlockData.Time_Entry_Code_Reference = timeEntryCode;
    
            reportedTimeBlockDataList.add(reportedTimeBlockData);
        }

        skedWorkdayImportTimeBlockResponse result = new skedWorkdayImportTimeBlockResponse(JSON.serialize(reportedTimeBlockDataList));
        try {
            HttpResponse res = timeTracking.Import_Reported_Time_Blocks_Http(reportedTimeBlockDataList);
            Dom.Document responseDoc = res.getBodyDocument();
            Dom.XmlNode rootNode = responseDoc.getRootElement();
            result.response = res.getBody();
            result.statusCode = res.getStatusCode();

            if (res.getStatusCode() != 200) {
                Dom.XmlNode bodyNode = rootNode.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XmlNode faultNode = bodyNode.getChildElement('Fault', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XmlNode faultString = faultNode.getChildElement('faultstring', null);
                result.isSuccess = false;
                result.message = res.getStatusCode() + ': ' + faultString.getText();
            }
		} catch (Exception exc) {
            result.isSuccess = false;
            result.message = exc.getMessage();
		}

        return result;
    }

    /******************************************* Private method *******************************************/

    private static Date parseDate(String dateStr) {
        List<String> dateParts = dateStr.split('-');
        return Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
    }

    private static String getPlanLabel(String planLabel) {
        if (planLabel.contains(skedConstants.AVAILABILITY_TYPE_PTO)) {
            return skedConstants.AVAILABILITY_TYPE_PTO;
        } else if (planLabel.contains(skedConstants.AVAILABILITY_TYPE_FLOATING_HOLIDAY)) {
            return skedConstants.AVAILABILITY_TYPE_FLOATING_HOLIDAY;
        } else if (planLabel.contains(skedConstants.UNAVAILABILITY_TYPE_SICK)) {
            return skedConstants.UNAVAILABILITY_TYPE_SICK;
        } else if (planLabel.contains(skedConstants.UNAVAILABILITY_TYPE_BEREAVEMENT)) {
            return skedConstants.UNAVAILABILITY_TYPE_BEREAVEMENT;
        } else if (planLabel.contains(skedConstants.UNAVAILABILITY_TYPE_PERSONAL)) {
            return skedConstants.UNAVAILABILITY_TYPE_PERSONAL;
        }

        return planLabel;
    }

    private static Boolean getIsDefaultTimeOffReasonCode(String timeOffReasonLabel) {
        return timeOffReasonLabel == 'Planned';
    }

    private static String getBsfErrorMessage(String workdayMessage) {
        List<sked_Workday_Validation_Error_Mapping__mdt> errorMessageMappings = [
            SELECT Id, Label, sked_Workday_Message__c, sked_BSF_Message__c
            FROM sked_Workday_Validation_Error_Mapping__mdt
            ORDER BY Label DESC
        ];

        for (sked_Workday_Validation_Error_Mapping__mdt errorMessageMapping : errorMessageMappings) {
            if (workdayMessage.contains(errorMessageMapping.sked_Workday_Message__c)) {
                return errorMessageMapping.sked_BSF_Message__c;
            }
        }

        return workdayMessage;
    }
}