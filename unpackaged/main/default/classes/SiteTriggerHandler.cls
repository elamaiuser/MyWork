/* 
 * @description: This class is called from Site trigger.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 7/31/2023				 Barnojit Sharma		  Phone Numbers must be limited to 10 Numbers (Logic for HRP-10394)
 * 3/8/2023				     Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572--> Deleted)
 * 9/27/2023                 Priti Jana               Logic for HRP-10172
 * 10/3/2023                 Priti Jana               Restricting non-admin users from Site deletion (Part of HRP-10115)
 * 11/09/2023                Barnojit Sharma          Geolocations on Sites are being lost (HRP-10835)
 * 11/17/2023			     Barnojit Sharma		  Sites are missing county information (HRP-11099)
 * 03/08/2024			     Barnojit Sharma		  Update Chapter on the site when the zip code changes. (HRP-12045)
 ************************************************************************************************************************************************
*/
public with sharing class SiteTriggerHandler extends TriggerHandler {
    
    public override void beforeUpdate() {
        
        System.debug('Entered method sked__Location__c BeforeUpdate');
        /*
        * HRP-12045 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('updateSiteChapter') == -1){
            SiteService.updateSiteChapter((List<sked__Location__c>)trigger.new, (Map<Id, sked__Location__c>)trigger.oldMap);                
        }
        System.debug('SiteService.updateSiteChapter : '+(List<sked__Location__c>)trigger.new);
        /*
        * HRP-12045 changes ends here
        */
        /*
        * HRP-10835 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('checkSiteAddress') == -1){
            SiteService.checkSiteAddress((Map<Id, sked__Location__c>)trigger.oldMap, (Map<Id, sked__Location__c>)trigger.newMap);                
        }
        /*
        * HRP-10835 changes ends here
        */
        /*
        * HRP-11099 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('updateSiteCountry') == -1){
            SiteService.updateSiteCountry((Map<Id, sked__Location__c>)trigger.oldMap, (List<sked__Location__c>)trigger.new);                
        }
        /*
        * HRP-11099 changes ends here
        */
        if(!checkRecursive.firstcall) {
            checkRecursive.firstcall = true;
            if(super.getTriggerMethodsToBypass().indexOf('updateInitialReviewer') == -1) {
                System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.updateInitialReviewer() Executing...');
                SiteService.updateInitialReviewer((List<sked__Location__c>)trigger.new, (Map<Id, sked__Location__c>)trigger.oldMap);
            }else{
                System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.updateInitialReviewer() Bypassed');
            }
        }
        
        // HRP - 6985
        if(super.getTriggerMethodsToBypass().indexOf('validateEndDateChangeOnSite') == -1)
        {
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.validateEndDateChangeOnSite() Executing...');
            SiteService.validateEndDateChangeOnSite((List<sked__Location__c>)trigger.new, (Map<Id, sked__Location__c>)trigger.oldMap);                
        }
        else{
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.validateEndDateChangeOnSite() Bypassed');                
        }
       
        // HRP - 9889 -----> Starts Here

        if(super.getTriggerMethodsToBypass().indexOf('validateOperationTypeChange') == -1)
        {
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.validateOperationTypeChange() Executing...');
            SiteService.validateOperationTypeChange((List<sked__Location__c>)trigger.new, (Map<Id, sked__Location__c>)trigger.oldMap);
        }else{
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.validateOperationTypeChange() Bypassed');                
        }
       
        // HRP - 9889 -----> Ends Here
        //Logic for HRP-10394 **Starts here**
        if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
            System.debug('SiteTriggerHandler.beforeUpdate() - FormatPhoneNumbers Executing...');
            FormatPhoneNumbers.format();
        }
        else{
            System.debug('FormatPhoneNumbers Bypassed');
        }
        //Logic for HRP-10394 **Ends here**
        
         // HRP-10172 -----> Starts Here
        if(super.getTriggerMethodsToBypass().indexOf('validatePhysicaLocationTypeChange') == -1)
        {
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.validatePhysicaLocationTypeChange() Executing...');
            SiteService.validatePhysicaLocationTypeChange('sked__Location__c', 'Update',(List<sked__Location__c>)trigger.new, (Map<Id, sked__Location__c>)trigger.oldMap);
        }else{
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.validatePhysicaLocationTypeChange() Bypassed');                
        }       
        // HRP-10172 -----> Ends Here
        System.debug('Exiting method sked__Location__c BeforeUpdate');
    }
    
    public override void beforeInsert(){
        /*
        * HRP-12045 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('updateSiteChapter') == -1){
            SiteService.updateSiteChapter((List<sked__Location__c>)trigger.new,null);                
        }
        /*
        * HRP-12045 changes ends here
        */
        // HRP - 9585
        if(super.getTriggerMethodsToBypass().indexOf('updateNationalName') == -1)
        {
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.updateNationalName() Executing...');
            SiteService.updateNationalName((List<sked__Location__c>)trigger.new);                
        }
        else{
            System.debug('SiteTriggerHandler.beforeUpdate() - SiteService.updateNationalName() Bypassed');                
        }
        //Logic for HRP-10394 **Starts here**
        if(super.getTriggerMethodsToBypass().indexOf('FormatPhoneNumbers') == -1) {
            System.debug('SiteTriggerHandler.beforeInsert() - FormatPhoneNumbers Executing...');
            FormatPhoneNumbers.format();
        }
        else{
            System.debug('FormatPhoneNumbers Bypassed');
        }
        //Logic for HRP-10394 **Ends here**
        /*
        * HRP-11099 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('updateSiteCountry') == -1){
            SiteService.updateSiteCountry(null, (List<sked__Location__c>)trigger.new);                
        }
        /*
        * HRP-11099 changes ends here
        */
    }
    
    public override void afterUpdate(){
        
        System.debug('Entered method sked__Location__c AfterUpdate');
        
        if(super.getTriggerMethodsToBypass().indexOf('getSiteBuildingNameChangedAccounts') == -1) {
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.updateInitialReviewer() Executing...');
            Set<Id> siteIds = SiteService.getSiteBuildingNameChangedAccounts((Map<Id, sked__Location__c>)trigger.oldMap, (List<sked__Location__c>)trigger.new);
            SiteService.updateOpportunitiesForSiteBuidlingNameChangeAsync(siteIds);
        }else{
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.getSiteBuildingNameChangedAccounts() Bypassed');
        }
        
        // HRP - 9276        
        if(super.getTriggerMethodsToBypass().indexOf('inactiveSiteBasedOnEndDate') == -1) {
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.inactiveSiteBasedOnEndDate() Executing...');
            SiteService.inactiveSiteBasedOnEndDate((List<sked__Location__c>)trigger.new,(Map<Id,sked__Location__c>)trigger.oldMap);
        }else{
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.inactiveSiteBasedOnEndDate() Bypassed');
        }
        
        // HRP - 9276
        if(super.getTriggerMethodsToBypass().indexOf('siteActiveOnEndDateChange') == -1) {
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.siteActiveOnEndDateChange() Executing...');
            SiteService.siteActiveOnEndDateChange((List<sked__Location__c>)trigger.new,(Map<Id,sked__Location__c>)trigger.oldMap);
        }else{
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.siteActiveOnEndDateChange() Bypassed');
        }
        
        System.debug('Exiting method sked__Location__c AfterUpdate');
        
        // HRP - 10085
        if(super.getTriggerMethodsToBypass().indexOf('updateTemplateOpportunitiesForSiteBuidlingNameChange') == -1) {
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.updateTemplateOpportunitiesForSiteBuidlingNameChange() Executing...');
            SiteService.updateTemplateOpportunitiesForSiteBuidlingNameChange((List<sked__Location__c>)trigger.new,(Map<Id, sked__Location__c>)trigger.oldMap);
        }else{
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.updateTemplateOpportunitiesForSiteBuidlingNameChange() Bypassed');
        }
        // HRP - 10085
        if(super.getTriggerMethodsToBypass().indexOf('updateDivesOnCalenderForSiteBuidlingNameChange') == -1) {
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.updateDivesOnCalenderForSiteBuidlingNameChange() Executing...');
            SiteService.updateDivesOnCalenderForSiteBuidlingNameChange((List<sked__Location__c>)trigger.new,(Map<Id, sked__Location__c>)trigger.oldMap);
        }else{
            System.debug('SiteTriggerHandler.afterUpdate() - SiteService.updateDivesOnCalenderForSiteBuidlingNameChange() Bypassed');
        }

    }
    
    public override void afterInsert(){
        
    }

    public override void beforeDelete()
    {
       // Part of HRP-10115 --> Starts Here

       if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1) {
        System.debug('SiteTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Executing...');
        BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('sked__Location__c', (List<sked__Location__c>)trigger.old);
    }   
    else{
        System.debug('SiteTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Bypassed');
    }
    
    // Part of HRP-10115 --> Ends Here
    }
    
    public override void afterDelete(){
        
    }
}