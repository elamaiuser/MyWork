global class BSF_Sched_DeleteExpiredTaxoVersionBatch implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        BSF_Batch_DeleteExpiredTaxoVersionBatch batch = new BSF_Batch_DeleteExpiredTaxoVersionBatch();
        Database.executeBatch(batch, 200); // you can change the batch size as needed
    }
}