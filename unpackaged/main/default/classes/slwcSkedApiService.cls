global class slwcSkedApiService {
    
    @AuraEnabled(cacheable=true)
    public static string getAddressPredictions(String queryText) {
        String sessionId = sked.SkeduloAPI.getSessionId();
        sked.ApiResult.AutoComplete apiResult = sked.SkeduloAPI.autocomplete(queryText, 'US', sessionId);
        Map<string, string> mapResult = new Map<string, string>();
        mapResult.put('sessionId', sessionId);
        mapResult.put('response', apiResult.response);
        return JSON.serialize(mapResult);
    }
    
    @AuraEnabled(cacheable=true)
    public static string getGeocode(String address) {
        List<string> addresses = new List<string>();
        addresses.add(address);
        sked.ApiResult.Geocode apiResult = sked.SkeduloAPI.geocode(addresses);
        return apiResult.response;
    }
    
    @AuraEnabled(cacheable=true)
    public static string getPlaceDetails(String placeId, String sessionId) {
        sked.ApiResult.Place apiResult = sked.SkeduloAPI.place(placeId, sessionId);
        return apiResult.response;
    }
    
    @AuraEnabled(cacheable=true)
    public static slwcAuraResult calculateDistanceMatrix(List<skedSkeduloApiData.latlng> origins, List<skedSkeduloApiData.latlng> destinations, Datetime departureTime) {
        slwcAuraResult result = new slwcAuraResult();
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        skedSkeduloApiData.distanceMatrixResult distanceMatrixResult = apiManager.calculateDistanceMatrix(origins, destinations, departureTime);
        result.returnedData = distanceMatrixResult;
        system.debug('#result.returnedData#' + result.returnedData);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static string getTimezone(Decimal latitude, Decimal longitude) {
        Location inputLocation = Location.newInstance(latitude, longitude);
        
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        skedSkeduloApiData.timezoneResult timezoneResult = apiManager.getTimezoneFromLocation(inputLocation, DateTime.now().getTime()/1000);
        return timezoneResult.timeZoneId;
    }
}