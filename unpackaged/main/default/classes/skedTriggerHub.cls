public virtual class skedTriggerHub extends skedHubBase {

    private Map<String, Set<Id>> mapObjectToProcessedObjectIds = new Map<String, Set<Id>>();
    private Boolean isObjectProcessed(Type componentClass, SObject sObj) {
        String componentClassName = componentClass.getName();

        if (!mapObjectToProcessedObjectIds.containsKey(componentClassName)) {
            mapObjectToProcessedObjectIds.put(componentClassName, new Set<Id>());
        }
        return mapObjectToProcessedObjectIds.get(componentClassName).contains(sObj.Id);
    }

    private void setObjectsProcessed(Type componentClass, List<SObject> listSObjects) {
        String componentClassName = componentClass.getName();

        if (!mapObjectToProcessedObjectIds.containsKey(componentClassName)) {
            mapObjectToProcessedObjectIds.put(componentClassName, new Set<Id>());
        }

        Set<Id> setObjectIdsProcessed = new Set<Id>();
        for (SObject sObj : listSObjects) {
            setObjectIdsProcessed.add(sObj.Id);
        }

        mapObjectToProcessedObjectIds.get(componentClassName).addAll(setObjectIdsProcessed);
    }
}