public with sharing class OrderTriggerHandler extends TriggerHandler {
    public override void beforeUpdate(){
        OrderService.setDefaultMaterialRecipient((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderService.validateMaterialrecipent((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderService.setOrderBudget((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderService.setPublicitySubmiter((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderService.checkOrderBudgetwithProduct((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderService.setPublicityApproved((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
    }
    
    public override void beforeInsert(){
        OrderService.setDefaultMaterialRecipient((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderService.setOrderBudget((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
        OrderService.calculateOrderDueDate((List<Order>)Trigger.new);
    }
    
    public override void afterUpdate(){
        
        
    }
    
    
    public override void afterInsert(){
        OrderService.validateMaterialrecipent((List<Order>)Trigger.old, (List<Order>)Trigger.new,(Map<Id,Order>)trigger.oldMap, (Map<Id,Order>)Trigger.newMap);
    }
    
    public override void afterDelete(){
        
    }
}