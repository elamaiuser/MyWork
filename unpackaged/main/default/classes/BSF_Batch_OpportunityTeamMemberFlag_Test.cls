@isTest
public class BSF_Batch_OpportunityTeamMemberFlag_Test {

    @testSetup static void createData(){
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c = 'New IN';
        insert testMobileAccount;
        
        sked__Tag__c tag = (sked__Tag__c)mapTestData.get('GLOBAL_TAG');
        insert tag;
        
       	sked__Location__c site = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert site;
        
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = site.Id;
        insert testMobileOpp;
        
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,5);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,5);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        Date defaultStartDate = System.today() -10;
        Date defaultEndDate = Date.newInstance(4000, 12, 31);
        
        List<AccountTeamMember> actTeamToInsert = new List<AccountTeamMember>();
        AccountTeamMember accAMUser = new AccountTeamMember(AccountId=testMobileAccount.Id,UserId=drdUsers[0].Id,TeamMemberRole='Account Manager',Start_Date__c=defaultStartDate,End_Date__c=defaultEndDate);
        AccountTeamMember accDMUser = new AccountTeamMember(AccountId=testMobileAccount.Id,UserId=dmUsers[0].Id,TeamMemberRole='District Manager',Start_Date__c=defaultStartDate,End_Date__c=defaultEndDate);
        actTeamToInsert.add(accAMUser);
        actTeamToInsert.add(accDMUser);
        insert actTeamToInsert;
        
        List<OpportunityTeamMember> opptyTeamToInsert = new List<OpportunityTeamMember>();
        OpportunityTeamMember opptyAMUser = new OpportunityTeamMember(OpportunityId=testMobileOpp.Id,UserId=drdUsers[0].Id,TeamMemberRole='Account Manager');
        OpportunityTeamMember opptyDMUser = new OpportunityTeamMember(OpportunityId=testMobileOpp.Id,UserId=dmUsers[0].Id,TeamMemberRole='District Manager');
        OpportunityTeamMember opptyAccSpecUser = new OpportunityTeamMember(OpportunityId=testMobileOpp.Id,UserId=drdUsers[1].Id,TeamMemberRole='Account Specialist');
        opptyTeamToInsert.add(opptyAMUser);
        opptyTeamToInsert.add(opptyDMUser);
        opptyTeamToInsert.add(opptyAccSpecUser);
        insert opptyTeamToInsert;
    }
    
    public static List<User> populateUserFields(String firstName,String lastName,Id profileId,Integer count){
        List<User> users = new List<User>();
        for(Integer index=1;index<=count;index++){
            User user1 = new User(Alias = firstName+index, FirstName = firstName+index, Email=firstName+index+'.'+lastName+index+'@test.com',EmailEncodingKey='UTF-8', LastName=lastName+index, LanguageLocaleKey='en_US', 
            	LocaleSidKey='en_US', ProfileId = profileId, TimeZoneSidKey='America/Los_Angeles', UserName=firstName+index+'.'+lastName+index+'@test.com.tst1');
        	users.add(user1);
        }
        return users;
    }
    
    @isTest static void testOpportunityTeamFlag1(){
        Test.startTest();
        List<Account> accountList = [Select Id from Account limit 10];
        BSF_Batch_OpportunityTeamMemberFlag batch1 = new BSF_Batch_OpportunityTeamMemberFlag(accountList);
      	Database.executeBatch(batch1);
        Test.stopTest();
    }
    
    @isTest static void testOpportunityTeamFlag2(){
        Test.startTest();
        List<Opportunity> opportunities = [Select Id from Opportunity limit 10];
        BSF_Batch_OpportunityTeamMemberFlag batch1 = new BSF_Batch_OpportunityTeamMemberFlag(opportunities);
      	Database.executeBatch(batch1);
        Test.stopTest();
    }
    
    @isTest static void testOpportunityTeamFlag3(){
        Test.startTest();
        BSF_Batch_OpportunityTeamMemberFlag batch1 = new BSF_Batch_OpportunityTeamMemberFlag();
      	Database.executeBatch(batch1);
        Test.stopTest();
    }
}