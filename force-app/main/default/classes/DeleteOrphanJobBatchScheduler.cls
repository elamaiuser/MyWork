global class DeleteOrphanJobBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        DeleteOrphanJobBatch batch = new DeleteOrphanJobBatch();
        Database.executeBatch(batch, 200);
    }
}