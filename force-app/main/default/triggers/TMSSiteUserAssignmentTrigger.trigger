trigger TMSSiteUserAssignmentTrigger on TMS_Site_User_Assignment__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            TMSSiteService.handleAssignmentBeforeSave((List<TMS_Site_User_Assignment__c>)Trigger.new, (Map<Id, TMS_Site_User_Assignment__c>)Trigger.oldMap);
        }
    }
}