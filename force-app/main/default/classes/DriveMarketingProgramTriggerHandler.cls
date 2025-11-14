public class DriveMarketingProgramTriggerHandler extends TriggerHandler {

  public override void afterUpdate() {
    if(super.getTriggerMethodsToBypass().indexOf('syncSpecialAffiliationsOnDrive') == -1) {
      DriveMarketingProgramTriggerService.syncSpecialAffiliationsOnDrive((Map<Id, Drive_Marketing_Programs__c>)Trigger.newMap, (Map<Id, Drive_Marketing_Programs__c>)Trigger.oldMap, 'Update');
    }
  }

  public override void afterInsert() {
    if(super.getTriggerMethodsToBypass().indexOf('setOrderBudget') == -1) {
      DriveMarketingProgramTriggerService.setOrderBudget((List<Drive_Marketing_Programs__c>)Trigger.old, (List<Drive_Marketing_Programs__c>)Trigger.new,(Map<Id,Drive_Marketing_Programs__c>)trigger.oldMap, (Map<Id,Drive_Marketing_Programs__c>)Trigger.newMap);
    }

    if(super.getTriggerMethodsToBypass().indexOf('syncSpecialAffiliationsOnDrive') == -1) {
      DriveMarketingProgramTriggerService.syncSpecialAffiliationsOnDrive((Map<Id, Drive_Marketing_Programs__c>)Trigger.newMap, null, 'Insert');
    }
  }

  public override void afterDelete() {
    if(super.getTriggerMethodsToBypass().indexOf('syncSpecialAffiliationsOnDrive') == -1) {
      DriveMarketingProgramTriggerService.syncSpecialAffiliationsOnDrive((Map<Id, Drive_Marketing_Programs__c>)Trigger.oldMap, null, 'Delete');
    }
  }

}