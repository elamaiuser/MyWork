public with sharing class UserTriggerHandler extends TriggerHandler{
    
    public override void beforeInsert(){
        //system.debug('entered111');
        if(super.getTriggerMethodsToBypass().indexOf('formatMobilePhone') == -1) {
            System.debug('UserTriggerHandler.beforeInsert() - userService.formatMobilePhone Executing...');
            userService.formatMobilePhone((List<User>) Trigger.new);
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        }else{
            System.debug('UserTriggerHandler.beforeInsert() - UserTriggerHandler.beforeInsert() Bypassed');
        }
    }
    
    public override void beforeUpdate(){
        system.debug('beforeupdateuser');
        if(super.getTriggerMethodsToBypass().indexOf('formatMobilePhone') == -1) {
            System.debug('UserTriggerHandler.beforeUpdate() - userService.formatMobilePhone Executing...');
            userService.formatMobilePhone((List<User>) Trigger.new);
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        }else{
            System.debug('UserTriggerHandler.beforeUpadte() - UserTriggerHandler.beforeInsert() Bypassed');
        }
    }
    
    public override void afterUpdate() {
        if(!checkRecursive.firstcall){
            if(super.getTriggerMethodsToBypass().indexOf('PublishEventForAssigningResourcesToUsers') == -1) {
                System.debug('UserTriggerHandler.afterUpdate() - userService.PublishEventForAssigningResourcesToUsers() Executing...');
                userService.PublishEventForAssigningResourcesToUsers((List<User>) Trigger.new);
            }
            else {
                System.debug('UserTriggerHandler.afterUpdate() - userService.PublishEventForAssigningResourcesToUsers() Bypassed');
            }
        }
    }    
}