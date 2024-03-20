global class skedStagingLocationZipCodeBatch implements Database.Batchable<sked_Staging_Location__c>, Database.AllowsCallouts {

    global List<sked_Staging_Location__c> start(Database.BatchableContext BC) {
        return [SELECT Id, sked_Address__c, sked_Zip_Code__c
                FROM sked_Staging_Location__c
                WHERE sked_Address__c != NULL];
    }

    global void execute(Database.BatchableContext BC, List<sked_Staging_Location__c> stagingLocations) {
        Map<Id, sked_Staging_Location__c> mapRecordToUpdate = new Map<Id, sked_Staging_Location__c>();
        for (sked_Staging_Location__c stagingLocation : stagingLocations) {
            try {
                String sessionId = sked.SkeduloAPI.getSessionId();
                sked.ApiResult.AutoComplete apiResult = sked.SkeduloAPI.autocomplete(stagingLocation.sked_Address__c, 'US', sessionId);
                
                autocompleteResponseModel autocompleteResponse = (autocompleteResponseModel)JSON.deserialize(apiResult.response, autocompleteResponseModel.class);
                string placeId = autocompleteResponse.result.predictions[0].placeId;
                
                sked.ApiResult.Place apiResult2 = sked.SkeduloAPI.place(placeId, sessionId);
                placeResult placeResponse = (placeResult)JSON.deserialize(apiResult2.response, placeResult.class);
                
                stagingLocation.sked_Zip_Code__c = placeResponse.result.addressComponents.postalCode;
                mapRecordToUpdate.put(stagingLocation.Id, stagingLocation);
            }
            catch (Exception ex) {}
        }

        if (!mapRecordToUpdate.isEmpty()) {
            update mapRecordToUpdate.values();
        }
    }
    
    global void finish(Database.BatchableContext BC) {

    }
    
    public class autocompleteResponseModel {
        public predictionsResult result;
    }
    
    public class predictionsResult {
        public List<prediction> predictions;
        public string status;
        public object errorMessage;
    }
    
    public class prediction {
        public string description;
        public string placeId;
    }
    
    public class addressComponents {
        public string postalCode;
    }
    
    public class addressComponentsResult {
        public addressComponents addressComponents;
    }

    public class placeResult {
        public addressComponentsResult result;
    }
    
}