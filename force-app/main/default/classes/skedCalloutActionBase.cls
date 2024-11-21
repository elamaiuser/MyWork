public abstract class skedCalloutActionBase {
    
    public static final integer DEFAULT_TIMEOUT = 60000;
    
    public virtual skedCalloutResultBase execute(Type resultType, string endPoint, string httpMethod, Map<string, string> mapHeader, string body) {
        return execute(resultType, endPoint, httpMethod, mapHeader, body, false);
    }

    public virtual skedCalloutResultBase execute(Type resultType, string endPoint, string httpMethod, Map<string, string> mapHeader, string body, boolean skipReservedKeyReplacement) {
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
                result.success = false;
                system.debug('#result.success: ' + result.success);
            }
            else {
                result = processResponse(resultType, result, response, !skipReservedKeyReplacement);
                result.success = true;
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
    protected abstract skedCalloutResultBase processError(Type resultType, skedCalloutResultBase result, string response);
    protected virtual skedCalloutResultBase processResponse(Type resultType, skedCalloutResultBase result, string response, boolean replaceReservedKeywords) {
        if (replaceReservedKeywords) {
            response = replaceReservedJSON(response, false);
        }

        boolean canDeserialize = TRUE;
        try {
            result = (skedCalloutResultBase) JSON.deserialize(response, resultType);
        }
        catch (Exception ex) {
            canDeserialize = FALSE;
        }
        if (!canDeserialize) {
            result = (skedCalloutResultBase)resultType.newInstance();
            result.message = response;
        }
        return result;
    }
    /******************************************* Private methods *******************************************/
    protected HttpRequest prepareHttpRequest(string endPoint, string httpMethod, Map<string, string> mapHeader, string body, boolean replaceReservedKeywords) {
        HttpRequest request = new Httprequest();
        request.setEndpoint(endPoint);
        if (!string.isBlank(body)) {
            if (replaceReservedKeywords) {
                body = replaceReservedJSON(body, true);
            }

            request.setBody(body);
        }
        else {
            request.setHeader('Content-length', '0');
        }
        if (httpMethod == 'PATCH') {
            request.setHeader('X-HTTP-Method-Override', 'PATCH');
        }
        for (string headerKey : mapHeader.keySet()) {
            string headerValue = mapHeader.get(headerKey);
            request.setHeader(headerKey, headerValue);
        }
        httpMethod = httpMethod == 'PATCH' ? 'POST' : httpMethod;
        request.setMethod(httpMethod);
        request.setTimeout(DEFAULT_TIMEOUT);
        return request;
    }
    
    public static String replaceReservedJSON(String data, Boolean isRequest) {
        String regexFormat = '(?m)^\\s*"{0}"\\s*:';
        String replacementFormat = '"{0}" :';
        Map<String, String> replacements = getReplacements(isRequest);
        String formattedJSON = JSON.serializePretty(JSON.deserializeUntyped(data));
        
        for (String key : replacements.keySet()) {
            String regex = String.format(regexFormat, new List<String> {key});
            String replacement = String.format(replacementFormat, new List<String> {replacements.get(key)});
            formattedJSON = formattedJSON.replaceAll(regex, replacement);
        }
        
        return formattedJSON;
    }
    
    private static Map<String, String> getReplacements(Boolean isRequest) {
        if (isRequest) {
            return new Map<String, String> {
                'end_x' => 'end',
                'time_x' => 'time',
                'from_x' => 'from'
            };
        } else {
            return new Map<String, String> {
                'end' => 'end_x',
                'time' => 'time_x',
                'from' => 'from_x'
            };
        }
    }
}