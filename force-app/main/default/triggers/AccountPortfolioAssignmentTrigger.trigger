trigger AccountPortfolioAssignmentTrigger on Account_Portfolio_Assignment__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    new AccountPortfolioAssignmentTriggerHandler().run();
    
}