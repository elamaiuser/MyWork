/* 
 * @Description: This class is used to serve different DOC object related functionalities and is called from DriveTriggerhandler.
 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 * 03/08/2023				 Kishore Das		      Users other than System Admin should not have any delete record permissions(Logic for HRP-10572 --> Deleted)
 * 20/09/2023				 Krapy Tuli				  Logic for HRP-10359 (Update AM, DM, AM Portfolio and DM Portfolio)
 * 10/03/2023                Priti Jana               Restricting non-admin users from DOC deletion (Part of HRP-HRP-10115)
 * 11/09/2023                Barnojit Sharma          Validation added to stop referring two DOC to a single BDO. (HRP-11326)
 * 12/27/2023				 Kishore Das		      Logic for HRP-11605(Newly created FS BDO's are reflecting as tentative when the DOC is reflecting as confirmed (out of sync))
 * 12/27/2023				 Barnojit Sharma		  The current 56 day validation rule that triggers when trying to change Drive Date will also be added to the Drive on Calendar. (HRP-11640)
 * 1/11/2024				 Priti Jana			      Logic for HRP-10882
 * 12/02/2024				 Barnojit Sharma		  BDO can not be confirmed if DCR or Pending Action is in progress. (HRP-10912)
 * 17/04/2024                Ankit Kundu              Method added as part of HRP-12170
 * 18/10/2024                Priti Jana               Logic for HRP-9815
 ************************************************************************************************************************************************
*/
public class DriveTriggerHandler extends TriggerHandler{ 

    Boolean isMigration=Boolean.valueOf(Label.OnlyForMigration); 
    Boolean isInserted=false;
    
    public override void beforeUpdate() {
        //Start HRP-10912
        if (super.getTriggerMethodsToBypass().indexOf('validateNoPendingDCR') == -1) {
            DriveTriggerService.validateNoPendingDCR((Map<Id, sked_Drive__c>)trigger.newMap, (Map<Id, sked_Drive__c>)trigger.oldMap);
        }
        //End HRP-10912
        if (super.getTriggerMethodsToBypass().indexOf('populateDriveWorksheetData') == -1) {
            //DriveTriggerService.populateDriveWorksheetData((List<sked_Drive__c>)trigger.new);
        }
        //Start HRP-11326
        if (super.getTriggerMethodsToBypass().indexOf('validateOpportunity') == -1) {
            //DriveTriggerService.validateOpportunity((Map<Id, sked_Drive__c>)trigger.oldMap, (List<sked_Drive__c>)trigger.new);
        }
        //End HRP-11326
        //Start HRP-11640
        if (super.getTriggerMethodsToBypass().indexOf('checkAccept56DaysVoilation') == -1) {
            DriveTriggerService.checkAccept56DaysVoilation((Map<Id, sked_Drive__c>)trigger.oldMap, (List<sked_Drive__c>)trigger.new);
        }
        //End HRP-11640
        
         // HRP-10882 --> Starts Here
        if (super.getTriggerMethodsToBypass().indexOf('validateRequiredSiteFieldsBasedOnDriveStatus') == -1) {
            DriveTriggerService.validateRequiredSiteFieldsBasedOnDriveStatus((Map<Id, sked_Drive__c>)trigger.oldMap, (Map<Id, sked_Drive__c>)trigger.newMap);
        }
        
        if (super.getTriggerMethodsToBypass().indexOf('checkMilitaryAuthoritySettingBeforeChangingStatus') == -1) {
            DriveTriggerService.checkMilitaryAuthoritySettingBeforeChangingStatus((List<sked_Drive__c>)trigger.new, (Map<Id, sked_Drive__c>)trigger.oldMap);
        }

         // HRP-10882 --> Ends Here
          //Start HRP-12170
        if (super.getTriggerMethodsToBypass().indexOf('autoPopulateDriveProjProductFields') == -1) {
            DriveTriggerService.autoPopulateDriveProjProductFields((Map<Id, sked_Drive__c>)trigger.oldMap, (List<sked_Drive__c>)trigger.new);
        }
        //End HRP-12170
        
        // HRP-9815 --> Starts Here
        if (super.getTriggerMethodsToBypass().indexOf('populateDriveOwnerOnAmUpdate') == -1) {
            DriveTriggerService.populateDriveOwnerOnAmUpdate((Map<Id, sked_Drive__c>)trigger.oldMap, (List<sked_Drive__c>)trigger.new);
        }
        // HRP-9815 --> Ends Here
    }
     
