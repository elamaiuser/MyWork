/**
 * @description: This is the Controller apex class for TravelTimePanel aura page in Site Collection Oparation.
 * @createdby: Barnojit Sharma
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 10/01/2024			    Barnojit Sharma			Controller apex class for Travel Time Breakdown information UI (HRP-10865)
 * 26/08/2024			    Apurba Bhattacharjee	HRP-13050 Issue with Travel Time JSON Not Populating on Site CO UI
 * *****************************************************************************************************************************************************************************************
 * */

public without sharing class BSF_TravelTimePanelController {

    public class BSF_TravelTimeDataWrapper {
        @AuraEnabled public String indexId {get; set;}
        @AuraEnabled public String effectiveDates {get; set;}
        @AuraEnabled public String direction {get; set;}
        @AuraEnabled public Boolean userOverride {get; set;}
        @AuraEnabled public String overrideComment {get; set;}
        @AuraEnabled public String collectionOpName {get; set;}
        @AuraEnabled public String address {get; set;}
        @AuraEnabled public List<TravelTimeBreakdownData> travelTimeBreakdownData {get; set;}
        @AuraEnabled public Boolean systemOverride {get; set;}
    }

    public class TravelTimeBreakdownData {
        @AuraEnabled public String travelTimeKey {get; set;}
        @AuraEnabled public String weekday {get; set;}
        @AuraEnabled public Integer travelTime {get; set;}
        @AuraEnabled public String startTime {get; set;}
        @AuraEnabled public String endTime {get; set;}
        @AuraEnabled public Integer travelDistance {get; set;}
    }


    @AuraEnabled
    public static void saveUpdatedRecords(List<BSF_TravelTimeDataWrapper> updatedRecords, String siteCO_Id) {
        system.debug('updatedRecords '+JSON.serialize(updatedRecords));
        system.debug('siteCO_Id '+siteCO_Id);
        List<sked_Travel_Time_Index_Item__c> objectsToUpdate = new List<sked_Travel_Time_Index_Item__c>();
        List<Id> indexIds = new List<Id>();
        List<sked_Travel_Time_Slot__c> travelTimeSlots = new List<sked_Travel_Time_Slot__c>();
        try{
            // Query travel time slots for the collection operation
            if (String.isNotBlank(siteCO_Id)) {
                List<sked_Site_Collection_Operation__c> siteCollectionOpData = [
                    SELECT Id, sked_Collection_Operation__c
                    FROM sked_Site_Collection_Operation__c
                    WHERE Id = :siteCO_Id
                    WITH SYSTEM_MODE
                    LIMIT 1
                ];

                if (!siteCollectionOpData.isEmpty()) {
                    travelTimeSlots = [
                        SELECT sked_Collection_Operation__c, sked_Weekday__c, sked_Start_Time__c, sked_End_Time__c
                        FROM sked_Travel_Time_Slot__c
                        WHERE sked_Collection_Operation__c = :siteCollectionOpData[0].sked_Collection_Operation__c
                        ORDER BY sked_Collection_Operation__c, sked_Weekday__c, sked_Start_Time__c
                    ];
                }
            }
            for (BSF_TravelTimeDataWrapper wrapper : updatedRecords) {
                if(String.isNotBlank(wrapper.indexId)){
                    indexIds.add(wrapper.indexId);
                }else{
                    throw new AuraHandledException('IndexId Missing.');
                }
            }
            System.debug('indexIds --> '+indexIds);
            if(!indexIds.isEmpty()) {
                Map<Id, sked_Travel_Time_Index_Item__c> indexItemMap = new Map<Id, sked_Travel_Time_Index_Item__c>([SELECT Id, 
                                                                                                                            sked_Travel_Time_Breakdown_JSON__c,
                                                                                                                            sked_Average_Travel_Time__c,
                                                                                                                            User_Override__c,
                                                                                                                            Override_Comment__c
                                                                                                                    FROM sked_Travel_Time_Index_Item__c
                                                                                                                    WHERE Id IN: indexIds
                                                                                                                    WITH SYSTEM_MODE]);
                if(indexItemMap.isEmpty()) {
                    throw new AuraHandledException('No Record Found.');
                }
                System.debug('indexItemMap --> '+indexItemMap.size());
                for (BSF_TravelTimeDataWrapper wrapper : updatedRecords) {
                    Id indexRecId = wrapper.indexId;
                    Boolean updateFlag = false;
                    Boolean updateJSONFlag = false;
                    Decimal averageTime = 0;
                    List<Integer> travelTimeSet = new List<Integer>();
                    List<TravelTimeBreakdownData> ttWrapData = wrapper.travelTimeBreakdownData;
                    System.debug('indexItemMap.get(indexRecId) --> '+indexItemMap.get(indexRecId));
                    sked_Travel_Time_Index_Item__c indexRec = indexItemMap.get(indexRecId);
                    Map<String, TravelTimeBreakdownJSON> ttJSONMap = new Map<String, TravelTimeBreakdownJSON>();
                    
                    if(wrapper.userOverride!= null &&  indexRec.User_Override__c != wrapper.userOverride){
                        updateFlag = true;
                        indexRec.User_Override__c = wrapper.userOverride;
                        indexRec.Override_Comment__c = String.isNotBlank(wrapper.overrideComment) ? wrapper.overrideComment.left(255) : '';
                    }
                    
                    if(wrapper.userOverride== true) {
                        updateFlag = true;
                        indexRec.Override_Comment__c = String.isNotBlank(wrapper.overrideComment) ? wrapper.overrideComment.left(255) : '';
                    }
                    
                    if(indexRec.sked_Travel_Time_Breakdown_JSON__c != null && indexRec.sked_Travel_Time_Breakdown_JSON__c != 'NO DATA') {
                        System.debug('indexRec.sked_Travel_Time_Breakdown_JSON__c --> '+indexRec.sked_Travel_Time_Breakdown_JSON__c);
                        List<TravelTimeBreakdownJSON> jsonData = (List<TravelTimeBreakdownJSON>) JSON.deserialize(indexRec.sked_Travel_Time_Breakdown_JSON__c, 
                                                                                                                    List<TravelTimeBreakdownJSON>.class);
                        for(TravelTimeBreakdownJSON ttData : jsonData) {
                            String key = String.valueOf(indexRecId).right(10)+ttData.weekday.left(4).toLowerCase()+ttData.startOfWindow.left(2)+ttData.endOfWindow.left(2);
                            ttJSONMap.put(key,ttData);
                        }
                    } else {
                        List<TravelTimeBreakdownJSON> jsonData = generateEmptyTravelTimeData(1, travelTimeSlots);
                        for(TravelTimeBreakdownJSON ttData : jsonData) {
                            String key = String.valueOf(indexRecId).right(10)+ttData.weekday.left(4).toLowerCase()+ttData.startOfWindow.left(2)+ttData.endOfWindow.left(2);
                            ttJSONMap.put(key,ttData);
                        }
                    }
                    if(!ttJSONMap.isEmpty()) {
                        for(TravelTimeBreakdownData wrap : ttWrapData) {
                            if(String.isNotBlank(wrap.travelTimeKey)) {
                                TravelTimeBreakdownJSON jsondata = ttJSONMap.get(wrap.travelTimeKey);
                                System.debug('jsondata: '+jsondata);
                                System.debug('wrap: '+wrap);
                                travelTimeSet.add(wrap.travelTime);
                                if(wrap.travelTime == null) {
                                    throw new AuraHandledException('TravelTime is Null.');
                                }else if(jsondata != NULL && jsondata.travelTime != wrap.travelTime) {
                                    jsondata.travelTime = wrap.travelTime;
                                    ttJSONMap.put(wrap.travelTimeKey,jsondata);
                                    updateJSONFlag = true;
                                }
                            } else {
                                throw new AuraHandledException('TravelTimeKey Missing.');
                            }
                        }
                    }
                    if(updateJSONFlag) {
                        updateFlag = true;
                        for(Integer item : travelTimeSet) averageTime += item;
                            averageTime/=travelTimeSet.size();
                        indexRec.sked_Average_Travel_Time__c = averageTime.round(System.RoundingMode.HALF_UP);
                        indexRec.sked_Travel_Time_Breakdown_JSON__c = JSON.serialize(ttJSONMap.values());
                    }
                    if(updateFlag){
                        objectsToUpdate.add(indexRec);
                    }
                }
            }
            System.debug('objectsToUpdate --> '+objectsToUpdate.size());
            if (!objectsToUpdate.isEmpty()) {
                try {
                    Database.update(objectsToUpdate,true);
                } catch (DmlException e) {
                    system.debug('#ex Database#' + e.getMessage());
                    system.debug('#ex Database#' + e.getStackTraceString());
                    throw new AuraHandledException('Error updating records: ' + e.getMessage());
                }
            }
        }catch(Exception ex) {
            system.debug('#ex #' + ex.getMessage());
            system.debug('#ex #' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<BSF_TravelTimeDataWrapper> getData(String siteCO_Id) {
        system.debug('siteCO_Id## '+siteCO_Id);
        List<BSF_TravelTimeDataWrapper> travelTimeDataWrap = new List<BSF_TravelTimeDataWrapper>();

        if(String.isBlank(siteCO_Id)) {
            return travelTimeDataWrap;
        }

        Boolean isRefreshInProgress = false;
        List<sked_Travel_Time_Index_Refresh_Request__c> refreshRequestList = [
            SELECT Id 
            FROM sked_Travel_Time_Index_Refresh_Request__c 
            WHERE sked_Manual_Refresh_SCO_Id__c = :siteCO_Id
            AND sked_Status__c IN ('Pending', 'In Progress')
            LIMIT 1
        ];
        if(!refreshRequestList.isEmpty()) {
            isRefreshInProgress = true;
        }
        
        Location site_Location;
        String siteKeystr;
        String CollectionOperationName;
        Map<Id,List<sked_Travel_Time_Index_Item__c>> stagingLocation_ttIndexMap = new Map<Id,List<sked_Travel_Time_Index_Item__c>>();
        Map<Id,List<sked_Collection_Op_Staging_Location__c>> stagingLocation_stagingLocationCOMap = new Map<Id,List<sked_Collection_Op_Staging_Location__c>>();
        Map<Id,sked_Staging_Location__c> stagingLocationMap = new Map<Id,sked_Staging_Location__c>();
        Map<String,sked_Travel_Time_Index_Item__c> indexItemMap = new Map<String,sked_Travel_Time_Index_Item__c>();
        Map<Id,String> ttIndex_DirectionMap = new Map<Id,String>();
        Map<Id,Location> stagingGeoLocationMap = new Map<Id,Location>();
        List<Id> stopDuplicateEnty_SC = new List<Id>();

        String todayStr = Date.today().format();
        String systemOverrideComment = BSF_Constants.SYSTEM_TTBD_OVERRIDE_COMMENT.replace('{0}',todayStr);

        List<sked_Site_Collection_Operation__c> siteCollectionOpData = [
            SELECT Id,
                sked_Collection_Operation__c,
                sked_Collection_Operation__r.Name,
                sked_Site__c,
                sked_Site__r.sked__GeoLocation__latitude__s,
                sked_Site__r.sked__GeoLocation__longitude__s
            FROM sked_Site_Collection_Operation__c 
            WHERE Id =: siteCO_Id
            AND sked_Collection_Operation__c != null
            AND sked_Site__c != null
            AND sked_Site__r.sked__GeoLocation__latitude__s != null
            AND sked_Site__r.sked__GeoLocation__longitude__s != null
            WITH SYSTEM_MODE
        ];

        CollectionOperationName = siteCollectionOpData.get(0).sked_Collection_Operation__r.Name;
        site_Location = Location.newInstance(siteCollectionOpData.get(0).sked_Site__r.sked__GeoLocation__latitude__s,
                                                siteCollectionOpData.get(0).sked_Site__r.sked__GeoLocation__longitude__s);
        siteKeystr = String.valueOf(site_Location.getLatitude())
                    + String.valueOf(site_Location.getLongitude()); //HRP-13050

        List<sked_Travel_Time_Slot__c> allTravelTimeSlots = [
            SELECT sked_Collection_Operation__c, sked_Weekday__c, sked_Start_Time__c, sked_End_Time__c
            FROM sked_Travel_Time_Slot__c
            WHERE sked_Collection_Operation__c = :siteCollectionOpData[0].sked_Collection_Operation__c
            ORDER BY sked_Collection_Operation__c, sked_Weekday__c, sked_Start_Time__c
        ];

        List<sked_Collection_Op_Staging_Location__c> stagingLocationCOList = [
            SELECT Id,
                sked_End_Date__c,
                sked_Start_Date__c,
                sked_Staging_Location__c,
                sked_Staging_Location__r.sked_GeoLocation__latitude__s,
                sked_Staging_Location__r.sked_GeoLocation__longitude__s,
                sked_Staging_Location__r.sked_Address__c,
                sked_Staging_Location__r.sked_Zip_Code__c
            FROM sked_Collection_Op_Staging_Location__c 
            WHERE sked_Collection_Operation__c =: siteCollectionOpData[0].sked_Collection_Operation__c
            AND sked_Staging_Location__c != null
            AND sked_Staging_Location__r.sked_GeoLocation__latitude__s != null
            AND sked_Staging_Location__r.sked_GeoLocation__longitude__s != null
            AND sked_Start_Date__c != null
            WITH SYSTEM_MODE
            ORDER BY sked_Start_Date__c DESC
        ]; 

        for (sked_Collection_Op_Staging_Location__c slco : stagingLocationCOList) {
            List<sked_Collection_Op_Staging_Location__c> tempList = new List<sked_Collection_Op_Staging_Location__c>{slco};
            if (stagingLocation_stagingLocationCOMap.isEmpty() || !stagingLocation_stagingLocationCOMap.containsKey(slco.sked_Staging_Location__c)) {
                stagingLocationMap.put(slco.sked_Staging_Location__c,slco.sked_Staging_Location__r);
                stagingGeoLocationMap.put(slco.sked_Staging_Location__c,
                                            Location.newInstance(slco.sked_Staging_Location__r.sked_GeoLocation__latitude__s,
                                            slco.sked_Staging_Location__r.sked_GeoLocation__longitude__s));
            }
            else {
                tempList.addAll(stagingLocation_stagingLocationCOMap.get(slco.sked_Staging_Location__c));
            }
            stagingLocation_stagingLocationCOMap.put(slco.sked_Staging_Location__c,tempList);
        }
        System.debug('stagingLocation_stagingLocationCOMap : '+stagingLocation_stagingLocationCOMap.size());
        System.debug('stagingGeoLocationMap : '+stagingGeoLocationMap.size());
        if(stagingGeoLocationMap.isEmpty()) {
            return travelTimeDataWrap;
        }
        String indexItemQuerry = 'SELECT Id, sked_From__latitude__s, sked_From__longitude__s, sked_To__latitude__s, sked_To__longitude__s, '
                                        +'Override_Comment__c, User_Override__c, sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_Backup__c FROM sked_Travel_Time_Index_Item__c WHERE ';
        String indexItemWhereCl_COtoSite = ' sked_To__latitude__s = '+site_Location.getLatitude()
                                            +' AND sked_To__longitude__s = '+site_Location.getLongitude();
        String indexItemWhereCl_SitetoCO = ' sked_From__latitude__s = '+site_Location.getLatitude()
                                            +' AND sked_From__longitude__s = '+site_Location.getLongitude();
        String indexItemWhereCl_COtoSite_StagingL = ' AND (';
        String indexItemWhereCl_SitetoCO_StagingL = ' AND (';

        for(Id slId : stagingGeoLocationMap.keySet()) {
            Location loc = stagingGeoLocationMap.get(slId);
            String indexStr_COtoSite = '( sked_From__latitude__s = '+loc.getLatitude();
            indexStr_COtoSite = indexStr_COtoSite + ' AND sked_From__longitude__s = '+loc.getLongitude();
            indexStr_COtoSite = indexStr_COtoSite + ' )';

            String indexStr_SitetoCO = '( sked_To__latitude__s = '+loc.getLatitude();
            indexStr_SitetoCO = indexStr_SitetoCO + ' AND sked_To__longitude__s = '+loc.getLongitude();
            indexStr_SitetoCO = indexStr_SitetoCO + ' )';

            if(indexItemWhereCl_COtoSite_StagingL.length() == 6) {
                indexItemWhereCl_COtoSite_StagingL = indexItemWhereCl_COtoSite_StagingL + indexStr_COtoSite;
            }else {
                indexItemWhereCl_COtoSite_StagingL = indexItemWhereCl_COtoSite_StagingL + ' OR ' + indexStr_COtoSite;
            }

            if(indexItemWhereCl_SitetoCO_StagingL.length() == 6) {
                indexItemWhereCl_SitetoCO_StagingL = indexItemWhereCl_SitetoCO_StagingL + indexStr_SitetoCO;
            }else {
                indexItemWhereCl_SitetoCO_StagingL = indexItemWhereCl_SitetoCO_StagingL + ' OR ' + indexStr_SitetoCO;
            }
        }

        indexItemWhereCl_COtoSite_StagingL = indexItemWhereCl_COtoSite_StagingL + ' )';
        indexItemWhereCl_SitetoCO_StagingL = indexItemWhereCl_SitetoCO_StagingL + ' )';

        String indexItemWhereCl = '('+indexItemWhereCl_COtoSite + indexItemWhereCl_COtoSite_StagingL+' ) OR ('
                                    +indexItemWhereCl_SitetoCO + indexItemWhereCl_SitetoCO_StagingL+' )';
        

        System.debug('Index Item SOQL : '+indexItemQuerry+indexItemWhereCl);  
        List<sked_Travel_Time_Index_Item__c> indexItemList = Database.query(indexItemQuerry+indexItemWhereCl,AccessLevel.SYSTEM_MODE);      
        System.debug('Index Item SOQL Data: '+indexItemList.size());         
        if(indexItemList.isEmpty()) {
            return travelTimeDataWrap;
        }

        for(sked_Travel_Time_Index_Item__c ttData : indexItemList) {
            //HRP-13050 --> Start
            Location source = Location.newInstance(ttData.sked_From__latitude__s, ttData.sked_From__longitude__s);
            Location destination = Location.newInstance(ttData.sked_To__latitude__s, ttData.sked_To__longitude__s);
            String key = String.valueOf(source.getLatitude())
                        +String.valueOf(source.getLongitude())
                        +String.valueOf(destination.getLatitude())
                        +String.valueOf(destination.getLongitude());
            indexItemMap.put(key,ttData);
            //HRP-13050 --> End
        }
        for(Id slId : stagingGeoLocationMap.keySet()) {
            List<sked_Travel_Time_Index_Item__c> ttDataList = new List<sked_Travel_Time_Index_Item__c>();
            String siteToCOKey = siteKeystr + String.valueOf(stagingGeoLocationMap.get(slId).getLatitude()) 
                                + String.valueOf(stagingGeoLocationMap.get(slId).getLongitude());
            String coToSiteKey = String.valueOf(stagingGeoLocationMap.get(slId).getLatitude()) 
                                + String.valueOf(stagingGeoLocationMap.get(slId).getLongitude())+ siteKeystr;
            
            if(indexItemMap.containsKey(siteToCOKey) && (stopDuplicateEnty_SC.isEmpty() || !stopDuplicateEnty_SC.contains(indexItemMap.get(siteToCOKey).Id))) {
                stopDuplicateEnty_SC.add(indexItemMap.get(siteToCOKey).Id);
                ttDataList.add(indexItemMap.get(siteToCOKey));
                ttIndex_DirectionMap.put(indexItemMap.get(siteToCOKey).Id,'Site to CO');
            }
            
            if(indexItemMap.containsKey(coToSiteKey) && (stopDuplicateEnty_SC.isEmpty() || !stopDuplicateEnty_SC.contains(indexItemMap.get(coToSiteKey).Id))) {
                stopDuplicateEnty_SC.add(indexItemMap.get(coToSiteKey).Id);
                ttDataList.add(indexItemMap.get(coToSiteKey));
                ttIndex_DirectionMap.put(indexItemMap.get(coToSiteKey).Id,'CO to Site');
            }

            if(!ttDataList.isEmpty()) {
                stagingLocation_ttIndexMap.put(slId,ttDataList);
            }
        }

        System.debug('stagingLocation_ttIndexMap : '+stagingLocation_ttIndexMap.size());  
        if(stagingLocation_ttIndexMap.isEmpty()) {
            return travelTimeDataWrap;
        }

        for(Id slId : stagingLocation_ttIndexMap.keySet()) {
            for(sked_Travel_Time_Index_Item__c ttRec : stagingLocation_ttIndexMap.get(slId)) {
                BSF_TravelTimeDataWrapper wrapper = new BSF_TravelTimeDataWrapper();
                wrapper.indexId = ttRec.Id;
                String efDates = '';
                for(sked_Collection_Op_Staging_Location__c cosl : stagingLocation_stagingLocationCOMap.get(slId)) {
                    String sDate = getDate(cosl.sked_Start_Date__c);
                    String eDate = getDate(cosl.sked_End_Date__c);
                    if(String.isNotBlank(efDates)) {
                        efDates = efDates +', '+ sDate +' to '+ eDate;
                    }else {
                        efDates = sDate +' to '+ eDate;
                    }
                }
                wrapper.effectiveDates = efDates;
                wrapper.collectionOpName = CollectionOperationName;
                wrapper.address = stagingLocationMap.get(slId).sked_Address__c;
                wrapper.userOverride = ttRec.User_Override__c;
                wrapper.overrideComment = String.isBlank(ttRec.Override_Comment__c) ? '' : ttRec.Override_Comment__c;
                wrapper.direction = ttIndex_DirectionMap.get(ttRec.Id);
                wrapper.systemOverride = false;
                wrapper.travelTimeBreakdownData = new List<TravelTimeBreakdownData>();
                if(ttRec.sked_Travel_Time_Breakdown_JSON__c != 'NO DATA' && ttRec.sked_Travel_Time_Breakdown_JSON__c != null) {
                    List<TravelTimeBreakdownJSON> jsonData = (List<TravelTimeBreakdownJSON>) JSON.deserialize(ttRec.sked_Travel_Time_Breakdown_JSON__c, List<TravelTimeBreakdownJSON>.class);
                    for(TravelTimeBreakdownJSON ttData : jsonData) {
                        wrapper.travelTimeBreakdownData.add(transformTTBDataToDataWrapper(ttData, wrapper.indexId));
                    }
                }
                else if(ttRec.sked_Travel_Time_Breakdown_JSON_Backup__c != null) {                    
                    List<TravelTimeBreakdownJSON> jsonData = (List<TravelTimeBreakdownJSON>) JSON.deserialize(ttRec.sked_Travel_Time_Breakdown_JSON_Backup__c, List<TravelTimeBreakdownJSON>.class);
                    for(TravelTimeBreakdownJSON ttData : jsonData) {
                        wrapper.travelTimeBreakdownData.add(transformTTBDataToDataWrapper(ttData, wrapper.indexId));
                        if(!isRefreshInProgress) {
                            wrapper.userOverride = true;
                            wrapper.systemOverride = true;
                            wrapper.overrideComment = systemOverrideComment;
                        } else {
                            wrapper.userOverride = ttRec.User_Override__c;
                            wrapper.systemOverride = false;
                        }                       
                    }
                }
                else {
                    List<TravelTimeBreakdownJSON> emptyJsonData = generateEmptyTravelTimeData(0, allTravelTimeSlots);
                    for(TravelTimeBreakdownJSON ttData : emptyJsonData) {
                        wrapper.travelTimeBreakdownData.add(transformTTBDataToDataWrapper(ttData, wrapper.indexId));
                        if(!isRefreshInProgress) {
                            wrapper.userOverride = true;
                            wrapper.systemOverride = true;
                            wrapper.overrideComment = systemOverrideComment;
                        } else {
                            wrapper.userOverride = ttRec.User_Override__c;
                            wrapper.systemOverride = false;
                        }
                    }
                }
                travelTimeDataWrap.add(wrapper);
            }
        }        
        system.debug('travelTimeDataWrap '+JSON.serialize(travelTimeDataWrap));
        return travelTimeDataWrap;
    }

    private static List<TravelTimeBreakdownJSON> generateEmptyTravelTimeData(Integer travelTime, List<sked_Travel_Time_Slot__c> travelTimeSlots) {
        List<TravelTimeBreakdownJSON> travelTimeBreakdownJSON = new List<TravelTimeBreakdownJSON>();

        // If travel time slots are provided, use them
        if (travelTimeSlots != null && !travelTimeSlots.isEmpty()) {
            for (sked_Travel_Time_Slot__c slot : travelTimeSlots) {
                TravelTimeBreakdownJSON ttData = new TravelTimeBreakdownJSON();
                ttData.weekday = slot.sked_Weekday__c;
                ttData.travelTime = travelTime;
                ttData.travelDistance = 0;
                ttData.startOfWindow = convertNumericTimeToString(slot.sked_Start_Time__c);
                ttData.endOfWindow = convertNumericTimeToString(slot.sked_End_Time__c);
                travelTimeBreakdownJSON.add(ttData);
            }
        } else {
            // Fallback to custom metadata if no travel time slots provided
            List<sked_Travel_Time_Breakdown_Setting__mdt> settings = [
                SELECT sked_Weekday__c,
                       sked_Start_At_Time_1__c, sked_Start_At_Time_2__c, sked_Start_At_Time_3__c,
                       sked_End_At_Time_1__c, sked_End_At_Time_2__c, sked_End_At_Time_3__c
                FROM sked_Travel_Time_Breakdown_Setting__mdt
                WHERE sked_Weekday__c != null
                ORDER BY sked_Weekday__c
            ];

            for (sked_Travel_Time_Breakdown_Setting__mdt setting : settings) {
                // Build list of time pairs dynamically
                List<TimePair> timePairs = buildTimePairs(setting);

                // Create travel time breakdown records for this weekday
                for (TimePair pair : timePairs) {
                    TravelTimeBreakdownJSON ttData = new TravelTimeBreakdownJSON();
                    ttData.weekday = setting.sked_Weekday__c;
                    ttData.travelTime = travelTime;
                    ttData.travelDistance = 0;
                    ttData.startOfWindow = convertNumericTimeToString(pair.startTime);
                    ttData.endOfWindow = convertNumericTimeToString(pair.endTime);
                    travelTimeBreakdownJSON.add(ttData);
                }
            }
        }

        return travelTimeBreakdownJSON;
    }

    // Helper method to build time pairs from metadata record
    private static List<TimePair> buildTimePairs(sked_Travel_Time_Breakdown_Setting__mdt setting) {
        List<TimePair> timePairs = new List<TimePair>();

        if (setting.sked_Start_At_Time_1__c != null && setting.sked_End_At_Time_1__c != null) {
            timePairs.add(new TimePair(setting.sked_Start_At_Time_1__c, setting.sked_End_At_Time_1__c));
        }
        if (setting.sked_Start_At_Time_2__c != null && setting.sked_End_At_Time_2__c != null) {
            timePairs.add(new TimePair(setting.sked_Start_At_Time_2__c, setting.sked_End_At_Time_2__c));
        }
        if (setting.sked_Start_At_Time_3__c != null && setting.sked_End_At_Time_3__c != null) {
            timePairs.add(new TimePair(setting.sked_Start_At_Time_3__c, setting.sked_End_At_Time_3__c));
        }

        return timePairs;
    }

    // Helper method to convert numeric time (e.g., 800) to string format (e.g., "08:00:00.000Z")
    private static String convertNumericTimeToString(Decimal timeValue) {
        Integer timeInt = timeValue.intValue();
        Integer hours = timeInt / 100;
        Integer minutes = Math.mod(timeInt, 100);

        String hoursStr = String.valueOf(hours).leftPad(2, '0');
        String minutesStr = String.valueOf(minutes).leftPad(2, '0');

        return hoursStr + ':' + minutesStr + ':00.000Z';
    }

    // Helper class to hold time pairs
    private class TimePair {
        Decimal startTime;
        Decimal endTime;

        TimePair(Decimal start, Decimal endVal) {
            this.startTime = start;
            this.endTime = endVal;
        }
    }

    private static TravelTimeBreakdownData transformTTBDataToDataWrapper(TravelTimeBreakdownJSON ttData, String indexId) {
        TravelTimeBreakdownData dataWrap = new TravelTimeBreakdownData();
        dataWrap.weekday = ttData.weekday;
        dataWrap.travelTime = ttData.travelTime;
        dataWrap.travelDistance = ttData.travelDistance;
        dataWrap.startTime = String.isBlank(ttData.startOfWindow) ? null : getTime(ttData.startOfWindow);
        dataWrap.endTime = String.isBlank(ttData.endOfWindow) ? null : getTime(ttData.endOfWindow);
        dataWrap.travelTimeKey = indexId.right(10) + ttData.weekday.left(4).toLowerCase() + ttData.startOfWindow.left(2) + ttData.endOfWindow.left(2);        
        return dataWrap;
    }

    private static String getTime(String timeStr) {
        String timeExtract = timeStr.substringBefore('.');
        List<String> timeComponent = timeExtract.split(':');
        Integer hour = Integer.valueOf(timeComponent[0]);
        Integer minutes = Integer.valueOf(timeComponent[1]);
        String am_pm;
        if(hour == 0) {
            hour = 12;
            am_pm = 'AM';
        }else if(hour < 12) {
            am_pm = 'AM';
        }else if(hour == 12) {
            am_pm = 'PM';
        }else if(hour > 12) {
            hour = hour - 12;
            am_pm = 'PM';
        }
        if(minutes < 10) {
            System.debug('final --> '+hour+':0'+minutes+am_pm);
            return hour+':0'+minutes+am_pm;
        }else {
            System.debug('final --> '+hour+':'+minutes+am_pm);
            return hour+':'+minutes+am_pm;
        }
    }

    private static String getDate(Date dateVal) {
        DateTime dDate = DateTime.newInstance(dateVal.year(),dateVal.month(),dateVal.day());
        return dDate.format('EEE M/d/yyyy');
    }

    @AuraEnabled
    public static Boolean isEditable() {
        String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1].Name;
        if(!System.label.TravelTimeEditableProfiles.split(',').contains(profileName)){
            return false;
        }
        return true;
    }

    private class TravelTimeBreakdownJSON {
        String weekday;
        Integer travelTime;
        Integer travelDistance;
        String startOfWindow;
        String siteId;
        String siteCollectionOperationIds;
        String endOfWindow;
        String direction;
    }

}