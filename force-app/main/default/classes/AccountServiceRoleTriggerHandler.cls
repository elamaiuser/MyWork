/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  12/05/2023				 Kishore Das		        Logic for HRP-11103 (Multiple BPLs if no overlap in effective date)
 *************************************************************************************************************************************************
*/
public class AccountServiceRoleTriggerHandler extends TriggerHandler{
    
    public override void beforeUpdate(){
       //Logic for HRP-11103
        AccountServiceRoleService.verifyValidBPLCountUpdate((List<Account_Service_Role__c>)trigger.old,
                                                      (List<Account_Service_Role__c>)trigger.new);
        //Logic for HRP-11103
    }
    
    public override void beforeInsert(){
        //Logic for HRP-11103
		AccountServiceRoleService.verifyValidBPLCountInsert((List<Account_Service_Role__c>)trigger.old,
                                                      (List<Account_Service_Role__c>)trigger.new);
        //Logic for HRP-11103
    }
    
    public override void afterUpdate(){
        system.debug('comes here2');
        
        AccountContactHistoryService.handleChangeEntry((Map<Id,Account_Service_Role__c>)trigger.oldMap, 
                                                       (List<Account_Service_Role__c>)trigger.new);
        
        
        /* The logic of updateCallListRecipientFlagOnOpp is moved to opportuinityContactRole Trigger Handler 
         * part of HRP-6219 
         * AccountServiceRoleService.updateCallListRecipientFlagOnOpp((Map<Id,Account_Service_Role__c>)trigger.oldMap, 
         * (List<Account_Service_Role__c>)trigger.new);
         */
         //HRP-9531 Update Account Contact_BPL__c field
         if(super.getTriggerMethodsToBypass().indexOf('updateBPLonAccount') == -1) {
            AccountServiceRoleService.updateBPLonAccount((List<Account_Service_Role__c>)trigger.new);
         }
         //Implemented for HRP-5860
         //AccountServiceRoleService.markContactAsInactive((Map<Id,Account_Service_Role__c>)trigger.oldMap,
          //                                             (List<Account_Service_Role__c>)trigger.new);
    }
    
    public override void afterInsert(){
        AccountContactHistoryService.handleChangeEntry((Map<Id,Account_Service_Role__c>)trigger.oldMap, 
                                                       (List<Account_Service_Role__c>)trigger.new);
        /* The logic of updateCallListRecipientFlagOnOpp is moved to opportuinityContactRole Trigger Handler 
         * part of HRP-6219 
         * AccountServiceRoleService.updateCallListRecipientFlagOnOpp(null, 
         * (List<Account_Service_Role__c>)trigger.new);
         */ 
         //HRP-9531 Update Account Contact_BPL__c field
         if(super.getTriggerMethodsToBypass().indexOf('updateBPLonAccount') == -1) {
            AccountServiceRoleService.updateBPLonAccount((List<Account_Service_Role__c>)trigger.new);
         }
    }
   public override void beforeDelete(){
       AccountContactHistoryService.handleAccountServiceRoleDelete((List<Account_Service_Role__c>)trigger.old);
    }
    public override void afterDelete(){
       //HRP-9531 Update Account Contact_BPL__c field
        if(super.getTriggerMethodsToBypass().indexOf('updateBPLonAccount') == -1) {
            AccountServiceRoleService.updateBPLonAccount((List<Account_Service_Role__c>)trigger.old);
        }
    }

}