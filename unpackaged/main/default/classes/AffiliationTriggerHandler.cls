public class AffiliationTriggerHandler extends TriggerHandler {
    public override void beforeUpdate(){   
        
        
    }
    public override void afterUpdate(){
        system.debug('before update populateEndDateInAccountAffiliation##');
        AffiliationService.populateEndDateInAccountAffiliation((list<Marketing_Program__c>) Trigger.new, 'Update'); 
    }
}