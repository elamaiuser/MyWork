/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  08/05/2023              Balaji N                    Logic for HRP-8897 (New Method: dateCheckbeforeInsertUpdate)
 *  08/29/2023				Balaji N			        Logic for HRP-10888(bypass for addAcctTeamMembersToBloodDriveOpptyMembers)
 *  09/27/2023				Balaji N					Logic for HRP-10890(bypass for addAcctTeamMembersToBloodDriveOpptyMembers; metadata logic)
 *  11/09/2023				Balaji N					Logic for HRP-11290(Method Name:beforeUpdate,method call for uncheckCoveringRecFlagForBackEndInsert)
 *  11/23/2023				Balaji N					Logic for HRP-11281(Method call for coveringRecruiterOpptyTeamonPastOpp & createAccountTeamMemberHistoryRecords)
 *  02/20/2024              Balaji N					Logic for HRP-11234(Method call for updateAccountOnTeammeberAssignment in after delete)
 *************************************************************************************************************************************************
*/
public class AccountTeamMemberTriggerHandler extends TriggerHandler{
    
    public override void beforeInsert(){
        //AccountTeamMemberService.populateDefaultAllocationFiledsOnInsert((List<AccountTeamMember>)trigger.new);
        //AccountTeamMemberService.createBloodDriveTeamMember((List<AccountTeamMember>)trigger.new);
        
        // Added for HRP-5076: Acceptance Criteria #5
AccountTeamMemberService.uncheckCoveringRecFlagForBackEndInsert((List<AccountTeamMember>)trigger.new,null); //HRP-11290 null parameter
        //HRP-8897
        if(bsf_constants.isdateCheckbeforeInsertUpdate) 
        { 
        AccountTeamMemberService.dateCheckbeforeInsertUpdate((List<AccountTeamMember>)trigger.new,null);
        } 
        //HRP-8897   
    }
    
