public class OpportunitySplitTriggerHandler extends TriggerHandler {
  public override void beforeUpdate(){  
  
        if(super.getTriggerMethodsToBypass().indexOf('addTeamMemberPortfolio') == -1) {
			System.debug('OpportunitySplitTriggerHandler.beforeUpdate() - OpportunitySplitService.addTeamMemberPortfolio() Executing...');
			OpportunitySplitService.addTeamMemberPortfolio( (List<OpportunitySplit>)trigger.new);
		}else{
			System.debug('OpportunitySplitTriggerHandler.beforeUpdate() - OpportunitySplitService.addTeamMemberPortfolio() Bypassed');
		}
		
    }
    
    public override void beforeInsert(){

		if(super.getTriggerMethodsToBypass().indexOf('addTeamMemberPortfolio') == -1) {
			System.debug('OpportunitySplitTriggerHandler.beforeInsert() - OpportunitySplitService.addTeamMemberPortfolio() Executing...');
			OpportunitySplitService.addTeamMemberPortfolio( (List<OpportunitySplit>)trigger.new);
		}else{
			System.debug('OpportunitySplitTriggerHandler.beforeInsert() - OpportunitySplitService.addTeamMemberPortfolio() Bypassed');
		}
       
    }
    
    public override void afterInsert(){
		
        if(super.getTriggerMethodsToBypass().indexOf('allowSpecificProfileUsers') == -1) {
			System.debug('OpportunitySplitTriggerHandler.afterInsert() - OpportunitySplitService.allowSpecificProfileUsers() Executing...');
			OpportunitySplitService.allowSpecificProfileUsers( (List<OpportunitySplit>)trigger.new, null,null);
		}else{
			System.debug('OpportunitySplitTriggerHandler.afterInsert() - OpportunitySplitService.allowSpecificProfileUsers() Bypassed');
		}
    }
    
    public override void afterUpdate(){
		
        if(super.getTriggerMethodsToBypass().indexOf('allowSpecificProfileUsers') == -1) {
			System.debug('OpportunitySplitTriggerHandler.afterUpdate() - OpportunitySplitService.allowSpecificProfileUsers() Executing...');
			OpportunitySplitService.allowSpecificProfileUsers( (List<OpportunitySplit>)trigger.new, (Map<Id,OpportunitySplit>)trigger.oldMap,(Map<Id,OpportunitySplit>)trigger.newMap);
        }else{
			System.debug('OpportunitySplitTriggerHandler.afterUpdate() - OpportunitySplitService.allowSpecificProfileUsers() Bypassed');
		}
    }
}