public class skedOpsRecordApiManager {
    
    public string longLiveToken;
    public Datetime expiryAt;
    public boolean isRefreshToken;

    public static final string OPS_RECORD_REFRESH_TOKEN = 'https://sso.redcross.org/as/token.oauth2';
    
    public skedOpsRecordApiData.opsRecordResult updateStaffRecord(skedOpsRecordApiData.opsRecordRequest request) {
        Map<string, object> mapBody = new Map<string, object>();
        string jsonBody = Json.serialize(request);
        string endpoint = skedSetting.instance.Admin.opsRecordApiUrl;

        actionBase action = new actionBase();
        return (skedOpsRecordApiData.opsRecordResult) action.execute(skedOpsRecordApiData.opsRecordResult.class, endpoint, 'POST', getDefaultHeader(), jsonBody, true);
    }

    public string getAccessToken() {
        skedOpsRecordApiData.refreshTokenResult result = refreshToken();
        return result.access_token;
    }

    public skedOpsRecordApiData.refreshTokenResult refreshToken() {
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/x-www-form-urlencoded');

        string jsonBody = '&client_id={{client_id}}&client_secret={{client_secret}}&grant_type={{grant_type}}';
        jsonBody = jsonBody.replace('{{client_id}}', 'apiOpsRecord');
        jsonBody = jsonBody.replace('{{client_secret}}', skedSetting.instance.Admin.opsRecordClientSecret); //Zo2QIhaCNzLrFWNyTN3uJXiMSir3eoLkW04ic8vtEpsHKMTIls3OWlmJEGYYkmE7
        jsonBody = jsonBody.replace('{{grant_type}}', 'client_credentials');//&grant_type=client_credentials
        jsonBody = jsonBody.substring(1);
        system.debug('jsonBody' + jsonBody);

        if (test.isRunningTest()) {
            skedOpsRecordApiData.refreshTokenResult token = new skedOpsRecordApiData.refreshTokenResult();
            token.access_token = 'access-token';
            token.token_type = 'long-life';
            token.expires_in = '50000';
            return token;
        }
        
        actionBase action = new actionBase();
        return (skedOpsRecordApiData.refreshTokenResult) action.execute(skedOpsRecordApiData.refreshTokenResult.class, OPS_RECORD_REFRESH_TOKEN, 'POST', mapHeader, jsonBody, TRUE);
    }
    
    /******************************************* Private methods *******************************************/
    private Map<string, string> getDefaultHeader() {
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/json');
        
        string token = getAccessToken();
        system.debug('AccessToken:' + token);
        mapHeader.put('Authorization', 'Bearer ' + token);
        
       return mapHeader;
    }

    /******************************************* Nested Classes *******************************************/
    public virtual class actionBase extends skedCalloutActionBase {
        public override skedCalloutResultBase execute(Type resultType, string endPoint, string httpMethod, Map<string, string> mapHeader, string body, boolean skipReservedKeyReplacement) {
            skedCalloutResultBase result;
            try {
                Http h = new Http();
                HttpRequest req = prepareHttpRequest(endPoint, httpMethod, mapHeader, body, !skipReservedKeyReplacement);
                
                system.debug('#req.getBody()# ' + req.getBody());
                
                HttpResponse res = h.send(req);
                string response = res.getBody();
                string status = res.getStatus();
                integer statusCode = res.getStatusCode();
                system.debug('#body# ' + body);
                system.debug('#request# ' + req);
                system.debug('#response: ' + response);
                system.debug('#statusCode: ' + statusCode);
                if (statusCode >= 400) {
                    result = processError(resultType, result, response);
                    result.message = statusCode == 500 ? skedConstants.OP_RECORD_SUBMIT_500 : skedConstants.OP_RECORD_SUBMIT_400;
                    result.success = false;
                    system.debug('#result.success: ' + result.success);
                } else {
                    result = processResponse(resultType, result, response, !skipReservedKeyReplacement);
                    result.success = true;
                    if (statusCode == 200) {
                        result.message = skedConstants.OP_RECORD_SUBMIT_200;
                    }
                }
                result.status = status;
                result.statusCode = statusCode;
            }
            catch (Exception ex) {
                result = (skedCalloutResultBase)resultType.newInstance();
                result.success = false;
                result.message = ex.getMessage() + ' - ' + ex.getStackTraceString();
            }
            return result;
        }
        
        public override skedCalloutResultBase processError(Type resultType, skedCalloutResultBase result, string response) {
            result = (skedCalloutResultBase) resultType.newInstance();
            try{
                try {
                    ((skedOpsRecordApiData.resultBase)result).error = (skedOpsRecordApiData.error)Json.deserialize(response, skedOpsRecordApiData.error.class);
                }
                catch (Exception ex) {
                    ((skedOpsRecordApiData.resultBase)result).errors = (List<skedOpsRecordApiData.error>)Json.deserialize(response, List<skedOpsRecordApiData.error>.class);
                }
            }catch (Exception exp) {
                skedOpsRecordApiData.error errObj= new skedOpsRecordApiData.error();
                errObj.message = response;
                errObj.errorType = '';
                errObj.errorKey = '';
                errObj.path = '';
                ((skedOpsRecordApiData.resultBase)result).error = errObj;
            }

            return result;
        }
    }
}