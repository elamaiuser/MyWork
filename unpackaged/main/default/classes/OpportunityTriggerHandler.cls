/* 
 * @description: This class is called from Opportunity trigger.
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 3/8/2023				     Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572)(Deleted)
 * 8/4/2023                  Ankit Kundu              HRP-10416 Projected WB & 2RBC not updating when Projected Procedures is updated
 * 8/24/2023                 Priti Jana               Restricting non-admin users from Site deletion (Part of HRP-10115)
 * 9/11/2023                 Priti Jana               Logic for HRP-10172
 * 10/24/2023	             Anil Kallu	              HRP-10959- Pass only opportunities that did not hit validation error into updateDrivesOnCalendarStatus
 * 12/08/2023				 Barnojit Sharma		  Update Accepts Blank Military Checkbox field from the template during Opportunity creation. (HRP-11179)
 ************************************************************************************************************************************************
*/

/***
* AS-012312->DRD User: BPL is Required to Promote Opportunity to Closed-AK.
* 
* */
public class OpportunityTriggerHandler extends TriggerHandler{
    // this varaible is using for OpptyMigration only
     Boolean isMigration=Boolean.valueOf(Label.OnlyForMigration);
     Boolean isInserted=false;
    public Static Boolean isSplit=false;
    
    public override void beforeUpdate(){
        System.debug('Entered method beforeUpdate');
        Set<Id> invalidStageOppIds = new Set<Id>();
         //HRP-6908
        if(super.getTriggerMethodsToBypass().indexOf('checkForOppStageChange') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkForOppStageChange() Executing...');
            invalidStageOppIds = OpportunityService.checkForOppStageChange((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
            System.debug('invalidStageOppIds->'+invalidStageOppIds);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkForOppStageChange() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('assignDefaultSiteDataIfNotPresent') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.assignDefaultSiteDataIfNotPresent() Executing...');
            OpportunityService.assignDefaultSiteDataIfNotPresent((List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.assignDefaultSiteDataIfNotPresent() Bypassed');
        }
         
         if(super.getTriggerMethodsToBypass().indexOf('primaryDriveContactRequired') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.primaryDriveContactRequired() Executing...');
                OpportunityService.primaryDriveContactRequired((Map<Id,Opportunity>)trigger.newMap,(Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.primaryDriveContactRequired() Bypassed');
            }

        if(super.getTriggerMethodsToBypass().indexOf('updateDriveDateDay') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateDriveDateDay() Executing...');
            OpportunityService.updateDriveDateDay((List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateDriveDateDay() Bypassed');
        }
      //HRP-10416 Start ->>  
	if(super.getTriggerMethodsToBypass().indexOf('updateOppProjUnitFields') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateOppProjUnitFields() Executing...');
            OpportunityService.updateOppProjUnitFields((Map<Id,Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateOppProjUnitFields() Bypassed');
        }
	//HRP-10416 <<-End
        /* Commented as part of HRP - 9887 --> Start
        if(super.getTriggerMethodsToBypass().indexOf('validateOnlineDonorMessage') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.validateOnlineDonorMessage() Executing...');
            OpportunityService.validateOnlineDonorMessage((Map<Id,Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.validateOnlineDonorMessage() Bypassed');
        } Commented as part of HRP - 9887 --> End */
        
        if(super.getTriggerMethodsToBypass().indexOf('checkAccept56DaysVoilation') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkAccept56DaysVoilation() Executing...');
            OpportunityService.checkAccept56DaysVoilation((Map<Id,Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkAccept56DaysVoilation() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('checkProductEndDate') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkProductEndDate() Executing...');
            OpportunityService.checkProductEndDate((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.newMap);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkProductEndDate() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('templateActiveCheckValidation') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.templateActiveCheckValidation() Executing...');
            OpportunityService.templateActiveCheckValidation((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap) ;
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.templateActiveCheckValidation() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('validateRequiredSiteFieldsBasedOnOppStage') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.validateRequiredSiteFieldsBasedOnOppStage() Executing...');
            //OpportunityService.validateRequiredSiteFieldsBasedOnOppStage((Map<Id,Opportunity>)trigger.newMap,(Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.validateRequiredSiteFieldsBasedOnOppStage() Bypassed');
        }
        
        // HRP - 3593
        if(RecursiveOpportunityTriggerHandler.firstRun){
            RecursiveOpportunityTriggerHandler.firstRun = false; 
            /*
            if(super.getTriggerMethodsToBypass().indexOf('generateTemplateOppId') == -1) {
                System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.generateTemplateOppId() Executing...');
                OpportunityService.generateTemplateOppId((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap);            
            }else{
                System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.generateTemplateOppId() Bypassed');
            }*/
            
            if(super.getTriggerMethodsToBypass().indexOf('duplicateSiteCheck') == -1) {
                System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.duplicateSiteCheck() Executing...');
                OpportunityService.duplicateSiteCheck((Map<Id,Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new);
            }else{
                System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.duplicateSiteCheck() Bypassed');
            }
        }
		
        // HRP - 3571
        if(super.getTriggerMethodsToBypass().indexOf('generateTemplateOppName') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.generateTemplateOppName() Executing...');
            OpportunityService.generateTemplateOppName((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap);        
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.generateTemplateOppName() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('reGenerateTemplateOppName') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.reGenerateTemplateOppName() Executing...');
            OpportunityService.reGenerateTemplateOppName((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.reGenerateTemplateOppName() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('checkOriginalValueChange') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkOriginalValueChange() Executing...');
            OpportunityService.checkOriginalValueChange((Map<Id, Opportunity>)trigger.oldMap, (List<Opportunity>) trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkOriginalValueChange() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('autoPopulateOpportunityTemplateValues') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.autoPopulateOpportunityTemplateValues() Executing...');
            OpportunityService.autoPopulateOpportunityTemplateValues((Map<Id, Opportunity>)trigger.oldMap, (List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.autoPopulateOpportunityTemplateValues() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('updateOpportunityName') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateOpportunityName() Executing...');
            OpportunityService.updateOpportunityName((List<Opportunity>) trigger.new, (Map<Id, Opportunity>)trigger.oldMap);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateOpportunityName() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('updateProjectionHistory') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateProjectionHistory() Executing...');
            OpportunityService.updateProjectionHistory((Map<Id, Opportunity>)trigger.oldMap, (List<Opportunity>) trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateProjectionHistory() Bypassed');
        }
        //HRP-5002 :Global Web Scheduling,HRP-4987=SF TimeZone Objects
        if(super.getTriggerMethodsToBypass().indexOf('updateWebSchedulingStart_EndDates') == -1){
        System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateWebSchedulingStart_EndDates() Executing...');
        OpportunityService.updateWebSchedulingStart_EndDates((List<Opportunity>) trigger.new,(Map<Id,Opportunity>)trigger.oldMap);
        } else {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateWebSchedulingStart_EndDates() Bypassed');
        }
        //HRP-4987=SF TimeZone Objects
          if(super.getTriggerMethodsToBypass().indexOf('updateWebSchedulingStartEndDates_WithoutGlobalSchedules') == -1) {	
          OpportunityService.updateWebSchedulingStart_EndDates_WithoutGlobalSchedules((List<Opportunity>) trigger.new,(Map<Id,Opportunity>)trigger.oldMap);
         } else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateWebSchedulingStart_EndDates_WithoutGlobalSchedules() Bypassed');
        } 
        
        // HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
        // HRP-5487 :CR: Adding Account Team to Blood Drive Team 
        if(super.getTriggerMethodsToBypass().indexOf('updateOpptyOwner_OpptyTeam') == -1) {	
            OpportunityService.updateOpptyOwner_OpptyTeam((List<Opportunity>) trigger.new,(Map<Id,Opportunity>)trigger.oldMap,true,false,false);
        } else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateOpptyOwner_OpptyTeam() Bypassed');  
        }
        if(super.getTriggerMethodsToBypass().indexOf('assignFlowStartAndEndTimeValues') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.assignFlowStartAndEndTimeValues() Executing...');
            OpportunityService.assignFlowStartAndEndTimeValues((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.assignFlowStartAndEndTimeValues() Bypassed');
        }
        
         //HRP-7103
        if(super.getTriggerMethodsToBypass().indexOf('updateOppStage') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateOppStage() Executing...');
            OpportunityService.updateOppStage((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateOppStage() Bypassed');
        }
        
        //HRP-6233 & HRP-6234
        if(super.getTriggerMethodsToBypass().indexOf('updateDrivesOnCalendarStatus') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateDrivesOnCalendarStatus() Executing...');
            OpportunityService.updateDrivesOnCalendarStatus((Map<Id, Opportunity>)trigger.oldMap, (List<Opportunity>)trigger.new,invalidStageOppIds);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateDrivesOnCalendarStatus() Bypassed');
        }
        
        //HRP-6696
        if(super.getTriggerMethodsToBypass().indexOf('checkForSiteChangeOnOpportunity') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkForSiteChangeOnOpportunity() Executing...');
            OpportunityService.checkForSiteChangeOnOpportunity((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.checkForSiteChangeOnOpportunity() Bypassed');
        }
        
       
        

        if(super.getTriggerMethodsToBypass().indexOf('SetAPHWebScheduling') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.SetAPHWebScheduling() Executing...');
            OpportunityService.SetAPHWebScheduling((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeUpdate() - OpportunityService.SetAPHWebScheduling() Bypassed');
        }
        
        //HRP-HRP-4875
		/*2/10/23 - commenting out per HRP-9304
		 * if(super.getTriggerMethodsToBypass().indexOf('updateDirectDonorsTo') == -1) {
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateDirectDonorsTo() Executing...');
            OpportunityService.updateDirectDonorsTo((Map<Id,Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeUpdate() - OpportunityService.updateDirectDonorsTo() Bypassed');
        }*/
            
        System.debug('Exiting method beforeUpdate');
    }
    
    public override void beforeInsert(){
        isSplit=true;
        System.debug('Entered method Opportunity beforeInsert');
       
        if(super.getTriggerMethodsToBypass().indexOf('assignDefaultSiteDataIfNotPresent') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.assignDefaultSiteDataIfNotPresent() Executing...');
            OpportunityService.assignDefaultSiteDataIfNotPresent((List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.assignDefaultSiteDataIfNotPresent() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('updateDriveDateDay') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateDriveDateDay() Executing...');
            OpportunityService.updateDriveDateDay((List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateDriveDateDay() Bypassed');
        }
		    
        //Per HRP-7032 this is no longer needed
        /*
        if(super.getTriggerMethodsToBypass().indexOf('verifyValidBPLExists') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.verifyValidBPLExists() Executing...');
            OpportunityService.verifyValidBPLExists((Map<Id,Opportunity>)trigger.oldMap,(Map<Id,Opportunity>)trigger.newMap);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.verifyValidBPLExists() Bypassed');
        }*/
        /* Commented as part of HRP - 9887 --> Start
        if(super.getTriggerMethodsToBypass().indexOf('validateOnlineDonorMessage') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.validateOnlineDonorMessage() Executing...');
            OpportunityService.validateOnlineDonorMessage((Map<Id,Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.validateOnlineDonorMessage() Bypassed');
        }
        Commented as part of HRP - 9887 --> End */
        if(super.getTriggerMethodsToBypass().indexOf('checkAccept56DaysVoilation') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.checkAccept56DaysVoilation() Executing...');
            OpportunityService.checkAccept56DaysVoilation(null,(List<Opportunity>)trigger.new);  
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.checkAccept56DaysVoilation() Bypassed');
        }
        
        //  OpportunityService.generateTemplateOppNameOnCLone((List<Opportunity>)trigger.new);

        if(super.getTriggerMethodsToBypass().indexOf('autoPopulateOpportunityTemplateValues') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.autoPopulateOpportunityTemplateValues() Executing...');
            OpportunityService.autoPopulateOpportunityTemplateValues(null, (List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.autoPopulateOpportunityTemplateValues() Bypassed');
        }
        
        if(super.getTriggerMethodsToBypass().indexOf('updateOpportunityName') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateOpportunityName() Executing...');
            OpportunityService.updateOpportunityName((List<Opportunity>) trigger.new, null);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateOpportunityName() Bypassed');
        }
        
        //HRP-5002 :Global Web Scheduling ,HRP-4987=SF TimeZone Objects
         if(super.getTriggerMethodsToBypass().indexOf('updateWebSchedulingStart_EndDates') == -1) {	
         OpportunityService.updateWebSchedulingStart_EndDates((List<Opportunity>) trigger.new,null);
         } else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateWebSchedulingStart_EndDates() Bypassed');
        } 
        
        //HRP-4987=SF TimeZone Objects
        if(super.getTriggerMethodsToBypass().indexOf('updateWebSchedulingStart_EndDates_WithoutGlobalSchedules') == -1) {	
            OpportunityService.updateWebSchedulingStart_EndDates_WithoutGlobalSchedules((List<Opportunity>) trigger.new,null);
        } else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateWebSchedulingStart_EndDates_WithoutGlobalSchedules() Bypassed');
        }
        // HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
        // HRP-5487 :CR: Adding Account Team to Blood Drive Team 
        if(super.getTriggerMethodsToBypass().indexOf('updateOpptyOwner_OpptyTeam') == -1) {	
            OpportunityService.updateOpptyOwner_OpportunityTeam((List<Opportunity>) trigger.new,true,false);
            
        } else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateOpptyOwner_OpptyTeam() Bypassed');  
        }
        if(super.getTriggerMethodsToBypass().indexOf('assignFlowStartAndEndTimeValues') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeInsert() - OpportunityService.assignFlowStartAndEndTimeValues() Executing...');
            OpportunityService.assignFlowStartAndEndTimeValues((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeInsert() - OpportunityService.assignFlowStartAndEndTimeValues() Bypassed');
        }
        //HRP-10416 For Before Insert Start ->>
        if(super.getTriggerMethodsToBypass().indexOf('updateOppProjUnitFields') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateOppProjUnitFields() Executing...');
            OpportunityService.updateOppProjUnitFields((Map<Id,Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateOppProjUnitFields() Bypassed');
        }
       // HRP-10416 For Before Update <<- End
        //HRP-7142 Set double red procedures to 0 when certain conditions are met
        if(super.getTriggerMethodsToBypass().indexOf('updateDoubleRedProcedures') == -1) {	
            OpportunityService.updateDoubleRedProcedures((List<Opportunity>) trigger.new,null);
        } else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateDoubleRedProcedures() Bypassed');
        } 
        
        //12/9 FWO added to replace the workflow "Update Drive Name Field".  Previously it was only called from beforeupdate.  This 
        //will only deal with templates
        if(super.getTriggerMethodsToBypass().indexOf('generateTemplateOppName') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.generateTemplateOppName() Executing...');
            OpportunityService.generateTemplateOppName((List<Opportunity>)trigger.new, null);        
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.generateTemplateOppName() Bypassed');
        }
        
        //12/9 FWO added to replace the workflow "Update Drive Name Field".  Previously it was only called from beforeupdate but now making sure
        //it is called from before insert also.  This will only deal with templates
        if(super.getTriggerMethodsToBypass().indexOf('reGenerateTemplateOppName') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.reGenerateTemplateOppName() Executing...');
            OpportunityService.reGenerateTemplateOppName((List<Opportunity>)trigger.new, null);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.reGenerateTemplateOppName() Bypassed');
        }
        
		//HRP-HRP-4875
		if(super.getTriggerMethodsToBypass().indexOf('updateDirectDonorsTo') == -1) {
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateDirectDonorsTo() Executing...');
            OpportunityService.updateDirectDonorsTo(null,(List<Opportunity>)trigger.new);
        }else{
            System.debug('OpportunityTriggerHandler.beforeInsert() - OpportunityService.updateDirectDonorsTo() Bypassed');
        }
        
        //Replacing worklfow logic (HRP-8946)
        if(super.getTriggerMethodsToBypass().indexOf('SetAPHWebScheduling') == -1) {
            System.debug('#### OpportunityTriggerHandler.beforeInsert() - OpportunityService.SetAPHWebScheduling() Executing...');
            OpportunityService.SetAPHWebScheduling((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
        }else{
            System.debug('#### OpportunityTriggerHandler.beforeInsert() - OpportunityService.SetAPHWebScheduling() Bypassed');
        }
        /*
        * HRP-11179 changes starts here
        */
        if(super.getTriggerMethodsToBypass().indexOf('updateAcceptblankMilitaryAuthNamePhone') == -1) {
            OpportunityService.updateAcceptblankMilitaryAuthNamePhone((List<Opportunity>)trigger.new);
        }
        /*
        * HRP-11179 changes ends here
        */
        System.debug('Exiting method beforeInsert');
    }
    
    public override void afterInsert(){
        isSplit=true;
        isInserted=true;
        System.debug('Entered method Opportunity AfterInsert');
        // OpportunityService.createRecruitmentTask((List<Opportunity>)trigger.new);
        
        //HRp-1084
        if(super.getTriggerMethodsToBypass().indexOf('insertOrUpdateCovRecruiterOpportunitySplit') == -1) {
            System.debug('OpportunityTriggerHandler.afterInsert() - OpportunityService.insertOrUpdateCovRecruiterOpportunitySplit() Executing...');
            OpportunityService.insertOrUpdateCovRecruiterOpportunitySplit((List<Opportunity>)trigger.new,null);
        }else{
            System.debug('OpportunityTriggerHandler.afterInsert() - OpportunityService.insertOrUpdateCovRecruiterOpportunitySplit() Bypassed');
        }
         // HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
        // HRP-5487 :CR: Adding Account Team to Blood Drive Team 
          if(super.getTriggerMethodsToBypass().indexOf('updateOpptyOwner_OpptyTeam') == -1) {	
              OpportunityService.updateOpptyOwner_OpportunityTeam((List<Opportunity>) trigger.new,false,true);
          } else{
            System.debug('OpportunityTriggerHandler.afterInsert - OpportunityService.updateOpptyOwner_OpptyTeam() Bypassed');  
        }
        //HRP-6038 -> Handle Drive Affiliation creation post new opportunity inserts
        if(super.getTriggerMethodsToBypass().indexOf('createDriveAffiliations') == -1 && System.isBatch() == false) {	
              OpportunityService.createDriveAffiliations((List<Opportunity>) trigger.new,(Map<Id,Opportunity>)trigger.newMap);
          } else{
            System.debug('OpportunityTriggerHandler.afterInsert - OpportunityService.createDriveAffiliations Bypassed');  
        }
        //HRP-6235
        if(super.getTriggerMethodsToBypass().indexOf('createSkedFixedSiteDrive') == -1) {
            System.debug('#### OpportunityTriggerHandler.afterInsert() - OpportunityService.createSkedFixedSiteDrive() Executing...');
            //public static void createDriveAffiliations(List<Opportunity> newOppList,Map<Id,Opportunity> newOppMap){
            OpportunityService.createSkedFixedSiteDrive((List<Opportunity>)trigger.new);
        }else{
            System.debug('#### OpportunityTriggerHandler.afterInsert() - OpportunityService.createSkedFixedSiteDrive() Bypassed');
        }
        
        
        //12/9 FWO to address HRP-8353.  Using a platform event for create the drive service role records for an opportunity based
        //on the template.  This will be done whenever an opportunity is created (both individual and series via plan a drive flow)
        
        if(super.getTriggerMethodsToBypass().indexOf('PublishEventForDriveServiceRole') == -1) {
            System.debug('#### OpportunityTriggerHandler.afterInsert() - OpportunityService.PublishEventForDriveServiceRole() Executing...');
            OpportunityService.PublishEventForDriveServiceRole((List<Opportunity>)trigger.new);
        }else{
            System.debug('#### OpportunityTriggerHandler.afterInsert() - OpportunityService.PublishEventForDriveServiceRole() Bypassed');
        }
        
        //HRP-7103
        if(super.getTriggerMethodsToBypass().indexOf('updateOppStage') == -1) {
            System.debug('#### OpportunityTriggerHandler.afterInsert() - OpportunityService.updateOppStage() Executing...');
            OpportunityService.updateOppStage((List<Opportunity>)trigger.new, null);
        }else{
            System.debug('#### OpportunityTriggerHandler.afterInsert() - OpportunityService.updateOppStage() Bypassed');
        }
        
		//12/9 FWO added to replace the workflows "Update Opportunity name with No Site & Update Opportunity Name with Site Building"
        if(super.getTriggerMethodsToBypass().indexOf('GenerateOpportunityName') == -1) {
            System.debug('OpportunityTriggerHandler.afterInsert() - OpportunityService.GenerateOpportunityName() Executing...');
            OpportunityService.GenerateOpportunityName((List<Opportunity>)trigger.new, null);
        }else{
            System.debug('OpportunityTriggerHandler.afterInsert() - OpportunityService.GenerateOpportunityName() Bypassed');
        }

        System.debug('Exiting method AfterInsert');
    }
    
    public override void afterUpdate(){
        System.debug('Entered method Opportunity AfterUpdate');
        // HRP-5852
        OpportunityService.validatePromotionEndDate((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
        //
        if(OpportunityRecursive.isOpportunity){
            
            if(super.getTriggerMethodsToBypass().indexOf('createRecruitmentTask') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.createRecruitmentTask() Executing...');
                OpportunityService.createRecruitmentTask((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.createRecruitmentTask() Bypassed');
            }
            
			if(super.getTriggerMethodsToBypass().indexOf('createSponsorPlanningMeetingTask') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.createSponsorPlanningMeetingTask() Executing...');
                OpportunityService.createSponsorPlanningMeetingTask((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.createSponsorPlanningMeetingTask() Bypassed');
            }
            
            // HRP-1760 
            if(super.getTriggerMethodsToBypass().indexOf('updateAccountWithEarliestDriveDate') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateAccountWithEarliestDriveDate() Executing...');
                OpportunityService.updateAccountWithEarliestDriveDate((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateAccountWithEarliestDriveDate() Bypassed');
            }
            //HRP-11457
             if(super.getTriggerMethodsToBypass().indexOf('updateOrderBudget') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateOrderBudget() Executing...');
                OpportunityService.updateOrderBudget( (List<Opportunity>)trigger.new);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateOrderBudget() Bypassed');
            }
            
            //HRp-1084
            if(super.getTriggerMethodsToBypass().indexOf('insertOrUpdateCovRecruiterOpportunitySplit') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.insertOrUpdateCovRecruiterOpportunitySplit() Executing...');
                OpportunityService.insertOrUpdateCovRecruiterOpportunitySplit((List<Opportunity>)trigger.new,(Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.insertOrUpdateCovRecruiterOpportunitySplit() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('updateOpportunitiesRelatedToTemplate') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateOpportunitiesRelatedToTemplate() Executing...');
                OpportunityService.updateOpportunitiesRelatedToTemplate((Map<Id,Opportunity>)trigger.oldMap, (List<Opportunity>)trigger.new);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateOpportunitiesRelatedToTemplate() Bypassed');
            }
            
            //HRP-5203 (update drives on calendar via PE)
			//if(super.getTriggerMethodsToBypass().indexOf('updateDrivesOnCalendarWithOpportunityChanges') == -1) {
            //    System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateDrivesOnCalendarWithOpportunityChanges() Executing...');
            //    OpportunityService.updateDrivesOnCalendarWithOpportunityChanges((Map<Id,Opportunity>)trigger.oldMap, (List<Opportunity>)trigger.new);
            //}else{
            //    System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateDrivesOnCalendarWithOpportunityChanges() Bypassed');
           	//}
            
            // HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
            // HRP-5487 :CR: Adding Account Team to Blood Drive Team 
            if(super.getTriggerMethodsToBypass().indexOf('updateOpptyOwner_OpptyTeam') == -1) {	
                OpportunityService.updateOpptyOwner_OpptyTeam((List<Opportunity>) trigger.new,(Map<Id,Opportunity>)trigger.oldMap,false,true,true);
            } else{
                System.debug('OpportunityTriggerHandler.afterUpdate - OpportunityService.updateOpptyOwner_OpptyTeam() Bypassed');  
            }
            System.debug('Exiting method AfterUpdate');
            
            //HRP-3459
            if(super.getTriggerMethodsToBypass().indexOf('cancelTasksForCancelledOpportunities') == -1) {	
                OpportunityService.cancelTasksForCancelledOpportunities((Map<Id,Opportunity>)trigger.oldMap,(Map<Id,Opportunity>)trigger.newMap);
            } else{
                System.debug('OpportunityTriggerHandler.afterUpdate - OpportunityService.cancelTasksForCancelledOpportunities() Bypassed');  
            }
            System.debug('Exiting method AfterUpdate');
            
            //HRP-6920
            if(super.getTriggerMethodsToBypass().indexOf('deleteDriveAffiliationOnDriveDateChange') == -1) {
                 OpportunityService.deleteDriveAffiliationOnDriveDateChange((List<Opportunity>)trigger.new,(Map<Id, Opportunity>)trigger.oldMap,(Map<Id, Opportunity>) trigger.newMap );
             } else{
                System.debug('OpportunityTriggerHandler.afterUpdate - OpportunityService.deleteDriveAffiliationOnDriveDateChange() Bypassed');  
            }
            System.debug('Exiting method AfterUpdate');
        
            /*//HRP-7128
            if(super.getTriggerMethodsToBypass().indexOf('UpdateOwnerSplit') == -1) {
                 OpportunityService.UpdateOwnerSplit((List<Opportunity>)trigger.new,(Map<Id, Opportunity>)trigger.oldMap);
             } else{
                System.debug('OpportunityTriggerHandler.afterUpdate - OpportunityService.UpdateOwnerSplit() Bypassed');  
            }
            System.debug('Exiting method AfterUpdate');*/
            
            //HRP-7287
            if(super.getTriggerMethodsToBypass().indexOf('closedOpportunity72HourTaskCreation') == -1) {
                 OpportunityService.closedOpportunity72HourTaskCreation((List<Opportunity>)trigger.new,(Map<Id, Opportunity>)trigger.oldMap);
             } else{
                System.debug('OpportunityTriggerHandler.afterUpdate - OpportunityService.closedOpportunity72HourTaskCreation() Bypassed');  
            }
            System.debug('Exiting method AfterUpdate');
            
            //HRP-7362
            if(super.getTriggerMethodsToBypass().indexOf('modifyTasksOnDriveDateChange') == -1) {
                 OpportunityService.modifyTasksOnDriveDateChange((Map<Id, Opportunity>)trigger.oldMap,(List<Opportunity>)trigger.new,(Map<Id, Opportunity>)trigger.newMap);
             } else{
                System.debug('OpportunityTriggerHandler.afterUpdate - OpportunityService.modifyTasksOnDriveDateChange() Bypassed');  
            }
            
            //12/9 FWO added to replace the workflows "Update Opportunity name with No Site & Update Opportunity Name with Site Building"
            if(super.getTriggerMethodsToBypass().indexOf('GenerateOpportunityName') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.GenerateOpportunityName() Executing...');
                OpportunityService.GenerateOpportunityName((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.GenerateOpportunityName() Bypassed');
            }

            //HRP-10172 --> Starts Here
            if(super.getTriggerMethodsToBypass().indexOf('updateTypeBasedOnPhysicalLocationType') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateTypeBasedOnPhysicalLocationType() Executing...');
                OpportunityService.updateTypeBasedOnPhysicalLocationType((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.updateTypeBasedOnPhysicalLocationType() Bypassed');
            }
            
            if(super.getTriggerMethodsToBypass().indexOf('populateRelatedFieldsOnDOC') == -1) {
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.populateRelatedFieldsOnDOC() Executing...');
                OpportunityService.populateRelatedFieldsOnDOC((List<Opportunity>)trigger.new, (Map<Id,Opportunity>)trigger.oldMap);
            }else{
                System.debug('OpportunityTriggerHandler.afterUpdate() - OpportunityService.populateRelatedFieldsOnDOC() Bypassed');
            }
            //HRP-10172 --> Ends Here
            System.debug('Exiting method AfterUpdate');
        }
    }

    //HRP-7774
    public override void beforeDelete()
    {	        
        // Part of HRP-10115 --> Starts Here
        if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1) {
                 BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('Opportunity', (List<Opportunity>)trigger.old);
             } else{
                System.debug('OpportunityTriggerHandler.beforeDelete - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Bypassed');  
            }
         // Part of HRP-10115 --> Ends Here
            System.debug('Exiting method beforeDelete');
       
    }
}