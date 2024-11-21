public class NewFixedSiteDriveQueueable implements Queueable {
    
    public List<NewFixedSiteDrive.fixedOpps> oppIdList;
    public NewFixedSiteDriveQueueable(List<NewFixedSiteDrive.fixedOpps> oppIds) {
        this.oppIdList = new List<NewFixedSiteDrive.fixedOpps>();
        this.oppIdList=oppIds;
    }
    
    public void execute(QueueableContext context) {
        List<Opportunity> oppList = new List<Opportunity>();
        List<NewFixedSiteDrive.fixedOpps> oppIds = this.oppIdList;
        
        if(oppIds[0].oppsToCreate != null && !oppIds[0].oppsToCreate.isEmpty()) {
            oppList = oppIds[0].oppsToCreate; 
        }
        Database.SaveResult[] srList = Database.insert(oppList, false);
        List<BSF_Error_Log__c> errorLogList = BSF_Utilities.createErrorLog(srList, 'Plan A Drive', 'NewFixedSiteDriveQueueable', 'execute', 'Error', 'Error during planning a drive');
        if(!errorLogList.isEmpty()) {
        	insert errorLogList;
        }
    }
}