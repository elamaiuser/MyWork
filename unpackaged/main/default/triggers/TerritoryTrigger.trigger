trigger TerritoryTrigger on sked_Territory__c (After update) 
{
	 System.debug('Inside trigger');
   new TerritoryTriggerHandler().run();
}