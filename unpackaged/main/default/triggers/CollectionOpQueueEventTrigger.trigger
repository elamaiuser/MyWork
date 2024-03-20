/**
 * @description: Trigger on Collection_Op_Queue_Event__e event
**/
trigger CollectionOpQueueEventTrigger on Collection_Op_Queue_Event__e (after insert) {
    CollectionOperationService.updateUserQueues((List<Collection_Op_Queue_Event__e>)trigger.new);
}