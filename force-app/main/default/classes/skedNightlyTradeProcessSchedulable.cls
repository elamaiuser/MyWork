public class skedNightlyTradeProcessSchedulable implements Schedulable {
    public skedNightlyTradeProcessSchedulable() {}

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new skedNightlyTradeProcessBatch(), 10);
    }
}