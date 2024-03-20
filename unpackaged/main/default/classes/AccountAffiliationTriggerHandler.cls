public class AccountAffiliationTriggerHandler extends TriggerHandler {
    public override void beforeUpdate(){ 
       AccountAffiliationService.AccountAffiliationDateValidation((list<Account_Marketing_Program__c>) Trigger.new);
    }
    public override void afterUpdate(){
        
        //AccountAffiliationService.createHistoryOnAccAffiliation((list<Account_Marketing_Program__c>) Trigger.new, 'Update');
        
    }
    
    public override void beforeInsert(){
        system.debug('SetUniqueAccountAffiliationKey');
        AccountAffiliationService.SetUniqueAccountAffiliationKey((list<Account_Marketing_Program__c>) Trigger.new,'Insert');  
    }
    
    public override void afterInsert(){
        AccountAffiliationService.createHistoryOnAccAffiliation((list<Account_Marketing_Program__c>) Trigger.new, 'Insert');
        
        AccountAffiliationService.AccountFlagForPumpItUpCurrent((list<Account_Marketing_Program__c>) Trigger.new,'Insert');
        AccountAffiliationService.deletePriorAccAffiliation((list<Account_Marketing_Program__c>) Trigger.new);//HRP-11077
        
        
    }
    
    public override void afterDelete(){
        AccountAffiliationService.createHistoryOnAccAffiliation((list<Account_Marketing_Program__c> )Trigger.old, 'Delete' );
    }
    
    public override void beforeDelete(){
    }
}