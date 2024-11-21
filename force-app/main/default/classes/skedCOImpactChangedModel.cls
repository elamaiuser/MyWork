public class skedCOImpactChangedModel {
    public Id collectionOpId;
    public Date impactStartQueryDate;
    public Date impactEndQueryDate;
    public Date coImpactStartDate;
    public Date coImpactEndDate;

    public skedCOImpactChangedModel(Biomed_Collection_Op_Center__c collectionOp, Date impactStartQueryDate, Date impactEndQueryDate) {
        this.collectionOpId = collectionOp.Id;
        this.impactStartQueryDate = impactStartQueryDate == null ? System.today() : impactStartQueryDate;
        this.impactEndQueryDate = impactEndQueryDate == null ? Date.newInstance(4000, 12, 31) : impactEndQueryDate;
        
        this.coImpactStartDate = collectionOp.sked_IMPACT_Start_Date__c;
        if (collectionOp.sked_IMPACT_Start_Date__c == null) {
            this.coImpactStartDate = System.today();
        }

        this.coImpactEndDate = collectionOp.sked_IMPACT_End_Date__c;
        if (collectionOp.sked_IMPACT_End_Date__c == null) {
            this.coImpactEndDate = Date.newInstance(4000, 12, 31);
        }
    }
}