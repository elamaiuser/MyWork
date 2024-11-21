public class ProductTriggerHandler extends TriggerHandler{
    public override void beforeUpdate(){
        ProductService.checkRelaetdDriveDateAndSendNotification((Map<Id,Product2>)trigger.oldMap,(Map<Id,Product2>)trigger.newMap);
    }
}