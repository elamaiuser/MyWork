public class ProductTriggerHandler extends TriggerHandler{
    public override void beforeUpdate(){
        ProductService.checkRelaetdDriveDateAndSendNotification((Map<Id,Product2>)trigger.oldMap,(Map<Id,Product2>)trigger.newMap);
    }

    public override void afterUpdate() {
        if(super.getTriggerMethodsToBypass().indexOf('populateProductRTAImageOnPackageItems') == -1) {
            ProductService.populateProductRTAImageOnPackageItems((List<Product2>)trigger.new , (Map<Id, Product2>)trigger.oldMap);
        }
    }
}