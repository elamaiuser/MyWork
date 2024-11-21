public class TerritoryCollOpTriggerHandler extends TriggerHandler
{
  public override void beforeUpdate()
  {
      TerritoryCollectionOperationService.DateHandlingOnUpdate((Map<Id,sked_Territory_Collection_Operation__c>)trigger.oldMap,(List<sked_Territory_Collection_Operation__c>)trigger.new);
  }
      
}