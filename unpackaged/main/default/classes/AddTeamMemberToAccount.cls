public inherited sharing class AddTeamMemberToAccount {
    
    // @AuraEnabled(cacheable=true)
    // public static List<SObject> findRecords(String searchKey, String objectName, String searchField){
    //     String key = '%' + searchKey + '%';
    //     String QUERY = 'Select Id, '+searchField+' From '+objectName +' Where '+searchField +' LIKE :key';
    //     System.debug(System.LoggingLevel.DEBUG, QUERY);
    //     List<SObject> sObjectList = Database.query(QUERY); 
    //     return sObjectList;
    // }

    @AuraEnabled(cacheable=false)
    public static List<String> getAccountNames(List<String> selectedIdsList ){
        List<Account> accnames = [ Select Id, Name from Account where ID IN: selectedIdsList ];

        List<String> accnameList = new List<String>();

        for( Account acc : accnames ){
            accnameList.add( acc.Name );
        }
        return accnameList;
    }
    
    @AuraEnabled(cacheable=false)
    public static void addAccountTeamMember(String inputString, List<String> selectedIdsList ){
        System.debug( 'inputString is ' + inputString );
        //List<String> selectedIdsList = new List<String>();
        // Object[] values = (Object[])JSON.deserializeUntyped(accList);
        // if(values.size()>0){         
        //      for (Object id : values) {
        //          selectedIdsList.add(string.valueof(id) );
        //      }
        //  }
  		
        // fetch from custom setting
        // List<UnassignedAccountId__c> unassignacc = [ select Id, AccountId__c from UnassignedAccountId__c];
        // if( !unassignacc.isEmpty() ){
            // for( UnassignedAccountId__c acc : unassignacc){
                // selectedIdsList.add( acc.AccountId__c );
            // }           
        // }

        AddTeamMemberToAccount.AddTeamMember member = (AddTeamMemberToAccount.AddTeamMember)JSON.deserialize(inputString,AddTeamMemberToAccount.AddTeamMember.class);
        System.debug('====member===='+member);
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
         AccountTeammember atm;
        for(String accId: selectedIdsList ){
            atm = new AccountTeammember();
            atm.AccountAccessLevel = member.accountAccessLevel;
            atm.CaseAccessLevel = member.caseAccessLevel;
            atm.OpportunityAccessLevel = member.bloodDriveAccessLevel;
            atm.userId = member.userId;
            atm.AccountId = accId;
            atm.Coverage_Reason__c = member.coveragereason;
            atm.TeamMemberRole = member.teamRole;
            atm.Start_Date__c = Date.valueof(member.startDate); 
            atm.End_Date__c = Date.valueof(member.endDate);
            atmList.add(atm);
        }
        try{
            //if (Schema.sObjectType.AccountTeamMember.isCreateable()){}
                 
        	Database.insert(atmList);

        //List<UnassignedAccountId__c> deleteunassignacc = [ select Id, AccountId__c from UnassignedAccountId__c];
        // if( !deleteunassignacc.isEmpty() ){
            // delete  deleteunassignacc;
        // }


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
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public String coveragereason;

    }
    

}