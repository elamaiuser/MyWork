/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/26/2023				 Kishore Das		        Schedular class for the batch BSF_BatchCalendarBuildStatusUpdate(HRP-10887)

 *************************************************************************************************************************************************
*/
global class BSF_BatchCalendarBuildStatusSchedular implements schedulable{
	global integer batchSize = 200;
    
    global BSF_BatchCalendarBuildStatusSchedular(integer batchSize){
        if(batchSize!=null)
        {
            this.batchSize=batchSize;
        }
    }
    global void execute(SchedulableContext sc)
    {
        BSF_BatchCalendarBuildStatusUpdate batch = new BSF_BatchCalendarBuildStatusUpdate();
        database.executebatch(batch,batchSize);
    }
}