// The following test class covers BSF_Batch_OpportunityTeamSync

@istest(SeeAllData = false)
public class BSF_Batch_OpportunityTeamSyncTest
{
    @testSetup
    static void prepareDataset()
    {
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
            
        // insert DRD Users
        List<User> drdUsersList = new List<User>();
        
        User drdUser = (User)mapTestData.get('DRD_USER');
        User drdUser2 = (User)mapTestData.get('DRD_MANAGER_USER');
        
        drdUsersList.add(drdUser);
        drdUsersList.add(drdUser2);
        
        system.runAs(new User(Id = UserInfo.getUserId()))
        {
            insert drdUsersList;
        }
        
        // insert Fixed Site Account
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        insert testFixedSiteAccount;
                        
        // insert AccountTeamMembers - Fixed Site
        
        List<AccountTeamMember> accTeamList = new  List<AccountTeamMember>();
        AccountTeamMember accTeamMember1 = (AccountTeamMember)mapTestData.get('ACCOUNT_TEAM_MEMBER_FIXED');
        accTeamMember1.AccountId = testFixedSiteAccount.Id;
        accTeamMember1.UserId = drdUsersList[0].Id;
        accTeamList.add(accTeamMember1);
        
       	AccountTeamMember accTeamMember2 = (AccountTeamMember)mapTestData.get('ACCOUNT_TEAM_MEMBER_FIXED2');
       	accTeamMember2.AccountId = testFixedSiteAccount.Id;
       	accTeamMember2.UserId = drdUsersList[1].Id;
       	accTeamList.add(accTeamMember2);
        
        insert accTeamList;
        
        // insert site
        sked__Location__c fixedSite = (sked__Location__c)mapTestdata.get('FIXED_SITE');
        insert fixedSite;
        
        // insert fixed site opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity fixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        fixedSiteOpp.Drive_Site__c = fixedSite.Id;
        fixedSiteOpp.AccountId = testFixedSiteAccount.Id;
        oppList.add(fixedSiteOpp);
        Triggerhandler.bypass('OpportunityTriggerhandler');
        insert oppList;
    }
    
    static testMethod void testBatchV1()
    {
        Test.startTest();
        List<Account> acc = [select Id from Account];
        
        Map<Id,List<AccountTeamMember>> mapOfAcctsWithTeamMembers = new Map<Id,List<AccountTeamMember>>();
        for(Account obj: acc)
        {
            mapOfAcctsWithTeamMembers.put(obj.Id,new List<AccountTeamMember>([select Id, accountId, start_date__c, end_date__c, TeammemberRole,Is_Covering_Recruiter__c, userId, BSF_Portfolio__c from AccountTeamMember where accountId =: obj.Id]));            
        }
        

        
        List<AccountTeamMember> accTeam2 = [select Id, accountId, start_date__c, end_date__c, TeammemberRole,Is_Covering_Recruiter__c, userId,BSF_Portfolio__c from AccountTeamMember limit 2];
        accTeam2[0].start_date__c = system.today().adddays(10);
        
        update accTeam2[0];
        
      Portfolio_Accounts_Processing__c pap = new Portfolio_Accounts_Processing__c();
        pap.Records_Processed__c = 1;
        insert pap;
        
           
        RecordType rt = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Taxonomy__c' and Name =: BSF_Constants.BIO_RECRUITMENT_RECORD_TYPE LIMIT 1];
        // Create corresponding taxonomy run
        Taxonomy_Run__c taxoRun = new Taxonomy_Run__c(
            //  External_Id__c = rt.Name + '_' + taxn.Version_Key__c,
            Status__c = 'pending',
            Taxo_Record_Type__c = rt.Name,
             Future_Version_Number__c =296,
            Run_Date__c = System.today()
        );
        insert taxoRun;
        
        Database.executeBatch(new BSF_Batch_OpportunityTeamSync(system.today().adddays(-1),system.today().addDays(2)));
        
        BSF_Batch_OpportunityTeamSync batch = new BSF_Batch_OpportunityTeamSync(mapOfAcctsWithTeamMembers,0,system.today().adddays(-1),system.today().addDays(2));
        database.executeBatch(batch, 50);
        
             //    Database.executeBatch(new BSF_Batch_OpportunityTeamSync(system.today().adddays(-1),system.today().addDays(2)),143);

  BSF_Batch_OpportunityTeamSync batch1 = new BSF_Batch_OpportunityTeamSync(system.today().adddays(-1),system.today().addDays(2),296);
        database.executeBatch(batch1, 50);
                
        
        Test.stopTest();
        
    }
    
    
     public static List<User> populateUserFields(String firstName,String lastName,Id profileId,Integer count){
        List<User> users = new List<User>();
        for(Integer index=1;index<=count;index++){
            User user1 = new User(Alias = firstName+index, FirstName = firstName+index, Email=firstName+index+'.'+lastName+index+'@test.com',EmailEncodingKey='UTF-8', LastName=lastName+index, LanguageLocaleKey='en_US', 
            	LocaleSidKey='en_US', ProfileId = profileId, TimeZoneSidKey='America/Los_Angeles', UserName=firstName+index+'.'+lastName+index+'@test.com.tst1',CommunityNickname=firstName+index+'.'+lastName+index+'@test.com.tst1');
        	users.add(user1);
        }
        return users;
    }
      @isTest
    public static void testMethodAccTeam()
    {
        skedHubBase.BypassInsertTriggers=true;
        skedHubBase.BypassUpdateTriggers=true;
        BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects(); 
                
        // insert Mobile Account
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        triggerHandler.bypass('AccountTriggerHandler');
        insert testMobileAccount;
        
        
        // insert Mobile Site
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert testMobileSite;
        
        // insert templates
        Opportunity testTemplate = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        testTemplate.AccountId = testMobileAccount.Id;
        testTemplate.Drive_Site__c = testMobileSite.Id;
        insert testTemplate;
        
        list<opportunity> opportunityList = new list<opportunity>();
        
        
       Opportunity testMobileOpp1 = new Opportunity(
            Name = 'Test Opportunity 2',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(55),
        	CloseDate = system.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
        testMobileOpp1.AccountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = testMobileSite.Id;
        testMobileOpp1.Parent_Template_Id__c = testTemplate.Id;
       opportunityList.add(testMobileOpp1);
        TriggerHandler.bypass('OpportunityTriggerHandler');
        insert opportunityList;
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
        AccountTeamMember coveringRecruiter1 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Leave of Absence (LOA)',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-1].Id);
        coveringRecruiter1.Is_Covering_Recruiter__c = true;
        coveringRecruiter1.Start_Date__c = System.today()-2;
        coveringRecruiter1.End_Date__c = System.today()+30;
        AccountTeamMember coveringRecruiter2 = new AccountTeamMember(AccountId=testMobileAccount.Id,Coverage_Reason__c='Vacant Territory',TeamMemberRole='Account Manager',UserId=drdUsers[drdUsers.size()-2].Id);
        coveringRecruiter2.Is_Covering_Recruiter__c = true;
        coveringRecruiter2.Start_Date__c = System.today()+50;
        coveringRecruiter2.End_Date__c = System.today()+100;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = false;
        
        coveringRecruiterList.add(coveringRecruiter1);
        coveringRecruiterList.add(coveringRecruiter2);
        test.startTest();
        insert coveringRecruiterList;
        test.stopTest();
     BSF_Batch_OpportunityTeamSync batch1 = new BSF_Batch_OpportunityTeamSync(system.today().adddays(-1),system.today().addDays(2),296);
        database.executeBatch(batch1, 50);
     
    
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
}