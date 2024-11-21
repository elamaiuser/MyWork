trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert,before Update,after Insert, after update,before Delete,after Delete) {
    new OpportunityContactRoleTriggerHandler().run();
}