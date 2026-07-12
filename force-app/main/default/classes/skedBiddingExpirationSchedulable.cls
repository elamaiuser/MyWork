global class skedBiddingExpirationSchedulable implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        Database.executeBatch(new skedBiddingExpirationBatch(), Integer.valueOf(Custom_Messages__mdt.getInstance('Batch_Size_of_skedBiddingExpirationBatch').value__c));
    }

}