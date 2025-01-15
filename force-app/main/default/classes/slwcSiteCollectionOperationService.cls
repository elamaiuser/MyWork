public class slwcSiteCollectionOperationService {
    @AuraEnabled
    public static slwcAuraResult manualRefreshTravelTimeIndexes(String siteCollectionOperationId) {
        slwcAuraResult result = new slwcAuraResult();

        List<sked_Travel_Time_Index_Item__c> ttiis = getRelatedTravelTimeItems(siteCollectionOperationId);
        if (!ttiis.isEmpty()) {
            Set<Id> ttiiIds = skedSObjectUtils.getRecordIds(ttiis);
            for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
                ttii.sked_Travel_Time_Breakdown_JSON_Backup__c = ttii.sked_Travel_Time_Breakdown_JSON__c;
                ttii.sked_Travel_Distance__c = null;
                ttii.sked_Travel_Time_Breakdown_JSON__c = null;
            }
            update ttiis;
            Database.executeBatch(new skedImmediateRefreshTravelTimeIndexBatch(new List<Id>(ttiiIds), skedSetting.instance.TravelTime.manualRefreshPriority, siteCollectionOperationId));
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasInvalidTravelTimeData(String siteCollectionOperationId) {
        Boolean hasInvalidTravelTimeData = false;
        List<sked_Travel_Time_Index_Item__c> ttiis = getRelatedTravelTimeItems(siteCollectionOperationId);
        if (!ttiis.isEmpty()) {
            for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
                if (ttii.sked_Travel_Distance__c == null || ttii.sked_Travel_Time_Breakdown_JSON__c == null
                        || ttii.sked_Travel_Time_Breakdown_JSON__c == 'NO DATA') {
                    hasInvalidTravelTimeData = true;
                }
            }
        }
        return hasInvalidTravelTimeData;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isManualRefreshInProgress(String siteCollectionOperationId) {

        Boolean isManualRefreshInProgress = false;

        List<sked_Travel_Time_Index_Refresh_Request__c> ttirrs = [
            SELECT Id
            FROM sked_Travel_Time_Index_Refresh_Request__c
            WHERE sked_Manual_Refresh_SCO_Id__c = :siteCollectionOperationId
            AND (sked_Status__c = 'Pending' OR sked_Status__c = 'In Progress')
        ];
        
        if (!ttirrs.isEmpty()) {
            isManualRefreshInProgress = true;
        }

        return isManualRefreshInProgress; 
    }
    
    @AuraEnabled    
    public static Boolean isSCOUserOverrideEnabled(String siteCollectionOperationId) {
        Boolean isSCOUserOverrideEnabled = false;
        List<sked_Site_Collection_Operation__c> scos = [
            SELECT Id, User_Override__c
            FROM sked_Site_Collection_Operation__c
            WHERE Id = :siteCollectionOperationId
        ];
        if (!scos.isEmpty()) {
            isSCOUserOverrideEnabled = scos[0].User_Override__c;
        }
        return isSCOUserOverrideEnabled;
    }

    @AuraEnabled
    public static slwcAuraResult getRelatedSiteInfo(List<Id> collectionOperationIds, Date startDate, Date endDate){
        slwcAuraResult result = new slwcAuraResult();
        List<sked_Site_Collection_Operation__c> siteCollectionOps = [
            SELECT Id, sked_Site__c, sked_Collection_Operation__c
            FROM sked_Site_Collection_Operation__c
            WHERE sked_Collection_Operation__c IN :collectionOperationIds
            AND sked_Start_Date__c <= :endDate
            AND sked_End_Date__c >= :startDate
        ];
        result.returnedData = siteCollectionOps;
        return result;
    }

    private static List<sked_Travel_Time_Index_Item__c> getRelatedTravelTimeItems(String scoId) {
        sked_Site_Collection_Operation__c siteCollectionOp = [
            SELECT Id, sked_Site__c, sked_Site__r.sked__Geolocation__c, sked_Collection_Operation__c
            FROM sked_Site_Collection_Operation__c
            WHERE Id = :scoId
        ];

        Biomed_Collection_Op_Center__c collectionOp = [
            SELECT Id,
            (SELECT Id, sked_Staging_Location__r.sked_Geolocation__c FROM sked_Collection_Op_Staging_Locations__r)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id = :siteCollectionOp.sked_Collection_Operation__c
        ];

        Set<String> keys = new Set<String>();
        if (collectionOp != null && collectionOp.sked_Collection_Op_Staging_Locations__r != null) {
            for (sked_Collection_Op_Staging_Location__c cosl : collectionOp.sked_Collection_Op_Staging_Locations__r) {
                keys.add(skedTravelTimeIndexItemUtils.getKey(cosl.sked_Staging_Location__r.sked_Geolocation__c, siteCollectionOp.sked_Site__r.sked__Geolocation__c));
                keys.add(skedTravelTimeIndexItemUtils.getKey(siteCollectionOp.sked_Site__r.sked__Geolocation__c, cosl.sked_Staging_Location__r.sked_Geolocation__c));
            }
        }

        List<sked_Travel_Time_Index_Item__c> ttiis = new List<sked_Travel_Time_Index_Item__c>();
        if (!keys.isEmpty()) {
            ttiis.addAll(skedTravelTimeIndexItemUtils.getTravelTimeIndexItemsByKey(keys).values());
        }

        return ttiis;
    }
}