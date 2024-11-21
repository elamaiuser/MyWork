public class InsertBsfErrorLog 
{
	public static void insertBsfErrors(List<BSF_Error_Log__c> logList)
    {
        if(!logList.isEmpty())
        {
           Database.SaveResult[] srList = Database.insert(logList,false);
             
           for (Database.SaveResult sr : srList) {
           		if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred in AccountTeamMemberService Insert.'+err.getStatusCode() + ': ' + err.getMessage());                    
                    }	
                }
           }
        }
    }
}