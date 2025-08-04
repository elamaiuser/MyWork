public class AccountAffiliationTriggerHandler extends TriggerHandler {
    public override void beforeUpdate() { 
        if (super.getTriggerMethodsToBypass().indexOf('AccountAffiliationDateValidation') == -1) {
            AccountAffiliationService.AccountAffiliationDateValidation((list<Account_Marketing_Program__c>) Trigger.new);
        }
    }
    public override void afterUpdate() {        
        //AccountAffiliationService.createHistoryOnAccAffiliation((list<Account_Marketing_Program__c>) Trigger.new, 'Update');
        if (super.getTriggerMethodsToBypass().indexOf('AccountFlagForAffiliationList') == -1) {
            AccountAffiliationService.AccountFlagForAffiliationList((list<Account_Marketing_Program__c>) Trigger.new,'Update');  
        }      
    }
    
    public override void beforeInsert() {
        if (super.getTriggerMethodsToBypass().indexOf('SetUniqueAccountAffiliationKey') == -1) {
            AccountAffiliationService.SetUniqueAccountAffiliationKey((list<Account_Marketing_Program__c>) Trigger.new,'Insert');  
        }
    }
    
    public override void afterInsert() {
        if (super.getTriggerMethodsToBypass().indexOf('createHistoryOnAccAffiliation') == -1) {
            AccountAffiliationService.createHistoryOnAccAffiliation((list<Account_Marketing_Program__c>) Trigger.new, 'Insert');
            AccountAffiliationService.updateMarketingProgramFlagOnAccounts((list<Account_Marketing_Program__c>) Trigger.new, 'Insert');
        }
        
        if (super.getTriggerMethodsToBypass().indexOf('AccountFlagForAffiliationList') == -1) {  
            AccountAffiliationService.AccountFlagForAffiliationList((list<Account_Marketing_Program__c>) Trigger.new,'Insert');
        }
        
        if (super.getTriggerMethodsToBypass().indexOf('deletePriorAccAffiliation') == -1) {
            AccountAffiliationService.deletePriorAccAffiliation((list<Account_Marketing_Program__c>) Trigger.new);//HRP-11077
        }
    }
    
    public override void afterDelete() {
        if (super.getTriggerMethodsToBypass().indexOf('createHistoryOnAccAffiliation') == -1) {
            AccountAffiliationService.createHistoryOnAccAffiliation((list<Account_Marketing_Program__c> )Trigger.old, 'Delete' );
            AccountAffiliationService.updateMarketingProgramFlagOnAccounts((list<Account_Marketing_Program__c>) Trigger.old, 'Delete');
        }
    }
    
    public override void beforeDelete() {}
}