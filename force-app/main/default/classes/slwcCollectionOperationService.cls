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
	//This method is created as part of HRP-13791. In this method the region will be fatch using taxonomy time zone using zip code and drive collection operation.
	//Created By Krapy Tuli 20-Jan-2025
    @AuraEnabled(cacheable=false)
    public static slwcAuraResult getSkedRegionIdUsingTaxonomy(string collectionOperationId, string postalCode, string start, string finish) {
        slwcAuraResult result = new slwcAuraResult();
        Set<String> timeZoneName = new Set<String>();
        Date startDate = convertDateTimeStringToDate(start);
        Date finishDate = convertDateTimeStringToDate(finish);
        List<Taxonomy__c> taxonomy = [Select Id, Time_Zone__c From Taxonomy__c where Zip_Code__c = :postalCode AND RecordType.Name = 'Bio Collection BSF' AND Start_Date__c <= :startDate AND End_Date__c >= :finishDate];
        for(Taxonomy__c taxo : taxonomy){
               timeZoneName.add(taxo.Time_Zone__c);
        }
        List<sked__Region__c> queryResults = [SELECT Id, sked__Timezone__c
                                              FROM sked__Region__c
                                              WHERE sked_Biomed_Collection_Op_Center__c = :collectionOperationId
                                              AND sked__Timezone__c = :timeZoneName];
        if (!queryResults.isEmpty()) {
            result.returnedData = queryResults.get(0).Id;
        }
        return result;
    }
	//HRP-13791 - This method to convert date time string into date HRP-13791
    @AuraEnabled(cacheable=false)
    public static Date convertDateTimeStringToDate(string dateString) {
        String dateTimeString = dateString;
        String datePart = dateTimeString.split('T')[0];
        Date parsedDate = Date.valueOf(datePart);
        return parsedDate;
    }
}