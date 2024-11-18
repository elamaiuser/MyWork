public with sharing class skedCollectionOpOptimizerSettingHandler extends skedTriggerHub {
    public override void onBeforeInsert() {
        populateOptimizerMappedWeight((List<sked_CollectionOperationOptimizerSetting__c>) this.context.newRecords);
    }

    public override void onBeforeUpdate() {
        captureConstraintOrWeightChanges(this.context.newRecords, (Map<Id, sked_CollectionOperationOptimizerSetting__c>) this.context.oldMap);
    }

    private void captureConstraintOrWeightChanges(
        List<sked_CollectionOperationOptimizerSetting__c> newRecords,
        Map<Id, sked_CollectionOperationOptimizerSetting__c> oldMap
    ) {
        List<sked_CollectionOperationOptimizerSetting__c> recordsWithConstraintOrWeightChanges = new List<sked_CollectionOperationOptimizerSetting__c>();
        for (sked_CollectionOperationOptimizerSetting__c newRecord : newRecords) {
            sked_CollectionOperationOptimizerSetting__c oldRecord = oldMap.get(newRecord.Id);
            if (oldRecord.sked_Constraint_Type__c != newRecord.sked_Constraint_Type__c 
                || oldRecord.sked_Default_Weight__c != newRecord.sked_Default_Weight__c) {
                recordsWithConstraintOrWeightChanges.add(newRecord);
            }
        }
        if (recordsWithConstraintOrWeightChanges.isEmpty()) {
            return;
        }

        populateOptimizerMappedWeight(recordsWithConstraintOrWeightChanges);
    }

    private void populateOptimizerMappedWeight(List<sked_CollectionOperationOptimizerSetting__c> records) {
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_CollectionOperationOptimizerSetting__c record : records) {
            collectionOperationIds.add(record.sked_Collection_Operation__c);
        }

        Map<Id, Biomed_Collection_Op_Center__c> collectionOperationMap = new Map<Id, Biomed_Collection_Op_Center__c>(
            [
                SELECT Id, sked_Low_Weight__c, sked_Medium_Weight__c, sked_High_Weight__c, sked_Role_Priorities_Weight__c
                FROM Biomed_Collection_Op_Center__c
                WHERE Id IN :collectionOperationIds
            ]
        );

        skedCollectionOpOptimizerSettingUtils.populateOptimizerMappedWeight(records, collectionOperationMap);
    }
}