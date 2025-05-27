public with sharing class OperationDriveLimitTriggerHandler extends TriggerHandler{
    public override void beforeInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('validate') == -1) {
			OperationDriveLimitService.validate( (List<sked_Operation_Drive_Limit__c>)trigger.new);
		}
    }
    public override void beforeUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('validate') == -1) {
            OperationDriveLimitService.validate((List<sked_Operation_Drive_Limit__c>)trigger.new);
		}
    }
}