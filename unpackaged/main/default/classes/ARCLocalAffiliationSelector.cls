public Interface ARCLocalAffiliationSelector {
    List<Sobject> getAffiliation();
    List<Sobject> getFilteredAffilaition(Boolean bval);
    List<Sobject> getLocalAffiliations(List<Id> parentid, String programtype);
}