public class skedTravelDistanceOneTimeBatch implements Database.Batchable<SObject> {

    public skedTravelDistanceOneTimeBatch() {}

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
           SELECT Id, sked_Travel_Time_Breakdown_JSON__c
           FROM sked_Travel_Time_Index_Item__c
           WHERE sked_Travel_Distance__c = NULL 
           OR sked_Average_Travel_Time__c = NULL
        ]);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<sked_Travel_Time_Index_Item__c> ttiis = (List<sked_Travel_Time_Index_Item__c>) scope;
        List<sked_Travel_Time_Index_Item__c> ttiisToUpdate = new List<sked_Travel_Time_Index_Item__c>();
        for (sked_Travel_Time_Index_Item__c ttii : ttiis) {
            if (ttii.sked_Travel_Time_Breakdown_JSON__c != null && ttii.sked_Travel_Time_Breakdown_JSON__c != skedConstants.NO_TRAVEL_TIME_DATA) {
                List<skedTravelTimeBreakdownModel> models = 
                    (List<skedTravelTimeBreakdownModel>)JSON.deserialize(ttii.sked_Travel_Time_Breakdown_JSON__c, List<skedTravelTimeBreakdownModel>.class);
                
                if (models != null && !models.isEmpty()) {
                    Decimal travelDistance;
                    Decimal averageTravelTime;
                    Decimal totalTravelTime = 0;
                    for (skedTravelTimeBreakdownModel model : models) {
                        if (travelDistance == null && model.travelDistance != null) {
                            travelDistance = model.travelDistance;
                        }
                        totalTravelTime += (model.travelTime != NULL ? model.travelTime : 0);  
                    }
                    averageTravelTime = totalTravelTime / models.size();
                    ttii.sked_Average_Travel_Time__c = Math.round(averageTravelTime);

                    if (travelDistance != null) {
                        ttii.sked_Travel_Distance__c = Math.round(travelDistance / skedConstants.METTER_PER_MILE);
                    }
                    ttiisToUpdate.add(ttii);
                }
            }
        }
        update ttiisToUpdate;
    }

    public void finish(Database.BatchableContext BC) {}
}