    public override void beforeUpdate(){
        if(!AccountTeamMemberService.isAccessLevelUpdated){
            AccountTeamMemberService.uncheckCoveringRecFlagForBackEndInsert((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap);//HRP-11290
         //HRP-8897
        if(bsf_constants.isdateCheckbeforeInsertUpdate) 
        { 
            AccountTeamMemberService.dateCheckbeforeInsertUpdate((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap);
        } 
        //HRP-8897
            //Added for HRP-5076: Acceptance Criteria #12
            AccountTeamMemberService.allowOnlyDateUpdatesForCoveringRecs((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap,(Map<ID,AccountTeamMember>)trigger.newMap);
            AccountTeamMemberService.populateDefaultAllocationFiledsOnUpdate((List<AccountTeamMember>)trigger.old,(List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap,(Map<ID,AccountTeamMember>)trigger.newMap);
            //AccountTeamMemberService.updateAccountTeamMemberHistoryRecords((Map<ID,AccountTeamMember>)trigger.newMap);
        }
    }
    
    public override void afterInsert(){
        System.debug('AccountTeamMemberTriggerHandler: Entered afterInsert');
        //Added as part of HRP-2193
        // AccountTeamMemberHelper.createAccountTeamMemberHistoryRecords((List<AccountTeamMember>)trigger.new);
        AccountTeamMemberService.createAccountTeamMemberHistoryRecords((List<AccountTeamMember>)trigger.new,null);//HRP-11281
        system.debug('populateDefaultAllocationFiledsOnInsert');
        AccountTeamMemberService.coveringRecruiterOpptyTeamonPastOpp((List<AccountTeamMember>)trigger.new,null);//HRP-11281
        AccountTeamMemberService.populateDefaultAllocationFiledsOnInsert((List<AccountTeamMember>)trigger.new);
        // HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
        // HRP-5487 :CR: Adding Account Team to Blood Drive Team 
        if(super.getTriggerMethodsToBypass().indexOf('addAcctTeamMembersToBloodDriveOpptyMembers') == -1 && !BSF_Utilities.metaDataupdate(null,null,null,'Opportunity_Team_Sync_Batch').By_Pass_Batch__c)//HRP-10888 & HRP-10890
        {  
            
            AccountTeamMemberService.addAcctTeamMembersToBloodDriveOpptyMembers((List<AccountTeamMember>)trigger.new,null,true);
        }
        else
        {
            system.debug(' AccountTeamMemberService.addAcctTeamMembersToBloodDriveOpptyMember is Bypassed');
        }
        //Added for HRP-5076: Acceptance Criteria #5:
        // Not required this method, this is shifted to before insert
        //AccountTeamMemberService.updateAccessLevelsOfCoveringRecruiters((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.newMap);
        AccountTeamMemberService.updateAccountOnTeammeberAssignment((List<AccountTeamMember>)trigger.new,null);//HRP-11234 2nd parameter
    }
    
    public override void afterUpdate(){
        System.debug('AccountTeamMemberTriggerHandler: Entered afterUpdate');
        AccountTeamMemberService.createAccountTeamMemberHistoryRecords((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap);//HRP-11281
        // HRP-5486 :CR: Account Manager will be Account/Opportunity Owner
        // HRP-5487 :CR: Adding Account Team to Blood Drive Team
        if(super.getTriggerMethodsToBypass().indexOf('addAcctTeamMembersToBloodDriveOpptyMembers') == -1 && !BSF_Utilities.metaDataupdate(null,null,null,'Opportunity_Team_Sync_Batch').By_Pass_Batch__c)//HRP-10888 & HRP-10890
        {  
            AccountTeamMemberService.addAcctTeamMembersToBloodDriveOpptyMembers((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap,true);
        }
        else
        {
            system.debug(' AccountTeamMemberService.addAcctTeamMembersToBloodDriveOpptyMember is Bypassed');
        }
        AccountTeamMemberService.coveringRecruiterOpptyTeamonPastOpp((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap);//HRP-11281
        AccountTeamMemberService.updateAccountOnTeammeberAssignment((List<AccountTeamMember>)trigger.new,(Map<ID,AccountTeamMember>)trigger.oldMap);//HRP-11234 2nd parameter
    }
    
    public override void afterDelete(){
        System.debug('AccountTeamMemberTriggerHandler: Entered afterDelete'); 
        //Added as part of HRP-2193
        //  AccountTeamMemberHelper.populateEndDateOnAccountTeamMemberHistoryRecords((List<AccountTeamMember>)trigger.old,(Map<ID,AccountTeamMember>)trigger.oldMap);
        //AccountTeamMemberService.populateEndDateOnAccountTeamMemberHistoryRecords((List<AccountTeamMember>)trigger.old,(Map<ID,AccountTeamMember>)trigger.oldMap);//HRP-11281
        AccountTeamMemberService.createAccountTeamMemberHistoryRecords((List<AccountTeamMember>)trigger.old,null);//HRP-11281
        AccountTeamMemberService.deleteOpportunity_Splits_Teams_OnAccountTeamMemberDelete((List<AccountTeamMember>)trigger.old,(Map<ID,AccountTeamMember>)trigger.oldMap);
        if(super.getTriggerMethodsToBypass().indexOf('addAcctTeamMembersToBloodDriveOpptyMembers') == -1 && !BSF_Utilities.metaDataupdate(null,null,null,'Opportunity_Team_Sync_Batch').By_Pass_Batch__c)//HRP-10888 & HRP-10890
        {
            AccountTeamMemberService.addAcctTeamMembersToBloodDriveOpptyMembers((List<AccountTeamMember>)trigger.old,null,true);
        }
        else
        {
            system.debug(' AccountTeamMemberService.addAcctTeamMembersToBloodDriveOpptyMember is Bypassed');
        }
        AccountTeamMemberService.updateAccountOnTeammeberAssignment((List<AccountTeamMember>)trigger.old,null);//HRP-11234 2nd parameter
    }
    
}