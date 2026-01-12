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
public with sharing class AccountTriggerHandler extends TriggerHandler{
    public static Boolean hasAccountMergePermission = FeatureManagement.checkPermission('Account_Merge_Custom_Permission');
    
    public override void beforeUpdate(){
        System.debug('beforeUpdate AccountTeamMemberHelper.skipAccountTrigger: '+AccountTeamMemberHelper.skipAccountTrigger);
        //HRP-10878 start
        if(!system.isFuture())
        AccountService.setZipcodeChange((List<Account>)trigger.new,(Map<Id, Account>)trigger.oldMap);
        //HRP-10878 End
        if(!checkRecursive.firstcall && !AccountTeamMemberHelper.skipAccountTrigger){
            checkRecursive.firstcall = true;
            if(super.getTriggerMethodsToBypass().indexOf('validationForDaysOfWeekDeclined') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.validationForDaysOfWeekDeclined() Executing...');
                AccountService.validationForDaysOfWeekDeclined((Map<Id, Account>)trigger.oldMap, (List<Account>)trigger.new);
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.validationForDaysOfWeekDeclined() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('customNotofocationForDaysOfWeekDeclined') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.customNotofocationForDaysOfWeekDeclined() Executing...');
                AccountService.customNotofocationForDaysOfWeekDeclined((List<Account>)trigger.new,(Map<Id, Account>)trigger.oldMap);
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.customNotofocationForDaysOfWeekDeclined() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('updateAccountType') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.updateAccountType() Executing...');
                AccountService.updateAccountType((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                             (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.updateAccountType() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('createNotesOnAccountStrategyupdate') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.createNotesOnAccountStrategyupdate() Executing...');
                AccountService.createNotesOnAccountStrategyupdate((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                                              (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
                System.debug('Number of Queries used in this apex code so far:createNotesOnAccountStrategyupdate ' + Limits.getQueries());
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.createNotesOnAccountStrategyupdate() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('populateMarketOnAccount') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.populateMarketOnAccount() Executing...');
                AccountService.populateMarketOnAccount((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                                   (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);   
                System.debug('Number of Queries used in this apex code so far:populateMarketOnAccount ' + Limits.getQueries());
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.populateMarketOnAccount() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('updateNationalNameStatus') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.updateNationalNameStatus() Executing...');
                AccountService.updateNationalNameStatus((List<Account>)Trigger.new, (Map<Id,Account>)Trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
                System.debug('Number of Queries used in this apex code so far:updateNationalNameStatus ' + Limits.getQueries());
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.updateNationalNameStatus() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('checkRolloverFlagUpdateAccessability') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.checkRolloverFlagUpdateAccessability() Executing...');
                //AccountService.checkRolloverFlagUpdateAccessability((List<Account>)Trigger.old, (List<Account>)Trigger.new, (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
                System.debug('Number of Queries used in this apex code so far:checkRolloverFlagUpdateAccessability ' + Limits.getQueries());
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.checkRolloverFlagUpdateAccessability() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('populateRMLookUp') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.populateRMLookUp() Executing...');
                //Added as part of HRP-2999
                //Populate the Relationship Manager User lookup field when RM Portfolio is populated
                //AccountService.populateRMLookUp((List<Account>)Trigger.new,(Map<Id,Account>)Trigger.newMap);
                System.debug('Number of Queries used in this apex code so far:populateRMLookUp ' + Limits.getQueries());
            }else{
                System.debug('AccountTriggerHandler.beforeUpdate() - AccountService.populateRMLookUp() Bypassed');
            }
            //Logic for HRP-10394 **Starts here**
            if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
                System.debug('AccountTriggerHandler.beforeUpdate() - FormatPhoneNumbers Executing...');
                FormatPhoneNumbers.format();
            }
            else{
                System.debug('FormatPhoneNumbers Bypassed');
            }
            //Logic for HRP-10394 **Ends here**
        }
        
    }
    
    public override void beforeInsert() {
        checkRecursive.isNewlyCreatedAccount = true;
        
        if(super.getTriggerMethodsToBypass().indexOf('updateAccountType') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateAccountType() Executing...');
            AccountService.updateAccountType((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                         (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
        }else{
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateAccountType() Bypassed');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('createNotesOnAccountStrategyupdate') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.createNotesOnAccountStrategyupdate() Executing...');
            AccountService.createNotesOnAccountStrategyupdate((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                                          (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
        }else{
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.createNotesOnAccountStrategyupdate() Bypassed');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('populateMarketOnAccount') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.populateMarketOnAccount() Executing...');
            AccountService.populateMarketOnAccount((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
                                           (Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
        }else{
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.populateMarketOnAccount() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('updateAccStatusAndInternalName') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateAccStatusAndInternalName() Executing...');
            AccountService.updateAccStatusAndInternalName((List<Account>)Trigger.new);
                                          
        }else{
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateAccStatusAndInternalName() Bypassed');
        }
        /* 
        * HRP-9585 changes starts here
        * @Description: Calling updateNationalName() method to New Accounts autopopulate "ADD" to National Name field.
    	* @Date: 02/05/2023
        */
        if(super.getTriggerMethodsToBypass().indexOf('updateNationalName') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateNationalName() Executing...');
            AccountService.updateNationalName((List<Account>)Trigger.new);
                                          
        }else{
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.updateNationalName() Bypassed');
        }
        /*
        * HRP-9585 changes Ends
        */
        /* 
        * HRP-9818 changes starts here
        * @Description: Calling checkUserProfile() method to check if DRD Users are tring to create Fixed Site Account.
    	* @Date: 02/05/2023
        */
        if(super.getTriggerMethodsToBypass().indexOf('checkUserProfile') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.checkUserProfile() Executing...');
            AccountService.checkUserProfile((List<Account>)Trigger.new);
                                          
        }else{
            System.debug('AccountTriggerHandler.beforeInsert() - AccountService.checkUserProfile() Bypassed');
        }
        /*
        * HRP-9818 changes Ends
        */
        //Logic for HRP-10394 **Starts here**
        if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
            System.debug('AccountTriggerHandler.beforeInsert() - FormatPhoneNumbers Executing...');
            FormatPhoneNumbers.format();
        }
        else{
            System.debug('FormatPhoneNumbers Bypassed');
        }
        //Logic for HRP-10394 **Ends here**
    }
    
    public override void afterUpdate(){
        System.debug('afterUpdate AccountTeamMemberHelper.skipAccountTrigger: '+AccountTeamMemberHelper.skipAccountTrigger);
        if(!AccountTeamMemberHelper.skipAccountTrigger){
        System.debug('Entered afterUpdate');
        //ContactService.standardizeMailingAddress((List<Contact>)trigger.new,(Map<Id,Contact>)trigger.oldMap, (Map<Id,Contact>)trigger.newMap,'UPDATE');
        if(super.getTriggerMethodsToBypass().indexOf('standardizeBillingAddress') == -1) {
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.standardizeBillingAddress() Executing...');
            AccountService.standardizeBillingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'UPDATE');
        }else{
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.standardizeBillingAddress() Bypassed');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('standardizeShippingAddress') == -1) {
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.standardizeShippingAddress() Executing...');
            AccountService.standardizeShippingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'UPDATE');
        //    AccountService.createAccountTeamMembers((List<Account>)trigger.new,(Map<Id,Account>)trigger.newMap,'',null,new Map<String,AccountTeamMember>());
        }else{
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.standardizeShippingAddress() Bypassed');
        }
        //HRP-10085
        if(super.getTriggerMethodsToBypass().indexOf('updateDivesOnCalenderForAccountInternalNameChange') == -1) {
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateDivesOnCalenderForAccountInternalNameChange() Executing...');
            AccountService.updateDivesOnCalenderForAccountInternalNameChange((List<Account>)trigger.new, (Map<Id,Account>)trigger.oldMap);
        }else{
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateDivesOnCalenderForAccountInternalNameChange() Bypassed');
        }
        //HRP-10085    
        if(super.getTriggerMethodsToBypass().indexOf('updateTemplateBloodDriveOpportunitiesForAccountNameChange') == -1) {
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateTemplateBloodDriveOpportunitiesForAccountNameChange() Executing...');
            AccountService.updateTemplateBloodDriveOpportunitiesForAccountNameChange((List<Account>)trigger.new, (Map<Id,Account>)trigger.oldMap);
        }else{
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateTemplateBloodDriveOpportunitiesForAccountNameChange() Bypassed');
        }    
        
        if(super.getTriggerMethodsToBypass().indexOf('createAccountTeamMembers') == -1) {
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.createAccountTeamMembers() Executing...');
            AccountService.createAccountTeamMembers((List<Account>)trigger.new,(Map<Id,Account>)trigger.newMap,'',null,new Map<String,AccountTeamMember>());        
        }else{
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.createAccountTeamMembers() Bypassed');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync') == -1) {
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync() Executing...');
            AccountService.updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync((List<Account>)trigger.new, (Map<Id, Account>)trigger.oldMap);       
        }else{
            System.debug('AccountTriggerHandler.afterUpdate() - AccountService.updateBloodDriveOpportunitiesForNameOrInternalNameChangeAsync() Bypassed');
        }
            
            // HRP- 9520/11951 --> Starts Here
            if(super.getTriggerMethodsToBypass().indexOf('setBusinessPlanningDateAndUser') == -1) {
            	System.debug('AccountTriggerHandler.afterUpdate() - AccountService.setBusinessPlanningDateAndUser() Executing...');
            	AccountService.setBusinessPlanningDateAndUser((List<Account>)trigger.new , (Map<Id,Account>)trigger.oldMap);       
        	}else{
            	System.debug('AccountTriggerHandler.afterUpdate() - AccountService.setBusinessPlanningDateAndUser() Bypassed');
        	}
            // HRP- 9520/11951 --> Ends Here
            // HRP- 12142 --> Starts Here
            if(super.getTriggerMethodsToBypass().indexOf('updateTaskChecklist') == -1) {
            	System.debug('AccountTriggerHandler.afterUpdate() - BSFTaskChecklistTriggerHandler.updateTaskChecklist() Executing...');
            	BSFTaskChecklistTriggerHandler.updateTaskChecklist((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap); 
            }
            // HRP- 12142 --> Ends Here
      }
    }
    
    
    public override void afterInsert(){
        System.debug('Entered afterInsert');
        if(super.getTriggerMethodsToBypass().indexOf('standardizeBillingAddress') == -1) {
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.standardizeBillingAddress() Executing...');
            AccountService.standardizeBillingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'INSERT');
        }else{
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.standardizeBillingAddress() Bypassed');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('standardizeShippingAddress') == -1) {
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.standardizeShippingAddress() Executing...');
            AccountService.standardizeShippingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'INSERT');
        }else{
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.standardizeShippingAddress() Bypassed');
        }
            
        if(super.getTriggerMethodsToBypass().indexOf('createAccountTeamMembers') == -1) {
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.createAccountTeamMembers() Executing...');
            AccountService.createAccountTeamMembers((List<Account>)trigger.new,(Map<Id,Account>)trigger.newMap,'',null,new Map<String,AccountTeamMember>());        
        }else{
            System.debug('AccountTriggerHandler.afterInsert() - AccountService.createAccountTeamMembers() Bypassed');
        }
    }
    
    public override void beforeDelete()
    {	
        // HRP-10115 --> starts Here
        if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1)
        {
            System.debug('AccountTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Executing...');
            BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('Account',(List<Account>)trigger.old);
        }
        else
        {
            System.debug('ContactTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Bypassed');           
        }
        // HRP-10115 --> Ends Here
    }
    
    /**
    * @description Prevent and stop user to do merge operation from delete of the Account record in result of merge.
    **/

    /*public void preventUserFromMerge(List<Account> oldList){
        for(Account acc : oldList){
            if(acc.MasterRecordId != null && !hasAccountMergePermission){
                acc.addError(Label.AccountMergePermissionMessage);
            }
        }
    }*/ 
    
    /*    

//VARIABLES
public static Boolean runWhenRunningTest = true;
public static Boolean bypassTrigger = false;

//METHODS
/**
* @description determine if trigger should be run
* @return   true if trigger should execute
*/
    /*   public static Boolean runTrigger()
{
return  AccountHelper.firstRun
&& ((!bypassTrigger && !Test.isRunningTest())
|| (!bypassTrigger && (runWhenRunningTest && Test.isRunningTest())));
}

/**
* @description logic for after insert trigger
* @param  Program Activity being inserted
*/
    /*   public override void OnBeforeUpdate(List<SObject> old, List<SObject> updated, Map<ID, SObject> oldMap, Map<ID, SObject> newMap){

AccountHelper.updateAccountType((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
AccountHelper.createNotesOnAccountStrategyupdate((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
AccountHelper.populateMarketOnAccount((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
}

public override void OnBeforeInsert(List<SObject> updated){
AccountHelper.updateAccountType((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
AccountHelper.createNotesOnAccountStrategyupdate((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
AccountHelper.populateMarketOnAccount((List<Account>)Trigger.old, (List<Account>)Trigger.new, 
(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)Trigger.newMap);
}

public override void OnAfterUpdate(List<SObject> old, List<SObject> updated, Map<ID, SObject> oldMap, Map<ID, SObject> newMap){
System.debug('Entered afterUpdate');
//ContactService.standardizeMailingAddress((List<Contact>)trigger.new,(Map<Id,Contact>)trigger.oldMap, (Map<Id,Contact>)trigger.newMap,'UPDATE');
AccountHelper.standardizeBillingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'UPDATE');
AccountHelper.standardizeShippingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'UPDATE');
}

public override void OnAfterInsert(List<SObject> updated){
System.debug('Entered afterInsert');
AccountHelper.standardizeBillingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'INSERT');
AccountHelper.standardizeShippingAddress((List<Account>)trigger.new,(Map<Id,Account>)trigger.oldMap, (Map<Id,Account>)trigger.newMap,'INSERT');
}

public override void finish()
{
AccountHelper.firstRun = false;
} 
*/
}