public class DriveMarketingProgramTriggerHandler extends TriggerHandler{

	public override void beforeUpdate(){
		
        
    }
    
    public override void beforeInsert(){
        
    }
    
    public override void afterUpdate(){
        
        
    }
    
    
   public override void afterInsert(){
      DriveMarketingProgramTriggerService.setOrderBudget((List<Drive_Marketing_Programs__c>)Trigger.old, (List<Drive_Marketing_Programs__c>)Trigger.new,(Map<Id,Drive_Marketing_Programs__c>)trigger.oldMap, (Map<Id,Drive_Marketing_Programs__c>)Trigger.newMap);
        
    } 
    
   // public override void afterDelete(){
        
  //  }
    
    
 //   public static void DriveMarketingProgramValidations(List<Drive_Marketing_Programs__c > oldList, List<Drive_Marketing_Programs__c > newList,
 //                                                       Map<Id,Drive_Marketing_Programs__c > oldMap,Map<Id,Drive_Marketing_Programs__c > newMap)
  //  {
        
  //      System.debug('Entered method DriveMarketingProgramValidations');
        
//   for(Drive_Marketing_Programs__c newDMC : newList){
            
           // if(newDMC.Name.contains('BHQ')){ 
                
//            }
//        }
//    }
               
              
}