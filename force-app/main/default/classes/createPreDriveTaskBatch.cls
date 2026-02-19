/**************************************************************************************
@ Component Name : createPreDriveTaskBatch
@ Developed By: Exavalu / ARC  
@ purpose: Creates Pre-Drive Security Task on closed opportunities
            having drive date within next 4 weeks to check
             if the site associated with the drive has security requirements
              so that DRD AM can ensure the security list is provided as needed.
***************************************************************************************
Story               Date           Modified by             Description 
=======================================================================================
HRP - 9562       04/26/2023        Kishore Das           If AM is not there , task owner should be a DM
                                                         If DM is not there , task owner should be an AS
                                                         If AS is not there , task owner should be the opp owner                                                          

HRP - 8030       05/18/2023        Priti Jana          	 Removed Extra check
                                                         for Pre-Drive Security Due date from start method
HRP - 12333	     03/22/2024		   Balaji N		   		 logic for HRP-12333
HRP - 12700	     08/14/2024		   Apurba Bhattacharjee	 HRP-12700 Add Drive Date to task list
**************************************************************************************/

global class createPreDriveTaskBatch implements Database.Batchable<sObject>
{
    
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        
        Date next4Weeks = System.today().addDays(28); 
        
        return Database.getQueryLocator([SELECT Id,Name FROM Opportunity
                                         WHERE drive_date__c >= today AND drive_date__c <=: next4Weeks
                                         AND StageName = 'Closed'
                                         AND Drive_Site__r.Sponsor_Security_Form_Required__c includes ('Pre-Drive')]);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope)
    {
        // Create a set to store opportunity Ids
        Set<Id> oppIds = new Set<Id>();

        // Create a list to store pre-existing tasks
        List<Task> preExistingSecurityTaskList = new List<Task>();

        // Create a list to store the tasks to be created
        List<Task> preDriveSecurityTaskList = new List<Task>();

        // Create a list to store drive service roles
        List<OpportunityContactRole> driveServiceRoleList = new List<OpportunityContactRole>();

        // Create a Map to store OpportunityTeamMembers by OpportunityId
        Map<Id, List<OpportunityTeamMember>> oppTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();

        for(Opportunity opp : scope)
        {
            oppIds.add(opp.Id);
        }

        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([select Id, OwnerId,Account_Manager__c,drive_date__c,                                                              
                                                              (select Contact.Name,Contact.Email from OpportunityContactRoles where Role =: BSF_Constants.SECURITY_LIST_RECIPIENT_ROLE Limit 1),
                                                              (Select Id from Tasks where Subject =: BSF_Constants.PRE_DRIVE_SECURITY_TASK Limit 1),  
                                                              Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c,Drive_Site__r.sked_Staff_List__c, 
                                                              Drive_Site__r.sked_Security_Directions__c,Drive_Site__r.Sponsor_Security_Form_Required__c
                                                              from opportunity where Id IN :oppIds]);


        // HRP - 9562 --> Start
        List<OpportunityTeamMember> allOpportunityTeamMembers = [SELECT Id, OpportunityId, TeamMemberRole, UserId
                                                                 FROM OpportunityTeamMember
                                                                 WHERE TeamMemberRole IN (:BSF_Constants.DISTRICT_MANAGER, :BSF_Constants.ACCOUNT_SPECIALIST)
                                                                 AND OpportunityId IN :oppIds
                                                                ];
        
        if(!allOpportunityTeamMembers.isEmpty())
        {
            for (OpportunityTeamMember oppteamMember : allOpportunityTeamMembers)
            {
                if (!oppTeamMembersMap.containsKey(oppteamMember.OpportunityId))
                {
                    oppTeamMembersMap.put(oppteamMember.OpportunityId, new List<OpportunityTeamMember>());
                }
                oppTeamMembersMap.get(oppteamMember.OpportunityId).add(oppteamMember);
            }
        }

        // HRP - 9562 --> End        

        for(opportunity oppObj : oppMap.values())
        {
            opportunity opp = new opportunity();
            opp = oppMap.get(oppObj.ID);  

            preExistingSecurityTaskList = opp.Tasks; // retrieving if any pre drive tasks already exist with this opp 
            driveServiceRoleList = opp.OpportunityContactRoles;  

            if(opp != NULL && preExistingSecurityTaskList.size() == 0)
            {                 
                Task preDriveSecurityTask = new Task();
                preDriveSecurityTask.subject = BSF_Constants.PRE_DRIVE_SECURITY_TASK;
                preDriveSecurityTask.priority = BSF_Constants.HIGH_PRIORITY_TASK;
                preDriveSecurityTask.Type = BSF_Constants.SECURITY_INFORMATION_COMPLETION;
                preDriveSecurityTask.whatId = opp.Id;
                preDriveSecurityTask.Drive_Date__c = opp.Drive_Date__c; //HRP-12700
                preDriveSecurityTask.ownerId = OpportunityService.getTaskOwner(opp, oppTeamMembersMap,Task_Reassignment_Matrix__mdt.getInstance('Security_Information_Completion').Assigned_To__c); //HRP-9562;//HRP-12333 added 3rd paarameter
                preDriveSecurityTask.ActivityDate = opp.Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c != NULL ? (opp.Drive_Date__c - Integer.ValueOf(opp.Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c)) : opp.Drive_Date__c;
                preDriveSecurityTask.Pre_Drive_Security_Due_Date__c = opp.Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c!= NULL ? opp.Drive_Site__r.sked_Pre_Drive_Security_Due_Date__c : NULL;
                preDriveSecurityTask.Staff_List__c = opp.Drive_Site__r.sked_Staff_List__c != NULL ? opp.Drive_Site__r.sked_Staff_List__c : null;
                preDriveSecurityTask.Description = opp.Drive_Site__r.sked_Security_Directions__c != null ? opp.Drive_Site__r.sked_Security_Directions__c : null;
                   
                if(driveServiceRolelist.size()>0)
                {
                    preDriveSecurityTask.Security_list_Recipient_Email__c = driveServiceRolelist[0].Contact.Email;
                    preDriveSecurityTask.Security_list_Recipient_Name__c = driveServiceRolelist[0].Contact.Name;
                }
                preDriveSecurityTaskList.add(preDriveSecurityTask);
            }
        }
        
        if(preDriveSecurityTaskList.size() > 0)
        {             
            Database.SaveResult[] srList = Database.Insert(preDriveSecurityTaskList, false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'Pre-Drive Security Task','createPreDriveTaskBatch','execute','Error','Error in Task Creation');
            InsertBsfErrorLog.insertBsfErrors(logList);  
        }
    }      
    
    
    global void finish(Database.BatchableContext bc)
    {
        
    }    
    
}