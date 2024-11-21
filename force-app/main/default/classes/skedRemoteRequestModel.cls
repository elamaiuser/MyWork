global virtual class skedRemoteRequestModel {
    public string recordId;
    public List<string> configKeys;
    public Map<string, object> viewData;

    public void populateViewData(Map<string, object> inputViewData) {
    	this.viewData = new Map<string, object>();
        for (string key : inputViewData.keySet()) {
            this.viewData.put(key, inputViewData.get(key));
        }
    }
}