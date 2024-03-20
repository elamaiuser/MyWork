public class skedStaffingBudgetWrapper {
    public Id collectionOpId {get;set;}
    public sked_Staffing_Budget__c staffingBudget {get;set;}
    public decimal approvedSlots {get;set;}
    public decimal availableSlots {
        get {
            return totalSlots - approvedSlots;
        }
    }
    public decimal totalSlots {get;set;}
}