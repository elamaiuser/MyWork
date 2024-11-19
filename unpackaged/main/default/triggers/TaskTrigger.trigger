trigger TaskTrigger on Task (before insert, before update, after update) {
	new TaskTriggerHandler().run();
}