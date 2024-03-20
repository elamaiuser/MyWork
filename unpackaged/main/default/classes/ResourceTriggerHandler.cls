/*
* Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 05/16/2023			Barnojit Sharma				ResourceTriggerHandler handler class for ResourceTrigger (HRP-1566)
 *****************************************************************************************************************************************************************************
*/
public with sharing class ResourceTriggerHandler extends TriggerHandler{
    public override void afterInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('pushNotificationUpdateEvent') == -1) {
            ResourceNotificationEmailUtil.pushNotificationUpdateEvent((List<sked__Resource__c>) trigger.new,null);
        }
    }
    public override void afterUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('pushNotificationUpdateEvent') == -1) {
            ResourceNotificationEmailUtil.pushNotificationUpdateEvent((List<sked__Resource__c>) trigger.new,(Map<Id,sked__Resource__c>) trigger.oldMap);
        }
    }
}