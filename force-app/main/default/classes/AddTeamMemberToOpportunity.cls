public inherited sharing class AddTeamMemberToOpportunity {    
    
    @AuraEnabled(cacheable=false)
    public static void addOpportunityTeamMember(String inputString, List<String> selectedIdsList ){
        AddTeamMemberToOpportunity.AddTeamMember member = (AddTeamMemberToOpportunity.AddTeamMember)JSON.deserialize(inputString,AddTeamMemberToOpportunity.AddTeamMember.class);
        //System.debug('====member===='+member);
        List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
        OpportunityTeamMember otm;
        for(String oppid: selectedIdsList ){
            otm = new OpportunityTeamMember();
            otm.OpportunityAccessLevel = member.bloodDriveAccessLevel;
            otm.userId = member.userId;
            otm.OpportunityId = oppid;
            otm.TeamMemberRole = member.teamRole;
            otmList.add(otm);
        }	
        try{
            //if (Schema.sObjectType.OpportunityTeamMember.isCreateable()){}
                 
                    Database.insert(otmList);
                 
        }
        catch(Exception e){
            throw new AuraHandledException('An Error Occured! '+e.getMessage());
        }
    }
    
	
	public without sharing class AddTeamMember{
        @AuraEnabled public String userId;
        @AuraEnabled public String teamRole;
        @AuraEnabled public String accountAccessLevel;
        @AuraEnabled public String caseAccessLevel;
        @AuraEnabled public String bloodDriveAccessLevel;
    }
    

}