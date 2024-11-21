/***
* HRP-1615->User: Managing Promotional Items Available to Drives
* 
* */
public class PromotionTriggerHandler extends TriggerHandler{
   
    public override void afterUpdate(){
        System.debug('Entered method beforeUpdate');
        PromotionService.validatePromotionEndDateWithDriveDate((List<Promotion__c>)trigger.new,(Map<Id,Promotion__c>)trigger.oldMap);
        System.debug('Exiting method beforeUpdate');     
    }
}