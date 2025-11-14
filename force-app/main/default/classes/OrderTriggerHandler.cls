/**
 * @Description:  This class is called from Order trigger.

 * Modification Log 
 * Date					     Developer Name			     Comments
 ********************************************************************************************************************************************************************
 * 04/25/2024				 Barnojit Sharma			 Restrict to one (Publicity) Order per opportunity(HRP-11307)
 * 08/07/2024				 Barnojit Sharma			 Publicity Material Ordering at template level(HRP-12664)
 * 12/07/2024                Ankit Kundu                 Publicity Material Ordering at template level(HRP-12664)
 *********************************************************************************************************************************************************************
**/
public with sharing class OrderTriggerHandler extends TriggerHandler {
    public static boolean bypassDeleteValidation = FALSE;
    public override void beforeUpdate(){
        /*
        * HRP-12664 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('templateOrderValidation') == -1) {
            OrderService.templateOrderValidation((List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('OrderProductValidation') == -1) {
            OrderService.OrderProductValidation((Map<Id,Order>)trigger.newMap,(Map<Id,Order>)trigger.oldMap);
        }
        /*if(super.getTriggerMethodsToBypass().indexOf('validateExpiredProductsOnSubmit') == -1) {
            OrderService.validateExpiredProductsOnSubmit((List<Order>)Trigger.new);
        }*/
        /*
        * HRP-12664 changes ends here
        */
        if(super.getTriggerMethodsToBypass().indexOf('setDefaultMaterialRecipient') == -1) {
            OrderService.setDefaultMaterialRecipient((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('validateMaterialrecipent') == -1) {
            OrderService.validateMaterialrecipent((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('setOrderBudget') == -1) {
            OrderService.setOrderBudget((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('setPublicitySubmiter') == -1) {
            OrderService.setPublicitySubmiter((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('checkOrderBudgetwithProduct') == -1) {
            OrderService.checkOrderBudgetwithProduct((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('setPublicityApproved') == -1) {
            OrderService.setPublicityApproved((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
    }
    
    public override void beforeInsert(){
        /*
        * HRP-11307 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('restrictOrderPerOpportunity') == -1) {
            OrderService.restrictOrderPerOpportunity((List<Order>)Trigger.new);
        }
        /*
        * HRP-11307 changes ends here
        */
         /*
        * HRP-12664 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('templateOrderValidation') == -1) {
            OrderService.templateOrderValidation((List<Order>)Trigger.new,null);
        }
        /*
        * HRP-12664 changes ends here
        */
        if(super.getTriggerMethodsToBypass().indexOf('setDefaultMaterialRecipient') == -1) {
            OrderService.setDefaultMaterialRecipient((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('setOrderBudget') == -1) {
            OrderService.setOrderBudget((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('calculateOrderDueDate') == -1) {
            OrderService.calculateOrderDueDate((List<Order>)Trigger.new);
        }
    }
    
    public override void afterUpdate(){
        
        
    }
    
    
    public override void afterInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('validateMaterialrecipent') == -1) {
            OrderService.validateMaterialrecipent((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        }
    }
    
    public override void beforeDelete(){
        /*
        * HRP-11307 changes starts here
        */ 
            if(super.getTriggerMethodsToBypass().indexOf('restrictOrderDeletion') == -1) {
                BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('Order',(List<Order>)Trigger.old);
            }
        
        /*
        * HRP-11307 changes ends here
        */
    }
}