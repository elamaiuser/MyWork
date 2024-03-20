/* 
 * @description: This class is called from BsfPortfolio trigger.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 03/08/2023				 Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572 --> Deleted)
 * 10/03/2023                Priti Jana               Restricting non-admin users from Portfolio deletion (Part of HRP-HRP-10115)
 ************************************************************************************************************************************************
*/

public class BsfPortfolioTriggerHandler extends TriggerHandler {
    public override void beforeUpdate(){
        BsfPortfolioService.revertStartDateOnUpdate(Trigger.new,(Map<Id,BSF_Portfolio__c>)Trigger.oldMap);
    }
    public override void afterUpdate()
    {
        BsfPortfolioService.updatePortfolioAssignments(Trigger.new,(Map<Id,BSF_Portfolio__c>)Trigger.newMap,(Map<Id,BSF_Portfolio__c>)Trigger.oldMap);
    }
    
    public override void beforeInsert(){
    }
    
    public override void afterInsert(){
        BsfPortfolioService.createTaskForAMOrRAOnPortfolioCreation(Trigger.new);
    }
    
    public override void afterDelete(){
    }
    
    public override void beforeDelete()
    {
        // Part of HRP-10115 --> Starts Here
        if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1) {
            System.debug('BsfPortfolioTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Executing...');
            BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('BSF_Portfolio__c', (List<BSF_Portfolio__c>)trigger.old);
    }
    else{
            System.debug('BsfPortfolioTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Bypassed');
        }
    // Part of HRP-10115 --> Ends Here
    }
}