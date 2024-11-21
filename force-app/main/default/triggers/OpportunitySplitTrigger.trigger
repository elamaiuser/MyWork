trigger OpportunitySplitTrigger on OpportunitySplit ( after delete, after insert, after undelete, after update, before delete, before insert, before update ) {
    new OpportunitySplitTriggerHandler().run();
}