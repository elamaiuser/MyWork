global class skedConvertBiddingToStandardSchedulable implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedConvertBiddingToStandardBatch(), 200);
    }
    
}