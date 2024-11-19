/*@Description: 1. This class contains invocable method to create opportunity through Queueable class from the Flow Create_New_Recurring_Mobile_Drive
* ***************************************************************************************************************************************************************/
/*@Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 10/24/2024			Balaji N				Logic for HRP-13489 Class created
*****************************************************************************************************************************************************************************
*/
//HRP-13489 Start
public class PlanADriveUtilityClass 
{
    @InvocableMethod(label='Queue Opportunity Creation' description='Break the transaction by invoking a queueable Apex')
    public static void queueOpportunityCreation(List<List<Opportunity>> oppList)
    {
        List<Id> joIdList = new List<Id>();
        system.debug('oppList'+oppList);
        if(!oppList.isEmpty())
        {
            List<Opportunity> oppToInsertList = oppList[0];
            joIdList.add(System.enqueueJob(new BSF_Queueable_CreateRecurringOpp(oppToInsertList)));
        }
        
    }
}
//HRP-13489 End