public class skedPopulateTravelTimeForDrives implements Database.Batchable<sObject>, Database.stateful  {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id,
            sked_Staging_Location__r.sked_Geolocation__c,
            sked_Drive_Site__r.sked__GeoLocation__c
            FROM sked_Drive__c
            WHERE (sked_Travel_Time_Site_To_CO__c = NULL OR sked_Travel_Time_CO_To_Site__c = NULL)
            AND sked_Staging_Location__r.sked_Geolocation__Latitude__s != NULL
            AND sked_Drive_Site__r.sked__GeoLocation__Latitude__s != NULL
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sked_Drive__c> drives) {
        Set<string> keys = new Set<string>();
        for (sked_Drive__c drive : drives) {
            String coToSiteKey = skedTravelTimeIndexItemUtils.getKey(drive.sked_Staging_Location__r.sked_Geolocation__c,
                                                                     drive.sked_Drive_Site__r.sked__GeoLocation__c);
            String siteToCoKey = skedTravelTimeIndexItemUtils.getKey(drive.sked_Drive_Site__r.sked__GeoLocation__c,
                                                                     drive.sked_Staging_Location__r.sked_Geolocation__c);

            keys.add(coToSiteKey);
            keys.add(siteToCoKey);
        }
        Map<String, sked_Travel_Time_Index_Item__c> ttiisByKey = skedTravelTimeIndexItemUtils.getTravelTimeIndexItemsByKey(keys);

        Map<Id, sked_Drive__c> mapDriveToUpdate = new Map<Id, sked_Drive__c>();
        for (sked_Drive__c drive : drives) {
            String coToSiteKey = skedTravelTimeIndexItemUtils.getKey(drive.sked_Staging_Location__r.sked_Geolocation__c,
                                                                     drive.sked_Drive_Site__r.sked__GeoLocation__c);
            String siteToCoKey = skedTravelTimeIndexItemUtils.getKey(drive.sked_Drive_Site__r.sked__GeoLocation__c,
                                                                     drive.sked_Staging_Location__r.sked_Geolocation__c);

            if (ttiisByKey.containsKey(coToSiteKey)) {
                sked_Travel_Time_Index_Item__c coToSiteTravelTime = ttiisByKey.get(coToSiteKey);
                drive.sked_Travel_Time_CO_To_Site__c = coToSiteTravelTime.Id;
                mapDriveToUpdate.put(drive.Id, drive);
            }

            if (ttiisByKey.containsKey(siteToCoKey)) {
                sked_Travel_Time_Index_Item__c siteToCoTravelTime = ttiisByKey.get(siteToCoKey);
                drive.sked_Travel_Time_Site_To_CO__c = siteToCoTravelTime.Id;
                mapDriveToUpdate.put(drive.Id, drive);
            }
        }

        if (!mapDriveToUpdate.isEmpty()) {
            skedHubBase.BypassUpdateTriggers = true;
            update mapDriveToUpdate.values();
            skedHubBase.BypassUpdateTriggers = false;
        }
    }

    public void finish(Database.BatchableContext BC) {}

}