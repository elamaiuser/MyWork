//@Description: This platform event trigger logs error in BSF_Error_Log__c object
/*
* Modification Log
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 08/05/2024                   Balaji N               	Logic for HRP-13028 created
*************************************************************************************************************************************************
*/
trigger createBsfErrorLogs on Error_Log_Event__e(after insert) 
{
    List<BSF_Error_Log__c> bsfErrList = new List<BSF_Error_Log__c>();
    for (Error_Log_Event__e event : Trigger.New) 
    {     
        BSF_Error_Log__c err = BSF_Utilities.getErrorLog('Exception Delete','Account Portfolio Assignment','HandleAccExceptionDelete','Error','Id: '+event.RecordId__c+' error: '+event.Error_Message__c,'Error in Deleting exception');
        err.Functionality__c='ED-'+system.now()+string.valueof(event.RecordId__c).substring(10,18);
        bsfErrList.add(err);      
    }
    
    if(!bsfErrList.isEmpty())
    {
        insert bsfErrList;
    }
}