    public override void beforeInsert() {
        if (super.getTriggerMethodsToBypass().indexOf('populateDriveWorksheetData') == -1) {
            DriveTriggerService.populateDriveWorksheetData((List<sked_Drive__c>)trigger.new);
        } //HRP-10359 Start
        if (super.getTriggerMethodsToBypass().indexOf('populateAMAndDM') == -1) {
            DriveTriggerService.populateAMAndDM((List<sked_Drive__c>)trigger.new);
        } //HRP-10359 End
        //Start HRP-11326
        if (super.getTriggerMethodsToBypass().indexOf('validateOpportunity') == -1) {
            //DriveTriggerService.validateOpportunity(null, (List<sked_Drive__c>)trigger.new);
        }
        //End HRP-11326
    }
    
    public override void afterInsert() {
        isInserted = true;
        if(super.getTriggerMethodsToBypass().indexOf('updateReadyForNationalNameReview') == -1) {
            DriveTriggerService.updateReadyForNationalNameReview((List<sked_Drive__c>)trigger.new, null);
        }
        //Logic for HRP-11605--Starts here--
        if(super.getTriggerMethodsToBypass().indexOf('populateLookupOnOpportunityDoc') == -1) {
            DriveTriggerService.populateLookupOnOpportunityDoc((List<sked_Drive__c>)trigger.new);
        }
        //Logic for HRP-11605--Ends here--
        if(super.getTriggerMethodsToBypass().indexOf('triggerTaskGenerationOnConfirm') == -1) {
            BSF_TaskPlanningService.triggerTaskGenerationOnConfirm((List<sked_Drive__c>)trigger.new, null);
        }
    }
    
    public override void afterUpdate() {
        if(super.getTriggerMethodsToBypass().indexOf('updateReadyForNationalNameReview') == -1) {
            DriveTriggerService.updateReadyForNationalNameReview((List<sked_Drive__c>)trigger.new, (Map<Id, sked_Drive__c>)trigger.oldMap);
        }
        
        //HRP-9815 --> Starts Here
        if(super.getTriggerMethodsToBypass().indexOf('updateDrdRepOnOpRecordUponOwnerChange') == -1) {
            DriveTriggerService.updateDrdRepOnOpRecordUponOwnerChange((List<sked_Drive__c>) Trigger.new, (Map<Id, sked_Drive__c>) Trigger.oldMap);
        }
        //HRP-9815 --> Ends Here

        //HRP-701
        if(super.getTriggerMethodsToBypass().indexOf('removeFirstTimeFlagUponDriveCompletion') == -1) {
            DriveTriggerService.removeFirstTimeFlagUponDriveCompletion((List<sked_Drive__c>) Trigger.new, (Map<Id, sked_Drive__c>) Trigger.oldMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('handleOneWeekCheckIn') == -1) {
            DriveTriggerService.handleOneWeekCheckIn((List<sked_Drive__c>) Trigger.new, (Map<Id, sked_Drive__c>) Trigger.oldMap);
        }
        if(super.getTriggerMethodsToBypass().indexOf('triggerTaskGenerationOnConfirm') == -1) {
            BSF_TaskPlanningService.triggerTaskGenerationOnConfirm((List<sked_Drive__c>)trigger.new, (Map<Id, sked_Drive__c>)trigger.oldMap);
        }
    }
    public override void beforeDelete()
    {
        // Part of HRP-10115 --> Starts Here
        if(super.getTriggerMethodsToBypass().indexOf('restrictNonAdminUsersForSobjectDeletion') == -1) {
            System.debug('DriveTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Executing...');
            BSF_Utilities.restrictNonAdminUsersForSobjectDeletion('sked_Drive__c', (List<sked_Drive__c>)trigger.old);
    }
    else{
            System.debug('DriveTriggerHandler.beforeDelete() - BSF_Utilities.restrictNonAdminUsersForSobjectDeletion() Bypassed');
        }
     // Part of HRP-10115 --> Ends Here
    }
}