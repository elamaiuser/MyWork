trigger PublicityPackageItemTrigger on Publicity_Package_Item__c (before insert, before update) {
	new PublicityPackageItemTriggerHandler().run();
}