public with sharing class OpportunityTeamMemberTriggerHandler extends TriggerHandler{
    Public static boolean isOpptyTeamBackEndUpdate = false;

/*        //VARIABLES
    public static Boolean runWhenRunningTest = true;
    public static Boolean bypassTrigger = false;
    
    //METHODS
    /**
* @description determine if trigger should be run
* @return   true if trigger should execute

    public static Boolean runTrigger()
    {
        return  AccountTeamMemberHelper.firstRun
            && ((!bypassTrigger && !Test.isRunningTest())
                || (!bypassTrigger && (runWhenRunningTest && Test.isRunningTest())));
    }*/
    
   public override void afterInsert(){
        System.debug('OpportunityTeamMemberTriggerHandler: Entered afterInsert');
        //OpportunityTeamMemberHelper.createOpportunityTeamMemberHistoryRecords((List<OpportunityTeamMember>)trigger.new);
        OpportunityTeamMemberService.createOpportunityTeamMemberHistoryRecords((List<OpportunityTeamMember>)trigger.new);
        
     }
   /* public override void beforeUpdate(){
        System.debug('OpportunityTeamMemberTriggerHandler: Entered beforeUpdate');
        if(!isOpptyTeamBackEndUpdate)
        {
          OpportunityTeamMemberService.restrictEditorDeleteofOpptyTeam((List<OpportunityTeamMember>)trigger.new);
        }
       	  
          
    }
    
    public override void beforeDelete(){
        System.debug('OpportunityTeamMemberTriggerHandler: Entered beforeUpdate');
       OpportunityTeamMemberService.restrictEditorDeleteofOpptyTeam((List<OpportunityTeamMember>)trigger.old);
       	  
          
    }*/
    
    public override void afterDelete(){
         System.debug('OpportunityTeamMemberTriggerHandler: Entered afterDelete'); 
         //OpportunityTeamMemberHelper.populateEndDateOnOpportunityTeamMemberHistoryRecords((List<OpportunityTeamMember>)trigger.old,(Map<ID,OpportunityTeamMember>)trigger.oldMap);
         OpportunityTeamMemberService.populateEndDateOnOpportunityTeamMemberHistoryRecords((List<OpportunityTeamMember>)trigger.old,(Map<ID,OpportunityTeamMember>)trigger.oldMap);
    }
}