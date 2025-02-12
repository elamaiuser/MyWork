public class skedTravelTimeIndexItemUtils {
    
    public static String getKey(Location loc) {
        return string.valueOf(loc.latitude) + ' ' + string.valueOf(loc.longitude);
    }
    
    public static String getKey(Location fromLoc, Location toLoc) {
        return string.valueOf(fromLoc.latitude) + ' ' + string.valueOf(fromLoc.longitude) 
            + ':' + string.valueOf(toLoc.latitude) + ' ' + string.valueOf(toLoc.longitude);
    }

    public static String getOrderingKey(String dir, Location loc) {
        return dir + loc.latitude + ':' + loc.longitude;
    }

    public static Map<String, sked_Travel_Time_Index_Item__c> getTravelTimeIndexItemsByKey(Set<String> keys) {
        Map<String, sked_Travel_Time_Index_Item__c> ttiiByKey = new Map<String, sked_Travel_Time_Index_Item__c>();
        for(sked_Travel_Time_Index_Item__c ttii : [
            SELECT Id, sked_Key__c, sked_Travel_Distance__c, sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_Backup__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Key__c IN :keys
        ]) {
            ttiiByKey.put(ttii.sked_Key__c, ttii);
        }

        return ttiiByKey;
    }

    public static void createTravelTimeIndexItems(List<TravelTimeIndexItem> ttiis) {
        ttiis = addFromToItems(ttiis);
        Set<String> ttiiKeys = new Set<String>();
        for (TravelTimeIndexItem ttii : ttiis) {
            ttiiKeys.add(getKey(ttii.fromLoc, ttii.toLoc));
        }

        Map<String, sked_Travel_Time_Index_Item__c> ttiisByKey = skedTravelTimeIndexItemUtils.getTravelTimeIndexItemsByKey(ttiiKeys);
        List<sked_Travel_Time_Index_Item__c> ttiisToAdd = new List<sked_Travel_Time_Index_Item__c>();
        Set<String> addedKeys = new Set<String>();

        for (TravelTimeIndexItem ttii : ttiis) {
            String key = getKey(ttii.fromLoc, ttii.toLoc);

            if (!ttiisByKey.containsKey(key) && !addedKeys.contains(key)) {
                Location coLoc = ttii.dir == skedConstants.TTII_DIRECTION_CO_TO_SITE ? ttii.fromLoc : ttii.toLoc;
                ttiisToAdd.add(new sked_Travel_Time_Index_Item__c(
                    sked_From__Latitude__s = ttii.fromLoc.latitude,
                    sked_From__Longitude__s = ttii.fromLoc.longitude,
                    sked_To__Latitude__s = ttii.toLoc.latitude,
                    sked_To__Longitude__s = ttii.toLoc.longitude,
                    sked_Timezone__c = ttii.timezone,
                    sked_Ordering_Key__c = getOrderingKey(ttii.dir, coLoc)
                ));
                addedKeys.add(key);
            }
        }

        if (!ttiisToAdd.isEmpty()) {
            insert ttiisToAdd;
        }
    }

    public static void updateTravelTimeBreakdownJSONBackup(List<sked_Travel_Time_Index_Item__c> ttiis) {
        List<sked_Travel_Time_Index_Item__c> ttiisToUpdate = new List<sked_Travel_Time_Index_Item__c>();
        List<String> reversedDirectionKeys = new List<String>();
        String noData = skedConstants.NO_TRAVEL_TIME_DATA;
        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            String reversedDirectionKey = getKey(ttii.sked_To__c, ttii.sked_From__c);
            reversedDirectionKeys.add(reversedDirectionKey);
            if(ttii.sked_Travel_Time_Breakdown_JSON__c != null && ttii.sked_Travel_Time_Breakdown_JSON__c != noData) {
                ttii.sked_Travel_Time_Breakdown_JSON_Backup__c = ttii.sked_Travel_Time_Breakdown_JSON__c;
                ttiisToUpdate.add(ttii);
            }
        }
        for (sked_Travel_Time_Index_Item__c reversedTtii : [
            SELECT Id, sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_Backup__c
            FROM sked_Travel_Time_Index_Item__c
            WHERE sked_Key__c IN :reversedDirectionKeys
        ]) {
            if(reversedTtii.sked_Travel_Time_Breakdown_JSON__c != null && reversedTtii.sked_Travel_Time_Breakdown_JSON__c != noData) {
                reversedTtii.sked_Travel_Time_Breakdown_JSON_Backup__c = reversedTtii.sked_Travel_Time_Breakdown_JSON__c;
                ttiisToUpdate.add(reversedTtii);
            }   
        }
        update ttiisToUpdate;
     }
     
    private static List<TravelTimeIndexItem> addFromToItems(List<TravelTimeIndexItem> ttiis) {
        List<TravelTimeIndexItem> newItems = new List<TravelTimeIndexItem>();
        for (TravelTimeIndexItem ttii : ttiis) {
            String newDir = ttii.dir == skedConstants.TTII_DIRECTION_CO_TO_SITE ? skedConstants.TTII_DIRECTION_SITE_TO_CO : skedConstants.TTII_DIRECTION_CO_TO_SITE;
            newItems.add(new TravelTimeIndexItem(
                ttii.toLoc,
                ttii.fromLoc,
                ttii.timezone,
                newDir
            ));
        }

        ttiis.addAll(newItems);
        return ttiis;
    }

    public class TravelTimeIndexItem {
        public Location fromLoc;
        public Location toLoc;
        public String timezone;
        public String dir;

        public TravelTimeIndexItem(Location fromLoc, Location toLoc, String timezone, String dir) {
            this.fromLoc = fromLoc;
            this.toLoc = toLoc;
            this.timezone = timezone;
            this.dir = dir;
        }
    }
}