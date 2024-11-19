public class skedCollectionOpStagingLocationHandler extends skedTriggerHub implements callable {
    
    public override void onAfterInsert() {
        if (!System.isBatch()) {
            initiateRepopulateDriveStagingLocationBatch((List<sked_Collection_Op_Staging_Location__c>) this.context.newRecords);
        }

        skedFutureCallEventHandler.publishFutureCallEvent(
            skedCollectionOpStagingLocationHandler.class.getName(),
            'createTravelTimeIndexItems',
            skedSObjectUtils.getRecordIds(this.context.newRecords)   
        );
    }
  
    public override void onAfterUpdate() {
        if (!System.isBatch()) {
            initiateRepopulateDriveStagingLocationBatch((List<sked_Collection_Op_Staging_Location__c>) this.context.newRecords, (Map<Id, sked_Collection_Op_Staging_Location__c>) this.context.oldMap);
        }
    }

    public override void onAfterDelete() {
        if (!System.isBatch()) {
        	initiateRepopulateDriveStagingLocationBatch((List<sked_Collection_Op_Staging_Location__c>) this.context.oldRecords);
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
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedCollectionOpStagingLocationHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }

    /******************************************** Private Methods ********************************************/
    private void initiateRepopulateDriveStagingLocationBatch(List<sked_Collection_Op_Staging_Location__c> cosls) {
        Set<Id> affectedStagingLocationIds = new Set<Id>();
        for (sked_Collection_Op_Staging_Location__c cosl : cosls) {
            if(!affectedStagingLocationIds.contains(cosl.sked_Staging_Location__c)){
            	affectedStagingLocationIds.add(cosl.sked_Staging_Location__c);
            }
        }
        Database.executeBatch(new skedRepopulateDriveStagingLocBatch(affectedStagingLocationIds));
    }

    private void initiateRepopulateDriveStagingLocationBatch(List<sked_Collection_Op_Staging_Location__c> cosls, Map<Id, sked_Collection_Op_Staging_Location__c> oldCoslsById) {
        Set<Id> affectedStagingLocationIds = new Set<Id>();
        for (sked_Collection_Op_Staging_Location__c cosl : cosls) {
            sked_Collection_Op_Staging_Location__c oldCoSl = oldCoslsById.get(cosl.Id);
            if(!affectedStagingLocationIds.contains(oldCoSl.sked_Staging_Location__c)){
            	affectedStagingLocationIds.add(oldCoSl.sked_Staging_Location__c);
            }
        }
        Database.executeBatch(new skedRepopulateDriveStagingLocBatch(affectedStagingLocationIds));
    }

    public static void createTravelTimeIndexItems(Set<Id> coslIds) {
        List<sked_Collection_Op_Staging_Location__c> cosls = [
            SELECT Id, sked_Collection_Operation__c, sked_Staging_Location__c, sked_Start_Date__c, sked_End_Date__c,
            sked_Staging_Location__r.sked_Geolocation__c, sked_Staging_Location__r.sked_Timezone__c
            FROM sked_Collection_Op_Staging_Location__c
            WHERE Id IN :coslIds
        ];
        System.debug('COSLS :: ' + cosls);
        

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