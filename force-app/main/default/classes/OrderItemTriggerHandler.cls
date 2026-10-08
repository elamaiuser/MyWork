public class OrderItemTriggerHandler extends TriggerHandler {

    public override void beforeUpdate() {
        if(super.getTriggerMethodsToBypass().indexOf('validateProductMaterialRecipient') == -1) {
            OrderItemTriggerService.validateProductMaterialRecipient((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('calculateBudgetforProductsProjected') == -1) {
            OrderItemTriggerService.calculateBudgetforProductsProjected((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        }
    }
    
    public override void beforeInsert() {
        if(super.getTriggerMethodsToBypass().indexOf('validateProductMaterialRecipient') == -1) {
            OrderItemTriggerService.validateProductMaterialRecipient((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        }

        if(super.getTriggerMethodsToBypass().indexOf('calculateBudgetforProductsProjected') == -1) {
            OrderItemTriggerService.calculateBudgetforProductsProjected((List<OrderItem>)Trigger.old, (List<OrderItem>)Trigger.new,(Map<Id,OrderItem>)trigger.oldMap, (Map<Id,OrderItem>)Trigger.newMap);
        }

        if(super.getTriggerMethodsToBypass().indexOf('checkZipCodeOnOppToAddProduct') == -1) {
            OrderItemTriggerService.checkZipCodeOnOppToAddProduct((List<OrderItem>)Trigger.New);   
        }

        // HRP - 10307 Starts Here -->
        if(super.getTriggerMethodsToBypass().indexOf('validateOneThemePerOrder') == -1) {
            OrderItemTriggerService.validateOneThemePerOrder((List<OrderItem>)Trigger.New);            
        }
        // HRP - 10307 Ends Here -->

        // HRP-12664 Start -->
        if(super.getTriggerMethodsToBypass().indexOf('validateProductEndDate') == -1) {
            OrderItemTriggerService.validateProductEndDate((List<OrderItem>)Trigger.New);            
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('validatedProductToOrderItem') == -1) {
            OrderItemTriggerService.validatedProductToOrderItem((List<OrderItem>)Trigger.New);            
        }
        // HRP-12664 End -->
        
        system.debug('Exiting beforeInsert Trigger');
        
    }
    
    public override void afterUpdate() {}
    
    
    public override void afterInsert() {}
    
}