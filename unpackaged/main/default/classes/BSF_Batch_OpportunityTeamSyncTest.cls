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
        
        Database.executeBatch(new BSF_Batch_OpportunityTeamSync(mapOfAcctsWithTeamMembers,1));
        
        List<AccountTeamMember> accTeam2 = [select Id, accountId, start_date__c, end_date__c, TeammemberRole,Is_Covering_Recruiter__c, userId,BSF_Portfolio__c from AccountTeamMember limit 2];
        accTeam2[0].start_date__c = system.today().adddays(10);
        update accTeam2[0];
        
        Database.executeBatch(new BSF_Batch_OpportunityTeamSync(system.today().adddays(-1),system.today().addDays(2)));
        
        Test.stopTest();
        
    }
    
}