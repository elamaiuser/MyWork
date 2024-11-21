@isTest
global class skedMockTest implements HttpCalloutMock {
    public boolean isErrorMode = false;
    public Integer statusCode = 200;
    
    global HTTPResponse respond(HTTPRequest req) {
        string endpoint = req.getEndpoint();
        PageReference pageRef = new PageReference(endpoint);
        string urlString = pageRef.getUrl();
        
        skedMockDataFactory mockDataFactory = new skedMockDataFactory();
        mockDataFactory.isErrorMode = this.isErrorMode;

        mockDataFactory.statusCode = this.statusCode;
        
        HttpResponse res;
        if (urlString.startsWith(skedSkeduloApiManager.NOTIFY_DISPATCH_ENDPOINT) || urlString.startsWith(skedSkeduloApiManager.NOTIFY_CANCEL_ENDPOINT)) {
            res = mockDataFactory.getNotifyResponse(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.NOTIFY_ONE_OFF_ENDPOINT)) {
            res = mockDataFactory.getOneOffResponse(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.NOTIFY_SMS_ENDPOINT)) {
            res = mockDataFactory.getCustomSmsResponse(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.GEOCODE_ENDPOINT)) {
            res = mockDataFactory.getGeocodeResponse(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.DISTANCE_MATRIX_ASYNC_ENDPOINT)) {
            res = mockDataFactory.getDistanceMatrixAsyncResponse(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.DISTANCE_MATRIX_ENDPOINT)) {
            res = mockDataFactory.getDistanceMatrixResponse(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.AVAILABILITY_PATTERN_ENDPOINT)) {
            res = mockDataFactory.getUpsertAvailabilityPatternResponse(req);
        }
        else if (urlString.startsWith(skedSetting.instance.Admin.opsRecordApiUrl)) {
            res = mockDataFactory.getUpdateStaffRecordResponse(req);
        }
        else if (urlString.startsWith(skedOpsRecordApiManager.OPS_RECORD_REFRESH_TOKEN)) {
            res = mockDataFactory.getOpsRecordRefreshToken(req);
        }
        else if (urlString.startswith(skedSkeduloApiManager.TIMEZONE_ENDPOINT)) {
            res = mockDataFactory.getTimezoneFromLocation(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.AVAILABILITY_PATTERN_ENDPOINT)) {
            res = mockDataFactory.upsertAvailabilityPattern(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.AVAILABILITY_SIMPLE_ENDPOINT)) {
            res = mockDataFactory.getSimplifiedResourceAvailability(req);
        }
        else if (urlString.startsWith(skedSkeduloApiManager.OPTIMIZATION_RUN_ARC_ENDPOINT)) {
            res = mockDataFactory.triggerOptimizationRun(req);
        }
        return res;
    }
    
    /************************************************ Nested classes ****************************************************/
    public class skedMockDataFactory {
        Boolean isErrorMode;
        Integer statusCode;
        
        public HTTPResponse getNotifyResponse(HTTPRequest req) { 
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            string jobId = string.valueOf(mapBody.get('jobId'));
            string resourceId = string.valueOf(mapBody.get('resourceId'));
            
            skedSkeduloApiData.notificationResult notificationResult = new skedSkeduloApiData.notificationResult();
            notificationResult.result = new skedSkeduloApiData.notificationReturnedData();
            notificationResult.result.jobId = jobId;
            notificationResult.result.results = new List<skedSkeduloApiData.allocationData>();
            skedSkeduloApiData.allocationData allocationData = new skedSkeduloApiData.allocationData();
            allocationData.resourceId = resourceId;
            if (this.isErrorMode == true) {
                allocationData.error = new skedSkeduloApiData.error();
                allocationData.error.errorKey = 'no_number';
                allocationData.error.errorType = 'recipient_error';
                allocationData.error.message = 'No mobile number set for resource ' + resourceId;
            }
            notificationResult.result.results.add(allocationData);
            
            res.setBody(Json.serialize(notificationResult));
            res.setStatusCode(this.statusCode);
            return res;
        }
        
        public HTTPResponse getOneOffResponse(HTTPRequest req) {
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);
            string protocol = string.valueOf(mapBody.get('protocol'));
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            skedSkeduloApiData.oneOffResult oneOffResult = new skedSkeduloApiData.oneOffResult();
            oneOffResult.result = new skedSkeduloApiData.oneOffReturnedData();
            oneOffResult.result.protocol = protocol;
            
            res.setBody(Json.serialize(oneOffResult));
            res.setStatusCode(this.statusCode);
            return res;
        }
        
        public HTTPResponse getCustomSmsResponse(HTTPRequest req) {
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);
            string protocol = string.valueOf(mapBody.get('protocol'));
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            skedSkeduloApiData.smsResult smsResult = new skedSkeduloApiData.smsResult();
            smsResult.result = new skedSkeduloApiData.smsReturnedData();
            smsResult.result.success = true;
            
            res.setBody(Json.serialize(smsResult));
            res.setStatusCode(this.statusCode);
            return res;
        }
        
        public HTTPResponse getGeocodeResponse(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);
            List<object> addresses = (List<object>)mapBody.get('addresses');
            
            skedSkeduloApiData.geocodeResult geocodeResult = new skedSkeduloApiData.geocodeResult();
            geocodeResult.result = new List<skedSkeduloApiData.geocodeResultItem>();
            for (object address : addresses) {
                skedSkeduloApiData.geocodeResultItem geocodeResultItem = new skedSkeduloApiData.geocodeResultItem();
                if (!this.isErrorMode) {
                    geocodeResultItem.geocodeSuccess = new skedSkeduloApiData.geocodeSuccess();
                    geocodeResultItem.geocodeSuccess.address = string.valueOf(address);
                    geocodeResultItem.geocodeSuccess.latlng = new skedSkeduloApiData.latlng();
                    geocodeResultItem.geocodeSuccess.latlng.lat = 37.757815;
                    geocodeResultItem.geocodeSuccess.latlng.lng = -122.5076407;
                }
                else {
                    geocodeResultItem.geocodeFailure = new skedSkeduloApiData.geocodeFailure();
                    geocodeResultItem.geocodeFailure.address = string.valueOf(address);
                    geocodeResultItem.geocodeFailure.reason = new skedSkeduloApiData.geocodeFailureReason();
                    geocodeResultItem.geocodeFailure.reason.msg = 'ZERO_RESULTS';
                }
                geocodeResult.result.add(geocodeResultItem);
            }
            
            res.setBody(Json.serialize(geocodeResult));
            res.setStatusCode(this.statusCode);
            return res;
        }
        
        public HTTPResponse getDistanceMatrixResponse(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            string jsonBody = req.getBody();
            distanceMatrixRequestBody requestBody = (distanceMatrixRequestBody)Json.deserialize(jsonBody, distanceMatrixRequestBody.class);
            
            skedSkeduloApiData.distanceMatrixResult distanceMatrixResult = new skedSkeduloApiData.distanceMatrixResult();
            distanceMatrixResult.result = new skedSkeduloApiData.Matrix();
            distanceMatrixResult.result.matrix = new List<List<skedSkeduloApiData.Element>>();
            for (integer i = 0; i < requestBody.origins.size(); i++) {
                List<skedSkeduloApiData.Element> row = new List<skedSkeduloApiData.Element>();
                for (integer j = 0; j < requestBody.destinations.size(); j++) {
                    skedSkeduloApiData.Element element = new skedSkeduloApiData.Element();
                    element.distance = new skedSkeduloApiData.Distance();
                    element.distance.distanceInMeters = 3000;
                    element.duration = new skedSkeduloApiData.Duration();
                    element.duration.durationInSeconds = 600;
                    element.status = 'OK';
                    row.add(element);
                }
                distanceMatrixResult.result.matrix.add(row);
            }
            
            res.setBody(Json.serialize(distanceMatrixResult));
            res.setStatusCode(this.statusCode);
            return res;
        }
        
        public HTTPResponse getUpsertAvailabilityPatternResponse(HTTPRequest req) {
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);
            string protocol = string.valueOf(mapBody.get('protocol'));
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            skedSkeduloApiData.upsertAvailabilityPatternResult apiResult = new skedSkeduloApiData.upsertAvailabilityPatternResult();
            List<sked__Availability_Pattern__c> availabilityPatterns = [SELECT Id FROM sked__Availability_Pattern__c LIMIT 1];
            if (availabilityPatterns != NULL && !availabilityPatterns.isEmpty()){
                apiResult.result = availabilityPatterns.get(0).Id;
                apiResult.created = availabilityPatterns.get(0).Id;
                apiResult.success = TRUE;
            }
            
            res.setBody(Json.serialize(apiResult));
            res.setStatusCode(this.statusCode);
            return res;
        }
        
        public HTTPResponse getDistanceMatrixAsyncResponse(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            string jsonBody = req.getBody();
            skedSkeduloApiData.distanceMatrixAsyncResult distanceMatrixAsyncResult = new skedSkeduloApiData.distanceMatrixAsyncResult();
            distanceMatrixAsyncResult.Id = 'b374586a-8bdf-435d-9a1d-80533b72edfd';
            res.setBody(Json.serialize(distanceMatrixAsyncResult));
            res.setStatusCode(this.statusCode);
            return res;
        }

        public HttpResponse getUpdateStaffRecordResponse(HTTPRequest req) {
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            skedOpsRecordApiData.opsRecordResult opsRecordResult = new skedOpsRecordApiData.opsRecordResult();
            opsRecordResult.success = !this.isErrorMode;
            opsRecordResult.statusCode = this.statusCode;

            res.setBody(JSON.serialize(opsRecordResult));
            res.setStatusCode(this.statusCode);

            return res;
        }

        public HttpResponse getOpsRecordRefreshToken(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            skedOpsRecordApiData.refreshTokenResult refreshTokenResult = new skedOpsRecordApiData.refreshTokenResult();
            refreshTokenResult.access_token = 'test-access-token';
            refreshTokenResult.expires_in = '5000';

            res.setBody(JSON.serialize(refreshTokenResult));
            res.setStatusCode(this.statusCode);

            return res;
        }

        public HttpResponse getTimezoneFromLocation(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            skedSkeduloApiData.timezoneResult result = new skedSkeduloApiData.timezoneResult();
            result.timeZoneId = UserInfo.getTimeZone().getID();
            
            res.setBody(Json.serialize(result));
            return res;
        }

        public HttpResponse upsertAvailabilityPattern(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            skedSkeduloApiData.upsertAvailabilityPatternResult result = new skedSkeduloApiData.upsertAvailabilityPatternResult();
            result.success = true;

            res.setBody(Json.serialize(result));
            return res;
        }

        public HttpResponse getSimplifiedResourceAvailability(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            skedSkeduloApiData.simplifiedResourceAvailabilityResult result = new skedSkeduloApiData.simplifiedResourceAvailabilityResult();
            result.success = true;

            res.setBody(JSON.serialize(result));
            return res;
        }

        public HttpResponse triggerOptimizationRun(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            skedSkeduloApiData.optimizationRunResult result = new skedSkeduloApiData.optimizationRunResult();
            result.success = true;

            res.setBody(JSON.serialize(result));
            return res;
        }
    }
    
    public class distanceMatrixRequestBody {
        public List<geometry> origins;
        public List<geometry> destinations;
    }
    
    public class geometry {
        public decimal lat;
        public decimal lng;
    }
    
}