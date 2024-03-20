//@Description: This class is a Handler for AccountPortfolioAssignment Trigger 
/* 
* Modification Log 
* Date					     Developer Name			     Comments
* ***********************************************************************************************************************************************
* 12/08/2023				  Balaji N				 logic for HRP-6028 (Method:HandleSpecialistForAM,Logic for Adding account Specialist based on AM node)
* 													  
* *
*************************************************************************************************************************************************
*/
public class AccountPortfolioAssignmentTriggerHandler extends TriggerHandler{
    
   /* public override void afterInsert(){
        if(super.getTriggerMethodsToBypass().indexOf('createDefaultTerritoryRecords') == -1) {
            System.debug('AccountPortfolioAssignmentTriggerHandler.beforeUpdate() - AccountPortfolioAssignmentService.createDefaultTerritoryRecords() Executing...');
            if(BSF_Constants.skipAccountPortfolioAssignmentUpdateTrigger){
                
                AccountPortfolioAssignmentService.createDefaultTerritoryRecords((List<Account_Portfolio_Assignment__c>)Trigger.new, (Map<Id,Account_Portfolio_Assignment__c>)Trigger.newMap,(Map<Id,Account_Portfolio_Assignment__c>)Trigger.oldMap);
            }           
        }else{
            System.debug('AccountPortfolioAssignmentTriggerHandler.beforeUpdate() - AccountPortfolioAssignmentService.createDefaultTerritoryRecords() Bypassed');
        }
    }*/
    //HRP-6028 start
    public override void afterInsert()
    {
        
        if(super.getTriggerMethodsToBypass().indexOf('HandleSpecialistForAM') == -1) {
        if(!BSF_Constants.skipAccountPortfolioAssignmentInsertTrigger)
        AccountPortfolioAssignmentService.HandleSpecialistForAM((List<Account_Portfolio_Assignment__c>)Trigger.new,(Map<Id,Account_Portfolio_Assignment__c>)Trigger.newMap,null);
        }
        
    }
    //HRP-6028 end
	public override void afterUpdate(){
        
        
        if(super.getTriggerMethodsToBypass().indexOf('UpdateAccPortfolioAndAccTeamDates') == -1) {
        if(!BSF_Constants.skipAccountPortfolioAssignmentTrigger){
        AccountPortfolioAssignmentService.UpdateAccPortfolioAndAccTeamDates((List<Account_Portfolio_Assignment__c>)Trigger.new, (Map<Id,Account_Portfolio_Assignment__c>)Trigger.newMap,(Map<Id,Account_Portfolio_Assignment__c>)Trigger.oldMap);
        }
        }
        //HRP-6028 start
        if(super.getTriggerMethodsToBypass().indexOf('HandleSpecialistForAM') == -1) {
            AccountPortfolioAssignmentService.HandleSpecialistForAM((List<Account_Portfolio_Assignment__c>)Trigger.new,(Map<Id,Account_Portfolio_Assignment__c>)Trigger.newMap,(Map<Id,Account_Portfolio_Assignment__c>)Trigger.oldMap);//HRP-6028
                 
        }
        //HRP-6028 end
        
    }
    //HRP-6028 start
    public override void afterDelete()
    {
        if(super.getTriggerMethodsToBypass().indexOf('HandleSpecialistForAM') == -1) {
        AccountPortfolioAssignmentService.HandleSpecialistForAM((List<Account_Portfolio_Assignment__c>)Trigger.old,null,null);
        }
    }
    //HRP-6028 end
}