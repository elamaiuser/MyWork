public class skedCOSLUtils {
    
    public static void generateCOSLForCurrentCOAddress() {
        Date currentDate = system.today();
        Date maxDate = Date.newInstance(4000, 12, 31);
        
        List<Biomed_Collection_Op_Center__c> collectionOperations = [
            SELECT Id, Staging_Location_Address__c, Staging_Location_Geolocation__Latitude__s, Staging_Location_Geolocation__Longitude__s
            FROM Biomed_Collection_Op_Center__c
            WHERE Staging_Location_Address__c != NULL
            AND Staging_Location_Geolocation__Latitude__s != NULL
            AND Staging_Location_Geolocation__Longitude__s != NULL
        ];
        
        List<string> geoKeys = new List<string>();
        for (Biomed_Collection_Op_Center__c collectionOperation : collectionOperations) {
            string geoKey = collectionOperation.Staging_Location_Geolocation__Latitude__s + ':' + collectionOperation.Staging_Location_Geolocation__Longitude__s;
            geoKeys.add(geoKey);
        }
        
        List<sked_Staging_Location__c> existingSLs = [SELECT Id, sked_Geolocation_Key__c,
                                                      (SELECT Id, sked_Collection_Operation__c
                                                       FROM sked_Collection_Op_Staging_Locations__r
                                                       WHERE sked_End_Date__c >= TODAY)
                                                      FROM sked_Staging_Location__c
                                                      WHERE sked_Geolocation_Key__c IN :geoKeys];
        Map<string, sked_Staging_Location__c> map_geoKey_SL = new Map<string, sked_Staging_Location__c>();
        for (sked_Staging_Location__c existingSL : existingSLs) {
            map_geoKey_SL.put(existingSL.sked_Geolocation_Key__c, existingSL);
        }
        
        List<sked_Staging_Location__c> newSLs = new List<sked_Staging_Location__c>();
        for (Biomed_Collection_Op_Center__c collectionOperation : collectionOperations) {
            string geoKey = collectionOperation.Staging_Location_Geolocation__Latitude__s + ':' + collectionOperation.Staging_Location_Geolocation__Longitude__s;
            if (!map_geoKey_SL.containsKey(geoKey)) {
                sked_Staging_Location__c newSL = new sked_Staging_Location__c(
                	sked_Address__c = collectionOperation.Staging_Location_Address__c,
                	sked_GeoLocation__Latitude__s = collectionOperation.Staging_Location_Geolocation__Latitude__s,
                	sked_GeoLocation__Longitude__s = collectionOperation.Staging_Location_Geolocation__Longitude__s
                );
                newSLs.add(newSL);
                
                map_geoKey_SL.put(geoKey, newSL);
            }
        }
        
        if (!newSLs.isEmpty()) {
            insert newSLs;
        }
        
        List<sked_Collection_Op_Staging_Location__c> newCOSLs = new List<sked_Collection_Op_Staging_Location__c>();
        for (Biomed_Collection_Op_Center__c collectionOperation : collectionOperations) {
            string geoKey = collectionOperation.Staging_Location_Geolocation__Latitude__s + ':' + collectionOperation.Staging_Location_Geolocation__Longitude__s;
            if (map_geoKey_SL.containsKey(geoKey)) {
                sked_Staging_Location__c stagingLocation = map_geoKey_SL.get(geoKey);
                Set<Id> coIds = new Set<Id>();
                if (stagingLocation.sked_Collection_Op_Staging_Locations__r != NULL && !stagingLocation.sked_Collection_Op_Staging_Locations__r.isEmpty()) {
                    for (sked_Collection_Op_Staging_Location__c coStagingLocation : stagingLocation.sked_Collection_Op_Staging_Locations__r) {
                        coIds.add(coStagingLocation.sked_Collection_Operation__c);
                    }
                }
                if (!coIds.contains(collectionOperation.Id)) {
                    sked_Collection_Op_Staging_Location__c newCOSL = new sked_Collection_Op_Staging_Location__c(
                    	sked_Staging_Location__c = stagingLocation.Id,
                        sked_Collection_Operation__c = collectionOperation.Id,
                        sked_Start_Date__c = currentDate,
                        sked_End_Date__c = maxDate
                    );
                    newCOSLs.add(newCOSL);
                }
            }
        }
        
        if (!newCOSLs.isEmpty()) {
            insert newCOSLs;
        }
    }

    public static Map<Id, List<sked_Collection_Op_Staging_Location__c>> getCoslsByCoIds(List<CoslQueryModel> queryModels) {
        skedQueryBuilder queryBuilder = new skedQueryBuilder();
        queryBuilder.setFromClause('sked_Collection_Op_Staging_Location__c');
        queryBuilder.setIsOrQuery(true);
        queryBuilder.addFields(new List<String>{
            'Id', 'sked_Start_Date__c', 'sked_End_Date__c', 'sked_Collection_Operation__c', 'sked_Staging_Location__r.sked_Geolocation__c', 'sked_Staging_Location__r.sked_Timezone__c'
        });
        
        for (CoslQueryModel queryModel : queryModels) {
            String collectionOpCondition = queryBuilder.generateCondition('sked_Collection_Operation__c = {0}', queryModel.coId);
            String startDateCondition = queryBuilder.generateCondition('sked_Start_Date__c <= {0}', queryModel.endDate);
            String endDateCondition = queryBuilder.generateCondition('sked_End_Date__c >= {0}', queryModel.startDate);
                    
            queryBuilder.addConditionGroup(new List<String>{collectionOpCondition, startDateCondition, endDateCondition});
        }

        Map<Id, List<sked_Collection_Op_Staging_Location__c>> coslsByCoId = new Map<Id, List<sked_Collection_Op_Staging_Location__c>>();
        for (sked_Collection_Op_Staging_Location__c cosl : Database.query(queryBuilder.toString())) {
            List<sked_Collection_Op_Staging_Location__c> cosls = coslsByCoId.get(cosl.sked_Collection_Operation__c);

            if (cosls == null) {
                cosls = new List<sked_Collection_Op_Staging_Location__c>();
            }

            cosls.add(cosl);
            coslsByCoId.put(cosl.sked_Collection_Operation__c, cosls);
        }

        return coslsByCoId;
    }

    public class CoslQueryModel {
        public Id coId;
        public Date startDate;
        public Date endDate;

        public CoslQueryModel(Id coId, Date startDate, Date endDate) {
            this.coId = coId;
            this.startDate = startDate == null ? skedConstants.EARLIEST_START_DATE : startDate;
            this.endDate = endDAte == null ? skedConstants.LATEST_END_DATE : endDate;
        }
    }
}