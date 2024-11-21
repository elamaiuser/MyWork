public class ARCMarketMappingTriggerHandler extends TriggerHandler {
	public override void beforeUpdate(){}
            
    public override void beforeInsert(){   
        
    }
    
    public override void afterInsert(){        
        ARCMarketMappingService.updateAccountMarketFieldOnInsert( (List<ARC_Market_Mapping__c>)trigger.new );
    }
    
    public override void afterUpdate(){  
        ARCMarketMappingService.updateAccountMarketField( (List<ARC_Market_Mapping__c>)trigger.new, (Map<Id,ARC_Market_Mapping__c>)trigger.oldMap,(Map<Id,ARC_Market_Mapping__c>)trigger.newMap);
        
    }
}