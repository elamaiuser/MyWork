public class skedExceptionMasterModel {
    public List<sked__Job_Allocation__c> jobAllocations;
    public Map<Id, sked_Drive_Shift__c> mapDriveShift;
    public Map<Id, sked__Job__c> mapJob;
    public Map<Id, sked__Resource__c> mapResource;
    
    public Set<string> newExceptionUniqueKeys;
}