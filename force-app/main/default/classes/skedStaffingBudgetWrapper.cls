public class skedStaffingBudgetWrapper {
    public Map<Id, Biomed_Collection_Op_Center__c> collectionOpById;
    public Map<Id, sked__Location__c> siteById;
    public sked_Staffing_Budget__c staffingBudget;
    public decimal approvedSlots;
    public decimal totalSlots {get;set;}

    public decimal availableSlots {
        get {
            return totalSlots - approvedSlots;
        }
    }

    public Id recordId {
        get {
            return this.staffingBudget.Id;
        }
    }

    public skedStaffingBudgetWrapper() {
        this.collectionOpById = new Map<Id, Biomed_Collection_Op_Center__c>();
        this.siteById = new Map<Id, sked__Location__c>();
    }
}