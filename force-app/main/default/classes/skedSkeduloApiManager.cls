global virtual class skedSkeduloApiManager {

    public static final string AVAILABILITY_PATTERN_ENDPOINT = 'https://api.skedulo.com/availability/patterns';
    public static final string AVAILABILITY_SIMPLE_ENDPOINT = 'https://api.skedulo.com/availability/simple';
    public static final string DISTANCE_MATRIX_ENDPOINT = 'https://api.skedulo.com/geoservices/distanceMatrix';
    public static final string DISTANCE_MATRIX_ASYNC_ENDPOINT = 'https://api.skedulo.com/geoservices/distanceMatrix/async?vendor=anymap';
    public static final string FIND_DIRECTIONS_ENDPOINT = 'https://api.skedulo.com/geoservices/directions';
    public static final string GEOCODE_ENDPOINT = 'https://api.skedulo.com/geoservices/geocode';
    public static final string NOTIFY_CANCEL_ENDPOINT = 'https://api.skedulo.com/notifications/notify_cancel';
    public static final string NOTIFY_DISPATCH_ENDPOINT = 'https://api.skedulo.com/notifications/dispatch';
    public static final string NOTIFY_ONE_OFF_ENDPOINT = 'https://api.skedulo.com/notifications/oneoff';
    public static final string NOTIFY_SMS_ENDPOINT = 'https://api.skedulo.com/notifications/sms';
    public static final string OPTIMIZE_SCHEDULE_ENDPOINT = 'https://api.skedulo.com/planr/optimize/schedule';
    public static final string TIMEZONE_ENDPOINT = 'https://api.skedulo.com/geoservices/timezone';

    public static final string SKEDULO_PROD_DOMAIN = 'https://api.skedulo.com';
    public static final string SKEDULO_DEV_DOMAIN = 'https://dev-api.test.skl.io';
    public static final string OPTIMIZE_ARC_SHIFT_ENDPOINT = '/optimization/schedule/arc';
    public static final String GET_OPTIMIZATION_RUN_DIFF_END_POINT = 'https://api.skedulo.com/optimization/run/{{runId}}/diff';
    public static final String GET_OPTIMIZATION_RUN_META_END_POINT = 'https://api.skedulo.com/optimization/run/{{runId}}/meta';
    
    public static final string OPTIMIZATION_RUN_ARC_ENDPOINT = 'https://api.skedulo.com/function/ArcPackage/Functions/triggerOptimizationRun';
    //Optmizer Stat HRP-12511
    public static final string OPTIMIZAION_RUN_STATISTICS_ENDPOINT = 'https://api.skedulo.com/optimization/run/{{runId}}/statistics';
    public static final string OPTIMIZAION_RUN_PARAMETERS_ENDPOINT = 'https://api.skedulo.com/optimization/run/{{runId}}/solvice';
    
    protected string longLiveDevToken;
    protected string longLiveToken;
    
    /******************************************* Skedulo Availability Pattern *******************************************/
    public skedSkeduloApiData.upsertAvailabilityPatternResult upsertAvailabilityPattern(skedSkeduloApiData.availabilityPatternPayload payload) {
        string jsonBody = Json.serialize(payload);
        actionBase action = new actionBase();
        return (skedSkeduloApiData.upsertAvailabilityPatternResult)action.execute(skedSkeduloApiData.upsertAvailabilityPatternResult.class, AVAILABILITY_PATTERN_ENDPOINT, 'POST', getDefaultHeader(), jsonBody);
    }
    
    public skedSkeduloApiData.simplifiedResourceAvailabilityResult getSimplifiedResourceAvailability(skedSkeduloApiData.simplifiedResourceAvailabilityPayload payload) {
        actionBase action = new actionBase();
        string url = AVAILABILITY_SIMPLE_ENDPOINT + '?resource_ids={{resourceIds}}&start={{start}}&end={{end}}&mergedAvailabilities={{mergedAvailabilities}}&entries=false';
        url = url.replace('{{resourceIds}}', payload.resource_ids);
        url = url.replace('{{start}}', payload.start);
        url = url.replace('{{end}}', payload.end_x);
        url = url.replace('{{mergedAvailabilities}}', 'true');
        return (skedSkeduloApiData.simplifiedResourceAvailabilityResult)action.execute(skedSkeduloApiData.simplifiedResourceAvailabilityResult.class, url, 'GET', getDefaultHeader(), null);
    }

    /******************************************* Skedulo Notifications *******************************************/
    public skedSkeduloApiData.notificationResult notifyDispatch(string jobId, string resourceId) {
        return notify('dispatch', jobId, resourceId);
    }

    public skedSkeduloApiData.notificationResult notifyCancel(string jobId) {
        return notify('notify_cancel', jobId, null);
    }

    public skedSkeduloApiData.smsResult notifySms(string countryCodeAbbreviation, string phoneNumber, string content) {
        Map<string, object> mapBody = new Map<string, object>();
        mapBody.put('countryCode', countryCodeAbbreviation);
        mapBody.put('message', content);
        mapBody.put('phoneNumber', phoneNumber);
        string jsonBody = Json.serialize(mapBody);

        actionBase action = new actionBase();
        return (skedSkeduloApiData.smsResult)action.execute(skedSkeduloApiData.smsResult.class, NOTIFY_SMS_ENDPOINT, 'POST', getDefaultHeader(), jsonBody);
    }

    public skedSkeduloApiData.oneOffResult notifyOneOff(string resourceId, string protocol, string message) {
        Map<string, object> mapBody = new Map<string, object>();
        mapBody.put('resourceId', resourceId);
        mapBody.put('message', message);
        mapBody.put('protocol', protocol);
        string jsonBody = Json.serialize(mapBody);
        system.debug('#mapBody#' + mapBody);

        actionBase action = new actionBase();
        return (skedSkeduloApiData.oneOffResult)action.execute(skedSkeduloApiData.oneOffResult.class, NOTIFY_ONE_OFF_ENDPOINT, 'POST', getDefaultHeader(), jsonBody);
    }

    /******************************************* Skedulo Optimization *******************************************/
    public skedSkeduloApiData.optimizationRunResult triggerOptimizationRun(skedSkeduloApiData.optimizationRunModel model) {
        Map<string, string> headers = getDefaultHeader();
        string body = JSON.serialize(model);
        system.debug('#body#' + body);
        actionBase action = new actionBase();

        skedSkeduloApiData.optimizationRunResult response = (skedSkeduloApiData.optimizationRunResult)action.execute(skedSkeduloApiData.optimizationRunResult.class, OPTIMIZATION_RUN_ARC_ENDPOINT, 'POST', headers, body);
    	return response;
    }

    // HRP-12511
    public skedSkeduloApiData.OptimizationRunStatisticsResult getOptimizerRunStatistics(string runId){
        Map<string, string> headers = getDefaultHeader();                
        string url = OPTIMIZAION_RUN_STATISTICS_ENDPOINT.replace('{{runId}}', runId);        
        actionBase action = new actionBase();
        skedSkeduloApiData.OptimizationRunStatisticsResult response = (skedSkeduloApiData.OptimizationRunStatisticsResult)action.execute(skedSkeduloApiData.OptimizationRunStatisticsResult.class, url, 'GET', headers, '', true );                        
        return response;
    }
    
    // HRP-12511
    public skedSkeduloApiData.OptimizationRunParametersResult getOptimizerRunParameters(string runId){
        Map<string, string> headers = getDefaultHeader();             
        string url = OPTIMIZAION_RUN_PARAMETERS_ENDPOINT.replace('{{runId}}', runId);
        actionBase action = new actionBase();
        skedSkeduloApiData.OptimizationRunParametersResult response = (skedSkeduloApiData.OptimizationRunParametersResult)action.execute(skedSkeduloApiData.OptimizationRunParametersResult.class, url, 'GET', headers, '', true );                
        return response;
    }

    public skedSkeduloApiData.optimizationRunMetaResult getOptimizerRunMetaResult(string runId){
        Map<string, string> headers = getDefaultHeader();              
        string url = GET_OPTIMIZATION_RUN_META_END_POINT.replace('{{runId}}', runId);
        actionBase action = new actionBase();
        skedSkeduloApiData.optimizationRunMetaResult response = (skedSkeduloApiData.optimizationRunMetaResult)action.execute(skedSkeduloApiData.optimizationRunMetaResult.class, url, 'GET', headers, '', true );                
        return response;
    }

    public skedSkeduloApiData.optimizationRunDiffResult getOptimizerRunDiffResult(string runId){
        Map<string, string> headers = getDefaultHeader();               
        string url = GET_OPTIMIZATION_RUN_DIFF_END_POINT.replace('{{runId}}', runId);
        actionBase action = new actionBase();
        skedSkeduloApiData.optimizationRunDiffResult response = (skedSkeduloApiData.optimizationRunDiffResult)action.execute(skedSkeduloApiData.optimizationRunDiffResult.class, url, 'GET', headers, '', true );                
        return response;
    }    

    /******************************************* Google Related *******************************************/
    public skedSkeduloApiData.geocodeResult getGeocode(List<string> addresses) {
        Map<string, object> mapBody = new Map<string, object>();
        mapBody.put('addresses', addresses);
        string jsonBody = Json.serialize(mapBody);

        actionBase action = new actionBase();
        return (skedSkeduloApiData.geocodeResult)action.execute(skedSkeduloApiData.geocodeResult.class, GEOCODE_ENDPOINT, 'POST', getDefaultHeader(), jsonBody);
    }
    
    public Map<string, skedSkeduloApiData.timezoneResult> getTimezonesFromLocation(Map<string, Location> mapLocation) {
        Map<string, skedSkeduloApiData.timezoneResult> results = new Map<string, skedSkeduloApiData.timezoneResult>();
        Long timeStamp = DateTime.now().getTime()/1000;
        for (String key : mapLocation.keySet()) {
            Location location = mapLocation.get(key);
            results.put(key, getTimezoneFromLocation(location, timeStamp));
        }
        return results;
    }
    
    public skedSkeduloApiData.timezoneResult getTimezoneFromLocation(Location location, Long timeStamp) {
        actionBase action = new actionBase();
        String endPoint = TIMEZONE_ENDPOINT;
        // Add lat and long parameter to endpoint
        endPoint += '?location=' + location.getLatitude() + ',' + location.getLongitude();
        // Add timestamp
        endPoint += '&timestamp=' + timeStamp;
        return (skedSkeduloApiData.timezoneResult)action.execute(skedSkeduloApiData.timezoneResult.class, endPoint, 'GET', getDefaultHeader(), '');
    }

    public skedSkeduloApiData.distanceMatrixResult calculateDistanceMatrix(List<object> origins, List<object> destinations, Datetime departureTime) {
        Map<string, object> mapBody = new Map<string, object>();
        mapBody.put('origins', origins);
        mapBody.put('destinations', destinations);
        if (departureTime != null) {
            mapBody.put('departureTime', JSON.serialize(departureTime).replace('"', ''));
        }
        string jsonBody = Json.serialize(mapBody);
        actionBase action = new actionBase();
        return (skedSkeduloApiData.distanceMatrixResult)action.execute(skedSkeduloApiData.distanceMatrixResult.class, DISTANCE_MATRIX_ENDPOINT, 'POST', getDefaultHeader(), jsonBody , true);
    }

    public skedSkeduloApiData.distanceMatrixResult calculateDistanceMatrix(List<object> origins, List<object> destinations) {
        return calculateDistanceMatrix(origins, destinations, null);
    }

    public skedSkeduloApiData.directionsResult findDirections(List<skedSkeduloApiData.directionsRequest> requests, List<String> avoid) {
        Map<string, object> mapBody = new Map<string, object>();
        mapBody.put('requests', requests);
        mapBody.put('avoid', avoid);
        string jsonBody = Json.serialize(mapBody);

        actionBase action = new actionBase();
        return (skedSkeduloApiData.directionsResult)action.execute(skedSkeduloApiData.directionsResult.class, FIND_DIRECTIONS_ENDPOINT, 'POST', getDefaultHeader(), jsonBody);
    }

    //Traffic Sensitive API
    public skedSkeduloApiData.distanceMatrixAsyncResult distanceMatrixAsync(List<string> timeBlocks, List<Location> origins, List<Location> destinations) {
        Map<string, object> mapBody = new Map<string, object>();
        List<string> originStrings = new List<string>();
        List<string> destinationStrings = new List<string>();
        List<string> timeBlockStrings = new List<string>();
        for (Location origin : origins) {
            originStrings.add('&origins=' + origin.getLatitude() + ',' + origin.getLongitude());
        }
        for (Location destination : destinations) {
            destinationStrings.add('&destinations=' + destination.getLatitude() + ',' + destination.getLongitude());
        }
        for (string timeBlock : timeBlocks) {
            timeBlockStrings.add('&timeBlock=' + timeBlock);
        }
        string jsonBody = '{{timeblock}}{{destinations}}{{origins}}';
        jsonBody = jsonBody.replace('{{timeblock}}', string.join(timeBlockStrings, ''));
        jsonBody = jsonBody.replace('{{destinations}}', string.join(destinationStrings, ''));
        jsonBody = jsonBody.replace('{{origins}}', string.join(originStrings, ''));
        jsonBody = jsonBody.substring(1);
        system.debug('jsonBody' + jsonBody);

        actionBase action = new actionBase();
        Map<string, string> mapHeader = getDefaultHeader();
        mapHeader.put('Content-Type', 'application/x-www-form-urlencoded');
        string token = mapHeader.get('Authorization');
        return (skedSkeduloApiData.distanceMatrixAsyncResult)action.execute(skedSkeduloApiData.distanceMatrixAsyncResult.class, DISTANCE_MATRIX_ASYNC_ENDPOINT, 'POST', mapHeader, jsonBody, TRUE);
    }
    
    public List<string> getTravelTimeSetting(string timezoneSidId) {
        List<sked_Travel_Time_Breakdown_Setting__mdt> settings = [SELECT sked_Weekday__c,
                                                                  sked_Start_At_Time_1__c, sked_Start_At_Time_2__c, sked_Start_At_Time_3__c,
                                                                  sked_End_At_Time_1__c, sked_End_At_Time_2__c, sked_End_At_Time_3__c
                                                                  FROM sked_Travel_Time_Breakdown_Setting__mdt];
        
        Map<string, sked_Travel_Time_Breakdown_Setting__mdt> mapSetting = new Map<string, sked_Travel_Time_Breakdown_Setting__mdt>();
        for (sked_Travel_Time_Breakdown_Setting__mdt setting : settings) {
            mapSetting.put(setting.sked_Weekday__c, setting);
        }
        
        List<string> timeBlocks = new List<string>();
        Date currentDate = System.today();
        for (integer i = 0; i < 7; i ++) {
            currentDate = currentDate.addDays(1);
            Datetime currentDateTime = skedDateTimeUtils.newDateTimeInstance(currentDate, 0, timezoneSidId);
            String dayOfWeek = currentDateTime.format('EEEE', timezoneSidId);
            sked_Travel_Time_Breakdown_Setting__mdt setting = mapSetting.get(dayOfWeek);
            
            DateTime startDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)setting.sked_Start_At_Time_1__c, timezoneSidId);
            DateTime endDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)setting.sked_End_At_Time_1__c, timezoneSidId);
            string startDtString = JSON.serialize(startDt).replace('"', '');
            startDtString = startDtString.replace('.000Z', '');
            string endDtString = JSON.serialize(endDt).replace('"', '');
            endDtString = endDtString.replace('.000Z', '');
            timeBlocks.add(startDtString + ',' + endDtString);
            
            startDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)setting.sked_Start_At_Time_2__c, timezoneSidId);
            endDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)setting.sked_End_At_Time_2__c, timezoneSidId);
            startDtString = JSON.serialize(startDt).replace('"', '');
            startDtString = startDtString.replace('.000Z', '');
            endDtString = JSON.serialize(endDt).replace('"', '');
            endDtString = endDtString.replace('.000Z', '');
            timeBlocks.add(startDtString + ',' + endDtString);
            
            startDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)setting.sked_Start_At_Time_3__c, timezoneSidId);
            endDt = skedDateTimeUtils.newDateTimeInstance(currentDate, (integer)setting.sked_End_At_Time_3__c, timezoneSidId);
            startDtString = JSON.serialize(startDt).replace('"', '');
            startDtString = startDtString.replace('.000Z', '');
            endDtString = JSON.serialize(endDt).replace('"', '');
            endDtString = endDtString.replace('.000Z', '');
            timeBlocks.add(startDtString + ',' + endDtString);
        }
        return timeBlocks;
    }
    
    /******************************************* Protected methods *******************************************/
    protected skedSkeduloApiData.notificationResult notify(string notifyType, string jobId, string resourceId) {
        string endPoint;
        if (notifyType == 'dispatch') {
            endPoint = NOTIFY_DISPATCH_ENDPOINT;
        }
        else if (notifyType == 'notify_cancel') {
            endPoint = NOTIFY_CANCEL_ENDPOINT;
        }

        Map<string, string> mapBody = new Map<string, string>();
        mapBody.put('jobId', jobId);
        if (!string.isBlank(resourceId)) {
            mapBody.put('resourceId', resourceId);
        }
        string jsonBody = Json.serialize(mapBody);

        actionBase action = new actionBase();
        return (skedSkeduloApiData.notificationResult)action.execute(skedSkeduloApiData.notificationResult.class, endPoint, 'POST', getDefaultHeader(), jsonBody);
    }

    /******************************************* Private methods *******************************************/
    private Map<string, string> getDefaultHeader() {
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/json');

        if (string.isBlank(this.longLiveToken)) {
            List<sked__Admin_Setting__mdt> skedLongLiveTokens = [SELECT sked__Description__c, sked__Value__c
                                                                 FROM sked__Admin_Setting__mdt
                                                                 WHERE DeveloperName = 'Skedulo_API_Token'];
            for (sked__Admin_Setting__mdt adminSetting : skedLongLiveTokens) {
                if (adminSetting.sked__Value__c != NULL) {
                    this.longLiveToken = adminSetting.sked__Value__c;
                    break;
                }
            }
            system.debug('skedLongLiveTokens:' + skedLongLiveTokens);
            mapHeader.put('Authorization', 'Bearer ' + this.longLiveToken);
        }
        else {
            mapHeader.put('Authorization', 'Bearer ' + this.longLiveToken);
        }

       return mapHeader;
    }

    private Map<string, string> getDefaultDevHeader() {
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/json');

        if (string.isBlank(this.longLiveDevToken)) {
            List<sked__Admin_Setting__mdt> skedLongLiveTokens = [SELECT sked__Description__c, sked__Value__c
                                                             FROM sked__Admin_Setting__mdt
                                                             WHERE DeveloperName = 'Skedulo_Dev_API_Token'];
            for (sked__Admin_Setting__mdt adminSetting : skedLongLiveTokens) {
                if (adminSetting.sked__Value__c != NULL) {
                    this.longLiveDevToken = adminSetting.sked__Value__c;
                    break;
                }
            }
            mapHeader.put('Authorization', 'Bearer ' + this.longLiveDevToken);
        }
        else {
            mapHeader.put('Authorization', 'Bearer ' + this.longLiveDevToken);
        }

        return mapHeader;
    }    

    /******************************************* Nested Classes *******************************************/
    public virtual class actionBase extends skedCalloutActionBase {
        public override skedCalloutResultBase processError(Type resultType, skedCalloutResultBase result, string response) {
            result = (skedCalloutResultBase)resultType.newInstance();
            try {
                ((skedSkeduloApiData.resultBase)result).error = (skedSkeduloApiData.error)Json.deserialize(response, skedSkeduloApiData.error.class);
            }
            catch (Exception ex) {
                ((skedSkeduloApiData.resultBase)result).errors = (List<skedSkeduloApiData.error>)Json.deserialize(response, List<skedSkeduloApiData.error>.class);
            }
            return result;
        }
    }

}