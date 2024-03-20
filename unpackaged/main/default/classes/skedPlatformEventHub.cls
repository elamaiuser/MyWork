public virtual class skedPlatformEventHub extends skedHubBase  {

    private Map<String, Set<String>> mapObjectToProcessedObjectReplayIds = new Map<String, Set<String>>();
    @TestVisible
    private Boolean isObjectProcessed(Type componentClass, SObject sObj) {
        return false;
    }

    private void setObjectsProcessed(Type componentClass, List<SObject> listSObjects) {
        String componentClassName = componentClass.getName();

        if (!mapObjectToProcessedObjectReplayIds.containsKey(componentClassName)) {
            mapObjectToProcessedObjectReplayIds.put(componentClassName, new Set<String>());
        }

        Set<String> setObjectIdsProcessed = new Set<String>();
        for (SObject sObj : listSObjects) {
            setObjectIdsProcessed.add((String) sObj.get('ReplayId'));
        }

        mapObjectToProcessedObjectReplayIds.get(componentClassName).addAll(setObjectIdsProcessed);
    }
}