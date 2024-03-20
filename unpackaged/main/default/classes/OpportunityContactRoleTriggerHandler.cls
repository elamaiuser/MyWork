/*@Description: This class calls different Trigger methods from Service Class serving purposes in different trigger contexts

 * ***************************************************************************************************************************/

 /* Modification Log 
 * Date					     Developer Name			          Comments
  ******************************************************************************************************************
  11/28/2023				  Priti Jana			     Logic for HRP-11544
 *******************************************************************************************************************
*/

public class OpportunityContactRoleTriggerHandler extends TriggerHandler
{
    
    public override void beforeInsert()
    {
        system.debug('Entering beforeInsert@@@');
        OpportunityContactRoleService.insertOpportunitycontactRolePrimaryFlag((List<OpportunityContactRole>)trigger.new);
        OpportunityContactRoleService.updateCallListRecipientFlagOnOppOnInsert((List<OpportunityContactRole>)trigger.new);
        
    }
    public override void afterInsert()
    {
        system.debug('Entering afterInsert@@@');
        if(super.getTriggerMethodsToBypass().indexOf('populateDriveWorksheetData') == -1)
        {
        	OpportunityContactRoleService.populateDriveWorksheetData(null,(List<OpportunityContactRole>)trigger.new);
        }
        
        // HRP- 11544 --> Starts Here
        
        if(super.getTriggerMethodsToBypass().indexOf('updateDOCPrimaryContact') == -1)
        {
            System.debug('OpportunityContactRoleTriggerHandler.afterInsert() - OpportunityContactRoleService.updateDOCPrimaryContact() Executing...');
        	OpportunityContactRoleService.updateDOCPrimaryContact(NULL, (Map<Id,OpportunityContactRole>)trigger.newMap,'Insert');
        }
        else
        {
            System.debug('OpportunityContactRoleTriggerHandler.afterInsert() - OpportunityContactRoleService.updateDOCPrimaryContact() Bypassed');
        } 
        // HRP- 11544 --> Ends Here 
        
        system.debug('Exiting afterInsert@@@');
    }
    
    public override void beforeUpdate()
    {
        system.debug('Entering beforeUpdate@@@');
        OpportunityContactRoleService.updateOpportunitycontactRolePrimaryFlag((List<OpportunityContactRole>)trigger.new);
    }
    
    public override void afterUpdate()
    {
        system.debug('Entering afterUpdate@@@');
        OpportunityContactRoleService.updateOpportunitycontactRolePrimaryFlag((List<OpportunityContactRole>)trigger.new);
        OpportunityContactRoleService.updateCallListRecipientFlagOnOppOnInsert((List<OpportunityContactRole>)trigger.new);
        if(super.getTriggerMethodsToBypass().indexOf('populateDriveWorksheetData') == -1) {
        	OpportunityContactRoleService.populateDriveWorksheetData((Map<Id,OpportunityContactRole>)trigger.OldMap,(List<OpportunityContactRole>)trigger.new);
        }
        
        //HRP-10263
		if(super.getTriggerMethodsToBypass().indexOf('updateCallListRecipientFlagOnOppOnUpdate') == -1) {
            System.debug('OpportunityContactRoleTriggerHandler.afterUpdate() - OpportunityContactRoleService.updateCallListRecipientFlagOnOppOnUpdate() Executing...');
        	OpportunityContactRoleService.updateCallListRecipientFlagOnOppOnUpdate((List<OpportunityContactRole>)trigger.new,(Map<Id,OpportunityContactRole>)trigger.oldMap);
        }else{
            System.debug('OpportunityContactRoleTriggerHandler.afterUpdate() - OpportunityContactRoleService.updateCallListRecipientFlagOnOppOnUpdate() Bypassed');
        }
        
         // HRP- 11544 --> Starts Here 

        if(super.getTriggerMethodsToBypass().indexOf('updateDOCPrimaryContact') == -1)
        {
            System.debug('OpportunityContactRoleTriggerHandler.afterUpdate() - OpportunityContactRoleService.updateDOCPrimaryContact() Executing...');
        	OpportunityContactRoleService.updateDOCPrimaryContact((Map<Id,OpportunityContactRole>)trigger.oldMap, (Map<Id,OpportunityContactRole>)trigger.newMap,'Update');
        }
        else
        {
            System.debug('OpportunityContactRoleTriggerHandler.afterUpdate() - OpportunityContactRoleService.updateDOCPrimaryContact() Bypassed');
        } 

        // HRP- 11544 --> Ends Here 
    }
    
    public override void beforeDelete()
    {
        system.debug('Entering beforedelete@@@');
    }
    
      public override void afterDelete()
      {
            system.debug('Entering afterDelete@@@');
            OpportunityContactRoleService.updateCallListRecipientFlagOnOppOnDelete((List<OpportunityContactRole>)trigger.old);
            if(super.getTriggerMethodsToBypass().indexOf('populateDriveWorksheetData') == -1)
            {
                OpportunityContactRoleService.populateDriveWorksheetDataAfterDelete((List<OpportunityContactRole>)trigger.old);
            }
          
          // HRP-11544 --> Starts Here
          if(super.getTriggerMethodsToBypass().indexOf('updateDOCPrimaryContact') == -1)
          {
            System.debug('OpportunityContactRoleTriggerHandler.afterDelete() - OpportunityContactRoleService.updateDOCPrimaryContact() Executing...');
        	OpportunityContactRoleService.updateDOCPrimaryContact((Map<Id,OpportunityContactRole>)trigger.oldMap, NULL,'Delete');
          }
          else
          {
            System.debug('OpportunityContactRoleTriggerHandler.afterDelete() - OpportunityContactRoleService.updateDOCPrimaryContact() Bypassed');
          } 

           // HRP-11544 --> Ends Here
    }
}