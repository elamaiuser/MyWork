public class skedSiteCollectionOperationHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
    }

    public override void onAfterInsert() {
        if (!skedSetting.instance.Admin.migrationMode) {
            updateSite(this.context.newRecords);
            createTravelTimeIndexItems(skedSObjectUtils.getRecordIds(this.context.newRecords));
        }
    }

    /******************************************** Private Methods ********************************************/
    private static void createTravelTimeIndexItems(Set<Id> scoIds) {
        List<sked_Site_Collection_Operation__c> scos = [
            SELECT Id, sked_Collection_Operation__c, sked_Site__c, sked_Start_Date__c, sked_End_Date__c
            FROM sked_Site_Collection_Operation__c
            WHERE Id IN :scoIds
        ];

        List<skedCOSLUtils.CoslQueryModel> coslQueryModels = new List<skedCOSLUtils.CoslQueryModel>();
        Set<Id> siteIds = new Set<Id>();
        for (sked_Site_Collection_Operation__c sco : scos) {
            siteIds.add(sco.sked_Site__c);
            coslQueryModels.add(new skedCOSLUtils.CoslQueryModel(
                sco.sked_Collection_Operation__c,
                sco.sked_Start_Date__c,
                sco.sked_End_Date__c     
            ));
        }

        Map<Id, sked__Location__c> siteById = new Map<Id, sked__Location__c>([
            SELECT Id, sked__GeoLocation__c
            FROM sked__Location__c
            WHERE Id IN :siteIds
        ]);

        Map<Id, List<sked_Collection_Op_Staging_Location__c>> coslsByCoId = skedCOSLUtils.getCoslsByCoIds(coslQueryModels);
        List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem> ttiis = new List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem>();

        for (sked_Site_Collection_Operation__c sco : scos) {
            sked__Location__c site = siteById.get(sco.sked_Site__c);
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

        if (!ttiis.isEmpty()) {
            skedTravelTimeIndexItemUtils.createTravelTimeIndexItems(ttiis);
        }
    }
    
    private void populateData(List<sked_Site_Collection_Operation__c> newRecords) {
        Set<Id> collectionOperationIds = new Set<Id>();
        Set<Id> siteIds = new Set<Id>();
        for (sked_Site_Collection_Operation__c newRecord : newRecords) {
            collectionOperationIds.add(newRecord.sked_Collection_Operation__c);
            siteIds.add(newRecord.sked_Site__c);
        }
        
        Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([
            SELECT Id, External_ID__c
            FROM Biomed_Collection_Op_Center__c
            WHERE Id IN :collectionOperationIds
            AND External_ID__c != NULL
        ]);
        Map<Id, sked__Location__c> mapSite = new Map<Id, sked__Location__c>([
            SELECT Id, sked_MigrationID__c
            FROM sked__Location__c
            WHERE Id IN :siteIds
            AND sked_MigrationID__c != NULL
        ]);
        for (sked_Site_Collection_Operation__c newRecord : newRecords) {
            Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(newRecord.sked_Collection_Operation__c);
            sked__Location__c site = mapSite.get(newRecord.sked_Site__c);
            
            if (collectionOperation != NULL && site != NULL) {
                newRecord.sked_UniqueKey__c = collectionOperation.External_ID__c + ':' + site.sked_MigrationID__c;
            }
        }
    }
	
	private void updateSite(List<sked_Site_Collection_Operation__c> scoList){
		Map<Id, sked_Site_Collection_Operation__c> sitesById = new Map<Id, sked_Site_Collection_Operation__c>();
		date today = System.today();
        Set<Id> regionIds = new Set<Id>();
		for(sked_Site_Collection_Operation__c scoObj : scoList){
            if(scoObj.sked_Start_Date__c <= today && scoObj.sked_End_Date__c >= today){
                sitesById.put(scoObj.sked_Site__c, scoObj);
                regionIds.add(scoObj.sked_Region__c);
			}
		}
        
        Map<Id, sked__Region__c> regionsById = new Map<Id, sked__Region__c>([
            SELECT Id, sked__Timezone__c
            FROM sked__Region__c
            WHERE Id IN :regionIds
        ]);
		
		List<sked__Location__c> sites = [
            SELECT id, sked_Collection_Operation__c, sked__Region__c, sked__Region__r.sked__Timezone__c, sked_Site_Main_Phone__c
            FROM sked__Location__c
            WHERE id IN: sitesById.keySet()
        ];
		
        List<sked__Location__c> sitesToUpdate = new List<sked__Location__c>();
		for(sked__Location__c loc : sites){
			if(sitesById.containsKey(loc.id)){
                sked_Site_Collection_Operation__c sco = sitesById.get(loc.id);

				if(sco.sked_Collection_Operation__c != null){
					loc.sked_Collection_Operation__c = sco.sked_Collection_Operation__c;
				}

				if(sco.sked_Region__c != null){
                    sked__Region__c updatedRegion = regionsById.get(sco.sked_Region__c);
					loc.sked__Region__c = updatedRegion.Id;
                    loc.sked_Timezone__c = updatedRegion.sked__Timezone__c;
				}

				sitesToUpdate.add(loc);
			}
		}

		if(sitesToUpdate.size() > 0){
			update sitesToUpdate;
		}
	}
}