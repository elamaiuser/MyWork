trigger CollectionOpUpdateEventTrigger on Collection_Op_Update_Event__e (After Insert) {
    CollectionOperationService.updateUserCollectionOpPicklist((List<Collection_Op_Update_Event__e>)trigger.new);
}