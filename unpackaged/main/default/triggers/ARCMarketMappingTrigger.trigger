trigger ARCMarketMappingTrigger on ARC_Market_Mapping__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
  new ARCMarketMappingTriggerHandler().run();

}