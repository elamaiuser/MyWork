trigger TaskTrigger on Task (before insert, before update) {
	new TaskTriggerHandler().run();
}