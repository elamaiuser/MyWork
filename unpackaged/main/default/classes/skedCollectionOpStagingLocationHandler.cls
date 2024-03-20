public class skedCollectionOpStagingLocationHandler extends skedTriggerHub implements callable {
    
    public override void onBeforeInsert() {
        populateData((List<sked_Collection_Op_Staging_Location__c>) this.context.newRecords);
    }

    public override void onAfterInsert() {
        if (!System.isBatch()) {
            initiateStagingLocationBatch((List<sked_Collection_Op_Staging_Location__c>) this.context.newRecords);
        }

        skedFutureCallEventHandler.publishFutureCallEvent(
            skedCollectionOpStagingLocationHandler.class.getName(),
            'createTravelTimeIndexItems',
            skedSObjectUtils.getRecordIds(this.context.newRecords)   
        );
    }
    
    public override void onBeforeUpdate() {
        populateData((List<sked_Collection_Op_Staging_Location__c>) this.context.newRecords, (Map<Id, sked_Collection_Op_Staging_Location__c>) this.context.oldMap);
    }

    public override void onAfterUpdate() {
        if (!System.isBatch()) {
            initiateStagingLocationBatch((List<sked_Collection_Op_Staging_Location__c>) this.context.newRecords, (Map<Id, sked_Collection_Op_Staging_Location__c>) this.context.oldMap);
        }
    }

    public override void onBeforeDelete() {
        validateDeletion(this.context.oldRecords);
    }

    public override void onAfterDelete() {
        Set<Id> affectedCoIds = new Set<Id>();
        for (sked_Collection_Op_Staging_Location__c coSl : (List<sked_Collection_Op_Staging_Location__c>) this.context.oldRecords) {
            affectedCoIds.add(coSl.sked_Collection_Operation__c);
        }

        if (!affectedCoIds.isEmpty() && !System.isBatch()) {
            List<Id> coIdsList = new List<Id>();
            coIdsList.addAll(affectedCoIds);
            Database.executeBatch(new skedMergeCollectionOpStagingLocsBatch(coIdsList));
        }
    }

    /******************************************** Callable Interface ********************************************/
    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'createTravelTimeIndexItems' {
                    createTravelTimeIndexItems((Set<Id>) JSON.deserialize((String) params.get('param1'), Set<Id>.class));

                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedAvailabilityHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    /******************************************** Private Methods ********************************************/
    private void initiateStagingLocationBatch(List<sked_Collection_Op_Staging_Location__c> cosls) {
        List<skedCoSlWrapper> coslWrappers = new List<skedCoSlWrapper>();
        for (sked_Collection_Op_Staging_Location__c cosl : cosls) {
            coslWrappers.add(new skedCoSlWrapper(cosl));
        }
        Database.executeBatch(new skedCollectionOpStagingLocBatch(coslWrappers));
    }

    private void initiateStagingLocationBatch(List<sked_Collection_Op_Staging_Location__c> cosls, Map<Id, sked_Collection_Op_Staging_Location__c> oldCoslsById) {
        List<skedCoSlWrapper> coslWrappers = new List<skedCoSlWrapper>();
        for (sked_Collection_Op_Staging_Location__c cosl : cosls) {
            sked_Collection_Op_Staging_Location__c oldCoSl = oldCoslsById.get(cosl.Id);
            coslWrappers.add(new skedCoSlWrapper(oldCoSl, cosl));
        }
        Database.executeBatch(new skedCollectionOpStagingLocBatch(coslWrappers));
    }

    private void validateDeletion(List<sked_Collection_Op_Staging_Location__c> deletedRecords) {
        Map<Id, List<sked_Collection_Op_Staging_Location__c>> existingCoSlByCo = getExistingCoSlsByCoId(deletedRecords);
        for (sked_Collection_Op_Staging_Location__c coSl : deletedRecords) {
            List<sked_Collection_Op_Staging_Location__c> coSlsForCo = existingCoSlByCo.get(coSl.sked_Collection_Operation__c);
            if (coSlsForCo.size() == 1) {
                coSl.addError('Unable to Delete last remaining Collection Operation Staging Location');
            }
        }
    }

    private void populateData(List<sked_Collection_Op_Staging_Location__c> newRecords) {
        Map<Id, List<sked_Collection_Op_Staging_Location__c>> existingCoSlByCo = getExistingCoSlsByCoId(newRecords);
        for (sked_Collection_Op_Staging_Location__c coSl : newRecords) {
            List<sked_Collection_Op_Staging_Location__c> existingCoSlsForCo = existingCoSlByCo.get(coSl.sked_Collection_Operation__c);

            if (existingCoSlsForCo == null || existingCoSlsForCo.isEmpty()) {
                coSl.sked_Start_Date__c = skedConstants.EARLIEST_START_DATE;
                coSl.sked_End_Date__c = skedConstants.LATEST_END_DATE;
            }
        }
    }

    private void populateData(List<sked_Collection_Op_Staging_Location__c> newRecords, Map<Id, sked_Collection_Op_Staging_Location__c> oldMap) {
        Map<Id, List<sked_Collection_Op_Staging_Location__c>> existingCoSlByCo = getExistingCoSlsByCoId(newRecords);
        for (sked_Collection_Op_Staging_Location__c coSl : newRecords) {
            sked_Collection_Op_Staging_Location__c oldRecord = oldMap.get(coSl.Id);

            if (oldRecord.sked_Start_Date__c == skedConstants.EARLIEST_START_DATE && coSl.sked_Start_Date__c != skedConstants.EARLIEST_START_DATE) {
                coSl.sked_Start_Date__c = skedConstants.EARLIEST_START_DATE;
            }

            if (oldRecord.sked_End_Date__c == skedConstants.LATEST_END_DATE && coSl.sked_End_Date__c != skedConstants.LATEST_END_DATE) {
                coSl.sked_End_Date__c = skedConstants.LATEST_END_DATE;
            }
            List<sked_Collection_Op_Staging_Location__c> existingCoSlsForCo = existingCoSlByCo.get(coSl.sked_Collection_Operation__c);

            if (existingCoSlsForCo == null || existingCoSlsForCo.isEmpty() || existingCoSlsForCo.size() == 1) {
                coSl.sked_Start_Date__c = skedConstants.EARLIEST_START_DATE;
                coSl.sked_End_Date__c = skedConstants.LATEST_END_DATE;
            }
        }
    }

    private Map<Id, List<sked_Collection_Op_Staging_Location__c>> getExistingCoSlsByCoId(List<sked_Collection_Op_Staging_Location__c> coSls) {
        Map<Id, List<sked_Collection_Op_Staging_Location__c>> coSlsByCoId = new Map<Id, List<sked_Collection_Op_Staging_Location__c>>();

        Set<Id> collectionOpIds = new Set<Id>();
        for (sked_Collection_Op_Staging_Location__c coSl : coSls) {
            collectionOpIds.add(coSl.sked_Collection_Operation__c);
        }

        List<sked_Collection_Op_Staging_Location__c> existingCoSls = [
            SELECT Id, sked_Collection_Operation__c, sked_Start_Date__c, sked_End_Date__c, sked_Staging_Location__c
            FROM sked_Collection_Op_Staging_Location__c
            WHERE sked_Collection_Operation__c IN :collectionOpIds
        ];

        if (existingCoSls != null && !existingCoSls.isEmpty()) {
            for (sked_Collection_Op_Staging_Location__c coSl : existingCoSls) {
                List<sked_Collection_Op_Staging_Location__c> coSlsForCo = coSlsByCoId.get(coSl.sked_Collection_Operation__c);

                if (coSlsForCo == null) {
                    coSlsForCo = new List<sked_Collection_Op_Staging_Location__c>();
                }

                coSlsForCo.add(coSl);
                coSlsByCoId.put(coSl.sked_Collection_Operation__c, coSlsForCo);
            }
        }

        return coSlsByCoId;
    }

    private static void createTravelTimeIndexItems(Set<Id> coslIds) {
        List<sked_Collection_Op_Staging_Location__c> cosls = [
            SELECT Id, sked_Collection_Operation__c, sked_Staging_Location__c, sked_Start_Date__c, sked_End_Date__c,
            sked_Staging_Location__r.sked_Geolocation__c, sked_Staging_Location__r.sked_Timezone__c
            FROM sked_Collection_Op_Staging_Location__c
            WHERE Id IN :coslIds
        ];

        List<skedSCOUtils.ScoQueryModel> scoQueryModels = new List<skedSCOUtils.ScoQueryModel>();
        for (sked_Collection_Op_Staging_Location__c cosl : cosls) {
            scoQueryModels.add(new skedSCOUtils.ScoQueryModel(
                cosl.sked_Collection_Operation__c,
                cosl.sked_Start_Date__c,
                cosl.sked_End_Date__c     
            ));
        }

        Map<Id, List<sked_Site_Collection_Operation__c>> scosByCoId = skedSCOUtils.getScosByCoIds(scoQueryModels);
        List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem> ttiis = new List<skedTravelTimeIndexItemUtils.TravelTimeIndexItem>();

        for (sked_Collection_Op_Staging_Location__c cosl : cosls) {
            List<sked_Site_Collection_Operation__c> scos = scosByCoId.get(cosl.sked_Collection_Operation__c);
            
            if (scos != null && !scos.isEmpty()) {
                for (sked_Site_Collection_Operation__c sco : scos) {
                    if ((sco.sked_Start_Date__c == null || sco.sked_Start_Date__c <= cosl.sked_End_Date__c) || (sco.sked_End_Date__c == null || sco.sked_End_Date__c >= cosl.sked_Start_Date__c)) {
                        if (sco.sked_Site__r.sked__GeoLocation__c != null && cosl.sked_Staging_Location__r.sked_Geolocation__c != null) {
                            ttiis.add(new skedTravelTimeIndexItemUtils.TravelTimeIndexItem(
                                sco.sked_Site__r.sked__GeoLocation__c,
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
}