public with sharing class OpportunityTeamMemberHelper {
 public static Boolean firstRun = true;
    
     public static void createOpportunityTeamMemberHistoryRecords(List<OpportunityTeamMember> newOpportunityTeamMembers){
         List<Team_Member_History__c> teamMemberHistoryList = new  List<Team_Member_History__c>();
         
         if(newOpportunityTeamMembers.size()>0){
             for(OpportunityTeamMember teamMember:newOpportunityTeamMembers){
                 Team_Member_History__c historyRecord = new Team_Member_History__c();
                 historyRecord.Blood_Drive_Opportunity__c = teamMember.OpportunityId;
                 historyRecord.Team_Member__c = teamMember.UserId;
                 if(teamMember.Start_Date__c!=null){
                     historyRecord.Start_Date__c = teamMember.Start_Date__c;
                 }
                 else{
                     historyRecord.Start_Date__c = System.today();
                 }
                 teamMemberHistoryList.add(historyRecord);
             }
         }
       
            Database.insert(teamMemberHistoryList);//dml for security
     }
    
    public static void populateEndDateOnOpportunityTeamMemberHistoryRecords(List<OpportunityTeamMember> deletedMappings, Map<ID, OpportunityTeamMember> MappingMap){
        
        // System.debug('Entered populateEndDateOnOpportunityTeamMemberHistoryRecords');
        // System.debug('MappingMap: '+MappingMap.keySet());
        Set<Id> userIdSet = new Set<Id>(); 
        Set<Id> optyIdSet = new Set<Id>();
        List<Team_Member_History__c> teamMemberHistoryListToUpdate = new List<Team_Member_History__c>();
        
        for(OpportunityTeamMember teamMember:deletedMappings){
           userIdSet.add(teamMember.UserId); 
           optyIdSet.add(teamMember.OpportunityId);
        }
        
        List<Team_Member_History__c> teamMemberHistoryList = [SELECT Id,Blood_Drive_Opportunity__c,Team_Member__c,Start_Date__c,End_Date__c FROM Team_Member_History__c WHERE Team_Member__c IN:userIdSet AND Blood_Drive_Opportunity__c IN:optyIdSet  ];
        
        //System.debug('teamMemberHistoryList to Update after delete: '+teamMemberHistoryList);
        if(teamMemberHistoryList.size()>0){
         for(Team_Member_History__c memberHistory:teamMemberHistoryList){
           		 memberHistory.End_Date__c =  system.today();
            	 teamMemberHistoryListToUpdate.add(memberHistory);
       	  }
        }
            Database.update(teamMemberHistoryListToUpdate);
        
    }
}