/* @Description:1.
*               2. This is Triggered from OpportunityService.createRecruitmentTask
* **********************************************************************************************************************************************
* Modification Log 
*  Date                          Developer Name                 Comments
* ***********************************************************************************************************************************************
* 10/26/2023                     Balaji N              Logic for HRP-10788 (Created this Trigger)
************************************************************************************************************************************************
*/

trigger TaskPlatformEvent on Task_Platform_Event__e (after insert) 
{
    list<task> taskList = new list<task>();
    for(Task_Platform_Event__e tp : trigger.new)
    {
                task t = new task();
                t.RecordTypeId = tp.RecordTypeId__c;
                t.ActivityDate = tp.ActivityDate__c;
                t.OwnerId = tp.OwnerId__c;//part of ticket HRP-9562
                t.subject = tp.Subject__c;
                t.WhatId = tp.WhatId__c;
                taskList.add(t);
    }
    
    if(!taskList.isEmpty())
    {
        Database.SaveResult[] srList = Database.insert(taskList, false);
    }
    
}