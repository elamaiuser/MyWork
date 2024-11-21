public class skedBiomedCollectionOpHandler extends skedTriggerHub implements Callable {
    
    public override void onBeforeUpdate() {
        validate(this.context.newRecords, (Map<Id, Biomed_Collection_Op_Center__c>)this.context.oldMap);
    }

    public override void onAfterUpdate() {
        captureJobIMPACTChanges(this.context.newRecords, (Map<Id, Biomed_Collection_Op_Center__c>) this.context.oldMap);
        captureWeightLevelValueChanges(this.context.newRecords, (Map<Id, Biomed_Collection_Op_Center__c>) this.context.oldMap);
    }
    
    public override void onAfterInsert() {
        if (!Test.isRunningTest()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedBiomedCollectionOpHandler.class.getName(),
                'createQueues',
                getCollectionOpNames(this.context.newRecords, false)
            );
        }
    }

    public override void onAfterDelete() {
        if (!Test.isRunningTest()) {
            skedFutureCallEventHandler.publishFutureCallEvent(
                skedBiomedCollectionOpHandler.class.getName(),
                'deleteQueues',
                getCollectionOpNames(this.context.oldRecords, false)
            );
        }
    }
    
    private void validate(List<Biomed_Collection_Op_Center__c> newRecords, Map<Id, Biomed_Collection_Op_Center__c> oldMap) {
        Map<Id, Biomed_Collection_Op_Center__c> mapRecordToValidate = new Map<Id, Biomed_Collection_Op_Center__c>();
        for (Biomed_Collection_Op_Center__c newRecord : newRecords) {
            Biomed_Collection_Op_Center__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Is_Deactivated__c != oldData.sked_Is_Deactivated__c && newRecord.sked_Is_Deactivated__c == TRUE) {
                mapRecordToValidate.put(newRecord.Id, newRecord);
            }
        }
        if (!mapRecordToValidate.isEmpty()) {
            List<Biomed_Collection_Op_Center__c> collectionOperations = [SELECT Id,
                                                                         (SELECT Id
                                                                          FROM sked_Drives__r
                                                                          WHERE sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL)
                                                                         FROM Biomed_Collection_Op_Center__c
                                                                         WHERE Id IN :mapRecordToValidate.keySet()];
            for (Biomed_Collection_Op_Center__c collectionOperation : collectionOperations) {
                boolean hasChildren = !collectionOperation.sked_Drives__r.isEmpty();
                if (hasChildren) {
                    Biomed_Collection_Op_Center__c newRecord = mapRecordToValidate.get(collectionOperation.Id);
                    newRecord.addError('This collection operation has children data and prior to deactivating, it must be disassociated from its children.');
                }
            }
        }
    }

    public static void deleteQueues(Set<String> collectionOpNames) {
        try {
            delete [
                SELECT Id 
                FROM Group
                WHERE Name LIKE :collectionOpNames
            ];     
        } catch (DmlException dExc) {
            System.debug('Failed to delete all Queues');
        }
    }

    public static void createQueues(Set<String> collectionOpNames) {
        List<Group> queuesToCreate = new List<Group>();
        Map<String, String> sObjectsToCreateQueuesForByName = new Map<String, String>();
        
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_DRIVE_CHANGE_REQUESTS, 'sked_Drive_Change_Request__c');
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_PENDING_ACTIONS, 'sked_Drive__c');
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_ROLE_TIME_VARIANCES, 'sked__Location__c');
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_DM_ROLE_TIME_VARIANCES, 'sked__Location__c');
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_CM_ROLE_TIME_VARIANCES, 'sked__Location__c');
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_DRIVE_SHIFT_TRADES, 'sked_Drive_Shift_Trade__c');
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_DM_DRIVE_CHANGE_REQUESTS, 'sked_Drive_Change_Request__c');
        sObjectsToCreateQueuesForByName.put(skedConstants.PROFILE_QUEUE_DM_PENDING_ACTIONS, 'sked_Drive__c');
 
        for(String coName : collectionOpNames) {
            for (String queueTarget : sObjectsToCreateQueuesForByName.keySet()) {
                queuesToCreate.add(new Group(
                    name = coName + ': ' + queueTarget,
                    type = skedConstants.GROUP_TYPE_QUEUE
                ));
            }
        }

        insert queuesToCreate;

        List<QueueSobject> queueSobjectsToCreate = new List<QueueSobject>();
        for (Group newQueue : queuesToCreate) {
            String correctQueueTarget = null;
            
            for (String queueTarget : sObjectsToCreateQueuesForByName.keySet()) {
                if (newQueue.name.contains(queueTarget)) {
                    correctQueueTarget = queueTarget;
                }
            }

            if (correctQueueTarget != null) {
                queueSobjectsToCreate.add(new QueueSobject(
                    QueueId = newQueue.Id,
                    SobjectType = sObjectsToCreateQueuesForByName.get(correctQueueTarget)
                ));
            }
        }

        insert queueSobjectsToCreate;
    }

    @testVisible
    private static Set<String> getCollectionOpNames(List<Biomed_Collection_Op_Center__c> records, Boolean appendWildcard) {
        Set<String> collectionOpNames = new Set<String>();
        for (Biomed_Collection_Op_Center__c co : records) {
            collectionOpNames.add(co.Name + (appendWildcard ? '%' : ''));
        }

        return collectionOpNames;
    }

    private void captureJobIMPACTChanges(List<Biomed_Collection_Op_Center__c> newRecords, Map<Id, Biomed_Collection_Op_Center__c> oldMap) {
        List<skedCOImpactChangedModel> impactChangedCOs = new List<skedCOImpactChangedModel>();
        for (Biomed_Collection_Op_Center__c co : newRecords) {
            Biomed_Collection_Op_Center__c oldCo = oldMap.get(co.Id);
            
            if (co.sked_IMPACT_Start_Date__c != oldCo.sked_IMPACT_Start_Date__c || co.sked_IMPACT_End_Date__c != oldCo.sked_IMPACT_End_Date__c) {
                Date impactStartQueryDate = co.sked_IMPACT_Start_Date__c;
                if (oldCo.sked_IMPACT_Start_Date__c < impactStartQueryDate || oldCo.sked_IMPACT_Start_Date__c == null) {
                    impactStartQueryDate = oldCo.sked_IMPACT_Start_Date__c;
                }

                Date impactEndQueryDate = co.sked_IMPACT_End_Date__c;
                if (oldCo.sked_IMPACT_End_Date__c > impactEndQueryDate || oldCo.sked_IMPACT_End_Date__c == null) {
                    impactEndQueryDate = oldCo.sked_IMPACT_End_Date__c;
                }

                impactChangedCOs.add(new skedCOImpactChangedModel(co, impactStartQueryDate, impactEndQueryDate));
            }
        }

        if (!impactChangedCOs.isEmpty() && !Test.isRunningTest()) {
            Database.executeBatch(new skedCaptureJobIMPACTBatch(impactChangedCOs), 200);
        }
    }

    private void captureWeightLevelValueChanges(List<Biomed_Collection_Op_Center__c> newRecords, Map<Id, Biomed_Collection_Op_Center__c> oldMap) {
        Map<Id, Biomed_Collection_Op_Center__c> coWithWeightLevelValueChanges = new Map<Id, Biomed_Collection_Op_Center__c>();
        for (Biomed_Collection_Op_Center__c co : newRecords) {
            Biomed_Collection_Op_Center__c oldCo = oldMap.get(co.Id);
            if (co.sked_Low_Weight__c != oldCo.sked_Low_Weight__c
                || co.sked_Medium_Weight__c != oldCo.sked_Medium_Weight__c
                || co.sked_High_Weight__c != oldCo.sked_High_Weight__c
                || co.sked_Role_Priorities_Weight__c  != oldCo.sked_Role_Priorities_Weight__c) {
                coWithWeightLevelValueChanges.put(co.Id, co);
            }
        }
        if (coWithWeightLevelValueChanges.isEmpty()) {
            return;
        }

        List<sked_CollectionOperationOptimizerSetting__c> optimizerSettings = [
            SELECT sked_Collection_Operation__c, sked_Default_Weight__c, sked_Constraint_Type__c, sked_Constraint__c, sked_Enabled__c, sked_Display_Type__c 
            FROM sked_CollectionOperationOptimizerSetting__c
            WHERE sked_Collection_Operation__c IN :coWithWeightLevelValueChanges.keySet()
        ];
        if (optimizerSettings.isEmpty()) {
            return;
        }

        skedCollectionOpOptimizerSettingUtils.populateOptimizerMappedWeight(optimizerSettings, coWithWeightLevelValueChanges);
        update optimizerSettings;
    }

    public static Object call(String methodName, Map<String, Object> params) {
        skedProcessEventResult result = new skedProcessEventResult();
        try {
            switch on methodName {
                when 'createQueues' {
                    createQueues((Set<String>) JSON.deserialize((String) params.get('param1'), Set<String>.class));

                }
                when 'deleteQueues' {
                    deleteQueues((Set<String>) JSON.deserialize((String) params.get('param1'), Set<String>.class));
                }
                when else {
                    throw new skedException('Unable to locate Method: ' + methodName + ' in Class: ' + skedBiomedCollectionOpHandler.class.getName());
                }
            }
        } catch (skedException ex) {
            result.addError(ex);
        }

        return result;
    }
}