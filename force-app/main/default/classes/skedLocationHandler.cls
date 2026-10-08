public class skedLocationHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        updateAddress(this.context.newRecords);
    }
    
    public override void onAfterInsert() {
        populateIdentifier(this.context.newRecords);
        createPhysicalLocationTags(this.context.newRecords);
        generateSiteCollectionOperations(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            revertAccidientallyChangedGeolocation(this.context.newRecords, (Map<Id, sked__Location__c>)this.context.oldMap);
        }
        populateData(this.context.newRecords, (Map<Id, sked__Location__c>) this.context.oldMap);
        updateAddress(this.context.newRecords, (Map<Id, sked__Location__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        updatePhysicalLocationTags(this.context.newRecords, (Map<Id, sked__Location__c>) this.context.oldMap);
        generateSiteCollectionOperations(this.context.newRecords, (Map<Id, sked__Location__c>) this.context.oldMap);
        if (skedSetting.instance.Admin.exavaluIntegration) {
            deactivateSites(this.context.newRecords, (Map<Id, sked__Location__c>) this.context.oldMap);
        }
        onAddressChanged(this.context.newRecords, (Map<Id, sked__Location__c>) this.context.oldMap);
        onDoNotUseVehicleChanged(this.context.newRecords, (Map<Id, sked__Location__c>) this.context.oldMap);
    }

    /*********************************************************** Privated Methods ***********************************************************/
    private void createPhysicalLocationTags(List<sked__Location__c> newRecords) {
        List<sked__Location__c> recordsToPopulate = new List<sked__Location__c>();
        for (sked__Location__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_Physical_Location_Type__c)) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            List<sked_Location_Tag__c> newLocationTags = new List<sked_Location_Tag__c>();
            for (sked__Location__c newRecord : recordsToPopulate) {
                if (mapTag.containsKey(newRecord.sked_Physical_Location_Type__c)) {
                    sked__Tag__c skedTag = mapTag.get(newRecord.sked_Physical_Location_Type__c);
                    sked_Location_Tag__c newLocationTag = new sked_Location_Tag__c(
                        sked_Location__c = newRecord.Id,
                        sked_Tag__c = skedTag.Id,
                        sked_Required__c = TRUE,
                        sked_SystemCreated__c = TRUE
                    );
                    newLocationTags.add(newLocationTag);
                }
            }
            insert newLocationTags;
        }
    }
    
    private void deactivateSites(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        List<Id> inactivesiteIds = new List<Id>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Active__c != oldData.sked_Active__c && newRecord.sked_Active__c == FALSE) {
                inactivesiteIds.add(newRecord.Id);
            }
        }
        if (!inactivesiteIds.isEmpty()) {
            ArcSkeduloSiteUtility.inactiveTemplatesforSites(inactivesiteIds);
        }
    }
    
    private void generateSiteCollectionOperations(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        Map<String,Integer> zipCodeVsSCOCount = new Map<String,Integer>();
        Map<String,String> zipCodeOldVsNew = new Map<String,String>();
        Map<String,Map<Id,Boolean>> zipCodeVsSCOUpdateCheckMap = new Map<String,Map<Id,Boolean>>();
        Map<string, List<sked__Location__c>> map_zipcode_Sites = new Map<string, List<sked__Location__c>>();
        Map<Id, sked__Location__c> mapRecordToPopulate = new Map<Id, sked__Location__c>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Zip_Code__c != oldData.sked_Zip_Code__c) {
                zipCodeOldVsNew.put(oldData.sked_Zip_Code__c,newRecord.sked_Zip_Code__c);
                mapRecordToPopulate.put(newRecord.Id, newRecord);
                List<sked__Location__c> sites;
                if (map_zipcode_Sites.containsKey(newRecord.sked_Zip_Code__c)) {
                    sites = map_zipcode_Sites.get(newRecord.sked_Zip_Code__c);
                }
                else {
                    sites = new List<sked__Location__c>();
                    map_zipcode_Sites.put(newRecord.sked_Zip_Code__c, sites);
                }
                sites.add(newRecord);
            }
        }
        if (!mapRecordToPopulate.isEmpty()) {
            List<sked_Site_Collection_Operation__c> existingSCOs = [SELECT Id, sked_End_Date__c, sked_Collections_Zip_Code__c, sked_Collections_Zip_Code__r.Zip__c, sked_Start_Date__c, sked_Region__c, sked_Site__c, sked_Collection_Operation__c
                                                                    FROM sked_Site_Collection_Operation__c
                                                                    WHERE sked_Site__c IN :mapRecordToPopulate.keySet() AND sked_End_Date__c >= TODAY];
            if ((!existingSCOs.isEmpty()) && (!map_zipcode_Sites.isEmpty())) {
                Map<Id, List<sked_Site_Collection_Operation__c>> map_SiteId_existingSCO= new Map<Id, List<sked_Site_Collection_Operation__c>>();
                for(sked_Site_Collection_Operation__c sco : existingSCOs){
                    List<sked_Site_Collection_Operation__c> siteCollOpp;
                    if (map_SiteId_existingSCO.containsKey(sco.sked_Site__c)) {
                        siteCollOpp = map_SiteId_existingSCO.get(sco.sked_Site__c);
                    }
                    else {
                        siteCollOpp = new List<sked_Site_Collection_Operation__c>();
                        map_SiteId_existingSCO.put(sco.sked_Site__c, siteCollOpp);
                    }
                    siteCollOpp.add(sco);
                    if(zipCodeVsSCOUpdateCheckMap.get(zipCodeOldVsNew.get(sco.sked_Collections_Zip_Code__r.Zip__c)) != null){
                        Map<Id,Boolean> getExistingSCOFromMap = zipCodeVsSCOUpdateCheckMap.get(zipCodeOldVsNew.get(sco.sked_Collections_Zip_Code__r.Zip__c));
                        getExistingSCOFromMap.put(sco.Id,FALSE);
                        zipCodeVsSCOUpdateCheckMap.put(zipCodeOldVsNew.get(sco.sked_Collections_Zip_Code__r.Zip__c),getExistingSCOFromMap);
                    } else{
                        Map<Id,Boolean> getExistingSCOFromMap = new Map<Id,Boolean>{sco.Id => FALSE};
                        zipCodeVsSCOUpdateCheckMap.put(zipCodeOldVsNew.get(sco.sked_Collections_Zip_Code__r.Zip__c),getExistingSCOFromMap);
                    }
                }
                for(Id siteId : map_SiteId_existingSCO.keySet()){
                    zipCodeVsSCOCount.put((zipCodeOldVsNew.get(map_SiteId_existingSCO.get(siteId)[0].sked_Collections_Zip_Code__r.Zip__c)), map_SiteId_existingSCO.get(siteId).size());
                }
                updateSiteCollectionOperation(map_zipcode_Sites, map_SiteId_existingSCO, zipCodeVsSCOCount, newRecords, zipCodeVsSCOUpdateCheckMap);

            }
            if(existingSCOs.isEmpty()){
                generateSiteCollectionOperations(mapRecordToPopulate.values());
            }
            
        }
    }

    private void generateSiteCollectionOperations(List<sked__Location__c> newRecords) {
        Map<string, List<sked__Location__c>> map_zipcode_Sites = new Map<string, List<sked__Location__c>>();
        //HRP-12054
        Set<String> zipCodeSet = new Set<String>();
        Set<String> collOpCodeSet = new Set<String>();
        Map<Id,Collections_Territory__c> collZipIdMap = new Map<Id,Collections_Territory__c>();
        Map<Id,sked__Location__c> siteIdMap = new Map<Id,sked__Location__c>();
        //HRP-12054
        for (sked__Location__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_Zip_Code__c)) {
                zipCodeSet.add(newRecord.sked_Zip_Code__c);//HRP-12054
                List<sked__Location__c> sites;
                if (map_zipcode_Sites.containsKey(newRecord.sked_Zip_Code__c)) {
                    sites = map_zipcode_Sites.get(newRecord.sked_Zip_Code__c);
                }
                else {
                    sites = new List<sked__Location__c>();
                    map_zipcode_Sites.put(newRecord.sked_Zip_Code__c, sites);
                }
                sites.add(newRecord);
            }
            siteIdMap.put(newRecord.Id,newRecord);//HRP-12054
        }
        if (!map_zipcode_Sites.isEmpty()) {
            List<Collections_Territory__c> collectionZipCodes = [SELECT Id, Collection_Operation__c, sked_End_Date__c, sked_Start_Date__c, Zip__c,Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c
                                                                 FROM Collections_Territory__c
                                                                 WHERE Zip__c IN :map_zipcode_Sites.keySet()
                                                                 AND sked_End_Date__c >= :system.today()];
            if (!collectionZipCodes.isEmpty()) {
                Set<Id> collectionOperationIds = new Set<Id>();
                for (Collections_Territory__c collectionZipCode : collectionZipCodes) {
                    collectionOperationIds.add(collectionZipCode.Collection_Operation__c);
                    collOpCodeSet.add(collectionZipCode.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c);//HRP-12054
                    collZipIdMap.put(collectionZipCode.Id,collectionZipCode);//HRP-12054
                }
                //Map<String, sked__Region__c> mapCollOperToRegion = skedRegionService.getMapOfCollectionOperationToRegion(collectionOperationIds);//HRP-12054
                
                List<sked_Site_Collection_Operation__c> siteCollectionOperations = new List<sked_Site_Collection_Operation__c>();
                for (Collections_Territory__c collectionZipCode : collectionZipCodes) {
                    if (map_zipcode_Sites.containsKey(collectionZipCode.Zip__c)) {
                        List<sked__Location__c> sites = map_zipcode_Sites.get(collectionZipCode.Zip__c);
                        for (sked__Location__c site : sites) {
                            /*Id regionId = skedRegionService.getRegionForCollectionOperation(collectionZipCode.Collection_Operation__c, 
mapCollOperToRegion, site.sked_Timezone__c);*///HRP-12054
                            sked_Site_Collection_Operation__c siteCollectionOperation = new sked_Site_Collection_Operation__c(
                                sked_Collection_Operation__c = collectionZipCode.Collection_Operation__c,
                                sked_Site__c = site.Id,
                                sked_Collections_Zip_Code__c = collectionZipCode.Id,
                                sked_Start_Date__c = collectionZipCode.sked_Start_Date__c,
                                sked_End_Date__c = collectionZipCode.sked_End_Date__c,
                                External_Id_BackEnd__c='Bio_Collection_BSF_SiteCo_'+collectionZipCode.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+site.Id,//HRP-12054
                                External_Id__c='Bio_Collection_BSF_SiteCo_'+collectionZipCode.Collection_Operation__r.Biomed_Collection_Op_Code_Center_ID__c+'_'+site.Id+'_'+collectionZipCode.sked_Start_Date__c//HRP-12054
                            );
                            siteCollectionOperations.add(siteCollectionOperation);
                        }
                    }
                }
                Map<String,Id> CollZipRegionMap = BSF_Utilities.findSkedRegion(collOpCodeSet,zipCodeSet,new List<Taxonomy__c>(),siteCollectionOperations,collZipIdMap,siteIdMap);//HRP-12054
                if (!siteCollectionOperations.isEmpty()) {
                    insert siteCollectionOperations;
                }
            }
        }
    }
    
    private void updateSiteCollectionOperation(Map<string, List<sked__Location__c>> map_zipcode_Sites, Map<Id, List<sked_Site_Collection_Operation__c>> map_SiteId_existingSCO, Map<String,Integer> zipCodeVsSCOCount, List<sked__Location__c> newRecords, Map<String,Map<Id,Boolean>> zipCodeVsSCOUpdateCheckMap) {
        if (!map_zipcode_Sites.isEmpty()) {
            Map<String,Integer> ZipCodeVsCollZipCount = new Map<String,Integer>();
            List<Collections_Territory__c> collectionZipCodes = [SELECT Id, Collection_Operation__c, sked_End_Date__c, sked_Start_Date__c, Zip__c
                                                                 FROM Collections_Territory__c
                                                                 WHERE Zip__c IN :map_zipcode_Sites.keySet()
                                                                 AND sked_End_Date__c >= :system.today()];
            if (!collectionZipCodes.isEmpty()) {
                Set<Id> collectionOperationIds = new Set<Id>();
                for (Collections_Territory__c collectionZipCode : collectionZipCodes) {
                    collectionOperationIds.add(collectionZipCode.Collection_Operation__c);
                    if(ZipCodeVsCollZipCount.containsKey(collectionZipCode.Zip__c)){
                        integer i = ZipCodeVsCollZipCount.get(collectionZipCode.Zip__c) + 1;
                        ZipCodeVsCollZipCount.put(collectionZipCode.Zip__c,i);
                    } else {
                        ZipCodeVsCollZipCount.put(collectionZipCode.Zip__c,1);
                    }

                }
                if(Boolean.ValueOf(System.label.Block_ZipCode_Update_On_Site)){
                    for (sked__Location__c sites : newRecords) {
                        if (ZipCodeVsCollZipCount.get(sites.sked_Zip_Code__c) != null && zipCodeVsSCOCount.get(sites.sked_Zip_Code__c) != null && ZipCodeVsCollZipCount.get(sites.sked_Zip_Code__c) != zipCodeVsSCOCount.get(sites.sked_Zip_Code__c)) {
                            sites.addError('Zip code change not allow because collection operation before and after zip code change is different in future');
                        }
                    }
                }
                Map<String, sked__Region__c> mapCollOperToRegion = skedRegionService.getMapOfCollectionOperationToRegion(collectionOperationIds);
                
                List<sked_Site_Collection_Operation__c> siteCollectionOperations = new List<sked_Site_Collection_Operation__c>();
                for (Collections_Territory__c collectionZipCode : collectionZipCodes) {
                    if (map_zipcode_Sites.containsKey(collectionZipCode.Zip__c)) {
                        List<sked__Location__c> sites = map_zipcode_Sites.get(collectionZipCode.Zip__c);
                        for (sked__Location__c site : sites) {
                            Id regionId = skedRegionService.getRegionForCollectionOperation(collectionZipCode.Collection_Operation__c, 
                                                                                            mapCollOperToRegion, site.sked_Timezone__c);
                            if(map_SiteId_existingSCO.containsKey(site.Id)){
                                for(sked_Site_Collection_Operation__c siteCollectionOperation : map_SiteId_existingSCO.get(site.Id)){
                                    if((ZipCodeVsCollZipCount.get(collectionZipCode.Zip__c) != null && zipCodeVsSCOCount.get(collectionZipCode.Zip__c) != null && ZipCodeVsCollZipCount.get(collectionZipCode.Zip__c) == zipCodeVsSCOCount.get(collectionZipCode.Zip__c) && siteCollectionOperation.sked_Collection_Operation__c == collectionZipCode.Collection_Operation__c)
                                    && ((siteCollectionOperation.sked_Start_Date__c <= system.today() && system.today() <= siteCollectionOperation.sked_End_Date__c)
                                        || (siteCollectionOperation.sked_Start_Date__c >= system.today() && system.today() <= siteCollectionOperation.sked_End_Date__c))){
                                        if(ZipCodeVsCollZipCount.get(collectionZipCode.Zip__c) > 1){
                                            if(siteCollectionOperation.sked_Start_Date__c == collectionZipCode.sked_Start_Date__c && siteCollectionOperation.sked_End_Date__c == collectionZipCode.sked_End_Date__c){
                                                siteCollectionOperation.Id = siteCollectionOperation.Id;
                                                siteCollectionOperation.sked_Collections_Zip_Code__c = collectionZipCode.Id;
                                                siteCollectionOperation.sked_Start_Date__c = collectionZipCode.sked_Start_Date__c;
                                                siteCollectionOperation.sked_End_Date__c = collectionZipCode.sked_End_Date__c;
                                                siteCollectionOperation.sked_Region__c = regionId;
                                                siteCollectionOperations.add(siteCollectionOperation);
                                                Map<Id,Boolean> noError = zipCodeVsSCOUpdateCheckMap.get(collectionZipCode.Zip__c);
                                                noError.put(siteCollectionOperation.Id,TRUE);
                                                zipCodeVsSCOUpdateCheckMap.put(collectionZipCode.Zip__c,noError);
                                            }
                                        } else {
                                            siteCollectionOperation.Id = siteCollectionOperation.Id;
                                            siteCollectionOperation.sked_Collections_Zip_Code__c = collectionZipCode.Id;
                                            siteCollectionOperation.sked_Start_Date__c = collectionZipCode.sked_Start_Date__c;
                                            siteCollectionOperation.sked_End_Date__c = collectionZipCode.sked_End_Date__c;
                                            siteCollectionOperation.sked_Region__c = regionId;
                                            siteCollectionOperations.add(siteCollectionOperation);
                                            Map<Id,Boolean> noError = zipCodeVsSCOUpdateCheckMap.get(collectionZipCode.Zip__c);
                                            noError.put(siteCollectionOperation.Id,TRUE);
                                            zipCodeVsSCOUpdateCheckMap.put(collectionZipCode.Zip__c,noError);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                set<String> errorZipCode = new Set<String>();
                for(String ZipCode : zipCodeVsSCOUpdateCheckMap.keySet()){
                    for(Id sCOId : zipCodeVsSCOUpdateCheckMap.get(ZipCode).keySet()){
                        Map<Id,Boolean> checkingSCOIsUpdated = zipCodeVsSCOUpdateCheckMap.get(ZipCode); 
                        if(checkingSCOIsUpdated.get(sCOId) == FALSE){
                            errorZipCode.add(ZipCode);
                        }
                    }
                }
                if(Boolean.ValueOf(System.label.Block_ZipCode_Update_On_Site)){
                    for (sked__Location__c sites : newRecords) {
                        if (errorZipCode.contains(sites.sked_Zip_Code__c)) {
                            sites.addError('Zip code change not allow because after zip code change SCO collection operation will also change');
                        }
                    }
                }
                if (!siteCollectionOperations.isEmpty()) {
                    update siteCollectionOperations;
                }
            }
        }
    }
    
    private void onAddressChanged(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        Map<Id, sked__Location__c> mapSiteWithAddressChanged = new Map<Id, sked__Location__c>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldRecord = oldMap.get(newRecord.Id);
            if (newRecord.sked__Address__c != oldRecord.sked__Address__c 
                || newRecord.sked__GeoLocation__Latitude__s != oldRecord.sked__GeoLocation__Latitude__s
                || newRecord.sked__GeoLocation__Longitude__s != oldRecord.sked__GeoLocation__Longitude__s
               ) {
                   mapSiteWithAddressChanged.put(newRecord.Id, newRecord);
               }
        }
        if (!mapSiteWithAddressChanged.isEmpty()) {
            if (!Test.isRunningTest() && !System.isBatch()) {
                Database.executeBatch(new skedUpdateJobAddressBatch(mapSiteWithAddressChanged.keySet()));
            }
            createTravelTimeIndexItems(mapSiteWithAddressChanged.keySet());
            Database.executeBatch(new skedTTChangeDCROnAddressChangeBatch(mapSiteWithAddressChanged.keySet()));
        }
    }
    
    private void onDoNotUseVehicleChanged(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        Map<Id, Boolean> newValueBySiteId = getSitesWithChangedVehicleRequirement(newRecords, oldMap);
        // Site updates can originate from integration/migration batches, where executeBatch is not permitted
        if (!newValueBySiteId.isEmpty() && !Test.isRunningTest() && !System.isBatch()) {
            Database.executeBatch(new skedCreateDCRForVehicleReqChangeBatch(newValueBySiteId));
        }
    }

    @TestVisible
    private static Map<Id, Boolean> getSitesWithChangedVehicleRequirement(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        Map<Id, Boolean> newValueBySiteId = new Map<Id, Boolean>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldRecord = oldMap.get(newRecord.Id);
            if (newRecord.sked__Type__c == skedConstants.SITE_TYPE_MOBILE
                && newRecord.sked_Do_Not_Use_Vehicle__c != oldRecord.sked_Do_Not_Use_Vehicle__c) {
                newValueBySiteId.put(newRecord.Id, newRecord.sked_Do_Not_Use_Vehicle__c);
            }
        }
        return newValueBySiteId;
    }

    private void populateData(List<sked__Location__c> newRecords) {
        for (sked__Location__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_National_Name__c)) {
                newRecord.sked_National_Name__c = newRecord.sked_National_Name__c.toUpperCase();
            }
        }

        skedTriggerUtils.populateTimezoneFromTaxonomy(newRecords, 'sked_Zip_Code__c', 'sked_Timezone__c');
    }
    
    private void populateData(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_National_Name__c != oldData.sked_National_Name__c) {
                if (!string.isBlank(newRecord.sked_National_Name__c)) {
                    newRecord.sked_National_Name__c = newRecord.sked_National_Name__c.toUpperCase();
                }
            }
        }

        // Populate Site's Timezone
        List<sked__Location__c> recordsToPopulate = new List<sked__Location__c>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Zip_Code__c != oldData.sked_Zip_Code__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            skedTriggerUtils.populateTimezoneFromTaxonomy(recordsToPopulate, 'sked_Zip_Code__c', 'sked_Timezone__c');
        }
    }
    
    public void populateIdentifier(List<sked__Location__c> newRecords) {
        List<UFIDGenerator.UFIDInfo> ufidInfos = new List<UFIDGenerator.UFIDInfo>();
        for (sked__Location__c newRecord : newRecords) {
            UFIDGenerator.UFIDInfo ufidInfo = new UFIDGenerator.UFIDInfo();
            ufidInfo.prefix = 'L';
            ufidInfo.maxLength = 6;
            ufidInfo.value = integer.valueOf(newRecord.sked_UFID_AN__c);
            ufidInfo.recordId = newRecord.id;
            ufidInfo.fieldName = 'sked_UFID__c';
            ufidInfos.add(ufidInfo);
        }
        UFIDGenerator.genUFID(ufidInfos);
    }
    
    private void updateAddress(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        List<string> fieldsToCheck = new List<string>();
        fieldsToCheck.add('sked_Address_1__c');
        fieldsToCheck.add('sked_Address_2__c');
        fieldsToCheck.add('sked_City__c');
        fieldsToCheck.add('sked_State__c');
        fieldsToCheck.add('sked_Zip_Code__c');
        
        List<sked__Location__c> recordsToUpdate = new List<sked__Location__c>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldData = oldMap.get(newRecord.Id);
            for (string field : fieldsToCheck) {
                object oldValue = oldData.get(field);
                object newValue = newRecord.get(field);
                if (newValue != oldValue) {
                    recordsToUpdate.add(newRecord);
                    break;
                }
            }
        }
        if (!recordsToUpdate.isEmpty()) {
            updateAddress(recordsToUpdate);
            validateAfterAddressChanged(recordsToUpdate, oldMap);
        }
    }

    private void validateAfterAddressChanged(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        User loginUser = [
            SELECT Id, Name, Profile.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        List<string> systemAdminProfiles = new List<string>();
        systemAdminProfiles.add('Global Admin');
        systemAdminProfiles.add('System Administrator');
        boolean isAdmin = systemAdminProfiles.contains(loginUser.Profile.Name);

        List<sked__Location__c> siteAddressChangesToValidate = new List<sked__Location__c>();
        Set<String> zipCodes = new Set<String>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldRecord = oldMap.get(newRecord.Id);
            if (newRecord.sked__Address__c != oldRecord.sked__Address__c) {
                if (oldRecord.sked__Address__c != null && !isAdmin) {
                    newRecord.addError('Only System Admin and Global Admin can edit site address.');
                    break;
                }
                siteAddressChangesToValidate.add(newRecord);
                zipCodes.add(newRecord.sked_Zip_Code__c);
                zipCodes.add(oldRecord.sked_Zip_Code__c);
            }
        }

        if (!siteAddressChangesToValidate.isEmpty()) {
            List<Collections_Territory__c> cts = [
                SELECT Id, Zip__c, Collection_Operation__c
                FROM Collections_Territory__c
                WHERE sked_Start_Date__c <= TODAY
                AND sked_End_Date__c >= TODAY
                AND Zip__c IN :zipCodes
            ];

            Map<String, Collections_Territory__c> activeCTByZip = new Map<String, Collections_Territory__c>();
            for (Collections_Territory__c ct : cts) {
                activeCTByZip.put(ct.Zip__c, ct);
            }

            for (sked__Location__c updatedSite : siteAddressChangesToValidate) {
                sked__Location__c oldSite = oldMap.get(updatedSite.Id);
                Boolean newSiteAddressBelongsToSameCO = false;
                String newZip = updatedSite.sked_Zip_Code__c;
                String oldZip = oldSite.sked_Zip_Code__c;

                Collections_Territory__c activeCTForOldZip = activeCTByZip.get(oldZip);
                Collections_Territory__c activeCTForNewZip = activeCTByZip.get(newZip);

                if (activeCTForNewZip == null) {
                    updatedSite.addError('Unrecognized Zip Code');
                }

                if (activeCTForNewZip != null && activeCTForOldZip != null && activeCTForNewZip.Collection_Operation__c != activeCTForOldZip.Collection_Operation__c) {
                    updatedSite.addError('Unable to update site as the Zip Code does not belong to the same Collection Operation.');
                }
            }
        }
    }
    
    private void updateAddress(List<sked__Location__c> sites) {
        for (sked__Location__c site : sites) {
            site.sked__Address__c = skedUtils.combineAddress(site.sked_Address_1__c,
                                                             site.sked_Address_2__c,
                                                             NULL,
                                                             site.sked_City__c,
                                                             site.sked_State__c,
                                                             site.sked_Zip_Code__c,
                                                             NULL);
        }
    }
    
    private void updatePhysicalLocationTags(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        Set<Id> recordIdsToUpdate = new Set<Id>();
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Physical_Location_Type__c != oldData.sked_Physical_Location_Type__c) {
                recordIdsToUpdate.add(newRecord.Id);
            }
        }
        if (!recordIdsToUpdate.isEmpty()) {
            List<sked__Location__c> skedLocations = [
                SELECT Id, sked_Physical_Location_Type__c,
                    (SELECT Id, sked_Tag__r.Name, sked_Location__c, sked_Tag__c
                     FROM sked_Location_Tags__r
                     WHERE sked_Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE)
                FROM sked__Location__c
                WHERE Id IN :recordIdsToUpdate
            ];
            List<sked_Location_Tag__c> recordsToDelete = new List<sked_Location_Tag__c>();
            List<sked_Location_Tag__c> recordsToInsert = new List<sked_Location_Tag__c>();
            
            List<sked__Tag__c> skedTags = [SELECT Id, Name
                                           FROM sked__Tag__c
                                           WHERE sked__Type__c = :skedConstants.TAG_TYPE_PHYSICAL_LOCATION_TYPE];
            Map<string, sked__Tag__c> mapTag = new Map<string, sked__Tag__c>();
            for (sked__Tag__c skedTag : skedTags) {
                mapTag.put(skedTag.Name, skedTag);
            }
            
            for (sked__Location__c skedLocation : skedLocations) {
                if (skedLocation.sked_Physical_Location_Type__c == NULL) {
                    if (skedLocation.sked_Location_Tags__r != NULL) {
                        recordsToDelete.addAll(skedLocation.sked_Location_Tags__r);
                    }
                }
                else {
                    Set<string> requiredTagNames = new Set<string>();
                    requiredTagNames.add(skedLocation.sked_Physical_Location_Type__c);
                    
                    Set<string> existingTagNames = new Set<string>();
                    for (sked_Location_Tag__c locationTag : skedLocation.sked_Location_Tags__r) {
                        if (!requiredTagNames.contains(locationTag.sked_Tag__r.Name)) {
                            recordsToDelete.add(locationTag);
                        }
                        else {
                            existingTagNames.add(locationTag.sked_Tag__r.Name);
                        }
                    }
                    
                    for (string requiredTagName : requiredTagNames) {
                        if (!existingTagNames.contains(requiredTagName)) {
                            if (mapTag.containsKey(requiredTagName)) {
                                sked__Tag__c skedTag = mapTag.get(requiredTagName);
                                sked_Location_Tag__c newLocationTag = new sked_Location_Tag__c(
                                    sked_Location__c = skedLocation.Id,
                                    sked_Tag__c = skedTag.Id,
                                    sked_Required__c = TRUE,
                                    sked_SystemCreated__c = TRUE
                                );
                                recordsToInsert.add(newLocationTag);
                            }
                        }
                    }
                }
            }

            if (!recordsToInsert.isEmpty() && !recordsToDelete.isEmpty()) {
                skedHubBase.BypassInsertTriggers = true;
                insert recordsToInsert;
                skedHubBase.BypassInsertTriggers = false;
                
                if (!System.isBatch() && !Test.isRunningTest()) {
                    Database.executeBatch(new skedLocationTagInsertBatch(recordsToInsert, recordsToDelete), 1);
                }
                
                skedHubBase.BypassDeleteTriggers = true;
                delete recordsToDelete;
                skedHubBase.BypassDeleteTriggers = false;
            } 
            else if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            } 
            else if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        }
    }

    private static void createTravelTimeIndexItems(Set<Id> siteIds) {
        Map<Id, sked__Location__c> siteById = new Map<Id, sked__Location__c>([
            SELECT Id, sked__GeoLocation__c,
                (SELECT Id, sked_Start_Date__c, sked_End_Date__c, sked_Collection_Operation__c 
                 FROM sked_Site_Collection_Operations__r)
            FROM sked__Location__c
            WHERE Id IN :siteIds
        ]);

        List<skedCOSLUtils.CoslQueryModel> coslQueryModels = new List<skedCOSLUtils.CoslQueryModel>();
        for (Id siteId : siteById.keySet()) {
            sked__Location__c site = siteById.get(siteId);
            for (sked_Site_Collection_Operation__c sco : site.sked_Site_Collection_Operations__r) {
                coslQueryModels.add(new skedCOSLUtils.CoslQueryModel(
                    sco.sked_Collection_Operation__c,
                    sco.sked_Start_Date__c,
                    sco.sked_End_Date__c
                ));
            }
        }

        Map<Id, List<sked_Collection_Op_Staging_Location__c>> coslsByCoId = skedCOSLUtils.getCoslsByCoIds(coslQueryModels);
        List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem> ttiis = new List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem>();

        for (Id siteId : siteById.keySet()) {
            sked__Location__c site = siteById.get(siteId);

            for (sked_Site_Collection_Operation__c sco : site.sked_Site_Collection_Operations__r) {
                List<sked_Collection_Op_Staging_Location__c> cosls = coslsByCoId.get(sco.sked_Collection_Operation__c);

                if (cosls != null && !cosls.isEmpty()) {
                    for (sked_Collection_Op_Staging_Location__c cosl : cosls) {
                        if ((sco.sked_Start_Date__c == null || sco.sked_Start_Date__c <= cosl.sked_End_Date__c) || (sco.sked_End_Date__c == null || sco.sked_End_Date__c >= cosl.sked_Start_Date__c)) {
                            if (site.sked__GeoLocation__c != null && cosl.sked_Staging_Location__r.sked_Geolocation__c != null) {
                                ttiis.add(new skedTravelTimeIndexItemUtils.TravelTimeIndexItem(
                                    site.sked__GeoLocation__c, 
                                    cosl.sked_Staging_Location__r.sked_Geolocation__c,
                                    cosl.sked_Staging_Location__r.sked_Timezone__c,
                                    skedConstants.TTII_DIRECTION_SITE_TO_CO
                                ));
                            }
                        }
                    }
                }
            }
        }

        if (!ttiis.isEmpty()) {
            skedTravelTimeIndexItemUtils.createTravelTimeIndexItems(ttiis);
        }
    }
    
    private void revertAccidientallyChangedGeolocation(List<sked__Location__c> newRecords, Map<Id, sked__Location__c> oldMap) {
        for (sked__Location__c newRecord : newRecords) {
            sked__Location__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.revertAccidientallyChangedGeolocation(newRecord, oldData, 'sked__Address__c', 'sked__GeoLocation__Latitude__s', 'sked__GeoLocation__Longitude__s');
        }
    }
    
}