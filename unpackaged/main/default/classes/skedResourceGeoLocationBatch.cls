global class skedResourceGeoLocationBatch implements Database.Batchable<sked__Resource__c>, Database.AllowsCallouts {
    
    protected Set<Id> resourceIds;
    private skedSkeduloApiManager apiManager;
    
    public skedResourceGeoLocationBatch(Set<Id> resourceIds) {
        this.resourceIds = resourceIds;
        this.apiManager = new skedSkeduloApiManager();
    }

    global List<sked__Resource__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Home_Address_1__c, sked_Home_Address_2__c, sked_Home_Address_3__c,
                sked_Home_Address_GeoLocation__Latitude__s, sked_Home_Address_GeoLocation__Longitude__s,
                sked_Home_City__c, sked_Home_State__c , sked_Home_Zip_Code__c,
                sked_Work_Address_1__c, sked_Work_Address_2__c, sked_Work_Address_3__c,
                sked_Work_Address_GeoLocation__Latitude__s, sked_Work_Address_GeoLocation__Longitude__s, 
                sked_Work_City__c, sked_Work_State__c , sked_Work_Zip_Code__c
                FROM sked__Resource__c
                WHERE Id IN : this.resourceIds];
    }

    global void execute(Database.BatchableContext BC, List<sked__Resource__c> resources) {
        Map<Id, sked__Resource__c> mapResourcesToUpdate = new Map<Id, sked__Resource__c>();
        for (sked__Resource__c resource : resources) {
            slwcArcApiService.inputAddressModel homeAddress = new slwcArcApiService.inputAddressModel();
            homeAddress.addressLine1 = resource.sked_Home_Address_1__c;
            homeAddress.addressLine2 = resource.sked_Home_Address_2__c;
            homeAddress.city = resource.sked_Home_City__c;
            homeAddress.state = resource.sked_Home_State__c;
            homeAddress.zip5 = resource.sked_Home_Zip_Code__c;
            
            slwcArcApiService.informaticaStandardAddressModel homeAddressResult = slwcArcApiService.getStandardAddress(homeAddress);
            if (homeAddressResult != NULL) {
                if (!string.isBlank(homeAddressResult.Latitude) && !string.isBlank(homeAddressResult.Longitude)) {
                    resource.sked_Home_Address_GeoLocation__Latitude__s = Decimal.valueOf(homeAddressResult.Latitude);
                    resource.sked_Home_Address_GeoLocation__Longitude__s = Decimal.valueOf(homeAddressResult.Longitude);
                    mapResourcesToUpdate.put(resource.Id, resource);
                }
            }
            
            slwcArcApiService.inputAddressModel workAddress = new slwcArcApiService.inputAddressModel();
            workAddress.addressLine1 = resource.sked_Work_Address_1__c;
            workAddress.addressLine2 = resource.sked_Work_Address_2__c;
            workAddress.city = resource.sked_Work_City__c;
            workAddress.state = resource.sked_Work_State__c;
            workAddress.zip5 = resource.sked_Work_Zip_Code__c;
            
            slwcArcApiService.informaticaStandardAddressModel workAddressResult = slwcArcApiService.getStandardAddress(workAddress);
            if (workAddressResult != NULL) {
                if (!string.isBlank(workAddressResult.Latitude) && !string.isBlank(workAddressResult.Longitude)) {
                    resource.sked_Work_Address_GeoLocation__Latitude__s = Decimal.valueOf(workAddressResult.Latitude);
                    resource.sked_Work_Address_GeoLocation__Longitude__s = Decimal.valueOf(workAddressResult.Longitude);
                    mapResourcesToUpdate.put(resource.Id, resource);
                }
            }

            if (homeAddressResult != null && workAddressResult != null) {
                List<skedSkeduloApiData.latlng> origins = new List<skedSkeduloApiData.latlng>();
                skedSkeduloApiData.latlng origin = new skedSkeduloApiData.latlng();
                origin.lat = resource.sked_Home_Address_Geolocation__Latitude__s;
                origin.lng = resource.sked_Home_Address_Geolocation__Longitude__s;
                origins.add(origin);
                
                List<skedSkeduloApiData.latlng> destinations = new List<skedSkeduloApiData.latlng>();
                skedSkeduloApiData.latlng destination = new skedSkeduloApiData.latlng();
                destination.lat = resource.sked_Work_Address_GeoLocation__Latitude__s;
                destination.lng = resource.sked_Work_Address_GeoLocation__Longitude__s;
                destinations.add(destination);

                skedSkeduloApiData.distanceMatrixResult distanceMatrixResult = apiManager.calculateDistanceMatrix(origins, destinations);
                List<skedSkeduloApiData.Element> elements = distanceMatrixResult.result.matrix.get(0);
                skedSkeduloApiData.Element element = elements.get(0);
                
                if (element.distance != NULL) {
                    decimal travelDistance = Math.ceil(element.distance.distanceInMeters / skedConstants.METTER_PER_MILE);
                    resource.sked_Distance_Home_To_Work__c = travelDistance;
                    mapResourcesToUpdate.put(resource.Id, resource);
                }
            }
        }

        if (!mapResourcesToUpdate.isEmpty()) {
            update mapResourcesToUpdate.values();
        }
    }
    
    global void finish(Database.BatchableContext BC) {

    }
    
}