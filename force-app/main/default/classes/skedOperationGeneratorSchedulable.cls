global class skedOperationGeneratorSchedulable implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedOperationGeneratorBatch(), 100);
    }
    
}