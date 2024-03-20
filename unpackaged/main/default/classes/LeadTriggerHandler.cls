/* 
 * @description: This class is called from Lead trigger.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 03/08/2023				 Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572--> Deleted)
 * 10/03/2023                Priti Jana               Restricting non-admin users from Portfolio deletion (Part of HRP-HRP-10115)
 * 20/10/2023                Krapy Tuli                Logic for HRP-10880 (Update Leads to consume New Taxonomy - Geo Realignment)
 ************************************************************************************************************************************************
*/


public class LeadTriggerHandler extends TriggerHandler{
    
    private final string logTag = '[LeadTriggerHandler]';
    
    public override void beforeUpdate(){
        LeadService.setLeadTerritory((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap);

    }
     
    public override void beforeInsert(){
        LeadService.setLeadTerritory((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap);
    }
        
    public override void afterUpdate(){
        LeadService.checkForArcRegionChange((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap); //HRP-10880
        LeadService.setAccountRecordType((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap);
        LeadService.convertToOpportunities((Map<Id,Lead>)trigger.oldMap, (List<Lead>)trigger.new);
        LeadService.createTimelineEvents((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap, 'UPDATE');
 		if(super.getTriggerMethodsToBypass().indexOf('sendQueueAssignmentNotifications') == -1) {
          LeadService.sendQueueAssignmentNotifications((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap);
        }        //LeadService.handleConversion((List<Lead>)trigger.new);
        //AS-012902->SYSTEM: Presenting DRD AM Campaign pick list when creating lead 
        LeadService.createOrUpdateCampaignMember((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap,(Map<Id,Lead>)trigger.newMap, 'UPDATE');
        LeadService.standardizeAddress((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap, (Map<Id,Lead>)trigger.newMap,'UPDATE');

    }
 
    public override void afterInsert(){
        LeadService.convertToOpportunities((Map<Id,Lead>)trigger.oldMap, (List<Lead>)trigger.new);
        LeadService.createTimelineEvents((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap, 'INSERT');
        if(super.getTriggerMethodsToBypass().indexOf('sendAutoResponseEmail') == -1) {
        	LeadService.sendAutoResponseEmail((List<Lead>)trigger.new);
        }
         //AS-012902->SYSTEM: Presenting DRD AM Campaign pick list when creating lead 
        LeadService.createOrUpdateCampaignMember((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap,(Map<Id,Lead>)trigger.newMap, 'INSERT');
        LeadService.standardizeAddress((List<Lead>)trigger.new,(Map<Id,Lead>)trigger.oldMap, (Map<Id,Lead>)trigger.newMap,'INSERT');
    }
    
    public override void beforeDelete()
    {
        //HRP-10115 --> Starts here
        if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1) {
            System.debug('LeadTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Executing...');
            BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('Lead', (List<Lead>)trigger.old);
    }
    else{
            System.debug('LeadTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Bypassed');
        }
        //HRP-10115 --> Ends here
    }
}