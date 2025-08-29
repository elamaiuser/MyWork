
public class BSF_Batch_PopulateCORegionScheduler implements Schedulable {
    Decimal futureVersion;
    Boolean allowChaining;
    Integer batchSize;
    
    public BSF_Batch_PopulateCORegionScheduler(Decimal futureVersion, Boolean allowChaining, Integer batchSize){
        this.futureVersion = futureVersion;
        this.allowChaining = allowChaining;
        this.batchSize = batchSize;
    }
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BSF_Batch_PopulateCORegion(null, futureVersion, allowChaining),batchSize);
    }
}