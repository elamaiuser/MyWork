trigger TerritoryCollectionOperation on sked_Territory_Collection_Operation__c (before insert,before update) 
{
	new TerritoryCollOpTriggerHandler().run();
}