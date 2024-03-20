/**
 * Added to handle DML Scenarios for AccountTeamMemberTrigger
 * Date: 03/04/2021
 * */

trigger AccountTeamMemberTrigger on AccountTeamMember (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
 new AccountTeamMemberTriggerHandler().run();
}