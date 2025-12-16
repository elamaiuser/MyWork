public class BSF_Batch_BSFPortfolioScheduler implements Schedulable {
    String recordTypeName;
    Decimal futureVersion;
    Boolean runAssignmentBatch;
    Boolean allowChaining;
    Integer batchSize;
    public BSF_Batch_BSFPortfolioScheduler(
        String recordTypeName, 
        Decimal futureVersion,
        Boolean runAssignmentBatch, 
        Boolean allowChaining, 
        Integer batchSize){

        this.recordTypeName = recordTypeName;
        this.futureVersion = futureVersion;
        this.runAssignmentBatch = runAssignmentBatch;
        this.allowChaining = allowChaining;
        this.batchSize = batchSize;
    }
    public void execute(SchedulableContext sc){
        Database.executeBatch(new BSF_Batch_BSFPortfolio(recordTypeName, futureVersion, null, null, runAssignmentBatch, allowChaining),batchSize);
    }
}