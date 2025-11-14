/* Modification Log 
 * 
 * Date					   Developer Name			    Comments
 * ****************************************************************************
 * 10/18/2024               Priti Jana              Logic for HRP-9815
 * 12/26/2024               Priti Jana              Logic for HRP-13882
 ******************************************************************************
*/

public with sharing class UserTriggerHandler extends TriggerHandler{
    
    public override void beforeInsert() {
        checkRecursive.firstCallForRecordCreation = TRUE; //HRP-13882
        if(super.getTriggerMethodsToBypass().indexOf('formatMobilePhone') == -1) {
            System.debug('UserTriggerHandler.beforeInsert() - userService.formatMobilePhone Executing...');
            userService.formatMobilePhone((List<User>) Trigger.new);
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        } else {
            System.debug('UserTriggerHandler.beforeInsert() - UserTriggerHandler.beforeInsert() Bypassed');
        }

    }
    
    public override void beforeUpdate() {
        if(super.getTriggerMethodsToBypass().indexOf('formatMobilePhone') == -1) {
            System.debug('UserTriggerHandler.beforeUpdate() - userService.formatMobilePhone Executing...');
            userService.formatMobilePhone((List<User>) Trigger.new);
            System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        } else {
            System.debug('UserTriggerHandler.beforeUpadte() - userService.formatMobilePhone Bypassed');
        }
    }
    
    public override void afterUpdate() {
        if(!checkRecursive.firstcall) {
            if(super.getTriggerMethodsToBypass().indexOf('PublishEventForAssigningResourcesToUsers') == -1) {
                System.debug('UserTriggerHandler.afterUpdate() - userService.PublishEventForAssigningResourcesToUsers() Executing...');
                userService.PublishEventForAssigningResourcesToUsers((List<User>) Trigger.new);
            }
            else {
                System.debug('UserTriggerHandler.afterUpdate() - userService.PublishEventForAssigningResourcesToUsers() Bypassed');
            }

            //HRP-9815 --> Starts Here
            if(super.getTriggerMethodsToBypass().indexOf('updateDrdRepContactOnOpRecordUponPhoneChange') == -1) {
                System.debug('UserTriggerHandler.afterUpdate() - userService.updateDrdRepContactOnOpRecordUponPhoneChange Executing...');
                userService.updateDrdRepContactOnOpRecordUponPhoneChange((List<User>) Trigger.new, (Map<Id, User>) Trigger.oldMap);
            } else {
                System.debug('UserTriggerHandler.afterUpdate() - userService.updateDrdRepContactOnOpRecordUponPhoneChange Bypassed');
            }
            //HRP-9815 --> Ends Here
        }
    }    
}