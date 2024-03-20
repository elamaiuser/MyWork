public with sharing class skedProcessEventResult {
    public boolean success;
    public string errorMessage;
    public string stackTrace;
    public string message;

    public skedProcessEventResult() {
        this.success = true;
    }

    public void addError(Exception ex) {
        this.success = false;
        this.errorMessage = ex.getMessage();
        this.stackTrace = ex.getStackTraceString();
    }
}