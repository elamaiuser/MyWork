public class MarketingExceptionInvokable 
{
    @InvocableMethod
    public static void updateBloodDrive(List<Id> TaskID)
    {
        system.debug('TaskID## '+TaskID);
        List<Task> taskList = [select id,Publish_to_Call_Center__c,Send_Emails__c,Send_Mailers__c,Web_Scheduling_Enabled__c,WhatId,WhoId from Task where id IN: TaskID];
        system.debug('tasklist## '+taskList);
        List<id> opptyID = new List<id>();
        Map<id,Task> opptyIdTaskMap = new map<id,Task>();
        
        for(Task tsk : taskList)
        {
            opptyID.add(tsk.WhatId);
            opptyIdTaskMap.put(tsk.WhatId,tsk);
        }
        system.debug('opptyIdTaskMap## '+opptyIdTaskMap);
        List<opportunity> opptyList = [select id,is_template__c,Parent_Template_Id__c ,Publish_to_Call_Center__c,Send_Emails__c,Send_Mailers__c,Web_Scheduling_Enabled__c from opportunity where Parent_Template_Id__c IN: opptyID and Drive_date__c > :system.today() ];
        
        
        List<opportunity> opptyListToUpdate = new List<opportunity>();
        
        for (id oppId:opptyIdTaskMap.keyset())
        {
            Opportunity updatedOpp = new opportunity();
            updatedOpp.id=oppId;
            updatedOpp.Publish_to_Call_Center__c = opptyIdTaskMap.get(oppId).Publish_to_Call_Center__c;
            updatedOpp.Send_Emails__c = opptyIdTaskMap.get(oppId).Send_Emails__c;
            updatedOpp.Send_Mailers__c = opptyIdTaskMap.get(oppId).Send_Mailers__c;
            updatedOpp.Web_Scheduling_Enabled__c = opptyIdTaskMap.get(oppId).Web_Scheduling_Enabled__c;
            opptyListToUpdate.add(updatedOpp);
        }
             
        
        for(opportunity opp : opptyList)
        {
            id oppId = opp.Parent_Template_Id__c; 
            opp.Publish_to_Call_Center__c = opptyIdTaskMap.get(oppId).Publish_to_Call_Center__c;
            opp.Send_Emails__c = opptyIdTaskMap.get(oppId).Send_Emails__c;
            opp.Send_Mailers__c = opptyIdTaskMap.get(oppId).Send_Mailers__c;
            opp.Web_Scheduling_Enabled__c = opptyIdTaskMap.get(oppId).Web_Scheduling_Enabled__c;
            opptyListToUpdate.add(opp);
        }
        
        if(!opptyListToUpdate.isEmpty())
        {
            try
            {
                update opptyListToUpdate;
            }
            catch(exception expt)
            {
                BSF_Error_Log__c err = BSF_Utilities.getErrorLog(null,'MarketingExceptionInvokable',expt.getStackTraceString(),'Error','Error Updateing Opportunity',expt.getMessage());
                if(Limits.getDMLStatements() < Limits.getLimitDMLStatements()){
                    try{
                        insert err;
                    }catch(Exception excptn){
                        System.debug(excptn.getMessage()+excptn.getStackTraceString()+excptn.getLineNumber());
                    }
                }
            }
        }
    }
    
}