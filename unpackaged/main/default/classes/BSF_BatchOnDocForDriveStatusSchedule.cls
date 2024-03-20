/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/26/2023				 Kishore Das		        Schedular class for the batch BSF_BatchOnDocForDriveStatusLookUp(HRP-11605)

 *************************************************************************************************************************************************
*/
global class BSF_BatchOnDocForDriveStatusSchedule implements schedulable{
	global integer batchSize = 200;
    public BSF_BatchOnDocForDriveStatusSchedule(integer batchSize)
    {
         if(batchSize!=0)
        {
            this.batchSize=batchSize;
        }
    }
    global void execute(SchedulableContext sc)
    {
        BSF_BatchOnDocForDriveStatusLookUp batch = new BSF_BatchOnDocForDriveStatusLookUp();
        database.executebatch(batch,batchSize);
    }
}