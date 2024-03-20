global class skedCollectionsZipCodeBatch implements System.Schedulable, Database.Batchable<sObject>, Database.Stateful {

    private static final String KEY_DELIMITER = ':';
    private static final String DEFAULT_KEYWORD = 'default';
    
    protected Set<Id> newSiteCollectionOperationIds;
    protected Set<Id> upsertedSiteCollectionOperationIds;
    
    protected string lastId = '';
  
    public skedCollectionsZipCodeBatch() { 
        this.lastId = '';
        this.newSiteCollectionOperationIds = new Set<Id>();
        this.upsertedSiteCollectionOperationIds = new Set<Id>();
    }
    
    public skedCollectionsZipCodeBatch(string lastId) { 
        this.lastId = lastId;
        this.newSiteCollectionOperationIds = new Set<Id>();
        this.upsertedSiteCollectionOperationIds = new Set<Id>();
    }
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedCollectionsZipCodeBatch(''), 1);
    }

    global List<Taxonomy__c> start(Database.BatchableContext BC) {
        //TODO: need to add filters, need to email somebody to clarify
        sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        
        return [SELECT Id, Collection_Operation_Name__c, End_Date__c, Start_Date__c, Zip_Code__c
                FROM Taxonomy__c
                WHERE RecordType.Name = 'Bio Collection BSF'
                AND Id > :this.lastId
                AND LastModifiedDate > :setting.sked_Admin_Last_Collections_Zip_Run__c
                ORDER BY Id ASC
                LIMIT 50000];
    }

    global void execute(Database.BatchableContext BC, List<Taxonomy__c> taxonomyRecords) {
        List<Collections_Territory__c> collectionsTerritories = generateCollectionsTerritories(taxonomyRecords);
        skedSiteCollectionOperationContainer result = generateSiteCOs(collectionsTerritories);
        
        if (result.insertedRecords != null && !result.insertedRecords.isEmpty()) {
            for (sked_Site_Collection_Operation__c insertedRecord : result.insertedRecords) {
                this.newSiteCollectionOperationIds.add(insertedRecord.Id);
            }
        }

        if (result.upsertedRecords != null && !result.upsertedRecords.isEmpty()) {
            for (sked_Site_Collection_Operation__c upsertedRecord : result.upsertedRecords) {
                this.upsertedSiteCollectionOperationIds.add(upsertedRecord.Id);
            }
        }
        
        this.lastId = taxonomyRecords.get(taxonomyRecords.size() - 1).Id;
    }
    
    global void finish(Database.BatchableContext BC) {
        sked_Admin_Setting__c setting = sked_Admin_Setting__c.getOrgDefaults();
        List<Taxonomy__c> remainRecordQuery = [
            SELECT Id, Collection_Operation_Name__c, End_Date__c, Start_Date__c, Zip_Code__c
            FROM Taxonomy__c
            WHERE RecordType.Name = 'Bio Collection BSF'
            AND Id > :this.lastId
            AND LastModifiedDate > :setting.sked_Admin_Last_Collections_Zip_Run__c
            ORDER BY Id ASC
            LIMIT 1
        ];
    
        if (remainRecordQuery.isEmpty()) {
            setting.sked_Admin_Last_Collections_Zip_Run__c = system.now();
            update setting;
            
            if (!Test.isRunningTest()) {
                Database.executeBatch(new skedDriveCOChangedBatch(this.upsertedSiteCollectionOperationIds), 200);
            }
        }
        else {
            if (!Test.isRunningTest()) {
                Database.executeBatch(new skedCollectionsZipCodeBatch(this.lastId), 200);
            }
        }
    }
    
    private static Map<String, Biomed_Collection_Op_Center__c> getCollectionOpsByName(Set<String> collectionOpNames) {
        List<Biomed_Collection_Op_Center__c> collectionOperations = [
            SELECT Id, Name
            FROM Biomed_Collection_Op_Center__c
            WHERE Name IN :collectionOpNames
            AND External_ID__c != NULL
        ];

        Map<String, Biomed_Collection_Op_Center__c> mapCollectionOperation = new Map<String, Biomed_Collection_Op_Center__c>();
        for (Biomed_Collection_Op_Center__c collectionOperation : collectionOperations) {
            mapCollectionOperation.put(collectionOperation.Name, collectionOperation);
        }

        return mapCollectionOperation;
    }
    
    public static List<Collections_Territory__c> generateCollectionsTerritories(List<Taxonomy__c> taxonomyRecords) {
        Set<String> collectionOpNames = new Set<String>();
        Set<string> zipcodes = new Set<string>();

        for (Taxonomy__c taxonomy : taxonomyRecords) {
            collectionOpNames.add(taxonomy.Collection_Operation_Name__c);
            zipCodes.add(taxonomy.Zip_Code__c);
        }

        Map<String, Biomed_Collection_Op_Center__c> collectionOperationByName = getCollectionOpsByName(collectionOpNames);
        
        List<Collections_Territory__c> newCollectionTerritories = new List<Collections_Territory__c>();
        for (Taxonomy__c taxonomy : taxonomyRecords) {
            if (collectionOperationByName.containsKey(taxonomy.Collection_Operation_Name__c)) {
                Biomed_Collection_Op_Center__c collectionOperation = collectionOperationByName.get(taxonomy.Collection_Operation_Name__c);
                
                Collections_Territory__c newCollectionsTerritory = new Collections_Territory__c(
                    Collection_Operation__c = collectionOperation.Id,
                    Zip__c = taxonomy.Zip_Code__c,
                    sked_Start_Date__c = taxonomy.Start_Date__c,
                    sked_End_Date__c = taxonomy.End_Date__c
                );
                newCollectionTerritories.add(newCollectionsTerritory);
            }
        }
        
        List<Collections_Territory__c> existingCollectionsTerritories = [
            SELECT Id, Zip__c, sked_End_Date__c, sked_Start_Date__c, Collection_Operation__c, CreatedDate
            FROM Collections_Territory__c
            WHERE Zip__c IN :zipCodes
            AND sked_Start_Date__c != NULL
            AND sked_End_Date__c != NULL
            ORDER BY sked_Start_Date__c ASC
        ];
        
        List<Collections_Territory__c> allCollectionsTerritories = new List<Collections_Territory__c>();
        if (!newCollectionTerritories.isEmpty()) {
            allCollectionsTerritories.addAll(newCollectionTerritories);
        }
        if (!existingCollectionsTerritories.isEmpty()) {
            allCollectionsTerritories.addAll(existingCollectionsTerritories);
        }
        
        Map<String, List<collectionTerritoryWrapper>> map_Zip_CTWrapper = new Map<String, List<collectionTerritoryWrapper>>();
        for (Collections_Territory__c collectionTerritory : allCollectionsTerritories) {
            collectionTerritoryWrapper wrapper = new collectionTerritoryWrapper();
            wrapper.record = collectionTerritory;

            List<collectionTerritoryWrapper> wrapperList = map_Zip_CTWrapper.get(collectionTerritory.Zip__c);
            if (wrapperList == NULL) {
                wrapperList = new List<collectionTerritoryWrapper>();
            }

            wrapperList.add(wrapper);
            map_Zip_CTWrapper.put(collectionTerritory.Zip__c, wrapperList);
        }
        
        for (string zip : map_Zip_CTWrapper.keySet()) {
            List<collectionTerritoryWrapper> wrapperList = map_Zip_CTWrapper.get(zip);
            wrapperList.sort();
            for (integer i = 0; i < wrapperList.size(); i++) {
                collectionTerritoryWrapper wrapper = wrapperList.get(i);
            }
            for (integer i = 0; i < wrapperList.size(); i++) {
                collectionTerritoryWrapper wrapper = wrapperList.get(i);
                if (wrapper.isDelete == TRUE) {
                    continue;
                }
                
                for (integer j = i + 1; j < wrapperList.size(); j++) {
                    collectionTerritoryWrapper nextWrapper = wrapperList.get(j);
                    if (wrapper.record.sked_End_Date__c < nextWrapper.record.sked_Start_Date__c) {
                        integer daysBetween = wrapper.record.sked_End_Date__c.daysBetween(nextWrapper.record.sked_Start_Date__c);
                        if (daysBetween == 1 && wrapper.record.Collection_Operation__c == nextWrapper.record.Collection_Operation__c) {
                            wrapper.record.sked_End_Date__c = nextWrapper.record.sked_End_Date__c;
                            nextWrapper.isDelete = TRUE;
                        }
                    }
                    else {
                        if (wrapper.record.Collection_Operation__c == nextWrapper.record.Collection_Operation__c) {
                            if (wrapper.record.sked_End_Date__c < nextWrapper.record.sked_End_Date__c) {
                                wrapper.record.sked_End_Date__c = nextWrapper.record.sked_End_Date__c;
                            }
                            nextWrapper.isDelete = TRUE;
                        }
                        else {
                            if (wrapper.record.sked_End_Date__c <= nextWrapper.record.sked_End_Date__c) {
                                if (wrapper.record.sked_Start_Date__c < nextWrapper.record.sked_Start_Date__c) {
                                    wrapper.record.sked_End_Date__c = nextWrapper.record.sked_Start_Date__c.addDays(-1);
                                }
                                else {
                                    wrapper.isDelete = TRUE;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        List<Collections_Territory__c> collectionsTerritoriesToUpsert = new List<Collections_Territory__c>();
        List<Collections_Territory__c> collectionsTerritoriesToDelete = new List<Collections_Territory__c>();
        
        for (string zip : map_Zip_CTWrapper.keySet()) {
            List<collectionTerritoryWrapper> wrapperList = map_Zip_CTWrapper.get(zip);
         	for (collectionTerritoryWrapper wrapper : wrapperList) {
                if (wrapper.isDelete == TRUE) {
                    if (wrapper.record.Id != NULL) {
                        collectionsTerritoriesToDelete.add(wrapper.record);
                    }
                }
                else {
                    collectionsTerritoriesToUpsert.add(wrapper.record);
                }
            }   
        }
        
        if (!collectionsTerritoriesToDelete.isEmpty()) {
            delete collectionsTerritoriesToDelete;
        }
        
        if (!collectionsTerritoriesToUpsert.isEmpty()) {
            upsert collectionsTerritoriesToUpsert;
        }

        return collectionsTerritoriesToUpsert;
    }
    
    public static skedSiteCollectionOperationContainer generateSiteCOs(List<Collections_Territory__c> collectionTerritories) {
        Set<string> zipCodes = new Set<string>();
        Set<Id> collectionOpIds = new Set<Id>();
        for (Collections_Territory__c collectionsTerritory : collectionTerritories) {
            zipCodes.add(collectionsTerritory.Zip__c);
            collectionOpIds.add(collectionsTerritory.Collection_Operation__c);
        }

        Map<String, sked__Region__c> mapCollOperToRegion = skedRegionService.getMapOfCollectionOperationToRegion(collectionOpIds);

        List<sked__Location__c> skedSites = [
            SELECT Id, sked_Zip_Code__c, sked_Timezone__c
            FROM sked__Location__c
            WHERE sked_Zip_code__c IN :zipCodes
        ];

        Map<String, List<sked__Location__c>> map_Zip_Sites = new Map<String, List<sked__Location__c>>();
        Set<Id> siteIds = new Set<Id>();
        for (sked__Location__c site : skedSites) {
            siteIds.add(site.Id);
            
            List<sked__Location__c> sites = map_Zip_Sites.get(site.sked_Zip_Code__c);
            if (sites == NULL) {
                sites = new List<sked__Location__c>();
                map_Zip_Sites.put(site.sked_Zip_Code__c, sites);
            }
            sites.add(site);
        }
        
        List<sked_Site_Collection_Operation__c> newSiteCOs = new List<sked_Site_Collection_Operation__c>();
        for (Collections_Territory__c ct : collectionTerritories) {
            if (map_Zip_Sites.containsKey(ct.Zip__c)) {
                List<sked__Location__c> sites = map_Zip_Sites.get(ct.Zip__c);
                for (sked__Location__c site : sites) {
                    sked_Site_Collection_Operation__c newSiteCO = new sked_Site_Collection_Operation__c(
                        sked_Collection_Operation__c = ct.Collection_Operation__c,
                        sked_Site__c = site.Id,
                        sked_Collections_Zip_Code__c = ct.Id,
                        sked_Start_Date__c = ct.sked_Start_Date__c,
                        sked_End_Date__c = ct.sked_End_Date__c,
                        sked_Region__c = skedRegionService.getRegionForCollectionOperation(ct.Collection_Operation__c, mapCollOperToRegion, site.sked_Timezone__c)
                    );
                    newSiteCOs.add(newSiteCO);
                }
            }
        }
        
        List<sked_Site_Collection_Operation__c> existingSiteCOs = [
            SELECT Id, sked_Site__c, sked_End_Date__c, sked_Start_Date__c, sked_Collection_Operation__c, CreatedDate,
            sked_Travel_Time_Breakdown_JSON__c, sked_Travel_Time_Breakdown_JSON_2__c,
            sked_Travel_Distance_1__c, sked_Travel_Distance_2__c
            FROM sked_Site_Collection_Operation__c
            WHERE sked_Site__c IN :siteIds
            AND sked_Start_Date__c != NULL
            AND sked_End_Date__c != NULL
            ORDER BY sked_Start_Date__c ASC
        ];
        
        List<sked_Site_Collection_Operation__c> allSiteCOs = new List<sked_Site_Collection_Operation__c>();
        if (!newSiteCOs.isEmpty()) {
            allSiteCOs.addAll(newSiteCOs);
        }
        if (!existingSiteCOs.isEmpty()) {
            allSiteCOs.addAll(existingSiteCOs);
        }
        
        Map<String, List<siteCOWrapper>> map_SiteId_SiteCOWrapper = new Map<String, List<siteCOWrapper>>();
        for (sked_Site_Collection_Operation__c siteCO : allSiteCOs) {
            siteCOWrapper wrapper = new siteCOWrapper();
            wrapper.record = siteCO;

            List<siteCOWrapper> wrapperList = map_SiteId_SiteCOWrapper.get(siteCO.sked_Site__c);
            if (wrapperList == NULL) {
                wrapperList = new List<siteCOWrapper>();
            }

            wrapperList.add(wrapper);
            map_SiteId_SiteCOWrapper.put(siteCO.sked_Site__c, wrapperList);
        }
        
        for (string zip : map_SiteId_SiteCOWrapper.keySet()) {
            List<siteCOWrapper> wrapperList = map_SiteId_SiteCOWrapper.get(zip);
            wrapperList.sort();
            for (integer i = 0; i < wrapperList.size(); i++) {
                siteCOWrapper wrapper = wrapperList.get(i);
            }
            for (integer i = 0; i < wrapperList.size(); i++) {
                siteCOWrapper wrapper = wrapperList.get(i);
                if (wrapper.isDelete == TRUE) {
                    continue;
                }
                
                for (integer j = i + 1; j < wrapperList.size(); j++) {
                    siteCOWrapper nextWrapper = wrapperList.get(j);
                    if (nextWrapper.isDelete == TRUE) {
                        continue;
                    }
                    if (wrapper.record.sked_End_Date__c < nextWrapper.record.sked_Start_Date__c) {
                        integer daysBetween = wrapper.record.sked_End_Date__c.daysBetween(nextWrapper.record.sked_Start_Date__c);
                        if (daysBetween == 1 && wrapper.record.sked_Collection_Operation__c == nextWrapper.record.sked_Collection_Operation__c) {
                            wrapper.record.sked_End_Date__c = nextWrapper.record.sked_End_Date__c;
                            nextWrapper.isDelete = TRUE;
                            copyTravelTimeData(nextWrapper, wrapper);
                        }
                    }
                    else {
                        if (wrapper.record.sked_Collection_Operation__c == nextWrapper.record.sked_Collection_Operation__c) {
                            if (wrapper.record.sked_End_Date__c < nextWrapper.record.sked_End_Date__c) {
                                wrapper.record.sked_End_Date__c = nextWrapper.record.sked_End_Date__c;
                            }
                            nextWrapper.isDelete = TRUE;
                            copyTravelTimeData(nextWrapper, wrapper);
                        }
                        else {
                            if (wrapper.record.sked_End_Date__c <= nextWrapper.record.sked_End_Date__c) {
                                if (wrapper.record.sked_Start_Date__c < nextWrapper.record.sked_Start_Date__c) {
                                    wrapper.record.sked_End_Date__c = nextWrapper.record.sked_Start_Date__c.addDays(-1);
                                }
                                else {
                                    wrapper.isDelete = TRUE;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        List<sked_Site_Collection_Operation__c> siteCOsToUpsert = new List<sked_Site_Collection_Operation__c>();
        List<sked_Site_Collection_Operation__c> siteCOsToDelete = new List<sked_Site_Collection_Operation__c>();
        List<sked_Site_Collection_Operation__c> siteCOsToInsert = new List<sked_Site_Collection_Operation__c>();
        
        for (string siteId : map_SiteId_SiteCOWrapper.keySet()) {
            List<siteCOWrapper> wrapperList = map_SiteId_SiteCOWrapper.get(siteId);
         	for (siteCOWrapper wrapper : wrapperList) {
                if (wrapper.isDelete == TRUE) {
                    if (wrapper.record.Id != NULL) {
                        wrapper.record.sked_Post_Migration_Processed__c = TRUE;
                        siteCOsToDelete.add(wrapper.record);
                    }
                }
                else {
                    siteCOsToUpsert.add(wrapper.record);
                    if (wrapper.record.Id == NULL) {
                        siteCOsToInsert.add(wrapper.record);
                    }
                }
            }   
        }
        
        if (!siteCOsToDelete.isEmpty()) {
            delete siteCOsToDelete;
        }
        
        if (!siteCOsToUpsert.isEmpty()) {
            upsert siteCOsToUpsert;
        }

        skedSiteCollectionOperationContainer returnContainer = new skedSiteCollectionOperationContainer();
        returnContainer.insertedRecords = siteCOsToInsert;
        returnContainer.upsertedRecords = siteCOsToUpsert;
        return returnContainer;
    }
    
    private static void copyTravelTimeData(siteCOWrapper sourceWrapper, siteCOWrapper targetWrapper) {
        integer travelTimeDataCount = 0;
        if (sourceWrapper.record.sked_Travel_Time_Breakdown_JSON__c != NULL) {
            targetWrapper.record.sked_Travel_Time_Breakdown_JSON__c = sourceWrapper.record.sked_Travel_Time_Breakdown_JSON__c;
            travelTimeDataCount++;
        }
        if (sourceWrapper.record.sked_Travel_Time_Breakdown_JSON_2__c != NULL) {
            targetWrapper.record.sked_Travel_Time_Breakdown_JSON_2__c = sourceWrapper.record.sked_Travel_Time_Breakdown_JSON_2__c;
            travelTimeDataCount++;
        }
        if (sourceWrapper.record.sked_Travel_Distance_1__c != NULL) {
            targetWrapper.record.sked_Travel_Distance_1__c = sourceWrapper.record.sked_Travel_Distance_1__c;
            travelTimeDataCount++;
        }
        if (sourceWrapper.record.sked_Travel_Distance_2__c != NULL) {
            targetWrapper.record.sked_Travel_Distance_2__c = sourceWrapper.record.sked_Travel_Distance_2__c;
            travelTimeDataCount++;
        }
        if (travelTimeDataCount == 4) {
            targetWrapper.record.sked_Post_Migration_Processed__c = TRUE;
        }
    }
    
    /* Nested classes */
    
    public class collectionTerritoryWrapper implements Comparable {
        public Collections_Territory__c record;
        public boolean isDelete;
        
        public virtual Integer compareTo(Object compareTo) {
            collectionTerritoryWrapper compareToRecord = (collectionTerritoryWrapper)compareTo;
            Integer returnValue = 0;
            
            if (this.record.sked_Start_Date__c > compareToRecord.record.sked_Start_Date__c) {
                returnValue = 1;
            }
            else if (this.record.sked_Start_Date__c < compareToRecord.record.sked_Start_Date__c) {
                returnValue = -1;
            }
            if (returnValue == 0) {
                if (this.record.sked_End_Date__c < compareToRecord.record.sked_End_Date__c) {
                    returnValue = 1;
                }
                else if (this.record.sked_End_Date__c > compareToRecord.record.sked_End_Date__c) {
                    returnValue = -1;
                }
            }
            if (returnValue == 0) {
                if (this.record.Id == NULL && compareToRecord.record.Id != NULL) {
                    returnValue = 1;
                }
                else if (this.record.Id != NULL && compareToRecord.record.Id == NULL) {
                    returnValue = -1;
                }
            }
            if (returnValue == 0) {
                if (this.record.Id != NULL && compareToRecord.record.Id != NULL) {
                    if (this.record.CreatedDate > compareToRecord.record.CreatedDate) {
                        returnValue = 1;
                    }
                    else if (this.record.CreatedDate < compareToRecord.record.CreatedDate) {
                        returnValue = -1;
                    }
                }
            }
            
            return returnValue;
        }
    }
    
    public class siteCOWrapper implements Comparable {
        public sked_Site_Collection_Operation__c record;
        public boolean isDelete;
        
        public virtual Integer compareTo(Object compareTo) {
            siteCOWrapper compareToRecord = (siteCOWrapper)compareTo;
            Integer returnValue = 0;
            
            if (this.record.sked_Start_Date__c > compareToRecord.record.sked_Start_Date__c) {
                returnValue = 1;
            }
            else if (this.record.sked_Start_Date__c < compareToRecord.record.sked_Start_Date__c) {
                returnValue = -1;
            }
            if (returnValue == 0) {
                if (this.record.sked_End_Date__c < compareToRecord.record.sked_End_Date__c) {
                    returnValue = 1;
                }
                else if (this.record.sked_End_Date__c > compareToRecord.record.sked_End_Date__c) {
                    returnValue = -1;
                }
            }
            if (returnValue == 0) {
                if (this.record.Id == NULL && compareToRecord.record.Id != NULL) {
                    returnValue = 1;
                }
                else if (this.record.Id != NULL && compareToRecord.record.Id == NULL) {
                    returnValue = -1;
                }
            }
            if (returnValue == 0) {
                if (this.record.Id != NULL && compareToRecord.record.Id != NULL) {
                    if (this.record.CreatedDate > compareToRecord.record.CreatedDate) {
                        returnValue = 1;
                    }
                    else if (this.record.CreatedDate < compareToRecord.record.CreatedDate) {
                        returnValue = -1;
                    }
                }
            }
            
            return returnValue;
        }
    }
    
    public class skedSiteCollectionOperationContainer {
        List<sked_Site_Collection_Operation__c> insertedRecords;
        List<sked_Site_Collection_Operation__c> upsertedRecords;

        public skedSiteCollectionOperationContainer() {}
    }

}