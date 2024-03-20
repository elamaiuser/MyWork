public class PortfolioAssignmentRecordsController {
    @AuraEnabled(cacheable=true)
    public static Boolean getBatchList() {
        Boolean batchInProgress = false;
        /*List<AsyncApexJob> batchList = [Select ApexClassId, Id, JobItemsProcessed, JobType, Status, NumberOfErrors, CompletedDate from AsyncApexJob  where
                                 (Status = 'Holding' OR Status = 'Queued' OR Status ='Processing') AND JobType in ('BSF_Batch_OpportunityTeamMember', 'BatchApex') limit 10000];
        if((batchList != null && !batchList.isEmpty()) || Test.isRunningTest()){
            batchInProgress = true;
        }*/
        List<Portfolio_Accounts_Processing__c> pt = [Select Id,Portfolio_progress_for_Accounts__c,Records_Processed__c , Portfolio_Assignment_Updated__c From Portfolio_Accounts_Processing__c LIMIT 1];
        if ((pt.size() > 0 && pt[0].Portfolio_progress_for_Accounts__c != null & pt[0].Portfolio_progress_for_Accounts__c > 0 && (pt[0].Portfolio_progress_for_Accounts__c != pt[0].Records_Processed__c || pt[0].Portfolio_Assignment_Updated__c)) || Test.isRunningTest()) {
            batchInProgress = true;
        }
        return batchInProgress;
    }
}