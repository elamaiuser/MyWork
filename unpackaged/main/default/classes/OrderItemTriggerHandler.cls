public class OrderItemTriggerHandler extends TriggerHandler{
    public override void beforeUpdate(){
        OrderItemTriggerService.validateProductMaterialRecipient((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
      //  OrderItemTriggerService.calculateBudgetforProductsProjected((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        if(super.getTriggerMethodsToBypass().indexOf('calculateBudgetforProductsProjected') == -1) {
                System.debug('OrderItemTriggerService.beforeUpdate() - OrderItemTriggerService.calculateBudgetforProductsProjected() Executing...');
                OrderItemTriggerService.calculateBudgetforProductsProjected((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        }
        else{
                System.debug('OrderItemTriggerService.beforeUpdate() - OrderItemTriggerService.calculateBudgetforProductsProjected() Bypassed');
            }
    }
    
    public override void beforeInsert(){
        OrderItemTriggerService.validateProductMaterialRecipient((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        OrderItemTriggerService.calculateBudgetforProductsProjected((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        OrderItemTriggerService.checkZipCodeOnOppToAddProduct((List<OrderItem>)Trigger.New);   
        
        // HRP - 10307 Starts Here -->
        if(super.getTriggerMethodsToBypass().indexOf('validateOneThemePerOrder') == -1)
        {
            System.debug('OrderItemTriggerService.beforeInsert() - OrderItemTriggerService.validateOneThemePerOrder() Executing...');
            OrderItemTriggerService.validateOneThemePerOrder((List<OrderItem>)Trigger.New);            
        }
        else
        {
            System.debug('OrderItemTriggerService.beforeInsert() - OrderItemTriggerService.validateOneThemePerOrder() Bypassed');            
        }
       
        // HRP - 10307 Ends Here -->
        
        system.debug('Exiting beforeInsert Trigger');
        
    }
    
    public override void afterUpdate(){
        
        
    }
    
    
    public override void afterInsert(){
        
        
    }
    
}