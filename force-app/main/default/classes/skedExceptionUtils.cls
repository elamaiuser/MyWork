public  class skedExceptionUtils {
    public static skedHC__Exception__c generateException(sked__Job_Allocation__c skedAllocation, string exceptionCode, string exceptionStr) {
        skedHC__Exception__c skedException = new skedHC__Exception__c (
            skedHC__Job__c = skedAllocation.sked__Job__c,
            skedHC__Job_Allocation__c = skedAllocation.Id,
            skedHC__Resource__c = skedAllocation.sked__Resource__c,
            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
        );
        if (!string.isBlank(exceptionCode)) {
            skedException.sked_Exception_Code__c = exceptionCode;
        }
        if (!string.isBlank(exceptionStr)) {
            skedException.skedHC__Exception__c = exceptionStr;
        }
        return skedException;
    }
}