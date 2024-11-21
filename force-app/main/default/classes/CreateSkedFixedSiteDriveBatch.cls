global class CreateSkedFixedSiteDriveBatch implements Database.Batchable<sObject> {
    
    global List<Opportunity> opportunitiesToGenerateDrivesFor;
    public static final Id FIXED_SITE_OPP_RECTYPEID = SObjectType.Opportunity.getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId();
    
    global CreateSkedFixedSiteDriveBatch(List<Opportunity> incomingOpportunities) {
        opportunitiesToGenerateDrivesFor = incomingOpportunities;
    }
    
    global List<Opportunity> start(Database.BatchableContext bc) {
        return opportunitiesToGenerateDrivesFor;
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        list<Opportunity> fixSiteOppList = new list<opportunity>();
        for(Opportunity opp : scope) {
            if(opp.RecordTypeId == FIXED_SITE_OPP_RECTYPEID) {
                fixSiteOppList.add(opp);
            }
        }
        DriveGeneratorService.generateDrivesOnOppInsert(fixSiteOppList);
        system.debug('--> \n Sked call to create drives is done. '); 
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}