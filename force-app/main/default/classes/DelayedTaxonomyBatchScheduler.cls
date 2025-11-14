//@Description: chaining Taxonomy Batches
/* 
*Modification Log 
* Date					     Developer Name			     Comments
* ***************************************************************************
* 04/04/2025                  Harika  Bolisetti          Logic for  HRP-14298
*****************************************************************************
*/
public class DelayedTaxonomyBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {   
        List<Taxonomy_Run__c> recordsToUpdate = new List<Taxonomy_Run__c>(); 
       
            List<Taxonomy_Run__c> taxonomyRuns = [SELECT Id, Taxo_Record_Type__c, Future_Version_Number__c, Sequence__c
                                                  FROM Taxonomy_Run__c 
                                                  WHERE Run_Date__c = TODAY AND Status__c = 'Pending' 
                                                  ORDER BY Sequence__c ASC LIMIT 1];
           
            if (!taxonomyRuns.isEmpty()) {
                Taxonomy_Run__c txrn = taxonomyRuns[0];
                txrn.Status__c = 'Processing';
                txrn.Processing_Start__c = System.now();
                recordsToUpdate.add(txrn);
                if (!recordsToUpdate.isEmpty()) 
                {
                    
                  //  Database.SaveResult[] updateResults = Database.update(recordsToUpdate, false);
                   // Taxo_Utilities.logErrors(updateResults, 'Taxonomy Run', 'BSF_Batch_TaxonomyEndDateHandler', 'Finish', 'Error',
                                             //'Error occurred while updating the Taxonomy Run Record',txrn.Taxo_Record_Type__c,txrn.Future_Version_Number__c);
                }
                
                
                if (txrn == null) return;
                Integer batchSize;
                
                if (txrn.Taxo_Record_Type__c == BSF_Constants.BIO_COLLECTION_RECORD_TYPE) {
                    batchSize = Taxo_Utilities.getBatchSize(txrn.Taxo_Record_Type__c, 'BSF_Batch_PopulateCORegion');
                    Database.executeBatch(new BSF_Batch_PopulateCORegion(null,txrn.Future_Version_Number__c,true), batchSize);
                } 
                else if (txrn.Taxo_Record_Type__c == BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE) {
                    batchSize = Taxo_Utilities.getBatchSize(txrn.Taxo_Record_Type__c, 'BSF_Batch_BSFPortfolio');
                    Database.executeBatch(new BSF_Batch_BSFPortfolio(txrn.Taxo_Record_Type__c, txrn.Future_Version_Number__c, null, null, true, true), batchSize);
                } 
                else {
                    batchSize = Taxo_Utilities.getBatchSize(txrn.Taxo_Record_Type__c, 'BSF_Batch_BSFPortfolio');
                    Database.executeBatch(new BSF_Batch_BSFPortfolio(txrn.Taxo_Record_Type__c, txrn.Future_Version_Number__c, null, null, false, true), batchSize);
                }
           
              
            } 
     
        
        
        
    }
    
    
    
}