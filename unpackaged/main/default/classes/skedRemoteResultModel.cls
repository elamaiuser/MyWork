global virtual class skedRemoteResultModel {
    public object data;
    public boolean success;
    public string errorMessage;
    public string stackTrace;
    public string message;
    public Map<string, object> viewData;
    
    public skedRemoteResultModel() {
        this.success = true;
        this.errorMessage = '';
        this.message = '';
        this.viewData = new Map<string, object>();
    }
    
    public skedRemoteResultModel(Map<string, object> inputViewData) {
        this.success = true;
        this.errorMessage = '';
        this.message = '';
        this.viewData = new Map<string, object>();
        for (string key : inputViewData.keySet()) {
            this.viewData.put(key, inputViewData.get(key));
        }
    }
    
    public void getError(Exception ex) {
        this.success = false;
        this.errorMessage = ex.getMessage();
        this.stackTrace = ex.getStackTraceString();
    }
    
    public void getError(Exception ex, SavePoint sp) {
        getError(ex);
        Database.rollback(sp);
    }
}