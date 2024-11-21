global class slwcCollectionOperationService {
    
    @AuraEnabled(cacheable=false)
    public static slwcAuraResult getSkedRegionId(string collectionOperationId, decimal latitude, decimal longitude) {
        slwcAuraResult result = new slwcAuraResult();
        
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        Location inputLocation = Location.newInstance(latitude, longitude);
        Long timestamp = system.now().getTime()/1000;
        skedSkeduloApiData.timezoneResult timezoneResult = apiManager.getTimezoneFromLocation(inputLocation, timestamp);
        
        List<sked__Region__c> queryResults = [SELECT Id, sked__Timezone__c
                                              FROM sked__Region__c
                                              WHERE sked_Biomed_Collection_Op_Center__c = :collectionOperationId
                                              AND sked__Timezone__c = :timezoneResult.timezoneId];
        if (!queryResults.isEmpty()) {
            result.returnedData = queryResults.get(0).Id;
        }
        return result;
    }
}