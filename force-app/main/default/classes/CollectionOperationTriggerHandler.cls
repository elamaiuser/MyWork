/**
 * @description: Handler class for Biomed_Collection_Op_Center__c trigger
**/
public without sharing class CollectionOperationTriggerHandler extends TriggerHandler{

    public override void afterInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('updateUserCollectionOpPicklist') == -1) {
            System.debug('CollectionOperationTriggerHandler.afterInsert() - CollectionOperationService.updateUserCollectionOpPicklist() Executing...');
            CollectionOperationService.updateUserCollectionOpPicklist((Map<Id,Biomed_Collection_Op_Center__c>)trigger.newMap,null);
        }else{
            System.debug('CollectionOperationTriggerHandler.afterInsert() - CollectionOperationService.updateUserCollectionOpPicklist() Bypassed...');
        }
    }

    public override void afterUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('updateUserQueues') == -1) {
            System.debug('CollectionOperationTriggerHandler.afterUpdate() - CollectionOperationService.updateUserQueues() Executing...');
            CollectionOperationService.updateUserQueues((List<Biomed_Collection_Op_Center__c>)trigger.new,(Map<Id,Biomed_Collection_Op_Center__c>)trigger.oldMap);
        }else{
            System.debug('CollectionOperationTriggerHandler.afterUpdate() - CollectionOperationService.updateUserQueues() Bypassed...');
        }
        if(super.getTriggerMethodsToBypass().indexOf('updateUserCollectionOpPicklist') == -1) {
            System.debug('CollectionOperationTriggerHandler.afterUpdate() - CollectionOperationService.updateUserCollectionOpPicklist() Executing...');
            CollectionOperationService.updateUserCollectionOpPicklist((Map<Id,Biomed_Collection_Op_Center__c>)trigger.newMap,(Map<Id,Biomed_Collection_Op_Center__c>)trigger.oldMap);
        }else{
            System.debug('CollectionOperationTriggerHandler.afterUpdate() - CollectionOperationService.updateUserCollectionOpPicklist() Bypassed...');
        }
    }

    public override void afterDelete(){
        if(super.getTriggerMethodsToBypass().indexOf('updateUserCollectionOpPicklist') == -1) {
            System.debug('CollectionOperationTriggerHandler.afterDelete() - CollectionOperationService.updateUserCollectionOpPicklist() Executing...');
            CollectionOperationService.updateUserCollectionOpPicklist(null,(Map<Id,Biomed_Collection_Op_Center__c>)trigger.oldMap);
        }else{
            System.debug('CollectionOperationTriggerHandler.afterDelete() - CollectionOperationService.updateUserCollectionOpPicklist() Bypassed...');
        }
    }
}