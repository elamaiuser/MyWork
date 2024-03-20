public class TerritoryTriggerHandler extends TriggerHandler
{
    public override void afterUpdate()
    {
	TerritoryService.updateTerritoryCollOp((List<sked_Territory__c>)trigger.new,(map<id,sked_Territory__c>)trigger.oldMap);
    }
}