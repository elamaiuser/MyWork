/* 
 * Date					Developer Name			Description
 * ***************************************************************************************************************************************************************************
 * 06/14/2023			Barnojit Sharma			Test class for BSF_RemoveAccountTeamMemberBatch (HRP-4773)
 *****************************************************************************************************************************************************************************
*/
@isTest
public class BSF_RemoveAccountTeamMemberBatchTest {

    @testSetup 
    static void createData(){
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
     
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c ='TEST';
        insert testMobileAccount;
        sked__Tag__c tag = (sked__Tag__c)mapTestData.get('GLOBAL_TAG');
        insert tag;
        
       	sked__Location__c site = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        skedHubBase.BypassInsertTriggers = true;
        TriggerHandler.bypass('SiteTriggerHandler');
        insert site;
        TriggerHandler.clearAllBypasses();
        skedHubBase.BypassInsertTriggers = false;
        
        Opportunity testMobileOpp = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp.accountId = testMobileAccount.Id;
        testMobileOpp.Drive_Site__c = site.Id;
        insert testMobileOpp;
        
        List<Taxonomy__c> taxonomies = PortfolioTestDataFactory.createTaxonomies('48420','48421');
        insert taxonomies;
        
        List<Taxonomy__c> taxoList = [SELECT Division_Code__c,Division_Key__c,Division_Name__c,DRD_Territory_Code__c,DRD_Territory_Key__c,DRD_Territory_Name__c,DS_Region_Code__c,DS_Region_Key__c,DS_Region_Name__c,
                                            Team_Code__c,Team_Key__c,Team_Name__c,ABM_Code__c,ABM_Name__c,Type_Key__c,Type__c,Start_Date__c,End_Date__c,
        									RecordType.Name,District_Code__c,District_Name__c,Collection_Operation_Code__c,Collection_Operation_Name__c,Supervisor_Code__c,Supervisor_Name__c,Portfolio_Code__c,Portfolio_Name__c
        									FROM Taxonomy__c WHERE RecordType.Name != :BSF_Constants.BIO_COLLECTION_RECORD_TYPE]; 
        
        TriggerHandler.bypass('BsfPortfolioTriggerHandler');
        BSFPortfolioHelper portfolioHelper = new BSFPortfolioHelper();
        portfolioHelper.createOrUpdatePortfolio(taxoList);
        TriggerHandler.clearBypass('BsfPortfolioTriggerHandler');
    }
    
    
    
    
    @isTest
    static void testBatch1(){
        Opportunity mobileOpportunity = [Select Id,Name,AccountId,Drive_Date__c FROM Opportunity Where Is_Template__c = FALSE AND RecordType.DeveloperName = 'Mobile_Opp' Limit 1];
        Account act = new Account(Id=mobileOpportunity.AccountId,BillingPostalCode='48420');
        TriggerHandler.bypass('AccountTriggerHandler');
        update act;
        TriggerHandler.clearBypass('AccountTriggerHandler');
        
        
        //create users
        List<User> users = new List<User>();
        Profile drdProfile = [SELECT Id FROM Profile WHERE Name='DRD Profile']; //Keep this in Label
        Profile drdManagerProfile = [SELECT Id FROM Profile WHERE Name='DRD Manager'];
        
        List<User> drdUsers = populateUserFields('DRD','User',drdProfile.Id,60);
        List<User> dmUsers = populateUserFields('DM','User',drdManagerProfile.Id,60);
        
        List<User> allUsers = new List<User>();
        allUsers.addAll(drdUsers);
        allUsers.addAll(dmUsers);
        insert allUsers;
        
        List<AccountTeamMember> coveringRecruiterList = new List<AccountTeamMember>();
        AccountTeamMember coveringRecruiter1 = new AccountTeamMember(AccountId=mobileOpportunity.AccountId,Coverage_Reason__c='Leave of Absence (LOA)',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-1].Id);
        coveringRecruiter1.Is_Covering_Recruiter__c = true;
        coveringRecruiter1.Start_Date__c = System.today()-2;
        coveringRecruiter1.End_Date__c = System.today()+30;
        AccountTeamMember coveringRecruiter2 = new AccountTeamMember(AccountId=mobileOpportunity.AccountId,Coverage_Reason__c='Vacant Territory',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-2].Id);
        coveringRecruiter2.Is_Covering_Recruiter__c = true;
        coveringRecruiter2.Start_Date__c = System.today()+50;
        coveringRecruiter2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        
        coveringRecruiterList.add(coveringRecruiter1);
        coveringRecruiterList.add(coveringRecruiter2);
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        insert coveringRecruiterList;
        
        coveringRecruiter1.Start_Date__c = System.today()+50;
        coveringRecruiter1.End_Date__c = System.today()+100;
        coveringRecruiter2.Start_Date__c = System.today()-2;
        coveringRecruiter2.End_Date__c = System.today()-1;
        update coveringRecruiterList;
		
        Test.startTest();
        
        	Database.executeBatch(new BSF_RemoveAccountTeamMemberBatch(), 200);
        	System.schedule('Test BSF_RemoveAccountTeamMemberBatch', '0 0 13 * * ?', new BSF_RemoveAccountTeamMemberBatch());
        Test.stopTest();
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
}