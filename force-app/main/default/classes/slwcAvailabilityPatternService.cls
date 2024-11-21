global class slwcAvailabilityPatternService {
    
    @AuraEnabled
    public static slwcAuraResult saveAvailabilityPattern(availabilityPattern model) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        skedSkeduloApiData.availabilityPatternPayload payload = generateAvailabilityPatternPayload(model);
        skedSkeduloApiData.upsertAvailabilityPatternResult calloutResult = apiManager.upsertAvailabilityPattern(payload);
        
        result.success = calloutResult.error == NULL && calloutResult.errors == NULL;
        
        if (result.success) {
            Set<Id> resourceIds = new Set<Id>();
            for (availabilityPatternResource patternResource : model.availabilityPatternResources) {
                resourceIds.add(patternResource.resourceId);
            }
            if (!string.isBlank(model.id)) {
                delete [SELECT Id 
                        FROM sked__Availability_Pattern_Resource__c 
                        WHERE sked__Availability_Pattern__c = :model.id
                        AND sked__Resource__c NOT IN :resourceIds];
            }
        }
        
        result.returnedData = calloutResult;
        return result;
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private static skedSkeduloApiData.availabilityPatternPayload generateAvailabilityPatternPayload(availabilityPattern model) {
        skedSkeduloApiData.availabilityPatternPayload payload = new skedSkeduloApiData.availabilityPatternPayload();
        
        string timezoneSidId = UserInfo.getTimeZone().getID();
        
        skedSkeduloApiData.pattern pattern = new skedSkeduloApiData.pattern();
        payload.pattern = pattern;
        
        pattern.UID = model.id;
        pattern.name = model.name;
        pattern.description = model.description;
        
        pattern.pattern = (skedSkeduloApiData.pattern2)Json.deserialize(model.pattern, skedSkeduloApiData.pattern2.class);
        
        if (model.availabilityPatternResources != NULL) {
            payload.resources = new List<skedSkeduloApiData.resource>();
            for (availabilityPatternResource patternResource : model.availabilityPatternResources) {
                skedSkeduloApiData.resource resource = new skedSkeduloApiData.resource();
                resource.UID = patternResource.id;
                resource.resourceId = patternResource.resourceId;
                
                patternResource.startTime = patternResource.startTime == NULL ? 0 : patternResource.startTime;
                DateTime patternResourceStart = skedDateTimeUtils.newDateTimeInstance(patternResource.startDate, patternResource.startTime, timezoneSidId);
                resource.start = patternResourceStart;
                
                patternResource.endTime = patternResource.endTime == NULL ? 0 : patternResource.endTime;
                if (!string.isBlank(patternResource.endDate) && patternResource.endTime != NULL) {
                    DateTime patternResourceEnd = skedDateTimeUtils.newDateTimeInstance(patternResource.endDate, patternResource.endTime, timezoneSidId);
                    resource.end_x = patternResourceEnd;
                }
                
                payload.resources.add(resource);
            }
        }
        
        return payload;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class availabilityPattern {
        public string id;
        public string name;
        public string description;
        public string hash;
        public string pattern;
        public skedAvailabilityPatternData patternData;
        public List<availabilityPatternResource> availabilityPatternResources;
    }
    
    public class availabilityPatternResource {
        public string id;
        public string name;
        public string availabilityPatternId;
        public string endDate;
        public integer endTime;
        public string resourceId;
        public string startDate;
        public integer startTime;
        public string status;
    }

}