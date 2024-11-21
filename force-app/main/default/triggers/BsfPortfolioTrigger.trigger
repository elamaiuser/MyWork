trigger BsfPortfolioTrigger on BSF_Portfolio__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    new BsfPortfolioTriggerHandler().run();
}