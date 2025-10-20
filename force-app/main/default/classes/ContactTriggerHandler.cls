/* 
 * @description: This class is called from Contact trigger.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***************************************************************************************************************************************************************
 * 07/05/2023				 Kishore Das			  Logic for HRP-10208 (Historical drive roles should not be considered in validation to inactivate contact)
 * 31/07/2023				 Barnojit Sharma		  Phone Numbers must be limited to 10 Numbers (Logic for HRP-10394)
 * 03/08/2023				 Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572)
 * 10/03/2023                Priti Jana               Restricting non-admin users from contact deletion (Logic for HRP-HRP-10115)
 *****************************************************************************************************************************************************************
*/
/*
* AS-013042-ContactAddress Standardization
* 
* */
public with sharing class ContactTriggerHandler extends TriggerHandler{
    
	public override void beforeUpdate() {
        System.debug('Entered beforeUpdate');
        ContactService.updatePhoneNumberFields((List<Contact>)trigger.new, (map<Id, Contact>)trigger.oldMap);
        
        //Logic for HRP-10208 **Starts here**
        if(super.getTriggerMethodsToBypass().indexOf('preventContactDeactivationIfAssociatedWithOpportunityOrAccount') == -1) {
                System.debug('ContactTriggerHandler.beforeUpdate() - ContactService.preventContactDeactivationIfAssociatedWithOpportunityOrAccount() Executing...');
                ContactService.preventContactDeactivationIfAssociatedWithOpportunityOrAccount((List<Contact>)trigger.new , (map<Id, Contact>)trigger.oldMap);
        }
        else{
                System.debug('ContactTriggerHandler.beforeUpdate() - ContactService.preventContactDeactivationIfAssociatedWithOpportunityOrAccount() Bypassed');
            }
        //Logic for HRP-10208 **ends here**
       //Logic for HRP-10394 **Starts here**
        if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
            System.debug('ContactTriggerHandler.beforeUpdate() - FormatPhoneNumbers Executing...');
            FormatPhoneNumbers.format();
        }
        else{
            System.debug('FormatPhoneNumbers Bypassed');
        }
        //Logic for HRP-10394 **Ends here**
    }
    
    public override void beforeInsert() {
        System.debug('Entered beforeInsert');
        ContactService.updatePhoneNumberFields((List<Contact>)trigger.new, null);
        //Logic for HRP-10394 **Starts here**
        if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
            System.debug('ContactTriggerHandler.beforeInsert() - FormatPhoneNumbers Executing...');
            FormatPhoneNumbers.format();
        }
        else{
            System.debug('FormatPhoneNumbers Bypassed');
        }
        //Logic for HRP-10394 **Ends here**
    }
    
    public override void afterUpdate(){
        System.debug('Entered afterUpdate');
        if('YES'.equalsIgnoreCase(Label.PerformAddressCleanup) && !checkRecursive.firstcall ){
            checkRecursive.firstcall = true;
            ContactService.standardizeMailingAddress((List<Contact>)trigger.new,(Map<Id,Contact>)trigger.oldMap, (Map<Id,Contact>)trigger.newMap,'UPDATE');
            ContactService.standardizeSecondaryAddress((List<Contact>)trigger.new,(Map<Id,Contact>)trigger.oldMap, (Map<Id,Contact>)trigger.newMap,'UPDATE');
        }	
    }
    
    
    public override void afterInsert(){
        System.debug('Entered afterInsert');
        if('YES'.equalsIgnoreCase(Label.PerformAddressCleanup)){
            ContactService.standardizeMailingAddress((List<Contact>)trigger.new,(Map<Id,Contact>)trigger.oldMap, (Map<Id,Contact>)trigger.newMap,'INSERT');
            ContactService.standardizeSecondaryAddress((List<Contact>)trigger.new,(Map<Id,Contact>)trigger.oldMap, (Map<Id,Contact>)trigger.newMap,'INSERT');
        }
    }
    
    //=====Pritam : 23/02/2021=======
    @Future
    public static void updateNameChangeFlag(List<ID> ids) {
        List<Contact> ctList = [SELECT Id, Contact_Name_Change__c FROM Contact WHERE Id IN: ids];
        for(Contact ct : ctList) {
            ct.Contact_Name_Change__c = False; 
        }
         //Schema.DescribeSObjectResult ds = Contact.sObjectType.getDescribe();
        //if( ds.isUpdateable() ){}
        update ctList;
    }
    //===============================
    
    
    public override void beforeDelete()
    {
        // HRP-10115 --> Starts Here
        if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1)
        {
            System.debug('ContactTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Executing...');
            BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('Contact',(List<Contact>)trigger.old);
        }
        else
        {
            System.debug('ContactTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Bypassed');           
        }
        // HRP-10115 --> Ends Here
    }
        
}