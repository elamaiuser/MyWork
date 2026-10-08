trigger TMSSiteTrigger on TMS_Site__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            TMSSiteService.handleTMSSiteBeforeSave((List<TMS_Site__c>)Trigger.new, (Map<Id, TMS_Site__c>)Trigger.oldMap);
        }
    }
}