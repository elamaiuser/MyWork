/*@Description: 1. This class is called from invocable method queueOpportunityCreation in PlanADriveUtilityClass to create opportunity
* ***************************************************************************************************************************************************************/
/*@Modification Log 
* 
* Date					Developer Name			Comments
* ***************************************************************************************************************************************************************************
* 10/24/2024			Balaji N				Logic for HRP-13489 Class created
*****************************************************************************************************************************************************************************
*/
//HRP-13489 Start
public class BSF_Queueable_CreateRecurringOpp implements Queueable
{
    public List<Opportunity> oppList = new List<Opportunity>();
    public BSF_Queueable_CreateRecurringOpp(List<Opportunity> oppFlowList)
    {
        oppList.addAll(oppFlowList);
        system.debug('oppList BSF_Queueable_CreateRecurringOpp'+oppList);
    }
	public void execute(QueueableContext context)
    {
        system.debug('execute'+this.oppList);
        List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(Database.Insert(this.oppList,false), 'Recurring Drive creation','Create New Recurring Mobile Drive','execute','Error','Error in Opportunity Creation');
        InsertBsfErrorLog.insertBsfErrors(logList);
    }
}
//HRP-13489 End