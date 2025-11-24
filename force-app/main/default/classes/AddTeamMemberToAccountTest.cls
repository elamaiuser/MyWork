/*
 * This Test class covering following class
 * AddTeamMemberToAccount
 */

@isTest(SeeAllData=false)
private class AddTeamMemberToAccountTest {
   
    @testSetup 
    static void prepareDataset() {
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        TriggerHandler.bypass('AccountTriggerHandler');
        TriggerHandler.bypass('UserTriggerHandler');
        TriggerHandler.bypass('SiteTriggerHandler');
        TriggerHandler.bypass('OpportunityTriggerHandler');
        
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
        
        //Create DRD Users
        List<User> testUsers = new List<User>();
        testUsers.add((User)mapTestData.get('DRD_USER'));
        testUsers.add((User)mapTestData.get('DRD_MANAGER_USER'));
        system.runAs(new User(Id = UserInfo.getUserId())) {
            for(User testUser : testUsers) {
                testUser.isActive = true;
            } 
            insert testUsers;
        }
        
        //insert account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'Test Account';
        insert testMobileAccount;
    }
    
    @isTest static void addAccountTeamMember_test() {   
        Test.startTest();
        
        Date currentdate = System.today();
        Date nextdate = System.today().addDays(5);
        
        String month = currentdate.month() < 10 ? '0' + String.valueOf(currentdate.month()) : String.valueOf(currentdate.month()) ;
        String day = currentdate.day() < 10 ? '0' + String.valueOf(currentdate.day()) : String.valueOf(currentdate.day()) ;
        String year = String.valueOf(currentdate.Year());
        String st_date = year + '-' + month + '-' + day ;
        
        month = nextdate.month() < 10 ? '0' + String.valueOf(nextdate.month()) : String.valueOf(nextdate.month()) ;
        day = nextdate.day() < 10 ? '0' + String.valueOf(nextdate.day()) : String.valueOf(nextdate.day()) ;
        year = String.valueOf(nextdate.Year());
        String ed_date = year + '-' + month + '-' + day ;
        
        AddTeamMemberToAccount.AddTeamMember  atm = new AddTeamMemberToAccount.AddTeamMember();
        atm.userId = [SELECT Id FROM User WHERE Profile.Name = 'DRD Profile' AND LastName = 'DRDLastName' AND IsActive = true LIMIT 1].Id;
        atm.teamRole = 'Account Manager';
        atm.accountAccessLevel = 'Read';
        atm.caseAccessLevel = 'None';
        atm.bloodDriveAccessLevel = 'None';
        atm.startDate = st_date;
        atm.endDate = ed_date ;
        atm.coveragereason = 'Vacant Territory';
        String atmJson = JSON.serialize( atm );
        
        AddTeamMemberToAccount.addAccountTeamMember(atmJson, new List<String>{[SELECT Id FROM Account LIMIT 1].Id});
		Test.stopTest();
        
        List<AccountTeammember> atmem = [SELECT Id FROM AccountTeammember LIMIT 1]; 
        Assert.isTrue(!atmem.isEmpty());
    }   
    
    @isTest static void addAccountDistricManager_test() {       
        Test.startTest();
        
        Date currentdate = System.today();
        Date nextdate = System.today().addDays(5);
        
        String month = currentdate.month() <10 ? '0' + String.valueOf(currentdate.month()) : String.valueOf(currentdate.month()) ;
        String day = currentdate.day() <10 ? '0' + String.valueOf(currentdate.day()) : String.valueOf(currentdate.day()) ;
        String year = String.valueOf(currentdate.Year());
        String st_date = year + '-' + month + '-' + day ;
        
        month = nextdate.month() <10 ? '0' + String.valueOf(nextdate.month()) : String.valueOf(nextdate.month()) ;
        day = nextdate.day() <10 ? '0' + String.valueOf(nextdate.day()) : String.valueOf(nextdate.day()) ;
        year = String.valueOf(nextdate.Year());
        String ed_date = year + '-' + month + '-' + day ;
        
        AddTeamMemberToAccount.AddTeamMember  atm = new AddTeamMemberToAccount.AddTeamMember();
        atm.userId = [SELECT Id FROM User WHERE Profile.Name = 'DRD Manager' AND LastName = 'DRDManagerLastName' AND IsActive = true LIMIT 1].Id;
        atm.teamRole = 'District Manager';
        atm.accountAccessLevel = 'Read';
        atm.caseAccessLevel = 'None';
        atm.bloodDriveAccessLevel = 'None';
        atm.startDate = st_date;
        atm.endDate = ed_date;
        atm.coveragereason = 'Vacant Territory';
        String atmJson = JSON.serialize( atm );
        
        AddTeamMemberToAccount.addAccountTeamMember(atmJson, new List<String>{[SELECT Id FROM Account LIMIT 1].Id});
		
        Test.stopTest();
        List<AccountTeammember> atmem = [select Id from AccountTeammember limit 1]; 
        Assert.isTrue(!atmem.isEmpty());
    }
    
    @isTest static void addAccountTemporaryManager_test() {  
        Test.startTest();
        
        List<String> selectedIdsList  = new List<String>{[SELECT Id FROM Account LIMIT 1].Id};
            
        Date currentdate = System.today();
        Date nextdate = System.today().addDays(5);
        String month = currentdate.month() < 10 ? '0' + String.valueOf(currentdate.month()) : String.valueOf(currentdate.month()) ;
        String day = currentdate.day() < 10 ? '0' + String.valueOf(currentdate.day()) : String.valueOf(currentdate.day()) ;
        String year = String.valueOf(currentdate.Year());
        String st_date = year + '-' + month + '-' + day ;
        
        month = nextdate.month() < 10 ? '0' + String.valueOf(nextdate.month()) : String.valueOf(nextdate.month()) ;
        day = nextdate.day() < 10 ? '0' + String.valueOf(nextdate.day()) : String.valueOf(nextdate.day()) ;
        year = String.valueOf(nextdate.Year());
        String ed_date = year + '-' + month + '-' + day ;

        AddTeamMemberToAccount.AddTeamMember  atm = new AddTeamMemberToAccount.AddTeamMember();
        atm.userId = [SELECT Id FROM User WHERE Profile.Name = 'DRD Manager' AND LastName = 'DRDManagerLastName' AND IsActive = true LIMIT 1].Id;
        atm.teamRole = 'Temporary Account Manager';
        atm.accountAccessLevel = 'Read';
        atm.caseAccessLevel = 'None';
        atm.bloodDriveAccessLevel = 'None';
        atm.startDate = st_date;
        atm.endDate = ed_date;
        atm.coveragereason = 'Vacant Territory';
        String atmJson = JSON.serialize( atm );
        
        AddTeamMemberToAccount.addAccountTeamMember(atmJson, selectedIdsList); 
        AddTeamMemberToAccount.getAccountNames(selectedIdsList);
		
        Test.stopTest();
        List<AccountTeammember> atmem = [SELECT Id FROM AccountTeammember LIMIT 1]; 
        Assert.isTrue(!atmem.isEmpty());
    }
}