/* @Description: This class is called from Account trigger to serve different functionalities in different trigger contexts for Account Object.
 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 08/06/2023			     Kishore Das			  Logic for HRP-10085 (It changes all the associated opportunities/templates name when account internal name changes,also changes related drives on calendar name when account name changes.
 																For site, when room name/site building name changes the related opportunity/template/drives on calendar name changes)

 * 31/07/2023				 Barnojit Sharma		  Phone Numbers must be limited to 10 Numbers (Logic for HRP-10394)
 * 03/08/2023				 Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572 --> Deleted)
 * 09/18/2023				 Balaji N				  Logic for HRP-10878(Method call:AccountService.setZipcodeChang)
 * 10/03/2023				 Priti Jana				  Logic for HRP-10115 (usage of utility method)
 * 02/06/2024				 Priti Jana				  Logic for HRP-9520
 * 10/29/2024			     Barnojit Sharma		  Post Drive Analysis task Enhancements. (Logic for HRP-12142)
 ************************************************************************************************************************************************
*/
/**
* AS-012769-SYSTEM: Mapping Converted Lead Fields to the Account
* */
public with sharing class AccountTriggerHandler extends TriggerHandler {
    public static Boolean hasAccountMergePermission = FeatureManagement.checkPermission('Account_Merge_Custom_Permission');
    
    public override void beforeUpdate() {
        
        //HRP-10878 start
        if(!system.isFuture()) AccountService.setZipcodeChange((List<Account>)trigger.new,(Map<Id, Account>)trigger.oldMap);
        //HRP-10878 End
        
        if(!checkRecursive.firstcall && !AccountTeamMemberHelper.skipAccountTrigger) {
            checkRecursive.firstcall = true;
            if(super.getTriggerMethodsToBypass().indexOf('validationForDaysOfWeekDeclined') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.validationForDaysOfWeekDeclined() Executing...');
                AccountService.validationForDaysOfWeekDeclined((Map<Id, Account>)trigger.oldMap, (List<Account>)trigger.new);
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('customNotofocationForDaysOfWeekDeclined') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.customNotofocationForDaysOfWeekDeclined() Executing...');
                AccountService.customNotofocationForDaysOfWeekDeclined((List<Account>)trigger.new,(Map<Id, Account>)trigger.oldMap);
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('updateAccountType') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.updateAccountType() Executing...');
                AccountService.updateAccountType((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                             (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('createNotesOnAccountStrategyupdate') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.createNotesOnAccountStrategyupdate() Executing...');
                AccountService.createNotesOnAccountStrategyupdate((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                                              (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('populateMarketOnAccount') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.populateMarketOnAccount() Executing...');
                AccountService.populateMarketOnAccount((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                                   (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);   
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('updateNationalNameStatus') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.updateNationalNameStatus() Executing...');
                AccountService.updateNationalNameStatus((List<Account>)Trigger.new, (Map<Id,Account>)Trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
            }
           
            //Logic for HRP-10394 **Starts here**
            if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - FormatPhoneNumbers Executing...');
                FormatPhoneNumbers.format();
            }
            //Logic for HRP-10394 **Ends here**
            
            // HRP- 9520/11951 --> Starts Here
            if(super.getTriggerMethodsToBypass().indexOf('setBusinessPlanningDateAndUser') == -1) {
            	System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.setBusinessPlanningDateAndUser() Executing...');
            	AccountService.setBusinessPlanningDateAndUser((List<Account>)trigger.new , (Map<Id,Account>)trigger.oldMap);       
        	}
            // HRP- 9520/11951 --> Ends Here
        }  
    }
    
    public override void beforeInsert() {
        checkRecursive.isNewlyCreatedAccount = true;
        
        if(super.getTriggerMethodsToBypass().indexOf('updateAccountType') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateAccountType() Executing...');
            AccountService.updateAccountType((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                         (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('createNotesOnAccountStrategyupdate') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.createNotesOnAccountStrategyupdate() Executing...');
            AccountService.createNotesOnAccountStrategyupdate((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                                          (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('populateMarketOnAccount') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.populateMarketOnAccount() Executing...');
            AccountService.populateMarketOnAccount((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                           (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('updateAccStatusAndInternalName') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateAccStatusAndInternalName() Executing...');
            AccountService.updateAccStatusAndInternalName((List<Account>)Trigger.new);
                                          
        }
        
        /* 
        * HRP-9585 changes starts here
        * @Description: Calling updateNationalName() method to New Accounts autopopulate "ADD" to National Name field.
    	* @Date: 02/05/2023
        */
        if(super.getTriggerMethodsToBypass().indexOf('updateNationalName') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateNationalName() Executing...');
            AccountService.updateNationalName((List<Account>)Trigger.new);
                                          
        }
        //HRP-9585 changes Ends
        
        /* 
        * HRP-9818 changes starts here
        * @Description: Calling checkUserProfile() method to check if DRD Users are tring to create Fixed Site Account.
    	* @Date: 02/05/2023
        */
        if(super.getTriggerMethodsToBypass().indexOf('checkUserProfile') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.checkUserProfile() Executing...');
            AccountService.checkUserProfile((List<Account>)Trigger.new);
                                          
        }
        // HRP-9818 changes Ends
        
        //Logic for HRP-10394 **Starts here**
        if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - FormatPhoneNumbers Executing...');
            FormatPhoneNumbers.format();
        }
        //Logic for HRP-10394 **Ends here**
    }
    
    public override void afterUpdate() {
        if(!AccountTeamMemberHelper.skipAccountTrigger) {
            if(super.getTriggerMethodsToBypass().indexOf('standardizeBillingAddress') == -1) {
                System.debug('AccountTriggerHandler.afterUpdate() - AccountService.standardizeBillingAddress() Executing...');
                AccountService.standardizeBillingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'UPDATE');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('standardizeShippingAddress') == -1) {
                System.debug('AccountTriggerHandler.afterUpdate() - AccountService.standardizeShippingAddress() Executing...');
                AccountService.standardizeShippingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'UPDATE');
            }
            
            //HRP-10085
            if(super.getTriggerMethodsToBypass().indexOf('updateDivesOnCalenderForAccountInternalNameChange') == -1) {
                System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateDivesOnCalenderForAccountInternalNameChange() Executing...');
                AccountService.updateDivesOnCalenderForAccountInternalNameChange((List<Account>)trigger.new, (Map<Id,Account>)trigger.oldMap);
            }
            
            //HRP-10085    
            if(super.getTriggerMethodsToBypass().indexOf('updateTemplateBloodDriveOpportunitiesForAccountNameChange') == -1) {
                System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateTemplateBloodDriveOpportunitiesForAccountNameChange() Executing...');
                AccountService.updateTemplateBloodDriveOpportunitiesForAccountNameChange((List<Account>)trigger.new, (Map<Id,Account>)trigger.oldMap);
            }  
            
            if(super.getTriggerMethodsToBypass().indexOf('createAccountTeamMembers') == -1) {
                System.debug('AccountTriggerHandler.afterUpdate() - AccountService.createAccountTeamMembers() Executing...');
                AccountService.createAccountTeamMembers((List<Account>)trigger.new,(Map<Id,Account>)trigger.newMap,'',null,new Map<String,AccountTeamMember>());        
            }
                
            if(super.getTriggerMethodsToBypass().indexOf('updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync') == -1) {
                System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync() Executing...');
                AccountService.updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync((List<Account>)trigger.new, (Map<Id, Account>)trigger.oldMap);       
            }
            
            // HRP- 12142 --> Starts Here
            if(super.getTriggerMethodsToBypass().indexOf('updateTaskChecklist') == -1) {
            	System.debug('AccountTriggerHandler.afterUpdate() - BSFTaskChecklistTriggerHandler.updateTaskChecklist() Executing...');
            	BSFTaskChecklistTriggerHandler.updateTaskChecklist((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap); 
            }
            // HRP- 12142 --> Ends Here
       }

        if(super.getTriggerMethodsToBypass().indexOf('handleTaskPlanningPathChange') == -1) {
            AccountService.handleTaskPlanningPathChange((List<Account>) trigger.new, (Map<Id, Account>) trigger.oldMap);    
        }  
    }
    
    public override void afterInsert() {
        if(super.getTriggerMethodsToBypass().indexOf('standardizeBillingAddress') == -1) {
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.standardizeBillingAddress() Executing...');
            AccountService.standardizeBillingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'INSERT');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('standardizeShippingAddress') == -1) {
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.standardizeShippingAddress() Executing...');
            AccountService.standardizeShippingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'INSERT');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('createAccountTeamMembers') == -1) {
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.createAccountTeamMembers() Executing...');
            AccountService.createAccountTeamMembers((List<Account>)trigger.new,(Map<Id,Account>)trigger.newMap,'',null,new Map<String,AccountTeamMember>());        
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('initializeAccountTaskConfigs') == -1) {
            BSF_TaskPlanningService.initializeAccountTaskConfigs((List<Account>) trigger.new);    
        }  
    }
    
    public override void beforeDelete() {	
        // HRP-10115 --> starts Here
        if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1) {
            System.debug('AccountTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Executing...');
            BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('Account',(List<Account>)trigger.old);
        }
        // HRP-10115 --> Ends Here
    }
}