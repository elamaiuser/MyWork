trigger TaskTrigger on Task (before insert, before update, after update,after insert) {
	new TaskTriggerHandler().run();
}