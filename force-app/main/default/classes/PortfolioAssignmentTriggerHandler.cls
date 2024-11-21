/*
 * 
 * Modification Log 
 * Date					Developer Name			Comments
 * ***************************************************************************
 * 27/04/2023				Balaji N			Logic for HRP-9951(Methods: AfterInsert & AfterUpdate)- added PortfolioAssignmentService.populateRMLookupOnAccount method call
 * 11/08/2023				Balaji N			Logic for HRP-11290(Removed method calls updateEndDateOfAccountTeamMembers,deleteAccountTeamMembers from after update & delete)
 * 11/08/2023				Balaji N			Logic for HRP-11290(Added publishPlarformEventsOnAfterInsert in after update & delete)
 * */
public class PortfolioAssignmentTriggerHandler extends TriggerHandler{

    public override void beforeInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('validateDateOverlap') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.beforeInsert() - Executing...');
            PortfolioAssignmentService.validateDateOverlap((List<Portfolio_Assignment__c>) Trigger.new,null);   

        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeInsert() - Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('checkPfAssignInsertRecords') == -1 ){
            System.debug('PortfolioAssignmentTriggerHandler.beforeInsert() - Executing...');
            //checkPfAssignInsertRecords(Trigger.new);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeInsert() - Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('checkPfAssign') == -1 ){
            System.debug('PortfolioAssignmentTriggerHandler.beforeInsert() - Executing...');
            PortfolioAssignmentService.checkPfAssign((List<Portfolio_Assignment__c>) Trigger.new,null);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeInsert() - Bypassed');
        }
        
      
        
    }
    /*private void checkPfAssignInsertRecords(List<Portfolio_Assignment__c> newRecords){
        //List<Batch_Tracking__c> batchTrackList = new List <Batch_Tracking__c>();
        //batchTrackList = [Select Count__c, User__c, CreatedById From Batch_Tracking__c Where CreatedById =: UserInfo.getUserId() AND Count__c > 0 Limit 100];
        List<Portfolio_Accounts_Processing__c> pt = [Select Id,Portfolio_progress_for_Accounts__c, Portfolio_Assignment_Updated__c, Records_Processed__c From Portfolio_Accounts_Processing__c LIMIT 1];
        if (pt.size() > 0 && pt[0].Portfolio_progress_for_Accounts__c != null && (pt[0].Portfolio_progress_for_Accounts__c != pt[0].Records_Processed__c || pt[0].Portfolio_Assignment_Updated__c)) {
            for(Portfolio_Assignment__c pfAssign : newRecords){
                if (!Test.isRunningTest()) {
                    pfAssign.addError('Portfolio Assignment records are already in progress. Please wait'); 
                }
            }
        }
        else if(pt.size() > 0 ){
            pt[0].Portfolio_Assignment_Updated__c = true;
            pt[0].Records_Processed__c = 0;
            pt[0].Portfolio_progress_for_Accounts__c = 0;
            update pt;
        }
        else{
            insert new Portfolio_Accounts_Processing__c(Name= 'American Red Cross',  Portfolio_progress_for_Accounts__c = 0, Portfolio_Assignment_Updated__c = true, Records_Processed__c = 0);

        }
    }*/
    
    public override void beforeUpdate(){
        if(super.getTriggerMethodsToBypass().indexOf('validateDateOverlap') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.beforeUpdate() - Executing...');
            PortfolioAssignmentService.validateDateOverlap((List<Portfolio_Assignment__c>) Trigger.new,(Map<Id,Portfolio_Assignment__c>) Trigger.oldMap);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeUpdate() - Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('checkPfAssignUpdateRecords') == -1 && !BSF_Constants.isEndateBatch){
            System.debug('PortfolioAssignmentTriggerHandler.beforeUpdate() - Executing...');
            //checkPfAssignUpdateRecords(Trigger.new, (Map<Id,Portfolio_Assignment__c>)Trigger.oldMap);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeUpdate() - Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('checkPfAssign') == -1 && !BSF_Constants.isEndateBatch){
            System.debug('PortfolioAssignmentTriggerHandler.beforeUpdate() - Executing...');
            PortfolioAssignmentService.checkPfAssign((List<Portfolio_Assignment__c>) Trigger.new,(Map<Id,Portfolio_Assignment__c>) Trigger.oldMap);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeUpdate() - Bypassed');
        }
      }
    /*private void checkPfAssignUpdateRecords(List<Portfolio_Assignment__c> newRecords, Map<Id, Portfolio_Assignment__c> oldMap){
        //List<Batch_Tracking__c> batchTrackList = new List <Batch_Tracking__c>();
        //batchTrackList = [Select Count__c, User__c, CreatedById From Batch_Tracking__c Where CreatedById =: UserInfo.getUserId() AND Count__c > 0 Limit 100];
        List<Portfolio_Accounts_Processing__c> pt = [Select Id,Portfolio_progress_for_Accounts__c, Portfolio_Assignment_Updated__c, Records_Processed__c From Portfolio_Accounts_Processing__c LIMIT 1];
        if (pt.size() > 0 && pt[0].Portfolio_progress_for_Accounts__c != null && (pt[0].Portfolio_progress_for_Accounts__c != pt[0].Records_Processed__c || pt[0].Portfolio_Assignment_Updated__c)) {
            for(Portfolio_Assignment__c pfAssign : newRecords){
                if (!Test.isRunningTest()) {
                    pfAssign.addError('Portfolio Assignment records are already in progress. Please wait'); 
                }
            }
        }else if(pt.size() > 0){
            Boolean hasChanged = false;
            for(Portfolio_Assignment__c pfAssign : newRecords){
                if ((pfAssign.Start_Date__c != oldMap.get(pfAssign.Id).Start_Date__c) || (pfAssign.End_Date__c != oldMap.get(pfAssign.Id).End_Date__c)) {
                    hasChanged = true;
                }  
            }
            if (hasChanged) {
                pt[0].Portfolio_Assignment_Updated__c = true;
                pt[0].Records_Processed__c = 0;
                pt[0].Portfolio_progress_for_Accounts__c = 0;
                update pt;
            }
        }else{
            Boolean hasChanged = false;
            for(Portfolio_Assignment__c pfAssign : newRecords){
                if ((pfAssign.Start_Date__c != oldMap.get(pfAssign.Id).Start_Date__c) || (pfAssign.End_Date__c != oldMap.get(pfAssign.Id).End_Date__c)) {
                    hasChanged = true;
                }  
            }
            if (hasChanged) {
                insert new Portfolio_Accounts_Processing__c(Name= 'American Red Cross',  Portfolio_progress_for_Accounts__c = 0, Portfolio_Assignment_Updated__c = true, Records_Processed__c = 0);
            }
        }
    }*/
    
    public override void beforeDelete(){
        if(super.getTriggerMethodsToBypass().indexOf('checkPfAssignDeleteRecords') == -1 && !BSF_Constants.isEndateBatch){
            System.debug('PortfolioAssignmentTriggerHandler.beforeDelete() - Executing...');
            //checkPfAssignDeleteRecords(Trigger.old);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeDelete() - Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('checkPfAssign') == -1 && !BSF_Constants.isEndateBatch){
            System.debug('PortfolioAssignmentTriggerHandler.beforeDelete() - Executing...');
           PortfolioAssignmentService.checkPfAssign((List<Portfolio_Assignment__c>) Trigger.old,null);     
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.beforeDelete() - Bypassed');
        }
    }
    /*private void checkPfAssignDeleteRecords(List<Portfolio_Assignment__c> oldRecords){
        //List<Batch_Tracking__c> batchTrackList = new List <Batch_Tracking__c>();
        //batchTrackList = [Select Count__c, User__c, CreatedById From Batch_Tracking__c Where CreatedById =: UserInfo.getUserId() AND Count__c > 0 Limit 100];
        List<Portfolio_Accounts_Processing__c> pt = [Select Id, Portfolio_progress_for_Accounts__c, Records_Processed__c, Portfolio_Assignment_Updated__c From Portfolio_Accounts_Processing__c LIMIT 1];
        if (pt.size() > 0 && pt[0].Portfolio_progress_for_Accounts__c != null && pt[0].Portfolio_progress_for_Accounts__c > 0  && (pt[0].Portfolio_progress_for_Accounts__c != pt[0].Records_Processed__c || pt[0].Portfolio_Assignment_Updated__c)) {
            for(Portfolio_Assignment__c pfAssign : oldRecords){
                if (!Test.isRunningTest()) {
                    pfAssign.addError('Portfolio Assignment records are already in progress. Please wait'); 
                }
            }
        }else if(pt.size() > 0 ){
            pt[0].Portfolio_Assignment_Updated__c = true;
            pt[0].Records_Processed__c = 0;
            pt[0].Portfolio_progress_for_Accounts__c = 0;
            update pt;
        }else{
            insert new Portfolio_Accounts_Processing__c(Name= 'American Red Cross',  Portfolio_progress_for_Accounts__c = 0, Portfolio_Assignment_Updated__c = true, Records_Processed__c = 0);
        }
    }*/
    
    public override void afterInsert(){
        System.debug('After Insert of PortfolioAssignmentTriggerHandler');
        //PortfolioAssignmentService.createAccountTeamMembers((List<Portfolio_Assignment__c>) Trigger.new);
        
        if(super.getTriggerMethodsToBypass().indexOf('publishPlarformEventsOnAfterInsert') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterInsert() - PortfolioAssignmentService.publishPlarformEventsOnAfterInsert() Executing...');
            PortfolioAssignmentService.publishPlarformEventsOnAfterInsert((List<Portfolio_Assignment__c>) Trigger.new,null);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterInsert() - PortfolioAssignmentService.publishPlarformEventsOnAfterInsert() Bypassed.');
        }
        
        //HRP-9951
        if(super.getTriggerMethodsToBypass().indexOf('populateRMLookupOnAccount') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterInsert() - PortfolioAssignmentService.populateRMLookupOnAccount() Executing...');
            BSF_Constants.isTeamMemberCreatedFromBackend = true;
            PortfolioAssignmentService.populateRMLookupOnAccount((List<Portfolio_Assignment__c>) Trigger.new);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterInsert() - PortfolioAssignmentService.populateRMLookupOnAccount() Bypassed.');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('manageUserAssignemntForPortfolioInOtherTaxo') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterInsert() - PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo() Executing...');
            PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo((List<Portfolio_Assignment__c>) Trigger.new,null,'Insert');   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterInsert() - PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo() Bypassed.');
        }
        //HRP-9951
       
        
    }
    public override void afterUpdate(){
        System.debug('After Update of PortfolioAssignmentTriggerHandler');
        
        if(super.getTriggerMethodsToBypass().indexOf('publishPlarformEventsOnAfterInsert') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterUpdate() - PortfolioAssignmentService.updateEndDateOfAccountTeamMembers() Executing...');
            BSF_Constants.isTeamMemberCreatedFromBackend = true;
            //PortfolioAssignmentService.updateEndDateOfAccountTeamMembers((Map<Id,Portfolio_Assignment__c>) Trigger.newMap,(Map<Id,Portfolio_Assignment__c>) Trigger.oldMap); //HRP-11290 
            PortfolioAssignmentService.publishPlarformEventsOnAfterInsert((List<Portfolio_Assignment__c>) Trigger.new,(Map<Id,Portfolio_Assignment__c>) Trigger.oldMap);  //HRP-11290
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterUpdate() - PortfolioAssignmentService.updateEndDateOfAccountTeamMembers() Bypassed.');
        }
        //HRP-9951
        if(super.getTriggerMethodsToBypass().indexOf('populateRMLookupOnAccount') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterUpdate() - PortfolioAssignmentService.populateRMLookupOnAccount() Executing...');
            BSF_Constants.isTeamMemberCreatedFromBackend = true;
            PortfolioAssignmentService.populateRMLookupOnAccount((List<Portfolio_Assignment__c>) Trigger.new);   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterUpdate() - PortfolioAssignmentService.populateRMLookupOnAccount() Bypassed.');
        }
        //HRP-9951
        if(super.getTriggerMethodsToBypass().indexOf('manageUserAssignemntForPortfolioInOtherTaxo') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterUpdate() - PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo() Executing...');
            BSF_Constants.isTeamMemberCreatedFromBackend = true;
            PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo((List<Portfolio_Assignment__c>) Trigger.new,(Map<Id,Portfolio_Assignment__c>) Trigger.oldMap,'Update');   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterUpdate() - PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo() Bypassed.');
        }
        
        
    }   
    
    public override void afterDelete(){ 
        system.debug('delete portfolioAssignmentRec');
        if(super.getTriggerMethodsToBypass().indexOf('publishPlarformEventsOnAfterInsert') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterDelete() - PortfolioAssignmentService.deleteAccountTeamMembers() Executing...');
            //PortfolioAssignmentService.deleteAccountTeamMembers(Trigger.Old,(Map<Id,Portfolio_Assignment__c>) Trigger.oldMap);   //HRP-11290
            PortfolioAssignmentService.publishPlarformEventsOnAfterInsert((List<Portfolio_Assignment__c>)Trigger.Old,null);//HRP-11290
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterDelete() - PortfolioAssignmentService.deleteAccountTeamMembers() Bypassed.');
        }
        if(super.getTriggerMethodsToBypass().indexOf('manageUserAssignemntForPortfolioInOtherTaxo') == -1){
            System.debug('PortfolioAssignmentTriggerHandler.afterDelete() - PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo() Executing...');
            PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo(Trigger.Old,(Map<Id,Portfolio_Assignment__c>) Trigger.oldMap,'Delete');   
        }else{
            System.debug('PortfolioAssignmentTriggerHandler.afterDelete() - PortfolioAssignmentService.manageUserAssignemntForPortfolioInOtherTaxo() Bypassed.');
        }
    }
}