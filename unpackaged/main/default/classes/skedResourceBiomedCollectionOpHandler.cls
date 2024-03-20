public class skedResourceBiomedCollectionOpHandler extends skedTriggerHub {
	
    public override void onAfterInsert() {
        createResourceRegions(this.context.newRecords);
    }
    
    public override void onAfterUpdate() {
        updateResourceRegions(this.context.newRecords, (Map<Id, sked_Resource_Biomed_Collection_Op__c>)this.context.oldMap);
    }
    
    public override void onBeforeDelete() {
        deleteResourceRegions((Map<Id, sked_Resource_Biomed_Collection_Op__c>)this.context.oldMap);
    }

    /*********************************************************** Nested classes ***********************************************************/
    private void createResourceRegions(List<sked_Resource_Biomed_Collection_Op__c> newRecords) {
        Set<Id> biomedCollectionOpIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (sked_Resource_Biomed_Collection_Op__c newRecord : newRecords) {
            biomedCollectionOpIds.add(newRecord.sked_Biomed_Collection_Op_Center__c);
            resourceIds.add(newRecord.sked_Resource__c);
        }
        List<sked__Region__c> skedRegions = [SELECT Id, Name, sked_Biomed_Collection_Op_Center__c
                                             FROM sked__Region__c
                                             WHERE sked_Biomed_Collection_Op_Center__c IN :biomedCollectionOpIds];
        Map<Id, sked__Region__c> map_collectionOpId_regionId = new Map<Id, sked__Region__c>();
        for (sked__Region__c skedRegion : skedRegions) {
            map_collectionOpId_regionId.put(skedRegion.sked_Biomed_Collection_Op_Center__c, skedRegion);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, Name, sked__Primary_Region__r.sked__Timezone__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        
        List<sked__Resource_Region__c> skedResourceRegionsToInsert = new List<sked__Resource_Region__c>();
        for (sked_Resource_Biomed_Collection_Op__c newRecord : newRecords) {
            if (map_collectionOpId_regionId.containsKey(newRecord.sked_Biomed_Collection_Op_Center__c )) {
                sked__Region__c skedRegion = map_collectionOpId_regionId.get(newRecord.sked_Biomed_Collection_Op_Center__c);
                sked__Resource__c skedResource = mapResource.get(newRecord.sked_Resource__c);
                
                string timezoneSidId = UserInfo.getTimeZone().getID();
                if (skedResource.sked__Primary_Region__r != NULL && !string.isBlank(skedResource.sked__Primary_Region__r.sked__Timezone__c)) {
                    timezoneSidId = skedResource.sked__Primary_Region__r.sked__Timezone__c;
                }
                
                sked__Resource_Region__c skedResourceRegion = new sked__Resource_Region__c(
                    Name = skedResource.Name + ' - ' + skedRegion.Name,
                    sked__Resource__c = newRecord.sked_Resource__c,
                    sked__Region__c = skedRegion.Id,
                    sked__Start__c = skedDateTimeUtils.newDateTimeInstance(newRecord.sked_Start_Date__c, 0, timezoneSidId),
                    sked__End__c = skedDateTimeUtils.newDateTimeInstance(newRecord.sked_End_Date__c, 0, timezoneSidId),
                    sked_Resource_Biomed_Collection_Op__c = newRecord.Id
                );
                skedResourceRegionsToInsert.add(skedResourceRegion);
            }
        }
        if (!skedResourceRegionsToInsert.isEmpty()) {
            insert skedResourceRegionsToInsert;
        }
    }

    private void updateResourceRegions(List<sked_Resource_Biomed_Collection_Op__c> newRecords, Map<Id, sked_Resource_Biomed_Collection_Op__c> oldMap) {
		Set<Id> biomedCollectionOpIds = new Set<Id>();
        for (sked_Resource_Biomed_Collection_Op__c newRecord : newRecords) {
            sked_Resource_Biomed_Collection_Op__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Start_Date__c != oldData.sked_Start_Date__c || newRecord.sked_End_Date__c != oldData.sked_End_Date__c) {
                biomedCollectionOpIds.add(newRecord.Id);
            }
        }
        if (!biomedCollectionOpIds.isEmpty()) {
            List<sked__Resource_Region__c> skedResourceRegionsToUpdate = [SELECT Id, sked__Start__c, sked__End__c,
                                                                          sked_Resource_Biomed_Collection_Op__r.sked_Start_Date__c,
                                                                          sked_Resource_Biomed_Collection_Op__r.sked_End_Date__c,
                                                                          sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c
                                                                          FROM sked__Resource_Region__c
                                                                          WHERE sked_Resource_Biomed_Collection_Op__c IN :biomedCollectionOpIds];
            if (!skedResourceRegionsToUpdate.isEmpty()) {
                for (sked__Resource_Region__c skedResourceRegion : skedResourceRegionsToUpdate) {
                    string timezoneSidId = UserInfo.getTimeZone().getID();
                    if (skedResourceRegion.sked__Resource__r.sked__Primary_Region__r != NULL && !string.isBlank(skedResourceRegion.sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c)) {
                        timezoneSidId = skedResourceRegion.sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c;
                    }
                    
                    skedResourceRegion.sked__Start__c = skedDateTimeUtils.newDateTimeInstance(skedResourceRegion.sked_Resource_Biomed_Collection_Op__r.sked_Start_Date__c, 0, timezoneSidId);
                    skedResourceRegion.sked__End__c = skedDateTimeUtils.newDateTimeInstance(skedResourceRegion.sked_Resource_Biomed_Collection_Op__r.sked_End_Date__c, 0, timezoneSidId);
                }
                update skedResourceRegionsToUpdate;
            }
        }
    }
    
    private void deleteResourceRegions(Map<Id, sked_Resource_Biomed_Collection_Op__c> oldMap) {
        delete [SELECT Id FROM sked__Resource_Region__c WHERE sked_Resource_Biomed_Collection_Op__c IN :oldMap.keySet()];
    }
    
}