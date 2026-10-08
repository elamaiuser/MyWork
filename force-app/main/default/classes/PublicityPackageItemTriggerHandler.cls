public class PublicityPackageItemTriggerHandler extends TriggerHandler {
	public override void beforeUpdate() {
        if(super.getTriggerMethodsToBypass().indexOf('getProductImageUrl') == -1) {
            PublicityPackageItemTriggerService.getProductImageUrl((List<Publicity_Package_Item__c>)trigger.new, (Map<Id, Publicity_Package_Item__c>)trigger.oldMap);
        }
    }
    
    public override void beforeInsert() {
        if(super.getTriggerMethodsToBypass().indexOf('getProductImageUrl') == -1) {
            PublicityPackageItemTriggerService.getProductImageUrl((List<Publicity_Package_Item__c>)trigger.new, null);
        }
    }
}