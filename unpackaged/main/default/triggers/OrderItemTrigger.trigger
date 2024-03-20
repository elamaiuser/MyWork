trigger OrderItemTrigger on OrderItem (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    new OrderItemTriggerHandler().run();
}