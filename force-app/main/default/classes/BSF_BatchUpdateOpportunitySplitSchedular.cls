/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/21/2023				 Kishore Das		        Schedular class for the batch BSF_BatchUpdateOpportunitySplit(HRP-11168)

 *************************************************************************************************************************************************
*/

global class BSF_BatchUpdateOpportunitySplitSchedular implements schedulable{
	global integer batchSize = 200;
    
    global BSF_BatchUpdateOpportunitySplitSchedular(integer batchSize){
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    global void execute(SchedulableContext sc)
    {
        BSF_BatchUpdateOpportunitySplit batch = new BSF_BatchUpdateOpportunitySplit();
        database.executebatch(batch,batchSize);
    }
}